/**
 *Submitted for verification at Arbiscan on 2023-03-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract BFRListingsData {
    struct BFRData {
        uint256 StakedBFRBal;
        uint256 esBFRBal;
        uint256 StakedesBFRBal;
        uint256 esBFRMaxVestBFRBal;
        uint256 esBFRMaxVestBlpBal;
        uint256 TokensToVest;
        uint256 BlpToVest;
        uint256 BlpBal;
        uint256 MPsBal;
        uint256 PendingUSDCBal;
        uint256 PendingesBFRBal;
        uint256 PendingMPsBal;
        uint256 SalePrice;
        uint256 EndAt;
    }

    struct BFRAccountData {
        uint256 StakedBFRBal;
        uint256 esBFRBal;
        uint256 StakedesBFRBal;
        uint256 esBFRMaxVestBFRBal;
        uint256 esBFRMaxVestBlpBal;
        uint256 TokensToVest;
        uint256 BlpToVest;
        uint256 BlpBal;
        uint256 MPsBal;
        uint256 PendingUSDCBal;
        uint256 PendingesBFRBal;
        uint256 PendingMPsBal;
    }

    address constant private EsBFR = 0x92914A456EbE5DB6A69905f029d6160CF51d3E6a;
    address constant private WETH = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address constant private USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address constant private BFR = 0x1A5B0aaF478bf1FDA7b934c76E7692D722982a6D;
    address constant private BFRRewardRouter = 0xbD5FBB3b2610d34434E316e1BABb9c3751567B67;
    address constant private stakedBFRTracker = 0x173817F33f1C09bCb0df436c2f327B9504d6e067;
    address constant private bonusBFRTracker = 0x00B88B6254B51C7b238c4675E6b601a696CC1aC8;
    address constant private feeBFRTracker = 0xBABF696008DDAde1e17D302b972376B8A7357698;
    address constant private BFRVester = 0x92f424a2A65efd48ea57b10D345f4B3f2460F8c8;
    address constant private stakedBlpTracker = 0x7d1d610Fe82482412842e8110afF1cB72FA66bc8;
    address constant private feeBlpTracker = 0xCCFd47cCabbF058Fb5566CC31b552b21279bd89a;
    address constant private BlpVester = 0x22499C54cD0F38fE75B2805619Ac8d0e815e3DC7;

    function GetBFRListingsData(address _Address) external view returns (BFRData memory) {
       BFRData memory BFRDataOut;
       BFRDataOut.StakedBFRBal = IRewardTracker(stakedBFRTracker).depositBalances(_Address, 0x1A5B0aaF478bf1FDA7b934c76E7692D722982a6D);
       BFRDataOut.esBFRBal = IERC20(EsBFR).balanceOf(_Address);
       BFRDataOut.StakedesBFRBal = IRewardTracker(stakedBFRTracker).depositBalances(_Address, 0x92914A456EbE5DB6A69905f029d6160CF51d3E6a);
       BFRDataOut.esBFRMaxVestBFRBal = IVester(BFRVester).getMaxVestableAmount(_Address);
       BFRDataOut.esBFRMaxVestBlpBal = IVester(BlpVester).getMaxVestableAmount(_Address);
       BFRDataOut.TokensToVest = IVester(BFRVester).getCombinedAverageStakedAmount(_Address);
       BFRDataOut.BlpToVest = IVester(BlpVester).getCombinedAverageStakedAmount(_Address);
       BFRDataOut.BlpBal = IERC20(stakedBlpTracker).balanceOf(_Address);
       BFRDataOut.MPsBal = IRewardTracker(feeBFRTracker).depositBalances(_Address, 0xD978595622184c6c64BF0ab7127f3728ca4F1E4a);
       BFRDataOut.PendingUSDCBal = IRewardTracker(feeBFRTracker).claimable(_Address);
       BFRDataOut.PendingesBFRBal = IRewardTracker(stakedBFRTracker).claimable(_Address) + IRewardTracker(stakedBlpTracker).claimable(_Address);
       BFRDataOut.PendingMPsBal = IRewardTracker(bonusBFRTracker).claimable(_Address);
       BFRDataOut.SalePrice = IBFRVault(_Address).SalePrice();
       BFRDataOut.EndAt = IBFRVault(_Address).EndAt();
       return (BFRDataOut);
    }

function GetBFRAccountData(address _Address) external view returns (BFRAccountData memory) {
       BFRAccountData memory BFRAccountDataOut;
       BFRAccountDataOut.StakedBFRBal = IRewardTracker(stakedBFRTracker).depositBalances(_Address, 0x1A5B0aaF478bf1FDA7b934c76E7692D722982a6D);
       BFRAccountDataOut.esBFRBal = IERC20(EsBFR).balanceOf(_Address);
       BFRAccountDataOut.StakedesBFRBal = IRewardTracker(stakedBFRTracker).depositBalances(_Address, 0x92914A456EbE5DB6A69905f029d6160CF51d3E6a);
       BFRAccountDataOut.esBFRMaxVestBFRBal = IVester(BFRVester).getMaxVestableAmount(_Address);
       BFRAccountDataOut.esBFRMaxVestBlpBal = IVester(BlpVester).getMaxVestableAmount(_Address);
       BFRAccountDataOut.TokensToVest = IVester(BFRVester).getCombinedAverageStakedAmount(_Address);
       BFRAccountDataOut.BlpToVest = IVester(BlpVester).getCombinedAverageStakedAmount(_Address);
       BFRAccountDataOut.BlpBal = IERC20(stakedBlpTracker).balanceOf(_Address);
       BFRAccountDataOut.MPsBal = IRewardTracker(feeBFRTracker).depositBalances(_Address, 0xD978595622184c6c64BF0ab7127f3728ca4F1E4a);
       BFRAccountDataOut.PendingUSDCBal = IRewardTracker(feeBFRTracker).claimable(_Address);
       BFRAccountDataOut.PendingesBFRBal = IRewardTracker(stakedBFRTracker).claimable(_Address) + IRewardTracker(stakedBlpTracker).claimable(_Address);
       BFRAccountDataOut.PendingMPsBal = IRewardTracker(bonusBFRTracker).claimable(_Address);
       return (BFRAccountDataOut);
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
    function getCombinedAverageStakedAmount(address _account) external view returns (uint256);
}

interface IBFRVault {
    function SalePrice() external view returns (uint256);
    function EndAt() external view returns (uint256);
}