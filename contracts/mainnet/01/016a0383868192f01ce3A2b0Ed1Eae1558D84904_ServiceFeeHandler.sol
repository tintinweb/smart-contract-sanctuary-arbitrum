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

import {BaseAuthorized} from "../base/BaseAuthorized.sol";
import {ICore} from "../interfaces/ICore.sol";
import {IACLManager} from "../interfaces/IACLManager.sol";
import {IServiceFeeHandler} from "../interfaces/IServiceFeeHandler.sol";
import {PayloadDecoderV1} from "../libraries/PayloadDecoderV1.sol";
import {DataHasherV1} from "../libraries/DataHasherV1.sol";

contract ServiceFeeHandler is IServiceFeeHandler, BaseAuthorized {
    using PayloadDecoderV1 for bytes;
    using DataHasherV1 for ICore.VerifiableData;

    mapping(address developer => uint256 amount) internal _deposited;
    mapping(address developer => uint256 amount) internal _withdrawn;

    constructor(IACLManager aclManager) BaseAuthorized(aclManager) {}

    function handleClaim(
        address provider,
        ICore.ContainerList calldata containers,
        ICore.VerifiableData calldata data
    ) external view override onlyCore returns (uint256 earned) {
        _aclManager.checkApproverSignatures(
            data.getHashAt(0, provider, containers),
            data.proof[0]
        );
        earned = data.payloads[0].decodeServiceFee();
    }

    function handleDeposit(
        address developer,
        uint256 amount,
        ICore.VerifiableData calldata /* data */
    ) external override onlyCore returns (uint256 depositable) {
        _deposited[developer] += amount;
        depositable = amount;
    }

    function handleWithdraw(
        address developer,
        uint256 amount,
        ICore.VerifiableData calldata data
    ) external override onlyCore returns (uint256 withdrawable) {
        require(
            (_withdrawn[developer] + amount) <= _deposited[developer],
            "Withdraw more than deposited"
        );
        _aclManager.checkApproverSignatures(
            data.getHashAt(0, developer, amount),
            data.proof[0]
        );
        _withdrawn[developer] += amount;
        withdrawable = data.payloads[0].decodeWithdrawableFee();
    }

    function getDeposited(address developer) external view returns (uint256) {
        return _deposited[developer];
    }

    function getWithdrawn(address developer) external view returns (uint256) {
        return _withdrawn[developer];
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

interface PayloadFormatV1 {
    function getStakeAmount(uint16[] calldata containerConfigurator) external;

    function getUnstakeAmount(uint256 amount) external;

    function getRewards(uint256 reward, uint256[] calldata pendings) external;

    function getServiceFee(uint256 amount) external;

    function getWithdrawableFee(uint256 amount) external;

    function getRemainStakeNumber(uint256[] calldata amounts) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {ICore} from "../interfaces/ICore.sol";

library DataHasherV1 {
    function getHashAt(
        ICore.VerifiableData calldata data,
        uint256 i,
        address sender,
        ICore.ContainerList calldata containers
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    block.chainid,
                    data.nonce,
                    data.deadline,
                    data.lastUpdateBlock,
                    data.version,
                    sender,
                    data.payloads[i],
                    containers.count,
                    containers.offset,
                    containers.bitset
                )
            );
    }

    function getHashAt(
        ICore.VerifiableData calldata data,
        uint256 i,
        address sender,
        uint256 amount
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    block.chainid,
                    data.nonce,
                    data.deadline,
                    data.lastUpdateBlock,
                    data.version,
                    sender,
                    data.payloads[i],
                    amount
                )
            );
    }

    function getHashAt(
        ICore.VerifiableData calldata data,
        uint256 i,
        address sender,
        address[] calldata providers,
        uint32[] calldata indexes
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    block.chainid,
                    data.nonce,
                    data.deadline,
                    data.lastUpdateBlock,
                    data.version,
                    sender,
                    data.payloads[i],
                    providers,
                    indexes
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

import {ICore} from "../interfaces/ICore.sol";
import {PayloadFormatV1} from "../interfaces/PayloadFormatV1.sol";

library PayloadDecoderV1 {
    function decodeStake(
        bytes calldata payload
    ) internal pure returns (uint16[] memory containerConfigurator) {
        require(
            bytes4(payload) == PayloadFormatV1.getStakeAmount.selector,
            "InvalidPayload"
        );
        containerConfigurator = abi.decode(payload[4:], (uint16[]));
    }

    function decodeUnstake(
        bytes calldata payload
    ) internal pure returns (uint256 amount) {
        require(
            bytes4(payload) == PayloadFormatV1.getUnstakeAmount.selector,
            "InvalidPayload"
        );
        amount = abi.decode(payload[4:], (uint256));
    }

    function decodeRewards(
        bytes calldata payload
    ) internal pure returns (uint256 reward, uint256[] memory pendings) {
        require(
            bytes4(payload) == PayloadFormatV1.getRewards.selector,
            "InvalidPayload"
        );
        (reward, pendings) = abi.decode(payload[4:], (uint256, uint256[]));
    }

    function decodeServiceFee(
        bytes calldata payload
    ) internal pure returns (uint256 amount) {
        require(
            bytes4(payload) == PayloadFormatV1.getServiceFee.selector,
            "InvalidPayload"
        );
        amount = abi.decode(payload[4:], (uint256));
    }

    function decodeWithdrawableFee(
        bytes calldata payload
    ) internal pure returns (uint256 amount) {
        require(
            bytes4(payload) == PayloadFormatV1.getWithdrawableFee.selector,
            "InvalidPayload"
        );
        amount = abi.decode(payload[4:], (uint256));
    }

    function decodeRemainStakeNumber(
        bytes calldata payload
    ) internal pure returns (uint256[] memory amounts) {
        require(
            bytes4(payload) == PayloadFormatV1.getRemainStakeNumber.selector,
            "InvalidPayload"
        );
        amounts = abi.decode(payload[4:], (uint256[]));
    }
}