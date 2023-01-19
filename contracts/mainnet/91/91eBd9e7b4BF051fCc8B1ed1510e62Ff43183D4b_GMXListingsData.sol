/**
 *Submitted for verification at Arbiscan on 2023-01-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract GMXListingsData {
    struct GMXData {
        uint256 StakedGMXBal;
        uint256 esGMXBal;
        uint256 StakedesGMXBal;
        uint256 esGMXMaxVestGMXBal;
        uint256 esGMXMaxVestGLPBal;
        uint256 GLPBal;
        uint256 MPsBal;
        uint256 PendingWETHBal;
        uint256 PendingesGMXBal;
        uint256 PendingMPsBal;
        uint256 SalePrice;
        uint256 EndAt;
    }

    address constant private EsGMX = 0xf42Ae1D54fd613C9bb14810b0588FaAa09a426cA;
    address constant private WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant private GMX = 0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a;
    address constant private GMXRewardRouter = 0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1;
    address constant private stakedGmxTracker = 0x908C4D94D34924765f1eDc22A1DD098397c59dD4;
    address constant private bonusGmxTracker = 0x4d268a7d4C16ceB5a606c173Bd974984343fea13;
    address constant private feeGmxTracker = 0xd2D1162512F927a7e282Ef43a362659E4F2a728F;
    address constant private gmxVester = 0x199070DDfd1CFb69173aa2F7e20906F26B363004;
    address constant private stakedGlpTracker = 0x1aDDD80E6039594eE970E5872D247bf0414C8903;
    address constant private feeGlpTracker = 0x4e971a87900b931fF39d1Aad67697F49835400b6;
    address constant private glpVester = 0xA75287d2f8b217273E7FCD7E86eF07D33972042E;

    function GetGMXListingsData(address _Address) external view returns (GMXData memory) {
       GMXData memory GMXDataOut;
       GMXDataOut.StakedGMXBal = IRewardTracker(stakedGmxTracker).depositBalances(_Address, 0xfc5A1A6EB076a2C7aD06eD22C90d7E710E35ad0a);
       GMXDataOut.esGMXBal = IERC20(EsGMX).balanceOf(_Address);
       GMXDataOut.StakedesGMXBal = IRewardTracker(stakedGmxTracker).depositBalances(_Address, 0xf42Ae1D54fd613C9bb14810b0588FaAa09a426cA);
       GMXDataOut.esGMXMaxVestGMXBal = IVester(gmxVester).getMaxVestableAmount(_Address);
       GMXDataOut.esGMXMaxVestGLPBal = IVester(glpVester).getMaxVestableAmount(_Address);
       GMXDataOut.GLPBal = IERC20(stakedGlpTracker).balanceOf(_Address);
       GMXDataOut.MPsBal = IRewardTracker(feeGmxTracker).depositBalances(_Address, 0x35247165119B69A40edD5304969560D0ef486921);
       GMXDataOut.PendingWETHBal = IRewardTracker(feeGmxTracker).claimable(_Address);
       GMXDataOut.PendingesGMXBal = IRewardTracker(stakedGmxTracker).claimable(_Address) + IRewardTracker(stakedGlpTracker).claimable(_Address);
       GMXDataOut.PendingMPsBal = IRewardTracker(bonusGmxTracker).claimable(_Address);
       GMXDataOut.SalePrice = IGMXVault(_Address).SalePrice();
       GMXDataOut.EndAt = IGMXVault(_Address).EndAt();
       return (GMXDataOut);
    }
}

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);
    function stakedAmounts(address _account) external returns (uint256);
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

interface IVester {
    function getMaxVestableAmount(address _account) external view returns (uint256);
}

interface IGMXVault {
    function SalePrice() external view returns (uint256);
    function EndAt() external view returns (uint256);
}