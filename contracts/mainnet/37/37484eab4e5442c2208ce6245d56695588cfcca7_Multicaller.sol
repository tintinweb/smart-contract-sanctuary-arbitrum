/**
 *Submitted for verification at Arbiscan.io on 2024-05-03
*/

pragma solidity ^0.8.0;

contract Multicaller {
    function multicall(
        address[] calldata targets,
        bytes[] calldata data
    ) external returns (string memory) {
        require(targets.length == data.length, "Invalid input");
        for (uint256 i = 0; i < targets.length; i++) {
            (bool success, bytes memory result) = targets[i].call{value: 0}(data[i]);
            if (!success) {
                string memory errorMessage;
                if (result.length < 68) {
                    errorMessage = "Call failed without revert message";
                } else {
                    assembly {
                        // Slice the revert message from the error data
                        errorMessage := add(result, 68)
                    }
                }
                return errorMessage;
            }
        }
        return ""; // Empty string indicates success
    }
}