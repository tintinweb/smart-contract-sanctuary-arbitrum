/**
 *Submitted for verification at Arbiscan on 2022-12-08
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract multisig {
    //owner1 is the deployer
    address public owner1;
    address public owner2 = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    address public owner3 = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    uint public conformations;
    address payable private currentAddressToWithdraw;
    uint private currentAmountToWithdraw;

    //event to check fallback function call
    event fallbackcalled(uint indexed _sender, uint _amount);

    //mappings
    mapping(address => bool) public hasConfirmedCurrentWithdrawal;

    constructor() public payable {
        owner1 = msg.sender;
    }

    //function modifier for onlyOwners
    modifier onlyOwner() {
        require(
            msg.sender == owner1 ||
                msg.sender == owner2 ||
                msg.sender == owner3,
            "Not the owner"
        );
        _;
    }

    function Deposit() public payable {}

    // fallback() external payable {
    //     emit fallbackcalled(msg.sender, msg.value);
    // }

    receive() external payable {}

    function initiateWithdraw(address payable _to, uint _value)
        public
        onlyOwner
    {
        require(_value <= address(this).balance, "Insufficient Balance");
        conformations += 1;
        hasConfirmedCurrentWithdrawal[msg.sender] = true;
        currentAddressToWithdraw = _to;
        currentAmountToWithdraw = _value;
    }

    function confirmWithdraw() public onlyOwner {
        require(conformations == 1, "Invalid Transaction or already confirmed");
        conformations = 0;
        currentAddressToWithdraw = payable(address(0));
        delete hasConfirmedCurrentWithdrawal[owner1];
        delete hasConfirmedCurrentWithdrawal[owner3];
        delete hasConfirmedCurrentWithdrawal[owner3];
        currentAddressToWithdraw.transfer(currentAmountToWithdraw);
    }

    function withdrawalPending(uint _conformations) public pure returns (bool) {
        if (_conformations == 1) {
            return true;
        } else {
            return false;
        }
    }

    function ownerConfirmed(uint _index) public view returns (bool) {
        require(_index <= 3, "Invalid Index");
        if (_index == 1) {
            return hasConfirmedCurrentWithdrawal[owner1];
        } else if (_index == 2) {
            return hasConfirmedCurrentWithdrawal[owner2];
        } else {
            return hasConfirmedCurrentWithdrawal[owner3];
        }
    }

    function getBalanceContract() public view returns (uint) {
        return address(this).balance;
    }
}

contract depositor {
    function deposit(address payable _to, uint _value) public payable returns (bool) {
        require(_value < address(msg.sender).balance,"Insufficient Balance");
        (bool success, bytes memory value) = _to.call{value: msg.value}(abi.encodeWithSignature("Deposit()"));
        require(success, "Error in transfer");
        return success;
    }

    function deposit_fallbaack(address payable _to, uint _value) public payable {
        require(_value < address(msg.sender).balance,"Insufficient Balance");
        (bool success, ) = _to.call{value: msg.value}(abi.encodeWithSignature("HelloWorldFunction()"));
    } 
}