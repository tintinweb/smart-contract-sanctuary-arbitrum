// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;

contract BatchUpgrade {

    address private _implementation;

    constructor(address newImplementation) {
        _implementation = newImplementation;
    }

    function batchUpgrade(address[] calldata accounts) external {
        for (uint256 i = 0; i < accounts.length;) {
            address account = accounts[i];
            (bool success,) = account.call(abi.encodeWithSignature("upgradeTo(address)", _implementation));
            require(success, "BatchUpgrade: upgrade failed");
            unchecked {
                ++i;
            }
        }
    }
}