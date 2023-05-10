/**
 *Submitted for verification at Arbiscan on 2023-05-10
*/

// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.13;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    function decimals() external view returns (uint8);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
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
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

contract PEPEStaking is Ownable {
    address public rewardTokenAddress =
        0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    address public nftCollectionAddress =
        0x427758eA93Bcc241C73C853EA649929E5a48a19B;

    // wallet has reward tokens.
    address tokenHolderAddress = 0x29fbE94b404dA4dEF4690bE5D523bFB08c925FC0;

    // Staker info
    struct Staker {
        // Last time of details update for this User
        uint256 lastTimeUpdate;
        // Calculated, but unclaimed rewards for the User. The rewards are
        // calculated each time the user writes to the Smart Contract
        uint256 unclaimedRewards;
        // token list of staker
        uint256[] stakedTokenIds;
    }

    uint256 private tokenDecimals = IERC20(rewardTokenAddress).decimals();

    // = x => x token/nft per day
    // (1 * 10**tokenDecimals) / 1 = 1 token
    // (1 * 10**tokenDecimals) / 10 = 0.1 token
    uint256 public rewardsPerDay =
        (1 * 10**tokenDecimals) / 1; // 1 token or usdt

    uint256 public totalReward =
        225_000 * 10**tokenDecimals; //100 token or usdt

    uint256 public deadline = block.timestamp + 10 * 24 * 3600; //30 days

    // user can only claim if his rewards greater than minRewardToClaim
    uint256 public minRewardToClaim =
        5 * 10**tokenDecimals; // 5 token

    uint256 public totalClaimedReward = 0; // dont change

    uint256 public totalStakedToken = 0; // dont change

    // Mapping of User Address to Staker info
    mapping(address => Staker) public stakers;
    mapping(uint256 => uint256) public dailyRewards;

    // Constructor function
    constructor() {}

    function _state(uint256 _date)
        external
        view
        returns (
            address _rewardTokenAddress,
            address _nftCollectionAddress,
            address _tokenHolderAddress,
            uint256 _rewardsPerDay,
            uint256 _totalReward,
            uint256 _totalClaimedReward,
            uint256 _deadline,
            uint256 _dailyReward
        )
    {
        uint256 dailyReward = dailyRewards[_date];
        return (
            rewardTokenAddress,
            nftCollectionAddress,
            tokenHolderAddress,
            rewardsPerDay,
            totalReward,
            totalClaimedReward,
            deadline,
            dailyReward
        );
    }

    // If address already has ERC721 Token/s staked, calculate the rewards.
    // For every new Token Id in param transferFrom user to this Smart Contract,
    // increment the amountStaked and map msg.sender to the Token Id of the staked
    // Token to later send back on withdrawal. Finally give lastTimeUpdate the
    // value of now.
    function stake(uint256[] calldata _tokenIds) external {
        require(deadline > block.timestamp, "Finished");
        require(totalReward > totalClaimedReward, "Out of token");
        require(_tokenIds.length > 0, "At least one nft");
        require(
            IERC721(nftCollectionAddress).ownerOf(_tokenIds[0]) == msg.sender,
            "At least one nft"
        );
        if (stakers[msg.sender].stakedTokenIds.length > 0) {
            uint256 rewards = _calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
        }
        uint256 len = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (
                IERC721(nftCollectionAddress).ownerOf(_tokenIds[i]) ==
                msg.sender
            ) {
                IERC721(nftCollectionAddress).transferFrom(
                    msg.sender,
                    address(this),
                    _tokenIds[i]
                );
                stakers[msg.sender].stakedTokenIds.push(_tokenIds[i]);
                totalStakedToken++;
                len++;
            }
        }
        stakers[msg.sender].lastTimeUpdate = len > 0
            ? block.timestamp
            : _calculateLastTime(stakers[msg.sender].lastTimeUpdate);
    }

    // Check if user has any ERC721 Tokens Staked and if he tried to withdraw,
    // calculate the rewards and store them in the unclaimedRewards and for each
    // ERC721 Token in param: check if msg.sender is the original staker, decrement
    // the amountStaked of the user and transfer the ERC721 token back to them
    function withdraw(uint256[] calldata _tokenIds) external {
        require(
            stakers[msg.sender].stakedTokenIds.length > 0,
            "Not staked nft"
        );

        uint256 len = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC721(nftCollectionAddress).transferFrom(
                address(this),
                msg.sender,
                _tokenIds[i]
            );
            removeElement(stakers[msg.sender].stakedTokenIds, _tokenIds[i]);
            len++;
        }
        if (len > 0) {
            uint256 rewards = _calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
            stakers[msg.sender].lastTimeUpdate = _calculateLastTime(
                stakers[msg.sender].lastTimeUpdate
            );
            totalStakedToken = totalStakedToken >= len
                ? totalStakedToken - len
                : 0;
        }
    }

    // Calculate rewards for the msg.sender, check if there are any rewards
    // claim, set unclaimedRewards to 0 and transfer the ERC20 Reward token
    // to the user.
    function claimRewards(uint256 _date) external {
        require(totalReward > totalClaimedReward, "Out of reward token");
        uint256 rewards = _calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;

        require(
            rewards >= minRewardToClaim,
            "Rewards is less than the minimum required to claim"
        );
        require(rewards > 0, "Not rewards");
        if (totalClaimedReward + rewards > totalReward) {
            rewards = totalReward - totalClaimedReward;
        }
        require(
            IERC20(rewardTokenAddress).allowance(
                tokenHolderAddress,
                address(this)
            ) >= rewards,
            "Token holder not allowance"
        );
        stakers[msg.sender].lastTimeUpdate = _calculateLastTime(
            stakers[msg.sender].lastTimeUpdate
        );
        stakers[msg.sender].unclaimedRewards = 0;
        IERC20(rewardTokenAddress).transferFrom(
            tokenHolderAddress,
            msg.sender,
            rewards
        );
        totalClaimedReward += rewards;
        dailyRewards[_date] += rewards;
    }

    function removeElement(uint256[] storage _array, uint256 _element)
        internal
    {
        for (uint256 i; i < _array.length; i++) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }

    //////////
    // View //
    //////////

    function userStakeInfo(address _user)
        public
        view
        returns (Staker memory, uint256 rewards)
    {
        return (stakers[_user], _availableRewards(_user));
    }

    function _availableRewards(address _user) internal view returns (uint256) {
        uint256 rewards = stakers[_user].unclaimedRewards +
            _calculateRewards(_user);
        return rewards;
    }

    /////////////
    // Internal//
    /////////////

    // Calculate rewards for param _staker by calculating the time passed
    // since last update in hours and mulitplying it to ERC721 Tokens Staked
    // and rewardsPerHour.
    function _calculateRewards(address _staker)
        internal
        view
        returns (uint256)
    {
        if (
            stakers[_staker].stakedTokenIds.length <= 0 ||
            block.timestamp < stakers[_staker].lastTimeUpdate
        ) {
            return 0;
        }
        uint256 rewardBlock = (block.timestamp -
            stakers[_staker].lastTimeUpdate) / (24 * 3600);
        uint256 rewards = rewardBlock *
            stakers[_staker].stakedTokenIds.length *
            rewardsPerDay;
        return rewards;
    }

    function _calculateLastTime(uint256 _lastTime)
        internal
        view
        returns (uint256)
    {
        uint256 rewardBlock = (block.timestamp - _lastTime) / (24 * 3600);
        return
            _lastTime + rewardBlock * 24 * 3600 > block.timestamp
                ? block.timestamp
                : _lastTime + rewardBlock * 24 * 3600;
    }

    //_rewardsPerDay = 1, _denominator = 10 => 0.1 token
    //_rewardsPerDay = 1, _denominator = 100 => 0.01 token
    function setRewardsPerDay(uint256 _rewardsPerDay, uint256 _denominator)
        public
        onlyOwner
    {
        rewardsPerDay =
            (_rewardsPerDay * 10**tokenDecimals) /
            _denominator;
    }

    function increaseTotalReward(uint256 _addition) public onlyOwner {
        require(_addition < 100000, "less than 100000");
        totalReward += _addition * 10**tokenDecimals;
    }

    function decreaseTotalReward(uint256 _reduce) public onlyOwner {
        if (
            totalReward >
            totalClaimedReward +
                _reduce *
                10**tokenDecimals
        ) {
            totalReward -= _reduce * 10**tokenDecimals;
        } else {
            totalReward = totalClaimedReward;
        }
    }

    function increaseDeadline(uint256 _additionDay) public onlyOwner {
        deadline += _additionDay * 24 * 3600;
    }

    function decreaseDeadline(uint256 _reduceDay) public onlyOwner {
        if (deadline > _reduceDay * 24 * 3600) {
            deadline = deadline - _reduceDay * 24 * 3600;
        }
    }

    function setTokenHolderAddress(address _tokenHolderAddress)
        public
        onlyOwner
    {
        tokenHolderAddress = _tokenHolderAddress;
    }

    function setLastTimeUpdate(address _staker, uint256 _lastTimeUpdate)
        public
        onlyOwner
    {
        stakers[_staker].lastTimeUpdate = _lastTimeUpdate;
    }
}