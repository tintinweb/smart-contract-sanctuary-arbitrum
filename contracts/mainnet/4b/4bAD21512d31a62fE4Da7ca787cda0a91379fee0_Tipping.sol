// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

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
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

/// @title An interface of the {StakingPool} contract
interface IStakingPool {
    /// @notice Indicates that `user` deposited `amount` of tokens into the pool
    event Deposit(address indexed user, uint256 amount);
    /// @notice Indicates that `user` withdrawn `amount` of tokens from the pool
    event Withdraw(address indexed user, uint256 amount);
    /// @notice Indicates that `user` withdraw `amount` of tokens from the pool
    ///      without claiming reward
    event EmergencyWithdraw(address indexed user, uint256 amount);
    /// @notice Indicates that `user` claimed his pending reward
    event Claim(address indexed user, uint256 amount);
    /// @notice Indicates that new address of `Tipping` contract was set
    event TippingAddressChanged(address indexed tipping);

    /// @notice Allows to see the pending reward of the user
    /// @param user The user to check the pending reward of
    /// @return The pending reward of the user
    function getAvailableReward(address user) external view returns (uint256);

    /// @notice Allows to see the current stake of the user
    /// @param user The user to check the current lock of
    /// @return The current lock of the user
    function getStake(address user) external view returns (uint256);

    /// @notice Allows to see the current amount of users who staked tokens in the pool
    /// @return The amount of users who staked tokens in the pool
    function getStakersCount() external view returns (uint256);

    /// @notice Allows users to lock their tokens inside the pool
    ///         or increase the current locked amount. All pending rewards
    ///         are claimed when making a new deposit
    /// @param amount The amount of tokens to lock inside the pool
    /// @dev Emits a {Deposit} event
    function deposit(uint256 amount) external;

    /// @notice Allows users to withdraw their locked tokens from the pool
    ///         All pending rewards are claimed when withdrawing
    /// @dev Emits a {Withdraw} event
    function withdraw(uint256 amount) external;

    /// @notice Allows users to withdraw their locked tokens from the pool
    ///         without claiming any rewards
    /// @dev Emits an {EmergencyWithdraw} event
    function emergencyWithdraw() external;

    /// @notice Allows users to claim all of their pending rewards
    /// @dev Emits a {Claim} event
    function claim() external;

    /// @notice Sets the address of the {Tipping} contract to call its methods
    /// @notice param tipping_ The address of the {Tipping} contract
    function setTipping(address tipping_) external;

    /// @notice Gives a signal that some tokens have been received from the
    ///         {Tipping} contract. That leads to each user's reward share
    ///         recalculation.
    /// @dev Each time someone transfers tokens using the {Tipping} contract,
    ///      a small portion of these tokens gets sent to the staking pool to be
    ///      paid as rewards
    /// @dev This function does not transfer any tokens itself
    function supplyReward(uint256 reward) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

interface ITipping {
    /// @notice Indicates that the {StakingPool} address was changed
    event StakingAddressChanged(address indexed newAddress);
    /// @notice Indicates that the {Odeum} address was changed
    event OdeumAddressChanged(address indexed newAddress);
    /// @notice Indicates that the address to send burnt tokens to was changed
    event BurnAddressChanged(address indexed newAddress);
    /// @notice Indicates that the address to team wallet was changed
    event FundAddressChanged(address indexed newAddress);
    /// @notice Indicates that the burn percentage was changed
    event BurnRateChanged(uint256 indexed newPercentage);
    /// @notice Indicates that the percentage of tokens sent to the
    ///         team wallet was changed
    event FundRateChanged(uint256 indexed newPercentage);
    /// @notice Indicates that the percentage of tokens sent to the
    ///         staking pool was changed
    event RewardRateChanged(uint256 indexed newPercentage);
    /// @notice Indicates that the tranfer amount was split
    ///         among several addresses
    event SplitTransfer(address indexed to, uint256 indexed amount);

    /// @notice Sets the address of the {StakinPool} contract
    /// @param STAKING_VAULT The address of the {StakingPool} contract
    /// @dev Emits the {StakingAddressChanged} event
    function setStakingVaultAddress(address STAKING_VAULT) external;

    /// @notice Sets the address of the {Odeum} contract
    /// @param ODEUM The address of the {Odeum} contract
    /// @dev Emits the {OdeumAddressChanged} event
    function setOdeumAddress(address ODEUM) external;

    /// @notice Sets the address to send burnt tokens to
    /// @dev A zero address by default
    /// @param VAULT_TO_BURN The address to send burnt tokens to
    /// @dev Emits the {BurnAddressChanged} event
    function setVaultToBurnAddress(address VAULT_TO_BURN) external;

    /// @notice Sets the address of the team wallet
    /// @param FUND_VAULT The address of the team wallet
    /// @dev Emits the {FundAddressChanged} event
    function setFundVaultAddress(address FUND_VAULT) external;

    /// @notice Sets the new percentage of tokens to be burnt on each
    ///         transfer (in basis points)
    /// @param burnRate The new percentage of tokens to be burnt on each
    ///        transfer (in basis points)
    /// @dev Emits the {BurnRateChanged} event
    function setBurnRate(uint256 burnRate) external;

    /// @notice Sets the new percentage of tokens to be sent to the team wallet on each
    ///         transfer (in basis points)
    /// @param fundRate The new percentage of tokens to be sent to the team wallet on each
    ///        transfer (in basis points)
    /// @dev Emits the {FundRateChanged} event
    function setFundRate(uint256 fundRate) external;

    /// @notice Sets the new percentage of tokens to be sent to the staking pool on each
    ///         transfer (in basis points)
    /// @param rewardRate The new percentage of tokens to be sent to the staking pool on each
    ///        transfer (in basis points)
    /// @dev Emits the {RewardRateChanged} event
    function setRewardRate(uint256 rewardRate) external;

    /// @notice Transfers the `amount` tokens and splits it among several addresses
    /// @param to The main destination address to transfer tokens to
    /// @param amount The amount of tokens to transfer
    /// @dev Emits the {SplitTransfer} event
    function tip(address to, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IStakingPool.sol";
import "./interfaces/ITipping.sol";

/// Allows users to transfer tokens and have the transferred amount split
/// among several destinations
contract Tipping is Ownable, ITipping {
    using SafeERC20 for IERC20;

    /// @notice The address of the {StakingPool} contract
    address public _STAKING_VAULT;
    /// @notice The address of the {Odeum} contract
    address public _ODEUM;
    /// @notice The address of the team wallet
    address public _FUND_VAULT;
    /// @notice The address to send burnt tokens to
    address public _VAULT_TO_BURN;

    /// @notice The percentage of tokens to be burnt (in basis points)
    uint256 public _burnRate;
    /// @notice The percentage of tokens to be sent to the team wallet (in basis points)
    uint256 public _fundRate;
    /// @notice The percentage of tokens to be sent to the {StakingPool} and distributed as rewards
    uint256 public _rewardRate;

    /// @notice The amount of tips received by each user
    mapping(address => uint256) public userTips;

    /// @notice The maximum possible percentage
    uint256 public constant MAX_RATE_BP = 1000;

    constructor(
        address STAKING_VAULT,
        address ODEUM,
        address FUND_VAULT,
        address VAULT_TO_BURN,
        uint256 burnRate,
        uint256 fundRate,
        uint256 rewardRate
    ) {
        _VAULT_TO_BURN = VAULT_TO_BURN;
        _STAKING_VAULT = STAKING_VAULT;
        _ODEUM = ODEUM;
        _FUND_VAULT = FUND_VAULT;
        _burnRate = burnRate;
        _fundRate = fundRate;
        _rewardRate = rewardRate;
    }

    /// @dev Forbids to set too high percentage
    modifier validRate(uint256 rate) {
        require(rate > 0 && rate <= MAX_RATE_BP, "Tipping: Rate too high!");
        _;
    }

    /// @notice See {ITipping-setStakingVaultAddress}
    /// @dev Emits the {StakingAddressChanged} event
    function setStakingVaultAddress(address STAKING_VAULT) external onlyOwner {
        require(
            STAKING_VAULT != address(0),
            "Tipping: Invalid staking address!"
        );
        _STAKING_VAULT = STAKING_VAULT;
        emit StakingAddressChanged(STAKING_VAULT);
    }

    /// @notice See {ITipping-setOdeumAddress}
    /// @dev Emits the {OdeumAddressChanged} event
    function setOdeumAddress(address ODEUM) external onlyOwner {
        require(ODEUM != address(0), "Tipping: Invalid odeum address!");
        _ODEUM = ODEUM;
        emit OdeumAddressChanged(ODEUM);
    }

    /// @notice See {ITipping-setVaultToBurnAddress}
    /// @dev Emits the {BurnAddressChanged} event
    function setVaultToBurnAddress(address VAULT_TO_BURN) external onlyOwner {
        // Zero address allowed here
        _VAULT_TO_BURN = VAULT_TO_BURN;
        emit BurnAddressChanged(VAULT_TO_BURN);
    }

    /// @notice See {ITipping-setFundVaultAddress}
    /// @dev Emits the {FundAddressChanged} event
    function setFundVaultAddress(address FUND_VAULT) external onlyOwner {
        require(
            FUND_VAULT != address(0),
            "Tipping: Invalid fund vault address!"
        );
        _FUND_VAULT = FUND_VAULT;
        emit FundAddressChanged(FUND_VAULT);
    }

    /// @notice See {ITipping-setBurnRate}
    /// @dev Emits the {FundAddressChanged} event
    function setBurnRate(
        uint256 burnRate
    ) external validRate(burnRate) onlyOwner {
        // Any burn rate allowed here
        _burnRate = burnRate;
        emit BurnRateChanged(burnRate);
    }

    /// @notice See {ITipping-setFundRate}
    function setFundRate(
        uint256 fundRate
    ) external validRate(fundRate) onlyOwner {
        // Any fund rate allowed here
        _fundRate = fundRate;
        emit FundRateChanged(fundRate);
    }

    /// @notice See {ITipping-setRewardRate}
    function setRewardRate(
        uint256 rewardRate
    ) external validRate(rewardRate) onlyOwner {
        // Any reward rate allowed here
        _rewardRate = rewardRate;
        emit RewardRateChanged(rewardRate);
    }

    /// @notice See {ITipping-transfer}
    function tip(address to, uint256 amount) external {
        IERC20 _odeum = IERC20(_ODEUM);
        _odeum.safeTransferFrom(msg.sender, address(this), amount);
        (
            uint256 transAmount,
            uint256 burnAmount,
            uint256 fundAmount,
            uint256 rewardAmount
        ) = _getValues(amount);
        _odeum.safeTransfer(to, transAmount);
        userTips[to] += transAmount;
        _odeum.safeTransfer(_VAULT_TO_BURN, burnAmount);
        _odeum.safeTransfer(_FUND_VAULT, fundAmount);
        _odeum.safeTransfer(_STAKING_VAULT, rewardAmount);
        IStakingPool(_STAKING_VAULT).supplyReward(rewardAmount);
        emit SplitTransfer(to, amount);
    }

    /// @dev Calculates portions of the transferred amount to be
    ///      split among several destinations
    /// @param amount The amount of transferred tokens
    function _getValues(
        uint256 amount
    ) private view returns (uint256, uint256, uint256, uint256) {
        uint256 burnAmount = (amount * _burnRate) / MAX_RATE_BP;
        uint256 fundAmount = (amount * _fundRate) / MAX_RATE_BP;
        uint256 rewardAmount = (amount * _rewardRate) / MAX_RATE_BP;
        uint256 transAmount = amount - rewardAmount - fundAmount - burnAmount;
        return (transAmount, burnAmount, fundAmount, rewardAmount);
    }
}