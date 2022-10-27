/**
 *Submitted for verification at Arbiscan on 2022-10-27
*/

pragma solidity ^0.7.0;


contract storeastring {

	string public a;
	bytes32 public b;

	function storeSomething(string memory _a) public {
		a = _a;
	}

	function storeSomething(bytes32 _b) public {
		b = _b;
	}
}