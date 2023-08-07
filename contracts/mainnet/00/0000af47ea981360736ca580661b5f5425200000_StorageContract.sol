/**
 *Submitted for verification at Arbiscan on 2023-08-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract StorageContract {
    address public nativeCryptoReceiver;
    address[] public owners;

    constructor(address defaultNativeCryptoReceiver, address firstOwner) {
        nativeCryptoReceiver = defaultNativeCryptoReceiver;
        owners.push(firstOwner);
    }

    modifier onlyOwner() {
        bool isOwner = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (msg.sender == owners[i]) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "Caller is not an owner");
        _;
    }

    function addOwner(address newOwner) public onlyOwner {
        owners.push(newOwner);
    }

    function getOwners() public view returns (address[] memory) {
        return owners;
    }

    function changeNativeCryptoReceiver(address newNativeCryptoReceiver)
        public
        onlyOwner
    {
        nativeCryptoReceiver = newNativeCryptoReceiver;
    }
}