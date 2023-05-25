// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import {IEvents, IAccount} from "./interfaces/IEvents.sol";
import {IFactory} from "./interfaces/IFactory.sol";

/// @title Consolidates all events emitted by the Smart Margin Accounts
/// @dev restricted to only Smart Margin Accounts
/// @author JaredBorders ([email protected])
contract Events is IEvents {
    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEvents
    address public immutable factory;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /// @dev modifier that restricts access to only accounts
    modifier onlyAccounts() {
        if (!IFactory(factory).accounts(msg.sender)) {
            revert OnlyAccounts();
        }

        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice constructs the Events contract
    /// @param _factory: address of the factory contract
    constructor(address _factory) {
        factory = _factory;
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IEvents
    function emitDeposit(address user, uint256 amount)
        external
        override
        onlyAccounts
    {
        emit Deposit({user: user, account: msg.sender, amount: amount});
    }

    /// @inheritdoc IEvents
    function emitWithdraw(address user, uint256 amount)
        external
        override
        onlyAccounts
    {
        emit Withdraw({user: user, account: msg.sender, amount: amount});
    }

    /// @inheritdoc IEvents
    function emitEthWithdraw(address user, uint256 amount)
        external
        override
        onlyAccounts
    {
        emit EthWithdraw({user: user, account: msg.sender, amount: amount});
    }

    /// @inheritdoc IEvents
    function emitConditionalOrderPlaced(
        uint256 conditionalOrderId,
        bytes32 marketKey,
        int256 marginDelta,
        int256 sizeDelta,
        uint256 targetPrice,
        IAccount.ConditionalOrderTypes conditionalOrderType,
        uint256 desiredFillPrice,
        bool reduceOnly
    ) external override onlyAccounts {
        emit ConditionalOrderPlaced({
            account: msg.sender,
            conditionalOrderId: conditionalOrderId,
            marketKey: marketKey,
            marginDelta: marginDelta,
            sizeDelta: sizeDelta,
            targetPrice: targetPrice,
            conditionalOrderType: conditionalOrderType,
            desiredFillPrice: desiredFillPrice,
            reduceOnly: reduceOnly
        });
    }

    /// @inheritdoc IEvents
    function emitConditionalOrderCancelled(
        uint256 conditionalOrderId,
        IAccount.ConditionalOrderCancelledReason reason
    ) external override onlyAccounts {
        emit ConditionalOrderCancelled({
            account: msg.sender,
            conditionalOrderId: conditionalOrderId,
            reason: reason
        });
    }

    /// @inheritdoc IEvents
    function emitConditionalOrderFilled(
        uint256 conditionalOrderId,
        uint256 fillPrice,
        uint256 keeperFee
    ) external override onlyAccounts {
        emit ConditionalOrderFilled({
            account: msg.sender,
            conditionalOrderId: conditionalOrderId,
            fillPrice: fillPrice,
            keeperFee: keeperFee
        });
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

import {IEvents} from "./IEvents.sol";
import {IFactory} from "./IFactory.sol";
import {IFuturesMarketManager} from "./tribeone/IFuturesMarketManager.sol";
import {IPerpsV2MarketConsolidated} from "./tribeone/IPerpsV2MarketConsolidated.sol";
import {ISystemStatus} from "./tribeone/ISystemStatus.sol";

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
    function getDelayedOrder(
        bytes32 _marketKey
    ) external returns (IPerpsV2MarketConsolidated.DelayedOrder memory);

    /// @notice checker() is the Resolver for Gelato
    /// (see https://docs.gelato.network/developer-services/automate/guides/custom-logic-triggers/smart-contract-resolvers)
    /// @notice signal to a keeper that a conditional order is valid/invalid for execution
    /// @dev call reverts if conditional order Id does not map to a valid conditional order;
    /// ConditionalOrder.marketKey would be invalid
    /// @param _conditionalOrderId: key for an active conditional order
    /// @return canExec boolean that signals to keeper a conditional order can be executed by Gelato
    /// @return execPayload calldata for executing a conditional order
    function checker(
        uint256 _conditionalOrderId
    ) external view returns (bool canExec, bytes memory execPayload);

    /// @notice the current withdrawable or usable balance
    /// @return free margin amount
    function freeMargin() external view returns (uint256);

    /// @notice get up-to-date position data from Synthetix PerpsV2
    /// @param _marketKey: key for Synthetix PerpsV2 Market
    /// @return position struct defining current position
    function getPosition(
        bytes32 _marketKey
    ) external returns (IPerpsV2MarketConsolidated.Position memory);

    /// @notice conditional order id mapped to conditional order
    /// @param _conditionalOrderId: id of conditional order
    /// @return conditional order
    function getConditionalOrder(
        uint256 _conditionalOrderId
    ) external view returns (ConditionalOrder memory);

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
    function execute(
        Command[] calldata _commands,
        bytes[] calldata _inputs
    ) external payable;

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
    /// @param marketKey: Synthetix PerpsV2 market key
    /// @param marginDelta: margin change
    /// @param sizeDelta: size change
    /// @param targetPrice: targeted fill price
    /// @param conditionalOrderType: expected conditional order type enum where 0 = LIMIT, 1 = STOP, etc..
    /// @param desiredFillPrice: desired price to fill Synthetix PerpsV2 order at execution time
    /// @param reduceOnly: if true, only allows position's absolute size to decrease
    function emitConditionalOrderPlaced(
        uint256 conditionalOrderId,
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
        uint256 conditionalOrderId,
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
    /// @param reason: reason for cancellation
    function emitConditionalOrderCancelled(
        uint256 conditionalOrderId,
        IAccount.ConditionalOrderCancelledReason reason
    ) external;

    event ConditionalOrderCancelled(
        address indexed account,
        uint256 conditionalOrderId,
        IAccount.ConditionalOrderCancelledReason reason
    );

    /// @notice emitted when a conditional order is filled
    /// @param conditionalOrderId: id of conditional order
    /// @param fillPrice: price the conditional order was executed at
    /// @param keeperFee: fees paid to the executor
    function emitConditionalOrderFilled(
        uint256 conditionalOrderId,
        uint256 fillPrice,
        uint256 keeperFee
    ) external;

    event ConditionalOrderFilled(
        address indexed account,
        uint256 conditionalOrderId,
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