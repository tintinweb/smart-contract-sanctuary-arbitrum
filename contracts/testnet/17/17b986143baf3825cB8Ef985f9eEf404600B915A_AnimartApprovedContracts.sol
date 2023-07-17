// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract AnimartApprovedContracts {
    address public owner;
    mapping(address => bool) private verifiedContracts;
    address[] public verifiedContractsList;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

    modifier onlyVerifiedAccounts(address _contractAddress) {
        require(verifiedContracts[_contractAddress], "This Collection is not verified!");
        _;
    }

    function addVerifiedContract( address _contractAddress) public onlyOwner {
        verifiedContracts[_contractAddress] = true;
        verifiedContractsList.push(_contractAddress);
    }

    function removeVerifiedContract (address _contractAddress) public onlyOwner {
        require(verifiedContracts[_contractAddress] == true, "Token is not verified.");
        verifiedContracts[_contractAddress] = false;

        for (uint256 i = 0; i < verifiedContractsList.length ; i++) {
            if (verifiedContractsList[i] == _contractAddress) {
                verifiedContractsList[i] = verifiedContractsList[verifiedContractsList.length - 1];
                verifiedContractsList.pop();
                break;
            }
        }
    }

    function getVerifiedContracts () public view returns (address[] memory) {
        return verifiedContractsList;
    }

}