// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IAuthority} from "./../utils/interfaces/IAuthority.sol";

import {Auth} from "./../utils/auth/Auth.sol";
import {Permission} from "./../utils/auth/Permission.sol";


contract Dictator is Ownable, IAuthority {
    event UpdateAccess(address target, bool enabled);
    event UpdatePermission(address target, bytes4 functionSig, bool enabled);

    constructor(address _owner) Ownable(_owner) {}

    function setAccess(Auth target, address user) public virtual onlyOwner {
        target.setAuth(user);

        emit UpdateAccess(user, true);
    }

    function removeAccess(Auth target, address user) public virtual onlyOwner {
        target.removeAuth(user);

        emit UpdateAccess(user, false);
    }

    function setPermission(Permission target, address user, bytes4 functionSig) public virtual onlyOwner {
        target.setPermission(user, functionSig);

        emit UpdatePermission(user, functionSig, true);
    }

    function removePermission(Permission target, address user, bytes4 functionSig) public virtual onlyOwner {
        target.removePermission(user, functionSig);

        emit UpdateAccess(user, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IAuthority {
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IAuthority} from "./../interfaces/IAuthority.sol";

abstract contract Auth {
    IAuthority public immutable authority;

    mapping(address => bool) public authMap;

    function canCall(address user) public view returns (bool) {
        return authMap[user];
    }

    constructor(IAuthority _authority) {
        authority = _authority;
    }

    modifier auth() {
        if (canCall(msg.sender)) {
            _;
        } else {
            revert Auth_Unauthorized();
        }
    }

    modifier checkAuthority() {
        if (msg.sender == address(authority)) {
            _;
        } else {
            revert Auth_Unauthorized();
        }
    }

    function setAuth(address user) external checkAuthority {
        authMap[user] = true;
    }

    function removeAuth(address user) external checkAuthority {
        delete authMap[user];
    }

    error Auth_Unauthorized();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IAuthority} from "./../interfaces/IAuthority.sol";

abstract contract Permission {
    IAuthority public immutable authority;

    mapping(address => mapping(bytes4 signatureHash => bool)) public permissionMap;

    function canCall(address user, bytes4 signatureHash) public view returns (bool) {
        return permissionMap[user][signatureHash];
    }

    constructor(IAuthority _authority) {
        authority = _authority;
    }

    modifier auth() {
        if (canCall(msg.sender, msg.sig)) {
            _;
        } else {
            revert Auth_Unauthorized();
        }
    }

    modifier checkAuthority() {
        if (msg.sender == address(authority)) {
            _;
        } else {
            revert Auth_Unauthorized();
        }
    }

    function setPermission(address user, bytes4 functionSig) external checkAuthority {
        permissionMap[user][functionSig] = true;
    }

    function removePermission(address user, bytes4 functionSig) external checkAuthority {
        delete permissionMap[user][functionSig];
    }

    error Auth_Unauthorized();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}