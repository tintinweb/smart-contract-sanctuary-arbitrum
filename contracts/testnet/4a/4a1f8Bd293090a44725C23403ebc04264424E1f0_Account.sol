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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.18;

import {Auth} from "./utils/Auth.sol";
import {
    IAccount,
    IEvents,
    IFactory,
    IFuturesMarketManager,
    IPerpsV2MarketConsolidated,
    ISettings,
    ISystemStatus
} from "./interfaces/IAccount.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {OpsReady, IOps} from "./utils/OpsReady.sol";

/// @title Kwenta Smart Margin Account Implementation
/// @author JaredBorders ([email protected]), JChiaramonte7 ([email protected])
/// @notice flexible smart margin account enabling users to trade on-chain derivatives
contract Account is IAccount, Auth, OpsReady {
    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IAccount
    bytes32 public constant VERSION = "2.0.1";

    /// @notice tracking code used when modifying positions
    bytes32 internal constant TRACKING_CODE = "KWENTA";

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice address of the Smart Margin Account Factory
    IFactory internal immutable FACTORY;

    /// @notice address of the contract used by all accounts for emitting events
    /// @dev can be immutable due to the fact the events contract is
    /// upgraded alongside the account implementation
    IEvents internal immutable EVENTS;

    /// @notice address of the Synthetix ProxyERC20sUSD contract used as the margin asset
    /// @dev can be immutable due to the fact the sUSD contract is a proxy address
    IERC20 internal immutable MARGIN_ASSET;

    /// @notice address of the Synthetix FuturesMarketManager
    /// @dev the manager keeps track of which markets exist, and is the main window between
    /// perpsV2 markets and the rest of the synthetix system. It accumulates the total debt
    /// over all markets, and issues and burns sUSD on each market's behalf
    IFuturesMarketManager internal immutable FUTURES_MARKET_MANAGER;

    /// @notice address of the Synthetix SystemStatus
    /// @dev the system status contract is used to check if the system is operational
    ISystemStatus internal immutable SYSTEM_STATUS;

    /// @notice address of contract used to store global settings
    ISettings internal immutable SETTINGS;

    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IAccount
    uint256 public committedMargin;

    /// @inheritdoc IAccount
    uint256 public conditionalOrderId;

    /// @notice track conditional orders by id
    mapping(uint256 id => ConditionalOrder order) internal conditionalOrders;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier isAccountExecutionEnabled() {
        _isAccountExecutionEnabled();

        _;
    }

    function _isAccountExecutionEnabled() internal view {
        if (!SETTINGS.accountExecutionEnabled()) {
            revert AccountExecutionDisabled();
        }
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice disable initializers on initial contract deployment
    /// @dev set owner of implementation to zero address
    /// @param _factory: address of the Smart Margin Account Factory
    /// @param _events: address of the contract used by all accounts for emitting events
    /// @param _marginAsset: address of the Synthetix ProxyERC20sUSD contract used as the margin asset
    /// @param _futuresMarketManager: address of the Synthetix FuturesMarketManager
    /// @param _gelato: address of Gelato
    /// @param _ops: address of Ops
    /// @param _settings: address of contract used to store global settings
    constructor(
        address _factory,
        address _events,
        address _marginAsset,
        address _futuresMarketManager,
        address _systemStatus,
        address _gelato,
        address _ops,
        address _settings
    ) Auth(address(0)) OpsReady(_gelato, _ops) {
        FACTORY = IFactory(_factory);
        EVENTS = IEvents(_events);
        MARGIN_ASSET = IERC20(_marginAsset);
        FUTURES_MARKET_MANAGER = IFuturesMarketManager(_futuresMarketManager);
        SYSTEM_STATUS = ISystemStatus(_systemStatus);
        SETTINGS = ISettings(_settings);
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IAccount
    function getDelayedOrder(bytes32 _marketKey)
        external
        view
        override
        returns (IPerpsV2MarketConsolidated.DelayedOrder memory order)
    {
        // fetch delayed order data from Synthetix
        order = _getPerpsV2Market(_marketKey).delayedOrders(address(this));
    }

    /// @inheritdoc IAccount
    function checker(uint256 _conditionalOrderId)
        external
        view
        returns (bool canExec, bytes memory execPayload)
    {
        canExec = _validConditionalOrder(_conditionalOrderId);

        // calldata for execute func
        execPayload =
            abi.encodeCall(this.executeConditionalOrder, _conditionalOrderId);
    }

    /// @inheritdoc IAccount
    function freeMargin() public view override returns (uint256) {
        return MARGIN_ASSET.balanceOf(address(this)) - committedMargin;
    }

    /// @inheritdoc IAccount
    function getPosition(bytes32 _marketKey)
        public
        view
        override
        returns (IPerpsV2MarketConsolidated.Position memory position)
    {
        // fetch position data from Synthetix
        position = _getPerpsV2Market(_marketKey).positions(address(this));
    }

    /// @inheritdoc IAccount
    function getConditionalOrder(uint256 _conditionalOrderId)
        public
        view
        override
        returns (ConditionalOrder memory)
    {
        return conditionalOrders[_conditionalOrderId];
    }

    /*//////////////////////////////////////////////////////////////
                               OWNERSHIP
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IAccount
    function setInitialOwnership(address _owner) external override {
        if (msg.sender != address(FACTORY)) revert Unauthorized();
        owner = _owner;
        emit OwnershipTransferred(address(0), _owner);
    }

    /// @notice transfer ownership of account to new address
    /// @dev update factory's record of account ownership
    /// @param _newOwner: new account owner
    function transferOwnership(address _newOwner) public override {
        // will revert if msg.sender is *NOT* owner
        super.transferOwnership(_newOwner);

        // update the factory's record of owners and account addresses
        FACTORY.updateAccountOwnership({
            _newOwner: _newOwner,
            _oldOwner: msg.sender // verified to be old owner
        });
    }

    /*//////////////////////////////////////////////////////////////
                               EXECUTION
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IAccount
    function execute(Command[] calldata _commands, bytes[] calldata _inputs)
        external
        payable
        override
        isAccountExecutionEnabled
    {
        uint256 numCommands = _commands.length;
        if (_inputs.length != numCommands) {
            revert LengthMismatch();
        }

        // loop through all given commands and execute them
        for (uint256 commandIndex = 0; commandIndex < numCommands;) {
            _dispatch(_commands[commandIndex], _inputs[commandIndex]);
            unchecked {
                ++commandIndex;
            }
        }
    }

    /// @notice Decodes and executes the given command with the given inputs
    /// @param _command: The command type to execute
    /// @param _inputs: The inputs to execute the command with
    function _dispatch(Command _command, bytes calldata _inputs) internal {
        uint256 commandIndex = uint256(_command);

        if (commandIndex < 2) {
            /// @dev only owner can execute the following commands
            if (!isOwner()) revert Unauthorized();

            if (_command == Command.ACCOUNT_MODIFY_MARGIN) {
                // Command.ACCOUNT_MODIFY_MARGIN
                int256 amount;
                assembly {
                    amount := calldataload(_inputs.offset)
                }
                _modifyAccountMargin({_amount: amount});
            } else {
                // Command.ACCOUNT_WITHDRAW_ETH
                uint256 amount;
                assembly {
                    amount := calldataload(_inputs.offset)
                }
                _withdrawEth({_amount: amount});
            }
        } else {
            /// @dev only owner and delegate(s) can execute the following commands
            if (!isAuth()) revert Unauthorized();

            if (commandIndex < 4) {
                if (_command == Command.PERPS_V2_MODIFY_MARGIN) {
                    // Command.PERPS_V2_MODIFY_MARGIN
                    address market;
                    int256 amount;
                    assembly {
                        market := calldataload(_inputs.offset)
                        amount := calldataload(add(_inputs.offset, 0x20))
                    }
                    _perpsV2ModifyMargin({_market: market, _amount: amount});
                } else {
                    // Command.PERPS_V2_WITHDRAW_ALL_MARGIN
                    address market;
                    assembly {
                        market := calldataload(_inputs.offset)
                    }
                    _perpsV2WithdrawAllMargin({_market: market});
                }
            } else if (commandIndex < 6) {
                if (_command == Command.PERPS_V2_SUBMIT_ATOMIC_ORDER) {
                    // Command.PERPS_V2_SUBMIT_ATOMIC_ORDER
                    address market;
                    int256 sizeDelta;
                    uint256 desiredFillPrice;
                    assembly {
                        market := calldataload(_inputs.offset)
                        sizeDelta := calldataload(add(_inputs.offset, 0x20))
                        desiredFillPrice :=
                            calldataload(add(_inputs.offset, 0x40))
                    }
                    _perpsV2SubmitAtomicOrder({
                        _market: market,
                        _sizeDelta: sizeDelta,
                        _desiredFillPrice: desiredFillPrice
                    });
                } else {
                    // Command.PERPS_V2_SUBMIT_DELAYED_ORDER
                    address market;
                    int256 sizeDelta;
                    uint256 desiredTimeDelta;
                    uint256 desiredFillPrice;
                    assembly {
                        market := calldataload(_inputs.offset)
                        sizeDelta := calldataload(add(_inputs.offset, 0x20))
                        desiredTimeDelta :=
                            calldataload(add(_inputs.offset, 0x40))
                        desiredFillPrice :=
                            calldataload(add(_inputs.offset, 0x60))
                    }
                    _perpsV2SubmitDelayedOrder({
                        _market: market,
                        _sizeDelta: sizeDelta,
                        _desiredTimeDelta: desiredTimeDelta,
                        _desiredFillPrice: desiredFillPrice
                    });
                }
            } else if (commandIndex < 8) {
                if (_command == Command.PERPS_V2_SUBMIT_OFFCHAIN_DELAYED_ORDER)
                {
                    // Command.PERPS_V2_SUBMIT_OFFCHAIN_DELAYED_ORDER
                    address market;
                    int256 sizeDelta;
                    uint256 desiredFillPrice;
                    assembly {
                        market := calldataload(_inputs.offset)
                        sizeDelta := calldataload(add(_inputs.offset, 0x20))
                        desiredFillPrice :=
                            calldataload(add(_inputs.offset, 0x40))
                    }
                    _perpsV2SubmitOffchainDelayedOrder({
                        _market: market,
                        _sizeDelta: sizeDelta,
                        _desiredFillPrice: desiredFillPrice
                    });
                } else {
                    // Command.PERPS_V2_CLOSE_POSITION
                    address market;
                    uint256 desiredFillPrice;
                    assembly {
                        market := calldataload(_inputs.offset)
                        desiredFillPrice :=
                            calldataload(add(_inputs.offset, 0x20))
                    }
                    _perpsV2ClosePosition({
                        _market: market,
                        _desiredFillPrice: desiredFillPrice
                    });
                }
            } else if (commandIndex < 10) {
                if (_command == Command.PERPS_V2_SUBMIT_CLOSE_DELAYED_ORDER) {
                    // Command.PERPS_V2_SUBMIT_CLOSE_DELAYED_ORDER
                    address market;
                    uint256 desiredTimeDelta;
                    uint256 desiredFillPrice;
                    assembly {
                        market := calldataload(_inputs.offset)
                        desiredTimeDelta :=
                            calldataload(add(_inputs.offset, 0x20))
                        desiredFillPrice :=
                            calldataload(add(_inputs.offset, 0x40))
                    }
                    _perpsV2SubmitCloseDelayedOrder({
                        _market: market,
                        _desiredTimeDelta: desiredTimeDelta,
                        _desiredFillPrice: desiredFillPrice
                    });
                } else {
                    // Command.PERPS_V2_SUBMIT_CLOSE_OFFCHAIN_DELAYED_ORDER
                    address market;
                    uint256 desiredFillPrice;
                    assembly {
                        market := calldataload(_inputs.offset)
                        desiredFillPrice :=
                            calldataload(add(_inputs.offset, 0x20))
                    }
                    _perpsV2SubmitCloseOffchainDelayedOrder({
                        _market: market,
                        _desiredFillPrice: desiredFillPrice
                    });
                }
            } else if (commandIndex < 12) {
                if (_command == Command.PERPS_V2_CANCEL_DELAYED_ORDER) {
                    // Command.PERPS_V2_CANCEL_DELAYED_ORDER
                    address market;
                    assembly {
                        market := calldataload(_inputs.offset)
                    }
                    _perpsV2CancelDelayedOrder({_market: market});
                } else {
                    // Command.PERPS_V2_CANCEL_OFFCHAIN_DELAYED_ORDER
                    address market;
                    assembly {
                        market := calldataload(_inputs.offset)
                    }
                    _perpsV2CancelOffchainDelayedOrder({_market: market});
                }
            } else if (commandIndex < 14) {
                if (_command == Command.GELATO_PLACE_CONDITIONAL_ORDER) {
                    // Command.GELATO_PLACE_CONDITIONAL_ORDER
                    bytes32 marketKey;
                    int256 marginDelta;
                    int256 sizeDelta;
                    uint256 targetPrice;
                    ConditionalOrderTypes conditionalOrderType;
                    uint256 desiredFillPrice;
                    bool reduceOnly;
                    assembly {
                        marketKey := calldataload(_inputs.offset)
                        marginDelta := calldataload(add(_inputs.offset, 0x20))
                        sizeDelta := calldataload(add(_inputs.offset, 0x40))
                        targetPrice := calldataload(add(_inputs.offset, 0x60))
                        conditionalOrderType :=
                            calldataload(add(_inputs.offset, 0x80))
                        desiredFillPrice :=
                            calldataload(add(_inputs.offset, 0xa0))
                        reduceOnly := calldataload(add(_inputs.offset, 0xc0))
                    }
                    _placeConditionalOrder({
                        _marketKey: marketKey,
                        _marginDelta: marginDelta,
                        _sizeDelta: sizeDelta,
                        _targetPrice: targetPrice,
                        _conditionalOrderType: conditionalOrderType,
                        _desiredFillPrice: desiredFillPrice,
                        _reduceOnly: reduceOnly
                    });
                } else {
                    // Command.GELATO_CANCEL_CONDITIONAL_ORDER
                    uint256 orderId;
                    assembly {
                        orderId := calldataload(_inputs.offset)
                    }
                    _cancelConditionalOrder({_conditionalOrderId: orderId});
                }
            } else {
                revert InvalidCommandType(commandIndex);
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        ACCOUNT DEPOSIT/WITHDRAW
    //////////////////////////////////////////////////////////////*/

    /// @notice allows ETH to be deposited directly into a margin account
    /// @notice ETH can be withdrawn
    receive() external payable {}

    /// @notice allow users to withdraw ETH deposited for keeper fees
    /// @param _amount: amount to withdraw
    function _withdrawEth(uint256 _amount) internal {
        if (_amount > 0) {
            (bool success,) = payable(owner).call{value: _amount}("");
            if (!success) revert EthWithdrawalFailed();

            EVENTS.emitEthWithdraw({user: msg.sender, amount: _amount});
        }
    }

    /// @notice deposit/withdraw margin to/from this smart margin account
    /// @param _amount: amount of margin to deposit/withdraw
    function _modifyAccountMargin(int256 _amount) internal {
        // if amount is positive, deposit
        if (_amount > 0) {
            /// @dev failed Synthetix asset transfer will revert and not return false if unsuccessful
            MARGIN_ASSET.transferFrom(owner, address(this), _abs(_amount));

            EVENTS.emitDeposit({user: msg.sender, amount: _abs(_amount)});
        } else if (_amount < 0) {
            // if amount is negative, withdraw
            _sufficientMargin(_amount);

            /// @dev failed Synthetix asset transfer will revert and not return false if unsuccessful
            MARGIN_ASSET.transfer(owner, _abs(_amount));

            EVENTS.emitWithdraw({user: msg.sender, amount: _abs(_amount)});
        }
    }

    /*//////////////////////////////////////////////////////////////
                          MODIFY MARKET MARGIN
    //////////////////////////////////////////////////////////////*/

    /// @notice deposit/withdraw margin to/from a Synthetix PerpsV2 Market
    /// @param _market: address of market
    /// @param _amount: amount of margin to deposit/withdraw
    function _perpsV2ModifyMargin(address _market, int256 _amount) internal {
        if (_amount > 0) {
            _sufficientMargin(_amount);
        }
        IPerpsV2MarketConsolidated(_market).transferMargin(_amount);
    }

    /// @notice withdraw margin from market back to this account
    /// @dev this will *not* fail if market has zero margin
    function _perpsV2WithdrawAllMargin(address _market) internal {
        IPerpsV2MarketConsolidated(_market).withdrawAllMargin();
    }

    /*//////////////////////////////////////////////////////////////
                             ATOMIC ORDERS
    //////////////////////////////////////////////////////////////*/

    /// @notice submit an atomic order to a Synthetix PerpsV2 Market
    /// @param _market: address of market
    /// @param _sizeDelta: size delta of order
    /// @param _desiredFillPrice: desired fill price of order
    function _perpsV2SubmitAtomicOrder(
        address _market,
        int256 _sizeDelta,
        uint256 _desiredFillPrice
    ) internal {
        IPerpsV2MarketConsolidated(_market).modifyPositionWithTracking({
            sizeDelta: _sizeDelta,
            desiredFillPrice: _desiredFillPrice,
            trackingCode: TRACKING_CODE
        });
    }

    /// @notice close Synthetix PerpsV2 Market position via an atomic order
    /// @param _market: address of market
    /// @param _desiredFillPrice: desired fill price of order
    function _perpsV2ClosePosition(address _market, uint256 _desiredFillPrice)
        internal
    {
        // close position (i.e. reduce size to zero)
        /// @dev this does not remove margin from market
        IPerpsV2MarketConsolidated(_market).closePositionWithTracking({
            desiredFillPrice: _desiredFillPrice,
            trackingCode: TRACKING_CODE
        });
    }

    /*//////////////////////////////////////////////////////////////
                             DELAYED ORDERS
    //////////////////////////////////////////////////////////////*/

    /// @notice submit a delayed order to a Synthetix PerpsV2 Market
    /// @param _market: address of market
    /// @param _sizeDelta: size delta of order
    /// @param _desiredTimeDelta: desired time delta of order
    /// @param _desiredFillPrice: desired fill price of order
    function _perpsV2SubmitDelayedOrder(
        address _market,
        int256 _sizeDelta,
        uint256 _desiredTimeDelta,
        uint256 _desiredFillPrice
    ) internal {
        IPerpsV2MarketConsolidated(_market).submitDelayedOrderWithTracking({
            sizeDelta: _sizeDelta,
            desiredTimeDelta: _desiredTimeDelta,
            desiredFillPrice: _desiredFillPrice,
            trackingCode: TRACKING_CODE
        });
    }

    /// @notice cancel a *pending* delayed order from a Synthetix PerpsV2 Market
    /// @dev will revert if no previous delayed order
    function _perpsV2CancelDelayedOrder(address _market) internal {
        IPerpsV2MarketConsolidated(_market).cancelDelayedOrder(address(this));
    }

    /// @notice close Synthetix PerpsV2 Market position via a delayed order
    /// @param _market: address of market
    /// @param _desiredTimeDelta: desired time delta of order
    /// @param _desiredFillPrice: desired fill price of order
    function _perpsV2SubmitCloseDelayedOrder(
        address _market,
        uint256 _desiredTimeDelta,
        uint256 _desiredFillPrice
    ) internal {
        // close position (i.e. reduce size to zero)
        /// @dev this does not remove margin from market
        IPerpsV2MarketConsolidated(_market).submitCloseDelayedOrderWithTracking({
            desiredTimeDelta: _desiredTimeDelta,
            desiredFillPrice: _desiredFillPrice,
            trackingCode: TRACKING_CODE
        });
    }

    /*//////////////////////////////////////////////////////////////
                        DELAYED OFF-CHAIN ORDERS
    //////////////////////////////////////////////////////////////*/

    /// @notice submit an off-chain delayed order to a Synthetix PerpsV2 Market
    /// @param _market: address of market
    /// @param _sizeDelta: size delta of order
    /// @param _desiredFillPrice: desired fill price of order
    function _perpsV2SubmitOffchainDelayedOrder(
        address _market,
        int256 _sizeDelta,
        uint256 _desiredFillPrice
    ) internal {
        IPerpsV2MarketConsolidated(_market)
            .submitOffchainDelayedOrderWithTracking({
            sizeDelta: _sizeDelta,
            desiredFillPrice: _desiredFillPrice,
            trackingCode: TRACKING_CODE
        });
    }

    /// @notice cancel a *pending* off-chain delayed order from a Synthetix PerpsV2 Market
    /// @dev will revert if no previous offchain delayed order
    function _perpsV2CancelOffchainDelayedOrder(address _market) internal {
        IPerpsV2MarketConsolidated(_market).cancelOffchainDelayedOrder(
            address(this)
        );
    }

    /// @notice close Synthetix PerpsV2 Market position via an offchain delayed order
    /// @param _market: address of market
    /// @param _desiredFillPrice: desired fill price of order
    function _perpsV2SubmitCloseOffchainDelayedOrder(
        address _market,
        uint256 _desiredFillPrice
    ) internal {
        // close position (i.e. reduce size to zero)
        /// @dev this does not remove margin from market
        IPerpsV2MarketConsolidated(_market)
            .submitCloseOffchainDelayedOrderWithTracking({
            desiredFillPrice: _desiredFillPrice,
            trackingCode: TRACKING_CODE
        });
    }

    /*//////////////////////////////////////////////////////////////
                           CONDITIONAL ORDERS
    //////////////////////////////////////////////////////////////*/

    /// @notice register a conditional order internally and with gelato
    /// @dev restricts _sizeDelta to be non-zero otherwise no need for conditional order
    /// @param _marketKey: Synthetix futures market id/key
    /// @param _marginDelta: amount of margin (in sUSD) to deposit or withdraw
    /// @param _sizeDelta: denominated in market currency (i.e. ETH, BTC, etc), size of position
    /// @param _targetPrice: expected conditional order price
    /// @param _conditionalOrderType: expected conditional order type enum where 0 = LIMIT, 1 = STOP, etc..
    /// @param _desiredFillPrice: desired price to fill Synthetix PerpsV2 order at execution time
    /// @param _reduceOnly: if true, only allows position's absolute size to decrease
    function _placeConditionalOrder(
        bytes32 _marketKey,
        int256 _marginDelta,
        int256 _sizeDelta,
        uint256 _targetPrice,
        ConditionalOrderTypes _conditionalOrderType,
        uint256 _desiredFillPrice,
        bool _reduceOnly
    ) internal {
        if (_sizeDelta == 0) revert ZeroSizeDelta();

        // if more margin is desired on the position we must commit the margin
        if (_marginDelta > 0) {
            _sufficientMargin(_marginDelta);
            committedMargin += _abs(_marginDelta);
        }

        // create and submit Gelato task for this conditional order
        bytes32 taskId = _createGelatoTask();

        // internally store the conditional order
        conditionalOrders[conditionalOrderId] = ConditionalOrder({
            marketKey: _marketKey,
            marginDelta: _marginDelta,
            sizeDelta: _sizeDelta,
            targetPrice: _targetPrice,
            gelatoTaskId: taskId,
            conditionalOrderType: _conditionalOrderType,
            desiredFillPrice: _desiredFillPrice,
            reduceOnly: _reduceOnly
        });

        EVENTS.emitConditionalOrderPlaced({
            conditionalOrderId: conditionalOrderId,
            gelatoTaskId: taskId,
            marketKey: _marketKey,
            marginDelta: _marginDelta,
            sizeDelta: _sizeDelta,
            targetPrice: _targetPrice,
            conditionalOrderType: _conditionalOrderType,
            desiredFillPrice: _desiredFillPrice,
            reduceOnly: _reduceOnly
        });

        ++conditionalOrderId;
    }

    /// @notice create a new Gelato task for a conditional order
    /// @return taskId of the new Gelato task
    function _createGelatoTask() internal returns (bytes32 taskId) {
        IOps.ModuleData memory moduleData = _createGelatoModuleData();

        taskId = IOps(OPS).createTask({
            execAddress: address(this),
            execData: abi.encodeCall(
                this.executeConditionalOrder, conditionalOrderId
                ),
            moduleData: moduleData,
            feeToken: ETH
        });
    }

    /// @notice create the Gelato ModuleData for a conditional order
    /// @dev see IOps for details on the task creation and the ModuleData struct
    function _createGelatoModuleData()
        internal
        view
        returns (IOps.ModuleData memory moduleData)
    {
        moduleData = IOps.ModuleData({
            modules: new IOps.Module[](1),
            args: new bytes[](1)
        });

        moduleData.modules[0] = IOps.Module.RESOLVER;
        moduleData.args[0] = abi.encode(
            address(this), abi.encodeCall(this.checker, conditionalOrderId)
        );
    }

    /// @notice cancel a gelato queued conditional order
    /// @param _conditionalOrderId: key for an active conditional order
    function _cancelConditionalOrder(uint256 _conditionalOrderId) internal {
        ConditionalOrder memory conditionalOrder =
            getConditionalOrder(_conditionalOrderId);

        // if margin was committed, free it
        if (conditionalOrder.marginDelta > 0) {
            committedMargin -= _abs(conditionalOrder.marginDelta);
        }

        // cancel gelato task
        /// @dev will revert if task id does not exist {Automate.cancelTask: Task not found}
        IOps(OPS).cancelTask({taskId: conditionalOrder.gelatoTaskId});

        // delete order from conditional orders
        delete conditionalOrders[_conditionalOrderId];

        EVENTS.emitConditionalOrderCancelled({
            conditionalOrderId: _conditionalOrderId,
            gelatoTaskId: conditionalOrder.gelatoTaskId,
            reason: ConditionalOrderCancelledReason
                .CONDITIONAL_ORDER_CANCELLED_BY_USER
        });
    }

    /*//////////////////////////////////////////////////////////////
                   GELATO CONDITIONAL ORDER HANDLING
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IAccount
    function executeConditionalOrder(uint256 _conditionalOrderId)
        external
        override
        isAccountExecutionEnabled
        onlyOps
    {
        ConditionalOrder memory conditionalOrder =
            getConditionalOrder(_conditionalOrderId);

        // remove conditional order from internal accounting
        delete conditionalOrders[_conditionalOrderId];

        // remove gelato task from their accounting
        /// @dev will revert if task id does not exist {Automate.cancelTask: Task not found}
        IOps(OPS).cancelTask({taskId: conditionalOrder.gelatoTaskId});

        // define Synthetix PerpsV2 market
        IPerpsV2MarketConsolidated market =
            _getPerpsV2Market(conditionalOrder.marketKey);

        /// @dev conditional order is valid given checker() returns true; define fill price
        uint256 fillPrice = _sUSDRate(market);

        // if conditional order is reduce only, ensure position size is only reduced
        if (conditionalOrder.reduceOnly) {
            int256 currentSize = market.positions({account: address(this)}).size;

            // ensure position exists and incoming size delta is NOT the same sign
            /// @dev if incoming size delta is the same sign, then the conditional order is not reduce only
            if (
                currentSize == 0
                    || _isSameSign(currentSize, conditionalOrder.sizeDelta)
            ) {
                EVENTS.emitConditionalOrderCancelled({
                    conditionalOrderId: _conditionalOrderId,
                    gelatoTaskId: conditionalOrder.gelatoTaskId,
                    reason: ConditionalOrderCancelledReason
                        .CONDITIONAL_ORDER_CANCELLED_NOT_REDUCE_ONLY
                });

                return;
            }

            // ensure incoming size delta is not larger than current position size
            /// @dev reduce only conditional orders can only reduce position size (i.e. approach size of zero) and
            /// cannot cross that boundary (i.e. short -> long or long -> short)
            if (_abs(conditionalOrder.sizeDelta) > _abs(currentSize)) {
                // bound conditional order size delta to current position size
                conditionalOrder.sizeDelta = -currentSize;
            }
        }

        // if margin was committed, free it
        if (conditionalOrder.marginDelta > 0) {
            committedMargin -= _abs(conditionalOrder.marginDelta);
        }

        // execute trade
        _perpsV2ModifyMargin({
            _market: address(market),
            _amount: conditionalOrder.marginDelta
        });
        _perpsV2SubmitOffchainDelayedOrder({
            _market: address(market),
            _sizeDelta: conditionalOrder.sizeDelta,
            _desiredFillPrice: conditionalOrder.desiredFillPrice
        });

        // pay Gelato imposed fee for conditional order execution
        (uint256 fee, address feeToken) = IOps(OPS).getFeeDetails();
        _transfer({_amount: fee, _paymentToken: feeToken});

        EVENTS.emitConditionalOrderFilled({
            conditionalOrderId: _conditionalOrderId,
            gelatoTaskId: conditionalOrder.gelatoTaskId,
            fillPrice: fillPrice,
            keeperFee: fee
        });
    }

    /// @notice order logic condition checker
    /// @dev this is where order type logic checks are handled
    /// @param _conditionalOrderId: key for an active order
    /// @return true if conditional order is valid by execution rules
    function _validConditionalOrder(uint256 _conditionalOrderId)
        internal
        view
        returns (bool)
    {
        ConditionalOrder memory conditionalOrder =
            getConditionalOrder(_conditionalOrderId);

        // return false if market is paused
        try SYSTEM_STATUS.requireFuturesMarketActive(conditionalOrder.marketKey)
        {} catch {
            return false;
        }

        /// @dev if marketKey is invalid, this will revert
        uint256 price = _sUSDRate(_getPerpsV2Market(conditionalOrder.marketKey));

        // check if markets satisfy specific order type
        if (
            conditionalOrder.conditionalOrderType == ConditionalOrderTypes.LIMIT
        ) {
            return _validLimitOrder(conditionalOrder, price);
        } else if (
            conditionalOrder.conditionalOrderType == ConditionalOrderTypes.STOP
        ) {
            return _validStopOrder(conditionalOrder, price);
        }

        // unknown order type
        return false;
    }

    /// @notice limit order logic condition checker
    /// @dev sizeDelta will never be zero due to check when submitting conditional order
    /// @param _conditionalOrder: struct for an active conditional order
    /// @param _price: current price of market asset
    /// @return true if conditional order is valid by execution rules
    function _validLimitOrder(
        ConditionalOrder memory _conditionalOrder,
        uint256 _price
    ) internal pure returns (bool) {
        if (_conditionalOrder.sizeDelta > 0) {
            // Long: increase position size (buy) once *below* target price
            // ex: open long position once price is below target
            return _price <= _conditionalOrder.targetPrice;
        } else {
            // Short: decrease position size (sell) once *above* target price
            // ex: open short position once price is above target
            return _price >= _conditionalOrder.targetPrice;
        }
    }

    /// @notice stop order logic condition checker
    /// @dev sizeDelta will never be zero due to check when submitting order
    /// @param _conditionalOrder: struct for an active conditional order
    /// @param _price: current price of market asset
    /// @return true if conditional order is valid by execution rules
    function _validStopOrder(
        ConditionalOrder memory _conditionalOrder,
        uint256 _price
    ) internal pure returns (bool) {
        if (_conditionalOrder.sizeDelta > 0) {
            // Long: increase position size (buy) once *above* target price
            // ex: unwind short position once price is above target (prevent further loss)
            return _price >= _conditionalOrder.targetPrice;
        } else {
            // Short: decrease position size (sell) once *below* target price
            // ex: unwind long position once price is below target (prevent further loss)
            return _price <= _conditionalOrder.targetPrice;
        }
    }

    /*//////////////////////////////////////////////////////////////
                            MARGIN UTILITIES
    //////////////////////////////////////////////////////////////*/

    /// @notice check that margin attempted to be moved/locked is within free margin bounds
    /// @param _marginOut: amount of margin to be moved/locked
    function _sufficientMargin(int256 _marginOut) internal view {
        if (_abs(_marginOut) > freeMargin()) {
            revert InsufficientFreeMargin(freeMargin(), _abs(_marginOut));
        }
    }

    /*//////////////////////////////////////////////////////////////
                            GETTER UTILITIES
    //////////////////////////////////////////////////////////////*/

    /// @notice fetch PerpsV2Market market defined by market key
    /// @param _marketKey: key for Synthetix PerpsV2 market
    /// @return IPerpsV2MarketConsolidated contract interface
    function _getPerpsV2Market(bytes32 _marketKey)
        internal
        view
        returns (IPerpsV2MarketConsolidated)
    {
        return IPerpsV2MarketConsolidated(
            FUTURES_MARKET_MANAGER.marketForKey(_marketKey)
        );
    }

    /// @notice get exchange rate of underlying market asset in terms of sUSD
    /// @param _market: Synthetix PerpsV2 Market
    /// @return price in sUSD
    function _sUSDRate(IPerpsV2MarketConsolidated _market)
        internal
        view
        returns (uint256)
    {
        (uint256 price, bool invalid) = _market.assetPrice();
        if (invalid) {
            revert InvalidPrice();
        }
        return price;
    }

    /*//////////////////////////////////////////////////////////////
                             MATH UTILITIES
    //////////////////////////////////////////////////////////////*/

    /// @notice get absolute value of the input, returned as an unsigned number.
    /// @param x: signed number
    /// @return z uint256 absolute value of x
    function _abs(int256 x) internal pure returns (uint256 z) {
        assembly {
            let mask := sub(0, shr(255, x))
            z := xor(mask, add(mask, x))
        }
    }

    /// @notice determines if input numbers have the same sign
    /// @dev asserts that both numbers are not zero
    /// @param x: signed number
    /// @param y: signed number
    /// @return true if same sign, false otherwise
    function _isSameSign(int256 x, int256 y) internal pure returns (bool) {
        assert(x != 0 && y != 0);
        return (x ^ y) >= 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import {IEvents} from "./IEvents.sol";
import {IFactory} from "./IFactory.sol";
import {IFuturesMarketManager} from "./synthetix/IFuturesMarketManager.sol";
import {IPerpsV2MarketConsolidated} from
    "./synthetix/IPerpsV2MarketConsolidated.sol";
import {ISettings} from "./ISettings.sol";
import {ISystemStatus} from "./synthetix/ISystemStatus.sol";

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
        ACCOUNT_WITHDRAW_ETH,
        PERPS_V2_MODIFY_MARGIN,
        PERPS_V2_WITHDRAW_ALL_MARGIN,
        PERPS_V2_SUBMIT_ATOMIC_ORDER,
        PERPS_V2_SUBMIT_DELAYED_ORDER, // 5
        PERPS_V2_SUBMIT_OFFCHAIN_DELAYED_ORDER,
        PERPS_V2_CLOSE_POSITION,
        PERPS_V2_SUBMIT_CLOSE_DELAYED_ORDER,
        PERPS_V2_SUBMIT_CLOSE_OFFCHAIN_DELAYED_ORDER,
        PERPS_V2_CANCEL_DELAYED_ORDER, // 10
        PERPS_V2_CANCEL_OFFCHAIN_DELAYED_ORDER,
        GELATO_PLACE_CONDITIONAL_ORDER,
        GELATO_CANCEL_CONDITIONAL_ORDER
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
    function getDelayedOrder(bytes32 _marketKey)
        external
        returns (IPerpsV2MarketConsolidated.DelayedOrder memory);

    /// @notice checker() is the Resolver for Gelato
    /// (see https://docs.gelato.network/developer-services/automate/guides/custom-logic-triggers/smart-contract-resolvers)
    /// @notice signal to a keeper that a conditional order is valid/invalid for execution
    /// @dev call reverts if conditional order Id does not map to a valid conditional order;
    /// ConditionalOrder.marketKey would be invalid
    /// @param _conditionalOrderId: key for an active conditional order
    /// @return canExec boolean that signals to keeper a conditional order can be executed by Gelato
    /// @return execPayload calldata for executing a conditional order
    function checker(uint256 _conditionalOrderId)
        external
        view
        returns (bool canExec, bytes memory execPayload);

    /// @notice the current withdrawable or usable balance
    /// @return free margin amount
    function freeMargin() external view returns (uint256);

    /// @notice get up-to-date position data from Synthetix PerpsV2
    /// @param _marketKey: key for Synthetix PerpsV2 Market
    /// @return position struct defining current position
    function getPosition(bytes32 _marketKey)
        external
        returns (IPerpsV2MarketConsolidated.Position memory);

    /// @notice conditional order id mapped to conditional order
    /// @param _conditionalOrderId: id of conditional order
    /// @return conditional order
    function getConditionalOrder(uint256 _conditionalOrderId)
        external
        view
        returns (ConditionalOrder memory);

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
    function execute(Command[] calldata _commands, bytes[] calldata _inputs)
        external
        payable;

    /// @notice execute a gelato queued conditional order
    /// @notice only keepers can trigger this function
    /// @dev currently only supports conditional order submission via PERPS_V2_SUBMIT_OFFCHAIN_DELAYED_ORDER COMMAND
    /// @param _conditionalOrderId: key for an active conditional order
    function executeConditionalOrder(uint256 _conditionalOrderId) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

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

    event Deposit(
        address indexed user, address indexed account, uint256 amount
    );

    /// @notice emitted after a successful withdrawal
    /// @param user: the address that withdrew from account
    /// @param amount: amount of marginAsset to withdraw from account
    function emitWithdraw(address user, uint256 amount) external;

    event Withdraw(
        address indexed user, address indexed account, uint256 amount
    );

    /// @notice emitted after a successful ETH withdrawal
    /// @param user: the address that withdrew from account
    /// @param amount: amount of ETH to withdraw from account
    function emitEthWithdraw(address user, uint256 amount) external;

    event EthWithdraw(
        address indexed user, address indexed account, uint256 amount
    );

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
pragma solidity ^0.8.18;

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
    event NewAccount(
        address indexed creator, address indexed account, bytes32 version
    );

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
    function getAccountOwner(address _account)
        external
        view
        returns (address);

    /// @param _owner: address of owner
    /// @return array of accounts owned by _owner
    function getAccountsOwnedBy(address _owner)
        external
        view
        returns (address[] memory);

    /*//////////////////////////////////////////////////////////////
                               OWNERSHIP
    //////////////////////////////////////////////////////////////*/

    /// @notice update owner to account(s) mapping
    /// @dev does *NOT* check new owner != old owner
    /// @param _newOwner: new owner of account
    /// @param _oldOwner: old owner of account
    function updateAccountOwnership(address _newOwner, address _oldOwner)
        external;

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

interface IOps {
    /**
     * @notice Whitelisted modules that are available for users to customise conditions and specifications of their tasks.
     *
     * @param RESOLVER Use dynamic condition & input data for execution. {See ResolverModule.sol}
     * @param TIME Repeated execution of task at a specified timing and interval. {See TimeModule.sol}
     * @param PROXY Creates a dedicated caller (msg.sender) to be used when executing the task. {See ProxyModule.sol}
     * @param SINGLE_EXEC Task is cancelled after one execution. {See SingleExecModule.sol}
     */
    enum Module {
        RESOLVER,
        TIME,
        PROXY,
        SINGLE_EXEC
    }

    /**
     * @notice Struct to contain modules and their relative arguments that are used for task creation.
     *
     * @param modules List of selected modules.
     * @param args Arguments of modules if any. Pass "0x" for modules which does not require args {See encodeModuleArg}
     */
    struct ModuleData {
        Module[] modules;
        bytes[] args;
    }

    /**
     * @notice Struct for time module.
     *
     * @param nextExec Time when the next execution should occur.
     * @param interval Time interval between each execution.
     */
    struct Time {
        uint128 nextExec;
        uint128 interval;
    }

    /**
     * @notice Initiates a task with conditions which Gelato will monitor and execute when conditions are met.
     *
     * @param execAddress Address of contract that should be called by Gelato.
     * @param execData Execution data to be called with / function selector if execution data is yet to be determined.
     * @param moduleData Conditional modules that will be used.
     * @param feeToken Address of token to be used as payment. Use address(0) if TaskTreasury is being used, 0xeeeeee... for ETH or native tokens.
     *
     * @return taskId Unique hash of the task created.
     */
    function createTask(
        address execAddress,
        bytes calldata execData,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    /**
     * @notice Terminates a task that was created and Gelato can no longer execute it.
     *
     * @param taskId Unique hash of the task that is being cancelled. {See LibTaskId-getTaskId}
     */
    function cancelTask(bytes32 taskId) external;

    /**
     * @notice Execution API called by Gelato.
     *
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that should be called by Gelato.
     * @param execData Execution data to be called with / function selector if execution data is yet to be determined.
     * @param moduleData Conditional modules that will be used.
     * @param txFee Fee paid to Gelato for execution, deducted on the TaskTreasury or transfered to Gelato.
     * @param feeToken Token used to pay for the execution. ETH = 0xeeeeee...
     * @param useTaskTreasuryFunds If taskCreator's balance on TaskTreasury should pay for the tx.
     * @param revertOnFailure To revert or not if call to execAddress fails. (Used for off-chain simulations)
     */
    function exec(
        address taskCreator,
        address execAddress,
        bytes memory execData,
        ModuleData calldata moduleData,
        uint256 txFee,
        address feeToken,
        bool useTaskTreasuryFunds,
        bool revertOnFailure
    ) external;

    /**
     * @notice Sets the address of task modules. Only callable by proxy admin.
     *
     * @param modules List of modules to be set
     * @param moduleAddresses List of addresses for respective modules.
     */
    function setModule(
        Module[] calldata modules,
        address[] calldata moduleAddresses
    ) external;

    /**
     * @notice Helper function to query fee and feeToken to be used for payment. (For executions which pays itself)
     *
     * @return uint256 Fee amount to be paid.
     * @return address Token to be paid. (Determined and passed by taskCreator during createTask)
     */
    function getFeeDetails() external view returns (uint256, address);

    /**
     * @notice Helper func to query all open tasks by a task creator.
     *
     * @param taskCreator Address of task creator to query.
     *
     * @return bytes32[] List of taskIds created.
     */
    function getTaskIdsByUser(address taskCreator)
        external
        view
        returns (bytes32[] memory);

    /**
     * @notice Helper function to compute task id with module arguments
     *
     * @param taskCreator The address which created the task.
     * @param execAddress Address of contract that will be called by Gelato.
     * @param execSelector Signature of the function which will be called by Gelato.
     * @param moduleData  Conditional modules that will be used. {See LibDataTypes-ModuleData}
     * @param feeToken Address of token to be used as payment. Use address(0) if TaskTreasury is being used, 0xeeeeee... for ETH or native tokens.
     */
    function getTaskId(
        address taskCreator,
        address execAddress,
        bytes4 execSelector,
        ModuleData memory moduleData,
        address feeToken
    ) external pure returns (bytes32 taskId);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

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
pragma solidity ^0.8.18;

interface IFuturesMarketManager {
    function marketForKey(bytes32 marketKey) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

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

    function positions(address account)
        external
        view
        returns (Position memory);

    function delayedOrders(address account)
        external
        view
        returns (DelayedOrder memory);

    function assetPrice() external view returns (uint256 price, bool invalid);

    function transferMargin(int256 marginDelta) external;

    function withdrawAllMargin() external;

    function modifyPositionWithTracking(
        int256 sizeDelta,
        uint256 desiredFillPrice,
        bytes32 trackingCode
    ) external;

    function closePositionWithTracking(
        uint256 desiredFillPrice,
        bytes32 trackingCode
    ) external;

    function submitCloseOffchainDelayedOrderWithTracking(
        uint256 desiredFillPrice,
        bytes32 trackingCode
    ) external;

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

    function submitOffchainDelayedOrderWithTracking(
        int256 sizeDelta,
        uint256 desiredFillPrice,
        bytes32 trackingCode
    ) external;

    function cancelDelayedOrder(address account) external;

    function cancelOffchainDelayedOrder(address account) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

interface ISystemStatus {
    function requireFuturesMarketActive(bytes32 marketKey) external view;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

/// @notice Authorization mixin for Smart Margin Accounts
/// @author JaredBorders ([email protected])
/// @dev This contract is intended to be inherited by the Account contract
abstract contract Auth {
    /*//////////////////////////////////////////////////////////////
                                 STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice owner of the account
    address public owner;

    /// @notice mapping of delegate address
    mapping(address delegate => bool) public delegates;

    /// @dev reserved storage space for future contract upgrades
    /// @custom:caution reduce storage size when adding new storage variables
    uint256[19] private __gap;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice thrown when an unauthorized caller attempts
    /// to access a caller restricted function
    error Unauthorized();

    /// @notice thrown when the delegate address is invalid
    /// @param delegateAddress: address of the delegate attempting to be added
    error InvalidDelegateAddress(address delegateAddress);

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice emitted after ownership transfer
    /// @param caller: previous owner
    /// @param newOwner: new owner
    event OwnershipTransferred(
        address indexed caller, address indexed newOwner
    );

    /// @notice emitted after a delegate is added
    /// @param caller: owner of the account
    /// @param delegate: address of the delegate being added
    event DelegatedAccountAdded(
        address indexed caller, address indexed delegate
    );

    /// @notice emitted after a delegate is removed
    /// @param caller: owner of the account
    /// @param delegate: address of the delegate being removed
    event DelegatedAccountRemoved(
        address indexed caller, address indexed delegate
    );

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @dev sets owner to _owner and not msg.sender
    /// @param _owner The address of the owner
    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEWS
    //////////////////////////////////////////////////////////////*/

    /// @return true if the caller is the owner
    function isOwner() public view virtual returns (bool) {
        return (msg.sender == owner);
    }

    /// @return true if the caller is the owner or a delegate
    function isAuth() public view virtual returns (bool) {
        return (msg.sender == owner || delegates[msg.sender]);
    }

    /*//////////////////////////////////////////////////////////////
                                SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Transfer ownership of the account
    /// @dev only owner can transfer ownership (not delegates)
    /// @param _newOwner The address of the new owner
    function transferOwnership(address _newOwner) public virtual {
        if (!isOwner()) revert Unauthorized();

        owner = _newOwner;

        emit OwnershipTransferred(msg.sender, _newOwner);
    }

    /// @notice Add a delegate to the account
    /// @dev only owner can add a delegate (not delegates)
    /// @param _delegate The address of the delegate
    function addDelegate(address _delegate) public virtual {
        if (!isOwner()) revert Unauthorized();

        if (_delegate == address(0) || delegates[_delegate]) {
            revert InvalidDelegateAddress(_delegate);
        }

        delegates[_delegate] = true;

        emit DelegatedAccountAdded({caller: msg.sender, delegate: _delegate});
    }

    /// @notice Remove a delegate from the account
    /// @dev only owner can remove a delegate (not delegates)
    /// @param _delegate The address of the delegate
    function removeDelegate(address _delegate) public virtual {
        if (!isOwner()) revert Unauthorized();

        if (_delegate == address(0) || !delegates[_delegate]) {
            revert InvalidDelegateAddress(_delegate);
        }

        delete delegates[_delegate];

        emit DelegatedAccountRemoved({caller: msg.sender, delegate: _delegate});
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import {IOps} from "../interfaces/IOps.sol";

/// @dev Inherit this contract to allow your smart
/// contract to make synchronous fee payments and have
/// call restrictions for functions to be automated.
abstract contract OpsReady {
    error OnlyOps();

    /// @notice address of Gelato Network contract
    address public immutable GELATO;

    /// @notice address of Gelato `Automate` contract
    address public immutable OPS;

    /// @notice internal address representation of ETH (used by Gelato)
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice modifier to restrict access to the `Automate` contract
    modifier onlyOps() {
        if (msg.sender != OPS) revert OnlyOps();
        _;
    }

    /// @notice sets the addresses of the Gelato Network contracts
    /// @param _gelato: address of the Gelato Network contract
    /// @param _ops: address of the Gelato `Automate` contract
    constructor(address _gelato, address _ops) {
        GELATO = _gelato;
        OPS = _ops;
    }

    /// @notice transfers fee (in ETH) to gelato for synchronous fee payments
    /// @dev happens at task execution time
    /// @param _amount: amount of asset to transfer
    /// @param _paymentToken: address of the token to transfer
    function _transfer(uint256 _amount, address _paymentToken) internal {
        /// @dev Smart Margin Accounts will only pay fees in ETH
        assert(_paymentToken == ETH);
        (bool success,) = GELATO.call{value: _amount}("");
        require(success, "OpsReady: ETH transfer failed");
    }
}