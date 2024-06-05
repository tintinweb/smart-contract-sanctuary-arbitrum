// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Ownable2Step } from "openzeppelin/access/Ownable2Step.sol";
import { ERC165 } from "openzeppelin/utils/introspection/ERC165.sol";

import { IMultiTokenCategoryRegistry } from "multitoken/interfaces/IMultiTokenCategoryRegistry.sol";

/**
 * @title MultiToken Category Registry
 * @notice Contract to register known MultiToken Categories for assets.
 * @dev Categories are stored as incremented by one to distinguish between 0 category value and category not registered.
 */
contract MultiTokenCategoryRegistry is Ownable2Step, ERC165, IMultiTokenCategoryRegistry {

    /**
    * @notice A reserved value for a category not registered.
    */
    uint8 public constant CATEGORY_NOT_REGISTERED = type(uint8).max;

    /**
     * @notice Mapping of assets address to its known category.
     * @dev Categories are incremented by one before being stored to distinguish between 0 category value and category not registered.
     */
    mapping (address => uint8) private _registeredCategory;

    /**
    * @notice Thrown when a reserved category value is used to register a category.
    */
    error ReservedCategoryValue();

    /**
     * @inheritdoc IMultiTokenCategoryRegistry
     */
    function registerCategoryValue(address assetAddress, uint8 category) external onlyOwner {
        if (category == CATEGORY_NOT_REGISTERED)
            revert ReservedCategoryValue(); // Note: to unregister a category, use `unregisterCategory` method.

        _registeredCategory[assetAddress] = category + 1;

        emit CategoryRegistered(assetAddress, category);
    }

    /**
     * @inheritdoc IMultiTokenCategoryRegistry
     */
    function unregisterCategoryValue(address assetAddress) external onlyOwner {
        delete _registeredCategory[assetAddress];

        emit CategoryUnregistered(assetAddress);
    }

    /**
     * @inheritdoc IMultiTokenCategoryRegistry
     */
    function registeredCategoryValue(address assetAddress) external view returns (uint8) {
        uint8 category = _registeredCategory[assetAddress];
        return category == 0 ? CATEGORY_NOT_REGISTERED : category - 1;
    }

    /**
     * @notice Check if the contract supports an interface.
     * @param interfaceId The interface identifier, as specified in ERC-165.
     * @return `true` if the contract supports `interfaceId`, `false` otherwise.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return
            interfaceId == type(IMultiTokenCategoryRegistry).interfaceId ||
            super.supportsInterface(interfaceId);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
* @title MultiToken Category Registry Interface
* @notice Interface for the MultiToken Category Registry.
* @dev Category Registry Interface ID is 0xc37a4a01.
*/
interface IMultiTokenCategoryRegistry {

    /**
    * @notice Emitted when a category is registered for an asset address.
    * @param assetAddress Address of an asset to which category is registered.
    * @param category A raw value of a MultiToken Category registered for an asset.
    */
    event CategoryRegistered(address indexed assetAddress, uint8 indexed category);

    /**
    * @notice Emitted when a category is unregistered for an asset address.
    * @param assetAddress Address of an asset to which category is unregistered.
    */
    event CategoryUnregistered(address indexed assetAddress);

    /**
     * @notice Register a MultiToken Category value to an asset address.
     * @param assetAddress Address of an asset to which category is registered.
     * @param category A raw value of a MultiToken Category to register for an asset.
     */
    function registerCategoryValue(address assetAddress, uint8 category) external;

    /**
     * @notice Clear the stored category for the asset address.
     * @param assetAddress Address of an asset to which category is unregistered.
     */
    function unregisterCategoryValue(address assetAddress) external;

    /**
     * @notice Getter for a registered category value of a given asset address.
     * @param assetAddress Address of an asset to which category is requested.
     * @return Raw category value registered for the asset address.
     */
    function registeredCategoryValue(address assetAddress) external view returns (uint8);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.0;

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