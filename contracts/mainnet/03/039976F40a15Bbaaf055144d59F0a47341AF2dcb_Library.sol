/**
 *Submitted for verification at Arbiscan on 2023-05-31
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

// File: Library.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;



/**
 * @title Library
 * @notice This contract has been automatically generated by SolidQuery 0.2.0.
 * It represents a structured, on-chain database that includes CRUD operations,
 * on-chain indexing capabilities, and getter and setter functions where applicable.
 * It is tailored to a specific schema, provided as input in a YAML format.
 * For detailed function descriptions and specific structure, please refer to the function
 * and struct level comments within the contract.
 * @dev For more information on SolidQuery, please visit our GitHub repository.
 * https://github.com/KenshiTech/SolidQuery
 */
contract Library is Context, Ownable {
  struct Book {
    string Title;
    string Author;
    uint256 YearPublished;
    uint256 DecadePublished;
  }

  uint256 private bookCounter = 0;

  event BookCreated(
    uint256 Id,
    string Title,
    string Author,
    uint256 YearPublished,
    uint256 DecadePublished
  );
  event BookUpdated(
    uint256 Id,
    string Title,
    string Author,
    uint256 YearPublished,
    uint256 DecadePublished
  );
  event BookDeleted(uint256 Id);

  mapping(uint256 => Book) Books;

  mapping(uint256 => uint256[]) bookDecadePublishedIndex;

  /**
   * @dev Removes a specific id from an array stored in the contract's storage.
   * @param index The storage array from which to remove the id.
   * @param id The id to remove from the array.
   */
  function popFromIndex(uint256[] storage index, uint256 id) internal {
    uint256 length = index.length;
    for (uint256 i = 0; i < length; i++) {
      if (id == index[i]) {
        index[i] = index[length - 1];
        index.pop();
        break;
      }
    }
  }

  /**
   * @dev Removes an ID from the bookDecadePublished index for a given Book record.
   * @param Id The Id of the record to remove from the index.
   */
  function deleteBookDecadePublishedIndexForId(uint256 Id) internal {
    uint256[] storage index = bookDecadePublishedIndex[
      Books[Id].DecadePublished
    ];
    popFromIndex(index, Id);
  }

  /**
   * @dev Adds a new ID to the bookDecadePublished index for a given Book record.
   * @param Id The Id of the record to add.
   * @param value The Book record to add.
   */
  function addBookDecadePublishedIndexForId(
    uint256 Id,
    Book memory value
  ) internal {
    bookDecadePublishedIndex[value.DecadePublished].push(Id);
  }

  /**
   * @dev Adds a new Book record and updates relevant indexes.
   * @notice Emits a BookAdded event on success.
   * @param value The new record to add.
   * @return The ID of the newly added record.
   */
  function addBook(Book calldata value) external onlyOwner returns (uint256) {
    uint256 Id = bookCounter++;
    Books[Id] = value;
    addBookDecadePublishedIndexForId(Id, value);
    emit BookCreated(
      Id,
      value.Title,
      value.Author,
      value.YearPublished,
      value.DecadePublished
    );
    return Id;
  }

  /**
   * @dev Deletes a Book record by its ID and updates relevant indexes.
   * @notice Emits a BookDeleted event on success.
   * @param Id The ID of the record to delete.
   */
  function deleteBook(uint256 Id) external onlyOwner {
    deleteBookDecadePublishedIndexForId(Id);
    delete Books[Id];
    emit BookDeleted(Id);
  }

  /**
   * @dev Updates a Book record by its Id.
   * @notice Emits a BookUpdated event on success.
   * @param Id The Id of the record to update.
   * @param value The new data to update the record with.
   */
  function updateBook(uint256 Id, Book calldata value) external onlyOwner {
    deleteBookDecadePublishedIndexForId(Id);
    addBookDecadePublishedIndexForId(Id, Books[Id]);
    Books[Id] = value;
    emit BookUpdated(
      Id,
      value.Title,
      value.Author,
      value.YearPublished,
      value.DecadePublished
    );
  }

  /**
   * @dev Finds IDs of Book records by a specific DecadePublished.
   * @param value The DecadePublished value to search by.
   * @return An array of matching record IDs.
   */
  function findBookByDecadePublished(
    uint256 value
  ) external view returns (uint256[] memory) {
    return bookDecadePublishedIndex[value];
  }

  /**
   * @dev Retrieves an array of Book records by their IDs.
   * @param IdList An array of record IDs to retrieve.
   * @return An array of the retrieved records.
   */
  function getBooksById(
    uint256[] calldata IdList
  ) external view returns (Book[] memory) {
    uint256 length = IdList.length;
    Book[] memory result = new Book[](length);
    for (uint256 index = 0; index < length; index++) {
      result[index] = Books[IdList[index]];
    }
    return result;
  }
}