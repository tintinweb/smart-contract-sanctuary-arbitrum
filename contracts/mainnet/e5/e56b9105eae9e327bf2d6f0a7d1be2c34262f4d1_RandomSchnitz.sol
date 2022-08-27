/**
 *Submitted for verification at Arbiscan on 2022-08-27
*/

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

struct TokenMetadata {
	address token;
	string name;
}

contract RandomSchnitz {
    string[] public a;
    string public b;
    TokenMetadata public c;
    
    function test(string[] memory _a) public {
        a = _a;
    }
    
    function test2(string memory _a) public {
        b = _a;
    }
    
    function PutInSomething(TokenMetadata memory _a) public {
        c = _a;
    }
}