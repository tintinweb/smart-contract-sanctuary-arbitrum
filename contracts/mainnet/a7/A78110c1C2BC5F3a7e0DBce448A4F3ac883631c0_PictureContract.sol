// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.19;

contract PictureContract {
    string public ipfsHash;
    
    function setHash(string memory _ipfsHash) public {
        ipfsHash = _ipfsHash;
    }
    
    function getHash() public view returns (string memory) {
        return ipfsHash;
    }
}