/**
 *Submitted for verification at Arbiscan.io on 2024-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract SponsorContract {
    // Mapping to store owner status
    mapping(address => bool) public isOwner;

    // Event for ownership changes
    event OwnershipGranted(address indexed newOwner);
    event OwnershipRevoked(address indexed oldOwner);

    constructor(address _owner1, address _owner2) {
        isOwner[_owner1] = true;
        isOwner[_owner2] = true;
        emit OwnershipGranted(_owner1);
        emit OwnershipGranted(_owner2);
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Caller is not an owner");
        _;
    }

    receive() external payable {}

    // Function to allow owners to execute transactions on behalf of the contract
    function sponsorTransaction(address target, bytes calldata data) public onlyOwner {
        (bool success, ) = target.call(data);
        require(success, "Transaction failed");
    }

    // Function to allow owners to execute transactions
    function executeTransaction(address target, bytes memory data) public payable onlyOwner {
        (bool success, ) = target.call{value: msg.value}(data);
        require(success, "Transaction failed");
    }

    // Administrative functions to manage owners
    function addOwner(address newOwner) public onlyOwner {
        isOwner[newOwner] = true;
        emit OwnershipGranted(newOwner);
    }

    function removeOwner(address oldOwner) public onlyOwner {
        isOwner[oldOwner] = false;
        emit OwnershipRevoked(oldOwner);
    }
}