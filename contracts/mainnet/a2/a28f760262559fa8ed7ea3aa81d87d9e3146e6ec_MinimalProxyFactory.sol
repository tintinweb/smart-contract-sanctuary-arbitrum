/**
 *Submitted for verification at Arbiscan on 2023-05-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

contract MinimalProxyFactory {
    function cloneWithTemplateAddress(address templateAddress)
        external
        returns (address createdAddress)
    {
        bytes20 _templateAddress = bytes20(templateAddress);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), _templateAddress)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            createdAddress := create(0, clone, 0x37)
        }
    }

}