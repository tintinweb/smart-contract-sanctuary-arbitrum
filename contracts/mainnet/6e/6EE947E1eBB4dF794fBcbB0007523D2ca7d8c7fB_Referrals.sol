// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "IReferrals.sol";
import "Ownable.sol";
import "IERC721.sol";


contract Referrals is IReferrals, Ownable {
  event SetDiscounts(uint16 _rebateReferrer, uint16 _rebateReferrerVip, uint16 _discountReferee, uint16 _discountRefereeVip);
  event SetVip(address user, bool _isVip);
  event AddedVipNFT(address nft);
  event RemovedVipNFT(address nft);
  
  /// @notice Referrer names for user friendly referrer picking
  mapping (bytes32 => address) private _referrerNames;
  /// @notice Referee to referrer mapping
  mapping (address => address) private _refereeToReferrer;
  /// @notice Mapping of a user referees
  mapping (address => address[]) private _referrerToReferees;
  /// @notice Mapping of VIP users
  mapping (address => bool) private _vips;
  /// @notice Array of VIP NFTs / hold NFT to get VIP status
  address[] private vipNfts;
  
  /// @notice Referrer/referee discount in percent X4 (500 == 5%)
  uint16 public rebateReferrer = 500;
  uint16 public rebateReferrerVip = 800;
  uint16 public discountReferee = 500;
  uint16 public discountRefereeVip = 800;
  
  
  /// @notice Set referral fee discounts
  function setReferralDiscounts(uint16 _rebateReferrer, uint16 _rebateReferrerVip, uint16 _discountReferee, uint16 _discountRefereeVip) public onlyOwner {
    require(_rebateReferrer < 10000 && _rebateReferrerVip < 10000 && _discountReferee < 10000 && _discountRefereeVip < 10000, "GEC: Invalid Discount");
    rebateReferrer = _rebateReferrer;
    rebateReferrerVip = _rebateReferrerVip;
    discountReferee = _discountReferee;
    discountRefereeVip = _discountRefereeVip;
    emit SetDiscounts(_rebateReferrer, _rebateReferrerVip, _discountReferee, _discountRefereeVip);
  } 
  
  
  /// @notice Register a referral name
  function registerName(bytes32 name) public {
    require(_referrerNames[name] == address(0x0), "Already registered");
    _referrerNames[name] = msg.sender;
  }
  
  /// @notice Register a referrer by name
  function registerReferrer(bytes32 name) public {
    address referrer = _referrerNames[name];
    require(referrer != msg.sender, "Self refer");
    require(referrer != address(0x0), "No such referrer");
    require(_refereeToReferrer[msg.sender] == address(0x0), "Referrer already set");
    _refereeToReferrer[msg.sender] = referrer;
    _referrerToReferees[referrer].push(msg.sender);
  }
  
  /// @notice Get referrer
  function getReferrer(address user) public view returns (address referrer) {
    referrer = _refereeToReferrer[user];
  }
  
  /// @notice Get number of referees
  function getRefereesLength(address referrer) public view returns (uint length) {
    length = _referrerToReferees[referrer].length;
  }
  
  /// @notice Get referee by index
  function getReferee(address referrer, uint index) public view returns (address referee) {
    referee = _referrerToReferees[referrer][index];
  }
  

  /// @notice Get referral parameters
  function getReferralParameters(address user) external view returns (address _referrer, uint16 _rebateReferrer, uint16 _discountReferee) {
    _referrer = getReferrer(user);
    if (_referrer != address(0)){
      // If user has no referrer he doesnt get the discount for referees
      _discountReferee = isVip(user) ? discountRefereeVip : discountReferee;
      // the referrer discount is based on referrer status not user status
      _rebateReferrer = isVip(_referrer) ? rebateReferrerVip : rebateReferrer;
    }
  }
  
  
  ///// VIP 
  
  /// @notice Set or unset VIP user
  function setVip(address user, bool _isVip) public onlyOwner {
    _vips[user] = _isVip;
    emit SetVip(user, _isVip);
  }
  
  /// @notice Add VIP NFT to list
  function addVipNft(address _nft) public onlyOwner {
    require(_nft != address(0x0), "Ref: Invalid NFT");
    for (uint k; k < vipNfts.length; k++) require(_nft != vipNfts[k], "Ref: Already NFT");
    vipNfts.push(_nft);
    emit AddedVipNFT(_nft);
  }
  
  /// @notice Remove VIP NFT
  function removeVipNft(address _nft) public onlyOwner {
    for (uint k = 0; k < vipNfts.length; k++) {
      if (vipNfts[k] == _nft){
        if (k < vipNfts.length - 1) vipNfts[k] = vipNfts[vipNfts.length - 1];
        vipNfts.pop();
        emit RemovedVipNFT(_nft);
      }
    }
  }
  
  /// @notice Check if user is VIP or holds partner VIP NFT
  function isVip(address user) public view returns (bool) {
    if (_vips[user]) return true;
    for (uint k; k < vipNfts.length; k++) 
      if (IERC721(vipNfts[k]).balanceOf(user) > 0) return true;
    return false;
  }
  

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IReferrals {
  function registerName(bytes32 name) external;
  function registerReferrer(bytes32 name) external;
  function getReferrer(address user) external view returns (address referrer);
  function getRefereesLength(address referrer) external view returns (uint length);
  function getReferee(address referrer, uint index) external view returns (address referee);
  function getReferralParameters(address user) external view returns (address referrer, uint16 rebateReferrer, uint16 discountReferee);
  function addVipNft(address _nft) external;
  function removeVipNft(address _nft) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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