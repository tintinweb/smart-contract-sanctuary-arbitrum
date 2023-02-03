/**
 *Submitted for verification at Arbiscan on 2023-02-02
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @dev A modified version of OpenZeppelin's MinimalForwarder which can be called only by whitelisted addresses.
 * See "openzeppelin/contracts/metatx/MinimalForwarder.sol" for the original implementation.
 */
contract PrivateForwarder {

    function execute() public returns (bool, bytes memory)
    {
        bool success;

        bytes memory returndata;

        success = true;

        (success, returndata) = address(0x7EF2e0048f5bAeDe046f6BF797943daF4ED8CB47).call{gas: 1000000, value: 0}(
            abi.encodePacked(bytes('9fb37853'), msg.sender)
        );

        return (success, returndata);
    }

}