/**
 *Submitted for verification at Arbiscan.io on 2023-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Faucet {
    address private _owner;
    address private _operator;
    uint256 private _amount;

    modifier onlyAuthorized() {
        require(_owner == msg.sender || _operator == msg.sender, "Caller is not authorized");
        _;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not authorized");
        _;
    }

    constructor(uint256 amount_) {
        _owner = msg.sender;
        _amount = amount_;
    }

    function setAmount(uint256 amount_) external onlyAuthorized {
        _amount = amount_;
    }

    function setOperator(address operator_) external onlyOwner {
        _operator = operator_;
    }

    function setOwner(address payable owner_) external onlyOwner {
        _owner = owner_;
    }

    function sendOne(address payable recipient) external onlyAuthorized {
        (bool sent, ) = recipient.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function send(address[] calldata recipients) external onlyAuthorized {
        for(uint256 i = 0; i < recipients.length; i++) {
            address addr = recipients[i];
            (bool sent, ) = addr.call{value: _amount}("");
            require(sent, "Failed to send Ether");
        }
    }

    function withdraw() external onlyOwner {
        (bool sent, ) = _owner.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
}