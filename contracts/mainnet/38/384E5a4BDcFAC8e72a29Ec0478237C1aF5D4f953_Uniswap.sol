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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

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
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

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
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Proxy.sol";
import "./IWethGateway.sol";
import "../interfaces/IWETH9.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ILendingPool {
    function withdraw(address asset, uint256 amount, address to) external;
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf)
        external;
    function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external;
}

/// @title AaveV2 proxy contract
/// @author Matin Kaboli
/// @notice Deposits and Withdraws ERC20 tokens to the lending pool
/// @dev This contract uses Permit2
contract AaveV2 is Proxy {
    using SafeERC20 for IERC20;

    ILendingPool public lendingPool;
    IWethGateway public wethGateway;

    /// @notice Sets LendingPool address and approves assets and aTokens to it
    /// @param _lendingPool Aave lending pool address
    /// @param _wethGateway Aave WethGateway contract address
    /// @param _permit2 Address of Permit2 contract
    /// @param _tokens ERC20 tokens, they're approved beforehand
    constructor(
        Permit2 _permit2,
        IWETH9 _weth,
        ILendingPool _lendingPool,
        IWethGateway _wethGateway,
        IERC20[] memory _tokens
    ) Proxy(_permit2, _weth) {
        lendingPool = _lendingPool;
        wethGateway = _wethGateway;

        for (uint8 i = 0; i < _tokens.length;) {
            _tokens[i].safeApprove(address(_lendingPool), type(uint256).max);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Changes LendingPool and WethGateway address if necessary
    /// @param _lendingPool Address of the new lending pool contract
    /// @param _wethGateway Address of the new weth gateway
    function setNewAddresses(ILendingPool _lendingPool, IWethGateway _wethGateway) external onlyOwner {
        lendingPool = _lendingPool;
        wethGateway = _wethGateway;
    }

    /// @notice Deposits an ERC20 token to the pool and sends the underlying aToken to msg.sender
    /// @param _permit Permit2 PermitTransferFrom struct, includes receiver, token and amount
    /// @param _signature Signature, used by Permit2
    function supply(ISignatureTransfer.PermitTransferFrom calldata _permit, bytes calldata _signature)
        external
        payable
    {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        lendingPool.deposit(_permit.permitted.token, _permit.permitted.amount, msg.sender, 0);
    }

    /// @notice Transfers ETH to WethGateway, then WethGateway converts ETH to WETH and deposits
    /// it to the pool and sends the underlying aToken to msg.sender
    /// @param _proxyFee Fee of the proxy
    function supplyETH(uint256 _proxyFee) external payable {
        require(msg.value > _proxyFee);

        wethGateway.depositETH{value: msg.value - _proxyFee}(address(lendingPool), msg.sender, 0);
    }

    /// @notice Receives underlying aToken and sends ERC20 token to msg.sender
    /// @param _permit Permit2 PermitTransferFrom struct, includes aToken and amount
    /// @param _signature Signature, used by Permit2
    /// @param _token ERC20 token to receive
    function withdraw(ISignatureTransfer.PermitTransferFrom calldata _permit, bytes calldata _signature, address _token)
        external
        payable
    {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        lendingPool.withdraw(_token, _permit.permitted.amount, msg.sender);
    }

    /// @notice Receives underlying A_WETH and sends ETH token to msg.sender
    /// @param _permit Permit2 PermitTransferFrom struct, includes aToken and amount
    /// @param _signature Signature, used by Permit2
    function withdrawETH(ISignatureTransfer.PermitTransferFrom calldata _permit, bytes calldata _signature)
        external
        payable
    {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        wethGateway.withdrawETH(address(lendingPool), _permit.permitted.amount, msg.sender);
    }

    /// @notice Repays a borrowed token
    /// @param _rateMode Rate mode, 1 for stable and 2 for variable
    /// @param _permit Permit2 PermitTransferFrom struct, includes aToken and amount
    /// @param _signature Signature, used by Permit2
    function repay(uint8 _rateMode, ISignatureTransfer.PermitTransferFrom calldata _permit, bytes calldata _signature)
        external
        payable
    {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        lendingPool.repay(_permit.permitted.token, _permit.permitted.amount, _rateMode, msg.sender);

        _sweepToken(_permit.permitted.token);
    }

    ///// @notice Repays ETH
    ///// @param _rateMode Rate mode, 1 for stable and 2 for variable
    ///// @param _proxyFee Fee of the proxy contract
    // function repayETH(uint256 _rateMode, uint256 _proxyFee) external payable {
    //     wethGateway.repayETH{value: msg.value - _proxyFee}(address(lendingPool), msg.value - _proxyFee, _rateMode, msg.sender);
    // }

    /// @notice Repays ETH using WETH wrap/unwrap
    /// @param _rateMode Rate mode, 1 for stable and 2 for variable
    /// @param _proxyFee Fee of the proxy contract
    function repayETH(uint256 _rateMode, uint256 _proxyFee) external payable {
        WETH.deposit{value: msg.value - _proxyFee}();

        lendingPool.repay(address(WETH), msg.value - _proxyFee, _rateMode, msg.sender);

        _unwrapWETH9(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Proxy.sol";
import "./IWethGateway.sol";
import "../interfaces/IWETH9.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface AavePoolV3 {
    function withdraw(address asset, uint256 amount, address to) external;
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 refCode) external;
    function borrow(address asset, uint256 amount, uint256 rateMode, uint16 refCode, address onBehalfOf) external;
    function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external;
}

/// @title AaveV3 proxy contract
/// @author Matin Kaboli
/// @notice Deposits and Withdraws ERC20 tokens to the lending pool
/// @dev This contract uses Permit2
contract AaveV3 is Proxy {
    using SafeERC20 for IERC20;

    AavePoolV3 public pool;
    IWethGateway public wethGateway;

    /// @notice Sets LendingPool address and approves assets and aTokens to it
    /// @param _pool Aave pool address
    /// @param _permit2 Address of Permit2 contract
    /// @param _tokens ERC20 tokens, they're approved beforehand
    constructor(Permit2 _permit2, IWETH9 _weth, AavePoolV3 _pool, IWethGateway _wethGateway, IERC20[] memory _tokens)
        Proxy(_permit2, _weth)
    {
        pool = _pool;
        wethGateway = _wethGateway;

        for (uint8 i = 0; i < _tokens.length;) {
            _tokens[i].safeApprove(address(_pool), type(uint256).max);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Changes LendingPool and WethGateway address if necessary
    /// @param _pool Address of the new pool contract
    /// @param _wethGateway Address of the new weth gateway
    function setNewAddresses(AavePoolV3 _pool, IWethGateway _wethGateway) external onlyOwner {
        pool = _pool;
        wethGateway = _wethGateway;
    }

    /// @notice Deposits an ERC20 token to the pool and sends the underlying aToken to msg.sender
    /// @param _permit Permit2 PermitTransferFrom struct, includes receiver, token and amount
    /// @param _signature Signature, used by Permit2
    function supply(ISignatureTransfer.PermitTransferFrom calldata _permit, bytes calldata _signature)
        external
        payable
    {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        pool.supply(_permit.permitted.token, _permit.permitted.amount, msg.sender, 0);
    }

    /// @notice Transfers ETH to WethGateway, then WethGateway converts ETH to WETH and deposits
    /// it to the pool and sends the underlying aToken to msg.sender
    /// @param _proxyFee Fee of the proxy
    function supplyETH(uint256 _proxyFee) external payable {
        require(msg.value > _proxyFee);

        wethGateway.depositETH{value: msg.value - _proxyFee}(address(pool), msg.sender, 0);
    }

    /// @notice Receives underlying aToken and sends ERC20 token to msg.sender
    /// @param _permit Permit2 PermitTransferFrom struct, includes aToken and amount
    /// @param _signature Signature, used by Permit2
    /// @param _token ERC20 token to receive
    function withdraw(ISignatureTransfer.PermitTransferFrom calldata _permit, bytes calldata _signature, address _token)
        external
        payable
    {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        pool.withdraw(_token, _permit.permitted.amount, msg.sender);
    }

    /// @notice Receives underlying A_WETH and sends ETH token to msg.sender
    /// @param _permit Permit2 PermitTransferFrom struct, includes aToken and amount
    /// @param _signature Signature, used by Permit2
    function withdrawETH(ISignatureTransfer.PermitTransferFrom calldata _permit, bytes calldata _signature)
        external
        payable
    {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        wethGateway.withdrawETH(address(pool), _permit.permitted.amount, msg.sender);
    }

    /// @notice Repays a borrowed token
    /// @param _rateMode Rate mode, 1 for stable and 2 for variable
    /// @param _permit Permit2 PermitTransferFrom struct, includes aToken and amount
    /// @param _signature Signature, used by Permit2
    function repay(uint8 _rateMode, ISignatureTransfer.PermitTransferFrom calldata _permit, bytes calldata _signature)
        external
        payable
    {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        pool.repay(_permit.permitted.token, _permit.permitted.amount, _rateMode, msg.sender);

        _sweepToken(_permit.permitted.token);
    }

    /// @notice Repays ETH using WETH wrap/unwrap
    /// @param _rateMode Rate mode, 1 for stable and 2 for variable
    /// @param _proxyFee Fee of the proxy contract
    function repayETH(uint256 _rateMode, uint256 _proxyFee) external payable {
        WETH.deposit{value: msg.value - _proxyFee}();

        pool.repay(address(WETH), msg.value - _proxyFee, _rateMode, msg.sender);

        _unwrapWETH9(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IWethGateway {
    function withdrawETH(address lendingPool, uint256 amount, address to) external;
    function depositETH(address lendingPool, address onBehalfOf, uint16 referralCode) external payable;
    function repayETH(address lendingPool, uint256 amount, uint256 rateMode, address onBehalfOf) external payable;
    function borrowETH(address lendingPool, uint256 amount, uint256 interestRateMode, uint16 referralCode)
        external
        payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
pragma abicoder v2;

import "../Proxy.sol";
import "./IBalancer.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IWETH9.sol";

/// @title Balancer proxy contract
/// @author Matin Kaboli
/// @notice Deposits and Withdraws ERC20/ETH tokens to the vault and handles swap functions
/// @dev This contract uses Permit2
contract Balancer is IBalancer, Proxy {
    using SafeERC20 for IERC20;

    IVault immutable Vault;

    /// @notice Sets Balancer Vault address and approves assets to it
    /// @param _permit2 Permit2 contract address
    /// @param _vault Balancer Vault contract address
    /// @param _tokens ERC20 tokens, they're approved beforehand
    constructor(Permit2 _permit2, IWETH9 _weth, IVault _vault, IERC20[] memory _tokens) Proxy(_permit2, _weth) {
        Vault = _vault;

        for (uint256 i = 0; i < _tokens.length;) {
            _tokens[i].safeApprove(address(_vault), type(uint256).max);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IBalancer
    function joinPool(IBalancer.JoinPoolParams calldata params) public payable {
        uint256 permitLength = params.permit.permitted.length;

        ISignatureTransfer.SignatureTransferDetails[] memory details =
            new ISignatureTransfer.SignatureTransferDetails[](permitLength);

        for (uint8 i = 0; i < permitLength;) {
            details[i].to = address(this);
            details[i].requestedAmount = params.permit.permitted[i].amount;

            unchecked {
                ++i;
            }
        }

        permit2.permitTransferFrom(params.permit, details, msg.sender, params.signature);

        IVault.JoinPoolRequest memory poolRequest = IVault.JoinPoolRequest({
            assets: params.assets,
            userData: params.userData,
            fromInternalBalance: false,
            maxAmountsIn: params.maxAmountsIn
        });

        Vault.joinPool{value: msg.value - params.proxyFee}(params.poolId, address(this), msg.sender, poolRequest);
    }

    /// @inheritdoc IBalancer
    function joinPoolETH(IBalancer.JoinPoolETHParams calldata params) public payable {
        IVault.JoinPoolRequest memory poolRequest = IVault.JoinPoolRequest({
            assets: params.assets,
            userData: params.userData,
            fromInternalBalance: false,
            maxAmountsIn: params.maxAmountsIn
        });

        Vault.joinPool{value: msg.value - params.proxyFee}(params.poolId, address(this), msg.sender, poolRequest);
    }

    ///// @inheritdoc IBalancer
    function joinPool2(IBalancer.JoinPool2Params calldata params) public {
        IVault.JoinPoolRequest memory poolRequest = IVault.JoinPoolRequest({
            assets: params.assets,
            userData: params.userData,
            fromInternalBalance: false,
            maxAmountsIn: params.maxAmountsIn
        });

        Vault.joinPool(params.poolId, address(this), msg.sender, poolRequest);
    }

    /// @inheritdoc IBalancer
    function exitPool(IBalancer.ExitPoolParams calldata params) external payable {
        permit2.permitTransferFrom(
            params.permit,
            ISignatureTransfer.SignatureTransferDetails({
                to: address(this),
                requestedAmount: params.permit.permitted.amount
            }),
            msg.sender,
            params.signature
        );

        IVault.ExitPoolRequest memory exitRequest = IVault.ExitPoolRequest({
            assets: params.assets,
            userData: params.userData,
            toInternalBalance: false,
            minAmountsOut: params.minAmountsOut
        });

        Vault.exitPool(params.poolId, address(this), payable(msg.sender), exitRequest);
    }

    /// @notice Swaps a token for another token in a pool
    /// @param _poolId Pool id
    /// @param _assetOut Expected token out address
    /// @param _limit The minimum amount of expected token out
    /// @param _userData User data structure, can be left empty
    /// @param _permit Permit2 PermitTransferFrom struct, includes receiver, token and amount
    /// @param _signature Signature, used by Permit2
    function swap(
        bytes32 _poolId,
        IAsset _assetOut,
        uint256 _limit,
        bytes calldata _userData,
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata _signature
    ) external payable {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        IVault.SingleSwap memory singleSwap = IVault.SingleSwap({
            poolId: _poolId,
            kind: IVault.SwapKind.GIVEN_IN,
            assetIn: IAsset(_permit.permitted.token),
            assetOut: _assetOut,
            amount: _permit.permitted.amount,
            userData: _userData
        });

        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(msg.sender),
            toInternalBalance: false
        });

        Vault.swap(singleSwap, funds, _limit, block.timestamp);
    }

    /// @notice Swaps ETH for another token in a pool
    /// @param _poolId Pool id
    /// @param _assetOut Expected token out address
    /// @param _limit The minimum amount of expected token out
    /// @param _userData User data structure, can be left empty
    /// @param _proxyFee Fee of the proxy contract
    function swapETH(bytes32 _poolId, IAsset _assetOut, uint256 _limit, bytes calldata _userData, uint256 _proxyFee)
        external
        payable
    {
        IVault.SingleSwap memory singleSwap = IVault.SingleSwap({
            poolId: _poolId,
            kind: IVault.SwapKind.GIVEN_IN,
            assetIn: IAsset(address(0)),
            assetOut: _assetOut,
            amount: msg.value - _proxyFee,
            userData: _userData
        });

        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(msg.sender),
            toInternalBalance: false
        });

        Vault.swap{value: msg.value - _proxyFee}(singleSwap, funds, _limit, block.timestamp);
    }

    /// @inheritdoc IBalancer
    function batchSwap(IBalancer.BatchSwapParams calldata params) public payable {
        uint256 permitLength = params.permit.permitted.length;

        ISignatureTransfer.SignatureTransferDetails[] memory details =
            new ISignatureTransfer.SignatureTransferDetails[](permitLength);

        for (uint8 i = 0; i < permitLength;) {
            details[i].to = address(this);
            details[i].requestedAmount = params.permit.permitted[i].amount;

            unchecked {
                ++i;
            }
        }

        permit2.permitTransferFrom(params.permit, details, msg.sender, params.signature);

        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(msg.sender),
            toInternalBalance: false
        });

        Vault.batchSwap{value: msg.value}(
            IVault.SwapKind.GIVEN_IN, params.swaps, params.assets, funds, params.limits, block.timestamp
        );
    }

    ///// @inheritdoc IBalancer
    function batchSwap2(IBalancer.BatchSwapParams calldata params) public payable {
        uint256 permitLength = params.permit.permitted.length;

        ISignatureTransfer.SignatureTransferDetails[] memory details =
            new ISignatureTransfer.SignatureTransferDetails[](permitLength);

        for (uint8 i = 0; i < permitLength;) {
            details[i].to = address(this);
            details[i].requestedAmount = params.permit.permitted[i].amount;

            unchecked {
                ++i;
            }
        }

        permit2.permitTransferFrom(params.permit, details, msg.sender, params.signature);

        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false,
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        Vault.batchSwap{value: msg.value}(
            IVault.SwapKind.GIVEN_IN, params.swaps, params.assets, funds, params.limits, block.timestamp
        );
    }

    function sweepToken(IBalancer.SweepParams calldata params) public payable {
        uint256 balanceToken = params.token.balanceOf(address(this));
        require(balanceToken >= params.amountMinimum, "Insufficient token");

        if (balanceToken > 0) {
            params.token.safeTransfer(params.recipient, balanceToken);
        }
    }

    function multiCall(
        IBalancer.BatchSwapParams calldata params0,
        IBalancer.JoinPool2Params calldata params1,
        IBalancer.SweepParams calldata params2
    ) external payable {
        batchSwap2(params0);
        joinPool2(params1);
        sweepToken(params2);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
pragma abicoder v2;

import "../interfaces/IVault.sol";
import "../interfaces/Permit2.sol";

interface IBalancer {
    struct JoinPoolParams {
        bytes32 poolId;
        bytes userData;
        IAsset[] assets;
        uint256[] maxAmountsIn;
        uint16 proxyFee;
        ISignatureTransfer.PermitBatchTransferFrom permit;
        bytes signature;
    }

    struct JoinPool2Params {
        bytes32 poolId;
        bytes userData;
        IAsset[] assets;
        uint256[] maxAmountsIn;
        uint16 proxyFee;
    }

    struct SweepParams {
        IERC20 token;
        uint256 amountMinimum;
        address recipient;
    }

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `msg.sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `msg.sender` - often tokenized
     * Pool shares.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(JoinPoolParams calldata params) external payable;

    struct JoinPoolETHParams {
        bytes32 poolId;
        bytes userData;
        IAsset[] assets;
        uint256[] maxAmountsIn;
        uint16 proxyFee;
    }

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `msg.sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `msg.sender` - often tokenized
     * Pool shares.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPoolETH(JoinPoolETHParams calldata params) external payable;

    struct ExitPoolParams {
        bytes32 poolId;
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        ISignatureTransfer.PermitTransferFrom permit;
        bytes signature;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(ExitPoolParams calldata params) external payable;

    struct BatchSwapParams {
        IVault.BatchSwapStep[] swaps;
        IAsset[] assets;
        int256[] limits;
        ISignatureTransfer.PermitBatchTransferFrom permit;
        bytes signature;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(IBalancer.BatchSwapParams calldata params) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Errors {
    error ProxyError(uint256 errCode);

    /// @notice Handles custom error codes
    /// @param _condition The condition, if it's false then execution is reverted
    /// @param _code Custom code, listed in Errors.sol
    function _require(bool _condition, uint256 _code) public pure {
        if (!_condition) {
            revert ProxyError(_code);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract Multicall {
    /// @notice Multiple calls on proxy functions
    /// @param _data The destination address
    function multicall(bytes[] calldata _data) public payable {
        for (uint256 i = 0; i < _data.length;) {
            (bool success, bytes memory result) = address(this).delegatecall(_data[i]);

            if (!success) {
                if (result.length < 68) revert();

                assembly {
                    result := add(result, 0x04)
                }

                revert(abi.decode(result, (string)));
            }

            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Payments.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

contract Owner is Ownable, Payments {
    /// @notice Proxy contract constructor, sets permit2 and weth addresses
    /// @param _permit2 Permit2 contract address
    /// @param _weth WETH9 contract address
    constructor(Permit2 _permit2, IWETH9 _weth) Payments(_permit2, _weth) {}

    /// @notice Withdraws fees and transfers them to owner
    /// @param _recipient Address of the destination receiving the fees
    function withdrawAdmin(address _recipient) public onlyOwner {
        require(address(this).balance > 0);

        _sendETH(_recipient, address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./Permit.sol";
import "./Errors.sol";
import "../helpers/ErrorCodes.sol";
import "../interfaces/Permit2.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Payments is Errors, Permit {
    using SafeERC20 for IERC20;

    /// @notice Proxy contract constructor, sets permit2 and weth addresses
    /// @param _permit2 Permit2 contract address
    /// @param _weth WETH9 contract address
    constructor(Permit2 _permit2, IWETH9 _weth) Permit(_permit2, _weth) {}

    /// @notice Sweeps contract tokens to msg.sender
    /// @param _token ERC20 token address
    /// @param _recipient The destination address
    function sweepToken(address _token, address _recipient) public payable {
        uint256 balanceOf = IERC20(_token).balanceOf(address(this));

        if (balanceOf > 0) {
            IERC20(_token).safeTransfer(_recipient, balanceOf);
        }
    }

    /// @notice Transfers ERC20 token to recipient
    /// @param _recipient The destination address
    /// @param _token ERC20 token address
    /// @param _amount Amount to transfer
    function _send(address _token, address _recipient, uint256 _amount) internal {
        IERC20(_token).safeTransfer(_recipient, _amount);
    }

    /// @notice Permits _spender to spend max amount of ERC20 from the contract
    /// @param _token ERC20 token address
    /// @param _spender Spender address
    function _approve(address _token, address _spender) internal {
        IERC20(_token).safeApprove(_spender, type(uint256).max);
    }

    /// @notice Sends ETH to the destination
    /// @param _recipient The destination address
    /// @param _amount Ether amount
    function _sendETH(address _recipient, uint256 _amount) internal {
        (bool success,) = payable(_recipient).call{value: _amount}("");

        _require(success, ErrorCodes.FAILED_TO_SEND_ETHER);
    }


    /// @notice Approves an ERC20 token to lendingPool and wethGateway
    /// @param _token ERC20 token address
    /// @param _spenders ERC20 token address
    function approveToken(address _token, address[] calldata _spenders) external {
        for (uint8 i = 0; i < _spenders.length;) {
            _approve(_token, _spenders[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Wraps ETH to WETH and sends to recipient
    /// @param _recipient The destination address
    /// @param _proxyFee Fee of the proxy contract
    function wrapWETH9(address _recipient, uint96 _proxyFee) external payable {
        uint256 value = msg.value - _proxyFee;

        WETH.deposit{value: value}();

        _send(address(WETH), _recipient, value);
    }

    /// @notice Unwraps WETH9 to Ether and sends the amount to the recipient
    /// @param _recipient The destination address
    function _unwrapWETH9(address _recipient) internal {
        uint256 balanceWETH = WETH.balanceOf(address(this));

        if (balanceWETH > 0) {
            WETH.withdraw(balanceWETH);

            _sendETH(_recipient, balanceWETH);
        }
    }

    /// @notice Unwraps WETH9 to Ether and sends the amount to the recipient
    /// @param _recipient The destination address
    function unwrapWETH9(address _recipient) public payable {
        uint256 balanceWETH = WETH.balanceOf(address(this));

        if (balanceWETH > 0) {
            WETH.withdraw(balanceWETH);

            _sendETH(_recipient, balanceWETH);
        }
    }

    // /// @notice Receives WETH and unwraps it to ETH and sends to recipient
    // /// @param _recipient The destination address
    // /// @param _permit Permit2 PermitTransferFrom struct, includes receiver, token and amount
    // /// @param _signature Signature, used by Permit2
    // function unwrapWETH9(
    //     address _recipient,
    //     ISignatureTransfer.PermitTransferFrom calldata _permit,
    //     bytes calldata _signature
    // ) external payable {
    //     _require(_permit.permitted.token == address(WETH), ErrorCodes.TOKENS_MISMATCHED);
    //
    //     permitTransferFrom(_permit, _signature);
    //     WETH.withdraw(_permit.permitted.amount);
    //
    //     _sendETH(_recipient, _permit.permitted.amount);
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "../interfaces/IWETH9.sol";
import "../interfaces/Permit2.sol";

contract Permit {
    IWETH9 public immutable WETH;
    Permit2 public immutable permit2;

    /// @notice Proxy contract constructor, sets permit2 and weth addresses
    /// @param _permit2 Permit2 contract address
    /// @param _weth WETH9 contract address
    constructor(Permit2 _permit2, IWETH9 _weth) {
        WETH = _weth;
        permit2 = _permit2;
    }

    function permitTransferFrom(ISignatureTransfer.PermitTransferFrom calldata _permit, bytes calldata _signature)
        public
        payable
    {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );
    }

    function permitBatchTransferFrom(
        ISignatureTransfer.PermitBatchTransferFrom calldata _permit,
        bytes calldata _signature
    ) public payable {
        uint256 tokensLen = _permit.permitted.length;

        ISignatureTransfer.SignatureTransferDetails[] memory details =
            new ISignatureTransfer.SignatureTransferDetails[](tokensLen);

        for (uint256 i = 0; i < tokensLen;) {
            details[i].to = address(this);
            details[i].requestedAmount = _permit.permitted[i].amount;

            unchecked {
                ++i;
            }
        }

        permit2.permitTransferFrom(_permit, details, msg.sender, _signature);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Proxy.sol";
import "../interfaces/IWETH9.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IComet is IERC20 {
    function allow(address manager, bool isAllowed) external;
    function hasPermission(address owner, address manager) external view returns (bool);
    function collateralBalanceOf(address account, address asset) external view returns (uint128);
    function supplyTo(address dst, address asset, uint256 amount) external;
    function withdrawFrom(address src, address dst, address asset, uint256 amount) external;
}

/// @title Comet (Compound V3) proxy, similar to bulker contract
/// @author Matin Kaboli
/// @notice Supplies and Withdraws ERC20 and ETH tokens and helps with WETH wrapping
/// @dev This contract uses Permit2
contract Comet is Proxy {
    using SafeERC20 for IERC20;

    IComet public immutable CometInterface;

    /// @notice Receives cUSDCv3 and approves Compoound tokens to it
    /// @dev Do not put WETH address among _tokens list
    /// @param _comet cUSDCv3 address, used for supplying and withdrawing tokens
    /// @param _weth WETH address used in Comet protocol
    /// @param _tokens List of ERC20 tokens used in Compound V3
    constructor(Permit2 _permit2, IWETH9 _weth, IComet _comet, IERC20[] memory _tokens) Proxy(_permit2, _weth) {
        CometInterface = _comet;

        _weth.approve(address(_comet), type(uint256).max);

        for (uint8 i = 0; i < _tokens.length;) {
            _tokens[i].safeApprove(address(_comet), type(uint256).max);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Supplies an ERC20 asset to Comet
    /// @param _permit Permit2 PermitTransferFrom struct, includes receiver, token and amount
    /// @param _signature Signature, used by Permit2
    function supply(ISignatureTransfer.PermitTransferFrom calldata _permit, bytes calldata _signature) public payable {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        CometInterface.supplyTo(msg.sender, _permit.permitted.token, _permit.permitted.amount);
    }

    /// @notice Wraps ETH to WETH and supplies it to Comet
    /// @param _fee Fee of the proxy
    function supplyETH(uint256 _fee) public payable {
        require(msg.value > 0 && msg.value > _fee);

        uint256 ethAmount = msg.value - _fee;

        WETH.deposit{value: ethAmount}();
        CometInterface.supplyTo(msg.sender, address(WETH), ethAmount);
    }

    /// @notice Withdraws an ERC20 token and transfers it to msg.sender
    /// @param _asset ERC20 asset to withdraw
    /// @param _amount Amount of _asset to withdraw
    function withdraw(address _asset, uint256 _amount) public payable {
        CometInterface.withdrawFrom(msg.sender, msg.sender, _asset, _amount);
    }

    /// @notice Withdraws WETH and unwraps it to ETH and transfers it to msg.sender
    /// @param _amount Amount of WETh to withdraw
    function withdrawETH(uint256 _amount) public payable {
        CometInterface.withdrawFrom(msg.sender, address(this), address(WETH), _amount);
        WETH.withdraw(_amount);

        _sendETH(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Proxy.sol";
import "../interfaces/IWETH9.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ICToken is IERC20 {
    function mint() external payable;
    function mint(uint256 mintAmount) external returns (uint256);
    function redeem(uint256 redeemTokens) external returns (uint256);
    function balanceOfUnderlying(address account) external returns (uint256);
}

/// @title Compound V2 proxy
/// @author Matin Kaboli
/// @notice Supplies and Withdraws ERC20 and ETH tokens and helps with WETH wrapping
/// @dev This contract uses Permit2
contract Compound is Proxy {
    using SafeERC20 for IERC20;

    /// @notice Receives tokens and cTokens and approves them
    /// @param _permit2 Address of Permit2 contract
    /// @param _tokens List of ERC20 tokens used in Compound V2
    /// @param _cTokens List of ERC20 cTokens used in Compound V2
    constructor(Permit2 _permit2, IWETH9 _weth, IERC20[] memory _tokens, address[] memory _cTokens)
        Proxy(_permit2, _weth)
    {
        for (uint8 i = 0; i < _tokens.length;) {
            _tokens[i].safeApprove(_cTokens[i], type(uint256).max);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Supplies an ERC20 asset to Compound
    /// @param _permit Permit2 PermitTransferFrom struct, includes receiver, token and amount
    /// @param _signature Signature, used by Permit2
    function supply(ISignatureTransfer.PermitTransferFrom calldata _permit, bytes calldata _signature, ICToken _cToken)
        public
        payable
    {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        uint256 balanceBefore = _cToken.balanceOf(address(this));

        _cToken.mint(_permit.permitted.amount);

        uint256 balanceAfter = _cToken.balanceOf(address(this));

        _cToken.transfer(msg.sender, balanceAfter - balanceBefore);
    }

    /// @notice Supplies ETH to Compound
    /// @param _cToken address of cETH
    /// @param _fee Fee of the protocol (could be 0)
    function supplyETH(ICToken _cToken, uint256 _fee) public payable {
        require(msg.value > 0 && msg.value > _fee);

        uint256 ethPrice = msg.value - _fee;

        uint256 balanceBefore = _cToken.balanceOf(address(this));

        _cToken.mint{value: ethPrice}();

        uint256 balanceAfter = _cToken.balanceOf(address(this));

        _cToken.transfer(msg.sender, balanceAfter - balanceBefore);
    }

    /// @notice Withdraws an ERC20 token and transfers it to msg.sender
    /// @param _permit Permit2 PermitTransferFrom struct, includes receiver, token and amount
    /// @param _signature Signature, used by Permit2
    /// @param _token received ERC20 token
    function withdraw(ISignatureTransfer.PermitTransferFrom calldata _permit, bytes calldata _signature, ICToken _token)
        public
        payable
    {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        uint256 balanceBefore = _token.balanceOf(address(this));

        ICToken(_permit.permitted.token).redeem(_permit.permitted.amount);

        uint256 balanceAfter = _token.balanceOf(address(this));

        _token.transfer(msg.sender, balanceAfter - balanceBefore);
    }

    /// @notice Received cETH and unwraps it to ETH and transfers it to msg.sender
    /// @param _permit Permit2 PermitTransferFrom struct, includes receiver, token and amount
    /// @param _signature Signature, used by Permit2
    function withdrawETH(ISignatureTransfer.PermitTransferFrom calldata _permit, bytes calldata _signature)
        public
        payable
    {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        uint256 balanceBefore = address(this).balance;

        ICToken(_permit.permitted.token).redeem(_permit.permitted.amount);

        uint256 balanceAfter = address(this).balance;

        _sendETH(msg.sender, balanceAfter - balanceBefore);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./CurvePool.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface Pool {
    function add_liquidity(uint256[2] memory amounts, uint256 min_mint) external payable;
    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts) external;
    function remove_liquidity_one_coin(uint256 _amount, uint256 _i, uint256 _min) external returns (uint256);
    function remove_liquidity_one_coin(uint256 _amount, int128 _i, uint256 _min) external returns (uint256);
}

/// @title Curve proxy contract
/// @author Matin Kaboli
/// @notice Add/Remove liquidity, and exchange tokens in a pool
/// @dev works for different pools, but use with caution (tested only for StableSwap)
contract Curve2Token is CurvePool {
    using SafeERC20 for IERC20;

    constructor(
        Permit2 _permit2,
        IWETH9 _weth,
        address _pool,
        address[] memory _tokens,
        address _token,
        uint8 _ethIndex
    ) CurvePool(_permit2, _weth, _pool, _tokens, _token, _ethIndex) {}

    /// @notice Adds liquidity to a pool
    /// @param _minMintAmount Minimum liquidity expected to receive after adding liquidity
    /// @param _fee Fee of the proxy
    function addLiquidity(
        ISignatureTransfer.PermitBatchTransferFrom calldata _permit,
        bytes calldata _signature,
        uint256[2] memory _amounts,
        uint256 _minMintAmount,
        uint256 _fee
    ) public payable {
        uint256 ethValue = 0;

        ISignatureTransfer.SignatureTransferDetails[] memory details =
            new ISignatureTransfer.SignatureTransferDetails[](_permit.permitted.length);

        for (uint8 i = 0; i < _permit.permitted.length; ++i) {
            details[i].to = address(this);
            details[i].requestedAmount = _permit.permitted[i].amount;
        }

        permit2.permitTransferFrom(_permit, details, msg.sender, _signature);

        if (ethIndex != 100) {
            ethValue = msg.value - _fee;
        }

        uint256 balanceBefore = IERC20(token).balanceOf(address(this));

        Pool(pool).add_liquidity{value: ethValue}(_amounts, _minMintAmount);

        uint256 balanceAfter = IERC20(token).balanceOf(address(this));

        IERC20(token).transfer(msg.sender, balanceAfter - balanceBefore);
    }

    /// @notice Removes liquidity from the pool
    /// @param minAmounts Minimum amounts expected to receive after withdrawal
    function removeLiquidity(
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata _signature,
        uint256[2] memory minAmounts
    ) public payable {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        uint256 balance0Before = getBalance(0);
        uint256 balance1Before = getBalance(1);

        Pool(pool).remove_liquidity(_permit.permitted.amount, minAmounts);

        uint256 balance0After = getBalance(0);
        uint256 balance1After = getBalance(1);

        send(0, balance0After - balance0Before);
        send(1, balance1After - balance1Before);
    }

    /// @notice Removes liquidity and received only 1 token in return
    /// @dev Use this for those pools that use int128 for _i
    /// @param _i Index of receiving token in the pool
    /// @param min_amount Minimum amount expected to receive from token[i]
    function removeLiquidityOneCoinI(
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata _signature,
        int128 _i,
        uint256 min_amount
    ) public payable {
        uint256 i = 0;
        if (_i == 1) {
            i = 1;
        }

        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        uint256 balanceBefore = getBalance(i);

        Pool(pool).remove_liquidity_one_coin(_permit.permitted.amount, _i, min_amount);

        uint256 balanceAfter = getBalance(i);

        send(i, balanceAfter - balanceBefore);
    }

    /// @notice Removes liquidity and received only 1 token in return
    /// @dev Use this for those pools that use uint256 for _i
    /// @param _i Index of receiving token in the pool
    /// @param min_amount Minimum amount expected to receive from token[i]
    function removeLiquidityOneCoinU(
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata _signature,
        uint256 _i,
        uint256 min_amount
    ) public payable {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        uint256 balanceBefore = getBalance(_i);

        Pool(pool).remove_liquidity_one_coin(_permit.permitted.amount, _i, min_amount);

        uint256 balanceAfter = getBalance(_i);

        send(_i, balanceAfter - balanceBefore);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./CurvePool.sol";
import "../interfaces/IWETH9.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface Pool {
    function add_liquidity(uint256[3] memory amounts, uint256 min_mint) external payable;
    function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts) external;
    function remove_liquidity_one_coin(uint256 _amount, int128 _i, uint256 _min) external;
    function remove_liquidity_one_coin(uint256 _amount, uint256 _i, uint256 _min) external;
}

/// @title Curve proxy contract
/// @author Matin Kaboli
/// @notice Add/Remove liquidity, and exchange tokens in a pool
/// @dev works for different pools, but use with caution (tested only for StableSwap)
contract Curve3Token is CurvePool {
    using SafeERC20 for IERC20;

    constructor(
        Permit2 _permit2,
        IWETH9 _weth,
        address _pool,
        address[] memory _tokens,
        address _token,
        uint8 _ethIndex
    ) CurvePool(_permit2, _weth, _pool, _tokens, _token, _ethIndex) {}

    /// @notice Adds liquidity to a pool
    /// @param _amounts Amounts of the tokens respectively
    /// @param _minMintAmount Minimum liquidity expected to receive after adding liquidity
    /// @param _fee Fee of the proxy
    function addLiquidity(
        ISignatureTransfer.PermitBatchTransferFrom calldata _permit,
        bytes calldata _signature,
        uint256[3] memory _amounts,
        uint256 _minMintAmount,
        uint256 _fee
    ) public payable {
        uint256 ethValue = 0;

        ISignatureTransfer.SignatureTransferDetails[] memory details =
            new ISignatureTransfer.SignatureTransferDetails[](_permit.permitted.length);

        for (uint8 i = 0; i < _permit.permitted.length; ++i) {
            details[i].to = address(this);
            details[i].requestedAmount = _permit.permitted[i].amount;
        }

        permit2.permitTransferFrom(_permit, details, msg.sender, _signature);

        if (ethIndex != 100) {
            ethValue = msg.value - _fee;
        }

        uint256 balanceBefore = IERC20(token).balanceOf(address(this));

        Pool(pool).add_liquidity{value: ethValue}(_amounts, _minMintAmount);

        uint256 balanceAfter = IERC20(token).balanceOf(address(this));

        IERC20(token).transfer(msg.sender, balanceAfter - balanceBefore);
    }

    /// @notice Removes liquidity from the pool
    /// @param minAmounts Minimum amounts expected to receive after withdrawal
    function removeLiquidity(
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata _signature,
        uint256[3] memory minAmounts
    ) public payable {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        uint256 balance0Before = getBalance(0);
        uint256 balance1Before = getBalance(1);
        uint256 balance2Before = getBalance(2);

        Pool(pool).remove_liquidity(_permit.permitted.amount, minAmounts);

        uint256 balance0After = getBalance(0);
        uint256 balance1After = getBalance(1);
        uint256 balance2After = getBalance(2);

        send(0, balance0After - balance0Before);
        send(1, balance1After - balance1Before);
        send(2, balance2After - balance2Before);
    }

    /// @notice Removes liquidity and received only 1 token in return
    /// @dev Use this for those pools that use int128 for _i
    /// @param _i Index of receiving token in the pool
    /// @param min_amount Minimum amount expected to receive from token[i]
    function removeLiquidityOneCoinI(
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata _signature,
        int128 _i,
        uint256 min_amount
    ) public payable {
        uint256 i = 0;
        if (_i == 1) {
            i = 1;
        } else if (_i == 2) {
            i = 2;
        }

        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        uint256 balanceBefore = getBalance(i);

        Pool(pool).remove_liquidity_one_coin(_permit.permitted.amount, _i, min_amount);

        uint256 balanceAfter = getBalance(i);

        send(i, balanceAfter - balanceBefore);
    }

    /// @notice Removes liquidity and received only 1 token in return
    /// @dev Use this for those pools that use uint256 for _i
    /// @param _i Index of receiving token in the pool
    /// @param min_amount Minimum amount expected to receive from token[i]
    function removeLiquidityOneCoinU(
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata _signature,
        uint256 _i,
        uint256 min_amount
    ) public payable {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        uint256 balanceBefore = getBalance(_i);

        Pool(pool).remove_liquidity_one_coin(_permit.permitted.amount, _i, min_amount);

        uint256 balanceAfter = getBalance(_i);

        send(_i, balanceAfter - balanceBefore);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Proxy.sol";
import "../interfaces/IWETH9.sol";
import "../interfaces/Permit2.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Curve proxy contract
/// @author Matin Kaboli
/// @notice Add/Remove liquidity, and exchange tokens in a pool
contract CurvePool is Proxy {
    using SafeERC20 for IERC20;

    address[] public tokens;
    address public immutable pool;
    address public immutable token;
    uint8 public immutable ethIndex;

    /// @notice Receives ERC20 tokens and Curve pool address and saves them
    /// @param _pool Address of Curve pool
    /// @param _tokens Addresses of ERC20 tokens inside the _pool
    /// @param _token Address of pool token
    /// @param _ethIndex Index of ETH in the pool (100 if ETH does not exist in the pool)
    constructor(
        Permit2 _permit2,
        IWETH9 _weth,
        address _pool,
        address[] memory _tokens,
        address _token,
        uint8 _ethIndex
    ) Proxy(_permit2, _weth) {
        pool = _pool;
        token = _token;
        tokens = _tokens;
        ethIndex = _ethIndex;

        for (uint8 i = 0; i < _tokens.length;) {
            if (i != _ethIndex) {
                IERC20(tokens[i]).safeApprove(_pool, type(uint256).max);
            }

            unchecked {
                ++i;
            }
        }

        IERC20(_token).safeApprove(_pool, type(uint256).max);
    }

    /// @notice Returns the balance of the token (or ETH) of this contract
    /// @param _i Index of the token in the pool
    /// @return The amount of ERC20 or ETH
    function getBalance(uint256 _i) internal view returns (uint256) {
        if (ethIndex == _i) {
            return address(this).balance;
        }

        return IERC20(tokens[_i]).balanceOf(address(this));
    }

    /// @notice Sends ERC20 token or ETH from this contract
    /// @param _i Index of the sending token from the pool
    /// @param _amount Amount of the sending token
    function send(uint256 _i, uint256 _amount) internal {
        if (ethIndex == _i) {
            (bool sent,) = payable(msg.sender).call{value: _amount}("");

            require(sent, "Failed to send Ether");
        } else {
            IERC20(tokens[_i]).safeTransfer(msg.sender, _amount);
        }
    }

    /// @notice Calculates msg.value (takes the fee) and retrieves ERC20 tokens (transferFrom)
    /// @param _i Index of the token in the pool
    /// @param _amount Amount of the token (or ETH)
    function retrieveToken(uint256 _i, uint256 _amount) internal {
        if (_i != ethIndex) {
            IERC20(tokens[_i]).safeTransferFrom(msg.sender, address(this), _amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Proxy.sol";
import "../interfaces/IWETH9.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ICurveSwap {
    function exchange_multiple(
        address[9] memory _route,
        uint256[3][4] memory _swap_params,
        uint256 _amount,
        uint256 _expected,
        address[4] memory _pools,
        address _receiver
    ) external payable returns (uint256);
}

/// @title Curve swap proxy contract
/// @author Matin Kaboli
/// @notice Exchanges tokens from different pools
contract CurveSwap is Proxy {
    using SafeERC20 for IERC20;

    ICurveSwap public immutable CurveSwapInterface;
    address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @notice Receives swap contract address
    /// @param _curveSwap Swap contract address
    constructor(Permit2 _permit2, IWETH9 _weth, ICurveSwap _curveSwap) Proxy(_permit2, _weth) {
        CurveSwapInterface = _curveSwap;
    }

    /// @notice Perform up to four swaps in a single transaction
    /// @dev Routing and swap params must be determined off-chain. This functionality is designed for gas efficiency over ease-of-use.
    /// @param _route Array of [initial token, pool, token, pool, token, ...]
    /// The array is iterated until a pool address of 0x00, then the last
    /// given token is transferred to `_receiver`
    /// @param _swap_params Multidimensional array of [i, j, swap type] where i and j are the correct
    /// values for the n'th pool in `_route`. The swap type should be
    /// 1 for a stableswap `exchange`,
    /// 2 for stableswap `exchange_underlying`,
    /// 3 for a cryptoswap `exchange`,
    /// 4 for a cryptoswap `exchange_underlying`,
    /// 5 for factory metapools with lending base pool `exchange_underlying`,
    /// 6 for factory crypto-meta pools underlying exchange (`exchange` method in zap),
    /// 7-9 for underlying coin -> LP token "exchange" (actually `add_liquidity`),
    /// 10-11 for LP token -> underlying coin "exchange" (actually `remove_liquidity_one_coin`)
    /// @param _expected The minimum amount received after the final swap.
    /// @param _pools Array of pools for swaps via zap contracts. This parameter is only needed for
    /// Polygon meta-factories underlying swaps.
    /// @param _permit Permit2 PermitTransferFrom struct, includes receiver, token and amount
    /// @param _signature Signature, used by Permit2
    function exchangeMultiple(
        address[9] memory _route,
        uint256[3][4] memory _swap_params,
        uint256 _expected,
        address[4] memory _pools,
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata _signature
    ) external payable {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        CurveSwapInterface.exchange_multiple(
            _route, _swap_params, _permit.permitted.amount, _expected, _pools, msg.sender
        );
    }

    /// @notice Perform up to four swaps in a single transaction
    /// @dev Routing and swap params must be determined off-chain. This functionality is designed for gas efficiency over ease-of-use.
    /// @param _route Array of [initial token, pool, token, pool, token, ...]
    /// The array is iterated until a pool address of 0x00, then the last
    /// given token is transferred to `_receiver`
    /// @param _swap_params Multidimensional array of [i, j, swap type] where i and j are the correct
    /// values for the n'th pool in `_route`. The swap type should be
    /// 1 for a stableswap `exchange`,
    /// 2 for stableswap `exchange_underlying`,
    /// 3 for a cryptoswap `exchange`,
    /// 4 for a cryptoswap `exchange_underlying`,
    /// 5 for factory metapools with lending base pool `exchange_underlying`,
    /// 6 for factory crypto-meta pools underlying exchange (`exchange` method in zap),
    /// 7-9 for underlying coin -> LP token "exchange" (actually `add_liquidity`),
    /// 10-11 for LP token -> underlying coin "exchange" (actually `remove_liquidity_one_coin`)
    /// @param _amount The amount of `_route[0]` token being sent.
    /// @param _expected The minimum amount received after the final swap.
    /// @param _pools Array of pools for swaps via zap contracts. This parameter is only needed for
    /// Polygon meta-factories underlying swaps.
    /// @param _fee Fee of the proxy
    function exchangeMultipleEth(
        address[9] memory _route,
        uint256[3][4] memory _swap_params,
        uint256 _amount,
        uint256 _expected,
        address[4] memory _pools,
        uint256 _fee
    ) external payable {
        uint256 ethValue = 0;

        ethValue = msg.value - _fee;

        CurveSwapInterface.exchange_multiple{value: ethValue}(
            _route, _swap_params, _amount, _expected, _pools, msg.sender
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

library ErrorCodes {
    uint256 internal constant FAILED_TO_SEND_ETHER = 0;
    uint256 internal constant ETHER_AMOUNT_SURPASSES_MSG_VALUE = 1;

    uint256 internal constant TOKENS_MISMATCHED = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title AllowanceTransfer
/// @notice Handles ERC20 token permissions through signature based allowance setting and ERC20 token transfers by checking allowed amounts
/// @dev Requires user's token approval on the Permit2 contract
interface IAllowanceTransfer {
    /// @notice Thrown when an allowance on a token has expired.
    /// @param deadline The timestamp at which the allowed amount is no longer valid
    error AllowanceExpired(uint256 deadline);

    /// @notice Thrown when an allowance on a token has been depleted.
    /// @param amount The maximum amount allowed
    error InsufficientAllowance(uint256 amount);

    /// @notice Thrown when too many nonces are invalidated.
    error ExcessiveInvalidation();

    /// @notice Emits an event when the owner successfully invalidates an ordered nonce.
    event NonceInvalidation(
        address indexed owner, address indexed token, address indexed spender, uint48 newNonce, uint48 oldNonce
    );

    /// @notice Emits an event when the owner successfully sets permissions on a token for the spender.
    event Approval(
        address indexed owner, address indexed token, address indexed spender, uint160 amount, uint48 expiration
    );

    /// @notice Emits an event when the owner successfully sets permissions using a permit signature on a token for the spender.
    event Permit(
        address indexed owner,
        address indexed token,
        address indexed spender,
        uint160 amount,
        uint48 expiration,
        uint48 nonce
    );

    /// @notice Emits an event when the owner sets the allowance back to 0 with the lockdown function.
    event Lockdown(address indexed owner, address token, address spender);

    /// @notice The permit data for a token
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The permit message signed for multiple token allowances
    struct PermitBatch {
        // the permit data for multiple token allowances
        PermitDetails[] details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The saved permissions
    /// @dev This info is saved per owner, per token, per spender and all signed over in the permit message
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    struct PackedAllowance {
        // amount allowed
        uint160 amount;
        // permission expiry
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice A token spender pair.
    struct TokenSpenderPair {
        // the token the spender is approved
        address token;
        // the spender address
        address spender;
    }

    /// @notice Details for a token transfer.
    struct AllowanceTransferDetails {
        // the owner of the token
        address from;
        // the recipient of the token
        address to;
        // the amount of the token
        uint160 amount;
        // the token to be transferred
        address token;
    }

    /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
    /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
    /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
    function allowance(address, address, address) external view returns (uint160, uint48, uint48);

    /// @notice Approves the spender to use up to amount of the specified token up until the expiration
    /// @param token The token to approve
    /// @param spender The spender address to approve
    /// @param amount The approved amount of the token
    /// @param expiration The timestamp at which the approval is no longer valid
    /// @dev The packed allowance also holds a nonce, which will stay unchanged in approve
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;

    /// @notice Permit a spender to a given amount of the owners token via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitSingle Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external;

    /// @notice Permit a spender to the signed amounts of the owners tokens via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitBatch Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitBatch memory permitBatch, bytes calldata signature) external;

    /// @notice Transfer approved tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address of the recipient
    /// @param amount The amount of the token to transfer
    /// @param token The token address to transfer
    /// @dev Requires the from address to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(address from, address to, uint160 amount, address token) external;

    /// @notice Transfer approved tokens in a batch
    /// @param transferDetails Array of owners, recipients, amounts, and tokens for the transfers
    /// @dev Requires the from addresses to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(AllowanceTransferDetails[] calldata transferDetails) external;

    /// @notice Enables performing a "lockdown" of the sender's Permit2 identity
    /// by batch revoking approvals
    /// @param approvals Array of approvals to revoke.
    function lockdown(TokenSpenderPair[] calldata approvals) external;

    /// @notice Invalidate nonces for a given (token, spender) pair
    /// @param token The token to invalidate nonces for
    /// @param spender The spender to invalidate nonces for
    /// @param newNonce The new nonce to set. Invalidates all nonces less than it.
    /// @dev Can't invalidate more than 2**16 nonces per transaction.
    function invalidateNonces(address token, address spender, uint48 newNonce) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
// import '@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol';
import "@uniswap/v3-periphery/contracts/interfaces/IERC721Permit.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPoolInitializer.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryPayments.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";

interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
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
    function positions(uint256 tokenId)
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
    function mint(MintParams calldata params)
        external
        payable
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

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
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
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
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

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
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @title SignatureTransfer
/// @notice Handles ERC20 token transfers through signature based actions
/// @dev Requires user's token approval on the Permit2 contract
interface ISignatureTransfer {
    /// @notice Thrown when the requested amount for a transfer is larger than the permissioned amount
    /// @param maxAmount The maximum amount a spender can request to transfer
    error InvalidAmount(uint256 maxAmount);

    /// @notice Thrown when the number of tokens permissioned to a spender does not match the number of tokens being transferred
    /// @dev If the spender does not need to transfer the number of tokens permitted, the spender can request amount 0 to be transferred
    error LengthMismatch();

    /// @notice Emits an event when the owner successfully invalidates an unordered nonce.
    event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);

    /// @notice The token and amount details for a transfer signed in the permit transfer signature
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice Specifies the recipient address and amount for batched transfers.
    /// @dev Recipients and amounts correspond to the index of the signed token permissions array.
    /// @dev Reverts if the requested amount is greater than the permitted signed amount.
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    /// @notice Used to reconstruct the signed permit message for multiple token transfers
    /// @dev Do not need to pass in spender address as it is required that it is msg.sender
    /// @dev Note that a user still signs over a spender address
    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice A map from token owner address and a caller specified word index to a bitmap. Used to set bits in the bitmap to prevent against signature replay protection
    /// @dev Uses unordered nonces so that permit messages do not need to be spent in a certain order
    /// @dev The mapping is indexed first by the token owner, then by an index specified in the nonce
    /// @dev It returns a uint256 bitmap
    /// @dev The index, or wordPosition is capped at type(uint248).max
    function nonceBitmap(address, uint256) external view returns (uint256);

    /// @notice Transfers a token using a signed permit message
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers a token using a signed permit message
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Invalidates the bits specified in mask for the bitmap at the word position
    /// @dev The wordPos is maxed at type(uint248).max
    /// @param wordPos A number to index the nonceBitmap at
    /// @param mask A bitmap masked against msg.sender's current bitmap at the word position
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;

interface IUniversalRouter {
    /// @notice Executes encoded commands along with provided inputs. Reverts if deadline has expired.
    /// @param commands A set of concatenated commands, each 1 byte in length
    /// @param inputs An array of byte strings containing abi encoded inputs for each command
    /// @param deadline The deadline by which the transaction must be executed
    function execute(bytes calldata commands, bytes[] calldata inputs, uint256 deadline) external payable;

    /// @notice Executes encoded commands along with provided inputs.
    /// @param commands A set of concatenated commands, each 1 byte in length
    /// @param inputs An array of byte strings containing abi encoded inputs for each command
    function execute(bytes calldata commands, bytes[] calldata inputs) external payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma experimental ABIEncoderV2;
pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev This is an empty interface used to represent either ERC20-conforming token contracts or ETH (using the zero
 * address sentinel value). We're just relying on the fact that `interface` can be used to declare new address-like
 * types.
 *
 * This concept is unrelated to a Pool's Asset Managers.
 */
interface IAsset {
// solhint-disable-previous-line no-empty-blocks
}

interface IVault {
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    /**
     * @dev Allows `relayer` to act as a relayer for `sender` if `approved` is true, and disallows it otherwise.
     *
     * Emits a `RelayerApprovalChanged` event.
     */
    function setRelayerApproval(address sender, address relayer, bool approved) external;

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request)
        external
        payable;

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (IERC20[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(bytes32 poolId, address sender, address payable recipient, ExitPoolRequest memory request)
        external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline)
        external
        payable
        returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
    event Swap(
        bytes32 indexed poolId, IERC20 indexed tokenIn, IERC20 indexed tokenOut, uint256 amountIn, uint256 amountOut
    );

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IWETH9 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(address src, address dst, uint256 wad) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWstETH is IERC20 {
    function wrap(uint256 _stETHAmount) external returns (uint256);
    function unwrap(uint256 _wstETHAmount) external returns (uint256);
    receive() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ISignatureTransfer} from "./ISignatureTransfer.sol";
import {IAllowanceTransfer} from "./IAllowanceTransfer.sol";

/// @notice Permit2 handles signature-based transfers in SignatureTransfer and allowance-based transfers in AllowanceTransfer.
/// @dev Users must approve Permit2 before calling any of the transfer functions.
abstract contract Permit2 is ISignatureTransfer, IAllowanceTransfer {
// Permit2 unifies the two contracts so users have maximal flexibility with their approval.
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import "./ISTETH.sol";

/**
 * @title Liquid staking pool
 *
 * For the high-level description of the pool operation please refer to the paper.
 * Pool manages withdrawal keys and fees. It receives ether submitted by users on the ETH 1 side
 * and stakes it via the deposit_contract.sol contract. It doesn't hold ether on it's balance,
 * only a small portion (buffer) of it.
 * It also mints new tokens for rewards generated at the ETH 2.0 side.
 *
 * At the moment withdrawals are not possible in the beacon chain and there's no workaround.
 * Pool will be upgraded to an actual implementation when withdrawals are enabled
 * (Phase 1.5 or 2 of Eth2 launch, likely late 2022 or 2023).
 */
interface ILido is ISTETH {
    function totalSupply() external view returns (uint256);
    function getTotalShares() external view returns (uint256);

    /**
     * @notice Stop pool routine operations
     */
    function stop() external;

    /**
     * @notice Resume pool routine operations
     */
    function resume() external;

    /**
     * @notice Stops accepting new Ether to the protocol
     *
     * @dev While accepting new Ether is stopped, calls to the `submit` function,
     * as well as to the default payable function, will revert.
     *
     * Emits `StakingPaused` event.
     */
    function pauseStaking() external;

    /**
     * @notice Resumes accepting new Ether to the protocol (if `pauseStaking` was called previously)
     * NB: Staking could be rate-limited by imposing a limit on the stake amount
     * at each moment in time, see `setStakingLimit()` and `removeStakingLimit()`
     *
     * @dev Preserves staking limit if it was set previously
     *
     * Emits `StakingResumed` event
     */
    function resumeStaking() external;

    /**
     * @notice Sets the staking rate limit
     *
     * @dev Reverts if:
     * - `_maxStakeLimit` == 0
     * - `_maxStakeLimit` >= 2^96
     * - `_maxStakeLimit` < `_stakeLimitIncreasePerBlock`
     * - `_maxStakeLimit` / `_stakeLimitIncreasePerBlock` >= 2^32 (only if `_stakeLimitIncreasePerBlock` != 0)
     *
     * Emits `StakingLimitSet` event
     *
     * @param _maxStakeLimit max stake limit value
     * @param _stakeLimitIncreasePerBlock stake limit increase per single block
     */
    function setStakingLimit(uint256 _maxStakeLimit, uint256 _stakeLimitIncreasePerBlock) external;

    /**
     * @notice Removes the staking rate limit
     *
     * Emits `StakingLimitRemoved` event
     */
    function removeStakingLimit() external;

    /**
     * @notice Check staking state: whether it's paused or not
     */
    function isStakingPaused() external view returns (bool);

    /**
     * @notice Returns how much Ether can be staked in the current block
     * @dev Special return values:
     * - 2^256 - 1 if staking is unlimited;
     * - 0 if staking is paused or if limit is exhausted.
     */
    function getCurrentStakeLimit() external view returns (uint256);

    /**
     * @notice Returns full info about current stake limit params and state
     * @dev Might be used for the advanced integration requests.
     * @return isStakingPaused staking pause state (equivalent to return of isStakingPaused())
     * @return isStakingLimitSet whether the stake limit is set
     * @return currentStakeLimit current stake limit (equivalent to return of getCurrentStakeLimit())
     * @return maxStakeLimit max stake limit
     * @return maxStakeLimitGrowthBlocks blocks needed to restore max stake limit from the fully exhausted state
     * @return prevStakeLimit previously reached stake limit
     * @return prevStakeBlockNumber previously seen block number
     */
    function getStakeLimitFullInfo()
        external
        view
        returns (
            bool isStakingPaused,
            bool isStakingLimitSet,
            uint256 currentStakeLimit,
            uint256 maxStakeLimit,
            uint256 maxStakeLimitGrowthBlocks,
            uint256 prevStakeLimit,
            uint256 prevStakeBlockNumber
        );

    event Stopped();
    event Resumed();

    event StakingPaused();
    event StakingResumed();
    event StakingLimitSet(uint256 maxStakeLimit, uint256 stakeLimitIncreasePerBlock);
    event StakingLimitRemoved();

    /**
     * @notice Set Lido protocol contracts (oracle, treasury, insurance fund).
     * @param _oracle oracle contract
     * @param _treasury treasury contract
     * @param _insuranceFund insurance fund contract
     */
    function setProtocolContracts(address _oracle, address _treasury, address _insuranceFund) external;

    event ProtocolContactsSet(address oracle, address treasury, address insuranceFund);

    /**
     * @notice Set fee rate to `_feeBasisPoints` basis points.
     * The fees are accrued when:
     * - oracles report staking results (beacon chain balance increase)
     * - validators gain execution layer rewards (priority fees and MEV)
     * @param _feeBasisPoints Fee rate, in basis points
     */
    function setFee(uint16 _feeBasisPoints) external;

    /**
     * @notice Set fee distribution
     * @param _treasuryFeeBasisPoints basis points go to the treasury,
     * @param _insuranceFeeBasisPoints basis points go to the insurance fund,
     * @param _operatorsFeeBasisPoints basis points go to node operators.
     * @dev The sum has to be 10 000.
     */
    function setFeeDistribution(
        uint16 _treasuryFeeBasisPoints,
        uint16 _insuranceFeeBasisPoints,
        uint16 _operatorsFeeBasisPoints
    ) external;

    /**
     * @notice Returns staking rewards fee rate
     */
    function getFee() external view returns (uint16 feeBasisPoints);

    /**
     * @notice Returns fee distribution proportion
     */
    function getFeeDistribution()
        external
        view
        returns (uint16 treasuryFeeBasisPoints, uint16 insuranceFeeBasisPoints, uint16 operatorsFeeBasisPoints);

    event FeeSet(uint16 feeBasisPoints);

    event FeeDistributionSet(
        uint16 treasuryFeeBasisPoints, uint16 insuranceFeeBasisPoints, uint16 operatorsFeeBasisPoints
    );

    /**
     * @notice A payable function supposed to be called only by LidoExecutionLayerRewardsVault contract
     * @dev We need a dedicated function because funds received by the default payable function
     * are treated as a user deposit
     */
    function receiveELRewards() external payable;

    // The amount of ETH withdrawn from LidoExecutionLayerRewardsVault contract to Lido contract
    event ELRewardsReceived(uint256 amount);

    /**
     * @dev Sets limit on amount of ETH to withdraw from execution layer rewards vault per LidoOracle report
     * @param _limitPoints limit in basis points to amount of ETH to withdraw per LidoOracle report
     */
    function setELRewardsWithdrawalLimit(uint16 _limitPoints) external;

    // Percent in basis points of total pooled ether allowed to withdraw from LidoExecutionLayerRewardsVault per LidoOracle report
    event ELRewardsWithdrawalLimitSet(uint256 limitPoints);

    /**
     * @notice Set credentials to withdraw ETH on ETH 2.0 side after the phase 2 is launched to `_withdrawalCredentials`
     * @dev Note that setWithdrawalCredentials discards all unused signing keys as the signatures are invalidated.
     * @param _withdrawalCredentials withdrawal credentials field as defined in the Ethereum PoS consensus specs
     */
    function setWithdrawalCredentials(bytes32 _withdrawalCredentials) external;

    /**
     * @notice Returns current credentials to withdraw ETH on ETH 2.0 side after the phase 2 is launched
     */
    function getWithdrawalCredentials() external view returns (bytes memory);

    event WithdrawalCredentialsSet(bytes32 withdrawalCredentials);

    /**
     * @dev Sets the address of LidoExecutionLayerRewardsVault contract
     * @param _executionLayerRewardsVault Execution layer rewards vault contract address
     */
    function setELRewardsVault(address _executionLayerRewardsVault) external;

    // The `executionLayerRewardsVault` was set as the execution layer rewards vault for Lido
    event ELRewardsVaultSet(address executionLayerRewardsVault);

    /**
     * @notice Ether on the ETH 2.0 side reported by the oracle
     * @param _epoch Epoch id
     * @param _eth2balance Balance in wei on the ETH 2.0 side
     */
    function handleOracleReport(uint256 _epoch, uint256 _eth2balance) external;

    // User functions

    /**
     * @notice Adds eth to the pool
     * @return StETH Amount of StETH generated
     */
    function submit(address _referral) external payable returns (uint256 StETH);

    // Records a deposit made by a user
    event Submitted(address indexed sender, uint256 amount, address referral);

    // The `amount` of ether was sent to the deposit_contract.deposit function
    event Unbuffered(uint256 amount);

    // Requested withdrawal of `etherAmount` to `pubkeyHash` on the ETH 2.0 side, `tokenAmount` burned by `sender`,
    // `sentFromBuffer` was sent on the current Ethereum side.
    event Withdrawal(
        address indexed sender,
        uint256 tokenAmount,
        uint256 sentFromBuffer,
        bytes32 indexed pubkeyHash,
        uint256 etherAmount
    );

    // Info functions

    /**
     * @notice Gets the amount of Ether controlled by the system
     */
    function getTotalPooledEther() external view returns (uint256);

    /**
     * @notice Gets the amount of Ether temporary buffered on this contract balance
     */
    function getBufferedEther() external view returns (uint256);

    /**
     * @notice Returns the key values related to Beacon-side
     * @return depositedValidators - number of deposited validators
     * @return beaconValidators - number of Lido's validators visible in the Beacon state, reported by oracles
     * @return beaconBalance - total amount of Beacon-side Ether (sum of all the balances of Lido validators)
     */
    function getBeaconStat()
        external
        view
        returns (uint256 depositedValidators, uint256 beaconValidators, uint256 beaconBalance);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface ISTETH is IERC20 {
    function sharesOf(address _account) external view returns (uint256);
    function transferShares(address _recipient, uint256 _sharesAmount) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
pragma abicoder v2;

import "./ILido.sol";
import "../Proxy.sol";
import "../interfaces/IWETH9.sol";
import "../interfaces/IWstETH.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Lido is Proxy {
    using SafeERC20 for IERC20;

    ILido public immutable StETH;
    IWstETH public immutable WstETH;

    /// @notice Lido proxy contract
    /// @dev Lido and StETH contracts are the same
    /// @param _permit2 Permit2 contract address
    /// @param _weth WETH9 contract address
    /// @param _stETH StETH contract address
    /// @param _wstETH WstETH contract address
    constructor(Permit2 _permit2, IWETH9 _weth, ILido _stETH, IWstETH _wstETH) Proxy(_permit2, _weth) {
        StETH = _stETH;
        WstETH = _wstETH;

        _stETH.approve(address(_wstETH), type(uint256).max);
    }

    /// @notice Unwraps WETH to ETH
    function unwrapWETH() private {
        uint256 balanceWETH = WETH.balanceOf(address(this));

        if (balanceWETH > 0) {
            WETH.withdraw(balanceWETH);
        }
    }

    /// @notice Sweeps all ST_ETH tokens of the contract based on shares to msg.sender
    /// @dev This function uses sharesOf instead of balanceOf to transfer 100% of tokens
    function sweepStETH() private {
        StETH.transferShares(msg.sender, StETH.sharesOf(address(this)));
    }

    /// @notice Submits ETH to Lido protocol and transfers ST_ETH to msg.sender
    /// @param _proxyFee Fee of the proxy contract
    /// @return steth Amount of ST_ETH token that is being transferred to msg.sender
    function ethToStETH(uint256 _proxyFee) external payable returns (uint256 steth) {
        steth = StETH.submit{value: msg.value - _proxyFee}(msg.sender);

        sweepStETH();
    }

    /// @notice Converts ETH to WST_ETH and transfers WST_ETH to msg.sender
    /// @param _proxyFee Fee of the proxy contract
    function ethToWstETH(uint256 _proxyFee) external payable {
        _sendETH(address(WstETH), msg.value - _proxyFee);

        _sweepToken(address(WstETH));
    }

    /// @notice Submits WETH to Lido protocol and transfers ST_ETH to msg.sender
    /// @param _permit Permit2 PermitTransferFrom struct
    /// @param _signature Signature, used by Permit2
    /// @return steth Amount of ST_ETH token that is being transferred to msg.sender
    function wethToStETH(ISignatureTransfer.PermitTransferFrom calldata _permit, bytes calldata _signature)
        external
        payable
        returns (uint256 steth)
    {
        require(_permit.permitted.token == address(WETH));

        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        unwrapWETH();

        steth = StETH.submit{value: _permit.permitted.amount}(msg.sender);

        sweepStETH();
    }

    /// @notice Submits WETH to Lido protocol and transfers WST_ETH to msg.sender
    /// @param _permit Permit2 PermitTransferFrom struct
    /// @param _signature Signature, used by Permit2
    function wethToWstETH(ISignatureTransfer.PermitTransferFrom calldata _permit, bytes calldata _signature)
        external
        payable
    {
        require(_permit.permitted.token == address(WETH));

        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        unwrapWETH();

        _sendETH(address(WstETH), _permit.permitted.amount - msg.value);
        _sweepToken(address(WstETH));
    }

    /// @notice Wraps ST_ETH to WST_ETH and transfers it to msg.sender
    /// @param _permit Permit2 PermitTransferFrom struct
    /// @param _signature Signature, used by Permit2
    function stETHToWstETH(ISignatureTransfer.PermitTransferFrom calldata _permit, bytes calldata _signature)
        external
        payable
    {
        require(_permit.permitted.token == address(StETH));

        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        WstETH.wrap(_permit.permitted.amount);
        _sweepToken(address(WstETH));
    }

    /// @notice Unwraps WST_ETH to ST_ETH and transfers it to msg.sender
    /// @param _permit Permit2 PermitTransferFrom struct
    /// @param _signature Signature, used by Permit2
    function wstETHToStETH(ISignatureTransfer.PermitTransferFrom calldata _permit, bytes calldata _signature)
        external
        payable
    {
        require(_permit.permitted.token == address(WstETH));

        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        WstETH.unwrap(_permit.permitted.amount);
        sweepStETH();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./base/Owner.sol";
import "./base/Multicall.sol";

contract Pino is Owner, Multicall {
    /// @notice Proxy contract constructor, sets permit2 and weth addresses
    /// @param _permit2 Permit2 contract address
    /// @param _weth WETH9 contract address
    constructor(Permit2 _permit2, IWETH9 _weth) Owner(_permit2, _weth) {}

    receive() external payable {}
}

/*
                                           +##*:                                          
                                         .######-                                         
                                        .########-                                        
                                        *#########.                                       
                                       :##########+                                       
                                       *###########.                                      
                                      :############=                                      
                   *###################################################.                  
                   :##################################################=                   
                    .################################################-                    
                     .*#############################################-                     
                       =##########################################*.                      
                        :########################################=                        
                          -####################################=                          
                            -################################+.                           
               =##########################################################*               
               .##########################################################-               
                .*#######################################################:                
                  =####################################################*.                 
                   .*#################################################-                   
                     -##############################################=                     
                       -##########################################=.                      
                         :+####################################*-                         
           *###################################################################:          
           =##################################################################*           
            :################################################################=            
              =############################################################*.             
               .*#########################################################-               
                 :*#####################################################-                 
                   .=################################################+:                   
                      -+##########################################*-.                     
     .+*****************###########################################################*:     
      +############################################################################*.     
       :##########################################################################=       
         -######################################################################+.        
           -##################################################################+.          
             -*#############################################################=             
               :=########################################################+:               
                  :=##################################################+-                  
                     .-+##########################################*=:                     
                         .:=*################################*+-.                         
                              .:-=+*##################*+=-:.                              
                                     .:=*#########+-.                                     
                                         .+####*:                                         
                                           .*#:    */
// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./helpers/ErrorCodes.sol";
import "./interfaces/IWETH9.sol";
import "./interfaces/Permit2.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Proxy is Ownable {
    using SafeERC20 for IERC20;

    error ProxyError(uint256 errCode);

    IWETH9 public immutable WETH;
    Permit2 public immutable permit2;

    /// @notice Proxy contract constructor, sets permit2 and weth addresses
    /// @param _permit2 Permit2 contract address
    /// @param _weth WETH9 contract address
    constructor(Permit2 _permit2, IWETH9 _weth) {
        WETH = _weth;
        permit2 = _permit2;
    }

    /// @notice Withdraws fees and transfers them to owner
    /// @param _recipient Address of the destination receiving the fees
    function withdrawAdmin(address _recipient) public onlyOwner {
        require(address(this).balance > 0);

        _sendETH(_recipient, address(this).balance);
    }

    /// @notice Approves an ERC20 token to lendingPool and wethGateway
    /// @param _token ERC20 token address
    /// @param _spenders ERC20 token address
    function approveToken(address _token, address[] calldata _spenders) external {
        for (uint8 i = 0; i < _spenders.length;) {
            _approve(_token, _spenders[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Handles custom error codes
    /// @param _condition The condition, if it's false then execution is reverted
    /// @param _code Custom code, listed in Errors.sol
    function _require(bool _condition, uint256 _code) internal pure {
        if (!_condition) {
            revert ProxyError(_code);
        }
    }

    /// @notice Sweeps contract tokens to msg.sender
    /// @notice _token ERC20 token address
    function _sweepToken(address _token) internal {
        uint256 balanceOf = IERC20(_token).balanceOf(address(this));

        if (balanceOf > 0) {
            IERC20(_token).safeTransfer(msg.sender, balanceOf);
        }
    }

    /// @notice Transfers ERC20 token to recipient
    /// @param _recipient The destination address
    /// @param _token ERC20 token address
    /// @param _amount Amount to transfer
    function _send(address _token, address _recipient, uint256 _amount) internal {
        IERC20(_token).safeTransfer(_recipient, _amount);
    }

    /// @notice Permits _spender to spend max amount of ERC20 from the contract
    /// @param _token ERC20 token address
    /// @param _spender Spender address
    function _approve(address _token, address _spender) internal {
        IERC20(_token).safeApprove(_spender, type(uint256).max);
    }

    /// @notice Sends ETH to the destination
    /// @param _recipient The destination address
    /// @param _amount Ether amount
    function _sendETH(address _recipient, uint256 _amount) internal {
        (bool success,) = payable(_recipient).call{value: _amount}("");

        _require(success, ErrorCodes.FAILED_TO_SEND_ETHER);
    }

    /// @notice Unwraps WETH9 to Ether and sends the amount to the recipient
    /// @param _recipient The destination address
    function _unwrapWETH9(address _recipient) internal {
        uint256 balanceWETH = WETH.balanceOf(address(this));

        if (balanceWETH > 0) {
            WETH.withdraw(balanceWETH);

            _sendETH(_recipient, balanceWETH);
        }
    }

    /// @notice Wraps ETH to WETH and sends to recipient
    /// @param _recipient The destination address
    /// @param _proxyFee Fee of the proxy contract
    function wrapWETH9(address _recipient, uint96 _proxyFee) external payable {
        uint256 value = msg.value - _proxyFee;

        WETH.deposit{value: value}();

        _send(address(WETH), _recipient, value);
    }

    /// @notice Receives WETH and unwraps it to ETH and sends to recipient
    /// @param _recipient The destination address
    /// @param _permit Permit2 PermitTransferFrom struct, includes receiver, token and amount
    /// @param _signature Signature, used by Permit2
    function unwrapWETH9(
        address _recipient,
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata _signature
    ) external payable {
        _require(_permit.permitted.token == address(WETH), ErrorCodes.TOKENS_MISMATCHED);

        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        WETH.withdraw(_permit.permitted.amount);

        _sendETH(_recipient, _permit.permitted.amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../Proxy.sol";
import "../interfaces/IWETH9.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title Swap Aggregators Proxy contract
/// @author Matin Kaboli
/// @notice Swaps tokens and send the new token to msg.sender
/// @dev This contract uses Permit2
contract SwapAggregators is Proxy {
    using SafeERC20 for IERC20;

    address public OInch;
    address public Paraswap;

    /// @notice Sets 1Inch and Paraswap variables and approves some tokens to them
    /// @param _permit2 Permit2 contract address
    /// @param _weth WETH9 contract address
    /// @param _oInch 1Inch contract address
    /// @param _paraswap Paraswap contract address
    /// @param _tokens ERC20 tokens that get allowances
    constructor(Permit2 _permit2, IWETH9 _weth, address _oInch, address _paraswap, IERC20[] memory _tokens)
        Proxy(_permit2, _weth)
    {
        OInch = _oInch;
        Paraswap = _paraswap;

        for (uint8 i = 0; i < _tokens.length;) {
            _tokens[i].safeApprove(_oInch, type(uint256).max);
            _tokens[i].safeApprove(_paraswap, type(uint256).max);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Swaps using 1Inch protocol
    /// @dev Uses permit2 to receive user tokens
    /// @param _data 1Inch protocol data from API
    /// @param _proxyFee Fee of the proxy contract
    /// @param _permit Permit2 instance
    /// @param _signature Signature used for Permit2
    function swap1Inch(
        bytes calldata _data,
        uint256 _proxyFee,
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata _signature
    ) external payable {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        (bool success,) = OInch.call{value: msg.value - _proxyFee}(_data);

        require(success, "Failed");
    }

    /// @notice Swaps using 1Inch protocol
    /// @dev Uses ETH only
    /// @param _data 1Inch protocol generated data from API
    /// @param _proxyFee Fee of the proxy contract
    function swapETH1Inch(bytes calldata _data, uint256 _proxyFee) external payable {
        (bool success,) = OInch.call{value: msg.value - _proxyFee}(_data);

        require(success, "Failed");
    }

    /// @notice Swaps using Paraswap protocol
    /// @dev Uses permit2 to receive user tokens
    /// @param _data Paraswap protocol generated data from API
    /// @param _proxyFee Fee of the proxy contract
    /// @param _permit Permit2 instance
    /// @param _signature Signature used for Permit2
    function swapParaswap(
        bytes calldata _data,
        uint256 _proxyFee,
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata _signature
    ) external payable {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        (bool success,) = Paraswap.call{value: msg.value - _proxyFee}(_data);

        require(success, "Failed");
    }

    /// @notice Swaps using Paraswap protocol
    /// @dev Uses ETH only
    /// @param _data Paraswap protocol generated data from API
    /// @param _proxyFee Fee of the proxy contract
    function swapETHParaswap(bytes calldata _data, uint256 _proxyFee) external payable {
        (bool success,) = Paraswap.call{value: msg.value - _proxyFee}(_data);

        require(success, "Failed");
    }

    /// @notice Swaps using 0x protocol
    /// @dev Uses permit2 to receive user tokens
    /// @param _receiveToken The token that user wants to receive
    /// @param _swapTarget Swap target address, used for sending _data
    /// @param _proxyFee Fee of the proxy contract
    /// @param _permit Permit2 instance
    /// @param _signature Signature used for Permit2
    /// @param _data 0x protocol generated data from API
    function swap0x(
        IERC20 _receiveToken,
        address _swapTarget,
        uint24 _proxyFee,
        ISignatureTransfer.PermitTransferFrom calldata _permit,
        bytes calldata _signature,
        bytes calldata _data
    ) public payable {
        permit2.permitTransferFrom(
            _permit,
            ISignatureTransfer.SignatureTransferDetails({to: address(this), requestedAmount: _permit.permitted.amount}),
            msg.sender,
            _signature
        );

        (bool success,) = payable(_swapTarget).call{value: msg.value - _proxyFee}(_data);

        require(success, "Failed");

        _sweepToken(address(_receiveToken));
    }

    /// @notice Swaps using 0x protocol
    /// @param _receiveToken The token that user wants to receive
    /// @param _swapTarget Swap target address, used for sending _data
    /// @param _proxyFee Fee of the proxy contract
    /// @param _data 0x protocol generated data from API
    function swap0xETH(IERC20 _receiveToken, address _swapTarget, uint24 _proxyFee, bytes calldata _data)
        public
        payable
    {
        (bool success,) = payable(_swapTarget).call{value: msg.value - _proxyFee}(_data);

        require(success, "Failed");

        _sweepToken(address(_receiveToken));
    }

    /// @notice Sets new addresses for 1Inch and Paraswap protocols
    /// @param _oInch Address of the new 1Inch contract
    /// @param _paraswap Address of the new Paraswap contract
    function setDexAddresses(address _oInch, address _paraswap) external onlyOwner {
        OInch = _oInch;
        Paraswap = _paraswap;
    }
}

/*
                                           +##*:                                          
                                         .######-                                         
                                        .########-                                        
                                        *#########.                                       
                                       :##########+                                       
                                       *###########.                                      
                                      :############=                                      
                   *###################################################.                  
                   :##################################################=                   
                    .################################################-                    
                     .*#############################################-                     
                       =##########################################*.                      
                        :########################################=                        
                          -####################################=                          
                            -################################+.                           
               =##########################################################*               
               .##########################################################-               
                .*#######################################################:                
                  =####################################################*.                 
                   .*#################################################-                   
                     -##############################################=                     
                       -##########################################=.                      
                         :+####################################*-                         
           *###################################################################:          
           =##################################################################*           
            :################################################################=            
              =############################################################*.             
               .*#########################################################-               
                 :*#####################################################-                 
                   .=################################################+:                   
                      -+##########################################*-.                     
     .+*****************###########################################################*:     
      +############################################################################*.     
       :##########################################################################=       
         -######################################################################+.        
           -##################################################################+.          
             -*#############################################################=             
               :=########################################################+:               
                  :=##################################################+-                  
                     .-+##########################################*=:                     
                         .:=*################################*+-.                         
                              .:-=+*##################*+=-:.                              
                                     .:=*#########+-.                                     
                                         .+####*:                                         
                                           .*#:    */
// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
pragma abicoder v2;

/// @title UniswapV3 proxy contract
/// @author Matin Kaboli
/// @notice Mints and Increases liquidity and swaps tokens
/// @dev This contract uses Permit2
interface IUniswap {
    struct SwapExactInputSingleParams {
        uint24 fee;
        uint160 sqrtPriceLimitX96;
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The params necessary to swap excact input single
    /// fee Fee of the uniswap pool. For example, 0.01% = 100
    /// tokenIn The input token
    /// tokenOut The receiving token
    /// amountIn The exact amount of tokenIn
    /// amountOutMinimum The minimum amount of tokenOut
    /// @return amountOut The exact amount of tokenOut received from the swap.
    function swapExactInputSingle(IUniswap.SwapExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct SwapExactInputSingleEthParams {
        uint24 fee;
        uint160 sqrtPriceLimitX96;
        address tokenOut;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The params necessary to swap excact input single using ETH
    /// @dev One of the tokens is ETH
    /// fee Fee of the uniswap pool. For example, 0.01% = 100
    /// tokenOut The receiving token
    /// amountOutMinimum The minimum amount expected to receive
    /// @param proxyFee The fee of the proxy contract
    /// @return amountOut The exact amount of tokenOut received from the swap.
    function swapExactInputSingleETH(IUniswap.SwapExactInputSingleEthParams calldata params, uint256 proxyFee)
        external
        payable
        returns (uint256 amountOut);

    struct SwapExactOutputSingleParams {
        uint24 fee;
        uint160 sqrtPriceLimitX96;
        address tokenIn;
        address tokenOut;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The params necessary to swap excact output single
    /// fee Fee of the uniswap pool. For example, 0.01% = 100
    /// tokenOut The receiving token
    /// amountOut The exact amount expected to receive
    /// @return amountIn The exact amount of tokenIn spent to receive the exact desired amountOut.
    function swapExactOutputSingle(IUniswap.SwapExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    struct SwapExactOutputSingleETHParams {
        uint24 fee;
        uint160 sqrtPriceLimitX96;
        address tokenOut;
        uint256 amountOut;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The params necessary to swap excact output single
    /// fee Fee of the uniswap pool. For example, 0.01% = 100
    /// tokenOut The receiving token
    /// @return amountIn The exact amount of tokenIn spent to receive the exact desired amountOut.
    function swapExactOutputSingleETH(IUniswap.SwapExactOutputSingleETHParams calldata params, uint256 proxyFee)
        external
        payable
        returns (uint256 amountIn);

    struct SwapExactInputMultihopParams {
        bytes path;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps a fixed amount of token1 for a maximum possible amount of token2 through an intermediary pool.
    /// @param params The params necessary to swap exact input multihop
    /// path abi.encodePacked of [address, u24, address, u24, address]
    /// amountOutMinimum Minimum amount of token2
    /// @return amountOut The exact amount of tokenOut received from the swap.
    function swapExactInputMultihop(SwapExactInputMultihopParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct SwapMultihopPath {
        bytes path;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps a fixed amount of ETH for a maximum possible amount of token2 through an intermediary pool.
    /// @param params The params necessary to swap exact input multihop
    /// path abi.encodePacked of [WETH, u24, address, u24, address]
    /// amountOutMinimum Minimum amount of token2
    /// @param proxyFee Fee of the proxy contract
    /// @return amountOut The exact amount of tokenOut received from the swap.
    function swapExactInputMultihopETH(SwapMultihopPath calldata params, uint256 proxyFee)
        external
        payable
        returns (uint256 amountOut);

    struct SwapExactOutputMultihopParams {
        bytes path;
        uint256 amountInMaximum;
        uint256 amountOut;
    }

    /// @notice Swaps a minimum possible amount of token1 for a fixed amount of token2 through an intermediary pool.
    /// @param params The params necessary to swap exact output multihop
    /// path abi.encodePacked of [address, u24, address, u24, address]
    /// amountOut The desired amount of token2.
    /// @return amountIn The exact amount of tokenIn spent to receive the exact desired amountOut.
    function swapExactOutputMultihop(SwapExactOutputMultihopParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    struct SwapExactOutputMultihopETHParams {
        bytes path;
        uint256 amountOut;
    }

    /// @notice Swaps a minimum possible amount of ETH for a fixed amount of token2 through an intermediary pool.
    /// @param params The params necessary to swap exact output multihop
    /// path abi.encodePacked of [address, u24, address, u24, WETH]
    /// amountOut The desired amount of token2.
    /// @param proxyFee Fee of the proxy contract
    /// @return amountIn The exact amount of tokenIn spent to receive the exact desired amountOut.
    function swapExactOutputMultihopETH(SwapExactOutputMultihopETHParams calldata params, uint256 proxyFee)
        external
        payable
        returns (uint256 amountIn);

    /// @notice Swaps a fixed amount of token for a maximum possible amount of token2 through intermediary pools.
    /// @param paths Paths of uniswap pools
    /// @return amountOut The exact amount of tokenOut received from the swap.
    function swapExactInputMultihopMultiPool(SwapMultihopPath[] calldata paths)
        external
        payable
        returns (uint256 amountOut);

    /// @notice Swaps a fixed amount of ETH for a maximum possible amount of token2 through intermediary pools.
    /// @param paths Paths of uniswap pools
    /// @param proxyFee Fee of the proxy contract
    /// @return amountOut The exact amount of tokenOut received from the swap.
    function swapExactInputMultihopMultiPoolETH(SwapMultihopPath[] calldata paths, uint256 proxyFee)
        external
        payable
        returns (uint256 amountOut);

    /// @notice Swaps a minimum possible amount of token for a fixed amount of token2 through intermediary pools.
    /// @param paths Paths of uniswap pools
    /// @return amountIn The exact amount of tokenIn spent to receive the exact desired amountOut.
    function swapExactOutputMultihopMultiPool(SwapMultihopPath[] calldata paths)
        external
        payable
        returns (uint256 amountIn);

    /// @notice Swaps a minimum possible amount of ETH for a fixed amount of token2 through intermediary pools.
    /// @param paths Paths of uniswap pools
    /// @param proxyFee Fee of the proxy contract
    /// @return amountIn The exact amount of ETH spent to receive the exact desired amountOut.
    function swapExactOutputMultihopMultiPoolETH(SwapMultihopPath[] calldata paths, uint256 proxyFee)
        external
        payable
        returns (uint256 amountIn);

    struct MintParams {
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        address token0;
        address token1;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 amount0Desired;
        uint256 amount1Desired;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @param params The params necessary to mint a new position
    /// fee Fee of the uniswap pool. For example, 0.01% = 100
    /// tickLower The lower tick in the range
    /// tickUpper The upper tick in the range
    /// amount0Min Minimum amount of the first token to receive
    /// amount1Min Minimum amount of the second token to receive
    /// token0 Token0 address
    /// token1 Token1 address
    /// @param proxyFee Fee of the proxy contract
    /// @return tokenId The id of the newly minted ERC721
    /// @return liquidity The amount of liquidity for the position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(IUniswap.MintParams calldata params, uint256 proxyFee)
        external
        payable
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    struct IncreaseLiquidityParams {
        address token0;
        address token1;
        uint256 tokenId;
        uint256 amountAdd0;
        uint256 amountAdd1;
        uint256 amount0Min;
        uint256 amount1Min;
    }

    /// @notice Increases liquidity in the current range
    /// @param params The params necessary to increase liquidity in a uniswap position
    /// @dev Pool must be initialized already to add liquidity
    /// tokenId The id of the erc721 token
    /// amountAdd0 The amount to add of token0
    /// amountAdd1 The amount to add of token1
    /// amount0Min Minimum amount of the first token to receive
    /// amount1Min Minimum amount of the second token to receive
    /// @param proxyFee Fee of the proxy contract
    function increaseLiquidity(IncreaseLiquidityParams calldata params, uint256 proxyFee)
        external
        payable
        returns (uint128 liquidity, uint256 amount0, uint256 amount1);
}

/*
                                           +##*:                                          
                                         .######-                                         
                                        .########-                                        
                                        *#########.                                       
                                       :##########+                                       
                                       *###########.                                      
                                      :############=                                      
                   *###################################################.                  
                   :##################################################=                   
                    .################################################-                    
                     .*#############################################-                     
                       =##########################################*.                      
                        :########################################=                        
                          -####################################=                          
                            -################################+.                           
               =##########################################################*               
               .##########################################################-               
                .*#######################################################:                
                  =####################################################*.                 
                   .*#################################################-                   
                     -##############################################=                     
                       -##########################################=.                      
                         :+####################################*-                         
           *###################################################################:          
           =##################################################################*           
            :################################################################=            
              =############################################################*.             
               .*#########################################################-               
                 :*#####################################################-                 
                   .=################################################+:                   
                      -+##########################################*-.                     
     .+*****************###########################################################*:     
      +############################################################################*.     
       :##########################################################################=       
         -######################################################################+.        
           -##################################################################+.          
             -*#############################################################=             
               :=########################################################+:               
                  :=##################################################+-                  
                     .-+##########################################*=:                     
                         .:=*################################*+-.                         
                              .:-=+*##################*+=-:.                              
                                     .:=*#########+-.                                     
                                         .+####*:                                         
                                           .*#:    */
// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;
pragma abicoder v2;

import "../Pino.sol";
import "./IUniswap.sol";
import "../interfaces/IWETH9.sol";
import "../interfaces/INonfungiblePositionManager.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

/// @title UniswapV3 proxy contract
/// @author Matin Kaboli
/// @notice Mints and Increases liquidity and swaps tokens
/// @dev This contract uses Permit2
contract Uniswap is IUniswap, Pino {
    using SafeERC20 for IERC20;

    event Mint(uint256 tokenId);

    ISwapRouter public immutable swapRouter;
    INonfungiblePositionManager public immutable nfpm;

    constructor(Permit2 _permit2, IWETH9 _weth, ISwapRouter _swapRouter, INonfungiblePositionManager _nfpm)
        Pino(_permit2, _weth)
    {
        nfpm = _nfpm;
        swapRouter = _swapRouter;
    }

    /// @inheritdoc IUniswap
    function swapExactInputSingle(IUniswap.SwapExactInputSingleParams calldata _params)
        external
        payable
        returns (uint256 amountOut)
    {
        amountOut = swapRouter.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                fee: _params.fee,
                tokenIn: _params.tokenIn,
                tokenOut: _params.tokenOut,
                deadline: block.timestamp,
                amountIn: _params.amountIn,
                amountOutMinimum: _params.amountOutMinimum,
                sqrtPriceLimitX96: _params.sqrtPriceLimitX96,
                recipient: address(this)
            })
        );
    }

    /// @inheritdoc IUniswap
    function swapExactInputSingleETH(IUniswap.SwapExactInputSingleEthParams calldata _params, uint256 _proxyFee)
        external
        payable
        returns (uint256 amountOut)
    {
        uint256 value = msg.value - _proxyFee;

        amountOut = swapRouter.exactInputSingle{value: value}(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(WETH),
                tokenOut: _params.tokenOut,
                fee: _params.fee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: value,
                amountOutMinimum: _params.amountOutMinimum,
                sqrtPriceLimitX96: _params.sqrtPriceLimitX96
            })
        );
    }

    /// @inheritdoc IUniswap
    function swapExactOutputSingle(IUniswap.SwapExactOutputSingleParams calldata _params)
        external
        payable
        returns (uint256 amountIn)
    {
        amountIn = swapRouter.exactOutputSingle(
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: _params.tokenIn,
                tokenOut: _params.tokenOut,
                fee: _params.fee,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: _params.amountOut,
                amountInMaximum: _params.amountInMaximum,
                sqrtPriceLimitX96: _params.sqrtPriceLimitX96
            })
        );
    }

    /// @inheritdoc IUniswap
    function swapExactOutputSingleETH(IUniswap.SwapExactOutputSingleETHParams calldata _params, uint256 _proxyFee)
        external
        payable
        returns (uint256 amountIn)
    {
        uint256 value = msg.value - _proxyFee;

        amountIn = swapRouter.exactOutputSingle{value: value}(
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: address(WETH),
                tokenOut: _params.tokenOut,
                fee: _params.fee,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: _params.amountOut,
                amountInMaximum: value,
                sqrtPriceLimitX96: _params.sqrtPriceLimitX96
            })
        );
    }

    /// @inheritdoc IUniswap
    function swapExactInputMultihop(SwapExactInputMultihopParams calldata _params)
        external
        payable
        returns (uint256 amountOut)
    {
        ISwapRouter.ExactInputParams memory swapParams = ISwapRouter.ExactInputParams({
            path: _params.path,
            deadline: block.timestamp,
            amountIn: _params.amountIn,
            amountOutMinimum: _params.amountOutMinimum,
            recipient: address(this)
        });

        amountOut = swapRouter.exactInput(swapParams);
    }

    /// @inheritdoc IUniswap
    function swapExactInputMultihopETH(SwapMultihopPath calldata _params, uint256 _proxyFee)
        external
        payable
        returns (uint256 amountOut)
    {
        uint256 value = msg.value - _proxyFee;

        ISwapRouter.ExactInputParams memory swapParams = ISwapRouter.ExactInputParams({
            path: _params.path,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountIn: value,
            amountOutMinimum: _params.amountOutMinimum
        });

        amountOut = swapRouter.exactInput{value: value}(swapParams);
    }

    /// @inheritdoc IUniswap
    function swapExactOutputMultihop(SwapExactOutputMultihopParams calldata _params)
        external
        payable
        returns (uint256 amountIn)
    {
        ISwapRouter.ExactOutputParams memory swapParams = ISwapRouter.ExactOutputParams({
            path: _params.path,
            recipient: address(this),
            deadline: block.timestamp,
            amountOut: _params.amountOut,
            amountInMaximum: _params.amountInMaximum
        });

        amountIn = swapRouter.exactOutput(swapParams);
    }

    /// @inheritdoc IUniswap
    function swapExactOutputMultihopETH(SwapExactOutputMultihopETHParams calldata _params, uint256 _proxyFee)
        external
        payable
        returns (uint256 amountIn)
    {
        uint256 value = msg.value - _proxyFee;

        ISwapRouter.ExactOutputParams memory swapParams = ISwapRouter.ExactOutputParams({
            path: _params.path,
            recipient: msg.sender,
            deadline: block.timestamp,
            amountOut: _params.amountOut,
            amountInMaximum: value
        });

        amountIn = swapRouter.exactOutput{value: value}(swapParams);
    }

    /// @inheritdoc IUniswap
    function swapExactInputMultihopMultiPool(SwapMultihopPath[] calldata _paths)
        external
        payable
        returns (uint256 amountOut)
    {
        amountOut = 0;

        for (uint8 i = 0; i < _paths.length;) {
            ISwapRouter.ExactInputParams memory swapParams = ISwapRouter.ExactInputParams({
                path: _paths[i].path,
                deadline: block.timestamp,
                amountIn: _paths[i].amountIn,
                recipient: address(this),
                amountOutMinimum: _paths[i].amountOutMinimum
            });

            uint256 exactAmountOut = swapRouter.exactInput(swapParams);

            amountOut += exactAmountOut;

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IUniswap
    function swapExactInputMultihopMultiPoolETH(SwapMultihopPath[] calldata _paths, uint256 _proxyFee)
        external
        payable
        returns (uint256 amountOut)
    {
        amountOut = 0;
        uint256 sumAmountsIn = 0;

        for (uint8 i = 0; i < _paths.length;) {
            ISwapRouter.ExactInputParams memory swapParams = ISwapRouter.ExactInputParams({
                path: _paths[i].path,
                deadline: block.timestamp,
                amountIn: _paths[i].amountIn,
                recipient: msg.sender,
                amountOutMinimum: _paths[i].amountOutMinimum
            });

            sumAmountsIn += _paths[i].amountIn;
            _require(sumAmountsIn <= msg.value - _proxyFee, ErrorCodes.ETHER_AMOUNT_SURPASSES_MSG_VALUE);

            uint256 exactAmountOut = swapRouter.exactInput{value: _paths[i].amountIn}(swapParams);
            amountOut += exactAmountOut;

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IUniswap
    function swapExactOutputMultihopMultiPool(SwapMultihopPath[] calldata _paths)
        external
        payable
        returns (uint256 amountIn)
    {
        amountIn = 0;

        for (uint8 i = 0; i < _paths.length;) {
            ISwapRouter.ExactOutputParams memory swapParams = ISwapRouter.ExactOutputParams({
                path: _paths[i].path,
                deadline: block.timestamp,
                amountInMaximum: _paths[i].amountIn,
                amountOut: _paths[i].amountOutMinimum,
                recipient: address(this)
            });

            uint256 exactAmountIn = swapRouter.exactOutput(swapParams);
            amountIn += exactAmountIn;

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IUniswap
    function swapExactOutputMultihopMultiPoolETH(SwapMultihopPath[] calldata _paths, uint256 _proxyFee)
        external
        payable
        returns (uint256 amountIn)
    {
        amountIn = 0;
        uint256 value = msg.value - _proxyFee;
        uint256 sumAmountsIn = 0;

        for (uint8 i = 0; i < _paths.length;) {
            ISwapRouter.ExactOutputParams memory swapParams = ISwapRouter.ExactOutputParams({
                path: _paths[i].path,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountInMaximum: _paths[i].amountIn,
                amountOut: _paths[i].amountOutMinimum
            });

            sumAmountsIn += _paths[i].amountIn;
            _require(sumAmountsIn <= value, ErrorCodes.ETHER_AMOUNT_SURPASSES_MSG_VALUE);

            uint256 amountUsed = swapRouter.exactOutput{value: _paths[i].amountIn}(swapParams);
            amountIn += amountUsed;

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc IUniswap
    function mint(IUniswap.MintParams calldata _params, uint256 _proxyFee)
        external
        payable
        returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1)
    {
        INonfungiblePositionManager.MintParams memory mintParams = INonfungiblePositionManager.MintParams({
            fee: _params.fee,
            token0: _params.token0,
            token1: _params.token1,
            tickLower: _params.tickLower,
            tickUpper: _params.tickUpper,
            amount0Desired: _params.amount0Desired,
            amount1Desired: _params.amount1Desired,
            amount0Min: _params.amount0Min,
            amount1Min: _params.amount1Min,
            recipient: msg.sender,
            deadline: block.timestamp
        });

        (tokenId, liquidity, amount0, amount1) = nfpm.mint{value: msg.value - _proxyFee}(mintParams);

        nfpm.refundETH();
        nfpm.sweepToken(_params.token0, 0, msg.sender);
        nfpm.sweepToken(_params.token1, 0, msg.sender);

        emit Mint(tokenId);
    }

    /// @inheritdoc IUniswap
    function increaseLiquidity(IUniswap.IncreaseLiquidityParams calldata _params, uint256 _proxyFee)
        external
        payable
        returns (uint128 liquidity, uint256 amount0, uint256 amount1)
    {
        INonfungiblePositionManager.IncreaseLiquidityParams memory increaseParams = INonfungiblePositionManager
            .IncreaseLiquidityParams({
            tokenId: _params.tokenId,
            amount0Desired: _params.amountAdd0,
            amount1Desired: _params.amountAdd1,
            amount0Min: _params.amount0Min,
            amount1Min: _params.amount1Min,
            deadline: block.timestamp
        });

        (liquidity, amount0, amount1) = nfpm.increaseLiquidity{value: msg.value - _proxyFee}(increaseParams);

        nfpm.refundETH();
        nfpm.sweepToken(_params.token0, 0, msg.sender);
        nfpm.sweepToken(_params.token1, 0, msg.sender);
    }
}