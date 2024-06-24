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
pragma solidity 0.8.25;

// Interfaces
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface IAthenaCoverToken is IERC721Enumerable {
  function mint(address to) external returns (uint256 coverId);

  function burn(uint256 tokenId) external;

  function tokensOf(
    address account_
  ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// Interfaces
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

interface IAthenaPositionToken is IERC721Enumerable {
  function mint(address to) external returns (uint256 positionId);

  function burn(uint256 tokenId) external;

  function tokensOf(
    address account_
  ) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IEcclesiaDao {
  function accrueRevenue(
    address _token,
    uint256 _amount,
    uint256 leverageFee_
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// libraries
import { VirtualPool } from "../libs/VirtualPool.sol";
import { PoolMath } from "../libs/PoolMath.sol";
import { DataTypes } from "../libs/DataTypes.sol";
// interfaces
import { IEcclesiaDao } from "../interfaces/IEcclesiaDao.sol";
import { IStrategyManager } from "../interfaces/IStrategyManager.sol";

interface ILiquidityManager {
  // ======= STRUCTS ======= //

  struct CoverRead {
    uint256 coverId;
    uint64 poolId;
    uint256 coverAmount;
    bool isActive;
    uint256 premiumsLeft;
    uint256 dailyCost;
    uint256 premiumRate;
    uint32 lastTick; // Last last tick for which the cover is active
  }

  struct PositionRead {
    uint256 positionId;
    uint256 supplied;
    uint256 suppliedWrapped;
    uint256 commitWithdrawalTimestamp;
    uint256 strategyRewardIndex;
    uint64[] poolIds;
    uint256 newUserCapital;
    uint256 newUserCapitalWrapped;
    uint256[] coverRewards;
    uint256 strategyRewards;
  }

  struct Position {
    uint256 supplied;
    uint256 commitWithdrawalTimestamp;
    uint256 strategyRewardIndex;
    uint64[] poolIds;
  }

  struct PoolOverlap {
    uint64 poolId;
    uint256 amount;
  }

  struct VPoolRead {
    uint64 poolId;
    uint256 feeRate; // amount of fees on premiums in RAY
    uint256 leverageFeePerPool; // amount of fees per pool when using leverage
    IEcclesiaDao dao;
    IStrategyManager strategyManager;
    PoolMath.Formula formula;
    DataTypes.Slot0 slot0;
    uint256 strategyId;
    uint256 strategyRewardRate;
    address paymentAsset; // asset used to pay LP premiums
    address underlyingAsset; // asset required by the strategy
    address wrappedAsset; // tokenised strategy shares (ex: aTokens)
    bool isPaused;
    uint64[] overlappedPools;
    uint256 ongoingClaims;
    uint256[] compensationIds;
    uint256[] overlappedCapital;
    uint256 utilizationRate;
    uint256 totalLiquidity;
    uint256 availableLiquidity;
    uint256 strategyRewardIndex;
    uint256 lastOnchainUpdateTimestamp;
    uint256 premiumRate;
    // The amount of liquidity index that is in the current unfinished tick
    uint256 liquidityIndexLead;
  }

  function strategyManager() external view returns (IStrategyManager);

  function positions(
    uint256 tokenId_
  ) external view returns (Position memory);

  function coverToPool(
    uint256 tokenId_
  ) external view returns (uint64);

  function poolOverlaps(
    uint64 poolIdA_,
    uint64 poolIdB_
  ) external view returns (uint256);

  function coverInfo(
    uint256 tokenId_
  ) external view returns (CoverRead memory);

  function isCoverActive(
    uint256 tokenId
  ) external view returns (bool);

  function addClaimToPool(uint256 coverId_) external;

  function removeClaimFromPool(uint256 coverId_) external;

  function payoutClaim(uint256 poolId_, uint256 amount_) external;

  function takeInterestsWithYieldBonus(
    address account_,
    uint256 yieldBonus_,
    uint256[] calldata positionIds_
  ) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

interface IStrategyManager {
  function getRewardIndex(
    uint256 strategyId
  ) external view returns (uint256);

  function getRewardRate(
    uint256 strategyId_
  ) external view returns (uint256);

  function underlyingAsset(
    uint256 strategyId_
  ) external view returns (address);

  function assets(
    uint256 strategyId_
  ) external view returns (address underlying, address wrapped);

  function wrappedToUnderlying(
    uint256 strategyId_,
    uint256 amountWrapped_
  ) external view returns (uint256);

  function depositToStrategy(
    uint256 strategyId_,
    uint256 amountUnderlying_
  ) external;

  function withdrawFromStrategy(
    uint256 strategyId_,
    uint256 amountCapitalUnderlying_,
    uint256 amountRewardsUnderlying_,
    address account_,
    uint256 /*yieldBonus_*/
  ) external;

  function depositWrappedToStrategy(uint256 strategyId_) external;

  function withdrawWrappedFromStrategy(
    uint256 strategyId_,
    uint256 amountCapitalUnderlying_,
    uint256 amountRewardsUnderlying_,
    address account_,
    uint256 /*yieldBonus_*/
  ) external;

  function payoutFromStrategy(
    uint256 strategyId_,
    uint256 amount,
    address claimant
  ) external;

  function computeReward(
    uint256 strategyId_,
    uint256 amount_,
    uint256 startRewardIndex_,
    uint256 endRewardIndex_
  ) external pure returns (uint256);

  function itCompounds(
    uint256 strategyId_
  ) external pure returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.25;

/// @title BitMath
/// @dev This library provides functionality for computing bit properties of an unsigned integer
library BitMath {
  /// @notice Returns the index of the least significant bit of the number,
  ///     where the least significant bit is at index 0 and the most significant bit is at index 255
  /// @dev The function satisfies the property:
  ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
  /// @param x the value for which to compute the least significant bit, must be greater than 0
  /// @return r the index of the least significant bit
  function leastSignificantBit(
    uint256 x
  ) internal pure returns (uint8 r) {
    require(x > 0);

    r = 255;
    if (x & type(uint128).max > 0) {
      r -= 128;
    } else {
      x >>= 128;
    }
    if (x & type(uint64).max > 0) {
      r -= 64;
    } else {
      x >>= 64;
    }
    if (x & type(uint32).max > 0) {
      r -= 32;
    } else {
      x >>= 32;
    }
    if (x & type(uint16).max > 0) {
      r -= 16;
    } else {
      x >>= 16;
    }
    if (x & type(uint8).max > 0) {
      r -= 8;
    } else {
      x >>= 8;
    }
    if (x & 0xf > 0) {
      r -= 4;
    } else {
      x >>= 4;
    }
    if (x & 0x3 > 0) {
      r -= 2;
    } else {
      x >>= 2;
    }
    if (x & 0x1 > 0) r -= 1;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

// Libraries
import { RayMath } from "../libs/RayMath.sol";
import { TickBitmap } from "../libs/TickBitmap.sol";
import { PoolMath } from "../libs/PoolMath.sol";

// Interfaces
import { IEcclesiaDao } from "../interfaces/IEcclesiaDao.sol";
import { IStrategyManager } from "../interfaces/IStrategyManager.sol";

library DataTypes {
  struct Slot0 {
    // The last tick at which the pool's liquidity was updated
    uint32 tick;
    // The distance in seconds between ticks
    uint256 secondsPerTick;
    uint256 coveredCapital;
    /**
     * The last timestamp at which the current tick changed
     * This value indicates the start of the current stored tick
     */
    uint256 lastUpdateTimestamp;
    // The index tracking how much premiums have been consumed in favor of LP
    uint256 liquidityIndex;
  }

  struct LpInfo {
    uint256 beginLiquidityIndex;
    uint256 beginClaimIndex;
  }

  struct Cover {
    uint256 coverAmount;
    uint256 beginPremiumRate;
    /**
     * If cover is active: last last tick for which the cover is valid
     * If cover is expired: slot0 tick at which the cover was expired minus 1
     */
    uint32 lastTick;
  }

  struct Compensation {
    uint64 fromPoolId;
    // The ratio is the claimed amount/ total liquidity in the claim pool
    uint256 ratio;
    uint256 strategyRewardIndexBeforeClaim;
    mapping(uint64 _poolId => uint256 _amount) liquidityIndexBeforeClaim;
  }

  struct VPool {
    uint64 poolId;
    uint256 feeRate; // amount of fees on premiums in RAY
    uint256 leverageFeePerPool; // amount of fees per pool when using leverage
    IEcclesiaDao dao;
    IStrategyManager strategyManager;
    PoolMath.Formula formula;
    Slot0 slot0;
    uint256 strategyId;
    address paymentAsset; // asset used to pay LP premiums
    address underlyingAsset; // asset covered & used by the strategy
    address wrappedAsset; // tokenised strategy shares (ex: aTokens)
    bool isPaused;
    uint64[] overlappedPools;
    uint256 ongoingClaims;
    uint256[] compensationIds;
    /**
     * Maps poolId 0 -> poolId 1 -> overlapping capital
     *
     * @dev poolId 0 -> poolId 0 points to a pool's own liquidity
     * @dev liquidity overlap is always registered in the lower poolId
     */
    mapping(uint64 _poolId => uint256 _amount) overlaps;
    mapping(uint256 _positionId => LpInfo) lpInfos;
    // Maps an word position index to a bitmap of tick states (initialized or not)
    mapping(uint24 _wordPos => uint256 _bitmap) tickBitmap;
    // Maps a tick to the amount of cover that expires after that tick ends
    mapping(uint32 _tick => uint256 _coverAmount) ticks;
    // Maps a cover ID to the premium position of the cover
    mapping(uint256 _coverId => Cover) covers;
  }

  struct VPoolConstructorParams {
    uint64 poolId;
    IEcclesiaDao dao;
    IStrategyManager strategyManager;
    uint256 strategyId;
    address paymentAsset;
    uint256 feeRate; //Ray
    uint256 leverageFeePerPool; //Ray
    uint256 uOptimal; //Ray
    uint256 r0; //Ray
    uint256 rSlope1; //Ray
    uint256 rSlope2; //Ray
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

// Libraries
import { RayMath } from "../libs/RayMath.sol";

// @bw move back into vpool ?

library PoolMath {
  using RayMath for uint256;

  // ======= CONSTANTS ======= //

  uint256 constant YEAR = 365 days;
  uint256 constant RAY = RayMath.RAY;
  uint256 constant MAX_SECONDS_PER_TICK = 1 days;
  uint256 constant FEE_BASE = RAY;
  uint256 constant PERCENTAGE_BASE = 100;
  uint256 constant FULL_CAPACITY = PERCENTAGE_BASE * RAY;

  // ======= STRUCTURES ======= //

  struct Formula {
    uint256 uOptimal;
    uint256 r0;
    uint256 rSlope1;
    uint256 rSlope2;
  }

  // ======= FUNCTIONS ======= //

  /**
   * @notice Computes the premium rate of a cover,
   * the premium rate is the APR cost for a cover  ,
   * these are paid by cover buyer on their cover amount.
   *
   * @param formula The formula of the pool
   * @param utilizationRate_ The utilization rate of the pool
   *
   * @return The premium rate of the cover expressed in rays
   *
   * @dev Not pure since reads self but pure for all practical purposes
   */
  function getPremiumRate(
    Formula calldata formula,
    uint256 utilizationRate_
  ) public pure returns (uint256 /* premiumRate */) {
    if (utilizationRate_ < formula.uOptimal) {
      // Return base rate + proportional slope 1 rate
      return
        formula.r0 +
        formula.rSlope1.rayMul(
          utilizationRate_.rayDiv(formula.uOptimal)
        );
    } else if (utilizationRate_ < FULL_CAPACITY) {
      // Return base rate + slope 1 rate + proportional slope 2 rate
      return
        formula.r0 +
        formula.rSlope1 +
        formula.rSlope2.rayMul(
          (utilizationRate_ - formula.uOptimal).rayDiv(
            FULL_CAPACITY - formula.uOptimal
          )
        );
    } else {
      // Return base rate + slope 1 rate + slope 2 rate
      /**
       * @dev Premium rate is capped because in case of overusage the
       * liquidity providers are exposed to the same risk as 100% usage but
       * cover buyers are not fully covered.
       * This means cover buyers only pay for the effective cover they have.
       */
      return formula.r0 + formula.rSlope1 + formula.rSlope2;
    }
  }

  /**
   * @notice Computes the liquidity index for a given period
   * @param utilizationRate_ The utilization rate
   * @param premiumRate_ The premium rate
   * @param timeSeconds_ The time in seconds
   * @return The liquidity index to add for the given time
   */
  function computeLiquidityIndex(
    uint256 utilizationRate_,
    uint256 premiumRate_,
    uint256 timeSeconds_
  ) public pure returns (uint /* liquidityIndex */) {
    return
      utilizationRate_
        .rayMul(premiumRate_)
        .rayMul(timeSeconds_)
        .rayDiv(YEAR);
  }

  /**
   * @notice Computes the premiums or interests earned by a liquidity position
   * @param userCapital_ The amount of liquidity in the position
   * @param endLiquidityIndex_ The end liquidity index
   * @param startLiquidityIndex_ The start liquidity index
   */
  function getCoverRewards(
    uint256 userCapital_,
    uint256 startLiquidityIndex_,
    uint256 endLiquidityIndex_
  ) public pure returns (uint256) {
    return
      (userCapital_.rayMul(endLiquidityIndex_) -
        userCapital_.rayMul(startLiquidityIndex_)) / 10_000;
  }

  /**
   * @notice Computes the new daily cost of a cover,
   * the emmission rate is the daily cost of a cover  .
   *
   * @param oldDailyCost_ The daily cost of the cover before the change
   * @param oldPremiumRate_ The premium rate of the cover before the change
   * @param newPremiumRate_ The premium rate of the cover after the change
   *
   * @return The new daily cost of the cover expressed in tokens/day
   */
  function getDailyCost(
    uint256 oldDailyCost_,
    uint256 oldPremiumRate_,
    uint256 newPremiumRate_
  ) public pure returns (uint256) {
    return (oldDailyCost_ * newPremiumRate_) / oldPremiumRate_;
  }

  /**
   * @notice Computes the new seconds per tick of a pool,
   * the seconds per tick is the time between two ticks  .
   *
   * @param oldSecondsPerTick_ The seconds per tick before the change
   * @param oldPremiumRate_ The premium rate before the change
   * @param newPremiumRate_ The premium rate after the change
   *
   * @return The new seconds per tick of the pool
   */
  function secondsPerTick(
    uint256 oldSecondsPerTick_,
    uint256 oldPremiumRate_,
    uint256 newPremiumRate_
  ) public pure returns (uint256) {
    return
      oldSecondsPerTick_.rayMul(oldPremiumRate_).rayDiv(
        newPremiumRate_
      );
  }

  /**
   * @notice Computes the updated premium rate of the pool based on utilization.
   * @param formula The formula of the pool
   * @param secondsPerTick_ The seconds per tick of the pool
   * @param coveredCapital_ The amount of covered capital
   * @param totalLiquidity_ The total amount liquidity
   * @param newCoveredCapital_ The new amount of covered capital
   * @param newTotalLiquidity_ The new total amount liquidity
   *
   * @return newPremiumRate The updated premium rate of the pool
   * @return newSecondsPerTick The updated seconds per tick of the pool
   */
  function updatePoolMarket(
    Formula calldata formula,
    uint256 secondsPerTick_,
    uint256 totalLiquidity_,
    uint256 coveredCapital_,
    uint256 newTotalLiquidity_,
    uint256 newCoveredCapital_
  )
    public
    pure
    returns (
      uint256 newPremiumRate,
      uint256 newSecondsPerTick,
      uint256 newUtilizationRate
    )
  {
    uint256 previousPremiumRate = getPremiumRate(
      formula,
      _utilization(coveredCapital_, totalLiquidity_)
    );

    newUtilizationRate = _utilization(
      newCoveredCapital_,
      newTotalLiquidity_
    );

    newPremiumRate = getPremiumRate(formula, newUtilizationRate);

    newSecondsPerTick = secondsPerTick(
      secondsPerTick_,
      previousPremiumRate,
      newPremiumRate
    );
  }

  /**
   * @notice Computes the percentage of the pool's liquidity used for covers.
   * @param coveredCapital_ The amount of covered capital
   * @param liquidity_ The total amount liquidity
   *
   * @return rate The utilization rate of the pool
   *
   * @dev The utilization rate is capped at 100%.
   */
  function _utilization(
    uint256 coveredCapital_,
    uint256 liquidity_
  ) public pure returns (uint256 /* rate */) {
    // If the pool has no liquidity then the utilization rate is 0
    if (liquidity_ == 0) return 0;

    /**
     * @dev Utilization rate is capped at 100% because in case of overusage the
     * liquidity providers are exposed to the same risk as 100% usage but
     * cover buyers are not fully covered.
     * This means cover buyers only pay for the effective cover they have.
     */
    if (liquidity_ < coveredCapital_) return FULL_CAPACITY;

    // Get a base PERCENTAGE_BASE percentage
    return (coveredCapital_ * PERCENTAGE_BASE).rayDiv(liquidity_);
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.25;

/**
 * @title RayMath library
 * @author Aave
 * @dev Provides mul and div function for rays (decimals with 27 digits)
 **/

library RayMath {
  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a*b, in ray
   **/
  function rayMul(
    uint256 a,
    uint256 b
  ) internal pure returns (uint256) {
    return (a * b + halfRAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(
    uint256 a,
    uint256 b
  ) internal pure returns (uint256) {
    return ((a * RAY) + (b / 2)) / b;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/ReentrancyGuard.sol)

pragma solidity ^0.8.25;

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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

// Libraries
import { BitMath } from "./BitMath.sol";

/// @title Packed tick initialized state library
/// @notice Stores a packed mapping of tick index to its initialized state
/// @dev The mapping uses int24 for keys since ticks are represented as int32 and there are 256 (2^8) values per word.
library TickBitmap {
  /// @notice Computes the position in the mapping where the initialized bit for a tick lives
  /// @param tick The tick for which to compute the position
  /// @return wordPos The key in the mapping containing the word in which the bit is stored
  /// @return bitPos The bit position in the word where the flag is stored
  function position(
    uint32 tick
  ) private pure returns (uint24 wordPos, uint8 bitPos) {
    wordPos = uint24(tick >> 8);
    bitPos = uint8(uint32(tick % 256));
  }

  /// @notice Flips the initialized state for a given tick from false to true, or vice versa
  /// @param self The mapping in which to flip the tick
  /// @param tick The tick to flip
  function flipTick(
    mapping(uint24 => uint256) storage self,
    uint32 tick
  ) internal {
    (uint24 wordPos, uint8 bitPos) = position(tick);
    uint256 mask = 1 << bitPos;
    self[wordPos] ^= mask;
  }

  function isInitializedTick(
    mapping(uint24 => uint256) storage self,
    uint32 tick
  ) internal view returns (bool) {
    (uint24 wordPos, uint8 bitPos) = position(tick);
    uint256 mask = 1 << bitPos;
    return (self[wordPos] & mask) != 0;
  }

  /// @notice Returns the next initialized tick contained in the same word (or adjacent word)
  /// as the tick that is to the left (greater than) of the given tick
  /// @param self The mapping in which to compute the next initialized tick
  /// @param tick The starting tick
  function nextTick(
    mapping(uint24 => uint256) storage self,
    uint32 tick
  ) internal view returns (uint32 next, bool initialized) {
    // start from the word of the next tick, since the current tick state doesn't matter
    (uint24 wordPos, uint8 bitPos) = position(tick + 1);
    // all the 1s at or to the left of the bitPos
    uint256 mask = ~((1 << bitPos) - 1);
    uint256 masked = self[wordPos] & mask;

    // if there are no initialized ticks to the left of the current tick, return leftmost in the word
    initialized = masked != 0;
    // overflow/underflow is possible, but prevented externally by limiting tick
    next = initialized
      ? (tick +
        1 +
        uint32(BitMath.leastSignificantBit(masked) - bitPos))
      : (tick + 1 + uint32(type(uint8).max - bitPos));
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

// Libraries
import { RayMath } from "../libs/RayMath.sol";
import { TickBitmap } from "../libs/TickBitmap.sol";
import { PoolMath } from "../libs/PoolMath.sol";
import { DataTypes } from "../libs/DataTypes.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Interfaces
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IEcclesiaDao } from "../interfaces/IEcclesiaDao.sol";
import { IStrategyManager } from "../interfaces/IStrategyManager.sol";

// ======= ERRORS ======= //

error ZeroAddressAsset();
error DurationBelowOneTick();
error DurationOverflow();
error InsufficientCapacity();
error NotEnoughLiquidityForRemoval();

/**
 * @title Athena Virtual Pool
 * @author vblackwhale
 *
 * This library provides the logic to create and manage virtual pools.
 * The pool storage is located in the Liquidity Manager contract.
 *
 * Definitions:
 *
 * Ticks:
 * They are a serie equidistant points in time who's distance from one another is variable.
 * The initial tick spacing is its maximum possible value of 86400 seconds or 1 day.
 * The distance between ticks will reduce as usage grows and increase when usage falls.
 * The change in distance represents the speed at which cover premiums are spent given the pool's usage.
 *
 * Core pool metrics are computed with the following flow:
 * Utilization Rate (ray %) -> Premium Rate (ray %) -> Daily Cost (token/day)
 */
library VirtualPool {
  // ======= LIBS ======= //
  using VirtualPool for DataTypes.VPool;
  using RayMath for uint256;
  using SafeERC20 for IERC20;
  using TickBitmap for mapping(uint24 => uint256);

  // ======= CONSTANTS ======= //

  bytes32 private constant POOL_SLOT_HASH =
    keccak256("diamond.storage.VPool");
  bytes32 private constant COMPENSATION_SLOT_HASH =
    keccak256("diamond.storage.Compensation");

  uint256 constant YEAR = 365 days;
  uint256 constant RAY = RayMath.RAY;
  uint256 constant MAX_SECONDS_PER_TICK = 1 days;
  uint256 constant FEE_BASE = RAY;
  uint256 constant PERCENTAGE_BASE = 100;
  uint256 constant HUNDRED_PERCENT = FEE_BASE * PERCENTAGE_BASE;

  // ======= STRUCTS ======= //

  struct CoverInfo {
    uint256 premiumsLeft;
    uint256 dailyCost;
    uint256 premiumRate;
    bool isActive;
  }

  struct UpdatePositionParams {
    uint256 currentLiquidityIndex;
    uint256 tokenId;
    uint256 userCapital;
    uint256 strategyRewardIndex;
    uint256 latestStrategyRewardIndex;
    uint256 strategyId;
    bool itCompounds;
    uint256 endCompensationId;
    uint256 nbPools;
  }

  struct UpdatedPositionInfo {
    uint256 newUserCapital;
    uint256 coverRewards;
    uint256 strategyRewards;
    DataTypes.LpInfo newLpInfo;
  }

  // ======= STORAGE GETTERS ======= //

  /**
   * @notice Returns the storage slot position of a pool.
   *
   * @param poolId_ The pool ID
   *
   * @return pool The storage slot position of the pool
   */
  function getPool(
    uint64 poolId_
  ) internal pure returns (DataTypes.VPool storage pool) {
    // Generate a random storage storage slot position based on the pool ID
    bytes32 storagePosition = keccak256(
      abi.encodePacked(POOL_SLOT_HASH, poolId_)
    );

    // Set the position of our struct in contract storage
    assembly {
      pool.slot := storagePosition
    }
  }

  /**
   * @notice Returns the storage slot position of a compensation.
   *
   * @param compensationId_ The compensation ID
   *
   * @return comp The storage slot position of the compensation
   *
   * @dev Enables VirtualPool library to access child compensation storage
   */
  function getCompensation(
    uint256 compensationId_
  ) internal pure returns (DataTypes.Compensation storage comp) {
    // Generate a random storage storage slot position based on the compensation ID
    bytes32 storagePosition = keccak256(
      abi.encodePacked(COMPENSATION_SLOT_HASH, compensationId_)
    );

    // Set the position of our struct in contract storage
    assembly {
      comp.slot := storagePosition
    }
  }

  // ======= VIRTUAL STORAGE INIT ======= //

  /**
   * @notice Initializes a virtual pool & populates its storage
   *
   * @param params The pool's constructor parameters
   */
  function _vPoolConstructor(
    DataTypes.VPoolConstructorParams memory params
  ) internal {
    DataTypes.VPool storage pool = VirtualPool.getPool(params.poolId);

    (address underlyingAsset, address wrappedAsset) = params
      .strategyManager
      .assets(params.strategyId);

    if (
      underlyingAsset == address(0) ||
      params.paymentAsset == address(0)
    ) {
      revert ZeroAddressAsset();
    }

    pool.poolId = params.poolId;
    pool.dao = params.dao;
    pool.strategyManager = params.strategyManager;
    pool.paymentAsset = params.paymentAsset;
    pool.strategyId = params.strategyId;
    pool.underlyingAsset = underlyingAsset;
    pool.wrappedAsset = wrappedAsset;
    pool.feeRate = params.feeRate;
    pool.leverageFeePerPool = params.leverageFeePerPool;

    pool.formula = PoolMath.Formula({
      uOptimal: params.uOptimal,
      r0: params.r0,
      rSlope1: params.rSlope1,
      rSlope2: params.rSlope2
    });

    /// @dev the initial tick spacing is its maximum value 86400 seconds
    pool.slot0.secondsPerTick = MAX_SECONDS_PER_TICK;
    pool.slot0.lastUpdateTimestamp = block.timestamp;
    /// @dev initialize at 1 to enable expiring covers created a first tick
    pool.slot0.tick = 1;

    pool.overlappedPools.push(params.poolId);
  }

  // ================================= //
  // ======= LIQUIDITY METHODS ======= //
  // ================================= //

  /**
   * @notice Returns the total liquidity of the pool.
   *
   * @param poolId_ The pool ID
   */
  function totalLiquidity(
    uint64 poolId_
  ) public view returns (uint256) {
    return getPool(poolId_).overlaps[poolId_];
  }

  /**
   * @notice Returns the available liquidity of the pool.
   *
   * @param poolId_ The pool ID
   */
  function availableLiquidity(
    uint64 poolId_
  ) public view returns (uint256) {
    DataTypes.VPool storage self = getPool(poolId_);

    /// @dev Since payout can lead to available capital underflow, we return 0
    if (totalLiquidity(poolId_) <= self.slot0.coveredCapital)
      return 0;

    return totalLiquidity(poolId_) - self.slot0.coveredCapital;
  }

  /**
   * @notice Computes an updated slot0 & liquidity index up to a timestamp.
   * These changes are virtual an not reflected in storage in this function.
   *
   * @param poolId_ The pool ID
   * @param timestamp_ The timestamp to update the slot0 & liquidity index to
   *
   * @return slot0 The updated slot0
   */
  function _refreshSlot0(
    uint64 poolId_,
    uint256 timestamp_
  ) public view returns (DataTypes.Slot0 memory slot0) {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    // Make copy in memory to allow for mutations
    slot0 = self.slot0;

    // The remaining time in seconds to run through to sync up to the timestamp
    uint256 remaining = timestamp_ - slot0.lastUpdateTimestamp;

    // If the remaining time is less than the tick spacing then return the slot0
    if (remaining < slot0.secondsPerTick) return slot0;

    uint256 utilization = PoolMath._utilization(
      slot0.coveredCapital,
      totalLiquidity(self.poolId)
    );
    uint256 premiumRate = PoolMath.getPremiumRate(
      self.formula,
      utilization
    );

    // Default to ignore remaining time in case we do not enter loop
    uint256 secondsSinceTickStart = remaining;
    uint256 secondsParsed;

    // @bw could opti here by searching for next initialized tick to compute the liquidity index with same premium & utilization in one go, parsing multiple 256 value bitmaps. This should exit when remaining < secondsToNextTickEnd before finishing with the partial tick operation.
    while (slot0.secondsPerTick <= remaining) {
      secondsSinceTickStart = 0;

      // Search for the next tick, either last in bitmap or next initialized
      (uint32 nextTick, bool isInitialized) = self
        .tickBitmap
        .nextTick(slot0.tick);

      uint256 secondsToNextTickEnd = slot0.secondsPerTick *
        (nextTick - slot0.tick);

      if (secondsToNextTickEnd <= remaining) {
        // Remove parsed tick size from remaining time to current timestamp
        remaining -= secondsToNextTickEnd;
        secondsParsed = secondsToNextTickEnd;

        slot0.liquidityIndex += PoolMath.computeLiquidityIndex(
          utilization,
          premiumRate,
          secondsParsed
        );

        // If the tick has covers then update pool metrics
        if (isInitialized) {
          (slot0, utilization, premiumRate) = self
            ._crossingInitializedTick(slot0, nextTick);
        }
        // Pool is now synched at the start of nextTick
        slot0.tick = nextTick;
      } else {
        /**
         * Time bewteen start of the new tick and the current timestamp
         * This is ignored since this is not enough for a full tick to be processed
         */
        secondsSinceTickStart = remaining % slot0.secondsPerTick;
        // Ignore interests of current uncompleted tick
        secondsParsed = remaining - secondsSinceTickStart;
        // Number of complete ticks that we can take into account
        slot0.tick += uint32(secondsParsed / slot0.secondsPerTick);
        // Exit loop after the liquidity index update
        remaining = 0;

        slot0.liquidityIndex += PoolMath.computeLiquidityIndex(
          utilization,
          premiumRate,
          secondsParsed
        );
      }
    }

    // Remove ignored duration so the update aligns with current tick start
    slot0.lastUpdateTimestamp = timestamp_ - secondsSinceTickStart;
  }

  /**
   * @notice Updates the pool's slot0 when the available liquidity changes.
   *
   * @param poolId_ The pool ID
   * @param liquidityToAdd_ The amount of liquidity to add
   * @param liquidityToRemove_ The amount of liquidity to remove
   * @param skipLimitCheck_ Whether to skip the available liquidity check
   *
   * @dev The skipLimitCheck_ is used for deposits & payouts
   */
  function _syncLiquidity(
    uint64 poolId_,
    uint256 liquidityToAdd_,
    uint256 liquidityToRemove_,
    bool skipLimitCheck_
  ) public {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    uint256 liquidity = totalLiquidity(self.poolId);
    uint256 available = availableLiquidity(self.poolId);

    // Skip liquidity check for deposits & payouts
    if (!skipLimitCheck_)
      if (available + liquidityToAdd_ < liquidityToRemove_)
        revert NotEnoughLiquidityForRemoval();

    // uint256 totalCovered = self.slot0.coveredCapital;
    uint256 newTotalLiquidity = (liquidity + liquidityToAdd_) -
      liquidityToRemove_;

    (, self.slot0.secondsPerTick, ) = PoolMath.updatePoolMarket(
      self.formula,
      self.slot0.secondsPerTick,
      liquidity,
      self.slot0.coveredCapital,
      newTotalLiquidity,
      self.slot0.coveredCapital
    );
  }

  // =================================== //
  // ======= COVERS & LP METHODS ======= //
  // =================================== //

  // ======= LIQUIDITY POSITIONS ======= //

  /**
   * @notice Adds liquidity info to the pool and updates the pool's state.
   *
   * @param poolId_ The pool ID
   * @param tokenId_ The LP position token ID
   * @param amount_ The amount of liquidity to deposit
   */
  function _depositToPool(
    uint64 poolId_,
    uint256 tokenId_,
    uint256 amount_
  ) external {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    // Skip liquidity check for deposits
    _syncLiquidity(poolId_, amount_, 0, true);

    // This sets the point from which the position earns rewards & is impacted by claims
    // also overwrites previous LpInfo after a withdrawal
    self.lpInfos[tokenId_] = DataTypes.LpInfo({
      beginLiquidityIndex: self.slot0.liquidityIndex,
      beginClaimIndex: self.compensationIds.length
    });
  }

  /**
   * @notice Pays the rewards and fees to the position owner and the DAO.
   *
   * @param poolId_ The pool ID
   * @param rewards_ The rewards to pay
   * @param account_ The account to pay the rewards to
   * @param yieldBonus_ The yield bonus to apply to the rewards
   * @param nbPools_ The number of pools in the position
   */
  function _payRewardsAndFees(
    uint64 poolId_,
    uint256 rewards_,
    address account_,
    uint256 yieldBonus_,
    uint256 nbPools_
  ) public {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    if (0 < rewards_) {
      uint256 fees = (rewards_ * self.feeRate) / HUNDRED_PERCENT;
      uint256 yieldBonus = (rewards_ *
        (HUNDRED_PERCENT - yieldBonus_)) / HUNDRED_PERCENT;

      uint256 netFees = fees == 0 || fees < yieldBonus
        ? 0
        : fees - yieldBonus;

      uint256 leverageFee;
      if (1 < nbPools_) {
        // The risk fee is only applied when using leverage
        // @dev The leverage fee is per pool so it starts at 2 * leverageFeePerPool
        leverageFee =
          (rewards_ * (self.leverageFeePerPool * nbPools_)) /
          HUNDRED_PERCENT;
      } else if (account_ == address(self.dao)) {
        // Take profits for the DAO accumulate the net in the leverage risk wallet
        leverageFee = rewards_ - netFees;
      }

      uint256 totalFees = netFees + leverageFee;
      // With insane leverage then the user could have a total fee rate above 100%
      uint256 net = rewards_ < totalFees ? 0 : rewards_ - totalFees;

      // Pay position owner
      if (net != 0) {
        IERC20(self.paymentAsset).safeTransfer(account_, net);
      }

      // Pay treasury & leverage risk wallet
      if (totalFees != 0) {
        IERC20(self.paymentAsset).safeTransfer(
          address(self.dao),
          totalFees
        );

        try
          self.dao.accrueRevenue(
            self.paymentAsset,
            netFees,
            leverageFee
          )
        {} catch {
          // Ignore errors in case the DAO contract is not set
        }
      }
    }
  }

  /// -------- TAKE INTERESTS -------- ///

  /**
   * @notice Takes the interests of a position and updates the pool's state.
   *
   * @param poolId_ The pool ID
   * @param tokenId_ The LP position token ID
   * @param account_ The account to pay the rewards to
   * @param supplied_ The amount of liquidity to take interest on
   * @param yieldBonus_ The yield bonus to apply to the rewards
   * @param poolIds_ The pool IDs of the position
   *
   * @return newUserCapital The user's capital after claims
   * @return coverRewards The rewards earned from cover premiums
   *
   * @dev Need to update user capital & payout strategy rewards upon calling this function
   */
  function _takePoolInterests(
    uint64 poolId_,
    uint256 tokenId_,
    address account_,
    uint256 supplied_,
    uint256 strategyRewardIndex_,
    uint256 latestStrategyRewardIndex_,
    uint256 yieldBonus_,
    uint64[] storage poolIds_
  )
    external
    returns (uint256 /*newUserCapital*/, uint256 /*coverRewards*/)
  {
    if (supplied_ == 0) return (0, 0);

    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    // Get the updated position info
    UpdatedPositionInfo memory info = _getUpdatedPositionInfo(
      poolId_,
      poolIds_,
      UpdatePositionParams({
        currentLiquidityIndex: self.slot0.liquidityIndex,
        tokenId: tokenId_,
        userCapital: supplied_,
        strategyRewardIndex: strategyRewardIndex_,
        latestStrategyRewardIndex: latestStrategyRewardIndex_,
        strategyId: self.strategyId,
        itCompounds: self.strategyManager.itCompounds(
          self.strategyId
        ),
        endCompensationId: self.compensationIds.length,
        nbPools: poolIds_.length
      })
    );

    // Pay cover rewards and send fees to treasury
    _payRewardsAndFees(
      poolId_,
      info.coverRewards,
      account_,
      yieldBonus_,
      poolIds_.length
    );

    // Update lp info to reflect the new state of the position
    self.lpInfos[tokenId_] = info.newLpInfo;

    // Return the user's capital & strategy rewards for withdrawal
    return (info.newUserCapital, info.strategyRewards);
  }

  /// -------- WITHDRAW -------- ///

  /**
   * @notice Withdraws liquidity from the pool and updates the pool's state.
   *
   * @param poolId_ The pool ID
   * @param tokenId_ The LP position token ID
   * @param supplied_ The amount of liquidity to withdraw
   * @param poolIds_ The pool IDs of the position
   *
   * @return newUserCapital The user's capital after claims
   * @return strategyRewards The rewards earned by the strategy
   */
  function _withdrawLiquidity(
    uint64 poolId_,
    uint256 tokenId_,
    uint256 supplied_,
    uint256 amount_,
    uint256 strategyRewardIndex_,
    uint256 latestStrategyRewardIndex_,
    uint64[] storage poolIds_
  ) external returns (uint256, uint256) {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    // Get the updated position info
    UpdatedPositionInfo memory info = _getUpdatedPositionInfo(
      poolId_,
      poolIds_,
      UpdatePositionParams({
        currentLiquidityIndex: self.slot0.liquidityIndex,
        tokenId: tokenId_,
        userCapital: supplied_,
        strategyRewardIndex: strategyRewardIndex_,
        latestStrategyRewardIndex: latestStrategyRewardIndex_,
        strategyId: self.strategyId,
        itCompounds: self.strategyManager.itCompounds(
          self.strategyId
        ),
        endCompensationId: self.compensationIds.length,
        nbPools: poolIds_.length
      })
    );

    // Pool rewards after commit are paid in favor of the DAO's leverage risk wallet
    _payRewardsAndFees(
      poolId_,
      info.coverRewards,
      address(self.dao),
      0, // No yield bonus for the DAO
      poolIds_.length
    );

    // Update lp info to reflect the new state of the position
    self.lpInfos[tokenId_] = info.newLpInfo;

    // Update liquidity index
    _syncLiquidity(poolId_, 0, amount_, false);

    // Return the user's capital & strategy rewards for withdrawal
    return (info.newUserCapital, info.strategyRewards);
  }

  // ======= COVERS ======= //

  /// -------- BUY -------- ///

  /**
   * @notice Registers a premium position for a cover,
   * it also initializes the last tick (expiration tick) of the cover is needed.
   *
   * @param self The pool
   * @param coverId_ The cover ID
   * @param beginPremiumRate_ The premium rate at the beginning of the cover
   * @param lastTick_ The last tick of the cover
   */
  function _addPremiumPosition(
    DataTypes.VPool storage self,
    uint256 coverId_,
    uint256 coverAmount_,
    uint256 beginPremiumRate_,
    uint32 lastTick_
  ) internal {
    self.ticks[lastTick_] += coverAmount_;

    self.covers[coverId_] = DataTypes.Cover({
      coverAmount: coverAmount_,
      beginPremiumRate: beginPremiumRate_,
      lastTick: lastTick_
    });

    /**
     * If the tick at which the cover expires is not initialized then initialize it
     * this indicates that the tick is not empty and has covers that expire
     */
    if (!self.tickBitmap.isInitializedTick(lastTick_)) {
      self.tickBitmap.flipTick(lastTick_);
    }
  }

  /**
   * @notice Registers a premium position of a cover and updates the pool's slot0.
   *
   * @param poolId_ The pool ID
   * @param coverId_ The cover ID
   * @param coverAmount_ The amount of cover to buy
   * @param premiums_ The amount of premiums deposited
   */
  function _registerCover(
    uint64 poolId_,
    uint256 coverId_,
    uint256 coverAmount_,
    uint256 premiums_
  ) external {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    // @bw could compute amount of time lost to rounding and conseqentially the amount of premiums lost, then register them to be able to harvest them / redistrib them
    uint256 available = availableLiquidity(self.poolId);

    /**
     * Check if pool has enough liquidity, when updating a cover
     * we closed the previous cover at this point so check for total
     * */
    if (available < coverAmount_) revert InsufficientCapacity();

    uint256 liquidity = totalLiquidity(self.poolId);

    (uint256 newPremiumRate, uint256 newSecondsPerTick, ) = PoolMath
      .updatePoolMarket(
        self.formula,
        self.slot0.secondsPerTick,
        liquidity,
        self.slot0.coveredCapital,
        liquidity,
        self.slot0.coveredCapital + coverAmount_
      );

    uint256 durationInSeconds = (premiums_ * YEAR * PERCENTAGE_BASE)
      .rayDiv(newPremiumRate) / coverAmount_;

    if (durationInSeconds < newSecondsPerTick)
      revert DurationBelowOneTick();

    /**
     * @dev The user can loose up to almost 1 tick of cover due to the floored division
     * The user can also win up to almost 1 tick of cover if it is opened at the start of a tick
     */
    uint256 tickDuration = durationInSeconds / newSecondsPerTick;
    // Check for overflow in case the cover amount is very low
    if (type(uint32).max < tickDuration) revert DurationOverflow();

    uint32 lastTick = self.slot0.tick + uint32(tickDuration);

    self._addPremiumPosition(
      coverId_,
      coverAmount_,
      newPremiumRate,
      lastTick
    );

    self.slot0.coveredCapital += coverAmount_;
    self.slot0.secondsPerTick = newSecondsPerTick;
  }

  /// -------- CLOSE -------- ///

  /**
   * @notice Closes a cover and updates the pool's slot0.
   *
   * @param poolId_ The pool ID
   * @param coverId_ The cover ID
   */
  function _closeCover(uint64 poolId_, uint256 coverId_) external {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    DataTypes.Cover memory cover = self.covers[coverId_];

    // Remove cover amount from the tick at which it expires
    uint256 coverAmount = cover.coverAmount;
    self.ticks[cover.lastTick] -= coverAmount;

    // If there is no more cover in the tick then flip it to uninitialized
    if (self.ticks[cover.lastTick] == 0) {
      self.tickBitmap.flipTick(cover.lastTick);
    }

    uint256 liquidity = totalLiquidity(self.poolId);

    (, self.slot0.secondsPerTick, ) = PoolMath.updatePoolMarket(
      self.formula,
      self.slot0.secondsPerTick,
      liquidity,
      self.slot0.coveredCapital,
      liquidity,
      self.slot0.coveredCapital - coverAmount
    );

    self.slot0.coveredCapital -= coverAmount;

    // @dev We remove 1 since the covers expire at the end of the tick
    self.covers[coverId_].lastTick = self.slot0.tick - 1;
  }

  // ======= INTERNAL POOL HELPERS ======= //

  /**
   * @notice Purges expired covers from the pool and updates the pool's slot0 up to the latest timestamp
   *
   * @param poolId_ The pool ID
   *
   * @dev function _purgeExpiredCoversUpTo
   */
  function _purgeExpiredCovers(uint64 poolId_) external {
    _purgeExpiredCoversUpTo(poolId_, block.timestamp);
  }

  /**
   * @notice Removes expired covers from the pool and updates the pool's slot0.
   * Required before any operation that requires the slot0 to be up to date.
   * This includes all position and cover operations.
   *
   * @param poolId_ The pool ID
   */
  function _purgeExpiredCoversUpTo(
    uint64 poolId_,
    uint256 timestamp_
  ) public {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);
    self.slot0 = _refreshSlot0(poolId_, timestamp_);
  }

  // ======= VIEW HELPERS ======= //

  /**
   * @notice Checks if a cover is active or if it has expired or been closed
   * @dev The user is protected during lastTick but the cover cannot be updated
   *
   * @param poolId_ The pool ID
   * @param coverId_ The cover ID
   *
   * @return Whether the cover is active
   */
  function _isCoverActive(
    uint64 poolId_,
    uint256 coverId_
  ) external view returns (bool) {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    return self.slot0.tick < self.covers[coverId_].lastTick;
  }

  /**
   * @notice Computes the cover and strategy rewards for an LP position.
   *
   * @param self The pool
   * @param info The updated position information
   * @param coverRewards The current rewards earned from cover premiums
   * @param strategyRewards The current rewards earned by the strategy
   * @param strategyId The strategy ID
   * @param itCompounds Whether the strategy compounds
   * @param endliquidityIndex The end liquidity index
   * @param startStrategyRewardIndex The start strategy reward index
   * @param endStrategyRewardIndex The end strategy reward index
   *
   * @return coverRewards The aggregated rewards earned from cover premiums
   * @return strategyRewards The aggregated rewards earned by the strategy
   */
  function computePositionRewards(
    DataTypes.VPool storage self,
    UpdatedPositionInfo memory info,
    uint256 coverRewards,
    uint256 strategyRewards,
    uint256 strategyId,
    bool itCompounds,
    uint256 endliquidityIndex,
    uint256 startStrategyRewardIndex,
    uint256 endStrategyRewardIndex
  )
    internal
    view
    returns (
      uint256 /* coverRewards */,
      uint256 /* strategyRewards */
    )
  {
    coverRewards += PoolMath.getCoverRewards(
      info.newUserCapital,
      info.newLpInfo.beginLiquidityIndex,
      endliquidityIndex
    );

    strategyRewards += self.strategyManager.computeReward(
      strategyId,
      // If strategy compounds then add to capital to compute next new rewards
      itCompounds
        ? info.newUserCapital + info.strategyRewards
        : info.newUserCapital,
      startStrategyRewardIndex,
      endStrategyRewardIndex
    );

    return (coverRewards, strategyRewards);
  }

  /**
   * @notice Computes the state changes of an LP position,
   * it aggregates the fees earned by the position and
   * computes the losses incurred by the claims in this pool.
   *
   * @param poolId_ The pool ID
   * @param poolIds_ The pool IDs of the position
   * @param params The update position parameters
   * - currentLiquidityIndex_ The current liquidity index
   * - tokenId_ The LP position token ID
   * - userCapital_ The user's capital
   * - strategyRewardIndex_ The strategy reward index
   * - latestStrategyRewardIndex_ The latest strategy reward index
   *
   * @return info Updated information about the position:
   * - newUserCapital The user's capital after claims
   * - coverRewards The rewards earned from cover premiums
   * - strategyRewards The rewards earned by the strategy
   * - newLpInfo The updated LpInfo of the position
   *
   * @dev Used for takeInterest, withdrawLiquidity and rewardsOf
   */
  function _getUpdatedPositionInfo(
    uint64 poolId_,
    uint64[] storage poolIds_,
    UpdatePositionParams memory params
  ) public view returns (UpdatedPositionInfo memory info) {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    // Make copy of current LP info state for position
    info.newLpInfo = self.lpInfos[params.tokenId];
    info.newUserCapital = params.userCapital;

    // This index is not bubbled up in info because it is updated by the LiquidityManager
    // @dev Left unitilized because _processCompensationsForPosition will update it event with no compensations
    uint256 upToStrategyRewardIndex;

    (
      info,
      upToStrategyRewardIndex
    ) = _processCompensationsForPosition(poolId_, poolIds_, params);

    /**
     * Finally add the rewards from the last claim or update to the current block
     * & register latest reward & claim indexes
     */
    (info.coverRewards, info.strategyRewards) = self
      .computePositionRewards(
        info,
        info.coverRewards,
        info.strategyRewards,
        params.strategyId,
        params.itCompounds,
        params.currentLiquidityIndex,
        upToStrategyRewardIndex,
        params.latestStrategyRewardIndex
      );

    // Register up to where the position has been updated
    // @dev
    info.newLpInfo.beginLiquidityIndex = params.currentLiquidityIndex;
    info.newLpInfo.beginClaimIndex = params.endCompensationId;
  }

  /**
   * @notice Updates the capital in an LP position post compensation payouts.
   *
   * @param poolId_ The pool ID
   * @param poolIds_ The pool IDs of the position
   * @param params The update position parameters
   *
   * @return info Updated information about the position:
   * @return upToStrategyRewardIndex The latest strategy reward index
   */
  function _processCompensationsForPosition(
    uint64 poolId_,
    uint64[] storage poolIds_,
    UpdatePositionParams memory params
  )
    public
    view
    returns (
      UpdatedPositionInfo memory info,
      uint256 upToStrategyRewardIndex
    )
  {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    info.newLpInfo = self.lpInfos[params.tokenId];
    info.newUserCapital = params.userCapital;

    // This index is not bubbled up in info because it is updated by the LiquidityManager
    upToStrategyRewardIndex = params.strategyRewardIndex;
    uint256 compensationId = info.newLpInfo.beginClaimIndex;

    /**
     * Parse each claim that may affect capital due to overlap in order to
     * compute rewards on post compensation capital
     */
    for (
      compensationId;
      compensationId < params.endCompensationId;
      compensationId++
    ) {
      DataTypes.Compensation storage comp = getCompensation(
        compensationId
      );

      // For each pool in the position
      for (uint256 j; j < params.nbPools; j++) {
        // Skip if the comp is not incoming from one of the pools in the position
        if (poolIds_[j] != comp.fromPoolId) continue;

        // We want the liquidity index of this pool at the time of the claim
        uint256 liquidityIndexBeforeClaim = comp
          .liquidityIndexBeforeClaim[self.poolId];

        // Compute the rewards accumulated up to the claim
        (info.coverRewards, info.strategyRewards) = self
          .computePositionRewards(
            info,
            info.coverRewards,
            info.strategyRewards,
            params.strategyId,
            params.itCompounds,
            liquidityIndexBeforeClaim,
            upToStrategyRewardIndex,
            comp.strategyRewardIndexBeforeClaim
          );

        info
          .newLpInfo
          .beginLiquidityIndex = liquidityIndexBeforeClaim;
        // Reduce capital after the comp
        info.newUserCapital -= info.newUserCapital.rayMul(comp.ratio);

        // Register up to where the rewards have been accumulated
        upToStrategyRewardIndex = comp.strategyRewardIndexBeforeClaim;

        break;
      }
    }

    // Register up to where the position has been updated
    info.newLpInfo.beginClaimIndex = params.endCompensationId;
  }

  /**
   * @notice Computes the updated state of a cover.
   *
   * @param poolId_ The pool ID
   * @param coverId_ The cover ID
   *
   * @return info The cover data
   */
  function _computeRefreshedCoverInfo(
    uint64 poolId_,
    uint256 coverId_
  ) external view returns (CoverInfo memory info) {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    return
      self._computeCoverInfo(
        coverId_,
        // For reads we sync the slot0 to the current timestamp to have latests data
        _refreshSlot0(poolId_, block.timestamp)
      );
  }

  /**
   * @notice Returns the current state of a cover.
   *
   * @param poolId_ The pool ID
   * @param coverId_ The cover ID
   *
   * @return info The cover data
   */
  function _computeCurrentCoverInfo(
    uint64 poolId_,
    uint256 coverId_
  ) external view returns (CoverInfo memory info) {
    DataTypes.VPool storage self = VirtualPool.getPool(poolId_);

    return self._computeCoverInfo(coverId_, self.slot0);
  }

  /**
   * @notice Computes the premium rate & daily cost of a cover,
   * this parses the pool's ticks to compute how much premiums are left and
   * what is the daily cost of keeping the cover openened.
   *
   * @param self The pool
   * @param coverId_ The cover ID
   *
   * @return info A struct containing the cover's premium rate & the cover's daily cost
   */
  function _computeCoverInfo(
    DataTypes.VPool storage self,
    uint256 coverId_,
    DataTypes.Slot0 memory slot0_
  ) internal view returns (CoverInfo memory info) {
    DataTypes.Cover storage cover = self.covers[coverId_];

    /**
     * If the cover's last tick is overtaken then it's expired & no premiums are left.
     * Return default 0 / false values in the returned struct.
     */
    if (cover.lastTick < slot0_.tick) return info;

    info.isActive = true;

    info.premiumRate = PoolMath.getPremiumRate(
      self.formula,
      PoolMath._utilization(
        slot0_.coveredCapital,
        totalLiquidity(self.poolId)
      )
    );

    /// @dev Skip division by premium rate PERCENTAGE_BASE for precision
    uint256 beginDailyCost = cover
      .coverAmount
      .rayMul(cover.beginPremiumRate)
      .rayDiv(365);
    info.dailyCost = PoolMath.getDailyCost(
      beginDailyCost,
      cover.beginPremiumRate,
      info.premiumRate
    );

    uint256 nbTicksLeft = cover.lastTick - slot0_.tick;
    // Duration in seconds between currentTick & minNextTick
    uint256 duration = nbTicksLeft * slot0_.secondsPerTick;

    /// @dev Unscale amount by PERCENTAGE_BASE & RAY
    info.premiumsLeft =
      (duration * info.dailyCost) /
      (1 days * PERCENTAGE_BASE * RAY);
    /// @dev Unscale amount by PERCENTAGE_BASE & RAY
    info.dailyCost = info.dailyCost / (PERCENTAGE_BASE * RAY);
  }

  /**
   * @notice Mutates a slot0 to reflect states changes upon crossing an initialized tick.
   * The covers crossed tick are expired and the pool's liquidity is updated.
   *
   * @dev It must be mutative so it can be used by read & write fns.
   *
   * @param self The pool
   * @param slot0_ The slot0 to mutate
   * @param tick_ The tick to cross
   *
   * @return The mutated slot0
   */
  function _crossingInitializedTick(
    DataTypes.VPool storage self,
    DataTypes.Slot0 memory slot0_,
    uint32 tick_
  )
    internal
    view
    returns (
      DataTypes.Slot0 memory /* slot0_ */,
      uint256 utilization,
      uint256 premiumRate
    )
  {
    uint256 liquidity = totalLiquidity(self.poolId);
    // Remove expired cover amount from the pool's covered capital
    uint256 newCoveredCapital = slot0_.coveredCapital -
      self.ticks[tick_];

    (premiumRate, slot0_.secondsPerTick, utilization) = PoolMath
      .updatePoolMarket(
        self.formula,
        self.slot0.secondsPerTick,
        liquidity,
        self.slot0.coveredCapital,
        liquidity,
        newCoveredCapital
      );

    // Remove expired cover amount from the pool's covered capital
    slot0_.coveredCapital = newCoveredCapital;

    return (slot0_, utilization, premiumRate);
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

// Contracts
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// Libraries
import { AthenaDataProvider } from "../misc/AthenaDataProvider.sol";
import { RayMath } from "../libs/RayMath.sol";
import { VirtualPool } from "../libs/VirtualPool.sol";
import { DataTypes } from "../libs/DataTypes.sol";
import { ReentrancyGuard } from "../libs/ReentrancyGuard.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Interfaces
import { ILiquidityManager } from "../interfaces/ILiquidityManager.sol";
import { IStrategyManager } from "../interfaces/IStrategyManager.sol";
import { IEcclesiaDao } from "../interfaces/IEcclesiaDao.sol";
import { IAthenaPositionToken } from "../interfaces/IAthenaPositionToken.sol";
import { IAthenaCoverToken } from "../interfaces/IAthenaCoverToken.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// ======= ERRORS ======= //

error OnlyTokenOwner();
error OnlyClaimManager();
error OnlyYieldRewarder();
error PoolDoesNotExist();
error PoolIsPaused();
error PoolIdsMustBeUniqueAndAscending();
error PoolCannotBeCompatibleWithItself();
error PoolIdsAreCannotBeMatched(uint64 poolIdA, uint64 poolIdB);
error AmountOfPoolsIsAboveMaxLeverage();
error IncompatiblePools(uint64 poolIdA, uint64 poolIdB);
error WithdrawCommitDelayNotReached();
error RatioAbovePoolCapacity();
error CoverIsExpired();
error NotEnoughPremiums();
error CannotUpdateCommittedPosition();
error CannotTakeInterestsCommittedPosition();
error CannotIncreaseCommittedPosition();
error PositionNotCommited();
error SenderNotLiquidityManager();
error PoolHasOnGoingClaims();
error ForbiddenZeroValue();
error MustPurgeExpiredTokenInTheFuture();
error InsufficientLiquidityForWithdrawal();
error OutOfBounds();

contract LiquidityManager is
  ILiquidityManager,
  ReentrancyGuard,
  Ownable
{
  // ======= LIBRARIES ======= //

  using SafeERC20 for IERC20;
  using RayMath for uint256;
  using VirtualPool for DataTypes.VPool;

  // ======= STORAGE ======= //

  IAthenaPositionToken public positionToken;
  IAthenaCoverToken public coverToken;
  IEcclesiaDao public ecclesiaDao;
  IStrategyManager public strategyManager;
  address public claimManager;
  address public yieldRewarder;

  /// The delay after commiting before a position can be withdrawn
  uint256 public withdrawDelay; // in seconds
  /// The maximum amount of pools a position can supply liquidity to
  uint256 public maxLeverage;
  /// The fee paid out to the DAO for each leveraged pool in a position
  uint256 public leverageFeePerPool; // Ray
  // Maps pool0 -> pool1 -> areCompatible for LP leverage
  mapping(uint64 => mapping(uint64 => bool)) public arePoolCompatible;

  /// Maps a cover ID to the ID of the pool storing the cover data
  mapping(uint256 _id => uint64 _poolId) public coverToPool;

  /// User LP data
  mapping(uint256 _id => Position) public _positions;

  /// The ID of the next claim to be
  uint256 public nextCompensationId;

  /// The token ID position data
  uint64 public nextPoolId;
  /// Maps a pool ID to the virtualized pool's storage
  mapping(uint64 _id => DataTypes.VPool) internal _pools;

  // ======= CONSTRUCTOR ======= //

  constructor(
    IAthenaPositionToken positionToken_,
    IAthenaCoverToken coverToken_,
    IEcclesiaDao ecclesiaDao_,
    IStrategyManager strategyManager_,
    address claimManager_,
    address yieldRewarder_,
    uint256 withdrawDelay_,
    uint256 maxLeverage_,
    uint256 leverageFeePerPool_
  ) Ownable(msg.sender) {
    positionToken = positionToken_;
    coverToken = coverToken_;

    ecclesiaDao = ecclesiaDao_;
    strategyManager = strategyManager_;
    claimManager = claimManager_;
    yieldRewarder = yieldRewarder_;

    withdrawDelay = withdrawDelay_;
    maxLeverage = maxLeverage_;
    leverageFeePerPool = leverageFeePerPool_;
  }

  // ======= EVENTS ======= //

  /// @notice Emitted when a new pool is created
  event PoolCreated(uint64 indexed poolId);

  /// @notice Emitted when a position is opened
  event PositionOpenned(uint256 indexed positionId);
  /// @notice Emitted when a position's liquidity is updated
  event InterestsTaken(uint256 indexed positionId);
  /// @notice Emitted when a position's liquidity is updated
  event PositionLiquidityUpdated(
    uint256 indexed positionId,
    uint256 amountAdded,
    uint256 amountRemoved
  );

  /// @notice Emits when a new cover is bought
  event CoverOpenned(uint64 indexed poolId, uint256 indexed coverId);
  /// @notice Emits when a cover is updated
  event CoverUpdated(uint256 indexed coverId);
  /// @notice Emits when a cover is closed
  event CoverClosed(uint256 indexed coverId);

  /// @notice Compensation is paid out for a claim
  event CompensationPaid(
    uint256 indexed poolId,
    uint256 indexed compensationId
  );

  /// ======= INTERNAL HELPERS ======= ///

  /**
   * @notice Throws if the pool does not exist
   * @param poolId_ The ID of the pool
   */
  function _checkPoolExists(uint64 poolId_) internal view {
    // We use the underlying asset since it cannot be address(0)
    if (VirtualPool.getPool(poolId_).underlyingAsset == address(0))
      revert PoolDoesNotExist();
  }

  /**
   * @notice Throws if the pool is paused
   * @param poolId_ The ID of the pool
   *
   * @dev You cannot buy cover, increase cover or add liquidity in a paused pool
   */
  function _checkIsNotPaused(uint64 poolId_) internal view {
    if (VirtualPool.getPool(poolId_).isPaused) revert PoolIsPaused();
  }

  /// ======= MODIFIERS ======= ///

  /**
   * @notice Throws if the caller is not the owner of the cover token
   * @param coverId_ The ID of the cover token
   */
  modifier onlyCoverOwner(uint256 coverId_) {
    if (msg.sender != coverToken.ownerOf(coverId_))
      revert OnlyTokenOwner();
    _;
  }

  /**
   * @notice Throws if the caller is not the owner of the position token
   * @param positionId_ The ID of the position token
   */
  modifier onlyPositionOwner(uint256 positionId_) {
    if (msg.sender != positionToken.ownerOf(positionId_))
      revert OnlyTokenOwner();
    _;
  }

  /**
   * @notice Throws if the caller is not the claim manager
   * @dev The claim manager is the contract that creates claims
   */
  modifier onlyClaimManager() {
    if (msg.sender != claimManager) revert OnlyClaimManager();
    _;
  }

  /**
   * @notice Throws if the caller is not the reward authority for yield bonuses
   */
  modifier onlyYieldRewarder() {
    if (msg.sender != address(yieldRewarder))
      revert OnlyYieldRewarder();
    _;
  }

  /// ======= VIEWS ======= ///

  function positions(
    uint256 tokenId_
  ) external view returns (Position memory) {
    return _positions[tokenId_];
  }

  /**
   * @notice Returns the up to date position data of a token
   * @param positionId_ The ID of the position
   * @return The position data
   */
  function positionInfo(
    uint256 positionId_
  ) external view returns (PositionRead memory) {
    Position storage position = _positions[positionId_];
    return AthenaDataProvider.positionInfo(position, positionId_);
  }

  /**
   * @notice Returns the up to date cover data of a token
   * @param coverId_ The ID of the cover
   * @return The cover data formatted for reading
   */
  function coverInfo(
    uint256 coverId_
  ) external view returns (CoverRead memory) {
    return AthenaDataProvider.coverInfo(coverId_);
  }

  /**
   * @notice Returns the virtual pool's storage
   * @param poolId_ The ID of the pool
   * @return The virtual pool's storage
   */
  function poolInfo(
    uint64 poolId_
  ) external view returns (VPoolRead memory) {
    return AthenaDataProvider.poolInfo(poolId_);
  }

  /**
   * @notice Returns the up to date data of an array of positions
   * @param positionIds The IDs of the positions
   * @return The positions data
   *
   * @dev Moved to LiquidityManager since cannot pass array of storage pointers in memory
   */
  function positionInfos(
    uint256[] calldata positionIds
  ) external view returns (ILiquidityManager.PositionRead[] memory) {
    ILiquidityManager.PositionRead[]
      memory result = new ILiquidityManager.PositionRead[](
        positionIds.length
      );

    for (uint256 i; i < positionIds.length; i++) {
      // Parse IDs here since we cannot make an array of storage pointers in memory
      Position storage position = _positions[positionIds[i]];
      result[i] = AthenaDataProvider.positionInfo(
        position,
        positionIds[i]
      );
    }

    return result;
  }

  /**
   * @notice Returns up to date data for an array of covers
   * @param coverIds The IDs of the covers
   * @return The array of covers data
   */
  function coverInfos(
    uint256[] calldata coverIds
  ) external view returns (ILiquidityManager.CoverRead[] memory) {
    return AthenaDataProvider.coverInfos(coverIds);
  }

  /**
   * @notice Returns up to date data for an array of pools
   * @param poolIds The IDs of the pools
   * @return The array of pools data
   */
  function poolInfos(
    uint256[] calldata poolIds
  ) external view returns (ILiquidityManager.VPoolRead[] memory) {
    return AthenaDataProvider.poolInfos(poolIds);
  }

  /**
   * @notice Returns if the cover is still active or has expired
   * @param coverId_ The ID of the cover
   * @return True if the cover is still active, otherwise false
   */
  function isCoverActive(
    uint256 coverId_
  ) public view returns (bool) {
    return
      VirtualPool._isCoverActive(coverToPool[coverId_], coverId_);
  }

  /**
   * @notice Returns amount liquidity overlap between two pools
   * @param poolIdA_ The ID of the first pool
   * @param poolIdB_ The ID of the second pool
   * @return The amount of liquidity overlap
   *
   * @dev The overlap is always stored in the pool with the lowest ID
   * @dev The overlap if poolA = poolB is the pool's liquidity
   */
  function poolOverlaps(
    uint64 poolIdA_,
    uint64 poolIdB_
  ) public view returns (uint256) {
    return
      poolIdA_ < poolIdB_
        ? VirtualPool.getPool(poolIdA_).overlaps[poolIdB_]
        : VirtualPool.getPool(poolIdB_).overlaps[poolIdA_];
  }

  /// ======= POOLS ======= ///

  /**
   * @notice Creates a new pool, combining a cover product with a strategy
   * @param paymentAsset_ The asset used to pay for premiums
   * @param strategyId_ The ID of the strategy to be used
   * @param feeRate_ The fee rate paid out to the DAO
   * @param uOptimal_ The optimal utilization rate
   * @param r0_ The base interest rate
   * @param rSlope1_ The initial slope of the interest rate curve
   * @param rSlope2_ The slope of the interest rate curve above uOptimal
   * @param compatiblePools_ An array of pool IDs that are compatible with the new pool
   */
  function createPool(
    address paymentAsset_,
    uint256 strategyId_,
    uint256 feeRate_,
    uint256 uOptimal_,
    uint256 r0_,
    uint256 rSlope1_,
    uint256 rSlope2_,
    uint64[] calldata compatiblePools_
  ) external onlyOwner {
    // Save pool ID to memory and update for next
    uint64 poolId = nextPoolId;
    nextPoolId++;

    // Create virtual pool
    VirtualPool._vPoolConstructor(
      // Create virtual pool argument struct
      DataTypes.VPoolConstructorParams({
        poolId: poolId,
        dao: ecclesiaDao,
        strategyManager: strategyManager,
        strategyId: strategyId_,
        paymentAsset: paymentAsset_,
        feeRate: feeRate_, //Ray
        leverageFeePerPool: leverageFeePerPool, //Ray
        uOptimal: uOptimal_, //Ray
        r0: r0_, //Ray
        rSlope1: rSlope1_, //Ray
        rSlope2: rSlope2_ //Ray
      })
    );

    // Add compatible pools
    uint256 nbPools = compatiblePools_.length;
    for (uint256 i; i < nbPools; i++) {
      uint64 compatiblePoolId = compatiblePools_[i];

      if (poolId == compatiblePoolId)
        revert PoolCannotBeCompatibleWithItself();

      // Register in the lowers pool ID to avoid redundant storage
      if (poolId < compatiblePoolId) {
        arePoolCompatible[poolId][compatiblePoolId] = true;
      } else {
        arePoolCompatible[compatiblePoolId][poolId] = true;
      }
    }

    emit PoolCreated(poolId);
  }

  /// ======= MAKE LP POSITION ======= ///

  /**
   * @notice Creates a new LP position
   * @param amount The amount of tokens to supply
   * @param isWrapped True if the user can & wants to provide strategy tokens
   * @param poolIds The IDs of the pools to provide liquidity to
   *
   * @dev Wrapped tokens are tokens representing a position in a strategy,
   * it allows the user to reinvest DeFi liquidity without having to withdraw
   * @dev Positions created after claim creation & before compensation are affected by the claim
   */
  function openPosition(
    uint256 amount,
    bool isWrapped,
    uint64[] calldata poolIds
  ) external nonReentrant {
    if (poolIds.length == 0 || amount == 0)
      revert ForbiddenZeroValue();
    // Check that the amount of pools is below the max leverage
    if (maxLeverage < poolIds.length)
      revert AmountOfPoolsIsAboveMaxLeverage();

    // Mint position NFT
    uint256 positionId = positionToken.mint(msg.sender);

    // All pools share the same strategy so we can use the first pool ID
    uint256 strategyId = VirtualPool.getPool(poolIds[0]).strategyId;
    uint256 amountUnderlying = isWrapped
      ? strategyManager.wrappedToUnderlying(strategyId, amount)
      : amount;

    // Check pool compatibility & underlying token then register overlapping capital
    _addOverlappingCapitalAfterCheck(
      poolIds,
      positionId,
      amountUnderlying,
      true // Purge pools
    );

    // Push funds to strategy manager
    if (isWrapped) {
      address wrappedAsset = VirtualPool
        .getPool(poolIds[0])
        .wrappedAsset;
      IERC20(wrappedAsset).safeTransferFrom(
        msg.sender,
        address(strategyManager),
        amount
      );

      strategyManager.depositWrappedToStrategy(strategyId);
    } else {
      address underlyingAsset = VirtualPool
        .getPool(poolIds[0])
        .underlyingAsset;
      IERC20(underlyingAsset).safeTransferFrom(
        msg.sender,
        address(strategyManager),
        amount
      );

      strategyManager.depositToStrategy(strategyId, amount);
    }

    _positions[positionId] = Position({
      supplied: amountUnderlying,
      commitWithdrawalTimestamp: 0,
      poolIds: poolIds,
      // Save index from which the position will start accruing strategy rewards
      strategyRewardIndex: strategyManager.getRewardIndex(strategyId)
    });

    emit PositionOpenned(positionId);
  }

  /// ======= UPDATE LP POSITION ======= ///

  /**
   * @notice Increases the position's provided liquidity
   * @param positionId_ The ID of the position
   * @param amount The amount of tokens to supply
   * @param isWrapped True if the user can & wants to provide strategy tokens
   *
   * @dev Wrapped tokens are tokens representing a position in a strategy,
   * it allows the user to reinvest DeFi liquidity without having to withdraw
   */
  function addLiquidity(
    uint256 positionId_,
    uint256 amount,
    bool isWrapped
  ) external onlyPositionOwner(positionId_) nonReentrant {
    Position storage position = _positions[positionId_];
    uint256 strategyId = VirtualPool
      .getPool(position.poolIds[0])
      .strategyId;

    if (amount == 0) revert ForbiddenZeroValue();
    // Positions that are commit for withdrawal cannot be increased
    if (position.commitWithdrawalTimestamp != 0)
      revert CannotIncreaseCommittedPosition();

    // Take interests in all pools before update
    // @dev Needed to register rewards & claims impact on capital
    _takeInterests(
      positionId_,
      positionToken.ownerOf(positionId_),
      0
    );

    uint256 amountUnderlying = isWrapped
      ? strategyManager.wrappedToUnderlying(strategyId, amount)
      : amount;

    // Check pool compatibility & underlying position then register overlapping capital
    _addOverlappingCapitalAfterCheck(
      position.poolIds,
      positionId_,
      amountUnderlying,
      false // Pools purged when taking interests
    );

    // Push funds to strategy manager
    if (isWrapped) {
      address wrappedAsset = VirtualPool
        .getPool(position.poolIds[0])
        .wrappedAsset;
      IERC20(wrappedAsset).safeTransferFrom(
        msg.sender,
        address(strategyManager),
        amount
      );

      strategyManager.depositWrappedToStrategy(strategyId);
    } else {
      address underlyingAsset = VirtualPool
        .getPool(position.poolIds[0])
        .underlyingAsset;
      IERC20(underlyingAsset).safeTransferFrom(
        msg.sender,
        address(strategyManager),
        amount
      );

      strategyManager.depositToStrategy(strategyId, amount);
    }

    // Update the position's capital
    position.supplied += amountUnderlying;
  }

  /// ======= TAKE LP INTERESTS ======= ///

  /**
   * @notice Takes the interests of a position
   * @param positionId_ The ID of the position
   * @param coverRewardsBeneficiary_ The address to send the cover rewards to
   * @param yieldBonus_ The yield bonus to apply
   */
  function _takeInterests(
    uint256 positionId_,
    address coverRewardsBeneficiary_,
    uint256 yieldBonus_
  ) private {
    Position storage position = _positions[positionId_];

    // Locks interests to avoid abusively early withdrawal commits
    if (position.commitWithdrawalTimestamp != 0)
      revert CannotTakeInterestsCommittedPosition();

    // All pools have same strategy since they are compatible
    uint256 latestStrategyRewardIndex = strategyManager
      .getRewardIndex(
        VirtualPool.getPool(position.poolIds[0]).strategyId
      );
    address posOwner = positionToken.ownerOf(positionId_);

    uint256 newUserCapital;
    uint256 strategyRewards;

    uint256 nbPools = position.poolIds.length;
    for (uint256 i; i < nbPools; i++) {
      // Clean pool from expired covers
      VirtualPool._purgeExpiredCovers(position.poolIds[i]);

      // These are the same values at each iteration
      (newUserCapital, strategyRewards) = VirtualPool
        ._takePoolInterests(
          position.poolIds[i],
          positionId_,
          coverRewardsBeneficiary_,
          position.supplied,
          position.strategyRewardIndex,
          latestStrategyRewardIndex,
          yieldBonus_,
          position.poolIds
        );
    }

    // All pools have same strategy since they are compatible
    uint256 strategyId = VirtualPool
      .getPool(position.poolIds[0])
      .strategyId;

    // Withdraw interests from strategy
    strategyManager.withdrawFromStrategy(
      strategyId,
      0, // No capital withdrawn
      strategyRewards,
      posOwner, // Always paid out to owner
      yieldBonus_
    );

    // Save index up to which the position has received strategy rewards
    position.strategyRewardIndex = latestStrategyRewardIndex;
    // Update the position capital to reflect potential reduction due to claims
    position.supplied = newUserCapital;

    emit InterestsTaken(positionId_);
  }

  /**
   * @notice Takes the interests of a position
   * @param positionId_ The ID of the position
   */
  function takeInterests(
    uint256 positionId_
  ) public onlyPositionOwner(positionId_) nonReentrant {
    _takeInterests(
      positionId_,
      positionToken.ownerOf(positionId_),
      0
    );
  }

  /**
   * @notice Takes the interests of a position taking into account the user yield bonus
   * @param account_ The address of the account
   * @param yieldBonus_ The yield bonus to apply
   * @param positionIds_ The IDs of the positions
   *
   * @dev This function is only callable by the yield bonus authority
   */
  function takeInterestsWithYieldBonus(
    address account_,
    uint256 yieldBonus_,
    uint256[] calldata positionIds_
  ) external onlyYieldRewarder {
    uint256 nbPositions = positionIds_.length;
    for (uint256 i; i < nbPositions; i++) {
      _takeInterests(positionIds_[i], account_, yieldBonus_);
    }
  }

  /// ======= CLOSE LP POSITION ======= ///

  /**
   * @notice Commits to withdraw the position's liquidity
   * @param positionId_ The ID of the position
   *
   * @dev Ongoing claims must be resolved before being able to commit
   * @dev Interests earned between the commit and the withdrawal are sent to the DAO
   */
  function commitRemoveLiquidity(
    uint256 positionId_
  ) external onlyPositionOwner(positionId_) nonReentrant {
    Position storage position = _positions[positionId_];

    for (uint256 i; i < position.poolIds.length; i++) {
      DataTypes.VPool storage pool = VirtualPool.getPool(
        position.poolIds[i]
      );
      // Cannot commit to withdraw while there are ongoing claims
      if (0 < pool.ongoingClaims) revert PoolHasOnGoingClaims();
    }

    // Take interests in all pools before withdrawal
    // @dev Any rewards accrued after this point will be send to the leverage risk wallet
    _takeInterests(
      positionId_,
      positionToken.ownerOf(positionId_),
      0
    );

    // Register the commit timestamp
    position.commitWithdrawalTimestamp = block.timestamp;
  }

  /**
   * @notice Cancels a position's commit to withdraw its liquidity
   * @param positionId_ The ID of the position
   *
   * @dev This redirects interest back to the position owner
   */
  function uncommitRemoveLiquidity(
    uint256 positionId_
  ) external onlyPositionOwner(positionId_) nonReentrant {
    Position storage position = _positions[positionId_];

    // Avoid users accidentally paying their rewards to the leverage risk wallet
    if (position.commitWithdrawalTimestamp == 0)
      revert PositionNotCommited();

    position.commitWithdrawalTimestamp = 0;

    // Pool rewards after commit are paid in favor of the DAO's leverage risk wallet
    _takeInterests(positionId_, address(ecclesiaDao), 0);
  }

  /**
   * @notice Closes a position and withdraws its liquidity
   * @param positionId_ The ID of the position
   * @param keepWrapped_ True if the user wants to keep the strategy tokens
   *
   * @dev The position must be committed and the delay elapsed to withdrawal
   * @dev Interests earned between the commit and the withdrawal are sent to the DAO
   */
  function removeLiquidity(
    uint256 positionId_,
    uint256 amount_,
    bool keepWrapped_
  ) external onlyPositionOwner(positionId_) nonReentrant {
    Position storage position = _positions[positionId_];

    if (amount_ == 0) revert ForbiddenZeroValue();

    // Check that commit delay has been reached
    if (position.commitWithdrawalTimestamp == 0)
      revert PositionNotCommited();
    if (
      block.timestamp <
      position.commitWithdrawalTimestamp + withdrawDelay
    ) revert WithdrawCommitDelayNotReached();

    // All pools have same strategy since they are compatible
    uint256 latestStrategyRewardIndex = strategyManager
      .getRewardIndex(
        VirtualPool.getPool(position.poolIds[0]).strategyId
      );
    address account = positionToken.ownerOf(positionId_);

    // Remove capital from pool & compute capital after claims & strategy rewards
    (
      uint256 capital,
      uint256 strategyRewards
    ) = _removeOverlappingCapital(
        positionId_,
        position.supplied,
        amount_,
        position.strategyRewardIndex,
        latestStrategyRewardIndex,
        position.poolIds
      );

    // Reduce position of new amount of capital minus the amount withdrawn
    if (capital < amount_)
      revert InsufficientLiquidityForWithdrawal();

    position.supplied = capital - amount_;
    // Reset the position's commitWithdrawalTimestamp
    position.commitWithdrawalTimestamp = 0;
    position.strategyRewardIndex = latestStrategyRewardIndex;

    // All pools have same strategy since they are compatible
    if (amount_ != 0 || strategyRewards != 0) {
      uint256 strategyId = VirtualPool
        .getPool(position.poolIds[0])
        .strategyId;
      if (keepWrapped_) {
        strategyManager.withdrawWrappedFromStrategy(
          strategyId,
          amount_,
          strategyRewards,
          account,
          0 // No yield bonus
        );
      } else {
        strategyManager.withdrawFromStrategy(
          strategyId,
          amount_,
          strategyRewards,
          account,
          0 // No yield bonus
        );
      }
    }
  }

  /// ======= BUY COVER ======= ///

  /**
   * @notice Buys a cover
   * @param poolId_ The ID of the pool
   * @param coverAmount_ The amount of cover to buy
   * @param premiums_ The amount of premiums to pay
   */
  function openCover(
    uint64 poolId_,
    uint256 coverAmount_,
    uint256 premiums_
  ) external nonReentrant {
    // Check if pool exists & is not currently paused
    _checkPoolExists(poolId_);
    _checkIsNotPaused(poolId_);

    // Get storage pointer to pool
    DataTypes.VPool storage pool = VirtualPool.getPool(poolId_);

    // Clean pool from expired covers
    VirtualPool._purgeExpiredCovers(poolId_);

    if (coverAmount_ == 0 || premiums_ == 0)
      revert ForbiddenZeroValue();

    // Transfer premiums from user
    IERC20(pool.paymentAsset).safeTransferFrom(
      msg.sender,
      address(this),
      premiums_
    );

    // Mint cover NFT
    uint256 coverId = coverToken.mint(msg.sender);

    // Map cover to pool for data access
    coverToPool[coverId] = poolId_;

    // Create cover in pool
    VirtualPool._registerCover(
      poolId_,
      coverId,
      coverAmount_,
      premiums_
    );

    emit CoverOpenned(poolId_, coverId);
  }

  /// ======= UPDATE COVER ======= ///

  /**
   * @notice Updates or closes a cover
   * @param coverId_ The ID of the cover
   * @param coverToAdd_ The amount of cover to add
   * @param coverToRemove_ The amount of cover to remove
   * @param premiumsToAdd_ The amount of premiums to add
   * @param premiumsToRemove_ The amount of premiums to remove
   *
   * @dev If premiumsToRemove_ is max uint256 then withdraw premiums
   * & closes the cover
   */
  function updateCover(
    uint256 coverId_,
    uint256 coverToAdd_,
    uint256 coverToRemove_,
    uint256 premiumsToAdd_,
    uint256 premiumsToRemove_
  ) external onlyCoverOwner(coverId_) nonReentrant {
    uint64 poolId = coverToPool[coverId_];

    // Get storage pointer to pool
    DataTypes.VPool storage pool = VirtualPool.getPool(poolId);

    // Clean pool from expired covers
    VirtualPool._purgeExpiredCovers(poolId);

    // Check if cover is expired
    if (!isCoverActive(coverId_)) revert CoverIsExpired();

    // Get the amount of premiums left
    uint256 premiums = VirtualPool
      ._computeCurrentCoverInfo(poolId, coverId_)
      .premiumsLeft;

    uint256 coverAmount = pool.covers[coverId_].coverAmount;

    // Close the existing cover
    VirtualPool._closeCover(poolId, coverId_);

    // Only allow one operation on cover amount change
    if (0 < coverToAdd_) {
      // Check if pool is currently paused
      _checkIsNotPaused(poolId);

      coverAmount += coverToAdd_;
    } else if (0 < coverToRemove_) {
      if (coverAmount <= coverToRemove_) revert ForbiddenZeroValue();

      // Unckecked is ok because we checked that coverToRemove_ < coverAmount
      unchecked {
        coverAmount -= coverToRemove_;
      }
    }

    // Only allow one operation on premiums amount change
    if (0 < premiumsToRemove_) {
      if (premiumsToRemove_ == type(uint256).max) {
        // If premiumsToRemove_ is max uint256, then remove all premiums
        premiumsToRemove_ = premiums;
      } else if (premiums < premiumsToRemove_) {
        // Else check if there is enough premiums left
        revert NotEnoughPremiums();
      }

      premiums -= premiumsToRemove_;
      IERC20(pool.paymentAsset).safeTransfer(
        msg.sender,
        premiumsToRemove_
      );
    } else if (0 < premiumsToAdd_) {
      // Transfer premiums from user
      IERC20(pool.paymentAsset).safeTransferFrom(
        msg.sender,
        address(this),
        premiumsToAdd_
      );
      premiums += premiumsToAdd_;
    }

    if (premiums != 0) {
      // Update cover
      VirtualPool._registerCover(
        poolId,
        coverId_,
        coverAmount,
        premiums
      );

      emit CoverUpdated(coverId_);
    } else {
      emit CoverClosed(coverId_);
      // @dev No need to freeze farming rewards since the cover owner needs to hold the cover to update it
    }
  }

  /// ======= LIQUIDITY CHANGES ======= ///

  /**
   * @notice Adds a position's liquidity to the pools and their overlaps
   * @param poolIds_ The IDs of the pools to add liquidity to
   * @param positionId_ The ID of the position
   * @param amount_ The amount of liquidity to add
   * @param purgePools If it should purge expired covers
   *
   * @dev PoolIds are checked at creation to ensure they are unique and ascending
   */
  function _addOverlappingCapitalAfterCheck(
    uint64[] memory poolIds_,
    uint256 positionId_,
    uint256 amount_,
    bool purgePools
  ) internal {
    uint256 nbPoolIds = poolIds_.length;

    for (uint256 i; i < nbPoolIds; i++) {
      uint64 poolId0 = poolIds_[i];

      _checkPoolExists(poolId0);

      DataTypes.VPool storage pool0 = VirtualPool.getPool(poolId0);

      // Check if pool is currently paused
      _checkIsNotPaused(poolId0);

      // Remove expired covers
      /// @dev Skip the purge when adding liquidity since it has been done
      if (purgePools) VirtualPool._purgeExpiredCovers(poolId0);

      // Update premium rate, seconds per tick & LP position info
      VirtualPool._depositToPool(poolId0, positionId_, amount_);

      // Add liquidity to the pools available liquidity
      pool0.overlaps[poolId0] += amount_;

      /**
       * Loops all pool combinations to check if they are compatible,
       * that they are in ascending order & that they are unique.
       * It then registers the overlapping capital.
       *
       * The loop starts at i + 1 to avoid redundant combinations.
       */
      for (uint256 j = i + 1; j < nbPoolIds; j++) {
        uint64 poolId1 = poolIds_[j];
        DataTypes.VPool storage pool1 = VirtualPool.getPool(poolId1);

        // Check if pool ID is greater than the previous one
        // This ensures each pool ID is unique & reduces computation cost
        if (poolId1 <= poolId0)
          revert PoolIdsMustBeUniqueAndAscending();

        // Check if pool is compatible
        if (!arePoolCompatible[poolId0][poolId1])
          revert IncompatiblePools(poolId0, poolId1);

        // Register overlap in both pools
        if (pool0.overlaps[poolId1] == 0) {
          pool0.overlappedPools.push(poolId1);
          pool1.overlappedPools.push(poolId0);
        }

        pool0.overlaps[poolId1] += amount_;
      }
    }

    emit PositionLiquidityUpdated(positionId_, amount_, 0);
  }

  /**
   * @notice Removes the position liquidity from its pools and overlaps
   * @param positionId_ The ID of the position
   * @param amount_ The amount of liquidity to remove
   * @param poolIds_ The IDs of the pools to remove liquidity from
   *
   * @return capital The updated user capital
   * @return rewards The strategy rewards
   *
   * @dev PoolIds have been checked at creation to ensure they are unique and ascending
   */
  function _removeOverlappingCapital(
    uint256 positionId_,
    uint256 supplied_,
    uint256 amount_,
    uint256 strategyRewardIndex_,
    uint256 latestStrategyRewardIndex_,
    uint64[] storage poolIds_
  ) internal returns (uint256 capital, uint256 rewards) {
    uint256 nbPoolIds = poolIds_.length;

    for (uint256 i; i < nbPoolIds; i++) {
      uint64 poolId0 = poolIds_[i];
      DataTypes.VPool storage pool0 = VirtualPool.getPool(poolId0);

      // Need to clean covers to avoid them causing a utilization overflow
      VirtualPool._purgeExpiredCovers(poolId0);

      // Remove liquidity
      // The updated user capital & strategy rewards are the same at each iteration
      (capital, rewards) = VirtualPool._withdrawLiquidity(
        poolId0,
        positionId_,
        supplied_,
        amount_,
        strategyRewardIndex_,
        latestStrategyRewardIndex_,
        poolIds_
      );

      // Considering the verification that pool IDs are unique & ascending
      // then start index is i to reduce required number of loops
      for (uint256 j = i; j < nbPoolIds; j++) {
        uint64 poolId1 = poolIds_[j];
        pool0.overlaps[poolId1] -= amount_;
      }
    }

    emit PositionLiquidityUpdated(positionId_, 0, amount_);
  }

  /// ======= CLAIMS ======= ///

  /**
   * @notice Registers a claim in the pool after a claim is created
   * @param coverId_ The ID of the cover
   *
   * @dev The existence of th cover is checked in the claim manager
   */
  function addClaimToPool(
    uint256 coverId_
  ) external onlyClaimManager {
    VirtualPool.getPool(coverToPool[coverId_]).ongoingClaims++;
  }

  /**
   * @notice Removes a claim from the pool after a claim is resolved
   * @param coverId_ The ID of the cover
   *
   * @dev The existence of th cover is checked in the claim manager
   */
  function removeClaimFromPool(
    uint256 coverId_
  ) external onlyClaimManager {
    VirtualPool.getPool(coverToPool[coverId_]).ongoingClaims--;
  }

  /**
   * @notice Attemps to open an updated cover after a compensation is paid out
   * @param poolId_ The ID of the pool
   * @param coverId_ The ID of the cover
   * @param newCoverAmount_ The amount of cover to buy
   * @param premiums_ The amount of premiums to pay
   *
   * @dev The function is external to use try/catch but can only be called internally
   */
  function attemptReopenCover(
    uint64 poolId_,
    uint256 coverId_,
    uint256 newCoverAmount_,
    uint256 premiums_
  ) external {
    // this function should be called only by this contract
    if (msg.sender != address(this)) {
      revert SenderNotLiquidityManager();
    }

    // This will trigger the catch part of the try/catch
    if (newCoverAmount_ == 0) revert ForbiddenZeroValue();

    VirtualPool._registerCover(
      poolId_,
      coverId_,
      newCoverAmount_,
      premiums_
    );
  }

  /**
   * @notice Pays out a compensation following an valid claim
   * @param coverId_ The ID of the cover
   * @param compensationAmount_ The amount of compensation to pay out
   */
  function payoutClaim(
    uint256 coverId_,
    uint256 compensationAmount_
  ) external onlyClaimManager {
    uint64 fromPoolId = coverToPool[coverId_];
    DataTypes.VPool storage poolA = VirtualPool.getPool(fromPoolId);

    uint256 ratio = compensationAmount_.rayDiv(
      VirtualPool.totalLiquidity(fromPoolId)
    );
    // The ration cannot be over 100% of the pool's liquidity (1 RAY)
    if (RayMath.RAY < ratio) revert RatioAbovePoolCapacity();

    uint256 strategyId = poolA.strategyId;
    uint256 strategyRewardIndex = strategyManager.getRewardIndex(
      strategyId
    );

    uint256 nbPools = poolA.overlappedPools.length;

    // Get compensation ID and its storage pointer
    uint256 compensationId = nextCompensationId;
    nextCompensationId++;
    DataTypes.Compensation storage compensation = VirtualPool
      .getCompensation(compensationId);
    // Register data common to all affected pools
    compensation.fromPoolId = fromPoolId;
    compensation.ratio = ratio;
    compensation.strategyRewardIndexBeforeClaim = strategyRewardIndex;

    for (uint256 i; i < nbPools; i++) {
      uint64 poolIdB = poolA.overlappedPools[i];
      DataTypes.VPool storage poolB = VirtualPool.getPool(poolIdB);

      (DataTypes.VPool storage pool0, uint64 poolId1) = fromPoolId <
        poolIdB
        ? (poolA, poolIdB)
        : (poolB, fromPoolId);

      // Skip if overlap is 0 because the pools no longer share liquidity
      if (pool0.overlaps[poolId1] == 0) continue;
      // Update pool state & remove expired covers
      VirtualPool._purgeExpiredCovers(poolIdB);

      // New context to avoid stack too deep error
      {
        // Remove liquidity from dependant pool
        uint256 amountToRemove = pool0.overlaps[poolId1].rayMul(
          ratio
        );

        // Skip if the amount to remove is 0
        if (amountToRemove == 0) continue;

        // Update pool pricing (premium rate & seconds per tick)
        /// @dev Skip available liquidity lock check as payouts are always possible
        VirtualPool._syncLiquidity(poolIdB, 0, amountToRemove, true);

        // Reduce available liquidity, at i = 0 this is the liquidity of cover's pool
        pool0.overlaps[poolId1] -= amountToRemove;

        // Only remove liquidity in indirectly dependant pools other than the cover's pool
        if (i != 0) {
          // Check all pool combinations to reduce overlapping capital
          for (uint64 j; j < nbPools; j++) {
            uint64 poolIdC = poolA.overlappedPools[j];
            if (poolIdC != fromPoolId)
              if (poolIdB <= poolIdC) {
                poolB.overlaps[poolIdC] -= amountToRemove;
              }
          }
        }

        // Trade references to track reward indexes in single compensation struct
        poolB.compensationIds.push(compensationId);
        compensation.liquidityIndexBeforeClaim[poolIdB] = poolB
          .slot0
          .liquidityIndex;
      }
    }

    address claimant = coverToken.ownerOf(coverId_);

    // New context to avoid stack too deep error
    {
      // If the cover isn't expired, then reduce the cover amount
      if (isCoverActive(coverId_)) {
        // Get the amount of premiums left
        uint256 premiums = VirtualPool
          ._computeCurrentCoverInfo(fromPoolId, coverId_)
          .premiumsLeft;

        // Reduce the cover amount by the compensation amount
        uint256 newCoverAmount = poolA.covers[coverId_].coverAmount -
          compensationAmount_;

        // Close the existing cover
        VirtualPool._closeCover(fromPoolId, coverId_);

        // Update cover
        try
          this.attemptReopenCover(
            fromPoolId,
            coverId_,
            newCoverAmount,
            premiums
          )
        {} catch {
          // If updating the cover fails beacause of not enough liquidity,
          // then close the cover entirely & transfer premiums back to user
          IERC20(poolA.paymentAsset).safeTransfer(claimant, premiums);
        }
      }
    }

    // Pay out the compensation from the strategy
    strategyManager.payoutFromStrategy(
      strategyId,
      compensationAmount_,
      claimant
    );

    emit CompensationPaid(fromPoolId, compensationId);
  }

  /// ======= MISC HELPERS ======= ///

  /**
   * @notice Purges a pool's expired covers up to a certain timestamp
   * @param poolId_ The ID of the pool
   * @param timestamp_ The timestamp up to which to purge the covers
   */
  function purgeExpiredCoversUpTo(
    uint64 poolId_,
    uint256 timestamp_
  ) external nonReentrant onlyOwner {
    if (timestamp_ <= block.timestamp)
      revert MustPurgeExpiredTokenInTheFuture();

    VirtualPool._purgeExpiredCoversUpTo(poolId_, timestamp_);
  }

  /**
   * @notice Updates a position up to a certain compensation index
   * @param positionId_ The ID of the position
   * @param endCompensationIndexes_ The end indexes of the compensations to update up to for each pool
   *
   * @dev Only callable by owner but does not enable it to withdraw funds or rewards
   */
  function updatePositionUpTo(
    uint256 positionId_,
    uint256[] calldata endCompensationIndexes_
  ) external nonReentrant onlyOwner {
    Position storage position = _positions[positionId_];

    // Locks interests to avoid abusively early withdrawal commits
    if (position.commitWithdrawalTimestamp != 0)
      revert CannotUpdateCommittedPosition();

    address account = positionToken.ownerOf(positionId_);

    VirtualPool.UpdatedPositionInfo memory info;
    uint256 latestStrategyRewardIndex;

    for (uint256 i; i < position.poolIds.length; i++) {
      // Clean pool from expired covers
      VirtualPool._purgeExpiredCovers(position.poolIds[i]);

      DataTypes.VPool storage pool = VirtualPool.getPool(
        position.poolIds[i]
      );

      if (
        endCompensationIndexes_[i] <=
        pool.lpInfos[positionId_].beginClaimIndex ||
        pool.compensationIds.length - 1 < endCompensationIndexes_[i]
      ) revert OutOfBounds();

      {
        // Get the updated position info
        (info, latestStrategyRewardIndex) = VirtualPool
          ._processCompensationsForPosition(
            position.poolIds[i],
            position.poolIds,
            VirtualPool.UpdatePositionParams({
              currentLiquidityIndex: pool.slot0.liquidityIndex,
              tokenId: positionId_,
              userCapital: position.supplied,
              strategyRewardIndex: position.strategyRewardIndex,
              latestStrategyRewardIndex: 0, // unused in this context
              strategyId: pool.strategyId,
              itCompounds: pool.strategyManager.itCompounds(
                pool.strategyId
              ),
              endCompensationId: endCompensationIndexes_[i],
              nbPools: position.poolIds.length
            })
          );
      }

      // Pay cover rewards and send fees to treasury
      VirtualPool._payRewardsAndFees(
        position.poolIds[i],
        info.coverRewards,
        account,
        0,
        position.poolIds.length
      );

      // Update lp info to reflect the new state of the position
      pool.lpInfos[positionId_] = info.newLpInfo;
      // We want to update the position's strategy reward index to the latest compensation
      if (position.strategyRewardIndex < latestStrategyRewardIndex)
        position.strategyRewardIndex = latestStrategyRewardIndex;
    }
  }

  /// ======= ADMIN ======= ///

  /**
   * @notice Pause or unpause a pool
   * @param poolId_ The ID of the pool
   * @param isPaused_ True if the pool should be paused
   *
   * @dev You cannot buy cover, increase cover or add liquidity in a paused pool
   */
  function pausePool(
    uint64 poolId_,
    bool isPaused_
  ) external onlyOwner {
    VirtualPool.getPool(poolId_).isPaused = isPaused_;
  }

  /**
   * @notice Updates the compatibility between pools
   * @param poolIds_ The IDs of the pools
   * @param poolIdCompatible_ The IDs of the pools that are compatible
   * @param poolIdCompatibleStatus_ The status of the compatibility
   */
  function updatePoolCompatibility(
    uint64[] calldata poolIds_,
    uint64[][] calldata poolIdCompatible_,
    bool[][] calldata poolIdCompatibleStatus_
  ) external onlyOwner {
    uint256 nbPools = poolIds_.length;
    for (uint256 i; i < nbPools; i++) {
      uint64 poolId0 = poolIds_[i];

      uint256 nbCompatiblePools = poolIdCompatible_[i].length;
      for (uint256 j; j < nbCompatiblePools; j++) {
        uint64 poolId1 = poolIdCompatible_[i][j];

        // Check that pool does not self match & it stores in smallest pool ID
        if (poolId1 <= poolId0)
          revert PoolIdsAreCannotBeMatched(poolId0, poolId1);

        arePoolCompatible[poolId0][poolId1] = poolIdCompatibleStatus_[
          i
        ][j];
      }
    }
  }

  /**
   * @notice Updates the withdraw delay and the maximum leverage
   * @param withdrawDelay_ The new withdraw delay
   * @param maxLeverage_ The new maximum leverage
   */
  function updateConfig(
    IEcclesiaDao ecclesiaDao_,
    IStrategyManager strategyManager_,
    address claimManager_,
    address yieldRewarder_,
    uint256 withdrawDelay_,
    uint256 maxLeverage_,
    uint256 leverageFeePerPool_
  ) external onlyOwner {
    ecclesiaDao = ecclesiaDao_;
    strategyManager = strategyManager_;

    yieldRewarder = yieldRewarder_;
    claimManager = claimManager_;

    withdrawDelay = withdrawDelay_;
    maxLeverage = maxLeverage_;
    leverageFeePerPool = leverageFeePerPool_;
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.25;

// interfaces
import { IStrategyManager } from "../interfaces/IStrategyManager.sol";
import { ILiquidityManager } from "../interfaces/ILiquidityManager.sol";
// libraries
import { VirtualPool } from "../libs/VirtualPool.sol";
import { DataTypes } from "../libs/DataTypes.sol";
import { PoolMath } from "../libs/PoolMath.sol";

/**
 * @title Athena Data Provider
 * @author vblackwhale
 *
 * This contract provides a way to access formatted data of various data structures.
 * It enables frontend applications to access the data in a more readable way.
 * The structures include:
 * - Positions
 * - Covers
 * - Virtual Pools
 *
 */
library AthenaDataProvider {
  /**
   * @notice Returns the up to date position data of a token
   * @param positionId_ The ID of the position
   * @return The position data
   */
  function positionInfo(
    ILiquidityManager.Position storage position_,
    uint256 positionId_
  ) external view returns (ILiquidityManager.PositionRead memory) {
    uint256[] memory coverRewards = new uint256[](
      position_.poolIds.length
    );
    VirtualPool.UpdatedPositionInfo memory info;

    DataTypes.VPool storage pool = VirtualPool.getPool(
      position_.poolIds[0]
    );

    // All pools have same strategy since they are compatible
    uint256 latestStrategyRewardIndex = ILiquidityManager(
      address(this)
    ).strategyManager().getRewardIndex(pool.strategyId);

    for (uint256 i; i < position_.poolIds.length; i++) {
      uint256 currentLiquidityIndex = VirtualPool
        ._refreshSlot0(position_.poolIds[i], block.timestamp)
        .liquidityIndex;

      info = VirtualPool._getUpdatedPositionInfo(
        position_.poolIds[i],
        position_.poolIds,
        VirtualPool.UpdatePositionParams({
          tokenId: positionId_,
          currentLiquidityIndex: currentLiquidityIndex,
          userCapital: position_.supplied,
          strategyRewardIndex: position_.strategyRewardIndex,
          latestStrategyRewardIndex: latestStrategyRewardIndex,
          strategyId: pool.strategyId,
          itCompounds: pool.strategyManager.itCompounds(
            pool.strategyId
          ),
          endCompensationId: pool.compensationIds.length,
          nbPools: position_.poolIds.length
        })
      );

      coverRewards[i] = info.coverRewards;
    }

    bool isWrappedAllowed = pool.wrappedAsset != address(0);
    (
      uint256 suppliedWrapped,
      uint256 newUserCapitalWrapped
    ) = isWrappedAllowed
        ? (
          ILiquidityManager(address(this))
            .strategyManager()
            .wrappedToUnderlying(pool.strategyId, position_.supplied),
          ILiquidityManager(address(this))
            .strategyManager()
            .wrappedToUnderlying(pool.strategyId, info.newUserCapital)
        )
        : (position_.supplied, info.newUserCapital);

    return
      ILiquidityManager.PositionRead({
        positionId: positionId_,
        supplied: position_.supplied,
        suppliedWrapped: suppliedWrapped,
        commitWithdrawalTimestamp: position_
          .commitWithdrawalTimestamp,
        strategyRewardIndex: latestStrategyRewardIndex,
        poolIds: position_.poolIds,
        newUserCapital: info.newUserCapital,
        newUserCapitalWrapped: newUserCapitalWrapped,
        coverRewards: coverRewards,
        strategyRewards: info.strategyRewards
      });
  }

  /**
   * @notice Returns the up to date cover data of a token
   * @param coverId_ The ID of the cover
   * @return The cover data formatted for reading
   */
  function coverInfo(
    uint256 coverId_
  ) public view returns (ILiquidityManager.CoverRead memory) {
    uint64 poolId = ILiquidityManager(address(this)).coverToPool(
      coverId_
    );
    DataTypes.VPool storage pool = VirtualPool.getPool(poolId);

    VirtualPool.CoverInfo memory info = VirtualPool
      ._computeRefreshedCoverInfo(poolId, coverId_);

    uint32 lastTick = pool.covers[coverId_].lastTick;
    uint256 coverAmount = pool.covers[coverId_].coverAmount;

    return
      ILiquidityManager.CoverRead({
        coverId: coverId_,
        poolId: poolId,
        coverAmount: coverAmount,
        premiumsLeft: info.premiumsLeft,
        dailyCost: info.dailyCost,
        premiumRate: info.premiumRate,
        isActive: info.isActive,
        lastTick: lastTick
      });
  }

  /**
   * @notice Returns the virtual pool's storage
   * @param poolId_ The ID of the pool
   * @return The virtual pool's storage
   */
  function poolInfo(
    uint64 poolId_
  ) public view returns (ILiquidityManager.VPoolRead memory) {
    DataTypes.VPool storage pool = VirtualPool.getPool(poolId_);

    // Save the last update timestamp to know when the pool was last updated onchain
    uint256 lastOnchainUpdateTimestamp = pool
      .slot0
      .lastUpdateTimestamp;

    DataTypes.Slot0 memory slot0 = VirtualPool._refreshSlot0(
      poolId_,
      block.timestamp
    );

    uint256 nbOverlappedPools = pool.overlappedPools.length;
    uint256[] memory overlappedCapital = new uint256[](
      nbOverlappedPools
    );
    for (uint256 i; i < nbOverlappedPools; i++) {
      overlappedCapital[i] = ILiquidityManager(address(this))
        .poolOverlaps(pool.poolId, pool.overlappedPools[i]);
    }

    uint256 totalLiquidity = VirtualPool.totalLiquidity(poolId_);
    uint256 utilization = PoolMath._utilization(
      slot0.coveredCapital,
      totalLiquidity
    );
    uint256 premiumRate = PoolMath.getPremiumRate(
      pool.formula,
      utilization
    );

    uint256 liquidityIndexLead = PoolMath.computeLiquidityIndex(
      utilization,
      premiumRate,
      // This is the ignoredDuration in the _refreshSlot0 function
      block.timestamp - slot0.lastUpdateTimestamp
    );

    uint256 strategyRewardRate = pool.strategyManager.getRewardRate(
      pool.strategyId
    );

    return
      ILiquidityManager.VPoolRead({
        poolId: pool.poolId,
        feeRate: pool.feeRate,
        leverageFeePerPool: pool.leverageFeePerPool,
        dao: pool.dao,
        strategyManager: pool.strategyManager,
        formula: pool.formula,
        slot0: slot0,
        strategyId: pool.strategyId,
        strategyRewardRate: strategyRewardRate,
        paymentAsset: pool.paymentAsset,
        underlyingAsset: pool.underlyingAsset,
        wrappedAsset: pool.wrappedAsset,
        isPaused: pool.isPaused,
        overlappedPools: pool.overlappedPools,
        ongoingClaims: pool.ongoingClaims,
        compensationIds: pool.compensationIds,
        overlappedCapital: overlappedCapital,
        utilizationRate: utilization,
        totalLiquidity: totalLiquidity,
        availableLiquidity: VirtualPool.availableLiquidity(poolId_),
        strategyRewardIndex: ILiquidityManager(address(this))
          .strategyManager()
          .getRewardIndex(pool.strategyId),
        lastOnchainUpdateTimestamp: lastOnchainUpdateTimestamp,
        premiumRate: premiumRate,
        liquidityIndexLead: liquidityIndexLead
      });
  }

  function coverInfos(
    uint256[] calldata coverIds
  ) external view returns (ILiquidityManager.CoverRead[] memory) {
    ILiquidityManager.CoverRead[]
      memory result = new ILiquidityManager.CoverRead[](
        coverIds.length
      );

    for (uint256 i; i < coverIds.length; i++) {
      result[i] = coverInfo(coverIds[i]);
    }

    return result;
  }

  function poolInfos(
    uint256[] calldata poolIds
  ) external view returns (ILiquidityManager.VPoolRead[] memory) {
    ILiquidityManager.VPoolRead[]
      memory result = new ILiquidityManager.VPoolRead[](
        poolIds.length
      );

    for (uint256 i; i < poolIds.length; i++) {
      result[i] = poolInfo(uint64(poolIds[i]));
    }

    return result;
  }
}