// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Ownablee {
    
    // address public owner;    

    address[] private ownerList;    

    mapping(address => bool) private isOwner;

    modifier onlyOwner() {
        require(isOwner[msg.sender], "caller is not the owner");
        _;
    }

    constructor() {
        // owner = msg.sender;
        ownerList.push(msg.sender);
        isOwner[msg.sender] = true;
    }
    
    // function transferOwnership(address _owner) external onlyOwner {
    //     require(_owner != address(0), "zero owner address");
        
    //     owner = _owner;
    //     ownerList.push(_owner);
    //     isOwner[_owner] = true;
    // }

    function addOwner(address[] memory _userList) external onlyOwner {
        require(_userList.length > 0, "addOwner: zero list");

        for(uint256 i = 0; i < _userList.length; i++) { 
            if(isOwner[_userList[i]]) continue;

            ownerList.push(_userList[i]);
            isOwner[_userList[i]] = true;
        }        
    }

    function removeOwner(address[] memory _userList) external onlyOwner {
        require(_userList.length > 0, "removeOwner: zero list");
        
        for(uint256 i = 0; i < _userList.length; i++) {
            if(!isOwner[_userList[i]]) continue;

            for(uint256 k = 0; k < ownerList.length; k++) { 
                if(_userList[i] == ownerList[k]) {
                    ownerList[k] = ownerList[ownerList.length - 1];
                    ownerList.pop();

                    isOwner[_userList[i]] = false;
                }
            }            
        }        
    }

    function isOwnerAddress(address _user) external view returns (bool) {
        return isOwner[_user];
    }

    function getOwnerList() external view returns (address[] memory) {
        return ownerList;
    }
}