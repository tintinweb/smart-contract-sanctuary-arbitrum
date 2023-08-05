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

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "./Storage.sol";

/**
 * @title FixedStaking
 * @notice This contract develops rolling, fixed rate staking
 * programs for a specific token, allowing users to stake an
 * NFT from a specific collection to earn 2x rewards.
 */
contract FixedStaking is Ownable, ERC721Holder {
    using SafeERC20 for IERC20;

    IERC20 private _rewardToken;
    IERC20 private _stakeToken;
    IERC721 private _bonusNft;
    uint256 private _remainingRewards;
    bool private _earlyUnlock;

    Storage private db = new Storage();

    /**
     * @dev Contract constructor
     * @param rewardTokenAddress Address of the rewards token.
     * @param stakeTokenAddress Address of the stake token.
     * @param bonusNftAddress Address of the bonus NFT collection.
     */
    constructor(
        address rewardTokenAddress,
        address stakeTokenAddress,
        address bonusNftAddress
    ) {
        _rewardToken = IERC20(rewardTokenAddress);
        _stakeToken = IERC20(stakeTokenAddress);
        _bonusNft = IERC721(bonusNftAddress);
        _remainingRewards = 0;
    }

    /**
     * @dev Returns the on-chain SolidQuery database address.
     */
    function getDatabase() external view returns (address) {
        return address(db);
    }

    /**
     * @dev Panic mode: let everyone unstake NOW.
     * @param status Set early unlock on or off.
     */
    function setEarlyUnlock(bool status) external onlyOwner {
        _earlyUnlock = status;
    }

    event RewardsAdded(uint256 amount);
    event RewardsRemoved(uint256 amount);

    /**
     * @dev Adds rewards from the pool.
     * @param amount The amount of rewards to add.
     */
    function addRewards(uint256 amount) external onlyOwner {
        _rewardToken.safeTransferFrom(msg.sender, address(this), amount);
        _remainingRewards += amount;
        emit RewardsAdded(amount);
    }

    /**
     * @dev Removes rewards from the pool if there are any remaining.
     * @param amount The amount of rewards to remove.
     */
    function removeRewards(uint256 amount) external onlyOwner {
        require(
            _remainingRewards >= amount,
            "Amount is bigger than the remaining rewards."
        );
        _rewardToken.safeTransfer(msg.sender, amount);
        _remainingRewards -= amount;
        emit RewardsRemoved(amount);
    }

    /**
     * @dev Called by a user to stake their tokens.
     * @param programId The id of the staking program for this stake.
     * @param amount The amount of tokens to stake.
     */
    function stakeTokens(uint256 programId, uint256 amount) external {
        require(amount > 0, "Amount cannot be 0");
        Storage.StakeProgram memory program = db.getStakeProgramById(programId);
        require(program.active, "Program is not active");
        uint256 rewards = (amount * program.rewards) / 1e18;
        require(_remainingRewards >= rewards, "Not enough rewards in the pool");
        _remainingRewards -= rewards;
        _stakeToken.safeTransferFrom(msg.sender, address(this), amount);
        Storage.Stake memory stake = Storage.Stake(
            msg.sender,
            block.timestamp + program.duration,
            amount,
            rewards,
            programId,
            0,
            false,
            false
        );
        db.addStake(stake);
    }

    /**
     * @dev Called by a user to stake their tokens with an NFT.
     * @param programId The id of the staking program for this stake.
     * @param amount The amount of tokens to stake.
     * @param nftId The NFT ID to use for bonus rewards.
     */
    function stakeTokensWithNft(
        uint256 programId,
        uint256 amount,
        uint256 nftId
    ) external {
        require(amount > 0, "Amount cannot be 0");
        Storage.StakeProgram memory program = db.getStakeProgramById(programId);
        require(program.active, "Program is not active");
        uint256 rewards = (2 * amount * program.rewards) / 1e18;
        require(_remainingRewards >= rewards, "Not enough rewards in the pool");
        _remainingRewards -= rewards;
        _stakeToken.safeTransferFrom(msg.sender, address(this), amount);
        _bonusNft.safeTransferFrom(msg.sender, address(this), nftId);
        Storage.Stake memory stake = Storage.Stake(
            msg.sender,
            block.timestamp + program.duration,
            amount,
            rewards,
            programId,
            nftId,
            false,
            true
        );
        db.addStake(stake);
    }

    /**
     * @dev Called by a user to unstake an unlocked stake.
     * @param stakeId The id of the stake record to unstake.
     */
    function unstake(uint256 stakeId) external {
        Storage.Stake memory stake = db.getStakeById(stakeId);
        require(stake.amount > 0, "Stake doesn't exist");
        require(
            _earlyUnlock || block.timestamp >= stake.unlock,
            "Cannot claim yet"
        );
        require(!stake.claimed, "Already claimed");
        stake.claimed = true;
        db.updateStake(stakeId, stake);
        _stakeToken.safeTransfer(stake.user, stake.amount);
        _rewardToken.safeTransfer(stake.user, stake.rewards);
        if (stake.hasNft) {
            _bonusNft.safeTransferFrom(address(this), stake.user, stake.nftId);
        }
    }

    /**
     * @dev Adds a new StakeProgram record and updates relevant indexes.
     * @notice Emits a StakeProgramAdded event on success.
     * @param value The new record to add.
     */
    function addStakeProgram(
        Storage.StakeProgram calldata value
    ) external onlyOwner {
        db.addStakeProgram(value);
    }

    /**
     * @dev Deletes a StakeProgram record by its ID and updates relevant indexes.
     * @notice Emits a StakeProgramDeleted event on success.
     * @param id The ID of the record to delete.
     */
    function deleteStakeProgram(uint256 id) external onlyOwner {
        db.deleteStakeProgram(id);
    }

    /**
     * @dev Updates a StakeProgram record by its id.
     * @notice Emits a StakeProgramUpdated event on success.
     * @param id The id of the record to update.
     * @param value The new data to update the record with.
     */
    function updateStakeProgram(
        uint256 id,
        Storage.StakeProgram calldata value
    ) external onlyOwner {
        db.updateStakeProgram(id, value);
    }

    /**
     * @dev Sends `amount` of ERC20 `token` from contract address
     * to `recipient`
     *
     * Useful if someone sent ERC20 tokens to the contract address by mistake.
     *
     * @param token The address of the ERC20 token contract.
     * @param recipient The address to which the tokens should be transferred.
     * @param amount The amount of tokens to transfer.
     */
    function recoverERC20(
        address token,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        require(
            token != address(_rewardToken),
            "Cannot recover the reward token."
        );
        require(
            token != address(_stakeToken),
            "Cannot recover the stake token."
        );
        IERC20(token).safeTransfer(recipient, amount);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Storage
 * @notice This contract has been automatically generated by SolidQuery 0.2.0.
 * It represents a structured, on-chain database that includes CRUD operations,
 * on-chain indexing capabilities, and getter and setter functions where applicable.
 * It is tailored to a specific schema, provided as input in a YAML format.
 * For detailed function descriptions and specific structure, please refer to the function
 * and struct level comments within the contract.
 * @dev For more information on SolidQuery, please visit our GitHub repository.
 * https://github.com/KenshiTech/SolidQuery
 */
contract Storage is Context, Ownable {
    struct StakeProgram {
        bool active;
        uint256 rewards;
        uint256 duration;
    }

    struct Stake {
        address user;
        uint256 unlock;
        uint256 amount;
        uint256 rewards;
        uint256 program;
        uint256 nftId;
        bool claimed;
        bool hasNft;
    }

    uint256 private stakeProgramCounter = 0;
    uint256 private stakeCounter = 0;

    event StakeProgramCreated(
        uint256 id,
        bool active,
        uint256 rewards,
        uint256 duration
    );
    event StakeProgramUpdated(
        uint256 id,
        bool active,
        uint256 rewards,
        uint256 duration
    );
    event StakeProgramDeleted(uint256 id);

    event StakeCreated(
        uint256 id,
        address user,
        uint256 unlock,
        uint256 amount,
        uint256 rewards,
        uint256 program,
        uint256 nftId,
        bool claimed,
        bool hasNft
    );
    event StakeUpdated(
        uint256 id,
        address user,
        uint256 unlock,
        uint256 amount,
        uint256 rewards,
        uint256 program,
        uint256 nftId,
        bool claimed,
        bool hasNft
    );
    event StakeDeleted(uint256 id);

    mapping(uint256 => StakeProgram) StakePrograms;
    mapping(uint256 => Stake) Stakes;

    mapping(address => uint256[]) stakeUserIndex;

    /**
     * @dev Removes a specific id from an array stored in the contract's storage.
     * @param index The storage array from which to remove the id.
     * @param id The id to remove from the array.
     */
    function popFromIndex(uint256[] storage index, uint256 id) internal {
        uint256 length = index.length;
        for (uint256 i = 0; i < length; i++) {
            if (id == index[i]) {
                index[i] = index[length - 1];
                index.pop();
                break;
            }
        }
    }

    /**
     * @dev Removes an ID from the stakeUser index for a given Stake record.
     * @param id The id of the record to remove from the index.
     */
    function deleteStakeUserIndexForId(uint256 id) internal {
        uint256[] storage index = stakeUserIndex[Stakes[id].user];
        popFromIndex(index, id);
    }

    /**
     * @dev Adds a new ID to the stakeUser index for a given Stake record.
     * @param id The id of the record to add.
     * @param value The Stake record to add.
     */
    function addStakeUserIndexForId(uint256 id, Stake memory value) internal {
        stakeUserIndex[value.user].push(id);
    }

    /**
     * @dev Adds a new StakeProgram record and updates relevant indexes.
     * @notice Emits a StakeProgramAdded event on success.
     * @param value The new record to add.
     * @return The ID of the newly added record.
     */
    function addStakeProgram(
        StakeProgram calldata value
    ) external onlyOwner returns (uint256) {
        uint256 id = stakeProgramCounter++;
        StakePrograms[id] = value;
        emit StakeProgramCreated(
            id,
            value.active,
            value.rewards,
            value.duration
        );
        return id;
    }

    /**
     * @dev Adds a new Stake record and updates relevant indexes.
     * @notice Emits a StakeAdded event on success.
     * @param value The new record to add.
     * @return The ID of the newly added record.
     */
    function addStake(
        Stake calldata value
    ) external onlyOwner returns (uint256) {
        uint256 id = stakeCounter++;
        Stakes[id] = value;
        addStakeUserIndexForId(id, value);
        emit StakeCreated(
            id,
            value.user,
            value.unlock,
            value.amount,
            value.rewards,
            value.program,
            value.nftId,
            value.claimed,
            value.hasNft
        );
        return id;
    }

    /**
     * @dev Deletes a StakeProgram record by its ID and updates relevant indexes.
     * @notice Emits a StakeProgramDeleted event on success.
     * @param id The ID of the record to delete.
     */
    function deleteStakeProgram(uint256 id) external onlyOwner {
        delete StakePrograms[id];
        emit StakeProgramDeleted(id);
    }

    /**
     * @dev Deletes a Stake record by its ID and updates relevant indexes.
     * @notice Emits a StakeDeleted event on success.
     * @param id The ID of the record to delete.
     */
    function deleteStake(uint256 id) external onlyOwner {
        deleteStakeUserIndexForId(id);
        delete Stakes[id];
        emit StakeDeleted(id);
    }

    /**
     * @dev Updates a StakeProgram record by its id.
     * @notice Emits a StakeProgramUpdated event on success.
     * @param id The id of the record to update.
     * @param value The new data to update the record with.
     */
    function updateStakeProgram(
        uint256 id,
        StakeProgram calldata value
    ) external onlyOwner {
        StakePrograms[id] = value;
        emit StakeProgramUpdated(
            id,
            value.active,
            value.rewards,
            value.duration
        );
    }

    /**
     * @dev Updates a Stake record by its id.
     * @notice Emits a StakeUpdated event on success.
     * @param id The id of the record to update.
     * @param value The new data to update the record with.
     */
    function updateStake(uint256 id, Stake calldata value) external onlyOwner {
        deleteStakeUserIndexForId(id);
        addStakeUserIndexForId(id, Stakes[id]);
        Stakes[id] = value;
        emit StakeUpdated(
            id,
            value.user,
            value.unlock,
            value.amount,
            value.rewards,
            value.program,
            value.nftId,
            value.claimed,
            value.hasNft
        );
    }

    /**
     * @dev Finds IDs of Stake records by a specific user.
     * @param value The user value to search by.
     * @return An array of matching record IDs.
     */
    function findStakesByUser(
        address value
    ) external view returns (uint256[] memory) {
        return stakeUserIndex[value];
    }

    /**
     * @dev Retrieves a StakeProgram record by its IDs.
     * @param id Record ID to retrieve.
     * @return The requested record.
     */
    function getStakeProgramById(
        uint256 id
    ) external view returns (StakeProgram memory) {
        return StakePrograms[id];
    }

    /**
     * @dev Retrieves an array of StakeProgram records by their IDs.
     * @param idList An array of record IDs to retrieve.
     * @return An array of the retrieved records.
     */
    function getStakeProgramsById(
        uint256[] calldata idList
    ) external view returns (StakeProgram[] memory) {
        uint256 length = idList.length;
        StakeProgram[] memory result = new StakeProgram[](length);
        for (uint256 index = 0; index < length; index++) {
            result[index] = StakePrograms[idList[index]];
        }
        return result;
    }

    /**
     * @dev Retrieves a Stake record by its IDs.
     * @param id Record ID to retrieve.
     * @return The requested record.
     */
    function getStakeById(uint256 id) external view returns (Stake memory) {
        return Stakes[id];
    }

    /**
     * @dev Retrieves an array of Stake records by their IDs.
     * @param idList An array of record IDs to retrieve.
     * @return An array of the retrieved records.
     */
    function getStakesById(
        uint256[] calldata idList
    ) external view returns (Stake[] memory) {
        uint256 length = idList.length;
        Stake[] memory result = new Stake[](length);
        for (uint256 index = 0; index < length; index++) {
            result[index] = Stakes[idList[index]];
        }
        return result;
    }
}