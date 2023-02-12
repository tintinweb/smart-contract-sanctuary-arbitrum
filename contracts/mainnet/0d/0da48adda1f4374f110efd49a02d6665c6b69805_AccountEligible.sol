/**
 *Submitted for verification at Arbiscan on 2023-02-12
*/

// File: gmxeligible.sol


pragma solidity ^0.8.17;
contract AccountEligible{
    address constant private EsGMXAddress = 0xf42Ae1D54fd613C9bb14810b0588FaAa09a426cA;
    address constant private WETHAddress = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant private GMXAddress = 0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;
    address constant private GMXRewardRouterAddress = 0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1;
    address constant private stakedGmxTracker = 0x908C4D94D34924765f1eDc22A1DD098397c59dD4;
    address constant private bonusGmxTracker = 0x4d268a7d4C16ceB5a606c173Bd974984343fea13;
    address constant private feeGmxTracker = 0xd2D1162512F927a7e282Ef43a362659E4F2a728F;
    address constant private gmxVester = 0x199070DDfd1CFb69173aa2F7e20906F26B363004;
    address constant private stakedGlpTracker = 0x1aDDD80E6039594eE970E5872D247bf0414C8903;
    address constant private feeGlpTracker = 0x4e971a87900b931fF39d1Aad67697F49835400b6;
    address constant private glpVester = 0xA75287d2f8b217273E7FCD7E86eF07D33972042E;
    function TransferEligible(address _receiver) external view returns (bool Eligible) {
        Eligible = true;
        if (IRewardTracker(stakedGmxTracker).averageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(stakedGmxTracker).cumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(bonusGmxTracker).averageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(bonusGmxTracker).cumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }       
        if (IRewardTracker(feeGmxTracker).averageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(feeGmxTracker).cumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }
        if (IVester(gmxVester).transferredAverageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IVester(gmxVester).transferredCumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(stakedGlpTracker).averageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(stakedGlpTracker).cumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(feeGlpTracker).averageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IRewardTracker(feeGlpTracker).cumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }
        if (IVester(glpVester).transferredAverageStakedAmounts(_receiver) > 0) {
            Eligible = false;
        }
        if (IVester(glpVester).transferredCumulativeRewards(_receiver) > 0) {
            Eligible = false;
        }
        if (IERC20(gmxVester).balanceOf(_receiver) > 0) {
            Eligible = false;
        }
        if (IERC20(glpVester).balanceOf(_receiver) > 0) {
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