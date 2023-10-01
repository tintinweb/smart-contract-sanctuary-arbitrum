/**
 *Submitted for verification at Arbiscan.io on 2023-09-30
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBEP20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract BulkSender {
    function bulkdSend(IBEP20 _token, address[] memory _receivers, uint256[] memory _amounts) external {
        uint256 length = _receivers.length;
        require(length == _amounts.length, "params not correct");
        for (uint256 i = 0; i < length; i++) {
            IBEP20(_token).transferFrom(msg.sender, _receivers[i], _amounts[i]);
        }
    }
}