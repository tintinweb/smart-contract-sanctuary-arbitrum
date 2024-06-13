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
import {IConfigurator} from "../interfaces/IConfigurator.sol";
import {IStakeHandler} from "../interfaces/IStakeHandler.sol";
import {PayloadDecoderV1} from "../libraries/PayloadDecoderV1.sol";
import {DataHasherV1} from "../libraries/DataHasherV1.sol";
import {StakeInfoHelper} from "../libraries/StakeInfoHelper.sol";

contract StakeHandler is IStakeHandler, BaseAuthorized {
    using PayloadDecoderV1 for bytes;
    using DataHasherV1 for ICore.VerifiableData;
    using StakeInfoHelper for bytes;

    event StakeAmount(
        address indexed provider,
        uint64 nonce,
        ICore.ContainerList containers,
        uint256[] amounts
    );
    event UnstakeAmount(
        address indexed provider,
        uint64 nonce,
        ICore.ContainerList containers,
        uint256[] amounts
    );

    IConfigurator private immutable _configurator;
    bytes private constant BYTES64 =
        hex"00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";

    mapping(address provider => mapping(uint256 bucket => bytes info))
        internal _stakeInfo;
    mapping(address provider => mapping(uint256 bucket => uint256 amount))
        internal _stakeRemain;

    constructor(
        IACLManager aclManager,
        IConfigurator configurator
    ) BaseAuthorized(aclManager) {
        _configurator = configurator;
    }

    function getStakeInfo(
        address provider,
        uint256 containerIndex
    )
        public
        view
        returns (
            uint16 config,
            bool isStaked,
            uint256 kValue,
            uint256 coefficient,
            uint256 stakeRemain
        )
    {
        uint256 bucket = (containerIndex / 8);
        uint256 j = (containerIndex % 8);
        bytes memory info = _stakeInfo[provider][bucket];
        config = info.getConfig(j);
        isStaked = info.isStaked(j);
        stakeRemain = _stakeRemain[provider][containerIndex];
        (uint16 cp1, uint16 cp2) = info.getCheckpoints(j);
        kValue = _configurator.getContainerKValueAtCheckpoint(config, cp1);
        coefficient = _configurator.getStakingCoefficientAtCheckpoint(cp2);
    }

    function handleStake(
        address provider,
        ICore.ContainerList calldata containers,
        ICore.VerifiableData calldata vdata
    ) external override onlyCore returns (uint256 amount) {
        _aclManager.checkValidatorSignatures(
            vdata.getHashAt(0, provider, containers),
            vdata.proof[0]
        );
        uint256[] memory amounts;
        (amount, amounts) = _stakeList(
            provider,
            containers,
            vdata.payloads[0].decodeStake()
        );
        emit StakeAmount(provider, vdata.nonce, containers, amounts);
    }

    function handleUnstake(
        address provider,
        ICore.ContainerList calldata containers,
        ICore.VerifiableData calldata vdata
    ) external override onlyCore returns (uint256 amount) {
        _aclManager.checkValidatorSignatures(
            vdata.getHashAt(0, provider, containers),
            vdata.proof[0]
        );
        amount = vdata.payloads[0].decodeUnstake();
        uint256[] memory amounts;
        (amount, amounts) = _unstakeList(provider, containers);
        emit UnstakeAmount(provider, vdata.nonce, containers, amounts);
    }

    function handleForceUnstake(
        address operator,
        address[] calldata providers,
        uint32[] calldata indexes,
        ICore.VerifiableData calldata vdata
    ) external override onlyCore {
        _aclManager.checkValidatorSignatures(
            vdata.getHashAt(0, operator, providers, indexes),
            vdata.proof[0]
        );
        _force(providers, indexes, vdata.payloads[0].decodeRemainStakeNumber());
    }

    function _stake(
        address provider,
        uint256 index,
        uint16 conf,
        bytes memory info
    ) internal returns (uint256 amount, bytes memory newinfo) {
        uint256 j = index % 8;
        require(!info.isStaked(j), "Container staked");
        require(info.isNew(j) || info.getConfig(j) == conf, "Config mismatch");

        (uint256 k, uint16 cp1) = _configurator.getContainerKValue(conf);
        (uint256 sc, uint16 cp2) = _configurator.getStakingCoefficient();
        amount = (k * sc) / (10 ** _configurator.getKValueDecimals());

        if (info.isForced(j)) {
            require(
                _stakeRemain[provider][index] <= amount,
                "Remain amount must less than or equal stake amount"
            );
            amount -= _stakeRemain[provider][index];
            _stakeRemain[provider][index] = 0;
        }
        newinfo = info.setStaked(j, conf, cp1, cp2);
    }

    function _stakeList(
        address provider,
        ICore.ContainerList calldata containers,
        uint16[] memory configs
    ) internal returns (uint256 totalAmount, uint256[] memory amounts) {
        uint256 curConfig = 0;
        amounts = new uint256[](containers.count);
        for (uint256 i = 0; i < containers.bitset.length; i++) {
            uint8 b = uint8(containers.bitset[i]);
            if (b == 0) continue;
            uint256 bucket = (containers.offset / 8) + i;
            bytes memory info = _stakeInfo[provider][bucket];
            if (info.length == 0) info = BYTES64;
            for (uint256 j = 0; j < 8; j++) {
                if (b & (1 << j) == 0) continue;
                (amounts[curConfig], info) = _stake(
                    provider,
                    bucket * 8 + j,
                    configs[curConfig],
                    info
                );
                totalAmount += amounts[curConfig];
                curConfig++;
            }
            _stakeInfo[provider][bucket] = info;
        }
        require(curConfig == configs.length, "Config length mismatch");
    }

    function _unstake(
        address provider,
        uint256 index,
        bytes memory info
    ) internal returns (uint256 amount, bytes memory newinfo) {
        uint256 j = index % 8;
        require(!info.isUnstaked(j), "Container unstaked");
        if (info.isForced(j)) {
            amount = _stakeRemain[provider][index];
            _stakeRemain[provider][index] = 0;
        } else if (info.isStaked(j)) {
            amount = _getStakedAmount(info, j);
        }
        newinfo = info.setUnstaked(j);
    }

    function _unstakeList(
        address provider,
        ICore.ContainerList calldata containers
    ) internal returns (uint256 totalAmount, uint256[] memory amounts) {
        uint256 curConfig = 0;
        amounts = new uint256[](containers.count);
        for (uint256 i = 0; i < containers.bitset.length; i++) {
            uint8 b = uint8(containers.bitset[i]);
            if (b == 0) continue;
            uint256 bucket = (containers.offset / 8) + i;
            bytes memory info = _stakeInfo[provider][bucket];
            if (info.length == 0) info = BYTES64;
            for (uint256 j = 0; j < 8; j++) {
                if (b & (1 << j) == 0) continue;
                (amounts[curConfig], info) = _unstake(
                    provider,
                    bucket * 8 + j,
                    info
                );
                totalAmount += amounts[curConfig];
                curConfig++;
            }
            _stakeInfo[provider][bucket] = info;
        }
    }

    function _force(
        address[] calldata providers,
        uint32[] calldata indexes,
        uint256[] memory amounts
    ) internal {
        for (uint256 i = 0; i < providers.length; i++) {
            uint256 bucket = (indexes[i] / 8);
            uint256 j = (indexes[i] % 8);
            bytes memory info = _stakeInfo[providers[i]][bucket];
            if (info.length == 0) info = BYTES64;
            require(info.isStaked(j), "Container not staked");
            require(
                amounts[i] < _getStakedAmount(info, j),
                "Remain amount must less than staked amount"
            );
            info = info.setForced(j);
            _stakeInfo[providers[i]][bucket] = info;
            _stakeRemain[providers[i]][indexes[i]] = amounts[i];
        }
    }

    function _getStakedAmount(
        bytes memory info,
        uint256 j
    ) internal view returns (uint256) {
        uint16 conf = info.getConfig(j);
        (uint16 cp1, uint16 cp2) = info.getCheckpoints(j);
        uint256 k = _configurator.getContainerKValueAtCheckpoint(conf, cp1);
        uint256 sc = _configurator.getStakingCoefficientAtCheckpoint(cp2);
        return (k * sc) / (10 ** _configurator.getKValueDecimals());
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

// SPDX-License-Identifier: MIT
pragma solidity =0.8.18;

library StakeInfoHelper {
    bytes1 private constant NEW = 0x00;
    bytes1 private constant STAKED = 0x01;
    bytes1 private constant UNSTAKED = 0x02;
    bytes1 private constant FORCED = 0x03;

    function isNew(
        bytes memory bucketData,
        uint256 j
    ) internal pure returns (bool) {
        return bucketData[j * 8] == NEW;
    }

    function isStaked(
        bytes memory bucketData,
        uint256 j
    ) internal pure returns (bool) {
        return bucketData[j * 8] == STAKED;
    }

    function isUnstaked(
        bytes memory bucketData,
        uint256 j
    ) internal pure returns (bool) {
        return bucketData[j * 8] == UNSTAKED;
    }

    function isForced(
        bytes memory bucketData,
        uint256 j
    ) internal pure returns (bool) {
        return bucketData[j * 8] == FORCED;
    }

    function getConfig(
        bytes memory bucketData,
        uint256 j
    ) internal pure returns (uint16) {
        return _getUint16(bucketData, j * 8 + 2);
    }

    function getCheckpoints(
        bytes memory bucketData,
        uint256 j
    ) internal pure returns (uint16 cp1, uint16 cp2) {
        cp1 = _getUint16(bucketData, j * 8 + 4);
        cp2 = _getUint16(bucketData, j * 8 + 6);
    }

    function setStaked(
        bytes memory bucketData,
        uint256 j,
        uint16 config,
        uint16 cp1,
        uint16 cp2
    ) internal pure returns (bytes memory) {
        bucketData[j * 8] = STAKED;
        bucketData[j * 8 + 2] = bytes2(config)[0];
        bucketData[j * 8 + 3] = bytes2(config)[1];
        bucketData[j * 8 + 4] = bytes2(cp1)[0];
        bucketData[j * 8 + 5] = bytes2(cp1)[1];
        bucketData[j * 8 + 6] = bytes2(cp2)[0];
        bucketData[j * 8 + 7] = bytes2(cp2)[1];
        return bucketData;
    }

    function setUnstaked(
        bytes memory bucketData,
        uint256 j
    ) internal pure returns (bytes memory) {
        bucketData[j * 8] = UNSTAKED;
        return bucketData;
    }

    function setForced(
        bytes memory bucketData,
        uint256 j
    ) internal pure returns (bytes memory) {
        bucketData[j * 8] = FORCED;
        return bucketData;
    }

    function _getUint16(
        bytes memory data,
        uint256 i
    ) internal pure returns (uint16) {
        return 256 * uint8(data[i]) + uint8(data[i + 1]);
    }
}