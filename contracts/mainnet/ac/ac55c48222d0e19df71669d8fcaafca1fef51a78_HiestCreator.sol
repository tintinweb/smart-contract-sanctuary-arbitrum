// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HiestCreator {

    error bytecodeisZero();

    error create2failed();

    function copyCreate( uint256 amount, bytes32 salt, address _contract  , bytes memory _init ) external {
        bytes memory bytecode;
        address addr;
        assembly {
            let size := extcodesize(_contract)
            bytecode := mload(0x40)
            mstore(bytecode, size)
            extcodecopy(_contract, add(bytecode, 0x20), 0, size)
        }
        if (bytecode.length == 0) {
            revert bytecodeisZero();
        }
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        if (addr == address(0)) {
            revert create2failed();
        }

        // Initialize
        addr.call( _init );
    }


}