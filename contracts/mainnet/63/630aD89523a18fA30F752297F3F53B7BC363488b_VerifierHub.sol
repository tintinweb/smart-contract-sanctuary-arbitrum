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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title VerifierHub
 * @dev Contract to manage ZK verifiers.
 */
contract VerifierHub is Ownable {
    mapping(bytes32 nameHash => address verifier) private _verifiers;
    string[] private _verifierNames;

    event VerifierSet(string verifierName, address addr);

    constructor(address _initialOwner) Ownable(_initialOwner) {}

    function setVerifier(
        string memory verifierName,
        address addr
    ) external onlyOwner {
        _setVerifier(verifierName, addr);
        emit VerifierSet(verifierName, addr);
    }

    /**
     * @notice Register multiple verifiers.
     * @param verifierNames Array of verifier names.
     * @param addrs Array of verifier addresses.
     */
    function setVerifierBatch(
        string[] memory verifierNames,
        address[] memory addrs
    ) external onlyOwner {
        require(
            verifierNames.length == addrs.length,
            "VerifierHub: arrays are not equal length"
        );
        for (uint16 i = 0; i < verifierNames.length; i++) {
            _setVerifier(verifierNames[i], addrs[i]);
        }
    }

    function getVerifierNames() external view returns (string[] memory) {
        return _verifierNames;
    }

    function getVerifier(
        string memory verifierName
    ) external view returns (address) {
        return _verifiers[keccak256(bytes(verifierName))];
    }

    function _setVerifier(string memory verifierName, address addr) internal {
        if (!_exists(verifierName)) {
            _verifierNames.push(verifierName);
        }
        _verifiers[keccak256(bytes(verifierName))] = addr;
    }

    function _exists(string memory verifierName) internal view returns (bool) {
        for (uint16 i = 0; i < _verifierNames.length; i++) {
            string memory _verifierName = _verifierNames[i];
            if (_equal(_verifierName, verifierName)) {
                return true;
            }
        }

        return false;
    }

    function _equal(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return
            bytes(a).length == bytes(b).length &&
            keccak256(bytes(a)) == keccak256(bytes(b));
    }
}