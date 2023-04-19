/**
 *Submitted for verification at Arbiscan on 2023-04-19
*/

// SPDX-License-Identifier: MIT

// This is the #cryptotagging wall. 

// Tagging the wall you overwrite the previous tag.

pragma solidity ^0.8.16;

contract boredwall
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
        require(msg.sender == tx.origin,"Confirm That You're Not A Robot");
        require(msg.value > cost, "greedisgood 999999999");       
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