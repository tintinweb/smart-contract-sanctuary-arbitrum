// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Extension} from "0xrails/extension/Extension.sol";
import {PayoutAddress} from "./PayoutAddress.sol";

contract PayoutAddressExtension is PayoutAddress, Extension {
    /*===============
        EXTENSION
    ===============*/

    /// @inheritdoc Extension
    function getAllSelectors() public pure override returns (bytes4[] memory selectors) {
        selectors = new bytes4[](3);
        selectors[0] = this.payoutAddress.selector;
        selectors[1] = this.updatePayoutAddress.selector;
        selectors[2] = this.removePayoutAddress.selector;

        return selectors;
    }

    /// @inheritdoc Extension
    function signatureOf(bytes4 selector) public pure override returns (string memory) {
        if (selector == this.payoutAddress.selector) {
            return "payoutAddress()";
        } else if (selector == this.updatePayoutAddress.selector) {
            return "updatePayoutAddress(address)";
        } else if (selector == this.removePayoutAddress.selector) {
            return "removePayoutAddress()";
        } else {
            return "";
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IExtension} from "./interface/IExtension.sol";

abstract contract Extension is IExtension {
    constructor() {
        getAllSignatures(); // verify selectors properly synced
    }

    /// @inheritdoc IExtension
    function signatureOf(bytes4 selector) public pure virtual returns (string memory signature) {}

    /// @inheritdoc IExtension
    function getAllSelectors() public pure virtual returns (bytes4[] memory selectors) {}

    /// @inheritdoc IExtension
    function getAllSignatures() public pure returns (string[] memory signatures) {
        bytes4[] memory selectors = getAllSelectors();
        uint256 len = selectors.length;
        signatures = new string[](len);
        for (uint256 i; i < len; i++) {
            bytes4 selector = selectors[i];
            string memory signature = signatureOf(selector);
            require(bytes4(keccak256(abi.encodePacked(signature))) == selector, "SELECTOR_SIGNATURE_MISMATCH");
            signatures[i] = signature;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Operations} from "0xrails/lib/Operations.sol";
import {IPermissions} from "0xrails/access/permissions/interface/IPermissions.sol";
import {IPayoutAddress} from "./IPayoutAddress.sol";
import {PayoutAddressStorage} from "./PayoutAddressStorage.sol";

/// @dev This contract provides utilities to manage collections' payout address
/// @notice It is not to be instantiated directly, but inherited by eg. PayoutAddressExtension
abstract contract PayoutAddress is IPayoutAddress {
    /*===========
        VIEWS
    ===========*/

    /// @inheritdoc IPayoutAddress
    function payoutAddress() public view virtual returns (address) {
        PayoutAddressStorage.Layout storage layout = PayoutAddressStorage.layout();
        return layout.payoutAddress;
    }

    /*=============
        SETTERS
    =============*/

    /// @inheritdoc IPayoutAddress
    function updatePayoutAddress(address newPayoutAddress) external virtual {
        _checkCanUpdatePayoutAddress();
        if (newPayoutAddress == address(0)) revert PayoutAddressIsZero();
        _updatePayoutAddress(newPayoutAddress);
    }

    /// @inheritdoc IPayoutAddress
    function removePayoutAddress() external virtual {
        _checkCanUpdatePayoutAddress();
        _updatePayoutAddress(address(0));
    }

    function _updatePayoutAddress(address newPayoutAddress) internal {
        PayoutAddressStorage.Layout storage layout = PayoutAddressStorage.layout();
        emit PayoutAddressUpdated(layout.payoutAddress, newPayoutAddress);
        layout.payoutAddress = newPayoutAddress;
    }

    /*====================
        AUTHORIZATION
    ====================*/

    /// @notice This function is meant to be invoked in the context of `delegatecall`
    function _checkCanUpdatePayoutAddress() internal virtual {
        IPermissions(address(this)).checkPermission(Operations.ADMIN, msg.sender);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IExtension {
    /// @dev Function to get the signature string for a specific function selector.
    /// @param selector The function selector to query.
    /// @return signature The signature string for the given function.
    function signatureOf(bytes4 selector) external pure returns (string memory signature);

    /// @dev Function to get an array of all recognized function selectors.
    /// @return selectors An array containing all 4-byte function selectors.
    function getAllSelectors() external pure returns (bytes4[] memory selectors);

    /// @dev Function to get an array of all recognized function signature strings.
    /// @return signatures An array containing all function signature strings.
    function getAllSignatures() external pure returns (string[] memory signatures);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Operations {
    bytes8 constant ADMIN = 0xfd45ddde6135ec42; // hashOperation("ADMIN");
    bytes8 constant MINT = 0x38381131ea27ecba; // hashOperation("MINT");
    bytes8 constant BURN = 0xf951edb3fd4a16a3; // hashOperation("BURN");
    bytes8 constant TRANSFER = 0x5cc15eb80ba37777; // hashOperation("TRANSFER");
    bytes8 constant METADATA = 0x0e5de49ee56c0bd3; // hashOperation("METADATA");
    bytes8 constant PERMISSIONS = 0x96bbcfa480f6f1a8; // hashOperation("PERMISSIONS");
    bytes8 constant GUARDS = 0x53cbed5bdabf52cc; // hashOperation("GUARDS");
    bytes8 constant VALIDATOR = 0xa95257aebefccffa; // hashOperation("VALIDATOR");
    bytes8 constant CALL = 0x706a455ca44ffc9f; // hashOperation("CALL");
    bytes8 constant INTERFACE = 0x4a9bf2931aa5eae4; // hashOperation("INTERFACE");
    bytes8 constant INITIALIZE_ACCOUNT = 0x18b11501aca1cd5e; // hashOperation("INITIALIZE_ACCOUNT");

    // TODO: deprecate and find another way versus anti-pattern
    // permits are enabling the permission, but only through set up modules/extension logic
    // e.g. someone can approve new members to mint, but cannot circumvent the module for taking payment
    bytes8 constant MINT_PERMIT = 0x0b6c53f325d325d3; // hashOperation("MINT_PERMIT");
    bytes8 constant BURN_PERMIT = 0x6801400fea7cd7c7; // hashOperation("BURN_PERMIT");
    bytes8 constant TRANSFER_PERMIT = 0xa994951607abf93b; // hashOperation("TRANSFER_PERMIT");
    bytes8 constant CALL_PERMIT = 0xc8d1733b0840734c; // hashOperation("CALL_PERMIT");
    bytes8 constant INITIALIZE_ACCOUNT_PERMIT = 0x449384b01ca84f74; // hashOperation("INITIALIZE_ACCOUNT_PERMIT");

    /// @dev Function to provide the signature string corresponding to an 8-byte operation
    /// @param name The signature string for an 8-byte operation. Empty for unrecognized operations.
    function nameOperation(bytes8 operation) public pure returns (string memory name) {
        if (operation == ADMIN) {
            return "ADMIN";
        } else if (operation == MINT) {
            return "MINT";
        } else if (operation == BURN) {
            return "BURN";
        } else if (operation == TRANSFER) {
            return "TRANSFER";
        } else if (operation == METADATA) {
            return "METADATA";
        } else if (operation == PERMISSIONS) {
            return "PERMISSIONS";
        } else if (operation == GUARDS) {
            return "GUARDS";
        } else if (operation == VALIDATOR) {
            return "VALIDATOR";
        } else if (operation == CALL) {
            return "CALL";
        } else if (operation == INTERFACE) {
            return "INTERFACE";
        } else if (operation == MINT_PERMIT) {
            return "MINT_PERMIT";
        } else if (operation == BURN_PERMIT) {
            return "BURN_PERMIT";
        } else if (operation == TRANSFER_PERMIT) {
            return "TRANSFER_PERMIT";
        } else if (operation == CALL_PERMIT) {
            return "CALL_PERMIT";
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PermissionsStorage} from "../PermissionsStorage.sol";

interface IPermissions {
    struct Permission {
        bytes8 operation;
        address account;
        uint40 updatedAt;
    }

    // events
    event PermissionAdded(bytes8 indexed operation, address indexed account);
    event PermissionRemoved(bytes8 indexed operation, address indexed account);

    // errors
    error PermissionAlreadyExists(bytes8 operation, address account);
    error PermissionDoesNotExist(bytes8 operation, address account);

    /// @dev Function to hash an operation's `name` and typecast it to 8-bytes
    function hashOperation(string memory name) external view returns (bytes8);

    /// @dev Function to check that an address retains the permission for an operation
    /// @param operation An 8-byte value derived by hashing the operation name and typecasting to bytes8
    /// @param account The address to query against storage for permission
    function hasPermission(bytes8 operation, address account) external view returns (bool);

    /// @dev Function to get an array of all existing Permission structs.
    function getAllPermissions() external view returns (Permission[] memory permissions);

    /// @dev Function to add permission for an address to carry out an operation
    /// @param operation The operation to permit
    /// @param account The account address to be granted permission for the operation
    function addPermission(bytes8 operation, address account) external;

    /// @dev Function to remove permission for an address to carry out an operation
    /// @param operation The operation to restrict
    /// @param account The account address whose permission to remove
    function removePermission(bytes8 operation, address account) external;

    /// @dev Function to provide reverts when checks for `hasPermission()` fails
    /// @param operation The operation to check
    /// @param account The account address whose permission to check
    function checkPermission(bytes8 operation, address account) external view;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IPayoutAddress {
    // events
    event PayoutAddressUpdated(address oldPayoutAddress, address newPayoutAddress);

    // errors
    error PayoutAddressIsZero();

    /// @dev Returns the address of the current `payoutAddress` in storage
    function payoutAddress() external view returns (address);

    /// @dev Updates the current payout address to the provided `payoutAddress`
    function updatePayoutAddress(address payoutAddress) external;

    /// @dev Removes the current payout address, replacing it with address(0x0)
    function removePayoutAddress() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library PayoutAddressStorage {
    // `keccak256(abi.encode(uint256(keccak256("groupos.PayoutAddress")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x6f6b6396a67f685820b27036440227e08d5018166d641c2de98d9ec56a7a9200;

    struct Layout {
        address payoutAddress;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library PermissionsStorage {
    // `keccak256(abi.encode(uint256(keccak256("0xrails.Permissions")) - 1)) & ~bytes32(uint256(0xff));`
    bytes32 internal constant SLOT = 0x9c5c344d590e19b509d94e6539bcccae12bdf46ca0b9e14840beae558bd13e00;

    struct Layout {
        uint256[] _permissionKeys;
        mapping(uint256 => PermissionData) _permissions;
    }

    struct PermissionData {
        uint24 index; //              [0..23]
        uint40 updatedAt; //          [24..63]
        bool exists; //              [64-71]
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = SLOT;
        assembly {
            l.slot := slot
        }
    }

    /* 
    .  Here is a rundown demonstrating the packing mechanic for `_packKey(adminOp, address(type(uint160).max))`:
    .  ```return (uint256(uint64(operation)) | uint256(uint160(account)) << 64);```     
    .  Left-pack account by typecasting to uint256: 
    .  ```addressToUint == 0x000000000000000000000000ffffffffffffffffffffffffffffffffffffffff```
    .  Shift left 64 bits, ie 8 bytes, which in hex is 16 digits: 
    .  ```leftShift64 == 0x00000000ffffffffffffffffffffffffffffffffffffffff0000000000000000```
    .  Left-pack operation by typecasting to uint256: 
    .  ```op == 0x000000000000000000000000000000000000000000000000df8b4c520ffe197c```
    .  Or packed operation against packed + shifted account: 
    .  ```_packedKey == 0x00000000ffffffffffffffffffffffffffffffffffffffffdf8b4c520ffe197c```
    */
    function _packKey(bytes8 operation, address account) internal pure returns (uint256) {
        // `operation` cast to uint64 to keep it on the small Endian side, packed with account to its left; leftmost 4 bytes remain empty
        return (uint256(uint64(operation)) | uint256(uint160(account)) << 64);
    }

    function _unpackKey(uint256 key) internal pure returns (bytes8 operation, address account) {
        operation = bytes8(uint64(key));
        account = address(uint160(key >> 64));
        return (operation, account);
    }

    function _hashOperation(string memory name) internal pure returns (bytes8) {
        return bytes8(keccak256(abi.encodePacked(name)));
    }
}