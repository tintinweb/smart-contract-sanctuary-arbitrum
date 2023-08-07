/**
 *Submitted for verification at Arbiscan on 2023-08-07
*/

pragma solidity ^0.8.0;

contract setstringcontract123{
    string public a;
    
    function setString(string memory _a) public {
        a = _a;
    }

    function returnString() public view returns (string memory) {
        return a;
    }
}