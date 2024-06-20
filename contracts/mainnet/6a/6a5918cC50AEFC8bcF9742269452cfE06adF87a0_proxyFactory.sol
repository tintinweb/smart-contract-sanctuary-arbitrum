/**
 *Submitted for verification at Arbiscan.io on 2024-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

contract proxyFactory {
    function createProxyWithNonce(
        address proxy,
        bytes memory initializer
    ) public {
        if (initializer.length > 0)
            // solhint-disable-next-line no-inline-assembly
            assembly {
                if eq(call(gas(), proxy, 0, add(initializer, 0x20), mload(initializer), 0, 0), 0) {
                    revert(0, 0)
                }
            }
    }
}