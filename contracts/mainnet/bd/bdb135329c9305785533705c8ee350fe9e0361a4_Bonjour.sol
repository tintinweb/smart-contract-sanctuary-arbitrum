/**
 *Submitted for verification at Arbiscan on 2022-08-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

contract Bonjour {

    mapping (string => uint) public greeting_count;

    //stored on the blockchain
    string public greetings_fr = "Bonjour!";
    string public greetings_it = "Bonjourno!";
    uint public count;
    //constant
    address public constant MY_ADDRESS = 0x095bDA636Ea6AbdBAaFb6E550227DB35cFc59790;
    address public owner;
    uint public immutable some_number;

    constructor(uint number){
        some_number = number;
        owner = msg.sender;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Only Owner!");
        _;
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner validAddress(_newOwner) {
        owner = _newOwner;
    }

    function getGreeting() public view returns (string memory){
        return greetings_fr;
    }


    function upOnly() public {
        count += 1;
    }

    function getSum(uint number1, uint number2) public pure returns(uint) {
        return number1 + number2;
  }
}