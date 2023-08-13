/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract RoobeeMulticall {

    event CallCompleted(
        address sender,
        uint256 value
    );

    function makeCalls(address[] calldata addresses, bytes[] calldata datas, uint256[] calldata values) external payable {
        // Arrays Length Mismatch
        require(datas.length == values.length, "ALM");
        // Datas Length Mismatch
        require(datas.length == addresses.length, "DLM");

        for(uint256 i = 0; i < datas.length; i++) {
            (bool success,) = addresses[i].call{ value: values[i]}(datas[i]);
            // Call Failed
            require(success, "CF");
        }

        emit CallCompleted(msg.sender, msg.value);
    }
}