// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

enum ManagerAction {
  Deposit,
  Withdraw,
  AddLiquidity,
  RemoveLiquidity
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

enum VaultStrategy {
  Neutral,
  Long,
  Short
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILendingPool {
  function totalValue() external view returns (uint256);
  function totalAvailableSupply() external view returns (uint256);
  function utilizationRate() external view returns (uint256);
  function exchangeRate() external view returns (uint256);
  function borrowAPR() external view returns (uint256);
  function lendingAPR() external view returns (uint256);
  function maxRepay(address _address) external view returns (uint256);
  function deposit(uint256 _assetAmount, uint256 _minSharesAmount) external;
  function withdraw(uint256 _ibTokenAmount, uint256 _minWithdrawAmount) external;
  function borrow(uint256 _assetAmount) external;
  function repay(uint256 _repayAmount) external;
  function updateProtocolFee(uint256 _protocolFee) external;
  function withdrawReserve(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICamelotOracle {
  function lpToken(
    address _token0,
    address _token1
  ) external view returns (address);

  function getAmountsOut(
    uint256 _amountIn,
    address[] memory path
  ) external view returns (uint256[] memory amounts);

  function getAmountsIn(
    uint256 _amountOut,
    uint256 _reserveIn,
    uint256 _reserveOut,
    uint256 _fee
  ) external view returns (uint256);

  function getLpTokenReserves(
    uint256 _amount,
    address _tokenA,
    address _tokenB,
    address _pair
  ) external view returns (uint256, uint256);

  function getLpTokenFees(
    address _tokenA,
    address _tokenB,
    address _pair
  ) external view returns (uint16, uint16);

  function getLpTokenValue(
    uint256 _amount,
    address _tokenA,
    address _tokenB,
    address _pair
  ) external view returns (uint256);

  function getLpTokenAmount(
    uint256 _value,
    address _tokenA,
    address _tokenB,
    address _pair
  ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICamelotDividends {
  function harvestAllDividends() external;

  function usersAllocation(address user) external view returns (uint256);

  function pendingDividendsAmount(address tokenReward, address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICamelotPair {
  function name() external pure returns (string memory);

  function symbol() external pure returns (string memory);

  function decimals() external pure returns (uint8);

  function getReserves() external view returns(
    uint112 reserve0,
    uint112 reserve1,
    uint16 token0FeePercent,
    uint16 token1FeePercent
  );

  function totalSupply() external view returns (uint256);

  function stableSwap() external view returns (bool);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function factory() external view returns (address);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
      address from,
      address to,
      uint256 value
  ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICamelotPositionHelper {
  function addLiquidityAndCreatePosition(
    address _tokenA,
    address _tokenB,
    uint256 _amountADesired,
    uint256 _amountBDesired,
    uint256 _amountAMin,
    uint256 _amountBMin,
    uint256 _deadline,
    address _to,
    INFTPool _nftPool,
    uint256 _lockDuration
  ) external;

}

interface INFTPool is IERC721 {
  function exists(uint256 tokenId) external view returns (bool);
  function hasDeposits() external view returns (bool);
  function lastTokenId() external view returns (uint256);
  function getPoolInfo() external view returns (
    address lpToken, address grailToken, address sbtToken, uint256 lastRewardTime, uint256 accRewardsPerShare,
    uint256 lpSupply, uint256 lpSupplyWithMultiplier, uint256 allocPoint
  );
  function getStakingPosition(uint256 tokenId) external view returns (
    uint256 amount, uint256 amountWithMultiplier, uint256 startLockTime,
    uint256 lockDuration, uint256 lockMultiplier, uint256 rewardDebt,
    uint256 boostPoints, uint256 totalMultiplier
  );
  function createPosition(uint256 amount, uint256 lockDuration) external;
  function boost(uint256 userAddress, uint256 amount) external;
  function unboost(uint256 userAddress, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICamelotRouter {
  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    address referrer,
    uint deadline
  ) external;

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external;

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external;

  function getAmountsOut(
    uint amountIn,
    address[] calldata path
  ) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICamelotSpNft {
  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

  function getStakingPosition(uint256 tokenId)
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    );

  function addToPosition(uint256 tokenId, uint256 amountToAdd) external;

  function withdrawFromPosition(uint256 tokenId, uint256 amountToWithdraw) external;

  function harvestPosition(uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ICamelotXGrail {
  function allocate(
    address usageAddress,
    uint256 amount,
    bytes calldata usageData
  ) external;

  function deallocate(
    address usageAddress,
    uint256 amount,
    bytes calldata usageData
  ) external;


  function redeem(
    uint256 amount,
    uint256 duration
  ) external;

  function finalizeRedeem(
    uint256 index
  ) external;

  function approveUsage(IXGrailTokenUsage usage, uint256 amount) external;

  function minRedeemDuration() external view returns (uint256);

  function getUserRedeemsLength(address userAddress) external view returns (uint256);

  function getUserRedeem(address userAddress, uint256 index) external view returns (uint256, uint256, uint256, address, uint256);

  function getUsageAllocation(address userAddress, address usageAddress) external view returns (uint256);
}

interface IXGrailTokenUsage {
    function allocate(address userAddress, uint256 amount, bytes calldata data) external;
    function deallocate(address userAddress, uint256 amount, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../../../enum/VaultStrategy.sol";

interface ICamelotYieldFarmVault {
  struct VaultConfig {
    // Boolean for whether vault accepts the native asset (e.g. AVAX)
    bool isNativeAsset;
    // Target leverage of the vault in 1e18
    uint256 targetLeverage;
    // Target Token A debt ratio in 1e18
    uint256 tokenADebtRatio;
    // Target Token B debt ratio in 1e18
    uint256 tokenBDebtRatio;
  }

  function strategy() external view returns (VaultStrategy);
  function tokenA() external view returns (address);
  function tokenB() external view returns (address);
  function treasury() external view returns (address);
  function perfFee() external view returns (uint256);
  function chainlinkOracle() external view returns (address);
  function vaultConfig() external view returns (VaultConfig memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "@openzeppelin/contracts/utils/math/Math.sol";

library OptimalDeposit {
  function optimalDeposit(
    uint256 _amountA,
    uint256 _amountB,
    uint256 _reserveA,
    uint256 _reserveB,
    uint256 _fee
  ) internal pure returns (uint256, bool) {
    uint256 swapAmt;
    bool isReversed;

    if (_amountA * _reserveB >= _amountB * _reserveA) {
      swapAmt = _optimalDeposit(_amountA, _amountB, _reserveA, _reserveB, _fee);
      isReversed = false;
    } else {
      swapAmt = _optimalDeposit(_amountB, _amountA, _reserveB, _reserveA, _fee);
      isReversed = true;
    }

    return (swapAmt, isReversed);
  }

    function optimalDepositTwoFees(
    uint256 _amountA,
    uint256 _amountB,
    uint256 _reserveA,
    uint256 _reserveB,
    uint256 _feeA,
    uint256 _feeB
  ) internal pure returns (uint256, bool) {
    uint256 swapAmt;
    bool isReversed;

    if (_amountA * _reserveB >= _amountB * _reserveA) {
      swapAmt = _optimalDeposit(_amountA, _amountB, _reserveA, _reserveB, _feeA);
      isReversed = false;
    } else {
      swapAmt = _optimalDeposit(_amountB, _amountA, _reserveB, _reserveA, _feeB);
      isReversed = true;
    }

    return (swapAmt, isReversed);
  }

  function _optimalDeposit(
    uint256 _amountA,
    uint256 _amountB,
    uint256 _reserveA,
    uint256 _reserveB,
    uint256 _fee
  ) internal pure returns (uint256) {
      require(_amountA * _reserveB >= _amountB * _reserveA, "Reversed");

      uint256 a = 1000 - _fee;
      uint256 b = (2000 - _fee) * _reserveA;
      uint256 _c = (_amountA * _reserveB) - (_amountB * _reserveA);
      uint256 c = _c * 1000 / (_amountB + _reserveB) * _reserveA;
      uint256 d = a * c * 4;
      uint256 e = Math.sqrt(b * b + d);
      uint256 numerator = e - b;
      uint256 denominator = a * 2;

      return numerator / denominator;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../../interfaces/oracles/ICamelotOracle.sol";
import "../../interfaces/lending/ILendingPool.sol";
import "../../interfaces/vaults/camelot/ICamelotYieldFarmVault.sol";
import "../../interfaces/swaps/camelot/ICamelotRouter.sol";
import "../../interfaces/swaps/camelot/ICamelotPair.sol";
import "../../interfaces/swaps/camelot/ICamelotSpNft.sol";
import "../../interfaces/swaps/camelot/ICamelotPositionHelper.sol";
import "../../interfaces/swaps/camelot/ICamelotXGrail.sol";
import "../../interfaces/swaps/camelot/ICamelotDividends.sol";
import "../../utils/OptimalDeposit.sol";
import "../../enum/ManagerAction.sol";
import "../../enum/VaultStrategy.sol";


contract CamelotYieldFarmManager is Ownable, IERC721Receiver {
  using SafeERC20 for IERC20;

  /* ========== STATE VARIABLES ========== */

  // Router contract
  ICamelotRouter public immutable router;
  // Vault contract
  ICamelotYieldFarmVault public immutable vault;
  // Token A lending pool contract
  ILendingPool public immutable tokenALendingPool;
  // Token B lending pool contract
  ILendingPool public immutable tokenBLendingPool;
  // e.g. WETH
  IERC20 public immutable tokenA;
  // e.g. USDC
  IERC20 public immutable tokenB;
  // Camelot LP token
  address public immutable lpToken;
  // SPNFT contract
  address public immutable spNft;
  // Camelot position helper contract used to establish spNFT
  address public immutable positionHelper;
  // SPNFT token ID
  uint256 public positionId;
  // Camelot Oracle contract
  ICamelotOracle public immutable camelotOracle;

  /* ========== CONSTANTS ========== */

  uint256 public constant SAFE_MULTIPLIER = 1e18;
  address public constant GRAIL = 0x3d9907F9a368ad0a51Be60f7Da3b97cf940982D8;
  address public constant xGRAIL = 0x3CAaE25Ee616f2C8E13C74dA0813402eae3F496b;

  /* ========== CONSTRUCTOR ========== */

  /**
    * @param _vault Vault contract
    * @param _lpToken LP token contract
    * @param _tokenALendingPool Token A lending pool contract
    * @param _tokenBLendingPool Token B lending pool contract
    * @param _router Camelot Router contract
    * @param _spNft Camelot SPNFT contract
    * @param _positionHelper Camelot Position helper contract
    * @param _camelotOracle Camelot Oracle contract
  */
  constructor(
    ICamelotYieldFarmVault _vault,
    ILendingPool _tokenALendingPool,
    ILendingPool _tokenBLendingPool,
    ICamelotRouter _router,
    address _lpToken,
    address _spNft,
    address _positionHelper,
    ICamelotOracle _camelotOracle
   ) {
    require(address(_vault) != address(0), "Invalid address");
    require(address(_tokenALendingPool) != address(0), "Invalid address");
    require(address(_tokenBLendingPool) != address(0), "Invalid address");
    require(address(_router) != address(0), "Invalid address");
    require(address(_lpToken) != address(0), "Invalid address");
    require(address(_spNft) != address(0), "Invalid address");
    require(address(_positionHelper) != address(0), "Invalid address");
    require(address(_camelotOracle) != address(0), "Invalid address");

    vault = _vault;
    tokenA = IERC20(_vault.tokenA());
    tokenB = IERC20(_vault.tokenB());
    tokenALendingPool = _tokenALendingPool;
    tokenBLendingPool = _tokenBLendingPool;
    router = _router;
    lpToken = _lpToken;
    spNft = _spNft;
    positionHelper = _positionHelper;
    camelotOracle = _camelotOracle;

    tokenA.approve(address(router), type(uint256).max);
    tokenB.approve(address(router), type(uint256).max);
    tokenA.approve(address(positionHelper), type(uint256).max);
    tokenB.approve(address(positionHelper), type(uint256).max);
    tokenA.approve(address(tokenALendingPool), type(uint256).max);
    tokenB.approve(address(tokenBLendingPool), type(uint256).max);
    IERC20(lpToken).approve(address(spNft), type(uint256).max);
    IERC20(lpToken).approve(address(router), type(uint256).max);
    IERC20(GRAIL).approve(address(router), type(uint256).max);
  }

  /* ========== MODIFIERS ========== */

  /**
    * Only allow approved address of vault
  */
  modifier onlyVault() {
    require(msg.sender == address(vault), "Caller is not approved vault");
    _;
  }

  /* ========== VIEW FUNCTIONS ========== */

  /**
    * Return the lp token amount held by manager
    * @return lpTokenAmt lpToken in 1e18
  */
  function lpTokenAmt() public view returns (uint256) {
    (,uint256 amountWithMultiplier,,,,,,) = ICamelotSpNft(spNft).getStakingPosition(positionId);

    return amountWithMultiplier;
  }

  /**
    * Get token A and B asset amt. Asset = Debt + Equity
    * @return tokenAAssetAmt Token A amt in token decimals
    * @return tokenBAssetAmt Token B amt in token decimals
  */
  function assetInfo() public view returns (uint256, uint256) {
    (uint256 tokenAAssetAmt, uint256 tokenBAssetAmt) = camelotOracle.getLpTokenReserves(
      lpTokenAmt(),
      address(tokenA),
      address(tokenB),
      lpToken
    );

    return (tokenAAssetAmt, tokenBAssetAmt);
  }

  /**
    * Get token A and B debt amt from lending pools
    * @return tokenADebtAmt Token A amt in token decimals
    * @return tokenBDebtAmt Token B amt in token decimals
  */
  function debtInfo() public view returns (uint256, uint256) {
    return (
      tokenALendingPool.maxRepay(address(this)),
      tokenBLendingPool.maxRepay(address(this))
    );
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /**
    * General function for deposit, withdraw, rebalance, called by vault
    * @param _action Enum, 0 - Deposit, 1 - Withdraw, 2 - AddLiquidity, 3 - RemoveLiquidity
    * @param _lpAmt Amt of LP tokens to sell for repay
    * @param _borrowTokenAAmt Amt of tokens to borrow in 1e18
    * @param _borrowTokenBAmt Amt of tokens to borrow in 1e18
    * @param _repayTokenAAmt Amt of tokens to repay in 1e18
    * @param _repayTokenBAmt Amt of tokens to repay in 1e18
  */
  function work(
    ManagerAction _action,
    uint256 _lpAmt,
    uint256 _borrowTokenAAmt,
    uint256 _borrowTokenBAmt,
    uint256 _repayTokenAAmt,
    uint256 _repayTokenBAmt
  ) external onlyVault {

    // ********** Deposit Flow **********
    if (_action == ManagerAction.Deposit) {
      // borrow from lending pools
      _borrow(_borrowTokenAAmt, _borrowTokenBAmt);
      // Swap assets optimally for LP
      _swapForOptimalDeposit();
      // Add tokens to lp receive lp tokens
      _addLiquidity();
      // Add lp in SPNFT position for rewards
      _stake();
    }

    // ********** Withdraw Flow **********
    if (_action == ManagerAction.Withdraw) {
      if (_lpAmt > 0) {
        // If estimated LP amount is more than actual LP amount owned
        if (_lpAmt > lpTokenAmt()) {
          _lpAmt = lpTokenAmt();
        }

        // Unstake LP from rewards pool
        _unstake(_lpAmt);
        // remove lp receive tokenA + B
        _removeLiquidity(lpToken, _lpAmt);
        // Swap tokens to ensure sufficient balance to repay
        _swapForRepay(_repayTokenAAmt, _repayTokenBAmt);
        // repay lending pools
        _repay(_repayTokenAAmt, _repayTokenBAmt);
        // swap excess tokens
        _swapExcess();

      }
    }

    // ********** Rebalance: Add Liquidity Flow **********
    if (_action == ManagerAction.AddLiquidity) {
      // Borrow from lending pools
      _borrow(_borrowTokenAAmt, _borrowTokenBAmt);
      // Check for dust amount before swapping to avoid revert
      if (_repayTokenAAmt > 1e16 || _repayTokenBAmt > 1e5) {
        // If required Swap tokens to ensure sufficient balance to repay
         _swapForRepay(_repayTokenAAmt, _repayTokenBAmt);
        // If required, repay lending pools
        _repay(_repayTokenAAmt, _repayTokenBAmt);
      }
      // Swap assets optimally for LP
      _swapForOptimalDeposit();
      // Add tokens to lp receive lp tokens
      _addLiquidity();
      // Stake lp in rewards pool
      _stake();
    }

    // ********** Rebalance: Remove Liquidity Flow **********
    if (_action == ManagerAction.RemoveLiquidity) {
      if (_lpAmt > 0) {
        // If estimated lp amount is more than actual lp amount owned
        if (_lpAmt > lpTokenAmt()) {
          _lpAmt = lpTokenAmt();
        }
        // Unstake lp from rewards pool
        _unstake(_lpAmt);
        // remove lp receive tokenA + B
        _removeLiquidity(lpToken, _lpAmt);
        // If required, borrow from lending pools
        _borrow(_borrowTokenAAmt, _borrowTokenBAmt);
        // Check for dust amount before swapping to avoid revert
        if (_repayTokenAAmt > 1e16 || _repayTokenBAmt > 1e5) {
          // If required Swap tokens to ensure sufficient balance to repay
          _swapForRepay(_repayTokenAAmt, _repayTokenBAmt);
          // If required, repay lending pools
          _repay(_repayTokenAAmt, _repayTokenBAmt);
        }
        // Swap assets optimally for LP
        _swapForOptimalDeposit();
        // Add tokens to lp receive lp tokens
        _addLiquidity();
        // Stake lp in rewards pool
        _stake();
      }
    }

    // Send tokens back to vault, also account for any dust cleanup
    tokenA.safeTransfer(msg.sender, tokenA.balanceOf(address(this)));
    tokenB.safeTransfer(msg.sender, tokenB.balanceOf(address(this)));
  }

  /**
    * Compound rewards, convert to more LP; called by vault or keeper
    * @notice Pass empty data if no allocation to dividends plugin
    * @param _data Bytes, 0 - dividendsPlugin, 1 - lpTokenRewards address[]
  */
  function compound(bytes calldata _data) external {
    // Harvest dividends receive WETH-USDC LP tokens + xGRAIL
    if (_data.length > 0) {
      (address dividendsPlugin, address[] memory lpTokenRewards) = abi.decode(_data, (address, address[]));
      ICamelotDividends(dividendsPlugin).harvestAllDividends();

      // Convert LP tokens to tokenB; loop to handle possible future multiple LP rewards
      for (uint256 i = 0; i < lpTokenRewards.length; i++) {
        address lpTokenAddress = lpTokenRewards[i];
        if (IERC20(lpTokenAddress).balanceOf(address(this)) > 0) {
          // Convert LP tokens to token0 + token1
          _removeLiquidity(lpTokenAddress, IERC20(lpTokenAddress).balanceOf(address(this)));
          // Swap token0 & token1 to tokenB (e.g. USDC), taking fee
          _swapRewardWithFee(ICamelotPair(lpTokenAddress).token0());
          _swapRewardWithFee(ICamelotPair(lpTokenAddress).token1());
        }
      }
    }

    // Harvest rewards receive GRAIL + xGRAIL
    ICamelotSpNft(spNft).harvestPosition(positionId);

    // Convert GRAIL to LP tokens
    if (IERC20(GRAIL).balanceOf(address(this)) > 0) {
      _swapRewardWithFee(GRAIL);
      _swapForOptimalDeposit();
      _addLiquidity();
      _stake();
    }

    // Note: Balance of xGRAIL will be allocated by keeper
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  /**
    * Internal function to optimally convert token balances to LP tokens
  */
  function _addLiquidity() internal {
    // Add liquidity receive LP tokens
    router.addLiquidity(
      address(tokenA),
      address(tokenB),
      tokenA.balanceOf(address(this)),
      tokenB.balanceOf(address(this)),
      0,
      0,
      address(this),
      block.timestamp
    );
  }

  /**
    * Internal function to withdraw LP tokens
    * @param _lpToken   Address of LP token
    * @param _lpAmt   Amt of lp tokens to withdraw in 1e18
  */
  function _removeLiquidity(address _lpToken, uint256 _lpAmt) internal {
    router.removeLiquidity(
      ICamelotPair(address(_lpToken)).token0(),
      ICamelotPair(address(_lpToken)).token1(),
      _lpAmt,
      0,
      0,
      address(this),
      block.timestamp
    );
  }

  /**
    * Internal function to stake LP tokens
  */
  function _stake() internal {
    // Add LP tokens to position (stake)
    ICamelotSpNft(spNft).addToPosition(
      positionId, // spNFT token id
      IERC20(lpToken).balanceOf(address(this)) // amount to add
    );
  }

  /**
    * Internal function to unstake LP tokens
    * @param _lpAmt   Amt of lp tokens to unstake in 1e18
  */
  function _unstake(uint256 _lpAmt) internal {
    ICamelotSpNft(spNft).withdrawFromPosition(
      positionId, // spNFT token id
      _lpAmt // amount to withdraw
    );
  }

  /**
    * Internal function to swap tokens for optimal deposit into LP
  */
  function _swapForOptimalDeposit() internal {
    // (uint256 reserveA, uint256 reserveB, uint256 feeA, uint256 feeB) = ICamelotPair(lpToken).getReserves();

    (uint256 reserveA, uint256 reserveB) = camelotOracle.getLpTokenReserves(
      IERC20(lpToken).totalSupply(),
      address(tokenA),
      address(tokenB),
      lpToken
    );

    (uint16 feeA, uint16 feeB) = camelotOracle.getLpTokenFees(
      address(tokenA),
      address(tokenB),
      lpToken
    );

    // Calculate optimal deposit for token0
    (uint256 optimalSwapAmount, bool isReversed) = OptimalDeposit.optimalDepositTwoFees(
      tokenA.balanceOf(address(this)),
      tokenB.balanceOf(address(this)),
      reserveA,
      reserveB,
      feeA/100,
      feeB/100 // e.g. fee of 0.3% = 3
    );

    address[] memory swapPathForOptimalDeposit = new address[](2);

    if (isReversed) {
      swapPathForOptimalDeposit[0] = address(tokenB);
      swapPathForOptimalDeposit[1] = address(tokenA);
    } else {
      swapPathForOptimalDeposit[0] = address(tokenA);
      swapPathForOptimalDeposit[1] = address(tokenB);
    }

    // Swap tokens to achieve optimal deposit amount
    if (optimalSwapAmount > 0) {
      router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        optimalSwapAmount, // amountIn
        0, // amountOutMin
        swapPathForOptimalDeposit, // path
        address(this), // to
        address(0), // referrer
        block.timestamp // deadline
      );
    }
  }

  /**
    * Internal function to swap tokens A/B to ensure sufficient amount for repaying lending pools
    * @param _repayTokenAAmt    Amt of token A to repay in token decimals
    * @param _repayTokenBAmt    Amt of token B to repay in token decimals
  */
  function _swapForRepay(uint256 _repayTokenAAmt, uint256 _repayTokenBAmt) internal {
    uint256 swapAmountIn;
    uint256 swapAmountOut;
    address[] memory swapPath = new address[](2);

    // Check if pair is stable swap, cannot use _getAmountsIn for stableswap
    require(!ICamelotPair(lpToken).stableSwap(), 'pair is stable swap');

    // (uint256 reserveA, uint256 reserveB, uint256 feeA, uint256 feeB) = ICamelotPair(lpToken).getReserves();

    (uint256 reserveA, uint256 reserveB) = camelotOracle.getLpTokenReserves(
      IERC20(lpToken).totalSupply(),
      address(tokenA),
      address(tokenB),
      lpToken
    );

    (uint16 feeA, uint16 feeB) = camelotOracle.getLpTokenFees(
      address(tokenA),
      address(tokenB),
      lpToken
    );

    if (_repayTokenAAmt > tokenA.balanceOf(address(this))) {
      // if insufficient tokenA, swap B for A
      swapPath[0] = address(tokenB);
      swapPath[1] = address(tokenA);
      unchecked {
        swapAmountOut = _repayTokenAAmt - tokenA.balanceOf(address(this));
      }
      // In: tokenB, Out: tokenA
      swapAmountIn = camelotOracle.getAmountsIn(
        swapAmountOut, // amountOut
        reserveB, // reserveIn
        reserveA, // reserveOut
        feeB // fee paid on token IN
      );
    } else if (_repayTokenBAmt > tokenB.balanceOf(address(this))) {
      // if insufficient tokenB, swap A for B
      swapPath[0] = address(tokenA);
      swapPath[1] = address(tokenB);
      unchecked {
        swapAmountOut = _repayTokenBAmt - tokenB.balanceOf(address(this));
      }
      // In: tokenA, Out: tokenB
      swapAmountIn = camelotOracle.getAmountsIn(
        swapAmountOut, // amountOut
        reserveA, // reserveIn
        reserveB, // reserveOut
        feeA // fee paid on token IN
      );
    }

    if (swapAmountIn > 0) {
      router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
        swapAmountIn,
        0,
        swapPath,
        address(this),
        address(0),
        block.timestamp
      );
    }
  }

  /**
    * Internal function to swap excess tokens according to vault strategy.
    * Neutral vault - swap A -> B, Long vault - swap B -> A
  */
  function _swapExcess() internal {
    address[] memory swapPathForRepayDifference = new address[](2);

    if (vault.strategy() == VaultStrategy.Neutral) {
      // Check if tokenA balance greater than 1e17 to avoid swapping dust
      if (tokenA.balanceOf(address(this)) > (SAFE_MULTIPLIER / 10)) {
        swapPathForRepayDifference[0] = address(tokenA);
        swapPathForRepayDifference[1] = address(tokenB);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
          tokenA.balanceOf(address(this)),
          0,
          swapPathForRepayDifference,
          address(this),
          address(0),
          block.timestamp
        );
      }
    }

    if (vault.strategy() == VaultStrategy.Long) {
      if (tokenB.balanceOf(address(this)) > 0) {
        swapPathForRepayDifference[0] = address(tokenB);
        swapPathForRepayDifference[1] = address(tokenA);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
          tokenB.balanceOf(address(this)),
          0,
          swapPathForRepayDifference,
          address(this),
          address(0),
          block.timestamp
        );
      }
    }
  }

  /**
    * Internal function to swap reward token for Token B (USDC); take cut of fees and transfer to treasury
    * @param _rewardToken  Address of reward token
  */
  function _swapRewardWithFee(address _rewardToken) internal {
    address[] memory swapRewardTokenPath = new address[](2);
    swapRewardTokenPath[0] = address(_rewardToken);
    swapRewardTokenPath[1] = address(tokenB);

    // Swap reward token to WETH/USDC
    router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
      IERC20(_rewardToken).balanceOf(address(this)),
      0,
      swapRewardTokenPath,
      address(this),
      address(0),
      block.timestamp
    );

    uint256 fee = tokenB.balanceOf(address(this))
                  * vault.perfFee()
                  / SAFE_MULTIPLIER;

    tokenB.safeTransfer(vault.treasury(), fee);
  }

  /**
    * Internal function to borrow from lending pools
    * @param _borrowTokenAAmt   Amt of token A to borrow in token decimals
    * @param _borrowTokenBAmt   Amt of token B to borrow in token decimals
  */
  function _borrow(uint256 _borrowTokenAAmt, uint256 _borrowTokenBAmt) internal {
    if (_borrowTokenAAmt > 0) {
      tokenALendingPool.borrow(_borrowTokenAAmt);
    }
    if (_borrowTokenBAmt > 0) {
      tokenBLendingPool.borrow(_borrowTokenBAmt);
    }
  }

  /**
    * Internal function to repay lending pools
    * @param _repayTokenAAmt   Amt of token A to repay in token decimals
    * @param _repayTokenBAmt   Amt of token B to repay in token decimals
  */
  function _repay(uint256 _repayTokenAAmt, uint256 _repayTokenBAmt) internal {
    if (_repayTokenAAmt > 0) {
      tokenALendingPool.repay(_repayTokenAAmt);
    }
    if (_repayTokenBAmt > 0) {
      tokenBLendingPool.repay(_repayTokenBAmt);
    }
  }

  /* ========== INTERFACE FUNCTIONS ========== */

  /**
    * Required to allow contract to receive ERC721 spNFT
  */
  function onERC721Received(
    address /*operator*/,
    address /*from*/,
    uint256 /*tokenId*/,
    bytes memory /*data*/
  ) external pure override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  /**
    * Required by Camelot contracts to handle NFT position
  */
  function onNFTAddToPosition(
    address /*operator*/,
    uint256 /*tokenId*/,
    uint256 /*lpAmount*/
  ) external pure returns (bool) {
    return true;
  }

  /**
    * Required by Camelot contracts to handle NFT position
  */
  function onNFTWithdraw(
    address /*operator*/,
    uint256 /*tokenId*/,
    uint256 /*lpAmount*/
  ) external pure returns (bool) {
    return true;
  }

  /**
    * Required by Camelot contracts to handle NFT position
  */
  function onNFTHarvest(
    address /*operator*/,
    address /*to*/,
    uint256 /*tokenId*/,
    uint256 /*grailAmount*/,
    uint256 /*xGRAILAmount*/
  ) external pure returns (bool) {
    return true;
  }

  /* ========== RESTRICTED FUNCTIONS ========== */

  /**
    * Update position id of SPNFT
  */
  function updatePositionId(uint256 _id) external onlyOwner {
    positionId = _id;
  }

  /**
    * Allocate xGRAIL to desired plugin
    * @notice usageData: 0: NFT pool address, 1: position id -- only for yield booster, if dividends, leave usageData empty
    * @param _data  Encoded data for allocation 0: usageAddress, 1: amt of xGRAIL to allocate, 2: usageData
  */
  function allocate(bytes calldata _data) external onlyVault {
    (
      address usageAddress,
      uint256 amt,
      bytes memory usageData
    ) = abi.decode(_data, (address, uint256, bytes));

    ICamelotXGrail(xGRAIL).approveUsage(IXGrailTokenUsage(usageAddress), amt);
    IERC20(xGRAIL).approve(usageAddress, amt);

    ICamelotXGrail(xGRAIL).allocate(usageAddress, amt, usageData);
  }

  /**
    * Deallocate xGRAIL from desired plugin
    * @notice usageData: 0: NFT pool address, 1: position id -- only for yield booster, if dividends, leave usageData empty
    * @param _data  Encoded data for deallocation 0: usageAddress, 1: amt of xGRAIL to deallocate, 2: usageData
  */
  function deallocate(bytes calldata _data) external onlyVault {
    (
      address usageAddress,
      uint256 amt,
      bytes memory usageData
    ) = abi.decode(_data, (address, uint256, bytes));

    ICamelotXGrail(xGRAIL).deallocate(usageAddress, amt, usageData);
  }

  /**
    * Redeem xGRAIL for Grail after vesting period
    * @param _amt Amt of xGRAIL to redeem
    * @param _redeemDuration Duration of redeem period in seconds
  */
  function redeem(uint256 _amt, uint256 _redeemDuration) external onlyOwner {
    ICamelotXGrail(xGRAIL).redeem(_amt, _redeemDuration);
  }

  /**
    * Finalize redeem after redeem period has ended
  */
  function finalizeRedeem() external onlyOwner {
    // Get all manager's redeem positions
    uint256 userRedeemLength = ICamelotXGrail(xGRAIL).getUserRedeemsLength(address(this));
    if (userRedeemLength == 0) return;
    // Loop through all redeem positions
    for (uint256 i = 0; i < userRedeemLength; i++) {
      (,,uint256 endTime,,) = ICamelotXGrail(xGRAIL).getUserRedeem(address(this), i);

      // If redeem period has ended finalize redeem claim GRAIL
      if (endTime < block.timestamp) {
        ICamelotXGrail(xGRAIL).finalizeRedeem(i);
      }
    }
  }

  /**
    * Transfer GRAIL to another address
    * @param _to  Address to transfer xGRAIL to
    * @param _amt Amt of xGRAIL to transfer
  */
  function transferGRAIL(address _to, uint256 _amt) external onlyOwner {
    IERC20(GRAIL).transfer(_to, _amt);
  }

  /**
    * Transfer xGRAIL (only if whitelisted) to another address
    * @param _to  Address to transfer xGRAIL to
    * @param _amt Amt of xGRAIL to transfer
  */
  function transferxGRAIL(address _to, uint256 _amt) external onlyOwner {
    IERC20(xGRAIL).transfer(_to, _amt);
  }
}