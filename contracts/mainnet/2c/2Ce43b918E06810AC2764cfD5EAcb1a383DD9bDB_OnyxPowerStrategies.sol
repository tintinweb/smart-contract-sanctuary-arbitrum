/**
 *Submitted for verification at Arbiscan on 2023-05-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ERC20 {
    function balanceOf(address) external view returns (uint256);
}

contract OnyxPowerStrategies {
    address public owner;
    address[] public strategies;

    constructor(address _owner, address[] memory _strategies) {
        strategies = _strategies;
        owner = _owner;
    }

    function setStrategies(address[] memory _strategies) external {
        require(msg.sender == owner, "Not owner");

        strategies = _strategies;
    }

    function balanceOf(address account) external view returns (uint256) {
        uint power = 0;

        // Loop over ONYX.balanceOf strategies
        for (uint8 i = 0; i < strategies.length; i++) {
            ERC20 strategy = ERC20(strategies[i]);
            power += strategy.balanceOf(account);
        }

        return (power);
    }
}