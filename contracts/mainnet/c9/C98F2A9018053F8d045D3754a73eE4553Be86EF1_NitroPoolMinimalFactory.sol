// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
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
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * - The `operator` cannot be the caller.
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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```solidity
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "../NitroPoolMinimal.sol";

import "../interfaces/INFTPool.sol";
import "../interfaces/INitroPoolFactory.sol";
import "../interfaces/tokens/IProtocolToken.sol";
import "../interfaces/tokens/IXToken.sol";

contract NitroPoolMinimalFactory is Ownable, INitroPoolFactory {
    using EnumerableSet for EnumerableSet.AddressSet;

    // (1%) max authorized default fee
    uint256 public constant MAX_DEFAULT_FEE = 100;

    IProtocolToken public immutable protocolToken;
    IXToken public immutable xToken;
    address private immutable _WETH;

    // To receive fees when defaultFee is set
    address public override feeAddress;

    // To recover rewards from emergency closed nitro pools
    address public override emergencyRecoveryAddress;

    // Default fee for nitro pools (*1e2)
    uint256 public defaultFee;

    // Owners or nitro addresses exempted from default fee
    EnumerableSet.AddressSet internal _exemptedAddresses;

    // All nitro pools
    EnumerableSet.AddressSet internal _nitroPools;

    // All published nitro pools
    EnumerableSet.AddressSet private _publishedNitroPools;

    // Published nitro pools per NFTPool
    mapping(address => EnumerableSet.AddressSet) private _nftPoolPublishedNitroPools;

    // Nitro pools per owner
    mapping(address => EnumerableSet.AddressSet) internal _ownerNitroPools;

    // ======================================================================== //
    // ============================== EVENTS ================================== //
    // ======================================================================== //

    event CreateNitroPool(address nitroAddress);
    event PublishNitroPool(address nitroAddress);
    event SetDefaultFee(uint256 fee);
    event SetFeeAddress(address feeAddress);
    event SetEmergencyRecoveryAddress(address emergencyRecoveryAddress);
    event SetExemptedAddress(address exemptedAddress, bool isExempted);
    event SetNitroPoolOwner(address previousOwner, address newOwner);

    // ======================================================================== //
    // ============================== ERRORS ================================== //
    // ======================================================================== //

    error UnknownNitroPool();
    error InvalidAmount();

    // ======================================================================= //
    // ============================= MODIFIERS =============================== //
    // ======================================================================= //

    modifier nitroPoolExists(address nitroPoolAddress) {
        if (!_nitroPools.contains(nitroPoolAddress)) revert UnknownNitroPool();
        _;
    }

    constructor(
        IProtocolToken _protocolToken,
        IXToken _xToken,
        address _weth,
        address _emergencyRecoveryAddress,
        address _feeAddress
    ) {
        address zeroAddr = address(0);
        if (_weth == zeroAddr || _emergencyRecoveryAddress == zeroAddr || _feeAddress == zeroAddr) revert ZeroAddress();

        protocolToken = _protocolToken;
        xToken = _xToken;
        _WETH = _weth;
        emergencyRecoveryAddress = _emergencyRecoveryAddress;
        feeAddress = _feeAddress;
    }

    // ======================================================================= //
    // =========================== EXTERNAL VIEW ============================= //
    // ======================================================================= //

    function WETH() public view override returns (address) {
        return _WETH;
    }

    /**
     * @dev Returns the number of nitroPools
     */
    function nitroPoolsLength() external view returns (uint256) {
        return _nitroPools.length();
    }

    /**
     * @dev Returns a nitroPool from its "index"
     */
    function getNitroPool(uint256 index) external view returns (address) {
        return _nitroPools.at(index);
    }

    /**
     * @dev Returns the number of published nitroPools
     */
    function publishedNitroPoolsLength() external view returns (uint256) {
        return _publishedNitroPools.length();
    }

    /**
     * @dev Returns a published nitroPool from its "index"
     */
    function getPublishedNitroPool(uint256 index) external view returns (address) {
        return _publishedNitroPools.at(index);
    }

    /**
     * @dev Returns the number of published nitroPools linked to "nftPoolAddress" NFTPool
     */
    function nftPoolPublishedNitroPoolsLength(address nftPoolAddress) external view returns (uint256) {
        return _nftPoolPublishedNitroPools[nftPoolAddress].length();
    }

    /**
     * @dev Returns a published nitroPool linked to "nftPoolAddress" from its "index"
     */
    function getNftPoolPublishedNitroPool(address nftPoolAddress, uint256 index) external view returns (address) {
        return _nftPoolPublishedNitroPools[nftPoolAddress].at(index);
    }

    /**
     * @dev Returns the number of nitroPools owned by "userAddress"
     */
    function ownerNitroPoolsLength(address userAddress) external view returns (uint256) {
        return _ownerNitroPools[userAddress].length();
    }

    /**
     * @dev Returns a nitroPool owned by "userAddress" from its "index"
     */
    function getOwnerNitroPool(address userAddress, uint256 index) external view returns (address) {
        return _ownerNitroPools[userAddress].at(index);
    }

    /**
     * @dev Returns the number of exemptedAddresses
     */
    function exemptedAddressesLength() external view returns (uint256) {
        return _exemptedAddresses.length();
    }

    /**
     * @dev Returns an exemptedAddress from its "index"
     */
    function getExemptedAddress(uint256 index) external view returns (address) {
        return _exemptedAddresses.at(index);
    }

    /**
     * @dev Returns if a given address is in exemptedAddresses
     */
    function isExemptedAddress(address checkedAddress) external view returns (bool) {
        return _exemptedAddresses.contains(checkedAddress);
    }

    /**
     * @dev Returns the fee for "nitroPoolAddress" address
     */
    function getNitroPoolFee(address nitroPoolAddress, address ownerAddress) external view override returns (uint256) {
        if (_exemptedAddresses.contains(nitroPoolAddress) || _exemptedAddresses.contains(ownerAddress)) {
            return 0;
        }
        return defaultFee;
    }

    // ======================================================================= //
    // ========================== STATE TRANSITIONS ========================== //
    // ======================================================================= //

    /**
     * @dev Deploys a new Nitro Pool
     */
    function createNitroPool(
        address nftPoolAddress,
        IERC20Metadata[] memory rewardTokens,
        uint256[] memory rewardStartTimes,
        uint256[] memory rewardsPerSecond,
        NitroPoolMinimal.PoolSettings memory _settings
    ) external virtual returns (address nitroPool) {
        // Initialize new nitro pool
        nitroPool = address(
            new NitroPoolMinimal(
                protocolToken,
                xToken,
                msg.sender,
                INFTPool(nftPoolAddress),
                rewardTokens,
                rewardStartTimes,
                rewardsPerSecond,
                _settings
            )
        );

        // Add new nitro
        _nitroPools.add(nitroPool);
        _ownerNitroPools[msg.sender].add(nitroPool);

        emit CreateNitroPool(nitroPool);
    }

    /**
     * @dev Publish a Nitro Pool
     *
     * Must only be called by the Nitro Pool contract
     */
    function publishNitroPool(address nftAddress) external override nitroPoolExists(msg.sender) {
        _publishedNitroPools.add(msg.sender);

        _nftPoolPublishedNitroPools[nftAddress].add(msg.sender);

        emit PublishNitroPool(msg.sender);
    }

    /**
     * @dev Transfers a Nitro Pool's ownership
     *
     * Must only be called by the NitroPool contract
     */
    function setNitroPoolOwner(address previousOwner, address newOwner) external override nitroPoolExists(msg.sender) {
        if (!_ownerNitroPools[previousOwner].remove(msg.sender)) revert InvalidOwner();

        _ownerNitroPools[newOwner].add(msg.sender);

        emit SetNitroPoolOwner(previousOwner, newOwner);
    }

    /**
     * @dev Set nitroPools default fee (when adding rewards)
     *
     * Must only be called by the owner
     */
    function setDefaultFee(uint256 newFee) external onlyOwner {
        if (newFee > MAX_DEFAULT_FEE) revert InvalidAmount();

        defaultFee = newFee;
        emit SetDefaultFee(newFee);
    }

    /**
     * @dev Set fee address
     *
     * Must only be called by the owner
     */
    function setFeeAddress(address feeAddress_) external onlyOwner {
        if (feeAddress_ == address(0)) revert ZeroAddress();
        feeAddress = feeAddress_;
        emit SetFeeAddress(feeAddress_);
    }

    /**
     * @dev Add or remove exemptedAddresses
     *
     * Must only be called by the owner
     */
    function setExemptedAddress(address exemptedAddress, bool isExempted) external onlyOwner {
        if (exemptedAddress == address(0)) revert ZeroAddress();

        if (isExempted) _exemptedAddresses.add(exemptedAddress);
        else _exemptedAddresses.remove(exemptedAddress);

        emit SetExemptedAddress(exemptedAddress, isExempted);
    }

    /**
     * @dev Set emergencyRecoveryAddress
     *
     * Must only be called by the owner
     */
    function setEmergencyRecoveryAddress(address emergencyRecoveryAddress_) external onlyOwner {
        if (emergencyRecoveryAddress_ == address(0)) revert ZeroAddress();

        emergencyRecoveryAddress = emergencyRecoveryAddress_;
        emit SetEmergencyRecoveryAddress(emergencyRecoveryAddress_);
    }

    // ======================================================================= //
    // ============================== INTERNAL =============================== //
    // ======================================================================= //
    /**
     * @dev Utility function to get the current block timestamp
     */
    function _currentBlockTimestamp() internal view virtual returns (uint256) {
        /* solhint-disable not-rely-on-time */
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.7.6 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface INFTHandler is IERC721Receiver {
    function onNFTHarvest(
        address operator,
        address to,
        uint256 tokenId,
        uint256 grailAmount,
        uint256 xGrailAmount
    ) external returns (bool);

    function onNFTAddToPosition(address operator, uint256 tokenId, uint256 lpAmount) external returns (bool);

    function onNFTWithdraw(address operator, uint256 tokenId, uint256 lpAmount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface INFTPool is IERC721 {
    function exists(uint256 tokenId) external view returns (bool);

    function hasDeposits() external view returns (bool);

    function getPoolInfo()
        external
        view
        returns (
            address lpToken,
            address protocolToken,
            address sbtToken,
            uint256 lastRewardTime,
            uint256 accRewardsPerShare,
            uint256 lpSupply,
            uint256 lpSupplyWithMultiplier,
            uint256 allocPointsARX,
            uint256 allocPointsWETH
        );

    function getStakingPosition(
        uint256 tokenId
    )
        external
        view
        returns (
            uint256 amount,
            uint256 amountWithMultiplier,
            uint256 startLockTime,
            uint256 lockDuration,
            uint256 lockMultiplier,
            uint256 rewardDebt,
            uint256 boostPoints,
            uint256 totalMultiplier
        );

    function createPosition(uint256 amount, uint256 lockDuration) external;

    function lastTokenId() external view returns (uint256);

    function pendingRewards(uint256 tokenId) external view returns (uint256 mainAmount, uint256 wethAmount);

    function harvestPositionTo(uint256 tokenId, address to) external;

    function addToPosition(uint256 tokenId, uint256 amountToAdd) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.7.6 <0.9.0;

interface INitroCustomReq {
    function canDepositDescription() external view returns (string calldata);

    function canHarvestDescription() external view returns (string calldata);

    function canDeposit(address user, uint256 tokenId) external view returns (bool);

    function canHarvest(address user) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.7.0 <0.9.0;

interface INitroPoolFactory {
    function emergencyRecoveryAddress() external view returns (address);

    function feeAddress() external view returns (address);

    function getNitroPoolFee(address nitroPoolAddress, address ownerAddress) external view returns (uint256);

    function publishNitroPool(address nftAddress) external;

    function setNitroPoolOwner(address previousOwner, address newOwner) external;

    function WETH() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.7.6 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IProtocolToken is IERC20 {
    function laIProtocolTokenstEmissionTime() external view returns (uint256);

    function claimMasterRewards(uint256 amount) external returns (uint256 effectiveAmount);

    function masterEmissionRate() external view returns (uint256);

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.7.6 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IXToken is IERC20 {
    function usageAllocations(address userAddress, address usageAddress) external view returns (uint256 allocation);

    function allocateFromUsage(address userAddress, uint256 amount) external;

    function convertTo(uint256 amount, address to) external;

    function deallocateFromUsage(address userAddress, uint256 amount) external;

    function isTransferWhitelisted(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

error TokenAlreadyAdded();
error ZeroAddress();
error ArrayLengthMismatch();
error ExceedsMaxTokenDecimals();
error MaxRewardCount();
error TokenNotAdded();
error RewardAlreadyStarted();
error NoRewardsAdded();
error PoolNotStartedYet();
error PoolAlreadyPublished();
error PoolNotPublished();
error CannotDecreaseRequirementSettings();
error LockTimeEndRequirementNotMet();
error LockDurationRequirementNotMet();
error DepositorPoolBalanceTooLow();
error NotWhitelisted();
error CannotHandleRewards();

error InvalidOperator();
error InvalidTokenOperator();
error InvalidStartTime();
error InvalidRewardStartTime();
error InvalidEndTime();
error InvalidDepositEndTime();
error InvalidHarvestStartTime();
error InvalidNFTPool();
error InvalidOwner();
error InvalidCustomRequirement();

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./NitroPoolErrors.sol";

import "./interfaces/INitroPoolFactory.sol";
import "./interfaces/INFTPool.sol";
import "./interfaces/INFTHandler.sol";
import "./interfaces/tokens/IProtocolToken.sol";
import "./interfaces/tokens/IXToken.sol";
import "./interfaces/INitroCustomReq.sol";

contract NitroPoolMinimal is ReentrancyGuard, Ownable, INFTHandler {
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IXToken;
    using SafeERC20 for IProtocolToken;

    struct RewardInfo {
        uint256 accTokenPerShare;
        uint256 rewardPerSecond;
        uint256 startTime;
        uint256 PRECISION_FACTOR;
    }

    struct UserInfo {
        uint256 totalDepositAmount; // Save total deposit amount
    }

    struct PoolSettings {
        uint256 startTime; // Start of rewards distribution
        uint256 endTime; // End of rewards distribution
        uint256 harvestStartTime; // (optional) Time at which stakers will be allowed to harvest their rewards
        uint256 depositEndTime; // (optional) Time at which deposits won't be allowed anymore
        uint256 lockDurationReq; // (optional) required lock duration for positions
        uint256 lockEndReq; // (optional) required lock end time for positions
        uint256 depositAmountReq; // (optional) required deposit amount for positions
        bool whitelist; // (optional) to only allow whitelisted users to deposit
        string description; // Project's description for this NitroPool
    }

    struct WhitelistStatus {
        address account;
        bool status;
    }

    uint8 public constant MAX_REWARDS = 8;

    PoolSettings public settings;

    bool public published; // Is pool published
    bool public emergencyClose; // When activated, can't distribute rewards anymore

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    IProtocolToken public protocolToken;
    IXToken public xToken;
    INitroPoolFactory public factory;
    INFTPool public nftPool;
    INitroCustomReq public customReqContract;

    // pool info
    uint256 public totalDepositAmount;
    uint256 public lastRewardTime;

    uint256 public creationTime;
    uint256 public publishTime;

    // Rewards address Set
    EnumerableSet.AddressSet internal _rewardTokenAddresses;

    // token address => reward info
    mapping(address => RewardInfo) internal _rewardInfo;

    // Set of accounts permitted to perform reward management tasks
    EnumerableSet.AddressSet internal _operators;

    // whitelisted users
    EnumerableSet.AddressSet private _whitelistedUsers;

    mapping(address => UserInfo) public userInfo;

    // user => token => debt
    mapping(address => mapping(address => uint256)) public userRewardDebts;

    // Map each token id back to the owners address
    mapping(uint256 => address) public tokenIdOwner;

    // List of all token id's for an account
    mapping(address => EnumerableSet.UintSet) private _userTokenIds;

    // account => token => amount
    mapping(address => mapping(address => uint256)) private _userPendingRewardBuffer;

    // ======================================================================== //
    // ================================ EVENTS ================================ //
    // ======================================================================== //

    event ActivateEmergencyClose();
    event Publish();
    event Deposit(address indexed userAddress, uint256 tokenId, uint256 amount);
    event Harvest(address indexed userAddress, address rewardsToken, uint256 pending);
    event UpdatePool();
    event Withdraw(address indexed userAddress, uint256 tokenId, uint256 amount);
    event EmergencyWithdraw(address indexed userAddress, uint256 tokenId, uint256 amount);
    event WithdrawRewards(address token, uint256 amount, uint256 totalRewardsAmount);
    event OperatorAdded(address operator);
    event OperatorRemoved(address operator);
    event RewardAdded(address indexed token, uint256 startTime, uint256 rate);
    event RewardRateUpdated(address indexed token, uint256 rate);
    event RewardStartUpdated(address indexed token, uint256 newStart);
    event SetRequirements(uint256 lockDurationReq, uint256 lockEndReq, uint256 depositAmountReq, bool whitelist);
    event SetCustomReqContract(address contractAddress);
    event WhitelistUpdated();
    event WithdrawToken(address token, uint256 amount);

    // ========================================================================== //
    // =============================== MODIFIERS ================================ //
    // ========================================================================== //

    modifier isValidNFTPool(address sender) {
        if (sender != address(nftPool)) revert InvalidNFTPool();
        _;
    }

    modifier onlyPoolOperator() {
        if (!_operators.contains(msg.sender)) revert InvalidOperator();
        _;
    }

    constructor(
        IProtocolToken _protocolToken,
        IXToken _xToken,
        address _owner,
        INFTPool _nftPool,
        IERC20Metadata[] memory rewardTokens,
        uint256[] memory rewardStartTimes,
        uint256[] memory rewardsPerSecond,
        PoolSettings memory _settings
    ) {
        if (address(_protocolToken) == address(0) || address(_xToken) == address(0)) revert ZeroAddress();

        if (_settings.startTime < block.timestamp) revert InvalidStartTime();
        if (_settings.endTime < _settings.startTime) revert InvalidEndTime();
        if (_settings.depositEndTime != 0 && _settings.startTime > _settings.depositEndTime)
            revert InvalidDepositEndTime();
        if (_settings.harvestStartTime != 0 && _settings.startTime > _settings.harvestStartTime)
            revert InvalidHarvestStartTime();

        uint256 rewardCount = rewardTokens.length;
        if (rewardStartTimes.length != rewardCount || rewardsPerSecond.length != rewardCount)
            revert ArrayLengthMismatch();

        factory = INitroPoolFactory(msg.sender);

        nftPool = _nftPool;
        protocolToken = _protocolToken;
        xToken = _xToken;

        creationTime = block.timestamp;
        lastRewardTime = _settings.startTime;

        settings.startTime = _settings.startTime;
        settings.endTime = _settings.endTime;
        settings.harvestStartTime = _settings.harvestStartTime == 0 ? _settings.startTime : _settings.harvestStartTime;
        settings.depositEndTime = _settings.depositEndTime;
        settings.description = _settings.description;

        for (uint256 i = 0; i < rewardCount; ) {
            _addReward(rewardTokens[i], rewardStartTimes[i], rewardsPerSecond[i]);

            unchecked {
                ++i;
            }
        }

        _setRequirements(
            _settings.lockDurationReq,
            _settings.lockEndReq,
            _settings.depositAmountReq,
            _settings.whitelist
        );

        _operators.add(_owner);
        Ownable.transferOwnership(_owner);
    }

    // ========================================================================= //
    // ================================= VIEW ================================== //
    // ========================================================================= //

    /**
     * @dev Returns the number of whitelisted addresses
     */
    function whitelistLength() external view returns (uint256) {
        return _whitelistedUsers.length();
    }

    /**
     * @dev Returns a whitelisted address from its "index"
     */
    function whitelistAddress(uint256 index) external view returns (address) {
        return _whitelistedUsers.at(index);
    }

    /**
     * @dev Checks if "account" address is whitelisted
     */
    function isWhitelisted(address account) external view returns (bool) {
        return _whitelistedUsers.contains(account);
    }

    /**
     * @dev Returns the number of tokenIds from positions deposited by "account" address
     */
    function userTokenIdsLength(address account) external view returns (uint256) {
        return _userTokenIds[account].length();
    }

    /**
     * @dev Returns a position's tokenId deposited by "account" address from its "index"
     */
    function userTokenId(address account, uint256 index) external view returns (uint256) {
        return _userTokenIds[account].at(index);
    }

    function getRewardTokensInfo() external view returns (address[] memory tokens, RewardInfo[] memory rewards) {
        (address[] memory rewardAddresses, uint256 rewardCount) = _getBaseRewardsInfo();

        tokens = rewardAddresses;
        rewards = new RewardInfo[](rewardCount);

        for (uint256 i = 0; i < rewardCount; i++) {
            rewards[i] = _rewardInfo[rewardAddresses[i]];
        }
    }

    function pendingRewards(
        address _user
    ) external view returns (address[] memory tokens, uint256[] memory rewardAmounts) {
        UserInfo storage user = userInfo[_user];

        (address[] memory rewardAddresses, uint256 rewardCount) = _getBaseRewardsInfo();

        tokens = rewardAddresses;
        rewardAmounts = new uint256[](rewardCount);

        // Stash loop items to reduce bytecode size
        RewardInfo memory reward;
        uint256 fromTime;
        uint256 rewardAmount;
        uint256 adjustedTokenPerShare;
        uint256 pendingForToken;
        uint256 blockTime = block.timestamp;

        // gas savings
        // Only need these combined checks once for all tokens instead of on each iteration
        bool shouldCheckRewards = blockTime > lastRewardTime && totalDepositAmount != 0;

        for (uint256 i = 0; i < rewardCount; ) {
            reward = _rewardInfo[rewardAddresses[i]];

            // Handle case of tokens added later also
            // Don't accumulate for rewards not active yet
            if (shouldCheckRewards && blockTime > reward.startTime) {
                // blockTime > reward.startTime. So reward is active at this point

                // Select proper "from" reference since tokens can be added at a later time
                // Using lastRewardTime alone would inflate/blow up the accPer for a token.
                fromTime = reward.startTime > lastRewardTime ? reward.startTime : lastRewardTime;

                rewardAmount = reward.rewardPerSecond * _getMultiplier(fromTime, blockTime);
                adjustedTokenPerShare =
                    reward.accTokenPerShare +
                    (rewardAmount * reward.PRECISION_FACTOR) /
                    totalDepositAmount;

                pendingForToken =
                    (user.totalDepositAmount * adjustedTokenPerShare) /
                    reward.PRECISION_FACTOR -
                    userRewardDebts[_user][rewardAddresses[i]];

                // Add any buffered amount for token
                pendingForToken += _userPendingRewardBuffer[_user][rewardAddresses[i]];

                rewardAmounts[i] = pendingForToken;
            } else {
                pendingForToken =
                    (user.totalDepositAmount * reward.accTokenPerShare) /
                    reward.PRECISION_FACTOR -
                    userRewardDebts[_user][rewardAddresses[i]];

                pendingForToken += _userPendingRewardBuffer[_user][rewardAddresses[i]];

                rewardAmounts[i] = pendingForToken;
            }

            unchecked {
                ++i;
            }
        }
    }

    // ========================================================================= //
    // ============================ EXTERNAL PUBLIC ============================ //
    // ========================================================================= //

    /**
     * @dev Update this NitroPool
     */
    function updatePool() external nonReentrant {
        _updatePool();
    }

    /**
     * @dev Automatically stakes transferred positions from a NFTPool
     * This acts as the sort of "deposit" function into this pool
     */
    function onERC721Received(
        address /*operator*/,
        address from,
        uint256 tokenId,
        bytes calldata /*data*/
    ) external override nonReentrant isValidNFTPool(msg.sender) returns (bytes4) {
        if (!published) revert PoolNotPublished();
        if (settings.whitelist && !_whitelistedUsers.contains(from)) revert NotWhitelisted();

        // Set data in both directions
        _userTokenIds[from].add(tokenId);
        tokenIdOwner[tokenId] = from;

        (uint256 amount, uint256 startLockTime, uint256 lockDuration) = _getStackingPosition(tokenId);
        _checkPositionRequirements(amount, startLockTime, lockDuration);

        _deposit(from, tokenId, amount);

        // Allow depositor to interact with the staked position later
        nftPool.approve(from, tokenId);
        return _ERC721_RECEIVED;
    }

    /**
     * @dev Withdraw a position from the NitroPool
     *
     * Can only be called by the position's previous owner
     */
    function withdraw(uint256 tokenId) external virtual nonReentrant {
        if (msg.sender != tokenIdOwner[tokenId]) revert InvalidOwner();

        (uint256 amount, , ) = _getStackingPosition(tokenId);

        _updatePool();
        UserInfo storage user = userInfo[msg.sender];
        _harvest(user, msg.sender);

        user.totalDepositAmount -= amount;
        totalDepositAmount -= amount;

        _updateRewardDebt(user);

        // Remove from previous owners info
        _userTokenIds[msg.sender].remove(tokenId);
        delete tokenIdOwner[tokenId];

        nftPool.safeTransferFrom(address(this), msg.sender, tokenId);

        emit Withdraw(msg.sender, tokenId, amount);
    }

    /**
     * @dev Withdraw a position from the NitroPool without caring about rewards, EMERGENCY ONLY
     *
     * Can only be called by position's previous owner
     */
    function emergencyWithdraw(uint256 tokenId) external virtual nonReentrant {
        if (msg.sender != tokenIdOwner[tokenId]) revert InvalidOwner();

        (uint256 amount, , ) = _getStackingPosition(tokenId);
        UserInfo storage user = userInfo[msg.sender];
        user.totalDepositAmount -= amount;
        totalDepositAmount -= amount;

        _updateRewardDebt(user);

        // Remove from previous owners info
        _userTokenIds[msg.sender].remove(tokenId);
        delete tokenIdOwner[tokenId];

        nftPool.safeTransferFrom(address(this), msg.sender, tokenId);

        emit EmergencyWithdraw(msg.sender, tokenId, amount);
    }

    /**
     * @dev Harvest pending NitroPool rewards
     */
    function harvest() external nonReentrant {
        _updatePool();
        UserInfo storage user = userInfo[msg.sender];
        _harvest(user, msg.sender);
        _updateRewardDebt(user);
    }

    /**
     * @dev Allow stacked positions to be harvested
     *
     * "to" can be set to token's previous owner
     * "to" can be set to this address only if this contract is allowed to transfer xToken
     */
    function onNFTHarvest(
        address operator,
        address to,
        uint256 tokenId,
        uint256 protocolTokenAmount,
        uint256 xTokenAmount
    ) external override isValidNFTPool(msg.sender) returns (bool) {
        // msg.sender during _checkOnNFTHarvest in NFTPool contract will be the provided operator argument here.
        // Verify that caller is the owner of the associated tokenId here
        address _owner = tokenIdOwner[tokenId];
        if (operator != _owner) revert InvalidTokenOperator();

        // If not whitelisted, the pool can't transfer/forward the xToken rewards owed to owner
        if (to == address(this) && !xToken.isTransferWhitelisted(address(this))) revert CannotHandleRewards();

        // Redirect rewards to position's previous owner
        if (to == address(this)) {
            protocolToken.safeTransfer(_owner, protocolTokenAmount);
            xToken.safeTransfer(_owner, xTokenAmount);
            // Also going to have WETH transferred in here at this time
            // Interface for onNFTHarvest was not updated to account for this in old version of NFTPool code
            IERC20Metadata WETH = IERC20Metadata(factory.WETH());
            WETH.safeTransfer(_owner, WETH.balanceOf(address(this)));
        }

        return true;
    }

    /**
     * @dev Allow position's previous owner to add more assets to his position
     */
    function onNFTAddToPosition(
        address operator,
        uint256 tokenId,
        uint256 amount
    ) external override nonReentrant isValidNFTPool(msg.sender) returns (bool) {
        // msg.sender during _checkOnAddToPosition in NFTPool contract will be the provided operator argument here.
        // Verify that caller is the owner of the associated tokenId here
        if (operator != tokenIdOwner[tokenId]) revert InvalidTokenOperator();
        _deposit(operator, tokenId, amount);
        return true;
    }

    /**
     * @dev Disallow withdraw assets from a stacked position
     */
    function onNFTWithdraw(
        address /*operator*/,
        uint256 /*tokenId*/,
        uint256 /*amount*/
    ) external pure override returns (bool) {
        return false;
    }

    // =============================================================================== //
    // ========================= EXTERNAL OWNABLE FUNCTIONS ========================== //
    // =============================================================================== //

    /**
     * @dev Publish the Nitro Pool
     *
     * Must only be called by the owner
     */
    function publish() external onlyPoolOperator {
        if (published) revert PoolAlreadyPublished();
        // This nitroPool is stale (Eg. publish should be called before the pools start time)
        if (settings.startTime < block.timestamp) revert PoolNotStartedYet();
        if (_rewardTokenAddresses.length() == 0) revert NoRewardsAdded();

        published = true;
        publishTime = block.timestamp;
        factory.publishNitroPool(address(nftPool));

        emit Publish();
    }

    /**
     * @dev Set whitelisted users
     *
     */
    function setWhitelist(WhitelistStatus[] calldata whitelistStatuses) external virtual onlyOwner {
        uint256 whitelistStatusesLength = whitelistStatuses.length;
        require(whitelistStatusesLength > 0, "Empty status list");

        for (uint256 i; i < whitelistStatusesLength; ++i) {
            if (whitelistStatuses[i].status) {
                _whitelistedUsers.add(whitelistStatuses[i].account);
            } else {
                _whitelistedUsers.remove(whitelistStatuses[i].account);
            }
        }

        emit WhitelistUpdated();
    }

    /**
     * @dev Fully reset the current whitelist
     *
     */
    function resetWhitelist() external onlyOwner {
        uint256 i = _whitelistedUsers.length();
        for (i; i > 0; --i) {
            _whitelistedUsers.remove(_whitelistedUsers.at(i - 1));
        }

        emit WhitelistUpdated();
    }

    /**
     * @dev Withdraw tokens from this NitroPool
     *
     * Must only be called by the owner
     */
    function withdrawTokens(address[] calldata tokens, uint256[] calldata amounts) external onlyOwner nonReentrant {
        uint256 tokenCount = tokens.length;
        if (amounts.length != tokenCount) revert ArrayLengthMismatch();

        for (uint256 i = 0; i < tokenCount; ) {
            // Not checking for existence in reward token list in event that another token ended up in the contract
            emit WithdrawToken(tokens[i], amounts[i]);
            _safeRewardsTransfer(IERC20Metadata(tokens[i]), msg.sender, amounts[i]);

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Set an external custom requirement contract
     */
    function setCustomReqContract(address contractAddress) external nonReentrant onlyOwner {
        // Allow to disable customReq event if pool is published
        require(!published || contractAddress == address(0), "published");
        customReqContract = INitroCustomReq(contractAddress);

        emit SetCustomReqContract(contractAddress);
    }

    /**
     * @dev Set requirements that positions must meet to be staked on this Nitro Pool
     *
     * Must only be called by the owner
     */
    function setRequirements(
        uint256 lockDurationReq,
        uint256 lockEndReq,
        uint256 depositAmountReq,
        bool whitelist
    ) external onlyOwner {
        _setRequirements(lockDurationReq, lockEndReq, depositAmountReq, whitelist);
    }

    /**
     * @dev Emergency close
     *
     * Must only be called by the owner
     * Emergency only: if used, the whole pool is definitely made void
     * All rewards are automatically transferred to the emergency recovery address
     */
    function activateEmergencyClose() external nonReentrant onlyOwner {
        address emergencyRecoveryAddress = factory.emergencyRecoveryAddress();

        emergencyClose = true;
        emit ActivateEmergencyClose();

        (address[] memory rewardAddresses, uint256 rewardCount) = _getBaseRewardsInfo();

        for (uint256 i = 0; i < rewardCount; ) {
            IERC20Metadata token = IERC20Metadata(rewardAddresses[i]);
            _safeRewardsTransfer(token, emergencyRecoveryAddress, token.balanceOf(address(this)));

            unchecked {
                ++i;
            }
        }
    }

    function addReward(
        IERC20Metadata rewardToken,
        uint256 rewardStartTime,
        uint256 rewardPerSecond
    ) external onlyOwner {
        _addReward(rewardToken, rewardStartTime, rewardPerSecond);
    }

    function _addReward(IERC20Metadata rewardToken, uint256 rewardStartTime, uint256 rewardPerSecond) private {
        if (_rewardTokenAddresses.length() == MAX_REWARDS) revert MaxRewardCount();
        if (_rewardTokenAddresses.contains(address(rewardToken))) revert TokenAlreadyAdded();
        if (rewardStartTime < block.timestamp || rewardStartTime < settings.startTime) revert InvalidRewardStartTime();

        uint256 decimalsRewardToken = uint256(rewardToken.decimals());
        if (decimalsRewardToken >= 30) revert ExceedsMaxTokenDecimals();

        _rewardTokenAddresses.add(address(rewardToken));

        _rewardInfo[address(rewardToken)] = RewardInfo({
            accTokenPerShare: 0,
            rewardPerSecond: rewardPerSecond,
            startTime: rewardStartTime,
            PRECISION_FACTOR: uint256(10 ** (uint256(30) - decimalsRewardToken))
        });

        emit RewardAdded(address(rewardToken), rewardStartTime, rewardPerSecond);
    }

    function addPoolOperator(address operator) external onlyOwner {
        _operators.add(operator);
        emit OperatorRemoved(operator);
    }

    function removePoolOperator(address operator) external onlyOwner {
        if (!_operators.contains(operator)) revert InvalidOperator();

        _operators.remove(operator);
        emit OperatorRemoved(operator);
    }

    function updateRewardRate(address token, uint256 rate) external onlyOwner {
        _updateRewardRate(token, rate);
    }

    function updateRewardStart(address token, uint256 newStart) external onlyOwner {
        _updateRewardStart(token, newStart);
    }

    /**
     * @dev Transfer ownership of this NitroPool
     *
     * Must only be called by the owner of this contract
     */
    function transferOwnership(address newOwner) public override onlyOwner {
        _setNitroPoolOwner(newOwner);
        Ownable.transferOwnership(newOwner);
    }

    /**
     * @dev Transfer ownership of this NitroPool
     *
     * Must only be called by the owner of this contract
     */
    function renounceOwnership() public override onlyOwner {
        _setNitroPoolOwner(address(0));
        Ownable.renounceOwnership();
    }

    // =============================================================================== //
    // ========================= EXTERNAL OPERATOR FUNCTIONS ========================= //
    // =============================================================================== //

    function operatorAddReward(
        IERC20Metadata rewardToken,
        uint256 rewardStartTime,
        uint256 rewardPerSecond
    ) external onlyPoolOperator {
        _addReward(rewardToken, rewardStartTime, rewardPerSecond);
    }

    function operatorUpdateRewardRate(address token, uint256 rate) external onlyPoolOperator {
        _updateRewardRate(token, rate);
    }

    function operatorUpdateRewardStart(address token, uint256 newStart) external onlyPoolOperator {
        _updateRewardStart(token, newStart);
    }

    // ============================================================================= //
    // ================================= INTERNAL ================================== //
    // ============================================================================= //

    function _updateRewardRate(address rewardToken, uint256 rate) internal {
        _validateRewardToken(rewardToken);

        _rewardInfo[rewardToken].rewardPerSecond = rate;
        emit RewardRateUpdated(rewardToken, rate);
    }

    function _updateRewardStart(address rewardToken, uint256 newStart) internal {
        _validateRewardToken(rewardToken);

        RewardInfo storage reward = _rewardInfo[rewardToken];

        if (block.timestamp >= reward.startTime) revert RewardAlreadyStarted();
        if (newStart < block.timestamp) revert InvalidRewardStartTime();

        reward.startTime = newStart;

        emit RewardStartUpdated(rewardToken, newStart);
    }

    /**
     * @dev Set requirements that positions must meet to be staked on this Nitro Pool
     */
    function _setRequirements(
        uint256 lockDurationReq,
        uint256 lockEndReq,
        uint256 depositAmountReq,
        bool whitelist
    ) internal {
        require(lockEndReq == 0 || settings.startTime < lockEndReq, "invalid lockEnd");
        // if (lockEndReq != 0 && settings.startTime > lockEndReq,)

        if (published) {
            // Can't decrease requirements if already published
            // require(lockDurationReq >= settings.lockDurationReq, "invalid lockDuration");
            // require(lockEndReq >= settings.lockEndReq, "invalid lockEnd");
            // require(depositAmountReq >= settings.depositAmountReq, "invalid depositAmount");

            if (lockDurationReq < settings.lockDurationReq) revert CannotDecreaseRequirementSettings();
            if (lockEndReq < settings.lockEndReq) revert CannotDecreaseRequirementSettings();
            if (depositAmountReq < settings.depositAmountReq) revert CannotDecreaseRequirementSettings();
            require(!settings.whitelist || settings.whitelist == whitelist, "invalid whitelist");
        }

        settings.lockDurationReq = lockDurationReq;
        settings.lockEndReq = lockEndReq;
        settings.depositAmountReq = depositAmountReq;
        settings.whitelist = whitelist;

        emit SetRequirements(lockDurationReq, lockEndReq, depositAmountReq, whitelist);
    }

    function _getBaseRewardsInfo() internal view returns (address[] memory rewardAddresses, uint256 rewardCount) {
        rewardAddresses = _rewardTokenAddresses.values();
        rewardCount = rewardAddresses.length;
    }

    /**
     * @dev Updates rewards states of this Nitro Pool to be up-to-date
     */
    function _updatePool() internal {
        uint256 currentBlockTimestamp = block.timestamp;

        if (currentBlockTimestamp <= lastRewardTime) return;

        // do nothing if there is no deposit
        if (totalDepositAmount == 0) {
            lastRewardTime = currentBlockTimestamp;
            emit UpdatePool();
            return;
        }

        (address[] memory rewardAddresses, uint256 rewardCount) = _getBaseRewardsInfo();
        uint256 fromTime;
        uint256 multiplier;
        uint256 rewardAmount;
        uint256 _startTime;

        for (uint256 i = 0; i < rewardCount; ) {
            RewardInfo storage reward = _rewardInfo[rewardAddresses[i]];
            _startTime = reward.startTime;

            // Handle case of tokens added later
            // Don't accumulate for rewards not active yet
            if (_startTime < block.timestamp) {
                // reward.startTime < block.timestamp (start is in the past). So reward is active.
                // Compare the reward start time to lastRewardTime.
                // Check is in the event reward emissions, should, have started.
                // But lastRewardTime is currently still some time before the rewards start time.
                // Meaning there has not been any triggers to updatePool since the rewards scheduled start time.

                fromTime = _startTime > lastRewardTime ? _startTime : lastRewardTime;
                multiplier = _getMultiplier(fromTime, block.timestamp);
                rewardAmount = reward.rewardPerSecond * multiplier;
                reward.accTokenPerShare += (rewardAmount * reward.PRECISION_FACTOR) / totalDepositAmount;
            }

            unchecked {
                ++i;
            }
        }

        lastRewardTime = currentBlockTimestamp;
        emit UpdatePool();
    }

    /**
     * @dev Add a user's deposited amount into this Nitro Pool
     */
    function _deposit(address account, uint256 tokenId, uint256 amount) internal {
        require(
            (settings.depositEndTime == 0 || settings.depositEndTime >= block.timestamp) && !emergencyClose,
            "Deposits not allowed"
        );

        if (address(customReqContract) != address(0)) {
            if (!customReqContract.canDeposit(account, tokenId)) revert InvalidCustomRequirement();
        }

        _updatePool();

        UserInfo storage user = userInfo[account];
        _harvest(user, account);

        user.totalDepositAmount += amount;
        totalDepositAmount += amount;

        _updateRewardDebt(user);

        emit Deposit(account, tokenId, amount);
    }

    /**
     * @dev Transfer to a user its pending rewards
     *
     * There may be local or custom requirements that prevent the user from being able to currently harvest.
     * In that case, any pending amounts are buffered for the user to be claimable later.
     */
    function _harvest(UserInfo storage user, address to) internal {
        uint256 userAmount = user.totalDepositAmount;
        // Check and exit early to reduce code nesting blocks below
        if (userAmount == 0) return;

        bool canHarvest = true;
        if (address(customReqContract) != address(0)) {
            canHarvest = customReqContract.canHarvest(to);
        }

        // We don't check for a short circuit option on canHarvest because rewards can be buffered for later

        (address[] memory rewardAddresses, uint256 rewardCount) = _getBaseRewardsInfo();
        RewardInfo memory reward;
        uint256 pendingForToken;
        address rewardAddress;

        for (uint256 i = 0; i < rewardCount; ) {
            rewardAddress = rewardAddresses[i];
            reward = _rewardInfo[rewardAddress];

            pendingForToken =
                (userAmount * reward.accTokenPerShare) /
                reward.PRECISION_FACTOR -
                userRewardDebts[msg.sender][rewardAddress];

            // Check if harvest is allowed
            if (block.timestamp < settings.harvestStartTime || !canHarvest) {
                // Buffer any pending amounts to be claimed later
                _userPendingRewardBuffer[msg.sender][rewardAddress] += pendingForToken;
            } else {
                // Otherwise complete harvest to user process
                if (pendingForToken > 0) {
                    _userPendingRewardBuffer[msg.sender][rewardAddress] = 0;
                    emit Harvest(to, rewardAddress, pendingForToken);
                    _safeRewardsTransfer(IERC20Metadata(rewardAddress), to, pendingForToken);
                }
            }

            unchecked {
                ++i;
            }
        }

        // Reward debts are handled/updated in each of the local calling functions afterwards as needed
    }

    /**
     * @dev Update a user's rewardDebt for rewardsToken1 and rewardsToken2
     */
    function _updateRewardDebt(UserInfo storage user) internal virtual {
        (address[] memory rewardAddresses, uint256 rewardCount) = _getBaseRewardsInfo();

        for (uint256 i = 0; i < rewardCount; ) {
            RewardInfo memory reward = _rewardInfo[rewardAddresses[i]];
            userRewardDebts[msg.sender][rewardAddresses[i]] =
                (user.totalDepositAmount * reward.accTokenPerShare) /
                reward.PRECISION_FACTOR;

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Check whether a position with "tokenId" ID is meeting all of this Nitro Pool's active requirements
     */
    function _checkPositionRequirements(uint256 amount, uint256 startLockTime, uint256 lockDuration) internal virtual {
        // lock duration requirement
        uint256 lockDurationReq = settings.lockDurationReq;
        if (lockDurationReq > 0) {
            // For unlocked position that have not been updated yet
            if (block.timestamp > startLockTime + lockDuration && lockDurationReq > lockDuration) {
                revert LockDurationRequirementNotMet();
            }
        }

        // lock end time requirement
        uint256 lockEndReq = settings.lockEndReq;
        if (lockEndReq > 0) {
            if (lockEndReq > startLockTime + lockDuration) revert LockTimeEndRequirementNotMet();
        }

        // Deposit amount requirement
        uint256 depositAmountReq = settings.depositAmountReq;
        if (depositAmountReq > 0) {
            if (amount < depositAmountReq) revert DepositorPoolBalanceTooLow();
        }
    }

    function _validateRewardToken(address rewardToken) internal view {
        if (rewardToken == address(0)) revert ZeroAddress();
        if (!_rewardTokenAddresses.contains(rewardToken)) revert TokenNotAdded();
    }

    /**
     * @dev Safe token transfer function, in case rounding error causes pool to not have enough tokens
     */
    function _safeRewardsTransfer(IERC20Metadata token, address to, uint256 amount) internal virtual {
        if (amount == 0) return;

        uint256 balance = token.balanceOf(address(this));

        // Cap to available balance
        if (amount > balance) {
            amount = balance;
        }

        token.safeTransfer(to, amount);
    }

    function _getStackingPosition(
        uint256 tokenId
    ) internal view returns (uint256 amount, uint256 startLockTime, uint256 lockDuration) {
        (amount, , startLockTime, lockDuration, , , , ) = nftPool.getStakingPosition(tokenId);
    }

    function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
        if (_to <= settings.endTime) {
            return _to - _from;
        } else if (_from >= settings.endTime) {
            return 0;
        } else {
            return settings.endTime - _from;
        }
    }

    function _setNitroPoolOwner(address newOwner) internal {
        factory.setNitroPoolOwner(owner(), newOwner);
    }
}