/**
 *Submitted for verification at Arbiscan.io on 2023-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

contract DRBT_Membership {
    address public owner;
    struct MembershipOption {
        uint256 ethAmount;
        uint256 validityPeriod;
    }
    mapping(uint256 => MembershipOption) public membershipOptions; // Option ID to MembershipOption
    mapping(address => mapping(uint256 => uint256)) public userExpirations; // User address to (Option ID to Expiration Timestamp)
    uint256 public numberOfOptions;

    constructor() {
        owner = msg.sender;
        // Initialize with default options
        membershipOptions[1] = MembershipOption(0.15 ether, 31 days);
        membershipOptions[2] = MembershipOption(0.05 ether, 31 days);
        membershipOptions[3] = MembershipOption(0.2 ether, 31 days);
        membershipOptions[4] = MembershipOption(0.07 ether, 31 days);
        membershipOptions[5] = MembershipOption(0.05 ether, 3 days);
        numberOfOptions = 5;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action");
        _;
    }

    // Function buy a membership
    function buyMembership(uint256 optionId) external payable {
        require(optionId > 0 && optionId <= numberOfOptions, "Invalid option ID");
        MembershipOption memory option = membershipOptions[optionId];
        require(msg.value == option.ethAmount, "Incorrect ETH amount sent");

        uint256 expiration = userExpirations[msg.sender][optionId];
        if (expiration == 0 || expiration < block.timestamp) {
            userExpirations[msg.sender][optionId] = block.timestamp + option.validityPeriod;
        } else {
            userExpirations[msg.sender][optionId] += option.validityPeriod;
        }
    }

    // Function to check memberships for a wallet
    function checkMembership(address userAddress)
        external
        view
        returns (uint256[] memory, uint256[] memory)
    {
        uint256[] memory activeOptionIds = new uint256[](numberOfOptions);
        uint256[] memory expirationTimestamps = new uint256[](numberOfOptions);
        uint256 count = 0;

        for (uint256 i = 1; i <= numberOfOptions; i++) {
            if (userExpirations[userAddress][i] > block.timestamp) {
                activeOptionIds[count] = i;
                expirationTimestamps[count] = userExpirations[userAddress][i];
                count++;
            }
        }

        uint256[] memory validOptionIds = new uint256[](count);
        uint256[] memory validExpirations = new uint256[](count);
        for (uint256 j = 0; j < count; j++) {
            validOptionIds[j] = activeOptionIds[j];
            validExpirations[j] = expirationTimestamps[j];
        }

        return (validOptionIds, validExpirations);
    }

    // Function to set a membership option
    function setMembershipOption(uint256 optionId, uint256 ethAmount, uint256 validityPeriod) external onlyOwner {
        require(optionId > 0, "Invalid option ID");
        membershipOptions[optionId] = MembershipOption(ethAmount, validityPeriod);
        if (optionId > numberOfOptions) {
            numberOfOptions = optionId;
        }
    }

    // Function to manually add time to an option for a given wallet
    function addTimeToMembership(address userAddress, uint256 optionId, uint256 additionalTime) external onlyOwner {
        require(membershipOptions[optionId].validityPeriod > 0, "Option does not exist");

        uint256 currentExpiration = userExpirations[userAddress][optionId];
        if (currentExpiration == 0 || currentExpiration < block.timestamp) {
            userExpirations[userAddress][optionId] = block.timestamp + additionalTime;
        } else {
            userExpirations[userAddress][optionId] += additionalTime;
        }
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}