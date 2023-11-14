// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "../TrustedContractManager.sol";

contract TrustedPluginManager is TrustedContractManager {
    constructor(address _owner) TrustedContractManager(_owner) {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "./ITrustedContractManager.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TrustedContractManager
 * @dev Implementation of the ITrustedContractManager interface
 * Manages and checks the trusted contracts in the system
 */
abstract contract TrustedContractManager is ITrustedContractManager, Ownable {
    /// @notice Mapping to keep track of trusted contracts
    mapping(address => bool) private _trustedContract;

    /**
     * @dev Sets the initial owner of the contract to `_owner`
     * @param _owner Address of the initial owner
     */
    constructor(address _owner) Ownable(_owner) {}

    /**
     * @notice Checks if the given address is a trusted contract
     * @param module Address of the module to be checked
     * @return True if the address is a trusted contract, false otherwise
     */
    function isTrustedContract(address module) external view returns (bool) {
        return _trustedContract[module];
    }
    /**
     * @dev Internal function to check if the given address is a contract
     * @param addr Address to be checked
     * @return isContract True if the address has code (is a contract), false otherwise
     */

    function _isContract(address addr) private view returns (bool isContract) {
        assembly {
            isContract := gt(extcodesize(addr), 0)
        }
    }
    /**
     * @notice Adds one or more contracts to the list of trusted contracts
     * Can only be called by the owner
     * @param modules Addresses of the contracts to be added
     */

    function add(address[] memory modules) external onlyOwner {
        for (uint256 i = 0; i < modules.length; i++) {
            require(_isContract(modules[i]), "TrustedContractManager: not a contract");
            require(!_trustedContract[modules[i]], "TrustedContractManager: contract already trusted");
            _trustedContract[modules[i]] = true;
            emit TrustedContractAdded(modules[i]);
        }
    }
    /**
     * @notice Removes one or more contracts from the list of trusted contracts
     * Can only be called by the owner
     * @param modules Addresses of the contracts to be removed
     */

    function remove(address[] memory modules) external onlyOwner {
        for (uint256 i = 0; i < modules.length; i++) {
            require(_trustedContract[modules[i]], "TrustedContractManager: contract not trusted");
            _trustedContract[modules[i]] = false;
            emit TrustedContractRemoved(modules[i]);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

/**
 * @title ITrustedContractManager Interface
 * @dev This interface defines methods and events for managing trusted contracts
 */
interface ITrustedContractManager {
    /**
     * @dev Emitted when a new trusted contract (module) is added
     * @param module Address of the trusted contract added
     */
    event TrustedContractAdded(address indexed module);
    /**
     * @dev Emitted when a trusted contract (module) is removed
     * @param module Address of the trusted contract removed
     */
    event TrustedContractRemoved(address indexed module);
    /**
     * @notice Checks if the specified address is a trusted contract
     * @param addr Address to check
     * @return Returns true if the address is a trusted contract, false otherwise
     */

    function isTrustedContract(address addr) external view returns (bool);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

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
}