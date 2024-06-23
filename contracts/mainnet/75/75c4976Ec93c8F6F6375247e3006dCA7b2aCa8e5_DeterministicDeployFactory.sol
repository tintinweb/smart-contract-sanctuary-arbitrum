/**
 *Submitted for verification at Arbiscan.io on 2024-06-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract DeterministicDeployFactory {
    event Deploy(address addr);

    function deploy(bytes memory bytecode, uint256 _salt) external payable {
        address addr;
        assembly {
            addr := create2(callvalue(), add(bytecode, 0x20), mload(bytecode), _salt)
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }

        emit Deploy(addr);
    }
}