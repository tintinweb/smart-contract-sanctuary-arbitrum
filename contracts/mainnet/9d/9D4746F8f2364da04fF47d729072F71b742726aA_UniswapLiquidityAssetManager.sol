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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.20;

import {IERC721} from "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.20;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IAssetPool} from "../interfaces/IAssetPool.sol";
import {IVerifier} from "../interfaces/IVerifier.sol";
import {IVerifierHub} from "../interfaces/IVerifierHub.sol";
import {IRelayerHub} from "../interfaces/IRelayerHub.sol";
import {IFeeManager} from "../interfaces/IFeeManager.sol";
import {IComplianceManager} from "../interfaces/IComplianceManager.sol";
import {IMerkleTreeOperator} from "../interfaces/IMerkleTreeOperator.sol";
import {IMimc254} from "../interfaces/IMimc254.sol";
import {BaseInputBuilder} from "./BaseInputBuilder.sol";

/**
 * @title BaseAssetManager
 * @dev Base contract for asset managers.
 */
abstract contract BaseAssetManager is Ownable, BaseInputBuilder {
    using SafeERC20 for IERC20;

    struct FundReleaseDetails {
        address assetAddress;
        address payable recipient;
        address payable relayer;
        uint256 relayerGasFee;
        uint256 amount;
    }

    IVerifierHub internal _verifierHub;
    IAssetPool internal _assetPoolERC20;
    IAssetPool internal _assetPoolERC721;
    IAssetPool internal _assetPoolETH;
    IRelayerHub internal _relayerHub;
    IFeeManager internal _feeManager;
    IComplianceManager internal _complianceManager;
    IMerkleTreeOperator internal immutable _merkleTreeOperator;
    IMimc254 internal immutable _mimc254;

    address public constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    bytes32 public constant ASSET_ETH = keccak256(abi.encode(ETH_ADDRESS));

    uint256 public constant P =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    error RelayerNotRegistered();
    error NullifierUsed();
    error NullifierLocked();
    error MerkleRootNotAllowed();
    error NoteFooterUsed();
    error NoteAlreadyCreated();
    error InvalidNoteParameters();
    error ZeroAddress();
    error NoteFooterDuplicated();
    error RelayerMismatch();

    // we dont use it for now
    modifier onlyETHAssetPool() {
        require(
            msg.sender == address(_assetPoolETH),
            "BaseAssetManager: Only ETH Asset Pool"
        );
        _;
    }

    constructor(
        address assetPoolERC20,
        address assetPoolERC721,
        address assetPoolETH,
        address verifierHub,
        address relayerHub,
        address feeManager,
        address complianceManager,
        address merkleTreeOperator,
        address mimc254,
        address initialOwner
    ) Ownable(initialOwner) {
        if (assetPoolERC20 == address(0) || 
            assetPoolERC721 == address(0) ||
            assetPoolETH == address(0) ||
            verifierHub == address(0) ||
            relayerHub == address(0) ||
            feeManager == address(0) ||
            complianceManager == address(0) ||
            merkleTreeOperator == address(0) ||
            mimc254 == address(0) ||
            initialOwner == address(0)
            ) {
                revert ZeroAddress();
        }
        _assetPoolERC20 = IAssetPool(assetPoolERC20);
        _assetPoolERC721 = IAssetPool(assetPoolERC721);
        _assetPoolETH = IAssetPool(assetPoolETH);
        _verifierHub = IVerifierHub(verifierHub);
        _relayerHub = IRelayerHub(relayerHub);
        _feeManager = IFeeManager(feeManager);
        _complianceManager = IComplianceManager(complianceManager);
        _merkleTreeOperator = IMerkleTreeOperator(merkleTreeOperator);
        _mimc254 = IMimc254(mimc254);
    }

    receive() external payable {}

    /**
     * @dev Transfers the asset to the asset pool if there are
     *      any remaining assets due to network failures.
     */
    function releaseToAsssetPool(
        address asset,
        uint256 amount
    ) external onlyOwner {
        require(amount > 0, "BaseAssetManager: amount must be greater than 0");
        if (asset == address(0) || asset == ETH_ADDRESS) {
            (bool success, ) = address(_assetPoolETH).call{value: amount}("");
            require(success, "BaseAssetManager: Failed to send Ether");
        } else {
            IERC20(asset).safeTransfer(address(_assetPoolERC20), amount);
        }
    }

    function setAssetPoolERC20(address assetPoolERC20) public onlyOwner {
        if (assetPoolERC20 != address(0)) {
            _assetPoolERC20 = IAssetPool(assetPoolERC20);
        }
    }

    function setAssetPoolERC721(address assetPoolERC721) public onlyOwner {
        if (assetPoolERC721 != address(0)) {
            _assetPoolERC721 = IAssetPool(assetPoolERC721);
        }
    }

    function setAssetPoolETH(address assetPoolETH) public onlyOwner {
        if (assetPoolETH != address(0)) {
            _assetPoolETH = IAssetPool(assetPoolETH);
        }
    }

    function setVerifierHub(address verifierHub) public onlyOwner {
        if (verifierHub != address(0)) {
            _verifierHub = IVerifierHub(verifierHub);
        }
    }

    function setRelayerHub(address relayerHub) public onlyOwner {
        if (relayerHub != address(0)) {
            _relayerHub = IRelayerHub(relayerHub);
        }
    }

    function setFeeManager(address feeManager) public onlyOwner {
        if (feeManager != address(0)) {
            _feeManager = IFeeManager(feeManager);
        }
    }

    function setComplianceManager(address complianceManager) public onlyOwner {
        if (complianceManager != address(0)) {
            _complianceManager = IComplianceManager(complianceManager);
        }
    }

    function getAssetPoolERC20() public view returns (address) {
        return address(_assetPoolERC20);
    }

    function getAssetPoolERC721() public view returns (address) {
        return address(_assetPoolERC721);
    }

    function getAssetPoolETH() public view returns (address) {
        return address(_assetPoolETH);
    }

    function getVerifierHub() public view returns (address) {
        return address(_verifierHub);
    }

    function getRelayerHub() public view returns (address) {
        return address(_relayerHub);
    }

    function getFeeManager() public view returns (address) {
        return address(_feeManager);
    }
    
    function getComplianceManager() public view returns (address) {
        return address(_complianceManager);
    }

    function getMerkleTreeOperator() public view returns (address) {
        return address(_merkleTreeOperator);
    }

    function getMimc254() public view returns (address) {
        return address(_mimc254);
    }

    function _postDeposit(bytes32 _noteCommitment) internal {
        _merkleTreeOperator.setNoteCommitmentCreated(_noteCommitment);
        _merkleTreeOperator.appendMerkleLeaf(bytes32(_noteCommitment));
    }

    function _postWithdraw(bytes32 _nullifier) internal {
        _merkleTreeOperator.setNullifierUsed(_nullifier);
    }

    function _setNullifierLock(bytes32 _nullifier, bool _locked) internal {
        _merkleTreeOperator.setNullifierLocked(_nullifier, _locked);
    } 
    
    function _registerNoteFooter(bytes32 _noteFooter) internal {
        _merkleTreeOperator.setNoteFooterUsed(_noteFooter);
    }

    function _releaseERC20WithFee(
        address _asset,
        address _to,
        address _relayer,
        uint256 _relayerGasFee,
        uint256 _amount
    ) internal returns (uint256, uint256, uint256) {
        (
            uint256 actualAmount,
            uint256 serviceFee,
            uint256 relayerRefund
        ) = _feeManager.calculateFee(_amount, _relayerGasFee);

        _assetPoolERC20.release(_asset, _to, actualAmount);

        if (relayerRefund > 0) {
            _assetPoolERC20.release(_asset, _relayer, relayerRefund);
        }
        if (serviceFee > 0) {
            _assetPoolERC20.release(_asset, address(_feeManager), serviceFee);
        }

        return (actualAmount, serviceFee, relayerRefund);
    }

    function _releaseETHWithFee(
        address payable _to,
        address payable _relayer,
        uint256 _relayerGasFee,
        uint256 _amount
    ) internal returns (uint256, uint256, uint256) {
        (
            uint256 actualAmount,
            uint256 serviceFee,
            uint256 relayerRefund
        ) = _feeManager.calculateFee(_amount, _relayerGasFee);

        _assetPoolETH.release(_to, actualAmount);

        if (relayerRefund > 0) {
            _assetPoolETH.release(_relayer, relayerRefund);
        }
        if (serviceFee > 0) {
            _assetPoolETH.release(payable(address(_feeManager)), serviceFee);
        }

        return (actualAmount, serviceFee, relayerRefund);
    }

    function _releaseFunds(
        FundReleaseDetails memory details
    ) internal returns (uint256, uint256, uint256) {
        if (
            details.assetAddress == ETH_ADDRESS ||
            details.assetAddress == address(0)
        ) {
            return
                _releaseETHWithFee(
                    details.recipient,
                    details.relayer,
                    details.relayerGasFee,
                    details.amount
                );
        } else {
            return
                _releaseERC20WithFee(
                    details.assetAddress,
                    details.recipient,
                    details.relayer,
                    details.relayerGasFee,
                    details.amount
                );
        }
    }

    function _verifyProof(
        bytes calldata _proof,
        bytes32[] memory _inputs,
        string memory verifierType
    ) internal view {
        IVerifier verifier = _verifierHub.getVerifier(verifierType);
        require(verifier.verify(_proof, _inputs), "invalid proof");
    }


    function _buildNoteForERC20(
        address asset,
        uint256 amount,
        bytes32 noteFooter
    ) internal view returns (bytes32) {
        return _buildNote(
            asset,
            amount,
            noteFooter,
            IMimc254.NoteDomainSeparator.FUNGIBLE
        );
    }

    function _buildNoteForERC721(
        address asset,
        uint256 tokenId,
        bytes32 noteFooter
    ) internal view returns (bytes32) {
        return _buildNote(
            asset,
            tokenId,
            noteFooter,
            IMimc254.NoteDomainSeparator.NON_FUNGIBLE
        );
    }

    function _validateRelayerIsRegistered(address relayer) internal view {
        if (!_relayerHub.isRelayerRegistered(relayer)) {
            revert RelayerNotRegistered();
        }
    }

    function _validateNullifierIsNotUsed(bytes32 nullifier) internal view {
        if (!_merkleTreeOperator.nullifierIsNotUsed(nullifier)) {
            revert NullifierUsed();
        }
    }
    
    function _validateNullifierIsNotLocked(bytes32 nullifier) internal view {
        if (!_merkleTreeOperator.nullifierIsNotLocked(nullifier)) {
            revert NullifierLocked();
        }
    }

    function _validateMerkleRootIsAllowed(bytes32 merkleRoot) internal view {
        if (!_merkleTreeOperator.merkleRootIsAllowed(merkleRoot)) {
            revert MerkleRootNotAllowed();
        }
    }

    function _validateNoteFooterIsNotUsed(bytes32 noteFooter) internal view {
        if (!_merkleTreeOperator.noteFooterIsNotUsed(noteFooter)) {
            revert NoteFooterUsed();
        }
    }

    function _validateNoteIsNotCreated(bytes32 noteCommitment) internal view {
        if (!_merkleTreeOperator.noteIsNotCreated(noteCommitment)) {
            revert NoteAlreadyCreated();
        }
    }

    function _buildNote(
        address asset,
        uint256 amount,
        bytes32 noteFooter,
        IMimc254.NoteDomainSeparator domainSeparator
    ) private view returns (bytes32) {
        
        if (asset == address(0) || amount  == 0 || noteFooter == bytes32(0)){
            revert InvalidNoteParameters();
        }
        uint256[] memory array = new uint256[](4);
        array[0] = uint256(domainSeparator);
        array[1] = uint256(_bytifyToNoir(asset));
        array[2] = amount;
        array[3] = uint256(noteFooter);
        return
            bytes32(_mimc254.mimcBn254(array));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title BaseInputBuilder
 * @dev Base contract for ZK verify input builders.
 */
contract BaseInputBuilder {
    uint256 internal _primeField;

    constructor(uint256 primeField) {
        _primeField = primeField;
    }

    function _bytifyToNoir(address value) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(ripemd160(abi.encode(value)))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.20;

interface IAssetPool {
    function setAssetManager(address assetManager,bool registered) external;

    function release(address tokenOrNft, address to, uint256 amountOrNftId) external;

    function release(address payable to, uint256 amount) external;

    function getAssetManagerRegistration( address assetManager) 
        external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.20;


interface IComplianceManager {
    function isAuthorized(address observer, address subject) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.20;

interface IFeeManager {
    function calculateFee(
        uint256 amount,
        uint256 relayerRefund
    ) external view returns (uint256, uint256, uint256);

    function calculateFee(
        uint256[4] calldata amount,
        uint256[4] calldata relayerRefund
    ) external view returns (uint256[4] memory, uint256[4] memory, uint256[4] memory);

    function calculateFeeForFSN(
        uint256[4] calldata amount,
        uint256[4] calldata relayerRefund
    ) external view returns (uint256[] memory, uint256[4] memory, uint256[4] memory);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.20;

interface IMerkleTreeOperator {
    function appendMerkleLeaf(bytes32 leaf) external;
    function setNoteCommitmentCreated(bytes32 commitment) external;
    function setNullifierUsed(bytes32 nullifier) external;
    function setNullifierLocked(bytes32 nullifier, bool locked) external;
    function setNoteFooterUsed(bytes32 noteFooter) external;

    function isRelayerRegistered(address _relayer) external view returns (bool);

    function merkleRootIsAllowed(
        bytes32 _merkleRoot
    ) external view returns (bool);

    function nullifierIsNotUsed(
        bytes32 _nullifier
    ) external view returns (bool);
   
    function nullifierIsNotLocked(
        bytes32 _nullifier
    ) external view returns (bool);

    function noteIsNotCreated(
        bytes32 _noteCommitment
    ) external view returns (bool);

    function noteFooterIsNotUsed(
        bytes32 _noteFooter
    ) external view returns (bool);

    function getMerkleRoot() external view returns (bytes32);

    function getMerklePath(
        bytes32 _noteCommitment
    ) external view returns (bytes32[] memory, bool[] memory, bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.20;


interface IMimc254 {
    enum NoteDomainSeparator {
        FUNGIBLE,
        NON_FUNGIBLE
    }

    function mimcBn254(uint256[] memory array) external view returns (uint256);

    /*function mimcBn254ForNote(
        uint256[3] memory array,
        NoteDomainSeparator domainSeparator
    ) external view returns (uint256);

    function mimcBn254ForTree(
        uint256[3] memory _array
    ) external view returns (uint256);

    function mimcBn254ForRoute(
        uint256[12] memory _array
    ) external view returns (uint256);*/
    
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.20;

interface IRelayerHub {
    function isRelayerRegistered(address _relayer) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.20;

interface IVerifier {
    function verify(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IVerifier} from "./IVerifier.sol";

interface IVerifierHub {
    function setVerifier(string memory verifierName, address addr) external;

    function getVerifierNames() external returns (string[] memory);

    function getVerifier(
        string memory verifierName
    ) external view returns (IVerifier);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// Internal imports
import {BaseAssetManager} from "../../core/base/BaseAssetManager.sol";
import {UniswapInputBuilder} from "./UniswapInputBuilder.sol";
import {IWETH9} from "../../core/interfaces/IWETH9.sol";

// External imports
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title UniswapCoreAssetManager
 * @dev Core contract for Uniswap asset managers.
 */
contract UniswapCoreAssetManager is BaseAssetManager, UniswapInputBuilder {
    /**
     * * LIBRARIES
     */

    using SafeERC20 for IERC20;

    /**
     * * STRUCTS
     */

    struct UniswapNoteData {
        address assetAddress;
        uint256 amount;
        bytes32 nullifier;
    }

    struct FeesDetails {
        uint256 serviceFee;
        uint256 relayerRefund;
    }

    struct AutoSplitArgs {
        // asset address of the note that will be split
        address asset;
        // amount of the note that will be split
        uint256 actualAmount;
        // desired amount of the note that will be split
        uint256 desiredAmount;
        // nullifier of the note that will be split
        bytes32 nullifier;
        // note footer of the out note created after split
        bytes32 noteFooter;
        // note footer of the change note created after split
        bytes32 changeNoteFooter;
    }

    struct AutoSplitDetails {
        // out note commitment after split
        bytes32 note;
        // change note commitment after split
        bytes32 changeNote;
        // change amount after split
        uint256 changeAmount;
    }

    struct TransferFundsToVaultWithFeesAndCreateNoteData {
        // amount of the note that will be transferred to the vault
        uint256 actualAmount;
        // asset of the note that will be transferred to the vault (normailized means WETH IS ETH)
        address normalizedAsset;
        // note footer of the note that will be transferred to the vault
        bytes32 noteCommitment;
        // fees details of the transfer
        FeesDetails feesDetails;
    }

    /**
     * * STATE VARIABLES
     */

    address public WETH_ADDRESS;

    /**
     * * CONSTRUCTOR
     */

    constructor(
        address assetPoolERC20,
        address assetPoolERC721,
        address assetPoolETH,
        address verifierHub,
        address relayerHub,
        address feeManager,
        address complianceManager,
        address merkleTreeOperator,
        address mimcBn254,
        address initialOwner,
        address wethAddress
    )
        BaseAssetManager(
            assetPoolERC20,
            assetPoolERC721,
            assetPoolETH,
            verifierHub,
            relayerHub,
            feeManager,
            complianceManager,
            merkleTreeOperator,
            mimcBn254,
            initialOwner
        )
        UniswapInputBuilder(P)
    {
        WETH_ADDRESS = wethAddress;
    }

    /**
     * * UTILS (WETH RELATED)
     */

    /**
     * @dev Converts ETH to WETH if the specified asset is ETH. This is essential for handling ETH in contracts
     * that require ERC20 compatibility. If the asset is already an ERC20 token, no conversion occurs.
     * @param assetAddress The address of the asset to potentially convert to WETH.
     * @param amount The amount of the asset to convert.
     * @return The address of WETH if conversion occurred, or the original asset address otherwise.
     */
    function _convertToWethIfNecessary(
        address assetAddress,
        uint256 amount
    ) internal returns (address) {
        if (assetAddress == ETH_ADDRESS || assetAddress == address(0)) {
            if (amount > 0) {
                IWETH9(WETH_ADDRESS).deposit{value: amount}();
            }

            return WETH_ADDRESS;
        }

        return assetAddress;
    }

    /**
     * @dev Converts WETH to ETH if the specified asset is WETH. Facilitates operations requiring native ETH
     * by unwrapping WETH. If the asset is not WETH, no action is taken.
     * @param assetAddress The address of the asset to potentially convert to ETH.
     * @param amount The amount of the asset to convert.
     * @return The address of ETH (represented as 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) if conversion occurred,
     *         or the original asset address otherwise.
     */
    function _convertToEthIfNecessary(
        address assetAddress,
        uint256 amount
    ) internal returns (address) {
        if (assetAddress == WETH_ADDRESS) {
            IWETH9(WETH_ADDRESS).withdraw(amount);
            return ETH_ADDRESS;
        }

        return assetAddress;
    }

    /**
     * * UTILS (NOTE RELATED)
     */

    /**
     * @dev Generates a unique note commitment from asset details and a note footer. This identifier can be used
     * for tracking and managing assets within the contract.
     * @param asset The address of the asset related to the note.
     * @param amount The amount of the asset.
     * @param noteFooter A unique identifier to ensure the uniqueness of the note.
     * @return A bytes32 representing the generated note commitment.
     */
    /*function _generateNoteCommitment(
        address asset,
        uint256 amount,
        bytes32 noteFooter
    ) internal view returns (bytes32) {
        return _buildNoteForERC20(asset, amount, noteFooter);
    }*/

    /**
     * * UTILS (TRANSFER RELATED)
     */

    /**
     * @dev Safely transfers ETH to a specified address. Ensures that the transfer is successful
     * and reverts the transaction if it fails.
     * @param to The recipient address.
     * @param amount The amount of ETH to transfer.
     */
    function _transferETH(address to, uint256 amount) internal {
        if (amount > 0) {
            (bool success, ) = to.call{value: amount}("");
            require(success, "transferETH: transfer failed");
        }
    }

    /**
     * @dev Transfers ERC20 tokens to a specified address using the SafeERC20 library. Provides safety checks
     * and reverts the transaction if the transfer fails.
     * @param token The ERC20 token address.
     * @param to The recipient address.
     * @param amount The amount of tokens to transfer.
     */
    function _transferERC20(
        address token,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            //IERC20(token).forceApprove(to, amount);
            IERC20(token).safeTransfer(to, amount);
        }
    }

    /**
     * @dev General utility function to transfer an asset (ETH or ERC20 token) to a specified address.
     * Automates the distinction between ETH and ERC20 transfers.
     * @param asset The asset address.
     * @param to The recipient address.
     * @param amount The amount of the asset to transfer.
     */
    function _transferAsset(
        address asset,
        address to,
        uint256 amount
    ) internal {
        if (asset == ETH_ADDRESS || asset == address(0)) {
            _transferETH(to, amount);
        } else {
            _transferERC20(asset, to, amount);
        }
    }

    /**
     * @dev Transfers an asset (ETH or ERC20) to the contract's vault for asset management.
     * Utilizes internal methods to handle the specificities of ETH vs. ERC20 transfers.
     * @param assetAddress The address of the asset to transfer.
     * @param amount The amount of the asset to transfer.
     */
    function _transferAssetToVault(
        address assetAddress,
        uint256 amount
    ) internal {
        address transferTo = (assetAddress == ETH_ADDRESS ||
            assetAddress == address(0))
            ? address(_assetPoolETH)
            : address(_assetPoolERC20);

        _transferAsset(assetAddress, transferTo, amount);
    }

    /**
     * @dev Transfers funds to the vault, deducts necessary fees, and creates a note commitment.
     * This function is used after an operation (like swapping or liquidity provision) to move the resulted asset
     * into the vault. It handles fee deduction, transfers the net amount to the vault, and creates a new note
     * representing the deposited asset.
     * @param asset The address of the asset to be transferred to the vault.
     * @param amount The gross amount of the asset before fees are deducted.
     * @param noteFooter The unique identifier used to generate the note commitment.
     * @param relayerGasFee The gas fee to be compensated to the relayer.
     * @param relayer The address of the relayer to receive the gas fee refund.
     * @return data A struct containing details of the transfer, including the normalized asset
     *         address (converted to ETH if necessary), the actual amount transferred to the vault after fees,
     *         the note commitment, and details of the fees deducted.
     */
    function _transferFundsToVaultWithFeesAndCreateNote(
        address asset,
        uint256 amount,
        bytes32 noteFooter,
        uint256 relayerGasFee,
        address payable relayer
    )
        internal
        returns (TransferFundsToVaultWithFeesAndCreateNoteData memory data)
    {
        data.normalizedAsset = _convertToEthIfNecessary(asset, amount);

        (
            data.actualAmount,
            data.feesDetails.serviceFee,
            data.feesDetails.relayerRefund
        ) = _feeManager.calculateFee(amount, relayerGasFee);

        _chargeFees(data.normalizedAsset, relayer, data.feesDetails);
        
        if (data.actualAmount > 0 ){
            _transferAssetToVault(data.normalizedAsset, data.actualAmount);

            data.noteCommitment = _buildNoteForERC20(
            data.normalizedAsset,
            data.actualAmount,
            noteFooter
            );
            _postDeposit(bytes32(data.noteCommitment));
        }
    }

    /**
     * * UTILS (RELEASE RELATED)
     */

    /**
     * @dev Releases an asset from the vault to a specified address without charging any fees.
     * Can handle both ETH and ERC20 assets.
     * @param asset The asset to release.
     * @param to The recipient address.
     * @param amount The amount of the asset to release.
     */
    function _releaseAssetFromVaultWithoutFee(
        address asset,
        address to,
        uint256 amount
    ) internal {
        if (amount > 0) {
            if (asset == ETH_ADDRESS || asset == address(0)) {
                _assetPoolETH.release(payable(to), amount);
            } else {
                _assetPoolERC20.release(asset, to, amount);
            }
        }
    }

    /**
     * @dev Releases funds based on the details provided in the fundReleaseDetails struct.
     * Calculates fees and refunds associated with the release process.
     * @param fundReleaseDetails A struct containing details about the fund release.
     * @return releasedAmount The amount of funds released.
     * @return feesDetails A struct containing details about the fees and refunds.
     */
    function _releaseAndPackDetails(
        FundReleaseDetails memory fundReleaseDetails
    )
        internal
        returns (uint256 releasedAmount, FeesDetails memory feesDetails)
    {
        (
            releasedAmount,
            feesDetails.serviceFee,
            feesDetails.relayerRefund
        ) = _releaseFunds(fundReleaseDetails);
    }

    /**
     * * UTILS (FEE RELATED)
     */

    /**
     * @dev Charges fees for a transaction and transfers them to the relayer and the fee manager.
     * The function ensures that the appropriate parties receive their respective fees for the operation.
     * @param asset The asset from which fees are to be charged.
     * @param relayer The address of the relayer to receive the relayer refund.
     * @param feesDetails The details of the fees to be charged, including service fees and relayer refunds.
     */
    function _chargeFees(
        address asset,
        address payable relayer,
        FeesDetails memory feesDetails
    ) internal {
        _transferAsset(asset, relayer, feesDetails.relayerRefund);
        _transferAsset(asset, address(_feeManager), feesDetails.serviceFee);
    }

    /**
     * @dev Charges fees from the vault for a transaction, transferring them to the relayer and the fee manager.
     * This function is used when fees need to be paid from assets stored within the vault.
     * @param asset The asset from which fees are to be charged.
     * @param relayer The address of the relayer to receive the relayer refund.
     * @param feesDetails The details of the fees to be charged, including service fees and relayer refunds.
     */
    function _chargeFeesFromVault(
        address asset,
        address payable relayer,
        FeesDetails memory feesDetails
    ) internal {
        _releaseAssetFromVaultWithoutFee(
            asset,
            relayer,
            feesDetails.relayerRefund
        );
        _releaseAssetFromVaultWithoutFee(
            asset,
            address(_feeManager),
            feesDetails.serviceFee
        );
    }

    /**
     * * UTILS (AUTO SPLIT RELATED)
     */

    /**
     * @dev Splits a note into two parts: a desired amount and the remaining change. This is used
     * for operations where the exact note amount is not needed and the remainder needs to be handled.
     * @param args The arguments for the split operation, including the asset, amounts, and note footers.
     * @return autoSplitDetails The details of the split operation,
     *         including the new note commitments and change amount.
     */
    function _autosplit(
        AutoSplitArgs memory args
    ) internal returns (AutoSplitDetails memory autoSplitDetails) {
        require(
            args.actualAmount >= args.desiredAmount,
            "autosplit: actual amount is less than desired amount"
        );

        autoSplitDetails.changeAmount = args.actualAmount - args.desiredAmount;

        autoSplitDetails.note = _buildNoteForERC20(
            args.asset,
            args.desiredAmount,
            args.noteFooter
        );
        autoSplitDetails.changeNote = _buildNoteForERC20(
            args.asset,
            autoSplitDetails.changeAmount,
            args.changeNoteFooter
        );

        _postWithdraw(args.nullifier);
        _postDeposit(bytes32(autoSplitDetails.note));
        _postDeposit(bytes32(autoSplitDetails.changeNote));
    }

    /**
     * * UTILS (TOKENS SORT RELATED)
     */

    /**
     * @dev Sorts two tokens based on their addresses and ensures the amounts are aligned with the sorted order.
     * This is useful for operations that require a consistent ordering of token addresses.
     * @param tokens An array of two token addresses to be sorted.
     * @param amounts An array of two amounts corresponding to the tokens array.
     * @return sortedTokens The sorted array of token addresses.
     * @return sortedAmounts The array of amounts aligned with the sorted order of tokens.
     * @return originalIndices The array of original indices.
     */
    function _sortTokens(
        address[2] memory tokens,
        uint256[2] memory amounts
    ) internal pure returns (address[2] memory, uint256[2] memory, uint8[2] memory) {
        if (uint256(uint160(tokens[0])) < uint256(uint160(tokens[1]))) {
            return (tokens, amounts, [0, 1]);
        }

        return ([tokens[1], tokens[0]], [amounts[1], amounts[0]], [1, 0]);
    }

    /**
     * @dev Sorts two tokens based on their addresses, converts them to WETH if necessary,
     * and ensures the amounts are aligned with the sorted order. This function combines token sorting
     * with the conversion operation for contracts that require WETH.
     * @param tokens An array of two token addresses to be sorted and potentially converted to WETH.
     * @param amounts An array of two amounts corresponding to the tokens array.
     * @return sortedTokens The sorted array of token addresses, converted to WETH if necessary.
     * @return sortedAmounts The array of amounts aligned with the sorted and possibly converted order of tokens.
     * @return originalIndices The array of original indices.
     */
    function _sortAndConvertToWeth(
        address[2] memory tokens,
        uint256[2] memory amounts
    )
        internal
        returns (
            address[2] memory sortedTokens,
            uint256[2] memory sortedAmounts,
            uint8[2] memory originalIndices
        )
    {
        address[2] memory wethedTokens = [
            _convertToWethIfNecessary(tokens[0], amounts[0]),
            _convertToWethIfNecessary(tokens[1], amounts[1])
        ];

        (sortedTokens, sortedAmounts, originalIndices) = _sortTokens(wethedTokens, amounts);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {BaseInputBuilder} from "../../core/base/BaseInputBuilder.sol";

contract UniswapInputBuilder is BaseInputBuilder {
    struct UniswapSimpleSwapInputs {
        bytes32 merkleRoot;
        address assetIn;
        uint256 amountIn;
        bytes32 nullifierIn;
        address assetOut;
        bytes32 noteFooter;
        uint24 poolFee;
        uint256 amountOutMin;
        address relayer;
    }

    struct UniswapCollectFeesInputs {
        bytes32 merkleRoot;
        address positionAddress;
        uint256 tokenId;
        bytes32 fee1NoteFooter;
        bytes32 fee2NoteFooter;
        address relayer;
    }

    struct UniswapLiquidityProvisionInputs {
        bytes32 merkleRoot;
        address asset1Address;
        address asset2Address;
        uint256 amount1;
        uint256 amount2;
        bytes32 nullifier1;
        bytes32 nullifier2;
        int24 tickMin;
        int24 tickMax;
        bytes32 noteFooter;
        bytes32 changeNoteFooter1;
        bytes32 changeNoteFooter2;
        address relayer;
        uint256 amount1Min;
        uint256 amount2Min;
        uint256 deadline;
        uint24 poolFee;
    }

    struct UniswapRemoveLiquidityInputs {
        bytes32 merkleRoot;
        address positionAddress;
        bytes32 positionNullifier;
        uint256 tokenId;
        bytes32 out1NoteFooter;
        bytes32 out2NoteFooter;
        address relayer;
        uint256 amount1Min;
        uint256 amount2Min;
        uint256 deadline;
    }

    constructor(uint256 primeField) BaseInputBuilder(primeField) {}

    function _buildUniswapSimpleSwapInputs(
        UniswapSimpleSwapInputs memory _rawInputs
    ) internal view returns (bytes32[] memory) {
        bytes32[] memory inputs = new bytes32[](9);

        inputs[0] = _rawInputs.merkleRoot;
        inputs[1] = _bytifyToNoir(_rawInputs.assetIn);
        inputs[2] = bytes32(_rawInputs.amountIn);
        inputs[3] = _rawInputs.nullifierIn;
        inputs[4] = _bytifyToNoir(_rawInputs.assetOut);
        inputs[5] = _rawInputs.noteFooter;
        inputs[6] = bytes32(uint256(_rawInputs.poolFee));
        inputs[7] = bytes32(_rawInputs.amountOutMin);
        inputs[8] = _bytifyToNoir(_rawInputs.relayer);

        return inputs;
    }

    function _buildUniswapCollectFeesInputs(
        UniswapCollectFeesInputs memory _rawInputs
    ) internal pure returns (bytes32[] memory) {
        bytes32[] memory inputs = new bytes32[](6);

        inputs[0] = _rawInputs.merkleRoot;
        inputs[1] = _bytifyToNoir(_rawInputs.positionAddress);
        inputs[2] = bytes32(_rawInputs.tokenId);
        inputs[3] = _rawInputs.fee1NoteFooter;
        inputs[4] = _rawInputs.fee2NoteFooter;
        inputs[5] = _bytifyToNoir(_rawInputs.relayer);

        return inputs;
    }

    function _buildUniswapRemoveLiquidityInputs(
        UniswapRemoveLiquidityInputs memory _rawInputs
    ) internal pure returns (bytes32[] memory) {
        bytes32[] memory inputs = new bytes32[](10);

        inputs[0] = _rawInputs.merkleRoot;
        inputs[1] = _bytifyToNoir(_rawInputs.positionAddress);
        inputs[2] = bytes32(_rawInputs.tokenId);
        inputs[3] = _rawInputs.positionNullifier;
        inputs[4] = _rawInputs.out1NoteFooter;
        inputs[5] = _rawInputs.out2NoteFooter;
        inputs[6] = bytes32(_rawInputs.deadline);
        inputs[7] = _bytifyToNoir(_rawInputs.relayer);
        inputs[8] = bytes32(_rawInputs.amount1Min);
        inputs[9] = bytes32(_rawInputs.amount2Min);

        return inputs;
    }

    function _buildUniswapLiquidityProvisionInputs(
        UniswapLiquidityProvisionInputs memory _rawInputs
    ) internal pure returns (bytes32[] memory) {
        bytes32[] memory inputs = new bytes32[](19);

        inputs[0] = _rawInputs.merkleRoot;
        inputs[1] = _bytifyToNoir(_rawInputs.asset1Address);
        inputs[2] = _bytifyToNoir(_rawInputs.asset2Address);
        inputs[3] = bytes32(_rawInputs.amount1);
        inputs[4] = bytes32(_rawInputs.amount2);
        inputs[5] = _int24ToBytes32(_abs(_rawInputs.tickMin));
        inputs[6] = _int24ToBytes32(_abs(_rawInputs.tickMax));
        inputs[7] = _boolToBytes32(_rawInputs.tickMin >= 0);
        inputs[8] = _boolToBytes32(_rawInputs.tickMax >= 0);
        inputs[9] = _rawInputs.nullifier1;
        inputs[10] = _rawInputs.nullifier2;
        inputs[11] = _rawInputs.noteFooter;
        inputs[12] = _rawInputs.changeNoteFooter1;
        inputs[13] = _rawInputs.changeNoteFooter2;
        inputs[14] = _bytifyToNoir(_rawInputs.relayer);
        inputs[15] = bytes32(_rawInputs.amount1Min);
        inputs[16] = bytes32(_rawInputs.amount2Min);
        inputs[17] = bytes32(_rawInputs.deadline);
        inputs[18] = bytes32(uint256(_rawInputs.poolFee));

        return inputs;
    }

    function _int24ToBytes32(
        int24 value
    ) internal pure returns (bytes32 result) {
        assembly {
            result := value
        }
    }

    function _boolToBytes32(bool value) public pure returns (bytes32) {
        return value ? bytes32(uint256(1)) : bytes32(uint256(0));
    }

    function _abs(int24 value) internal pure returns (int24) {
        return value < 0 ? -value : value;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// Internal imports
import {UniswapCoreAssetManager} from "./UniswapCoreAssetManager.sol";
import {INonfungiblePositionManager} from "./interfaces/INonfungiblePositionManager.sol";

// External imports
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title UniswapLiquidityAssetManager
 * @dev Extends UniswapCoreAssetManager to manage liquidity on Uniswap.
 *      Handles liquidity provision, fee collection, and liquidity removal.
 */
contract UniswapLiquidityAssetManager is UniswapCoreAssetManager {
    /**
     * * LIBRARIES
     */

    using SafeERC20 for IERC20;

    /**
     * * STRUCTS
     */

    struct UniswapLPData {
        address token1;
        address token2;
    }

    struct UniswapLiquidityProvisionArgs {
        // data of the note that will be used for liquidity provision as first token
        UniswapNoteData noteData1;
        // data of the note that will be used for liquidity provision as second token
        UniswapNoteData noteData2;
        // address of the relayer
        address payable relayer;
        // gas fees of the relayer
        uint256[2] relayerGasFees;
        // merkle root of the merkle tree that the commitment of the note is included
        bytes32 merkleRoot;
        // note footer of the note that will be created after mint (both tokens)
        bytes32[2] changeNoteFooters;
        // tick min of the liquidity provision
        int24 tickMin;
        // tick max of the liquidity provision
        int24 tickMax;
        // deadline of the liquidity provision
        uint256 deadline;
        // note footer of the NFT position note that will be created after liquidity provision
        bytes32 positionNoteFooter;
        // pool fee of the liquidity provision (Uniswap)
        uint24 poolFee;
        // minimum amount of the asset that will be minted as liquidity
        uint256[2] amountsMin;
    }

    struct UniswapCollectFeesArgs {
        // merkle root of the merkle tree that the commitment of the NFT position note is included
        bytes32 merkleRoot;
        // NFT position note id
        uint256 tokenId;
        // note footer of the notes that will be created after collecting fees (both tokens)
        bytes32[2] feeNoteFooters;
        // gas fees of the relayer (from both tokens)
        uint256[2] relayerGasFees;
        // address of the relayer
        address payable relayer;
    }

    struct UniswapRemoveLiquidityArgs {
        // merkle root of the merkle tree that the commitment of the NFT position note is included
        bytes32 merkleRoot;
        // NFT position note
        UniswapNoteData positionNote;
        // note footer of the notes that will be created after removing liquidity (both tokens)
        bytes32[2] outNoteFooters;
        // gas fees of the relayer (from both tokens)
        uint256[2] relayerGasFees;
        // deadline of the remove liquidity
        uint256 deadline;
        // address of the relayer
        address payable relayer;
        // minimum amount of the asset that will be received after remove liquidity
        uint256[2] amountsMin;
    }

    /**
     * * STATE VARIABLES
     */

    mapping(uint256 tokenId => UniswapLPData data) public uniswapLPData;
    INonfungiblePositionManager public immutable nonfungiblePositionManager;

    /**
     * * EVENTS
     */

    event UniswapLiquidityProvision(
        uint256 tokenId,
        bytes32 positionNote,
        bytes32[2] nullifiers,
        uint256[2] changeAmounts,
        bytes32[2] changeNoteCommitments,
        bytes32[2] changeNoteFooters
    );

    event UniswapCollectFees(
        uint256 tokenId,
        address[2] assets,
        uint256[2] amounts,
        bytes32[2] feeNoteCommitments,
        bytes32[2] feeNoteFooters
    );

    event UniswapRemoveLiquidity(
        uint256 tokenId,
        bytes32 positionNullifier,
        uint256[2] amounts,
        bytes32[2] outNoteCommitments,
        bytes32[2] outNoteFooters
    );

    /**
     * * CONSTRUCTOR
     */

    constructor(
        address assetPoolERC20,
        address assetPoolERC721,
        address assetPoolETH,
        address verifierHub,
        address relayerHub,
        address feeManager,
        address complianceManager,
        address merkleTreeOperator,
        address mimcBn254,
        address initialOwner,
        INonfungiblePositionManager _nonfungiblePositionManager,
        address wethAddress
    )
        UniswapCoreAssetManager(
            assetPoolERC20,
            assetPoolERC721,
            assetPoolETH,
            verifierHub,
            relayerHub,
            feeManager,
            complianceManager,
            merkleTreeOperator,
            mimcBn254,
            initialOwner,
            wethAddress
        )
    {
        nonfungiblePositionManager = _nonfungiblePositionManager;
    }

    /**
     * * HANDLERS (LIQUIDITY PROVISION)
     */

    /**
     * @dev Provisions liquidity to Uniswap by minting a new LP token.
     * Requires validation of input arguments, verification of proof, and preparation of liquidity provision arguments.
     * Mints the LP token and manages related assets and notes.
     * @param args Arguments required for liquidity provision including notes data,
     *        relayer information, fee details, and Uniswap pool parameters.
     * @param proof Cryptographic proof to verify the operation.
     */
    function uniswapLiquidityProvision(
        UniswapLiquidityProvisionArgs memory args,
        bytes calldata proof
    ) public returns (uint256 tokenId) {
        _validateLiquidityProvisionArgs(args);
        _verifyProofForLiquidityProvision(args, proof);

        INonfungiblePositionManager.MintParams memory mintParams;
        uint8[2] memory originalIndices;

        (
            mintParams,
            //feesDetails,
            originalIndices
        ) = _releaseFundsAndPrepareLiquidityProvisionArgs(args);


        bytes32[2] memory changeNoteCommitments;
        uint256[2] memory changeAmounts;
        bytes32 positionNote;

        (
            changeNoteCommitments,
            changeAmounts,
            positionNote,
            tokenId
        ) = _executeLPMint(args, mintParams, originalIndices);

        emit UniswapLiquidityProvision(
            tokenId,
            positionNote,
            [args.noteData1.nullifier, args.noteData2.nullifier],
            [changeAmounts[originalIndices[0]], changeAmounts[originalIndices[1]]],
            [changeNoteCommitments[originalIndices[0]], changeNoteCommitments[originalIndices[1]]],
            args.changeNoteFooters
        );
    }

    /**
     * * HANDLERS (COLLECT FEES)
     */

    /**
     * @dev Collects fees accrued from liquidity provision on Uniswap.
     * Validates arguments, verifies proof, and handles the transfer of collected fees to the asset vault.
     * @param args Arguments for fee collection including the LP token ID, fee note footers, and relayer information.
     * @param proof Cryptographic proof to verify the fee collection.
     * @return dataToken1 Information about the first token's fee collection
     *         including the amount transferred to the vault and fee details.
     * @return dataToken2 Information about the second token's fee collection
     *         including the amount transferred to the vault and fee details.
     */
    function uniswapCollectFees(
        UniswapCollectFeesArgs memory args,
        bytes calldata proof
    )
        public
        returns (
            TransferFundsToVaultWithFeesAndCreateNoteData memory dataToken1,
            TransferFundsToVaultWithFeesAndCreateNoteData memory dataToken2
        )
    {
        _validateCollectFeesArgs(args);
        _verifyProofForCollectFees(args, proof);
        _releaseERC721Position(args.tokenId);

        _registerNoteFooter(args.feeNoteFooters[0]);
        _registerNoteFooter(args.feeNoteFooters[1]);

        (uint256 amount0, uint256 amount1) = nonfungiblePositionManager.collect(
            _prepareCollectFeeParams(args.tokenId)
        );

        _transferERC721PositionToVault(args.tokenId);

        (dataToken1) = _transferFundsToVaultWithFeesAndCreateNote(
            uniswapLPData[args.tokenId].token1,
            amount0,
            args.feeNoteFooters[0],
            args.relayerGasFees[0],
            args.relayer
        );

        (dataToken2) = _transferFundsToVaultWithFeesAndCreateNote(
            uniswapLPData[args.tokenId].token2,
            amount1,
            args.feeNoteFooters[1],
            args.relayerGasFees[1],
            args.relayer
        );

        emit UniswapCollectFees(
            args.tokenId,
            [uniswapLPData[args.tokenId].token1, uniswapLPData[args.tokenId].token2],
            [dataToken1.actualAmount, dataToken2.actualAmount],
            [dataToken1.noteCommitment, dataToken2.noteCommitment],
            args.feeNoteFooters
        );
    }

    /**
     * * HANDLERS (REMOVE LIQUIDITY)
     */

    /**
     * @dev Removes liquidity from Uniswap, handling the return of underlying assets
     *      and the management of related notes.
     * Validates arguments, verifies proof, and executes liquidity removal.
     * @param args Arguments for liquidity removal including the LP token ID, note data, and relayer information.
     * @param proof Cryptographic proof to verify the operation.
     * @return dataToken1 Information about the first token's return
     *         including the amount transferred to the vault and fee details.
     * @return dataToken2 Information about the second token's return
     *         including the amount transferred to the vault and fee details.
     */
    function uniswapRemoveLiquidity(
        UniswapRemoveLiquidityArgs memory args,
        bytes calldata proof
    )
        public
        returns (
            TransferFundsToVaultWithFeesAndCreateNoteData memory dataToken1,
            TransferFundsToVaultWithFeesAndCreateNoteData memory dataToken2
        )
    {
        _validateRemoveLiquidityArgs(args);
        _verifyProofForRemoveLiquidity(args, proof);
        
        _postWithdraw(args.positionNote.nullifier);
        _registerNoteFooter(args.outNoteFooters[0]);
        _registerNoteFooter(args.outNoteFooters[1]);

        _releaseERC721Position(args.positionNote.amount);

        (
            ,
            ,
            address token1,
            address token2,
            ,
            ,
            ,
            uint128 liquidity,
            ,
            ,
            ,

        ) = nonfungiblePositionManager.positions(args.positionNote.amount);

        nonfungiblePositionManager.decreaseLiquidity(
            _prepareRemoveLiquidityParams(args, liquidity)
        );

        (uint256 amount0, uint256 amount1) = nonfungiblePositionManager.collect(
            _prepareCollectFeeParams(args.positionNote.amount)
        );

        _burnERC721Position(args.positionNote.amount);

        (dataToken1) = _transferFundsToVaultWithFeesAndCreateNote(
            token1,
            amount0,
            args.outNoteFooters[0],
            args.relayerGasFees[0],
            args.relayer
        );

        (dataToken2) = _transferFundsToVaultWithFeesAndCreateNote(
            token2,
            amount1,
            args.outNoteFooters[1],
            args.relayerGasFees[1],
            args.relayer
        );

        emit UniswapRemoveLiquidity(
            args.positionNote.amount,
            args.positionNote.nullifier,
            [dataToken1.actualAmount, dataToken2.actualAmount],
            [dataToken1.noteCommitment, dataToken2.noteCommitment],
            args.outNoteFooters
        );
    }

    /**
     * * UTILS (ARGS VALIDATORS)
     */

    /**
     * @dev Validates the arguments for provisioning liquidity. Ensures that the merkle root is allowed,
     * nullifiers are not used, note footers are not used, and the relayer is registered.
     * @param args The arguments for the liquidity provision operation.
     */
    function _validateLiquidityProvisionArgs(
        UniswapLiquidityProvisionArgs memory args
    ) internal view {
        _validateMerkleRootIsAllowed(args.merkleRoot);
        _validateNullifierIsNotUsed(args.noteData1.nullifier);
        _validateNullifierIsNotUsed(args.noteData2.nullifier);
        _validateNullifierIsNotLocked(args.noteData1.nullifier);
        _validateNullifierIsNotLocked(args.noteData2.nullifier);
        _validateNoteFooterIsNotUsed(args.positionNoteFooter);
        _validateNoteFooterIsNotUsed(args.changeNoteFooters[0]);
        _validateNoteFooterIsNotUsed(args.changeNoteFooters[1]);
        _validateRelayerIsRegistered(args.relayer);
        if(msg.sender != args.relayer) {
            revert RelayerMismatch();
        }

        if(args.changeNoteFooters[0] == args.changeNoteFooters[1] ||
            args.positionNoteFooter == args.changeNoteFooters[0] ||
            args.positionNoteFooter == args.changeNoteFooters[1]) {
            revert NoteFooterDuplicated();
        }
    }

    /**
     * @dev Validates the arguments for collecting fees from liquidity. Ensures that the merkle root is allowed,
     * fee note footers have not been used, and the relayer is registered.
     * @param args The arguments for the fee collection operation.
     */
    function _validateCollectFeesArgs(
        UniswapCollectFeesArgs memory args
    ) internal view {
        _validateMerkleRootIsAllowed(args.merkleRoot);
        _validateNoteFooterIsNotUsed(args.feeNoteFooters[0]);
        _validateNoteFooterIsNotUsed(args.feeNoteFooters[1]);
        _validateRelayerIsRegistered(args.relayer);
        if(msg.sender != args.relayer) {
            revert RelayerMismatch();
        }

        if(args.feeNoteFooters[0] == args.feeNoteFooters[1]) {
            revert NoteFooterDuplicated();
        }
    }

    /**
     * @dev Validates the arguments for removing liquidity. Ensures that the merkle root is allowed,
     * the position note nullifier has not been used, out note footers have not been used,
     * and the relayer is registered.
     * @param args The arguments for the liquidity removal operation.
     */
    function _validateRemoveLiquidityArgs(
        UniswapRemoveLiquidityArgs memory args
    ) internal view {
        _validateMerkleRootIsAllowed(args.merkleRoot);
        _validateNullifierIsNotUsed(args.positionNote.nullifier);
        _validateNullifierIsNotLocked(args.positionNote.nullifier);
        _validateNoteFooterIsNotUsed(args.outNoteFooters[0]);
        _validateNoteFooterIsNotUsed(args.outNoteFooters[1]);
        _validateRelayerIsRegistered(args.relayer);
        if(msg.sender != args.relayer) {
            revert RelayerMismatch();
        }

        if (args.outNoteFooters[0] == args.outNoteFooters[1]) {
            revert NoteFooterDuplicated();
        }
    }

    /**
     * * UTILS (PROOF VERIFIERS)
     */

    /**
     * @dev Verifies the proof for liquidity provision operation. This function is intended to integrate with
     * a zero-knowledge proof system to validate the operation's integrity and authorization.
     * @param args The arguments for the liquidity provision operation, used to construct the proof's inputs.
     * @param proof The cryptographic proof associated with the liquidity provision operation.
     */
    function _verifyProofForLiquidityProvision(
        UniswapLiquidityProvisionArgs memory args,
        bytes calldata proof
    ) internal view {
        UniswapLiquidityProvisionInputs memory inputs;

        inputs.merkleRoot = args.merkleRoot;
        inputs.asset1Address = args.noteData1.assetAddress;
        inputs.asset2Address = args.noteData2.assetAddress;
        inputs.amount1 = args.noteData1.amount;
        inputs.amount2 = args.noteData2.amount;
        inputs.nullifier1 = args.noteData1.nullifier;
        inputs.nullifier2 = args.noteData2.nullifier;
        inputs.noteFooter = args.positionNoteFooter;
        inputs.tickMin = args.tickMin;
        inputs.tickMax = args.tickMax;
        inputs.changeNoteFooter1 = args.changeNoteFooters[0];
        inputs.changeNoteFooter2 = args.changeNoteFooters[1];
        inputs.relayer = args.relayer;
        inputs.amount1Min = args.amountsMin[0];
        inputs.amount2Min = args.amountsMin[1];
        inputs.poolFee = args.poolFee;
        inputs.deadline = args.deadline;

        _verifyProof(
            proof,
            _buildUniswapLiquidityProvisionInputs(inputs),
            "uniswapLiquidityProvision"
        );
    }

    /**
     * @dev Verifies the proof for fee collection from liquidity. This function is intended to integrate with
     * a zero-knowledge proof system to validate the operation's integrity and authorization.
     * @param args The arguments for the fee collection operation, used to construct the proof's inputs.
     * @param proof The cryptographic proof associated with the fee collection operation.
     */
    function _verifyProofForCollectFees(
        UniswapCollectFeesArgs memory args,
        bytes calldata proof
    ) internal view {
        UniswapCollectFeesInputs memory inputs;

        inputs.merkleRoot = args.merkleRoot;
        inputs.positionAddress = address(nonfungiblePositionManager);
        inputs.tokenId = args.tokenId;
        inputs.fee1NoteFooter = args.feeNoteFooters[0];
        inputs.fee2NoteFooter = args.feeNoteFooters[1];
        inputs.relayer = args.relayer;

        _verifyProof(
            proof,
            _buildUniswapCollectFeesInputs(inputs),
            "uniswapCollectFees"
        );
    }

    /**
     * @dev Verifies the proof for liquidity removal operation. This function is intended to integrate with
     * a zero-knowledge proof system to validate the operation's integrity and authorization.
     * @param args The arguments for the liquidity removal operation, used to construct the proof's inputs.
     * @param proof The cryptographic proof associated with the liquidity removal operation.
     */
    function _verifyProofForRemoveLiquidity(
        UniswapRemoveLiquidityArgs memory args,
        bytes calldata proof
    ) internal view {
        UniswapRemoveLiquidityInputs memory inputs;

        inputs.merkleRoot = args.merkleRoot;
        inputs.positionAddress = address(nonfungiblePositionManager);
        inputs.positionNullifier = args.positionNote.nullifier;
        inputs.tokenId = args.positionNote.amount;
        inputs.out1NoteFooter = args.outNoteFooters[0];
        inputs.out2NoteFooter = args.outNoteFooters[1];
        inputs.deadline = args.deadline;
        inputs.relayer = args.relayer;
        inputs.amount1Min = args.amountsMin[0];
        inputs.amount2Min = args.amountsMin[1];

        _verifyProof(
            proof,
            _buildUniswapRemoveLiquidityInputs(inputs),
            "uniswapRemoveLiquidity"
        );
    }

    /**
     * * UTILS (LP)
     */

    /**
     * @dev Executes the minting of a Uniswap LP token as part of the liquidity provision process. 
     *      This involves interacting with the Uniswap contract, handling asset transfers, and creating necessary notes.
     * @param args Arguments for the liquidity provision, including details about the assets and pool parameters.
     * @param mintParams Parameters prepared for minting the LP token, derived from the provided arguments.
     * @param originalIndices The original indices of the tokens used in the liquidity provision.
     * @return changeNoteCommitments Commitments for any change notes created as a result of the minting process.
     * @return changeAmounts Amounts of assets not used in the minting and returned as change.
     * @return positionNote The note representing the newly created LP token position.
     * @return tokenId The ID of the minted LP token.
     */
    function _executeLPMint(
        UniswapLiquidityProvisionArgs memory args,
        INonfungiblePositionManager.MintParams memory mintParams,
        uint8[2] memory originalIndices
    )
        internal
        returns (
            bytes32[2] memory changeNoteCommitments,
            uint256[2] memory changeAmounts,
            bytes32 positionNote,
            uint256 tokenId
        )
    {
        uint256 mintedAmount0;
        uint256 mintedAmount1;

        _registerNoteFooter(args.positionNoteFooter);
        _registerNoteFooter(args.changeNoteFooters[0]);
        _registerNoteFooter(args.changeNoteFooters[1]);

        (tokenId, , mintedAmount0, mintedAmount1) = nonfungiblePositionManager
            .mint(mintParams);

        (changeNoteCommitments, changeAmounts) = _handleChangeAfterUniswapLp(
            mintParams,
            [mintedAmount0, mintedAmount1],
            args.changeNoteFooters,
            originalIndices
        );

        uniswapLPData[tokenId] = UniswapLPData({
            token1: mintParams.token0,
            token2: mintParams.token1
        });

        positionNote = _buildNoteForERC721(
            address(nonfungiblePositionManager),
            tokenId,
            args.positionNoteFooter
        );

        _transferERC721PositionToVault(tokenId);

        _postDeposit(positionNote);

        if (changeAmounts[0] > 0) {
            _postDeposit(changeNoteCommitments[0]);
        }

        if (changeAmounts[1] > 0) {
            _postDeposit(bytes32(changeNoteCommitments[1]));
        }
    }

    /**
     * * UTILS (CHANGE)
     */

    /**
     * @dev Handles any change returned after the Uniswap LP minting process. 
     *      This involves creating notes for the change amounts and transferring assets back to the vault if necessary.
     * @param mintParams The minting parameters including the desired amounts of assets for the liquidity provision.
     * @param actuallyMintedAmounts The actual amounts of assets used in the minting process.
     * @param noteFooters Footers for the notes representing the change amounts.
     * @param originalIndices The original indices of the tokens used in the liquidity provision.
     * @return changeNoteCommitments Commitments for the change notes created for any unutilized asset amounts.
     * @return changeAmounts The amounts of each asset not used in the minting and returned as change.
     */
    function _handleChangeAfterUniswapLp(
        INonfungiblePositionManager.MintParams memory mintParams,
        uint256[2] memory actuallyMintedAmounts,
        bytes32[2] memory noteFooters,
        uint8[2] memory originalIndices
    )
        internal
        returns (
            bytes32[2] memory changeNoteCommitments,
            uint256[2] memory changeAmounts
        )
    {
        changeAmounts = [
            mintParams.amount0Desired - actuallyMintedAmounts[0],
            mintParams.amount1Desired - actuallyMintedAmounts[1]
        ];

        //_registerNoteFooter(noteFooters[0]);
        //_registerNoteFooter(noteFooters[1]);

        address normalizedToken0 = _convertToEthIfNecessary(mintParams.token0, changeAmounts[0]);
        address normalizedToken1 = _convertToEthIfNecessary(mintParams.token1, changeAmounts[1]);

        _transferAssetToVault(normalizedToken0, changeAmounts[0]);
        _transferAssetToVault(normalizedToken1, changeAmounts[1]);

        if (changeAmounts[0] > 0) {
            changeNoteCommitments[0] = _buildNoteForERC20(
                normalizedToken0,
                changeAmounts[0],
                noteFooters[originalIndices[0]]
            );
        }

        if (changeAmounts[1] > 0) {
            changeNoteCommitments[1] = _buildNoteForERC20(
                normalizedToken1,
                changeAmounts[1],
                noteFooters[originalIndices[1]]
            );
        }
    }

    /**
     * * UTILS (ARGS PREPARERS)
     */

    /**
     * @dev Prepares the arguments for the liquidity provision operation,
     *      including releasing funds and setting up the mint parameters.
     * @param args The liquidity provision arguments, detailing the operation's specifics.
     * @return mintParams The parameters required for minting the LP token.
     * @return originalIndices The original indices of the tokens used in the liquidity provision.
     */
    function _releaseFundsAndPrepareLiquidityProvisionArgs(
        UniswapLiquidityProvisionArgs memory args
    )
        internal
        returns (
            INonfungiblePositionManager.MintParams memory mintParams,
            //FeesDetails memory feesDetails,
            uint8[2] memory originalIndices
        )
    {
        _postWithdraw(bytes32(args.noteData1.nullifier));
        _postWithdraw(bytes32(args.noteData2.nullifier));

        /**
         * * Release funds for token 1
         */

        FundReleaseDetails memory fundReleaseDetails1;

        fundReleaseDetails1.assetAddress = args.noteData1.assetAddress;
        fundReleaseDetails1.recipient = payable(address(this));
        fundReleaseDetails1.relayer = args.relayer;
        fundReleaseDetails1.relayerGasFee = args.relayerGasFees[0];
        fundReleaseDetails1.amount = args.noteData1.amount;
        

        (
            uint256 actualReleasedAmountToken1,
            //FeesDetails memory feesDetails1
        ) = _releaseAndPackDetails(fundReleaseDetails1);

        /**
         * * Release funds for token 2
         */

        FundReleaseDetails memory fundReleaseDetails2;

        fundReleaseDetails2.assetAddress = args.noteData2.assetAddress;
        fundReleaseDetails2.recipient = payable(address(this));
        fundReleaseDetails2.relayer = args.relayer;
        fundReleaseDetails2.relayerGasFee = args.relayerGasFees[1];
        fundReleaseDetails2.amount = args.noteData2.amount;


        (
            uint256 actualReleasedAmountToken2,
            //FeesDetails memory feesDetails2
        ) = _releaseAndPackDetails(fundReleaseDetails2);

        /**
         * * Post release setup
         */

        //feesDetails.serviceFee =
        //    feesDetails1.serviceFee +
        //    feesDetails2.serviceFee;

        //feesDetails.relayerRefund =
        //    args.relayerGasFees[0] +
        //    args.relayerGasFees[1];

        address[2] memory tokens;
        uint256[2] memory amounts;

        (
            tokens,
            amounts,
            originalIndices
        ) = _sortAndConvertToWeth(
                [args.noteData1.assetAddress, args.noteData2.assetAddress],
                [actualReleasedAmountToken1, actualReleasedAmountToken2]
            );

        /**
         * * Prepare mint parameters
         */

        mintParams.token0 = tokens[0];
        mintParams.token1 = tokens[1];

        mintParams.fee = args.poolFee;
        mintParams.tickLower = args.tickMin;
        mintParams.tickUpper = args.tickMax;
        mintParams.amount0Desired = amounts[0];
        mintParams.amount1Desired = amounts[1];
        mintParams.amount0Min = args.amountsMin[originalIndices[0]];
        mintParams.amount1Min = args.amountsMin[originalIndices[1]];
        mintParams.recipient = payable(address(this));
        mintParams.deadline = args.deadline;

        IERC20(mintParams.token0).forceApprove(
            address(nonfungiblePositionManager),
            mintParams.amount0Desired
        );
        IERC20(mintParams.token1).forceApprove(
            address(nonfungiblePositionManager),
            mintParams.amount1Desired
        );
    }

    /**
     * @dev Prepares the parameters required for collecting fees from the non-fungible position manager.
     * @param tokenId The ID of the LP token from which fees are to be collected.
     * @return collectParams The parameters required for the collect operation.
     */
    function _prepareCollectFeeParams(
        uint256 tokenId
    )
        internal
        view
        returns (INonfungiblePositionManager.CollectParams memory collectParams)
    {
        collectParams.tokenId = tokenId;
        collectParams.recipient = address(this);
        collectParams.amount0Max = type(uint128).max;
        collectParams.amount1Max = type(uint128).max;
    }

    /**
     * @dev Prepares the parameters required for removing liquidity via the non-fungible position manager.
     * @param args The arguments detailing the liquidity removal operation.
     * @param liquidity The liquidity amount to remove.
     * @return decreaseLiquidityParams The parameters required for the decrease liquidity operation.
     */
    function _prepareRemoveLiquidityParams(
        UniswapRemoveLiquidityArgs memory args,
        uint128 liquidity
    )
        internal
        view
        returns (
            INonfungiblePositionManager.DecreaseLiquidityParams
                memory decreaseLiquidityParams
        )
    {
        decreaseLiquidityParams.tokenId = args.positionNote.amount;
        decreaseLiquidityParams.liquidity = liquidity;
        decreaseLiquidityParams.amount0Min = args.amountsMin[0];
        decreaseLiquidityParams.amount1Min = args.amountsMin[1];
        decreaseLiquidityParams.deadline = args.deadline;
    }

    /**
     * * UTILS (RELEASE ERC721 POSITION RELATED)
     */

    /**
     * @dev Releases an ERC721 token (LP token) from the asset pool to this contract.
     * @param tokenId The ID of the LP token to release.
     */
    function _releaseERC721Position(uint256 tokenId) internal {
        _assetPoolERC721.release(
            address(nonfungiblePositionManager),
            address(this),
            tokenId
        );
    }

    /**
     * * UTILS (TRANSFER ERC721 POSITION RELATED)
     */

    /**
     * @dev Transfers an ERC721 token (LP token) from this contract to the asset vault.
     * @param tokenId The ID of the LP token to transfer.
     */
    function _transferERC721PositionToVault(uint256 tokenId) internal {
        IERC721(address(nonfungiblePositionManager)).safeTransferFrom(
            address(this),
            address(_assetPoolERC721),
            tokenId
        );
    }

    /**
 * @dev Burns position token after it is used.
     * @param tokenId The ID of the LP token to burn.
     */
    function _burnERC721Position(uint256 tokenId) internal {
        nonfungiblePositionManager.burn(tokenId);
    }

    /**
     * @dev Callback function to receive ERC721 tokens.
     * This function is called when the LP token is transferred to this contract.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import "./IPoolInitializer.sol";
import "./IERC721Permit.sol";
import "./IPeripheryPayments.sol";
import "./IPeripheryImmutableState.sol";
import "../libraries/PoolAddress.sol";

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(
        uint256 indexed tokenId,
        uint128 liquidity,
        uint256 amount0,
        uint256 amount1
    );
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(
        uint256 indexed tokenId,
        address recipient,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(
        MintParams calldata params
    )
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    )
        external
        payable
        returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        CollectParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(
        uint256 amountMinimum,
        address recipient
    ) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint)
    /// performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee,
    /// will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH =
        //0xa598dd2fba360510c5a8f02f44423a4468e902df5857dbce3ca162a43a3a31ff;
        0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
        
    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(
        address factory,
        PoolKey memory key
    ) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(
                                abi.encode(key.token0, key.token1, key.fee)
                            ),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}