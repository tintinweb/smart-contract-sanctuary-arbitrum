/**
 *Submitted for verification at Arbiscan on 2022-05-30
*/

pragma solidity 0.8.11;

contract CrowdFunding {
    uint public numCampaigns;

    struct Campaign {
        address payable admin;
        uint goal;
        uint balance;
    }

    mapping (uint => Campaign) campaigns;

    function createCampaign(uint goal) external returns(uint campaignId) {
        campaignId = numCampaigns++;
        Campaign storage c = campaigns[campaignId];
        c.admin = payable(msg.sender);
        c.goal = goal;
    }

    function bid(uint campaignId) external payable {
        Campaign storage c = campaigns[campaignId];
        c.balance += msg.value;
    }

    modifier withdrawEligible(address operator, uint campaignId) {
        Campaign storage c = campaigns[campaignId];
        require(operator == c.admin);
        require(c.balance >= c.goal);
        _;
    }

    function withdraw(uint campaignId) external withdrawEligible(msg.sender, campaignId) {
        Campaign storage c = campaigns[campaignId];

        uint transferAmount = c.balance;
        c.admin.transfer(transferAmount);
        c.balance = 0;
    }
}