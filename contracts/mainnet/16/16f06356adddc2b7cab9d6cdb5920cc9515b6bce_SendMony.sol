/**
 *Submitted for verification at Arbiscan on 2022-11-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract SendMony {

    address public wallletT;
    mapping (address => uint) public mapswall;
    uint256 constant S = 7 * 86400; // all future times are rounded by week
    uint256 constant ES = 4 * 365 * 86400; // 4 years
    uint256 constant RW = 10**18;

   

    constructor() {
        wallletT = msg.sender;
    }

    struct ManufWallet {

        uint256 ee2;
        uint256 r3;
    }

    

    function superdonate() public payable {
        mapswall[msg.sender] = msg.value;
    }

    function returneth() public {
        address payable _to = payable(wallletT);
        address _contract = address(this);
        _to.transfer(_contract.balance);
    }


    string public namey;
  

    uint256 public averageUnlockTimey;
    uint256 public epochy;
    uint256 public counter;
    function setName(string memory _name) external returns (uint256) {
        counter += 1;
        namey = _name;
        epochy -= 1;
        averageUnlockTimey = 121;
        return counter;
    }
}