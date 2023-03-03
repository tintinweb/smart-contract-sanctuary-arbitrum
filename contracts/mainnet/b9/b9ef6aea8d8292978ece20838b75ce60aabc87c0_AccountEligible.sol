/**
 *Submitted for verification at Arbiscan on 2023-03-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
contract AccountEligible{
    address constant private EsBFR = 0x92914A456EbE5DB6A69905f029d6160CF51d3E6a;
    address constant private WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant private BFR = 0x1A5B0aaF478bf1FDA7b934c76E7692D722982a6D;
    address constant private BFRRewardRouter = 0xbD5FBB3b2610d34434E316e1BABb9c3751567B67;
    address constant private stakedBFRTracker = 0x173817F33f1C09bCb0df436c2f327B9504d6e067;
    address constant private bonusBFRTracker = 0x00B88B6254B51C7b238c4675E6b601a696CC1aC8;
    address constant private feeBFRTracker = 0xBABF696008DDAde1e17D302b972376B8A7357698;
    address constant private BFRVester = 0x92f424a2A65efd48ea57b10D345f4B3f2460F8c8;
    address constant private stakedBlpTracker = 0x7d1d610Fe82482412842e8110afF1cB72FA66bc8;
    address constant private feeBlpTracker = 0xCCFd47cCabbF058Fb5566CC31b552b21279bd89a;
    address constant private BlpVester = 0x22499C54cD0F38fE75B2805619Ac8d0e815e3DC7;
    function TransferEligible(address _receiver) external view returns (bool Eligible) {
        Eligible = true;
        if (IRewardTracker(stakedBFRTracker).averageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(stakedBFRTracker).cumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(bonusBFRTracker).averageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(bonusBFRTracker).cumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }       
        if (IRewardTracker(feeBFRTracker).averageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(feeBFRTracker).cumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }
        if (IVester(BFRVester).transferredAverageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IVester(BFRVester).transferredCumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(stakedBlpTracker).averageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(stakedBlpTracker).cumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(feeBlpTracker).averageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(feeBlpTracker).cumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }
        if (IVester(BlpVester).transferredAverageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IVester(BlpVester).transferredCumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }
        if (IERC20(BFRVester).balanceOf(_receiver) > 0) {
            Eligible = false;
        }
        if (IERC20(BlpVester).balanceOf(_receiver) > 0) {
            Eligible = false;
        }
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);
    function stakedAmounts(address _account) external view returns (uint256);
    function updateRewards() external;
    function stake(address _depositToken, uint256 _amount) external;
    function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount) external;
    function unstake(address _depositToken, uint256 _amount) external;
    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;
    function tokensPerInterval() external view returns (uint256);
    function claim(address _receiver) external returns (uint256);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function averageStakedAmounts(address _account) external view returns (uint256);
    function cumulativeRewards(address _account) external view returns (uint256);
}
interface IVester {
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function transferredAverageStakedAmounts(address _account) external view returns (uint256);
    function transferredCumulativeRewards(address _account) external view returns (uint256);
    function cumulativeRewardDeductions(address _account) external view returns (uint256);
    function bonusRewards(address _account) external view returns (uint256);
    function transferStakeValues(address _sender, address _receiver) external;
    function setTransferredAverageStakedAmounts(address _account, uint256 _amount) external;
    function setTransferredCumulativeRewards(address _account, uint256 _amount) external;
    function setCumulativeRewardDeductions(address _account, uint256 _amount) external;
    function setBonusRewards(address _account, uint256 _amount) external;
    function getMaxVestableAmount(address _account) external view returns (uint256);
    function getCombinedAverageStakedAmount(address _account) external view returns (uint256);
}