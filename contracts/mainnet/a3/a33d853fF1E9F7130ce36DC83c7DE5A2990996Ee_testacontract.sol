/**
 *Submitted for verification at Arbiscan on 2022-10-13
*/

pragma solidity ^0.8.0;


struct aSomething {
    somethingInaSomething ThisIsA;
    somethingInaSomething2 ThisIsB;
}

struct somethingInaSomething {
    uint256 a;
    uint256 b;
    uint256 c;
}

struct somethingInaSomething2 {
    address[] d;
    uint256[] e;
    uint256 f;
}

contract testacontract {
    function gimmeSupply(aSomething calldata a) public view returns (uint256) {
        return 1;
    }
}