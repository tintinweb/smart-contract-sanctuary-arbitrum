// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Commands} from "src/libraries/Commands.sol";
import {Errors} from "src/libraries/Errors.sol";
import {PerpTradeStorage} from "src/PerpTrade/PerpTradeStorage.sol";
import {IAccount} from "src/q/interfaces/IAccount.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICapOrders} from "src/protocols/cap/interfaces/ICapOrders.sol";
import {IMarketStore} from "src/protocols/cap/interfaces/IMarketStore.sol";
import {IAccount as IKwentaAccount} from "src/protocols/kwenta/interfaces/IAccount.sol";
import {IFactory as IKwentaFactory} from "src/protocols/kwenta/interfaces/IFactory.sol";
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
            _cap(data);
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

    function _cap(bytes memory data) internal {
        // decode the data
        (address account,, ICapOrders.Order memory order, uint256 tpPrice, uint256 slPrice) =
            abi.decode(data, (address, uint96, ICapOrders.Order, uint256, uint256));

        if (account == address(0)) revert Errors.ZeroAddress();
        // TODO (update tests to uncomment)
        // if (order.asset != IOperator(operator).getAddress("DEFAULTSTABLECOIN")) revert Errors.InputMismatch();

        // calculate the approval amount and approve the token
        IMarketStore.Market memory market = IMarketStore(MARKET_STORE).get(order.market);
        uint256 valueConsumed = order.margin + (order.size * market.fee) / BPS_DIVIDER;
        bytes memory tokenApprovalData = abi.encodeWithSignature("approve(address,uint256)", FUND_STORE, valueConsumed);
        IAccount(account).execute(order.asset, tokenApprovalData);

        // Make the execute from account
        bytes memory tradeData = abi.encodeCall(ICapOrders.submitOrder, (order, tpPrice, slPrice));
        IAccount(account).execute(ORDERS, tradeData);
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
                IAccount(account).execute(depositToken, tokenApprovalData);
            }

            if (needApproval) {
                address adapter = getGmxRouter();
                bytes memory pluginApprovalData;
                pluginApprovalData = abi.encodeWithSignature("approvePlugin(address)", getGmxOrderBook());
                IAccount(account).execute(adapter, pluginApprovalData);
                pluginApprovalData = abi.encodeWithSignature("approvePlugin(address)", getGmxPositionRouter());
                IAccount(account).execute(adapter, pluginApprovalData);
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
                IAccount(account).execute{value: fee}(getGmxOrderBook(), tradeData);
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
                IAccount(account).execute{value: fee}(getGmxPositionRouter(), tradeData);
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
                IAccount(account).execute{value: fee + 1}(getGmxOrderBook(), tradeData);
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
                IAccount(account).execute{value: fee + 1}(getGmxPositionRouter(), tradeData);
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
        IAccount(account).execute(token, tokenApprovalData);
        IAccount(account).execute{value: msg.value}(CROSS_CHAIN_ROUTER, lifiData);
    }

    function _modifyOrder(bytes calldata data, bool isCancel) internal {
        (address account,, uint256 command, Order orderType, bytes memory orderData) =
            abi.decode(data, (address, uint256, uint256, Order, bytes));
        address adapter;
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
                (uint256 orderIndex) = abi.decode(orderData, (uint256));
                if (orderType == Order.CANCEL_INCREASE) {
                    actionData = abi.encodeWithSignature("cancelIncreaseOrder(uint256)", orderIndex);
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
                adapter = getGmxOrderBook();
            } else {
                revert Errors.CommandMisMatch();
            }
        } else {
            if (command == Commands.CAP) {
                (uint256 cancelOrderId, bytes memory capOrderData) = abi.decode(orderData, (uint256, bytes));
                bytes memory cancelOrderData = abi.encodeWithSignature("cancelOrder(uint256)", cancelOrderId);
                IAccount(account).execute(ORDERS, cancelOrderData);

                _cap(capOrderData);
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
        if (actionData.length > 0) IAccount(account).execute(adapter, actionData);
    }

    function _claimRewards(bytes calldata data) internal {
        (address account, uint256 command, bytes[] memory rewardData) = abi.decode(data, (address, uint256, bytes[]));
        address treasury = IOperator(operator).getAddress("TREASURY");
        address token;
        uint256 rewardAmount;

        if (command == Commands.CAP) {
            token = rewards.ARB;
            rewardAmount = IERC20(token).balanceOf(account);
            if (rewardData[0].length > 0) IAccount(account).execute(rewards.REWARDS, rewardData[0]);
            rewardAmount = IERC20(token).balanceOf(account) - rewardAmount;
        } else if (command == Commands.GMX) {
            token = IOperator(operator).getAddress("WRAPPEDTOKEN");
            rewardAmount = IERC20(token).balanceOf(account);
        } else {
            revert Errors.CommandMisMatch();
        }

        if (rewardAmount > 0) {
            IAccount(account).execute(
                token, abi.encodeWithSignature("transfer(address,uint256)", treasury, rewardAmount)
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
    function execute(address adapter, bytes calldata data) external payable returns (bytes memory returnData);
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IEvents} from "./IEvents.sol";
import {IFactory} from "./IFactory.sol";
import {IFuturesMarketManager} from "src/protocols/kwenta/interfaces/synthetix/IFuturesMarketManager.sol";
import {IPerpsV2MarketConsolidated} from "src/protocols/kwenta/interfaces/synthetix/IPerpsV2MarketConsolidated.sol";
import {ISettings} from "./ISettings.sol";
import {ISystemStatus} from "src/protocols/kwenta/interfaces/synthetix/ISystemStatus.sol";

/// @title Kwenta Smart Margin Account Implementation Interface
/// @author JaredBorders ([email protected]), JChiaramonte7 ([email protected])
interface IAccount {
    /*///////////////////////////////////////////////////////////////
                                Types
    ///////////////////////////////////////////////////////////////*/

    /// @notice Command Flags used to decode commands to execute
    /// @dev under the hood ACCOUNT_MODIFY_MARGIN = 0, ACCOUNT_WITHDRAW_ETH = 1
    enum Command {
        ACCOUNT_MODIFY_MARGIN, // 0
        ACCOUNT_WITHDRAW_ETH, // 1
        PERPS_V2_MODIFY_MARGIN, // 2
        PERPS_V2_WITHDRAW_ALL_MARGIN, // 3
        PERPS_V2_SUBMIT_ATOMIC_ORDER, // 4
        PERPS_V2_SUBMIT_DELAYED_ORDER, // 5
        PERPS_V2_SUBMIT_OFFCHAIN_DELAYED_ORDER, // 6
        PERPS_V2_CLOSE_POSITION, // 7
        PERPS_V2_SUBMIT_CLOSE_DELAYED_ORDER, // 8
        PERPS_V2_SUBMIT_CLOSE_OFFCHAIN_DELAYED_ORDER, // 9
        PERPS_V2_CANCEL_DELAYED_ORDER, // 10
        PERPS_V2_CANCEL_OFFCHAIN_DELAYED_ORDER, // 11
        GELATO_PLACE_CONDITIONAL_ORDER, // 12
        GELATO_CANCEL_CONDITIONAL_ORDER // 13
    }

    /// @notice denotes conditional order types for code clarity
    /// @dev under the hood LIMIT = 0, STOP = 1
    enum ConditionalOrderTypes {
        LIMIT,
        STOP
    }

    /// @notice denotes conditional order cancelled reasons for code clarity
    /// @dev under the hood CONDITIONAL_ORDER_CANCELLED_BY_USER = 0, CONDITIONAL_ORDER_CANCELLED_NOT_REDUCE_ONLY = 1
    enum ConditionalOrderCancelledReason {
        CONDITIONAL_ORDER_CANCELLED_BY_USER,
        CONDITIONAL_ORDER_CANCELLED_NOT_REDUCE_ONLY
    }

    /// marketKey: Synthetix PerpsV2 Market id/key
    /// marginDelta: amount of margin to deposit or withdraw; positive indicates deposit, negative withdraw
    /// sizeDelta: denoted in market currency (i.e. ETH, BTC, etc), size of Synthetix PerpsV2 position
    /// targetPrice: limit or stop price target needing to be met to submit Synthetix PerpsV2 order
    /// gelatoTaskId: unqiue taskId from gelato necessary for cancelling conditional orders
    /// conditionalOrderType: conditional order type to determine conditional order fill logic
    /// desiredFillPrice: desired price to fill Synthetix PerpsV2 order at execution time
    /// reduceOnly: if true, only allows position's absolute size to decrease
    struct ConditionalOrder {
        bytes32 marketKey;
        int256 marginDelta;
        int256 sizeDelta;
        uint256 targetPrice;
        bytes32 gelatoTaskId;
        ConditionalOrderTypes conditionalOrderType;
        uint256 desiredFillPrice;
        bool reduceOnly;
    }
    /// @dev see example below elucidating targtPrice vs desiredFillPrice:
    /// 1. targetPrice met (ex: targetPrice = X)
    /// 2. account submits delayed order to Synthetix PerpsV2 with desiredFillPrice = Y
    /// 3. keeper executes Synthetix PerpsV2 order after delay period
    /// 4. if current market price defined by Synthetix PerpsV2
    ///    after delay period satisfies desiredFillPrice order is filled

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice thrown when commands length does not equal inputs length
    error LengthMismatch();

    /// @notice thrown when Command given is not valid
    error InvalidCommandType(uint256 commandType);

    /// @notice thrown when conditional order type given is not valid due to zero sizeDelta
    error ZeroSizeDelta();

    /// @notice exceeds useable margin
    /// @param available: amount of useable margin asset
    /// @param required: amount of margin asset required
    error InsufficientFreeMargin(uint256 available, uint256 required);

    /// @notice call to transfer ETH on withdrawal fails
    error EthWithdrawalFailed();

    /// @notice base price from the oracle was invalid
    /// @dev Rate can be invalid either due to:
    ///     1. Returned as invalid from ExchangeRates - due to being stale or flagged by oracle
    ///     2. Out of deviation bounds w.r.t. to previously stored rate
    ///     3. if there is no valid stored rate, w.r.t. to previous 3 oracle rates
    ///     4. Price is zero
    error InvalidPrice();

    /// @notice thrown when account execution has been disabled in the settings contract
    error AccountExecutionDisabled();

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice returns the version of the Account
    function VERSION() external view returns (bytes32);

    /// @return returns the amount of margin locked for future events (i.e. conditional orders)
    function committedMargin() external view returns (uint256);

    /// @return returns current conditional order id
    function conditionalOrderId() external view returns (uint256);

    /// @notice get delayed order data from Synthetix PerpsV2
    /// @dev call reverts if _marketKey is invalid
    /// @param _marketKey: key for Synthetix PerpsV2 Market
    /// @return delayed order struct defining delayed order (will return empty struct if no delayed order exists)
    function getDelayedOrder(bytes32 _marketKey) external returns (IPerpsV2MarketConsolidated.DelayedOrder memory);

    /// @notice checker() is the Resolver for Gelato
    /// (see https://docs.gelato.network/developer-services/automate/guides/custom-logic-triggers/smart-contract-resolvers)
    /// @notice signal to a keeper that a conditional order is valid/invalid for execution
    /// @dev call reverts if conditional order Id does not map to a valid conditional order;
    /// ConditionalOrder.marketKey would be invalid
    /// @param _conditionalOrderId: key for an active conditional order
    /// @return canExec boolean that signals to keeper a conditional order can be executed by Gelato
    /// @return execPayload calldata for executing a conditional order
    function checker(uint256 _conditionalOrderId) external view returns (bool canExec, bytes memory execPayload);

    /// @notice the current withdrawable or usable balance
    /// @return free margin amount
    function freeMargin() external view returns (uint256);

    /// @notice get up-to-date position data from Synthetix PerpsV2
    /// @param _marketKey: key for Synthetix PerpsV2 Market
    /// @return position struct defining current position
    function getPosition(bytes32 _marketKey) external returns (IPerpsV2MarketConsolidated.Position memory);

    /// @notice conditional order id mapped to conditional order
    /// @param _conditionalOrderId: id of conditional order
    /// @return conditional order
    function getConditionalOrder(uint256 _conditionalOrderId) external view returns (ConditionalOrder memory);

    /*//////////////////////////////////////////////////////////////
                                MUTATIVE
    //////////////////////////////////////////////////////////////*/

    /// @notice sets the initial owner of the account
    /// @dev only called once by the factory on account creation
    /// @param _owner: address of the owner
    function setInitialOwnership(address _owner) external;

    /// @notice executes commands along with provided inputs
    /// @param _commands: array of commands, each represented as an enum
    /// @param _inputs: array of byte strings containing abi encoded inputs for each command
    function execute(Command[] calldata _commands, bytes[] calldata _inputs) external payable;

    /// @notice execute a gelato queued conditional order
    /// @notice only keepers can trigger this function
    /// @dev currently only supports conditional order submission via PERPS_V2_SUBMIT_OFFCHAIN_DELAYED_ORDER COMMAND
    /// @param _conditionalOrderId: key for an active conditional order
    function executeConditionalOrder(uint256 _conditionalOrderId) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title Kwenta Factory Interface
/// @author JaredBorders ([email protected])
interface IFactory {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted when new account is created
    /// @param creator: account creator (address that called newAccount())
    /// @param account: address of account that was created (will be address of proxy)
    /// @param version: version of account created
    event NewAccount(address indexed creator, address indexed account, bytes32 version);

    /// @notice emitted when implementation is upgraded
    /// @param implementation: address of new implementation
    event AccountImplementationUpgraded(address implementation);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice thrown when factory cannot set account owner to the msg.sender
    /// @param data: data returned from failed low-level call
    error FailedToSetAcountOwner(bytes data);

    /// @notice thrown when Account creation fails due to no version being set
    /// @param data: data returned from failed low-level call
    error AccountFailedToFetchVersion(bytes data);

    /// @notice thrown when factory is not upgradable
    error CannotUpgrade();

    /// @notice thrown when account is unrecognized by factory
    error AccountDoesNotExist();

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @return canUpgrade: bool to determine if system can be upgraded
    function canUpgrade() external view returns (bool);

    /// @return logic: account logic address
    function implementation() external view returns (address);

    /// @param _account: address of account
    /// @return whether or not account exists
    function accounts(address _account) external view returns (bool);

    /// @param _account: address of account
    /// @return owner of account
    function getAccountOwner(address _account) external view returns (address);

    /// @param _owner: address of owner
    /// @return array of accounts owned by _owner
    function getAccountsOwnedBy(address _owner) external view returns (address[] memory);

    /*//////////////////////////////////////////////////////////////
                               OWNERSHIP
    //////////////////////////////////////////////////////////////*/

    /// @notice update owner to account(s) mapping
    /// @dev does *NOT* check new owner != old owner
    /// @param _newOwner: new owner of account
    /// @param _oldOwner: old owner of account
    function updateAccountOwnership(address _newOwner, address _oldOwner) external;

    /*//////////////////////////////////////////////////////////////
                           ACCOUNT DEPLOYMENT
    //////////////////////////////////////////////////////////////*/

    /// @notice create unique account proxy for function caller
    /// @return accountAddress address of account created
    function newAccount() external returns (address payable accountAddress);

    /*//////////////////////////////////////////////////////////////
                             UPGRADABILITY
    //////////////////////////////////////////////////////////////*/

    /// @notice upgrade implementation of account which all account proxies currently point to
    /// @dev this *will* impact all existing accounts
    /// @dev future accounts will also point to this new implementation (until
    /// upgradeAccountImplementation() is called again with a newer implementation)
    /// @dev *DANGER* this function does not check the new implementation for validity,
    /// thus, a bad upgrade could result in severe consequences.
    /// @param _implementation: address of new implementation
    function upgradeAccountImplementation(address _implementation) external;

    /// @notice remove upgradability from factory
    /// @dev cannot be undone
    function removeUpgradability() external;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

import {IAccount} from "./IAccount.sol";

/// @title Interface for contract that emits all events emitted by the Smart Margin Accounts
/// @author JaredBorders ([email protected])
interface IEvents {
    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted when a non-account contract attempts to call a restricted function
    error OnlyAccounts();

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice returns the address of the factory contract
    function factory() external view returns (address);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted after a successful withdrawal
    /// @param user: the address that withdrew from account
    /// @param amount: amount of marginAsset to withdraw from account
    function emitDeposit(address user, uint256 amount) external;

    event Deposit(address indexed user, address indexed account, uint256 amount);

    /// @notice emitted after a successful withdrawal
    /// @param user: the address that withdrew from account
    /// @param amount: amount of marginAsset to withdraw from account
    function emitWithdraw(address user, uint256 amount) external;

    event Withdraw(address indexed user, address indexed account, uint256 amount);

    /// @notice emitted after a successful ETH withdrawal
    /// @param user: the address that withdrew from account
    /// @param amount: amount of ETH to withdraw from account
    function emitEthWithdraw(address user, uint256 amount) external;

    event EthWithdraw(address indexed user, address indexed account, uint256 amount);

    /// @notice emitted when a conditional order is placed
    /// @param conditionalOrderId: id of conditional order
    /// @param gelatoTaskId: id of gelato task
    /// @param marketKey: Synthetix PerpsV2 market key
    /// @param marginDelta: margin change
    /// @param sizeDelta: size change
    /// @param targetPrice: targeted fill price
    /// @param conditionalOrderType: expected conditional order type enum where 0 = LIMIT, 1 = STOP, etc..
    /// @param desiredFillPrice: desired price to fill Synthetix PerpsV2 order at execution time
    /// @param reduceOnly: if true, only allows position's absolute size to decrease
    function emitConditionalOrderPlaced(
        uint256 conditionalOrderId,
        bytes32 gelatoTaskId,
        bytes32 marketKey,
        int256 marginDelta,
        int256 sizeDelta,
        uint256 targetPrice,
        IAccount.ConditionalOrderTypes conditionalOrderType,
        uint256 desiredFillPrice,
        bool reduceOnly
    ) external;

    event ConditionalOrderPlaced(
        address indexed account,
        uint256 indexed conditionalOrderId,
        bytes32 indexed gelatoTaskId,
        bytes32 marketKey,
        int256 marginDelta,
        int256 sizeDelta,
        uint256 targetPrice,
        IAccount.ConditionalOrderTypes conditionalOrderType,
        uint256 desiredFillPrice,
        bool reduceOnly
    );

    /// @notice emitted when a conditional order is cancelled
    /// @param conditionalOrderId: id of conditional order
    /// @param gelatoTaskId: id of gelato task
    /// @param reason: reason for cancellation
    function emitConditionalOrderCancelled(
        uint256 conditionalOrderId,
        bytes32 gelatoTaskId,
        IAccount.ConditionalOrderCancelledReason reason
    ) external;

    event ConditionalOrderCancelled(
        address indexed account,
        uint256 indexed conditionalOrderId,
        bytes32 indexed gelatoTaskId,
        IAccount.ConditionalOrderCancelledReason reason
    );

    /// @notice emitted when a conditional order is filled
    /// @param conditionalOrderId: id of conditional order
    /// @param gelatoTaskId: id of gelato task
    /// @param fillPrice: price the conditional order was executed at
    /// @param keeperFee: fees paid to the executor
    function emitConditionalOrderFilled(
        uint256 conditionalOrderId,
        bytes32 gelatoTaskId,
        uint256 fillPrice,
        uint256 keeperFee
    ) external;

    event ConditionalOrderFilled(
        address indexed account,
        uint256 indexed conditionalOrderId,
        bytes32 indexed gelatoTaskId,
        uint256 fillPrice,
        uint256 keeperFee
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface IFuturesMarketManager {
    function marketForKey(bytes32 marketKey) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface IPerpsV2MarketConsolidated {
    struct Position {
        uint64 id;
        uint64 lastFundingIndex;
        uint128 margin;
        uint128 lastPrice;
        int128 size;
    }

    struct DelayedOrder {
        bool isOffchain;
        int128 sizeDelta;
        uint128 desiredFillPrice;
        uint128 targetRoundId;
        uint128 commitDeposit;
        uint128 keeperDeposit;
        uint256 executableAtTime;
        uint256 intentionTime;
        bytes32 trackingCode;
    }

    function marketKey() external view returns (bytes32 key);

    function positions(address account) external view returns (Position memory);

    function delayedOrders(address account) external view returns (DelayedOrder memory);

    function assetPrice() external view returns (uint256 price, bool invalid);

    function transferMargin(int256 marginDelta) external;

    function withdrawAllMargin() external;

    function modifyPositionWithTracking(int256 sizeDelta, uint256 desiredFillPrice, bytes32 trackingCode) external;

    function closePositionWithTracking(uint256 desiredFillPrice, bytes32 trackingCode) external;

    function submitCloseOffchainDelayedOrderWithTracking(uint256 desiredFillPrice, bytes32 trackingCode) external;

    function submitCloseDelayedOrderWithTracking(
        uint256 desiredTimeDelta,
        uint256 desiredFillPrice,
        bytes32 trackingCode
    ) external;

    function submitDelayedOrderWithTracking(
        int256 sizeDelta,
        uint256 desiredTimeDelta,
        uint256 desiredFillPrice,
        bytes32 trackingCode
    ) external;

    function submitOffchainDelayedOrderWithTracking(int256 sizeDelta, uint256 desiredFillPrice, bytes32 trackingCode)
        external;

    function cancelDelayedOrder(address account) external;

    function cancelOffchainDelayedOrder(address account) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

/// @title Kwenta Smart Margin Account Settings Interface
/// @author JaredBorders ([email protected])
interface ISettings {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted when account execution is enabled or disabled
    /// @param enabled: true if account execution is enabled, false if disabled
    event AccountExecutionEnabledSet(bool enabled);

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @notice checks if account execution is enabled or disabled
    /// @return enabled: true if account execution is enabled, false if disabled
    function accountExecutionEnabled() external view returns (bool);

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice enables or disables account execution
    /// @param _enabled: true if account execution is enabled, false if disabled
    function setAccountExecutionEnabled(bool _enabled) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.17;

interface ISystemStatus {
    function requireFuturesMarketActive(bytes32 marketKey) external view;
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