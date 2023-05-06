/**
 *Submitted for verification at Arbiscan on 2023-05-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract XenBatchSon {  
    address private immutable o;
	constructor(address sender) {
		 o = sender;   
	}
    function c(address t,bytes memory d) external {
        require(msg.sender == o, "i8"); 
        assembly {
            let succeeded := call(
                gas(),
                t,
                0,
                add(d, 0x20),
                mload(d),
                0,
                0
            )
        }
    }

}