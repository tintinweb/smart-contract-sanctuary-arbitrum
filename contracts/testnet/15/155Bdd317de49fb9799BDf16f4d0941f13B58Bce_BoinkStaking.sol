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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

// testnet version to accept test ETH erc20 instead of goerli eth

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IBoinkStaking.sol";

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

contract BoinkStaking is IBoinkStaking, ReentrancyGuard, Ownable {
    IStakingToken public stakingToken;
    IERC721 public honeyCrystalNft;
    IERC20 public rewardToken; // ERC20 token used for rewards

    uint256 private constant EXTRA_SHARE_PER_NFT = 20; // 20% extra shares per NFT
    uint256 private constant MAX_EXTRA_SHARES = 100; // Max extra shares percentage
    uint256 private constant MAX_NFTS_FOR_EXTRA_SHARES = 5; // Max number of NFTs for extra shares

    uint256 public totalSupply;

    mapping(address => uint256[]) private stakedNFTs;
    mapping(address => uint256) private userExtraShares;

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public lastClaimedRewardAmount;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event NFTDeposited(address indexed user, uint256[] tokenIds);
    event NFTWithdrawn(address indexed user, uint256[] tokenIds);

    constructor(address _rewardToken) {
        rewardToken = IERC20(_rewardToken);
    }

    function setHoneyCrystalNftContract(address _honeyCrystalNft) external onlyOwner override {
        honeyCrystalNft = IERC721(_honeyCrystalNft);
    }

    function setStakingToken(address _stakingToken) external onlyOwner override {
        stakingToken = IStakingToken(_stakingToken);
    }

    function setRewardToken(address _rewardToken) external onlyOwner {
        rewardToken = IERC20(_rewardToken);
    }

    // Function to view staked NFTs and their token IDs for a user
    function viewStakedNFTs(address _user) public view override returns (uint256[] memory) {
        return stakedNFTs[_user];
    }

    // Function to get the count of staked NFTs for a user
    function countStakedNFTs(address _user) public view override returns (uint256) {
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
    function depositNFT(uint256[] calldata _tokenIds) external nonReentrant override {
        require(_tokenIds.length > 0, "Must deposit at least one NFT");
        require(stakedNFTs[_msgSender()].length + _tokenIds.length <= MAX_NFTS_FOR_EXTRA_SHARES, "Exceeds max NFT stake");

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            honeyCrystalNft.transferFrom(_msgSender(), address(this), _tokenIds[i]);
            stakedNFTs[_msgSender()].push(_tokenIds[i]);
        }

        // Update user's extra shares
        updateUserExtraShares(_msgSender());
        emit NFTDeposited(_msgSender(), _tokenIds);
    }

    // Withdraw NFTs and claim rewards
    function withdrawNFT(uint256[] calldata _tokenIds) external nonReentrant override {
        require(_tokenIds.length > 0, "No NFTs to withdraw");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(honeyCrystalNft.ownerOf(_tokenIds[i]) == address(this), "Contract does not own this NFT");
            honeyCrystalNft.transferFrom(address(this), _msgSender(), _tokenIds[i]);
            removeStakedNFT(_msgSender(), _tokenIds[i]);
        }
        // Update user's extra shares
        updateUserExtraShares(_msgSender());
        emit NFTWithdrawn(_msgSender(), _tokenIds);
    }

    // Function to withdraw all staked NFTs
    function withdrawAllNFTs() external nonReentrant override {
        uint256[] memory userNFTs = stakedNFTs[_msgSender()];
        require(userNFTs.length > 0, "No NFTs to withdraw");

        for (uint256 i = 0; i < userNFTs.length; i++) {
            uint256 tokenId = userNFTs[i];
            require(honeyCrystalNft.ownerOf(tokenId) == address(this), "Contract does not own this NFT");
            honeyCrystalNft.transferFrom(address(this), _msgSender(), tokenId);
            // Note: No need to call removeStakedNFT here as we're clearing the whole array next
        }

        // Clear the user's staked NFT array and reset extra shares
        delete stakedNFTs[_msgSender()];
        updateUserExtraShares(_msgSender());

        emit NFTWithdrawn(_msgSender(), userNFTs);
    }

    // Function to claim the reward
    function claimReward() public nonReentrant override {
        // Update last claimed amount to current total reward received
        lastClaimedRewardAmount[_msgSender()] = rewardToken.balanceOf(address(this));

        // Then calculate the reward based on this updated state
        uint256 tokenReward = calculateReward(_msgSender());

        if (tokenReward > 0) {
            rewardToken.transfer(_msgSender(), tokenReward);
            emit RewardClaimed(_msgSender(), tokenReward);
        }
    }

    // Adjusted reward calculation
    function calculateReward(address _account) public view override returns (uint256) {
        if (totalSupply == 0) return 0;
        uint256 newReward = rewardToken.balanceOf(address(this)) - lastClaimedRewardAmount[_account];
        uint256 baseShare = (balanceOf[_account] * newReward) / totalSupply;
        uint256 extraShareAmount = (baseShare * userExtraShares[_account]) / 100;
        return baseShare + extraShareAmount;
    }

    function stake(uint256 _amount) external nonReentrant override {
        require(_amount > 0, "amount = 0");
        // require(balanceOf[_msgSender()] + _amount <= stakingToken.getMaxWallet(), "Exceeds maxWallet limit"); // COMMENT OUT FOR TESTNET
        stakingToken.transferFrom(_msgSender(), address(this), _amount);
        balanceOf[_msgSender()] += _amount;
        totalSupply += _amount;
        emit Staked(_msgSender(), _amount);
    }

    function withdraw(uint256 _amount) external nonReentrant override {
        require(_amount > 0, "amount = 0");
        balanceOf[_msgSender()] -= _amount;
        totalSupply -= _amount;
        stakingToken.transfer(_msgSender(), _amount);
        emit Unstaked(_msgSender(), _amount);
    }

    function emergencyWithdraw() external nonReentrant override {
        uint256 stakedAmount = balanceOf[_msgSender()];
        require(stakedAmount > 0, "No tokens staked");
        balanceOf[_msgSender()] = 0;
        totalSupply -= stakedAmount;
        stakingToken.transfer(_msgSender(), stakedAmount);
    }

    // TESTNET ONLY
    function emergencyRecover() external onlyOwner override {
        rewardToken.transfer(owner(), rewardToken.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

interface IBoinkStaking {
    function setHoneyCrystalNftContract(address _honeyCrystalNft) external;
    function setStakingToken(address _stakingToken) external;
    function viewStakedNFTs(address _user) external view returns (uint256[] memory);
    function countStakedNFTs(address _user) external view returns (uint256);
    function depositNFT(uint256[] calldata _tokenIds) external;
    function withdrawNFT(uint256[] calldata _tokenIds) external;
    function withdrawAllNFTs() external;
    function claimReward() external;
    function calculateReward(address _account) external view returns (uint256);
    function stake(uint256 _amount) external;
    function withdraw(uint256 _amount) external;
    function emergencyWithdraw() external;
    function emergencyRecover() external;
}