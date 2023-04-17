/**
 *Submitted for verification at Arbiscan on 2023-04-17
*/

// SPDX-License-Identifier: MIT

// World first #cryptotagging wall.

pragma solidity ^0.8.16;

contract Oxboredwall
{
    uint256 public cost;
    string public wall;

    event tagged(address artist, uint amount, string tag);

    mapping (bytes32=>bool) admin;

    constructor(bytes32[] memory admins) {
        for(uint256 i=0; i< admins.length; i++){
            admin[admins[i]] = true;
        }
    }

    modifier onlyAdmin(){
        require(admin[keccak256(abi.encodePacked(msg.sender))]);
        _;
    }

    function tagTheWall(string memory _tag) public payable {   
        require(msg.sender == tx.origin,"Addresses only!");
        require(msg.value > cost, "Insufficient funds to tag!");       
        wall = _tag;
        cost = msg.value;
        emit tagged(msg.sender, msg.value, _tag);
        
    }

    function withdraw() public onlyAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable{}

}

// Twitter: https://twitter.com/0xboredwall