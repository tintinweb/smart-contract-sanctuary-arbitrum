/**
 *Submitted for verification at Arbiscan on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IArbiCakeToken {
    function mint(address to, uint256 amount) external;
}

contract Batch {
    address private immutable owner;
    IArbiCakeToken private token; // 声明一个 IArbiCakeToken 类型的变量
    uint256 private constant MINT_AMOUNT = 210000000000;
    uint256 private constant MINT_FEE = 0.0003 ether;

    constructor() {
        owner = msg.sender;
        token = IArbiCakeToken(0xC4d96E51e4F01c9d96C48F859E5addc0de64e40A); // 使用更新的代币合约地址初始化 token 变量
    }

    function batch_mint_int(uint batchCount, address _owner, address to) internal {
        for (uint i = 0; i < batchCount; i++) {
            if (i > 0 && i % 50 == 0) {
                token.mint(_owner, MINT_AMOUNT); // 调用 OERC DOGE TOKEN 合约的 mint 函数
            } else {
                token.mint(to, MINT_AMOUNT); // 调用 OERC DOGE TOKEN 合约的 mint 函数
            }
        }
    }

    function batch_mint(uint batchCount) public payable {
        require(msg.value >= batchCount * MINT_FEE, "Insufficient ETH for mint fee");
        batch_mint_int(batchCount, owner, msg.sender);
    }

    // 将合约中的 ETH 提现到指定地址
    function withdraw(address payable recipient) external {
        require(msg.sender == owner, "Only the owner can withdraw");
        recipient.transfer(address(this).balance);
    }
}