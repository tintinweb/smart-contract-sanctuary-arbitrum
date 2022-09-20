/**
 *Submitted for verification at Arbiscan on 2022-09-20
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

contract SingleCall {
    function call(address _target, bytes memory _data) external payable returns (bool success, bytes memory data) {
        require(_target != address(0), "INVALID_TARGET");
        (success, data) = _target.call{ value: msg.value }(_data);
        require(success, "CALL_ERROR");
    }
}