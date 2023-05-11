/**
 *Submitted for verification at Arbiscan on 2023-04-13
*/

//SPDX-License-Identifier: UNLICENSED
//arb 0x2df5ae0074416c1fa15275ef619e09362efc9bef
//to loop from radiant
pragma solidity 0.8.19;
pragma abicoder v2;

import "./Base.sol";

IBalancer constant BALANCER = IBalancer(0xBA12222222228d8Ba445958a75a0704d566BF2C8);
ILendingPool constant lendingPool = ILendingPool(0xF4B1486DD74D07706052A33d31d7c0AAFD0659E1);
uint256 constant MAX = 2**256-1;

contract RDNT{
    address owner;
    constructor(){
        owner = msg.sender;
    }
    function proxyCall(address target, bytes calldata call, uint256 value) public{
        require(owner == msg.sender, "onlyOwner");
        (bool success, bytes memory retval) = target.call{value:value}(call);
        require(success, string(retval));
    }

    function withdraw(
        IRTOKEN rToken,
        IRTOKEN debtToken
    ) public {
        address asset_address = rToken.UNDERLYING_ASSET_ADDRESS();
        require(asset_address == debtToken.UNDERLYING_ASSET_ADDRESS(), "bad param");
        IERC20(asset_address).approve(address(lendingPool), type(uint256).max);

        uint256 debt_amount = debtToken.balanceOf(msg.sender);
        uint256 asset_amount = rToken.balanceOf(msg.sender);
        
        address[] memory tokens = new address[](1);
        tokens[0] = asset_address;
        uint[] memory amounts = new uint[](1);
        amounts[0] = debt_amount;
        BALANCER.flashLoan(address(this), tokens, amounts,  abi.encode(address(rToken), asset_address, debt_amount, asset_amount, msg.sender));
    }

    function receiveFlashLoan(address[] memory, uint256[] memory, uint256[] memory, bytes memory data) external{
        (address rToken_address, address asset_address, uint256 debt_amount, uint256 asset_amount, address user_address) = abi.decode(data, (address, address, uint256, uint256, address));
        IRTOKEN rToken = IRTOKEN(rToken_address);
        require(debt_amount > 0, "no borrow amount");
        lendingPool.repay(asset_address, debt_amount, 2, user_address);
        uint256 rtoken_balance = rToken.balanceOf(user_address);
        rToken.transferFrom(user_address, address(this), rtoken_balance);
        lendingPool.withdraw(asset_address, debt_amount, msg.sender);
        lendingPool.withdraw(asset_address, asset_amount-debt_amount, user_address);
    }
}