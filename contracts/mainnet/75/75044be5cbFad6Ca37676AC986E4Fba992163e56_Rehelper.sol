// SPDX-License-Identifier: Unlicensed

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.0;


interface arbhelper {
     function setBatch(uint256 newcount) external;
     function setIndex(uint256 newindex) external;
     function collectArb() external;

}


contract Rehelper {
    address helperaddr;
    uint256 counter;
    arbhelper ArbHelper;
    address immutable owner;
    
    constructor () {
owner = msg.sender;
helperaddr = 0x783329ba7A7f971D559CCd896403D58aDB07a677;
ArbHelper = arbhelper(helperaddr);
counter = 0;
}

modifier restricted() {
        require(
            msg.sender == owner,
            "Access restriction"
        );
        _;
    }

    function collect() external restricted {
        uint256 a = counter;
        uint256 b = counter + 1000;
        ArbHelper.setBatch(b);
        ArbHelper.setIndex(a);
        ArbHelper.collectArb();
        counter = b;
    }

    function reset() external restricted {
        counter = 0;
    }

}