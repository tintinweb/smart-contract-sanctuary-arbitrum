// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
pragma abicoder v2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AddressPagination} from "./AddressPagination.sol";

/// @title Locker List Contract
/// @author Radiant
/// @dev All function calls are currently implemented without side effects
contract LockerList is Ownable {
    using AddressPagination for address[];

    // Users list
    address[] internal userlist;
    mapping(address => uint256) internal indexOf;
    mapping(address => bool) internal inserted;

    /********************** Events ***********************/

    event LockerAdded(address indexed locker);
    event LockerRemoved(address indexed locker);

    /**
     * @dev Constructor
	 */
    constructor() Ownable() {}

    /********************** Lockers list ***********************/
    /**
     * @notice Return the number of users.
	 */
    function lockersCount() external view returns (uint256) {
        return userlist.length;
    }

    /**
     * @notice Return the list of users.
	 */
    function getUsers(uint256 page, uint256 limit) external view returns (address[] memory) {
        return userlist.paginate(page, limit);
    }

    /**
     * @notice Add a locker.
	 * @dev This can be called only by the owner. Owner should be MFD contract.
	 */
    function addToList(address user) external onlyOwner {
        if (inserted[user] == false) {
            inserted[user] = true;
            indexOf[user] = userlist.length;
            userlist.push(user);
        }

        emit LockerAdded(user);
    }

    /**
     * @notice Remove a locker.
	 * @dev This can be called only by the owner. Owner should be MFD contract.
	 */
    function removeFromList(address user) external onlyOwner {
        assert(inserted[user] == true);

        delete inserted[user];

        uint256 index = indexOf[user];
        uint256 lastIndex = userlist.length - 1;
        address lastUser = userlist[lastIndex];

        indexOf[lastUser] = index;
        delete indexOf[user];

        userlist[index] = lastUser;
        userlist.pop();

        emit LockerRemoved(user);
    }
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
pragma solidity 0.8.12;

/// @title Library for pagination of address array
/// @author Radiant Devs
/// @dev All function calls are currently implemented without side effects
library AddressPagination {
    /**
     * @notice Paginate address array.
	 * @param array source address array.
	 * @param page number
	 * @param limit per page
	 * @return result address array.
	 */
    function paginate(
        address[] memory array,
        uint256 page,
        uint256 limit
    ) internal pure returns (address[] memory result) {
        result = new address[](limit);
        for (uint256 i = 0; i < limit; i++) {
            if (page * limit + i >= array.length) {
                result[i] = address(0);
            } else {
                result[i] = array[page * limit + i];
            }
        }
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