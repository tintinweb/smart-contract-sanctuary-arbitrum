// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract TransactionBatcher {
    function batchSend(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas
    ) public payable {
        uint256 length = targets.length;
        for (uint256 i = 0; i < length; ) {
            (bool success, ) = targets[i].call{value: values[i]}(datas[i]);
            require(success, "Transaction failed");
            unchecked {
                ++i;
            }
        }
    }
}