/**
 *Submitted for verification at Arbiscan.io on 2023-08-30
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;



contract FundManagere {

    mapping(address => bool) public whitelist;
    event Log(address indexed);

    receive() external payable {}

    function addToWhitelist(address _address) public {
        whitelist[_address] = true;
    }

    function removeFromWhitelist(address _address) public {
        whitelist[_address] = false;
    }

    function emitEvent() public {
        emit Log(msg.sender);
    }
}