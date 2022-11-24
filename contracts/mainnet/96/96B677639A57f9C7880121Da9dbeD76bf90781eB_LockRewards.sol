/**
 *Submitted for verification at Arbiscan on 2022-11-24
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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


// File contracts/interfaces/ILockRewards.sol

 
pragma solidity ^0.8.15;

interface ILockRewards {
    // Functions
    function balanceOf(address owner) external view returns (uint256);
    function balanceOfInEpoch(address owner, uint256 epochId) external view returns (uint256);
    function totalLocked() external view returns (uint256);
    function getCurrentEpoch() external view returns (uint256 start, uint256 finish, uint256 locked, uint256 rewards1, uint256 rewards2, bool isSet);
    function getNextEpoch() external view returns (uint256 start, uint256 finish, uint256 locked, uint256 rewards1, uint256 rewards2, bool isSet);
    function getEpoch(uint256 epochId) external view returns (uint256 start, uint256 finish, uint256 locked, uint256 rewards1, uint256 rewards2, bool isSet);
    function getAccount(address owner) external view returns (uint256 balance, uint256 lockEpochs, uint256 lastEpochPaid, uint256 rewards1, uint256 rewards2);
    function getEpochAccountInfo(address owner, uint256 epochId) external view returns (uint256 balance, uint256 start, uint256 finish, uint256 locked, uint256 userRewards1, uint256 userRewards2, bool isSet);
    function updateAccount() external returns (uint256 balance, uint256 lockEpochs, uint256 lastEpochPaid, uint256 rewards1, uint256 rewards2);
    function deposit(uint256 amount, uint256 lockEpochs) external;
    function withdraw(uint256 amount) external;
    function claimReward() external returns(uint256, uint256);
    function exit() external returns(uint256, uint256);
    function setNextEpoch(uint256 reward1, uint256 reward2, uint256 epochDurationInDays) external;
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external;
    function changeRecoverWhitelist(address tokenAddress, bool flag) external;
    function recoverERC721(address tokenAddress, uint256 tokenId) external;
    function changeEnforceTime(bool flag) external;
    function changeMaxEpochs(uint256 _maxEpochs) external;
    
    // Events
    event Deposit(address indexed user, uint256 amount, uint256 lockedEpochs);
    event Relock(address indexed user, uint256 totalBalance, uint256 lockedEpochs);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address token, uint256 reward);
    event SetNextReward(uint256 indexed epochId, uint256 reward1, uint256 reward2, uint256 start, uint256 finish);
    event RecoveredERC20(address token, uint256 amount);
    event RecoveredERC721(address token, uint256 tokenId);
    event ChangeERC20Whiltelist(address token, bool tokenState);
    event ChangeEnforceTime(uint256 indexed currentTime, bool flag);
    event ChangeMaxLockEpochs(uint256 indexed currentTime, uint256 oldEpochs, uint256 newEpochs);
    
    // Errors
    error InsufficientAmount();
    error InsufficientBalance();
    error FundsInLockPeriod(uint256 balance);
    error InsufficientFundsForRewards(address token, uint256 available, uint256 rewardAmount);
    error LockEpochsMax(uint256 maxEpochs);
    error LockEpochsMin(uint256 minEpochs);
    error NotWhitelisted();
    error CannotWhitelistGovernanceToken(address governanceToken);
    error EpochMaxReached(uint256 maxEpochs);
    error EpochStartInvalid(uint256 epochStart, uint256 now);
    
    // Structs
    struct Account {
        uint256 balance;
        uint256 lockEpochs;
        uint256 lastEpochPaid;
        uint256 rewards1;
        uint256 rewards2;
    }

    struct Epoch {
        mapping(address => uint256) balanceLocked;
        uint256 start;
        uint256 finish;
        uint256 totalLocked;
        uint256 rewards1;
        uint256 rewards2;
        bool    isSet;
    }

    struct RewardToken {
        address addr;
        uint256 rewards;
        uint256 rewardsPaid;
    }
}


// File contracts/LockRewards.sol

 
pragma solidity ^0.8.15;
/** @title Lock tokens and receive rewards in
 * 2 different tokens
 *  @author gcontarini jocorrei
 *  @notice The locking mechanism is based on epochs.
 * How long each epoch is going to last is up to the
 * contract owner to decide when setting an epoch with
 * the amount of rewards needed. To receive rewards, the
 * funds must be locked before the epoch start and will
 * become claimable at the epoch end. Relocking with 
 * more tokens increases the amount received moving forward.
 * But it also can relock ALL funds for longer periods.
 *  @dev Contract follows a simple owner access control implemented
 * by the Ownable contract. The contract deployer is the owner at 
 * start.
 */
contract LockRewards is ILockRewards, ReentrancyGuard, Ownable, Pausable {
    using SafeERC20 for IERC20;

    /// @dev Account hold all user information 
    mapping(address => Account) public accounts;
    /// @dev Total amount of lockTokes that the contract holds
    uint256 public totalAssets;
    address public lockToken;
    /// @dev Hold all rewardToken information like token address
    RewardToken[2] public rewardToken;
    
    /// @dev If false, allows users to withdraw their tokens before the locking end period
    bool    public enforceTime = true;
    
    /// @dev Hold all epoch information like rewards and balance locked for each user
    mapping(uint256 => Epoch) public epochs;
    uint256 public currentEpoch = 1;
    uint256 public nextUnsetEpoch = 1;
    uint256 public maxEpochs;
    uint256 public minEpochs;

    /// @dev Contract owner can whitelist an ERC20 token and withdraw its funds
    mapping(address => bool) public whitelistRecoverERC20;
    
    /**
     *  @notice maxEpochs can be changed afterwards by the contract owner
     *  @dev Owner is the deployer
     *  @param _lockToken: token address which users can deposit to receive rewards
     *  @param _rewardAddr1: token address used to pay users rewards (Governance token)
     *  @param _rewardAddr2: token address used to pay users rewards (WETH)
     *  @param _maxEpochs: max number of epochs an user can lock its funds 
     */
    constructor(
        address _lockToken,
        address _rewardAddr1,
        address _rewardAddr2,
        uint256 _maxEpochs,
        uint256 _minEpochs
    ) {
        lockToken = _lockToken;
        rewardToken[0].addr  = _rewardAddr1;  
        rewardToken[1].addr  = _rewardAddr2;  
        maxEpochs = _maxEpochs;
        minEpochs = _minEpochs;
    }

    /* ========== VIEWS ========== */
    
    /**
     *  @notice Total deposited for address in lockTokens
     *  @dev Show the total balance, not necessary it's all locked
     *  @param owner: user address
     *  @return balance: total balance of address
     */
    function balanceOf(address owner) external view returns (uint256) {
        return accounts[owner].balance;
    }

    /**
     *  @notice Shows the total of tokens locked in an epoch for an user
     *  @param owner: user address
     *  @param epochId: the epoch number
     *  @return balance: total of tokens locked for an epoch 
     */
    function balanceOfInEpoch(address owner, uint256 epochId) external view returns (uint256) {
        return epochs[epochId].balanceLocked[owner];
    }

    /**
     *  @notice Total assets that contract holds
     *  @dev Not all tokens are actually locked
     *  @return totalAssets: amount of lock Tokens deposit in this contract
     */
    function totalLocked() external view returns (uint256) {
        return totalAssets;
    }

    /**
     *  @notice Show all information for on going epoch
     */
    function getCurrentEpoch() external view returns (
        uint256 start,
        uint256 finish,
        uint256 locked,
        uint256 rewards1,
        uint256 rewards2,
        bool    isSet
    ) {
        return _getEpoch(currentEpoch);
    }

    /**
     *  @notice Show all information for next epoch
     *  @dev If next epoch is not set, return all zeros and nulls
     */
    function getNextEpoch() external view returns (
        uint256 start,
        uint256 finish,
        uint256 locked,
        uint256 rewards1,
        uint256 rewards2,
        bool    isSet
    ) {
        if (currentEpoch == nextUnsetEpoch) 
            return (0, 0, 0, 0, 0, false);
        return _getEpoch(currentEpoch + 1);
    }

    /** 
     *  @notice Show information for a given epoch
     *  @dev Start and finish values are seconds 
     *  @param epochId: number of epoch
     */
    function getEpoch(uint256 epochId) external view returns (
        uint256 start,
        uint256 finish,
        uint256 locked,
        uint256 rewards1,
        uint256 rewards2,
        bool    isSet
    ) {
        return _getEpoch(epochId);
    }
    
    /** 
     *  @notice Show information for an account 
     *  @dev LastEpochPaid tell when was the last epoch in each
     * this accounts was updated, which means receive rewards. 
     *  @param owner: address for account 
     */
    function getAccount(
        address owner
    ) external view returns (
        uint256 balance,
        uint256 lockEpochs,
        uint256 lastEpochPaid,
        uint256 rewards1,
        uint256 rewards2
    ) {
        return _getAccount(owner);
    }

    /** 
     *  @notice Show account info for next epoch payout
     *  @param owner: address for account 
     *  @param epochId: index of epoch 
     */
    function getEpochAccountInfo(
        address owner,
        uint256 epochId
    ) external view returns (
        uint256 balance,
        uint256 start,
        uint256 finish,
        uint256 locked,
        uint256 userRewards1,
        uint256 userRewards2,
        bool isSet
    ) {
        start = epochs[epochId].start; 
        finish= epochs[epochId].finish;
        isSet= epochs[epochId].isSet;
        uint256 locked = epochs[epochId].totalLocked;
        uint256 rewards1 = epochs[epochId].rewards1;
        uint256 rewards2 = epochs[epochId].rewards2;

        uint256 balance = epochs[epochId].balanceLocked[owner];
        if(balance > 0) {
        uint256 share = balance * 1e18 / locked;

        userRewards1 += share * rewards1 / 1e18;
        userRewards2 += share * rewards2 / 1e18;
        }
    }
    
    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     *  @notice Update caller account state (grant rewards if available)
     */
    function updateAccount() external whenNotPaused updateEpoch updateReward(msg.sender) returns (
        uint256 balance,
        uint256 lockEpochs,
        uint256 lastEpochPaid,
        uint256 rewards1,
        uint256 rewards2
    ) {
        return _getAccount(msg.sender);
    }

    /**
     *  @notice Deposit tokens to receive rewards.
     * In case of a relock, it will increase the total locked epochs
     * for the total amount of tokens deposited. The contract doesn't
     * allow different unlock periods for same address. Also, all
     * deposits will grant rewards for the next epoch, not the
     * current one if setted by the owner.
     *  @dev Allows relocking by setting amount to zero.
     * To increase amount locked without increasing
     * epochs locked, set lockEpochs to zero.
     *  @param amount: the amount of lock tokens to deposit
     *  @param lockEpochs: how many epochs funds will be locked.
     */
    function deposit(
        uint256 amount,
        uint256 lockEpochs
    ) external nonReentrant whenNotPaused updateEpoch updateReward(msg.sender) {
        if (lockEpochs < minEpochs) revert LockEpochsMin(minEpochs);
        if (lockEpochs > maxEpochs) revert LockEpochsMax(maxEpochs);
        IERC20 lToken = IERC20(lockToken);

        uint256 oldLockEpochs = accounts[msg.sender].lockEpochs;
        // Increase lockEpochs for user
        accounts[msg.sender].lockEpochs += lockEpochs;
        
        // This is done to save gas in case of a relock
        // Also, emits a different event for deposit or relock
        if (amount > 0) {
            lToken.safeTransferFrom(msg.sender, address(this), amount);
            totalAssets += amount;
            accounts[msg.sender].balance += amount;
        
            emit Deposit(msg.sender, amount, lockEpochs);
        } else {
            emit Relock(msg.sender, accounts[msg.sender].balance, lockEpochs);
        }
        
        // Check if current epoch is in course
        // Then, set the deposit for the upcoming ones
        uint256 _currEpoch = currentEpoch; 
        uint256 next = epochs[_currEpoch].isSet ? _currEpoch + 1 : _currEpoch;
        
        // Since all funds will be locked for the same period
        // Update all future lock epochs for this new value
        uint256 lockBoundary;
        if (!epochs[_currEpoch].isSet || oldLockEpochs == 0)
            lockBoundary = accounts[msg.sender].lockEpochs;
        else 
            lockBoundary = accounts[msg.sender].lockEpochs - 1;
        uint256 newBalance = accounts[msg.sender].balance;
        for (uint256 i = 0; i < lockBoundary;) {
            epochs[i + next].totalLocked += newBalance - epochs[i + next].balanceLocked[msg.sender];
            epochs[i + next].balanceLocked[msg.sender] = newBalance;

            unchecked { ++i; }
        }
    }

    /**
     *  @notice Allows withdraw after lockEpochs is zero 
     *  @param amount: tokens to caller receive
     */
    function withdraw(
        uint256 amount
    ) external nonReentrant whenNotPaused updateEpoch updateReward(msg.sender) {
        _withdraw(amount);
    }

    /**
     *  @notice User can receive its claimable rewards 
     */
    function claimReward() external nonReentrant whenNotPaused updateEpoch updateReward(msg.sender) returns(uint256, uint256) {
        return _claim();
    }

    /**
     *  @notice User withdraw all its funds and receive all available rewards 
     *  @dev If user funds it's still locked, all transaction will revert
     */
    function exit() external nonReentrant whenNotPaused updateEpoch updateReward(msg.sender) returns(uint256, uint256) {
        _withdraw(accounts[msg.sender].balance);
        return _claim();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */


    /**
     * @notice Pause contract. Can only be called by the contract owner.
     * @dev If contract is already paused, transaction will revert
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause contract. Can only be called by the contract owner.
     * @dev If contract is already unpaused, transaction will revert
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     *  @notice Set a new epoch. The amount needed of tokens
     * should be transfered before calling setNextEpoch. Can only
     * have 2 epochs set, the on going one and the next.
     *  @dev Can set a start epoch different from now when there's
     * no epoch on going. If there's an epoch on going, can
     * only set the start after the finish of current epoch.
     *  @param reward1: the amount of rewards to be distributed
     * in token 1 for this epoch
     *  @param reward2: the amount of rewards to be distributed
     * in token 2 for this epoch
     *  @param epochDurationInDays: how long the epoch will last
     * in days
     *  @param epochStart: the epoch start date in unix epoch (seconds) 
     */
    function setNextEpoch(
        uint256 reward1,
        uint256 reward2,
        uint256 epochDurationInDays,
        uint256 epochStart
    ) external onlyOwner updateEpoch {
        _setEpoch(reward1, reward2, epochDurationInDays, epochStart);
    }

    /**
     *  @notice Set a new epoch. The amount needed of tokens
     * should be transfered before calling setNextEpoch. Can only
     * have 2 epochs set, the on going one and the next.
     *  @dev If epoch is finished and there isn't a new to start,
     * the contract will hold. But in that case, when the next 
     * epoch is set it'll already start (meaning: start will be
     * the current block timestamp).
     *  @param reward1: the amount of rewards to be distributed
     * in token 1 for this epoch
     *  @param reward2: the amount of rewards to be distributed
     * in token 2 for this epoch
     *  @param epochDurationInDays: how long the epoch will last
     * in days
     */
    function setNextEpoch(
        uint256 reward1,
        uint256 reward2,
        uint256 epochDurationInDays
    ) external onlyOwner updateEpoch {
        _setEpoch(reward1, reward2, epochDurationInDays, block.timestamp);
    }
    
    /**
     *  @notice To recover ERC20 sent by accident.
     * All funds are only transfered to contract owner.
     *  @dev To allow a withdraw, first the token must be whitelisted
     *  @param tokenAddress: token to transfer funds
     *  @param tokenAmount: the amount to transfer to owner
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        if (whitelistRecoverERC20[tokenAddress] == false) revert NotWhitelisted();
        
        uint balance = IERC20(tokenAddress).balanceOf(address(this));
        if (balance < tokenAmount) revert InsufficientBalance(); 

        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit RecoveredERC20(tokenAddress, tokenAmount);
    }

    /**
     *  @notice  Add or remove a token from recover whitelist,
     * cannot whitelist governance token
     *  @dev Only contract owner are allowed. Emits an event
     * allowing users to perceive the changes in contract rules.
     * The contract allows to whitelist the underlying tokens
     * (both lock token and rewards tokens). This can be exploited
     * by the owner to remove all funds deposited from all users.
     * This is done bacause the owner is mean to be a multisig or
     * treasury wallet from a DAO
     *  @param flag: set true to allow recover
     */
    function changeRecoverWhitelist(address tokenAddress, bool flag) external onlyOwner {
        if (tokenAddress == rewardToken[0].addr) revert CannotWhitelistGovernanceToken(rewardToken[0].addr);
        whitelistRecoverERC20[tokenAddress] = flag;
        emit ChangeERC20Whiltelist(tokenAddress, flag);
    }

    /**
     *  @notice Allows recover for NFTs 
     */
    function recoverERC721(address tokenAddress, uint256 tokenId) external onlyOwner {
        IERC721(tokenAddress).transferFrom(address(this), owner(), tokenId);
        emit RecoveredERC721(tokenAddress, tokenId);
    }

    /**
     *  @notice Allows owner change rule to allow users' withdraw
     * before the lock period is over
     *  @dev In case a major flaw, do this to prevent users from losing
     * their funds. Also, if no more epochs are going to be setted allows 
     * users to withdraw their assets
     *  @param flag: set false to allow withdraws
     */
    function changeEnforceTime(bool flag) external onlyOwner {
        enforceTime = flag;
        emit ChangeEnforceTime(block.timestamp, flag);
    }

    /**
     *  @notice Allows owner to change the max epochs an 
     * user can lock their funds
     *  @param _maxEpochs: new value for maxEpochs
     */
    function changeMaxEpochs(uint256 _maxEpochs) external onlyOwner {
        uint256 oldEpochs = maxEpochs;
        maxEpochs = _maxEpochs;
        emit ChangeMaxLockEpochs(block.timestamp, oldEpochs, _maxEpochs);
    }
    
    /* ========== INTERNAL FUNCTIONS ========== */
    
    /**
     *  @notice Implements internal setEpoch logic
     *  @dev Can only set 2 epochs, the on going and
     * the next one. This has to be done in 2 different
     * transactions.
     *  @param reward1: the amount of rewards to be distributed
     * in token 1 for this epoch
     *  @param reward2: the amount of rewards to be distributed
     * in token 2 for this epoch
     *  @param epochDurationInDays: how long the epoch will last
     * in days
     *  @param epochStart: the epoch start date in unix epoch (seconds) 
     */
    function _setEpoch(
        uint256 reward1,
        uint256 reward2,
        uint256 epochDurationInDays,
        uint256 epochStart
    ) internal {
        if (nextUnsetEpoch - currentEpoch > 1)
            revert EpochMaxReached(2);
        if (epochStart < block.timestamp)
            revert EpochStartInvalid(epochStart, block.timestamp);

        uint256[2] memory rewards = [reward1, reward2];

        for (uint256 i = 0; i < 2;) {
            uint256 unclaimed = rewardToken[i].rewards - rewardToken[i].rewardsPaid;
            uint256 balance = IERC20(rewardToken[i].addr).balanceOf(address(this));
            
            if (balance - unclaimed < rewards[i])
                revert InsufficientFundsForRewards(rewardToken[i].addr, balance - unclaimed, rewards[i]);
            
            rewardToken[i].rewards += rewards[i];

            unchecked { ++i; }
        }
        
        uint256 next = nextUnsetEpoch;
        
        if (currentEpoch == next || epochStart > epochs[next - 1].finish + 1) {
            epochs[next].start = epochStart;
        } else {
            epochs[next].start = epochs[next - 1].finish + 1;
        }
        epochs[next].finish = epochs[next].start + (3 hours); // Seconds in a day TODO

        epochs[next].rewards1 = reward1;
        epochs[next].rewards2 = reward2;
        epochs[next].isSet = true;
        
        nextUnsetEpoch += 1;
        emit SetNextReward(next, reward1, reward2, epochs[next].start, epochs[next].finish);
    }
    
    /**
     *  @notice Implements internal withdraw logic
     *  @dev The withdraw is always done in name 
     * of caller for caller
     *  @param amount: amount of tokens to withdraw
     */
    function _withdraw(uint256 amount) internal {
        if (amount == 0 || accounts[msg.sender].balance < amount) revert InsufficientAmount();
        if (accounts[msg.sender].lockEpochs > 0 && enforceTime) revert FundsInLockPeriod(accounts[msg.sender].balance);

        IERC20(lockToken).safeTransfer(msg.sender, amount);
        totalAssets -= amount;
        accounts[msg.sender].balance -= amount;
        emit Withdrawn(msg.sender, amount);
    }

    /**
     *  @notice Implements internal claim rewards logic
     *  @dev The claim is always done in name 
     * of caller for caller
     *  @return amount of rewards transfer in token 1
     *  @return amount of rewards transfer in token 2
     */
    function _claim() internal returns(uint256, uint256) {
        uint256 reward1 = accounts[msg.sender].rewards1;
        uint256 reward2 = accounts[msg.sender].rewards2;

        if (reward1 > 0) {
            accounts[msg.sender].rewards1 = 0;
            IERC20(rewardToken[0].addr).safeTransfer(msg.sender, reward1);
            emit RewardPaid(msg.sender, rewardToken[0].addr, reward1);
        }
        if (reward2 > 0) {
            accounts[msg.sender].rewards2 = 0;
            IERC20(rewardToken[1].addr).safeTransfer(msg.sender, reward2);
            emit RewardPaid(msg.sender, rewardToken[1].addr, reward2);
        }
        return (reward1, reward2);
    }
    
    /**
     *  @notice Implements internal getAccount logic
     *  @param owner: address to check information§
     */
    function _getAccount(
        address owner
    ) internal view returns (
        uint256 balance,
        uint256 lockEpochs,
        uint256 lastEpochPaid,
        uint256 rewards1,
        uint256 rewards2
    ) {
        return (
            accounts[owner].balance,
            accounts[owner].lockEpochs,
            accounts[owner].lastEpochPaid,
            accounts[owner].rewards1,
            accounts[owner].rewards2
        );
    }
    
    /**
     *  @notice Implements internal getEpoch logic
     *  @param epochId: the number of the epoch
     */
    function _getEpoch(uint256 epochId) internal view returns (
        uint256 start,
        uint256 finish,
        uint256 locked,
        uint256 rewards1,
        uint256 rewards2,
        bool    isSet
    ) {
        return (
            epochs[epochId].start, 
            epochs[epochId].finish,
            epochs[epochId].totalLocked,
            epochs[epochId].rewards1,
            epochs[epochId].rewards2,
            epochs[epochId].isSet
            );
    }

    /* ========== MODIFIERS ========== */
    
    modifier updateEpoch {
        uint256 current = currentEpoch;

        while (epochs[current].finish <= block.timestamp && epochs[current].isSet == true)
            current++;
        currentEpoch = current;
        _;
    }

    modifier updateReward(address owner) {
        uint256 current = currentEpoch;
        uint256 lockEpochs = accounts[owner].lockEpochs;
        uint256 lastEpochPaid = accounts[owner].lastEpochPaid;
        
        // Solve edge case for first epoch
        // since epochs starts on value 1
        if (lastEpochPaid == 0) {
            accounts[owner].lastEpochPaid = 1;
            ++lastEpochPaid;
        }

        uint256 rewardPaid1 = 0;
        uint256 rewardPaid2 = 0;
        uint256 locks = 0;

        uint256 limit = lastEpochPaid + lockEpochs; 
        if (limit > current)
            limit = current;

        for (uint256 i = lastEpochPaid; i < limit;) {
            if (epochs[i].balanceLocked[owner] == 0) {
                unchecked { ++i; }
                continue;
            }

            uint256 share = epochs[i].balanceLocked[owner] * 1e18 / epochs[i].totalLocked;

            rewardPaid1 += share * epochs[i].rewards1 / 1e18;
            rewardPaid2 += share * epochs[i].rewards2 / 1e18;
            
            unchecked { ++locks; ++i; }
        }
        rewardToken[0].rewardsPaid += rewardPaid1;
        rewardToken[1].rewardsPaid += rewardPaid2;

        accounts[owner].rewards1 += rewardPaid1;
        accounts[owner].rewards2 += rewardPaid2;
        
        accounts[owner].lockEpochs -= locks;

        if (lastEpochPaid != current)
            accounts[owner].lastEpochPaid = current;
        _;
    }
}