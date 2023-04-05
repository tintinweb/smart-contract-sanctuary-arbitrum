// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;

contract ChildChainBribeInterface {
   event ClaimRewards(
        address indexed from,
        address indexed reward,
        uint256 amount
    );
    event ClawbackRewards(address indexed reward, uint256 amount);
    event Deposit(address indexed from, uint256 tokenId, uint256 amount);
    event NotifyReward(
        address indexed from,
        address indexed reward,
        uint256 amount
    );
    event StoredRewards(address indexed reward, uint256 amount);
    event Withdraw(address indexed from, uint256 tokenId, uint256 amount);

    function DURATION() external view returns (uint256) {}

    function _deposit(uint256 amount, uint256 tokenId) external {}

    function _voter() external view returns (address) {}

    function _withdraw(uint256 amount, uint256 tokenId) external {}

    function balanceOf(uint256 tokenId) external view returns (uint256) {}

    function clawbackRewards(address token, uint256 period) external {}

    function earned(address token, uint256 tokenId)
        external
        view
        returns (uint256) {}

    function earnedStored(uint256, address) external view returns (uint256) {}

    function factoryAddress() external view returns (address _factory) {}

    function getPeriodReward(
        uint256[] memory timestamps,
        uint256 tokenId,
        address[] memory tokens
    ) external {}

    function getReward(uint256 tokenId, address[] memory tokens) external {}

    function getRewardForOwner(uint256 tokenId, address[] memory tokens)
        external {}

    function governanceAddress()
        external
        view
        returns (address _governanceAddress) {}

    function historicIsReward(address) external view returns (bool) {}

    function historicRewards(uint256) external view returns (address) {}

    function initialize(address voter, address _ve) external {}

    function isReward(address token) external view returns (bool) {}

    function lastWeekRewardRate(address token) external view returns (uint256) {}

    function left(address token) external view returns (uint256) {}

    function notifyRewardAmount(address token, uint256 amount) external {}

    function periodBalanceOf(uint256, uint256) external view returns (uint256) {}

    function periodEarned(
        uint256 timestamp,
        address token,
        uint256 tokenId
    ) external view returns (uint256) {}

    function periodIsReward(uint256, address) external view returns (bool) {}

    function periodRewardAmount(uint256, address)
        external
        view
        returns (uint256) {}

    function periodRewardClawedBack(uint256, address)
        external
        view
        returns (bool) {}

    function periodRewardPerToken(uint256 timestamp, address token)
        external
        view
        returns (uint256) {}

    function periodRewards(uint256, uint256) external view returns (address) {}

    function periodRewardsList() external view returns (address[] memory) {}

    function periodRewardsList(uint256 timestamp)
        external
        view
        returns (address[] memory) {}

    function periodRewardsListLength(uint256 timestamp)
        external
        view
        returns (uint256) {}

    function periodRewardsListLength() external view returns (uint256) {}

    function periodTotalSupply(uint256) external view returns (uint256) {}

    function periodUserRewardClaimed(
        uint256,
        uint256,
        address
    ) external view returns (bool) {}

    function rewardPerToken(address token) external view returns (uint256) {}

    function rewardRate(address token) external view returns (uint256) {}

    function rewards(uint256 index) external view returns (address) {}

    function rewardsList() external view returns (address[] memory) {}

    function rewardsListLength() external view returns (uint256) {}

    function secondLastWeekRewardRate(address token)
        external
        view
        returns (uint256) {}

    function totalSupply() external view returns (uint256) {}

    function userFirstVote(uint256) external view returns (uint256) {}

    function userLastClaimed(uint256, address) external view returns (uint256) {}

    function ve() external view returns (address) {}
}