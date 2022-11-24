/**
 *Submitted for verification at Arbiscan on 2022-11-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract DonationHub {

    address public truewal;
    mapping (address => uint) public mapswall;
    uint256 constant WEEKS = 7 * 86400; // all future times are rounded by week
    uint256 constant MAXTIMES = 4 * 365 * 86400; // 4 years
    uint256 constant MULTIPLIERW = 10**18;

   

    constructor() {
        truewal = msg.sender;
    }

    struct ManufWallet {

        uint256 ee2;
        uint256 r3;
    }

    

    function superdonate() public payable {
        mapswall[msg.sender] = msg.value;
    }

    function returneth() public {
        address payable _to = payable(truewal);
        address _contract = address(this);
        _to.transfer(_contract.balance);
    }


    string public name;
  

    uint256 public averageUnlockTime;
    uint256 public epoch;
    uint256 public counter;
    function setName(string memory _name) external returns (uint256) {
        counter += 1;
        name = _name;
        epoch -= 1;
        averageUnlockTime = 121;
        return counter;
    }
}