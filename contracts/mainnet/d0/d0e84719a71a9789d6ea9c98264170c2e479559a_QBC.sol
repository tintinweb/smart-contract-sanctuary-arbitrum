// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./BlackListable.sol";

contract QBC is ERC20, BlackListable{

    //50%锁定
    address private account1 = 0xBc5303015F49DBCfDFe4EAAbF49B634ac2038C30;
    //5%扶贫钱包
    address private account2 = 0xB316f19DE356Ee9285b48536532DE17120dD009C;
    //3%用于CEX
    address private account3 = 0xc8E11a4B2882c07c19Af3813B8672Fa4E5AeeE06;
    //2%用于营销推广
    address private account4 = 0x5b4e6450FAC49cA12219BE8aF117D99D6102929c;
    //40%底池
    address private account5 = 0x600c894E41d9e9D5869cd5eE6DC9aC3011C968b6;

    uint8 private accountCount = 0;

    constructor() ERC20("QBCS Token", "QBCS") {
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