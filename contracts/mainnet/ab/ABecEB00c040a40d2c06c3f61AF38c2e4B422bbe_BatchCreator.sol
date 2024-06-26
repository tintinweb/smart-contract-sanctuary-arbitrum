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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.20;

import {IERC165} from "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.20;

import {IERC721Receiver} from "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or
 * {IERC721-setApprovalForAll}.
 */
abstract contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/IERC165.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

interface IVestingLockup {
  struct Recipient {
    address beneficiary;
    bool adminRedeem;
  }

  function createPlan(
    address recipient,
    address token,
    uint256 amount,
    uint256 start,
    uint256 cliff,
    uint256 rate,
    uint256 period,
    address vestingAdmin,
    bool adminTransferOBO
  ) external returns (uint256);

  function createPlan(
    address recipient,
    address token,
    uint256 amount,
    uint256 start,
    uint256 cliff,
    uint256 rate,
    uint256 period
  ) external returns (uint256);

  function createVestingLock(
    Recipient memory recipient,
    uint256 vestingTokenId,
    uint256 start,
    uint256 cliff,
    uint256 rate,
    uint256 period,
    bool transferable,
    bool adminTransferOBO
  ) external returns (uint256 newLockId);

  function hedgeyVesting() external view returns (address);

  function delegate(uint256 planId, address delegatee) external;

  function changeVestingPlanAdmin(uint256 planId, address newAdmin) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';


/// @notice Library to help safely transfer tokens to and from contracts, only supports ERC20 tokens that are not deflationary or tax tokens. 
library TransferHelper {
  using SafeERC20 for IERC20;

  /// @notice Internal function used for standard ERC20 transferFrom method
  /// @notice it contains a pre and post balance check
  /// @notice as well as a check on the msg.senders balance
  /// @param token is the address of the ERC20 being transferred
  /// @param from is the remitting address
  /// @param to is the location where they are being delivered
  function transferTokens(
    address token,
    address from,
    address to,
    uint256 amount
  ) internal {
    uint256 priorBalance = IERC20(token).balanceOf(address(to));
    require(IERC20(token).balanceOf(from) >= amount, 'THL01');
    SafeERC20.safeTransferFrom(IERC20(token), from, to, amount);
    uint256 postBalance = IERC20(token).balanceOf(address(to));
    require(postBalance - priorBalance == amount, 'THL02');
  }

  /// @notice Internal function is used with standard ERC20 transfer method
  /// @notice this function ensures that the amount received is the amount sent with pre and post balance checking
  /// @param token is the ERC20 contract address that is being transferred
  /// @param to is the address of the recipient
  /// @param amount is the amount of tokens that are being transferred
  function withdrawTokens(
    address token,
    address to,
    uint256 amount
  ) internal {
    uint256 priorBalance = IERC20(token).balanceOf(address(to));
    SafeERC20.safeTransfer(IERC20(token), to, amount);
    uint256 postBalance = IERC20(token).balanceOf(address(to));
    require(postBalance - priorBalance == amount, 'THL02');
  }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import '../libraries/TransferHelper.sol';
import '../interfaces/IVestingLockup.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';

/// @title BatchCreator is a contract that allows creating multiple vesting plans, lockup plans and vesting lockup plans in a single transaction
/// @notice there are two types of batching functions, one that creates the plans and one that creates the plans and initially delegates the tokens held by the plans
contract BatchCreator is ERC721Holder {
  /**** EVENTS FOR EACH SPECIFIC BATCH FUNCTION*****************************/

  mapping(address => bool) public whitelist;
  address private _manager;
  constructor() {
    _manager = msg.sender;
  }

  function initWhiteList(address[] memory _whiteList) external {
    require(msg.sender == _manager, 'not manager');
    for (uint256 i; i < _whiteList.length; i++) {
      whitelist[_whiteList[i]] = true;
    }
    delete _manager;
  }


  event VestingLockupBatchCreated(
    address indexed creator,
    address indexed token,
    uint256 numPlansCreated,
    uint256[] planIds,
    uint256[] lockIds,
    uint256 totalAmount,
    uint8 mintType
  );
  event VestingBatchCreated(
    address indexed creator,
    address indexed token,
    uint256 numPlansCreated,
    uint256[] planIds,
    uint256 totalAmount,
    uint8 mintType
  );
  event LockupBatchCreated(
    address indexed creator,
    address indexed token,
    uint256 numPlansCreated,
    uint256[] planIds,
    uint256 totalAmount,
    uint8 mintType
  );

  /// @notice struct to hold the parameters for a vesting or lockup plan, these generally define a vesting or lockup schedule
  /// @param amount is the amount of tokens in a single plan
  /// @param start is the block time start date of the plan
  /// @param cliff is an optional cliff date for the plan
  /// @param rate is the rate at which the tokens are released per period
  /// @param period is the length of time between releases, ie each period is the number of seconds in each discrete period when tokens are released
  struct Plan {
    uint256 amount;
    uint256 start;
    uint256 cliff;
    uint256 rate;
    uint256 period;
  }

  /// @notice an additional multi token transfer funtion for ERC20 tokens to make it simple to send tokens to recipients in a big batch if needed
  function multiTransferTokens(address token, address[] calldata recipients, uint256[] calldata amounts) external {
    require(recipients.length == amounts.length);
    for (uint16 i; i < recipients.length; i++) {
      TransferHelper.transferTokens(token, msg.sender, recipients[i], amounts[i]);
    }
  }

  /// @notice function to batch create lockup plans
  /// @param lockupContract is the contract address of the specific hedgey lockup plan contract
  /// @param token is the address of the token being locked up
  /// @param totalAmount is the total amount of tokens being locked up aggregated across all plans
  /// @param recipients is an array of addresses that will receive the lockup plans
  /// @param plans is an array of Plan structs that define the lockup schedules for each plan
  /// @param mintType is an optional parameter to specify the type of minting that is being done, primarily used for internal database tagging
  function createLockupPlans(
    address lockupContract,
    address token,
    uint256 totalAmount,
    address[] calldata recipients,
    Plan[] calldata plans,
    uint8 mintType
  ) external returns (uint256[] memory) {
    require(totalAmount > 0, '0_totalAmount');
    require(lockupContract != address(0), '0_locker');
    require(token != address(0), '0_token');
    require(plans.length > 0, 'no plans');
    require(whitelist[lockupContract], 'not whitelisted');
    TransferHelper.transferTokens(token, msg.sender, address(this), totalAmount);
    SafeERC20.safeIncreaseAllowance(IERC20(token), lockupContract, totalAmount);
    uint256 amountCheck;
    uint256[] memory newPlanIds = new uint256[](recipients.length);
    for (uint16 i; i < plans.length; i++) {
      uint256 newPlanId = IVestingLockup(lockupContract).createPlan(
        recipients[i],
        token,
        plans[i].amount,
        plans[i].start,
        plans[i].cliff,
        plans[i].rate,
        plans[i].period
      );
      amountCheck += plans[i].amount;
      newPlanIds[i] = newPlanId;
    }
    require(amountCheck == totalAmount, 'totalAmount error');
    emit LockupBatchCreated(msg.sender, token, plans.length, newPlanIds, totalAmount, mintType);
    return newPlanIds;
  }

  /// @notice function to batch create lockup plans, and immeditatley have the plans delegate the tokens - should only be used for onchain voting
  /// @param lockupContract is the contract address of the specific hedgey lockup plan contract
  /// @param token is the address of the token being locked up
  /// @param totalAmount is the total amount of tokens being locked up aggregated across all plans
  /// @param recipients is an array of addresses that will receive the lockup plans
  /// @param delegatees is the array of address where each individual plan will delegate their tokens to, this may be the same as the recipients
  /// @param plans is an array of Plan structs that define the lockup schedules for each plan
  /// @param mintType is an optional parameter to specify the type of minting that is being done, primarily used for internal database tagging
  function createLockupPlansWithDelegation(
    address lockupContract,
    address token,
    uint256 totalAmount,
    address[] calldata recipients,
    address[] calldata delegatees,
    Plan[] calldata plans,
    uint8 mintType
  ) external returns (uint256[] memory) {
    require(totalAmount > 0, '0_totalAmount');
    require(lockupContract != address(0), '0_locker');
    require(token != address(0), '0_token');
    require(plans.length > 0, 'no plans');
    require(whitelist[lockupContract], 'not whitelisted');
    TransferHelper.transferTokens(token, msg.sender, address(this), totalAmount);
    SafeERC20.safeIncreaseAllowance(IERC20(token), lockupContract, totalAmount);
    uint256 amountCheck;
    uint256[] memory newPlanIds = new uint256[](recipients.length);
    for (uint16 i; i < plans.length; i++) {
      uint256 newPlanId = IVestingLockup(lockupContract).createPlan(
        address(this),
        token,
        plans[i].amount,
        plans[i].start,
        plans[i].cliff,
        plans[i].rate,
        plans[i].period
      );
      amountCheck += plans[i].amount;
      newPlanIds[i] = newPlanId;
      IVestingLockup(lockupContract).delegate(newPlanId, delegatees[i]);
      IERC721(lockupContract).transferFrom(address(this), recipients[i], newPlanId);
    }
    require(amountCheck == totalAmount, 'totalAmount error');
    emit LockupBatchCreated(msg.sender, token, plans.length, newPlanIds, totalAmount, mintType);
    return newPlanIds;
  }

  /// @notice function to batch create vesting plans
  /// @param vestingContract is the contract address of the specific hedgey vesting plan contract
  /// @param token is the address of the token being vested
  /// @param totalAmount is the total amount of tokens being vested aggregated across all plans
  /// @param recipients is an array of addresses that will receive the vesting plans
  /// @param plans is an array of Plan structs that define the vesting schedules for each plan
  /// @param vestingAdmin is the address of the admin for the vesting plans
  /// @param adminTransferOBO is a boolean that specifies if the admin can transfer the vesting plans on behalf of the recipient
  /// @param mintType is an optional parameter to specify the type of minting that is being done, primarily used for internal database tagging
  function createVestingPlans(
    address vestingContract,
    address token,
    uint256 totalAmount,
    address[] calldata recipients,
    Plan[] calldata plans,
    address vestingAdmin,
    bool adminTransferOBO,
    uint8 mintType
  ) external returns (uint256[] memory) {
    require(totalAmount > 0, '0_totalAmount');
    require(vestingContract != address(0), '0_vesting');
    require(token != address(0), '0_token');
    require(plans.length > 0, 'no plans');
    require(whitelist[vestingContract], 'not whitelisted');
    TransferHelper.transferTokens(token, msg.sender, address(this), totalAmount);
    SafeERC20.safeIncreaseAllowance(IERC20(token), vestingContract, totalAmount);
    uint256 amountCheck;
    uint256[] memory newPlanIds = new uint256[](recipients.length);
    for (uint16 i; i < plans.length; i++) {
      uint256 newPlanId = IVestingLockup(vestingContract).createPlan(
        recipients[i],
        token,
        plans[i].amount,
        plans[i].start,
        plans[i].cliff,
        plans[i].rate,
        plans[i].period,
        vestingAdmin,
        adminTransferOBO
      );
      amountCheck += plans[i].amount;
      newPlanIds[i] = newPlanId;
    }
    require(amountCheck == totalAmount, 'totalAmount error');
    emit VestingBatchCreated(msg.sender, token, plans.length, newPlanIds, totalAmount, mintType);
    return newPlanIds;
  }

  /// @notice function to batch create vesting plans with immediate delegation of the tokens. 
  /// @dev Note the vesting admin transferBOB must be true, so it is not an option
  /// @param vestingContract is the contract address of the specific hedgey vesting plan contract
  /// @param token is the address of the token being vested
  /// @param totalAmount is the total amount of tokens being vested aggregated across all plans
  /// @param recipients is an array of addresses that will receive the vesting plans
  /// @param delegatees is the array of address where each individual plan will delegate their tokens to, this may be the same as the recipients
  /// @param plans is an array of Plan structs that define the vesting schedules for each plan
  /// @param vestingAdmin is the address of the admin for the vesting plans
  /// @param mintType is an optional parameter to specify the type of minting that is being done, primarily used for internal database tagging
  function createVestingPlansWithDelegation(
    address vestingContract,
    address token,
    uint256 totalAmount,
    address[] calldata recipients,
    address[] calldata delegatees,
    Plan[] calldata plans,
    address vestingAdmin,
    uint8 mintType
  ) external returns (uint256[] memory) {
    require(totalAmount > 0, '0_totalAmount');
    require(vestingContract != address(0), '0_vesting');
    require(token != address(0), '0_token');
    require(plans.length > 0, 'no plans');
    require(whitelist[vestingContract], 'not whitelisted');
    TransferHelper.transferTokens(token, msg.sender, address(this), totalAmount);
    SafeERC20.safeIncreaseAllowance(IERC20(token), vestingContract, totalAmount);
    uint256 amountCheck;
    uint256[] memory newPlanIds = new uint256[](recipients.length);
    for (uint16 i; i < plans.length; i++) {
      uint256 newPlanId = IVestingLockup(vestingContract).createPlan(
        address(this),
        token,
        plans[i].amount,
        plans[i].start,
        plans[i].cliff,
        plans[i].rate,
        plans[i].period,
        address(this),
        true
      );
      amountCheck += plans[i].amount;
      newPlanIds[i] = newPlanId;
      IVestingLockup(vestingContract).delegate(newPlanId, delegatees[i]);
      IERC721(vestingContract).transferFrom(address(this), recipients[i], newPlanId);
      IVestingLockup(vestingContract).changeVestingPlanAdmin(newPlanId, vestingAdmin);
    }
    require(amountCheck == totalAmount, 'totalAmount error');
    emit VestingBatchCreated(msg.sender, token, plans.length, newPlanIds, totalAmount, mintType);
    return newPlanIds;
  }

  /// @notice function to batch create vesting lockup plans
  /// @param lockupContract is the contract address of the specific hedgey lockup plan contract
  /// @param token is the address of the token being vested
  /// @param totalAmount is the total amount of tokens being vested aggregated across all plans
  /// @param recipients is an array of Recipient structs that define the beneficiary and adminRedeem status for each plan
  /// @param vestingPlans is an array of Plan structs that define the vesting schedules for each plan
  /// @param vestingAdmin is the address of the admin for the vesting plans
  /// @param adminTransferOBO is a boolean that specifies if the admin can transfer the vesting plans on behalf of the recipient
  /// @param locks is an array of Plan structs that define the lockup schedules for each veting plan
  /// @param transferablelocks is a boolean that specifies if the lockup plans can be transferred by the beneficiary
  /// @param mintType is an optional parameter to specify the type of minting that is being done, primarily used for internal database tagging
  function createVestingLockupPlans(
    address lockupContract,
    address token,
    uint256 totalAmount,
    IVestingLockup.Recipient[] calldata recipients,
    Plan[] calldata vestingPlans,
    address vestingAdmin,
    bool adminTransferOBO,
    Plan[] calldata locks,
    bool transferablelocks,
    uint8 mintType
  ) external returns (uint256[] memory, uint256[] memory) {
    require(vestingPlans.length == recipients.length, 'lenError');
    require(vestingPlans.length == locks.length, 'lenError');
    require(totalAmount > 0, '0_totalAmount');
    require(whitelist[lockupContract], 'not whitelisted');
    address vestingContract = IVestingLockup(lockupContract).hedgeyVesting();
    TransferHelper.transferTokens(token, msg.sender, address(this), totalAmount);
    SafeERC20.safeIncreaseAllowance(IERC20(token), vestingContract, totalAmount);
    uint256 amountCheck;
    uint256[] memory newVestingIds = new uint256[](vestingPlans.length);
    uint256[] memory newLockIds = new uint256[](vestingPlans.length);
    for (uint16 i; i < vestingPlans.length; i++) {
      uint256 newVestingId = IVestingLockup(vestingContract).createPlan(
        lockupContract,
        token,
        vestingPlans[i].amount,
        vestingPlans[i].start,
        vestingPlans[i].cliff,
        vestingPlans[i].rate,
        vestingPlans[i].period,
        vestingAdmin,
        false
      );
      uint256 newLockId = IVestingLockup(lockupContract).createVestingLock(
        IVestingLockup.Recipient(recipients[i].beneficiary, recipients[i].adminRedeem),
        newVestingId,
        locks[i].start,
        locks[i].cliff,
        locks[i].rate,
        locks[i].period,
        transferablelocks,
        adminTransferOBO
      );
      newVestingIds[i] = newVestingId;
      newLockIds[i] = newLockId;
      amountCheck += vestingPlans[i].amount;
    }
    require(amountCheck == totalAmount, 'totalAmount error');
    emit VestingLockupBatchCreated(
      msg.sender,
      token,
      vestingPlans.length,
      newVestingIds,
      newLockIds,
      totalAmount,
      mintType
    );
    return (newVestingIds, newLockIds);
  }

  /// @notice function to batch create vesting lockup plans with immediate delegation. 
  /// @dev Note that only the Vesting Plans will delegate initially, not the locksup
  /// @param lockupContract is the contract address of the specific hedgey lockup plan contract
  /// @param token is the address of the token being vested
  /// @param totalAmount is the total amount of tokens being vested aggregated across all plans
  /// @param recipients is an array of Recipient structs that define the beneficiary and adminRedeem status for each plan
  /// @param delegatees is an array of addresses that will receive the vesting plans
  /// @param vestingPlans is an array of Plan structs that define the vesting schedules for each plan
  /// @param vestingAdmin is the address of the admin for the vesting plans
  /// @param adminTransferOBO is a boolean that specifies if the admin can transfer the vesting plans on behalf of the recipient
  /// @param locks is an array of Plan structs that define the lockup schedules for each veting plan
  /// @param transferablelocks is a boolean that specifies if the lockup plans can be transferred by the beneficiary
  /// @param mintType is an optional parameter to specify the type of minting that is being done, primarily used for internal database tagging
  function createVestingLockupPlansWithDelegation(
    address lockupContract,
    address token,
    uint256 totalAmount,
    IVestingLockup.Recipient[] calldata recipients,
    address[] calldata delegatees,
    Plan[] calldata vestingPlans,
    address vestingAdmin,
    bool adminTransferOBO,
    Plan[] calldata locks,
    bool transferablelocks,
    uint8 mintType
  ) external returns (uint256[] memory, uint256[] memory) {
    require(vestingPlans.length == recipients.length, 'lenError');
    require(vestingPlans.length == locks.length, 'lenError');
    require(totalAmount > 0, '0_totalAmount');
    require(whitelist[lockupContract], 'not whitelisted');
    address vestingContract = IVestingLockup(lockupContract).hedgeyVesting();
    TransferHelper.transferTokens(token, msg.sender, address(this), totalAmount);
    SafeERC20.safeIncreaseAllowance(IERC20(token), vestingContract, totalAmount);
    uint256 amountCheck;
    uint256[] memory newVestingIds = new uint256[](vestingPlans.length);
    uint256[] memory newLockIds = new uint256[](vestingPlans.length);
    for (uint16 i; i < vestingPlans.length; i++) {
      uint256 newVestingId = IVestingLockup(vestingContract).createPlan(
        address(this),
        token,
        vestingPlans[i].amount,
        vestingPlans[i].start,
        vestingPlans[i].cliff,
        vestingPlans[i].rate,
        vestingPlans[i].period,
        address(this),
        true
      );
      IVestingLockup(vestingContract).delegate(newVestingId, delegatees[i]);
      IERC721(vestingContract).transferFrom(address(this), lockupContract, newVestingId);
      IVestingLockup(vestingContract).changeVestingPlanAdmin(newVestingId, vestingAdmin);
      uint256 newLockId = IVestingLockup(lockupContract).createVestingLock(
        IVestingLockup.Recipient(recipients[i].beneficiary, recipients[i].adminRedeem),
        newVestingId,
        locks[i].start,
        locks[i].cliff,
        locks[i].rate,
        locks[i].period,
        transferablelocks,
        adminTransferOBO
      );
      newVestingIds[i] = newVestingId;
      newLockIds[i] = newLockId;
      amountCheck += vestingPlans[i].amount;
    }
    require(amountCheck == totalAmount, 'totalAmount error');
    emit VestingLockupBatchCreated(
      msg.sender,
      token,
      vestingPlans.length,
      newVestingIds,
      newLockIds,
      totalAmount,
      mintType
    );
    return (newVestingIds, newLockIds);
  }
}