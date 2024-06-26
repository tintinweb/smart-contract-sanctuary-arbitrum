// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/draft-IERC6093.sol)
pragma solidity ^0.8.20;

/**
 * @dev Standard ERC20 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC20 tokens.
 */
interface IERC20Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC20InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC20InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `spender`’s `allowance`. Used in transfers.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     * @param allowance Amount of tokens a `spender` is allowed to operate with.
     * @param needed Minimum amount required to perform a transfer.
     */
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC20InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `spender` to be approved. Used in approvals.
     * @param spender Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC20InvalidSpender(address spender);
}

/**
 * @dev Standard ERC721 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC721 tokens.
 */
interface IERC721Errors {
    /**
     * @dev Indicates that an address can't be an owner. For example, `address(0)` is a forbidden owner in EIP-20.
     * Used in balance queries.
     * @param owner Address of the current owner of a token.
     */
    error ERC721InvalidOwner(address owner);

    /**
     * @dev Indicates a `tokenId` whose `owner` is the zero address.
     * @param tokenId Identifier number of a token.
     */
    error ERC721NonexistentToken(uint256 tokenId);

    /**
     * @dev Indicates an error related to the ownership over a particular token. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param tokenId Identifier number of a token.
     * @param owner Address of the current owner of a token.
     */
    error ERC721IncorrectOwner(address sender, uint256 tokenId, address owner);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC721InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC721InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param tokenId Identifier number of a token.
     */
    error ERC721InsufficientApproval(address operator, uint256 tokenId);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC721InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC721InvalidOperator(address operator);
}

/**
 * @dev Standard ERC1155 Errors
 * Interface of the https://eips.ethereum.org/EIPS/eip-6093[ERC-6093] custom errors for ERC1155 tokens.
 */
interface IERC1155Errors {
    /**
     * @dev Indicates an error related to the current `balance` of a `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     * @param balance Current balance for the interacting account.
     * @param needed Minimum amount required to perform a transfer.
     * @param tokenId Identifier number of a token.
     */
    error ERC1155InsufficientBalance(address sender, uint256 balance, uint256 needed, uint256 tokenId);

    /**
     * @dev Indicates a failure with the token `sender`. Used in transfers.
     * @param sender Address whose tokens are being transferred.
     */
    error ERC1155InvalidSender(address sender);

    /**
     * @dev Indicates a failure with the token `receiver`. Used in transfers.
     * @param receiver Address to which tokens are being transferred.
     */
    error ERC1155InvalidReceiver(address receiver);

    /**
     * @dev Indicates a failure with the `operator`’s approval. Used in transfers.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     * @param owner Address of the current owner of a token.
     */
    error ERC1155MissingApprovalForAll(address operator, address owner);

    /**
     * @dev Indicates a failure with the `approver` of a token to be approved. Used in approvals.
     * @param approver Address initiating an approval operation.
     */
    error ERC1155InvalidApprover(address approver);

    /**
     * @dev Indicates a failure with the `operator` to be approved. Used in approvals.
     * @param operator Address that may be allowed to operate on tokens without being their owner.
     */
    error ERC1155InvalidOperator(address operator);

    /**
     * @dev Indicates an array length mismatch between ids and values in a safeBatchTransferFrom operation.
     * Used in batch transfers.
     * @param idsLength Length of the array of token identifiers
     * @param valuesLength Length of the array of token amounts
     */
    error ERC1155InvalidArrayLength(uint256 idsLength, uint256 valuesLength);
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.20;

import {IERC721} from "./IERC721.sol";
import {IERC721Receiver} from "./IERC721Receiver.sol";
import {IERC721Metadata} from "./extensions/IERC721Metadata.sol";
import {Context} from "../../utils/Context.sol";
import {Strings} from "../../utils/Strings.sol";
import {IERC165, ERC165} from "../../utils/introspection/ERC165.sol";
import {IERC721Errors} from "../../interfaces/draft-IERC6093.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Errors {
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    mapping(uint256 tokenId => address) private _owners;

    mapping(address owner => uint256) private _balances;

    mapping(uint256 tokenId => address) private _tokenApprovals;

    mapping(address owner => mapping(address operator => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        if (owner == address(0)) {
            revert ERC721InvalidOwner(address(0));
        }
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _requireOwned(tokenId);
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        _requireOwned(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string.concat(baseURI, tokenId.toString()) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual {
        _approve(to, tokenId, _msgSender());
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        _requireOwned(tokenId);

        return _getApproved(tokenId);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        // Setting an "auth" arguments enables the `_isAuthorized` check which verifies that the token exists
        // (from != 0). Therefore, it is not needed to verify that the return value is not 0 here.
        address previousOwner = _update(to, tokenId, _msgSender());
        if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        transferFrom(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     *
     * IMPORTANT: Any overrides to this function that add ownership of tokens not tracked by the
     * core ERC721 logic MUST be matched with the use of {_increaseBalance} to keep balances
     * consistent with ownership. The invariant to preserve is that for any address `a` the value returned by
     * `balanceOf(a)` must be equal to the number of tokens such that `_ownerOf(tokenId)` is `a`.
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns the approved address for `tokenId`. Returns 0 if `tokenId` is not minted.
     */
    function _getApproved(uint256 tokenId) internal view virtual returns (address) {
        return _tokenApprovals[tokenId];
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `owner`'s tokens, or `tokenId` in
     * particular (ignoring whether it is owned by `owner`).
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _isAuthorized(address owner, address spender, uint256 tokenId) internal view virtual returns (bool) {
        return
            spender != address(0) &&
            (owner == spender || isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
    }

    /**
     * @dev Checks if `spender` can operate on `tokenId`, assuming the provided `owner` is the actual owner.
     * Reverts if `spender` does not have approval from the provided `owner` for the given token or for all its assets
     * the `spender` for the specific `tokenId`.
     *
     * WARNING: This function assumes that `owner` is the actual owner of `tokenId` and does not verify this
     * assumption.
     */
    function _checkAuthorized(address owner, address spender, uint256 tokenId) internal view virtual {
        if (!_isAuthorized(owner, spender, tokenId)) {
            if (owner == address(0)) {
                revert ERC721NonexistentToken(tokenId);
            } else {
                revert ERC721InsufficientApproval(spender, tokenId);
            }
        }
    }

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * NOTE: the value is limited to type(uint128).max. This protect against _balance overflow. It is unrealistic that
     * a uint256 would ever overflow from increments when these increments are bounded to uint128 values.
     *
     * WARNING: Increasing an account's balance using this function tends to be paired with an override of the
     * {_ownerOf} function to resolve the ownership of the corresponding tokens so that balances and ownership
     * remain consistent with one another.
     */
    function _increaseBalance(address account, uint128 value) internal virtual {
        unchecked {
            _balances[account] += value;
        }
    }

    /**
     * @dev Transfers `tokenId` from its current owner to `to`, or alternatively mints (or burns) if the current owner
     * (or `to`) is the zero address. Returns the owner of the `tokenId` before the update.
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that
     * `auth` is either the owner of the token, or approved to operate on the token (by the owner).
     *
     * Emits a {Transfer} event.
     *
     * NOTE: If overriding this function in a way that tracks balances, see also {_increaseBalance}.
     */
    function _update(address to, uint256 tokenId, address auth) internal virtual returns (address) {
        address from = _ownerOf(tokenId);

        // Perform (optional) operator check
        if (auth != address(0)) {
            _checkAuthorized(from, auth, tokenId);
        }

        // Execute the update
        if (from != address(0)) {
            // Clear approval. No need to re-authorize or emit the Approval event
            _approve(address(0), tokenId, address(0), false);

            unchecked {
                _balances[from] -= 1;
            }
        }

        if (to != address(0)) {
            unchecked {
                _balances[to] += 1;
            }
        }

        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        return from;
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal {
        
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));

        if (previousOwner != address(0)) {
            revert ERC721InvalidSender(address(0));
        }
    }

    /**
     * @dev Mints `tokenId`, transfers it to `to` and checks for `to` acceptance.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        _checkOnERC721Received(address(0), to, tokenId, data);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal {
        address previousOwner = _update(address(0), tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal {
        if (to == address(0)) {
            revert ERC721InvalidReceiver(address(0));
        }
        address previousOwner = _update(to, tokenId, address(0));
        if (previousOwner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        } else if (previousOwner != from) {
            revert ERC721IncorrectOwner(from, tokenId, previousOwner);
        }
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking that contract recipients
     * are aware of the ERC721 standard to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is like {safeTransferFrom} in the sense that it invokes
     * {IERC721Receiver-onERC721Received} on the receiver, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `tokenId` token must exist and be owned by `from`.
     * - `to` cannot be the zero address.
     * - `from` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId) internal {
        _safeTransfer(from, to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeTransfer-address-address-uint256-}[`_safeTransfer`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        _checkOnERC721Received(from, to, tokenId, data);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that `auth` is
     * either the owner of the token, or approved to operate on all tokens held by this owner.
     *
     * Emits an {Approval} event.
     *
     * Overrides to this logic should be done to the variant with an additional `bool emitEvent` argument.
     */
    function _approve(address to, uint256 tokenId, address auth) internal {
        _approve(to, tokenId, auth, true);
    }

    /**
     * @dev Variant of `_approve` with an optional flag to enable or disable the {Approval} event. The event is not
     * emitted in the context of transfers.
     */
    function _approve(address to, uint256 tokenId, address auth, bool emitEvent) internal virtual {
        // Avoid reading the owner unless necessary
        if (emitEvent || auth != address(0)) {
            address owner = _requireOwned(tokenId);

            // We do not use _isAuthorized because single-token approvals should not be able to call approve
            if (auth != address(0) && owner != auth && !isApprovedForAll(owner, auth)) {
                revert ERC721InvalidApprover(auth);
            }

            if (emitEvent) {
                emit Approval(owner, to, tokenId);
            }
        }

        _tokenApprovals[tokenId] = to;
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Requirements:
     * - operator can't be the address zero.
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        if (operator == address(0)) {
            revert ERC721InvalidOperator(operator);
        }
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` doesn't have a current owner (it hasn't been minted, or it has been burned).
     * Returns the owner.
     *
     * Overrides to ownership logic should be done to {_ownerOf}.
     */
    function _requireOwned(uint256 tokenId) internal view returns (address) {
        address owner = _ownerOf(tokenId);
        if (owner == address(0)) {
            revert ERC721NonexistentToken(tokenId);
        }
        return owner;
    }

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target address. This will revert if the
     * recipient doesn't accept the token transfer. The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data) private {
        if (to.code.length > 0) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                if (retval != IERC721Receiver.onERC721Received.selector) {
                    revert ERC721InvalidReceiver(to);
                }
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721InvalidReceiver(to);
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.20;

import {ERC721} from "../ERC721.sol";
import {IERC721Enumerable} from "./IERC721Enumerable.sol";
import {IERC165} from "../../../utils/introspection/ERC165.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds enumerability
 * of all the token ids in the contract as well as all token ids owned by each account.
 *
 * CAUTION: `ERC721` extensions that implement custom `balanceOf` logic, such as `ERC721Consecutive`,
 * interfere with enumerability and should not be used together with `ERC721Enumerable`.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    mapping(address owner => mapping(uint256 index => uint256)) private _ownedTokens;
    mapping(uint256 tokenId => uint256) private _ownedTokensIndex;

    uint256[] private _allTokens;
    mapping(uint256 tokenId => uint256) private _allTokensIndex;

    /**
     * @dev An `owner`'s token query was out of bounds for `index`.
     *
     * NOTE: The owner being `address(0)` indicates a global out of bounds index.
     */
    error ERC721OutOfBoundsIndex(address owner, uint256 index);

    /**
     * @dev Batch mint is not allowed.
     */
    error ERC721EnumerableForbiddenBatchMint();

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
        if (index >= balanceOf(owner)) {
            revert ERC721OutOfBoundsIndex(owner, index);
        }
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual returns (uint256) {
        if (index >= totalSupply()) {
            revert ERC721OutOfBoundsIndex(address(0), index);
        }
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_update}.
     */
    function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
        address previousOwner = super._update(to, tokenId, auth);

        if (previousOwner == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (previousOwner != to) {
            _removeTokenFromOwnerEnumeration(previousOwner, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (previousOwner != to) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }

        return previousOwner;
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = balanceOf(to) - 1;
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = balanceOf(from);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * See {ERC721-_increaseBalance}. We need that to account tokens that were minted in batch
     */
    function _increaseBalance(address account, uint128 amount) internal virtual override {
        if (amount > 0) {
            revert ERC721EnumerableForbiddenBatchMint();
        }
        super._increaseBalance(account, amount);
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/introspection/ERC165.sol)

pragma solidity ^0.8.20;

import {IERC165} from "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.20;

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
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;

    uint256 private _status;

    /**
     * @dev Unauthorized reentrant call.
     */
    error ReentrancyGuardReentrantCall();

    constructor() {
        _status = NOT_ENTERED;
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
        // On the first call to nonReentrant, _status will be NOT_ENTERED
        if (_status == ENTERED) {
            revert ReentrancyGuardReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;

import {Math} from "./math/Math.sol";
import {SignedMath} from "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import './PlanDelegator.sol';

abstract contract ERC721Delegate is PlanDelegator {
  event TokenDelegated(uint256 indexed tokenId, address indexed delegate);
  event DelegateRemoved(uint256 indexed tokenId, address indexed delegate);

  function _delegateToken(address delegate, uint256 tokenId) internal {
    require(_isApprovedDelegatorOrOwner(msg.sender, tokenId), '!delegator');
    _transferDelegate(delegate, tokenId);
  }

  // function for minting should add the token to the delegate and increase the balance
  function _addDelegate(address to, uint256 tokenId) private {
    require(to != address(0), '!address(0)');
    uint256 length = _delegateBalances[to];
    _delegatedTokens[to][length] = tokenId;
    _delegatedTokensIndex[tokenId] = length;
    _delegates[tokenId] = to;
    _delegateBalances[to] += 1;
    emit TokenDelegated(tokenId, to);
  }

  // function for burning should reduce the balances and set the token mapped to 0x0 address
  function _removeDelegate(uint256 tokenId) private {
    address from = _delegates[tokenId];
    require(from != address(0), '!address(0)');
    uint256 lastTokenIndex = _delegateBalances[from] - 1;
    uint256 tokenIndex = _delegatedTokensIndex[tokenId];
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _delegatedTokens[from][lastTokenIndex];
      _delegatedTokens[from][tokenIndex] = lastTokenId;
      _delegatedTokensIndex[lastTokenId] = tokenIndex;
    }
    delete _delegatedTokensIndex[tokenId];
    delete _delegatedTokens[from][lastTokenIndex];
    _delegateBalances[from] -= 1;
    _delegates[tokenId] = address(0);
    emit DelegateRemoved(tokenId, from);
  }

  // function for transfering should reduce the balances of from by 1, increase the balances of to by 1, and set the delegate address To
  function _transferDelegate(address to, uint256 tokenId) internal {
    _removeDelegate(tokenId);
    _addDelegate(to, tokenId);
  }

  //mapping from tokenId to the delegate address
  mapping(uint256 => address) private _delegates;

  // mapping from delegate address to token count
  mapping(address => uint256) private _delegateBalances;

  // mapping from delegate to the list of delegated token Ids
  mapping(address => mapping(uint256 => uint256)) private _delegatedTokens;

  // maping from token ID to the index of the delegates token list
  mapping(uint256 => uint256) private _delegatedTokensIndex;

  function balanceOfDelegate(address delegate) public view returns (uint256) {
    require(delegate != address(0), '!address(0)');
    return _delegateBalances[delegate];
  }

  function delegatedTo(uint256 tokenId) public view returns (address) {
    address delegate = _delegates[tokenId];
    return delegate;
  }

  function tokenOfDelegateByIndex(address delegate, uint256 index) public view returns (uint256) {
    require(index < _delegateBalances[delegate], 'out of bounds');
    return _delegatedTokens[delegate][index];
  }

  function _updateDelegate(address to, uint256 tokenId) internal {
    if (_ownerOf(tokenId) == address(0x0)) {
      _addDelegate(to, tokenId);
    } else if (to == address(0x0)) {
      _removeDelegate(tokenId);
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

abstract contract PlanDelegator is ERC721Enumerable {
  // mapping of tokenId to address who can delegate an NFT on behalf of the owner
  /// @dev follows tokenApprovals logic

  /******Storage Variables******************************************************************/
  mapping(uint256 => address) internal _approvedDelegators;

  /// @dev operatorApprovals simialr to ERC721 standards
  mapping(address => mapping(address => bool)) internal _approvedOperatorDelegators;


  /***EVENTS******************************************************************************/

  /// @dev event that is emitted when a single plan delegator has been approved
  event DelegatorApproved(uint256 indexed id, address owner, address delegator);

  /// @dev event emit when the operator delegator has been approved to manage all delegation of a single address
  event ApprovalForAllDelegation(address owner, address operator, bool approved);


  /***************EXTERNAL FUNCTIONS***************************************************************************/

  /// @notice function to assign a single planId to a delegator. The delegator then has authority to call functions on other contracts such as delegate
  /// @param delegator is the address of the delegator who can delegate on behalf of the nft owner
  /// @param planId is the id of the vesting or lockup plan
  function approveDelegator(address delegator, uint256 planId) public virtual {
    address owner = ownerOf(planId);
    require(msg.sender == owner || isApprovedForAllDelegation(owner, msg.sender), '!ownerOperator');
    require(delegator != msg.sender, '!self approval');
    _approveDelegator(delegator, planId);
  }

  /// @notice function that performs both the approveDelegator function and approves a spender
  /// @param spender is the address who is approved to spend and is also a Delegator
  /// @param planId is the vesting plan id
  function approveSpenderDelegator(address spender, uint256 planId) public virtual {
    address owner = ownerOf(planId);
    require(
      msg.sender == owner || (isApprovedForAllDelegation(owner, msg.sender) && isApprovedForAll(owner, msg.sender)),
      '!ownerOperator'
    );
    require(spender != msg.sender, '!self approval');
    _approveDelegator(spender, planId);
    _approve(spender, planId, msg.sender);
  }

  /// @notice this function sets an address to be an operator delegator for the msg.sender, whereby the operator can delegate all tokens owned by the msg.sender
  /// the operator can also approve other single plan delegators
  /// @param operator address of the operator for the msg.sender
  /// @param approved boolean for approved if true, and false if not
  function setApprovalForAllDelegation(address operator, bool approved) public virtual {
    _setApprovalForAllDelegation(msg.sender, operator, approved);
  }

  /// @notice functeion to set the approval operator for both delegation and for spending NFTs of the msg.sender
  /// @param operator is the address who will be allowed to spend and delegate
  /// @param approved is the bool determining if they are allowed or not
  function setApprovalForOperator(address operator, bool approved) public virtual {
    _setApprovalForAllDelegation(msg.sender, operator, approved);
    _setApprovalForAll(msg.sender, operator, approved);
  }

  /****INTERNAL FUNCTIONS**************************************************************************************/

  /// @notice internal function to update the storage of approvedDelegators and emit the event
  function _approveDelegator(address delegator, uint256 planId) internal virtual {
    _approvedDelegators[planId] = delegator;
    emit DelegatorApproved(planId, ownerOf(planId), delegator);
  }

  /// @notice internal function to update the storage of approvedOperatorDelegators, and emit the event
  function _setApprovalForAllDelegation(address owner, address operator, bool approved) internal virtual {
    require(owner != operator, '!operator');
    _approvedOperatorDelegators[owner][operator] = approved;
    emit ApprovalForAllDelegation(owner, operator, approved);
  }

  /// @notice internal view function to determine if a delegator, typically the msg.sender is allowed to delegate a token, based on being either the Owner, Delegator or Operator.
  function _isApprovedDelegatorOrOwner(address delegator, uint256 planId) internal view returns (bool) {
    address owner = ownerOf(planId);
    return (delegator == owner ||
      isApprovedForAllDelegation(owner, delegator) ||
      getApprovedDelegator(planId) == delegator);
  }

  /***********************PUBLIC VIEW FUNCTIONS***********************************************************/

  /// @notice function to get the approved delegator of a single planId
  function getApprovedDelegator(uint256 planId) public view returns (address) {
    return _approvedDelegators[planId];
  }

  /// @notice function to evaluate if an operator is approved to manage delegations of an owner address
  function isApprovedForAllDelegation(address owner, address operator) public view returns (bool) {
    return _approvedOperatorDelegators[owner][operator];
  }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

interface IVesting {
  struct Plan {
    address token;
    uint256 amount;
    uint256 start;
    uint256 cliff;
    uint256 rate;
    uint256 period;
    address vestingAdmin;
    bool adminTransferOBO;
  }

  function plans(uint256 planId) external view returns (Plan memory);

  function redeemPlans(uint256[] calldata planIds) external;

  function delegate(uint256 planId, address delegatee) external;

  function delegatePlans(uint256[] calldata planIds, address[] calldata delegatees) external;

  function setupVoting(uint256 planId) external returns (address votingVault);

  function toggleAdminTransferOBO(uint256 planId, bool adminTransferOBO) external;

  function ownerOf(uint256 planId) external view returns (address owner);

  function planBalanceOf(
    uint256 planId,
    uint256 timeStamp,
    uint256 redemptionTime
  ) external view returns (uint256 balance, uint256 remainder, uint256 latestUnlock);

  function planEnd(uint256 planId) external view returns (uint256 end);
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

library UnlockLibrary {

  /// @notice function to calculate the end date of a plan based on its start, amount, rate and period
  function endDate(uint256 start, uint256 amount, uint256 rate, uint256 period) internal pure returns (uint256 end) {
    end = (amount % rate == 0) ? (amount / rate) * period + start : ((amount / rate) * period) + period + start;
  }

  /// @notice function to validate the end date of a vesting lock
  /// @param start is the start date of the lockup
  /// @param cliff is the cliff date of the lockup
  /// @param amount is the total amount of tokens in the lockup, which would be the entire amount of the vesting plan
  /// @param rate is the amount of tokens that unlock per period
  /// @param period is the seconds in each period, a 1 is a period of 1 second whereby tokens unlock every second
  /// @param vestingEnd is the end date of the vesting plan
  /// @dev this function validates the lockup end date against 0 entry values, plus ensures that the cliff date is at least the same as the end date
  /// and finally it chekcs that if the lock isn't a single date unlock, that the end date is beyond the vesting end date
  function validateEnd(
    uint256 start,
    uint256 cliff,
    uint256 amount,
    uint256 rate,
    uint256 period,
    uint256 vestingEnd
  ) internal pure returns (uint256 end) {
    require(amount > 0, '0_amount');
    require(rate > 0, '0_rate');
    require(rate <= amount, 'rate > amount');
    require(period > 0, '0_period');
    end = endDate(start, amount, rate, period);
    require(cliff <= end, 'cliff > end');
    if (rate < amount) {
      require(end >= vestingEnd, 'end error');
    }
  }

  /// @notice function to calculate the unlocked (claimable) balance, still locked balance, and the most recent timestamp the unlock would take place
  /// the most recent unlock time is based on the periods, so if the periods are 1, then the unlock time will be the same as the redemption time,
  /// however if the period more than 1 second, the latest unlock will be a discrete time stamp
  /// @param start is the start time of the plan
  /// @param cliffDate is the timestamp of the cliff of the plan
  /// @param totalAmount is the total amount of tokens in the vesting plan
  /// @param availableAmount is the total unclaimed amount tokens still in the vesting plan
  /// @param rate is the amount of tokens that unlock per period
  /// @param period is the seconds in each period, a 1 is a period of 1 second whereby tokens unlock every second
  /// @param redemptionTime is the time requested for the plan to be redeemed, this can be the same as the current time or prior to it for partial redemptions
  function balanceAtTime(
    uint256 start,
    uint256 cliffDate,
    uint256 totalAmount,
    uint256 availableAmount,
    uint256 rate,
    uint256 period,
    uint256 redemptionTime
  ) internal pure returns (uint256 unlockedBalance, uint256 lockedBalance, uint256 unlockTime) {
    if (start > redemptionTime || cliffDate > redemptionTime) {
      // if the start date or cliff date are in the future, nothing is unlocked
      lockedBalance = availableAmount;
      unlockTime = start;
      unlockedBalance = 0;
    } else if (availableAmount < rate && totalAmount > rate) {
      // if the available amount is less than the rate, and the total amount is greater than the rate,
      // then it is still mid vesting or unlock stream, and so we cant unlock anything because we need to wait for the available amount to be greater than the rate
      lockedBalance = availableAmount;
      unlockTime = start;
      unlockedBalance = 0;
    } else {
      /// need to make sure clock is set correctly
      uint256 periodsElapsed = (redemptionTime - start) / period;
      uint256 calculatedBalance = periodsElapsed * rate;
      uint256 availablePeriods = availableAmount / rate;
      if (totalAmount <= calculatedBalance && availableAmount <= calculatedBalance) {
        /// if the total and the available are less than the calculated amount, then we can redeem the entire available balance
        lockedBalance = 0;
        unlockTime = start + (period * availablePeriods);
        unlockedBalance = availableAmount;
      } else if (availableAmount < calculatedBalance) {
        // else if the available is less than calculated but total is still more than calculated amount - we are still in the middle of vesting terms
        // so we need to determine the total number of periods we can actually unlock, which is the available amount divided by the rate
        unlockedBalance = availablePeriods * rate;
        lockedBalance = availableAmount - unlockedBalance;
        unlockTime = start + (period * availablePeriods);
      } else {
        // the calculated amount is less than available and total, so we just unlock the calculated amount
        unlockedBalance = calculatedBalance;
        lockedBalance = availableAmount - unlockedBalance;
        unlockTime = start + (period * periodsElapsed);
      }
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import '../libraries/TransferHelper.sol';

interface IGovernanceToken {
  function delegate(address delegatee) external;
  function delegates(address wallet) external view returns (address delegate);
}

contract VotingVault {
  address public token;
  address public controller;

  constructor(address _token, address beneficiary) {
    controller = msg.sender;
    token = _token;
    address existingDelegate = IGovernanceToken(token).delegates(beneficiary);
    if (existingDelegate != address(0)) IGovernanceToken(token).delegate(existingDelegate);
    else IGovernanceToken(token).delegate(beneficiary);
  }

  modifier onlyController() {
    require(msg.sender == controller);
    _;
  }

    /// @notice function to delegate the tokens of this address
    /// @dev if the delegatee is the existing delegate, skip the delegate function call - would be redundant
  function delegateTokens(address delegatee) external onlyController {
    address existingDelegate = IGovernanceToken(token).delegates(address(this));
    if (existingDelegate != delegatee) {
      uint256 balanceCheck = IERC20(token).balanceOf(address(this));
      IGovernanceToken(token).delegate(delegatee);
      // check to make sure delegate function is not malicious
      require(balanceCheck == IERC20(token).balanceOf(address(this)));
    }
  }

  function withdrawTokens(address to, uint256 amount) external onlyController {
    TransferHelper.withdrawTokens(token, to, amount);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.24;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import './ERC721Delegate/ERC721Delegate.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol';

import './libraries/UnlockLibrary.sol';
import './libraries/TransferHelper.sol';
import './interfaces/IVesting.sol';
import './periphery/VotingVault.sol';

/// @title TokenVestingLock
/// @notice This contract is used exclusively as an add-module for the Hedgey Vesting Plans to allow an additional lockup mechanism for tokens that are vesting
/// This contract will point to exactly one specific Hedgey Vesting contract, and it will allow for the holder of the plan to redeem their vesting tokens
/// but will conform to an additional lockup schedule where vested tokens are subject to the lockup, and can only be fully redeemed by the beneficiary
/// based on the combined vesting and lockups schedules.
/// @dev this contract is an ERC721 Enumerable extenstion that physically holds the Hedgey Vesting NFTs and issues recipients an NFT representing both the vesting and lockup schedule
/// @author iceman from Hedgey

contract TokenVestingLock is ERC721Delegate, ReentrancyGuard, ERC721Holder {
  /// @dev this is the implementation stored of the specific Hedgey Vesting contract this particular lockup contract is tied to
  IVesting public immutable hedgeyVesting;

  /// @notice for security only a special hedgey plan creator address is able to mint these NFTs in addition to vesting admin of a plan
  address public hedgeyPlanCreator;

  string public baseURI;
  /// @dev manager for setting the baseURI & hedgeyPlanCreator contract;
  address internal manager;

  /// @notice the internal counter of tokenIds that will be mapped to each vestinglock object and the associated NFT
  uint256 internal _tokenIds;

  /// @notice a struct that is used for creation of a new lockup that defines the beneficiary and if the vesting admin can redeem on behalf
  struct Recipient {
    address beneficiary;
    bool adminRedeem;
  }

  /// @notice primary struct defining the vesting lockup and its schedule
  /// @param token is the address of the token that is locked up and vesting
  /// @param totalAmount is the total amount - this comes from the vesting plan at inception and has to match
  /// @param availableAmount is the actual amount of tokens that have vested and been redeemed into this contract that are maximally available to unlock at any time
  /// @param start is the start date of the lockup schedule in block time
  /// @param cliff is the cliff date of the lockup schedule in block time
  /// @param rate is the rate at which tokens unlock per period. So if the rate is 100 and period is 1, then 100 tokens unlock per 1 second
  /// @param period is the length of each discrete period. a "streaming" version uses a period of 1 for 1 second but daily is 86400 as example
  /// @param vestingTokenId is the specific NFT token ID that is tied to the vesting plan
  /// @param vestingAdmin is the administrator on the vesting plan, this is the only address that can edit the lockup schedule
  /// @param transferable this is a toggle that the admin can define and allow the NFT to be transferred to another wallet by the owner of the lockup
  /// @param adminTransferOBO this is a toggle that would led the vestingAdmin transfer the lockup NFT to another wallet on behalf of the owner in case of emergency
  struct VestingLock {
    address token;
    uint256 totalAmount;
    uint256 availableAmount;
    uint256 start;
    uint256 cliff;
    uint256 rate;
    uint256 period;
    uint256 vestingTokenId;
    address vestingAdmin;
    bool transferable;
    bool adminTransferOBO;
  }

  /// @notice this is mapping of the VestingLock struct to the tokenIds which represent each NFT
  mapping(uint256 => VestingLock) internal _vestingLocks;

  /// @notice this is a mapping of the vestingTokenIds that have been allocted to a lockup NFT so that lockup NFTs are always mapped ONLY one to one to a vesting plan
  mapping(uint256 => bool) internal _allocatedVestingTokenIds;

  /// @notice this is a mapping of the approved redeemeers that can redeem the vested tokens or unlock the unlocked tokens, used as a mechanism for redeeming on behalf
  /// @dev if the user sets the zero address to be true, then it is a global approval for anyone to redeem
  mapping(uint256 => mapping(address => bool)) internal _approvedRedeemers;

  mapping(address => mapping(address => bool)) internal _redeemerOperators;

  /// @notice separate mapping specifically defining if the vestingAdmin can redeem on behalf of end users
  mapping(uint256 => bool) internal _adminRedeem;

  /// @notice this is a mapping of the voting vaults owned by the locked NFTs specifically used for onchain voting and delegation
  mapping(uint256 => address) public votingVaults;

  /*************EVENTS****************************************************************************************************/
  /// @notice events
  event VestingLockupCreated(
    uint256 indexed lockId,
    uint256 indexed vestingTokenId,
    address indexed beneficiary,
    VestingLock lock,
    uint256 lockEnd
  );
  event TokensUnlocked(uint256 indexed lockId, uint256 unlockedAmount, uint256 remainingTotal, uint256 unlockTime);
  event VestingRedeemed(
    uint256 indexed lockId,
    uint256 indexed vestingId,
    uint256 redeemedAmount,
    uint256 availableAmount,
    uint256 totalAmount
  );
  event LockEdited(uint256 indexed lockId, uint256 start, uint256 cliff, uint256 rate, uint256 period, uint256 end);

  event RedeemerApproved(uint256 indexed lockId, address redeemer);
  event RedeemerRemoved(uint256 indexed lockId, address redeemer);
  event AdminRedemption(uint256 indexed lockId, bool enabled);
  event VotingVaultCreated(uint256 indexed lockId, address votingVault);

  event VestingAdminUpdated(uint256 indexed lockId, address newAdmin);
  event TransferabilityUpdated(uint256 indexed lockId, bool transferable);
  event LockAdminTransferToggle(uint256 indexed id, bool transferable);

  event URISet(string newURI);
  event ManagerChanged(address newManager);
  event PlanCreatorChanged(address newPlanCreator);

  /*************CONSTRUCTOR & URI ADMIN FUNCTIONS****************************************************************************************************/

  /// @notice the constructor maps the specific hedgey vesting contract at inception and takes in the hedgeyPlanCreator address for minting the NFTs
  /// @dev note that these cannot be changed after deployment!
  constructor(
    string memory name,
    string memory symbol,
    address _hedgeyVesting,
    address _hedgeyPlanCreator,
    address _manager
  ) ERC721(name, symbol) {
    hedgeyVesting = IVesting(_hedgeyVesting);
    hedgeyPlanCreator = _hedgeyPlanCreator;
    manager = _manager;
  }

  modifier onlyManager() {
    require(msg.sender == manager, '!M');
    _;
  }

  /// @notice override function to deliver custom baseURI
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  /// @notice function to set the base URI after the contract has been launched, only the admin can call
  /// @param _uri is the new baseURI for the metadata
  function updateBaseURI(string memory _uri) external onlyManager {
    baseURI = _uri;
    emit URISet(_uri);
  }

  /// @notice function to change the admin address
  /// @param newManager is the new address for the admin
  function changeManager(address newManager) external onlyManager {
    manager = newManager;
    emit ManagerChanged(newManager);
  }

  /// @notice function to update the plan creator address in the case of updates to the functionality
  /// @param newCreator is the new address for the plan creator
  /// @dev only the admin can call this function
  function updatePlanCreator(address newCreator) external onlyManager {
    hedgeyPlanCreator = newCreator;
    emit PlanCreatorChanged(newCreator);
  }

  /*****TOKEN ID FUNCTIONS*************************************************************************************/
  /// @notice function to increment the tokenId counter, and returns the current tokenId after inrecmenting
  function incrementTokenId() internal returns (uint256) {
    _tokenIds++;
    return _tokenIds;
  }
  /// @notice function to get the current running total of tokenId, useful for when totalSupply does not match
  function currentTokenId() external view returns (uint256) {
    return _tokenIds;
  }

  /***PUBLIC GETTER FUNCTIONS***************************************************************************************************/

  /// @notice function to get the lock details of a specific lock NFT
  /// @param lockId is the token Id of the NFT
  function getVestingLock(uint256 lockId) external view returns (VestingLock memory) {
    return _vestingLocks[lockId];
  }

  /// @notice function to get the end date of a specific lock NFT
  /// @param lockId is the token Id of the NFT
  function getLockEnd(uint256 lockId) external view returns (uint256 end) {
    VestingLock memory lock = _vestingLocks[lockId];
    end = UnlockLibrary.endDate(lock.start, lock.totalAmount, lock.rate, lock.period);
  }

  /// @notice function to get the balance of a specific lock NFT at the current time
  /// @param lockId is the token Id of the NFT
  /// @dev the unlockedBalance is the amount of tokens that can be unlocked now, with the upper limit of the available amount that has already been vested and redeemed
  /// @dev the locked balance is the amount of tokens still locked based ont he lockup schedule
  /// @dev the unlockTime is the timestamp when the lock resets based on how many periods were able to be unlocked
  function getLockBalance(
    uint256 lockId
  ) external view returns (uint256 unlockedBalance, uint256 lockedBalance, uint256 unlockTime) {
    VestingLock memory lock = _vestingLocks[lockId];
    (unlockedBalance, lockedBalance, unlockTime) = UnlockLibrary.balanceAtTime(
      lock.start,
      lock.cliff,
      lock.totalAmount,
      lock.availableAmount,
      lock.rate,
      lock.period,
      block.timestamp
    );
  }

  /***********************REDEEMER FUNCTIONS**********************************************************************/

  /// @notice function to approve a new redeemer who can call the redeemVesting or unlock functions
  /// @param lockId is the token Id of the NFT
  /// @param redeemer is the address of the new redeemer (it can be the zero address)
  /// @dev only owner of the NFT can call this function
  /// @dev if the zero address is set to true, then it becomes publicly avilable for anyone to redeem
  function approveRedeemer(uint256 lockId, address redeemer) external {
    require(msg.sender == ownerOf(lockId) || _redeemerOperators[ownerOf(lockId)][msg.sender]);
    _approvedRedeemers[lockId][redeemer] = true;
    emit RedeemerApproved(lockId, redeemer);
  }

  /// @notice function to remove an approved redeemer
  /// @param lockId is the token Id of the NFT
  /// @param redeemer is the address of the redeemer to be removed
  /// @dev this function simply deletes the storage of the approved redeemer
  function removeRedeemer(uint256 lockId, address redeemer) external {
    require(msg.sender == ownerOf(lockId) || _redeemerOperators[ownerOf(lockId)][msg.sender]);
    delete _approvedRedeemers[lockId][redeemer];
    emit RedeemerRemoved(lockId, redeemer);
  }

  function approveRedeemerOperator(address operator, bool approved) external {
    _redeemerOperators[msg.sender][operator] = approved;
  }

  /// @notice function to set the admin redemption toggle on a specific lock NFT
  /// @param lockId is the token Id of the NFT
  /// @param enabled is the boolean toggle to allow the vesting admin to redeem on behalf of the owner
  function setAdminRedemption(uint256 lockId, bool enabled) external {
    require(msg.sender == ownerOf(lockId) || _redeemerOperators[ownerOf(lockId)][msg.sender]);
    _adminRedeem[lockId] = enabled;
    emit AdminRedemption(lockId, enabled);
  }

  /// @notice function to check if the admin can redeem on behalf of the owner
  /// @param lockId is the token Id of the NFT
  /// @param admin is the address of the admin
  function adminCanRedeem(uint256 lockId, address admin) public view returns (bool) {
    return (_adminRedeem[lockId] && admin == _vestingLocks[lockId].vestingAdmin);
  }

  /// @notice function to check if a specific address is an approved redeemer
  /// @param lockId is the token Id of the NFT
  /// @param redeemer is the address of the redeemer
  /// @dev will return true if the redeemer is the owner of the NFT, if the redeemer is approved or if the 0x0 address is approved, or if the redeemer is the admin address
  function isApprovedRedeemer(uint256 lockId, address redeemer) public view returns (bool) {
    address owner = ownerOf(lockId);
    return (owner == redeemer ||
      _approvedRedeemers[lockId][redeemer] ||
      _approvedRedeemers[lockId][address(0x0)] ||
      _redeemerOperators[owner][redeemer] ||
      adminCanRedeem(lockId, redeemer));
  }

  /******CORE EXTERNAL FUNCTIONS *********************************************************************************************/

  /// @notice function to create a new lockup NFT for a vesting plan
  /// @param recipient is the struct that defines the beneficiary and if the vesting admin can redeem on behalf
  /// @param vestingTokenId is the specific NFT token ID that is tied to the vesting plan
  /// @param start is the start date of the lockup schedule in block time
  /// @param cliff is the cliff date of the lockup schedule in block time
  /// @param rate is the rate at which tokens unlock per period
  /// @param period is the length of each discrete period
  /// @param transferable is the toggle that allows the NFT to be transferred to another wallet by the owner of the lockup
  /// @param adminTransferOBO is the toggle that would led the vestingAdmin transfer the lockup NFT to another wallet on behalf of the owner in case of emergency
  /// @dev this function will check that the vesting plan is owned by this contract, and that the vesting plan is not already allocated to a lockup NFT
  /// the function will also check that the caller is the hedgeyPlanCreator or the vestingAdmin of the plan
  /// the function will automatically set the totalAmount to the vesting plan amount, the token address to the vesting plan token address, and the vesting admin to the vestingAdmin of the vesting plan
  /// the function will perform a special check, if the plan is set to unlock the tokens all at once on a single date - where the rate is equal to the total amount
  /// then it will set the period to 1. Otherwise it will check that the lock end is greater than or equal to the vesting end
  /// the function will increment the tokenIds counter and store the new lockup NFT in the _vestingLocks mapping
  /// the function will then safeMint the new NFT to the recipient
  /// the function will toggle the vestingAdminTransfer to false for the vesting plan so that it cannot be pulled out of the lockup contract without approval from the recipient
  /// @dev this function is called either at the creation of both a new vesting plan with a lockup, which is the most common use case and done by the hdedgeyPlanCreator
  /// or it can be done after the fact if a vesting plan is transferred into this contract, and then the vesting admin calls this function to add a lockup schedule to the unallocated vesting plan
  function createVestingLock(
    Recipient memory recipient,
    uint256 vestingTokenId,
    uint256 start,
    uint256 cliff,
    uint256 rate,
    uint256 period,
    bool transferable,
    bool adminTransferOBO
  ) external nonReentrant returns (uint256 newLockId) {
    require(!_allocatedVestingTokenIds[vestingTokenId], 'a');
    require(hedgeyVesting.ownerOf(vestingTokenId) == address(this));
    _allocatedVestingTokenIds[vestingTokenId] = true;
    address vestingAdmin = hedgeyVesting.plans(vestingTokenId).vestingAdmin;
    require(msg.sender == hedgeyPlanCreator || msg.sender == vestingAdmin);
    uint256 totalAmount = hedgeyVesting.plans(vestingTokenId).amount;
    if (rate == totalAmount) period = 1;
    address token = hedgeyVesting.plans(vestingTokenId).token;
    uint256 vestingEnd = hedgeyVesting.planEnd(vestingTokenId);
    uint256 lockEnd = UnlockLibrary.validateEnd(start, cliff, totalAmount, rate, period, vestingEnd);
    newLockId = incrementTokenId();
    _vestingLocks[newLockId] = VestingLock(
      token,
      totalAmount,
      0,
      start,
      cliff,
      rate,
      period,
      vestingTokenId,
      vestingAdmin,
      transferable,
      adminTransferOBO
    );
    if (recipient.adminRedeem) {
      _adminRedeem[newLockId] = true;
      emit AdminRedemption(newLockId, true);
    }
    _safeMint(recipient.beneficiary, newLockId);
    hedgeyVesting.toggleAdminTransferOBO(vestingTokenId, false);
    emit VestingLockupCreated(newLockId, vestingTokenId, recipient.beneficiary, _vestingLocks[newLockId], lockEnd);
  }

  /// @notice function to redeem the vested tokens and immediateyl unlock whatever is available for multiple vesting lockups
  /// @param lockIds is the array of tokenIds of the lockup NFTs
  /// @dev this function will iterate through the array of lockIds and call the internal _redeemVesting function and then immediately call the internal _unlock function
  /// the function will pull any tokens that are vested into this contract, and then unlock any avilable and unlocked tokens and transfer them to the owner of the NFT - the beneficiary
  /// if there is nothing vested or unlocked, it will simply skip the redemption & unlocking and move onto the next tokenId rather than reverting the whole transaction
  /// this allows for a vestingAdmin who is redeeming on behalf of a group of users to redeem all of the tokens they are an admin for without having to calculate which ones have available balances and which do not
  function redeemAndUnlock(
    uint256[] calldata lockIds
  )
    external
    nonReentrant
    returns (uint256[] memory redeemedBalances, uint256[] memory vestingRemainder, uint256[] memory unlockedBalances)
  {
    uint256 l = lockIds.length;
    redeemedBalances = new uint256[](l);
    vestingRemainder = new uint256[](l);
    unlockedBalances = new uint256[](l);
    for (uint256 i; i < l; i++) {
      (redeemedBalances[i], vestingRemainder[i]) = _redeemVesting(lockIds[i]);
      unlockedBalances[i] = _unlock(lockIds[i]);
    }
  }

  /// @notice function to unlock tokens from an lockup
  /// @param lockIds is the array of tokenIds of the lockup NFTs
  /// @dev this function assumes that there are tokens that are vested and have already been redeemed and pulled into this contract that are now just locked and ready to be unlocked
  /// if there is nothing to unlock the function will not revert but no tokens will be moved
  function unlock(uint256[] calldata lockIds) external nonReentrant returns (uint256[] memory unlockedBalances) {
    uint256 l = lockIds.length;
    unlockedBalances = new uint256[](l);
    for (uint256 i; i < l; i++) {
      unlockedBalances[i] = _unlock(lockIds[i]);
    }
  }
  /// @notice function to redeem the vested tokens from the vesting plan associated with a specific lockup
  /// @param lockIds is the array of tokenIds of the lockup NFTs
  /// @dev this function will redeem anything that has vested, and the vested tokens will be pulled into this contract
  /// if there are no vested tokens for a specific plan, it will not revert but simply skip it on underlying the vesting contract logic itself
  function redeemVestingPlans(
    uint256[] calldata lockIds
  ) external nonReentrant returns (uint256[] memory balances, uint256[] memory remainders) {
    uint256 l = lockIds.length;
    balances = new uint256[](l);
    remainders = new uint256[](l);
    for (uint256 i; i < l; i++) {
      (balances[i], remainders[i]) = _redeemVesting(lockIds[i]);
    }
  }

  /// @notice function to burn a lockup NFT where the vesting plan NFT has been revoked and is burned
  /// @param lockId is the token Id of the lockup NFT associated with the revoked vesting plan
  /// @dev this function requires only the owner of the lockup NFT to call it
  /// it will check that the available amount is 0, so that the owner is not burning an NFT and thus losing the tokens that are still locked
  /// it will the use the try / catch patter to attempt to see if this contract is still the owner of the vesting plan.
  /// if this contract is still the owner, then it will revert as clearly the vesting plan has not been burned
  /// if the vesting plan is not owned by this contract anymore, then it will burn the lockup NFT and delete all storage of the lockup NFT
  /// @dev this does allow for the ability for a vestingAdmin to transfer the vestingPlan out of this contract, then the owner to burn this NFT even if the vesting plan is still active
  /// used only for emergency purposes where a mistake was made and the vesting plan was not supposed to be locked up or the lockup was wrong and needs to be adjusted
  /// but since only the owner of the lockup can burn the lock NFT, this allows there to be a safety mechanism in place
  /// such that it can be assumed there is agreement between the owner and the vestingAdmin to perform this emergency action
  function burnRevokedVesting(uint256 lockId) external nonReentrant {
    require(msg.sender == ownerOf(lockId), '!owner');
    VestingLock memory lock = _vestingLocks[lockId];
    require(lock.availableAmount == 0);
    try hedgeyVesting.ownerOf(lock.vestingTokenId) returns (address vestingOwner) {
      require(vestingOwner != address(this));
      _burn(lockId);
      delete _vestingLocks[lockId];
      delete _allocatedVestingTokenIds[lock.vestingTokenId];
    } catch {
      _burn(lockId);
      delete _vestingLocks[lockId];
      delete _allocatedVestingTokenIds[lock.vestingTokenId];
    }
  }

  /************CORE INTERNAL FUNCTIONS**************************************************************************************************/

  /// @notice internal function to unlock tokens available for a specific lockup NFT
  /// @param lockId is the token Id of the vestinglock NFT
  /// @dev this function will check that the msg sender is an approved redeemer
  /// then it will get the available balances that can be unlocked at the current time
  /// @dev if the unlocked balance is 0, the function will simply return 0 as the unlocked Balance and will not process anything further
  /// @dev if the function has an available unlocked balance it will check if the tokens are held externally at a voting vault
  /// and then transfer the amount of unlocked tokens from either the voting vualt or this contract to the beneficiary and owner of the lock NFT
  /// if the remaining total is now equal to 0, ie the total amount less the unlocked balance, then the vesting plan is burned and we can burn the lock NFT and delete it from storage
  /// otherwise we will update the available amount to be the lockedBalance - where the locked balance only includes the available amount that has been physically vested and pulled into this contract already
  /// update the start time to the unlock time
  /// and update the totalAmount to be the reaminig total amount which is the initial lock total amount less the unlocked balance
  function _unlock(uint256 lockId) internal returns (uint256 unlockedBalance) {
    require(isApprovedRedeemer(lockId, msg.sender), '!app');
    VestingLock memory lock = _vestingLocks[lockId];
    uint256 lockedBalance;
    uint256 unlockTime;
    (unlockedBalance, lockedBalance, unlockTime) = UnlockLibrary.balanceAtTime(
      lock.start,
      lock.cliff,
      lock.totalAmount,
      lock.availableAmount,
      lock.rate,
      lock.period,
      block.timestamp
    );
    if (unlockedBalance == 0) {
      return 0;
    }
    if (votingVaults[lockId] != address(0)) {
      VotingVault(votingVaults[lockId]).withdrawTokens(ownerOf(lockId), unlockedBalance);
    } else {
      TransferHelper.withdrawTokens(lock.token, ownerOf(lockId), unlockedBalance);
    }
    uint256 remainingTotal = lock.totalAmount - unlockedBalance;
    if (remainingTotal == 0) {
      _burn(lockId);
      delete _vestingLocks[lockId];
      delete _allocatedVestingTokenIds[lock.vestingTokenId];
    } else {
      _vestingLocks[lockId].availableAmount = lockedBalance;
      _vestingLocks[lockId].start = unlockTime;
      _vestingLocks[lockId].totalAmount = remainingTotal;
    }
    emit TokensUnlocked(lockId, unlockedBalance, remainingTotal, unlockTime);
  }

  /// @notice function to redeem the vested tokens from the vesting plan associated with a specific lockup
  /// @param lockId is the token Id of the vestingLock NFT
  /// @dev this function will check that the msg sender is an approved redeemer
  /// @dev the function will check that the vesting plan is owned by this contract. If it is not then it will simply return 0,0
  /// the function then checks the balance and remainder coming from the vesting plan contract itself. If the balance returns 0, then it will simply return 0,0
  /// the function then calls the redeemPlans function on the vesting plan contract to redeem the vested tokens
  /// the function performs a check ensuring that the balance calculated is the difference between the amount of tokens this contract holds before plus the redeemed balance equals the amount of tokens after
  /// the function then updates the available amount of the vestingLock struct to add the newly received redeemed balance of tokens
  /// then it will update the totalAmount of the lockup to equal the remainder of the vestingPlan plus available amount
  /// so that the total equals the amount still held by the vesting plan contract, and the amount held by this contract address
  // finally the function checks if the lockup has setup a voting vault, and if so it will transfer the tokens to the voting vault from this address
  function _redeemVesting(uint256 lockId) internal returns (uint256 balance, uint256 remainder) {
    require(isApprovedRedeemer(lockId, msg.sender), '!app');
    uint256 vestingId = _vestingLocks[lockId].vestingTokenId;
    require(_allocatedVestingTokenIds[vestingId], '!al');
    try hedgeyVesting.ownerOf(vestingId) returns (address vestingOwner) {
      if (vestingOwner != address(this)) {
        _vestingLocks[lockId].totalAmount = _vestingLocks[lockId].availableAmount;
        return (0, 0);
      }
    } catch {
      // set the total amount to the available amount - this will allow the nft to be unlocked if there is anything left still available but not locked
      _vestingLocks[lockId].totalAmount = _vestingLocks[lockId].availableAmount;
      return (0, 0);
    }
    (balance, remainder, ) = hedgeyVesting.planBalanceOf(vestingId, block.timestamp, block.timestamp);
    if (balance == 0) {
      return (balance, remainder);
    }
    uint256 preRedemptionBalance = IERC20(_vestingLocks[lockId].token).balanceOf(address(this));
    uint256[] memory vestingIds = new uint256[](1);
    vestingIds[0] = vestingId;
    hedgeyVesting.redeemPlans(vestingIds);
    uint256 postRedemptionBalance = IERC20(_vestingLocks[lockId].token).balanceOf(address(this));
    require(postRedemptionBalance - preRedemptionBalance == balance, '!r');
    _vestingLocks[lockId].availableAmount += balance;
    _vestingLocks[lockId].totalAmount = _vestingLocks[lockId].availableAmount + remainder;
    if (votingVaults[lockId] != address(0)) {
      TransferHelper.withdrawTokens(_vestingLocks[lockId].token, votingVaults[lockId], balance);
    }
    emit VestingRedeemed(
      lockId,
      vestingId,
      balance,
      _vestingLocks[lockId].availableAmount,
      _vestingLocks[lockId].totalAmount
    );
  }

  /************************************VESTING ADMIN FUNCTIONS**********************************************************/

  /// @notice function for the vesting admin to change their address to a new admin.
  /// @param lockIds is the array of tokenIds of the lockup NFTs
  /// @param newAdmin is the address of the new vesting admin
  /// @dev this function allows an admin to transfer in bulk
  /// @dev this function will check that the msg.sender is either the current admin, or the new vesting plan admin
  /// for the case where they have changed their address on the vesting plan contract and need to adjust it on the lockup contract as well
  /// this function just updates the vestingAdmin storage for each plan to the new admin
  function updateVestingAdmin(uint256[] memory lockIds, address newAdmin) external {
    uint256 l = lockIds.length;
    for (uint16 i; i < l; i++) {
      uint256 lockId = lockIds[i];
      address vestingAdmin = hedgeyVesting.plans(_vestingLocks[lockId].vestingTokenId).vestingAdmin;
      require(msg.sender == _vestingLocks[lockId].vestingAdmin || msg.sender == vestingAdmin, '!vA');
      _vestingLocks[lockId].vestingAdmin = newAdmin;
      emit VestingAdminUpdated(lockId, newAdmin);
    }
  }

  /// @notice function to update the transferability of a specific lock NFT
  /// @param lockIds is the array of tokenIds of the lockup NFTs
  /// @param transferable is a boolean toggle that allows the NFT to be transferred to another wallet by the owner of the lockup
  /// @dev this function simply checks that only the current vestingAdmin can make this adjustment, and then updates the storage accordingly
  function updateTransferability(uint256[] memory lockIds, bool transferable) external {
    uint256 l = lockIds.length;
    for (uint16 i; i < l; i++) {
      require(msg.sender == _vestingLocks[lockIds[i]].vestingAdmin, '!vA');
      _vestingLocks[lockIds[i]].transferable = transferable;
      emit TransferabilityUpdated(lockIds[i], transferable);
    }
  }

  /// @notice function to allow the admin to edit the lock details for a lock that hasn't started yet
  /// @param lockId is the token Id of the lockup NFT
  /// @param start is the start date of the new lockup schedule
  /// @param cliff is the cliff date of the new lockup schedule
  /// @param rate is the rate at which tokens unlock per period
  /// @param period is the length of each discrete period
  /// @dev this function can Only be called before the later of the start or the cliff - ie the lock must effectively not have started or have anything unlocked to change it
  /// the function can only be called by the existing vesting admin
  /// the function will update the vestinglock storage with the new start, cliff, rate, and period parameters
  /// the function will also double check and update the vesting plan to pull in the new total amount, being the available amount and the amount still in the vesting plan
  /// the function then validates that the end date
  function editLockDetails(uint256 lockId, uint256 start, uint256 cliff, uint256 rate, uint256 period) external nonReentrant {
    VestingLock storage lock = _vestingLocks[lockId];
    require(msg.sender == lock.vestingAdmin, '!vA');
    // must be before the later of the start or cliff
    uint256 editableDate = lock.start > lock.cliff ? lock.start : lock.cliff;
    require(block.timestamp < editableDate, '!e');
    lock.start = start;
    lock.cliff = cliff;
    lock.rate = rate;
    lock.totalAmount = hedgeyVesting.plans(lock.vestingTokenId).amount + lock.availableAmount;
    lock.period = rate == lock.totalAmount ? 1 : period;
    uint256 vestingEnd = hedgeyVesting.planEnd(lock.vestingTokenId);
    uint256 end = UnlockLibrary.validateEnd(start, cliff, lock.totalAmount, rate, lock.period, vestingEnd);
    emit LockEdited(lockId, start, cliff, rate, lock.period, end);
  }

  /*****************BENEFICIARY TRANSFERABILITY TOGGLES**********************************************************************/

  /// @notice function to allow the admin to transfer on behalf of the beneficial owner of the vesting lock NFT
  /// @param lockId is the token Id of the vesting lock NFT
  /// @param adminTransferOBO is the boolean toggle that would led the vestingAdmin transfer the lockup NFT to another wallet on behalf of the owner in case of emergency
  function updateAdminTransferOBO(uint256 lockId, bool adminTransferOBO) external {
    require(msg.sender == ownerOf(lockId), '!owner');
    _vestingLocks[lockId].adminTransferOBO = adminTransferOBO;
    emit LockAdminTransferToggle(lockId, adminTransferOBO);
  }

  /// @notice function to allow the admin of the actual vesting plan to transfer the vesting plan out of this contract
  /// @param lockId is the token Id of the vesting lock NFT
  /// @param transferable is the a boolean toggle recorded in storage on the vesting contract that determines it the vestingAdmin can transfer the vesting plan to another wallet
  /// @dev this function should be used carefully as it allows the vestingAdmin to transfer the vesting plan out of this contract - meaning the lockup will no longer be tied to the vesting plan
  /// transferring the vesting plan out may be used in case of emergency, but it will also mean the lockup is no longer valid to redeem vesting anymore
  function updateVestingTransferability(uint256 lockId, bool transferable) external {
    require(msg.sender == ownerOf(lockId), '!owner');
    hedgeyVesting.toggleAdminTransferOBO(_vestingLocks[lockId].vestingTokenId, transferable);
  }

  /***************DELEGATION FUNCTION FOR VESTING PLANS**********************************************************************************/

  /// @notice function to delegate multiple plans to multiple delegates in a single transaction
  /// @param lockIds is the array of tokenIds of the lockup NFTs
  /// @param delegatees is the array of addresses that each corresponding planId will be delegated to
  /// @dev this function will call the underlying vesting plan contract and delegate the tokens to the delegatee
  function delegatePlans(uint256[] calldata lockIds, address[] calldata delegatees) external nonReentrant {
    require(lockIds.length == delegatees.length);
    uint256 l = lockIds.length;
    uint256[] memory vestingIds = new uint256[](l);
    for (uint256 i; i < l; i++) {
      require(_isApprovedDelegatorOrOwner(msg.sender, lockIds[i]), '!d');
      vestingIds[i] = _vestingLocks[lockIds[i]].vestingTokenId;
    }
    hedgeyVesting.delegatePlans(vestingIds, delegatees);
  }

  /***************DELEGATION FUNCTION FOR ERC721DELEGATE CONTRACT**********************************************************************************/

  /// @notice functeion to delegate multiple plans to multiple delegates in a single transaction
  /// @dev this also calls the internal _delegateToken function from ERC721Delegate.sol to delegate an NFT to another wallet.
  /// @dev this function iterates through the array of plans and delegatees, delegating each individual NFT.
  /// @param lockIds is the array of planIds that will be delegated
  /// @param delegatees is the array of addresses that each corresponding planId will be delegated to
  function delegateLockNFTs(uint256[] calldata lockIds, address[] calldata delegatees) external nonReentrant {
    require(lockIds.length == delegatees.length);
    uint256 l = lockIds.length;
    for (uint256 i; i < l; i++) {
      _delegateToken(delegatees[i], lockIds[i]);
    }
  }

  /***************DELEGATION FUNCTION FOR ONCHAIN VOTING**********************************************************************************/

  /// @notice this function allows an owner of multiple vesting plans to delegate multiple of them in a single transaction, each planId corresponding to a delegatee address
  /// @dev this function should only be used for onchain voting and delegation with an ERC20Votes token
  /// @param lockIds is the ids of the vesting plan and NFT
  /// @param delegatees is the array of addresses where each vesting plan will delegate the tokens to
  function delegateLockPlans(
    uint256[] calldata lockIds,
    address[] calldata delegatees
  ) external nonReentrant returns (address[] memory) {
    require(lockIds.length == delegatees.length);
    uint256 l = lockIds.length;
    address[] memory vaults = new address[](l);
    for (uint256 i; i < l; i++) {
      vaults[i] = _delegate(lockIds[i], delegatees[i]);
    }
    return vaults;
  }

  /**************************INTERNAL ONCHAIN VOTING FUNCTIONS*************************************************************************************************************/

  /// @notice the internal function to setup a voting vault.
  /// @dev this will check that no voting vault exists already and then deploy a new voting vault contract
  // during the constructor setup of the voting vault, it will auto delegate the voting vault address to whatever the existing delegate of the vesting plan holder has delegated to
  // if it has not delegated yet, it will self-delegate the tokens
  /// then transfer the tokens remaining in the vesting plan to the voting vault physically
  /// @param lockId is the id of the vesting plan and NFT
  function _setupVoting(uint256 lockId) internal returns (address) {
    require(_isApprovedDelegatorOrOwner(msg.sender, lockId), '!d');
    require(votingVaults[lockId] == address(0), 'exists');
    VestingLock memory lock = _vestingLocks[lockId];
    VotingVault vault = new VotingVault(lock.token, ownerOf(lockId));
    votingVaults[lockId] = address(vault);
    if (lock.availableAmount > 0) TransferHelper.withdrawTokens(lock.token, address(vault), lock.availableAmount);
    emit VotingVaultCreated(lockId, address(vault));
    return address(vault);
  }

  /// @notice this internal function will physically delegate tokens held in a voting vault to a delegatee
  /// @dev if a voting vautl has not been setup yet, then the function will call the internal _setupVoting function and setup a new voting vault
  /// and then it will delegate the tokens held in the vault to the delegatee
  /// @param lockId is the id of the vesting plan and NFT
  /// @param delegatee is the address of the delegatee where the tokens in the voting vault will be delegated to
  function _delegate(uint256 lockId, address delegatee) internal returns (address) {
    require(_isApprovedDelegatorOrOwner(msg.sender, lockId), '!d');
    address vault = votingVaults[lockId];
    if (votingVaults[lockId] == address(0)) {
      vault = _setupVoting(lockId);
    }
    VotingVault(vault).delegateTokens(delegatee);
    return vault;
  }

  /******************************PUBLIC AGGREGATE VIEW FUNCTIONS ***********************************************************************/

  /// @notice this function will aggregate the available amount for a specific holder across all of their plans, based on a single ERC20 token
  /// @param holder is the address of the beneficiary who owns the vesting plan(s)
  /// @param token is the ERC20 address of the token that is stored across the vesting plans
  function lockedBalances(address holder, address token) external view returns (uint256 lockedBalance) {
    uint256 holdersBalance = balanceOf(holder);
    for (uint256 i; i < holdersBalance; i++) {
      uint256 lockId = tokenOfOwnerByIndex(holder, i);
      VestingLock memory lock = _vestingLocks[lockId];
      if (token == lock.token) {
        lockedBalance += lock.availableAmount;
      }
    }
  }

  /// @notice this function will pull all of the tokens locked in vesting plans where the NFT has been delegated to a specific delegatee wallet address
  /// this is useful for the snapshot strategy hedgey-delegate, polling this function based on the wallet signed into snapshot
  /// by default all NFTs are self-delegated when they are minted.
  /// @param delegatee is the address of the delegate where NFTs have been delegated to
  /// @param token is the address of the ERC20 token that is locked in vesting plans and has been delegated
  function delegatedBalances(address delegatee, address token) external view returns (uint256 delegatedBalance) {
    uint256 delegateBalance = balanceOfDelegate(delegatee);
    for (uint256 i; i < delegateBalance; i++) {
      uint256 lockId = tokenOfDelegateByIndex(delegatee, i);
      VestingLock memory lock = _vestingLocks[lockId];
      if (token == lock.token) {
        delegatedBalance += lock.availableAmount;
      }
    }
  }

  /*******INTERNAL NFT TRANSFERABILITY UPDATES*********************************************************************************/

  /// @notice function that overrides the internal OZ logic to manage the transferability of the NFT
  /// @dev if the auth address is the 0x0 address, then its either mint or burn and we do not need to perform any additional checks
  /// @dev if the auth address is not the 0x0 address, then it will check if the auth address (spender) is the vesting admin, and if it is, will process the transfer and check if the admintransfertoggle is on
  /// we have the function set specifically to check when auth is the vesting admin so that the _isAuthorzied can check if the adminTransferOBO is on
  /// or if the admin has specifically been approved to transfer on behalf of the owner, then it can be done once by the admin in the normal _getApproved function
  /// otherwise we check if the lockup is transferable and then perform the transfer
  function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
    if (auth != address(0x0)) {
      if (auth == _vestingLocks[tokenId].vestingAdmin) {
        return super._update(to, tokenId, auth);
      } else {
        require(_vestingLocks[tokenId].transferable, '!transferable');
        return super._update(to, tokenId, auth);
      }
    } else {
      _updateDelegate(to, tokenId);
      return super._update(to, tokenId, address(0x0));
    }
  }

  /// @notice this function overrides the internal isAuthorized function specifically for when the vestingAdmin is the spender, and check if the adminTransferOBO is on
  /// @dev we update the authorization logic instead of the update logic for the adminTransferOBO toggle as we want to check this whenever the admin is the spender
  function _isAuthorized(
    address owner,
    address spender,
    uint256 tokenId
  ) internal view virtual override returns (bool) {
    return
      spender != address(0) &&
      (owner == spender ||
        isApprovedForAll(owner, spender) ||
        _getApproved(tokenId) == spender ||
        (spender == _vestingLocks[tokenId].vestingAdmin && _vestingLocks[tokenId].adminTransferOBO));
  }
}