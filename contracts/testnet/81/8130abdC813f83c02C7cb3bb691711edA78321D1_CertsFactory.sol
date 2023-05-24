// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.2) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

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
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
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
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
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

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
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
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
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
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
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
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
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
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../interfaces/IRoles.sol";
import "../Constant.sol";

contract Accessable {

    IRoles private _roles;
    string private constant NO_RIGHTS = "No rights";

    constructor(IRoles roles) {
        _roles = roles;
    }

    function getRoles() public view returns (IRoles) {
        return _roles;
    }
   
    modifier onlyDeployer() {
        _require(_roles.isDeployer(msg.sender), NO_RIGHTS);
        _;
    }

    modifier onlyConfigurator() {
        _require(_roles.isConfigurator(msg.sender), NO_RIGHTS);
        _;
    }

    modifier onlyApprover() {
        _require(_roles.isApprover(msg.sender), NO_RIGHTS);
        _;
    }

    modifier onlyDaoAdmin() {
        _require(_roles.isAdmin(msg.sender), NO_RIGHTS);
        _;
    }

    modifier onlyDaoOrApprover() {
        _require(_roles.isAdmin(msg.sender) || _roles.isApprover(msg.sender), NO_RIGHTS);
        _;
    }

    function _require(bool condition, string memory err) pure internal {
        require(condition, err);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;


contract PauseRefundable {

    bool private _paused;
    bool private _refundable;
    bool private _hasSetRefundableOnce;

    event SetPaused(bool pause);
    event SetRefundable(bool refundable);
    event Refund(address token, uint amount, address to);

    modifier notPaused() {
        require(!_paused, "Paused");
        _;
    }

    modifier canRefund() {
        require(_paused && _refundable, "Cannot refund");
        _;
    }

    function isPausedRefundable() external view returns (bool paused, bool refundable) {
        return (_paused, _refundable);
    }

    function _setPause(bool set) internal {
        // Cannot unpause if has set refundable previously //
        bool notAllowed = _hasSetRefundableOnce && !set;
        require(!notAllowed, "Cannot unpause");
        if (_paused != set) {
            _paused = set;
            emit SetPaused(set);
        }
    }

    function _setRefundable(bool set) internal {
        require(_paused, "Not paused yet");
        if (!_hasSetRefundableOnce && set) {
            _hasSetRefundableOnce = true;
        }

        if (_refundable != set) {
            _refundable = set;
            emit SetRefundable(set);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1


pragma solidity 0.8.15;

library Constant {

    address public constant ZERO_ADDRESS                        = address(0);
    uint    public constant E18                                 = 1e18;
    uint    public constant PCNT_100                            = 1e18;
    uint    public constant PCNT_50                             = 5e17;
    uint    public constant E12                                 = 1e12;
    
    // SaleTypes
    uint8    public constant TYPE_IDO                            = 0;
    uint8    public constant TYPE_OTC                            = 1;
    uint8    public constant TYPE_NFT                            = 2;

    uint8    public constant PUBLIC                              = 0;
    uint8    public constant STAKER                              = 1;
    uint8    public constant WHITELISTED                         = 2;

    // Misc
    bytes public constant ETH_SIGN_PREFIX                       = "\x19Ethereum Signed Message:\n32";

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

enum AddressKey {

    // Dao MultiSig
    DaoMultiSig,
    OfficialSigner,

    // Token
    Launch,
    GovernanceLaunch, // Staked Launch

    // Fees Addresses
    ReferralRewardVault,
    TreasuryVault,
    SalesVault
}

interface IAddressProvider {
    function getAddress(AddressKey key) external view returns (address);
    function getOfficialAddresses() external view returns (address a, address b);
    function getTokenAddresses() external view returns (address a, address b);
    function getFeeAddresses() external view returns (address[3] memory values);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

enum DataSource {
    Campaign,
    SuperCerts,
    Governance,
    Referral,
    Proposal,
    MarketPlace,
    SuperFarm,
    EggPool,
    Swap
}

enum DataAction {
    Buy,
    Refund,
    ClaimCerts,
    ClaimTokens,
    ClaimTeamTokens,
    List,
    Unlist,
    AddLp,
    RemoveLp,
    Rebate,
    Revenue,
    Swap
}

interface IDataLog {
    
    function log(address fromContract, address fromUser, uint source, uint action, uint data1, uint data2) external;

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

enum ParamKey {

        // There will only be 1 parameterProvders in the native chain.
        // The rest of the eVM contracts will retrieve from this single parameterProvider.

        ProposalTimeToLive,
        ProposalMinPower,
        ProposalMaxQueue,
        ProposalVotingDuration,
        ProposalLaunchCollateral,
        ProposalTimeLock,
        ProposalCreatorExecutionDuration,
        ProposalQuorumPcnt, // Eg 30% of total power voted (Yes, No, Abstain) to pass.
        ProposalDummy1, // For future
        ProposalDummy2, // For future

        StakerMinLaunch,        // Eg: Min 1000 vLaunch
        StakerCapLaunch,        // Eg: Cap at 50,000 vLaunch
        StakerDiscountMinPnct,  // Eg: 1000 vLaunch gets 0.6% discount on Fee. For OTC and NFT only.
        StakerDiscountCapPnct,  // Eg: 50,000 vLaunch gets 30%% discount on Fee. For OTC and NFT only.
        StakerDummy1,           // For future
        StakerDummy2,           // For future

        RevShareReferralPcnt,   // Fee% for referrals
        RevShareTreasuryPcnt,   // Fee% for treasury
        RevShareDealsTeamPcnt,  // Business & Tech .
        RevShareDummy1, // For future
        RevShareDummy2, // For future

        ReferralUplineSplitPcnt,    // Eg 80% of rebate goes to upline, 20% to user
        ReferralDummy1, // For future
        ReferralDummy2, // For future

        SaleUserMaxFeePcnt,         // User's max fee% for any sale
        SaleUserCurrentFeePcnt,     // The current user's fee%
        SaleChargeFee18Dp,          // Each time a user buys, there's a fee like $1. Can be 0.
        SaleMaxPurchasePcntByFund,  // The max % of hardCap that SuperLauncher Fund can buy in a sale.
        SaleDummy1, // For future
        SaleDummy2, // For future

        lastIndex
    }

interface IParameterProvider {

    function setValue(ParamKey key, uint value) external;
    function setValues(ParamKey[] memory keys, uint[] memory values) external;
    function getValue(ParamKey key) external view returns (uint);
    function getValues(ParamKey[] memory keys) external view returns (uint[] memory);

    // Validation
    function validateChanges(ParamKey[] calldata keys, uint[] calldata values) external returns (bool success);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface IRoles {
    function isAdmin(address user) view external returns (bool);
    function isDeployer(address user) view external returns (bool);
    function isConfigurator(address user) view external returns (bool);
    function isApprover(address user) view external returns (bool);
    function isRole(string memory roleName, address user) view external returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../interfaces/IManager.sol";

abstract contract Factory {
    
    IManager internal _manager;
    uint internal _autoIndex;

    constructor(IManager manager) {
        _manager = manager;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../../interfaces/IRoles.sol";
import "../../interfaces/IDataLog.sol";
import "../../interfaces/IParameterProvider.sol";
import "../../interfaces/IAddressProvider.sol";

interface IManager {
    function getRoles() external view returns (IRoles);
    function getParameterProvider() external view returns (IParameterProvider);
     function getAddressProvider() external view returns (IAddressProvider);
    function logData(address user, DataSource source, DataAction action, uint data1, uint data2) external;
    function isCampaignActive(address campaign) external view returns (bool);
}

interface ISaleManager is IManager {
    function addCampaign(address newContract) external;
    function isRouterApproved(address router) external view returns (bool);
}

interface ICertsManager is IManager {
    function addCerts(address certsContract) external;   
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

interface ISuperCerts {
    function setUserSourceByCampaign(uint groupId, string memory groupName, uint totalTokens,  bool finalizeGroup) external ;
    function setTeamSourceByCampaign(address teamAddress, address currency, uint amount) external;
    function claimCertsFromCampaign(address user, uint groupId, string memory groupName, uint amount) external;
    function claimTeamCertsFromCampaign() external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../base/Accessable.sol";
import "../../base/PauseRefundable.sol";
import "./lib/Logics.sol";
import "../interfaces/IManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract CertsBase is PauseRefundable, Accessable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Logics for *;

    CertsTypes.Store private _dataStore;
    ICertsManager internal _manager;

    modifier notLive() {
        _require(!isLive(), "Already live");
        _;
    }

    event FundInForGroup(address indexed user, uint groupId, string groupName, uint amount);
    event ClaimCertsFromMerkle(address indexed user, uint timeStamp, uint groupId, uint claimIndex, uint amount, uint nftId);
    event ClaimCertsFromCampaign(address indexed user, uint timeStamp, uint groupId, uint amount, uint nftId, bool isTeam);
    event ClaimTokens(address indexed user, uint timeStamp, uint id, uint amount, bool isTeam);
    event Split(uint timeStamp, uint id1, uint id2, uint amount);
    event SplitPercent(uint timeStamp, uint id1, uint id2, uint percent);
    event Combine(uint timeStamp, uint id1, uint id2);

    constructor(ICertsManager mgr) Accessable(mgr.getRoles()) {
        _manager = mgr;
    }

    //--------------------//
    //   QUERY FUNCTIONS  //
    //--------------------//

    function getAsset() external view returns (string memory, string memory, uint, uint, bool) {
        CertsTypes.Asset storage asset = _asset();
        return (asset.symbol, asset.certsName, uint(asset.tokenType), asset.tokenId, asset.isFunded);
    }

    function getGroupCount() external view returns (uint user, uint team) {
        user = _groups().items.length;
        team = _teamGroup().item.hasVesting() ? 1 : 0;
    }

    function getGroupInfo(uint groupId, bool isTeam) external view returns (string memory, uint, uint) {
        CertsTypes.GroupInfo storage info = isTeam ? _teamGroup().item.info : _groups().items[groupId].info;
        return (info.name, info.totalEntitlement, info.totalClaimed);
    }

    function getGroupState(uint groupId, bool isTeam) external view returns (bool finalized, bool funded) {
        CertsTypes.GroupState storage state =  _getGroup(groupId, isTeam).state;
        return (state.finalized, state.finalized);
    }

    function checkGroupStatus(uint groupId, bool isTeam) external view returns (CertsTypes.GroupError) {
        return _getGroup(groupId, isTeam).statusCheck(isTeam);
    }

    function getVestingInfo(uint groupId, bool isTeam) external view returns (CertsTypes.VestingItem[] memory) {
        return _getGroup(groupId, isTeam).vestItems;
    }

    function getVestingStartTime() public view returns (uint) {
        return _vestings().vestingStartTime;
    }

    function getNftInfo(uint nftId) external view returns (bool, uint, uint, uint, bool) {
        CertsTypes.NftInfo storage info = _nftAt(nftId);
        return (info.isTeam, info.groupId, info.totalEntitlement, info.totalClaimed, info.valid);
    }

    function isLive() public view returns (bool) {
        uint time = getVestingStartTime();
        return (time != 0 && block.timestamp > time);
    }

    function isCertClaimed(uint groupId, uint index) external view returns (bool) {
        CertsTypes.Group storage group = _groups().items[groupId];
        return group.isClaimed(index);
    }

    function verifyCertClaim(uint groupId, uint index, address account, uint amount, bytes32[] calldata merkleProof) external view returns (bool) {
        CertsTypes.Group storage group = _groups().items[groupId];
        return group.verifyClaim(index, account, amount, merkleProof);
    }

    //--------------------//
    // INTERNAL FUNCTIONS //
    //--------------------//
    function _store() internal view returns (CertsTypes.Store storage) {
        return _dataStore;
    }

    function _vestings() internal view returns (CertsTypes.Vestings storage) {
        return _dataStore.vestings;
    }

    function _groups() internal view returns (CertsTypes.UserGroups storage) {
        return _dataStore.vestings.users;
    }

    function _teamGroup() internal view returns (CertsTypes.TeamGroup storage) {
        return _dataStore.vestings.team;
    }

    function _getGroup(uint groupId, bool isTeam) internal view returns (CertsTypes.Group storage) {
        return isTeam ? _teamGroup().item : _groups().items[groupId];
    }

    function _asset() internal view returns (CertsTypes.Asset storage) {
        return _dataStore.vestings.users.asset;
    }

    function _nftAt(uint nftId) internal view returns (CertsTypes.NftInfo storage nft) {
        nft = _dataStore.nftInfoMap[nftId];
        _require(nft.valid, "Not valid");
    }

    function _nextNftIdIncrement() internal returns (uint) {
        return _dataStore.nextIds++;
    }

    function _transferAssetOut(address to, uint amount) internal {
        CertsTypes.AssetType assetType = _asset().tokenType;
        address token = _asset().tokenAddress;

        if (assetType == CertsTypes.AssetType.ERC20) {
            IERC20(token).safeTransfer(to, amount);
        } else if (assetType == CertsTypes.AssetType.ERC1155) {
            IERC1155(token).safeTransferFrom(address(this), to, _asset().tokenId, amount, "");
        } else if (assetType == CertsTypes.AssetType.ERC721) {
            CertsTypes.Erc721Handler storage handler = _store().erc721Handler;
            uint len = handler.erc721IdArray.length;
            _require(handler.numErc721TransferedOut + amount <= len, "Exceeded");

            for (uint n = 0; n < amount; n++) {
                uint id = handler.erc721IdArray[handler.erc721NextClaimIndex++];
                IERC721(token).safeTransferFrom(address(this), to, id);
            }
            handler.numErc721TransferedOut += amount;
        }
    }

    function _transferOutErc20(address token, address to, uint amount) internal {
        IERC20(token).safeTransfer(to, amount);
    }

    function _requireNonZero(address a) internal pure {
        _require(a != Constant.ZERO_ADDRESS, "Invalid address");
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "../base/Factory.sol";
import "./SuperCertsV3.sol";

contract CertsFactory is Factory {
   
    constructor(ICertsManager manager) Factory(manager) { }

    function create(string calldata symbol) external {
        if (_manager.getRoles().isDeployer(msg.sender)) {
            // Deploy SuperCerts
            string memory certsName = string(abi.encodePacked(symbol, "-Certs")); // Append symbol from XYZ -> XYZ-Certs
            bytes32 salt = keccak256(abi.encodePacked(certsName, _autoIndex++, msg.sender));
            ICertsManager mgr = ICertsManager(address(_manager));
            address newAddress = address(new SuperCertsV3{salt: salt}(mgr, symbol, certsName));
            mgr.addCerts(newAddress);
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

library CertsTypes {
    struct Store {
        Vestings vestings;
        mapping(uint => NftInfo) nftInfoMap; // Maps NFT Id to NftInfo
        uint nextIds; // NFT Id management
        Erc721Handler erc721Handler; // Erc721 asset deposit & claiming management
    }

    struct Asset {
        string symbol;
        string certsName;
        address tokenAddress;
        AssetType tokenType;
        uint tokenId; // Specific for ERC1155 type of asset only
        bool isFunded;
    }

    struct Fund {
        address currency;
        address claimer;
        uint canRefundToGroupId; // Which group Id can this fund be refunded
    }

    struct Vestings {
        TeamGroup team;
        UserGroups users;
        uint vestingStartTime; // Global timestamp for vesting to start
    }

    struct TeamGroup {
        Fund fund;
        Group item;
    }

    struct UserGroups {
        Asset asset;
        Group[] items;
    }

    struct Group {
        GroupInfo info;
        GroupSource source;
        VestingItem[] vestItems;
        mapping(uint => uint) deedClaimMap;
        GroupState state;
    }

    struct GroupSource {
        // 2 modes to claim the deed.
        // 1: By merkle tree
        // 2: By SL Campaign
        bytes32 merkleRootUserSource; // Cert claims using Merkle tree
        address campaignUserSource; // SL campaign to define the users (including team vesting)
    }

    struct VestingItem {
        VestingReleaseType releaseType;
        uint delay;
        uint duration;
        uint percent;
    }

    struct GroupInfo {
        string name;
        uint totalEntitlement; // Total tokens to be distributed to this group
        uint totalClaimed; // In case of refund, we use this to determine the remaining unclaimed entitlement.
    }

    struct GroupState {
        bool finalized;
        bool funded;
    }

    struct Erc721Handler {
        uint[] erc721IdArray;
        mapping(uint => bool) idExistMap;
        uint erc721NextClaimIndex;
        uint numErc721TransferedOut;
        uint numUsedByVerifiedGroups;
    }

    struct NftInfo {
        bool isTeam; // Team vesting NFT or User vesting NFT
        uint groupId;
        uint totalEntitlement;
        uint totalClaimed;
        bool valid;
    }

    // ENUMS
    enum AssetType {
        ERC20,
        ERC1155,
        ERC721
    }

    enum VestingReleaseType {
        LumpSum,
        Linear,
        Unsupported
    }

    enum GroupError {
        None,
        // InvalidId,
        NotYetFinalized,
        NoUserSource,
        NoEntitlement,
        NoVestingItem
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../CertsTypes.sol";
import "../../../Constant.sol";

library Logics {
    // Events for Groups
    event AppendGroup(address indexed user, string name);
    event AttachToCampaign(address campaign, string name);
    event SetGroupFinalized(address indexed user, string name);
    event SetUserSource(address indexed campaign, string name, uint totalTokens);
    event SetTeamSource(address indexed campaign, address fundAddress, uint fundAmount);
    // Events for Vesting
    event DefineVesting();
    event StartVesting(address indexed user, uint timeStamp);
    // Misc events
    event SetAssetDetails(address indexed user, address tokenAddress, CertsTypes.AssetType tokenType, uint tokenIdFor1155);

    //--------------//
    // GROUPS LOGIC //
    //--------------//

    function appendGroups(CertsTypes.UserGroups storage groups, string[] memory names) external returns (uint len) {
        len = names.length;
        for (uint n = 0; n < len; n++) {
            (bool found, ) = exist(groups, names[n]);
            _require(!found, "Group exist");

            CertsTypes.Group storage newGroup = groups.items.push();
            newGroup.info.name = names[n];
            emit AppendGroup(msg.sender, names[n]);
        }
    }

    function setUserSourceByMerkle(CertsTypes.Group storage group, bytes32 root, uint totalTokens) external {
        group.source.merkleRootUserSource = root;
        group.info.totalEntitlement = totalTokens;
        emit SetUserSource(msg.sender, group.info.name, totalTokens);
    }

    function setUserSourceByCampaign(CertsTypes.Group storage group, address campaign, uint totalTokens, bool finalizeGroup) external {
        // Check is the campaign hook?
        _require(group.source.campaignUserSource == campaign, "Wrong hook");

        group.info.totalEntitlement = totalTokens;

        if (finalizeGroup) {
            setFinalized(group);
        }
        emit SetUserSource(msg.sender, group.info.name, totalTokens);
    }

    function setTeamSourceByCampaign(CertsTypes.TeamGroup storage team, address campaign, address teamAddress, address currency, uint amount) external {
        // Check is the campaign hook?
        _require(team.item.source.campaignUserSource == campaign, "Wrong hook");

        team.item.info.totalEntitlement = amount;
        team.item.state.funded = true;
        team.fund.currency = currency;
        team.fund.claimer = teamAddress;
        setFinalized(team.item);
        emit SetTeamSource(msg.sender, currency, amount);
    }

    // Can only be attached to a single campaign only.
    function attachToCampaign(CertsTypes.Vestings storage vestings, address campaign, uint groupId, string memory groupName) external {
        _require(campaign != address(0), "Invalid address");
        _require(vestings.team.item.source.campaignUserSource == address(0), "Already attached");

        CertsTypes.Group storage group = at(vestings.users, groupId, groupName);
        group.source.campaignUserSource = campaign; // For UserGroup
        vestings.team.item.source.campaignUserSource = campaign; // For TeamGroup
        vestings.team.fund.canRefundToGroupId = groupId;
        emit AttachToCampaign(campaign, group.info.name);
    }

    function setFinalized(CertsTypes.Group storage group) public {
        if (!group.state.finalized) {
            // Either merkleroot OR campaign source is required
            _require(hasUserSource(group), "No source");
            _require(group.info.totalEntitlement > 0, "No entitlement");
            _require(group.vestItems.length > 0, "No vesting");
            group.state.finalized = true;
            emit SetGroupFinalized(msg.sender, group.info.name);
        }
    }

    function statusCheck(CertsTypes.Group storage group, bool isTeam) external view returns (CertsTypes.GroupError) {
       
        if (!group.state.finalized) return CertsTypes.GroupError.NotYetFinalized;
        if (group.info.totalEntitlement == 0) return CertsTypes.GroupError.NoEntitlement;
        if (group.vestItems.length == 0) return CertsTypes.GroupError.NoVestingItem;
        if (!isTeam && !hasUserSource(group)) return CertsTypes.GroupError.NoUserSource; // Only User group requires user source
        return CertsTypes.GroupError.None;
    }

    function exist(CertsTypes.UserGroups storage groups, string memory name) public view returns (bool, uint) {
        uint len = groups.items.length;
        for (uint n = 0; n < len; n++) {
            if (_strcmp(groups.items[n].info.name, name)) {
                return (true, n);
            }
        }
        return (false, 0);
    }

    function hasVesting(CertsTypes.Group storage group) external view returns (bool) {
        return group.vestItems.length > 0;
    }

    function at(CertsTypes.UserGroups storage groups, uint groupId, string memory groupName, bool requiredFinalizeState) external view returns (CertsTypes.Group storage group) {
        group = at(groups, groupId, groupName);
        _require(group.state.finalized == requiredFinalizeState, "Wrong finalize state");
    }

    function at(CertsTypes.UserGroups storage groups, uint groupId, string memory groupName) public view returns (CertsTypes.Group storage group) {
        group = groups.items[groupId];
        bool matched = _strcmp(group.info.name, groupName);
        _require(matched, "Unnmatched");
    }

    function at(CertsTypes.TeamGroup storage team, bool requiredFinalizeState) external view returns (CertsTypes.Group storage group) {
        group = team.item;
        _require(group.state.finalized == requiredFinalizeState, "Wrong finalize state");
    }

    function hasUserSource(CertsTypes.Group storage group) private view returns (bool) {
        return group.source.merkleRootUserSource.length > 0 || group.source.campaignUserSource != address(0);
    }

    //---------------------//
    // MERKLE CLAIMS LOGIC //
    //---------------------//

    function isClaimed(CertsTypes.Group storage group, uint index) public view returns (bool) {
        uint claimedWordIndex = index / 256;
        uint claimedBitIndex = index % 256;
        uint claimedWord = group.deedClaimMap[claimedWordIndex];
        uint mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function setClaimed(CertsTypes.Group storage group, uint index) public {
        uint claimedWordIndex = index / 256;
        uint claimedBitIndex = index % 256;
        group.deedClaimMap[claimedWordIndex] = group.deedClaimMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function claim(CertsTypes.Group storage group, uint index, address account, uint amount, bytes32[] calldata merkleProof) external {
        _require(!isClaimed(group, index), "Claimed");
        _require(amount > 0 && verifyClaim(group, index, account, amount, merkleProof), "Invalid");
        setClaimed(group, index);
    }

    function verifyClaim(CertsTypes.Group storage group, uint index, address account, uint amount, bytes32[] calldata merkleProof) public view returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        return MerkleProof.verify(merkleProof, group.source.merkleRootUserSource, node);
    }

    //---------------//
    // VESTING LOGIC //
    //---------------//

    function defineVesting(CertsTypes.Group storage group, CertsTypes.VestingItem[] calldata vestItems) external returns (uint) {
        
        uint len = vestItems.length;
        delete group.vestItems; // Clear existing vesting items

        // Append items
        uint totalPercent;
        for (uint n = 0; n < len; n++) {
            CertsTypes.VestingReleaseType relType = vestItems[n].releaseType;

            _require(relType < CertsTypes.VestingReleaseType.Unsupported, "Invalid type");
            _require(!(relType == CertsTypes.VestingReleaseType.Linear && vestItems[n].duration == 0), "Invalid param");
            _require(vestItems[n].percent > 0, "Invalid percent");

            totalPercent += vestItems[n].percent;
            group.vestItems.push(vestItems[n]);
        }
        // The total percent have to add up to 100 %
        _require(totalPercent == Constant.PCNT_100, "Must be 100%");
        emit DefineVesting();
        return len;
    }

    function getClaimablePercent(CertsTypes.Vestings storage vestings, uint groupId, bool isTeam) public view returns (uint claimablePercent, uint totalEntitlement) {
        CertsTypes.Group storage group;
        if (isTeam) {
            group = vestings.team.item;
        } else {
            group = vestings.users.items[groupId];
        }

        if (!group.state.finalized) {
            return (0, 0);
        }

        totalEntitlement = group.info.totalEntitlement;

        uint start = vestings.vestingStartTime;
        uint end = block.timestamp;

        // Vesting not started yet ?
        if (start == 0 || end <= start) {
            return (0, totalEntitlement);
        }

        CertsTypes.VestingItem[] storage items = group.vestItems;
        uint len = items.length;

        for (uint n = 0; n < len; n++) {
            (uint percent, bool continueNext, uint traverseBy) = getRelease(items[n], start, end);
            claimablePercent += percent;

            if (continueNext) {
                start += traverseBy;
            } else {
                break;
            }
        }
    }

    function getClaimable(CertsTypes.Vestings storage vestings, CertsTypes.NftInfo storage nft) external view returns (uint claimable) {
        (uint percentReleasable, ) = getClaimablePercent(vestings, nft.groupId, nft.isTeam);
        if (percentReleasable > 0) {
            uint totalReleasable = (percentReleasable * nft.totalEntitlement) / Constant.PCNT_100;
            if (totalReleasable > nft.totalClaimed) {
                claimable = totalReleasable - nft.totalClaimed;
            }
        }
    }

    function getRelease(CertsTypes.VestingItem storage item, uint start, uint end) public view returns (uint releasedPercent, bool continueNext, uint traverseBy) {
        releasedPercent = 0;
        bool passedDelay = (end > (start + item.delay));
        if (passedDelay) {
            if (item.releaseType == CertsTypes.VestingReleaseType.LumpSum) {
                releasedPercent = item.percent;
                continueNext = true;
                traverseBy = item.delay;
            } else if (item.releaseType == CertsTypes.VestingReleaseType.Linear) {
                uint elapsed = end - start - item.delay;
                releasedPercent = _min(item.percent, (item.percent * elapsed) / item.duration);
                continueNext = (end > (start + item.delay + item.duration));
                traverseBy = (item.delay + item.duration);
            } else {
                assert(false);
            }
        }
    }

    function startVesting(CertsTypes.Vestings storage vestings, uint startTime) external {
        if (startTime == 0) {
            startTime = block.timestamp;
        }

        // Make sure that the asset address are set before start vesting.
        // Also, at least 1 group must be funded
        CertsTypes.Asset storage asset = vestings.users.asset;
        _require(asset.tokenAddress != Constant.ZERO_ADDRESS && asset.isFunded && startTime >= block.timestamp, "Cannot start");

        vestings.vestingStartTime = startTime;
        emit StartVesting(msg.sender, startTime);
    }

    

    function getUnClaimed(CertsTypes.Vestings storage vestings, uint groupId, bool isTeam) external view returns(uint) {
        
        CertsTypes.Group storage group;
        if (isTeam) {
            group = vestings.team.item;
        } else {
            group = vestings.users.items[groupId];
        }
        return group.info.totalEntitlement - group.info.totalClaimed;
    }

    //------------//
    // MISC LOGIC //
    //------------//

    function setAssetDetails(CertsTypes.Asset storage asset, address tokenAddress, CertsTypes.AssetType tokenType, uint tokenIdFor1155) external {
        _require(!asset.isFunded, "Funded");
        _require(tokenAddress != Constant.ZERO_ADDRESS, "Invalid address");
        asset.tokenAddress = tokenAddress;
        asset.tokenType = tokenType;
        asset.tokenId = tokenIdFor1155;
        emit SetAssetDetails(msg.sender, tokenAddress, tokenType, tokenIdFor1155);
    }

    // Helpers
    function _strcmp(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    function _min(uint a, uint b) private pure returns (uint) {
        return a < b ? a : b;
    }

    function _require(bool condition, string memory error) private pure {
        require(condition, error);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../interfaces/ISuperCerts.sol";
import "./CertsBase.sol";

contract SuperCertsV3 is ISuperCerts, ERC721Enumerable, ERC1155Holder, ERC721Holder, CertsBase {
    using SafeERC20 for IERC20;
    using Logics for *;

    string private constant SUPER_CERTS = "SuperCerts";
    string private constant TEAM_VESTING = "Team";
    string private constant BASE_URI = "https://superlauncher.io/metadata/";

    constructor(
        ICertsManager manager,
        string memory tokenSymbol,
        string memory certsName
    ) ERC721(certsName, SUPER_CERTS) CertsBase(manager) {
        _groups().asset.symbol = tokenSymbol;
        _groups().asset.certsName = certsName;
        _teamGroup().item.info.name = TEAM_VESTING; // Default team group name
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, ERC1155Receiver) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId) || ERC1155Receiver.supportsInterface(interfaceId);
    }

    function tokenURI(uint /*tokenId*/) public view virtual override returns (string memory) {
        return string(abi.encodePacked(BASE_URI, _groups().asset.certsName));
    }

    //--------------------//
    //   SETUP & CONFIG   //
    //--------------------//

    function appendGroups(string[] memory names) external notLive onlyConfigurator {
        _groups().appendGroups(names);
    }

    function defineVesting(uint groupId, string memory groupName, CertsTypes.VestingItem[] calldata vestItems, bool isTeam) external notLive onlyConfigurator {
        CertsTypes.Group storage group = isTeam ? _teamGroup().at(false) : _groups().at(groupId, groupName, false);
        group.defineVesting(vestItems);
    }

    function setUserSourceByMerkle(uint groupId, string memory groupName, bytes32 merkleRoot, uint totalTokens) external notLive onlyConfigurator {
        CertsTypes.Group storage group = _groups().at(groupId, groupName, false);
        group.setUserSourceByMerkle(merkleRoot, totalTokens);
    }

    // Allow Ido, Otc or Nft campaign to be the team & users source of this SuperCert
    // Only allow attachment once.
    function attachToCampaign(address campaign, uint groupId, string memory groupName) external notLive onlyConfigurator {
        _vestings().attachToCampaign(campaign, groupId, groupName);
    }

    // This is called by the campaign
    function setUserSourceByCampaign(uint groupId, string memory groupName, uint totalTokens, bool finalizeGroup) external override notLive {
        CertsTypes.Group storage group = _groups().at(groupId, groupName, false);
        group.setUserSourceByCampaign(msg.sender, totalTokens, finalizeGroup);
    }

    // This is called by the campaign after the vested fund has been transferred from campaign to superCerts. 
    function setTeamSourceByCampaign(address teamAddress, address currency, uint amount) external override notLive {
        _vestings().team.setTeamSourceByCampaign(msg.sender, teamAddress, currency, amount);
    }

    function setAssetDetails(address tokenAddress, CertsTypes.AssetType tokenType, uint tokenIdFor1155) external notLive onlyConfigurator {
        _asset().setAssetDetails(tokenAddress, tokenType, tokenIdFor1155);
    }

    // Note: Campaign will call group.setFinalize (for team and user group) once sale is over. 
    // Only non-campaign groups need to be managed or finalized manually.
    function setGroupFinalized(uint groupId, string memory groupName) external notLive onlyApprover {
        CertsTypes.Group storage group = _groups().at(groupId, groupName, false);
        group.setFinalized();
    }

    function fundInForGroup(uint groupId, string memory groupName, uint tokenAmount) external notLive onlyDaoOrApprover {
        _requireNonZero(_asset().tokenAddress);
        CertsTypes.Group storage group = _groups().at(groupId, groupName, true); // Group must be finalized

        // Must be correct amount and not yet funded
        _require(!group.state.funded && tokenAmount == group.info.totalEntitlement, "Cannot fund in");
        group.state.funded = true;
        _asset().isFunded = true;

        CertsTypes.AssetType assetType = _asset().tokenType;
        if (assetType == CertsTypes.AssetType.ERC20) {
            IERC20(_asset().tokenAddress).safeTransferFrom(msg.sender, address(this), tokenAmount);
        } else if (assetType == CertsTypes.AssetType.ERC1155) {
            IERC1155(_asset().tokenAddress).safeTransferFrom(msg.sender, address(this), _asset().tokenId, tokenAmount, "");
        } else {
            // Verify that the amount has been deposied already ?
            CertsTypes.Erc721Handler storage handler = _store().erc721Handler;

            uint totalDeposited721 = handler.erc721IdArray.length;
            _require(totalDeposited721 >= (handler.numUsedByVerifiedGroups + tokenAmount), "Insufficient erc721");
            handler.numUsedByVerifiedGroups += tokenAmount;
        }
        emit FundInForGroup(msg.sender, groupId, groupName, tokenAmount);
    }

    function notifyErc721Deposited(uint[] calldata ids) external notLive onlyDaoOrApprover {
        _require(_asset().tokenType == CertsTypes.AssetType.ERC721, "Not Erc721");
        address token = _asset().tokenAddress;
        CertsTypes.Erc721Handler storage handler = _store().erc721Handler;

        uint id;
        uint len = ids.length;
        for (uint n = 0; n < len; n++) {
            // Make sure it is owned by this contract
            id = ids[n];
            _require(IERC721(token).ownerOf(id) == address(this), "Id not found");

            if (!handler.idExistMap[id]) {
                handler.idExistMap[id] = true;
                handler.erc721IdArray.push(id);
            }
        }
    }

    // If startTime is 0, the vesting wil start immediately.
    function startVesting(uint startTime) external notLive onlyApprover {
        _vestings().startVesting(startTime);
    }

    //--------------------//
    //   USER OPERATION   //
    //--------------------//

    // A user address can claim multiple certs.
    function claimCerts(uint[] calldata groupIds, uint[] calldata indexes, uint[] calldata amounts, bytes32[][] calldata merkleProofs) external nonReentrant {
        uint len = groupIds.length;
        _require(len > 0 && len == indexes.length && len == merkleProofs.length, "Invalid param");

        uint grpId;
        uint claimIndex;
        uint amount;
        uint nftId;

        CertsTypes.UserGroups storage groups = _groups();
        for (uint n = 0; n < len; n++) {
            grpId = groupIds[n];
            claimIndex = indexes[n];
            amount = amounts[n];

            CertsTypes.Group storage item = groups.items[grpId];
            _require(item.state.finalized && !item.isClaimed(claimIndex), "Cannot claim");
            item.claim(claimIndex, msg.sender, amount, merkleProofs[n]);

            // Mint NFT
            nftId = _mint(msg.sender, grpId, amount, 0, false);
            emit ClaimCertsFromMerkle(msg.sender, block.timestamp, grpId, claimIndex, amount, nftId);
            _manager.logData(msg.sender, DataSource.Campaign, DataAction.ClaimCerts, nftId, amount);
        }
    }

    function claimCertsFromCampaign(address user, uint groupId, string memory groupName, uint amount) external override nonReentrant {
        _claimCertsFromCampaign(user, groupId, groupName, amount, false);
    }

    function claimTeamCertsFromCampaign() external override nonReentrant {
        CertsTypes.TeamGroup storage team = _vestings().team;
        _claimCertsFromCampaign(team.fund.claimer, 0, "", team.item.info.totalEntitlement, true);
    }

    function _claimCertsFromCampaign(address user, uint groupId, string memory groupName, uint amount, bool isTeam) private {
        CertsTypes.Group storage group;
        if (isTeam) {
            group = _teamGroup().at(true);
        } else {
            group = _groups().at(groupId, groupName, true);
        }
    
        // Only the correct campaign can call this to mint cert
        _require(group.source.campaignUserSource == msg.sender && user != Constant.ZERO_ADDRESS, "Cannot claim");

        // Mint NFT
        uint nftId = _mint(user, groupId, amount, 0, isTeam);

        emit ClaimCertsFromCampaign(user, block.timestamp, groupId, amount, nftId, isTeam);
        _manager.logData(msg.sender, DataSource.Campaign, DataAction.ClaimCerts, nftId, amount);
    }

    function getGroupReleasable(uint groupId, bool isTeam) external view returns (uint percentReleasable, uint totalEntitlement) {
        (percentReleasable, totalEntitlement) = _vestings().getClaimablePercent(groupId, isTeam);
    }

    function getClaimable(uint nftId) public view returns (uint claimable, uint totalClaimed, uint totalEntitlement) {
        CertsTypes.NftInfo storage nft = _nftAt(nftId);
        totalEntitlement = nft.totalEntitlement;
        totalClaimed = nft.totalClaimed;
        claimable = _vestings().getClaimable(nft);
    }

    // ERC721 cannot be batchTransfer. In order to make sure the claim will not fail due to claiming
    // a huge number of ERC721 token, we allow specifying a claim amount 'maxAmount'. This way, the
    // user can claim multiple times without having gas limitation issue.
    // If maxAmount is set to 0, it will claim all available tokens.
    function claimTokens(uint nftId, uint maxAmount) external notPaused nonReentrant {
        _require(ownerOf(nftId) == msg.sender, "Not owner");

        // if this group is not yet funded, it should not be claimable
        CertsTypes.NftInfo storage nft = _nftAt(nftId);
        CertsTypes.Group storage group = _getGroup(nft.groupId, nft.isTeam);

        _require(group.state.funded, "Not funded");

        (uint claimable, , ) = getClaimable(nftId);
        _require(claimable > 0, "Nothing to claim");

        // Partial claim ?
        if (maxAmount != 0 && claimable > maxAmount) {
            claimable = maxAmount;
        }

        nft.totalClaimed += claimable;
        group.info.totalClaimed += claimable;

        // Transfer Asset Out to user, or currency out to team
        if (nft.isTeam) {
            address currency = _vestings().team.fund.currency;
            _transferOutErc20(currency, msg.sender, claimable);
        } else {
            _transferAssetOut(msg.sender, claimable);
        }
        emit ClaimTokens(msg.sender, block.timestamp, nftId, claimable, nft.isTeam);
        _manager.logData(msg.sender, DataSource.Campaign, DataAction.ClaimTokens, nftId, claimable);
    }

    // Split an amount of entitlement out from the "remaining" entitlement from an exceeding Deed and becomes a new Deed.
    // After the split, both Deeds should have non-zero remaining entitlement left.
    function split(uint id, uint amount) external notPaused nonReentrant returns (uint newId) {
        _require(ownerOf(id) == msg.sender, "Not owner");

        CertsTypes.NftInfo storage nft = _nftAt(id);
        uint entitlementLeft = nft.totalEntitlement - nft.totalClaimed;
        _require(amount > 0 && entitlementLeft > amount, "Invalid amount");

        // Calculate the new NFT's required totalEntitlemnt totalClaimed, in a way that these values are distributed
        // as fairly as possible between the parent and child NFT.
        // Important note is that the sum of the totalEntitlement and totalClaimed before and after the split
        // should remain the same. Nothing more or less is resulted due to the split.
        uint neededTotalEnt = (amount * nft.totalEntitlement) / entitlementLeft;
        _require(neededTotalEnt > 0, "Invalid amount");
        uint neededTotalClaimed = neededTotalEnt - amount;

        nft.totalEntitlement -= neededTotalEnt;
        nft.totalClaimed -= neededTotalClaimed;

        // Sanity Check
        _require(nft.totalEntitlement > 0 && nft.totalClaimed < nft.totalEntitlement, "Fail check");

        // mint new nft
        newId = _mint(msg.sender, nft.groupId, neededTotalEnt, neededTotalClaimed, nft.isTeam);
        emit Split(block.timestamp, id, newId, amount);
    }

    function combine(uint id1, uint id2) external notPaused nonReentrant {
        _require(ownerOf(id1) == msg.sender && ownerOf(id2) == msg.sender, "Not owner");

        CertsTypes.NftInfo storage nft1 = _nftAt(id1);
        CertsTypes.NftInfo memory nft2 = _nftAt(id2);

        // Must be the same team & group
        _require(nft1.isTeam == nft2.isTeam, "Different team");
        _require(nft1.groupId == nft2.groupId, "Different group");

        // Since the vesting items are the same, we can just add up the 2 nft
        nft1.totalEntitlement += nft2.totalEntitlement;
        nft1.totalClaimed += nft2.totalClaimed;

        // Burn NFT 2
        _burn(id2);
        delete _store().nftInfoMap[id2];

        emit Combine(block.timestamp, id1, id2);
    }

    //--------------------//
    //   PAUSE, REFUND    //
    //--------------------//
    function setPause(bool set) external onlyDaoAdmin {
        _setPause(set);
    }

    function setRefundable(bool set) external onlyDaoAdmin {
        _setRefundable(set);
    }

    function returnFund(uint nftId) external canRefund nonReentrant {
        CertsTypes.NftInfo storage nft = _nftAt(nftId);
        
        _require(ownerOf(nftId) == msg.sender, "Not owner");
        _require(!nft.isTeam, "Not entitled");
        _require(_vestings().team.fund.canRefundToGroupId == nft.groupId, "Not entitled"); // Only 1 campaign group can share this fund;

        uint fundLeft = _vestings().getUnClaimed(0, true);
        CertsTypes.Group storage group = _getGroup(nft.groupId, false);
        uint totalEntLeft = group.info.totalEntitlement - group.info.totalClaimed;
        uint userEntLeft = nft.totalEntitlement - nft.totalClaimed;
        uint refundAmt = (userEntLeft * fundLeft) / totalEntLeft;

        address currency = _vestings().team.fund.currency;
        _transferOutErc20(currency, msg.sender, refundAmt);

        _burn(nftId);
        delete _store().nftInfoMap[nftId];

        _manager.logData(msg.sender, DataSource.Campaign, DataAction.Refund, refundAmt, 0);
    }

    //-------------------//
    // PRIVATE FUNCTIONS //
    //-------------------//

    function _mint(address to, uint groupId, uint totalEntitlement, uint totalClaimed, bool isTeam) private returns (uint id) {
        _require(totalEntitlement > 0, "Invalid entitlement");
        id = _nextNftIdIncrement();
        _mint(to, id);

        // Setup the certificate's info
        _store().nftInfoMap[id] = CertsTypes.NftInfo(isTeam, groupId, totalEntitlement, totalClaimed, true);
    }
}