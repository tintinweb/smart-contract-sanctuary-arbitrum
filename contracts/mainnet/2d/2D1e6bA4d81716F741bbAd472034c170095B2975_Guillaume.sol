/**
 *Submitted for verification at Arbiscan on 2022-05-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Guillaume {
    address payable public  owner;

    uint256 public totalLiquidity;
    mapping(address => uint256) public depositedAmount;

    string public greeter;

    constructor() {
        owner = payable(msg.sender);
        greeter = "Ceci est le contract pour Guilaume";
    }

    function deposit() public payable{
        require(msg.value >= 5000000000000000,"!amount");
        depositedAmount[msg.sender] += msg.value;
        totalLiquidity += msg.value;
    }

    function withdrawAll() public {
        require(msg.sender == owner,"!auth");
        owner.transfer(totalLiquidity);
    }

}