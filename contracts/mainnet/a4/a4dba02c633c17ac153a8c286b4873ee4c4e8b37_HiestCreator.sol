// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HiestCreator {

    error bytecodeisZero();

    error create2failed();
    event addressCreated( address _addr );

    function copyCreate( bytes32 salt,  bytes memory bytecode ) external {
        address addr;
        if (bytecode.length == 0) {
            revert bytecodeisZero();
        }
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        if (addr == address(0)) {
            revert create2failed();
        }
        emit addressCreated(addr);

        // Initialize
        //        addr.call( _init );
    }

    function fetchBN ( ) external view returns ( uint256 ){
        return block.number;
    }

}