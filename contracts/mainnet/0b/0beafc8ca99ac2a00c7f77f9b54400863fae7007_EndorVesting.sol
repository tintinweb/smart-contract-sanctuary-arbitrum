/**
 *Submitted for verification at Arbiscan on 2023-02-01
*/

pragma solidity ^0.8.0;

contract EndorVesting {
    address owner;
    uint256 public totalSupply;
    uint256 public vestedAmount;
    uint256 public vestingPeriod;
    uint256 public vestingStart;

    constructor() public {
        owner = msg.sender;
        totalSupply = 1000000000000000000;
        vestingPeriod = 2629800;
        vestingStart = block.timestamp;
    }

    function releaseVestedAmount() public {
        uint256 elapsedTime = block.timestamp - vestingStart;
        uint256 vestedAmountNow = elapsedTime * totalSupply / vestingPeriod;
        require(vestedAmountNow > vestedAmount, "Not enough vested tokens available.");
        vestedAmount = vestedAmountNow;
        payable(owner).transfer(vestedAmountNow);
    }

    function getVestedAmount() public view returns (uint256) {
        return vestedAmount;
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }
}