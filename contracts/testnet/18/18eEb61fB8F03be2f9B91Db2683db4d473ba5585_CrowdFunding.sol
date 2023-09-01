// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract CrowdFunding {
    struct Campaign {
        bytes32 id;
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string image;
        address[] donators;
        uint256[] donations;
    }

    mapping(bytes32 => Campaign) public campaigns;
    bytes32[] public listCampaignsID;

    uint256 public numberOfCampaigns = 0;

    function generateUUID() public view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(block.timestamp, msg.sender, numberOfCampaigns)
            );
    }

    function createCampaign(
        address _owner,
        string memory _title,
        string memory _description,
        uint256 _target,
        uint256 _deadline,
        string memory _image
    ) public returns (uint256) {
        bytes32 id = generateUUID();
        Campaign storage campaign = campaigns[id];
        listCampaignsID.push(id);

        require(
            campaign.deadline < block.timestamp,
            "Deadline must be in the future"
        );

        campaign.owner = _owner;
        campaign.title = _title;
        campaign.description = _description;
        campaign.target = _target;
        campaign.deadline = _deadline;
        campaign.image = _image;
        campaign.amountCollected = 0;
        campaign.id = id;

        numberOfCampaigns++;

        return numberOfCampaigns - 1;
    }

    function donateToCampaign(bytes32 _id) public payable {
        Campaign storage campaign = campaigns[_id];

        require(msg.value > 0, "Donation must be greater than 0");

        campaign.donators.push(msg.sender);
        campaign.donations.push(msg.value);
        campaign.amountCollected += msg.value;
    }

    function getDonators(bytes32 _id)
        public
        view
        returns (address[] memory, uint256[] memory)
    {
        return (campaigns[_id].donators, campaigns[_id].donations);
    }

    function getCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory _campaigns = new Campaign[](listCampaignsID.length);

        for (uint256 i = 0; i < listCampaignsID.length; i++) {
            _campaigns[i] = campaigns[listCampaignsID[i]];
        }
        return _campaigns;
    }

    function getCampaign(bytes32 _id) public view returns (Campaign memory) {
        return campaigns[_id];
    }
}