/**
 *Submitted for verification at Arbiscan on 2023-02-02
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

contract RevertTest {

    bool public done;
    bool public internalDone;

    constructor() {}

    function alwaysRevert() public  {
        require(1 == 1, "REVERTED");
        done = true;

        internalRevert();
    }

    function internalRevert() internal {
        require(1 == 2, "REVERTED");
        internalDone = true;
    }

    fallback() external {
        alwaysRevert();
    }
}