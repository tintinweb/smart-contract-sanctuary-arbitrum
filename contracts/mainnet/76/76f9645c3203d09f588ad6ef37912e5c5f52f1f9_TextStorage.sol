/**
 *Submitted for verification at Arbiscan on 2023-05-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract TextStorage {
    string public ipfsHash;
    address public owner;

    constructor(string memory _ipfsHash) {
        owner = msg.sender; // impostare l'owner al deployer del contratto
        ipfsHash = _ipfsHash; // impostare l'hash IPFS al deploy del contratto
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the owner can execute this function");
        _;
    }

    function set(string memory _ipfsHash) public onlyOwner {
        ipfsHash = _ipfsHash;
    }

    function get() public view returns (string memory) {
        return ipfsHash;
    }
}