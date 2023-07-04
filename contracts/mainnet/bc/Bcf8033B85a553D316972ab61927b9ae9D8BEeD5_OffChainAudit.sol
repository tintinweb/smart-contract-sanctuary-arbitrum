/**
 *Submitted for verification at Arbiscan on 2023-07-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IDatabase {
    function beingAudited(address previous) external;
}

contract OffChainAudit {
    constructor(address database) {
        IDatabase(database).beingAudited(0x0000000000000000000000000000000000000000);
    }
}