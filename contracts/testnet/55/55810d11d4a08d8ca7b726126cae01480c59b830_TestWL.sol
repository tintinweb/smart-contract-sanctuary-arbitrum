/**
 *Submitted for verification at Arbiscan on 2022-08-31
*/

//SPDX-License-Identifier: MIT



pragma solidity ^0.8.0;



contract TestWL {

    uint whitelistCount;



    uint whitelistAllocation;



    uint totalFund;

    address owner;



    address [] addressList;

    address withdrawReceiver;



    mapping(address => bool) whitelistAddresses;

    mapping(address => uint256) currentPayments;



    constructor() {

        owner = msg.sender;

        whitelistCount = 0;

        withdrawReceiver = 0xb1c64Ba62a3372A8Ff13Ef3791ee248fa27da376;



        whitelistAllocation = 1500000000000000000;

    }



    modifier onlyOwner() {

        require(msg.sender == owner, "Ownable: caller is not the owner");

        _;

    }



    function setwhitelistAllocation(uint _whitelistAllocation) external onlyOwner{

        whitelistAllocation = _whitelistAllocation;

    }



    function getWhitelistAllocation() view public returns(uint) {

        return whitelistAllocation;

    }



    function getAddressCurrentPayments(address _address) view public returns(uint) {

        return currentPayments[_address];

    }



    function payWL() public payable {

        require(whitelistAddresses[msg.sender], "User is not whitelisted");

        require(msg.value + currentPayments[msg.sender] <= whitelistAllocation, "Payment above maximum allocation");

        currentPayments[msg.sender] += msg.value;

        totalFund += msg.value;

    }



    function addwhitelistAddress(address _address) external onlyOwner {

        if (whitelistAddresses[_address] != true) {

            whitelistAddresses[_address] = true;

            whitelistCount ++;

        }

    }



    function addMultipleAddresses(address[] memory addAddressList) external onlyOwner{

        for (uint i=0; i < addAddressList.length; i++) {

            if (whitelistAddresses[addAddressList[i]] != true) {

                whitelistAddresses[addAddressList[i]] = true;

                whitelistCount ++;

            }

        }

    }



    function removeWhitelistAddress(address _address) external onlyOwner {

        whitelistAddresses[_address] = false;

        whitelistCount --;

    }



    function withdraw() public onlyOwner{

        payable(withdrawReceiver).transfer(address(this).balance);

    }



    function emergency_withdraw() public onlyOwner{

        payable(owner).transfer(address(this).balance);

    }



    function IsWhitelisted(address _whitelistedAddress) public view returns(bool) {

        bool userIsWhitelisted = whitelistAddresses[_whitelistedAddress];

        return userIsWhitelisted;

    }



    function getCurrentBalance() view public returns(uint) {

        return address(this).balance;

    }



    function getTotalFund() view public returns(uint) {

        return totalFund;

    }



    function getWhitelistCount() view public returns(uint) {

        return whitelistCount;

    }



    function getOwner() view public returns(address) {

        return owner;

    }



}