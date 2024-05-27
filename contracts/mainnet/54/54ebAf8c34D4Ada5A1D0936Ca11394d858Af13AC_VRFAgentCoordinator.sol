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

// Copyright 2021-2022, Offchain Labs, Inc.
// For license information, see https://github.com/OffchainLabs/nitro-contracts/blob/main/LICENSE
// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.4.21 <0.9.0;

/// @title Provides insight into the cost of using the chain.
/// @notice These methods have been adjusted to account for Nitro's heavy use of calldata compression.
/// Of note to end-users, we no longer make a distinction between non-zero and zero-valued calldata bytes.
/// Precompiled contract that exists in every Arbitrum chain at 0x000000000000000000000000000000000000006c.
interface ArbGasInfo {
    /// @notice Get gas prices for a provided aggregator
    /// @return return gas prices in wei
    ///        (
    ///            per L2 tx,
    ///            per L1 calldata byte
    ///            per storage allocation,
    ///            per ArbGas base,
    ///            per ArbGas congestion,
    ///            per ArbGas total
    ///        )
    function getPricesInWeiWithAggregator(address aggregator)
    external
    view
    returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    );

    /// @notice Get gas prices. Uses the caller's preferred aggregator, or the default if the caller doesn't have a preferred one.
    /// @return return gas prices in wei
    ///        (
    ///            per L2 tx,
    ///            per L1 calldata byte
    ///            per storage allocation,
    ///            per ArbGas base,
    ///            per ArbGas congestion,
    ///            per ArbGas total
    ///        )
    function getPricesInWei()
    external
    view
    returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    );

    /// @notice Get prices in ArbGas for the supplied aggregator
    /// @return (per L2 tx, per L1 calldata byte, per storage allocation)
    function getPricesInArbGasWithAggregator(address aggregator)
    external
    view
    returns (
        uint256,
        uint256,
        uint256
    );

    /// @notice Get prices in ArbGas. Assumes the callers preferred validator, or the default if caller doesn't have a preferred one.
    /// @return (per L2 tx, per L1 calldata byte, per storage allocation)
    function getPricesInArbGas()
    external
    view
    returns (
        uint256,
        uint256,
        uint256
    );

    /// @notice Get the gas accounting parameters. `gasPoolMax` is always zero, as the exponential pricing model has no such notion.
    /// @return (speedLimitPerSecond, gasPoolMax, maxTxGasLimit)
    function getGasAccountingParams()
    external
    view
    returns (
        uint256,
        uint256,
        uint256
    );

    /// @notice Get the minimum gas price needed for a tx to succeed
    function getMinimumGasPrice() external view returns (uint256);

    /// @notice Get ArbOS's estimate of the L1 basefee in wei
    function getL1BaseFeeEstimate() external view returns (uint256);

    /// @notice Get how slowly ArbOS updates its estimate of the L1 basefee
    function getL1BaseFeeEstimateInertia() external view returns (uint64);

    /// @notice Get the L1 pricer reward rate, in wei per unit
    /// Available in ArbOS version 11
    function getL1RewardRate() external view returns (uint64);

    /// @notice Get the L1 pricer reward recipient
    /// Available in ArbOS version 11
    function getL1RewardRecipient() external view returns (address);

    /// @notice Deprecated -- Same as getL1BaseFeeEstimate()
    function getL1GasPriceEstimate() external view returns (uint256);

    /// @notice Get L1 gas fees paid by the current transaction
    function getCurrentTxL1GasFees() external view returns (uint256);

    /// @notice Get the backlogged amount of gas burnt in excess of the speed limit
    function getGasBacklog() external view returns (uint64);

    /// @notice Get how slowly ArbOS updates the L2 basefee in response to backlogged gas
    function getPricingInertia() external view returns (uint64);

    /// @notice Get the forgivable amount of backlogged gas ArbOS will ignore when raising the basefee
    function getGasBacklogTolerance() external view returns (uint64);

    /// @notice Returns the surplus of funds for L1 batch posting payments (may be negative).
    function getL1PricingSurplus() external view returns (int256);

    /// @notice Returns the base charge (in L1 gas) attributed to each data batch in the calldata pricer
    function getPerBatchGasCharge() external view returns (int64);

    /// @notice Returns the cost amortization cap in basis points
    function getAmortizedCostCapBips() external view returns (uint64);

    /// @notice Returns the available funds from L1 fees
    function getL1FeesAvailable() external view returns (uint256);

    /// @notice Returns the equilibration units parameter for L1 price adjustment algorithm
    /// Available in ArbOS version 20
    function getL1PricingEquilibrationUnits() external view returns (uint256);

    /// @notice Returns the last time the L1 calldata pricer was updated.
    /// Available in ArbOS version 20
    function getLastL1PricingUpdateTime() external view returns (uint64);

    /// @notice Returns the amount of L1 calldata payments due for rewards (per the L1 reward rate)
    /// Available in ArbOS version 20
    function getL1PricingFundsDueForRewards() external view returns (uint256);

    /// @notice Returns the amount of L1 calldata posted since the last update.
    /// Available in ArbOS version 20
    function getL1PricingUnitsSinceUpdate() external view returns (uint64);

    /// @notice Returns the L1 pricing surplus as of the last update (may be negative).
    /// Available in ArbOS version 20
    function getLastL1PricingSurplus() external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface ArbSys {
    /**
    * @notice Get Arbitrum block number (distinct from L1 block number; Arbitrum genesis block has block number 0)
    * @return block number as int
     */
    function arbBlockNumber() external view returns (uint);
    /**
     * @notice Get Arbitrum block hash (reverts unless currentBlockNum-256 <= arbBlockNum < currentBlockNum)
     * @return block hash
     */
    function arbBlockHash(uint256 arbBlockNum) external view returns (bytes32);
}

pragma solidity ^0.8.19;

interface OVM_GasPriceOracle {
    function getL1Fee(bytes memory _data) external view returns (uint256);

    function getL1GasUsed(bytes memory _data) external view returns (uint256);

    function overhead() external view returns (uint256);

    function l1BaseFee() external view returns (uint256);

    function scalar() external view returns (uint256);

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./VRFAgentConsumerInterface.sol";

interface VRFAgentConsumerFactoryInterface {

    function createConsumer(address agent_, address owner_) external returns (VRFAgentConsumerInterface);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFAgentConsumerInterface {

    function setVrfConfig(
        address vrfCoordinator_,
        bytes32 vrfKeyHash_,
        uint64 vrfSubscriptionId_,
        uint16 vrfRequestConfirmations_,
        uint32 vrfCallbackGasLimit_,
        uint256 vrfRequestPeriod_
    ) external;

    function setOffChainIpfsHash(string calldata _ipfsHash) external;

    function getPseudoRandom() external returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFAgentCoordinatorInterface {
    /**
     * @notice Get configuration relevant for making requests
     * @return minimumRequestConfirmations global min for request confirmations
     * @return maxGasLimit global max for request gas limit
     * @return s_agentProviders list of registered agents
     */
    function getRequestConfig() external view returns (uint16, uint32, address[] memory);

    /**
     * @notice Request a set of random words.
     * @param agent - Corresponds to a agent provider address
     * @param subId  - The ID of the VRF subscription. Must be funded
     * with the minimum subscription balance required for the selected keyHash.
     * @param minimumRequestConfirmations - How many blocks you'd like the
     * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
     * for why you may want to request more. The acceptable range is
     * [minimumRequestBlockConfirmations, 200].
     * @param callbackGasLimit - How much gas you'd like to receive in your
     * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
     * may be slightly less than this amount because of gas used calling the function
     * (argument decoding etc.), so you may need to request slightly more than you expect
     * to have inside fulfillRandomWords. The acceptable range is
     * [0, maxGasLimit]
     * @param numWords - The number of uint256 random values you'd like to receive
     * in your fulfillRandomWords callback. Note these numbers are expanded in a
     * secure way by the VRFCoordinator from a single random value supplied by the oracle.
     * @return requestId - A unique identifier of the request. Can be used to match
     * a request to a response in fulfillRandomWords.
     */
    function requestRandomWords(
        address agent,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);

    /**
     * @notice Create a VRF subscription.
     * @return subId - A unique subscription id.
     * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
     */
    function createSubscription() external returns (uint64 subId);

    function createSubscriptionWithConsumer() external returns (uint64 subId, address consumer);

    /**
     * @notice Get a VRF subscription.
     * @param subId - ID of the subscription
     * @return owner - owner of the subscription.
     * @return consumers - list of consumer address which are able to use this subscription.
     */
    function getSubscription(uint64 subId) external view returns (address owner, address[] memory consumers);

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @param newOwner - proposed new owner of the subscription
     */
    function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @dev will revert if original owner of subId has
     * not requested that msg.sender become the new owner.
     */
    function acceptSubscriptionOwnerTransfer(uint64 subId) external;

    /**
     * @notice Add a consumer to a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - New consumer which can use the subscription
     */
    function addConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Remove a consumer from a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - Consumer to remove from the subscription
     */
    function removeConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Cancel a subscription
     * @param subId - ID of the subscription
     */
    function cancelSubscription(uint64 subId) external;

    /*
     * @notice Check to see if there exists a request commitment consumers
     * for all consumers and keyhashes for a given sub.
     * @param subId - ID of the subscription
     * @return true if there exists at least one unfulfilled request for the subscription, false
     * otherwise.
     */
    function pendingRequestExists(uint64 subId) external view returns (bool);

    function fulfillRandomnessResolver(uint64 _subId) external view returns (bool, bytes calldata);

    /*
     * @notice Get last pending request id
     */
    function lastPendingRequestId(address consumer, uint64 subId) external view returns (uint256);

    /*
     * @notice Get current nonce
     */
    function getCurrentNonce(address consumer, uint64 subId) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFChainlinkCoordinatorInterface {
    /**
     * @notice Get configuration relevant for making requests
     * @return minimumRequestConfirmations global min for request confirmations
     * @return maxGasLimit global max for request gas limit
     * @return s_agentProviders list of registered agents
     */
    function getRequestConfig() external view returns (uint16, uint32, address[] memory);

    /**
     * @notice Request a set of random words.
     * @param keyHash - Corresponds to a public key hash
     * @param subId  - The ID of the VRF subscription. Must be funded
     * with the minimum subscription balance required for the selected keyHash.
     * @param minimumRequestConfirmations - How many blocks you'd like the
     * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
     * for why you may want to request more. The acceptable range is
     * [minimumRequestBlockConfirmations, 200].
     * @param callbackGasLimit - How much gas you'd like to receive in your
     * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
     * may be slightly less than this amount because of gas used calling the function
     * (argument decoding etc.), so you may need to request slightly more than you expect
     * to have inside fulfillRandomWords. The acceptable range is
     * [0, maxGasLimit]
     * @param numWords - The number of uint256 random values you'd like to receive
     * in your fulfillRandomWords callback. Note these numbers are expanded in a
     * secure way by the VRFCoordinator from a single random value supplied by the oracle.
     * @return requestId - A unique identifier of the request. Can be used to match
     * a request to a response in fulfillRandomWords.
     */
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);

    /**
     * @notice Create a VRF subscription.
     * @return subId - A unique subscription id.
     * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
     */
    function createSubscription() external returns (uint64 subId);

    function createSubscriptionWithConsumer() external returns (uint64 subId, address consumer);

    /**
     * @notice Get a VRF subscription.
     * @param subId - ID of the subscription
     * @return owner - owner of the subscription.
     * @return consumers - list of consumer address which are able to use this subscription.
     */
    function getSubscription(uint64 subId) external view returns (address owner, address[] memory consumers);

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @param newOwner - proposed new owner of the subscription
     */
    function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

    /**
     * @notice Request subscription owner transfer.
     * @param subId - ID of the subscription
     * @dev will revert if original owner of subId has
     * not requested that msg.sender become the new owner.
     */
    function acceptSubscriptionOwnerTransfer(uint64 subId) external;

    /**
     * @notice Add a consumer to a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - New consumer which can use the subscription
     */
    function addConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Remove a consumer from a VRF subscription.
     * @param subId - ID of the subscription
     * @param consumer - Consumer to remove from the subscription
     */
    function removeConsumer(uint64 subId, address consumer) external;

    /**
     * @notice Cancel a subscription
     * @param subId - ID of the subscription
     */
    function cancelSubscription(uint64 subId) external;

    /*
     * @notice Check to see if there exists a request commitment consumers
     * for all consumers and keyhashes for a given sub.
     * @param subId - ID of the subscription
     * @return true if there exists at least one unfulfilled request for the subscription, false
     * otherwise.
     */
    function pendingRequestExists(uint64 subId) external view returns (bool);

    function fulfillRandomnessResolver(uint64 _subId) external view returns (bool, bytes calldata);

    /*
     * @notice Get last pending request id
     */
    function lastPendingRequestId(address consumer, uint64 subId) external view returns (uint256);

    /*
     * @notice Get current nonce
     */
    function getCurrentNonce(address consumer, uint64 subId) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { ArbSys } from "../interfaces/ArbSys.sol";
import "../interfaces/ArbGasInfo.sol";
import "../interfaces/OVM_GasPriceOracle.sol";

/// @dev A library that abstracts out opcodes that behave differently across chains.
/// @dev The methods below return values that are pertinent to the given chain.
/// @dev For instance, ChainSpecificUtil.getBlockNumber() returns L2 block number in L2 chains
library ChainSpecificUtil {
  // ------------ Start Arbitrum Constants ------------

  /// @dev ARBSYS_ADDR is the address of the ArbSys precompile on Arbitrum.
  /// @dev reference: https://github.com/OffchainLabs/nitro/blob/v2.0.14/contracts/src/precompiles/ArbSys.sol#L10
  address private constant ARBSYS_ADDR = address(0x0000000000000000000000000000000000000064);
  ArbSys private constant ARBSYS = ArbSys(ARBSYS_ADDR);

  /// @dev ARBGAS_ADDR is the address of the ArbGasInfo precompile on Arbitrum.
  /// @dev reference: https://github.com/OffchainLabs/nitro/blob/v2.0.14/contracts/src/precompiles/ArbGasInfo.sol#L10
  address private constant ARBGAS_ADDR = address(0x000000000000000000000000000000000000006C);
  ArbGasInfo private constant ARBGAS = ArbGasInfo(ARBGAS_ADDR);

  uint256 private constant ARB_MAINNET_CHAIN_ID = 42161;
  uint256 private constant ARB_GOERLI_TESTNET_CHAIN_ID = 421613;
  uint256 private constant ARB_SEPOLIA_TESTNET_CHAIN_ID = 421614;

  // ------------ End Arbitrum Constants ------------

  // ------------ Start Optimism Constants ------------
  /// @dev L1_FEE_DATA_PADDING includes 35 bytes for L1 data padding for Optimism
  bytes internal constant L1_FEE_DATA_PADDING =
    "0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff";
  /// @dev OVM_GASPRICEORACLE_ADDR is the address of the OVM_GasPriceOracle precompile on Optimism.
  /// @dev reference: https://community.optimism.io/docs/developers/build/transaction-fees/#estimating-the-l1-data-fee
  address private constant OVM_GASPRICEORACLE_ADDR = address(0x420000000000000000000000000000000000000F);
  OVM_GasPriceOracle private constant OVM_GASPRICEORACLE = OVM_GasPriceOracle(OVM_GASPRICEORACLE_ADDR);

  uint256 private constant OP_MAINNET_CHAIN_ID = 10;
  uint256 private constant OP_GOERLI_CHAIN_ID = 420;
  uint256 private constant OP_SEPOLIA_CHAIN_ID = 11155420;

  /// @dev Base is a OP stack based rollup and follows the same L1 pricing logic as Optimism.
  uint256 private constant BASE_MAINNET_CHAIN_ID = 8453;
  uint256 private constant BASE_GOERLI_CHAIN_ID = 84531;

  // ------------ End Optimism Constants ------------

  /**
   * @notice Returns the blockhash for the given blockNumber.
   * @notice If the blockNumber is more than 256 blocks in the past, returns the empty string.
   * @notice When on a known Arbitrum chain, it uses ArbSys.arbBlockHash to get the blockhash.
   * @notice Otherwise, it uses the blockhash opcode.
   * @notice Note that the blockhash opcode will return the L2 blockhash on Optimism.
   */
  function _getBlockhash(uint64 blockNumber) internal view returns (bytes32) {
    uint256 chainid = block.chainid;
    if (_isArbitrumChainId(chainid)) {
      if ((_getBlockNumber() - blockNumber) > 256 || blockNumber >= _getBlockNumber()) {
        return "";
      }
      return ARBSYS.arbBlockHash(blockNumber);
    }
    return blockhash(blockNumber);
  }

  /**
   * @notice Returns the block number of the current block.
   * @notice When on a known Arbitrum chain, it uses ArbSys.arbBlockNumber to get the block number.
   * @notice Otherwise, it uses the block.number opcode.
   * @notice Note that the block.number opcode will return the L2 block number on Optimism.
   */
  function _getBlockNumber() internal view returns (uint256) {
    uint256 chainid = block.chainid;
    if (_isArbitrumChainId(chainid)) {
      return ARBSYS.arbBlockNumber();
    }
    return block.number;
  }

  /**
   * @notice Returns the L1 fees that will be paid for the current transaction, given any calldata
   * @notice for the current transaction.
   * @notice When on a known Arbitrum chain, it uses ArbGas.getCurrentTxL1GasFees to get the fees.
   * @notice On Arbitrum, the provided calldata is not used to calculate the fees.
   * @notice On Optimism, the provided calldata is passed to the OVM_GasPriceOracle predeploy
   * @notice and getL1Fee is called to get the fees.
   */
  function _getCurrentTxL1GasFees(bytes memory txCallData) internal view returns (uint256) {
    uint256 chainid = block.chainid;
    if (_isArbitrumChainId(chainid)) {
      return ARBGAS.getCurrentTxL1GasFees();
    } else if (_isOptimismChainId(chainid)) {
      return OVM_GASPRICEORACLE.getL1Fee(bytes.concat(txCallData, L1_FEE_DATA_PADDING));
    }
    return 0;
  }

  /**
   * @notice Returns the gas cost in wei of calldataSizeBytes of calldata being posted
   * @notice to L1.
   */
  function _getL1CalldataGasCost(uint256 calldataSizeBytes) internal view returns (uint256) {
    uint256 chainid = block.chainid;
    if (_isArbitrumChainId(chainid)) {
      (, uint256 l1PricePerByte, , , , ) = ARBGAS.getPricesInWei();
      // see https://developer.arbitrum.io/devs-how-tos/how-to-estimate-gas#where-do-we-get-all-this-information-from
      // for the justification behind the 140 number.
      return l1PricePerByte * (calldataSizeBytes + 140);
    } else if (_isOptimismChainId(chainid)) {
      return _calculateOptimismL1DataFee(calldataSizeBytes);
    }
    return 0;
  }

  /**
   * @notice Return true if and only if the provided chain ID is an Arbitrum chain ID.
   */
  function _isArbitrumChainId(uint256 chainId) internal pure returns (bool) {
    return
      chainId == ARB_MAINNET_CHAIN_ID ||
      chainId == ARB_GOERLI_TESTNET_CHAIN_ID ||
      chainId == ARB_SEPOLIA_TESTNET_CHAIN_ID;
  }

  /**
   * @notice Return true if and only if the provided chain ID is an Optimism chain ID.
   * @notice Note that optimism chain id's are also OP stack chain id's.
   */
  function _isOptimismChainId(uint256 chainId) internal pure returns (bool) {
    return
      chainId == OP_MAINNET_CHAIN_ID ||
      chainId == OP_GOERLI_CHAIN_ID ||
      chainId == OP_SEPOLIA_CHAIN_ID ||
      chainId == BASE_MAINNET_CHAIN_ID ||
      chainId == BASE_GOERLI_CHAIN_ID;
  }

  function _calculateOptimismL1DataFee(uint256 calldataSizeBytes) internal view returns (uint256) {
    // from: https://community.optimism.io/docs/developers/build/transaction-fees/#the-l1-data-fee
    // l1_data_fee = l1_gas_price * (tx_data_gas + fixed_overhead) * dynamic_overhead
    // tx_data_gas = count_zero_bytes(tx_data) * 4 + count_non_zero_bytes(tx_data) * 16
    // note we conservatively assume all non-zero bytes.
    uint256 l1BaseFeeWei = OVM_GASPRICEORACLE.l1BaseFee();
    uint256 numZeroBytes = 0;
    uint256 numNonzeroBytes = calldataSizeBytes - numZeroBytes;
    uint256 txDataGas = numZeroBytes * 4 + numNonzeroBytes * 16;
    uint256 fixedOverhead = OVM_GASPRICEORACLE.overhead();

    // The scalar is some value like 0.684, but is represented as
    // that times 10 ^ number of scalar decimals.
    // e.g scalar = 0.684 * 10^6
    // The divisor is used to divide that and have a net result of the true scalar.
    uint256 scalar = OVM_GASPRICEORACLE.scalar();
    uint256 scalarDecimals = OVM_GASPRICEORACLE.decimals();
    uint256 divisor = 10 ** scalarDecimals;

    uint256 l1DataFee = (l1BaseFeeWei * (txDataGas + fixedOverhead) * scalar) / divisor;
    return l1DataFee;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** ****************************************************************************
  * @notice Verification of verifiable-random-function (VRF) proofs, following
  * @notice https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.3
  * @notice See https://eprint.iacr.org/2017/099.pdf for security proofs.

  * @dev Bibliographic references:

  * @dev Goldberg, et al., "Verifiable Random Functions (VRFs)", Internet Draft
  * @dev draft-irtf-cfrg-vrf-05, IETF, Aug 11 2019,
  * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05

  * @dev Papadopoulos, et al., "Making NSEC5 Practical for DNSSEC", Cryptology
  * @dev ePrint Archive, Report 2017/099, https://eprint.iacr.org/2017/099.pdf
  * ****************************************************************************
  * @dev USAGE

  * @dev The main entry point is _randomValueFromVRFProof. See its docstring.
  * ****************************************************************************
  * @dev PURPOSE

  * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
  * @dev to Vera the verifier in such a way that Vera can be sure he's not
  * @dev making his output up to suit himself. Reggie provides Vera a public key
  * @dev to which he knows the secret key. Each time Vera provides a seed to
  * @dev Reggie, he gives back a value which is computed completely
  * @dev deterministically from the seed and the secret key.

  * @dev Reggie provides a proof by which Vera can verify that the output was
  * @dev correctly computed once Reggie tells it to her, but without that proof,
  * @dev the output is computationally indistinguishable to her from a uniform
  * @dev random sample from the output space.

  * @dev The purpose of this contract is to perform that verification.
  * ****************************************************************************
  * @dev DESIGN NOTES

  * @dev The VRF algorithm verified here satisfies the full uniqueness, full
  * @dev collision resistance, and full pseudo-randomness security properties.
  * @dev See "SECURITY PROPERTIES" below, and
  * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-3

  * @dev An elliptic curve point is generally represented in the solidity code
  * @dev as a uint256[2], corresponding to its affine coordinates in
  * @dev GF(FIELD_SIZE).

  * @dev For the sake of efficiency, this implementation deviates from the spec
  * @dev in some minor ways:

  * @dev - Keccak hash rather than the SHA256 hash recommended in
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5
  * @dev   Keccak costs much less gas on the EVM, and provides similar security.

  * @dev - Secp256k1 curve instead of the P-256 or ED25519 curves recommended in
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5
  * @dev   For curve-point multiplication, it's much cheaper to abuse ECRECOVER

  * @dev - _hashToCurve recursively hashes until it finds a curve x-ordinate. On
  * @dev   the EVM, this is slightly more efficient than the recommendation in
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.1.1
  * @dev   step 5, to concatenate with a nonce then hash, and rehash with the
  * @dev   nonce updated until a valid x-ordinate is found.

  * @dev - _hashToCurve does not include a cipher version string or the byte 0x1
  * @dev   in the hash message, as recommended in step 5.B of the draft
  * @dev   standard. They are unnecessary here because no variation in the
  * @dev   cipher suite is allowed.

  * @dev - Similarly, the hash input in _scalarFromCurvePoints does not include a
  * @dev   commitment to the cipher suite, either, which differs from step 2 of
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.3
  * @dev   . Also, the hash input is the concatenation of the uncompressed
  * @dev   points, not the compressed points as recommended in step 3.

  * @dev - In the calculation of the challenge value "c", the "u" value (i.e.
  * @dev   the value computed by Reggie as the nonce times the secp256k1
  * @dev   generator point, see steps 5 and 7 of
  * @dev   https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.3
  * @dev   ) is replaced by its ethereum address, i.e. the lower 160 bits of the
  * @dev   keccak hash of the original u. This is because we only verify the
  * @dev   calculation of u up to its address, by abusing ECRECOVER.
  * ****************************************************************************
  * @dev   SECURITY PROPERTIES

  * @dev Here are the security properties for this VRF:

  * @dev Full uniqueness: For any seed and valid VRF public key, there is
  * @dev   exactly one VRF output which can be proved to come from that seed, in
  * @dev   the sense that the proof will pass _verifyVRFProof.

  * @dev Full collision resistance: It's cryptographically infeasible to find
  * @dev   two seeds with same VRF output from a fixed, valid VRF key

  * @dev Full pseudorandomness: Absent the proofs that the VRF outputs are
  * @dev   derived from a given seed, the outputs are computationally
  * @dev   indistinguishable from randomness.

  * @dev https://eprint.iacr.org/2017/099.pdf, Appendix B contains the proofs
  * @dev for these properties.

  * @dev For secp256k1, the key validation described in section
  * @dev https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.6
  * @dev is unnecessary, because secp256k1 has cofactor 1, and the
  * @dev representation of the public key used here (affine x- and y-ordinates
  * @dev of the secp256k1 point on the standard y^2=x^3+7 curve) cannot refer to
  * @dev the point at infinity.
  * ****************************************************************************
  * @dev OTHER SECURITY CONSIDERATIONS
  *
  * @dev The seed input to the VRF could in principle force an arbitrary amount
  * @dev of work in _hashToCurve, by requiring extra rounds of hashing and
  * @dev checking whether that's yielded the x ordinate of a secp256k1 point.
  * @dev However, under the Random Oracle Model the probability of choosing a
  * @dev point which forces n extra rounds in _hashToCurve is 2⁻ⁿ. The base cost
  * @dev for calling _hashToCurve is about 25,000 gas, and each round of checking
  * @dev for a valid x ordinate costs about 15,555 gas, so to find a seed for
  * @dev which _hashToCurve would cost more than 2,017,000 gas, one would have to
  * @dev try, in expectation, about 2¹²⁸ seeds, which is infeasible for any
  * @dev foreseeable computational resources. (25,000 + 128 * 15,555 < 2,017,000.)

  * @dev Since the gas block limit for the Ethereum main net is 10,000,000 gas,
  * @dev this means it is infeasible for an adversary to prevent correct
  * @dev operation of this contract by choosing an adverse seed.

  * @dev (See TestMeasureHashToCurveGasCost for verification of the gas cost for
  * @dev _hashToCurve.)

  * @dev It may be possible to make a secure constant-time _hashToCurve function.
  * @dev See notes in _hashToCurve docstring.
*/
contract VRF {
  // See https://www.secg.org/sec2-v2.pdf, section 2.4.1, for these constants.
  // Number of points in Secp256k1
  uint256 private constant GROUP_ORDER = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;
  // Prime characteristic of the galois field over which Secp256k1 is defined
  uint256 private constant FIELD_SIZE =
    // solium-disable-next-line indentation
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
  uint256 private constant WORD_LENGTH_BYTES = 0x20;

  // (base^exponent) % FIELD_SIZE
  // Cribbed from https://medium.com/@rbkhmrcr/precompiles-solidity-e5d29bd428c4
  function _bigModExp(uint256 base, uint256 exponent) internal view returns (uint256 exponentiation) {
    uint256 callResult;
    uint256[6] memory bigModExpContractInputs;
    bigModExpContractInputs[0] = WORD_LENGTH_BYTES; // Length of base
    bigModExpContractInputs[1] = WORD_LENGTH_BYTES; // Length of exponent
    bigModExpContractInputs[2] = WORD_LENGTH_BYTES; // Length of modulus
    bigModExpContractInputs[3] = base;
    bigModExpContractInputs[4] = exponent;
    bigModExpContractInputs[5] = FIELD_SIZE;
    uint256[1] memory output;
    assembly {
      callResult := staticcall(
        not(0), // Gas cost: no limit
        0x05, // Bigmodexp contract address
        bigModExpContractInputs,
        0xc0, // Length of input segment: 6*0x20-bytes
        output,
        0x20 // Length of output segment
      )
    }
    if (callResult == 0) {
      // solhint-disable-next-line gas-custom-errors
      revert("bigModExp failure!");
    }
    return output[0];
  }

  // Let q=FIELD_SIZE. q % 4 = 3, ∴ x≡r^2 mod q ⇒ x^SQRT_POWER≡±r mod q.  See
  // https://en.wikipedia.org/wiki/Modular_square_root#Prime_or_prime_power_modulus
  uint256 private constant SQRT_POWER = (FIELD_SIZE + 1) >> 2;

  // Computes a s.t. a^2 = x in the field. Assumes a exists
  function _squareRoot(uint256 x) internal view returns (uint256) {
    return _bigModExp(x, SQRT_POWER);
  }

  // The value of y^2 given that (x,y) is on secp256k1.
  function _ySquared(uint256 x) internal pure returns (uint256) {
    // Curve is y^2=x^3+7. See section 2.4.1 of https://www.secg.org/sec2-v2.pdf
    uint256 xCubed = mulmod(x, mulmod(x, x, FIELD_SIZE), FIELD_SIZE);
    return addmod(xCubed, 7, FIELD_SIZE);
  }

  // True iff p is on secp256k1
  function _isOnCurve(uint256[2] memory p) internal pure returns (bool) {
    // Section 2.3.6. in https://www.secg.org/sec1-v2.pdf
    // requires each ordinate to be in [0, ..., FIELD_SIZE-1]
    // solhint-disable-next-line gas-custom-errors
    require(p[0] < FIELD_SIZE, "invalid x-ordinate");
    // solhint-disable-next-line gas-custom-errors
    require(p[1] < FIELD_SIZE, "invalid y-ordinate");
    return _ySquared(p[0]) == mulmod(p[1], p[1], FIELD_SIZE);
  }

  // Hash x uniformly into {0, ..., FIELD_SIZE-1}.
  function _fieldHash(bytes memory b) internal pure returns (uint256 x_) {
    x_ = uint256(keccak256(b));
    // Rejecting if x >= FIELD_SIZE corresponds to step 2.1 in section 2.3.4 of
    // http://www.secg.org/sec1-v2.pdf , which is part of the definition of
    // string_to_point in the IETF draft
    while (x_ >= FIELD_SIZE) {
      x_ = uint256(keccak256(abi.encodePacked(x_)));
    }
    return x_;
  }

  // Hash b to a random point which hopefully lies on secp256k1. The y ordinate
  // is always even, due to
  // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.1.1
  // step 5.C, which references arbitrary_string_to_point, defined in
  // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.5 as
  // returning the point with given x ordinate, and even y ordinate.
  function _newCandidateSecp256k1Point(bytes memory b) internal view returns (uint256[2] memory p) {
    unchecked {
      p[0] = _fieldHash(b);
      p[1] = _squareRoot(_ySquared(p[0]));
      if (p[1] % 2 == 1) {
        // Note that 0 <= p[1] < FIELD_SIZE
        // so this cannot wrap, we use unchecked to save gas.
        p[1] = FIELD_SIZE - p[1];
      }
    }
    return p;
  }

  // Domain-separation tag for initial hash in _hashToCurve. Corresponds to
  // vrf.go/hashToCurveHashPrefix
  uint256 internal constant HASH_TO_CURVE_HASH_PREFIX = 1;

  // Cryptographic hash function onto the curve.
  //
  // Corresponds to algorithm in section 5.4.1.1 of the draft standard. (But see
  // DESIGN NOTES above for slight differences.)
  //
  // TODO(alx): Implement a bounded-computation hash-to-curve, as described in
  // "Construction of Rational Points on Elliptic Curves over Finite Fields"
  // http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.831.5299&rep=rep1&type=pdf
  // and suggested by
  // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-hash-to-curve-01#section-5.2.2
  // (Though we can't used exactly that because secp256k1's j-invariant is 0.)
  //
  // This would greatly simplify the analysis in "OTHER SECURITY CONSIDERATIONS"
  // https://www.pivotaltracker.com/story/show/171120900
  function _hashToCurve(uint256[2] memory pk, uint256 input) internal view returns (uint256[2] memory rv) {
    rv = _newCandidateSecp256k1Point(abi.encodePacked(HASH_TO_CURVE_HASH_PREFIX, pk, input));
    while (!_isOnCurve(rv)) {
      rv = _newCandidateSecp256k1Point(abi.encodePacked(rv[0]));
    }
    return rv;
  }

  /** *********************************************************************
   * @notice Check that product==scalar*multiplicand
   *
   * @dev Based on Vitalik Buterin's idea in ethresear.ch post cited below.
   *
   * @param multiplicand: secp256k1 point
   * @param scalar: non-zero GF(GROUP_ORDER) scalar
   * @param product: secp256k1 expected to be multiplier * multiplicand
   * @return verifies true iff product==scalar*multiplicand, with cryptographically high probability
   */
  function _ecmulVerify(
    uint256[2] memory multiplicand,
    uint256 scalar,
    uint256[2] memory product
  ) internal pure returns (bool verifies) {
    // solhint-disable-next-line gas-custom-errors
    require(scalar != 0, "zero scalar"); // Rules out an ecrecover failure case
    uint256 x = multiplicand[0]; // x ordinate of multiplicand
    uint8 v = multiplicand[1] % 2 == 0 ? 27 : 28; // parity of y ordinate
    // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
    // Point corresponding to address ecrecover(0, v, x, s=scalar*x) is
    // (x⁻¹ mod GROUP_ORDER) * (scalar * x * multiplicand - 0 * g), i.e.
    // scalar*multiplicand. See https://crypto.stackexchange.com/a/18106
    bytes32 scalarTimesX = bytes32(mulmod(scalar, x, GROUP_ORDER));
    address actual = ecrecover(bytes32(0), v, bytes32(x), scalarTimesX);
    // Explicit conversion to address takes bottom 160 bits
    address expected = address(uint160(uint256(keccak256(abi.encodePacked(product)))));
    return (actual == expected);
  }

  // Returns x1/z1-x2/z2=(x1z2-x2z1)/(z1z2) in projective coordinates on P¹(𝔽ₙ)
  function _projectiveSub(
    uint256 x1,
    uint256 z1,
    uint256 x2,
    uint256 z2
  ) internal pure returns (uint256 x3, uint256 z3) {
    unchecked {
      uint256 num1 = mulmod(z2, x1, FIELD_SIZE);
      // Note this cannot wrap since x2 is a point in [0, FIELD_SIZE-1]
      // we use unchecked to save gas.
      uint256 num2 = mulmod(FIELD_SIZE - x2, z1, FIELD_SIZE);
      (x3, z3) = (addmod(num1, num2, FIELD_SIZE), mulmod(z1, z2, FIELD_SIZE));
    }
    return (x3, z3);
  }

  // Returns x1/z1*x2/z2=(x1x2)/(z1z2), in projective coordinates on P¹(𝔽ₙ)
  function _projectiveMul(
    uint256 x1,
    uint256 z1,
    uint256 x2,
    uint256 z2
  ) internal pure returns (uint256 x3, uint256 z3) {
    (x3, z3) = (mulmod(x1, x2, FIELD_SIZE), mulmod(z1, z2, FIELD_SIZE));
    return (x3, z3);
  }

  /** **************************************************************************
        @notice Computes elliptic-curve sum, in projective co-ordinates

        @dev Using projective coordinates avoids costly divisions

        @dev To use this with p and q in affine coordinates, call
        @dev _projectiveECAdd(px, py, qx, qy). This will return
        @dev the addition of (px, py, 1) and (qx, qy, 1), in the
        @dev secp256k1 group.

        @dev This can be used to calculate the z which is the inverse to zInv
        @dev in isValidVRFOutput. But consider using a faster
        @dev re-implementation such as ProjectiveECAdd in the golang vrf package.

        @dev This function assumes [px,py,1],[qx,qy,1] are valid projective
             coordinates of secp256k1 points. That is safe in this contract,
             because this method is only used by _linearCombination, which checks
             points are on the curve via ecrecover.
        **************************************************************************
        @param px The first affine coordinate of the first summand
        @param py The second affine coordinate of the first summand
        @param qx The first affine coordinate of the second summand
        @param qy The second affine coordinate of the second summand

        (px,py) and (qx,qy) must be distinct, valid secp256k1 points.
        **************************************************************************
        Return values are projective coordinates of [px,py,1]+[qx,qy,1] as points
        on secp256k1, in P²(𝔽ₙ)
        @return sx
        @return sy
        @return sz
    */
  function _projectiveECAdd(
    uint256 px,
    uint256 py,
    uint256 qx,
    uint256 qy
  ) internal pure returns (uint256 sx, uint256 sy, uint256 sz) {
    unchecked {
      // See "Group law for E/K : y^2 = x^3 + ax + b", in section 3.1.2, p. 80,
      // "Guide to Elliptic Curve Cryptography" by Hankerson, Menezes and Vanstone
      // We take the equations there for (sx,sy), and homogenize them to
      // projective coordinates. That way, no inverses are required, here, and we
      // only need the one inverse in _affineECAdd.

      // We only need the "point addition" equations from Hankerson et al. Can
      // skip the "point doubling" equations because p1 == p2 is cryptographically
      // impossible, and required not to be the case in _linearCombination.

      // Add extra "projective coordinate" to the two points
      (uint256 z1, uint256 z2) = (1, 1);

      // (lx, lz) = (qy-py)/(qx-px), i.e., gradient of secant line.
      // Cannot wrap since px and py are in [0, FIELD_SIZE-1]
      uint256 lx = addmod(qy, FIELD_SIZE - py, FIELD_SIZE);
      uint256 lz = addmod(qx, FIELD_SIZE - px, FIELD_SIZE);

      uint256 dx; // Accumulates denominator from sx calculation
      // sx=((qy-py)/(qx-px))^2-px-qx
      (sx, dx) = _projectiveMul(lx, lz, lx, lz); // ((qy-py)/(qx-px))^2
      (sx, dx) = _projectiveSub(sx, dx, px, z1); // ((qy-py)/(qx-px))^2-px
      (sx, dx) = _projectiveSub(sx, dx, qx, z2); // ((qy-py)/(qx-px))^2-px-qx

      uint256 dy; // Accumulates denominator from sy calculation
      // sy=((qy-py)/(qx-px))(px-sx)-py
      (sy, dy) = _projectiveSub(px, z1, sx, dx); // px-sx
      (sy, dy) = _projectiveMul(sy, dy, lx, lz); // ((qy-py)/(qx-px))(px-sx)
      (sy, dy) = _projectiveSub(sy, dy, py, z1); // ((qy-py)/(qx-px))(px-sx)-py

      if (dx != dy) {
        // Cross-multiply to put everything over a common denominator
        sx = mulmod(sx, dy, FIELD_SIZE);
        sy = mulmod(sy, dx, FIELD_SIZE);
        sz = mulmod(dx, dy, FIELD_SIZE);
      } else {
        // Already over a common denominator, use that for z ordinate
        sz = dx;
      }
    }
    return (sx, sy, sz);
  }

  // p1+p2, as affine points on secp256k1.
  //
  // invZ must be the inverse of the z returned by _projectiveECAdd(p1, p2).
  // It is computed off-chain to save gas.
  //
  // p1 and p2 must be distinct, because _projectiveECAdd doesn't handle
  // point doubling.
  function _affineECAdd(
    uint256[2] memory p1,
    uint256[2] memory p2,
    uint256 invZ
  ) internal pure returns (uint256[2] memory) {
    uint256 x;
    uint256 y;
    uint256 z;
    (x, y, z) = _projectiveECAdd(p1[0], p1[1], p2[0], p2[1]);
    // solhint-disable-next-line gas-custom-errors
    require(mulmod(z, invZ, FIELD_SIZE) == 1, "invZ must be inverse of z");
    // Clear the z ordinate of the projective representation by dividing through
    // by it, to obtain the affine representation
    return [mulmod(x, invZ, FIELD_SIZE), mulmod(y, invZ, FIELD_SIZE)];
  }

  // True iff address(c*p+s*g) == lcWitness, where g is generator. (With
  // cryptographically high probability.)
  function _verifyLinearCombinationWithGenerator(
    uint256 c,
    uint256[2] memory p,
    uint256 s,
    address lcWitness
  ) internal pure returns (bool) {
    // Rule out ecrecover failure modes which return address 0.
    unchecked {
      // solhint-disable-next-line gas-custom-errors
      require(lcWitness != address(0), "bad witness");
      uint8 v = (p[1] % 2 == 0) ? 27 : 28; // parity of y-ordinate of p
      // Note this cannot wrap (X - Y % X), but we use unchecked to save
      // gas.
      bytes32 pseudoHash = bytes32(GROUP_ORDER - mulmod(p[0], s, GROUP_ORDER)); // -s*p[0]
      bytes32 pseudoSignature = bytes32(mulmod(c, p[0], GROUP_ORDER)); // c*p[0]
      // https://ethresear.ch/t/you-can-kinda-abuse-ecrecover-to-do-ecmul-in-secp256k1-today/2384/9
      // The point corresponding to the address returned by
      // ecrecover(-s*p[0],v,p[0],c*p[0]) is
      // (p[0]⁻¹ mod GROUP_ORDER)*(c*p[0]-(-s)*p[0]*g)=c*p+s*g.
      // See https://crypto.stackexchange.com/a/18106
      // https://bitcoin.stackexchange.com/questions/38351/ecdsa-v-r-s-what-is-v
      address computed = ecrecover(pseudoHash, v, bytes32(p[0]), pseudoSignature);
      return computed == lcWitness;
    }
  }

  // c*p1 + s*p2. Requires cp1Witness=c*p1 and sp2Witness=s*p2. Also
  // requires cp1Witness != sp2Witness (which is fine for this application,
  // since it is cryptographically impossible for them to be equal. In the
  // (cryptographically impossible) case that a prover accidentally derives
  // a proof with equal c*p1 and s*p2, they should retry with a different
  // proof nonce.) Assumes that all points are on secp256k1
  // (which is checked in _verifyVRFProof below.)
  function _linearCombination(
    uint256 c,
    uint256[2] memory p1,
    uint256[2] memory cp1Witness,
    uint256 s,
    uint256[2] memory p2,
    uint256[2] memory sp2Witness,
    uint256 zInv
  ) internal pure returns (uint256[2] memory) {
    unchecked {
      // Note we are relying on the wrap around here
      // solhint-disable-next-line gas-custom-errors
      require((cp1Witness[0] % FIELD_SIZE) != (sp2Witness[0] % FIELD_SIZE), "points in sum must be distinct");
      // solhint-disable-next-line gas-custom-errors
      require(_ecmulVerify(p1, c, cp1Witness), "First mul check failed");
      // solhint-disable-next-line gas-custom-errors
      require(_ecmulVerify(p2, s, sp2Witness), "Second mul check failed");
      return _affineECAdd(cp1Witness, sp2Witness, zInv);
    }
  }

  // Domain-separation tag for the hash taken in _scalarFromCurvePoints.
  // Corresponds to scalarFromCurveHashPrefix in vrf.go
  uint256 internal constant SCALAR_FROM_CURVE_POINTS_HASH_PREFIX = 2;

  // Pseudo-random number from inputs. Matches vrf.go/_scalarFromCurvePoints, and
  // https://datatracker.ietf.org/doc/html/draft-irtf-cfrg-vrf-05#section-5.4.3
  // The draft calls (in step 7, via the definition of string_to_int, in
  // https://datatracker.ietf.org/doc/html/rfc8017#section-4.2 ) for taking the
  // first hash without checking that it corresponds to a number less than the
  // group order, which will lead to a slight bias in the sample.
  //
  // TODO(alx): We could save a bit of gas by following the standard here and
  // using the compressed representation of the points, if we collated the y
  // parities into a single bytes32.
  // https://www.pivotaltracker.com/story/show/171120588
  function _scalarFromCurvePoints(
    uint256[2] memory hash,
    uint256[2] memory pk,
    uint256[2] memory gamma,
    address uWitness,
    uint256[2] memory v
  ) internal pure returns (uint256 s) {
    return uint256(keccak256(abi.encodePacked(SCALAR_FROM_CURVE_POINTS_HASH_PREFIX, hash, pk, gamma, v, uWitness)));
  }

  // True if (gamma, c, s) is a correctly constructed randomness proof from pk
  // and seed. zInv must be the inverse of the third ordinate from
  // _projectiveECAdd applied to cGammaWitness and sHashWitness. Corresponds to
  // section 5.3 of the IETF draft.
  //
  // TODO(alx): Since I'm only using pk in the ecrecover call, I could only pass
  // the x ordinate, and the parity of the y ordinate in the top bit of uWitness
  // (which I could make a uint256 without using any extra space.) Would save
  // about 2000 gas. https://www.pivotaltracker.com/story/show/170828567
  function _verifyVRFProof(
    uint256[2] memory pk,
    uint256[2] memory gamma,
    uint256 c,
    uint256 s,
    uint256 seed,
    address uWitness,
    uint256[2] memory cGammaWitness,
    uint256[2] memory sHashWitness,
    uint256 zInv
  ) internal view {
    unchecked {
      // solhint-disable-next-line gas-custom-errors
      require(_isOnCurve(pk), "public key is not on curve");
      // solhint-disable-next-line gas-custom-errors
      require(_isOnCurve(gamma), "gamma is not on curve");
      // solhint-disable-next-line gas-custom-errors
      require(_isOnCurve(cGammaWitness), "cGammaWitness is not on curve");
      // solhint-disable-next-line gas-custom-errors
      require(_isOnCurve(sHashWitness), "sHashWitness is not on curve");
      // Step 5. of IETF draft section 5.3 (pk corresponds to 5.3's Y, and here
      // we use the address of u instead of u itself. Also, here we add the
      // terms instead of taking the difference, and in the proof construction in
      // vrf.GenerateProof, we correspondingly take the difference instead of
      // taking the sum as they do in step 7 of section 5.1.)
      // solhint-disable-next-line gas-custom-errors
      require(_verifyLinearCombinationWithGenerator(c, pk, s, uWitness), "addr(c*pk+s*g)!=_uWitness");
      // Step 4. of IETF draft section 5.3 (pk corresponds to Y, seed to alpha_string)
      uint256[2] memory hash = _hashToCurve(pk, seed);
      // Step 6. of IETF draft section 5.3, but see note for step 5 about +/- terms
      uint256[2] memory v = _linearCombination(c, gamma, cGammaWitness, s, hash, sHashWitness, zInv);
      // Steps 7. and 8. of IETF draft section 5.3
      uint256 derivedC = _scalarFromCurvePoints(hash, pk, gamma, uWitness, v);
      // solhint-disable-next-line gas-custom-errors
      require(c == derivedC, "invalid proof");
    }
  }

  // Domain-separation tag for the hash used as the final VRF output.
  // Corresponds to vrfRandomOutputHashPrefix in vrf.go
  uint256 internal constant VRF_RANDOM_OUTPUT_HASH_PREFIX = 3;

  struct Proof {
    uint256[2] pk;
    uint256[2] gamma;
    uint256 c;
    uint256 s;
    uint256 seed;
    address uWitness;
    uint256[2] cGammaWitness;
    uint256[2] sHashWitness;
    uint256 zInv;
  }

  /* ***************************************************************************
     * @notice Returns proof's output, if proof is valid. Otherwise reverts

     * @param proof vrf proof components
     * @param seed  seed used to generate the vrf output
     *
     * Throws if proof is invalid, otherwise:
     * @return output i.e., the random output implied by the proof
     * ***************************************************************************
     */
  function _randomValueFromVRFProof(Proof memory proof, uint256 seed) internal view returns (uint256 output) {
    _verifyVRFProof(
      proof.pk,
      proof.gamma,
      proof.c,
      proof.s,
      seed,
      proof.uWitness,
      proof.cGammaWitness,
      proof.sHashWitness,
      proof.zInv
    );
    output = uint256(keccak256(abi.encode(VRF_RANDOM_OUTPUT_HASH_PREFIX, proof.gamma)));
    return output;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/VRFAgentCoordinatorInterface.sol";
import "./interfaces/VRFAgentConsumerInterface.sol";
import "./interfaces/VRFChainlinkCoordinatorInterface.sol";

/**
 * @title VRFAgentConsumer
 * @author PowerPool
 */
contract VRFAgentConsumer is VRFAgentConsumerInterface, Ownable {
    uint32 public constant VRF_NUM_RANDOM_WORDS = 10;

    address public agent;
    address public vrfCoordinator;
    bytes32 public vrfKeyHash;
    uint64 public vrfSubscriptionId;
    uint16 public vrfRequestConfirmations;
    uint32 public vrfCallbackGasLimit;

    uint256 public vrfRequestPeriod;
    uint256 public lastVrfFulfillAt;
    uint256 public lastVrfRequestAtBlock;

    uint256 public pendingRequestId;
    uint256[] public lastVrfNumbers;

    string public offChainIpfsHash;
    bool public useLocalIpfsHash;

    event SetVrfConfig(address vrfCoordinator, bytes32 vrfKeyHash, uint64 vrfSubscriptionId, uint16 vrfRequestConfirmations, uint32 vrfCallbackGasLimit, uint256 vrfRequestPeriod);
    event ClearPendingRequestId();
    event SetOffChainIpfsHash(string ipfsHash);

    constructor(address agent_) {
        agent = agent_;
    }

    /*** AGENT OWNER METHODS ***/
    function setVrfConfig(
        address vrfCoordinator_,
        bytes32 vrfKeyHash_,
        uint64 vrfSubscriptionId_,
        uint16 vrfRequestConfirmations_,
        uint32 vrfCallbackGasLimit_,
        uint256 vrfRequestPeriod_
    ) external onlyOwner {
        vrfCoordinator = vrfCoordinator_;
        vrfKeyHash = vrfKeyHash_;
        vrfSubscriptionId = vrfSubscriptionId_;
        vrfRequestConfirmations = vrfRequestConfirmations_;
        vrfCallbackGasLimit = vrfCallbackGasLimit_;
        vrfRequestPeriod = vrfRequestPeriod_;
        emit SetVrfConfig(vrfCoordinator_, vrfKeyHash_, vrfSubscriptionId_, vrfRequestConfirmations_, vrfCallbackGasLimit_, vrfRequestPeriod_);
    }

    function clearPendingRequestId() external onlyOwner {
        pendingRequestId = 0;
        emit ClearPendingRequestId();
    }

    function setOffChainIpfsHash(string calldata _ipfsHash) external onlyOwner {
        offChainIpfsHash = _ipfsHash;
        useLocalIpfsHash = bytes(offChainIpfsHash).length > 0;
        emit SetOffChainIpfsHash(_ipfsHash);
    }

    function rawFulfillRandomWords(
        uint256 _requestId,
        uint256[] memory _randomWords
    ) external {
        require(msg.sender == address(vrfCoordinator), "sender not vrfCoordinator");
        require(_requestId == pendingRequestId, "request not found");
        lastVrfNumbers = _randomWords;
        pendingRequestId = 0;
        if (vrfRequestPeriod != 0) {
            lastVrfFulfillAt = block.timestamp;
        }
    }

    function isReadyForRequest() public view returns (bool) {
        return pendingRequestId == 0
            && (vrfRequestPeriod == 0 || lastVrfFulfillAt + vrfRequestPeriod < block.timestamp);
    }

    function getLastBlockHash() public virtual view returns (uint256) {
        return uint256(blockhash(block.number - 1));
    }

    function getPseudoRandom() external returns (uint256) {
        if (msg.sender == agent && isReadyForRequest()) {
            pendingRequestId = _requestRandomWords();
            lastVrfRequestAtBlock = block.number;
        }
        uint256 blockHashNumber = getLastBlockHash();
        if (lastVrfNumbers.length > 0) {
            uint256 vrfNumberIndex = uint256(keccak256(abi.encodePacked(agent.balance))) % uint256(VRF_NUM_RANDOM_WORDS);
            blockHashNumber = uint256(keccak256(abi.encodePacked(blockHashNumber, lastVrfNumbers[vrfNumberIndex])));
        }
        return blockHashNumber;
    }

    function _requestRandomWords() internal virtual returns (uint256) {
        if (vrfKeyHash == bytes32(0)) {
            return VRFAgentCoordinatorInterface(vrfCoordinator).requestRandomWords(
                agent,
                vrfSubscriptionId,
                vrfRequestConfirmations,
                vrfCallbackGasLimit,
                VRF_NUM_RANDOM_WORDS
            );
        } else {
            return VRFChainlinkCoordinatorInterface(vrfCoordinator).requestRandomWords(
                vrfKeyHash,
                vrfSubscriptionId,
                vrfRequestConfirmations,
                vrfCallbackGasLimit,
                VRF_NUM_RANDOM_WORDS
            );
        }
    }

    function getLastVrfNumbers() external view returns (uint256[] memory) {
        return lastVrfNumbers;
    }

    function fulfillRandomnessResolver() external view returns (bool, bytes memory) {
        if (useLocalIpfsHash) {
            return (VRFAgentCoordinatorInterface(vrfCoordinator).pendingRequestExists(vrfSubscriptionId), bytes(offChainIpfsHash));
        } else {
            return VRFAgentCoordinatorInterface(vrfCoordinator).fulfillRandomnessResolver(vrfSubscriptionId);
        }
    }

    function lastPendingRequestId() external view returns (uint256) {
        return VRFAgentCoordinatorInterface(vrfCoordinator).lastPendingRequestId(address(this), vrfSubscriptionId);
    }

    function getRequestData() external view returns (
        uint256 subscriptionId,
        uint256 requestAtBlock,
        uint256 requestId,
        uint64 requestNonce,
        uint32 numbRandomWords,
        uint32 callbackGasLimit
    ) {
        return (
            vrfSubscriptionId,
            lastVrfRequestAtBlock,
            pendingRequestId,
            VRFAgentCoordinatorInterface(vrfCoordinator).getCurrentNonce(address(this), vrfSubscriptionId),
            VRF_NUM_RANDOM_WORDS,
            vrfCallbackGasLimit
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/VRFAgentCoordinatorInterface.sol";
import "./interfaces/VRFAgentConsumerFactoryInterface.sol";
import {VRF} from "./VRF.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./VRFAgentConsumer.sol";
import "./utils/ChainSpecificUtil.sol";

contract VRFAgentCoordinator is VRF, Ownable, VRFAgentCoordinatorInterface {
  // solhint-disable-next-line chainlink-solidity/prefix-immutable-variables-with-i
  using SafeERC20 for IERC20;

  // We need to maintain a list of consuming addresses.
  // This bound ensures we are able to loop over them as needed.
  // Should a user require more consumers, they can use multiple subscriptions.
  uint16 public constant MAX_CONSUMERS = 100;
  error TooManyConsumers();
  error InvalidConsumer(uint64 subId, address consumer);
  error InvalidSubscription();
  error InvalidCalldata();
  error MustBeSubOwner(address owner);
  error PendingRequestExists();
  error MustBeRequestedOwner(address proposedOwner);
  event FundsRecovered(address token, address to, uint256 amount);
  // We use the config for the mgmt APIs
  struct SubscriptionConfig {
    address owner; // Owner can fund/withdraw/cancel the sub.
    address requestedOwner; // For safely transferring sub ownership.
    // Maintains the list of keys in s_consumers.
    // We do this for 2 reasons:
    // 1. To be able to clean up all keys from s_consumers when canceling a subscription.
    // 2. To be able to return the list of all consumers in getSubscription.
    // Note that we need the s_consumers map to be able to directly check if a
    // consumer is valid without reading all the consumers from storage.
    address[] consumers;
  }
  // Note a nonce of 0 indicates an the consumer is not assigned to that subscription.
  mapping(address => mapping(uint64 => uint64)) /* consumer */ /* subId */ /* nonce */ private s_consumers;
  mapping(uint64 => SubscriptionConfig) /* subId */ /* subscriptionConfig */ private s_subscriptionConfigs;
  // We make the sub count public so that its possible to
  // get all the current subscriptions via getSubscription.
  uint64 private s_currentSubId;

  event SubscriptionCreated(uint64 indexed subId, address owner);
  event SubscriptionConsumerAdded(uint64 indexed subId, address consumer);
  event SubscriptionConsumerRemoved(uint64 indexed subId, address consumer);
  event SubscriptionCanceled(uint64 indexed subId);
  event SubscriptionOwnerTransferRequested(uint64 indexed subId, address from, address to);
  event SubscriptionOwnerTransferred(uint64 indexed subId, address from, address to);

  // Set this maximum to 200 to give us a 56 block window to fulfill
  // the request before requiring the block hash feeder.
  uint16 public constant MAX_REQUEST_CONFIRMATIONS = 200;
  uint32 public constant MAX_NUM_WORDS = 500;
  // 5k is plenty for an EXTCODESIZE call (2600) + warm CALL (100)
  // and some arithmetic operations.
  uint256 private constant GAS_FOR_CALL_EXACT_CHECK = 5_000;
  error InvalidRequestConfirmations(uint16 have, uint16 min, uint16 max);
  error GasLimitTooBig(uint32 have, uint32 want);
  error NumWordsTooBig(uint32 have, uint32 want);
  error AgentProviderAlreadyRegistered();
  error NoSuchProvingKey(bytes32 keyHash);
  error InsufficientGasForConsumer(uint256 have, uint256 want);
  error InvalidProvider();
  error InvalidTxOrigin();
  error NoCorrespondingRequest();
  error IncorrectCommitment();
  error BlockhashNotInStore(uint256 blockNum);
  error PaymentTooLarge();
  error Reentrant();
  struct RequestCommitment {
    uint64 blockNum;
    uint64 subId;
    uint32 callbackGasLimit;
    uint32 numWords;
    address sender;
  }
  mapping(address => bool) /* keyHash */ /* oracle */ private s_agentProviders;
  address[] private s_agentProvidersList;
  mapping(uint256 => bytes32) /* requestID */ /* commitment */ private s_requestCommitments;

  VRFAgentConsumerFactoryInterface consumerFactory;
  string private offChainIpfsHash;

  event SetConsumerFactory(address consumerFactory);
  event SetOffChainIpfsHash(string offChainIpfsHash);
  event AgentProviderRegistered(address indexed agent);
  event AgentProviderDeregistered(address indexed agent);
  event RandomWordsRequested(
    address indexed keyHash,
    uint256 indexed requestId,
    uint256 preSeed,
    uint64 indexed subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords,
    address sender
  );
  event RandomWordsFulfilled(uint256 indexed requestId, uint256 outputSeed, bool success);

  struct Config {
    uint16 minimumRequestConfirmations;
    uint32 maxGasLimit;
    // Reentrancy protection.
    bool reentrancyLock;
  }
  Config private s_config;
  event ConfigSet(
    uint16 minimumRequestConfirmations,
    uint32 maxGasLimit
  );

  constructor(VRFAgentConsumerFactoryInterface _consumerFactory) Ownable() {
    consumerFactory = _consumerFactory;
  }

  /**
   * @notice Set consumer factory
   * @param _consumerFactory address of the consumer factory
   */
  function setConsumerFactory(VRFAgentConsumerFactoryInterface _consumerFactory) external onlyOwner {
    consumerFactory = _consumerFactory;
    emit SetConsumerFactory(address(_consumerFactory));
  }

  /**
   * @notice Set OffChain IPFS hash
   * @param _offChainIpfsHash IPFS hash of OffChain script
   */
  function setOffChainIpfsHash(string calldata _offChainIpfsHash) external onlyOwner {
    offChainIpfsHash = _offChainIpfsHash;
    emit SetOffChainIpfsHash(_offChainIpfsHash);
  }

  /**
   * @notice Registers an agent as provider
   * @param agent address of the agent
   */
  function registerAgent(address agent) external onlyOwner {
    if (s_agentProviders[agent]) {
      revert AgentProviderAlreadyRegistered();
    }
    s_agentProviders[agent] = true;
    s_agentProvidersList.push(agent);
    emit AgentProviderRegistered(agent);
  }

  /**
   * @notice Deregisters an agent as provider
   * @param agent address of the agent
   */
  function deregisterAgent(address agent) external onlyOwner {
    delete s_agentProviders[agent];
    for (uint256 i = 0; i < s_agentProvidersList.length; i++) {
      if (s_agentProvidersList[i] == agent) {
        address last = s_agentProvidersList[s_agentProvidersList.length - 1];
        // Copy last element and overwrite kh to be deleted with it
        s_agentProvidersList[i] = last;
        s_agentProvidersList.pop();
      }
    }
    emit AgentProviderDeregistered(agent);
  }

  /**
   * @notice Sets the configuration of the vrfv2 coordinator
   * @param minimumRequestConfirmations global min for request confirmations
   * @param maxGasLimit global max for request gas limit
   */
  function setConfig(
    uint16 minimumRequestConfirmations,
    uint32 maxGasLimit
  ) external onlyOwner {
    if (minimumRequestConfirmations > MAX_REQUEST_CONFIRMATIONS) {
      revert InvalidRequestConfirmations(
        minimumRequestConfirmations,
        minimumRequestConfirmations,
        MAX_REQUEST_CONFIRMATIONS
      );
    }
    s_config = Config({
      minimumRequestConfirmations: minimumRequestConfirmations,
      maxGasLimit: maxGasLimit,
      reentrancyLock: false
    });
    emit ConfigSet(minimumRequestConfirmations, maxGasLimit);
  }

  function getConfig()
    external
    view
    returns (
      uint16 minimumRequestConfirmations,
      uint32 maxGasLimit
    )
  {
    return (
      s_config.minimumRequestConfirmations,
      s_config.maxGasLimit
    );
  }

  /**
   * @notice Owner cancel subscription
   * @param subId subscription id
   * @dev notably can be called even if there are pending requests, outstanding ones may fail onchain
   */
  function ownerCancelSubscription(uint64 subId) external onlyOwner {
    if (s_subscriptionConfigs[subId].owner == address(0)) {
      revert InvalidSubscription();
    }
    _cancelSubscriptionHelper(subId);
  }

  /**
   * @inheritdoc VRFAgentCoordinatorInterface
   */
  function getRequestConfig() external view override returns (uint16, uint32, address[] memory) {
    return (s_config.minimumRequestConfirmations, s_config.maxGasLimit, s_agentProvidersList);
  }

  /**
   * @inheritdoc VRFAgentCoordinatorInterface
   */
  function requestRandomWords(
    address agent,
    uint64 subId,
    uint16 requestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external override nonReentrant returns (uint256) {
    // Input validation using the subscription storage.
    if (s_subscriptionConfigs[subId].owner == address(0)) {
      revert InvalidSubscription();
    }
    // A nonce of 0 indicates consumer is not allocated to the sub.
    uint64 currentNonce = s_consumers[msg.sender][subId];
    if (currentNonce == 0) {
      revert InvalidConsumer(subId, msg.sender);
    }
    // Input validation using the config storage word.
    if (
      requestConfirmations < s_config.minimumRequestConfirmations || requestConfirmations > MAX_REQUEST_CONFIRMATIONS
    ) {
      revert InvalidRequestConfirmations(
        requestConfirmations,
        s_config.minimumRequestConfirmations,
        MAX_REQUEST_CONFIRMATIONS
      );
    }
    // No lower bound on the requested gas limit. A user could request 0
    // and they would simply be billed for the proof verification and wouldn't be
    // able to do anything with the random value.
    if (callbackGasLimit > s_config.maxGasLimit) {
      revert GasLimitTooBig(callbackGasLimit, s_config.maxGasLimit);
    }
    if (numWords > MAX_NUM_WORDS) {
      revert NumWordsTooBig(numWords, MAX_NUM_WORDS);
    }
    // Note we do not check whether the keyHash is valid to save gas.
    // The consequence for users is that they can send requests
    // for invalid keyHashes which will simply not be fulfilled.
    uint64 nonce = currentNonce + 1;
    (uint256 requestId, uint256 preSeed) = _computeRequestId(agent, msg.sender, subId, nonce);

    s_requestCommitments[requestId] = keccak256(
      abi.encode(requestId, ChainSpecificUtil._getBlockNumber(), subId, callbackGasLimit, numWords, msg.sender)
    );
    emit RandomWordsRequested(
      agent,
      requestId,
      preSeed,
      subId,
      requestConfirmations,
      callbackGasLimit,
      numWords,
      msg.sender
    );
    s_consumers[msg.sender][subId] = nonce;

    return requestId;
  }

  /**
   * @notice Get request commitment
   * @param requestId id of request
   * @dev used to determine if a request is fulfilled or not
   */
  function getCommitment(uint256 requestId) external view returns (bytes32) {
    return s_requestCommitments[requestId];
  }

  function _computeRequestId(
    address agent,
    address sender,
    uint64 subId,
    uint64 nonce
  ) private pure returns (uint256, uint256) {
    uint256 preSeed = uint256(keccak256(abi.encode(agent, sender, subId, nonce)));
    return (uint256(keccak256(abi.encode(agent, preSeed))), preSeed);
  }

  /**
   * @dev calls target address with exactly gasAmount gas and data as calldata
   * or reverts if at least gasAmount gas is not available.
   */
  function _callWithExactGas(uint256 gasAmount, address target, bytes memory data) private returns (bool success) {
    assembly {
      let g := gas()
      // Compute g -= GAS_FOR_CALL_EXACT_CHECK and check for underflow
      // The gas actually passed to the callee is min(gasAmount, 63//64*gas available).
      // We want to ensure that we revert if gasAmount >  63//64*gas available
      // as we do not want to provide them with less, however that check itself costs
      // gas.  GAS_FOR_CALL_EXACT_CHECK ensures we have at least enough gas to be able
      // to revert if gasAmount >  63//64*gas available.
      if lt(g, GAS_FOR_CALL_EXACT_CHECK) {
        revert(0, 0)
      }
      g := sub(g, GAS_FOR_CALL_EXACT_CHECK)
      // if g - g//64 <= gasAmount, revert
      // (we subtract g//64 because of EIP-150)
      if iszero(gt(sub(g, div(g, 64)), gasAmount)) {
        revert(0, 0)
      }
      // solidity calls check that a contract actually exists at the destination, so we do the same
      if iszero(extcodesize(target)) {
        revert(0, 0)
      }
      // call and return whether we succeeded. ignore return data
      // call(gas,addr,value,argsOffset,argsLength,retOffset,retLength)
      success := call(gasAmount, target, 0, add(data, 0x20), mload(data), 0, 0)
    }
    return success;
  }

  function publicKeyToAddress(uint[2] memory publicKey) public pure returns (address) {
    bytes32 hash = keccak256(abi.encodePacked(publicKey));
    return ecrecover(0, 0, hash, bytes32(publicKey[0] > 0 ? publicKey[0] : 1)); // recovering address
  }

  function _getRandomnessFromProof(
    Proof memory proof,
    RequestCommitment memory rc
  ) private view returns (bytes32 keyHash, uint256 requestId, uint256 randomness) {
    if (!s_agentProviders[msg.sender]) {
      revert InvalidProvider();
    }
//    if (publicKeyToAddress(proof.pk) != tx.origin) {
//      revert InvalidTxOrigin();
//    }
    requestId = uint256(keccak256(abi.encode(msg.sender, proof.seed)));
    bytes32 commitment = s_requestCommitments[requestId];
    if (commitment == 0) {
      revert NoCorrespondingRequest();
    }
    if (
      commitment != keccak256(abi.encode(requestId, rc.blockNum, rc.subId, rc.callbackGasLimit, rc.numWords, rc.sender))
    ) {
      revert IncorrectCommitment();
    }

    bytes32 blockHash = ChainSpecificUtil._getBlockhash(rc.blockNum);
    if (blockHash == bytes32(0)) {
      revert BlockhashNotInStore(rc.blockNum);
    }

    // The seed actually used by the VRF machinery, mixing in the blockhash
    keyHash = hashOfKey(proof.pk);
    uint256 actualSeed = uint256(keccak256(abi.encodePacked(proof.seed, blockHash, keyHash)));
    randomness = VRF._randomValueFromVRFProof(proof, actualSeed); // Reverts on failure
    return (keyHash, requestId, randomness);
  }

  /*
   * @notice Fulfill a randomness request
   * @param proof contains the proof and randomness
   * @param rc request commitment pre-image, committed to at request time
   */
  function fulfillRandomWords(Proof memory proof, RequestCommitment memory rc) external nonReentrant {
    (bytes32 keyHash, uint256 requestId, uint256 randomness) = _getRandomnessFromProof(proof, rc);
    //TODO: compare keyHash and proof.pk?

    uint256[] memory randomWords = new uint256[](rc.numWords);
    for (uint256 i = 0; i < rc.numWords; i++) {
      randomWords[i] = uint256(keccak256(abi.encode(randomness, i)));
    }

    delete s_requestCommitments[requestId];
    VRFAgentConsumer v;
    bytes memory resp = abi.encodeWithSelector(v.rawFulfillRandomWords.selector, requestId, randomWords);
    // Call with explicitly the amount of callback gas requested
    // Important to not let them exhaust the gas budget and avoid oracle payment.
    // Do not allow any non-view/non-pure coordinator functions to be called
    // during the consumers callback code via reentrancyLock.
    // Note that _callWithExactGas will revert if we do not have sufficient gas
    // to give the callee their requested amount.
    s_config.reentrancyLock = true;
    bool success = _callWithExactGas(rc.callbackGasLimit, rc.sender, resp);
    s_config.reentrancyLock = false;

    emit RandomWordsFulfilled(requestId, randomness, success);
  }

  function getCurrentSubId() external view returns (uint64) {
    return s_currentSubId;
  }

  /**
   * @inheritdoc VRFAgentCoordinatorInterface
   */
  function getSubscription(uint64 subId) external view override returns (address owner, address[] memory consumers) {
    if (s_subscriptionConfigs[subId].owner == address(0)) {
      revert InvalidSubscription();
    }
    return (
      s_subscriptionConfigs[subId].owner,
      s_subscriptionConfigs[subId].consumers
    );
  }

  /**
   * @inheritdoc VRFAgentCoordinatorInterface
   */
  function createSubscription() public override returns (uint64) {
    s_currentSubId++;
    uint64 subId = s_currentSubId;

    address[] memory consumers = new address[](1);
    s_subscriptionConfigs[subId] = SubscriptionConfig({
      owner: msg.sender,
      requestedOwner: address(0),
      consumers: consumers
    });

    emit SubscriptionCreated(subId, msg.sender);
    return subId;
  }

  function createSubscriptionWithConsumer() external override nonReentrant returns (uint64, address) {
    uint64 subId = createSubscription();
    address latestAgent = s_agentProvidersList[s_agentProvidersList.length - 1];
    VRFAgentConsumerInterface agentConsumer = consumerFactory.createConsumer(latestAgent, msg.sender);

    _addConsumer(subId, address(agentConsumer));

    return (subId, address(agentConsumer));
  }

  /**
   * @inheritdoc VRFAgentCoordinatorInterface
   */
  function requestSubscriptionOwnerTransfer(
    uint64 subId,
    address newOwner
  ) external override onlySubOwner(subId) nonReentrant {
    // Proposing to address(0) would never be claimable so don't need to check.
    if (s_subscriptionConfigs[subId].requestedOwner != newOwner) {
      s_subscriptionConfigs[subId].requestedOwner = newOwner;
      emit SubscriptionOwnerTransferRequested(subId, msg.sender, newOwner);
    }
  }

  /**
   * @inheritdoc VRFAgentCoordinatorInterface
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external override nonReentrant {
    if (s_subscriptionConfigs[subId].owner == address(0)) {
      revert InvalidSubscription();
    }
    if (s_subscriptionConfigs[subId].requestedOwner != msg.sender) {
      revert MustBeRequestedOwner(s_subscriptionConfigs[subId].requestedOwner);
    }
    address oldOwner = s_subscriptionConfigs[subId].owner;
    s_subscriptionConfigs[subId].owner = msg.sender;
    s_subscriptionConfigs[subId].requestedOwner = address(0);
    emit SubscriptionOwnerTransferred(subId, oldOwner, msg.sender);
  }

  /**
   * @inheritdoc VRFAgentCoordinatorInterface
   */
  function removeConsumer(uint64 subId, address consumer) external override onlySubOwner(subId) nonReentrant {
    if (pendingRequestExists(subId)) {
      revert PendingRequestExists();
    }
    if (s_consumers[consumer][subId] == 0) {
      revert InvalidConsumer(subId, consumer);
    }
    // Note bounded by MAX_CONSUMERS
    address[] memory consumers = s_subscriptionConfigs[subId].consumers;
    uint256 lastConsumerIndex = consumers.length - 1;
    for (uint256 i = 0; i < consumers.length; i++) {
      if (consumers[i] == consumer) {
        address last = consumers[lastConsumerIndex];
        // Storage write to preserve last element
        s_subscriptionConfigs[subId].consumers[i] = last;
        // Storage remove last element
        s_subscriptionConfigs[subId].consumers.pop();
        break;
      }
    }
    delete s_consumers[consumer][subId];
    emit SubscriptionConsumerRemoved(subId, consumer);
  }

  /**
   * @inheritdoc VRFAgentCoordinatorInterface
   */
  function addConsumer(uint64 subId, address consumer) external override onlySubOwner(subId) nonReentrant {
    _addConsumer(subId, consumer);
  }

  function _addConsumer(uint64 subId, address consumer) internal {
    // Already maxed, cannot add any more consumers.
    if (s_subscriptionConfigs[subId].consumers.length == MAX_CONSUMERS) {
      revert TooManyConsumers();
    }
    if (s_consumers[consumer][subId] != 0) {
      // Idempotence - do nothing if already added.
      // Ensures uniqueness in s_subscriptionConfigs[subId].consumers.
      return;
    }
    // Initialize the nonce to 1, indicating the consumer is allocated.
    s_consumers[consumer][subId] = 1;
    s_subscriptionConfigs[subId].consumers.push(consumer);

    emit SubscriptionConsumerAdded(subId, consumer);
}

  /**
   * @inheritdoc VRFAgentCoordinatorInterface
   */
  function cancelSubscription(uint64 subId) external override onlySubOwner(subId) nonReentrant {
    if (pendingRequestExists(subId)) {
      revert PendingRequestExists();
    }
    _cancelSubscriptionHelper(subId);
  }

  function _cancelSubscriptionHelper(uint64 subId) private nonReentrant {
    SubscriptionConfig memory subConfig = s_subscriptionConfigs[subId];
    // Note bounded by MAX_CONSUMERS;
    // If no consumers, does nothing.
    for (uint256 i = 0; i < subConfig.consumers.length; i++) {
      delete s_consumers[subConfig.consumers[i]][subId];
    }
    delete s_subscriptionConfigs[subId];
    emit SubscriptionCanceled(subId);
  }

  /**
   * @notice Recover token sent mistakenly.
   * @param token address of token to send
   * @param to address to send token to
   */
  function recoverFunds(address token, address to) external onlyOwner {
    uint256 amount = IERC20(token).balanceOf(address(this));
    IERC20(token).transfer(to, amount);
    emit FundsRecovered(token, to, amount);
  }

  /**
   * @notice Returns the proving key hash key associated with this public key
   * @param publicKey the key to return the hash of
   */
  function hashOfKey(uint256[2] memory publicKey) public pure returns (bytes32) {
    return keccak256(abi.encode(publicKey));
  }

  function getOffChainIpfsHash() external view returns (string memory) {
    return offChainIpfsHash;
  }

  function getConsumerFactory() external view returns (address) {
    return address(consumerFactory);
  }

  /**
   * @inheritdoc VRFAgentCoordinatorInterface
   * @dev Looping is bounded to MAX_CONSUMERS*(number of keyhashes).
   * @dev Used to disable subscription canceling while outstanding request are present.
   */
  function pendingRequestExists(uint64 subId) public view override returns (bool) {
    SubscriptionConfig memory subConfig = s_subscriptionConfigs[subId];
    for (uint256 i = 0; i < subConfig.consumers.length; i++) {
      uint256 reqId = lastPendingRequestId(subConfig.consumers[i], subId);
      if (s_requestCommitments[reqId] != 0) {
        return true;
      }
    }
    return false;
  }

  function lastPendingRequestId(address consumer, uint64 subId) public view returns (uint256) {
    for (uint256 i = 0; i < s_agentProvidersList.length; i++) {
      (uint256 reqId, ) = _computeRequestId(s_agentProvidersList[i], consumer, subId, s_consumers[consumer][subId]);
      if (s_requestCommitments[reqId] != 0) {
        return reqId;
      }
    }
    return 0;
  }

  function getCurrentNonce(address consumer, uint64 subId) public view returns (uint64) {
    return s_consumers[consumer][subId];
  }

  function fulfillRandomnessResolver(uint64 _subId) external view returns (bool, bytes memory) {
    return (pendingRequestExists(_subId), bytes(offChainIpfsHash));
  }


  modifier onlySubOwner(uint64 subId) {
    address owner = s_subscriptionConfigs[subId].owner;
    if (owner == address(0)) {
      revert InvalidSubscription();
    }
    if (msg.sender != owner) {
      revert MustBeSubOwner(owner);
    }
    _;
  }

  modifier nonReentrant() {
    if (s_config.reentrancyLock) {
      revert Reentrant();
    }
    _;
  }

  /**
   * @notice The type and version of this contract
   * @return Type and version string
   */
  function typeAndVersion() external pure virtual returns (string memory) {
    return "VRFAgentCoordinator 1.0.0";
  }
}