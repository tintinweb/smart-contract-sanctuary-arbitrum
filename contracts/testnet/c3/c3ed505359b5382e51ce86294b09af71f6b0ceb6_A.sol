/**
 *Submitted for verification at Arbiscan on 2023-07-04
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.4;

contract A {
    mapping(address => string) private _msg;

    constructor() {
        
    }
    
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    function msgOf(address addr) public view returns (string memory) {
        return _msg[addr];
    }

    function setMsg(string calldata m) external callerIsUser {
        _msg[msg.sender]=m;
    }

    function getSelfMsg() public view returns (string memory) {
        return _msg[msg.sender];
    }
}