// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


/**
    @title Migrations
    @dev allows the contract owner to set and upgrade a migration
    @author abhaydeshpande
 */
contract Migrations {
    address public owner;
    uint public last_completed_migration;
    bool public paused = false;

    constructor() public{
        owner = msg.sender;
    }

    modifier restricted() {
        require(msg.sender == owner, "Access Denied");
        require(!paused, "Contract Paused");
        _;
    }

    function setCompleted(uint completed) public restricted {
        last_completed_migration = completed;
    }

    function upgrade(address new_address) public restricted {
        Migrations upgraded = Migrations(new_address);
        upgraded.setCompleted(last_completed_migration);
    }

    function pause() public restricted {
        paused = true;
    }

    function resume() public restricted {
        paused = false;
    }
}