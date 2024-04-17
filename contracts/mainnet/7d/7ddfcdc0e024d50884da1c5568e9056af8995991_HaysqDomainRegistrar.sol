/**
 *Submitted for verification at Arbiscan.io on 2024-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract HaysqDomainRegistrar {
    struct DomainOwner {
        address owner;
        uint256 registeredAt;
    }

    mapping(string => DomainOwner) public domainOwners;

    uint256 public constant nstRegistrationFee = 0 ether;
    uint256 public constant registrationPeriod = 31500000;

    function registerDomain(string memory _domainName) public payable {
        require(msg.value >= 0.00 ether, "Insufficient ETH");
        require(bytes(_domainName).length > 0, "Domain name cannot be empty");
        require(domainOwners[_domainName].owner == address(0), "Domain name already registered");
        require(keccak256(abi.encodePacked(_domainName)) != keccak256(abi.encodePacked("")), "Invalid domain name");
        require(keccak256(abi.encodePacked(_domainName)) != keccak256(abi.encodePacked(".")), "Domain name can only have .nst extension");

        domainOwners[_domainName] = DomainOwner(msg.sender, block.timestamp);
    }

    function getDomainOwner(string memory _domainName) public view returns (address) {
        return domainOwners[_domainName].owner;
    }

    function getDomainRegistrationDate(string memory _domainName) public view returns (uint256) {
        return domainOwners[_domainName].registeredAt;
    }

    function getDomainExpirationDate(string memory _domainName) public view returns (uint256) {
        uint256 registrationDate = domainOwners[_domainName].registeredAt;
        if (registrationDate == 0) {
            return 0; // Domain not registered
        }
        return registrationDate + registrationPeriod;
    }
}