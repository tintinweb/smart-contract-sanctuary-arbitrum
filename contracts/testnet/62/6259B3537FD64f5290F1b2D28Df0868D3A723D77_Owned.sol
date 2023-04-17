// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/** 
    @title Owned
    @dev allows for ownership transfer and a contract that inherits from it.
    @author abhaydeshpande
*/

contract Owned {
    address payable public owner;

    constructor() public {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    function transferOwnership(address payable newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner address cannot be zero");
        owner = newOwner;
    }
}

contract MyContract is Owned {
    fallback() external payable {
        revert("Invalid transaction");
    }

    receive() external payable {
        owner.transfer(msg.value);
    }
}