// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./BlackListable.sol";

contract QIONGBI is ERC20, BlackListable{

    //50%锁定
    address private account1 = 0xbD0340e4bc9890D0871359aB5427A6CD9645aFbd;
    //5%扶贫钱包
    address private account2 = 0x20C5f54eE99E1E57b1F5007b7D92dC3feD0ee538;
    //3%用于CEX
    address private account3 = 0x2883b4464695f876b5422C9C0F7b86A93879f235;
    //2%用于营销推广
    address private account4 = 0x4039345101bf693380d0FA8a199C5a8398Ead476;
    //40%底池
    address private account5 = 0xF9aB7EB167BEAC10a44C3c427eE5bB517Eb581D7;

    uint8 private accountCount = 0;

    constructor() ERC20("QIONGBI Token", "QIONGBI") {
        uint256 total = 10000000000000 * (10 ** 8);
        _mint(account1, total / uint256(2));
        _mint(account2, total / uint256(20));
        _mint(account3, total * uint256(3) / uint256(100));
        _mint(account4, total / uint256(50));
        _mint(account5, total * uint256(2) / uint256(5));
    }

    function _beforeTokenTransfer(
        address from,
        address to
    ) override internal virtual {
        require( from != account1);

        require(!isBlackListed[to] && !isBlackListed[from], "Blacklisted");
    }

    function _afterTokenTransfer(
        address from,
        address to
    ) override internal virtual {

        if (balanceOf(from) > 0 && balanceOf(to) > 0 && to != address(0)) {
            accountCount++;
        }

        if(accountCount == 1000 || accountCount == 2000){
            _burn(from, totalSupply() / uint256(20));
        }
        if(accountCount == 3000 || accountCount == 5000){
            _burn(from, totalSupply() / uint256(10));
        }
        if(accountCount == 10000){
            _burn(from, totalSupply() / uint256(5));
        }
    }
}