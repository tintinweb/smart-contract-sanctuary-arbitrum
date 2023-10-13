/**
 *Submitted for verification at Arbiscan.io on 2023-10-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract AgeInfoStorage {

    struct Info {
        string name;
        uint age;
    }
    
    Info[] public infos;

    function setAgeInfo(string memory _name, uint _age) public {
        infos.push(Info(_name, _age));
    }
    
    function getAgeInfo(uint _index) public view returns (string memory, uint) {
        Info storage info = infos[_index];
        return (info.name, info.age);
    }
}