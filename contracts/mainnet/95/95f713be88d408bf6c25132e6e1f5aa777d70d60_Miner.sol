/**
 *Submitted for verification at Arbiscan on 2022-06-23
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Miner {
    uint256 public toGetOneMiner = 1080000;
    uint256 public PSN = 10000;
    uint256 public PSNH = 5000;
    uint256 public market;

    mapping (address => uint256) public miningPower;
    mapping (address => uint256) public claimed;
    mapping (address => uint256) public lastDitribution;
    mapping (address => address) public referrals;

    address public devAddress = 0x71AF1059c7a6C039B34e4dbd54CEd11724C32894;

    function sinceLastDistribution(address adr) public view returns (uint256) {
        uint256 secondsPassed = min(
            toGetOneMiner,
            block.timestamp - lastDitribution[adr]
        );
        return secondsPassed * miningPower[adr];
    }

    function calculateRewards(address user) public view returns (uint256) {
        uint256 interval = rewards(user);
        uint256 value = calculateSell(interval);
        return value;
    }

    function rewards(address user) public view returns (uint256) {
        return claimed[user] + sinceLastDistribution(user);
    }

    function distribute(address ref) public {
        if (referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = ref == msg.sender ? address(0) : ref;
        }
        address referral = referrals[msg.sender] == address(0) ? devAddress : referrals[msg.sender];
        
        uint256 used = rewards(msg.sender);
        uint256 pendingMiners = used / toGetOneMiner;
        miningPower[msg.sender] = miningPower[msg.sender] + pendingMiners;
        claimed[msg.sender] = 0;
        lastDitribution[msg.sender] = block.timestamp;

        // referral
        claimed[referral] = claimed[referral] + (used / 10);

        // boost market to nerf miners hoarding
        market = market + (used / 5);
    }

    function sell() public {
        uint256 interval = rewards(msg.sender);
        uint256 value = calculateSell(interval);
        uint256 fee = getDevFee(value);
        claimed[msg.sender] = 0;
        lastDitribution[msg.sender] = block.timestamp;
        market = market + interval;
        payable(devAddress).transfer(fee);
        payable(msg.sender).transfer(value - fee);
    }

    function mine(address ref) public payable {
        require(msg.value >= 1e17, "mine: at least 0.1");
        uint256 bought = calculateMine(msg.value, address(this).balance - msg.value);
        bought = bought - getDevFee(bought);
        uint256 fee = getDevFee(msg.value);
        claimed[msg.sender] = claimed[msg.sender] + bought;
        payable(devAddress).transfer(fee);
        distribute(ref);
    }

    function seedMarket() public payable {
        require(market == 0, "market not 0");
        market = 108000000000;
    }

    function calculateMine(uint256 value, uint256 balance) public view returns (uint256) {
        return calculateTrade(value, balance, market);
    }

    function calculateSell(uint256 interval) public view returns(uint256) {
        return calculateTrade(interval, market, address(this).balance);
    }

    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) public view returns (uint256) {
        return (PSN * bs) / (PSNH + ((PSN * rs) + (PSNH * rt)) / rt);
    }

    function getDevFee(uint256 amount) public pure returns(uint256) {
        return amount * 3 / 100;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}