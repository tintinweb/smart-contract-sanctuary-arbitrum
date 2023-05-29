// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "Ownable.sol";
contract BallotTest is Ownable {

    constructor() {

    }

    //合约地址可以接受转账
    receive() external payable{}
    
    fallback() external payable{}

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed.");
    }

}