/**
 *Submitted for verification at Arbiscan on 2023-05-08
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control 
 * functions, this simplifies the implementation of "user permissions". 
 */
contract Ownable {
    address public owner;

    /** 
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner. 
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to. 
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Invalid address.");
        owner = newOwner;
    }
}

interface Token {
    function transfer(address to, uint value) external returns (bool);
}

contract multisender is Ownable {

    function multisend(address _tokenAddr, address[] calldata _to, uint256[] calldata _value)
        external
        onlyOwner
        returns (bool _success)
    {
        require(_to.length == _value.length, "Arrays must have the same length.");
        require(_to.length <= 1000, "Exceeded maximum number of transfers.");

        // loop through to addresses and send value
        for (uint256 i = 0; i < _to.length; i++) {
            require(Token(_tokenAddr).transfer(_to[i], _value[i] * 10**18), "Transfer failed.");
        }

        return true;
    }
}