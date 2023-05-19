/**
 *Submitted for verification at Arbiscan on 2023-05-19
*/

pragma solidity ^0.8.0;

contract Fee {
    address public owner;
    uint256 public stableFee;
    uint256 public volatileFee;

    constructor() {
        owner = msg.sender;
        stableFee = 4;
        volatileFee = 20;
    }

    function setStableFee(uint _stableFee) external {
        require(owner == msg.sender, "Only owner");
        stableFee = _stableFee;
    }

    function setVolatileFee(uint _volatileFee) external {
        require(owner == msg.sender, "Only owner");
        volatileFee = _volatileFee;
    }
}