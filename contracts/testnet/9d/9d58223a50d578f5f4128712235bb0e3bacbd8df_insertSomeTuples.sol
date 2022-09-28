/**
 *Submitted for verification at Arbiscan on 2022-09-27
*/

pragma solidity ^0.8.0;

contract insertSomeTuples {

    struct LookAtMeIAmAStruct {
        uint256 _a;
        address _b;
        string _c;
    }

    address reserved;
    LookAtMeIAmAStruct public data;

    function insertSomething(LookAtMeIAmAStruct memory _i) public {
        data = _i;
    }

    function showSomething() public view returns (LookAtMeIAmAStruct memory) {
        return data;
    }
}