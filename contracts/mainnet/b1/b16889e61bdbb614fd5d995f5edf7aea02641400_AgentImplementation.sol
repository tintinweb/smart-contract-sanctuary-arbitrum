/**
 *Submitted for verification at Arbiscan on 2023-07-21
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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

interface IParam {
    /// @notice LogicBatch is signed by a signer using EIP-712
    struct LogicBatch {
        Logic[] logics; // An array of `Logic` structs to be executed
        Fee[] fees; // An array of `Fee` structs to be charged
        uint256 deadline; // The deadline for a signer's signature
    }

    /// @notice Logic represents a single action to be executed
    struct Logic {
        address to; // The target address for the execution
        bytes data; // Encoded function calldata
        Input[] inputs; // An array of `Input` structs for amount calculation and token approval
        WrapMode wrapMode; // Determines if wrap or unwrap native
        address approveTo; // The address to approve tokens for if different from `to` such as a spender contract
        address callback; // The address allowed to make a one-time call to the agent
    }

    /// @notice Input represents a single input for token amount calculation and approval
    struct Input {
        address token; // Token address
        uint256 balanceBps; // Basis points for calculating the amount, set 0 to use amountOrOffset as amount
        uint256 amountOrOffset; // Read as amount if balanceBps is 0; otherwise, read as byte offset of amount in `Logic.data` for replacement, or set 1 << 255 for no replacement
    }

    /// @notice Fee represents a fee to be charged
    struct Fee {
        address token; // The token address
        uint256 amount; // The fee amount
        bytes32 metadata; // Metadata related to the fee
    }

    /// @notice WrapMode determines how to handle native during execution
    enum WrapMode {
        NONE, // No wrapping or unwrapping of native
        WRAP_BEFORE, // Wrap native before calling `Logic.to`
        UNWRAP_AFTER // Unwrap native after calling `Logic.to`
    }
}

interface IAgent {
    event AmountReplaced(uint256 i, uint256 j, uint256 amount);

    event FeeCharged(address indexed token, uint256 amount, bytes32 metadata);

    error Initialized();

    error NotRouter();

    error NotCallback();

    error InvalidBps();

    error UnresetCallbackWithCharge();

    function router() external returns (address);

    function wrappedNative() external returns (address);

    function initialize() external;

    function execute(IParam.Logic[] calldata logics, address[] calldata tokensReturn) external payable;

    function executeWithSignerFee(
        IParam.Logic[] calldata logics,
        IParam.Fee[] calldata fees,
        address[] calldata tokensReturn
    ) external payable;

    function executeByCallback(IParam.Logic[] calldata logics) external payable;
}

interface IRouter {
    event SignerAdded(address indexed signer);

    event SignerRemoved(address indexed signer);

    event FeeCollectorSet(address indexed feeCollector_);

    event PauserSet(address indexed pauser);

    event Paused();

    event Unpaused();

    event Execute(address indexed user, address indexed agent, uint256 indexed referralCode);

    event AgentCreated(address indexed agent, address indexed user);

    error NotReady();

    error InvalidPauser();

    error AlreadyPaused();

    error NotPaused();

    error InvalidFeeCollector();

    error InvalidNewPauser();

    error SignatureExpired(uint256 deadline);

    error InvalidSigner(address signer);

    error InvalidSignature();

    error AgentAlreadyCreated();

    function agentImplementation() external view returns (address);

    function agents(address user) external view returns (IAgent);

    function signers(address signer) external view returns (bool);

    function currentUser() external view returns (address);

    function feeCollector() external view returns (address);

    function pauser() external view returns (address);

    function owner() external view returns (address);

    function domainSeparator() external view returns (bytes32);

    function getAgent(address user) external view returns (address);

    function getCurrentUserAgent() external view returns (address, address);

    function calcAgent(address user) external view returns (address);

    function addSigner(address signer) external;

    function removeSigner(address signer) external;

    function setFeeCollector(address feeCollector_) external;

    function setPauser(address pauser_) external;

    function rescue(address token, address receiver, uint256 amount) external;

    function pause() external;

    function unpause() external;

    function execute(
        IParam.Logic[] calldata logics,
        address[] calldata tokensReturn,
        uint256 referralCode
    ) external payable;

    function executeWithSignerFee(
        IParam.LogicBatch calldata logicBatch,
        address signer,
        bytes calldata signature,
        address[] calldata tokensReturn,
        uint256 referralCode
    ) external payable;

    function newAgent() external returns (address);

    function newAgent(address user) external returns (address);
}

interface IFeeCalculator {
    /// @notice Get fee array by `to` and `data`
    function getFees(address to, bytes calldata data) external view returns (IParam.Fee[] memory);

    /// @notice Return updated `data` with fee included
    function getDataWithFee(bytes calldata data) external view returns (bytes memory);
}

interface IFeeGenerator {
    function getFeeCalculator(bytes4 selector, address to) external view returns (address feeCalculator);

    function getNativeFeeCalculator() external view returns (address nativeFeeCalculator);
}

interface IWrappedNative {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}

interface IERC20Usdt {
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external;
}

/// @title Approve helper
/// @notice Contains helper methods for interacting with ERC20 tokens that have inconsistent implementation
library ApproveHelper {
    function _approveMax(address token, address to, uint256 amount) internal {
        if (IERC20Usdt(token).allowance(address(this), to) < amount) {
            try IERC20Usdt(token).approve(to, type(uint256).max) {} catch {
                IERC20Usdt(token).approve(to, 0);
                IERC20Usdt(token).approve(to, type(uint256).max);
            }
        }
    }
}

/// @title Agent implementation contract
/// @notice Delegated by all users' agents
contract AgentImplementation is IAgent, ERC721Holder, ERC1155Holder {
    using SafeERC20 for IERC20;
    using Address for address;
    using Address for address payable;

    /// @dev Flag for identifying the initialized state and reducing gas cost when resetting `_callbackWithCharge`
    bytes32 internal constant _INIT_CALLBACK_WITH_CHARGE = bytes32(bytes20(address(1)));

    /// @dev Flag for identifying whether to charge fee determined by the least significant bit of `_callbackWithCharge`
    bytes32 internal constant _CHARGE_MASK = bytes32(uint256(1));

    /// @dev Flag for identifying the native address such as ETH on Ethereum
    address internal constant _NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Flag for identifying any address in router's fee calculators mapping
    address internal constant _ANY_TO_ADDRESS = address(0);

    /// @dev Denominator for calculating basis points
    uint256 internal constant _BPS_BASE = 10_000;

    /// @dev Flag for identifying when basis points calculation is not applied
    uint256 internal constant _BPS_NOT_USED = 0;

    /// @dev Flag for identifying no replacement of the amount by setting the most significant bit to 1 (1<<255)
    uint256 internal constant _OFFSET_NOT_USED = 0x8000000000000000000000000000000000000000000000000000000000000000;

    /// @notice Immutable address for recording the router address
    address public immutable router;

    /// @notice Immutable address for recording wrapped native address such as WETH on Ethereum
    address public immutable wrappedNative;

    /// @dev Transient packed address and flag for recording a valid callback and a charge fee flag
    bytes32 internal _callbackWithCharge;

    /// @dev Create the agent implementation contract
    constructor(address wrappedNative_) {
        router = msg.sender;
        wrappedNative = wrappedNative_;
    }

    /// @notice Initialize user's agent and can only be called once.
    function initialize() external {
        if (_callbackWithCharge != bytes32(0)) revert Initialized();
        _callbackWithCharge = _INIT_CALLBACK_WITH_CHARGE;
    }

    /// @notice Execute arbitrary logics and is only callable by the router. Charge fee based on the scenarios defined
    ///         in the router.
    /// @dev The router is designed to prevent reentrancy so additional prevention is not needed here
    /// @param logics Array of logics to be executed
    /// @param tokensReturn Array of ERC-20 tokens to be returned to the current user
    function execute(IParam.Logic[] calldata logics, address[] calldata tokensReturn) external payable {
        if (msg.sender != router) revert NotRouter();

        _chargeFeeByMsgValue();

        _executeLogics(logics, true);

        _returnTokens(tokensReturn);
    }

    /// @notice Execute arbitrary logics and is only callable by the router using a signer's signature
    /// @dev The router is designed to prevent reentrancy so additional prevention is not needed here
    /// @param logics Array of logics to be executed
    /// @param fees Array of fees
    /// @param tokensReturn Array of ERC-20 tokens to be returned to the current user
    function executeWithSignerFee(
        IParam.Logic[] calldata logics,
        IParam.Fee[] calldata fees,
        address[] calldata tokensReturn
    ) external payable {
        if (msg.sender != router) revert NotRouter();

        _chargeFee(fees);

        _executeLogics(logics, false);

        _returnTokens(tokensReturn);
    }

    /// @notice Execute arbitrary logics and is only callable by a valid callback. Charge fee based on the scenarios
    ///         defined in the router if the charge bit is set.
    /// @dev A valid callback address is set during `_executeLogics` and reset here
    /// @param logics Array of logics to be executed
    function executeByCallback(IParam.Logic[] calldata logics) external payable {
        bytes32 callbackWithCharge = _callbackWithCharge;

        // Revert if msg.sender is not equal to the callback address
        if (msg.sender != address(bytes20(callbackWithCharge))) revert NotCallback();

        // Check the least significant bit to determine whether to charge fee
        bool shouldChargeFeeByLogic = (callbackWithCharge & _CHARGE_MASK) != bytes32(0);

        // Reset immediately to prevent reentrancy
        // If reentrancy is not blocked, an attacker could manipulate the callback contract to compel agent to execute
        // malicious logic, such as transferring funds from agents and users.
        _callbackWithCharge = _INIT_CALLBACK_WITH_CHARGE;

        // Execute logics with the charge fee flag
        _executeLogics(logics, shouldChargeFeeByLogic);
    }

    function _getBalance(address token) internal view returns (uint256 balance) {
        if (token == _NATIVE) {
            balance = address(this).balance;
        } else {
            balance = IERC20(token).balanceOf(address(this));
        }
    }

    function _executeLogics(IParam.Logic[] calldata logics, bool shouldChargeFeeByLogic) internal {
        // Execute each logic
        uint256 logicsLength = logics.length;
        for (uint256 i; i < logicsLength; ) {
            address to = logics[i].to;
            bytes memory data = logics[i].data;
            IParam.Input[] calldata inputs = logics[i].inputs;
            IParam.WrapMode wrapMode = logics[i].wrapMode;
            address approveTo = logics[i].approveTo;

            // Default `approveTo` is same as `to` unless `approveTo` is set
            if (approveTo == address(0)) {
                approveTo = to;
            }

            // Execute each input if need to modify the amount or do approve
            uint256 value;
            uint256 wrappedAmount;
            uint256 inputsLength = inputs.length;
            for (uint256 j; j < inputsLength; ) {
                address token = inputs[j].token;
                uint256 balanceBps = inputs[j].balanceBps;

                // Calculate native or token amount
                // 1. if balanceBps is `_BPS_NOT_USED`, then `amountOrOffset` is interpreted directly as the amount.
                // 2. if balanceBps isn't `_BPS_NOT_USED`, then the amount is calculated by the balance with bps
                uint256 amount;
                if (balanceBps == _BPS_NOT_USED) {
                    amount = inputs[j].amountOrOffset;
                } else {
                    if (balanceBps > _BPS_BASE) revert InvalidBps();

                    if (token == wrappedNative && wrapMode == IParam.WrapMode.WRAP_BEFORE) {
                        // Use the native balance for amount calculation as wrap will be executed later
                        amount = (address(this).balance * balanceBps) / _BPS_BASE;
                    } else {
                        amount = (_getBalance(token) * balanceBps) / _BPS_BASE;
                    }

                    // Check if the calculated amount should replace the data at the offset. For most protocols that use
                    // `msg.value` to pass the native amount, use `_OFFSET_NOT_USED` to indicate no replacement.
                    uint256 offset = inputs[j].amountOrOffset;
                    if (offset != _OFFSET_NOT_USED) {
                        assembly {
                            let loc := add(add(data, 0x24), offset) // 0x24 = 0x20(data_length) + 0x4(sig)
                            mstore(loc, amount)
                        }
                    }
                    emit AmountReplaced(i, j, amount);
                }

                if (token == wrappedNative && wrapMode == IParam.WrapMode.WRAP_BEFORE) {
                    // Use += to accumulate amounts with multiple WRAP_BEFORE, although such cases are rare
                    wrappedAmount += amount;
                }

                if (token == _NATIVE) {
                    value += amount;
                } else if (token != approveTo) {
                    ApproveHelper._approveMax(token, approveTo, amount);
                }

                unchecked {
                    ++j;
                }
            }

            if (wrapMode == IParam.WrapMode.WRAP_BEFORE) {
                // Wrap native before the call
                IWrappedNative(wrappedNative).deposit{value: wrappedAmount}();
            } else if (wrapMode == IParam.WrapMode.UNWRAP_AFTER) {
                // Or store the before wrapped native amount for calculation after the call
                wrappedAmount = _getBalance(wrappedNative);
            }

            // Set callback who should enter one-time `executeByCallback`
            if (logics[i].callback != address(0)) {
                bytes32 callback = bytes32(bytes20(logics[i].callback));
                if (shouldChargeFeeByLogic) {
                    // Set the least significant bit
                    _callbackWithCharge = callback | _CHARGE_MASK;
                } else {
                    _callbackWithCharge = callback;
                }
            }

            // Execute and send native
            if (data.length == 0) {
                payable(to).sendValue(value);
            } else {
                to.functionCallWithValue(data, value, 'ERROR_ROUTER_EXECUTE');
            }

            // Revert if the previous call didn't enter `executeByCallback`
            if (_callbackWithCharge != _INIT_CALLBACK_WITH_CHARGE) revert UnresetCallbackWithCharge();

            // Charge fee before unwrap to prevent insufficient wrapped native
            if (shouldChargeFeeByLogic) {
                _chargeFeeByLogic(logics[i]);
            }

            // Unwrap to native after the call
            if (wrapMode == IParam.WrapMode.UNWRAP_AFTER) {
                IWrappedNative(wrappedNative).withdraw(_getBalance(wrappedNative) - wrappedAmount);
            }

            unchecked {
                ++i;
            }
        }
    }

    function _chargeFeeByMsgValue() internal {
        if (msg.value == 0) return;

        address nativeFeeCalculator = IFeeGenerator(router).getNativeFeeCalculator();
        if (nativeFeeCalculator != address(0)) {
            _chargeFee(IFeeCalculator(nativeFeeCalculator).getFees(_ANY_TO_ADDRESS, abi.encodePacked(msg.value)));
        }
    }

    function _chargeFeeByLogic(IParam.Logic calldata logic) internal {
        bytes memory data = logic.data;
        bytes4 selector = bytes4(data);
        address to = logic.to;

        address feeCalculator = IFeeGenerator(router).getFeeCalculator(selector, to);
        if (feeCalculator != address(0)) {
            _chargeFee(IFeeCalculator(feeCalculator).getFees(to, data));
        }
    }

    function _chargeFee(IParam.Fee[] memory fees) internal {
        uint256 length = fees.length;
        if (length == 0) return;

        address feeCollector = IRouter(router).feeCollector();
        for (uint256 i; i < length; ) {
            uint256 amount = fees[i].amount;
            if (amount == 0) {
                unchecked {
                    ++i;
                }
                continue;
            }

            address token = fees[i].token;
            if (token == _NATIVE) {
                payable(feeCollector).sendValue(amount);
            } else {
                IERC20(token).safeTransfer(feeCollector, amount);
            }

            emit FeeCharged(token, amount, fees[i].metadata);
            unchecked {
                ++i;
            }
        }
    }

    function _returnTokens(address[] calldata tokensReturn) internal {
        // Return tokens to the current user if any balance
        uint256 tokensReturnLength = tokensReturn.length;
        if (tokensReturnLength > 0) {
            address user = IRouter(router).currentUser();
            for (uint256 i; i < tokensReturnLength; ) {
                address token = tokensReturn[i];
                if (token == _NATIVE) {
                    payable(user).sendValue(address(this).balance);
                } else {
                    uint256 balance = IERC20(token).balanceOf(address(this));
                    IERC20(token).safeTransfer(user, balance);
                }

                unchecked {
                    ++i;
                }
            }
        }
    }
}