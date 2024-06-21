// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "./upgradable/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "./upgradable/UUPSUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/BaseOrderUtils.sol";
import "./interfaces/IDatastore.sol";
import "./interfaces/Keys.sol";
import "./interfaces/IPriceFeed.sol";
import "./interfaces/Enum.sol";
import "./interfaces/IModuleManager.sol";
import "./interfaces/ISmartAccountFactory.sol";
import "./interfaces/IWNT.sol";
import "./interfaces/IExchangeRouter.sol";
import "./interfaces/IReferrals.sol";
import "./interfaces/IOrderCallbackReceiver.sol";
import "./interfaces/IProfitShare.sol";
import "./interfaces/IBiconomyModuleSetup.sol";
import "./interfaces/IEcdsaOwnershipRegistryModule.sol";
import "./interfaces/IPostExecutionHandler.sol";

//v2.1.1
//Arbitrum equipped
contract Gmxv2OrderModule is Initializable, OwnableUpgradeable, UUPSUpgradeable, IOrderCallbackReceiver {
    mapping(address => address) public operators;
    mapping(bytes32 => ProfitTakeParam) public orderCollateral; //[order key, position collateral]

    uint256 public ethPriceMultiplier; // cache for gas saving, ETH's GMX price precision
    address public postExecutionHandler;

    uint256 public simpleGasBase; //deployAA, cancelOrder
    uint256 public newOrderGasBase; //every newOrder
    uint256 public callbackGasLimit;

    address private constant SENTINEL_OPERATORS = address(0x1);
    address private constant USDC = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
    address private constant WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    IDataStore private constant DATASTORE = IDataStore(0xFD70de6b91282D8017aA4E741e9Ae325CAb992d8);
    bytes32 private constant REFERRALCODE = 0x74726164616f7800000000000000000000000000000000000000000000000000; //tradaox
    address private constant REFERRALSTORAGE = 0xe6fab3F0c7199b0d34d7FbE83394fc0e0D06e99d;
    ISmartAccountFactory private constant BICONOMY_FACTORY =
        ISmartAccountFactory(0x000000a56Aaca3e9a4C479ea6b6CD0DbcB6634F5);
    bytes private constant SETREFERRALCODECALLDATA =
        abi.encodeWithSignature("setTraderReferralCodeByUser(bytes32)", REFERRALCODE);
    bytes private constant MODULE_SETUP_DATA = abi.encodeWithSignature("getModuleAddress()"); //0xf004f2f9
    address private constant BICONOMY_MODULE_SETUP = 0x32b9b615a3D848FdEFC958f38a529677A0fc00dD;
    bytes4 private constant OWNERSHIPT_INIT_SELECTOR = 0x2ede3bc0; //bytes4(keccak256("initForSmartAccount(address)"))
    address private constant DEFAULT_ECDSA_OWNERSHIP_MODULE = 0x0000001c5b32F37F5beA87BDD5374eB2aC54eA8e;
    bytes32 private constant ETH_MULTIPLIER_KEY = 0x007b50887d7f7d805ee75efc0a60f8aaee006442b047c7816fc333d6d083cae0; //keccak256(abi.encode(keccak256(abi.encode("PRICE_FEED_MULTIPLIER")), address(WETH)))
    bytes32 private constant ETH_PRICE_FEED_KEY = 0xb1bca3c71fe4192492fabe2c35af7a68d4fc6bbd2cfba3e35e3954464a7d848e; //keccak256(abi.encode(keccak256(abi.encode("PRICE_FEED")), address(WETH)))
    uint256 private constant ETH_MULTIPLIER = 10 ** 18;
    uint256 private constant USDC_MULTIPLIER = 10 ** 6;
    address private constant ORDER_VAULT = 0x31eF83a530Fde1B38EE9A18093A333D8Bbbc40D5;
    IExchangeRouter private constant EXCHANGE_ROUTER = IExchangeRouter(0x69C527fC77291722b52649E45c838e41be8Bf5d5);
    IReferrals private constant TRADAO_REFERRALS = IReferrals(0xdb3643FE2693Beb1a78704E937F7C568FdeEeDdf);
    address private constant ORDER_HANDLER = 0xB0Fc2a48b873da40e7bc25658e5E6137616AC2Ee;
    bytes32 private constant COLLATERAL_AMOUNT = 0xb88da5cd71628783263477a6261c2906e380aa32e85e2e87b2463bbdc1127221; //keccak256(abi.encode("COLLATERAL_AMOUNT"));
    uint256 private constant MIN_PROFIT_TAKE_BASE = 5 * USDC_MULTIPLIER;
    uint256 private constant MAX_PROFIT_TAKE_RATIO = 2000; //20.00%;
    IProfitShare private constant PROFIT_SHARE = IProfitShare(0xBA6Eed0E234e65124BeA17c014CAc502B4441D64);
    uint256 private constant FLOAT_PRECISION = 10 ** 30;
    uint256 private constant ORACLE_PRICE_COUNT = 3;

    event GasBaseUpdated(uint256 simple, uint256 newOrder);
    event CallbackGasLimitUpdated(uint256 callback);
    event EnabledOperator(address indexed operator);
    event DisabledOperator(address indexed operator);
    event NewSmartAccount(address indexed creator, address userEOA, uint96 number, address smartAccount);
    event OrderCreated(
        address indexed aa,
        address indexed followee,
        uint256 sizeDelta,
        uint256 collateralDelta,
        uint256 acceptablePrice,
        bytes32 orderKey,
        uint256 triggerPrice,
        address tradaoReferrer
    );
    event OrderCreationFailed(
        address indexed aa,
        address indexed followee,
        uint256 sizeDelta,
        uint256 collateralDelta,
        uint256 acceptablePrice,
        uint256 triggerPrice,
        Enum.OrderFailureReason reason
    );
    event OrderCancelled(address indexed aa, bytes32 orderKey);
    event PayGasFailed(address indexed aa, uint256 gasFeeEth, uint256 ethPrice, uint256 aaUSDCBalance);
    event TakeProfitSuccess(address indexed account, bytes32 orderKey, uint256 amount, address to);
    event TakeProfitFailed(address indexed account, bytes32 orderKey, Enum.TakeProfitFailureReason reason);
    event PostExecutionHandlerUpdated(address prevAddress, address currentAddress);

    error UnsupportedOrderType();
    error OrderCreationError(
        address aa,
        address followee,
        uint256 sizeDelta,
        uint256 collateralDelta,
        uint256 acceptablePrice,
        uint256 triggerPrice
    );

    struct OrderParamBase {
        address followee; //the trader that copy from; 0: not a copy trade.
        address market;
        Order.OrderType orderType;
        bool isLong;
    }

    struct OrderParam {
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount; //for increase, indicate USDC transfer amount; for decrease, set to createOrderParams
        uint256 acceptablePrice;
        address smartAccount;
    }

    struct ProfitTakeParam {
        address followee;
        uint256 prevCollateral;
        address operator;
    }

    /**
     * @dev Only allows addresses with the operator role to call the function.
     */
    modifier onlyOperator() {
        require(SENTINEL_OPERATORS != msg.sender && operators[msg.sender] != address(0), "403");
        _;
    }

    modifier onlyOrderHandler() {
        require(msg.sender == ORDER_HANDLER, "403");
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function enableOperator(address _operator) external onlyOwner {
        // operator address cannot be null or sentinel. operator cannot be added twice.
        require(_operator != address(0) && _operator != SENTINEL_OPERATORS && operators[_operator] == address(0), "400");

        operators[_operator] = operators[SENTINEL_OPERATORS];
        operators[SENTINEL_OPERATORS] = _operator;

        emit EnabledOperator(_operator);
    }

    function disableOperator(address prevoperator, address _operator) external onlyOwner {
        // Validate operator address and check that it corresponds to operator index.
        require(
            _operator != address(0) && _operator != SENTINEL_OPERATORS && operators[prevoperator] == _operator, "400"
        );
        operators[prevoperator] = operators[_operator];
        delete operators[_operator];
        emit DisabledOperator(_operator);
    }

    function updatePostExecutionHandler(address handler) external onlyOwner {
        address _prev = postExecutionHandler;
        postExecutionHandler = handler;
        emit PostExecutionHandlerUpdated(_prev, handler);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function deployAA(address userEOA, uint96 number, address _referrer) external returns (bool isSuccess) {
        uint256 startGas = gasleft();

        address aa = _deployAA(userEOA, number);
        setReferralCode(aa);
        if (_referrer != address(0)) {
            TRADAO_REFERRALS.setReferrerFromModule(aa, _referrer);
        }
        emit NewSmartAccount(msg.sender, userEOA, number, aa);
        isSuccess = true;

        if (operators[msg.sender] != address(0)) {
            uint256 ethPrice = getPriceFeedPrice();
            uint256 gasUsed = _adjustGasUsage(startGas - gasleft(), simpleGasBase);
            isSuccess = _payGas(aa, gasUsed * tx.gasprice, ethPrice);
        }
    }

    //cancel single order
    function cancelOrder(address smartAccount, bytes32 key) external onlyOperator returns (bool success) {
        uint256 startGas = gasleft();
        require(key > 0, "key");

        bytes memory data = abi.encodeWithSelector(EXCHANGE_ROUTER.cancelOrder.selector, key);
        success = IModuleManager(smartAccount).execTransactionFromModule(
            address(EXCHANGE_ROUTER), 0, data, Enum.Operation.Call
        );
        if (success) {
            emit OrderCancelled(smartAccount, key);
        }

        uint256 ethPrice = getPriceFeedPrice();
        uint256 gasUsed = _adjustGasUsage(startGas - gasleft(), simpleGasBase);
        success = _payGas(smartAccount, gasUsed * tx.gasprice, ethPrice);
    }

    //single order, could contain trigger price
    function newOrder(uint256 triggerPrice, OrderParamBase memory _orderBase, OrderParam memory _orderParam)
        external
        onlyOperator
        returns (bytes32 orderKey)
    {
        uint256 startGasLeft = gasleft();
        uint256 ethPrice = getPriceFeedPrice();
        uint256 _executionGasFee = getExecutionFeeGasLimit(_orderBase.orderType) * tx.gasprice;
        orderKey = _newOrder(_executionGasFee, triggerPrice, _orderBase, _orderParam);

        uint256 gasFeeAmount = _adjustGasUsage(startGasLeft - gasleft(), newOrderGasBase) * tx.gasprice;
        _payGas(
            _orderParam.smartAccount,
            orderKey == bytes32(uint256(1)) ? gasFeeAmount : gasFeeAmount + _executionGasFee,
            ethPrice
        );
    }

    /**
     *   copy trading orders.
     *   do off chain check before every call:
     *   1. check if very aa's module is enabled
     *   2. estimate gas, check aa's balance
     *   3. do simulation call
     */
    function newOrders(OrderParamBase memory _orderBase, OrderParam[] memory orderParams)
        external
        onlyOperator
        returns (bytes32[] memory orderKeys)
    {
        uint256 lastGasLeft = gasleft();
        uint256 ethPrice = getPriceFeedPrice();
        uint256 _executionGasFee = getExecutionFeeGasLimit(_orderBase.orderType) * tx.gasprice;
        uint256 multiplierFactor = DATASTORE.getUint(Keys.EXECUTION_GAS_FEE_MULTIPLIER_FACTOR);
        uint256 _newOrderGasBase = newOrderGasBase;

        uint256 len = orderParams.length;
        orderKeys = new bytes32[](len);
        for (uint256 i; i < len; i++) {
            OrderParam memory _orderParam = orderParams[i];
            orderKeys[i] = _newOrder(_executionGasFee, 0, _orderBase, _orderParam);
            uint256 gasUsed = lastGasLeft - gasleft();
            lastGasLeft = gasleft();
            uint256 gasFeeAmount = (_newOrderGasBase + (gasUsed * multiplierFactor / FLOAT_PRECISION)) * tx.gasprice;
            _payGas(
                _orderParam.smartAccount,
                orderKeys[i] == bytes32(uint256(1)) ? gasFeeAmount : gasFeeAmount + _executionGasFee,
                ethPrice
            );
        }
    }

    //@return, bytes32(uint256(1)): pay execution Fee failed
    function _newOrder(
        uint256 _executionGasFee,
        uint256 triggerPrice,
        OrderParamBase memory _orderBase,
        OrderParam memory _orderParam
    ) internal returns (bytes32 orderKey) {
        //transfer execution fee WETH from operator to GMX Vault
        bool isSuccess = IERC20(WETH).transferFrom(msg.sender, ORDER_VAULT, _executionGasFee);
        if (!isSuccess) {
            emit OrderCreationFailed(
                _orderParam.smartAccount,
                _orderBase.followee,
                _orderParam.sizeDeltaUsd,
                _orderParam.initialCollateralDeltaAmount,
                _orderParam.acceptablePrice,
                triggerPrice,
                Enum.OrderFailureReason.PayExecutionFeeFailed
            );
            return bytes32(uint256(1));
        }

        bool isIncreaseOrder = BaseOrderUtils.isIncreaseOrder(_orderBase.orderType);
        if (isIncreaseOrder && _orderParam.initialCollateralDeltaAmount > 0) {
            isSuccess = _aaTransferUsdc(_orderParam.smartAccount, _orderParam.initialCollateralDeltaAmount, ORDER_VAULT);
            if (!isSuccess) {
                emit OrderCreationFailed(
                    _orderParam.smartAccount,
                    _orderBase.followee,
                    _orderParam.sizeDeltaUsd,
                    _orderParam.initialCollateralDeltaAmount,
                    _orderParam.acceptablePrice,
                    triggerPrice,
                    Enum.OrderFailureReason.TransferCollateralToVaultFailed
                );
                return bytes32(uint256(2));
            }
        }

        //build orderParam
        BaseOrderUtils.CreateOrderParams memory cop;
        _buildOrderCustomPart(_orderBase, _orderParam, cop);
        cop.numbers.executionFee = _executionGasFee;
        cop.numbers.triggerPrice = triggerPrice;
        if (!isIncreaseOrder) {
            cop.numbers.initialCollateralDeltaAmount = _orderParam.initialCollateralDeltaAmount;
        }
        cop.addresses.callbackContract = address(this);
        cop.numbers.callbackGasLimit = callbackGasLimit;

        //send order
        orderKey = _aaCreateOrder(cop);
        if (orderKey == 0) {
            if (isIncreaseOrder && _orderParam.initialCollateralDeltaAmount > 0) {
                //protect user's collateral.
                revert OrderCreationError(
                    _orderParam.smartAccount,
                    _orderBase.followee,
                    _orderParam.sizeDeltaUsd,
                    _orderParam.initialCollateralDeltaAmount,
                    _orderParam.acceptablePrice,
                    triggerPrice
                );
            } else {
                emit OrderCreationFailed(
                    _orderParam.smartAccount,
                    _orderBase.followee,
                    _orderParam.sizeDeltaUsd,
                    _orderParam.initialCollateralDeltaAmount,
                    _orderParam.acceptablePrice,
                    triggerPrice,
                    Enum.OrderFailureReason.CreateOrderFailed
                );
            }
        } else {
            emit OrderCreated(
                _orderParam.smartAccount,
                _orderBase.followee,
                _orderParam.sizeDeltaUsd,
                _orderParam.initialCollateralDeltaAmount,
                _orderParam.acceptablePrice,
                orderKey,
                triggerPrice,
                TRADAO_REFERRALS.getReferrer(_orderParam.smartAccount)
            );

            //save position collateral
            orderCollateral[orderKey] = ProfitTakeParam(
                _orderBase.followee,
                getCollateral(_orderParam.smartAccount, _orderBase.market, USDC, _orderBase.isLong),
                msg.sender
            );
        }
        return orderKey;
    }

    //return orderKey == 0 if failed.
    function _aaCreateOrder(BaseOrderUtils.CreateOrderParams memory cop) internal returns (bytes32 orderKey) {
        bytes memory data = abi.encodeWithSelector(EXCHANGE_ROUTER.createOrder.selector, cop);
        (bool success, bytes memory returnData) = IModuleManager(cop.addresses.receiver)
            .execTransactionFromModuleReturnData(address(EXCHANGE_ROUTER), 0, data, Enum.Operation.Call);
        if (success) {
            orderKey = bytes32(returnData);
        }
    }

    function _payGas(address aa, uint256 totalGasFeeEth, uint256 _ethPrice) internal returns (bool isSuccess) {
        if (aa.balance < totalGasFeeEth) {
            //transfer gas fee and execution fee USDC from AA to TinySwap
            isSuccess = _aaTransferUsdc(aa, _calcUsdc(totalGasFeeEth, _ethPrice), msg.sender);
        } else {
            //convert ETH to WETH to operator
            bytes memory data = abi.encodeWithSelector(IWNT(WETH).depositTo.selector, msg.sender);
            (bool success, bytes memory returnData) =
                IModuleManager(aa).execTransactionFromModuleReturnData(WETH, totalGasFeeEth, data, Enum.Operation.Call);
            isSuccess = success && (returnData.length == 0 || abi.decode(returnData, (bool)));
        }
        if (!isSuccess) {
            emit PayGasFailed(aa, totalGasFeeEth, _ethPrice, IERC20(USDC).balanceOf(aa));
        }
    }

    function _buildOrderCustomPart(
        OrderParamBase memory _orderBase,
        OrderParam memory _orderParam,
        BaseOrderUtils.CreateOrderParams memory params
    ) internal pure {
        params.addresses.initialCollateralToken = USDC;
        params.decreasePositionSwapType = Order.DecreasePositionSwapType.SwapPnlTokenToCollateralToken;
        params.shouldUnwrapNativeToken = true;

        //common part
        params.addresses.market = _orderBase.market;
        params.orderType = _orderBase.orderType;
        params.isLong = _orderBase.isLong;
        params.autoCancel = true;

        //custom part
        params.addresses.receiver = _orderParam.smartAccount;
        params.numbers.sizeDeltaUsd = _orderParam.sizeDeltaUsd;
        params.numbers.acceptablePrice = _orderParam.acceptablePrice;
    }

    function _aaTransferUsdc(address aa, uint256 usdcAmount, address to) internal returns (bool isSuccess) {
        if (usdcAmount == 0) {
            return true;
        }
        bytes memory data = abi.encodeWithSelector(IERC20.transfer.selector, to, usdcAmount);
        (bool success, bytes memory returnData) =
            IModuleManager(aa).execTransactionFromModuleReturnData(USDC, 0, data, Enum.Operation.Call);
        return success && (returnData.length == 0 || abi.decode(returnData, (bool)));
    }

    function _calcUsdc(uint256 ethAmount, uint256 _ethPrice) internal view returns (uint256 usdcAmount) {
        return ethAmount * _ethPrice * USDC_MULTIPLIER / ETH_MULTIPLIER / ethPriceMultiplier;
    }

    function _deployAA(address userEOA, uint96 number) internal returns (address) {
        uint256 index = uint256(bytes32(bytes.concat(bytes20(userEOA), bytes12(number))));
        address aa = BICONOMY_FACTORY.deployCounterFactualAccount(BICONOMY_MODULE_SETUP, MODULE_SETUP_DATA, index);
        bytes memory data = abi.encodeWithSelector(
            IModuleManager.setupAndEnableModule.selector,
            DEFAULT_ECDSA_OWNERSHIP_MODULE,
            abi.encodeWithSelector(OWNERSHIPT_INIT_SELECTOR, userEOA)
        );
        bool isSuccess = IModuleManager(aa).execTransactionFromModule(aa, 0, data, Enum.Operation.Call);
        require(isSuccess, "500");

        return aa;
    }

    function getExecutionFeeGasLimit(Order.OrderType orderType) public view returns (uint256) {
        uint256 gasBase = _estimateExecuteOrderGasLimit(orderType) + callbackGasLimit;
        return _adjustGasLimitForEstimate(gasBase);
    }

    // @dev adjust the estimated gas limit to help ensure the execution fee is sufficient during
    // the actual execution
    // @param dataStore DataStore
    // @param estimatedGasLimit the estimated gas limit
    function _adjustGasLimitForEstimate(uint256 estimatedGasLimit) internal view returns (uint256) {
        uint256 baseGasLimit = DATASTORE.getUint(Keys.ESTIMATED_GAS_FEE_BASE_AMOUNT);
        baseGasLimit += DATASTORE.getUint(Keys.ESTIMATED_GAS_FEE_PER_ORACLE_PRICE) * ORACLE_PRICE_COUNT;
        uint256 multiplierFactor = DATASTORE.getUint(Keys.ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR);
        return baseGasLimit + (estimatedGasLimit * multiplierFactor / FLOAT_PRECISION);
    }

    // @dev the estimated gas limit for orders
    function _estimateExecuteOrderGasLimit(Order.OrderType orderType) internal view returns (uint256) {
        if (BaseOrderUtils.isIncreaseOrder(orderType)) {
            return DATASTORE.getUint(Keys.INCREASE_ORDER_GAS_LIMIT);
        }

        if (BaseOrderUtils.isDecreaseOrder(orderType)) {
            return DATASTORE.getUint(Keys.DECREASE_ORDER_GAS_LIMIT) + DATASTORE.getUint(Keys.SINGLE_SWAP_GAS_LIMIT);
        }

        revert UnsupportedOrderType();
    }

    // @dev adjust the gas usage to pay operator
    // @param gasUsed the amount of gas used
    function _adjustGasUsage(uint256 gasUsed, uint256 baseGas) internal view returns (uint256) {
        // the gas cost is estimated based on the gasprice of the request txn
        // the actual cost may be higher if the gasprice is higher in the execution txn
        // the multiplierFactor should be adjusted to account for this
        uint256 multiplierFactor = DATASTORE.getUint(Keys.EXECUTION_GAS_FEE_MULTIPLIER_FACTOR);
        uint256 gasLimit = (gasUsed * multiplierFactor / FLOAT_PRECISION);
        return baseGas + gasLimit;
    }

    function updateGasBase(uint256 _simpleGasBase, uint256 _newOrderGasBase) external onlyOperator {
        uint256 baseGasLimit = DATASTORE.getUint(Keys.EXECUTION_GAS_FEE_BASE_AMOUNT);
        require(_simpleGasBase <= _newOrderGasBase && _newOrderGasBase <= baseGasLimit, "400");
        simpleGasBase = _simpleGasBase;
        newOrderGasBase = _newOrderGasBase;
        emit GasBaseUpdated(_simpleGasBase, _newOrderGasBase);
    }

    function updateCallbackGasLimit(uint256 _callbackGasLimit) external onlyOperator {
        require(_callbackGasLimit <= simpleGasBase + newOrderGasBase, "400");
        callbackGasLimit = _callbackGasLimit;
        emit CallbackGasLimitUpdated(_callbackGasLimit);
    }

    //return price with token's GMX price precision
    function getPriceFeedPrice() public view returns (uint256) {
        IPriceFeed priceFeed = IPriceFeed(DATASTORE.getAddress(ETH_PRICE_FEED_KEY));

        (
            /* uint80 roundID */
            ,
            int256 _price,
            /* uint256 startedAt */
            ,
            /* uint256 updatedAt */
            ,
            /* uint80 answeredInRound */
        ) = priceFeed.latestRoundData();

        require(_price > 0, "500P");

        return uint256(_price) * getPriceFeedMultiplier() / FLOAT_PRECISION;
    }

    // @dev get the multiplier value to convert the external price feed price to the price of 1 unit of the token
    // represented with 30 decimals
    // for example, if USDC has 6 decimals and a price of 1 USD, one unit of USDC would have a price of
    // 1 / (10 ^ 6) * (10 ^ 30) => 1 * (10 ^ 24)
    // if the external price feed has 8 decimals, the price feed price would be 1 * (10 ^ 8)
    // in this case the priceFeedMultiplier should be 10 ^ 46
    // the conversion of the price feed price would be 1 * (10 ^ 8) * (10 ^ 46) / (10 ^ 30) => 1 * (10 ^ 24)
    // formula for decimals for price feed multiplier: 60 - (external price feed decimals) - (token decimals)
    //
    // @param dataStore DataStore
    // @param token the token to get the price feed multiplier for
    // @return the price feed multipler
    function getPriceFeedMultiplier() public view returns (uint256) {
        uint256 multiplier = DATASTORE.getUint(ETH_MULTIPLIER_KEY);
        require(multiplier > 0, "500");
        return multiplier;
    }

    function updateEthPriceMultiplier() external {
        IPriceFeed priceFeed = IPriceFeed(DATASTORE.getAddress(ETH_PRICE_FEED_KEY));
        ethPriceMultiplier = (10 ** uint256(priceFeed.decimals())) * getPriceFeedMultiplier() / (10 ** 30);
    }

    function setReferralCode(address smartAccount) public returns (bool isSuccess) {
        return IModuleManager(smartAccount).execTransactionFromModule(
            REFERRALSTORAGE, 0, SETREFERRALCODECALLDATA, Enum.Operation.Call
        );
    }

    // @dev called after an order execution
    // @param key the key of the order
    // @param order the order that was executed
    function afterOrderExecution(bytes32 key, Order.Props memory order, EventUtils.EventLogData memory eventData)
        external
        onlyOrderHandler
    {
        ProfitTakeParam storage ptp = orderCollateral[key];
        if (ptp.operator == address(0)) {
            //not a Tradao order
            return;
        }

        if (postExecutionHandler != address(0)) {
            IPostExecutionHandler(postExecutionHandler).handleOrder(key, order);
        }

        address followee = ptp.followee;
        if (followee == address(0) || !BaseOrderUtils.isDecreaseOrder(order.numbers.orderType)) {
            //not a decrease order, no need to take profit.
            return;
        }

        uint256 prevCollateral = ptp.prevCollateral;
        if (prevCollateral == 0) {
            //exception
            emit TakeProfitFailed(order.addresses.account, key, Enum.TakeProfitFailureReason.PrevCollateralMissed);
            return;
        }
        delete orderCollateral[key];

        if (eventData.addressItems.items[0].value != USDC) {
            //exception
            emit TakeProfitFailed(order.addresses.account, key, Enum.TakeProfitFailureReason.InvalidCollateralToken);
            return;
        }

        uint256 outputAmount = eventData.uintItems.items[0].value;
        if (outputAmount < MIN_PROFIT_TAKE_BASE) {
            //do not take profit if output is too small.
            emit TakeProfitFailed(order.addresses.account, key, Enum.TakeProfitFailureReason.ProfitTooSmall);
            return;
        }

        uint256 curCollateral = getCollateral(order.addresses.account, order.addresses.market, USDC, order.flags.isLong);
        if (curCollateral >= prevCollateral) {
            //exception, the realized pnl will be transfered to user's account
            emit TakeProfitFailed(order.addresses.account, key, Enum.TakeProfitFailureReason.CollateralAmountInversed);
            return;
        }

        uint256 collateralDelta = prevCollateral - curCollateral;
        if (outputAmount < collateralDelta + MIN_PROFIT_TAKE_BASE) {
            //do not take profit if it's loss or profit is too small.
            emit TakeProfitFailed(order.addresses.account, key, Enum.TakeProfitFailureReason.ProfitTooSmall);
            return;
        }

        //take profit
        //get profitTakeRatio, can't greater than MAX_PROFIT_TAKE_RATIO
        uint256 profitTakeRatio = PROFIT_SHARE.getProfitTakeRatio(
            order.addresses.account, order.addresses.market, outputAmount - collateralDelta, followee
        );
        if (profitTakeRatio == 0) {
            return;
        } else if (profitTakeRatio > MAX_PROFIT_TAKE_RATIO) {
            profitTakeRatio = MAX_PROFIT_TAKE_RATIO;
        }

        uint256 profitTaken = (outputAmount - collateralDelta) * profitTakeRatio / 10000;
        if (_aaTransferUsdc(order.addresses.account, profitTaken, address(PROFIT_SHARE))) {
            PROFIT_SHARE.distributeProfit(order.addresses.account, order.addresses.market, followee);
            emit TakeProfitSuccess(order.addresses.account, key, profitTaken, address(PROFIT_SHARE));
        } else {
            emit TakeProfitFailed(order.addresses.account, key, Enum.TakeProfitFailureReason.TransferError);
        }
    }

    // @dev called after an order cancellation
    // @param key the key of the order
    // @param order the order that was cancelled
    function afterOrderCancellation(bytes32 key, Order.Props memory order, EventUtils.EventLogData memory)
        external
        onlyOrderHandler
    {
        ProfitTakeParam storage ptp = orderCollateral[key];
        if (ptp.prevCollateral > 0) {
            emit TakeProfitFailed(order.addresses.account, key, Enum.TakeProfitFailureReason.Canceled);
        }
        delete orderCollateral[key];
    }

    // @dev called after an order has been frozen, see OrderUtils.freezeOrder in OrderHandler for more info
    // @param key the key of the order
    // @param order the order that was frozen
    function afterOrderFrozen(bytes32 key, Order.Props memory order, EventUtils.EventLogData memory)
        external
        onlyOrderHandler
    {
        ProfitTakeParam storage ptp = orderCollateral[key];
        if (ptp.prevCollateral > 0) {
            emit TakeProfitFailed(order.addresses.account, key, Enum.TakeProfitFailureReason.Frozen);
        }
        delete orderCollateral[key];
    }

    // @dev get the key for a position, then get the collateral of the position
    // @param account the position's account
    // @param market the position's market
    // @param collateralToken the position's collateralToken
    // @param isLong whether the position is long or short
    // @return the collateral amount amplified in collateral token decimals.
    function getCollateral(address account, address market, address collateralToken, bool isLong)
        internal
        view
        returns (uint256)
    {
        bytes32 key = keccak256(abi.encode(account, market, collateralToken, isLong));
        return DATASTORE.getUint(keccak256(abi.encode(key, COLLATERAL_AMOUNT)));
    }

    function withdraw(address aa, address[] calldata tokenAddresses, uint256[] calldata amounts) external {
        require(tokenAddresses.length == amounts.length, "400");
        require(msg.sender == IEcdsaOwnershipRegistryModule(DEFAULT_ECDSA_OWNERSHIP_MODULE).getOwner(aa), "403");

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            if (amounts[i] == 0) {
                continue;
            }

            if (tokenAddresses[i] == address(0)) {
                // This is an ETH transfer
                require(aa.balance >= amounts[i], "400A");
                IModuleManager(aa).execTransactionFromModule(msg.sender, amounts[i], "", Enum.Operation.Call);
            } else {
                // This is an ERC20 token transfer
                require(IERC20(tokenAddresses[i]).balanceOf(aa) >= amounts[i], "400B");
                bytes memory data = abi.encodeWithSelector(IERC20.transfer.selector, msg.sender, amounts[i]);
                IModuleManager(aa).execTransactionFromModule(tokenAddresses[i], 0, data, Enum.Operation.Call);
            }
        }
    }

    function claimFundingFees(address aa, address[] calldata tokens, address[] calldata markets) external {
        require(markets.length == tokens.length, "400");
        require(msg.sender == IEcdsaOwnershipRegistryModule(DEFAULT_ECDSA_OWNERSHIP_MODULE).getOwner(aa), "403");

        bytes memory data =
            abi.encodeWithSelector(IExchangeRouter.claimFundingFees.selector, markets, tokens, msg.sender);
        IModuleManager(aa).execTransactionFromModule(address(EXCHANGE_ROUTER), 0, data, Enum.Operation.Call);
    }

    function claimCollateral(
        address aa,
        address[] calldata tokens,
        address[] calldata markets,
        uint256[] calldata timeKeys
    ) external {
        require(markets.length == tokens.length && markets.length == timeKeys.length, "400");
        require(msg.sender == IEcdsaOwnershipRegistryModule(DEFAULT_ECDSA_OWNERSHIP_MODULE).getOwner(aa), "403");

        bytes memory data =
            abi.encodeWithSelector(IExchangeRouter.claimCollateral.selector, markets, tokens, timeKeys, msg.sender);
        IModuleManager(aa).execTransactionFromModule(address(EXCHANGE_ROUTER), 0, data, Enum.Operation.Call);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {ContextUpgradeable} from "./ContextUpgradeable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.20;

import {IERC1822Proxiable} from "@openzeppelin/contracts/interfaces/draft-IERC1822.sol";
import {ERC1967Utils} from "./ERC1967Utils.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable __self = address(this);

    /**
     * @dev The version of the upgrade interface of the contract. If this getter is missing, both `upgradeTo(address)`
     * and `upgradeToAndCall(address,bytes)` are present, and `upgradeTo` must be used if no function should be called,
     * while `upgradeToAndCall` will invoke the `receive` function if the second argument is the empty byte string.
     * If the getter returns `"5.0.0"`, only `upgradeToAndCall(address,bytes)` is present, and the second argument must
     * be the empty byte string if no function should be called, making it impossible to invoke the `receive` function
     * during an upgrade.
     */
    string public constant UPGRADE_INTERFACE_VERSION = "5.0.0";

    /**
     * @dev The call is from an unauthorized context.
     */
    error UUPSUnauthorizedCallContext();

    /**
     * @dev The storage `slot` is unsupported as a UUID.
     */
    error UUPSUnsupportedProxiableUUID(bytes32 slot);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        _checkProxy();
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        _checkNotDelegated();
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual notDelegated returns (bytes32) {
        return ERC1967Utils.IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     *
     * @custom:oz-upgrades-unsafe-allow-reachable delegatecall
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) public payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data);
    }

    /**
     * @dev Reverts if the execution is not performed via delegatecall or the execution
     * context is not of a proxy with an ERC1967-compliant implementation pointing to self.
     * See {_onlyProxy}.
     */
    function _checkProxy() internal view virtual {
        if (
            address(this) == __self // Must be called through delegatecall
                || ERC1967Utils.getImplementation() != __self // Must be called through an active proxy
        ) {
            revert UUPSUnauthorizedCallContext();
        }
    }

    /**
     * @dev Reverts if the execution is performed via delegatecall.
     * See {notDelegated}.
     */
    function _checkNotDelegated() internal view virtual {
        if (address(this) != __self) {
            // Must not be called through delegatecall
            revert UUPSUnauthorizedCallContext();
        }
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev Performs an implementation upgrade with a security check for UUPS proxies, and additional setup call.
     *
     * As a security check, {proxiableUUID} is invoked in the new implementation, and the return value
     * is expected to be the implementation slot in ERC1967.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function _upgradeToAndCallUUPS(address newImplementation, bytes memory data) private {
        try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
            if (slot != ERC1967Utils.IMPLEMENTATION_SLOT) {
                revert UUPSUnsupportedProxiableUUID(slot);
            }
            ERC1967Utils.upgradeToAndCall(newImplementation, data);
        } catch {
            // The implementation is not UUPS
            revert ERC1967Utils.ERC1967InvalidImplementation(newImplementation);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./Order.sol";

// @title Order
// @dev Library for common order functions used in OrderUtils, IncreaseOrderUtils
// DecreaseOrderUtils, SwapOrderUtils
library BaseOrderUtils {
    // @dev CreateOrderParams struct used in createOrder to avoid stack
    // too deep errors
    //
    // @param addresses address values
    // @param numbers number values
    // @param orderType for order.orderType
    // @param decreasePositionSwapType for order.decreasePositionSwapType
    // @param isLong for order.isLong
    // @param shouldUnwrapNativeToken for order.shouldUnwrapNativeToken
    struct CreateOrderParams {
        CreateOrderParamsAddresses addresses;
        CreateOrderParamsNumbers numbers;
        Order.OrderType orderType;
        Order.DecreasePositionSwapType decreasePositionSwapType;
        bool isLong;
        bool shouldUnwrapNativeToken;
        bool autoCancel;
        bytes32 referralCode;
    }

    // @param receiver for order.receiver
    // @param callbackContract for order.callbackContract
    // @param market for order.market
    // @param initialCollateralToken for order.initialCollateralToken
    // @param swapPath for order.swapPath
    struct CreateOrderParamsAddresses {
        address receiver;
        address cancellationReceiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    // @param sizeDeltaUsd for order.sizeDeltaUsd
    // @param triggerPrice for order.triggerPrice
    // @param acceptablePrice for order.acceptablePrice
    // @param executionFee for order.executionFee
    // @param callbackGasLimit for order.callbackGasLimit
    // @param minOutputAmount for order.minOutputAmount
    struct CreateOrderParamsNumbers {
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
    }

    // @dev check if an orderType is an increase order
    // @param orderType the order type
    // @return whether an orderType is an increase order
    function isIncreaseOrder(Order.OrderType orderType) internal pure returns (bool) {
        return orderType == Order.OrderType.MarketIncrease || orderType == Order.OrderType.LimitIncrease;
    }

    // @dev check if an orderType is a decrease order
    // @param orderType the order type
    // @return whether an orderType is a decrease order
    function isDecreaseOrder(Order.OrderType orderType) internal pure returns (bool) {
        return orderType == Order.OrderType.MarketDecrease || orderType == Order.OrderType.LimitDecrease
            || orderType == Order.OrderType.StopLossDecrease || orderType == Order.OrderType.Liquidation;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// @title DataStore
// @dev DataStore for all general state values
interface IDataStore {
    // @dev get the uint value for the given key
    // @param key the key of the value
    // @return the uint value for the key
    function getUint(bytes32 key) external view returns (uint256);

    // @dev get the int value for the given key
    // @param key the key of the value
    // @return the int value for the key
    function getInt(bytes32 key) external view returns (int256);

    // @dev get the address value for the given key
    // @param key the key of the value
    // @return the address value for the key
    function getAddress(bytes32 key) external view returns (address);

    // @dev get the bool value for the given key
    // @param key the key of the value
    // @return the bool value for the key
    function getBool(bytes32 key) external view returns (bool);

    // @dev get the string value for the given key
    // @param key the key of the value
    // @return the string value for the key
    function getString(bytes32 key) external view returns (string memory);

    // @dev get the bytes32 value for the given key
    // @param key the key of the value
    // @return the bytes32 value for the key
    function getBytes32(bytes32 key) external view returns (bytes32);

    // @dev get the uint array for the given key
    // @param key the key of the uint array
    // @return the uint array for the key
    function getUintArray(bytes32 key) external view returns (uint256[] memory);

    // @dev get the int array for the given key
    // @param key the key of the int array
    // @return the int array for the key
    function getIntArray(bytes32 key) external view returns (int256[] memory);

    // @dev get the address array for the given key
    // @param key the key of the address array
    // @return the address array for the key
    function getAddressArray(bytes32 key) external view returns (address[] memory);

    // @dev get the bool array for the given key
    // @param key the key of the bool array
    // @return the bool array for the key
    function getBoolArray(bytes32 key) external view returns (bool[] memory);

    // @dev get the string array for the given key
    // @param key the key of the string array
    // @return the string array for the key
    function getStringArray(bytes32 key) external view returns (string[] memory);

    // @dev get the bytes32 array for the given key
    // @param key the key of the bytes32 array
    // @return the bytes32 array for the key
    function getBytes32Array(bytes32 key) external view returns (bytes32[] memory);

    // @dev check whether the given value exists in the set
    // @param setKey the key of the set
    // @param value the value to check
    function containsBytes32(bytes32 setKey, bytes32 value) external view returns (bool);

    // @dev get the length of the set
    // @param setKey the key of the set
    function getBytes32Count(bytes32 setKey) external view returns (uint256);

    // @dev get the values of the set in the given range
    // @param setKey the key of the set
    // @param the start of the range, values at the start index will be returned
    // in the result
    // @param the end of the range, values at the end index will not be returned
    // in the result
    function getBytes32ValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (bytes32[] memory);

    // @dev check whether the given value exists in the set
    // @param setKey the key of the set
    // @param value the value to check
    function containsAddress(bytes32 setKey, address value) external view returns (bool);

    // @dev get the length of the set
    // @param setKey the key of the set
    function getAddressCount(bytes32 setKey) external view returns (uint256);

    // @dev get the values of the set in the given range
    // @param setKey the key of the set
    // @param the start of the range, values at the start index will be returned
    // in the result
    // @param the end of the range, values at the end index will not be returned
    // in the result
    function getAddressValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (address[] memory);

    // @dev check whether the given value exists in the set
    // @param setKey the key of the set
    // @param value the value to check
    function containsUint(bytes32 setKey, uint256 value) external view returns (bool);

    // @dev get the length of the set
    // @param setKey the key of the set
    function getUintCount(bytes32 setKey) external view returns (uint256);

    // @dev get the values of the set in the given range
    // @param setKey the key of the set
    // @param the start of the range, values at the start index will be returned
    // in the result
    // @param the end of the range, values at the end index will not be returned
    // in the result
    function getUintValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// @title Keys
// @dev Keys for values in the DataStore
library Keys {
    // @dev key for the base gas limit used when estimating execution fee
    bytes32 internal constant ESTIMATED_GAS_FEE_BASE_AMOUNT =
        keccak256(abi.encode("ESTIMATED_GAS_FEE_BASE_AMOUNT_V2_1"));
    // @dev key for the multiplier used when estimating execution fee
    bytes32 internal constant ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR =
        keccak256(abi.encode("ESTIMATED_GAS_FEE_MULTIPLIER_FACTOR"));
    // @dev key for the gas limit used for each oracle price when estimating execution fee
    bytes32 internal constant ESTIMATED_GAS_FEE_PER_ORACLE_PRICE =
        keccak256(abi.encode("ESTIMATED_GAS_FEE_PER_ORACLE_PRICE"));

    // @dev key for the estimated gas limit for increase orders
    bytes32 internal constant INCREASE_ORDER_GAS_LIMIT = keccak256(abi.encode("INCREASE_ORDER_GAS_LIMIT"));
    // @dev key for the estimated gas limit for decrease orders
    bytes32 internal constant DECREASE_ORDER_GAS_LIMIT = keccak256(abi.encode("DECREASE_ORDER_GAS_LIMIT"));

    // @dev key for the estimated gas limit for single swaps
    bytes32 internal constant SINGLE_SWAP_GAS_LIMIT = keccak256(abi.encode("SINGLE_SWAP_GAS_LIMIT"));

    // @dev key for the multiplier used when calculating execution fee
    bytes32 internal constant EXECUTION_GAS_FEE_MULTIPLIER_FACTOR =
        keccak256(abi.encode("EXECUTION_GAS_FEE_MULTIPLIER_FACTOR"));
    // @dev key for the base gas limit used when calculating execution fee
    bytes32 internal constant EXECUTION_GAS_FEE_BASE_AMOUNT =
        keccak256(abi.encode("EXECUTION_GAS_FEE_BASE_AMOUNT_V2_1"));

    // bytes32 internal constant SWAP_ORDER_GAS_LIMIT = keccak256(abi.encode("SWAP_ORDER_GAS_LIMIT"));
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// @title IPriceFeed
// @dev Interface for a price feed
interface IPriceFeed {
    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.20;

/// @title Enum - Collection of enums
abstract contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }

    enum OrderFailureReason {
        PayExecutionFeeFailed,
        TransferCollateralToVaultFailed,
        CreateOrderFailed
    }

    enum TakeProfitFailureReason {
        Canceled,
        PrevCollateralMissed,
        InvalidCollateralToken,
        CollateralAmountInversed,
        TransferError,
        ProfitTooSmall,
        Frozen
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.20;

import {Enum} from "./Enum.sol";

/**
 *   @title Fallback Manager - A contract that manages fallback calls made to the Smart Account
 *   @dev Fallback calls are handled by a `handler` contract that is stored at FALLBACK_HANDLER_STORAGE_SLOT
 *        fallback calls are not delegated to the `handler` so they can not directly change Smart Account storage
 */
interface IModuleManager {
    /**
     * @dev Setups module for this Smart Account and enables it.
     * @notice This SHOULD only be done via userOp or a selfcall.
     * @notice Enables the module `module` for the wallet.
     */
    function setupAndEnableModule(address setupContract, bytes memory setupData) external returns (address);

    function execTransactionFromModule(address to, uint256 value, bytes memory data, Enum.Operation operation)
        external
        returns (bool);

    function execTransactionFromModuleReturnData(address to, uint256 value, bytes memory data, Enum.Operation operation)
        external
        returns (bool success, bytes memory returnData);

    /**
     * @dev Allows a Module to execute a batch of Smart Account transactions without any further confirmations.
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operations Operation type of module transaction.
     */
    function execBatchTransactionFromModule(
        address[] calldata to,
        uint256[] calldata value,
        bytes[] calldata data,
        Enum.Operation[] calldata operations
    ) external returns (bool success);

    /**
     * @dev Returns if a module is enabled
     * @return True if the module is enabled
     */
    function isModuleEnabled(address module) external view returns (bool);

    /**
     * @dev Adds a module to the allowlist.
     * @notice This SHOULD only be done via userOp or a selfcall.
     */
    function enableModule(address module) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.20;

/**
 * @title Smart Account Factory - factory responsible for deploying Smart Accounts using CREATE2 and CREATE
 * @dev It deploys Smart Accounts as proxies pointing to `basicImplementation` that is immutable.
 *      This allows keeping the same address for the same Smart Account owner on various chains via CREATE2
 * @author Chirag Titiya - <[email protected]>
 */
interface ISmartAccountFactory {
    /**
     * @notice Deploys account using create2 and points it to basicImplementation
     * @param moduleSetupContract address of the module setup contract
     * @param moduleSetupData data for module setup contract
     * @param index extra salt that allows to deploy more account if needed for same EOA (default 0)
     * @return proxy address of the deployed account
     */
    function deployCounterFactualAccount(address moduleSetupContract, bytes calldata moduleSetupData, uint256 index)
        external
        returns (address proxy);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

/**
 * @title IWNT
 * @dev Interface for Wrapped Native Tokens, e.g. WETH
 * The contract is named WNT instead of WETH for a more general reference name
 * that can be used on any blockchain
 */
interface IWNT {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function depositTo(address account) external payable;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./BaseOrderUtils.sol";

interface IExchangeRouter {
    function createOrder(BaseOrderUtils.CreateOrderParams calldata params) external payable returns (bytes32);
    function cancelOrder(bytes32 key) external payable;
    function claimFundingFees(address[] memory markets, address[] memory tokens, address receiver)
        external
        payable
        returns (uint256[] memory);
    function claimCollateral(
        address[] memory markets,
        address[] memory tokens,
        uint256[] memory timeKeys,
        address receiver
    ) external payable returns (uint256[] memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

interface IReferrals {
    event ReferralUpdated(address indexed aa, address indexed referral);

    function getReferrer(address aa) external view returns (address);

    function setReferrerFromModule(address _aa, address _referrer) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

import "./EventUtils.sol";
import "./Order.sol";

// @title IOrderCallbackReceiver
// @dev interface for an order callback contract
interface IOrderCallbackReceiver {
    // @dev called after an order execution
    // @param key the key of the order
    // @param order the order that was executed
    function afterOrderExecution(bytes32 key, Order.Props memory order, EventUtils.EventLogData memory eventData)
        external;

    // @dev called after an order cancellation
    // @param key the key of the order
    // @param order the order that was cancelled
    function afterOrderCancellation(bytes32 key, Order.Props memory order, EventUtils.EventLogData memory eventData)
        external;

    // @dev called after an order has been frozen, see OrderUtils.freezeOrder in OrderHandler for more info
    // @param key the key of the order
    // @param order the order that was frozen
    function afterOrderFrozen(bytes32 key, Order.Props memory order, EventUtils.EventLogData memory eventData)
        external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

interface IProfitShare {
    //return profit take ratio, factor: 10000
    function getProfitTakeRatio(address account, address market, uint256 profit, address followee)
        external
        view
        returns (uint256);
    function distributeProfit(address account, address market, address followee) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

interface IBiconomyModuleSetup {
    function getModuleAddress() external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.20;

interface IEcdsaOwnershipRegistryModule {
    /**
     * @dev Returns the owner of the Smart Account. Reverts for Smart Accounts without owners.
     * @param smartAccount Smart Account address.
     * @return owner The owner of the Smart Account.
     */
    function getOwner(address smartAccount) external view returns (address);
}

pragma solidity ^0.8.20;

import "./Order.sol";

interface IPostExecutionHandler {
    function handleOrder(bytes32 key, Order.Props memory order) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {}

    function __Context_init_unchained() internal onlyInitializing {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.20;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/ERC1967/ERC1967Utils.sol)

pragma solidity ^0.8.20;

import {Address} from "./Address.sol";
import {StorageSlot} from "./StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 */
library ERC1967Utils {
    // We re-declare ERC-1967 events here because they can't be used directly from IERC1967.
    // This will be fixed in Solidity 0.8.21. At that point we should remove these events.
    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1.
     */
    // solhint-disable-next-line private-vars-leading-underscore
    bytes32 internal constant IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev The `implementation` of the proxy is invalid.
     */
    error ERC1967InvalidImplementation(address implementation);

    /**
     * @dev An upgrade function sees `msg.value > 0` that may be lost.
     */
    error ERC1967NonPayable();

    /**
     * @dev Returns the current implementation address.
     */
    function getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        if (newImplementation.code.length == 0) {
            revert ERC1967InvalidImplementation(newImplementation);
        }
        StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Performs implementation upgrade with additional setup call if data is nonempty.
     * This function is payable only if the setup call is performed, otherwise `msg.value` is rejected
     * to avoid stuck value in the contract.
     *
     * Emits an {IERC1967-Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);

        if (data.length > 0) {
            Address.functionDelegateCall(newImplementation, data);
        } else {
            _checkNonPayable();
        }
    }

    /**
     * @dev Reverts if `msg.value` is not zero. It can be used to avoid `msg.value` stuck in the contract
     * if an upgrade doesn't perform an initialization call.
     */
    function _checkNonPayable() private {
        if (msg.value > 0) {
            revert ERC1967NonPayable();
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

// @title Order
// @dev Struct for orders
library Order {
    enum OrderType
    // @dev MarketSwap: swap token A to token B at the current market price
    // the order will be cancelled if the minOutputAmount cannot be fulfilled
    {
        MarketSwap,
        // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
        LimitSwap,
        // @dev MarketIncrease: increase position at the current market price
        // the order will be cancelled if the position cannot be increased at the acceptablePrice
        MarketIncrease,
        // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitIncrease,
        // @dev MarketDecrease: decrease position at the current market price
        // the order will be cancelled if the position cannot be decreased at the acceptablePrice
        MarketDecrease,
        // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitDecrease,
        // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        StopLossDecrease,
        // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
        Liquidation
    }

    enum DecreasePositionSwapType {
        NoSwap,
        SwapPnlTokenToCollateralToken,
        SwapCollateralTokenToPnlToken
    }

    // @dev there is a limit on the number of fields a struct can have when being passed
    // or returned as a memory variable which can cause "Stack too deep" errors
    // use sub-structs to avoid this issue
    // @param addresses address values
    // @param numbers number values
    // @param flags boolean values
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    // @param account the account of the order
    // @param receiver the receiver for any token transfers
    // this field is meant to allow the output of an order to be
    // received by an address that is different from the creator of the
    // order whether this is for swaps or whether the account is the owner
    // of a position
    // for funding fees and claimable collateral, the funds are still
    // credited to the owner of the position indicated by order.account
    // @param callbackContract the contract to call for callbacks
    // @param uiFeeReceiver the ui fee receiver
    // @param market the trading market
    // @param initialCollateralToken for increase orders, initialCollateralToken
    // is the token sent in by the user, the token will be swapped through the
    // specified swapPath, before being deposited into the position as collateral
    // for decrease orders, initialCollateralToken is the collateral token of the position
    // withdrawn collateral from the decrease of the position will be swapped
    // through the specified swapPath
    // for swaps, initialCollateralToken is the initial token sent for the swap
    // @param swapPath an array of market addresses to swap through
    struct Addresses {
        address account;
        address receiver;
        address cancellationReceiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    // @param sizeDeltaUsd the requested change in position size
    // @param initialCollateralDeltaAmount for increase orders, initialCollateralDeltaAmount
    // is the amount of the initialCollateralToken sent in by the user
    // for decrease orders, initialCollateralDeltaAmount is the amount of the position's
    // collateralToken to withdraw
    // for swaps, initialCollateralDeltaAmount is the amount of initialCollateralToken sent
    // in for the swap
    // @param orderType the order type
    // @param triggerPrice the trigger price for non-market orders
    // @param acceptablePrice the acceptable execution price for increase / decrease orders
    // @param executionFee the execution fee for keepers
    // @param callbackGasLimit the gas limit for the callbackContract
    // @param minOutputAmount the minimum output amount for decrease orders and swaps
    // note that for decrease orders, multiple tokens could be received, for this reason, the
    // minOutputAmount value is treated as a USD value for validation in decrease orders
    // @param updatedAtBlock the block at which the order was last updated
    struct Numbers {
        OrderType orderType;
        DecreasePositionSwapType decreasePositionSwapType;
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
        uint256 updatedAtBlock;
        uint256 updatedAtTime;
    }

    // @param isLong whether the order is for a long or short
    // @param shouldUnwrapNativeToken whether to unwrap native tokens before
    // transferring to the user
    // @param isFrozen whether the order is frozen
    struct Flags {
        bool isLong;
        bool shouldUnwrapNativeToken;
        bool isFrozen;
        bool autoCancel;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.0;

library EventUtils {
    struct EventLogData {
        AddressItems addressItems;
        UintItems uintItems;
        IntItems intItems;
        BoolItems boolItems;
        Bytes32Items bytes32Items;
        BytesItems bytesItems;
        StringItems stringItems;
    }

    struct AddressItems {
        AddressKeyValue[] items;
        AddressArrayKeyValue[] arrayItems;
    }

    struct UintItems {
        UintKeyValue[] items;
        UintArrayKeyValue[] arrayItems;
    }

    struct IntItems {
        IntKeyValue[] items;
        IntArrayKeyValue[] arrayItems;
    }

    struct BoolItems {
        BoolKeyValue[] items;
        BoolArrayKeyValue[] arrayItems;
    }

    struct Bytes32Items {
        Bytes32KeyValue[] items;
        Bytes32ArrayKeyValue[] arrayItems;
    }

    struct BytesItems {
        BytesKeyValue[] items;
        BytesArrayKeyValue[] arrayItems;
    }

    struct StringItems {
        StringKeyValue[] items;
        StringArrayKeyValue[] arrayItems;
    }

    struct AddressKeyValue {
        string key;
        address value;
    }

    struct AddressArrayKeyValue {
        string key;
        address[] value;
    }

    struct UintKeyValue {
        string key;
        uint256 value;
    }

    struct UintArrayKeyValue {
        string key;
        uint256[] value;
    }

    struct IntKeyValue {
        string key;
        int256 value;
    }

    struct IntArrayKeyValue {
        string key;
        int256[] value;
    }

    struct BoolKeyValue {
        string key;
        bool value;
    }

    struct BoolArrayKeyValue {
        string key;
        bool[] value;
    }

    struct Bytes32KeyValue {
        string key;
        bytes32 value;
    }

    struct Bytes32ArrayKeyValue {
        string key;
        bytes32[] value;
    }

    struct BytesKeyValue {
        string key;
        bytes value;
    }

    struct BytesArrayKeyValue {
        string key;
        bytes[] value;
    }

    struct StringKeyValue {
        string key;
        string value;
    }

    struct StringArrayKeyValue {
        string key;
        string[] value;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(address target, bool success, bytes memory returndata)
        internal
        view
        returns (bytes memory)
    {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/StorageSlot.sol)
// This file was procedurally generated from scripts/generate/templates/StorageSlot.js.

pragma solidity ^0.8.20;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```solidity
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(newImplementation.code.length > 0);
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}