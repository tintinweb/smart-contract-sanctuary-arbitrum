/**
 *Submitted for verification at Arbiscan on 2023-01-02
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

error Unauthorized();
error DonationIsBelowMinimum();

contract FundMe {
    mapping(address => uint256) public addressToAmount;
    address[] public donors;
    address immutable i_owner;
    uint256 constant MIN_DONATION_ETH = 0.01 ether;


    constructor() {
        i_owner = msg.sender;
    }

    receive() external payable {
        addDonation();
    }

    function donate() public payable {
        addDonation();
    }

    function addDonation() private {
        if (msg.value >= MIN_DONATION_ETH)
        {
            if (addressToAmount[msg.sender] == 0)
                donors.push(msg.sender);
            addressToAmount[msg.sender] += msg.value;
        }
        else if ((MIN_DONATION_ETH < msg.value) && (addressToAmount[msg.sender] != 0)) 
            addressToAmount[msg.sender] += msg.value;
        else
            revert DonationIsBelowMinimum();
    }

    function withdraw() public onlyOwner {
        address payable recipient = payable(i_owner);
        recipient.transfer(address(this).balance);        
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner)
            revert Unauthorized();
            _;
    }
}