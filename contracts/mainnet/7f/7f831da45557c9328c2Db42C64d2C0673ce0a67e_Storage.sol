/**
 *Submitted for verification at Arbiscan on 2023-05-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

  function multisendEther(address[] memory _contributors, uint256 _amt) public payable {
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            payable (_contributors[i]).transfer(_amt);
        }
    }
}