// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity ^0.8.0;

contract MyContract {
    bool public paused;

    constructor() {
        paused = false;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    function pause() public {
        paused = true;
    }

    function unpause() public {
        paused = false;
    }

    function doSomething() public whenNotPaused {
        // some code
    }
}