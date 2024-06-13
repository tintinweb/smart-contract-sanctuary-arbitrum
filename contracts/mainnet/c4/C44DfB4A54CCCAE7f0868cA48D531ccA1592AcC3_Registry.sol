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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {IACLManager} from "../interfaces/IACLManager.sol";
import {ICore} from "../interfaces/ICore.sol";

/**
 * @title BaseAuthorized
 * @notice Authorizes AethirCore contract to perform actions
 */
abstract contract BaseAuthorized {
    IACLManager internal immutable _aclManager;

    modifier onlyCore() {
        _aclManager.requireCore(msg.sender);
        _;
    }

    modifier onlyOperator() {
        _aclManager.requireOperator(msg.sender);
        _;
    }

    modifier onlyMigrator() {
        _aclManager.requireMigrator(msg.sender);
        _;
    }

    modifier onlyRiskAdmin() {
        _aclManager.requireRiskAdmin(msg.sender);
        _;
    }

    constructor(IACLManager aclManager) {
        require(
            address(aclManager) != address(0),
            "ACL manager cannot be zero"
        );
        _aclManager = aclManager;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {BaseAuthorized} from "./BaseAuthorized.sol";
import {IACLManager} from "../interfaces/IACLManager.sol";
import {IRegistry} from "../interfaces/IRegistry.sol";
import {IRewardHandler} from "../interfaces/IRewardHandler.sol";
import {IServiceFeeHandler} from "../interfaces/IServiceFeeHandler.sol";
import {IStakeHandler} from "../interfaces/IStakeHandler.sol";
import {IVestingController} from "../interfaces/IVestingController.sol";
import {IRiskManager} from "../interfaces/IRiskManager.sol";
import {IConfigurator} from "../interfaces/IConfigurator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Registry is IRegistry, BaseAuthorized {
    uint64 private _version;
    IERC20 private immutable _aethirToken;
    IRewardHandler private _rewardHandler;
    IServiceFeeHandler private _serviceFeeHandler;
    IStakeHandler private _stakeHandler;
    IVestingController private _vestingController;
    IRiskManager private _riskManager;
    IConfigurator private _configurator;

    constructor(
        IACLManager aclManager,
        IERC20 aethirToken,
        IRewardHandler rewardHandler,
        IServiceFeeHandler serviceFeeHandler,
        IStakeHandler stakeHandler,
        IVestingController vestingController,
        IRiskManager riskManager,
        IConfigurator configurator
    ) BaseAuthorized(aclManager) {
        require(
            address(aethirToken) != address(0) &&
                address(rewardHandler) != address(0) &&
                address(serviceFeeHandler) != address(0) &&
                address(stakeHandler) != address(0) &&
                address(vestingController) != address(0) &&
                address(riskManager) != address(0) &&
                address(configurator) != address(0),
            "CannotBeZero"
        );
        _version = 1;
        _aethirToken = aethirToken;
        _rewardHandler = rewardHandler;
        _serviceFeeHandler = serviceFeeHandler;
        _stakeHandler = stakeHandler;
        _vestingController = vestingController;
        _riskManager = riskManager;
        _configurator = configurator;
    }

    /// @inheritdoc IRegistry
    function getVersion() public view override returns (uint64) {
        return _version;
    }

    /// @inheritdoc IRegistry
    function setVersion(uint64 value) external override onlyMigrator {
        _version = value;
    }

    /// @inheritdoc IRegistry
    function getAethirToken() public view override returns (IERC20) {
        return _aethirToken;
    }

    /// @inheritdoc IRegistry
    function getACLManager() public view override returns (IACLManager) {
        return _aclManager;
    }

    /// @inheritdoc IRegistry
    function getRewardHandler() public view override returns (IRewardHandler) {
        return _rewardHandler;
    }

    /// @inheritdoc IRegistry
    function setRewardHandler(
        IRewardHandler value
    ) external override onlyMigrator {
        require(address(value) != address(0), "CannotBeZero");
        _rewardHandler = value;
    }

    /// @inheritdoc IRegistry
    function getServiceFeeHandler()
        public
        view
        override
        returns (IServiceFeeHandler)
    {
        return _serviceFeeHandler;
    }

    /// @inheritdoc IRegistry
    function setServiceFeeHandler(
        IServiceFeeHandler value
    ) external override onlyMigrator {
        require(address(value) != address(0), "CannotBeZero");
        _serviceFeeHandler = value;
    }

    /// @inheritdoc IRegistry
    function getStakeHandler() public view override returns (IStakeHandler) {
        return _stakeHandler;
    }

    /// @inheritdoc IRegistry
    function setStakeHandler(
        IStakeHandler value
    ) external override onlyMigrator {
        require(address(value) != address(0), "CannotBeZero");
        _stakeHandler = value;
    }

    /// @inheritdoc IRegistry
    function getVestingController()
        public
        view
        override
        returns (IVestingController)
    {
        return _vestingController;
    }

    /// @inheritdoc IRegistry
    function setVestingController(
        IVestingController value
    ) external override onlyMigrator {
        require(address(value) != address(0), "CannotBeZero");
        _vestingController = value;
    }

    /// @inheritdoc IRegistry
    function getRiskManager() public view override returns (IRiskManager) {
        return _riskManager;
    }

    /// @inheritdoc IRegistry
    function setRiskManager(
        IRiskManager value
    ) external override onlyRiskAdmin {
        require(address(value) != address(0), "CannotBeZero");
        _riskManager = value;
    }

    /// @inheritdoc IRegistry
    function getConfigurator() public view override returns (IConfigurator) {
        return _configurator;
    }

    /// @inheritdoc IRegistry
    function setConfigurator(
        IConfigurator value
    ) external override onlyMigrator {
        require(address(value) != address(0), "CannotBeZero");
        _configurator = value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

/**
 * @title IACLManager
 * @notice Defines the basic interface for the ACL Manager
 */
interface IACLManager {
    /// @notice thrown when tx has not been completed because it lacks valid authentication credentials
    error Unauthorized(string message);

    /// @notice true if the address is Core Module, false otherwise
    /// @param account: the address to check
    /// @return true if the given address is Core Module, false otherwise
    function isCore(address account) external view returns (bool);

    /// @notice revert if the address is not Core Module
    /// @param account: the address to check
    function requireCore(address account) external view;

    /// @notice true if the address is Originator, false otherwise
    /// @param account: the address to check
    /// @return true if the given address is Originator, false otherwise
    function isOriginator(address account) external view returns (bool);

    /// @notice revert if the address is not Originator
    /// @param account: the address to check
    function requireOriginator(address account) external view;

    /// @notice true if the address is Operator, false otherwise
    /// @param account: the address to check
    /// @return true if the given address is Operator, false otherwise
    function isOperator(address account) external view returns (bool);

    /// @notice revert if the address is not Operator
    /// @param account: the address to check
    function requireOperator(address account) external view;

    /// @notice true if the address is Migrator, false otherwise
    /// @param account: the address to check
    /// @return true if the given address is Migrator, false otherwise
    function isMigrator(address account) external view returns (bool);

    /// @notice revert if the address is not Migrator
    /// @param account: the address to check
    function requireMigrator(address account) external view;

    /// @notice true if the address is Validator, false otherwise
    /// @param account: the address to check
    /// @return true if the given address is Validator, false otherwise
    function isValidator(address account) external view returns (bool);

    /// @notice revert if the address is not Validator
    /// @param account: the address to check
    function requireValidator(address account) external view;

    /// @notice true if the address is Approver, false otherwise
    /// @param account: the address to check
    /// @return true if the given address is Approver, false otherwise
    function isApprover(address account) external view returns (bool);

    /// @notice revert if the address is not Approver
    /// @param account: the address to check
    function requireApprover(address account) external view;

    /// @notice true if the address is EmergencyAdmin, false otherwise
    /// @param account: the address to check
    /// @return true if the given address is EmergencyAdmin, false otherwise
    function isEmergencyAdmin(address account) external view returns (bool);

    /// @notice revert if the address is not EmergencyAdmin
    /// @param account: the address to check
    function requireEmergencyAdmin(address account) external view;

    /// @notice true if the address is RiskAdmin, false otherwise
    /// @param account: the address to check
    /// @return true if the given address is RiskAdmin, false otherwise
    function isRiskAdmin(address account) external view returns (bool);

    /// @notice revert if the address is not RiskAdmin
    /// @param account: the address to check
    function requireRiskAdmin(address account) external view;

    /// @notice get number of required validator signatures for verifiable data
    function getRequiredValidatorSignatures() external view returns (uint8);

    /// @notice set number of required validator signatures for verifiable data
    function setRequiredValidatorSignatures(uint8 value) external;

    /// @notice get number of required approver signatures for verifiable data
    function getRequiredApproverSignatures() external view returns (uint8);

    /// @notice set number of required approver signatures for verifiable data
    function setRequiredApproverSignatures(uint8 value) external;

    function checkValidatorSignatures(
        bytes32 dataHash,
        bytes calldata signatures
    ) external view;

    function checkApproverSignatures(
        bytes32 dataHash,
        bytes calldata signatures
    ) external view;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

interface IConfigurator {
    /// @notice service fee data
    /// @param retailUpside: retail service fee upside
    /// @param retailDownside: retail service fee downside
    /// @param wholesaleUpside: wholesale service fee upside
    /// @param wholesaleDownside: wholesale service fee downside
    struct ServiceFee {
        uint256 retailUpside;
        uint256 retailDownside;
        uint256 wholesaleUpside;
        uint256 wholesaleDownside;
    }

    /// @notice thrown when value is not valid
    error InvalidValue(string message);

    /// @notice returns first epoch start time (in UNIX timestamp)
    function getDeployTs() external view returns (uint256);

    /// @notice returns epoch duration (in seconds)
    function getEpochDuration() external view returns (uint256);

    /// @notice returns current system epoch
    function getEpoch() external view returns (uint256);

    /// @notice returns token amount released yearly
    function getYearlyEmission() external view returns (uint256);

    /// @notice configures token amount released yearly
    /// @param value: the new token amount
    function setYearlyEmission(uint256 value) external;

    /// @notice returns staking coefficient
    function getStakingCoefficient()
        external
        view
        returns (uint256 value, uint16 cp);

    /// @notice returns staking coefficient at checkpoint `cp`
    function getStakingCoefficientAtCheckpoint(
        uint16 cp
    ) external view returns (uint256 value);

    /// @notice configures staking coefficient
    /// @param value: the new staking coefficient
    function setStakingCoefficient(uint256 value) external;

    /// @notice returns k-value for container ith configuration
    function getContainerKValue(
        uint16 index
    ) external view returns (uint256 value, uint16 cp);

    /// @notice returns k-value for container ith configuration at checkpoint `cp`
    function getContainerKValueAtCheckpoint(
        uint16 index,
        uint16 cp
    ) external view returns (uint256 value);

    /// @notice configures k-values for each container configuration
    /// @param indexes: the k-indexes
    /// @param values: the new k-values
    function setContainerKValue(
        uint16[] calldata indexes,
        uint256[] calldata values
    ) external;

    /// @notice returns the number of decimals used to get its user representation.
    /// For example, if `decimals` equals `2`, a kValue of `505` should
    /// be displayed to a user as `5.05` (`505 / 10 ** 2`)
    function getKValueDecimals() external view returns (uint8);

    /// @notice returns reward locked time before vesting
    function getRewardLockedTime() external view returns (uint64);

    /// @notice configures reward locked time before vesting
    /// @param value: new locked time (in days)
    function setRewardLockedTime(uint64 value) external;

    /// @notice returns vesting period
    function getVestingPeriod() external view returns (uint64);

    /// @notice configures vesting period
    /// @param value: new vesting period (in days)
    function setVestingPeriod(uint64 value) external;

    /// @notice returns quality parameter (Q)
    function getQualityParameter()
        external
        view
        returns (uint256 min, uint256 max);

    /// @notice configures quality parameter (Q)
    /// @param min: min Q value
    /// @param max: max Q value
    function setQualityParameter(uint256 min, uint256 max) external;

    /// @notice returns average quality parameter (SQ)
    function getAverageQualityParameter()
        external
        view
        returns (uint256[] memory);

    /// @notice configures average quality parameter (SQ)
    /// @param values: new SQ values
    function setAverageQualityParameter(uint256[] calldata values) external;

    /// @notice returns service fee for container ith configuration
    function getServiceFees(
        uint16 index
    ) external view returns (ServiceFee memory);

    /// @notice configures wholesale service fee for each container configuration
    /// @param indexes: the k-indexes
    /// @param values: the new service fee
    function setServiceFees(
        uint16[] calldata indexes,
        ServiceFee[] calldata values
    ) external;

    /// @notice returns wholesale maintenance time
    function getWholesaleMaintenanceTime() external view returns (uint256);

    /// @notice configures wholesale maintenance time
    /// @param value: new wholesale maintenance time
    function setWholesaleMaintenanceTime(uint256 value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

/**
 * @dev Interface of Aethir Core Contract
 */
interface ICore {
    /// @notice verifiable off-chain data
    /// @param nonce: off-chain request id
    /// @param deadline: deadline timestamp as seconds since Unix epoch
    /// @param lastUpdateBlock: last indexed event blocknumber
    /// @param version: system version
    /// @param payloads: data package (format according to system version)
    /// @param proof: data proof (Validator Signature or Merkle Proof)
    struct VerifiableData {
        uint64 nonce;
        uint64 deadline;
        uint64 lastUpdateBlock;
        uint64 version;
        bytes[] payloads;
        bytes[] proof;
    }

    /// @notice list of containers
    /// @param offset: index of the first container in the bitset, must be multiples of 256
    /// @param bitset: bit[n] = 1 mean enable container at index `offset`+`n`
    struct ContainerList {
        uint16 count;
        uint32 offset;
        bytes bitset;
    }

    /// @notice emitted after a successful stake containers request
    event Stake(
        address indexed provider,
        uint64 nonce,
        ContainerList containers
    );

    /// @notice emitted after a successful unstake containers request
    event Unstake(
        address indexed provider,
        uint64 nonce,
        ContainerList containers
    );

    /// @notice emitted after a successful claim reward request
    event ClaimReward(
        address indexed provider,
        uint64 nonce,
        ContainerList containers
    );

    /// @notice emitted after a successful claim service fee request
    event ClaimServiceFee(
        address indexed provider,
        uint64 nonce,
        ContainerList containers
    );

    /// @notice emitted after a successful deposit service fee request
    event DepositServiceFee(
        address indexed developer,
        uint64 nonce,
        uint256 amount
    );

    /// @notice emitted after a successful withdraw service fee request
    event WithdrawServiceFee(
        address indexed developer,
        uint64 nonce,
        uint256 amount
    );

    /// @notice emitted after system update version
    event VersionUpdate(uint64 indexed oldVersion, uint64 indexed newVersion);

    /// @notice emitted after a successful force unstake containers request
    event ForceUnstake(
        address indexed operator,
        uint64 nonce,
        address[] providers,
        uint32[] indexes
    );

    /// @notice thrown when data version does not match with system version
    error InvalidVersion();

    /// @notice thrown when data deadline exceeded block timestamp
    error DataExpired();

    /// @notice thrown when data nonce is lower than the last id
    error NonceTooLow();

    /// @notice thrown when data payload is invalid
    error InvalidPayload();

    /// @notice thrown when parameter is invalid
    error InvalidParameter(string message);

    /// @notice thrown when data merkle proof or signature is invalid
    error InvalidProof();

    /// @notice thrown when on-chain and off-chain data are out-of-sync
    error DataTooOld();

    /// @notice thrown when there is abnormal data
    error DataConflict(string message);

    /// @notice Returns the current system version
    function version() external view returns (uint64);

    /// @notice Returns the current system epoch
    function currentEpoch()
        external
        view
        returns (uint64 epoch, uint64 startTs, uint64 endTs);

    /// @notice Returns the current nonce for `owner`
    /// A higher nonce must be included whenever generate a signature
    /// Every successful call update `owner`'s nonce to the new one
    /// This prevents a signature from being used multiple times.
    function nonces(address owner) external view returns (uint64);

    /// @notice Container Provider stake multiple containers
    /// @dev Caller must have allowance for this contract of at least stake amount
    /// @param containers: list of containers to stake
    /// @param vdata: additional data for calculating stake amount
    function stakeContainers(
        ContainerList calldata containers,
        VerifiableData calldata vdata
    ) external returns (bool);

    /// @notice Container Provider unstake and claim reward for multiple containers
    /// @param containers: list of containers to unstake
    /// @param vdata: additional data for calculating unstake amount, reward and service fee
    function unstakeContainers(
        ContainerList calldata containers,
        VerifiableData calldata vdata
    ) external returns (bool);

    /// @notice Container Provider claim reward for multiple containers
    /// @dev Reward will be sent to Vesting Controller and released following schedule
    /// @param containers: list of container to claim reward
    /// @param vdata: additional data for calculating reward amount
    function claimReward(
        ContainerList calldata containers,
        VerifiableData calldata vdata
    ) external returns (bool);

    /// @notice Container Provider claim service fee for multiple containers
    /// @param containers: list of container to claim service fee
    /// @param vdata: additional data for calculating service fee amount
    function claimServiceFee(
        ContainerList calldata containers,
        VerifiableData calldata vdata
    ) external returns (bool);

    /// @notice Game Developer deposit service fee
    /// @dev Caller must have allowance for this contract of at least deposit amount
    /// @param amount: amount of token game developer want to deposit
    /// @param vdata: additional data for calculating depositable service fee
    function depositServiceFee(
        uint256 amount,
        VerifiableData calldata vdata
    ) external returns (bool);

    /// @notice Game Developer withdraw service fee
    /// @param amount: amount of token game developer want to withdraw
    /// @param vdata: additional data for calculating withdrawable service fee
    function withdrawServiceFee(
        uint256 amount,
        VerifiableData calldata vdata
    ) external returns (bool);

    /// @notice Operator force unstake multiple containers
    /// @param providers: address of providers
    /// @param indexes: unstaked container index
    /// @param vdata: additional data for calculating remain stake number
    function forceUnstake(
        address[] calldata providers,
        uint32[] calldata indexes,
        VerifiableData calldata vdata
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {IACLManager} from "./IACLManager.sol";
import {IRewardHandler} from "./IRewardHandler.sol";
import {IServiceFeeHandler} from "./IServiceFeeHandler.sol";
import {IStakeHandler} from "./IStakeHandler.sol";
import {IVestingController} from "./IVestingController.sol";
import {IRiskManager} from "./IRiskManager.sol";
import {IConfigurator} from "./IConfigurator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRegistry {
    /// @notice thrown when value is not valid
    error CannotBeZero();

    /// @notice returns the current system version
    function getVersion() external view returns (uint64);

    /// @notice registers new system version
    /// @param value: new version
    function setVersion(uint64 value) external;

    /// @notice returns the contract address of the Aethir Token
    /// @return The address of the Aethir Token
    function getAethirToken() external view returns (IERC20);

    /// @notice returns the contract address of the ACL Manager
    /// @return The address of the ACL Manager
    function getACLManager() external view returns (IACLManager);

    /// @notice returns the contract address of the Reward Handler
    /// @return The address of the Reward Handler
    function getRewardHandler() external view returns (IRewardHandler);

    /// @notice registers the contract address of the Reward Handler
    /// @param value: address of new Reward Handler
    function setRewardHandler(IRewardHandler value) external;

    /// @notice returns the contract address of the Service Fee Handler
    /// @return The address of the Service Fee Handler
    function getServiceFeeHandler() external view returns (IServiceFeeHandler);

    /// @notice registers the contract address of the Service Fee Handler
    /// @param value: address of new Service Fee Handler
    function setServiceFeeHandler(IServiceFeeHandler value) external;

    /// @notice returns the contract address of the Stake Handler
    /// @return The address of the Stake Handler
    function getStakeHandler() external view returns (IStakeHandler);

    /// @notice registers the contract address of the Stake Handler
    /// @param value: address of new Stake Handler
    function setStakeHandler(IStakeHandler value) external;

    /// @notice returns the contract address of the Vesting Controller
    /// @return The address of the Vesting Controller
    function getVestingController() external view returns (IVestingController);

    /// @notice registers the contract address of the Vesting Controller
    /// @param value: address of new Vesting Controller
    function setVestingController(IVestingController value) external;

    /// @notice returns the contract address of the Risk Manager
    /// @return The address of the Risk Manager
    function getRiskManager() external view returns (IRiskManager);

    /// @notice registers the contract address of the Risk Manager
    /// @param value: address of new Risk Manager
    function setRiskManager(IRiskManager value) external;

    /// @notice returns the contract address of the Configurator
    /// @return The address of the Configurator
    function getConfigurator() external view returns (IConfigurator);

    /// @notice registers the contract address of the Configurator
    /// @param value: address of new Configurator
    function setConfigurator(IConfigurator value) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {ICore} from "../interfaces/ICore.sol";

interface IRewardHandler {
    function handleClaim(
        address provider,
        ICore.ContainerList calldata containers,
        ICore.VerifiableData calldata data
    ) external returns (uint256 reward);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

/**
 * @dev Interface of Risk Manager
 */
interface IRiskManager {
    /// @notice thrown when transfer more than risk limit
    error InvalidTransfer();

    /// @notice Throws if the transfering is on suspicion of illegal activity
    /// @param to: address of receiver
    /// @param amount: amount of token want to transfer
    /// @param reason: tranfering reason
    function tryTransfer(address to, uint256 amount, uint8 reason) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {ICore} from "../interfaces/ICore.sol";

interface IServiceFeeHandler {
    function handleClaim(
        address provider,
        ICore.ContainerList calldata containers,
        ICore.VerifiableData calldata data
    ) external returns (uint256 earned);

    function handleDeposit(
        address developer,
        uint256 amount,
        ICore.VerifiableData calldata data
    ) external returns (uint256 depositable);

    function handleWithdraw(
        address developer,
        uint256 amount,
        ICore.VerifiableData calldata data
    ) external returns (uint256 withdrawable);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {ICore} from "../interfaces/ICore.sol";

interface IStakeHandler {
    function handleStake(
        address provider,
        ICore.ContainerList calldata containers,
        ICore.VerifiableData calldata vdata
    ) external returns (uint256 amount);

    function handleUnstake(
        address provider,
        ICore.ContainerList calldata containers,
        ICore.VerifiableData calldata vdata
    ) external returns (uint256 amount);

    function handleForceUnstake(
        address operator,
        address[] calldata providers,
        uint32[] calldata indexes,
        ICore.VerifiableData calldata vdata
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

/**
 * @dev Interface of Vesting Controller
 */
interface IVestingController {
    /// @notice emitted after a successful release request
    event TokenReleased(address indexed beneficiary, uint256 amount);

    /// @notice emitted after a successful new vesting request
    event NewVestingSchedule(
        address indexed beneficiary,
        uint64 lockedDays,
        uint256[] amounts
    );

    /// @notice Amount of token already released
    function released(address beneficiary) external view returns (uint256);

    /// @notice Getter for the amount of releasable tokens
    function releasable(address beneficiary) external view returns (uint256);

    /// @notice Release the tokens that have already vested
    function release(address beneficiary) external;

    /// @notice Calculates the amount of tokens that has already vested
    function vestedAmount(
        address beneficiary,
        uint64 timestamp
    ) external view returns (uint256);

    /// @notice Start new vesting for the beneficiary
    function newVesting(
        address beneficiary,
        uint64 lockedDays,
        uint256[] memory amounts
    ) external;
}