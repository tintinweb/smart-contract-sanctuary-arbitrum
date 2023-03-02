/**
 *Submitted for verification at Arbiscan on 2023-02-28
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: DonationContract.sol


pragma solidity ^0.8.19;


contract DonationContract is Ownable {
    uint256 public fundInCents; // Total fund in cents available

    struct Transaction {
        string _id; // transaction id
        string _userId; // user id
        uint256 _amountInCents; // amount transacted in cents
        bool _isAddFund;
    }

    // transaction id => donation
    mapping(string => Transaction) public transactions;

    function add(Transaction memory _transaction) public onlyOwner {
        // Check if transaction already exist
        require(
            transactions[_transaction._id]._amountInCents <= 0,
            "Transaction already exist."
        );

        updateFund(_transaction);
        transactions[_transaction._id] = _transaction;
    }

    function addMultiple(Transaction[] memory _transactions) public onlyOwner {
        for (uint256 i = 0; i < _transactions.length; i++) {
            // Check if transaction already exist
            if (transactions[_transactions[i]._id]._amountInCents <= 0) {
                revert("Transaction already exist.");
            }

            updateFund(_transactions[i]);
            transactions[_transactions[i]._id] = _transactions[i];
        }
    }

    function updateFund(Transaction memory _transaction) private {
        if (_transaction._isAddFund) {
            // Add to fund if the transaction is a donation
            fundInCents += _transaction._amountInCents;
        } else {
            if (fundInCents < _transaction._amountInCents) {
                revert("Insufficient fund.");
            }

            // Subtract from fund if the transaction is a redemption
            fundInCents -= _transaction._amountInCents;
        }
    }
}