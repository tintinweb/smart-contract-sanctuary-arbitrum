// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.9;

contract QuickFundAlpha {
    
    // default address to which fees are sent
    address payable defaultFeesAddress = payable(0xc69848d26622b782363C4C9066c9787a270E9232);

    // address of the contract owner
    address public owner;

    // constructor to set the contract owner to the address that deploys the contract
    constructor() {
        owner = msg.sender;
    }

    bool internal locked;

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }
    

    // modifier to allow only the contract owner to execute a function
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    uint256 public numberOfCampaigns = 0;

    // A struct that holds all inital campaign details
    struct CampaignDetails {
        string title; // title of campaign
        string description;  // description of campaign
        uint256 target;  // target of campaign in native currency
        uint256 deadline; // deadline of campaign
        string category; // category of the campaign
        string [] image; // urls of campagin images
        string [] video; // urls of campaign videos
        string [] milestones; // milestones of the campaign
        uint8 campaign_type; // campaign type, 0 = secured, 1 = direct
        uint8 campaign_state; // campaign state, active = 0, inactive = 1;
    }

    // A struct that holds all campaign states 
    struct CampaignState {
        address owner; // address of the owner of the campaign
        uint256 amountCollected; // total amount of native currency collected
        uint256 supportersCount; // amount of donators that voted yes to allow withdrawal  
        uint256 opposersCount; // amount of donators that voted no to allow withdrawal 
        address[] donators; // array to store the addresses of donators
        string [] donatorsNotes; // array to store the notes of each donater
        mapping(address => bool) donations; // a mapping to hold addy's of donatores // returns true if user has donated
        mapping(address => uint256) donationAmounts; // a mapping to hold how much a user has donated
        mapping(address => uint256) refundAmounts; // a mapping to hold how much a user has donated
        mapping(address => bool) voted; // a mapping to hold the donator voter status
        string[] updates; // an array of updates for the campaign
        bool goalMet; // boolean ot indicate if the campaign goal has been met
        bool voteSuccessful; // boolean to indicate if a vote to allow campaign funds withdrawal is successful
        bool refundable; // boolean to indicate if a campaign donations can be refunded or not. // NOTE: maybe this is not needed ?
        bool voteOpen; // boolean to indicate if a campaign has opened voting or not
        bool fundsWithdrawn; // boolean to indicate if the campaign fund have already been Withdrawn
        uint256 amountWithdrawn;
    }


    mapping(uint256 => CampaignDetails) public campaignDetails;
    mapping(uint256 => CampaignState) public campaignState;


    //modifer to only allow campaignOwner to interact with their campaign
    modifier onlyCampaignOwner(uint256 campaignId) {
        require(msg.sender == campaignState[campaignId].owner, "Only the campaign owner can call this function.");
        _;
    }


     //NOTE: THIS WORKS
    // function to create a new campaign
    function createCampaign(
    address _owner,
    string memory _title, 
    string memory _description, 
    uint256 _target, 
    uint256 _deadline, 
    string memory _category, 
    string [] memory _image, 
    string [] memory _video,
    string [] memory _milestones,
    uint8 _campaign_type
    ) public returns (uint256) {

        CampaignDetails storage _campaignDetails = campaignDetails[numberOfCampaigns];
        CampaignState storage _campaignState = campaignState[numberOfCampaigns];

        if(_deadline < block.timestamp) {
            revert("deadline should be in the future");
        } 

        _campaignState.owner = _owner;
        _campaignDetails.title = _title;
        _campaignDetails.description = _description;
        _campaignDetails.target = _target;
        _campaignDetails.deadline = _deadline;
        _campaignState.amountCollected = 0;
        _campaignDetails.category = _category;
        _campaignDetails.image = _image;
        _campaignDetails.video = _video;
        _campaignDetails.milestones = _milestones;
        _campaignDetails.campaign_type = _campaign_type;
        _campaignState.updates.push("");
        _campaignState.goalMet = false;
        _campaignState.voteOpen = false;
        _campaignState.voteSuccessful = false;
        if (_campaign_type == 0 ) { 
            _campaignDetails.campaign_type = 0;
            _campaignState.refundable = true;
        } else if (_campaign_type == 1 ) {
            _campaignDetails.campaign_type = 1;
            _campaignState.refundable = false;
        } else {
            revert("Campaign type can only be 0 (Secured) or 1 (Direct)");
        }
        _campaignState.fundsWithdrawn = false;
        _campaignState.amountWithdrawn = 0;
        _campaignDetails.campaign_state = 0; // Make Campaign active when it first launches

        numberOfCampaigns++;

        return numberOfCampaigns - 1;

    }

    // a function to update the campaign that can only be called, by the campaign owner
    function updateCampaign(
        uint256 pid,
        string memory _title,
        string memory _description,
        string memory _category,
        string [] memory _image,
        string [] memory _video,
        string [] memory _milestones
    ) public onlyCampaignOwner(pid) {
        CampaignDetails storage _campaignDetails = campaignDetails[pid];
        if (_campaignDetails.deadline < block.timestamp) {
            revert("you can not update a campaign after the deadline");
        }
        _campaignDetails.title = _title;
        _campaignDetails.description = _description;
        _campaignDetails.category = _category;
        _campaignDetails.image = _image;
        _campaignDetails.video = _video;
        _campaignDetails.milestones = _milestones;
    }


    // function to allow donaters to the campaign to vote to allow funds withdrawl if the campaign goal is not met
    // only allows voting once for each donater, and only allows 7 days after the campaign deadline to vote.
    function vote(uint256 campaignId, bool supportWithdrawal) public {
        CampaignState storage _campaignState = campaignState[campaignId];
        CampaignDetails storage _campaignDetails = campaignDetails[campaignId];

        if (_campaignDetails.deadline + 604800 < block.timestamp) {
            revert("You can only vote, during the grace period");
        }
        
        if(_campaignState.donationAmounts[msg.sender] < 10000000000000000) {
            revert("you need to donate at least 0.01 in order to vote");
        }

        if(_campaignState.voted[msg.sender]) {
            revert("Each donator to the campaign can only vote once, and you can only vote if you have donated at least 0.01 coins");
        }

        require(_campaignState.voteOpen, "There is no open vote for this campaign.");
        require(_campaignState.donations[msg.sender], "You have not donated to this campaign, so you are not allowed to vote.");
        _campaignState.voted[msg.sender] = true;

        if(supportWithdrawal) {
            _campaignState.supportersCount++;
        } else {
            _campaignState.opposersCount++;
        }
            
    }


    // a function to withdraw funds of a secured campaign
    // can only be called by the campaign owner, will only work with secured campaigns
    // requires that the campaign goal is met, or voters has voted to allow campaign funds to be withdrawn
    function withdrawFunds(uint256 campaignId) onlyCampaignOwner(campaignId) noReentrant() public  {
        
        CampaignState storage _campaignState = campaignState[campaignId];
        CampaignDetails storage _campaignDetails = campaignDetails[campaignId];

        if (_campaignDetails.campaign_type != 0) {
            revert("only secured campaigns are able to request to withdrawFunds, all other campaign types get their funds sent directly");
        }

        if (_campaignState.goalMet == true) { 

            // subtract the 1% fee from the total funds
            // transfer the funds to the campaign owner's address
            address payable addy = payable(_campaignState.owner);
            uint256 transferAmount = (_campaignState.amountCollected * 99 / 100)  - _campaignState.amountWithdrawn;
            addy.transfer(transferAmount);
            _campaignState.amountWithdrawn += (_campaignState.amountCollected * 99 / 100);
            
        } else if (_campaignState.goalMet == false) {
            if (_campaignDetails.deadline + 604800 > block.timestamp) {
                revert("You can withdraw funds, after the voting grace period ends");
            }

            if(_campaignState.supportersCount > _campaignState.opposersCount) {
        
                address payable addy = payable(_campaignState.owner);
                uint256 transferAmount = (_campaignState.amountCollected * 99 / 100)  - _campaignState.amountWithdrawn;
                addy.transfer(transferAmount);
                _campaignState.amountWithdrawn += (_campaignState.amountCollected * 99 / 100);
                _campaignState.voteSuccessful = true;

            } else if (_campaignState.opposersCount > _campaignState.supportersCount) {
                revert("your vote has not passed, more people voted agaisnt releasing your funds");    
            } else if (_campaignState.opposersCount == _campaignState.supportersCount){
                revert("your vote has not passed, you need at least more than 50% voting in your favor");
            }
        }
            _campaignState.fundsWithdrawn = true;
    }



    // this function allows users to donate to campaigns, if the campaign is secured then the funds are transferred to the smart contract
    // if the campaign type is direct then the funds are sent direcrly to the campaign owner
    // in all cases 1% fees are sent to the smart contract
    function donate(uint256 campaignId, string memory note) public noReentrant() payable {
        CampaignDetails storage _campaignDetails = campaignDetails[campaignId];
        CampaignState storage _campaignState = campaignState[campaignId];

        uint256 amount = msg.value;
        uint256 fees = amount / 100;

        _campaignState.amountCollected = _campaignState.amountCollected + msg.value;


        // check if campaign goal has been met
        if (_campaignState.amountCollected >= _campaignDetails.target) {
            _campaignState.goalMet = true;
        }

        // add donor to the list of donors
        if(_campaignDetails.campaign_type == 0) {
            // Send the funds to the smart contract
            (bool feesSent,) = payable(defaultFeesAddress).call{value: fees}("");
            require(feesSent, "Error transferring fees.");

        } else if (_campaignDetails.campaign_type == 1) {

            // check fees were sent to campaign
            (bool feesSent,) = payable(defaultFeesAddress).call{value: fees}("");
            require(feesSent, "Error transferring fees.");

            (bool sentOther,) = payable(_campaignState.owner).call{value: amount - fees}("");
            require(sentOther, "Error transferring funds to campaign owner.");

        } else {
            revert("campaign type is invalid");
        }

            _campaignState.donators.push(msg.sender);
            _campaignState.donations[msg.sender] = true;
            _campaignState.donationAmounts[msg.sender] += msg.value;
            _campaignState.donatorsNotes.push(note);
    }

    // NOTE: THIS WORKS
    // a function to send updates to a campaign // it works
    function pushUpdate(uint256 campaignId, string memory update) public onlyCampaignOwner(campaignId) {
        CampaignState storage _campaignState = campaignState[campaignId];
        _campaignState.updates.push(update);
    }


    // NOTE:THIS WORKS COMPLETLY 
    // a function to open a vote to allow funds withdrawal of a campaign
    // can only be called if a campaign target is not met, and can be called during the 7 days after the campaign deadline
    // can only be called by the campaign owner.
    function openVote(uint256 campaignId) public onlyCampaignOwner(campaignId) {
        
        CampaignDetails storage _campaignDetails = campaignDetails[campaignId];
        CampaignState storage _campaignState = campaignState[campaignId];

        if (_campaignDetails.deadline > block.timestamp) {
            revert("deadline for this campagin has not passed, you can only open a vote after a campaign deadline passes");
        }

        if (_campaignDetails.deadline + 604800 < block.timestamp) {
            revert("7 days have passed after the campaign deadline, you cannot open a vote after the grace period");
        }
        
        require(!_campaignState.voteOpen, "A vote is already open for this campaign.");
        require(_campaignDetails.campaign_type == 0 && !_campaignState.goalMet && _campaignState.refundable, "This campaign is not Secured or has met it's goal or is not refundable, so voting is not allowed.");
        _campaignState.voteOpen = true;

    }
    
    struct CampaignDetailsWithoutMapping {
        address owner;
        string title;
        string description;
        uint256 target;
        uint256 deadline;
        uint256 amountCollected;
        string category;
        string[] updates;
        string[] image;
        string[] video;
        string[] milestones;
        uint8 campaignType;
        bool voteOpened;
        bool voteSuccess;
        uint8 current_state;
        
    }

   
    // get a single campaign data
    function getCampaign(uint256 campaignId) public view returns(CampaignDetailsWithoutMapping memory) {
        CampaignDetailsWithoutMapping memory item;
        item.owner = campaignState[campaignId].owner;
        item.title = campaignDetails[campaignId].title;
        item.description = campaignDetails[campaignId].description;
        item.target = campaignDetails[campaignId].target;
        item.amountCollected = campaignState[campaignId].amountCollected;
        item.image = campaignDetails[campaignId].image;
        item.video = campaignDetails[campaignId].video;
        item.milestones = campaignDetails[campaignId].milestones;
        item.deadline = campaignDetails[campaignId].deadline;
        item.category = campaignDetails[campaignId].category;
        item.updates = campaignState[campaignId].updates;
        item.campaignType = campaignDetails[campaignId].campaign_type;
        item.voteOpened = campaignState[campaignId].voteOpen;
        item.voteSuccess = campaignState[campaignId].voteSuccessful;
        item.current_state = campaignDetails[campaignId].campaign_state;
        return item;
    }

    // function to take a campaign id and change it's state to inactive 
    // if the campaign deadline has passed by over 3 months
    // and no donations were made
    function deactivateCampaign(uint256 campaignId) public onlyOwner {
        // Get the campaign struct from the mapping
        CampaignDetails storage _campaignDetails = campaignDetails[campaignId];
        CampaignState storage _campaignState = campaignState[campaignId];       

        // Ensure that only the contract owner can remove the campaign
        require(msg.sender == owner, "Only the contract owner can remove the campaign.");

        // check if three months have passed since the campaign deadline
        require(block.timestamp >= _campaignDetails.deadline + 7776000, "three months have not passed since the campaign deadline");

        // check if the campaign has reached its goal
        require(_campaignState.amountCollected == 0, "the campaign has reached its goal");

        // make campaign inactive
        _campaignDetails.campaign_state = 1; 
    }
    

    event cleanPerformed(string note, uint timestamp, address sender);

    uint256 public lastIndex;

    // NOTE: function to clean up the campaigns that are not active
    function cleanUp() public {

        if (lastIndex == numberOfCampaigns) {
            revert("no need to clean up, all campaigns have been already checked");
        }

        uint256 currentTimestamp = block.timestamp;
        uint256 deactivationCounter = 0;
        uint256 i = lastIndex;
        int numbersIncreased = 0;
        // Set a threshold of 500 campaigns read 
        int threshold = 500;
        // Set a limit of 50 deactivations per call
        uint256 limit = 50;
        // Iterate through all campaigns in the mapping
        for (i; i < numberOfCampaigns; i++) {
            CampaignDetails storage _campaignDetails = campaignDetails[i];
            CampaignState storage _campaignState = campaignState[i];    
            ++numbersIncreased;
            // Check if three months have passed since the campaign deadline
            if (currentTimestamp >= _campaignDetails.deadline + 7776000) {
                // Check if the campaign has not recieved any donations, if campaign had donations then it should be kept on display for refunds
                if(_campaignState.amountCollected == 0) {
                    // Call the deactivate campaign function
                    deactivateCampaign(i);
                    deactivationCounter++;
                }
            }
            // if we reach the limit break, 
            if (deactivationCounter == limit || numbersIncreased == threshold) {
                lastIndex = i+1;
                break;
            }
        }
        emit cleanPerformed("clean up performed", block.timestamp, msg.sender);
    }
    

    // function to refund donators to the campaign if it fails and no vote passes
    function refund(uint256 campaignId) public noReentrant() {
      
      CampaignState storage _campaignState = campaignState[campaignId];
      CampaignDetails storage _campaignDetails = campaignDetails[campaignId];

      if (_campaignDetails.deadline + 604800 > block.timestamp) {
        revert("7 days have not passed after the campaign deadline, please try again after the deadline");
      }
     
      if (_campaignDetails.campaign_type != 0 ) {
        revert("only secured campaigns can be refunded");
      }

      if (!_campaignState.donations[msg.sender]) {
        revert("only donators can be refunded");
      }

      if(_campaignState.supportersCount > _campaignState.opposersCount) {
        _campaignState.voteSuccessful = true;
        revert("this campaign voted successfuly to allow withdrawl");
      } 

      uint256 refundAmount = (_campaignState.donationAmounts[msg.sender] * 99 / 100) - _campaignState.refundAmounts[msg.sender];
      payable(msg.sender).transfer(refundAmount); 
      _campaignState.refundAmounts[msg.sender] += _campaignState.donationAmounts[msg.sender] * 99 / 100;
  
    }

    struct Donator {
        address addy;
        uint256 donationAmount;
        string note;
    }
    
    // returns the donators of the campagin, removing duplicates
    function getDonators(uint256 campaignId) public view returns (Donator[] memory) {
        CampaignState storage _campaignState = campaignState[campaignId];
        Donator[] memory donators = new Donator[](_campaignState.donators.length);
        uint256 j = 0;
        for (uint256 i = 0; i < _campaignState.donators.length; i++) {
            bool isDuplicate = false;
            for (uint256 k = 0; k < j; k++) {
                if (donators[k].addy == _campaignState.donators[i]) {
                    isDuplicate = true;
                    break;
                }
            }
            if (!isDuplicate) {
                donators[j] = Donator(_campaignState.donators[i], _campaignState.donationAmounts[_campaignState.donators[i]], _campaignState.donatorsNotes[i]);
                j++;
            }
        }
        // create new donators array with the same size as unique donators
        Donator[] memory uniqueDonators = new Donator[](j);
        // copy unique donators to new array
        for (uint256 i = 0; i < j; i++) {
            uniqueDonators[i] = donators[i];
        }
        return uniqueDonators;
    }

    // returns the donators of the campagin
    function getAllDonators(uint256 campaignId) public view returns (address[] memory) {
        CampaignState storage _campaignState = campaignState[campaignId];
        return _campaignState.donators;
    }

    // sets the default fees address, can only be called by the contract owner
   function setDefaultFeesAddress(address payable _newAddress) public onlyOwner {
        require(_newAddress != address(0), "The new address cannot be the zero address.");
        defaultFeesAddress = _newAddress;
    }

    // getter for the default fees address
    function getDefaultFeesAddress() public view returns (address) {
        return defaultFeesAddress;
    }


}