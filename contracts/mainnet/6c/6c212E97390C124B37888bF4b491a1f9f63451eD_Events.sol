// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ICopyWallet, IEvents} from "./interfaces/IEvents.sol";
import {IFactory} from "./interfaces/IFactory.sol";

contract Events is IEvents {
    /* ========== STATE ========== */

    address public immutable factory;

    /* ========== MODIFIER ========== */

    modifier onlyCopyWallets() {
        if (!IFactory(factory).accounts(msg.sender)) {
            revert OnlyCopyWallets();
        }
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor(address _factory) {
        factory = _factory;
    }

    /* ========== EMIT ========== */

    function emitDeposit(
        address user,
        uint256 amount
    ) external override onlyCopyWallets {
        emit Deposit({user: user, copyWallet: msg.sender, amount: amount});
    }

    function emitWithdraw(
        address user,
        uint256 amount
    ) external override onlyCopyWallets {
        emit Withdraw({user: user, copyWallet: msg.sender, amount: amount});
    }

    function emitEthWithdraw(
        address user,
        uint256 amount
    ) external override onlyCopyWallets {
        emit EthWithdraw({user: user, copyWallet: msg.sender, amount: amount});
    }

    function emitChargeExecutorFee(
        address executor,
        address receiver,
        uint256 fee,
        uint256 feeUsd
    ) external override onlyCopyWallets {
        emit ChargeExecutorFee({
            executor: executor,
            receiver: receiver,
            copyWallet: msg.sender,
            fee: fee,
            feeUsd: feeUsd
        });
    }

    function emitChargeProtocolFee(
        address receiver,
        uint256 sizeUsd,
        uint256 feeUsd
    ) external override onlyCopyWallets {
        emit ChargeProtocolFee({
            receiver: receiver,
            copyWallet: msg.sender,
            sizeUsd: sizeUsd,
            feeUsd: feeUsd
        });
    }

    function emitCreateGelatoTask(
        uint256 taskId,
        bytes32 gelatoTaskId,
        ICopyWallet.TaskCommand command,
        address source,
        uint256 market,
        int256 collateralDelta,
        int256 sizeDelta,
        uint256 triggerPrice,
        uint256 acceptablePrice,
        address referrer
    ) external override onlyCopyWallets {
        emit CreateGelatoTask({
            copyWallet: msg.sender,
            taskId: taskId,
            gelatoTaskId: gelatoTaskId,
            command: command,
            source: source,
            market: market,
            collateralDelta: collateralDelta,
            sizeDelta: sizeDelta,
            triggerPrice: triggerPrice,
            acceptablePrice: acceptablePrice,
            referrer: referrer
        });
    }

    function emitUpdateGelatoTask(
        uint256 taskId,
        bytes32 gelatoTaskId,
        int256 collateralDelta,
        int256 sizeDelta,
        uint256 triggerPrice,
        uint256 acceptablePrice
    ) external override onlyCopyWallets {
        emit UpdateGelatoTask({
            copyWallet: msg.sender,
            taskId: taskId,
            gelatoTaskId: gelatoTaskId,
            collateralDelta: collateralDelta,
            sizeDelta: sizeDelta,
            triggerPrice: triggerPrice,
            acceptablePrice: acceptablePrice
        });
    }

    function emitCancelGelatoTask(
        uint256 taskId,
        bytes32 gelatoTaskId,
        bytes32 reason
    ) external override onlyCopyWallets {
        emit CancelGelatoTask({
            copyWallet: msg.sender,
            taskId: taskId,
            gelatoTaskId: gelatoTaskId,
            reason: reason
        });
    }

    function emitGelatoTaskRunned(
        uint256 taskId,
        bytes32 gelatoTaskId,
        uint256 fillPrice,
        uint256 fee
    ) external override onlyCopyWallets {
        emit GelatoTaskRunned({
            copyWallet: msg.sender,
            taskId: taskId,
            gelatoTaskId: gelatoTaskId,
            fillPrice: fillPrice,
            fee: fee
        });
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ICopyWallet} from "./ICopyWallet.sol";

interface IEvents {
    error OnlyCopyWallets();

    function factory() external view returns (address);

    function emitDeposit(address user, uint256 amount) external;

    event Deposit(
        address indexed user,
        address indexed copyWallet,
        uint256 amount
    );

    function emitWithdraw(address user, uint256 amount) external;

    event Withdraw(
        address indexed user,
        address indexed copyWallet,
        uint256 amount
    );

    function emitEthWithdraw(address user, uint256 amount) external;

    event EthWithdraw(
        address indexed user,
        address indexed copyWallet,
        uint256 amount
    );

    function emitChargeExecutorFee(
        address executor,
        address receiver,
        uint256 fee,
        uint256 feeUsd
    ) external;

    event ChargeExecutorFee(
        address indexed executor,
        address indexed receiver,
        address indexed copyWallet,
        uint256 fee,
        uint256 feeUsd
    );

    function emitChargeProtocolFee(
        address receiver,
        uint256 sizeUsd,
        uint256 feeUsd
    ) external;

    event ChargeProtocolFee(
        address indexed receiver,
        address indexed copyWallet,
        uint256 sizeUsd,
        uint256 feeUsd
    );

    function emitCreateGelatoTask(
        uint256 taskId,
        bytes32 gelatoTaskId,
        ICopyWallet.TaskCommand command,
        address source,
        uint256 market,
        int256 collateralDelta,
        int256 sizeDelta,
        uint256 triggerPrice,
        uint256 acceptablePrice,
        address referrer
    ) external;

    event CreateGelatoTask(
        address indexed copyWallet,
        uint256 indexed taskId,
        bytes32 indexed gelatoTaskId,
        ICopyWallet.TaskCommand command,
        address source,
        uint256 market,
        int256 collateralDelta,
        int256 sizeDelta,
        uint256 triggerPrice,
        uint256 acceptablePrice,
        address referrer
    );

    function emitUpdateGelatoTask(
        uint256 taskId,
        bytes32 gelatoTaskId,
        int256 collateralDelta,
        int256 sizeDelta,
        uint256 triggerPrice,
        uint256 acceptablePrice
    ) external;

    event UpdateGelatoTask(
        address indexed copyWallet,
        uint256 indexed taskId,
        bytes32 indexed gelatoTaskId,
        int256 collateralDelta,
        int256 sizeDelta,
        uint256 triggerPrice,
        uint256 acceptablePrice
    );

    function emitCancelGelatoTask(
        uint256 taskId,
        bytes32 gelatoTaskId,
        bytes32 reason
    ) external;

    event CancelGelatoTask(
        address indexed copyWallet,
        uint256 indexed taskId,
        bytes32 indexed gelatoTaskId,
        bytes32 reason
    );

    function emitGelatoTaskRunned(
        uint256 taskId,
        bytes32 gelatoTaskId,
        uint256 fillPrice,
        uint256 fee
    ) external;

    event GelatoTaskRunned(
        address indexed copyWallet,
        uint256 indexed taskId,
        bytes32 indexed gelatoTaskId,
        uint256 fillPrice,
        uint256 fee
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IFactory {
    event NewCopyWallet(
        address indexed creator,
        address indexed account,
        bytes32 version
    );

    event CopyWalletImplementationUpgraded(address implementation);

    error FailedToInitCopyWallet(bytes data);

    error CopyWalletFailedToFetchVersion(bytes data);

    error CannotUpgrade();

    error CopyWalletDoesNotExist();

    function canUpgrade() external view returns (bool);

    function implementation() external view returns (address);

    function accounts(address _account) external view returns (bool);

    function getCopyWalletOwner(
        address _account
    ) external view returns (address);

    function getCopyWalletsOwnedBy(
        address _owner
    ) external view returns (address[] memory);

    function updateCopyWalletOwnership(
        address _newOwner,
        address _oldOwner
    ) external;

    function newCopyWallet(
        address initialExecutor
    ) external returns (address payable accountAddress);

    /// @dev this *will* impact all existing accounts
    /// @dev future accounts will also point to this new implementation (until
    /// upgradeCopyWalletImplementation() is called again with a newer implementation)
    /// @dev *DANGER* this function does not check the new implementation for validity,
    /// thus, a bad upgrade could result in severe consequences.
    function upgradeCopyWalletImplementation(address _implementation) external;

    /// @dev cannot be undone
    function removeUpgradability() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ICopyWallet {
    enum Command {
        OWNER_MODIFY_FUND, //0
        OWNER_WITHDRAW_ETH, //1
        OWNER_WITHDRAW_TOKEN, //2
        PERP_CREATE_ACCOUNT, //3
        PERP_MODIFY_COLLATERAL, //4
        PERP_PLACE_ORDER, //5
        PERP_CLOSE_ORDER, //6
        PERP_CANCEL_ORDER, //7
        PERP_WITHDRAW_ALL_MARGIN, //8
        GELATO_CREATE_TASK, //9
        GELATO_UPDATE_TASK, //10
        GELETO_CANCEL_TASK //11
    }

    enum TaskCommand {
        STOP_ORDER, //0
        LIMIT_ORDER //1
    }

    struct CopyWalletConstructorParams {
        address factory;
        address events;
        address configs;
        address usdAsset;
        address automate;
        address taskCreator;
    }

    struct Position {
        address source;
        uint256 lastSizeUsd;
        uint256 lastSizeDeltaUsd;
        uint256 lastFeeUsd;
    }

    struct Task {
        bytes32 gelatoTaskId;
        TaskCommand command;
        address source;
        uint256 market;
        int256 collateralDelta;
        int256 sizeDelta;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        address referrer;
    }

    error LengthMismatch();

    error InvalidCommandType(uint256 commandType);

    error ZeroSizeDelta();

    error InsufficientAvailableFund(uint256 available, uint256 required);

    error EthWithdrawalFailed();

    error NoOpenPosition();

    error NoOrderFound();

    error NoTaskFound();

    error SourceMismatch();

    error PositionExist();

    error CannotExecuteTask(uint256 taskId, address executor);

    function VERSION() external view returns (bytes32);

    function executor() external view returns (address);

    function lockedFund() external view returns (uint256);

    function lockedFundD18() external view returns (uint256);

    function availableFund() external view returns (uint256);

    function availableFundD18() external view returns (uint256);

    function ethToUsd(uint256 _amount) external view returns (uint256);

    // TODO enable again
    // function checker(
    //     uint256 _taskId
    // ) external view returns (bool canExec, bytes memory execPayload);
    // function getTask(uint256 _taskId) external view returns (Task memory);
    // function executeTask(uint256 _taskId) external;

    function positions(uint256 _key) external view returns (Position memory);

    function init(address _owner, address _executor) external;

    function execute(
        Command[] calldata _commands,
        bytes[] calldata _inputs
    ) external payable;
}