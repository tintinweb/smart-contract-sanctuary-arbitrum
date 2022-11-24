// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

interface IUXDRouter {

    error RouterNotController(address caller);
    error DepositoryExists(address asset, address depository);
    error DepositoryDoesNotExist(address asset, address depository);

    event DepositoryRegistered(
        address indexed asset, 
        address indexed depository, 
        address indexed caller
    );
    event DepositoryUnregistered(
        address indexed asset, 
        address indexed depository, 
        address indexed caller
    );
    
    function registerDepository(address asset, address depository) external; 
    function unregisterDepository(address asset, address depository) external;
    function getDepositoryForAsset(address asset) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IUXDRouter} from "./IUXDRouter.sol";

/// @title UXDRouter
/// @notice Routes request to mint and redeem to specific depositories. 
/// @dev Manages lists of registered depositories per asset.
contract UXDRouter is Ownable, IUXDRouter {

    /// @dev asset => list of depositories for this asset
    mapping(address => address[]) public depositoriesForAsset;

    /// @notice Register a new depository for given asset
    /// @dev Will revert if this depository has already been registered for this asset.
    /// @param asset Asset to register depository for.
    /// @param depository The depository address
    function registerDepository(address asset, address depository) external onlyOwner {
        if (_isDepositoryRegistered(asset, depository)) {
            revert DepositoryExists(asset, depository);
        }
        depositoriesForAsset[asset].push(depository);
        
        emit DepositoryRegistered(asset, depository, msg.sender);
    }

    /// @notice Unregister a depository for a given asset
    /// @dev depository must have been previously registerd for this asset.
    /// @param asset Asset to unregister depository for.
    /// @param depository The depository address
    function unregisterDepository(address asset, address depository) external onlyOwner {
        if (_isDepositoryRegistered(asset, depository)) {
            revert DepositoryDoesNotExist(asset, depository);
        }
        address[] storage depositories = depositoriesForAsset[asset];
        for (uint256 i = 0; i < depositories.length; i++) {
            if (depositories[i] == depository) {
                depositories[i] = depositories[depositories.length - 1];
                depositories.pop();
                emit DepositoryUnregistered(asset, depository, msg.sender);
                break;
            }
        }
    }

    /// @notice Return a depository address for an asset.
    function getDepositoryForAsset(address asset) external view returns (address) {
        return _firstDepositoryForAsset(asset);
    }

    /// @dev returns the first depository for an asset
    function _firstDepositoryForAsset(address asset) private view returns (address) {
        address[] storage depositories = depositoriesForAsset[asset];
        if (depositories.length == 0) {
            return address(0);
        }
        return depositories[0];
    }

    /// @dev returns true if a given depository is already registered for a given asset
    function _isDepositoryRegistered(address asset, address depository) private view returns (bool) {
        address[] storage depositories = depositoriesForAsset[asset];
        for (uint256 i = 0; i < depositories.length; i++) {
            if (depositories[i] == depository) {
                return true;
            }
        }
        return false;
    }
}