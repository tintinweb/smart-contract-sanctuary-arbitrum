/**
 *Submitted for verification at Arbiscan on 2023-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract AddressUtils {
  
    function isContracts(address[] memory addrs) public view returns(bool[] memory){
        bool[] memory rets = new bool[](addrs.length);
        for(uint32 i = 0; i < addrs.length; i ++) {
            // check if token is actually a contract
            address addr = addrs[i];
            uint256 codeSize;
            assembly { codeSize := extcodesize(addr) } // contract code size
            rets[i] = codeSize > 0;
        }
        return rets;
    }
   
}