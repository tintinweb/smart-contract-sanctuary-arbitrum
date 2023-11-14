/**
 *Submitted for verification at Arbiscan.io on 2023-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract onRampEvents {
    event OnRampSet(uint64 indexed destChainSelector, address onRamp);
    //dest 5009297550715157269
    //onRamp 0x261c05167db67B2b619f9d312e0753f3721ad6E8

    function emitOnRamp(uint64 destChainSelector, address onRamp) external {
        emit OnRampSet(destChainSelector, onRamp);
    }
}