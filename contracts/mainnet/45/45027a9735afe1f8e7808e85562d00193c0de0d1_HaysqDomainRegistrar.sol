/**
 *Submitted for verification at Arbiscan.io on 2024-04-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;

contract HaysqDomainRegistrar {
    struct DomainOwner {
        address owner;
        uint256 registeredAt;
        bool exists;
    }

    mapping(string => DomainOwner) public domainOwners;

    uint256 public nstRegistrationFee = 0.0005 ether; // ÖZELLEŞTİR: Kayıt ücreti
    uint256 public nstRenewalFee = 0.0004 ether; // ÖZELLEŞTİR: Yenileme ücreti

    uint256 public registrationPeriod = 31500000; // ÖZELLEŞTİR: Kayıt süresi (saniye cinsinden)
    uint256 public renewalPeriod = 31500000; // ÖZELLEŞTİR: Yenileme süresi (saniye cinsinden)

    address public deployer = 0x9d93D24c1a9e3506DBf588D238A4549Ce796aa79;

    constructor() {
        deployer = 0x9d93D24c1a9e3506DBf588D238A4549Ce796aa79;
    }

    function registerDomain(string memory _domainName) public payable {
        require(msg.value >= nstRegistrationFee, "Insufficient ETH");
        require(bytes(_domainName).length > 0, "Domain name cannot be empty");
        require(!domainOwners[_domainName].exists, "Domain name already registered");
        require(keccak256(abi.encodePacked(_domainName)) != keccak256(abi.encodePacked("")), "Invalid domain name");
        require(keccak256(abi.encodePacked(_domainName)) != keccak256(abi.encodePacked(".")), "Domain name can only have .nst extension");

        domainOwners[_domainName] = DomainOwner(msg.sender, block.timestamp, true);
    }

    function getDomainOwner(string memory _domainName) public view returns (address) {
        require(domainOwners[_domainName].exists, "Domain name not found");
        return domainOwners[_domainName].owner;
    }

    function getDomainRegistrationDate(string memory _domainName) public view returns (uint256) {
        require(domainOwners[_domainName].exists, "Domain name not found");
        return domainOwners[_domainName].registeredAt;
    }

    function getDomainExpirationDate(string memory _domainName) public view returns (uint256) {
        require(domainOwners[_domainName].exists, "Domain name not found");
        return domainOwners[_domainName].registeredAt + registrationPeriod;
    }

    function renewDomain(string memory _domainName) public payable {
        require(msg.value >= nstRenewalFee, "Insufficient ETH");
        require(domainOwners[_domainName].exists, "Domain name not found");
        require(domainOwners[_domainName].owner == msg.sender, "Domain name does not belong to you");
        require(block.timestamp <= domainOwners[_domainName].registeredAt + registrationPeriod, "Domain name has expired");

        domainOwners[_domainName].registeredAt = block.timestamp;
    }

    function getRegistrationFee() public view returns (uint256) {
        return nstRegistrationFee;
    }

    function getRenewalFee() public view returns (uint256) {
        return nstRenewalFee;
    }

    function getRegistrationPeriod() public view returns (uint256) {
        return registrationPeriod;
    }

    function getRenewalPeriod() public view returns (uint256) {
        return renewalPeriod;
    }

    function getDeployerAddress() public view returns (address) {
        return deployer;
    }
}