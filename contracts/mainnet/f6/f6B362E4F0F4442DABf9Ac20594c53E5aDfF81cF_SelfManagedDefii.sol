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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.20;

import {IERC20} from "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.20;

import {IERC721} from "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Context.sol)

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

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SharedLiquidity} from "./SharedLiquidity.sol";
import {Logic} from "./Logic.sol";
import {Constants} from "../../libraries/Constants.sol";

abstract contract Execution is SharedLiquidity, Ownable {
    using SafeERC20 for IERC20;

    struct ExecutionConstructorParams {
        address logic;
        address incentiveVault;
        address treasury;
        uint256 fixedFee;
        uint256 performanceFee;
    }

    address public immutable LOGIC;
    address public immutable INCENTIVE_VAULT;
    address public immutable TREASURY;
    uint256 public immutable PERFORMANCE_FEE;
    uint256 public immutable FIXED_FEE;
    bool public killed;

    event Entered(uint256 liquidityDelta);
    event EmergencyExited();

    error EnterFailed();
    error ExitFailed();
    error Killed();
    error NotKilled();

    modifier alive() {
        if (killed) revert Killed();
        _;
    }

    constructor(ExecutionConstructorParams memory params) Ownable(msg.sender) {
        LOGIC = params.logic;
        INCENTIVE_VAULT = params.incentiveVault;
        TREASURY = params.treasury;
        PERFORMANCE_FEE = params.performanceFee;
        FIXED_FEE = params.fixedFee;
    }

    function claimRewards() external {
        _logic(abi.encodeCall(Logic.claimRewards, (INCENTIVE_VAULT)));
    }

    function emergencyExit() external alive onlyOwner {
        _logic(abi.encodeCall(Logic.emergencyExit, ()));

        killed = true;
        emit EmergencyExited();
    }

    function totalLiquidity() public view override returns (uint256) {
        return Logic(LOGIC).accountLiquidity(address(this));
    }

    function _enter(
        uint256 minLiquidityDelta
    ) internal alive returns (uint256 newShares) {
        uint256 liquidityBefore = totalLiquidity();
        _logic(abi.encodeCall(Logic.enter, ()));
        uint256 liquidityAfter = totalLiquidity();
        if (
            liquidityBefore >= liquidityAfter ||
            (liquidityAfter - liquidityBefore) < minLiquidityDelta
        ) {
            revert EnterFailed();
        }
        emit Entered(liquidityAfter - liquidityBefore);

        return _sharesFromLiquidityDelta(liquidityBefore, liquidityAfter);
    }

    function _exit(
        uint256 shares,
        address[] memory tokens,
        uint256[] memory minDeltas
    ) internal alive {
        uint256 n = tokens.length;
        for (uint256 i = 0; i < n; i++) {
            minDeltas[i] += IERC20(tokens[i]).balanceOf(address(this));
        }

        uint256 liquidity = _toLiquidity(shares);
        _logic(abi.encodeCall(Logic.exit, (liquidity)));

        for (uint256 i = 0; i < n; i++) {
            if (IERC20(tokens[i]).balanceOf(address(this)) < minDeltas[i]) {
                revert ExitFailed();
            }
        }
    }

    function _withdrawLiquidity(
        address recipient,
        uint256 amount
    ) internal alive {
        _logic(abi.encodeCall(Logic.withdrawLiquidity, (recipient, amount)));
    }

    function _withdrawAfterEmergencyExit(
        address recipient,
        uint256 shares,
        uint256 totalShares,
        address[] memory tokens
    ) internal {
        if (!killed) revert NotKilled();

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 tokenBalance = IERC20(tokens[i]).balanceOf(address(this));
            if (tokenBalance > 0) {
                IERC20(tokens[i]).safeTransfer(
                    recipient,
                    (tokenBalance * shares) / totalShares
                );
            }
        }
    }

    function _logic(bytes memory call) internal returns (bytes memory data) {
        bool success;
        (success, data) = LOGIC.delegatecall(call);

        if (!success) {
            assembly {
                revert(add(data, 32), mload(data))
            }
        }
    }

    function _calculateFixedFeeAmount(
        uint256 shares
    ) internal view returns (uint256 performanceFeeAmount) {
        return (shares * FIXED_FEE) / Constants.BPS;
    }

    function _calculatePerformanceFeeAmount(
        uint256 shares
    ) internal view returns (uint256 performanceFeeAmount) {
        return (shares * PERFORMANCE_FEE) / Constants.BPS;
    }
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

abstract contract Logic {
    error NotImplemented();
    error WrongBuildingBlockId(uint256);

    function claimRewards(address recipient) external payable virtual {
        revert NotImplemented();
    }

    function emergencyExit() external payable virtual {
        revert NotImplemented();
    }

    function exitBuildingBlock(uint256 buildingBlockId) external payable virtual {
        revert NotImplemented();
    }

    function withdrawFunds(address recipient) external payable virtual {
        revert NotImplemented();
    }

    function withdrawLiquidity(
        address recipient,
        uint256 amount
    ) external payable virtual {
        revert NotImplemented();
    }

    function enter() external payable virtual;

    function exit(uint256 liquidity) external payable virtual;

    function accountLiquidity(
        address account
    ) external view virtual returns (uint256);
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

/* solhint-disable named-return-values */
abstract contract SharedLiquidity {
    function totalShares() public view virtual returns (uint256);

    function totalLiquidity() public view virtual returns (uint256);

    function _sharesFromLiquidityDelta(
        uint256 liquidityBefore,
        uint256 liquidityAfter
    ) internal view returns (uint256) {
        uint256 totalShares_ = totalShares();
        uint256 liquidityDelta = liquidityAfter - liquidityBefore;
        if (totalShares_ == 0) {
            return liquidityDelta;
        } else {
            return (liquidityDelta * totalShares_) / liquidityBefore;
        }
    }

    function _toLiquidity(uint256 shares) internal view returns (uint256) {
        return (shares * totalLiquidity()) / totalShares();
    }
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IVault} from "../../interfaces/IVault.sol";
import {IDefii} from "../../interfaces/IDefii.sol";

contract LocalInstructions {
    using SafeERC20 for IERC20;

    address immutable SWAP_ROUTER;

    event Swap(
        address tokenIn,
        address tokenOut,
        address swapRouter,
        uint256 amountIn,
        uint256 amountOut
    );

    error WrongInstructionType(
        IDefii.InstructionType provided,
        IDefii.InstructionType required
    );
    error InstructionFailed();

    constructor(address swapRouter) {
        SWAP_ROUTER = swapRouter;
    }

    function _doSwap(
        IDefii.SwapInstruction memory swapInstruction
    ) internal returns (uint256 amountOut) {
        if (swapInstruction.tokenIn == swapInstruction.tokenOut) {
            return swapInstruction.amountIn;
        }
        amountOut = IERC20(swapInstruction.tokenOut).balanceOf(address(this));
        IERC20(swapInstruction.tokenIn).safeIncreaseAllowance(
            SWAP_ROUTER,
            swapInstruction.amountIn
        );
        (bool success, ) = SWAP_ROUTER.call(swapInstruction.routerCalldata);

        amountOut =
            IERC20(swapInstruction.tokenOut).balanceOf(address(this)) -
            amountOut;

        if (!success || amountOut < swapInstruction.minAmountOut)
            revert InstructionFailed();

        emit Swap(
            swapInstruction.tokenIn,
            swapInstruction.tokenOut,
            SWAP_ROUTER,
            swapInstruction.amountIn,
            amountOut
        );
    }

    function _returnAllFunds(
        address vault,
        uint256 positionId,
        address token
    ) internal {
        _returnFunds(
            vault,
            positionId,
            token,
            IERC20(token).balanceOf(address(this))
        );
    }

    function _returnFunds(
        address vault,
        uint256 positionId,
        address token,
        uint256 amount
    ) internal {
        if (amount > 0) {
            IERC20(token).safeIncreaseAllowance(vault, amount);
            IVault(vault).depositToPosition(positionId, token, amount, 0);
        }
    }

    function _checkInstructionType(
        IDefii.Instruction memory instruction,
        IDefii.InstructionType requiredType
    ) internal pure {
        if (instruction.type_ != requiredType) {
            revert WrongInstructionType(instruction.type_, requiredType);
        }
    }

    /* solhint-disable named-return-values */
    function _decodeSwap(
        IDefii.Instruction memory instruction
    ) internal pure returns (IDefii.SwapInstruction memory) {
        _checkInstructionType(instruction, IDefii.InstructionType.SWAP);
        return abi.decode(instruction.data, (IDefii.SwapInstruction));
    }

    function _decodeMinLiquidityDelta(
        IDefii.Instruction memory instruction
    ) internal pure returns (uint256) {
        _checkInstructionType(
            instruction,
            IDefii.InstructionType.MIN_LIQUIDITY_DELTA
        );
        return abi.decode(instruction.data, (uint256));
    }

    function _decodeMinTokensDelta(
        IDefii.Instruction memory instruction
    ) internal pure returns (IDefii.MinTokensDeltaInstruction memory) {
        _checkInstructionType(
            instruction,
            IDefii.InstructionType.MIN_TOKENS_DELTA
        );
        return abi.decode(instruction.data, (IDefii.MinTokensDeltaInstruction));
    }
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

abstract contract SupportedTokens {
    error TokenNotSupported(address token);

    function supportedTokens() public view virtual returns (address[] memory t);

    function _checkToken(address token) internal view {
        if (!_isTokenSupported(token)) {
            revert TokenNotSupported(token);
        }
    }

    function _isTokenSupported(
        address
    ) internal view virtual returns (bool isSupported);
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDefii is IERC20 {
    /// @notice Instruction type
    /// @dev SWAP_BRIDGE is combination of SWAP + BRIDGE instructions.
    /// @dev Data for MIN_LIQUIDITY_DELTA type is just `uint256`
    enum InstructionType {
        SWAP,
        BRIDGE,
        SWAP_BRIDGE,
        REMOTE_CALL,
        MIN_LIQUIDITY_DELTA,
        MIN_TOKENS_DELTA
    }

    /// @notice DEFII type
    enum Type {
        LOCAL,
        REMOTE
    }

    /// @notice DEFII instruction
    struct Instruction {
        InstructionType type_;
        bytes data;
    }

    /// @notice Swap instruction
    /// @dev `routerCalldata` - 1inch router calldata from API
    struct SwapInstruction {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        bytes routerCalldata;
    }

    /// @notice Bridge instruction
    /// @dev `slippage` should be in bps
    struct BridgeInstruction {
        address token;
        uint256 amount;
        uint256 slippage;
        address bridgeAdapter;
        uint256 value;
        bytes bridgeParams;
    }

    /// @notice Swap and bridge instruction. Do swap and bridge all token from swap
    /// @dev `routerCalldata` - 1inch router calldata from API
    /// @dev `slippage` should be in bps
    struct SwapBridgeInstruction {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 minAmountOut;
        bytes routerCalldata;
        address bridgeAdapter;
        uint256 value;
        bytes bridgeParams;
        uint256 slippage;
    }

    struct MinTokensDeltaInstruction {
        address[] tokens;
        uint256[] deltas;
    }

    /// @notice Enters DEFII with predefined logic
    /// @param amount Notion amount for enter
    /// @param positionId Position id (used in callback)
    /// @param instructions List with instructions for enter
    /// @dev Caller should implement `IVault` interface
    function enter(
        uint256 amount,
        uint256 positionId,
        Instruction[] calldata instructions
    ) external payable;

    /// @notice Exits from DEFII with predefined logic
    /// @param shares Defii lp amount to burn
    /// @param positionId Position id (used in callback)
    /// @param instructions List with instructions for enter
    /// @dev Caller should implement `IVault` interface
    function exit(
        uint256 shares,
        uint256 positionId,
        Instruction[] calldata instructions
    ) external payable;

    /// @notice Withdraw liquidity (eg lp tokens) from
    /// @param shares Defii lp amount to burn
    /// @param recipient Address for withdrawal
    /// @param instructions List with instructions
    /// @dev Caller should implement `IVault` interface
    function withdrawLiquidity(
        address recipient,
        uint256 shares,
        Instruction[] calldata instructions
    ) external payable;

    /// @notice DEFII notion (start token)
    /// @return notion address
    // solhint-disable-next-line named-return-values
    function notion() external view returns (address);

    /// @notice DEFII type
    /// @return type Type
    // solhint-disable-next-line named-return-values
    function defiiType() external pure returns (Type);
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import {IDefii} from "./IDefii.sol";
import {Status} from "../libraries/StatusLogic.sol";

interface IVault is IERC721Enumerable {
    /// @notice Event emitted when vault balance has changed
    /// @param positionId Position id
    /// @param token token address
    /// @param amount token amount
    /// @param increased True if balance increased, False if balance decreased
    /// @dev You can get current balance via `funds(token, positionId)`
    event BalanceChanged(
        uint256 indexed positionId,
        address indexed token,
        uint256 amount,
        bool increased
    );

    /// @notice Event emitted when defii status changed
    /// @param positionId Position id
    /// @param defii Defii address
    /// @param newStatus New status
    event DefiiStatusChanged(
        uint256 indexed positionId,
        address indexed defii,
        Status indexed newStatus
    );

    /// @notice Reverts, for example, if you try twice run enterDefii before processing ended
    /// @param currentStatus - Current defii status
    /// @param wantStatus - Want defii status
    /// @param positionStatus - Position status
    error CantChangeDefiiStatus(
        Status currentStatus,
        Status wantStatus,
        Status positionStatus
    );

    /// @notice Reverts if trying to decrease more balance than there is
    error InsufficientBalance(
        uint256 positionId,
        address token,
        uint256 balance,
        uint256 needed
    );

    /// @notice Reverts if trying to exit with 0% or > 100%
    error WrongExitPercentage(uint256 percentage);

    /// @notice Reverts if position processing in case we can't
    error PositionProcessing();

    /// @notice Reverts if trying use unknown defii
    error UnsupportedDefii(address defii);

    /// @notice Deposits token to vault. If caller don't have position, opens it
    /// @param token Token address.
    /// @param amount Token amount.
    /// @param operatorFeeAmount Fee for operator (offchain service help)
    /// @dev You need to get `operatorFeeAmount` from API or set it to 0, if you don't need operator
    function deposit(
        address token,
        uint256 amount,
        uint256 operatorFeeAmount
    ) external returns (uint256 positionId);

    /// @notice Deposits token to vault. If caller don't have position, opens it
    /// @param token Token address
    /// @param amount Token amount
    /// @param operatorFeeAmount Fee for operator (offchain service help)
    /// @param deadline Permit deadline
    /// @param permitV The V parameter of ERC712 permit sig
    /// @param permitR The R parameter of ERC712 permit sig
    /// @param permitS The S parameter of ERC712 permit sig
    /// @dev You need to get `operatorFeeAmount` from API or set it to 0, if you don't need operator
    function depositWithPermit(
        address token,
        uint256 amount,
        uint256 operatorFeeAmount,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external returns (uint256 positionId);

    /// @notice Deposits token to vault. If caller don't have position, opens it
    /// @param positionId Position id
    /// @param token Token address
    /// @param amount Token amount
    /// @param operatorFeeAmount Fee for operator (offchain service help)
    /// @dev You need to get `operatorFeeAmount` from API or set it to 0, if you don't need operator
    function depositToPosition(
        uint256 positionId,
        address token,
        uint256 amount,
        uint256 operatorFeeAmount
    ) external;

    /// @notice Withdraws token from vault
    /// @param token Token address
    /// @param amount Token amount
    /// @param positionId Position id
    /// @dev Validates, that position not processing, if `token` is `NOTION`
    function withdraw(
        address token,
        uint256 amount,
        uint256 positionId
    ) external;

    /// @notice Enters the defii
    /// @param defii Defii address
    /// @param positionId Position id
    /// @param instructions List with encoded instructions for DEFII
    function enterDefii(
        address defii,
        uint256 positionId,
        IDefii.Instruction[] calldata instructions
    ) external payable;

    /// @notice Callback for DEFII
    /// @param positionId Position id
    /// @param shares Minted shares amount
    /// @dev DEFII should call it after enter
    function enterCallback(uint256 positionId, uint256 shares) external;

    /// @notice Exits from defii
    /// @param defii Defii address
    /// @param positionId Position id
    /// @param instructions List with encoded instructions for DEFII
    function exitDefii(
        address defii,
        uint256 positionId,
        IDefii.Instruction[] calldata instructions
    ) external payable;

    /// @notice Callback for DEFII
    /// @param positionId Position id
    /// @dev DEFII should call it after exit
    function exitCallback(uint256 positionId) external;

    function NOTION() external returns (address);
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

library Constants {
    uint256 constant BPS = 1e4;
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {IVault} from "../interfaces/IVault.sol";

uint256 constant MASK_SIZE = 2;
uint256 constant ONES_MASK = (1 << MASK_SIZE) - 1;
uint256 constant MAX_DEFII_AMOUNT = 256 / MASK_SIZE - 1;

enum Status {
    NOT_PROCESSING,
    ENTERING,
    EXITING,
    PROCESSED
}

type Statuses is uint256;
using StatusLogic for Statuses global;

library StatusLogic {
    /*
    Library for gas efficient status updates.

    We have more than 2 statuses, so, we can't use simple bitmask. To solve
    this problem, we use MASK_SIZE bits for every status.
    */

    function getPositionStatus(
        Statuses statuses
    ) internal pure returns (Status positionStatus) {
        return
            Status(Statuses.unwrap(statuses) >> (MASK_SIZE * MAX_DEFII_AMOUNT));
    }

    function getDefiiStatus(
        Statuses statuses,
        uint256 defiiIndex
    ) internal pure returns (Status defiiStatus) {
        return
            Status(
                (Statuses.unwrap(statuses) >> (MASK_SIZE * defiiIndex)) &
                    ONES_MASK
            );
    }

    // solhint-disable-next-line named-return-values
    function isAllDefiisProcessed(
        Statuses statuses,
        uint256 numDefiis
    ) internal pure returns (bool) {
        // Status.PROCESSED = 3 = 0b11
        // So, if all defiis processed, we have
        // statuses = 0b0100......111111111

        // First we need remove 2 left bits (position status)
        uint256 withoutPosition = Statuses.unwrap(
            statuses.setPositionStatus(Status.NOT_PROCESSING)
        );

        return (withoutPosition + 1) == (2 ** (MASK_SIZE * numDefiis));
    }

    function updateDefiiStatus(
        Statuses statuses,
        uint256 defiiIndex,
        Status newStatus,
        uint256 numDefiis
    ) internal pure returns (Statuses newStatuses) {
        Status positionStatus = statuses.getPositionStatus();

        if (positionStatus == Status.NOT_PROCESSING) {
            // If position not processing:
            // - we can start enter/exit
            // - we need to update position status too
            if (newStatus == Status.ENTERING || newStatus == Status.EXITING) {
                return
                    statuses
                        .setDefiiStatus(defiiIndex, newStatus)
                        .setPositionStatus(newStatus);
            }
        } else {
            Status currentStatus = statuses.getDefiiStatus(defiiIndex);
            // If position entering:
            // - we can start/finish enter
            // - we need to reset position status, if all defiis has processed

            // If position exiting:
            // - we can start/finish exit
            // - we need to reset position status, if all defiis has processed

            // prettier-ignore
            if ((
        positionStatus == Status.ENTERING && currentStatus == Status.NOT_PROCESSING && newStatus == Status.ENTERING)
        || (positionStatus == Status.ENTERING && currentStatus == Status.ENTERING && newStatus == Status.PROCESSED)
        || (positionStatus == Status.EXITING && currentStatus == Status.NOT_PROCESSING && newStatus == Status.EXITING)
        || (positionStatus == Status.EXITING && currentStatus == Status.EXITING && newStatus == Status.PROCESSED)) {
                statuses = statuses.setDefiiStatus(defiiIndex, newStatus);
                if (statuses.isAllDefiisProcessed(numDefiis)) {
                    return Statuses.wrap(0);
                } else {
                    return statuses;
                }
            }
        }

        revert IVault.CantChangeDefiiStatus(
            statuses.getDefiiStatus(defiiIndex),
            newStatus,
            positionStatus
        );
    }

    function setPositionStatus(
        Statuses statuses,
        Status newStatus
    ) internal pure returns (Statuses newStatuses) {
        uint256 offset = MASK_SIZE * MAX_DEFII_AMOUNT;
        uint256 cleanupMask = ~(ONES_MASK << offset);
        uint256 newStatusMask = uint256(newStatus) << offset;
        return
            Statuses.wrap(
                (Statuses.unwrap(statuses) & cleanupMask) | newStatusMask
            );
    }

    function setDefiiStatus(
        Statuses statuses,
        uint256 defiiIndex,
        Status newStatus
    ) internal pure returns (Statuses newStatuses) {
        uint256 offset = MASK_SIZE * defiiIndex;
        uint256 cleanupMask = ~(ONES_MASK << offset);
        uint256 newStatusMask = uint256(newStatus) << offset;
        return
            Statuses.wrap(
                (Statuses.unwrap(statuses) & cleanupMask) | newStatusMask
            );
    }
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

interface ISelfManagedFactory {
    function operator() external returns (address);

    function isTokenWhitelisted(address token) external view returns (bool);
}

// SPDX-License-Identifier: SHIFT-1.0
pragma solidity ^0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Metadata, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {Logic} from "../defii/execution/Logic.sol";
import {Execution} from "../defii/execution/Execution.sol";
import {SupportedTokens} from "../defii/supported-tokens/SupportedTokens.sol";
import {LocalInstructions} from "../defii/instructions/LocalInstructions.sol";
import {IDefii} from "../interfaces/IDefii.sol";
import {ISelfManagedFactory} from "./ISelfManagedFactory.sol";

contract SelfManagedDefii is LocalInstructions, Ownable {
    using Address for address;
    using Address for address payable;
    using SafeERC20 for IERC20;

    // immutable like
    ISelfManagedFactory public immutable FACTORY;
    address public LOGIC;

    address public incentiveVault;

    modifier onlyOwnerOrOperator() {
        if (msg.sender != owner() && msg.sender != FACTORY.operator())
            revert Ownable.OwnableUnauthorizedAccount(msg.sender);
        _;
    }

    constructor(
        address swapRouter,
        address factory
    ) LocalInstructions(swapRouter) Ownable(factory) {
        FACTORY = ISelfManagedFactory(factory);
    }

    receive() external payable {}

    function init(
        address logic,
        address owner,
        address incentiveVault_
    ) external {
        require(LOGIC == address(0));
        LOGIC = logic;

        incentiveVault = incentiveVault_;
        _transferOwnership(owner);
    }

    function enter(
        IDefii.Instruction[] calldata instructions
    ) external onlyOwner {
        uint256 n = instructions.length;
        for (uint256 i = 0; i < n - 1; i++) {
            IDefii.SwapInstruction memory instruction = _decodeSwap(
                instructions[i]
            );
            if (!FACTORY.isTokenWhitelisted(instruction.tokenIn))
                revert SupportedTokens.TokenNotSupported(instruction.tokenIn);
            if (!FACTORY.isTokenWhitelisted(instruction.tokenOut))
                revert SupportedTokens.TokenNotSupported(instruction.tokenOut);
            _doSwap(instruction);
        }

        uint256 minLiquidityDelta = _decodeMinLiquidityDelta(
            instructions[n - 1]
        );
        uint256 liquidityBefore = totalLiquidity();
        LOGIC.functionDelegateCall(abi.encodeCall(Logic.enter, ()));
        uint256 liquidityAfter = totalLiquidity();

        if (
            liquidityBefore > liquidityAfter ||
            (liquidityAfter - liquidityBefore) < minLiquidityDelta
        ) {
            revert Execution.EnterFailed();
        }
    }

    function exit(
        uint256 percentage,
        IDefii.MinTokensDeltaInstruction memory minTokensDelta
    ) external onlyOwner {
        if (percentage == 0) percentage = 100;
        uint256 liquidity = (percentage * totalLiquidity()) / 100;

        uint256 n = minTokensDelta.tokens.length;
        for (uint256 i = 0; i < n; i++) {
            minTokensDelta.deltas[i] += IERC20(minTokensDelta.tokens[i])
                .balanceOf(address(this));
        }

        LOGIC.functionDelegateCall(abi.encodeCall(Logic.exit, (liquidity)));

        for (uint256 i = 0; i < n; i++) {
            if (
                IERC20(minTokensDelta.tokens[i]).balanceOf(address(this)) <
                minTokensDelta.deltas[i]
            ) {
                revert Execution.ExitFailed();
            }
        }
        LOGIC.functionDelegateCall(abi.encodeCall(Logic.withdrawFunds, (owner())));
    }

    function claimRewards() external onlyOwnerOrOperator {
        LOGIC.functionDelegateCall(
            abi.encodeCall(Logic.claimRewards, (incentiveVault))
        );
    }

    function emergencyExit() external onlyOwnerOrOperator {
        LOGIC.functionDelegateCall(abi.encodeCall(Logic.emergencyExit, ()));
        LOGIC.functionDelegateCall(abi.encodeCall(Logic.withdrawFunds, (owner())));
    }

    function withdrawLiquidity(
        address account,
        uint256 amount
    ) external onlyOwner {
        LOGIC.functionDelegateCall(
            abi.encodeCall(Logic.withdrawLiquidity, (account, amount))
        );
    }

    function exitBuildingBlock(
        uint256 buildingBlockId
    ) external onlyOwnerOrOperator {
        LOGIC.functionDelegateCall(
            abi.encodeCall(Logic.exitBuildingBlock, (buildingBlockId))
        );
        LOGIC.functionDelegateCall(abi.encodeCall(Logic.withdrawFunds, (owner())));
    }

    function withdrawERC20(IERC20 token) external onlyOwnerOrOperator {
        uint256 tokenAmount = token.balanceOf(address(this));
        if (tokenAmount > 0) {
            token.safeTransfer(owner(), tokenAmount);
        }
    }

    function withdrawETH() external onlyOwnerOrOperator {
        payable(owner()).sendValue(address(this).balance);
    }

    function changeIncentiveVault(address incentiveVault_) external onlyOwner {
        incentiveVault = incentiveVault_;
    }

    function runMultipleTx(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external {
        // we don't need onlyOwner modifier, owner checks in runTx
        require(targets.length == datas.length);
        require(targets.length == values.length);

        for (uint256 i = 0; i < targets.length; i++) {
            runTx(targets[i], values[i], datas[i]);
        }
    }

    function simulateExit(
        address[] calldata tokens
    ) external returns (int256[] memory balanceChanges) {
        try this.simulateExitAndRevert(tokens) {} catch (bytes memory result) {
            balanceChanges = abi.decode(result, (int256[]));
        }
    }

    function simulateExitAndRevert(address[] calldata tokens) external {
        int256[] memory balanceChanges = new int256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            balanceChanges[i] = int256(
                IERC20(tokens[i]).balanceOf(address(this))
            );
        }

        LOGIC.functionDelegateCall(
            abi.encodeCall(Logic.exit, (totalLiquidity()))
        );

        for (uint256 i = 0; i < tokens.length; i++) {
            balanceChanges[i] =
                int256(IERC20(tokens[i]).balanceOf(address(this))) -
                balanceChanges[i];
        }

        bytes memory returnData = abi.encode(balanceChanges);
        uint256 returnDataLength = returnData.length;

        assembly {
            revert(add(returnData, 0x20), returnDataLength)
        }
    }

    function simulateClaimRewards(
        address[] calldata rewardTokens
    ) external returns (int256[] memory balanceChanges) {
        try this.simulateClaimRewardsAndRevert(rewardTokens) {} catch (
            bytes memory result
        ) {
            balanceChanges = abi.decode(result, (int256[]));
        }
    }

    function simulateClaimRewardsAndRevert(
        address[] calldata rewardTokens
    ) external {
        int256[] memory balanceChanges = new int256[](rewardTokens.length);
        for (uint256 i = 0; i < rewardTokens.length; i++) {
            balanceChanges[i] = int256(
                IERC20(rewardTokens[i]).balanceOf(incentiveVault)
            );
        }

        LOGIC.functionDelegateCall(
            abi.encodeCall(Logic.claimRewards, (incentiveVault))
        );

        for (uint256 i = 0; i < rewardTokens.length; i++) {
            balanceChanges[i] =
                int256(IERC20(rewardTokens[i]).balanceOf(incentiveVault)) -
                balanceChanges[i];
        }

        bytes memory returnData = abi.encode(balanceChanges);
        uint256 returnDataLength = returnData.length;
        assembly {
            revert(add(returnData, 0x20), returnDataLength)
        }
    }

    function runTx(
        address target,
        uint256 value,
        bytes memory data
    ) public onlyOwner {
        target.functionCallWithValue(data, value);
    }

    function totalLiquidity() public view returns (uint256) {
        return Logic(LOGIC).accountLiquidity(address(this));
    }
}