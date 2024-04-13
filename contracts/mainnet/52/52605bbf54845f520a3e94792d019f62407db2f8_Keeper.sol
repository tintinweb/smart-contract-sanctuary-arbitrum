/**
 *Submitted for verification at Arbiscan.io on 2024-04-12
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.18;

interface IStrategy {
    function report() external returns (uint256, uint256);

    function tend() external;
}

interface IVault {
    function process_report(address) external returns (uint256, uint256);
}

/**
 * @title Keeper
 * @notice
 *   To allow permissionless reporting on V3 vaults and strategies.
 *
 *   This will do low level calls so that in can be used without reverting
 *   it the roles have not been set or the functions are not available.
 */
contract Keeper {
    /**
     * @notice Reports on a strategy.
     */
    function report(address _strategy) external returns (uint256, uint256) {
        return IStrategy(_strategy).report();
    }

    /**
     * @notice Tends a strategy.
     */
    function tend(address _strategy) external {
        return IStrategy(_strategy).tend();
    }

    /**
     * @notice Report strategy profits on a vault.
     */
    function process_report(
        address _vault,
        address _strategy
    ) external returns (uint256, uint256) {
        return IVault(_vault).process_report(_strategy);
    }
}