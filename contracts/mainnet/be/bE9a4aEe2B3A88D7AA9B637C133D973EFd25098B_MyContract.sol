// SPDX-License-Identifier: MIT

// Deployed with the Atlas IDE
// https://app.atlaszk.com

pragma solidity >=0.4.22 <0.9.0;

contract MyContract {
    bool public paused;

    function pauseContract() public {
        paused = true;
    }

    function resumeContract() public {
        paused = false;
    }

    function doSomething() public view returns(string memory) {
        require(!paused, "Contract is paused");
        // Function logic here
        return "Contract is running";
    }
}