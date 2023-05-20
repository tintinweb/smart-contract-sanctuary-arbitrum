// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./XNFTHolder.sol";
import "./interfaces/ICakeBaker.sol";
import "./interfaces/ITokenXBaseV3.sol";
import "./interfaces/IChick.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract Bullish is ReentrancyGuard, Pausable, XNFTHolder
{
	using SafeERC20 for IERC20;

	struct PoolInfo
	{
		address address_token_stake;
		uint256 xnft_grade; 
		address address_token_reward;

		uint256 alloc_point;
		uint256 harvest_interval_block_count;
		uint256 withdrawal_interval_block_count;

		uint256 total_staked_amount;
		uint256 accu_reward_amount_per_share_e12;
		uint256 last_reward_block_id;
	}

	struct FeeInfo
	{
		uint256 deposit_e6;

		uint256 withdrawal_min_e6;
		uint256 withdrawal_max_e6;
		uint256 withdrawal_period_block_count; // decrease time from max to min
	}

	struct RewardInfo
	{
		bool is_native_token;
		uint256 emission_start_block_id;
		uint256 emission_end_block_id;
		uint256 emission_per_block;
		uint256 emission_fee_rate_e6; // ~30%
		uint256 total_alloc_point;
	}

	struct UserInfo
	{
		uint256 staked_amount;
		uint256 paid_reward_amount;
		uint256 locked_reward_amount;
		uint256 reward_debt; // from MasterChefV2

		uint256 last_deposit_block_id;
		uint256 last_harvest_block_id;
		uint256 last_withdrawal_block_id;
	}

	uint256 public constant MAX_HARVEST_INTERVAL_BLOCK = 15000; // about 15 days
	uint256 public constant MAX_DEPOSIT_FEE_E6 = 15000; // 1.5%
	uint256 public constant MAX_WITHDRAWAL_FEE_E6 = 15000; // 1.5%
	uint256 public constant MAX_EMISSION_FEE_E6 = 300000; // 30%

	address public address_chick; // for tax
	address public address_cakebaker; // for delegate farming to pancakeswap

	PoolInfo[] public pool_info; // pool_id / pool_info
	FeeInfo[] public fee_info; // pool_id / fee_info

	mapping(uint256 => mapping(address => UserInfo)) public user_info; // pool_id / user_adddress / user_info
	mapping(address => RewardInfo) public reward_info; // reward_address / reward_info

	//---------------------------------------------------------------
	// Front-end connectors
	//---------------------------------------------------------------
	event SetChickCB(address indexed operator, address _controller);
	event SetCakeBakerCB(address indexed operator, address _controller);

	event MakePoolCB(address indexed operator, uint256 new_pool_id);
	event SetPoolInfoCB(address indexed operator, uint256 _pool_id);
	event UpdateEmissionRateCB(address indexed operator, uint256 _reward_per_block);

	event DepositCB(address indexed user, uint256 _pool_id, uint256 _amount);
	event WithdrawCB(address indexed user, uint256 _pool_id, uint256 _amount);
	event HarvestCB(address indexed user, uint256 _pool_id, uint256 _reward_debt);

	event EmergencyWithdrawCB(address indexed user, uint256 _pool_id, uint256 _amount);
	event HandleStuckCB(address indexed user, uint256 _amount);

	event SetDepositFeeCB(address indexed user, uint256 _pool_id, uint256 _fee_rate_e6);
	event SetWithdrawalFeeCB(address indexed user, uint256 _pool_id, uint256 _fee_max_e6, uint256 _fee_min_e6, uint256 _period_block_count);

	event ExtendMintPeriodCB(address indexed user, address _address_token_reward, uint256 _period_block_count);
	event SetAllocPointCB(address indexed user, uint256 _pool_id, uint256 _alloc_point);

	event SetTestData(uint256 value1, uint256 value2);

	//---------------------------------------------------------------
	// External Method
	//---------------------------------------------------------------
	constructor(address _address_nft) XNFTHolder(_address_nft)
	{
		address_operator = msg.sender;
		address_nft = _address_nft;
	}

	function make_reward(address _address_token_reward, bool _is_native_token, uint256 _emission_per_block, uint256 _emission_start_block_id, 
		uint256 _period_block_count, uint256 _emission_fee_rate_e6) external onlyOperator
	{
		require(_address_token_reward != address(0), "make_reward: Wrong address");
		require(_emission_fee_rate_e6 <= MAX_EMISSION_FEE_E6, "make_reward: Fee limit exceed");
		require(_period_block_count > 0, "make_reward: Wrong period");

		RewardInfo storage reward = reward_info[_address_token_reward];
		reward.is_native_token = _is_native_token;
		reward.emission_per_block = _emission_per_block;
		reward.emission_start_block_id = (block.number > _emission_start_block_id)? block.number : _emission_start_block_id;
		reward.emission_end_block_id = reward.emission_start_block_id + _period_block_count;
		reward.emission_fee_rate_e6 = _emission_fee_rate_e6;
	}

	function make_pool(address _address_token_stake, uint256 _xnft_grade, address _address_token_reward, uint256 _alloc_point,
		uint256 _harvest_interval_block_count, uint256 _withdrawal_interval_block_count, bool _refresh_reward) public onlyOperator
	{
		if(_refresh_reward)
			refresh_reward_per_share_all();

		require(_address_token_stake != address(0), "make_pool: Wrong address");
		require(_address_token_reward != address(0), "make_pool: Wrong address");
		require(_harvest_interval_block_count <= MAX_HARVEST_INTERVAL_BLOCK, "make_pool: Invalid harvest interval");

		RewardInfo storage reward = reward_info[_address_token_reward];
		require(reward.emission_per_block != 0, "make_pool: Invalid reward token");

		reward.total_alloc_point += _alloc_point;

		pool_info.push(PoolInfo({
			address_token_stake: _address_token_stake,
			xnft_grade: _xnft_grade,

			address_token_reward: _address_token_reward,

			alloc_point: _alloc_point,
			harvest_interval_block_count: _harvest_interval_block_count,
			withdrawal_interval_block_count: _withdrawal_interval_block_count,

			total_staked_amount: 0,
			accu_reward_amount_per_share_e12: 0,
			last_reward_block_id: 0
		}));

		fee_info.push(FeeInfo({
			deposit_e6: 0,
			withdrawal_max_e6: 0,
			withdrawal_min_e6: 0,
			withdrawal_period_block_count: 0
		}));

		uint256 new_pool_id = pool_info.length-1;
		emit MakePoolCB(msg.sender, new_pool_id);
	}

	function deposit(uint256 _pool_id, uint256 _amount, uint256[] memory _xnft_ids) public whenNotPaused nonReentrant
	{
		require(_pool_id < pool_info.length, "deposit: Wrong pool id");

		_mint_rewards(_pool_id);

		address address_user = msg.sender;
		
		if(pool_info[_pool_id].xnft_grade == NFT_NOT_USED)
			_deposit_erc20(_pool_id, address_user, _amount);
		else
			_deposit_erc1155(_pool_id, address_user, _xnft_ids);

		emit DepositCB(address_user, _pool_id, _amount);
	}

	function withdraw(uint256 _pool_id, uint256 _amount, uint256[] memory _xnft_ids) public nonReentrant
	{
		require(_pool_id < pool_info.length, "withdraw: Wrong pool id");

		_mint_rewards(_pool_id);

		address address_user = msg.sender;

		if(pool_info[_pool_id].xnft_grade == NFT_NOT_USED)
			_withdraw_erc20(_pool_id, address_user, _amount);
		else
			_withdraw_erc1155(_pool_id, address_user, _xnft_ids);

		emit WithdrawCB(msg.sender, _pool_id, _amount);
	}

	function harvest(uint256 _pool_id) public nonReentrant
	{
		require(_pool_id < pool_info.length, "harvest: Wrong pool id");

		address address_user = msg.sender;
		
		_refresh_rewards(address_user, _pool_id);
		
		PoolInfo storage pool = pool_info[_pool_id];
		UserInfo storage user = user_info[_pool_id][address_user];

		if(pool.harvest_interval_block_count > 0 && user.last_harvest_block_id > 0)
			require(block.number >= user.last_harvest_block_id + pool.harvest_interval_block_count, "harvest: Too early");
		
		// transfer rewards
		uint256 amount = user.locked_reward_amount;
		if(amount > 0)
		{
			uint256 received_amount = _safe_reward_transfer(pool.address_token_reward, address_user, amount);

			user.paid_reward_amount += received_amount;
			user.locked_reward_amount -= received_amount;
			user.last_harvest_block_id = block.number;

			emit HarvestCB(msg.sender, _pool_id, received_amount);
		}
		else
			emit HarvestCB(msg.sender, _pool_id, 0);
	}

	function get_pending_reward_amount(uint256 _pool_id) external view returns(uint256)
	{
		require(_pool_id < pool_info.length, "get_pending_reward_amount: Wrong pool id");

		address address_user = msg.sender;
		PoolInfo memory pool = pool_info[_pool_id];
		UserInfo memory user = user_info[_pool_id][address_user];
		RewardInfo memory reward = reward_info[pool.address_token_reward];

		// getting mint reward amount without _mint_rewards for front-end
		uint256 mint_reward_amount = _get_new_mint_reward_amount(_pool_id, pool, reward);
		if(mint_reward_amount == 0)
			return 0;
		
		uint256 new_rps_e12 = mint_reward_amount * 1e12 / pool.total_staked_amount;
		uint256 new_pool_accu_e12 = pool.accu_reward_amount_per_share_e12 + new_rps_e12;
		
		uint256 boosted_amount = _get_boosted_user_amount(_pool_id, address_user, user.staked_amount);
		uint256 user_rewards = (boosted_amount * new_pool_accu_e12) / 1e12;
	
		return user_rewards - user.reward_debt;
	}

	function refresh_reward_per_share_all() public
	{
		for(uint256 i=0; i < pool_info.length; i++)
			_mint_rewards(i);
	}

	function emergency_withdraw(uint256 _pool_id) public nonReentrant
	{
		require(_pool_id < pool_info.length, "emergency_withdraw: Wrong pool id.");

		address address_user = msg.sender;
		PoolInfo storage pool = pool_info[_pool_id];
		UserInfo storage user = user_info[_pool_id][address_user];

		uint256 amount = user.staked_amount;
		if(amount > 0)
		{
			if(pool.xnft_grade == NFT_NOT_USED)
			{
				IERC20 stake_token = IERC20(pool.address_token_stake);
				stake_token.safeTransfer(address_user, amount);
			}
			else
				emergency_withdraw_nft(_pool_id);

			user.staked_amount = 0;
			user.last_deposit_block_id = 0;
			user.locked_reward_amount = 0;
			user.reward_debt = 0;
			
			pool.total_staked_amount -= amount;
			if(pool.total_staked_amount <= 0)
				pool.last_reward_block_id = 0; // pause emission 
		}

		emit EmergencyWithdrawCB(address_user, _pool_id, amount);
	}

	function handle_stuck(address _address_user, address _address_token, uint256 _amount) public onlyOperator
	{
		for(uint256 i=0; i<pool_info.length; i++)
		{
			require(_address_token != pool_info[i].address_token_stake, "handle_stuck: Wrong token address");
			require(_address_token != pool_info[i].address_token_reward, "handle_stuck: Wrong token address");
		}

		IERC20 stake_token = IERC20(_address_token);
		stake_token.safeTransfer(_address_user, _amount);

		emit HandleStuckCB(_address_user, _amount);
	}

	//---------------------------------------------------------------
	// Internal Method
	//---------------------------------------------------------------
	function _deposit_erc20(uint256 _pool_id, address _address_user, uint256 _amount) internal
	{
		PoolInfo storage pool = pool_info[_pool_id];
		UserInfo storage user = user_info[_pool_id][_address_user];
		RewardInfo storage reward = reward_info[pool.address_token_reward];

		if(user.staked_amount > 0)
		{
			uint256 boosted_amount = _get_boosted_user_amount(_pool_id, _address_user, user.staked_amount);
			uint256 cur_user_rewards = (boosted_amount * pool.accu_reward_amount_per_share_e12) / 1e12;
			uint256 pending = cur_user_rewards - user.reward_debt;
			
			if(pending > 0)
				user.locked_reward_amount += pending; // safeEggTransfer
		} 

		if(_amount > 0)
		{
			IERC20 stake_token = IERC20(pool.address_token_stake);

			// User -> Bullish
			stake_token.safeTransferFrom(_address_user, address(this), _amount);
			
			// Checking Fee
			uint256 deposit_fee = 0;
			if(fee_info[_pool_id].deposit_e6 > 0 && address_chick != address(0))
			{
				// Bullish -> Chick for Fee
				deposit_fee = (_amount * fee_info[_pool_id].deposit_e6) / 1e6;
				stake_token.safeTransfer(address_chick, deposit_fee);
				IChick(address_chick).make_juice(pool.address_token_stake);
			}

			uint256 deposit_amount = _amount - deposit_fee;

			// Bullish -> CakeBaker for delegate farming
			if(address_cakebaker != address(0))
				ICakeBaker(address_cakebaker).delegate(address(this), pool.address_token_stake, deposit_amount);

			// Write down deposit amount on Bullish's ledger
			user.staked_amount += deposit_amount;
			user.last_deposit_block_id = block.number;
			pool.total_staked_amount += deposit_amount;

			emit SetTestData(reward.emission_start_block_id, block.number);
		
			if(reward.emission_start_block_id >= block.number && pool.total_staked_amount > 0 && pool.last_reward_block_id == 0)
				pool.last_reward_block_id = block.number; // start emission
		}

		uint256 cur_boosted_amount = _get_boosted_user_amount(_pool_id, _address_user, user.staked_amount);
		user.reward_debt = (cur_boosted_amount * pool.accu_reward_amount_per_share_e12) / 1e12;
	}

	function _withdraw_erc20(uint256 _pool_id, address _address_user, uint256 _amount) internal
	{
		PoolInfo storage pool = pool_info[_pool_id];
		UserInfo storage user = user_info[_pool_id][_address_user];

		if(user.staked_amount > 0)
		{
			uint256 boosted_amount = _get_boosted_user_amount(_pool_id, _address_user, user.staked_amount);
			uint256 cur_user_rewards = (boosted_amount * pool.accu_reward_amount_per_share_e12) / 1e12;
			uint256 pending = cur_user_rewards - user.reward_debt;
			
			if(pending > 0)
				user.locked_reward_amount += pending; // safeEggTransfer
		}

		if(_amount > 0)
		{
			// CakeBaker -> Bullish from delegate farming
			if(address_cakebaker != address(0))
				ICakeBaker(address_cakebaker).retain(address(this), pool.address_token_stake, _amount);

			IERC20 stake_token = IERC20(pool.address_token_stake);

			// Checking Fee
			uint256 withdraw_fee = 0;
			uint256 withdraw_fee_rate_e6 = _get_cur_withdraw_fee_e6(user, fee_info[_pool_id]);
			if(withdraw_fee_rate_e6 > 0 && address_chick != address(0))
			{
				// Bullish -> Chick for Fee
				withdraw_fee = (_amount * withdraw_fee_rate_e6) / 1e6;				
				stake_token.safeTransfer(address_chick, withdraw_fee);
				IChick(address_chick).make_juice(pool.address_token_stake);
			}

			uint256 withdraw_amount = _amount - withdraw_fee;

			// Bullish -> User
			stake_token.safeTransfer(_address_user, withdraw_amount);

			// Write down deposit amount on Bullish's ledger
			user.staked_amount -= _amount;
			if(user.staked_amount == 0)
				user.last_deposit_block_id = 0;
			
			pool.total_staked_amount -= _amount;
			if(pool.total_staked_amount <= 0)
				pool.last_reward_block_id = 0; // pause emission
		}

		uint256 cur_boosted_amount = _get_boosted_user_amount(_pool_id, _address_user, user.staked_amount);
		user.reward_debt = (cur_boosted_amount * pool.accu_reward_amount_per_share_e12) / 1e12;
	}

	function _deposit_erc1155(uint256 _pool_id, address _address_user, uint256[] memory _xnft_ids) internal
	{
		uint256 _amount = _xnft_ids.length * 1e18;
		PoolInfo storage pool = pool_info[_pool_id];
		UserInfo storage user = user_info[_pool_id][_address_user];
		RewardInfo storage reward = reward_info[pool.address_token_reward];

		if(user.staked_amount > 0) 
		{
			uint256 cur_user_rewards = (user.staked_amount * pool.accu_reward_amount_per_share_e12) / 1e12;
			uint256 pending = cur_user_rewards - user.reward_debt;
			
			if(pending > 0)
				user.locked_reward_amount += pending; // safeEggTransfer
		}

		if(_amount > 0)
		{
			// User -> Bullish
			deposit_nfts(_pool_id, _xnft_ids);

			// Write down deposit amount on Bullish's ledger
			user.staked_amount += _amount;
			user.last_deposit_block_id = block.number;
			pool.total_staked_amount += _amount;

			if(reward.emission_start_block_id >= block.number && pool.total_staked_amount > 0 && pool.last_reward_block_id == 0)
				pool.last_reward_block_id = block.number; // start emission
		}

		user.reward_debt = (user.staked_amount * pool.accu_reward_amount_per_share_e12) / 1e12;
	}

	function _withdraw_erc1155(uint256 _pool_id, address _address_user, uint256[] memory _xnft_ids) internal
	{
		uint256 _amount = _xnft_ids.length * 1e18;
		PoolInfo storage pool = pool_info[_pool_id];
		UserInfo storage user = user_info[_pool_id][_address_user];

		if(user.staked_amount > 0)
		{
			uint256 cur_user_rewards = (user.staked_amount * pool.accu_reward_amount_per_share_e12) / 1e12;
			uint256 pending = cur_user_rewards - user.reward_debt;
			
			if(pending > 0)
				user.locked_reward_amount += pending; // safeEggTransfer
		}

		if(_amount > 0) 
		{
			require(user.staked_amount >= _amount, "withdraw: Insufficient amount");
			require(pool.withdrawal_interval_block_count == 0 || 
				block.number >= user.last_withdrawal_block_id + pool.withdrawal_interval_block_count, "withdraw: Too early to withdraw");

			// Bullish -> User
			withdraw_nfts(_pool_id, _xnft_ids);

			// Write down deposit amount on Bullish's ledger
			user.staked_amount -= _amount;
			if(user.staked_amount == 0)
				user.last_deposit_block_id = 0;

			pool.total_staked_amount -= _amount;	
			if(pool.total_staked_amount <= 0)
				pool.last_reward_block_id = 0; // pause emission 
		}

		user.reward_debt = (user.staked_amount * pool.accu_reward_amount_per_share_e12) / 1e12;
	}

	function _refresh_rewards(address address_user, uint256 _pool_id) internal
	{
		_mint_rewards(_pool_id);

		if(pool_info[_pool_id].xnft_grade == NFT_NOT_USED)
			_deposit_erc20(_pool_id, address_user, 0);
		else
			_deposit_erc1155(_pool_id, address_user, new uint256[](0));
	}

	function _mint_rewards(uint256 _pool_id) internal
	{
		PoolInfo storage pool = pool_info[_pool_id];
		if(pool.total_staked_amount == 0) // disabled pool
			return;

		RewardInfo storage reward = reward_info[pool.address_token_reward];
		uint256 mint_reward_amount = _get_new_mint_reward_amount(_pool_id, pool, reward);
		if(mint_reward_amount == 0)
			return;

		// distribute rewards to pool
		uint256 new_rps_e12 = mint_reward_amount * 1e12 / pool.total_staked_amount;

		pool.accu_reward_amount_per_share_e12 += new_rps_e12;
		pool.last_reward_block_id = block.number;

		// mint to pool
		if(reward.is_native_token == true)
		{
			ITokenXBaseV3 reward_token = ITokenXBaseV3(pool.address_token_reward);
			reward_token.mint(address(this), mint_reward_amount);
			
			// mint fee to fund
			if(address_chick != address(0) && reward.emission_fee_rate_e6 > 0)
			{
				uint256 reward_for_fund = (mint_reward_amount * reward.emission_fee_rate_e6) / 1e6;
				reward_token.mint(address_chick, reward_for_fund);
			}
		}
	}

	function _safe_reward_transfer(address _address_token_reward, address _to, uint256 _amount) internal returns(uint256)
	{
		IERC20 reward_token = IERC20(_address_token_reward);
		uint256 cur_reward_balance = reward_token.balanceOf(address(this));

		if(_amount > cur_reward_balance)
		{
			reward_token.safeTransfer(_to, cur_reward_balance);
			return cur_reward_balance;
		}
		else
		{
			reward_token.safeTransfer(_to, _amount);
			return _amount;
		}
	}

	function _get_cur_withdraw_fee_e6(UserInfo memory _user, FeeInfo memory _fee) internal view returns(uint256)
	{
		if(_fee.withdrawal_period_block_count == 0)
			return 0;

		if(_user.last_deposit_block_id == 0)
			return _fee.withdrawal_max_e6;

		uint256 block_diff = (block.number <= _user.last_deposit_block_id)? 0 : block.number - _user.last_deposit_block_id;
		uint256 reduction_rate_e6 = _min(block_diff * 1e6 / _fee.withdrawal_period_block_count, 1e6);
		uint256 movement_e6 = ((_fee.withdrawal_max_e6 - _fee.withdrawal_min_e6) * reduction_rate_e6) / 1e6;

		return (_fee.withdrawal_max_e6 - movement_e6);
	}

	function _get_boosted_user_amount(uint256 _pool_id, address _address_user, uint256 _user_staked_amount) internal view returns(uint256)
	{
		PoolInfo storage pool = pool_info[_pool_id];
		if(pool.xnft_grade == NFT_NOT_USED)
			return _user_staked_amount;

		uint256 tvl_boost_rate_e6 = get_user_tvl_boost_rate_e6(_pool_id, _address_user);
		uint256 boosted_amount_e6 = _user_staked_amount * (1000000 + tvl_boost_rate_e6);
		return boosted_amount_e6 / 1e6;
	}

	function _get_new_mint_reward_amount(uint256 _pool_id, PoolInfo memory _pool, RewardInfo memory _reward) private view returns(uint256)
	{
		if(_has_new_reward(block.number, _pool, _reward) == false)
			return 0;

		// additional reward to current block
		uint256 elapsed_block_count = block.number - _pool.last_reward_block_id;
		uint256 mint_reward_amount = (elapsed_block_count * _reward.emission_per_block * _pool.alloc_point) / _reward.total_alloc_point;

		// add more rewards for the nft boosters
		if(_pool.xnft_grade != NFT_NOT_USED)
		{
			uint256 pool_boost_rate_e6 = get_pool_tvl_boost_rate_e6(_pool_id);
			if(pool_boost_rate_e6 > 0)
				mint_reward_amount += (mint_reward_amount * (1000000 + pool_boost_rate_e6) / 1e6);
		}

		return mint_reward_amount;
	}

	function _has_new_reward(uint256 block_id, PoolInfo memory _pool, RewardInfo memory _reward) private pure returns(bool)
	{
		if(_pool.alloc_point <= 0 || _pool.total_staked_amount <= 0)
			return false;

		if(	_reward.emission_per_block == 0 ||
			_reward.total_alloc_point == 0 ||

			_reward.emission_start_block_id == 0 ||
			_reward.emission_end_block_id == 0 ||

			block_id < _reward.emission_start_block_id || 
			block_id > _reward.emission_end_block_id)
			return false;
		
		return true;
	}

	function _min(uint256 a, uint256 b) internal pure returns(uint256)
	{
		return a <= b ? a : b;
	}
	
	//---------------------------------------------------------------
	// Variable Interfaces
	//---------------------------------------------------------------
	function get_cur_withdraw_fee_e6(uint256 _pool_id) public view returns(uint256)
	{
		address address_user = msg.sender;
		UserInfo storage user = user_info[_pool_id][address_user];

		uint256 withdraw_fee_rate_e6 = _get_cur_withdraw_fee_e6(user, fee_info[_pool_id]);
		return withdraw_fee_rate_e6;
	}
	
	function set_chick(address _new_address) public onlyOperator
	{
		address_chick = _new_address;
		emit SetChickCB(msg.sender, _new_address);
	}

	function set_cakebaker(address _new_address) public onlyOperator
	{
		address_cakebaker = _new_address;
		emit SetCakeBakerCB(msg.sender, _new_address);
	}

	function get_pool_count() external view returns(uint256)
	{
		return pool_info.length;
	}
	
	function set_deposit_fee_e6(uint256[] memory _pool_id_list, uint256 _fee_e6) public onlyOperator
	{
		require(_pool_id_list.length > 0, "set_deposit_fee_e6: Empty pool list.");
		require(_fee_e6 <= MAX_DEPOSIT_FEE_E6, "set_deposit_fee_e6: Maximun deposit fee exceeded.");
		
		for(uint256 i=0; i<_pool_id_list.length; i++)
		{
			uint256 _pool_id = _pool_id_list[i];
			require(_pool_id < pool_info.length, "set_deposit_fee_e6: Wrong pool id.");
			
			FeeInfo storage cur_fee = fee_info[_pool_id];
			cur_fee.deposit_e6 = _fee_e6;

			emit SetDepositFeeCB(msg.sender, _pool_id, _fee_e6);
		}
	}

	function set_withdrawal_fee_e6(uint256[] memory _pool_id_list, uint256 _fee_max_e6, uint256 _fee_min_e6, uint256 _period_block_count) external onlyOperator
	{
		require(_pool_id_list.length > 0, "set_withdrawal_fee_e6: Empty pool list.");
		require(_fee_max_e6 <= MAX_WITHDRAWAL_FEE_E6, "set_withdrawal_fee_e6: Maximun fee exceeded.");
		require(_fee_min_e6 <= _fee_max_e6, "set_withdrawal_fee_e6: Wrong withdrawal fee");
		
		for(uint256 i=0; i<_pool_id_list.length; i++)
		{
			uint256 _pool_id = _pool_id_list[i];
			require(_pool_id < pool_info.length, "set_withdrawal_fee: Wrong pool id.");

			FeeInfo storage cur_fee = fee_info[_pool_id];
			cur_fee.withdrawal_max_e6 = _fee_max_e6;
			cur_fee.withdrawal_min_e6 = _fee_min_e6;
			cur_fee.withdrawal_period_block_count = _period_block_count;

			emit SetWithdrawalFeeCB(msg.sender, i, _fee_max_e6, _fee_min_e6, _period_block_count);
		}
	}

	function extend_mint_period(address _address_token_reward, uint256 _period_block_count) external onlyOperator
	{
		require(_period_block_count > 0, "extend_mint_period: Wrong period");

		RewardInfo storage reward = reward_info[_address_token_reward];
		reward.emission_end_block_id += _period_block_count;

		emit ExtendMintPeriodCB(msg.sender, _address_token_reward, _period_block_count);
	}

	function set_alloc_point(uint256 _pool_id, uint256 _alloc_point) external onlyOperator
	{
		require(_pool_id < pool_info.length, "set_alloc_point: Wrong pool id.");

		refresh_reward_per_share_all();

		PoolInfo storage pool = pool_info[_pool_id];
		RewardInfo storage reward = reward_info[pool.address_token_reward];

		reward.total_alloc_point += _alloc_point;
		reward.total_alloc_point -= pool.alloc_point;

		pool.alloc_point = _alloc_point;

		emit SetAllocPointCB(msg.sender, _pool_id, _alloc_point);
	}

	function set_emission_per_block(address _address_reward, uint256 _emission_per_block) external onlyOperator
	{
		require(_address_reward != address(0), "set_emission_per_block: Wrong address");

		refresh_reward_per_share_all();

		reward_info[_address_reward].emission_per_block = _emission_per_block;
		
		emit UpdateEmissionRateCB(msg.sender, _emission_per_block);
	}

	function pause() external onlyOperator
	{
		_pause();
	}

	function resume() external onlyOperator
	{
		_unpause();
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "./Bullish.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract BullishDrill is Bullish
{
	constructor(address _address_nft, address _address_chick) Bullish(_address_nft)
	{
		set_chick(_address_chick);
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Interface
//---------------------------------------------------------
interface ICakeBaker
{
	function add_pancake_farm(uint256 _pancake_pool_id, address _address_lp) external returns(uint256);
	function delegate(address _from, address _address_lp, uint256 _amount) external returns(uint256);
	function retain(address _to, address _address_lp, uint256 _amount) external returns(uint256);
	function harvest() external;
	function handle_stuck(address _token, uint256 _amount, address _to) external;
	function set_address_reward_vault(address _new_address) external;
	function set_operator(address _new_address) external;
	function set_controller(address _new_controller) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Interface
//---------------------------------------------------------
interface IChick
{
	function make_juice(address _address_token) external;
	function set_operator(address _new_operator) external;
	function set_address_token(address _address_arrow, address _address_target) external;
	function set_bnb_per_busd_vault_ratio(uint256 _bnd_ratio) external;
	function set_swap_threshold(uint256 _threshold) external;
	function handle_stuck(address _address_token, uint256 _amount, address _to) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Interface
//---------------------------------------------------------
interface ITokenXBaseV3
{
	function mint(address _to, uint256 _amount) external;
	function burn(uint256 _amount) external;
	function set_operator(address _new_operator) external;
	function set_controller(address _new_controller, bool _is_set) external;
	function set_chick(address _new_chick) external;
	function set_chick_work(bool _is_work) external;
	function set_total_supply_limit(uint256 _amount) external;
	function set_tax_free(address _to, bool _is_free) external;
	function set_sell_amount_limit(address _address_to_limit, uint256 _limit) external;
	function toggle_block_send(address[] memory _accounts, bool _is_blocked) external;
	function toggle_block_recv(address[] memory _accounts, bool _is_blocked) external;
	function set_send_tax_e6(uint256 _tax_rate, uint256 _tax_with_nft_rate) external;
	function set_recv_tax_e6(uint256 _tax_rate, uint256 _tax_with_nft_rate) external;
	function set_address_xnft(address _address_xnft) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >= 0.8.17;

//---------------------------------------------------------
// Imports
//---------------------------------------------------------
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

//---------------------------------------------------------
// Contract
//---------------------------------------------------------
contract XNFTHolder is Pausable, ERC1155Holder
{
	struct GradeInfo
	{
		uint256 grade_prefix;
		uint256 tvl_boost_rate_e6;
	}

	struct UserNFTInfo
	{
		mapping(uint256 => uint16) xnft_exist; // xnft_id / xnft_exist
		uint256[] used_xnft_ids;
		uint256 xnft_amount;
		uint256 tvl_boost_rate_e6;
	}

	struct PoolNFTInfo
	{
		uint256 tvl_boost_rate_e6;
		address[] address_user_list;
		mapping(address => UserNFTInfo) user_info; // user_adddress / user_info
	}

	address public address_operator;
	address public address_nft;

	mapping(uint256 => GradeInfo) public grade_info; // grade_id(1, 2, 3...) / grade_info
	mapping(uint256 => PoolNFTInfo) public pool_nft_info; // pool_id / pool_nft_info
	mapping(address => uint256) public user_total_staked_amount; // user_address / staked_amount

	uint16 internal constant NFT_NOT_USED = 0;
	uint16 internal constant NFT_EXIST = 1;
	uint16 internal constant NFT_NOT_EXIST = 2;

	//---------------------------------------------------------------
	// Front-end connectors
	//---------------------------------------------------------------
	event SetOperatorCB(address indexed operator, address _new_operator);
	event DepositNFTs(address indexed user, uint256 indexed pool_id, uint256[] xnft_ids);
	event WithdrawNFTs(address indexed user, uint256 indexed pool_id, uint256[] xnft_ids);

	//---------------------------------------------------------------
	// Modifier
	//---------------------------------------------------------------
	modifier onlyOperator() { require(msg.sender == address_operator, "onlyOperator: not authorized"); _; }

	//---------------------------------------------------------------
	// External Method
	//---------------------------------------------------------------
	constructor(address _address_nft)
	{
		address_operator = msg.sender;
		address_nft = _address_nft;
	} 

	function deposit_nfts(uint256 _pool_id, uint256[] memory _xnft_ids) public
	{
		for(uint256 i=0; i<_xnft_ids.length; i++)
			_deposit_nft(_pool_id, _xnft_ids[i]);

		emit DepositNFTs(msg.sender, _pool_id, _xnft_ids);
	}

	function withdraw_nfts(uint256 _pool_id, uint256[] memory _xnft_ids) public
	{
		for(uint256 i=0; i<_xnft_ids.length; i++)
			_withdraw_nft(_pool_id, _xnft_ids[i]);

		emit WithdrawNFTs(msg.sender, _pool_id, _xnft_ids);
	}

	function refresh_pool_boost_rate(uint256 _pool_id) public onlyOperator
	{
		PoolNFTInfo storage pool = pool_nft_info[_pool_id];
		pool.tvl_boost_rate_e6 = 0;

		if(pool.address_user_list.length == 0)
			return;
	
		for(uint256 i=0; i < pool.address_user_list.length; i++)
		{
			UserNFTInfo storage user = pool.user_info[pool.address_user_list[i]];
			user.tvl_boost_rate_e6 = 0;

			if(user.xnft_amount == 0)
				continue;

			for(uint256 j=0; j<user.used_xnft_ids.length; j++)
			{
				uint256 nft_id = user.used_xnft_ids[j];
				if(user.xnft_exist[nft_id] == NFT_EXIST)
				{
					uint256 boost_rate = _get_nft_boost_rate(nft_id);
					user.tvl_boost_rate_e6 += boost_rate;
				}
			}
			
			pool.tvl_boost_rate_e6 += user.tvl_boost_rate_e6;
		}
	}

	//function emergency_withdraw_nft(uint256 _pool_id) internal
	function emergency_withdraw_nft(uint256 _pool_id) public
	{
		address _address_user = msg.sender;
		PoolNFTInfo storage pool = pool_nft_info[_pool_id];
		UserNFTInfo storage user = pool.user_info[_address_user];
		require(user.xnft_amount > 0, "emergency_withdraw_nft: insufficient amount");

		IERC1155 stake_token = IERC1155(address_nft);
		uint256[] memory xnft_ids = get_deposit_nft_list(_pool_id);
		for(uint256 i=0; i<xnft_ids.length; i++)
		{
			// Holder -> User
			stake_token.safeTransferFrom(address(this), _address_user, xnft_ids[i], 1, "");
			user.xnft_exist[xnft_ids[i]] = NFT_NOT_EXIST;
		}

		user.xnft_amount = 0;
		user.tvl_boost_rate_e6 = 0;

		refresh_pool_boost_rate(_pool_id);
	}

	function handle_stuck_nft(address _address_user, address _address_nft, uint256 _nft_id, uint256 _amount) public onlyOperator
	{
		require(_address_user != address(0), "handle_stuck_nft: Wrong sender address");
		require(_address_nft != address_nft, "handle_stuck_nft: Wrong token address");
		require(_nft_id > 0, "handle_stuck_nft: Invalid NFT id");
		require(_amount > 0, "handle_stuck_nft: Invalid amount");

		IERC1155 nft = IERC1155(_address_nft);
		nft.safeTransferFrom(address(this), _address_user, _nft_id, _amount, "");
	}

	//---------------------------------------------------------------
	// Internal Method
	//---------------------------------------------------------------
	function _deposit_nft(uint256 _pool_id, uint256 _xnft_id) public
	{
		require(IERC1155(address_nft).balanceOf(msg.sender, _xnft_id) > 0, "deposit_nft: does not own NFT");
		require(msg.sender != address(0), "deposit_nft: Wrong sender address");

		address _address_user = msg.sender;
		PoolNFTInfo storage pool = pool_nft_info[_pool_id];
		UserNFTInfo storage user = pool.user_info[_address_user];

		// User -> Holder
		IERC1155 stake_token = IERC1155(address_nft);
		stake_token.safeTransferFrom(_address_user, address(this), _xnft_id, 1, "");

		_add_nft_id(user, _xnft_id);
		user_total_staked_amount[_address_user]++;

		uint256 boost_rate = _get_nft_boost_rate(_xnft_id);
		pool.tvl_boost_rate_e6 += boost_rate;
		user.tvl_boost_rate_e6 += boost_rate;

		if(user.used_xnft_ids.length == 0)
			pool.address_user_list.push(_address_user);
	}

	function _withdraw_nft(uint256 _pool_id, uint256 _xnft_id) public
	{
		require(IERC1155(address_nft).balanceOf(address(this), _xnft_id) > 0, "_withdraw_nft: does not own NFT");
		require(msg.sender != address(0), "_withdraw_nft: Wrong sender address");

		address _address_user = msg.sender;
		PoolNFTInfo storage pool = pool_nft_info[_pool_id];
		UserNFTInfo storage user = pool.user_info[_address_user];
		
		require(user.xnft_amount > 0, "_withdraw_nft: insufficient amount");
		require(user.xnft_exist[_xnft_id] == NFT_EXIST, "_withdraw_nft: does not own NFT");

		// Holder -> User
		IERC1155 stake_token = IERC1155(address_nft);
		stake_token.safeTransferFrom(address(this), _address_user, _xnft_id, 1, "");

		_remove_nft_id(user, _xnft_id);
		user_total_staked_amount[_address_user]--;

		uint256 boost_rate = _get_nft_boost_rate(_xnft_id);
		pool.tvl_boost_rate_e6 -= boost_rate;
		user.tvl_boost_rate_e6 -= boost_rate;
	}
	
	function _add_nft_id(UserNFTInfo storage user, uint256 _xnft_id) internal
	{
		user.xnft_amount++;
		
		if(user.xnft_exist[_xnft_id] == NFT_NOT_USED)
			user.used_xnft_ids.push(_xnft_id);
		
		user.xnft_exist[_xnft_id] = NFT_EXIST;
	}

	function _remove_nft_id(UserNFTInfo storage user, uint256 _xnft_id) internal
	{
		user.xnft_amount--;
		user.xnft_exist[_xnft_id] = NFT_NOT_EXIST;
	}

	function _get_nft_grade(uint256 _xnft_id) internal view returns(uint256)
	{
		for(uint256 grade=2; grade<127; grade++)
		{
			if(grade_info[grade].grade_prefix == 0 || grade_info[grade].grade_prefix > _xnft_id)
				return grade-1;
		}

		return 1;
	}

	function _get_nft_boost_rate(uint256 _xnft_id) internal view returns(uint256)
	{
		uint256 grade = _get_nft_grade(_xnft_id);
		return grade_info[grade].tvl_boost_rate_e6;
	}
	
	//---------------------------------------------------------------
	// Variable Interfaces
	//---------------------------------------------------------------
	//function set_boost_rate_e6(uint256 grade, uint256 _tvl_boost_rate_e6) external onlyOperator whenPaused
	function set_boost_rate_e6(uint256 grade, uint256 _tvl_boost_rate_e6) external onlyOperator
	{
		GradeInfo storage cur_grade_info = grade_info[grade];
		cur_grade_info.grade_prefix = grade * 1e6;
		cur_grade_info.tvl_boost_rate_e6 = _tvl_boost_rate_e6;
	}

	function get_pool_tvl_boost_rate_e6(uint256 _pool_id) public view returns(uint256)
	{
		PoolNFTInfo storage pool = pool_nft_info[_pool_id];
		return pool.tvl_boost_rate_e6;
	}

	function get_user_tvl_boost_rate_e6(uint256 _pool_id, address _address_user) public view returns(uint256)
	{
		PoolNFTInfo storage pool = pool_nft_info[_pool_id];
		UserNFTInfo storage user = pool.user_info[_address_user];
		return user.tvl_boost_rate_e6;
	}
	
	function get_deposit_nft_amount(uint256 _pool_id) public view returns(uint256)
	{
		address _address_user = msg.sender;
		PoolNFTInfo storage pool = pool_nft_info[_pool_id];
		UserNFTInfo storage user = pool.user_info[_address_user];
		return user.xnft_amount;
	}

	function get_deposit_nft_list(uint256 _pool_id) public view returns(uint256[] memory) 
	{
		address _address_user = msg.sender;
		PoolNFTInfo storage pool = pool_nft_info[_pool_id];
		UserNFTInfo storage user = pool.user_info[_address_user];
		if(user.xnft_amount == 0)
			return new uint256[](0);

		uint256 cur_len = 0;
		uint256[] memory id_list = new uint256[](user.xnft_amount);
		for(uint256 i=0; i<user.used_xnft_ids.length; i++)
		{
			uint256 nft_id = user.used_xnft_ids[i];
			if(user.xnft_exist[nft_id] == NFT_EXIST)
			{
				id_list[cur_len] = nft_id;
				cur_len++;
			}
		}

		return id_list;
	}

	function set_operator(address _new_operator) external onlyOperator
	{
		require(_new_operator != address(0), "set_operator: Wrong address");
		address_operator = _new_operator;
		emit SetOperatorCB(msg.sender, _new_operator);
	}
}