/**
 *Submitted for verification at Arbiscan on 2023-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// reward calculator contract interface
interface RewardCalcInterface {
    function getRewardAmount(uint256 _jackpotBalance) external view returns (uint256);
}

// Reward handling contract
contract Jackpot {
    address public owner;
    address public randomizer; // randomizer address
    uint256 public randomizationFee; // randomization fee ( only qualifier pay it )
    uint256 public gasFee; // randomization gas fee ( only qualifier pay it )
    uint256 public winThreshold; // lowest qualified winning swap amount
    RewardCalcInterface rewardCalc; // reward calculator contract

    // only owner modifier
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // only randomizer modifier
    modifier onlyRandomizer() {
        require(msg.sender == randomizer, "Only Randomizer");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address _rewardCalculatorAddress, address _randomizer) {
        owner = msg.sender;
        randomizer = _randomizer;
        rewardCalc = RewardCalcInterface(_rewardCalculatorAddress);
        winThreshold = 100000000000000000;  // 0.1 ETH
        randomizationFee = 500000000000000; // 0.0005 ETH 
        gasFee = 500000000000000; // 0.0005 ETH 
    }
    
    // reward swapper
    function rewardSwapper(address _swapper) external onlyRandomizer {
        // get the reward amount
        uint256 reward = rewardCalc.getRewardAmount(address(this).balance);
        // transfer reward amount
        payable(_swapper).transfer(reward);
    }

    function payFees() external payable onlyRandomizer {
        // transfer gas and randomization fees
        payable(owner).transfer(gasFee);
        payable(randomizer).transfer(randomizationFee);
    }

    // transfers ownership
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }
    
    // update reward calculator contract
    function setRewardCalculator(address _newAddress) external onlyOwner {
        rewardCalc = RewardCalcInterface(_newAddress);
    }

    // update randomizer address
    function setRandomizer(address _newAddress) external onlyOwner {
        randomizer = _newAddress;
    }

    // update randomization fee
    function setRandomizationFee(uint256 _fee) external onlyOwner {
        randomizationFee = _fee;
    }

    // update randomization gas fee
    function setGasFee(uint256 _fee) external onlyOwner {
        gasFee = _fee;
    }

    // update winning threshold fee
    function setWinThreshold(uint256 _threshold) external onlyOwner {
        winThreshold = _threshold;
    }

    // migrate
    function migrate(address _newJackpot) external onlyOwner {
        payable(_newJackpot).transfer(address(this).balance);
    }
    
    fallback() external payable {}
    receive() external payable {}
}