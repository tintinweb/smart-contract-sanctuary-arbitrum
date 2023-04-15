/**
 *Submitted for verification at Arbiscan on 2023-04-15
*/

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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/legacy/SafeAmount.sol


pragma solidity 0.8.2;


library SafeAmount {
    using SafeERC20 for IERC20;

    /**
     @notice transfer tokens from. Incorporate fee on transfer tokens
     @param token The token
     @param from From address
     @param to To address
     @param amount The amount
     @return result The actual amount transferred
     */
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount) internal returns (uint256 result) {
        uint256 preBalance = IERC20(token).balanceOf(to);
        IERC20(token).safeTransferFrom(from, to, amount);
        uint256 postBalance = IERC20(token).balanceOf(to);
        result = postBalance - preBalance;
        require(result <= amount, "SA: actual amount larger than transfer amount");
    }

    /**
     @notice Sends ETH
     @param to The to address
     @param value The amount
     */
	function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}
// File: contracts/legacy/FestakedLib.sol



pragma solidity 0.8.2;



library FestakedLib {
    using SafeERC20 for IERC20;
    event Staked(address indexed token, address indexed staker_, uint256 requestedAmount_, uint256 stakedAmount_);
    event PaidOut(address indexed token, address indexed rewardToken, address indexed staker_, uint256 amount_, uint256 reward_);

    struct FestakeState {
        uint256 stakedTotal;
        uint256 stakingCap;
        uint256 stakedBalance;
        uint256 withdrawnEarly;
        mapping(address => uint256) _stakes;
    }

    struct FestakeRewardState {
        uint256 rewardBalance;
        uint256 rewardsTotal;
        uint256 earlyWithdrawReward;
    }

    /**
     @notice Tries to stake
     @param payer The payer
     @param staker The staker
     @param amount The amount
     @param stakingStarts The staking start time
     @param stakingEnds The staking end time
     @param stakingCap The staking cap
     @param tokenAddress The token address
     @param state The staking storage state
     @return Amount staked
     */
    function tryStake(address payer, address staker, uint256 amount,
        uint256 stakingStarts,
        uint256 stakingEnds,
        uint256 stakingCap,
        address tokenAddress,
        FestakeState storage state
        )
    internal
    _after(stakingStarts)
    _before(stakingEnds)
    _positive(amount)
    returns (uint256) {
        // check the remaining amount to be staked
        // For pay per transfer tokens we limit the cap on incoming tokens for simplicity. This might
        // mean that cap may not necessary fill completely which is ok.
        uint256 remaining = amount;
        // uint256 stakedTotal = state.stakedTotal;
        {
        uint256 stakedBalance = state.stakedBalance;
        if (stakingCap > 0 && remaining > (stakingCap - stakedBalance)) {
            remaining = stakingCap - stakedBalance;
        }
        }
        // These requires are not necessary, because it will never happen, but won't hurt to double check
        // this is because stakedTotal and stakedBalance are only modified in this method during the staking period
        require(remaining > 0, "Festaking: Staking cap is filled");
        // require((remaining + stakedTotal) <= stakingCap, "Festaking: this will increase staking amount pass the cap");
        // Update remaining in case actual amount paid was different.
        remaining = _payMe(payer, remaining, tokenAddress);
        emit Staked(tokenAddress, staker, amount, remaining);

        // Transfer is completed
        return remaining;
    }

    /**
     @notice Stake some amount
     @param payer The payer
     @param staker The staker
     @param amount The amount
     @param stakingStarts The staking start time
     @param stakingEnds The staking end time
     @param stakingCap The staking cap
     @param tokenAddress The token address
     @param state The staking storage state
     */
    function stake(address payer, address staker, uint256 amount,
        uint256 stakingStarts,
        uint256 stakingEnds,
        uint256 stakingCap,
        address tokenAddress,
        FestakeState storage state
        )
    internal
    returns (bool) {
        uint256 remaining = tryStake(payer, staker, amount,
            stakingStarts, stakingEnds, stakingCap, tokenAddress, state);

        // Transfer is completed
        state.stakedBalance = state.stakedBalance + remaining;
        state.stakedTotal = state.stakedTotal + remaining;
        state._stakes[staker] = state._stakes[staker] + remaining;
        return true;
    }

    /**
     @notice Adds rewards to an stake
     @param rewardAmount The reward amount
     @param rewardTokenAddress The reward token address
     @param state The staking storage state
     */
    function addReward(
        uint256 rewardAmount,
        uint256 withdrawableAmount,
        address rewardTokenAddress,
        FestakeRewardState storage state
    )
    internal
    returns (bool) {
        require(rewardAmount != 0, "Festaking: reward must be positive");
        address from = msg.sender;
        rewardAmount = _payMe(from, rewardAmount, rewardTokenAddress);
        require(withdrawableAmount <= rewardAmount, "Festaking: withdrawable amount must be less than or equal to the reward amount");
        state.rewardsTotal = state.rewardsTotal + rewardAmount;
        state.rewardBalance = state.rewardBalance + rewardAmount;
        state.earlyWithdrawReward = state.earlyWithdrawReward + withdrawableAmount;
        return true;
    }

    /**
     @notice Adds extra tokens in the pool as rewards
     @param rewardTokenAddress The reward token address
     @param tokenAddress The token address
     @param me The stake contract address
     @param stakedBalance The staked balance
     param state The staking storage state
     */
    function addMarginalReward(
        address rewardTokenAddress,
        address tokenAddress,
        address me,
        uint256 stakedBalance,
        FestakeRewardState storage state)
        internal
        returns (bool) {
        uint256 amount = IERC20(rewardTokenAddress).balanceOf(me) - state.rewardsTotal;
        if (rewardTokenAddress == tokenAddress) {
            amount = amount - stakedBalance;
        }
        if (amount == 0) {
            return true; // No reward to add. Its ok. No need to fail callers.
        }
        state.rewardsTotal = state.rewardsTotal + amount;
        state.rewardBalance = state.rewardBalance + amount;
        return true;
    }

    /**
     @notice Tries a withdraw. And pays rewards
     @param from The staker address
     @param tokenAddress The token address
     @param rewardTokenAddress The reward token address
     @param amount The amount
     @param withdrawStarts early withdraw period
     @param withdrawEnds end of early withdraw and start of maturity
     @param stakingEnds end of staking period
     @param state The staking state
     @param rewardState The reward state
     @return The withdawn amount
     */
    function tryWithdraw(
        address from,
        address tokenAddress,
        address rewardTokenAddress,
        uint256 amount,
        uint256 withdrawStarts,
        uint256 withdrawEnds,
        uint256 stakingEnds,
        FestakeState storage state,
        FestakeRewardState storage rewardState
    )
    internal
    _after(withdrawStarts)
    _positive(amount)
    _realAddress(msg.sender)
    returns (uint256) {
        require(amount <= state._stakes[from], "Festaking: not enough balance");
        if (block.timestamp < withdrawEnds) {
            return _withdrawEarly(tokenAddress, rewardTokenAddress, from, amount, withdrawEnds,
                stakingEnds, state, rewardState);
        } else {
            return _withdrawAfterClose(tokenAddress, rewardTokenAddress, from, amount, state, rewardState);
        }
    }

    /**
     @notice Runs a withdraw. And pays rewards
     @param from The staker address
     @param tokenAddress The token address
     @param rewardTokenAddress The reward token address
     @param amount The amount
     @param withdrawStarts early withdraw period
     @param withdrawEnds end of early withdraw and start of maturity
     @param stakingEnds end of staking period
     @param state The staking state
     @param rewardState The reward state
     */
    function withdraw(
        address from,
        address tokenAddress,
        address rewardTokenAddress,
        uint256 amount,
        uint256 withdrawStarts,
        uint256 withdrawEnds,
        uint256 stakingEnds,
        FestakeState storage state,
        FestakeRewardState storage rewardState
    )
    internal
    returns (bool) {
        uint256 wdAmount = tryWithdraw(from, tokenAddress, rewardTokenAddress, amount, withdrawStarts,
            withdrawEnds, stakingEnds, state, rewardState);
        state.stakedBalance = state.stakedBalance - wdAmount;
        state._stakes[from] = state._stakes[from] - wdAmount;
        return true;
    }

    /**
     @notice Runs an early withdrawal.
     @param tokenAddress The token address
     @param rewardTokenAddress The reward token address
     @param from The staker address
     @param amount The amount
     @param withdrawEnds end of early withdraw and start of maturity
     @param stakingEnds end of staking period
     @param state The staking state
     @param rewardState The reward state
     */
    function _withdrawEarly(
        address tokenAddress,
        address rewardTokenAddress,
        address from,
        uint256 amount,
        uint256 withdrawEnds,
        uint256 stakingEnds,
        FestakeState storage state,
        FestakeRewardState storage rewardState
    )
    private
    _realAddress(from)
    returns (uint256) {
        // This is the formula to calculate reward:
        // r = (earlyWithdrawReward / stakedTotal) * (now - stakingEnds) / (withdrawEnds - stakingEnds)
        // w = (1+r) * a
        uint256 denom = (withdrawEnds - stakingEnds) * state.stakedTotal;
        uint256 reward = (
        ( (block.timestamp - stakingEnds) * rewardState.earlyWithdrawReward ) * amount
        ) / denom;
        rewardState.rewardBalance = rewardState.rewardBalance - reward;
        bool principalPaid = _payDirect(from, amount, tokenAddress);
        bool rewardPaid = _payDirect(from, reward, rewardTokenAddress);
        require(principalPaid && rewardPaid, "Festaking: error paying");
        emit PaidOut(tokenAddress, rewardTokenAddress, from, amount, reward);
        return amount;
    }

    /**
     @notice Runs a withdraw after close
     @param tokenAddress The token address
     @param rewardTokenAddress The reward token address
     @param from The staker address
     @param amount The amount
     @param state The staking state
     @param rewardState The reward state
     */
    function _withdrawAfterClose(
        address tokenAddress,
        address rewardTokenAddress,
        address from,
        uint256 amount,
        FestakeState storage state,
        FestakeRewardState storage rewardState
    ) private
    _realAddress(from)
    returns (uint256) {
        uint256 rewBal = rewardState.rewardBalance;
        uint256 reward = (rewBal * amount) / state.stakedBalance;
        rewardState.rewardBalance = rewBal - reward;
        bool principalPaid = _payDirect(from, amount, tokenAddress);
        bool rewardPaid = _payDirect(from, reward, rewardTokenAddress);
        require(principalPaid && rewardPaid, "Festaking: error paying");
        emit PaidOut(tokenAddress, rewardTokenAddress, from, amount, reward);
        return amount;
    }

    /**
     @notice Transfers money from an account to self
     @param payer The payer
     @param amount The amount
     @param token The token
     @return The transferred amount
     */
    function _payMe(address payer, uint256 amount, address token)
    internal
    returns (uint256) {
        return _payTo(payer, address(this), amount, token);
    }

    /**
    @notice Transfers tokens from owner to a receiver
    @param allower The owner of tokena
    @param receiver Ther receiver
    @param amount The amount
    @param token The token
    @return Transferred amount
     */
    function _payTo(address allower, address receiver, uint256 amount, address token)
    internal
    returns (uint256) {
        // Request to transfer amount from the contract to receiver.
        // contract does not own the funds, so the allower must have added allowance to the contract
        // Allower is the original owner.
        return SafeAmount.safeTransferFrom(token, allower, receiver, amount);
    }

    /**
     @notice Transfers tokens from us to someone
     @param to Receiver
     @param amount Tehe amount
     @param token The token
     */
    function _payDirect(address to, uint256 amount, address token)
    private
    returns (bool) {
        if (amount == 0) {
            return true;
        }
        IERC20(token).safeTransfer(to, amount);
        return true;
    }

    /**
     @notice Check if address is not zero
     @param addr The address
     */
    modifier _realAddress(address addr) {
        require(addr != address(0), "Festaking: zero address");
        _;
    }

    /**
     @notice Check if the amount is positive
     @param amount The amount
     */
    modifier _positive(uint256 amount) {
        require(amount != 0, "Festaking: negative amount");
        _;
    }

    /**
     @notice Check if we are past given time
     @param eventTime The event time
     */
    modifier _after(uint eventTime) {
        require(block.timestamp >= eventTime, "Festaking: bad timing for the request");
        _;
    }

    /**
     @notice Checkk if we are before the given time
     @param eventTime The event time
     */
    modifier _before(uint eventTime) {
        require(block.timestamp < eventTime, "Festaking: bad timing for the request");
        _;
    }
}
// File: contracts/legacy/IFestaked.sol



pragma solidity ^0.8.0;

/**
 * @dev Ferrum Staking interface
 */
interface IFestaked {
    
    event Staked(address indexed token, address indexed staker_, uint256 requestedAmount_, uint256 stakedAmount_);

    /**
    @notice Stake an amount
    @param amount The amount to stake
    @return True if success
    */
    function stake (uint256 amount) external returns (bool);

    /**
    @notice Stake for a user
    @param staker The staker
    @param amount The amount
    @return True if success
     */
    function stakeFor (address staker, uint256 amount) external returns (bool);

    /**
    @notice Returns staked amount for a user
    @param account The staker
    @return Staked amount
     */
    function stakeOf(address account) external view returns (uint256);

    /**
    @notice Token address
    @return Token address
     */
    function tokenAddress() external view returns (address);

    /**
    @notice Staked total
    @return Staked total
     */
    function stakedTotal() external view returns (uint256);

    /**
    @notice Staked balance
    @return Staked balance
     */
    function stakedBalance() external view returns (uint256);

    /**
    @notice Staking start time
    @return Staking start time
     */
    function stakingStarts() external view returns (uint256);

    /**
    @notice Staking end time
    @return Staking end time
     */
    function stakingEnds() external view returns (uint256);
}
// File: contracts/legacy/RewardAdder.sol


pragma solidity 0.8.2;




abstract contract RewardAdder is ReentrancyGuard, IFestaked {
    address  public rewardTokenAddress;
    FestakedLib.FestakeRewardState public rewardState;
    address public rewardSetter; // Not using Ownable to save on deployment gas

    /**
    @notice Rewards total
    @return The rewards total
     */
    function rewardsTotal() external view returns (uint256) {
        return rewardState.rewardsTotal;
    }

    /**
    @notice Early withdraw rewards
    @return Early withdraw rewards
     */
    function earlyWithdrawReward() external view returns (uint256) {
        return rewardState.earlyWithdrawReward;
    }

    /**
    @notice Rewards balance
    @return Rewards balance
     */
    function rewardBalance() external view returns (uint256) {
        return rewardState.rewardBalance;
    }

    /**
    @notice Adds reward
    @param rewardAmount The reward amount
    @param withdrawableAmount The withrdawable amount
    @return True if success
     */
    function addReward(uint256 rewardAmount, uint256 withdrawableAmount)
    external nonReentrant returns (bool) {
        return FestakedLib.addReward(rewardAmount, withdrawableAmount,
            rewardTokenAddress, rewardState);
    }
}

// File: contracts/legacy/FestakedOptimized.sol



pragma solidity 0.8.2;



/**
 * A staking contract distributes rewards.
 * One can create several TraditionalFestaking over one
 * staking and give different rewards for a single
 * staking contract.
 */
contract FestakedOptimized is IFestaked {
    string private _name;
    address  public override tokenAddress;
    uint public override stakingStarts;
    uint public override stakingEnds;
    uint public withdrawStarts;
    uint public withdrawEnds;
    uint public stakingCap;
    FestakedLib.FestakeState public stakeState;

    /**
     * Fixed periods. For an open ended contract use end dates from very distant future.
     */
    constructor (
        string memory name_,
        address tokenAddress_,
        uint stakingStarts_,
        uint stakingEnds_,
        uint withdrawStarts_,
        uint withdrawEnds_,
        uint256 stakingCap_) {
        require(tokenAddress_ != address(0), "Festaking: 0 address");
        require(stakingStarts_ != 0, "Festaking: zero staking start time");
        require(withdrawStarts_ >= stakingEnds_, "Festaking: withdrawStarts must be after staking ends");
        require(withdrawEnds_ >= withdrawStarts_, "Festaking: withdrawEnds must be after withdraw starts");

        if (stakingStarts_ < block.timestamp) {
            stakingStarts = block.timestamp;
        } else {
            stakingStarts = stakingStarts_;
        }
        require(stakingEnds_ >= stakingStarts, "Festaking: staking end must be after staking starts");
        _name = name_;

        tokenAddress = tokenAddress_;

        stakingEnds = stakingEnds_;

        withdrawStarts = withdrawStarts_;

        withdrawEnds = withdrawEnds_;

        stakingCap = stakingCap_;
    }

    /**
    @notice the name
    @return The name
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
    @notice The total amount staked
    @return The total amount staked
     */
    function stakedTotal() external override view returns (uint256) {
        return stakeState.stakedTotal;
    }

    /**
    @notice The staked balance
    @return The staked balance
     */
    function stakedBalance() public override view returns (uint256) {
        return stakeState.stakedBalance;
    }

    /**
    @notice Returns staked amount for a user
    @param account The staker
    @return Staked amount
     */
    function stakeOf(address account) external override view returns (uint256) {
        return stakeState._stakes[account];
    }

    /**
    @notice Stake for a user
    @param staker The staker
    @param amount The amount
    @return True if success
     */
    function stakeFor(address staker, uint256 amount)
    external
    virtual
    override
    returns (bool) {
        return _stake(msg.sender, staker, amount);
    }

    /**
    @notice Stake an amount
    @param amount The amount to stake
    @return True if success
    */
    function stake(uint256 amount)
    external
    virtual
    override
    returns (bool) {
        address from = msg.sender;
        return _stake(from, from, amount);
    }

    /**
    @notice Stake an amount
    @param payer The payer
    @param staker The staker
    @param amount The amount to stake
    @return True if success
    */
    function _stake(address payer, address staker, uint256 amount) internal virtual returns (bool) {
        require(payer != address(0), "Festaking: payer required");
        require(staker != address(0), "Festaking: staker required");
        return FestakedLib.stake(payer, staker, amount,
            stakingStarts, stakingEnds, stakingCap, tokenAddress,
            stakeState);
    }
}
// File: contracts/legacy/FestakedWithReward.sol


pragma solidity 0.8.2;



contract FestakedWithReward is FestakedOptimized, RewardAdder {
    constructor (string memory name_,
        address tokenAddress_,
        address rewardTokenAddress_,
        uint stakingStarts_,
        uint stakingEnds_,
        uint withdrawStarts_,
        uint withdrawEnds_,
        uint256 stakingCap_) FestakedOptimized (
            name_,
            tokenAddress_,
            stakingStarts_,
            stakingEnds_,
            withdrawStarts_,
            withdrawEnds_,
            stakingCap_
        ) {
        require(rewardTokenAddress_ != address(0), "Festaking: 0 reward address");
        rewardTokenAddress = rewardTokenAddress_;
        rewardSetter = msg.sender;
    }

    /**
    @notice Adds marginal rewards. Marginal reward is amount of tokens in the contract
    that are not already added to reward or stake
    @param withdrawableAmount The withdrawable amount
     */
    function addMarginalReward(uint256 withdrawableAmount)
    external nonReentrant {
        require(msg.sender == rewardSetter, "Festaking: Not allowed");
        rewardState.earlyWithdrawReward = withdrawableAmount;
        FestakedLib.addMarginalReward(rewardTokenAddress, tokenAddress,
            address(this), stakedBalance(), rewardState);
        require(rewardState.rewardBalance >= withdrawableAmount, "Festaking: withdrawable reward is more than balance");
    }

    /**
    @notice Withdraws an amount
    @param amount The amount
    @return True if successful
    */
    function withdraw(uint256 amount) virtual
    external nonReentrant
    returns (bool) {
        return FestakedLib.withdraw(
            msg.sender,
            tokenAddress,
            rewardTokenAddress,
            amount,
            withdrawStarts,
            withdrawEnds,
            stakingEnds,
            stakeState,
            rewardState);
    }
}