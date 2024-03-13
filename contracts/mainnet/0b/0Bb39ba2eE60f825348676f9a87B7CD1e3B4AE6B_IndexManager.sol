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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import './interfaces/IIndexManager.sol';

contract IndexManager is IIndexManager, Context, Ownable {
  IIndexAndStatus[] public indexes;
  mapping(address => bool) public authorized;

  modifier onlyAuthorized() {
    bool _authd = _msgSender() == owner() || authorized[_msgSender()];
    require(_authd, 'UNAUTHORIZED');
    _;
  }

  function indexLength() external view returns (uint256) {
    return indexes.length;
  }

  function allIndexes()
    external
    view
    override
    returns (IIndexAndStatus[] memory)
  {
    return indexes;
  }

  function setAuthorized(
    address _auth,
    bool _isAuthed
  ) external onlyAuthorized {
    require(authorized[_auth] != _isAuthed, 'CHANGE');
    authorized[_auth] = _isAuthed;
  }

  function addIndex(
    address _index,
    bool _verified
  ) external override onlyAuthorized {
    indexes.push(IIndexAndStatus({ index: _index, verified: _verified }));
    emit AddIndex(_index, _verified);
  }

  function removeIndex(uint256 _indexIdx) external override onlyAuthorized {
    IIndexAndStatus memory _idx = indexes[_indexIdx];
    indexes[_indexIdx] = indexes[indexes.length - 1];
    indexes.pop();
    emit RemoveIndex(_idx.index);
  }

  function verifyIndex(
    uint256 _indexIdx,
    bool _verified
  ) external override onlyAuthorized {
    require(indexes[_indexIdx].verified != _verified, 'CHANGE');
    indexes[_indexIdx].verified = _verified;
    emit SetVerified(indexes[_indexIdx].index, _verified);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IIndexManager {
  struct IIndexAndStatus {
    address index;
    bool verified;
  }

  event AddIndex(address indexed index, bool verified);

  event RemoveIndex(address indexed index);

  event SetVerified(address indexed index, bool verified);

  function allIndexes() external view returns (IIndexAndStatus[] memory);

  function addIndex(address index, bool verified) external;

  function removeIndex(uint256 idx) external;

  function verifyIndex(uint256 idx, bool verified) external;
}