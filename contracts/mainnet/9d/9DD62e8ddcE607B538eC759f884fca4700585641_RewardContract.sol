// SPDX-License-Identifier: MIT

pragma solidity >0.8.0;

import "./IERC20.sol";

contract RewardContract {
    string public Name;
    string public Twitter;
    address public Bird;
    uint256 public DeployedTimestamp;

    constructor (address _birdAddress) {
        Name = "Bird Rewards Contract";
        Twitter = "https://twitter.com/BirdArbitrum";
        Bird = _birdAddress;
        DeployedTimestamp = block.timestamp;
    }

    function getBirdBalance() public view returns (uint256) {
        return IERC20(Bird).balanceOf(address(this));
    }

}