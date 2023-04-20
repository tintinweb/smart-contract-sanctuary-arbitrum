/**
 *Submitted for verification at Arbiscan on 2023-04-20
*/

/// SPDX-License-Identifier: MIT
pragma solidity ~0.8.0;

contract BlockOracle {

    function blocknumber() public view returns(uint256){
        return block.number;
    }

}