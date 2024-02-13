// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.20;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";
import {IERC20Permit} from "../extensions/IERC20Permit.sol";
import {Address} from "../../../utils/Address.sol";

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

    /**
     * @dev An operation with an ERC20 token failed.
     */
    error SafeERC20FailedOperation(address token);

    /**
     * @dev Indicates a failed `decreaseAllowance` request.
     */
    error SafeERC20FailedDecreaseAllowance(address spender, uint256 currentAllowance, uint256 requestedDecrease);

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transfer, (to, value)));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeCall(token.transferFrom, (from, to, value)));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        forceApprove(token, spender, oldAllowance + value);
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `requestedDecrease`. If `token` returns no
     * value, non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 requestedDecrease) internal {
        unchecked {
            uint256 currentAllowance = token.allowance(address(this), spender);
            if (currentAllowance < requestedDecrease) {
                revert SafeERC20FailedDecreaseAllowance(spender, currentAllowance, requestedDecrease);
            }
            forceApprove(token, spender, currentAllowance - requestedDecrease);
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeCall(token.approve, (spender, value));

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeCall(token.approve, (spender, 0)));
            _callOptionalReturn(token, approvalCall);
        }
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

        bytes memory returndata = address(token).functionCall(data);
        if (returndata.length != 0 && !abi.decode(returndata, (bool))) {
            revert SafeERC20FailedOperation(address(token));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return success && (returndata.length == 0 || abi.decode(returndata, (bool))) && address(token).code.length > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Address.sol)

pragma solidity ^0.8.20;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev The ETH balance of the account is not enough to perform the operation.
     */
    error AddressInsufficientBalance(address account);

    /**
     * @dev There's no code at `target` (it is not a contract).
     */
    error AddressEmptyCode(address target);

    /**
     * @dev A call to an address target failed. The target may have reverted.
     */
    error FailedInnerCall();

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.20/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        if (address(this).balance < amount) {
            revert AddressInsufficientBalance(address(this));
        }

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) {
            revert FailedInnerCall();
        }
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason or custom error, it is bubbled
     * up by this function (like regular Solidity function calls). However, if
     * the call reverted with no returned reason, this function reverts with a
     * {FailedInnerCall} error.
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        if (address(this).balance < value) {
            revert AddressInsufficientBalance(address(this));
        }
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and reverts if the target
     * was not a contract or bubbling up the revert reason (falling back to {FailedInnerCall}) in case of an
     * unsuccessful call.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            // only check if target is a contract if the call was successful and the return data is empty
            // otherwise we already know that it was a contract
            if (returndata.length == 0 && target.code.length == 0) {
                revert AddressEmptyCode(target);
            }
            return returndata;
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and reverts if it wasn't, either by bubbling the
     * revert reason or with a default {FailedInnerCall} error.
     */
    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        if (!success) {
            _revert(returndata);
        } else {
            return returndata;
        }
    }

    /**
     * @dev Reverts with returndata if present. Otherwise reverts with {FailedInnerCall}.
     */
    function _revert(bytes memory returndata) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert FailedInnerCall();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title The interface for the Staking V1 contract
/// @notice The Staking Contract contains the logic for BRO Token staking and reward distribution
interface IStakingV1 {
    /// @notice Emitted when compound amount is zero
    error NothingToCompound();

    /// @notice Emitted when withdraw amount is zero
    error NothingToWithdraw();

    /// @notice Emitted when rewards claim amount($BRO or $bBRO) is zero
    error NothingToClaim();

    /// @notice Emitted when configured limit for unstaking periods per staker was reached
    error UnstakingPeriodsLimitWasReached();

    /// @notice Emitted when unstaking period was not found
    /// @param unstakingPeriod specified unstaking period to search for
    error UnstakingPeriodNotFound(uint256 unstakingPeriod);

    /// @notice Emitted when configured limit for withdrawals per unstaking period was reached
    error WithdrawalsLimitWasReached();

    /// @notice Emitted when withdrawal was not found
    /// @param amount specified withdrawal amount
    /// @param unstakingPeriod specified unstaking period
    error WithdrawalNotFound(uint256 amount, uint256 unstakingPeriod);

    /// @notice Emitted when staker staked some amount by specified unstaking period
    /// @param staker staker's address
    /// @param amount staked amount
    /// @param unstakingPeriod selected unstaking period
    event Staked(
        address indexed staker,
        uint256 amount,
        uint256 unstakingPeriod
    );

    /// @notice Emitted when stake was performed via one of the protocol members
    /// @param staker staker's address
    /// @param amount staked amount
    /// @param unstakingPeriod selected unstaking period
    event ProtocolMemberStaked(
        address indexed staker,
        uint256 amount,
        uint256 unstakingPeriod
    );
    /// @notice Emitted when staker compunded his $BRO rewards
    /// @param staker staker's address
    /// @param compoundAmount compounded amount
    /// @param unstakingPeriod selected unstaking period where to deposit compounded tokens
    event Compounded(
        address indexed staker,
        uint256 compoundAmount,
        uint256 unstakingPeriod
    );

    /// @notice Emitted when staker unstaked some amount of tokens from selected unstaking period
    /// @param staker staker's address
    /// @param amount unstaked amount
    /// @param unstakingPeriod selected unstaking period from where to deduct specified amount
    event Unstaked(
        address indexed staker,
        uint256 amount,
        uint256 unstakingPeriod
    );

    /// @notice Emitted when staker withdrew his token after unstaking period was expired
    /// @param staker staker's address
    /// @param amount withdrawn amount
    event Withdrawn(address indexed staker, uint256 amount);

    /// @notice Emitted when staker cancelled withdrawal
    /// @param staker staker's address
    /// @param compoundAmount amount that was moved from withdrawal to unstaking period
    /// @param unstakingPeriod specified unstaking period to find withdrawal
    event WithdrawalCanceled(
        address indexed staker,
        uint256 compoundAmount,
        uint256 unstakingPeriod
    );

    /// @notice Emitted when staker claimed his $BRO rewards
    /// @param staker staker's address
    /// @param amount claimed $BRO amount
    event BroRewardsClaimed(address indexed staker, uint256 amount);

    /// @notice Emitted when staked claimed his $bBRO rewards
    /// @param staker staker's address
    /// @param amount claimed $bBRO amount
    event BBroRewardsClaimed(address indexed staker, uint256 amount);

    struct InitializeParams {
        // distributor address
        address distributor_;
        // epoch manager address
        address epochManager_;
        // $BRO token address
        address broToken_;
        // $bBRO token address
        address bBroToken_;
        // list of protocol members
        address[] protocolMembers_;
        // min amount of BRO that can be staked per tx
        uint256 minBroStakeAmount_;
        // min amount of epochs for unstaking period
        uint256 minUnstakingPeriod_;
        // max amount of epochs for unstaking period
        uint256 maxUnstakingPeriod_;
        // max amount of unstaking periods the staker can have
        // this check is omitted when staking via community bonding
        uint8 maxUnstakingPeriodsPerStaker_;
        // max amount of withdrawals per unstaking period the staker can have
        // 5 unstaking periods = 25 withdrawals max
        uint8 maxWithdrawalsPerUnstakingPeriod_;
        // variable for calculating rewards generating amount
        // that will generate $BRO staking rewards
        uint256 rewardGeneratingAmountBaseIndex_;
        // percentage that is used to decrease
        // withdrawal rewards generating $BRO amount
        uint256 withdrawalAmountReducePerc_;
        // percentage that is used to decrease
        // $bBRO rewards for unstaked amounts
        uint256 withdrawnBBroRewardReducePerc_;
        // variable for calculating $bBRO rewards
        uint256 bBroRewardsBaseIndex_;
        // variable for calculating $bBRO rewards
        uint16 bBroRewardsXtraMultiplier_;
    }

    struct Withdrawal {
        // $BRO rewards generating amount
        uint256 rewardsGeneratingAmount;
        // locked amount that doesn't generate $BRO rewards
        uint256 lockedAmount;
        // timestamp when unstaking period started
        uint256 withdrewAt;
        // unstaking period in epochs to wait before token release
        uint256 unstakingPeriod;
    }

    struct UnstakingPeriod {
        // $BRO rewards generating amount
        uint256 rewardsGeneratingAmount;
        // locked amount that doesn't generate $BRO rewards
        uint256 lockedAmount;
        // unstaking period in epochs to wait before token release
        uint256 unstakingPeriod;
    }

    struct Staker {
        // $BRO rewards index that is used to compute staker share
        uint256 broRewardIndex;
        // unclaimed $BRO rewards
        uint256 pendingBroReward;
        // unclaimed $bBRO rewards
        uint256 pendingBBroReward;
        // last timestamp when rewards was claimed
        uint256 lastRewardsClaimTimestamp;
        // stakers unstaking periods
        UnstakingPeriod[] unstakingPeriods;
        // stakers withdrawals
        Withdrawal[] withdrawals;
    }

    /// @notice Stakes specified amount of $BRO tokens
    /// @param _amount amount of $BRO tokens to stake
    /// @param _unstakingPeriod specified unstaking period
    function stake(uint256 _amount, uint256 _unstakingPeriod) external;

    /// @notice Stake specified amount of $BRO tokens via one of the protocol members
    /// @param _stakerAddress staker's address
    /// @param _amount bonded amount that will be staked
    /// @param _unstakingPeriod specified unstaking period
    function protocolMemberStake(
        address _stakerAddress,
        uint256 _amount,
        uint256 _unstakingPeriod
    ) external;

    /// @notice Compounds staker pending $BRO rewards and deposits them to specified unstaking period
    /// @param _unstakingPeriod specified unstaking period
    function compound(uint256 _unstakingPeriod) external;

    /// @notice Increases selected unstaking period
    /// @dev If increase version of unstaking period already exists the contract will
    /// move all the funds there and remove the old one
    /// @param _currentUnstakingPeriod unstaking period to increase
    /// @param _increasedUnstakingPeriod increased unstaking period
    function increaseUnstakingPeriod(
        uint256 _currentUnstakingPeriod,
        uint256 _increasedUnstakingPeriod
    ) external;

    /// @notice Unstakes specified amount of $BRO tokens.
    /// Unstaking period starts at this moment of time.
    /// @param _amount specified amount to unstake
    /// @param _unstakingPeriod specified unstaking period
    function unstake(uint256 _amount, uint256 _unstakingPeriod) external;

    /// @notice Unstakes specified amount of $BRO tokens via one of the protocol members.
    /// Unstaking period starts at this moment of time.
    /// @param _stakerAddress staker's address
    /// @param _amount specified amount to unstake
    /// @param _unstakingPeriod specified unstaking period
    function protocolMemberUnstake(
        address _stakerAddress,
        uint256 _amount,
        uint256 _unstakingPeriod
    ) external;

    /// @notice Removes all expired withdrawals and transferes unstaked amount to the staker
    function withdraw() external;

    /// @notice Cancels withdrawal. Moves withdrawn funds back to the unstaking period
    /// @param _amount specified amount to find withdrawal
    /// @param _unstakingPeriod specified unstaking period to find withdrawal
    function cancelUnstaking(uint256 _amount, uint256 _unstakingPeriod)
        external;

    /// @notice Claimes staker rewards and transferes them to the staker wallet
    /// @param _claimBro defines either to claim $BRO rewards or not
    /// @param _claimBBro defines either to claim $bBRO rewards or not
    /// @return amount of claimed $BRO and $bBRO tokens
    function claimRewards(bool _claimBro, bool _claimBBro)
        external
        returns (uint256, uint256);

    /// @notice Returns staker info
    /// @param _stakerAddress staker's address to look for
    function getStakerInfo(address _stakerAddress)
        external
        view
        returns (Staker memory);

    /// @notice Returns total amount of rewards generating $BRO by staker address
    /// @param _stakerAddress staker's address to look for
    function totalStakerRewardsGeneratingBro(address _stakerAddress)
        external
        view
        returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IStakingV1 } from "./interfaces/IStakingV1.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ProtocolMigratorArb is Ownable {
    using SafeERC20 for IERC20;

    struct UserMigration {
        address account;
        uint256 broInWalletBalance;
        uint256 bBroInWalletBalance;
        uint256 stakedBro;
    }

    IERC20 public broToken;
    IERC20 public bBroToken;
    IStakingV1 public staking;

    uint256 public unstakingPeriod;

    constructor(
        address broToken_,
        address bBroToken_,
        address staking_,
        uint256 unstakingPeriod_
    ) Ownable(msg.sender) {
        broToken = IERC20(broToken_);
        bBroToken = IERC20(bBroToken_);
        staking = IStakingV1(staking_);
        unstakingPeriod = unstakingPeriod_;
    }

    function migrate(
        UserMigration[] calldata _userMigrations
    ) external onlyOwner {
        for (uint256 i = 0; i < _userMigrations.length; i++) {
            if (_userMigrations[i].broInWalletBalance != 0) {
                broToken.safeTransfer(
                    _userMigrations[i].account,
                    _userMigrations[i].broInWalletBalance
                );
            }

            if (_userMigrations[i].bBroInWalletBalance != 0) {
                bBroToken.safeTransfer(
                    _userMigrations[i].account,
                    _userMigrations[i].bBroInWalletBalance
                );
            }

            if (_userMigrations[i].stakedBro != 0) {
                broToken.safeIncreaseAllowance(
                    address(staking),
                    _userMigrations[i].stakedBro
                );
                staking.protocolMemberStake(
                    _userMigrations[i].account,
                    _userMigrations[i].stakedBro,
                    unstakingPeriod
                );
            }
        }
    }

    function withdrawRemainingBro() external onlyOwner {
        broToken.safeTransfer(super.owner(), broToken.balanceOf(address(this)));
    }
}