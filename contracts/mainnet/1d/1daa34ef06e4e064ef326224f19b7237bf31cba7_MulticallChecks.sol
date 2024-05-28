// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.20;

/**
 * @title MulticallChecks
 * @author GoldLink
 *
 * @dev Checks multicall result and reverts if a failure occurs.
 */
library MulticallChecks {
    function checkMulticallResult(
        bool success,
        bytes memory result
    ) external pure {
        if (!success) {
            // Next 5 lines from https://ethereum.stackexchange.com/a/83577
            if (result.length < 68) revert();
            assembly {
                result := add(result, 0x04)
            }
            revert(abi.decode(result, (string)));
        }
    }
}