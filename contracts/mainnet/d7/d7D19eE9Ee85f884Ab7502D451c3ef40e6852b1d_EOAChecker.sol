// SPDX-License-Identifier: UNLICENSED
// @author github: @dcrypt
// @notice Check if addresses are Externally owned addresses(EAOs) or not.

pragma solidity ^0.8.9;

contract EOAChecker {
    constructor() {}

    /**
     @notice Checks if addresses provided in arguements are Externally owned addresses(EAOs) or not.
   
     @return boolean representation of if both from and to addresses are Externally owned addresses or not 
     @param _addr address  to check.
     */

    function isEAO(address _addr) public view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(_addr)
        }
        return size == 0;
    }
}