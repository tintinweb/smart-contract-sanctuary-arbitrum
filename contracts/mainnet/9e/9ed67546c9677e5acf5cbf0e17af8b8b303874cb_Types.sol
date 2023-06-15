// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

error AlreadyUsedNonce();
error InvalidStakeAmount();
error CannotWithdrawBeforePoolNonFlexibleEnds();
error RedemptionLimitExceeded(uint256 _used);
error InvalidPassProof();
error InActivePass();
error PassExpired();
error OnlyAuthorizedCanPerformThisAction();
error PoolIsInitializedAlready();
error ExpiredSignature();
error InvalidSignature();
error InvalidInitializer();
error OnlyAuthorizedCanModifyDisabledState();
error OnlyAuthorizedCanSetBatch();
error AlreadyUsedSignature();
error PassBatchIdIsInvalid();
error PassBatchIsNotYetOpen();
error PassBatchIsDisabled();
error InvalidPoolKind();

interface ITarget {
    function initialize(Types.Sign calldata _sign, Types.Pool calldata _pool)
        external;
}

interface IFactory {
    function getPool(Types.Pool calldata _pool, address _signer)
        external
        view
        returns (
            address deployAddress,
            bytes memory code,
            bytes32 salt
        );
}

library Types {
    enum PoolKind {
        Flexible,
        NonFlexible
    }

    struct Sign {
        address signer;
        bytes signature;
        uint256 timestamp;
    }

    struct Pool {
        Types.PoolKind kind;
        address stakeToken;
        address rewardToken;
        uint256 startsAt;
        uint256 endsAt;
        uint256 rewardSupply;
        uint256 nonce;
    }

    struct PoolState {
        address factory;
        bool isInitialized;
        address signer;
        Types.Pool pool;
        uint256 rewardRate;
        uint256 factor;
        uint256 lastCommitAt;
        uint256 rewardPerTokenStaked;
        uint256 totalStaked;
        bool isPassDisabled;
        mapping(address => uint256) userRewardPerTokenPaid;
        mapping(address => uint256) rewards;
        mapping(address => uint256) stakes;
        mapping(uint256 => Types.Batch) batches;
        mapping(bytes32 => uint256) usedLeaves;
    }

    struct Pass {
        uint256 batchId;
        uint256 nonce;
        uint256 amount;
        uint256 stakeAmount;
        bytes32[] proof;
        uint256 startsAt;
        uint256 endsAt;
    }

    struct Batch {
        uint256 id;
        uint256 isOpenAt;
        bool disabled;
        bytes32 root;
    }
}