/**
 *Submitted for verification at Arbiscan.io on 2023-09-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.12;

/**
 * @title Raymond
 * @dev Increment & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Raymond {

    uint256 number;

    /**
     * @dev Increment value in variable
     */
    function increment() public {
        number++;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256) {
        return number;
    }
}