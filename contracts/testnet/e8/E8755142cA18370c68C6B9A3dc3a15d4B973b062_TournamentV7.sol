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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
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

// --no verify
// support voucher
// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../../interfaces/IGamePolicy.sol";
import "../../interfaces/IPrizeManagerV3.sol";
import "../../interfaces/ITournamentV7.sol";
import "../../interfaces/IJackpot.sol";
import "../../interfaces/IVoucher.sol";
import "../../interfaces/IWarehouse.sol";

contract TournamentV7 is ReentrancyGuard, ITournamentV7, Ownable {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    enum GAME_STATUS {PENDING, AVAILABLE, CLOSED, CANCELED}
    enum ROUND_RESULT {UNDEFINED, DOWN, UP, DRAW}
    struct GameInfo {
        uint256 maxPlayers;
        uint256 minPlayers;
        uint256 maxRounds;
        address targetToken;
        address buyInToken;
        uint256 buyInAmount;
        uint256 currentRoundNumber;
        uint256 startTime;
        uint256 nPlayers;
        address[] players;
        uint256[] vouchers;
        GAME_STATUS status;
        address creator;
        uint256 totalVoucherAmount;
        address voucherPayer;
    }

    struct RoundInfo {
        uint256 startTime;
        ROUND_RESULT result; // 1: down | 2: up | 3: draw
        uint256 players;
        uint256 predictions; // 0: down | 1 : up
        uint256 recordedAt;
    }

    struct GameResult {
        address[] winners;
        address proposer;
    }

    struct SponsorInfo {
        uint256 totalSponsors;
        address[] tokens;
        uint256[] amounts;
        address[] sponsors;
    }

    struct WaitingRoom {
        address targetToken;
        address buyInToken;
        address[] players;
        uint256 nPlayers;
        uint256 buyInAmount;
        uint256 totalVoucherAmount;
        uint256[] vouchers;
    }

    // gameId => gameInfo
    mapping (uint256 => GameInfo) public gameInfo;
    // gameId => roundId => roundInfo
    mapping (uint256 => mapping (uint256 => RoundInfo)) public roundInfo;
    // gameId => gameResult
    mapping(uint256 => GameResult) public gameResult;
    // gameId => roundId => user => prediction
    // 1: down | 2: up
    mapping(uint256 => mapping (uint256 => mapping(address => uint256))) public userPredictions;
    // gameId => roundId => isHasData
    mapping(uint256 => mapping (uint256 => bool)) public isHasData;
    // address => gameId => status
    mapping(address => mapping(uint256 => bool)) public isJoinedGame;
    // gameID => sponsorInfo
    mapping(uint256 => SponsorInfo) public sponsorInfo;
    // address => gameId => voucherId
    mapping(address => mapping (uint256 => uint256)) public vouchers;
    // quick match target token => buy in token => buy in amount => waitingRoom
    mapping (address => mapping( address => mapping(uint256 => WaitingRoom))) public waitingRoom;
    // address => quick match target token => buy in token => buy in amount => bool
    mapping(address => mapping (address => mapping( address => mapping(uint256 => bool)))) public isJoinedWaitingRoom;
    // quick match target token => buy in token => buy in amount => id
    mapping (address => mapping( address => mapping(uint256 => uint256))) public rooms;


    IGamePolicy public gamePolicy;
    IPrizeManagerV3 public prizeManager;
    IVoucher public voucher;
    IWarehouse public warehouse;
    address public feeReceiver;
    uint256 public currentGameId;
    uint256 public winingFeePercent;
    uint256 public operationFeeRatio;
    uint256 public creatorFeeRatio;
    uint256 public consolationPercent;
    uint256 public maxCreationFeeAmount;
    uint256 public delayTime;
    uint256 public limitStart;
    uint256 public quickmatch_max_round;
    uint256 public quickmatch_max_winner;
    uint256 public quickmatch_min_players;
    uint256 public quickmatch_max_players;
    uint256 public quickmatch_time_delay;
    uint256 public constant MAX_PLAYERS = 100;
    uint256 public constant MIN_PLAYERS = 50;
    uint256 public constant MAX_ROUNDS = 20;
    uint256 public constant ROUND_DURATION = 60; // 60s
    uint256 public constant ONE_HUNDRED_PERCENT = 10000;
    uint256 public constant BASE_RATIO = 1000;

    /* ========== MODIFIERS ========== */

    modifier onlyOperator {
        require(gamePolicy.isOperator(msg.sender), "PredictionV7: !operator");
        _;
    }

    /* ========== CONSTRUCTOR ========== */

    constructor (IGamePolicy _gamePolicy, address _prizeManager, address _voucher, address _feeReceiver, uint256 _currentGameId, address _warehouse) {
        gamePolicy = _gamePolicy;
        prizeManager = IPrizeManagerV3(_prizeManager);
        voucher = IVoucher(_voucher);
        feeReceiver = _feeReceiver;
        currentGameId = _currentGameId;
        maxCreationFeeAmount = 5e18;
        delayTime = 30;
        limitStart = 1 days;
        quickmatch_max_round = 10;
        quickmatch_min_players = 4;
        quickmatch_max_winner = 1;
        quickmatch_time_delay = 0;
        quickmatch_max_players = 10;
        warehouse = IWarehouse(_warehouse);
    }

    /* ========== VIEWS ========== */

    function getParticipants(uint256 _gameId) external view returns (address[] memory _result){
        GameInfo memory _gameInfo = gameInfo[_gameId];
        _result = new address[](_gameInfo.players.length);
        for (uint256 i = 0; i < _gameInfo.players.length; i++) {
            _result[i] = _gameInfo.players[i];
        }
    }

    function getPlayersInWaitingRoon(address _targetToken, address _buyInToken, uint256 _buyInAmount) external view returns (address[] memory _result){
        WaitingRoom memory _waitingRoom = waitingRoom[_targetToken][_buyInToken][_buyInAmount];
        _result = new address[](_waitingRoom.players.length);
        for (uint256 i = 0; i < _waitingRoom.players.length; i++) {
            _result[i] = _waitingRoom.players[i];
        }
    }

    function getPredictionOfPlayer(uint256 _gameId, uint256 _roundId, address _player) external view returns(uint _status, uint _prediction){
        uint256 _players = roundInfo[_gameId][_roundId].players;
        uint256 _predictions = roundInfo[_gameId][_roundId].predictions;

        uint256 _index = 0;
        GameInfo memory _gameInfo = gameInfo[_gameId];
        for (uint256 index = 0; index < _gameInfo.players.length; index++) {
            if(_gameInfo.players[index] == _player){
                _index = index;
                break;
            }
        }

        bytes memory bStatus = _toBinary(_players);
        bytes memory bPredictions = _toBinary(_predictions);

        _status = bStatus[_index] == bytes1("1") ? 1 : 0;
        _prediction = bPredictions[_index] == bytes1("1") ? 1 : 0;

        return (_status, _prediction);
    }

    function getPlayersAlive(uint256 _gameId, uint256 _roundId) external view returns (address[] memory _result) {
        GameInfo memory _gameInfo = gameInfo[_gameId];
        _result = new address[](_gameInfo.players.length);
        if( _roundId == 1 ){
            _result = _gameInfo.players;
            return _result;
        } else {
            uint256 _players = roundInfo[_gameId][_roundId - 1].players;
            bytes memory bStatus = _toBinary(_players);
             uint256 count = 0;
             for (uint256 index = 0; index < bStatus.length; index++) {
                if( bStatus[index] == bytes1("1")){
                    _result[count++] = _gameInfo.players[index];
                }
             }
        }
    }




    /* ========== PUBLIC FUNCTIONS ========== */

    function create(
        uint256 _maxPlayers,
        uint256 _minPlayers,
        uint256 _maxRounds,
        address _targetToken,
        address _buyInToken,
        uint256 _buyInAmount,
        uint256 _startTime,
        address _voucherPayer
    ) external {
        _startTime = ((_startTime - 1) / 60 + 1) * 60;
        require(_startTime > block.timestamp, "PredictionV7: !startTime");
        require(gamePolicy.isTargetToken(_targetToken), "PredictionV7: !target token");
        require(gamePolicy.isBuyInToken(_buyInToken), "PredictionV7: !buyIn token");
        require( _buyInAmount >= gamePolicy.getBuyInLimit(_buyInToken), "PredictionV7: !minBuyIn");
        require(_startTime <= block.timestamp + limitStart, "PredictionV7: Too early");
        address[] memory _newPlayers;
        uint256[] memory _newVouchers;
        currentGameId++;
        GameInfo memory _gameInfo = GameInfo (
            _maxPlayers > 0 ? _maxPlayers : MAX_PLAYERS,
            _minPlayers > 0 ? _minPlayers : MIN_PLAYERS,
            _maxRounds > 0 ? _maxRounds : MAX_ROUNDS,
            _targetToken,
            _buyInToken,
            _buyInAmount,
            0,
            _startTime,
            0,
            _newPlayers,
            _newVouchers,
            block.timestamp < _startTime ? GAME_STATUS.PENDING : GAME_STATUS.AVAILABLE,
            msg.sender,
            0,
            _voucherPayer
        );
        gameInfo[currentGameId] = _gameInfo;
        uint256 _creationFee = _buyInAmount >= maxCreationFeeAmount ? maxCreationFeeAmount : _buyInAmount;
        if ( _creationFee > 0) {
            IERC20(_buyInToken).safeTransferFrom(msg.sender, feeReceiver, _creationFee);
        }
        emit NewGameCreated(currentGameId);
    }

    function join(uint256 _gameId, uint256 _voucherId) external nonReentrant {
        GameInfo storage _gameInfo = gameInfo[_gameId];
        require(_gameInfo.status == GAME_STATUS.PENDING && _gameInfo.startTime > block.timestamp + delayTime, "PredictionV7: started");
        require(!isJoinedGame[msg.sender][_gameId], "PredictionV7: joined");
        require(_gameInfo.nPlayers < _gameInfo.maxPlayers, "PredictionV7: enough player");
        uint256 _buyInAmount = _gameInfo.buyInAmount;
        if (_voucherId > 0) {
            require(voucher.ownerOf(_voucherId) == msg.sender, "PredictionV7: !owner");
            (address _voucherToken, uint256 _voucherAmount) = voucher.info(_voucherId);
            require(_voucherToken == _gameInfo.buyInToken, "PredictionV7: voucher != buyIn Token");
            if (_voucherAmount > _buyInAmount) {
                _voucherAmount = _buyInAmount;
            }
            voucher.remove(_voucherId, msg.sender);
            _buyInAmount -= _voucherAmount;
            _gameInfo.totalVoucherAmount += _voucherAmount;
        }

        IERC20(_gameInfo.buyInToken).safeTransferFrom(msg.sender, address(this), _buyInAmount);
        isJoinedGame[msg.sender][_gameId] = true;
        uint256 _index = _gameInfo.nPlayers;
        _gameInfo.nPlayers++;
        _gameInfo.players.push(msg.sender);
        _gameInfo.vouchers.push(_voucherId);
        address _jackpot = gamePolicy.getJackpotAddress();
        if (_jackpot != address(0)) {
            IJackpot(_jackpot).newTicket(msg.sender);
        }
        emit NewPlayer(_gameId, msg.sender, _index);
    }

    function sponsor(uint256 _gameId, address _token, uint256 _amount) external {
        require(gameInfo[_gameId].status == GAME_STATUS.PENDING, "PredictionV7: game started");

        SponsorInfo storage _sponsorInfo = sponsorInfo[_gameId];
        uint256 _limit = gamePolicy.getSponsorLimit(_token);
        require(_limit > 0 && _amount >= _limit, "PredictionV7: !sponsor");
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        _sponsorInfo.tokens.push(_token);
        _sponsorInfo.amounts.push(_amount);
        _sponsorInfo.sponsors.push(msg.sender);
        _sponsorInfo.totalSponsors++;
        emit Sponsored(_gameId, _token, _amount, msg.sender);
    }

    function joinWaitingRoom(address _targetToken, address _buyInToken, uint256 _buyInAmount, uint256 _voucherId) external nonReentrant{
        WaitingRoom storage _waitingRoom = waitingRoom[_targetToken][_buyInToken][_buyInAmount];
        require(_waitingRoom.nPlayers < quickmatch_max_players, "PredictionV7: max players");
        require(!isJoinedWaitingRoom[msg.sender][_targetToken][_buyInToken][_buyInAmount], "PredictionV7: joined waitingRoom");
        if( _waitingRoom.buyInToken == address(0)){
            address[] memory _newPlayers;
            uint256[] memory _newVouchers;
            WaitingRoom memory _tmpWaitingRoom = WaitingRoom(_targetToken, _buyInToken, _newPlayers, 0, _buyInAmount, 0, _newVouchers); 
            waitingRoom[_targetToken][_buyInToken][_buyInAmount] = _tmpWaitingRoom;
        }
        isJoinedWaitingRoom[msg.sender][_targetToken][_buyInToken][_buyInAmount] = true;
        
        if( _voucherId > 0){
            require(voucher.ownerOf(_voucherId) == msg.sender, "PredictionV7: !owner");
            (address _voucherToken, uint256 _voucherAmount) = voucher.info(_voucherId);
            require(_voucherToken == _buyInToken, "PredictionV7: voucher != buyIn Token");
            if (_voucherAmount > _buyInAmount) {
                _voucherAmount = _buyInAmount;
            }
            voucher.remove(_voucherId, msg.sender);
            _buyInAmount -= _voucherAmount;
            _waitingRoom.totalVoucherAmount += _voucherAmount;
            
        }

        uint256 _currentRoomId = rooms[_targetToken][_buyInToken][_buyInAmount];

        emit NewWaiter(_targetToken, _buyInToken, _buyInAmount, msg.sender, _waitingRoom.nPlayers, _currentRoomId);  

        _waitingRoom.players.push(msg.sender);
        _waitingRoom.nPlayers++;
        _waitingRoom.vouchers.push(_voucherId);
        

        IERC20(_buyInToken).safeTransferFrom(msg.sender, address(this), _buyInAmount);
    }

    function start(address _targetToken, address _buyInToken, uint256 _buyInAmount, address _voucherPayer) external onlyOperator{
        WaitingRoom storage _waitingRoom = waitingRoom[_targetToken][_buyInToken][_buyInAmount];
        require( _waitingRoom.nPlayers >= quickmatch_min_players, "PredictionV7: !min players");
        uint256 _startTime = ((block.timestamp + quickmatch_time_delay - 1) / 60 + 1) * 60;
        currentGameId++;
        uint256[] memory _newVouchers;
        address[] memory _newPlayers;
        GameInfo memory _gameInfo = GameInfo (
            _waitingRoom.nPlayers,
            quickmatch_min_players,
            quickmatch_max_round,
            _targetToken,
            _buyInToken,
            _buyInAmount,
            0,
            _startTime,
            _waitingRoom.nPlayers,
            _waitingRoom.players,
            _waitingRoom.vouchers,
            GAME_STATUS.AVAILABLE,
            msg.sender,
            _waitingRoom.totalVoucherAmount,
            _voucherPayer
        );
        gameInfo[currentGameId] = _gameInfo;
        rooms[_targetToken][_buyInToken][_buyInAmount] = currentGameId;
        uint256 _currentRoomId = rooms[_targetToken][_buyInToken][_buyInAmount];
        emit NewQuickMatchCreated(currentGameId, _startTime, _currentRoomId);

        _resetWaitingRoom(_waitingRoom.players, _targetToken, _buyInToken, _buyInAmount); 
        _waitingRoom.nPlayers = 0;
        _waitingRoom.players = _newPlayers;
        _waitingRoom.vouchers = _newVouchers;
        _waitingRoom.totalVoucherAmount = 0;
        rooms[_targetToken][_buyInToken][_buyInAmount]++;

    }

    function leave(address _targetToken, address _buyInToken, uint256 _buyInAmount) external nonReentrant{
        require(isJoinedWaitingRoom[msg.sender][_targetToken][_buyInToken][_buyInAmount], "PredictionV7: !joined waitingRoom");
        WaitingRoom storage _waitingRoom = waitingRoom[_targetToken][_buyInToken][_buyInAmount];

        for (uint256 index = 0; index < _waitingRoom.players.length; index++) {
            if( _waitingRoom.players[index] == msg.sender){
                _waitingRoom.players[index]  = _waitingRoom.players[_waitingRoom.players.length - 1];
                uint256 _currentRoomId = rooms[_targetToken][_buyInToken][_buyInAmount];
                emit ChangeIndex(_waitingRoom.players[index], index, _currentRoomId);

                _waitingRoom.players.pop();
                _waitingRoom.nPlayers--;

          
                isJoinedWaitingRoom[msg.sender][_targetToken][_buyInToken][_buyInAmount] = false;  

                if ( _waitingRoom.vouchers[index] > 0){
                    (address _voucherToken, uint256 _voucherAmount) = voucher.info(_waitingRoom.vouchers[index]);
                    if (_voucherAmount > _buyInAmount) {
                        _voucherAmount = _buyInAmount;
                    }
                    _waitingRoom.totalVoucherAmount -= _voucherAmount;
                    warehouse.recover(address(voucher), _waitingRoom.vouchers[index]);
                    _buyInAmount -= _voucherAmount;
                }
                
                IERC20(_waitingRoom.buyInToken).safeTransfer( msg.sender, _buyInAmount);

                _waitingRoom.vouchers[index] = _waitingRoom.vouchers[_waitingRoom.vouchers.length - 1];
                _waitingRoom.vouchers.pop();

                emit LeaveRoom(_currentRoomId, msg.sender);
                
            }
        }

    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _approveTokenIfNeeded(address _token) internal {
        if (IERC20(_token).allowance(address(this), address(prizeManager)) == 0) {
            IERC20(_token).safeApprove(address(prizeManager), type(uint256).max);
        }
    }

    function _prefixed(bytes32 _hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    }

    // option:
    //  - 1: not start
    //  - 2: normal
    //  - 3: consoled

    function _finishGame(uint256 _gameId, address[] memory _winners, uint256 _option) internal {
        GameInfo storage _gameInfo = gameInfo[_gameId];
        require(_gameInfo.status == GAME_STATUS.AVAILABLE || _gameInfo.status == GAME_STATUS.PENDING, "PredictionV7: !available");
        _gameInfo.status = _option == 1 ? GAME_STATUS.CANCELED : GAME_STATUS.CLOSED;

        GameResult storage _gameResult = gameResult[_gameId];
        _gameResult.winners = _winners;
        _gameResult.proposer = msg.sender;
        _createPrize(_gameId, _winners, msg.sender, _option);
    }

    function _createPrize(uint256 _gameId, address[] memory _winners, address _proposer, uint256 _option) internal {
        GameResult storage _gameResult = gameResult[_gameId];
        GameInfo memory _gameInfo = gameInfo[_gameId];
        _gameResult.winners = _winners;
        _gameResult.proposer = _proposer;

        uint256 _totalBuyIn = _gameInfo.buyInAmount * _gameInfo.nPlayers;

        if (_option == 1) {
            IERC20(_gameInfo.buyInToken).safeTransfer(address(prizeManager), _totalBuyIn - _gameInfo.totalVoucherAmount);
            prizeManager.createPrize(_gameId, _winners, _gameInfo.vouchers, _gameInfo.buyInToken, _gameInfo.buyInAmount);
            prizeManager.claimAll(_gameId);
        }
        if (_option == 2 || _option == 3) {
            uint256[] memory _newVouchers = new uint256[](_winners.length);
            uint256 _feePercent = winingFeePercent;
            if (_option == 3) {
                _feePercent = ONE_HUNDRED_PERCENT - consolationPercent;
            }
            uint256 _fee = _totalBuyIn * _feePercent / ONE_HUNDRED_PERCENT;
            uint256 _prizeAmount = (_totalBuyIn - _fee) / _winners.length;
            // get voucher
            if(_gameInfo.voucherPayer != address(0)){
                IERC20(_gameInfo.buyInToken).safeTransferFrom(_gameInfo.voucherPayer, address(this), _gameInfo.totalVoucherAmount);
            }
            IERC20(_gameInfo.buyInToken).safeTransfer(address(prizeManager), _totalBuyIn - _fee);
            prizeManager.createPrize(_gameId, _winners, _newVouchers, _gameInfo.buyInToken, _prizeAmount);
            _transferSystemFee(_gameInfo.buyInToken, _fee, _gameInfo.creator);

            if (sponsorInfo[_gameId].totalSponsors > 0) {
                uint256[] memory _sizePrizeAmounts = new uint256[](sponsorInfo[_gameId].totalSponsors);
                SponsorInfo memory _sponsorInfo = sponsorInfo[_gameId];
                for (uint256 i = 0; i < sponsorInfo[_gameId].totalSponsors; i++) {
                    uint256 _sidePrizeFee = _sponsorInfo.amounts[i] * _feePercent / ONE_HUNDRED_PERCENT;
                    _sizePrizeAmounts[i] = (_sponsorInfo.amounts[i] - _sidePrizeFee) / _winners.length;
                    _transferSystemFee(_sponsorInfo.tokens[i], _sidePrizeFee, _gameInfo.creator);
                    IERC20(_sponsorInfo.tokens[i]).safeTransfer(address(prizeManager), _sponsorInfo.amounts[i] - _sidePrizeFee);
                }
                prizeManager.createSidePrize(_gameId, _sponsorInfo.tokens, _sizePrizeAmounts);
            }
        }
    }

    function _transferSystemFee(address _token, uint256 _amount, address _creator) internal {
        uint256 _creatorFee = _amount * creatorFeeRatio / BASE_RATIO;
        uint256 _operationFee = _amount - _creatorFee;
        IERC20(_token).safeTransfer(_creator, _creatorFee);
        IERC20(_token).safeTransfer(gamePolicy.getTreasuryAddress(), _operationFee);
    }

    function _toBinary(uint256 _value) internal pure returns (bytes memory) {
        if (_value == 0) {
            return "0";
        }
        uint256 bitCount = 0;
        uint256 tempValue = _value;
        while (tempValue > 0) {
            tempValue = tempValue >> 1;
            bitCount++;
        }
        bytes memory result = new bytes(bitCount);
        while (bitCount > 0) {
            result[--bitCount] = ((_value & 1) == 1) ? bytes1("1") : bytes1("0");
            _value = _value >> 1;
        }
        return result;
    }

    function _resetWaitingRoom(address[] memory _players, address _targetToken, address _buyInToken, uint256 _buyInAmount) internal {
        for (uint256 index = 0; index < _players.length; index++) {
            isJoinedWaitingRoom[_players[index]][_targetToken][_buyInToken][_buyInAmount] = false;
        }
    }


    /* ========== RESTRICTED FUNCTIONS ========== */

    // 1 : down | 2 : up
    // startTime = 0 -> default
    
    function record(uint256 _gameId, uint256 _roundId, uint256  _players, uint256 _predictions) external onlyOperator {
        GameInfo storage _gameInfo = gameInfo[_gameId];
        require(_gameInfo.status != GAME_STATUS.CLOSED && _gameInfo.status != GAME_STATUS.CANCELED, "PredictionV7: closed");
        require(block.timestamp >= _gameInfo.startTime && _gameInfo.startTime > 0, "PredictionV7: !started");
        require(!isHasData[_gameId][_roundId], "PredictionV7: have data");

        if (_gameInfo.status == GAME_STATUS.PENDING) {
            _gameInfo.status = GAME_STATUS.AVAILABLE;
        }
        isHasData[_gameId][_roundId] = true;
        uint256 _previousRoundId = _gameInfo.currentRoundNumber;
        _gameInfo.currentRoundNumber++;
        uint256 _startTime = _previousRoundId > 0 ? roundInfo[_gameId][_previousRoundId].startTime + ROUND_DURATION : gameInfo[_gameId].startTime;
         if (_gameInfo.nPlayers >= _gameInfo.minPlayers){
            RoundInfo memory _roundInfo = RoundInfo(
            _startTime,
            ROUND_RESULT.UNDEFINED,
            _players,
            _predictions,
            block.timestamp
        );
            roundInfo[_gameId][_roundId] = _roundInfo;
            _gameInfo.currentRoundNumber++;
            emit Record(_gameId, _roundId, _players, _predictions);
        } else {
            // not start
            _finishGame(_gameId, _gameInfo.players, 1);
        }
    }
    
    function update(uint256 _gameId, uint256 _roundId, uint256 _result) external onlyOperator {
        require(roundInfo[_gameId][_roundId].result == ROUND_RESULT(0), "PredictionV7: have result");
        roundInfo[_gameId][_roundId].result = ROUND_RESULT(_result);
    }

    // 0 : normal | 1 : force finish with specific round
    function finish(uint256 _gameId, address[] memory _winners, bool _isConsoled) external onlyOperator {
        _finishGame(_gameId, _winners, _isConsoled? 3:2);
        emit GameFinished( _gameId, _winners);
    }

    function changeSponsoredGameId(uint256 _oldGameId, uint256 _newGameId) external onlyOperator {
        require(gameInfo[_oldGameId].status == GAME_STATUS.CANCELED, "PredictionV7: !canceled");
        sponsorInfo[_newGameId] = sponsorInfo[_oldGameId];
        sponsorInfo[_oldGameId].totalSponsors = 0;
        emit SponsorChanged(_oldGameId, _newGameId, msg.sender);
    }


    function setWinningFee(uint256 _fee) external onlyOwner {
        require(_fee < ONE_HUNDRED_PERCENT, "PredictionV7: !fee");
        uint256 _oldWinningFee = winingFeePercent;
        winingFeePercent = _fee;
        emit WinningFeeChanged(_fee, _oldWinningFee);
    }

    function setConsolationPercent(uint256 _newPercent) external onlyOwner {
        uint256 _oldPercent = consolationPercent;
        consolationPercent = _newPercent;
        emit ConsolationPercentChanged(_newPercent, _oldPercent);
    }

    function setSystemFeeRatio(uint256 _creatorRatio, uint256 _operationRatio) external onlyOwner {
        require(_creatorRatio + _operationRatio == BASE_RATIO, "PredictionV7: !data");
        creatorFeeRatio = _creatorRatio;
        operationFeeRatio = _operationRatio;
        emit SystemFeeChanged(_creatorRatio, _operationRatio);
    }

    function setMaxCreationFee( uint256 _maxFeeAmount) external onlyOwner {
        require(_maxFeeAmount > 0, "PredictionV7: !minFee");
        uint256 _oldFeeAmount = maxCreationFeeAmount;
        maxCreationFeeAmount = _maxFeeAmount;
        emit MaxCreationFeeChanged(_maxFeeAmount, _oldFeeAmount);
    }

    function setDelay( uint256 _delayTime) external onlyOwner {
        uint256 _oldDelayTime = delayTime;
        delayTime = _delayTime;
        emit DelayTimeChanged(_delayTime, _oldDelayTime);
    }

    function setlimitStart( uint256 _limitStart) external onlyOwner {
        uint256 _oldLimitStart = limitStart;
        limitStart = _limitStart;
        emit LimitStartChanged(_limitStart, _oldLimitStart);
    }

    function setMinPlayersQuickMatch( uint256 _minPlayers) external onlyOperator {
        uint256 _oldMinPlayer = quickmatch_min_players;
        quickmatch_min_players = _minPlayers;
        emit MinPlayerQuickMatchChanged(_minPlayers, _oldMinPlayer);
    }

    function setMaxPlayersQuickMatch( uint256 _maxPlayers) external onlyOperator {
        uint256 _oldMaxPlayer = quickmatch_max_players;
        quickmatch_max_players = _maxPlayers;
        emit MaxPlayerQuickMatchChanged(_maxPlayers, _oldMaxPlayer);
    }

    function setMaxRoundsQuickMatch( uint256 _maxRounds) external onlyOperator {
        uint256 _oldMaxRound = quickmatch_max_round;
        quickmatch_max_round = _maxRounds;
        emit MaxPlayerQuickMatchChanged(_maxRounds, _oldMaxRound);
    }

    function setMaxWinnersQuickMatch( uint256 _maxWinners) external onlyOperator {
        uint256 _oldMaxWinner = quickmatch_max_winner;
        quickmatch_max_winner = _maxWinners;
        emit MaxWinnerQuickMatchChanged(_maxWinners, _oldMaxWinner);
    }

    function setTimeDelayQuickMatch( uint256 _timeDelay) external onlyOperator {
        uint256 _oldTimeDelay = quickmatch_time_delay;
        quickmatch_time_delay = _timeDelay;
        emit TimeDelayQuickMatchChanged(_timeDelay, _oldTimeDelay);
    }



    // EVENTS
    event NewGameCreated(uint256 gameId);
    event NewQuickMatchCreated(uint256 gameId, uint256 startTime, uint256 roomId);
    event GameFinished(uint256 gameId, address[] winners);
    event Sponsored(uint256 gameId, address token, uint256 amount, address sponsor);
    event SponsorChanged(uint256 oldGameId, uint256 newGameId, address operator);
    event NewPlayer(uint256 gameId, address player, uint256 index);
    event NewWaiter(address targetToken, address buyInToken, uint256 buyInAmount, address player, uint256 index, uint256 roomId);
    event ChangeIndex(address player, uint256 index, uint256 roomId);
    event LeaveRoom(uint256 gameId, address player);
    event Record(uint256 gameId, uint256 roundId, uint256 players, uint256 prediction);
    event WinningFeeChanged(uint256 newFee, uint256 oldFee);
    event ConsolationPercentChanged(uint256 newPercent, uint256 oldPercent);
    event SystemFeeChanged(uint256 creatorRatio, uint256 operatorRatio);
    event MaxCreationFeeChanged(uint256 newCreationFee, uint256 oldCreationFee);
    event DelayTimeChanged(uint256 newDelayTime, uint256 oldDelayTime);
    event LimitStartChanged( uint256 newLimitStart, uint256 oldLimitStart);
    event MinPlayerQuickMatchChanged(uint256 newMinPlayer, uint256 oldMinPlayer);
    event MaxPlayerQuickMatchChanged(uint256 newMaxPlayer, uint256 oldMaxPlayer);
    event MaxRoundsQuickMatchChanged(uint256 newMaxRound, uint256 oldMaxRound);
    event MaxWinnerQuickMatchChanged(uint256 newMaxWinner, uint256 oldMaxWinner);
    event TimeDelayQuickMatchChanged(uint256 newTimeDelay, uint256 oldTimeDelay);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;
pragma experimental ABIEncoderV2;

interface IGamePolicy {
    function setOperator(address, bool) external;
    function isOperator(address) external view returns (bool);
    function getOperators() external view returns (address[] memory);
    function setTournamentRouter(address, bool) external;
    function isTournamentRouter(address) external view returns (bool);
    function getTournamentRouters() external view returns (address[] memory);
    function isHeadsUpBank(address) external view returns(bool);
    function setHeadsUpBank(address) external;
    function isHeadsUpRouter(address) external view returns (bool);
    function setHeadsUpRouter(address, bool) external;
    function getBankAddress() external view returns (address);
    function getTreasuryAddress() external view returns (address);
    function getJackpotAddress() external view returns (address);
    function isTargetToken(address) external view returns (bool);
    function isBuyInToken(address) external view returns (bool);
    function getSponsorLimit(address) external view returns (uint256);
    function getBuyInLimit(address) external view returns (uint256);
    function isPrizeManager(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;
pragma experimental ABIEncoderV2;

interface IJackpot {
    function newTicket(address) external;
    function claim(uint256, address, address) external;
    function claimAll(uint256, address) external;
    function currentPrize() external returns(address[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;
pragma experimental ABIEncoderV2;

interface IPrizeManagerV3 {
    function createPrize(uint256, address[] memory, uint256[] memory, address, uint256) external;
    function createSidePrize(uint256, address[] memory, uint256[] memory) external;
    function newWinners(uint256, address[] memory) external;
    function claimPrize(uint256, address) external;
    function claimAll(uint256[] memory, address) external;
    function batchClaim(uint256[] memory, address[] memory) external;
    function updatePrize(uint256, uint256) external;
    function claimAll(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;
pragma experimental ABIEncoderV2;

interface ITournamentV7 {
    function join(uint256, uint256) external;
    function create(uint256, uint256, uint256, address, address, uint256, uint256, address) external;
    function finish(uint256, address[] memory, bool) external;
    function record(uint256, uint256, uint256, uint256) external;
    function update(uint256, uint256, uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/interfaces/IERC721.sol";

interface IVoucher is IERC721{
    function burn(uint256) external;
    function info(uint256) external view returns(address, uint256);
    function mint(address, uint256, uint256, bytes memory) external;
    function remove(uint256, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.17;
pragma experimental ABIEncoderV2;

interface IWarehouse {
    function add(address, uint256, address) external;
    function recover(address, uint256) external;
}