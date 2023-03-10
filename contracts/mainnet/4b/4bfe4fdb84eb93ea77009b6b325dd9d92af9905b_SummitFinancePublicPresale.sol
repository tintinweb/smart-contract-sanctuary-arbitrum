/**
 *Submitted for verification at Arbiscan on 2023-03-10
*/

//SPDX-License-Identifier: MIT


// Welcome in the first AutoStaking token of the Arbitrum history

// Auto stacker on #arbitrum, hold $SMF and earn up to 69,420% APY.
// The most simple and secure Auto-staking & Auto-compounding protocol.

// A new era on Arbitrum is coming, be ready...

// Come join our rapidly growing community and take the time to read the documents provided as you welcome to Summit Finance's stealth presale. 
// Remember that in order to navigate a red market like today, it's important to hold onto a gem. This may be the perfect day for you.


// Tw: https://twitter.com/Summit_Fi
// Tg: https://t.me/SummitFinance


//           /\
//          /**\
//         /****\   /\
//        /      \ /**\
//       /  /\    /    \        /\    /\  /\      /\            /\/\/\  /\
//      /  /  \  /      \      /  \/\/  \/  \  /\/  \/\  /\  /\/ / /  \/  \
//     /  /    \/ /\     \    /    \ \  /    \/ /   /  \/  \/  \  /    \   \
//    /  /      \/  \/\   \  /      \    /   /    \
// __/__/_______/___/__\___\__________________________________________________


pragma solidity ^0.8.0;

contract SummitFinancePublicPresale {
    uint256 addressesCount;

    uint256 presaleMinAllocation;
    uint256 presaleMaxAllocation;

    uint256 totalFund;
    address owner;

    address[] addressList;
    address withdrawalAddress;

    mapping(address => uint256) currentPayments;

    constructor(address _withdrawalAddress) {
        owner = msg.sender;

        withdrawalAddress = _withdrawalAddress;

        addressesCount = 0;

        presaleMinAllocation = 0.033 ether;
        presaleMaxAllocation = 0.1 ether;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function setPresaleMinAllocation(uint256 _presaleMinAllocation) external onlyOwner {
        presaleMinAllocation = _presaleMinAllocation;
    }

    function setPresaleMaxAllocation(uint256 _presaleMaxAllocation) external onlyOwner {
        presaleMaxAllocation = _presaleMaxAllocation;
    }

    function getPresaleMinAllocation() public view returns (uint256) {
        return presaleMinAllocation;
    }

    function getPresaleMaxAllocation() public view returns (uint256) {
        return presaleMaxAllocation;
    }

    function getAddressCurrentPayments(address _address) public view returns (uint256) {
        return currentPayments[_address];
    }

    function payPresale() public payable {
        require(msg.value + currentPayments[msg.sender] >= presaleMinAllocation, "Payment above minimum allocation");
        require(msg.value + currentPayments[msg.sender] <= presaleMaxAllocation, "Payment above maximum allocation");
        currentPayments[msg.sender] += msg.value;
        totalFund += msg.value;
        addressesCount++;
    }

    function withdraw() public onlyOwner {
        payable(withdrawalAddress).transfer(address(this).balance);
    }

    function getCurrentBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTotalFund() public view returns (uint256) {
        return totalFund;
    }

    function getAddressesCount() public view returns (uint256) {
        return addressesCount;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getWithdrawalAddress() public view returns (address) {
        return withdrawalAddress;
    }
}