// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Commands} from "src/libraries/Commands.sol";
import {Errors} from "src/libraries/Errors.sol";
import {PerpTradeStorage} from "src/PerpTrade/PerpTradeStorage.sol";
import {IAccount} from "src/q/interfaces/IAccount.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IGmxOrderBook} from "src/protocols/gmx/interfaces/IGmxOrderBook.sol";
import {IGmxReader} from "src/protocols/gmx/interfaces/IGmxReader.sol";
import {IGmxVault} from "src/protocols/gmx/interfaces/IGmxVault.sol";
import {ICapOrders} from "src/protocols/cap/interfaces/ICapOrders.sol";
import {IMarketStore} from "src/protocols/cap/interfaces/IMarketStore.sol";
import {IOperator} from "src/storage/interfaces/IOperator.sol";

contract PerpTradeArbi is PerpTradeStorage {
    /*//////////////////////////////////////////////////////////////
                             CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _operator) PerpTradeStorage(_operator) {}

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice execute the type of trade
    /// @dev can only be called by `Q` or `Vault`
    /// @param command the command of the ddex protocol from `Commands` library
    /// @param data encoded data of parameters depending on the ddex
    /// @param isOpen bool to check if the trade is an increase or a decrease trade
    function execute(uint256 command, bytes calldata data, bool isOpen) external payable onlyQorVault {
        if (command == Commands.CAP) {
            _cap(data, isOpen);
        } else if (command == Commands.GMX) {
            _gmx(data, isOpen);
        } else if (command == Commands.CROSS_CHAIN) {
            _crossChain(data);
        } else if (command == Commands.MODIFY_ORDER) {
            _modifyOrder(data, isOpen);
        } else if (command == Commands.CLAIM_REWARDS) {
            _claimRewards(data);
        } else {
            revert Errors.CommandMisMatch();
        }
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function _cap(bytes memory data, bool isOpen) internal {
        // decode the data
        (address account,, ICapOrders.Order memory order, uint256 tpPrice, uint256 slPrice) =
            abi.decode(data, (address, uint96, ICapOrders.Order, uint256, uint256));

        if (account == address(0)) revert Errors.ZeroAddress();
        order.asset = IOperator(operator).getAddress("DEFAULTSTABLECOIN");

        // calculate the approval amount and approve the token
        if (isOpen) {
            bytes memory tokenApprovalData =
                abi.encodeWithSignature("approve(address,uint256)", FUND_STORE, order.margin);
            IAccount(account).execute(order.asset, tokenApprovalData, 0);

            IMarketStore.Market memory market = IMarketStore(MARKET_STORE).get(order.market);
            uint256 fee = (order.size * market.fee) / BPS_DIVIDER;
            order.margin -= fee;
        }
        // Make the execute from account
        bytes memory tradeData = abi.encodeCall(ICapOrders.submitOrder, (order, tpPrice, slPrice));
        IAccount(account).execute(ORDERS, tradeData, 0);
    }

    function _gmx(bytes calldata data, bool isOpen) internal {
        if (isOpen) {
            (
                address account,
                uint96 amount,
                uint32 leverage,
                address tradeToken,
                bool tradeDirection,
                bool isLimit,
                int256 triggerPrice,
                bool needApproval,
                bytes32 referralCode
            ) = abi.decode(data, (address, uint96, uint32, address, bool, bool, int256, bool, bytes32));
            address depositToken = IOperator(operator).getAddress("DEFAULTSTABLECOIN");
            if (account == address(0)) revert Errors.ZeroAddress();
            if (triggerPrice < 1) revert Errors.ZeroAmount();
            if (leverage < 1) revert Errors.ZeroAmount();

            if (IERC20(depositToken).balanceOf(account) < amount) revert Errors.BalanceLessThanAmount();
            {
                bytes memory tokenApprovalData =
                    abi.encodeWithSignature("approve(address,uint256)", getGmxRouter(), amount);
                IAccount(account).execute(depositToken, tokenApprovalData, 0);
            }

            if (needApproval) {
                address adapter = getGmxRouter();
                bytes memory pluginApprovalData;
                pluginApprovalData = abi.encodeWithSignature("approvePlugin(address)", getGmxOrderBook());
                IAccount(account).execute(adapter, pluginApprovalData, 0);
                pluginApprovalData = abi.encodeWithSignature("approvePlugin(address)", getGmxPositionRouter());
                IAccount(account).execute(adapter, pluginApprovalData, 0);
            }

            uint256 fee = getGmxFee();
            if (isLimit) {
                bytes memory tradeData = abi.encodeWithSignature(
                    "createIncreaseOrder(address[],uint256,address,uint256,uint256,address,bool,uint256,bool,uint256,bool)",
                    getPath(false, tradeDirection, depositToken, tradeToken),
                    amount,
                    tradeToken,
                    0,
                    uint256(leverage * amount) * 1e18,
                    tradeDirection ? tradeToken : depositToken,
                    tradeDirection,
                    uint256(triggerPrice) * 1e22,
                    !tradeDirection,
                    fee,
                    false
                );
                IAccount(account).execute{value: fee}(getGmxOrderBook(), tradeData, fee);
            } else {
                bytes memory tradeData = abi.encodeWithSignature(
                    "createIncreasePosition(address[],address,uint256,uint256,uint256,bool,uint256,uint256,bytes32,address)",
                    getPath(false, tradeDirection, depositToken, tradeToken), // path in case theres a swap
                    tradeToken, // the asset for which the position needs to be opened
                    amount, // the collateral amount
                    0, // the min amount of tradeToken in case of long and usdc in case of short for swap
                    uint256(leverage * amount) * 1e18, // size including the leverage to open a position, in 1e30 units
                    tradeDirection, // direction of the execute, true - long, false - short
                    uint256(triggerPrice) * 1e22, // the price at which the manager wants to open a position, in 1e30 units
                    fee, // min execution fee, `Gmx.PositionRouter.minExecutionFee()`
                    referralCode, // referral code
                    address(0) // an optional callback contract, this contract will be called on request execution or cancellation
                );
                IAccount(account).execute{value: fee}(getGmxPositionRouter(), tradeData, fee);
            }
        } else {
            (
                address account,
                uint96 collateralDelta,
                address tradeToken,
                uint256 sizeDelta,
                bool tradeDirection,
                bool isLimit,
                int256 triggerPrice,
                bool triggerAboveThreshold
            ) = abi.decode(data, (address, uint96, address, uint256, bool, bool, int256, bool));
            address depositToken = IOperator(operator).getAddress("DEFAULTSTABLECOIN");
            if (account == address(0)) revert Errors.ZeroAddress();
            if (triggerPrice < 1) revert Errors.ZeroAmount();

            uint256 fee = getGmxFee();
            if (isLimit) {
                bytes memory tradeData = abi.encodeWithSignature(
                    "createDecreaseOrder(address,uint256,address,uint256,bool,uint256,bool)",
                    tradeToken, // the asset used for the position
                    sizeDelta, // size of the position, in 1e30 units
                    tradeDirection ? tradeToken : depositToken, // if long, then collateral is baseToken, if short then collateral usdc
                    collateralDelta, // the amount of collateral to withdraw
                    tradeDirection, // the direction of the exisiting position
                    uint256(triggerPrice) * 1e22, // the price at which the manager wants to close the position, in 1e30 units
                    // depends on whether its a take profit order or a stop loss order
                    // if tp, tradeDirection ? true : false
                    // if sl, tradeDirection ? false: true
                    triggerAboveThreshold
                );
                IAccount(account).execute{value: fee + 1}(getGmxOrderBook(), tradeData, fee + 1);
            } else {
                bytes memory tradeData = abi.encodeWithSignature(
                    "createDecreasePosition(address[],address,uint256,uint256,bool,address,uint256,uint256,uint256,bool,address)",
                    getPath(true, tradeDirection, depositToken, tradeToken), // path in case theres a swap
                    tradeToken, // the asset for which the position was opened
                    collateralDelta, // the amount of collateral to withdraw
                    sizeDelta, // the total size which has to be closed, in 1e30 units
                    tradeDirection, // the direction of the exisiting position
                    account, // address of the receiver after closing the position
                    uint256(triggerPrice) * 1e22, // the price at which the manager wants to close the position, in 1e30 units
                    0, // min output token amount
                    getGmxFee() + 1, // min execution fee = `Gmx.PositionRouter.minExecutionFee() + 1`
                    false, // _withdrawETH, true if the amount recieved should be in ETH
                    address(0) // an optional callback contract, this contract will be called on request execution or cancellation
                );
                IAccount(account).execute{value: fee + 1}(getGmxPositionRouter(), tradeData, fee + 1);
            }
        }
    }

    function _crossChain(bytes calldata data) internal {
        bytes memory lifiData;
        address account;
        address token;
        uint256 amount;

        (account, token, amount, lifiData) = abi.decode(data, (address, address, uint256, bytes));

        if (account == address(0)) revert Errors.ZeroAddress();
        if (token == address(0)) revert Errors.ZeroAddress();
        if (amount < 1) revert Errors.ZeroAmount();
        if (lifiData.length == 0) revert Errors.ExchangeDataMismatch();

        bytes memory tokenApprovalData = abi.encodeWithSignature("approve(address,uint256)", CROSS_CHAIN_ROUTER, amount);
        IAccount(account).execute(token, tokenApprovalData, 0);
        IAccount(account).execute{value: msg.value}(CROSS_CHAIN_ROUTER, lifiData, msg.value);
    }

    function _modifyOrder(bytes calldata data, bool isCancel) internal {
        (address account,, uint256 command, Order orderType, bytes memory orderData) =
            abi.decode(data, (address, uint256, uint256, Order, bytes));
        address adapter;
        address tradeToken; // purchase token (path[pat.lenfth - 1] while createIncreseOrder)
        uint256 executionFeeRefund;
        uint256 purchaseTokenAmount;
        bytes memory actionData;

        if (isCancel) {
            if (command == Commands.CAP) {
                if (orderType == Order.CANCEL_MULTIPLE) {
                    (uint256[] memory orderIDs) = abi.decode(orderData, (uint256[]));
                    actionData = abi.encodeWithSignature("cancelOrders(uint256[])", orderIDs);
                } else {
                    (uint256 orderId) = abi.decode(orderData, (uint256));
                    actionData = abi.encodeWithSignature("cancelOrder(uint256)", orderId);
                }
                adapter = ORDERS;
            } else if (command == Commands.GMX) {
                adapter = getGmxOrderBook();
                (uint256 orderIndex) = abi.decode(orderData, (uint256));
                if (orderType == Order.CANCEL_INCREASE) {
                    actionData = abi.encodeWithSignature("cancelIncreaseOrder(uint256)", orderIndex);
                    (tradeToken, purchaseTokenAmount,,,,,,, executionFeeRefund) =
                        IGmxOrderBook(adapter).getIncreaseOrder(account, orderIndex);
                } else if (orderType == Order.CANCEL_DECREASE) {
                    actionData = abi.encodeWithSignature("cancelDecreaseOrder(uint256)", orderIndex);
                } else if (orderType == Order.CANCEL_MULTIPLE) {
                    (uint256[] memory increaseOrderIndexes, uint256[] memory decreaseOrderIndexes) =
                        abi.decode(orderData, (uint256[], uint256[]));
                    actionData = abi.encodeWithSignature(
                        "cancelMultiple(uint256[],uint256[],uint256[])",
                        new uint[](0), // swapOrderIndexes,
                        increaseOrderIndexes,
                        decreaseOrderIndexes
                    );
                }
            } else {
                revert Errors.CommandMisMatch();
            }
        } else {
            if (command == Commands.CAP) {
                (uint256 cancelOrderId, bytes memory capOrderData) = abi.decode(orderData, (uint256, bytes));
                bytes memory cancelOrderData = abi.encodeWithSignature("cancelOrder(uint256)", cancelOrderId);
                IAccount(account).execute(ORDERS, cancelOrderData, 0);
                if (orderType == Order.UPDATE_INCREASE) {
                    _cap(capOrderData, true);
                } else if (orderType == Order.UPDATE_DECREASE) {
                    _cap(capOrderData, false);
                } else {
                    revert Errors.CommandMisMatch();
                }
            } else if (command == Commands.GMX) {
                if (orderType == Order.UPDATE_INCREASE) {
                    (uint256 _orderIndex, uint256 _sizeDelta, uint256 _triggerPrice, bool _triggerAboveThreshold) =
                        abi.decode(orderData, (uint256, uint256, uint256, bool));
                    actionData = abi.encodeWithSignature(
                        "updateIncreaseOrder(uint256,uint256,uint256,bool)",
                        _orderIndex,
                        _sizeDelta,
                        _triggerPrice,
                        _triggerAboveThreshold
                    );
                } else if (orderType == Order.UPDATE_DECREASE) {
                    (
                        uint256 _orderIndex,
                        uint256 _collateralDelta,
                        uint256 _sizeDelta,
                        uint256 _triggerPrice,
                        bool _triggerAboveThreshold
                    ) = abi.decode(orderData, (uint256, uint256, uint256, uint256, bool));
                    actionData = abi.encodeWithSignature(
                        "updateDecreaseOrder(uint256,uint256,uint256,uint256,bool)",
                        _orderIndex,
                        _collateralDelta,
                        _sizeDelta,
                        _triggerPrice,
                        _triggerAboveThreshold
                    );
                }
                adapter = getGmxOrderBook();
            } else {
                revert Errors.CommandMisMatch();
            }
        }
        // TODO check on updateIncrease order too
        if (actionData.length > 0) IAccount(account).execute(adapter, actionData, 0);

        address depositToken = IOperator(operator).getAddress("DEFAULTSTABLECOIN");
        if (tradeToken != depositToken && purchaseTokenAmount > 0) {
            // TODO discuss what to do on cancelMultiple increase orders?? loop or use multi execute ??
            address[] memory path = new address[](2);
            path[0] = tradeToken;
            path[1] = depositToken;

            // TODO check maxAmount In logic ??
            (uint256 minOut,) =
                IGmxReader(getGmxReader()).getAmountOut(IGmxVault(getGmxVault()), path[0], path[1], purchaseTokenAmount);

            // TODO revert if minOut == 0
            address router = getGmxRouter();
            address account = account;
            bytes memory tokenApprovalData =
                abi.encodeWithSignature("approve(address,uint256)", router, purchaseTokenAmount);
            IAccount(account).execute(tradeToken, tokenApprovalData, 0);
            bytes memory swapData = abi.encodeWithSignature(
                "swap(address[],uint256,uint256,address)",
                path,
                purchaseTokenAmount, // amountIn
                minOut,
                account //  receiver
            );
            IAccount(account).execute(router, swapData, 0);
        }
        if (executionFeeRefund > 0) {
            // TODO add error if fee refund and ETH balance are not same or do check on If line
            // if (account.balance != executionFeeRefund) revert Errors.BalanceLessThanAmount();
            address treasury = IOperator(operator).getAddress("TREASURY");
            IAccount(account).execute(treasury, "", executionFeeRefund);
        }
    }

    function _claimRewards(bytes calldata data) internal {
        (address account, uint256 command, bytes[] memory rewardData) = abi.decode(data, (address, uint256, bytes[]));
        address treasury = IOperator(operator).getAddress("TREASURY");
        address token;
        uint256 rewardAmount;

        if (command == Commands.CAP) {
            token = rewards.ARB;
            rewardAmount = IERC20(token).balanceOf(account);
            if (rewardData[0].length > 0) IAccount(account).execute(rewards.REWARDS, rewardData[0], 0);
            rewardAmount = IERC20(token).balanceOf(account) - rewardAmount;
        } else if (command == Commands.GMX) {
            token = IOperator(operator).getAddress("WRAPPEDTOKEN");
            rewardAmount = IERC20(token).balanceOf(account);
        } else {
            revert Errors.CommandMisMatch();
        }

        if (rewardAmount > 0) {
            IAccount(account).execute(
                token, abi.encodeWithSignature("transfer(address,uint256)", treasury, rewardAmount), 0
            );
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/// @title Commands similar to UniversalRouter
/// @notice Command Flags used to decode commands
/// @notice https://github.com/Uniswap/universal-router/blob/main/contracts/libraries/Commands.sol
library Commands {
    // Masks to extract certain bits of commands
    bytes1 internal constant FLAG_ALLOW_REVERT = 0x80;
    bytes1 internal constant COMMAND_TYPE_MASK = 0x3f;

    // Command Types. Maximum supported command at this moment is 0x3f.

    // Command Types where value >= 0x00, for Perpetuals
    uint256 constant GMX = 0x00;
    uint256 constant PERP = 0x01;
    uint256 constant CAP = 0x02;
    uint256 constant KWENTA = 0x03;
    // COMMAND_PLACEHOLDER = 0x04;
    // Future perpetual protocols can be added below

    // Command Types where value >= 0x10, for Spot
    uint256 constant UNI = 0x10;
    uint256 constant SUSHI = 0x11;
    uint256 constant ONE_INCH = 0x12;
    uint256 constant TRADER_JOE = 0x13;
    uint256 constant PANCAKE = 0x14;
    // COMMAND_PLACEHOLDER = 0x15;
    // Future spot protocols can be added below

    // Future financial services like options can be added with a value >= 0x20

    // Command Types where value >= 0x30, for trade functions
    uint256 constant CROSS_CHAIN = 0x30;
    uint256 constant MODIFY_ORDER = 0x31;
    uint256 constant CLAIM_REWARDS = 0x32;
    // COMMAND_PLACEHOLDER = 0x3d;
    // Future functions to interact with protocols can be added below
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

library Errors {
    // Zero Errors
    error ZeroAmount();
    error ZeroAddress();
    error ZeroTotalRaised();
    error ZeroClaimableAmount();

    // Modifier Errors
    error NotOwner();
    error NotAdmin();
    error CallerNotVault();
    error CallerNotTrade();
    error CallerNotVaultOwner();
    error CallerNotGenerate();
    error NoAccess();
    error NotPlugin();

    // State Errors
    error BelowMinFundraisingPeriod();
    error AboveMaxFundraisingPeriod();
    error BelowMinLeverage();
    error AboveMaxLeverage();
    error BelowMinEndTime();
    error TradeTokenNotApplicable();

    // STV errors
    error StvDoesNotExist();
    error AlreadyOpened();
    error MoreThanTotalRaised();
    error MoreThanTotalReceived();
    error StvNotOpen();
    error StvNotClose();
    error ClaimNotApplicable();
    error StvStatusMismatch();

    // General Errors
    error BalanceLessThanAmount();
    error FundraisingPeriodEnded();
    error TotalRaisedMoreThanCapacity();
    error StillFundraising();
    error CommandMisMatch();
    error TradeCommandMisMatch();
    error NotInitialised();
    error Initialised();
    error LengthMismatch();
    error TransferFailed();
    error DelegateCallFailed();
    error CallFailed(bytes);
    error AccountAlreadyExists();
    error SwapFailed();
    error ExchangeDataMismatch();
    error AccountNotExists();
    error InputMismatch();

    // Protocol specific errors
    error GmxFeesMisMatch();
    error UpdateOrderRequestMisMatch();
    error CancelOrderRequestMisMatch();

    // Subscriptions
    error NotASubscriber();
    error AlreadySubscribed();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Errors} from "src/libraries/Errors.sol";
import {GmxStorage} from "src/protocols/gmx/GmxStorage.sol";
import {CapStorage} from "src/protocols/cap/CapStorage.sol";
import {KwentaStorage} from "src/protocols/kwenta/KwentaStorage.sol";
import {IOperator} from "src/storage/interfaces/IOperator.sol";
import {DS} from "src/protocols/cap/interfaces/IDataStore.sol";

contract PerpTradeStorage is GmxStorage, CapStorage, KwentaStorage {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    enum Order {
        UPDATE_INCREASE,
        UPDATE_DECREASE,
        CANCEL_INCREASE,
        CANCEL_DECREASE,
        CANCEL_MULTIPLE
    }

    struct Rewards {
        address ARB; // token
        address REWARDS;
        address KWENTA; // token
        address OP; // token
        address BATCHCLAIM;
        address REWARDESCROW;
    }

    address public operator;
    address public CROSS_CHAIN_ROUTER;
    Rewards public rewards;

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event InitPerpTrade(address indexed operator);
    event GmxUpdate(Gmx dex);
    event CapUpdate(address indexed ds);
    event KwentaUpdate(address indexed kwentaFactory, address indexed susd);
    event CrossChainUpdate(address indexed router);
    event RewardsUpdate(Rewards rewards);

    /*//////////////////////////////////////////////////////////////
                        CONSTRUCTOR/MODIFIERS
    //////////////////////////////////////////////////////////////*/

    constructor(address _operator) {
        operator = _operator;
        emit InitPerpTrade(_operator);
    }

    modifier onlyOwner() {
        address owner = IOperator(operator).getAddress("OWNER");
        if (msg.sender != owner) revert Errors.NotOwner();
        _;
    }

    modifier onlyQorVault() {
        address q = IOperator(operator).getAddress("Q");
        address vault = IOperator(operator).getAddress("VAULT");
        if ((msg.sender != q) && (msg.sender != vault)) revert Errors.NoAccess();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                             SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice function to set/update the necessary contract addresses of gmx
    /// @dev can only be called by the owner
    /// @param _dex `Gmx` struct which contains the necessary contract addresses of GMX
    function setGmx(Gmx memory _dex) external onlyOwner {
        dex = _dex;
        emit GmxUpdate(_dex);
    }

    /// @notice function to set/update the necessary contract addresses of cap
    /// @dev can only be called by the owner
    /// @param _ds address of the DS contract
    function setCap(address _ds) external onlyOwner {
        ds = DS(_ds);
        MARKET_STORE = ds.getAddress("MarketStore");
        FUND_STORE = ds.getAddress("FundStore");
        ORDERS = ds.getAddress("Orders");
        PROCESSOR = ds.getAddress("Processor");
        ORDER_STORE = ds.getAddress("OrderStore");
        emit CapUpdate(_ds);
    }

    /// @notice function to set/update the necessary contract addresses of kwenta
    /// @dev can only be called by the owner
    /// @param _kwentaFactory address of kwenta factory contract
    /// @param _sUSD address of sUSD token
    function setKwenta(address _kwentaFactory, address _sUSD) external onlyOwner {
        kwentaFactory = _kwentaFactory;
        SUSD = _sUSD;
        emit KwentaUpdate(_kwentaFactory, _sUSD);
    }

    /// @notice function to set/update the necessary contract addresses of cross chain
    /// @dev can only be called by the owner
    /// @param _router address of the cross chain router
    function setCrossChainRouter(address _router) external onlyOwner {
        if (_router == address(0)) revert Errors.ZeroAddress();
        CROSS_CHAIN_ROUTER = _router;
        emit CrossChainUpdate(_router);
    }

    function setRewards(Rewards memory _rewards) external onlyOwner {
        rewards = _rewards;
        emit RewardsUpdate(_rewards);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IAccount {
    function execute(address adapter, bytes calldata data, uint256 ethToSend)
        external
        payable
        returns (bytes memory returnData);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
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
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGmxOrderBook {
    function getSwapOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            address path0,
            address path1,
            address path2,
            uint256 amountIn,
            uint256 minOut,
            uint256 triggerRatio,
            bool triggerAboveThreshold,
            bool shouldUnwrap,
            uint256 executionFee
        );

    function getIncreaseOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            address purchaseToken,
            uint256 purchaseTokenAmount,
            address collateralToken,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function getDecreaseOrder(address _account, uint256 _orderIndex)
        external
        view
        returns (
            address collateralToken,
            uint256 collateralDelta,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function executeSwapOrder(address, uint256, address payable) external;
    function executeDecreaseOrder(address, uint256, address payable) external;
    function executeIncreaseOrder(address, uint256, address payable) external;

    function createIncreaseOrder(
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) external payable;

    function createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external payable;

    function createSwapOrder(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _triggerRatio, // tokenB / tokenA
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap,
        bool _shouldUnwrap
    ) external payable;

    function increaseOrdersIndex(address) external view returns (uint256);
    function decreaseOrdersIndex(address) external view returns (uint256);

    function validatePositionOrderPrice(
        bool _triggerAboveThreshold,
        uint256 _triggerPrice,
        address _indexToken,
        bool _maximizePrice,
        bool _raise
    ) external view returns (uint256, bool);

    function updateIncreaseOrder(
        uint256 _orderIndex,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function updateSwapOrder(uint256 _orderIndex, uint256 _minOut, uint256 _triggerRatio, bool _triggerAboveThreshold)
        external;

    function cancelIncreaseOrder(uint256 _orderIndex) external;

    function cancelDecreaseOrder(uint256 _orderIndex) external;

    function cancelSwapOrder(uint256 _orderIndex) external;

    function cancelMultiple(
        uint256[] memory _swapOrderIndexes,
        uint256[] memory _increaseOrderIndexes,
        uint256[] memory _decreaseOrderIndexes
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IGmxVault} from "./IGmxVault.sol";

interface IGmxReader {
    function getAmountOut(IGmxVault _vault, address _tokenIn, address _tokenOut, uint256 _amountIn)
        external
        view
        returns (uint256, uint256);
    function getMaxAmountIn(IGmxVault _vault, address _tokenIn, address _tokenOut) external view returns (uint256);
    function getPositions(
        address _vault,
        address _account,
        address[] memory _collateralTokens,
        address[] memory _indexTokens,
        bool[] memory _isLong
    ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./IGmxVaultUtils.sol";

interface IGmxVault {
    function isInitialized() external view returns (bool);

    function isSwapEnabled() external view returns (bool);

    function isLeverageEnabled() external view returns (bool);

    function setVaultUtils(IGmxVaultUtils _vaultUtils) external;

    function setError(uint256 _errorCode, string calldata _error) external;

    function router() external view returns (address);

    function usdg() external view returns (address);

    function gov() external view returns (address);

    function whitelistedTokenCount() external view returns (uint256);

    function maxLeverage() external view returns (uint256);

    function minProfitTime() external view returns (uint256);

    function hasDynamicFees() external view returns (bool);

    function fundingInterval() external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function getTargetUsdgAmount(address _token) external view returns (uint256);

    function inManagerMode() external view returns (bool);

    function inPrivateLiquidationMode() external view returns (bool);

    function maxGasPrice() external view returns (uint256);

    function approvedRouters(address _account, address _router) external view returns (bool);

    function isLiquidator(address _account) external view returns (bool);

    function isManager(address _account) external view returns (bool);

    function minProfitBasisPoints(address _token) external view returns (uint256);

    function tokenBalances(address _token) external view returns (uint256);

    function lastFundingTimes(address _token) external view returns (uint256);

    function setMaxLeverage(uint256 _maxLeverage) external;

    function setInManagerMode(bool _inManagerMode) external;

    function setManager(address _manager, bool _isManager) external;

    function setIsSwapEnabled(bool _isSwapEnabled) external;

    function setIsLeverageEnabled(bool _isLeverageEnabled) external;

    function setMaxGasPrice(uint256 _maxGasPrice) external;

    function setUsdgAmount(address _token, uint256 _amount) external;

    function setBufferAmount(address _token, uint256 _amount) external;

    function setMaxGlobalShortSize(address _token, uint256 _amount) external;

    function setInPrivateLiquidationMode(bool _inPrivateLiquidationMode) external;

    function setLiquidator(address _liquidator, bool _isActive) external;

    function setFundingRate(uint256 _fundingInterval, uint256 _fundingRateFactor, uint256 _stableFundingRateFactor)
        external;

    function setFees(
        uint256 _taxBasisPoints,
        uint256 _stableTaxBasisPoints,
        uint256 _mintBurnFeeBasisPoints,
        uint256 _swapFeeBasisPoints,
        uint256 _stableSwapFeeBasisPoints,
        uint256 _marginFeeBasisPoints,
        uint256 _liquidationFeeUsd,
        uint256 _minProfitTime,
        bool _hasDynamicFees
    ) external;

    function setTokenConfig(
        address _token,
        uint256 _tokenDecimals,
        uint256 _redemptionBps,
        uint256 _minProfitBps,
        uint256 _maxUsdgAmount,
        bool _isStable,
        bool _isShortable
    ) external;

    function setPriceFeed(address _priceFeed) external;

    function withdrawFees(address _token, address _receiver) external returns (uint256);

    function directPoolDeposit(address _token) external;

    function buyUSDG(address _token, address _receiver) external returns (uint256);

    function sellUSDG(address _token, address _receiver) external returns (uint256);

    function swap(address _tokenIn, address _tokenOut, address _receiver) external returns (uint256);

    function increasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external;

    function decreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external returns (uint256);

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external;

    function tokenToUsdMin(address _token, uint256 _tokenAmount) external view returns (uint256);

    function priceFeed() external view returns (address);

    function fundingRateFactor() external view returns (uint256);

    function stableFundingRateFactor() external view returns (uint256);

    function cumulativeFundingRates(address _token) external view returns (uint256);

    function getNextFundingRate(address _token) external view returns (uint256);

    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function mintBurnFeeBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function allWhitelistedTokensLength() external view returns (uint256);

    function allWhitelistedTokens(uint256) external view returns (address);

    function whitelistedTokens(address _token) external view returns (bool);

    function stableTokens(address _token) external view returns (bool);

    function shortableTokens(address _token) external view returns (bool);

    function feeReserves(address _token) external view returns (uint256);

    function globalShortSizes(address _token) external view returns (uint256);

    function globalShortAveragePrices(address _token) external view returns (uint256);

    function maxGlobalShortSizes(address _token) external view returns (uint256);

    function tokenDecimals(address _token) external view returns (uint256);

    function tokenWeights(address _token) external view returns (uint256);

    function guaranteedUsd(address _token) external view returns (uint256);

    function poolAmounts(address _token) external view returns (uint256);

    function bufferAmounts(address _token) external view returns (uint256);

    function reservedAmounts(address _token) external view returns (uint256);

    function usdgAmounts(address _token) external view returns (uint256);

    function maxUsdgAmounts(address _token) external view returns (uint256);

    function getRedemptionAmount(address _token, uint256 _usdgAmount) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getPosition(address _account, address _collateralToken, address _indexToken, bool _isLong)
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256, bool, uint256);

    function getPositionDelta(address _account, address _collateralToken, address _indexToken, bool _isLong)
        external
        view
        returns (bool, uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ICapOrders {
    struct Order {
        uint256 orderId; // incremental order id
        address user; // user that submitted the order
        address asset; // Asset address, e.g. address(0) for ETH
        string market; // Market this order was submitted on
        uint256 margin; // Collateral tied to this order. In wei
        uint256 size; // Order size (margin * leverage). In wei
        uint256 price; // The order's price if its a trigger or protected order
        uint256 fee; // Fee amount paid. In wei
        bool isLong; // Wether the order is a buy or sell order
        uint8 orderType; // 0 = market, 1 = limit, 2 = stop
        bool isReduceOnly; // Wether the order is reduce-only
        uint256 timestamp; // block.timestamp at which the order was submitted
        uint256 expiry; // block.timestamp at which the order expires
        uint256 cancelOrderId; // orderId to cancel when this order executes
    }

    function submitOrder(Order memory params, uint256 tpPrice, uint256 slPrice) external payable;
    function cancelOrder(uint256 orderId) external;
    function cancelOrders(uint256[] calldata orderIds) external;
}

interface IMarketStore {
    struct Market {
        string name; // Market's full name, e.g. Bitcoin / U.S. Dollar
        string category; // crypto, fx, commodities, or indices
        address chainlinkFeed; // Price feed contract address
        uint256 maxLeverage; // No decimals
        uint256 maxDeviation; // In bps, max price difference from oracle to chainlink price
        uint256 fee; // In bps. 10 = 0.1%
        uint256 liqThreshold; // In bps
        uint256 fundingFactor; // Yearly funding rate if OI is completely skewed to one side. In bps.
        uint256 minOrderAge; // Min order age before is can be executed. In seconds
        uint256 pythMaxAge; // Max Pyth submitted price age, in seconds
        bytes32 pythFeed; // Pyth price feed id
        bool allowChainlinkExecution; // Allow anyone to execute orders with chainlink
        bool isReduceOnly; // accepts only reduce only orders
    }

    function get(string calldata market) external view returns (Market memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IOperator {
    function getAddress(string calldata adapter) external view returns (address);
    function getAddresses(string[] calldata adapters) external view returns (address[] memory);
    function getTraderAccount(address trader) external view returns (address);
    function getPlugin(address plugin) external view returns (bool);
    function getPlugins(address[] calldata plugins) external view returns (bool[] memory);
    function setAddress(string calldata adapter, address addr) external;
    function setAddresses(string[] calldata adapters, address[] calldata addresses) external;
    function setTraderAccount(address trader, address account) external;
    function getAllSubscribers(address manager) external view returns (address[] memory);
    function getIsSubscriber(address manager, address subscriber) external view returns (bool);
    function getSubscriptionAmount(address manager, address subscriber) external view returns (uint96);
    function getTotalSubscribedAmountPerManager(address manager) external view returns (uint96);
    function setSubscribe(address manager, address subscriber, uint96 maxLimit) external;
    function setUnsubscribe(address manager, address subscriber) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {IGmxPositionRouter} from "src/interfaces/external/gmx/IGmxPositionRouter.sol";

contract GmxStorage {
    struct Gmx {
        address vault;
        address router;
        address positionRouter;
        address orderBook;
        address reader;
        address defaultShortCollateral;
    }

    // struct which contains all the necessary contract addresses of GMX
    // check `IReaderStorage.Gmx`
    Gmx public dex;

    function getGmxVault() internal view returns (address) {
        return dex.vault;
    }

    function getGmxRouter() internal view returns (address) {
        return dex.router;
    }

    function getGmxPositionRouter() internal view returns (address) {
        return dex.positionRouter;
    }

    function getGmxOrderBook() internal view returns (address) {
        return dex.orderBook;
    }

    function getGmxReader() internal view returns (address) {
        return dex.reader;
    }

    function getGmxDefaultShortCollateral() internal view returns (address) {
        return dex.defaultShortCollateral;
    }

    function getGmxFee() internal view returns (uint256 fee) {
        address _gmxPositionRouter = getGmxPositionRouter();
        /// GMX checks if `msg.value >= fee` for closing positions, so we need 1 more WEI to pass.
        fee = IGmxPositionRouter(_gmxPositionRouter).minExecutionFee();
    }

    function getPath(bool _isClose, bool _tradeDirection, address _depositToken, address _tradeToken)
        internal
        view
        returns (address[] memory _path)
    {
        if (_isClose) {
            if (_tradeDirection) {
                // for long, the collateral is in the tradeToken,
                // we swap from tradeToken to usdc, path[0] = tradeToken
                _path = new address[](2);
                _path[0] = _tradeToken;
                _path[1] = dex.defaultShortCollateral;
            } else {
                // for short, the collateral is in stable coin,
                // so the path only needs depositToken since there's no swap
                _path = new address[](1);
                _path[0] = _depositToken;
            }
        } else {
            if (_tradeDirection) {
                // for long, the collateral is in the tradeToken,
                //  we swap from usdc to tradeToken, path[0] = depositToken
                _path = new address[](2);
                _path[0] = _depositToken;
                _path[1] = _tradeToken;
            } else {
                // for short, the collateral is in stable coin,
                // so the path only needs depositToken since there's no swap
                _path = new address[](1);
                _path[0] = _depositToken;
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {DS} from "src/protocols/cap/interfaces/IDataStore.sol";

contract CapStorage {
    uint256 public constant BPS_DIVIDER = 10000;
    DS public ds;
    //address public owner;
    address public MARKET_STORE;
    address public FUND_STORE;
    address public ORDERS;
    address public PROCESSOR;
    address public ORDER_STORE;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract KwentaStorage {
    //address public owner;
    address public kwentaFactory;
    address public SUSD;

    function getKwentaFactory() public view returns (address) {
        return kwentaFactory;
    }

    function getSUSD() public view returns (address) {
        return SUSD;
    }
}

interface DS {
    function getAddress(string calldata key) external view returns (address);

    function setAddress(string calldata key, address value, bool overwrite) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGmxVaultUtils {
    function updateCumulativeFundingRate(address _collateralToken, address _indexToken) external returns (bool);
    function validateIncreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _sizeDelta,
        bool _isLong
    ) external view;
    function validateDecreasePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver
    ) external view;
    function validateLiquidation(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        bool _raise
    ) external view returns (uint256, uint256);
    function getEntryFundingRate(address _collateralToken, address _indexToken, bool _isLong)
        external
        view
        returns (uint256);
    function getPositionFee(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _sizeDelta
    ) external view returns (uint256);
    function getFundingFee(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);
    function getBuyUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getSellUsdgFeeBasisPoints(address _token, uint256 _usdgAmount) external view returns (uint256);
    function getSwapFeeBasisPoints(address _tokenIn, address _tokenOut, uint256 _usdgAmount)
        external
        view
        returns (uint256);
    function getFeeBasisPoints(
        address _token,
        uint256 _usdgDelta,
        uint256 _feeBasisPoints,
        uint256 _taxBasisPoints,
        bool _increment
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGmxPositionRouter {
    struct IncreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        uint256 amountIn;
        uint256 minOut;
        uint256 sizeDelta;
        bool isLong;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool hasCollateralInETH;
        address callbackTarget;
    }

    struct DecreasePositionRequest {
        address account;
        address[] path;
        address indexToken;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        address receiver;
        uint256 acceptablePrice;
        uint256 minOut;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool withdrawETH;
        address callbackTarget;
    }

    function executeIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

    function executeDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable returns (bytes32);

    function minExecutionFee() external view returns (uint256);

    function setPositionKeeper(address _account, bool _isActive) external;

    function getRequestKey(address _account, uint256 _index) external pure returns (bytes32);

    function getDecreasePositionRequestPath(bytes32 _key) external view returns (address[] memory);

    function cancelIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

    function cancelDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

    function executeIncreasePositions(uint256 _count, address payable _executionFeeReceiver) external;

    function executeDecreasePositions(uint256 _count, address payable _executionFeeReceiver) external;

    function increasePositionRequestKeysStart() external view returns (uint256);

    function decreasePositionRequestKeysStart() external view returns (uint256);

    function increasePositionRequestKeys(uint256 index) external view returns (bytes32);

    function decreasePositionRequestKeys(uint256 index) external view returns (bytes32);

    function increasePositionRequests(bytes32 key) external view returns (IncreasePositionRequest memory);

    function dereasePositionRequests(bytes32 key) external view returns (DecreasePositionRequest memory);

    function increasePositionsIndex(address account) external view returns (uint256);

    function decreasePositionsIndex(address account) external view returns (uint256);
}