//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ISignature.sol";

/// ID `txnCount` has already been processed.
/// @param txnCount ID of the transaction.
error DuplicatedTransaction(uint256 txnCount);

/// Invalid signature.
error InvalidSignature(); 

/// Invalid data.
error InvalidData(); 

interface IMasterOfInflation {
    struct MintFromPoolParams {
        // Slot 1 (160/256)
        uint64 poolId;
        uint64 amount;
        // Extra odds (out of 100,000) of pulling the item. Will be multiplied against the base odds
        // (1 + bonus) * dynamicBaseOdds
        uint32 bonus;

        // Slot 2
        uint256 itemId;

        // Slot 3
        uint256 randomNumber;

        // Slot 4 (192/256)
        address user;
        uint32 negativeBonus;
    }

    function tryMintFromPool(MintFromPoolParams calldata params) external;
}

interface ITreasureFragment {
    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;
}

/// @title Handles Treasure Fragments. 
/// @author Wayne (Ellerian Prince)
/// @notice Allows off-chain Lootboxes to be burnt in exchange for on-chain Treasure Fragments.
/// @dev This contract needs perms to mint Treasure Fragments.
contract ElleriaTreasureFragments is Ownable, ReentrancyGuard {
  /// @notice Number of past attempts.
  uint256 public tryCount;

  /// @notice Address used to verify signatures.
  address public signerAddr;

  /// @dev Reference to the contract that does signature verifications.
  ISignature public signatureAbi;

  /// @dev Address of the Master of inflation Contract.
  address public masterOfInflationAddr;

    /// @dev Address of the Treasure Fragment Contract.
  address public treasureFragmentAddr;

  // Prevents replaying of mints.
  mapping(uint256 => bool) private _isProcessed; 

  /// @dev Initializes dependencies.
  /// @param _signatureAddr Address of contract used to verify signatures.
  /// @param _signerAddr Address of the private signer.
  /// @param _masterOfInflationAddr Address of contract allowing fragment mints.
  /// @param _tryCount ID to start from.
  constructor(
    address _signatureAddr, 
    address _signerAddr, 
    address _masterOfInflationAddr,
    address _fragmentAddr,
    uint256 _tryCount)
  {
      signatureAbi = ISignature(_signatureAddr);
      masterOfInflationAddr = _masterOfInflationAddr;
      treasureFragmentAddr = _fragmentAddr;
      signerAddr = _signerAddr;

      tryCount = _tryCount;
  }

    /// @notice Try to mint fragments using a server-generated signature. Generated when fragment lootboxes are burnt.
    /// @dev Withdrawals rely on signature and its payload; care must be taken in the private signature generation.
    ///      In the backend- Lootbox balance is deducted before the signature is generated to prevent stacking.
    ///      _txnCount is incremented every signature generation, and is checked for prevent replay attacks.
    ///      This means there can be gaps in _txnCount (but not tryCount).
    /// @param _signature Signature.
    /// @param _data An array containing the txnCount, poolId, amount, bonus, itemId, negativeBonus, in order.
  function tryMintTreasureFragments(bytes memory _signature, uint256[] memory _data) external nonReentrant {
    if (_data.length != 6) {
      revert InvalidData();
    }

    if(!signatureAbi.bigVerify(signerAddr, msg.sender, _data, _signature)) {
      revert InvalidSignature();
    }

    uint256 _txnCount = _data[0];

    if (_isProcessed[_txnCount]) {
      revert DuplicatedTransaction(_txnCount);
    }

    ++tryCount;
    _isProcessed[_txnCount] = true;

    IMasterOfInflation.MintFromPoolParams memory params;
    params.poolId = uint64(_data[1]);
    params.amount = uint64(_data[2]);
    params.bonus = uint32(_data[3]);
    params.itemId = _data[4];
    params.randomNumber = 0;
    params.user = msg.sender;
    params.negativeBonus = uint32(_data[5]);

    IMasterOfInflation(masterOfInflationAddr).tryMintFromPool(params);

    emit MintAttempt(msg.sender, _txnCount, params.poolId, params.amount, params.bonus, params.itemId, params.negativeBonus);
  }

    /// @notice Relays the burn call to the main contract.
    /// @param account Signature.
    /// @param ids An array containing a list of ids to burn.
    /// @param values An array mapped to ids containing amount to burn.
  function burnTreasureFragments(address account, uint256[] memory ids, uint256[] memory values) 
  external {
    ITreasureFragment(treasureFragmentAddr).burnBatch(account, ids, values);
  }
  
  /// @notice Event emitted when tryMintTreasureFragments is called.
  /// @param sender The address of the caller.
  /// @param txnCount The transaction count.
  /// @param poolId The pool id.
  /// @param amount The number of fragments to attempt minting.
  /// @param bonus Bonus odds.
  /// @param itemId The fragment item id.
  /// @param negativeBonus Negative odds.
  event MintAttempt(address indexed sender,
    uint256 txnCount,
    uint256 poolId,
    uint256 amount,
    uint256 bonus,
    uint256 itemId,
    uint256 negativeBonus
  );
}

pragma solidity ^0.8.0;
//SPDX-License-Identifier: MIT

// Interface for the signature verifier.
contract ISignature {
    function verify(address _signer, address _to, uint256 _amount, string memory _message, uint256 _nonce, bytes memory signature) public pure returns (bool) { }
    function bigVerify(address _signer, address _to, uint256[] memory _data, bytes memory signature ) public pure returns (bool) {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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