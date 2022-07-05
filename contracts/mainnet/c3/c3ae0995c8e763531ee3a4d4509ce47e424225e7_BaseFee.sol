// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use
pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;

contract BaseFee {

    function getBaseFee() public view returns(uint256) {
        return block.basefee;
    }

}