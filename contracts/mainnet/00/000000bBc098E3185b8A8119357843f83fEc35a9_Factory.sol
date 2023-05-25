// SPDX-License-Identifier: Mit
pragma solidity ^0.8.0;

contract Factory {
    bytes public args;

    function deploy(
        bytes32 _salt,
        bytes calldata _bytecode,
        bytes calldata _args
    ) external payable returns (address _contract) {
        args = _args;
        assembly {
            let zero := returndatasize()
            calldatacopy(zero, _bytecode.offset, _bytecode.length)
            _contract := create2(callvalue(), zero, _bytecode.length, _salt)
            if iszero(_contract) {
                invalid()
            }
        }
        delete args;
    }
}