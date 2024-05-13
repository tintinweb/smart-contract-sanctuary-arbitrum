// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.19;

contract RewardsDistributorInterface {

    // Public and external variables
    function solidlyMinter() external view returns (address) {}
    function solidlyVoter() external view returns (address) {}
    function solidlyToken() external view returns (address) {}
    function owner() external view returns (address) {}
    function root() external view returns (bytes32 value, uint256 lastUpdatedAt) {}
    function isRootAdmin(address admin) external view returns (uint256 status) {}
    function isClaimsPauser(address pauser) external view returns (uint256 status) {}
    function approvedIncentiveAmounts(address token) external view returns (uint256 amount) {}
    function claimDelay() external view returns (uint256) {}
    function activePeriod() external view returns (uint256) {}
    function maxIncentivePeriods() external view returns (uint256) {}
    function claims(address earner, bytes32 rewardKey) external view returns (uint256 amount, uint256 timestamp) {}
    function periodRewards(uint256 period, bytes32 rewardKey) external view returns (uint256 rewardAmount) {}

    function lastUpdateBlock() external view returns (uint80) {}
    function nextUpdateBlock() external view returns (uint80) {}
    function lastUpdateTime() external view returns (uint64) {}
    function targetTime() external view returns (uint24) {}
    function paused() external view returns (bool) {}
    function collateralAmount() external view returns (uint256) {}

    function isRootSetterA(address setter) external view returns (uint256 status) {}
    function isRootSetterB(address setter) external view returns (uint256 status) {}

    function rootCandidateA() external view returns (bytes32 value, uint256 lastUpdatedAt) {}
    function rootCandidateB() external view returns (bytes32 value, uint256 lastUpdatedAt) {}

    // Public and external functions
    function initialize(address _solidlyMinter, address _solidlyVoter) external {}
    function claimAll(ClaimParams calldata params) external {}
    function depositLPSolidEmissions(address pool, uint256 amount) external {}
    function depositLPTokenIncentive(
        address pool,
        address token,
        uint256 amount,
        uint256 distributionStart,
        uint256 numDistributionPeriods
    ) external {}
    function depositVoteIncentive(
        address pool,
        address token,
        uint256 amount,
        uint256 distributionStart,
        uint256 numDistributionPeriods
    ) external {}
    function collectPoolFees(address pool) external returns (uint256 amount0, uint256 amount1) {}
    function setOwner(address _owner) external {}
    function toggleRootAdminStatus(address addr) external {}
    function toggleRootSetterAStatus(address addr) external {}
    function toggleRootSetterBStatus(address addr) external {}
    function setRoot(bytes32 _root) external {}
    function setRootCandidateA(bytes32 _root) external {}
    function setRootCandidateB(bytes32 _root) external {}
    function triggerRoot() external {}
    function setCollateralAmount(uint256 _collateralAmount) external {}
    function setClaimDelay(uint256 newClaimDelay) external {}
    function setTargetTime(uint24 _targetTime) external {}
    function setUpdateInterval(uint80 _lastBlock, uint80 _nextBlock, uint64 _lastUpdate) external {}
    function setMaxIncentivePeriods(uint256 newMaxIncentivePeriods) external {}
    function updateApprovedIncentiveAmounts(address token, uint256 amount) external {}
    function toggleClaimsPauserStatus(address addr) external {}
    function pauseClaimsGovernance() external {}
    function unpauseClaimsGovernance() external {}
    function pauseClaimsPublic() external {}
    function withdrawCollateral(address payable _to, uint256 _amount) external {}

    function getRewardKey(
        RewardType _type,
        uint8 subtype,
        address pool,
        address token
    ) external pure returns (bytes32 key) {}

    // Structs used in function parameters
    struct ClaimParams {
        address[] earners;
        EarnedRewardType[] types;
        address[] pools;
        address[] tokens;
        uint256[] amounts;
        MultiProof proof;
    }

    struct MultiProof {
        bytes32[] path;
        bool[] flags;
    }

    // Enums used in function parameters
    enum RewardType {
        STORED,
        EARNED
    }

    enum EarnedRewardType {
        LP_POOL_FEES,
        LP_SOLID_EMISSIONS,
        LP_TOKEN_INCENTIVE,
        PROTOCOL_POOL_FEES,
        VOTER_POOL_FEES,
        VOTER_VOTE_INCENTIVE
    }
}