/**
 *Submitted for verification at Arbiscan on 2022-06-04
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*
 * 
 * User creates a campaign.
 * Users can pledge, transferring their token to a campaign.
 * After the campaign ends, campaign creator can claim the funds if total amount pledged is more than the campaign goal.
 * Otherwise, campaign did not reach it's goal, users can withdraw their pledge.
 */
contract CrowdFund {
    event Launch(uint id, address indexed creator, uint32 startDate, uint32 endDate, uint goal);
    event Pledge(uint indexed id, address indexed funder, uint amount);
    event Unpledge(uint indexed id, address indexed funder, uint amount);
    event Claim(uint id);
    event Refund(uint id, address indexed funder, uint amount);
    event Cancel(uint id);

    struct Campaign {
        address payable creator;
        uint goal;
        uint raised;
        uint32 startDate;
        uint32 endDate;
        bool claimed;
    }

    uint public numCampaign;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public pledgedAmount;


    function launch(uint _goal, uint32 _startDate, uint32 _endDate) external {
        require(_startDate >= block.timestamp, "start time < now");
        require(_startDate < _endDate, "start time < end time");
        require(_endDate - _startDate <= 90 days, "exceeds maximum funding period");

        numCampaign ++ ;
        campaigns[numCampaign] = Campaign({
            creator: payable(msg.sender),
            goal: _goal,
            raised: 0,
            startDate: _startDate,
            endDate: _endDate,
            claimed: false
        });

        emit Launch(numCampaign, msg.sender, _startDate, _endDate, _goal);
    }

    function cancel(uint _id) external {
        Campaign memory c = campaigns[_id];
        
        require(block.timestamp < c.startDate, "Funding already started");
        require(msg.sender == c.creator, "Not funding creator");

        delete campaigns[_id];

        emit Cancel(_id);
    }

    function pledge(uint _id) payable external {
        Campaign storage c = campaigns[_id];

        require(block.timestamp >= c.startDate, "Funding not started");
        require(block.timestamp <= c.endDate, "Funding ended");

        c.raised += msg.value;
        pledgedAmount[_id][msg.sender] += msg.value;

        emit Pledge(_id, msg.sender, msg.value);
    }

    function unpledge(uint _id, uint _amount) payable external {
        Campaign storage c = campaigns[_id];

        require(block.timestamp < c.endDate, "Funding ended");
        require(pledgedAmount[_id][msg.sender] >= _amount, "Not enough balance");

        pledgedAmount[_id][msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
        c.raised -= _amount;

        emit Unpledge(_id, msg.sender, _amount);
    }

    function claim(uint _id) external {
        Campaign storage c = campaigns[_id];

        require(block.timestamp >= c.endDate, "Funding not ended");
        require(c.claimed == false, "Already claimed");
        require(msg.sender == c.creator, "Not creator");
        require(c.goal <= c.raised, "Not enough fund raised");

        payable(msg.sender).transfer(c.raised);
        c.claimed = true;

        emit Claim(_id);
    }

    function refund(uint _id) external {
        Campaign storage c = campaigns[_id];

        require(block.timestamp >= c.endDate, "Funding not ended");
        require(c.raised < c.goal, "Fund succeed, can't refund");

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        payable(msg.sender).transfer(bal);

        emit Refund(_id, msg.sender, bal);
    }

    function getTime() view external returns (uint) {
        return block.timestamp;
    }

}