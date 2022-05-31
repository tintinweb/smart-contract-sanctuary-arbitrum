/**
 *Submitted for verification at Arbiscan on 2022-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Crowdfund {
    struct Funder {
        address addr;
        uint amount;
    }

    struct Campaign {
        address payable rev;
        uint id;
        uint goal;
        uint amount;
        uint endDate;
        Funder[] funders;
    }

    uint public campaignCount;
    mapping(uint => Campaign) public campaigns;

    function Create (address payable rev, uint goal, uint fundtime) external {
        require(fundtime>=30, "fundtime can't equal zero.");

        ++campaignCount;
        Campaign storage c = campaigns[campaignCount];
        c.rev = rev;
        c.id = campaignCount;
        c.goal = goal;
        c.endDate = block.timestamp+fundtime;
    }

    function Fund(uint cid) external payable {
        Campaign storage c = campaigns[cid];
        c.funders.push(Funder({addr:msg.sender, amount:msg.value}));
        c.amount += msg.value;
    }

    function Withdraw(uint cid) external {
        Campaign storage c = campaigns[cid];
        require(c.endDate<block.timestamp, "crowdfund hasn't been completed.");
        require(c.amount>c.goal, "crowdfund can't arrive fund goal.");

        c.rev.transfer(c.amount);
    }

}