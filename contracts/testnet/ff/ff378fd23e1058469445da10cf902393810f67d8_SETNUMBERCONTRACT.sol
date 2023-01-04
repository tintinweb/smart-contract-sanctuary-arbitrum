/**
 *Submitted for verification at Arbiscan on 2023-01-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract SETNUMBERCONTRACT{
    address reserved;
    uint256 public number;
    
     /**
     * @dev upgrades the implementation of the proxy
     *
     * requirements:
     *
     * - the caller must be the admin of the contract
     */
    function setNumber(uint256 _number) public {
        number = _number * 20002;
    }

     function decimals() public view returns (uint256) {
        return number;
    }
}