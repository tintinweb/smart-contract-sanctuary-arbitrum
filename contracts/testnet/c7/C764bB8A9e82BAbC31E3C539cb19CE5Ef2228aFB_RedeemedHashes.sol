// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14; 


/// @dev Thrown when comparisson has a zero value
/// @param nonZeroValue Type of the zero value
error CantBeZero(string nonZeroValue);

/// @dev When a low-level call fails
/// @param errorMsg Custom error message
error CallFailed(string errorMsg); 

/// @dev Thrown when the queried token is not in the database
/// @param token Address of queried token
error TokenNotInDatabase(address token);

/// @dev For when the queried token is in the database
/// @param token Address of queried token
error TokenAlreadyInDatabase(address token);

/// @dev Thrown when an user is not in the database
/// @param user Address of the queried user
error UserNotInDatabase(address user);

/// @dev Thrown when the call is done by a non-account/proxy
error NotAccount();

/// @dev Thrown when a custom condition is not fulfilled
/// @param errorMsg Custom error message
error ConditionNotMet(string errorMsg);

/// @dev Thrown when an unahoritzed user makes the call
/// @param unauthorizedUser Address of the msg.sender
error NotAuthorized(address unauthorizedUser);

/// @dev When reentrance occurs
error NoReentrance();

/// @dev When a particular action hasn't been enabled yet
error NotEnabled();

/// @dev Thrown when the account name is too long
error NameTooLong();

/// @dev Thrown when the queried Gelato task is invalid
/// @param taskId Gelato task
error InvalidTask(bytes32 taskId);

/// @dev Thrown if an attempt to add a L1 token is done after it's been disabled
/// @param l1Token L1 token address
error L1TokenDisabled(address l1Token);

/// @dev Thrown when a Gelato's task ID doesn't exist
error NoTaskId();

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;



interface IRedeemedHashes {

    /**
     * @dev Gets the L1 hashes, associated to a taskId, of the txs
     * that have been manually redeemed.
     * @param taskId_ Gelato's taskId associated to each account
     * @return bytes32[] Array of L1 tx hashes
     */
    function getRedeemsPerTask(bytes32 taskId_) external view returns(bytes32[] memory);

    /**
     * @dev Stores a completed manual redeemption on a retryable ticket
     * @param taskId_ Gelato's taskId associated to the account that initated the L1 transfer
     * @param hash_ L1 tx hash from the transfer (this is initiated by Gelato)
     */
    function storeRedemption(bytes32 taskId_, bytes32 hash_) external;

    /**
     * @dev Queries if a particular ticket's L1 tx hash was manually redeemed or not
     * @param taskId_ Gelato's taskId associated to the account where hash_ was initiated
     * @param hash_ L1 tx hash produced by Gelato when calling an account
     * @return bool If hash_ was manually redeemed or not
     */
    function wasRedeemed(bytes32 taskId_, bytes32 hash_) external view returns(bool);

    /**
     * @dev Gets all the manual redemptions done in the system for all accounts
     * @return bytes32[] Retryable ticket's L1 tx hashes that have been manually redeemed
     */
    function getTotalRedemptions() external view returns(bytes32[] memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.14;


import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/arbitrum/IRedeemedHashes.sol';
import '../Errors.sol';


/**
 * @notice Keeps a record -on L2- of L1 retryable tickets that have been
 * manually redeemed. 
 */
contract RedeemedHashes is IRedeemedHashes, Ownable {

    bytes32[] totalRedemptions;
    mapping(bytes32 => bytes32[]) taskIdToHashes; 

    /// @inheritdoc IRedeemedHashes
    function getRedeemsPerTask(bytes32 taskId_) external view returns(bytes32[] memory) {
        return taskIdToHashes[taskId_];
    }

    /// @inheritdoc IRedeemedHashes
    function storeRedemption(bytes32 taskId_, bytes32 hash_) external onlyOwner {
        totalRedemptions.push(hash_);
        taskIdToHashes[taskId_].push(hash_);
    }

    /// @inheritdoc IRedeemedHashes
    function wasRedeemed(bytes32 taskId_, bytes32 hash_) external view returns(bool) {
        bytes32[] memory hashes = taskIdToHashes[taskId_];
        if (hashes.length == 0) revert InvalidTask(taskId_);

        for (uint i=0; i < hashes.length;) {
            if (hashes[i] == hash_) return true;
            unchecked { ++i; }
        }
        return false;
    }

    /// @inheritdoc IRedeemedHashes
    function getTotalRedemptions() external view returns(bytes32[] memory) {
        return totalRedemptions;
    }
}