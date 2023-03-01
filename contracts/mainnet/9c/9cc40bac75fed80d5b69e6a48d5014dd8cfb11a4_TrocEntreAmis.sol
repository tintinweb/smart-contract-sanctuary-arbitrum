/**
 *Submitted for verification at Arbiscan on 2023-02-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract TrocEntreAmis {
    // ContractOwner
    address private contractOwner = msg.sender;
    
    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Not permitted");
        _;
    }

    // Item
    struct Item {
        uint id;
        address owner;
        string name;
        string description;
        uint value;
        uint status;
    }
    
    Item[] items;
 
    function findItem(uint id) public view returns(Item memory) {
        if(id >= items.length)
            revert('Not found');

        return items[id];
    }

    function getAll() public view returns(Item[] memory) {
        return items;
    }
    
    function addItem(string memory name, string memory description, uint value) public returns(Item memory) {
        items.push(
           Item({owner: msg.sender, id: items.length, name: name, description: description, value: value, status: 1}));

        return items[uint(items.length-1)];
    }
    
    function updateItem(uint id, string memory name, string memory description, uint value) public returns(Item memory) {
        require((id < items.length) && (msg.sender == items[id].owner));

        items[uint(id)].id = id;
        items[uint(id)].name = name;
        items[uint(id)].description = description;
        items[uint(id)].value = value;

        return items[uint(id)];
    }

    function transferOwnership(address newOwner, uint id) 
    public returns(Item memory) {
        require((id < items.length) && (msg.sender == items[id].owner));

        items[uint(id)].owner = newOwner;
        items[uint(id)].status = 0;

        return items[uint(id)];
    }
}