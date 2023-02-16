/**
 *Submitted for verification at Arbiscan on 2023-02-15
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

/*

/$$$$$$                /$$                          /$$$$$$$$ /$$                                                  
/$$__  $$              |__/                         | $$_____/|__/                                                  
| $$  \__/ /$$  /$$  /$$ /$$  /$$$$$$$ /$$$$$$$      | $$       /$$ /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$$  /$$$$$$ 
|  $$$$$$ | $$ | $$ | $$| $$ /$$_____//$$_____/      | $$$$$   | $$| $$__  $$ |____  $$| $$__  $$ /$$_____/ /$$__  $$
\____  $$| $$ | $$ | $$| $$|  $$$$$$|  $$$$$$       | $$__/   | $$| $$  \ $$  /$$$$$$$| $$  \ $$| $$      | $$$$$$$$
/$$  \ $$| $$ | $$ | $$| $$ \____  $$\____  $$      | $$      | $$| $$  | $$ /$$__  $$| $$  | $$| $$      | $$_____/
|  $$$$$$/|  $$$$$/$$$$/| $$ /$$$$$$$//$$$$$$$/      | $$      | $$| $$  | $$|  $$$$$$$| $$  | $$|  $$$$$$$|  $$$$$$$
\______/  \_____/\___/ |__/|_______/|_______/       |__/      |__/|__/  |__/ \_______/|__/  |__/ \_______/ \_______/

*/

contract AddressTracker {
    address[] public addresses;
    address[] public owners;
    bool wlToggle = true;

    constructor() {
        owners.push(msg.sender);
    }

    function addAddress(address _address) public {
        require(isOwner(), "Only the owner can add addresses");
        addresses.push(_address);
    }

    function addAddresses(address[] memory _addresses) public {
        require(isOwner(), "Only the owner can add addresses");
        for (uint256 i = 0; i < _addresses.length; i++) {
            addresses.push(_addresses[i]);
        }
    }

    function isAddressSubmitted(address _address) public view returns (bool) {
        for (uint256 i = 0; i < addresses.length; i++) {
            if (addresses[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function addOwner(address _owner) public {
        require(isOwner(), "Only the owner can add owners");
        owners.push(_owner);
    }

    function toggle() public {
        require(isOwner(), "Only the owner can add owners");
        wlToggle = !wlToggle;
    }

    function isOwner() public view returns (bool) {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                return true;
            }
        }
        return false;
    }

    function checkToggle() public view returns (bool) {
        return wlToggle;
    }
}