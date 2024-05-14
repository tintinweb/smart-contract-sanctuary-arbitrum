// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

// This contract is taken from Uniswap's multi call implementation (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/base/Multicall.sol)
// and was modified to be solidity 0.8 compatible. Additionally, the method was restricted to only work with msg.value
// set to 0 to avoid any nasty attack vectors on function calls that use value sent with deposits.

/// @title MultiCaller
/// @notice Enables calling multiple methods in a single call to the contract
contract MultiCaller {
    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// Contains structs and functions used by SpokePool contracts to facilitate universal settlement.
interface V3SpokePoolInterface {
    /**************************************
     *              ENUMS                 *
     **************************************/

    // Fill status tracks on-chain state of deposit, uniquely identified by relayHash.
    enum FillStatus {
        Unfilled,
        RequestedSlowFill,
        Filled
    }
    // Fill type is emitted in the FilledRelay event to assist Dataworker with determining which types of
    // fills to refund (e.g. only fast fills) and whether a fast fill created a sow fill excess.
    enum FillType {
        FastFill,
        // Fast fills are normal fills that do not replace a slow fill request.
        ReplacedSlowFill,
        // Replaced slow fills are fast fills that replace a slow fill request. This type is used by the Dataworker
        // to know when to send excess funds from the SpokePool to the HubPool because they can no longer be used
        // for a slow fill execution.
        SlowFill
        // Slow fills are requested via requestSlowFill and executed by executeSlowRelayLeaf after a bundle containing
        // the slow fill is validated.
    }

    /**************************************
     *              STRUCTS               *
     **************************************/

    // This struct represents the data to fully specify a **unique** relay submitted on this chain.
    // This data is hashed with the chainId() and saved by the SpokePool to prevent collisions and protect against
    // replay attacks on other chains. If any portion of this data differs, the relay is considered to be
    // completely distinct.
    struct V3RelayData {
        // The address that made the deposit on the origin chain.
        address depositor;
        // The recipient address on the destination chain.
        address recipient;
        // This is the exclusive relayer who can fill the deposit before the exclusivity deadline.
        address exclusiveRelayer;
        // Token that is deposited on origin chain by depositor.
        address inputToken;
        // Token that is received on destination chain by recipient.
        address outputToken;
        // The amount of input token deposited by depositor.
        uint256 inputAmount;
        // The amount of output token to be received by recipient.
        uint256 outputAmount;
        // Origin chain id.
        uint256 originChainId;
        // The id uniquely identifying this deposit on the origin chain.
        uint32 depositId;
        // The timestamp on the destination chain after which this deposit can no longer be filled.
        uint32 fillDeadline;
        // The timestamp on the destination chain after which any relayer can fill the deposit.
        uint32 exclusivityDeadline;
        // Data that is forwarded to the recipient.
        bytes message;
    }

    // Contains parameters passed in by someone who wants to execute a slow relay leaf.
    struct V3SlowFill {
        V3RelayData relayData;
        uint256 chainId;
        uint256 updatedOutputAmount;
    }

    // Contains information about a relay to be sent along with additional information that is not unique to the
    // relay itself but is required to know how to process the relay. For example, "updatedX" fields can be used
    // by the relayer to modify fields of the relay with the depositor's permission, and "repaymentChainId" is specified
    // by the relayer to determine where to take a relayer refund, but doesn't affect the uniqueness of the relay.
    struct V3RelayExecutionParams {
        V3RelayData relay;
        bytes32 relayHash;
        uint256 updatedOutputAmount;
        address updatedRecipient;
        bytes updatedMessage;
        uint256 repaymentChainId;
    }

    // Packs together parameters emitted in FilledV3Relay because there are too many emitted otherwise.
    // Similar to V3RelayExecutionParams, these parameters are not used to uniquely identify the deposit being
    // filled so they don't have to be unpacked by all clients.
    struct V3RelayExecutionEventInfo {
        address updatedRecipient;
        bytes updatedMessage;
        uint256 updatedOutputAmount;
        FillType fillType;
    }

    /**************************************
     *              EVENTS                *
     **************************************/

    event V3FundsDeposited(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 indexed destinationChainId,
        uint32 indexed depositId,
        uint32 quoteTimestamp,
        uint32 fillDeadline,
        uint32 exclusivityDeadline,
        address indexed depositor,
        address recipient,
        address exclusiveRelayer,
        bytes message
    );

    event RequestedSpeedUpV3Deposit(
        uint256 updatedOutputAmount,
        uint32 indexed depositId,
        address indexed depositor,
        address updatedRecipient,
        bytes updatedMessage,
        bytes depositorSignature
    );

    event FilledV3Relay(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 repaymentChainId,
        uint256 indexed originChainId,
        uint32 indexed depositId,
        uint32 fillDeadline,
        uint32 exclusivityDeadline,
        address exclusiveRelayer,
        address indexed relayer,
        address depositor,
        address recipient,
        bytes message,
        V3RelayExecutionEventInfo relayExecutionInfo
    );

    event RequestedV3SlowFill(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 indexed originChainId,
        uint32 indexed depositId,
        uint32 fillDeadline,
        uint32 exclusivityDeadline,
        address exclusiveRelayer,
        address depositor,
        address recipient,
        bytes message
    );

    /**************************************
     *              FUNCTIONS             *
     **************************************/

    function depositV3(
        address depositor,
        address recipient,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 destinationChainId,
        address exclusiveRelayer,
        uint32 quoteTimestamp,
        uint32 fillDeadline,
        uint32 exclusivityDeadline,
        bytes calldata message
    ) external payable;

    function depositV3Now(
        address depositor,
        address recipient,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount,
        uint256 destinationChainId,
        address exclusiveRelayer,
        uint32 fillDeadlineOffset,
        uint32 exclusivityDeadline,
        bytes calldata message
    ) external payable;

    function speedUpV3Deposit(
        address depositor,
        uint32 depositId,
        uint256 updatedOutputAmount,
        address updatedRecipient,
        bytes calldata updatedMessage,
        bytes calldata depositorSignature
    ) external;

    function fillV3Relay(V3RelayData calldata relayData, uint256 repaymentChainId) external;

    function fillV3RelayWithUpdatedDeposit(
        V3RelayData calldata relayData,
        uint256 repaymentChainId,
        uint256 updatedOutputAmount,
        address updatedRecipient,
        bytes calldata updatedMessage,
        bytes calldata depositorSignature
    ) external;

    function requestV3SlowFill(V3RelayData calldata relayData) external;

    function executeV3SlowRelayLeaf(
        V3SlowFill calldata slowFillLeaf,
        uint32 rootBundleId,
        bytes32[] calldata proof
    ) external;

    /**************************************
     *              ERRORS                *
     **************************************/

    error DisabledRoute();
    error InvalidQuoteTimestamp();
    error InvalidFillDeadline();
    error InvalidExclusiveRelayer();
    error InvalidExclusivityDeadline();
    error MsgValueDoesNotMatchInputAmount();
    error NotExclusiveRelayer();
    error NoSlowFillsInExclusivityWindow();
    error RelayFilled();
    error InvalidSlowFillRequest();
    error ExpiredFillDeadline();
    error InvalidMerkleProof();
    error InvalidChainId();
    error InvalidMerkleLeaf();
    error ClaimedMerkleLeaf();
    error InvalidPayoutAdjustmentPct();
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/**
 * @title A contract that provides modifiers to prevent reentrancy to state-changing and view-only methods. This contract
 * is inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/ReentrancyGuard.sol
 * and https://github.com/balancer-labs/balancer-core/blob/master/contracts/BPool.sol.
 * @dev The reason why we use this local contract instead of importing from uma/contracts is because of the addition
 * of the internal method `functionCallStackOriginatesFromOutsideThisContract` which doesn't exist in the one exported
 * by uma/contracts.
 */
contract Lockable {
    bool internal _notEntered;

    constructor() {
        // Storing an initial non-zero value makes deployment a bit more expensive, but in exchange the refund on every
        // call to nonReentrant will be lower in amount. Since refunds are capped to a percentage of the total
        // transaction's gas, it is best to keep them low in cases like this one, to increase the likelihood of the full
        // refund coming into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a nonReentrant function from another nonReentrant function is not supported. It is possible to
     * prevent this from happening by making the nonReentrant function external, and making it call a private
     * function that does the actual state modification.
     */
    modifier nonReentrant() {
        _preEntranceCheck();
        _preEntranceSet();
        _;
        _postEntranceReset();
    }

    /**
     * @dev Designed to prevent a view-only method from being re-entered during a call to a nonReentrant() state-changing method.
     */
    modifier nonReentrantView() {
        _preEntranceCheck();
        _;
    }

    /**
     * @dev Returns true if the contract is currently in a non-entered state, meaning that the origination of the call
     * came from outside the contract. This is relevant with fallback/receive methods to see if the call came from ETH
     * being dropped onto the contract externally or due to ETH dropped on the the contract from within a method in this
     * contract, such as unwrapping WETH to ETH within the contract.
     */
    function functionCallStackOriginatesFromOutsideThisContract() internal view returns (bool) {
        return _notEntered;
    }

    // Internal methods are used to avoid copying the require statement's bytecode to every nonReentrant() method.
    // On entry into a function, _preEntranceCheck() should always be called to check if the function is being
    // re-entered. Then, if the function modifies state, it should call _postEntranceSet(), perform its logic, and
    // then call _postEntranceReset().
    // View-only methods can simply call _preEntranceCheck() to make sure that it is not being re-entered.
    function _preEntranceCheck() internal view {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");
    }

    function _preEntranceSet() internal {
        // Any calls to nonReentrant after this point will fail
        _notEntered = false;
    }

    function _postEntranceReset() internal {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/V3SpokePoolInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Lockable.sol";
import "@uma/core/contracts/common/implementation/MultiCaller.sol";

/**
 * @title SwapAndBridgeBase
 * @notice Base contract for both variants of SwapAndBridge.
 */
abstract contract SwapAndBridgeBase is Lockable, MultiCaller {
    using SafeERC20 for IERC20;

    // This contract performs a low level call with arbirary data to an external contract. This is a large attack
    // surface and we should whitelist which function selectors are allowed to be called on the exchange.
    mapping(bytes4 => bool) public allowedSelectors;

    // Across SpokePool we'll submit deposits to with acrossInputToken as the input token.
    V3SpokePoolInterface public immutable SPOKE_POOL;

    // Exchange address or router where the swapping will happen.
    address public immutable EXCHANGE;

    // Params we'll need caller to pass in to specify an Across Deposit. The input token will be swapped into first
    // before submitting a bridge deposit, which is why we don't include the input token amount as it is not known
    // until after the swap.
    struct DepositData {
        // Token received on destination chain.
        address outputToken;
        // Amount of output token to be received by recipient.
        uint256 outputAmount;
        // The account credited with deposit who can submit speedups to the Across deposit.
        address depositor;
        // The account that will receive the output token on the destination chain. If the output token is
        // wrapped native token, then if this is an EOA then they will receive native token on the destination
        // chain and if this is a contract then they will receive an ERC20.
        address recipient;
        // The destination chain identifier.
        uint256 destinationChainid;
        // The account that can exclusively fill the deposit before the exclusivity deadline.
        address exclusiveRelayer;
        // Timestamp of the deposit used by system to charge fees. Must be within short window of time into the past
        // relative to this chain's current time or deposit will revert.
        uint32 quoteTimestamp;
        // The timestamp on the destination chain after which this deposit can no longer be filled.
        uint32 fillDeadline;
        // The timestamp on the destination chain after which anyone can fill the deposit.
        uint32 exclusivityDeadline;
        // Data that is forwarded to the recipient if the recipient is a contract.
        bytes message;
    }

    event SwapBeforeBridge(
        address exchange,
        address indexed swapToken,
        address indexed acrossInputToken,
        uint256 swapTokenAmount,
        uint256 acrossInputAmount,
        address indexed acrossOutputToken,
        uint256 acrossOutputAmount
    );

    /****************************************
     *                ERRORS                *
     ****************************************/
    error MinimumExpectedInputAmount();
    error LeftoverSrcTokens();
    error InvalidFunctionSelector();

    /**
     * @notice Construct a new SwapAndBridgeBase contract.
     * @param _spokePool Address of the SpokePool contract that we'll submit deposits to.
     * @param _exchange Address of the exchange where tokens will be swapped.
     * @param _allowedSelectors Function selectors that are allowed to be called on the exchange.
     */
    constructor(
        V3SpokePoolInterface _spokePool,
        address _exchange,
        bytes4[] memory _allowedSelectors
    ) {
        SPOKE_POOL = _spokePool;
        EXCHANGE = _exchange;
        for (uint256 i = 0; i < _allowedSelectors.length; i++) {
            allowedSelectors[_allowedSelectors[i]] = true;
        }
    }

    // This contract supports two variants of swap and bridge, one that allows one token and another that allows the caller to pass them in.
    function _swapAndBridge(
        bytes calldata routerCalldata,
        uint256 swapTokenAmount,
        uint256 minExpectedInputTokenAmount,
        DepositData calldata depositData,
        IERC20 _swapToken,
        IERC20 _acrossInputToken
    ) internal {
        // Note: this check should never be impactful, but is here out of an abundance of caution.
        // For example, if the exchange address in the contract is also an ERC20 token that is approved by some
        // user on this contract, a malicious actor could call transferFrom to steal the user's tokens.
        if (!allowedSelectors[bytes4(routerCalldata)]) revert InvalidFunctionSelector();

        // Pull tokens from caller into this contract.
        _swapToken.safeTransferFrom(msg.sender, address(this), swapTokenAmount);
        // Swap and run safety checks.
        uint256 srcBalanceBefore = _swapToken.balanceOf(address(this));
        uint256 dstBalanceBefore = _acrossInputToken.balanceOf(address(this));

        _swapToken.safeIncreaseAllowance(EXCHANGE, swapTokenAmount);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = EXCHANGE.call(routerCalldata);
        require(success, string(result));

        _checkSwapOutputAndDeposit(
            swapTokenAmount,
            srcBalanceBefore,
            dstBalanceBefore,
            minExpectedInputTokenAmount,
            depositData,
            _swapToken,
            _acrossInputToken
        );
    }

    /**
     * @notice Check that the swap returned enough tokens to submit an Across deposit with and then submit the deposit.
     * @param swapTokenAmount Amount of swapToken to swap for a minimum amount of acrossInputToken.
     * @param swapTokenBalanceBefore Balance of swapToken before swap.
     * @param inputTokenBalanceBefore Amount of Across input token we held before swap
     * @param minExpectedInputTokenAmount Minimum amount of received acrossInputToken that we'll bridge
     **/
    function _checkSwapOutputAndDeposit(
        uint256 swapTokenAmount,
        uint256 swapTokenBalanceBefore,
        uint256 inputTokenBalanceBefore,
        uint256 minExpectedInputTokenAmount,
        DepositData calldata depositData,
        IERC20 _swapToken,
        IERC20 _acrossInputToken
    ) internal {
        // Sanity check that we received as many tokens as we require:
        uint256 returnAmount = _acrossInputToken.balanceOf(address(this)) - inputTokenBalanceBefore;
        // Sanity check that received amount from swap is enough to submit Across deposit with.
        if (returnAmount < minExpectedInputTokenAmount) revert MinimumExpectedInputAmount();
        // Sanity check that we don't have any leftover swap tokens that would be locked in this contract (i.e. check
        // that we weren't partial filled).
        if (swapTokenBalanceBefore - _swapToken.balanceOf(address(this)) != swapTokenAmount) revert LeftoverSrcTokens();

        emit SwapBeforeBridge(
            EXCHANGE,
            address(_swapToken),
            address(_acrossInputToken),
            swapTokenAmount,
            returnAmount,
            depositData.outputToken,
            depositData.outputAmount
        );
        // Deposit the swapped tokens into Across and bridge them using remainder of input params.
        _acrossInputToken.safeIncreaseAllowance(address(SPOKE_POOL), returnAmount);
        SPOKE_POOL.depositV3(
            depositData.depositor,
            depositData.recipient,
            address(_acrossInputToken), // input token
            depositData.outputToken, // output token
            returnAmount, // input amount.
            depositData.outputAmount, // output amount
            depositData.destinationChainid,
            depositData.exclusiveRelayer,
            depositData.quoteTimestamp,
            depositData.fillDeadline,
            depositData.exclusivityDeadline,
            depositData.message
        );
    }
}

/**
 * @title SwapAndBridge
 * @notice Allows caller to swap between two pre-specified tokens on a chain before bridging the received token
 * via Across atomically. Provides safety checks post-swap and before-deposit.
 * @dev This variant primarily exists
 */
contract SwapAndBridge is SwapAndBridgeBase {
    using SafeERC20 for IERC20;

    // This contract simply enables the caller to swap a token on this chain for another specified one
    // and bridge it as the input token via Across. This simplification is made to make the code
    // easier to reason about and solve a specific use case for Across.
    IERC20 public immutable SWAP_TOKEN;

    // The token that will be bridged via Across as the inputToken.
    IERC20 public immutable ACROSS_INPUT_TOKEN;

    /**
     * @notice Construct a new SwapAndBridge contract.
     * @param _spokePool Address of the SpokePool contract that we'll submit deposits to.
     * @param _exchange Address of the exchange where tokens will be swapped.
     * @param _allowedSelectors Function selectors that are allowed to be called on the exchange.
     * @param _swapToken Address of the token that will be swapped for acrossInputToken. Cannot be 0x0
     * @param _acrossInputToken Address of the token that will be bridged via Across as the inputToken.
     */
    constructor(
        V3SpokePoolInterface _spokePool,
        address _exchange,
        bytes4[] memory _allowedSelectors,
        IERC20 _swapToken,
        IERC20 _acrossInputToken
    ) SwapAndBridgeBase(_spokePool, _exchange, _allowedSelectors) {
        SWAP_TOKEN = _swapToken;
        ACROSS_INPUT_TOKEN = _acrossInputToken;
    }

    /**
     * @notice Swaps tokens on this chain via specified router before submitting Across deposit atomically.
     * Caller can specify their slippage tolerance for the swap and Across deposit params.
     * @dev If swapToken or acrossInputToken are the native token for this chain then this function might fail.
     * the assumption is that this function will handle only ERC20 tokens.
     * @param routerCalldata ABI encoded function data to call on router. Should form a swap of swapToken for
     * enough of acrossInputToken, otherwise this function will revert.
     * @param swapTokenAmount Amount of swapToken to swap for a minimum amount of depositData.inputToken.
     * @param minExpectedInputTokenAmount Minimum amount of received depositData.inputToken that we'll submit bridge
     * deposit with.
     * @param depositData Specifies the Across deposit params we'll send after the swap.
     */
    function swapAndBridge(
        bytes calldata routerCalldata,
        uint256 swapTokenAmount,
        uint256 minExpectedInputTokenAmount,
        DepositData calldata depositData
    ) external nonReentrant {
        _swapAndBridge(
            routerCalldata,
            swapTokenAmount,
            minExpectedInputTokenAmount,
            depositData,
            SWAP_TOKEN,
            ACROSS_INPUT_TOKEN
        );
    }
}

/**
 * @title UniversalSwapAndBridge
 * @notice Allows caller to swap between any two tokens specified at runtime on a chain before
 * bridging the received token via Across atomically. Provides safety checks post-swap and before-deposit.
 */
contract UniversalSwapAndBridge is SwapAndBridgeBase {
    /**
     * @notice Construct a new SwapAndBridgeBase contract.
     * @param _spokePool Address of the SpokePool contract that we'll submit deposits to.
     * @param _exchange Address of the exchange where tokens will be swapped.
     * @param _allowedSelectors Function selectors that are allowed to be called on the exchange.
     */
    constructor(
        V3SpokePoolInterface _spokePool,
        address _exchange,
        bytes4[] memory _allowedSelectors
    ) SwapAndBridgeBase(_spokePool, _exchange, _allowedSelectors) {}

    /**
     * @notice Swaps tokens on this chain via specified router before submitting Across deposit atomically.
     * Caller can specify their slippage tolerance for the swap and Across deposit params.
     * @dev If swapToken or acrossInputToken are the native token for this chain then this function might fail.
     * the assumption is that this function will handle only ERC20 tokens.
     * @param swapToken Address of the token that will be swapped for acrossInputToken.
     * @param acrossInputToken Address of the token that will be bridged via Across as the inputToken.
     * @param routerCalldata ABI encoded function data to call on router. Should form a swap of swapToken for
     * enough of acrossInputToken, otherwise this function will revert.
     * @param swapTokenAmount Amount of swapToken to swap for a minimum amount of depositData.inputToken.
     * @param minExpectedInputTokenAmount Minimum amount of received depositData.inputToken that we'll submit bridge
     * deposit with.
     * @param depositData Specifies the Across deposit params we'll send after the swap.
     */
    function swapAndBridge(
        IERC20 swapToken,
        IERC20 acrossInputToken,
        bytes calldata routerCalldata,
        uint256 swapTokenAmount,
        uint256 minExpectedInputTokenAmount,
        DepositData calldata depositData
    ) external nonReentrant {
        _swapAndBridge(
            routerCalldata,
            swapTokenAmount,
            minExpectedInputTokenAmount,
            depositData,
            swapToken,
            acrossInputToken
        );
    }
}