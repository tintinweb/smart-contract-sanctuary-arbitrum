// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract MessageExecutor {
    function execute(address fns, bytes memory data) external payable returns (bytes memory) {
        (bool success, bytes memory result) = fns.delegatecall(data);
        if (!success) {
        	// Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
        return result;
    }
}