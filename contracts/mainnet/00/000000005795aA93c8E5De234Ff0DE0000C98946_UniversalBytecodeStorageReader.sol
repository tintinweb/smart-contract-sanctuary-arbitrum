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

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.22;

// Created By: Art Blocks Inc.

import {IUniversalBytecodeStorageReader} from "../interfaces/v0.8.x/IUniversalBytecodeStorageReader.sol";

import {IBytecodeStorageReader_Base} from "../interfaces/v0.8.x/IBytecodeStorageReader_Base.sol";

import "@openzeppelin-5.0/contracts/access/Ownable.sol";

/**
 * @title Art Blocks Universal Bytecode Storage Reader
 * @author Art Blocks Inc.
 * @notice This contract is used to read the bytecode of a contract deployed by Art Blocks' BytecodeStorage library.
 * It is designed to be owned and configurable by a Art Blocks secure multisig wallet, providing a single location
 * to read on-chain data stored by the Art Blocks BytecodeStorage libarary. This contract is intended to be updated
 * as new versions of the Art Blocks BytecodeStorage library are released, such that the Art Blocks community can
 * continue to read the bytecode of all existing and future Art Blocks contracts in a single location.
 * The exposed interface is simplified to only include the read string function.
 * Additional functionality, such as alternate read methods or determining a contract's version, deployer, and other
 * metadata, may be available on the active BytecodeStorageReader contract.
 */
contract UniversalBytecodeStorageReader is
    Ownable,
    IUniversalBytecodeStorageReader
{
    /**
     * @notice The active bytecode storage reader contract being used by this universal reader.
     * Updateable by the owner of this contract.
     * This contract is intended to be updated as new versions of the Art Blocks BytecodeStorage library are released.
     * @dev To prevent a single point of failure, contracts may point directly to BytecodeStorageReader contracts
     * instead of this universal reader.
     */
    IBytecodeStorageReader_Base public activeBytecodeStorageReaderContract;

    /**
     * @notice Construct a new UniversalBytecodeStorageReader contract, owned by input owner address.
     * @param owner_ The address that will be set as the owner of this contract.
     */
    constructor(address owner_) Ownable(owner_) {}

    /**
     * @notice Update the active bytecode storage reader contract being used by this universal reader.
     * @param newBytecodeStorageReaderContract The address of the new active bytecode storage reader contract.
     */
    function updateBytecodeStorageReaderContract(
        IBytecodeStorageReader_Base newBytecodeStorageReaderContract
    ) external onlyOwner {
        activeBytecodeStorageReaderContract = newBytecodeStorageReaderContract;
        emit ReaderUpdated({
            activeReader: address(newBytecodeStorageReaderContract)
        });
    }

    /**
     * @notice Read a string from a data contract deployed via BytecodeStorage.
     * @dev may also support reading additional stored data formats in the future.
     * @param address_ address of contract deployed via BytecodeStorage to be read
     * @return The string data stored at the specific address.
     */
    function readFromBytecode(
        address address_
    ) external view returns (string memory) {
        return
            activeBytecodeStorageReaderContract.readFromBytecode({
                address_: address_
            });
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
// Creatd By: Art Blocks Inc.

pragma solidity ^0.8.0;

/**
 * @title Art Blocks Script Storage Library - Minimal Interface for Reader Contracts
 * @notice This interface defines the minimal expected read function(s) for a Bytecode Storage Reader contract.
 */
interface IBytecodeStorageReader_Base {
    /**
     * @notice Read a string from a data contract deployed via BytecodeStorage.
     * @dev may also support reading additional stored data formats in the future.
     * @param address_ address of contract deployed via BytecodeStorage to be read
     * @return data The string data stored at the specific address.
     */
    function readFromBytecode(
        address address_
    ) external view returns (string memory data);
}

// SPDX-License-Identifier: LGPL-3.0-only
// Created By: Art Blocks Inc.

pragma solidity ^0.8.0;

import {IBytecodeStorageReader_Base} from "./IBytecodeStorageReader_Base.sol";

/**
 * @title This interface extends the IBytecodeStorageReader_Base interface with relevant events and functions used on the
 * universal bytecode storage reader contract.
 * @author Art Blocks Inc.
 */
interface IUniversalBytecodeStorageReader is IBytecodeStorageReader_Base {
    /**
     * @notice The active bytecode storage reader contract being used by this universal reader was updated.
     * @param activeReader The address of the new active bytecode storage reader contract.
     */
    event ReaderUpdated(address indexed activeReader);

    /**
     * @notice Update the active bytecode storage reader contract being used by this universal reader.
     * @dev emits a ReaderUpdated event when successful.
     * @param newBytecodeStorageReaderContract The address of the new active bytecode storage reader contract.
     */
    function updateBytecodeStorageReaderContract(
        IBytecodeStorageReader_Base newBytecodeStorageReaderContract
    ) external;
}