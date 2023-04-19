/**
 *Submitted for verification at Arbiscan on 2023-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
}

contract RewardCalculator {
    using SafeMath for uint256;
    address public owner;
    address public jackpot;
    uint256 public percentageNumerator;
    uint256 public percentageDenominator;

    event RewardAmountCalculated(uint256 indexed reward);

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not owner");
        _;
    }

    modifier onlyJackpot() {
        require(msg.sender == jackpot, "Only jackpot");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        owner = msg.sender;
        percentageNumerator = 75;
        percentageDenominator = 100;
    }

    function getRewardAmount(uint256 _jackpotBalance) public view onlyJackpot returns (uint256) {
        return _jackpotBalance.mul(percentageNumerator).div(percentageDenominator);
    }

    function setPayout(uint256 _numerator, uint256 _denominator) external onlyOwner {
        percentageNumerator = _numerator;
        percentageDenominator = _denominator;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function setJackpot(address _newJackpot) external onlyOwner{
        jackpot = _newJackpot;
    }
}