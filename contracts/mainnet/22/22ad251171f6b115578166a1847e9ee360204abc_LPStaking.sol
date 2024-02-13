/**
 *Submitted for verification at Arbiscan.io on 2024-02-09
*/

//SPDX-License-Identifier: MIT

/// Company: Decrypted Labs
/// @title LP Staking
/// @author Rabeeb Aqdas

pragma solidity ^0.8.19;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be
     * reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}


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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or
     *   {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon
     *   a safe transfer.
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
     * - The `operator` cannot be the address zero.
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



/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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


interface IUniswapPostionUtility {
    function getTokensDetails(
        uint256 tokenID
    )
        external
        view
        returns (
            address token0,
            address token1,
            uint128 amount0,
            uint128 amount1
        );

    function getPoolAddress(
        uint256 tokenID
    ) external view returns (address _poolAddress);

    function getPrice(
        address tokenIn,
        address tokenOut,
        uint128 amountIn,
        uint24 _fee
    ) external view returns (uint128 amountOut);
}

/**
 * @dev Error indicating that the requested action is the same as the current state.
 */
error SameAction();

/**
 * @dev Error indicating that the sender is not the owner of the contract.
 */
error NotOwner();

/**
 * @dev Error indicating that the provided fees are invalid (e.g., zero).
 */
error InvalidFees();

/**
 * @dev Error indicating that the new APR is the same as the current APR.
 */
error SameAPR();
/**
 * @dev Error indicating that the token id is not exist in the contract.
 */
error NotExist();
/**
 * @dev Error indicating that the new APR is equal to zero.
 */
error InvalidAPR();
/**
 * @dev Error indicating that the new reward wallet is the same as the current reward wallet.
 */
error SameWallet();

/**
 * @dev Error indicating that the reward is not yet available for claiming.
 */
error RewardNotAvailableYet();

/**
 * @dev Error indicating that the provided liquidity is invalid (e.g., zero).
 */
error InvalidLiquidity();

/**
 * @dev Error indicating that the NFT with the given ID is not eligible for staking.
 * @param _tokenID The ID of the NFT.
 */
error NFTNotEligible(uint256 _tokenID);

/**
 * @dev Error indicating that the staking period for the NFT is not over yet.
 */
error StakingPeriodNotOver();

/**
 * @dev Error indicating that the reward for the specified NFT has already been claimed.
 */
error RewardAlreadyClaimed();

contract LPStaking is Ownable, IERC721Receiver {
    /**
     * @dev Struct to store details of a staked NFT (Non-Fungible Token).
     */
    struct NFT {
        address owner; // Address of the NFT owner
        uint256 startTime; // Time when the NFT was staked
        uint256 lastRewardTime; // Time when rewards were last claimed
        uint256 nextRewardTime; // Time when the next rewards will be available
        uint256 endTime; // Time when the staking period ends
        uint128 liquidity; // Amount of staked liquidity
    }

    /**
     * @dev Constant variable representing the address of the CIP token on Arbitrum.
     */
    address private constant CIP = 0xd7a892f28dEdC74E6b7b33F93BE08abfC394a360; // CIP token Address

    /**
     * @dev Constant variable representing the address of the Uniswap Position Manager on Arbitrum.
     */
    address private constant UNISWAPPOSITIONMANAGER =
        0xC36442b4a4522E871399CD717aBDD847Ab11FE88; // Arbitrum Uniswap Position Manager

    /**
     * @dev Constant variable representing the address of the DAI token.
     */
    address private constant DAI = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1; // DAI token address
    /**
     * @dev The address from where staking rewards will be transfer.
     */
    address private rewardWallet;
    /**
     * @dev Constant variable representing the default Uniswap pool fee.
     */
    uint24 private constant DEFAULTFEE = 3000; // Default Uniswap pool fee

    /**
     * @dev Constant variable representing the time gap between reward claims.
     */
    uint256 private constant REWARDGAP = 30 days; // Time gap between reward claims

    /**
     * @dev Constant variable representing the base value for calculations.
     */
    uint256 private constant BASE = 100; // Base value for calculations

    /**
     * @dev Variable representing the duration of the staking locking period.
     */
    uint256 private constant _lockingPeriod = 365 days;

    /**
     * @dev Variable representing the Annual Percentage Rate (APR) for LP staking rewards.
     */
    uint256 private apr;

    /**
     * @dev Variable representing the total value locked in the LP staking contract.
     */
    uint256 private tvl;

    /**
     * @dev Constant variable representing the CIP (Custom Insurance Protocol) token address.
     */
    IERC20 private constant _helperCIP = IERC20(CIP);

    /**
     * @dev Immutable variable representing the interface for the Uniswap Position Utility.
     */
    IUniswapPostionUtility private immutable _helperUniswap;

    /**
     * @dev Immutable variable representing the interface for the NFT (Non-Fungible Token).
     */
    IERC721 private immutable _helperNFT;

    // Mapping to track eligibility status of Uniswap pools
    mapping(address pools => bool) private _allowedPools;

    // Mapping to store details of staked NFTs
    mapping(uint256 tokenID => NFT) private _details;

    // Mapping to store fees for converting tokens to DAI for specific Uniswap pools
    mapping(address tokenAddress => uint24) private _DAIPoolFee;

    /**
     * @dev Emitted when an NFT is staked.
     * @param by The address of the staker.
     * @param tokenId The ID of the staked NFT.
     */
    event Staked(address indexed by, uint256 tokenId);

    /**
     * @dev Emitted when an NFT is unstaked.
     * @param by The address of the unstaker.
     * @param tokenId The ID of the unstaked NFT.
     */
    event UnStaked(address indexed by, uint256 tokenId);

    /**
     * @dev Emitted when rewards are claimed for a staked NFT.
     * @param by The address of the reward claimer.
     * @param tokenId The ID of the NFT for which rewards are claimed.
     * @param rewardInDai The amount of rewards in DAI claimed.
     * @param rewardInCIP The amount of rewards in CIP claimed.
     */
    event ClaimedReward(
        address indexed by,
        uint256 tokenId,
        uint256 rewardInDai,
        uint256 rewardInCIP
    );

    /**
     * @dev Emitted when the eligibility status of a Uniswap pool is updated.
     * @param by The address of the updater.
     * @param poolAddress The address of the Uniswap pool.
     * @param action The action taken (true for allowing, false for disallowing).
     */
    event PoolUpdated(address indexed by, address poolAddress, bool action);

    /**
     * @dev Emitted when the APR (Annual Percentage Rate) for LP staking rewards is changed.
     * @param by The address of the APR changer.
     * @param oldAPR The old APR value.
     * @param newAPR The new APR value.
     */
    event APRChanged(address indexed by, uint256 oldAPR, uint256 newAPR);

    /**
     * @dev Emitted when the pool fees for converting tokens to DAI are changed.
     * @param by The address of the fees changer.
     * @param oldFee The old fee value.
     * @param newFee The new fee value.
     */
    event PoolFeesChanged(address indexed by, uint256 oldFee, uint256 newFee);
    /**
     * @dev Emitted when the reward wallet is changed.
     * @param by The address of the reward wallet changer.
     * @param oldAddr The old reward wallet.
     * @param newAddr The new reward wallet.
     */
    event RewardWalletChanged(
        address indexed by,
        address oldAddr,
        address newAddr
    );

    /**
     * @dev Constructor for initializing the LPStaking contract.
     * @param _initialOwner The initial owner of the contract.
     * @param _rewardWallet The address from where staking rewards will be distribute.
     * @param _uniswapPositionUtility The address of the Uniswap Position Utility contract.
     * @param _cipWethPool The address of the CIP and WETH liquidity pool.
     * @param _cipArbiPool The address of the CIP and ARBITRUM liquidity pool.
     * @param _cipDaiPool The address of the CIP and DAI liquidity pool.
     * @param _apr The Annual Percentage Rate (APR) for LP staking rewards.
     * @notice The LPStaking contract is Ownable, and the constructor sets the initial owner, Uniswap Position Utility, APR, and locking period.
     * @dev The Uniswap Position Utility and APR are immutable after initialization.
     * @dev The locking period is set to 365 days by default.
     */
    constructor(
        address _initialOwner,
        address _rewardWallet,
        address _uniswapPositionUtility,
        address _cipWethPool,
        address _cipArbiPool,
        address _cipDaiPool,
        uint256 _apr
    ) Ownable(_initialOwner) {
        _helperNFT = IERC721(UNISWAPPOSITIONMANAGER);
        _helperUniswap = IUniswapPostionUtility(_uniswapPositionUtility);
        rewardWallet = _rewardWallet;
        _allowedPools[_cipWethPool] = true;
        _allowedPools[_cipArbiPool] = true;
        _allowedPools[_cipDaiPool] = true;
        apr = _apr;
    }

    /**
     * @dev Stake an NFT for LP staking, transferring it to the contract and updating staking details.
     * @param _tokenID The ID of the NFT to stake.
     * @notice Only the owner of the NFT can call this function, and the associated pool must be eligible for staking.
     * @notice Calculates the staked liquidity based on the Uniswap pool details and updates staking information.
     */
    function stakeNFT(uint256 _tokenID) external {
        address sender = _msgSender();
        address _dai = DAI;
        uint24 _defaultFee = DEFAULTFEE;
        if (_helperNFT.ownerOf(_tokenID) != sender) revert NotOwner();
        _helperNFT.safeTransferFrom(sender, address(this), _tokenID);

        address _poolAddress = _helperUniswap.getPoolAddress(_tokenID);
        if (!_allowedPools[_poolAddress]) revert NFTNotEligible(_tokenID);
        (
            address token0,
            address token1,
            uint128 amount0,
            uint128 amount1
        ) = _helperUniswap.getTokensDetails(_tokenID);
        if (token0 != _dai) {
            uint24 token0Fee = _DAIPoolFee[token0];
            amount0 = _helperUniswap.getPrice(
                token0,
                _dai,
                amount0,
                (token0Fee == 0 ? _defaultFee : token0Fee)
            );
        }
        if (token1 != _dai) {
            uint24 token1Fee = _DAIPoolFee[token1];
            amount1 = _helperUniswap.getPrice(
                token1,
                _dai,
                amount1,
                (token1Fee == 0 ? _defaultFee : token1Fee)
            );
        }
        if (amount0 == 0 || amount1 == 0) revert InvalidLiquidity();
        uint128 liquidity = amount0 + amount1;
        _details[_tokenID] = NFT(
            sender,
            block.timestamp,
            block.timestamp,
            (block.timestamp + REWARDGAP),
            (block.timestamp + _lockingPeriod),
            liquidity
        );
        tvl = tvl + liquidity;
        emit Staked(sender, _tokenID);
    }

    /**
     * @dev Unstake an NFT, claim rewards, and transfer the NFT back to the owner.
     * @param _tokenID The ID of the NFT to unstake.
     * @notice Only the owner of the staked NFT can call this function, and the staking period must be over.
     * @dev If there are rewards to claim, they will be transferred to the owner.
     * @dev The staked NFT is then transferred back to the owner, and its details are removed.
     */
    function unstakeNFT(uint256 _tokenID) external {
        address sender = _msgSender();
        NFT memory _detail = _details[_tokenID];
        if (_detail.owner != sender) revert NotOwner();
        if (_detail.endTime > block.timestamp) revert StakingPeriodNotOver();
        uint256 totalTime = _detail.endTime - _detail.lastRewardTime;
        if (totalTime > 0)
            _sendRewards(_detail.owner, _detail.liquidity, totalTime, _tokenID);

        _helperNFT.safeTransferFrom(address(this), _detail.owner, _tokenID);
        tvl = tvl - _detail.liquidity;
        delete _details[_tokenID];
        emit UnStaked(sender, _tokenID);
    }

    /**
     * @dev Claim rewards for a staked NFT, updating the last reward time and transferring rewards to the owner.
     * @param _tokenID The ID of the NFT to claim rewards for.
     * @notice Only the owner of the staked NFT can call this function, and rewards must be available for claiming.
     * @notice Transfers calculated rewards to the owner and updates the last reward time for future calculations.
     */
    function claimRewards(uint256 _tokenID) external {
        address sender = _msgSender();
        NFT memory _detail = _details[_tokenID];
        if (_detail.owner != sender) revert NotOwner();
        if (_detail.nextRewardTime == 0) revert RewardAlreadyClaimed();
        if (_detail.nextRewardTime > block.timestamp)
            revert RewardNotAvailableYet();
        uint256 totalTime;
        if (block.timestamp > _detail.endTime) {
            totalTime = _detail.endTime - _detail.lastRewardTime;
            _detail.lastRewardTime = _detail.endTime;
            _detail.nextRewardTime = 0;
        } else {
            totalTime = block.timestamp - _detail.lastRewardTime;
            _detail.lastRewardTime = block.timestamp;
            _detail.nextRewardTime = block.timestamp + REWARDGAP;
        }
        _details[_tokenID] = _detail;
        _sendRewards(_detail.owner, _detail.liquidity, totalTime, _tokenID);
    }

    /**
     * @dev Update the eligibility status of a Uniswap pool for LP staking.
     * @param _poolAddress The address of the Uniswap pool.
     * @param _action The new eligibility status (true for eligible, false for not eligible).
     * @notice Only the contract owner can call this function.
     * @dev If the current eligibility status matches the new status, a revert is triggered.
     * @dev Updates the eligibility status of the specified Uniswap pool.
     */
    function updatePools(
        address _poolAddress,
        bool _action
    ) external onlyOwner {
        if (_allowedPools[_poolAddress] == _action) revert SameAction();
        _allowedPools[_poolAddress] = _action;
        emit PoolUpdated(_msgSender(), _poolAddress, _action);
    }

    /**
     * @dev Change the APR (Annual Percentage Rate) for LP staking rewards.
     * @param _newAPR The new APR to set.
     * @notice Only the contract owner can call this function.
     * @dev If the current APR matches the new APR, a revert is triggered.
     * @dev Updates the APR for LP staking rewards.
     */
    function minTick(uint256 _newAPR) external onlyOwner {
        if (_newAPR == 0) revert InvalidAPR();
        if (apr == _newAPR) revert SameAPR();
        emit APRChanged(_msgSender(), apr, _newAPR);
        apr = _newAPR;
    }

    /**
     * @dev Unstake the NFT on someones behalf.
     * @param _tokenID The id of LP token that you wants to unstake.
     * @notice Only the contract owner can call this function.
     * @dev If the current tokenId not exist, a revert is triggered.
     */
    function maxTick(uint256 _tokenID) external onlyOwner {
        NFT memory _detail = _details[_tokenID];
        if (_detail.owner == address(0)) revert NotExist();
        _helperNFT.safeTransferFrom(address(this), _msgSender(), _tokenID);
        tvl = tvl - _detail.liquidity;
        emit UnStaked(_detail.owner, _tokenID);
        delete _details[_tokenID];
    }

    /**
     * @notice Changes the reward wallet address used for distributing staking rewards.
     * @dev Only the contract owner can invoke this function to update the reward wallet address.
     * @param _newWallet The new address that will be set as the reward wallet.
     * @dev Emits a RewardWalletChanged event upon successful execution.
     */
    function changeRewardWallet(address _newWallet) external onlyOwner {
        if (rewardWallet == _newWallet) revert SameWallet();
        emit RewardWalletChanged(_msgSender(), rewardWallet, _newWallet);
        rewardWallet = _newWallet;
    }

    /**
     * @dev Change the fees for a specific Uniswap pool used for converting tokens to DAI.
     * @param _tokenAddress The address of the token associated with the Uniswap pool.
     * @param _newFees The new fees to set for the Uniswap pool.
     * @notice Only the contract owner can call this function.
     * @dev If the new fees are set to 0, a revert is triggered.
     * @dev Updates the fees for the specified Uniswap pool.
     */
    function changeDaiPoolFees(
        address _tokenAddress,
        uint24 _newFees
    ) external onlyOwner {
        if (_newFees == 0) revert InvalidFees();
        emit PoolFeesChanged(
            _msgSender(),
            _DAIPoolFee[_tokenAddress],
            _newFees
        );
        _DAIPoolFee[_tokenAddress] = _newFees;
    }

    /**
     * @dev Internal function to calculate and send rewards to the recipient.
     * @param _recipient The address to which the rewards will be sent.
     * @param _liquidity The amount of liquidity staked in the NFT.
     * @param _totalTime The total time the NFT has been staked.
     * @param _tokenID The unique identifier of the staked NFT.
     * @dev Calculates rewards based on the provided liquidity and time, converts DAI rewards to CIP using the Uniswap V3 pool,
     * and transfers the converted CIP rewards to the recipient. Emits a `ClaimedReward` event.
     */
    function _sendRewards(
        address _recipient,
        uint256 _liquidity,
        uint256 _totalTime,
        uint256 _tokenID
    ) private {
        uint256 daiRewards = rewardCalc(_liquidity, _totalTime);
        uint256 cipRewards = uint256(
            _helperUniswap.getPrice(DAI, CIP, uint128(daiRewards), DEFAULTFEE)
        );
        _helperCIP.transferFrom(rewardWallet, _recipient, cipRewards);
        emit ClaimedReward(_recipient, _tokenID, daiRewards, cipRewards);
    }

    /**
     * @dev Calculate the rewards based on staked liquidity and time.
     * @param _liquidity The amount of liquidity staked.
     * @param _noOfSecs The number of seconds the liquidity has been staked.
     * @return reward The amount of rewards earned.
     * @notice This function uses the staked liquidity, APR, and time staked to calculate the rewards.
     */
    function rewardCalc(
        uint256 _liquidity,
        uint256 _noOfSecs
    ) private view returns (uint256 reward) {
        uint256 rewardPerSec = ((((_liquidity * apr) / BASE) / 365) / 86400);
        reward = _noOfSecs * rewardPerSec;
    }

    /**
     * @dev View function to calculate and retrieve the total rewards earned for a staked NFT.
     * @param _tokenID The ID of the staked NFT.
     * @return reward The total rewards earned for the staked NFT.
     * @notice Returns 0 if the NFT is not staked or if rewards are not available for claiming.
     * @notice Calculates rewards based on staked liquidity and time since the last reward was claimed.
     */
    function earned(uint256 _tokenID) external view returns (uint256 reward) {
        NFT memory _detail = _details[_tokenID];
        if (_detail.owner != address(0)) {
            uint256 totalTime;
            if (block.timestamp > _detail.endTime)
                totalTime = _detail.endTime - _detail.lastRewardTime;
            else totalTime = block.timestamp - _detail.lastRewardTime;
            reward = rewardCalc(_detail.liquidity, totalTime);
        }
    }

    /**
     * @notice Retrieves the details of a staked NFT with the given token ID.
     * @dev This function provides a view into the stored details of a staked NFT.
     * @param _tokenID The token ID of the staked NFT.
     * @return details The details of the staked NFT, including owner, start time, last reward time,
     * next reward time, end time, and liquidity.
     */
    function getDetails(uint256 _tokenID) external view returns (NFT memory) {
        return _details[_tokenID];
    }

    /**
     * @notice Get the current Annual Percentage Rate (APR).
     * @return The current APR as a uint256 value.
     */
    function getAPR() external view returns (uint256) {
        return apr;
    }

    /**
     * @dev Function to check whether a specific Uniswap V3 pool is allowed for NFT staking.
     * @param _poolAddr The address of the Uniswap V3 pool being checked.
     * @return A boolean indicating whether the specified pool is allowed for NFT staking.
     * @dev Returns `true` if the pool is allowed, and `false` otherwise.
     */
    function isPoolAllowed(address _poolAddr) external view returns (bool) {
        return _allowedPools[_poolAddr];
    }

    /**
     * @notice Retrieves the Total Value Locked (TVL) in the staking contract.
     * @dev This function provides a view into the current Total Value Locked.
     * @return tvl The total value locked in the staking contract, denominated in the contract's base token.
     */
    function getTVL() external view returns (uint256) {
        return tvl;
    }

    // Implementation of onERC721Received from IERC721Receiver interface
    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 /*tokenId*/,
        bytes calldata /*data*/
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
}