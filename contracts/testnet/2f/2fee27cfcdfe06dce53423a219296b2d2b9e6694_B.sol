/**
 *Submitted for verification at Arbiscan on 2022-09-27
*/

/**
 *Submitted for verification at Arbiscan on 2022-09-20
*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract B {
    uint256 public aNumber;
    string public aString;
    bool public aBool;
    address public anAddress;
    uint test;
    
    uint256[] public anArrayOfNumber;
    string[] public anArrayOfString;
    bool[] public anArrayOfBool;
    address[] public anArrayOfAddress;

    uint256 public someNumber;

    constructor() {

    }

    // basic data types
    function setaNumber(uint256 _a) public {
        aNumber = _a;
    }
    
    function setaString(string memory _a) public {
        aString = _a;
    }

    function setaBool(bool _a) public {
        aBool = _a;
    }

    function setanAddress(address _a) public {
        anAddress = _a;
    }
    // basic datatypes
    
    
    // array datatypes
    function setanArrayOfNumber(uint256[] memory _a) public {
        anArrayOfNumber = _a;
    }
    
    function setanArrayOfString(string[] memory _a) public {
        anArrayOfString = _a;
    }

    function setanArrayOfBool(bool[] memory _a) public {
        anArrayOfBool = _a;
    }

    function setanArrayOfAddress(address[] memory _a) public {
        anArrayOfAddress = _a;
    }

    
    function extraFunctionJustForTrippn(uint _a) public {
        aNumber = _a;
    }
}