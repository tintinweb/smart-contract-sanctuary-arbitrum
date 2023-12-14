// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./ReentrancyGuard.sol";
import "./ERC721/IERC721.sol";
import "./Ownable.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface IStakingToken is IERC20 {
    function getMaxWallet() external view returns (uint256);
}

contract BoinkStaking is ReentrancyGuard, Ownable {
    IStakingToken public stakingToken;
    mapping(address => bool) public boosterNfts; // Mapping to track accepted NFT contracts

    uint256 private constant EXTRA_SHARE_PER_NFT = 20; // 20% extra shares per NFT
    uint256 private constant MAX_EXTRA_SHARES = 100; // Max extra shares percentage
    uint256 private constant MAX_NFTS_FOR_EXTRA_SHARES = 5; // Max number of NFTs for extra shares

    uint256 public totalETHReceived;
    uint256 public totalSupply;

    mapping(address => uint256[]) private stakedNFTs;
    mapping(address => uint256) private userExtraShares;

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public lastClaimedETHAmount;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event NFTDeposited(address indexed user, uint256[] tokenIds);
    event NFTWithdrawn(address indexed user, uint256[] tokenIds);
    event NftContractAdded(address indexed nftContract);
    event NftContractRemoved(address indexed nftContract);

    modifier onlyBoosterNfts() {
        require(boosterNfts[msg.sender], "NFT contract not accepted");
        _;
    }

    function addBoosterNfts(address _nftContract) external onlyOwner {
        boosterNfts[_nftContract] = true;
        emit NftContractAdded(_nftContract);
    }

    function removeBoosterNfts(address _nftContract) external onlyOwner {
        boosterNfts[_nftContract] = false;
        emit NftContractRemoved(_nftContract);
    }

    function setStakingToken(address _stakingToken) external onlyOwner {
        stakingToken = IStakingToken(_stakingToken);
    }

    function viewStakedNFTs(address _user) public view returns (uint256[] memory) {
        return stakedNFTs[_user];
    }

    function countStakedNFTs(address _user) public view returns (uint256) {
        return stakedNFTs[_user].length;
    }

    // Helper function to remove a staked NFT from the array
    function removeStakedNFT(address _user, uint256 _tokenId) internal {
        uint256[] storage staked = stakedNFTs[_user];
        for (uint256 i = 0; i < staked.length; i++) {
            if (staked[i] == _tokenId) {
                staked[i] = staked[staked.length - 1];
                staked.pop();
                break;
            }
        }
    }

    // Helper function to update user's extra shares
    function updateUserExtraShares(address _user) internal {
        uint256 nftCount = stakedNFTs[_user].length;
        uint256 extraShares = nftCount * EXTRA_SHARE_PER_NFT;
        if (extraShares > MAX_EXTRA_SHARES) {
            extraShares = MAX_EXTRA_SHARES;
        }
        userExtraShares[_user] = extraShares;
    }

    // Deposit NFTs for booster
    function depositNFT(address _nftContract, uint256[] calldata _tokenIds) external onlyBoosterNfts nonReentrant {
        require(_tokenIds.length > 0, "Must deposit at least one NFT");
        require(stakedNFTs[msg.sender].length + _tokenIds.length <= MAX_NFTS_FOR_EXTRA_SHARES, "Exceeds max NFT stake");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC721(_nftContract).transferFrom(msg.sender, address(this), _tokenIds[i]);
            stakedNFTs[msg.sender].push(_tokenIds[i]);
        }

        // Update user's extra shares
        updateUserExtraShares(msg.sender);
        emit NFTDeposited(msg.sender, _tokenIds);
    }

    // Withdraw NFTs and claim rewards
    function withdrawNFT(address _nftContract, uint256[] calldata _tokenIds) external onlyBoosterNfts nonReentrant {
        require(_tokenIds.length > 0, "No NFTs to withdraw");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(IERC721(_nftContract).ownerOf(_tokenIds[i]) == address(this), "Contract does not own this NFT");
            IERC721(_nftContract).transferFrom(address(this), msg.sender, _tokenIds[i]);
            removeStakedNFT(msg.sender, _tokenIds[i]);
        }
        // Update user's extra shares
        updateUserExtraShares(msg.sender);
        emit NFTWithdrawn(msg.sender, _tokenIds);
    }

    // Function to withdraw all staked NFTs
    function withdrawAllNFTs(address _nftContract) external onlyBoosterNfts nonReentrant {
        uint256[] memory userNFTs = stakedNFTs[msg.sender];
        require(userNFTs.length > 0, "No NFTs to withdraw");

        for (uint256 i = 0; i < userNFTs.length; i++) {
            uint256 tokenId = userNFTs[i];
            require(IERC721(_nftContract).ownerOf(tokenId) == address(this), "Contract does not own this NFT");
            IERC721(_nftContract).transferFrom(address(this), msg.sender, tokenId);
            // Note: No need to call removeStakedNFT here as we're clearing the whole array next
        }

        // Clear the user's staked NFT array and reset extra shares
        delete stakedNFTs[msg.sender];
        updateUserExtraShares(msg.sender);

        emit NFTWithdrawn(msg.sender, userNFTs);
    }

    function calculateReward(address _account) public view returns (uint256) {
        if (totalSupply == 0) return 0;

        uint256 newETH = totalETHReceived - lastClaimedETHAmount[_account];

        // Calculate base share based on staked tokens
        uint256 baseShare = (balanceOf[_account] * newETH) / totalSupply;

        // Calculate boosted share based on NFT deposits
        uint256 boostedShareAmount = 0;
        uint256 nftCount = stakedNFTs[_account].length;

        if (nftCount > 0) {
            // Calculate boosted share for each NFT
            uint256 perNFTBoost = (EXTRA_SHARE_PER_NFT * nftCount) / 100;
            boostedShareAmount = (baseShare * perNFTBoost);

            // Cap boosted share to prevent abuse
            if (boostedShareAmount > MAX_EXTRA_SHARES) {
                boostedShareAmount = MAX_EXTRA_SHARES;
            }
        }

        // Deduct boosted share from base share to redistribute rewards
        baseShare -= boostedShareAmount;

        return baseShare + boostedShareAmount;
    }

    function stake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "amount = 0");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        balanceOf[msg.sender] += _amount;
        totalSupply += _amount;
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        require(_amount > 0, "amount = 0");
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount);
    }

    function emergencyWithdraw() external nonReentrant {
        uint256 stakedAmount = balanceOf[msg.sender];
        require(stakedAmount > 0, "No tokens staked");
        balanceOf[msg.sender] = 0;
        totalSupply -= stakedAmount;
        stakingToken.transfer(msg.sender, stakedAmount);
    }

    function emergencyRecover() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {
        totalETHReceived += msg.value;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.19;

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

pragma solidity 0.8.19;

import "../IERC165.sol";

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

pragma solidity 0.8.19;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity 0.8.19;

import "./Context.sol";

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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity 0.8.19;

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}