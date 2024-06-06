/**
 *Submitted for verification at Arbiscan.io on 2024-06-06
*/

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

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IMultiplier {
    /**
     * Applies a multiplier on the _amount, based on the _pool and _beneficiary.
     * The multiplier is not necessarily a constant number, it can be a more complex factor.
     */
    function applyMultiplier(uint256 _amount, uint256 _duration) external view returns (uint256);

    function getMultiplier(uint256 _amount, uint256 _duration) external view returns (uint256);

    function getDurationGroup(uint256 _duration) external view returns (uint256);

    function getDurationMultiplier(uint256 _duration) external view returns (uint256);
}

interface IPenaltyFee {
    /**
     * Calculates the penalty fee for the given _amount for a specific _beneficiary.
     */
    function calculate(
        uint256 _amount,
        uint256 _duration,
        address _pool
    ) external view returns (uint256);
}

interface IStakingPool {
    struct StakingInfo {
        uint256 stakedAmount; // amount of the stake
        uint256 minimumStakeTimestamp; // timestamp of the minimum stake
        uint256 duration; // in seconds
        uint256 rewardPerTokenPaid; // Reward per token paid
        uint256 rewards; // rewards to be claimed
    }

    function rewardsMultiplier() external view returns (IMultiplier);

    function penaltyFeeCalculator() external view returns (IPenaltyFee);

    event Staked(address indexed user, uint256 stakeNumber, uint256 amount);
    event Unstaked(address indexed user, uint256 stakeNumber, uint256 amount);
    event RewardPaid(address indexed user, uint256 stakeNumber, uint256 reward);
}

contract wtiaStakingPool is ReentrancyGuard, IStakingPool {
    using SafeERC20 for IERC20;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;
    uint256 public immutable rewardsTokenDecimals;

    IMultiplier public immutable override rewardsMultiplier;
    IPenaltyFee public immutable override penaltyFeeCalculator;

    address public owner;

    // Duration of the rewards (in seconds)
    uint256 public rewardsDuration;
    // Timestamp of when the staking starts
    uint256 public startsAt;
    // Timestamp of when the staking ends
    uint256 public endsAt;
    // Timestamp of the reward updated
    uint256 public lastUpdateTime;
    // Reward per second (total rewards / duration)
    uint256 public rewardRatePerSec;
    // Reward per token stored
    uint256 public rewardPerTokenStored;

    bool public isPaused;

    // Total staked
    uint256 public totalRewards;
    // Raw amount staked by all users
    uint256 public totalStaked;
    // Total staked with each user multiplier applied
    uint256 public totalWeightedStake;
    // User address => array of the staking info
    mapping(address => StakingInfo[]) public userStakingInfo;

    // it has to be evaluated on a user basis

    enum StakeTimeOptions {
        Duration,
        EndTime
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    event TokenRecovered(address token, uint256 amount);

    constructor(
        address _stakingToken,
        address _rewardToken,
        uint256 _rewardsTokenDecimals,
        address _multiplier,
        address _penaltyFeeCalculator
    ) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardToken);
        rewardsTokenDecimals = _rewardsTokenDecimals;
        rewardsMultiplier = IMultiplier(_multiplier);
        penaltyFeeCalculator = IPenaltyFee(_penaltyFeeCalculator);
    }

    /* ========== VIEWS ========== */

    /**
     * Calculates how much rewards a user has earned up to current block, every time the user stakes/unstakes/withdraw.
     * We update "rewards[_user]" with how much they are entitled to, up to current block.
     * Next time we calculate how much they earned since last update and accumulate on rewards[_user].
     */
    function getUserRewards(address _user, uint256 _stakeNumber) public view returns (uint256) {
        uint256 weightedAmount = rewardsMultiplier.applyMultiplier(
            userStakingInfo[_user][_stakeNumber].stakedAmount,
            userStakingInfo[_user][_stakeNumber].duration
        );
        uint256 rewardsSinceLastUpdate = ((weightedAmount * (rewardPerToken() - userStakingInfo[_user][_stakeNumber].rewardPerTokenPaid)) /
            (100**rewardsTokenDecimals));
        return rewardsSinceLastUpdate + userStakingInfo[_user][_stakeNumber].rewards;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < endsAt ? block.timestamp : endsAt;
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerTokenStored;
        }
        uint256 howLongSinceLastTime = lastTimeRewardApplicable() - lastUpdateTime;
        return rewardPerTokenStored + ((rewardRatePerSec * howLongSinceLastTime * (100**rewardsTokenDecimals)) / totalWeightedStake);
    }

    function getUserStakes(address _user) external view returns (StakingInfo[] memory) {
        return userStakingInfo[_user];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _updateReward(address _user, uint256 _stakeNumber) private {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_user != address(0)) {
            userStakingInfo[_user][_stakeNumber].rewards = getUserRewards(_user, _stakeNumber);
            userStakingInfo[_user][_stakeNumber].rewardPerTokenPaid = rewardPerTokenStored;
        }
    }

    function stake(
        uint256 _amount,
        StakeTimeOptions _stakeTimeOption,
        uint256 _unstakeTime
    ) external nonReentrant inProgress {
        require(_amount > 0, "TrestleStakingPool::stake: amount = 0");
        uint256 _minimumStakeTimestamp = _stakeTimeOption == StakeTimeOptions.Duration ? block.timestamp + _unstakeTime : _unstakeTime;
        require(_minimumStakeTimestamp > startsAt, "TrestleStakingPool::stake: _minimumStakeTimestamp <= startsAt");
        require(_minimumStakeTimestamp > block.timestamp, "TrestleStakingPool::stake: _minimumStakeTimestamp <= block.timestamp");

        uint256 _stakeDuration = _minimumStakeTimestamp - block.timestamp;

        _updateReward(address(0), 0);
        StakingInfo memory _stakingInfo = StakingInfo({
            stakedAmount: _amount,
            minimumStakeTimestamp: _minimumStakeTimestamp,
            duration: _stakeDuration,
            rewardPerTokenPaid: rewardPerTokenStored,
            rewards: 0
        });
        userStakingInfo[msg.sender].push(_stakingInfo);

        uint256 _stakeNumber = userStakingInfo[msg.sender].length - 1;

        uint256 weightedStake = rewardsMultiplier.applyMultiplier(_amount, _stakeDuration);
        totalWeightedStake += weightedStake;
        totalStaked += _amount;

        stakingToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _stakeNumber, _amount);
    }

    function unstake(uint256 _amount, uint256 _stakeNumber) external nonReentrant {
        require(_amount > 0, "TrestleStakingPool::unstake: amount = 0");
        require(_amount <= userStakingInfo[msg.sender][_stakeNumber].stakedAmount, "TrestleStakingPool::unstake: not enough balance");

        _updateReward(msg.sender, _stakeNumber);

        uint256 currentWeightedStake = rewardsMultiplier.applyMultiplier(
            userStakingInfo[msg.sender][_stakeNumber].stakedAmount,
            userStakingInfo[msg.sender][_stakeNumber].duration
        );
        totalWeightedStake -= currentWeightedStake;
        totalStaked -= _amount;

        uint256 penaltyFee = 0;
        if (block.timestamp < userStakingInfo[msg.sender][_stakeNumber].minimumStakeTimestamp) {
            penaltyFee = penaltyFeeCalculator.calculate(_amount, userStakingInfo[msg.sender][_stakeNumber].duration, address(this));
            if (penaltyFee > _amount) {
                penaltyFee = _amount;
            }
        }

        userStakingInfo[msg.sender][_stakeNumber].stakedAmount -= _amount;

        if (userStakingInfo[msg.sender][_stakeNumber].stakedAmount == 0) {
            _claimRewards(msg.sender, _stakeNumber);
            // remove the staking info from array
            userStakingInfo[msg.sender][_stakeNumber] = userStakingInfo[msg.sender][userStakingInfo[msg.sender].length - 1];
            userStakingInfo[msg.sender].pop();
        } else {
            // update the weighted stake
            uint256 newWeightedStake = rewardsMultiplier.applyMultiplier(
                userStakingInfo[msg.sender][_stakeNumber].stakedAmount,
                userStakingInfo[msg.sender][_stakeNumber].duration
            );
            totalWeightedStake += newWeightedStake;
        }

        if (penaltyFee > 0) {
            stakingToken.safeTransfer(BURN_ADDRESS, penaltyFee);
            _amount -= penaltyFee;
        }
        stakingToken.safeTransfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _stakeNumber, _amount);
    }

    function _claimRewards(address _user, uint256 _stakeNumber) private {
        uint256 reward = userStakingInfo[_user][_stakeNumber].rewards;

        if (reward > 0) {
            userStakingInfo[_user][_stakeNumber].rewards = 0;
            rewardsToken.safeTransfer(_user, reward);
            emit RewardPaid(_user, _stakeNumber, reward);
        }
    }

    function claimRewards(uint256 _stakeNumber) external nonReentrant {
        _updateReward(msg.sender, _stakeNumber);
        _claimRewards(msg.sender, _stakeNumber);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function initializeStaking(
        uint256 _startsAt,
        uint256 _rewardsDuration,
        uint256 _amount
    ) external nonReentrant onlyOwner {
        require(_startsAt > block.timestamp, "TrestleStakingPool::initializeStaking: _startsAt must be in the future");
        require(_rewardsDuration > 0, "TrestleStakingPool::initializeStaking: _rewardsDuration = 0");
        require(_amount > 0, "TrestleStakingPool::initializeStaking: _amount = 0");
        require(startsAt == 0, "TrestleStakingPool::initializeStaking: staking already started");

        _updateReward(address(0), 0);

        rewardsDuration = _rewardsDuration;
        startsAt = _startsAt;
        endsAt = _startsAt + _rewardsDuration;

        // add the amount to the pool
        uint256 initialAmount = rewardsToken.balanceOf(address(this));
        rewardsToken.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 actualAmount = rewardsToken.balanceOf(address(this)) - initialAmount;
        totalRewards = actualAmount;
        rewardRatePerSec = actualAmount / _rewardsDuration;

        // set the staking to in progress
        isPaused = false;
    }

    function resumeStaking() external onlyOwner {
        require(rewardRatePerSec > 0, "TrestleStakingPool::startStaking: reward rate = 0");
        require(isPaused, "TrestleStakingPool::startStaking: staking already started");
        isPaused = false;
    }

    function pauseStaking() external onlyOwner {
        require(!isPaused, "TrestleStakingPool::pauseStaking: staking already paused");
        isPaused = true;
    }

    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IERC20(tokenAddress).safeTransfer(owner, tokenAmount);
        emit TokenRecovered(tokenAddress, tokenAmount);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        address currentOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(currentOwner, _newOwner);
    }

    /* ========== MODIFIERS ========== */

    modifier inProgress() {
        require(!isPaused, "TrestleStakingPool::initialized: staking is paused");
        require(startsAt <= block.timestamp, "TrestleStakingPool::initialized: staking has not started yet");
        require(endsAt > block.timestamp, "TrestleStakingPool::notFinished: staking has finished");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "TrestleStakingPool::onlyOwner: not authorized");
        _;
    }
}