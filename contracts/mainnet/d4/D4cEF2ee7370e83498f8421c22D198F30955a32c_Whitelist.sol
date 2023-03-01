// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Whitelist {
    address public owner;

    mapping(address => bool) public isWhitelists;
    mapping(address => bool) public managers;

    constructor() {
        owner = msg.sender;
        managers[owner] = true;
    }

    modifier ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    modifier ownerManager() {
        require(managers[msg.sender], "PERMISSION_DENIED");
        _;
    }

    function addManager(address manager, bool isActive) external ownerOnly {
        managers[manager] = isActive;
    }

    function addWhitelist(address user) external ownerManager {
        isWhitelists[user] = true;
    }

    function addWhitelists(address[] memory users) external ownerManager {
        uint256 arrayLength = users.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            isWhitelists[users[i]] = true;
        }
    }
}