/**
 *Submitted for verification at Arbiscan on 2022-11-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract KeyFinder {
    function getKey(address account, uint256 epoch)
        public
        view
        returns (uint256)
    {
        return uint256(uint160(account)) * (epoch**2);
    }
}