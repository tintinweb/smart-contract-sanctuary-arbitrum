/**
 *Submitted for verification at Arbiscan on 2023-06-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract FLC {
    string public name = "FairLaunch Coin";
    string public symbol = "FLC";
    uint256 public totalSupply = 10000000 * 10**18; // 10 million FLC tokens, assuming 18 decimal places precision

    mapping(address => uint256) public balances;
    mapping(address => address) public referrer;
    mapping(address => uint256) public referralRewards;

    uint256 public airdropCount = 0;
    uint256 public airdropPerWallet = 1000 * 10**18; // Initial airdrop amount per wallet

    address public serverAddress;
    bool public airdropComplete = false;

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function claimAirdrop() external {
        require(!airdropComplete, "Airdrop has already been completed");

        address walletAddress = msg.sender;
        require(isEligibleForAirdrop(walletAddress), "Not eligible for airdrop");
        require(balances[walletAddress] == 0, "Airdrop already claimed");

        uint256 airdropAmount = calculateAirdropAmount();
        require(airdropAmount > 0, "No more airdrop available");

        airdropCount += airdropAmount;
        balances[walletAddress] = airdropAmount;

        distributeReferralRewards(walletAddress, airdropAmount);

        if (airdropCount >= totalSupply) {
            airdropComplete = true;
        }

        emit AirdropClaimed(walletAddress, airdropAmount);
    }

    function isEligibleForAirdrop(address /*wallet*/) internal pure returns (bool) {
        // Check if the wallet has at least 2 transactions per month for the past 12 months
        // and average balance >= 0.05 ether
        // Add your own implementation or integration with external services to check eligibility
        return true; // Placeholder implementation
    }

    function calculateAirdropAmount() internal view returns (uint256) {
        uint256 remainingAirdrop = totalSupply - airdropCount;
        uint256 availableAirdrop = remainingAirdrop > 1000000 * 10**18 ? airdropPerWallet : remainingAirdrop / 2;
        return availableAirdrop;
    }

    function distributeReferralRewards(address wallet, uint256 airdropAmount) internal {
        address referrer1 = referrer[wallet];
        if (referrer1 != address(0)) {
            uint256 referralReward1 = airdropAmount * 20 / 100;
            balances[referrer1] += referralReward1;
            referralRewards[referrer1] += referralReward1;

            address referrer2 = referrer[referrer1];
            if (referrer2 != address(0)) {
                uint256 referralReward2 = airdropAmount * 10 / 100;
                balances[referrer2] += referralReward2;
                referralRewards[referrer2] += referralReward2;

                address referrer3 = referrer[referrer2];
                if (referrer3 != address(0)) {
                    uint256 referralReward3 = airdropAmount * 5 / 100;
                    balances[referrer3] += referralReward3;
                    referralRewards[referrer3] += referralReward3;
                }
            }
        }
    }

    function setServerAddress(address _serverAddress) external {
        require(serverAddress == address(0), "Server address already set");
        serverAddress = _serverAddress;
    }

    function getRemainingAirdropAmount() public view returns (uint256) {
        uint256 remainingAirdrop = totalSupply - airdropCount;
        return remainingAirdrop;
    }

    function getContractBalance() public view returns (uint256) {
        address contractAddress = address(this);
        return balances[contractAddress];
    }

    event AirdropClaimed(address indexed walletAddress, uint256 amount);
}