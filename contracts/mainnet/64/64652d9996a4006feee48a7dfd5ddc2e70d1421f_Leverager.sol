/**
 *Submitted for verification at Arbiscan on 2023-02-28
*/

//SPDX-License-Identifier: UNLICENSED
//arb 
//to loop from radiant
pragma solidity 0.8.19;
pragma abicoder v2;
struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
}

interface ILendingPool {
    function deposit(address asset,uint256 amount,address onBehalfOf,uint16 referralCode) external;
    function withdraw(address asset,uint256 amount,address to) external returns (uint256);
    function borrow(address asset,uint256 amount,uint256 interestRateMode,uint16 referralCode,address onBehalfOf) external;
    function repay(address asset,uint256 amount,uint256 rateMode,address onBehalfOf) external returns (uint256);
    function getConfiguration(address asset) external view returns (ReserveConfigurationMap memory);
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
interface IRTOKEN is IERC20{
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
    function approveDelegation(address delegatee, uint256 amount) external;
}
interface IBalancer{
    function flashLoan(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts,
        bytes memory userData
    ) external;
}

IBalancer constant BALANCER = IBalancer(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
ILendingPool constant lendingPool = ILendingPool(0x2032b9A8e9F7e76768CA9271003d3e43E1616B1F);
uint256 constant MAX = 2**256-1;

contract Leverager{

    uint256 private borrowAmt;

    function loop(
        IRTOKEN rToken,
        IRTOKEN debtToken
    ) external {
        address asset = rToken.UNDERLYING_ASSET_ADDRESS();
        require(asset == debtToken.UNDERLYING_ASSET_ADDRESS(), "bad param");
        IERC20(asset).approve(address(lendingPool), type(uint256).max);

        uint256 debt;

        {
        ReserveConfigurationMap memory conf =  lendingPool.getConfiguration(asset);
        uint256 ltv = conf.data % (2 ** 16); //8000
        uint256 ratio = 10000 * 10000/(10000-ltv); // 50000
        uint256 assetbal = IERC20(asset).balanceOf(msg.sender);
        IERC20(asset).transferFrom(msg.sender, address(this), assetbal);
        lendingPool.deposit(asset, assetbal, msg.sender, 0);
        uint256 collateral = rToken.balanceOf(msg.sender);
        uint256 currentDebt = debtToken.balanceOf(msg.sender);
        uint256 netAsset = collateral-currentDebt;
        uint256 targetCollateral = netAsset*ratio/10000;
        uint256 targetDebt = targetCollateral - netAsset;
        debt = targetDebt - currentDebt - 10;
        }

        address[] memory tokens = new address[](1);
        tokens[0] = asset;
        uint[] memory amounts = new uint[](1);
        amounts[0] = debt;
        borrowAmt = debt;
        BALANCER.flashLoan(address(this), tokens,amounts, abi.encode(msg.sender));
        borrowAmt = 0;
    }

    function receiveFlashLoan(
        address[] memory tokens,
        uint256[] memory amounts,
        uint256[] memory feeAmounts,
        bytes memory b
    ) external{
        address asset = tokens[0];
        uint256 _borrowAmt = borrowAmt;//save gas
        require(_borrowAmt>0, "no borrowAmt");
        require(msg.sender==address(BALANCER) && amounts[0]==_borrowAmt, "bad param");
        require(feeAmounts[0]==0, "expect no fee");
        
        (address user) = abi.decode(b, (address));
        lendingPool.deposit(asset, _borrowAmt, user, 0);
        lendingPool.borrow(asset, _borrowAmt, 2, 0, user);
        IERC20(asset).transfer(msg.sender, _borrowAmt);
    }

}