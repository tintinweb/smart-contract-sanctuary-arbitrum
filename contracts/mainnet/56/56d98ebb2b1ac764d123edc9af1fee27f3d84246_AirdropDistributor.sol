/**
 *Submitted for verification at Arbiscan on 2023-04-25
*/

// SPDX-License-Identifier: MIT
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function setApprovalForAll(address operator, bool _approved) external;

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

    function nftStatus(uint256 _tokenId) external view returns (uint8 typeNFT,uint256 mining,uint256 attack,uint256 defense, uint256 hpBlood);
}

// File: Airdrop.sol


pragma solidity ^0.8.1;






contract AirdropDistributor is Ownable,ReentrancyGuard,Pausable {
    IERC20 public token;
    IERC721 public nftOGCollection;
    IERC721 public nftODYSSEYCollection;

    uint256 public MAX_TOKENAIRDROP_OG = 450000000000 *  10 ** 18;
    uint256 public MAX_TOKENAIRDROP_ODYSSEY_NFT = 120000000000 *  10 ** 18;
    uint256 public MAX_TOKENAIRDROP_REFER = 30000000000 *  10 ** 18;

    uint256 public tokenPer_Nft_OG_Claim = 15000000 * 10 ** 18;
    uint256 public tokenPer_ODYSSEY_NFT_Claim = 4000000 * 10 ** 18;
    uint256 public tokenPer_REFER_Claim = 1000000 * 10 ** 18;

    // uint256 public MAX_ODYSSEY_NFT_Claim = 30000;
    // uint256 public MAX_REFER = 30000;


    mapping(address => uint256) public _trackStake_OG;

    mapping(uint256 => bool) public _isNumber_ODYSSEY_NFT_Claimed;

    uint256 public claimedCount_TOKENID_OG = 0;
    uint256 public claimedCount_TOKENID_ODYSSEY_NFT = 0;
    uint256 public claimedCount_TOKEN_REFER = 0;


    event Claim_OG(address indexed user, uint256 amount,address referrer, uint timestamp);
    event Claim_ODYSSEY_NFT(address indexed user, uint256 amount,address referrer, uint timestamp);
    event Stake(uint256[] indexed tokenID,address indexed user);


    constructor(IERC20 _token,IERC721 _nftOGCollection,IERC721 _nftODYSSEYCollection) {
        token = _token;
        nftOGCollection = _nftOGCollection;
        nftODYSSEYCollection = _nftODYSSEYCollection;
    }

    function stake(uint256[] calldata _tokenIds) external whenNotPaused nonReentrant {
        uint256 len = _tokenIds.length;
        for (uint256 i; i < len; ++i) {
            require(nftOGCollection.ownerOf(_tokenIds[i]) == msg.sender, "Can't stake NFT that you don't own ");
            nftOGCollection.transferFrom(msg.sender, address(this), _tokenIds[i]);
            _trackStake_OG[msg.sender] += 1;
        }
        emit Stake(_tokenIds,msg.sender);
    }


    function claimOG(address referrer) external whenNotPaused nonReentrant {
        require(_trackStake_OG[msg.sender] > 0, "no nft for claim");
        require(claimedCount_TOKENID_OG <= MAX_TOKENAIRDROP_OG, "claim ODYSSEY NFT MAX");

        uint256 amountOfTokensToClaim = tokenPer_Nft_OG_Claim * _trackStake_OG[msg.sender];
        claimedCount_TOKENID_OG += tokenPer_Nft_OG_Claim * _trackStake_OG[msg.sender];
        _trackStake_OG[msg.sender] = 0;

        token.transfer(msg.sender, amountOfTokensToClaim);

        if (referrer != address(0) && referrer != msg.sender && claimedCount_TOKEN_REFER <= MAX_TOKENAIRDROP_REFER) {
            claimedCount_TOKEN_REFER+= tokenPer_REFER_Claim;
            token.transfer(referrer, tokenPer_REFER_Claim);
        }


        emit Claim_OG(msg.sender, amountOfTokensToClaim,referrer, block.timestamp);
    }

    function claimODYSSEYNFT(uint256[] calldata _tokenIds,address referrer) external whenNotPaused nonReentrant {
        require(claimedCount_TOKENID_ODYSSEY_NFT <= MAX_TOKENAIRDROP_ODYSSEY_NFT, "claim ODYSSEY NFT MAX");
        uint256 len = _tokenIds.length;
        require(len > 0, "input empty");

        uint256 amountOfTokensToClaim;
         for (uint256 i; i < len; ++i) {
            require(nftODYSSEYCollection.ownerOf(_tokenIds[i]) == msg.sender, "Can't claim NFT that you don't own ");
            require(_isNumber_ODYSSEY_NFT_Claimed[_tokenIds[i]] == false, "NFT that have already been claimed");
            _isNumber_ODYSSEY_NFT_Claimed[_tokenIds[i]] = true;
            claimedCount_TOKENID_ODYSSEY_NFT+= tokenPer_ODYSSEY_NFT_Claim;
            amountOfTokensToClaim += tokenPer_ODYSSEY_NFT_Claim;
        }

        token.transfer(msg.sender, amountOfTokensToClaim);

        if (referrer != address(0) && referrer != msg.sender && claimedCount_TOKEN_REFER <= MAX_TOKENAIRDROP_REFER) {
            claimedCount_TOKEN_REFER+=1;
            token.transfer(referrer, tokenPer_REFER_Claim);
        }


        emit Claim_ODYSSEY_NFT(msg.sender, amountOfTokensToClaim,referrer, block.timestamp);
    }




    function isHaveOGClaim(address _addressUser)  public view returns (bool){
        if(_trackStake_OG[_addressUser] > 0){
            return  true;
        }
        return false;
    }

    function setToken(address _tokenAddress) public onlyOwner {
        token = IERC20(_tokenAddress);
    }

    function setNftOGCollection(address _nftOgCollection) public onlyOwner {
        nftOGCollection = IERC721(_nftOgCollection);
    }

    function setNftODYSSEYCollection(address _nftODYSSEYCollection) public onlyOwner {
        nftODYSSEYCollection = IERC721(_nftODYSSEYCollection);
    }


    function setTokenPer_Nft_OG_Claim(uint256 _tokenPer_Nft_OG_Claim) public onlyOwner {
        tokenPer_Nft_OG_Claim = _tokenPer_Nft_OG_Claim;
    }

    function setTokenPer_ODYSSEY_NFT_Claim(uint256 _tokenPer_ODYSSEY_NFT_Claim) public onlyOwner {
        tokenPer_ODYSSEY_NFT_Claim = _tokenPer_ODYSSEY_NFT_Claim;
    }

    function setTokenPer_REFER_Claim(uint256 _tokenPer_REFER_Claim) public onlyOwner {
        tokenPer_REFER_Claim = _tokenPer_REFER_Claim;
    }

    function setMAX_TOKENAIRDROP_OG(uint256 _MAX_TOKENAIRDROP_OG) public onlyOwner {
        MAX_TOKENAIRDROP_OG = _MAX_TOKENAIRDROP_OG;
    }

    function setMAX_TOKENAIRDROP_ODYSSEY_NFT(uint256 _MAX_TOKENAIRDROP_ODYSSEY_NFT) public onlyOwner {
        MAX_TOKENAIRDROP_ODYSSEY_NFT = _MAX_TOKENAIRDROP_ODYSSEY_NFT;
    }

    function setMAX_TOKENAIRDROP_REFER(uint256 _MAX_TOKENAIRDROP_REFER) public onlyOwner {
        MAX_TOKENAIRDROP_REFER = _MAX_TOKENAIRDROP_REFER;
    }


     function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

   function recoverEth() external onlyOwner {
        (bool os, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(os);
    }

    function recoverERC20(address _tokenAddress, uint256 amount) external onlyOwner {
        IERC20(_tokenAddress).transfer(owner(), amount);
    }
    
}