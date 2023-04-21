/**
 *Submitted for verification at Arbiscan on 2023-04-21
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
    uint256 public gasFee; // win qualification gas fee ( only qualifier pay it )
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
        randomizationFee = 300000000000000; // 0.0003 ETH
        gasFee = 300000000000000; // 0.0003 ETH
    }

    // reward swapper
    function rewardSwapper(address _swapper) external onlyRandomizer {
        // get the reward amount
        uint256 reward = rewardCalc.getRewardAmount(address(this).balance);
        // transfer reward amount
        payable(_swapper).transfer(reward);
    }

    
    // pay fees to randomizer to handle the randomization
    function payFees() external onlyRandomizer {
        // transfer gas and randomization fees
        payable(owner).transfer(gasFee);
        payable(randomizer).transfer(randomizationFee);
    }

    function geBalance() public view returns (uint256){
        return address(this).balance;
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
    function setRandomizationFees(uint256 _randomizationFee) external onlyOwner {
        randomizationFee = _randomizationFee;
    }

    // update gas fee
    function setGasFees(uint256 _gasFee) external onlyOwner {
        gasFee = _gasFee;
    }
    
    // migrate jackpot's funds to a new jackpot
    function migrate(address _newJackpot) external onlyOwner {
        payable(_newJackpot).transfer(address(this).balance);
    }

     // transfers ownership
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    fallback() external payable {}
    receive() external payable {}
}