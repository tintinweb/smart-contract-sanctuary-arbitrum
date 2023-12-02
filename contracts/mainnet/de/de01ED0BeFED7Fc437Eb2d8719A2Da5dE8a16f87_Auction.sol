// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
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
// OpenZeppelin Contracts (last updated v4.9.3) (token/ERC20/utils/SafeERC20.sol)

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
     * non-reverting calls are assumed to be successful. Meant to be used with tokens that require the approval
     * to be set to zero before setting it to a non-zero value, such as USDT.
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

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolErrors,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
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
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

import './IPoolInitializer.sol';
import './IERC721Permit.sol';
import './IPeripheryPayments.sol';
import './IPeripheryImmutableState.sol';
import '../libraries/PoolAddress.sol';

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

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
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

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
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

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
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xa598dd2fba360510c5a8f02f44423a4468e902df5857dbce3ca162a43a3a31ff;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encode(key.token0, key.token1, key.fee)),
                            POOL_INIT_CODE_HASH
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

import {INonfungiblePositionManager} from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import {TransferHelper} from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {IBurnableToken} from "./interfaces/IBurnableToken.sol";
import {IERC20Mintable} from "./interfaces/IERC20Mintable.sol";
import {IFeeSplitter} from "./interfaces/IFeeSplitter.sol";
import {SignatureHelper} from "./libs/SignatureHelper.sol";
import {IAuction} from "./interfaces/IAuction.sol";
import {IRecycle} from "./interfaces/IRecycle.sol";
import {IVeXNF} from "./interfaces/IVeXNF.sol";
import {IXNF} from "./interfaces/IXNF.sol";
import {console} from "hardhat/console.sol";
import {Math} from "./libs/Math.sol";

/*
 * @title Auction Contract
 *
 * @notice This contract facilitates a token burning mechanism where users can burn their tokens in exchange
 * for rewards. The contract manages the burn process, calculates rewards, and distributes them accordingly.
 * It's an essential component of the ecosystem, promoting token scarcity and incentivising user participation.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
contract Auction is
    IAuction,
    ReentrancyGuard
{

    /// ------------------------------------- LIBRARYS ------------------------------------- \\\

    /**
     * @notice Library used for splitting and recovering signatures.
     */
    using SignatureHelper for bytes;

    /**
     * @notice Library used for handling message hashes.
     */
    using SignatureHelper for bytes32;

    /**
     * @notice Library used for safeTransfer.
     */
    using SafeERC20 for IERC20Mintable;

    /// ------------------------------------ VARIABLES ------------------------------------- \\\

    /**
     * @notice Internal flag to check if a function was previously called.
     */
    bool internal _isTriggered;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Denominator for basis points calculations.
     */
    uint256 constant public BP = 1e18;

    /**
     * @notice The constant pool fee value.
     */
    uint24 public constant POOL_FEE = 1e4;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice The current nonce value.
     */
    uint256 public nonce;

    /**
     * @notice Fee amount per batch.
     */
    uint256 public batchFee;

    /**
     * @notice Amount of YSL tokens per batch.
     */
    uint256 public YSLPerBatch;

    /**
     * @notice Amount of vXEN tokens per batch.
     */
    uint256 public vXENPerBatch;

    /**
     * @notice The current cycle number.
     */
    uint256 public currentCycle;

    /**
     * @notice The last active cycle number.
     */
    uint256 public lastActiveCycle;

    /**
     * @notice Duration of a period in seconds.
     */
    uint256 public i_periodDuration;

    /**
     * @notice The initial timestamp when the contract was deployed.
     */
    uint256 public i_initialTimestamp;

    /**
     * @notice The last cycle in which fees were claimed.
     */
    uint256 public lastClaimFeesCycle;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Array of cycle numbers for halving events.
     */
    uint256[9] public cyclesForHalving;

    /**
     * @notice Array of reward amounts for each halving event.
     */
    uint256[9] public rewardsPerHalving;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Address of the veXNF contract, set during deployment and cannot be changed.
     */
    address public veXNF;

    /**
     * @notice Address of the Auction contract, set during deployment and cannot be changed.
     */
    address public Recycle;

    /**
     * @notice Address of the first registrar.
     */
    address public registrar1;

    /**
     * @notice Address of the second registrar.
     */
    address public registrar2;

    /// ------------------------------------ INTERFACES ------------------------------------- \\\

    /**
     * @notice Interface to interact with the XNF token contract.
     */
    IERC20Mintable public xnf;

    /**
     * @notice Interface to interact with the YSL token contract.
     */
    IBurnableToken public ysl;

    /**
     * @notice Interface to interact with the vXEN token contract.
     */
    IBurnableToken public vXEN;

    /**
     * @notice Interface to interact with the NonfungiblePositionManager contract.
     */
    INonfungiblePositionManager public nonfungiblePositionManager;

    /// ------------------------------------ MAPPINGS --------------------------------------- \\\

    /**
     * @notice Mapping that associates each user address with their respective user information.
     */
    mapping (address => User) public userInfo;

    /**
     * @notice Mapping that associates each cycle number with its respective cycle information.
     */
    mapping (uint256 => Cycle) public cycleInfo;

    /**
     * @notice Mapping that associates each user address with their last activity information.
     */
    mapping (address => UserLastActivity) public userLastActivityInfo;

    /**
     * @notice Mapping that associates each cycle number with the total recycler power during the first hour.
     */
    mapping (uint256 => uint256) public totalPowerOfRecyclersFirstHour;

    /**
     * @notice Mapping that associates each user and cycle with their recycler power during the first hour.
     */
    mapping (address => mapping (uint256 => uint256)) public recyclerPowerFirstHour;

    /// -------------------------------------- ERRORS --------------------------------------- \\\

    /**
     * @notice Error thrown when the transfer of native tokens failed.
     */
    error TransferFailed();

    /**
     * @notice Error thrown when the provided YSL address is the zero address.
     */
    error ZeroYSLAddress();

    /**
     * @notice Error thrown when the provided vXEN address is the zero address.
     */
    error ZeroVXENAddress();

    /**
     * @notice Error thrown when the provided signature is invalid.
     */
    error InvalidSignature();

    /**
     * @notice Error thrown when the batch number is out of the allowed range.
     */
    error InvalidBatchNumber();

    /**
     * @notice Error thrown when a function is called by an unauthorized address.
     */
    error UnauthorizedCaller();

    /**
     * @notice Error thrown when the provided value is less than the required burn fee.
     */
    error InsufficientBurnFee();

    /**
     * @notice Error thrown when the provided Registrar 1 address is the zero address.
     */
    error ZeroRegistrar1Address();

    /**
     * @notice Error thrown when native fee is insufficient.
     */
    error InsufficientNativeFee();

    /**
     * @notice Error thrown when the provided Registrar 2 address is the zero address.
     */
    error ZeroRegistrar2Address();

    /**
     * @notice Error thrown when the partner percentage exceeds the allowed limit.
     */
    error InvalidPartnerPercentage();

    /**
     * @notice Error thrown when there's an attempt to distribute an invalid amount.
     */
    error InvalidDistributionAmount();

    /**
     * @notice Error thrown when the transfer amount is insufficient.
     */
    error InsufficientTransferAmount();

    /**
     * @notice Error thrown when no native rewards are available for recycling.
     */
    error NoNativeRewardsForRecycling();

    /**
     * @notice Error thrown when the contract is already initialised.
     */
    error ContractInitialised(address contractAddress);

    /**
     * @notice Error thrown when native value is insufficient for burn.
     */
    error InsufficientNativeValue(uint256 nativeValue, uint256 burnFee);

    /// ------------------------------------- STRUCTURES ------------------------------------ \\\

    /**
     * @notice User info struct detailing accumulated activities and pending rewards.
     * @param accCycleYSLBurnedBatches Accumulated YSL batches burned by the user in the current cycle.
     * @param accCyclevXENBurnedBatches Accumulated vXEN batches burned by the user in the current cycle.
     * @param accCycleNativeBatches Accumulated native batches by the user in the current cycle.
     * @param accCycleSwaps Accumulated swaps made by the user in the current cycle.
     * @param pendingRewardsFromBurn Pending XNF rewards from burning activities.
     * @param pendingRewardsFromSwap Pending XNF rewards from swapping activities.
     * @param pendingRewardsFromNative Pending XNF rewards from native participation activities.
     * @param pendingNative Pending native rewards for the user.
     */
    struct User {
        uint256 accCycleYSLBurnedBatches;
        uint256 accCyclevXENBurnedBatches;
        uint256 accCycleNativeBatches;
        uint256 accCycleSwaps;
        uint256 pendingRewardsFromBurn;
        uint256 pendingRewardsFromSwap;
        uint256 pendingRewardsFromNative;
        uint256 pendingNative;
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Struct capturing the accumulated activities and rewards for a specific cycle.
     * @param previouseActiveCycle The previous active cycle number.
     * @param cycleYSLBurnedBatches Accumulated YSL batches burned in the current cycle.
     * @param cyclevXENBurnedBatches Accumulated vXEN batches burned in the current cycle.
     * @param cycleNativeBatches Accumulated native batches in the current cycle.
     * @param cycleAccNative Accumulated native rewards in the current cycle.
     * @param cycleAccNativeFromSwaps Accumulated native rewards from swaps in the current cycle.
     * @param cycleAccNativeFromNativeParticipants Accumulated native rewards from native participation in the current cycle.
     * @param cycleAccNativeFromAuction Accumulated native rewards from auctions in the current cycle.
     * @param cycleAccExactNativeFromSwaps Accumulated exact native rewards from swaps in the current cycle.
     * @param cycleAccBonus Accumulated bonus in the current cycle.
     * @param accRewards Accumulated rewards for the current cycle.
     */
    struct Cycle {
        uint256 previouseActiveCycle;
        uint256 cycleYSLBurnedBatches;
        uint256 cyclevXENBurnedBatches;
        uint256 cycleNativeBatches;
        uint256 cycleAccNative;
        uint256 cycleAccNativeFromSwaps;
        uint256 cycleAccNativeFromNativeParticipants;
        uint256 cycleAccNativeFromAuction;
        uint256 cycleAccExactNativeFromSwaps;
        uint256 cycleAccBonus;
        uint256 accRewards;
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Struct capturing the last cycle of various user activities.
     * @param lastCycleForBurn Last cycle in which the user burned tokens.
     * @param lastCycleForRecycle Last cycle in which the user recycled.
     * @param lastCycleForSwap Last cycle in which the user swapped.
     * @param lastCycleForNativeParticipation Last cycle in which the user participated in native activities.
     * @param lastUpdatedStats Last cycle in which the user's stats were updated.
     */
    struct UserLastActivity {
        uint256 lastCycleForBurn;
        uint256 lastCycleForRecycle;
        uint256 lastCycleForSwap;
        uint256 lastCycleForNativeParticipation;
        uint256 lastUpdatedStats;
    }

    /// -------------------------------------- EVENTS --------------------------------------- \\\

    /**
     * @notice Triggered when a user burns tokens.
     * @param isvXEN Indicates if the burned tokens are vXEN.
     * @param user Address initiating the burn.
     * @param batchNumber Count of batches burned.
     * @param burnFee Fee incurred for the burn action.
     * @param cycle Current cycle during which the action is taking place.
     */
    event BurnAction(
        bool isvXEN,
        address indexed user,
        uint256 batchNumber,
        uint256 burnFee,
        uint256 cycle
    );

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Triggered when a user claims XNF rewards.
     * @param user Address of the claimer.
     * @param cycle Current cycle during which the action is taking place.
     * @param pendingRewardsFromBurn Amount of XNF rewards claimed from burning.
     */
    event XNFClaimed(
        address indexed user,
        uint256 cycle,
        uint256 pendingRewardsFromBurn
    );

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Triggered when a user claims veXNF.
     * @param user Address of the claimer.
     * @param cycle Current cycle during which the action is taking place.
     * @param veXNFClaimedAmount Total amount of veXNF claimed.
     */
    event veXNFClaimed(
        address indexed user,
        uint256 cycle,
        uint256 veXNFClaimedAmount
    );

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Triggered when a user claims native rewards.
     * @param user Address of the claimer.
     * @param cycle Current cycle during which the action is taking place.
     * @param bonusAdded Bonus amount added to the rewards pool.
     * @param nativeTransferred Total native amount transferred to the user.
     */
    event NativeClaimed(
        address indexed user,
        uint256 cycle,
        uint256 bonusAdded,
        uint256 nativeTransferred
    );

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Triggered when a user recycles tokens.
     * @param user Address initiating the recycle action.
     * @param cycle Current cycle during which the action is taking place.
     * @param burnFee Fee incurred for recycling.
     * @param batchNumber Count of batches recycled.
     * @param nativeAmountRecycled Total native amount recycled.
     * @param userRecyclerPower Power of the user during recycling.
     * @param totalRecyclerPower Combined power of all recyclers.
     */
    event RecycleAction(
        address indexed user,
        uint256 cycle,
        uint256 burnFee,
        uint256 batchNumber,
        uint256 nativeAmountRecycled,
        uint256 userRecyclerPower,
        uint256 totalRecyclerPower
    );

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Triggered when a user registers for swapping.
     * @param user Address of the registered user.
     * @param cycle Current cycle during which the action is taking place.
     * @param swapFee Fee incurred for the swap registration.
     * @param registrar Address responsible for the registration.
     */
    event SwapUserRegistered(
        address indexed user,
        uint256 cycle,
        uint256 swapFee,
        address registrar
    );

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Triggered upon participation using native tokens.
     * @param user Participant's address.
     * @param batchNumber Count of participation batches.
     * @param burnFee Fee incurred for participation.
     * @param cycle Current cycle during which the action is taking place.
     */
    event ParticipateWithNative(
        address indexed user,
        uint256 batchNumber,
        uint256 burnFee,
        uint256 cycle
    );

    /// --------------------------------- EXTERNAL FUNCTIONS -------------------------------- \\\

    /**
     * @notice Initialises the contract with essential parameters.
     * @param _Recycle Address of the Recycle contract.
     * @param _xnf Address of the XNF token contract.
     * @param _veXNF Address of the veXNF contract.
     * @param _vXEN Address of the vXEN token contract.
     * @param _ysl Address of the YSL token contract.
     * @param _registrar1 Address of the first registrar.
     * @param _registrar2 Address of the second registrar.
     * @param _YSLPerBatch Amount of YSL tokens per batch.
     * @param _vXENPerBatch Amount of vXEN tokens per batch.
     * @param _batchFee Amount of native tokens per batch.
     * @param _nonfungiblePositionManager Address of the NonfungiblePositionManager contract.
     */
    function initialise(
        address _Recycle,
        address _xnf,
        address _veXNF,
        address _vXEN,
        address _ysl,
        address _registrar1,
        address _registrar2,
        uint256 _YSLPerBatch,
        uint256 _vXENPerBatch,
        uint256 _batchFee,
        address _nonfungiblePositionManager
    ) external {
        if (address(ysl) != address(0)) {
            revert ContractInitialised(address(ysl));
        }
        if (_ysl == address(0)) {
            revert ZeroYSLAddress();
        }
        if (_vXEN == address(0)) {
            revert ZeroVXENAddress();
        }
        if (_registrar1 == address(0)) {
            revert ZeroRegistrar1Address();
        }
        if (_registrar2 == address(0)) {
            revert ZeroRegistrar2Address();
        }
        rewardsPerHalving = [
            10000 ether, 5000 ether, 2500 ether,
            1250 ether, 625 ether, 312.5 ether,
            156.25 ether
        ];
        cyclesForHalving = [
            90, 270, 630,
            1350, 2790, 4230,
            5670, 73830
        ];
        nonfungiblePositionManager = INonfungiblePositionManager(_nonfungiblePositionManager);
        registrar1 = _registrar1;
        registrar2 = _registrar2;
        i_initialTimestamp = block.timestamp+1 hours;
        i_periodDuration = 1 days;
        vXEN = IBurnableToken(_vXEN);
        ysl = IBurnableToken(_ysl);
        vXENPerBatch = _vXENPerBatch;
        YSLPerBatch = _YSLPerBatch;
        batchFee = _batchFee;
        Recycle = _Recycle;
        veXNF = _veXNF;
        xnf = IERC20Mintable(_xnf);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Accepts native tokens and contributes to the cycle's auction fees.
     * @dev Updates the current cycle's accumulated fees from auctions and creates protocol-owned liquidity.
     */
    receive() external payable {
        calculateCycle();
        cycleInfo[currentCycle].cycleAccNativeFromAuction += msg.value * 25 / 100;
        IRecycle(Recycle).executeBuybackBurn{value: msg.value * 75 / 100} ();
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows the caller to claim all their pending rewards.
     * @dev Claims native, XNF, and veXNF rewards for the caller.
     */
    function claimAll() external override {
        _updateStatsForUser(msg.sender);
        _claimNative(msg.sender);
        _claimXNF(msg.sender);
        _claimveXNF(msg.sender);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Claims all rewards on behalf of a specified user.
     * @dev Only callable by the veXNF contract. Claims native, XNF, and veXNF rewards for the specified user.
     * @param _user Address of the user for whom rewards are being claimed.
     */
    function claimAllForUser(address _user)
        external
        override
    {
        if (msg.sender != veXNF) {
            revert UnauthorizedCaller();
        }
        _updateStatsForUser(_user);
        _claimNative(_user);
        _claimXNF(_user);
        _claimveXNF(_user);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Claims veXNF rewards on behalf of a specified user.
     * @dev Only callable by the veXNF contract. Claims veXNF rewards for the specified user.
     * @param _user Address of the user for whom rewards are being claimed.
     */
    function claimVeXNFForUser(address _user)
        external
        override
    {
        if (msg.sender != veXNF) {
            revert UnauthorizedCaller();
        }
        _claimveXNF(_user);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows the caller to recycle native rewards and claim all other rewards.
     * @dev Recycles native rewards and claims XNF and veXNF rewards for the caller.
     */
    function claimAllAndRecycle() external override {
        _updateStatsForUser(msg.sender);
        _recycle(msg.sender);
        _claimXNF(msg.sender);
        _claimveXNF(msg.sender);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns specified batches of vXEN or YSL tokens to earn rewards.
     * @dev Updates the current cycle and user stats based on the burn action.
     * @param _isvXEN Indicates if vXEN tokens are being burned. If false, YSL tokens are burned.
     * @param _batchNumber Number of token batches to burn.
     */
    function burn(
        bool _isvXEN,
        uint256 _batchNumber
    )
        external
        payable
        override
    {
        if (_isvXEN) {
            vXEN.burn(msg.sender, _batchNumber * vXENPerBatch);
        }
        else {
            ysl.burn(msg.sender, _batchNumber * YSLPerBatch);
        }
        calculateCycle();
        if (_batchNumber > 1e4 || _batchNumber < 1) {
            revert InvalidBatchNumber();
        }
        uint256 burnFee = coefficientWrapper(_batchNumber);
        if (_isvXEN) {
            _setupNewCycle(0, _batchNumber, 0, 0, burnFee);
            if (currentCycle == 0) {
                userInfo[msg.sender].accCyclevXENBurnedBatches += _batchNumber;
            }
            else {
                updateStats(msg.sender);
                if (userLastActivityInfo[msg.sender].lastCycleForBurn != currentCycle) {
                    userInfo[msg.sender].accCyclevXENBurnedBatches = _batchNumber;
                }
                else {
                    userInfo[msg.sender].accCyclevXENBurnedBatches += _batchNumber;
                }
                userLastActivityInfo[msg.sender].lastCycleForBurn = currentCycle;
            }
        } else {
            _setupNewCycle(_batchNumber, 0, 0, 0, burnFee);
            if (currentCycle == 0) {
                userInfo[msg.sender].accCycleYSLBurnedBatches += _batchNumber;
            }
            else {
                updateStats(msg.sender);
                if (userLastActivityInfo[msg.sender].lastCycleForBurn != currentCycle) {
                    userInfo[msg.sender].accCycleYSLBurnedBatches = _batchNumber;
                }
                else {
                    userInfo[msg.sender].accCycleYSLBurnedBatches += _batchNumber;
                }
                userLastActivityInfo[msg.sender].lastCycleForBurn = currentCycle;
            }
        }
        if (msg.value < burnFee) {
            revert InsufficientBurnFee();
        }
        _sendViaCall(
            payable(msg.sender),
            msg.value - burnFee
        );
        emit BurnAction(
            _isvXEN,
            msg.sender,
            _batchNumber,
            burnFee,
            currentCycle
        );
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Registers the caller as a swap user and earns rewards.
     * @dev Validates the signature, updates the current cycle, and user stats.
     * @param signature Signed data for user registration.
     * @param partner Address of the partner for fee distribution.
     * @param partnerPercent Percentage of fees to be distributed to the partner.
     * @param feeSplitter Address responsible for fee distribution.
     */
    function registerSwapUser(
        bytes calldata signature,
        address partner,
        uint256 partnerPercent,
        address feeSplitter
    )
        external
        payable
        override
    {
        if (msg.value == 0) {
            revert InsufficientTransferAmount();
        }
        if (partnerPercent > 50) {
            revert InvalidPartnerPercentage();
        }
        calculateCycle();
        uint256 fee;
        if (partner != address(0)) {
            fee = msg.value - msg.value * partnerPercent / 100;
        } else {
            fee = msg.value;
        }
        _setupNewCycle(0, 0, 0, fee, msg.value);
        (bytes32 r, bytes32 s, uint8 v) = signature._splitSignature();
        bytes32 messageHash = (
            SignatureHelper._getMessageHash(
                msg.sender,
                msg.value,
                partner,
                partnerPercent,
                feeSplitter,
                nonce
            )
        )._getEthSignedMessageHash();
        address signatureAddress = ecrecover(messageHash, v, r, s);
        if (signatureAddress != registrar1 && signatureAddress != registrar2) {
            revert InvalidSignature();
        }
        nonce++;
        if (currentCycle == 0) {
            userInfo[msg.sender].accCycleSwaps = msg.value;
        }
        else {
            updateStats(msg.sender);
            if (userLastActivityInfo[msg.sender].lastCycleForSwap != currentCycle) {
                userInfo[msg.sender].accCycleSwaps = msg.value;
            }
            else {
                userInfo[msg.sender].accCycleSwaps += msg.value;
            }
            userLastActivityInfo[msg.sender].lastCycleForSwap = currentCycle;
        }
        if (partner != address(0)) {
            IFeeSplitter(feeSplitter).distributeFees{value: msg.value * partnerPercent / 100} (partner);
        }
        emit SwapUserRegistered(
            msg.sender,
            currentCycle,
            msg.value,
            signatureAddress
        );
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Registers the caller as a burner by paying in native tokens.
     * @dev Updates the current cycle and user stats based on the native participation.
     * @param _batchNumber Number of batches the user is participating with.
     */
    function participateWithNative(uint256 _batchNumber)
        external
        payable
        override
    {
        calculateCycle();
        if (_batchNumber > 1e4 || _batchNumber < 1) {
            revert InvalidBatchNumber();
        }
        uint256 nativeFee = coefficientWrapper(_batchNumber);
        _setupNewCycle(0, 0, _batchNumber, 0, nativeFee);
        if (currentCycle == 0) {
            userInfo[msg.sender].accCycleNativeBatches += _batchNumber;
        }
        else {
            updateStats(msg.sender);
            if (userLastActivityInfo[msg.sender].lastCycleForNativeParticipation != currentCycle) {
                userInfo[msg.sender].accCycleNativeBatches = _batchNumber;
            }
            else {
                userInfo[msg.sender].accCycleNativeBatches += _batchNumber;
            }
            userLastActivityInfo[msg.sender].lastCycleForNativeParticipation = currentCycle;
        }
        if (msg.value < nativeFee) {
            revert InsufficientNativeFee();
        }
        _sendViaCall(
            payable(msg.sender),
            msg.value - nativeFee
        );
        emit ParticipateWithNative(
            msg.sender,
            _batchNumber,
            nativeFee,
            currentCycle
        );
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows the caller to claim their native rewards.
     * @dev Internally calls the _claimNative function to handle the reward claim.
     */
    function claimNative()
        external
        override
        nonReentrant
    {
        _updateStatsForUser(msg.sender);
        _claimNative(msg.sender);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows the caller to claim their pending XNF rewards.
     * @dev Updates user stats and transfers the XNF rewards to the caller.
     */
    function claimXNF() external override {
        _updateStatsForUser(msg.sender);
        _claimXNF(msg.sender);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows the caller to claim XNF rewards and locks them in the veXNF contract for a year.
     * @dev Claims XNF rewards for the caller and locks them in the veXNF contract.
     */
    function claimVeXNF() external override {
        _updateStatsForUser(msg.sender);
        _claimveXNF(msg.sender);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Enables users to recycle their native rewards and claim other rewards.
     * @dev Processes the recycling of native rewards and distributes rewards based on user participation.
     */
    function recycle() external override {
        _updateStatsForUser(msg.sender);
        _recycle(msg.sender);
    }

    /// --------------------------------- PUBLIC FUNCTIONS ---------------------------------- \\\

    /**
     * @notice Updates the current cycle number based on the elapsed time since the contract's initialisation.
     * @dev If the calculated cycle is greater than the stored cycle, it updates the stored cycle.
     * @return The calculated current cycle, representing the number of complete cycles that have elapsed.
     */
    function calculateCycle()
        public
        override
        returns (uint256)
    {
        uint256 calculatedCycle = getCurrentCycle();
        if (calculatedCycle > currentCycle) {
            currentCycle = calculatedCycle;
        }
        return calculatedCycle;
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Refreshes the user's statistics, including pending rewards and fees.
     * @dev This function should be called periodically to ensure accurate user statistics.
     * @param _user The user's address whose statistics need to be updated.
     */
    function updateStats(address _user)
        public
        override
    {
        calculateCycle();
        User storage user = userInfo[_user];
        UserLastActivity storage userLastActivity = userLastActivityInfo[_user];
        (
            uint256 pendingRewardsFromBurn,
            uint256 pendingRewardsFromSwap,
            uint256 pendingRewardsFromNative
        ) = pendingXNF(_user);
        if (userLastActivity.lastCycleForBurn != currentCycle && (user.accCycleYSLBurnedBatches != 0 || user.accCyclevXENBurnedBatches != 0)) {
            user.accCycleYSLBurnedBatches = 0;
            user.accCyclevXENBurnedBatches = 0;
        }
        if (userLastActivity.lastCycleForNativeParticipation != currentCycle && user.accCycleNativeBatches != 0) {
            user.accCycleNativeBatches = 0;
        }
        if (userLastActivity.lastCycleForSwap != currentCycle && user.accCycleSwaps != 0) {
            user.accCycleSwaps = 0;
        }
        user.pendingRewardsFromSwap = pendingRewardsFromSwap;
        user.pendingRewardsFromBurn = pendingRewardsFromBurn;
        user.pendingRewardsFromNative = pendingRewardsFromNative;
        user.pendingNative = pendingNative(_user);
        if (userLastActivity.lastCycleForRecycle < currentCycle) {
            recyclerPowerFirstHour[_user][userLastActivity.lastCycleForRecycle] = 0;
        }
        userLastActivity.lastUpdatedStats = currentCycle;
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Computes the pending XNF rewards for a user across various activities.
     * @dev Rewards are calculated based on user's activities like burning, swapping, recycling, and native participation.
     * @param _user Address of the user to compute rewards for.
     * @return pendingRewardsFromBurn Rewards from burning tokens.
     * @return pendingRewardsFromSwap Rewards from swapping tokens.
     * @return pendingRewardsFromNative Rewards from native token participation.
     */
    function pendingXNF(address _user)
        public
        view
        override
        returns (
            uint256 pendingRewardsFromBurn,
            uint256 pendingRewardsFromSwap,
            uint256 pendingRewardsFromNative
        )
    {
        uint256 rewardsFromYSLBurn;
        uint256 rewardsFromvXENBurn;
        uint256 rewardsFromSwap;
        uint256 rewardsFromNative;
        User memory user = userInfo[_user];
        UserLastActivity storage userLastActivity = userLastActivityInfo[_user];
        uint256 cycle = getCurrentCycle();
        if (cycleInfo[userLastActivity.lastCycleForSwap].cycleAccNativeFromSwaps != 0 && user.accCycleSwaps != 0) {
            rewardsFromSwap = calculateRewardPerCycle(userLastActivity.lastCycleForSwap) * user.accCycleSwaps
                                    / cycleInfo[userLastActivity.lastCycleForSwap].cycleAccNativeFromSwaps;
            if (cycleInfo[userLastActivity.lastCycleForBurn].cycleYSLBurnedBatches != 0 || cycleInfo[userLastActivity.lastCycleForBurn].cyclevXENBurnedBatches != 0) {
                rewardsFromSwap /= 2;
            }
            if (cycleInfo[userLastActivity.lastCycleForBurn].cycleNativeBatches != 0) {
                rewardsFromSwap /= 10;
            }
        }
        if (cycleInfo[userLastActivity.lastCycleForNativeParticipation].cycleNativeBatches != 0 && user.accCycleNativeBatches != 0) {
            rewardsFromNative = calculateRewardPerCycle(userLastActivity.lastCycleForNativeParticipation) * user.accCycleNativeBatches
                                    / cycleInfo[userLastActivity.lastCycleForNativeParticipation].cycleNativeBatches;
            if (cycleInfo[userLastActivity.lastCycleForBurn].cycleYSLBurnedBatches != 0 || cycleInfo[userLastActivity.lastCycleForBurn].cyclevXENBurnedBatches != 0) {
                rewardsFromNative /= 2;
            }
            if (cycleInfo[userLastActivity.lastCycleForBurn].cycleAccNativeFromSwaps != 0) {
                rewardsFromNative = rewardsFromNative * 9 / 10;
            }
        }
        uint256 totalBatchesBurned = cycleInfo[userLastActivity.lastCycleForBurn].cycleYSLBurnedBatches 
                                        + cycleInfo[userLastActivity.lastCycleForBurn].cyclevXENBurnedBatches;
        if (cycleInfo[userLastActivity.lastCycleForBurn].cycleYSLBurnedBatches != 0 && user.accCycleYSLBurnedBatches != 0) {
            rewardsFromYSLBurn = calculateRewardPerCycle(userLastActivity.lastCycleForBurn) * user.accCycleYSLBurnedBatches
                                    / cycleInfo[userLastActivity.lastCycleForBurn].cycleYSLBurnedBatches;
            if (cycleInfo[userLastActivity.lastCycleForSwap].cycleAccNativeFromSwaps != 0 || cycleInfo[userLastActivity.lastCycleForBurn].cycleNativeBatches != 0) {
                rewardsFromYSLBurn /= 2;
            }
            if (cycleInfo[userLastActivity.lastCycleForBurn].cyclevXENBurnedBatches != 0) {
                rewardsFromYSLBurn = rewardsFromYSLBurn * cycleInfo[userLastActivity.lastCycleForBurn].cycleYSLBurnedBatches / totalBatchesBurned;
            }
        }
        if (cycleInfo[userLastActivity.lastCycleForBurn].cyclevXENBurnedBatches != 0 && user.accCyclevXENBurnedBatches != 0) {
            rewardsFromvXENBurn = calculateRewardPerCycle(userLastActivity.lastCycleForBurn) * user.accCyclevXENBurnedBatches
                                    / cycleInfo[userLastActivity.lastCycleForBurn].cyclevXENBurnedBatches;
            if (cycleInfo[userLastActivity.lastCycleForSwap].cycleAccNativeFromSwaps != 0 || cycleInfo[userLastActivity.lastCycleForBurn].cycleNativeBatches != 0) {
                rewardsFromvXENBurn /= 2;
            }
            if (cycleInfo[userLastActivity.lastCycleForBurn].cycleYSLBurnedBatches != 0) {
                rewardsFromvXENBurn = rewardsFromvXENBurn * cycleInfo[userLastActivity.lastCycleForBurn].cyclevXENBurnedBatches / totalBatchesBurned;
            }
        }
        if (userLastActivity.lastCycleForBurn != cycle && (user.accCycleYSLBurnedBatches != 0 || user.accCyclevXENBurnedBatches != 0)) {
            pendingRewardsFromBurn = rewardsFromYSLBurn + rewardsFromvXENBurn;
        }
        if (userLastActivity.lastCycleForSwap != cycle && user.accCycleSwaps != 0) {
            pendingRewardsFromSwap += rewardsFromSwap;
        }
        if (userLastActivity.lastCycleForNativeParticipation != cycle && user.accCycleNativeBatches != 0) {
            pendingRewardsFromNative += rewardsFromNative;
        }
        if (userLastActivity.lastUpdatedStats < cycle) {
            pendingRewardsFromBurn += user.pendingRewardsFromBurn;
            pendingRewardsFromSwap += user.pendingRewardsFromSwap;
            pendingRewardsFromNative += user.pendingRewardsFromNative;
        } else {
            pendingRewardsFromBurn = user.pendingRewardsFromBurn;
            pendingRewardsFromSwap = user.pendingRewardsFromSwap;
            pendingRewardsFromNative = user.pendingRewardsFromNative;
        }
        return (pendingRewardsFromBurn, pendingRewardsFromSwap, pendingRewardsFromNative);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Calculates the pending native token rewards for a user based on their NFT ownership and recycling activities.
     * @dev The rewards are accumulated over cycles and are based on user's recycling power and NFT ownership.
     * @param _user Address of the user to compute native rewards for.
     * @return _pendingNative Total pending native rewards for the user.
     */
    function pendingNative(address _user)
        public
        view
        override
        returns (uint256 _pendingNative)
    {
        User memory user = userInfo[_user];
        UserLastActivity storage userLastActivity = userLastActivityInfo[_user];
        uint256 cycle = getCurrentCycle();
        if (userLastActivity.lastUpdatedStats < cycle) {
            uint256 cycleEndTs;
            for (uint256 i = userLastActivity.lastUpdatedStats; i < cycle; i++) {
                cycleEndTs = i_initialTimestamp + i_periodDuration * (i + 1) - 1;
                if (cycleInfo[i].cycleAccNative + cycleInfo[i].cycleAccExactNativeFromSwaps
                    + cycleInfo[i].cycleAccNativeFromAuction + cycleInfo[i].cycleAccNativeFromNativeParticipants != 0) {
                    if (IVeXNF(veXNF).totalBalanceOfNFTAt(_user, cycleEndTs) != 0) {
                        _pendingNative += (cycleInfo[i].cycleAccNative + cycleInfo[i].cycleAccExactNativeFromSwaps
                                            + cycleInfo[i].cycleAccNativeFromAuction + cycleInfo[i].cycleAccNativeFromNativeParticipants)
                                                * IVeXNF(veXNF).totalBalanceOfNFTAt(_user, cycleEndTs) / IVeXNF(veXNF).totalSupplyAtT(cycleEndTs);
                    }
                }
            }
        }
        if (userLastActivity.lastCycleForRecycle < cycle) {
            if (cycleInfo[userLastActivity.lastCycleForRecycle].cycleAccBonus != 0) {
                if (recyclerPowerFirstHour[_user][userLastActivity.lastCycleForRecycle] != 0) {
                    _pendingNative += cycleInfo[userLastActivity.lastCycleForRecycle].cycleAccBonus
                                        * recyclerPowerFirstHour[_user][userLastActivity.lastCycleForRecycle]
                                            / totalPowerOfRecyclersFirstHour[userLastActivity.lastCycleForRecycle];
                }
            }
        }
        if (userLastActivity.lastUpdatedStats < cycle) {
            _pendingNative += user.pendingNative;
        } else {
            _pendingNative = user.pendingNative;
        }
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Calculates the pending native token rewards for a user for the current cycle based on their NFT ownership and recycling activities.
     * @dev The rewards are accumulated over cycles and are based on user's recycling power and NFT ownership.
     * @param _user Address of the user to compute native rewards for.
     * @return _pendingNative Total pending native rewards for the user for the current cycle.
     */
    function pendingNativeForCurrentCycle(address _user)
        public
        view
        override
        returns (uint256 _pendingNative)
    {
        UserLastActivity storage userLastActivity = userLastActivityInfo[_user];
        uint256 cycle = getCurrentCycle();
        uint256 cycleEndTs;
        cycleEndTs = i_initialTimestamp + i_periodDuration * (cycle + 1) - 1;
        if (cycleInfo[cycle].cycleAccNative + cycleInfo[cycle].cycleAccExactNativeFromSwaps
                + cycleInfo[cycle].cycleAccNativeFromAuction + cycleInfo[cycle].cycleAccNativeFromNativeParticipants != 0) {
            if (IVeXNF(veXNF).totalBalanceOfNFTAt(_user, cycleEndTs) != 0) {
                _pendingNative = (cycleInfo[cycle].cycleAccNative + cycleInfo[cycle].cycleAccExactNativeFromSwaps
                                    + cycleInfo[cycle].cycleAccNativeFromAuction + cycleInfo[cycle].cycleAccNativeFromNativeParticipants)
                                        * IVeXNF(veXNF).totalBalanceOfNFTAt(_user, cycleEndTs) / IVeXNF(veXNF).totalSupplyAtT(cycleEndTs);
            }
        }
        if (userLastActivity.lastCycleForRecycle == cycle) {
            if (cycleInfo[cycle].cycleAccBonus != 0) {
                if (recyclerPowerFirstHour[_user][cycle] != 0) {
                    _pendingNative += cycleInfo[cycle].cycleAccBonus
                                        * recyclerPowerFirstHour[_user][cycle]
                                            / totalPowerOfRecyclersFirstHour[cycle];
                }
            }
        }
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Computes the pending XNF rewards for a user for the current cycle across various activities.
     * @dev Rewards are calculated based on user's activities like burning, swapping, recycling, and native participation.
     * @param _user Address of the user to compute rewards for.
     * @return pendingRewardsFromBurn Rewards from burning tokens.
     * @return pendingRewardsFromSwap Rewards from swapping tokens.
     * @return pendingRewardsFromNative Rewards from native token participation.
     */
    function pendingXNFForCurrentCycle(address _user)
        public
        view
        override
        returns (
            uint256 pendingRewardsFromBurn,
            uint256 pendingRewardsFromSwap,
            uint256 pendingRewardsFromNative
        )
    {
        uint256 rewardsFromYSLBurn;
        uint256 rewardsFromvXENBurn;
        uint256 rewardsFromSwap;
        uint256 rewardsFromNative;
        User memory user = userInfo[_user];
        UserLastActivity storage userLastActivity = userLastActivityInfo[_user];
        uint256 cycle = getCurrentCycle();
        if (cycleInfo[cycle].cycleAccNativeFromSwaps != 0 && user.accCycleSwaps != 0) {
            rewardsFromSwap = calculateRewardPerCycle(cycle) * user.accCycleSwaps
                                    / cycleInfo[cycle].cycleAccNativeFromSwaps;
            if (cycleInfo[cycle].cycleYSLBurnedBatches != 0 || cycleInfo[cycle].cyclevXENBurnedBatches != 0) {
                rewardsFromSwap /= 2;
            }
            if (cycleInfo[cycle].cycleNativeBatches != 0) {
                rewardsFromSwap /= 10;
            }
        }
        if (cycleInfo[cycle].cycleNativeBatches != 0 && user.accCycleNativeBatches != 0) {
            rewardsFromNative = calculateRewardPerCycle(cycle) * user.accCycleNativeBatches
                                    / cycleInfo[cycle].cycleNativeBatches;
            if (cycleInfo[cycle].cycleYSLBurnedBatches != 0 || cycleInfo[cycle].cyclevXENBurnedBatches != 0) {
                rewardsFromNative /= 2;
            }
            if (cycleInfo[cycle].cycleAccNativeFromSwaps != 0) {
                rewardsFromNative = rewardsFromNative * 9 / 10;
            }
        }
        uint256 totalBatchesBurned = cycleInfo[cycle].cycleYSLBurnedBatches 
                                        + cycleInfo[cycle].cyclevXENBurnedBatches;
        if (cycleInfo[cycle].cycleYSLBurnedBatches != 0 && user.accCycleYSLBurnedBatches != 0) {
            rewardsFromYSLBurn = calculateRewardPerCycle(cycle) * user.accCycleYSLBurnedBatches
                                    / cycleInfo[cycle].cycleYSLBurnedBatches;
            if (cycleInfo[cycle].cycleAccNativeFromSwaps != 0 || cycleInfo[cycle].cycleNativeBatches != 0) {
                rewardsFromYSLBurn /= 2;
            }
            if (cycleInfo[cycle].cyclevXENBurnedBatches != 0) {
                rewardsFromYSLBurn = rewardsFromYSLBurn * cycleInfo[cycle].cycleYSLBurnedBatches / totalBatchesBurned;
            }
        }
        if (cycleInfo[cycle].cyclevXENBurnedBatches != 0 && user.accCyclevXENBurnedBatches != 0) {
            rewardsFromvXENBurn = calculateRewardPerCycle(cycle) * user.accCyclevXENBurnedBatches
                                    / cycleInfo[cycle].cyclevXENBurnedBatches;
            if (cycleInfo[cycle].cycleAccNativeFromSwaps != 0 || cycleInfo[cycle].cycleNativeBatches != 0) {
                rewardsFromvXENBurn /= 2;
            }
            if (cycleInfo[cycle].cycleYSLBurnedBatches != 0) {
                rewardsFromvXENBurn = rewardsFromvXENBurn * cycleInfo[cycle].cyclevXENBurnedBatches / totalBatchesBurned;
            }
        }
        if (userLastActivity.lastCycleForBurn == cycle && (user.accCycleYSLBurnedBatches != 0 || user.accCyclevXENBurnedBatches != 0)) {
            pendingRewardsFromBurn = rewardsFromYSLBurn + rewardsFromvXENBurn;
        }
        if (userLastActivity.lastCycleForSwap == cycle && user.accCycleSwaps != 0) {
            pendingRewardsFromSwap += rewardsFromSwap;
        }
        if (userLastActivity.lastCycleForNativeParticipation == cycle && user.accCycleNativeBatches != 0) {
            pendingRewardsFromNative += rewardsFromNative;
        }
        return (pendingRewardsFromBurn, pendingRewardsFromSwap, pendingRewardsFromNative);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Determines the burn or native fee for a given number of batches, adjusting for the time within the current cycle.
     * @dev The burn and native fee is dynamic and changes based on the number of hours passed in the current cycle.
     * @param batchNumber The number of batches for which the burn or native fee is being calculated.
     * @return burnFee The calculated burn or native fee in wei for the given number of batches.
     */
    function coefficientWrapper(uint256 batchNumber)
        public
        view
        override
        returns (uint256 burnFee)
    {
        uint256 cycle = getCurrentCycle();
        uint256 startOfCurrentCycle = i_initialTimestamp + cycle * i_periodDuration + 1;
        uint256 hoursPassed = (block.timestamp - startOfCurrentCycle) / 1 hours;
        uint256 burnCoefficient;
        if (hoursPassed == 0) {
            burnCoefficient = 50 * BP;
        }
        else {
            burnCoefficient = 50 * BP + (50 * BP * hoursPassed) / 23;
        }
        uint256 ETHValueOfBatches = batchFee * batchNumber;
        uint256 constantValue;
        if (hoursPassed > 19) {
            constantValue = 0;
        }
        else {
           constantValue = 5 * 1e13 - (hoursPassed * 5 * 1e12) / 2;
        }
        burnFee = burnCoefficient * ETHValueOfBatches
                                        * (1e18 - constantValue * batchNumber) / (100 * BP * BP);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the current cycle number based on the time elapsed since the contract's initialization.
     * @dev The cycle number is determined by dividing the elapsed time by the period duration.
     * @return The current cycle number, representing how many complete cycles have elapsed.
     */
    function getCurrentCycle()
        public
        view
        override
        returns (uint256)
    {
        return (block.timestamp - i_initialTimestamp) / i_periodDuration;
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Calculates the reward amount for a given cycle, adjusting for halving events.
     * @dev The reward amount decreases over time based on predefined halving cycles.
     * @param cycle The cycle number for which the reward is being calculated.
     * @return The reward amount for the specified cycle.
     */
    function calculateRewardPerCycle(uint256 cycle)
        public
        view
        override
        returns (uint256)
    {
        for (uint256 i; i < 7; i++) {
            if (cycle >= cyclesForHalving[i] && cycle < cyclesForHalving[i+1]) {
                return rewardsPerHalving[i];
            }
        }
        if (cycle >= cyclesForHalving[7]) {
            return 0;
        }
        if (cycle < cyclesForHalving[0]) {
            return 20000 ether;
        }
    }

    /// -------------------------------- INTERNAL FUNCTIONS --------------------------------- \\\

    /**
     * @notice Initialises liquidity for the XNF token by calculating the required XNF amount based on native token price.
     * @dev The function ensures that the liquidity is only added once.
     */
    function _addInitialLiquidity() internal {
        if (_isTriggered) {
            return;
        }
        uint256 nativeAmount = cycleInfo[0].cycleAccNative
                                + cycleInfo[0].cycleAccExactNativeFromSwaps
                                + cycleInfo[0].cycleAccNativeFromAuction
                                + cycleInfo[0].cycleAccNativeFromNativeParticipants;
        uint256 xnfRequired = 1e5 ether;
        xnf.mint(address(this), xnfRequired);
        uint256 amount0;
        uint256 amount1;
        address token0;
        address token1;
        address weth = nonfungiblePositionManager.WETH9();
        if (weth < address(xnf)) {
            token0 = weth;
            token1 = address(xnf);
            amount0 = nativeAmount;
            amount1 = xnfRequired;
        } else {
            token0 = address(xnf);
            token1 = weth;
            amount0 = xnfRequired;
            amount1 = nativeAmount;
        }
        uint160 sqrtPrice = Math.sqrt(uint160(amount1)) * 2**96 / Math.sqrt(uint160(amount0));
        TransferHelper.safeApprove(address(xnf), address(nonfungiblePositionManager), xnfRequired);
        address pool = nonfungiblePositionManager.createAndInitializePoolIfNecessary(token0, token1, POOL_FEE, sqrtPrice);
        INonfungiblePositionManager.MintParams memory params =
            INonfungiblePositionManager.MintParams({
                token0: token0,
                token1: token1,
                fee: POOL_FEE,
                tickLower: TickMath.MIN_TICK / IUniswapV3Pool(pool).tickSpacing() * IUniswapV3Pool(pool).tickSpacing(),
                tickUpper: TickMath.MAX_TICK / IUniswapV3Pool(pool).tickSpacing() * IUniswapV3Pool(pool).tickSpacing(),
                amount0Desired: amount0,
                amount1Desired: amount1,
                amount0Min: 0,
                amount1Min: 0,
                recipient: Recycle,
                deadline: block.timestamp + 100
            });
        (uint256 tokenId, , , ) = nonfungiblePositionManager.mint{value: nativeAmount} (params);
        IRecycle(Recycle).setTokenId(tokenId);
        IXNF(address(xnf)).setLPAddress(pool);
        _isTriggered = true;
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Updates the statistics for a specific user.
     * @dev This function recalculates the current cycle and updates the user's statistics accordingly.
     * @param _user Address of the user whose statistics are being updated.
     */
    function _updateStatsForUser(address _user) internal {
        calculateCycle();
        updateStats(_user);
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Claims the accumulated native rewards for a specific user.
     * @dev This function also updates the cycle's accumulated bonus based on the user's pending native rewards.
     * @param _user Address of the user for whom the native rewards are being claimed.
     */
    function _claimNative(address _user) internal {
        cycleInfo[currentCycle].cycleAccBonus += userInfo[_user].pendingNative * 25 / 100;
        if (lastClaimFeesCycle != currentCycle) {
            if (cycleInfo[lastClaimFeesCycle].cycleAccBonus != 0 && totalPowerOfRecyclersFirstHour[lastClaimFeesCycle] == 0) {
                cycleInfo[currentCycle].cycleAccBonus += cycleInfo[lastClaimFeesCycle].cycleAccBonus;
                cycleInfo[lastClaimFeesCycle].cycleAccBonus = 0;
            }
            lastClaimFeesCycle = currentCycle;
        }
        uint256 nativeAmount = userInfo[_user].pendingNative * 75 / 100;
        userInfo[_user].pendingNative = 0;
        _sendViaCall(
            payable(_user),
            nativeAmount
        );
        emit NativeClaimed(
            _user,
            currentCycle,
            userInfo[_user].pendingNative * 25 / 100,
            nativeAmount
        );
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Claims the accumulated XNF rewards for a specific user.
     * @dev This function mints and transfers the XNF tokens to the user.
     * @param _user Address of the user for whom the XNF rewards are being claimed.
     */
    function _claimXNF(address _user) internal {
        uint256 pendingRewardsFromBurn = userInfo[_user].pendingRewardsFromBurn;
        userInfo[_user].pendingRewardsFromBurn = 0;
        if (pendingRewardsFromBurn != 0) {
            xnf.mint(_user, pendingRewardsFromBurn);
        }
        if (!_isTriggered && lastActiveCycle != currentCycle && lastActiveCycle == 0) {
            _addInitialLiquidity();
        }
        emit XNFClaimed(
            _user,
            currentCycle,
            pendingRewardsFromBurn
        );
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Claims the accumulated veXNF rewards for a specific user.
     * @dev This function mints and transfers the veXNF tokens to the user.
     * @param _user Address of the user for whom the veXNF rewards are being claimed.
     */
    function _claimveXNF(address _user) internal {
        uint256 pendingRewardsFromSwap = userInfo[_user].pendingRewardsFromSwap;
        uint256 pendingRewardsFromNative = userInfo[_user].pendingRewardsFromNative;
        userInfo[_user].pendingRewardsFromSwap = 0;
        userInfo[_user].pendingRewardsFromNative = 0;
        if (pendingRewardsFromSwap != 0) {
            xnf.mint(address(this), pendingRewardsFromSwap);
        }
        if (pendingRewardsFromNative != 0) {
            xnf.mint(address(this), pendingRewardsFromNative);
        }
        uint256 pendingveXNF = pendingRewardsFromSwap + pendingRewardsFromNative;
        if (pendingveXNF != 0) {
            xnf.approve(veXNF, pendingveXNF);
            IVeXNF(veXNF).createLockFor(pendingveXNF, 365, _user);
            emit veXNFClaimed(_user, currentCycle, pendingveXNF);
        }
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows users to recycle their native rewards and subsequently claim their rewards.
     * @dev Users can recycle their native rewards and receive rewards based on their participation in the cycle.
     * @param _user Address of the user performing the recycling action.
     */
    function _recycle(address _user) internal {
        uint256 nativeAmount = userInfo[_user].pendingNative;
        userInfo[_user].pendingNative = 0;
        if (nativeAmount == 0) {
           revert NoNativeRewardsForRecycling();
        }
        uint256 batchNumber = nativeAmount / batchFee;
        if (batchNumber > 1e4) {
            batchNumber = 1e4;
        }
        uint256 burnFee = coefficientWrapper(batchNumber);
        IRecycle(Recycle).recycle{value: nativeAmount - burnFee} ();
        _burn(_user, batchNumber, burnFee);
        uint256 startOfCurrentCycle = i_initialTimestamp + currentCycle * i_periodDuration + 1;
        uint256 hoursPassed = (block.timestamp - startOfCurrentCycle) / 1 hours;
        if (hoursPassed == 0) {
            recyclerPowerFirstHour[_user][currentCycle] = IVeXNF(veXNF).totalBalanceOfNFTAt(_user, block.timestamp);
            totalPowerOfRecyclersFirstHour[currentCycle] += IVeXNF(veXNF).totalBalanceOfNFTAt(_user, block.timestamp);
        }
        userLastActivityInfo[_user].lastCycleForRecycle = currentCycle;
        emit RecycleAction(
            _user,
            currentCycle,
            burnFee,
            batchNumber,
            nativeAmount,
            recyclerPowerFirstHour[_user][currentCycle],
            totalPowerOfRecyclersFirstHour[currentCycle]
        );
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Initialises or updates cycle data based on the provided parameters.
     * @dev This function sets up the cycle data for a new cycle or updates an existing cycle's data.
     * @param _YSLBatchAmount Number of YSL batches being burned.
     * @param _vXENBatchAmount Number of vXEN batches being burned.
     * @param _nativeBatchAmount Number of native batches.
     * @param _exactSwapFee Exact fee from swapping.
     * @param _burnFee Fee amount for burning.
     */
    function _setupNewCycle(
        uint256 _YSLBatchAmount,
        uint256 _vXENBatchAmount,
        uint256 _nativeBatchAmount,
        uint256 _exactSwapFee,
        uint256 _burnFee
    ) internal {
        Cycle storage cycle = cycleInfo[currentCycle];
        uint256 swapFee;
        uint256 feeFromNative;
        if (_exactSwapFee != 0) {
            swapFee = _burnFee;
            _burnFee = 0;
        }
        if (_nativeBatchAmount != 0) {
            feeFromNative = _burnFee;
            _burnFee = 0;
        }
        uint256 amountToAddLiquidity;
        if (_burnFee != 0) {
            amountToAddLiquidity = _burnFee * 75 / 100;
        } else if (swapFee != 0) {
            amountToAddLiquidity = _exactSwapFee * 75 / 100;
        } else {
            amountToAddLiquidity = feeFromNative * 75 / 100;
        }
        if (lastActiveCycle != 0 && lastActiveCycle != currentCycle) {
            uint256 cycleEndTs = i_initialTimestamp + i_periodDuration * (lastActiveCycle + 1) - 1;
            if (IVeXNF(veXNF).totalSupplyAtT(cycleEndTs) == 0) {
                if (cycleInfo[lastActiveCycle].cycleAccNative != 0
                        || cycleInfo[lastActiveCycle].cycleAccExactNativeFromSwaps != 0
                        || cycleInfo[lastActiveCycle].cycleAccNativeFromAuction != 0
                        || cycleInfo[lastActiveCycle].cycleAccNativeFromNativeParticipants != 0)
                {
                uint256 nativeAmount = cycleInfo[lastActiveCycle].cycleAccNative +
                        cycleInfo[lastActiveCycle].cycleAccExactNativeFromSwaps +
                        cycleInfo[lastActiveCycle].cycleAccNativeFromAuction +
                        cycleInfo[lastActiveCycle].cycleAccNativeFromNativeParticipants;
                        IRecycle(Recycle).executeBuybackBurn{value: nativeAmount} ();
                }
            }
        }
        if (currentCycle == 0 && cycle.accRewards == 0) {
            cycle.cycleYSLBurnedBatches = _YSLBatchAmount;
            cycle.cyclevXENBurnedBatches = _vXENBatchAmount;
            cycle.cycleNativeBatches = _nativeBatchAmount;
            cycle.cycleAccNative = _burnFee;
            cycle.cycleAccNativeFromSwaps = swapFee;
            cycle.cycleAccNativeFromNativeParticipants = feeFromNative;
            cycle.cycleAccExactNativeFromSwaps = _exactSwapFee;
            cycle.accRewards = calculateRewardPerCycle(currentCycle);
        }
        else if (lastActiveCycle != currentCycle) {
            cycleInfo[currentCycle] = Cycle(
                lastActiveCycle,
                _YSLBatchAmount,
                _vXENBatchAmount,
                _nativeBatchAmount,
                _burnFee * 25 / 100,
                swapFee,
                feeFromNative * 25 / 100,
                cycleInfo[currentCycle].cycleAccNativeFromAuction,
                _exactSwapFee * 25 / 100,
                0,
                calculateRewardPerCycle(currentCycle)
            );
            if (lastActiveCycle == 0) {
                _addInitialLiquidity();
            }
            IRecycle(Recycle).executeBuybackBurn{value: amountToAddLiquidity} ();
            lastActiveCycle = currentCycle;
        }
        else {
            cycle.cycleYSLBurnedBatches += _YSLBatchAmount;
            cycle.cyclevXENBurnedBatches += _vXENBatchAmount;
            cycle.cycleNativeBatches += _nativeBatchAmount;
            if (currentCycle == 0) {
                cycle.cycleAccNative += _burnFee;
                cycle.cycleAccNativeFromSwaps += swapFee;
                cycle.cycleAccExactNativeFromSwaps += _exactSwapFee;
                cycle.cycleAccNativeFromNativeParticipants += feeFromNative;
            } else {
                cycle.cycleAccNative += _burnFee * 25 / 100;
                cycle.cycleAccNativeFromSwaps += swapFee;
                cycle.cycleAccExactNativeFromSwaps += _exactSwapFee * 25 / 100;
                cycle.cycleAccNativeFromNativeParticipants += feeFromNative * 25 / 100;
                IRecycle(Recycle).executeBuybackBurn{value: amountToAddLiquidity} ();
            }
        }
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns tokens for a user based on the number of batches and the native amount provided.
     * @dev Calculates the number of YSL and vXEN batches to burn, updates user statistics, and handles rewards.
     * @param _user Address of the user whose tokens are being burned.
     * @param _batchNumber Total number of batches being burned.
     * @param _nativeAmount Amount of native currency associated with the burn.
     */
    function _burn(
        address _user,
        uint256 _batchNumber,
        uint256 _nativeAmount
    ) internal {
        User storage user = userInfo[_user];
        UserLastActivity storage userLastActivity = userLastActivityInfo[_user];
        uint256 burnFee = coefficientWrapper(_batchNumber);
        uint256 YSLBurnedBatches;
        uint256 vXENBurnedBatches;
        if (cycleInfo[currentCycle].cycleYSLBurnedBatches == cycleInfo[currentCycle].cyclevXENBurnedBatches) {
            if (_batchNumber % 2 != 0) {
                vXENBurnedBatches = _batchNumber / 2 + 1;
                YSLBurnedBatches = _batchNumber / 2;
            } else {
                YSLBurnedBatches = _batchNumber / 2;
                vXENBurnedBatches = _batchNumber / 2;
            }
        } else if (cycleInfo[currentCycle].cycleYSLBurnedBatches > cycleInfo[currentCycle].cyclevXENBurnedBatches) {
            uint256 diff = cycleInfo[currentCycle].cycleYSLBurnedBatches - cycleInfo[currentCycle].cyclevXENBurnedBatches;
            if (diff >= _batchNumber) {
                vXENBurnedBatches = _batchNumber;
            } else {
                uint256 remainder = _batchNumber - diff;
                if (remainder % 2 != 0) {
                    YSLBurnedBatches = remainder / 2 + 1;
                    vXENBurnedBatches = remainder / 2 + diff;
                } else {
                    YSLBurnedBatches = remainder / 2;
                    vXENBurnedBatches = remainder / 2 + diff;
                }
            }
        } else {
            uint256 diff = cycleInfo[currentCycle].cyclevXENBurnedBatches - cycleInfo[currentCycle].cycleYSLBurnedBatches;
            if (diff >= _batchNumber) {
                YSLBurnedBatches = _batchNumber;
            } else {
                uint256 remainder = _batchNumber - diff;
                if (remainder % 2 != 0) {
                    YSLBurnedBatches = remainder / 2 + diff;
                    vXENBurnedBatches = remainder / 2 + 1;
                } else {
                    YSLBurnedBatches = remainder / 2 + diff;
                    vXENBurnedBatches = remainder / 2;
                }
            }
        }
        _setupNewCycle(YSLBurnedBatches, vXENBurnedBatches, 0, 0, burnFee);
        if (currentCycle == 0) {
            user.accCycleYSLBurnedBatches += YSLBurnedBatches;
            user.accCyclevXENBurnedBatches += vXENBurnedBatches;
        }
        else {
            updateStats(_user);
            if (userLastActivity.lastCycleForBurn != currentCycle) {
                user.accCycleYSLBurnedBatches = YSLBurnedBatches;
                user.accCyclevXENBurnedBatches = vXENBurnedBatches;
            } else {
                user.accCycleYSLBurnedBatches += YSLBurnedBatches;
                user.accCyclevXENBurnedBatches += vXENBurnedBatches;
            }
            userLastActivity.lastCycleForBurn = currentCycle;
        }
        if (_nativeAmount < burnFee) {
            revert InsufficientNativeValue(_nativeAmount, burnFee);
        }
        _sendViaCall(
            payable(_user),
            _nativeAmount - burnFee
        );
    }

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Sends the specified amount of native currency to the provided address.
     * @dev Uses a low-level call to send native currency. Reverts if the send operation fails.
     * @param to Address to send the native currency to.
     * @param amount Amount of native currency to send.
     */
    function _sendViaCall(
        address payable to,
        uint256 amount
    ) internal {
        (bool sent, ) = to.call{value: amount} ("");
        if (!sent) {
            revert TransferFailed();
        }
    }

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

/*
 * @title IAuction Interface
 *
 * @notice This interface defines the essential functions for an auction contract,
 * facilitating token burning, reward distribution, and cycle management. It provides
 * a standardized way to interact with different auction implementations.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
interface IAuction {

    /// --------------------------------- EXTERNAL FUNCTIONS -------------------------------- \\\

    /**
     * @notice Enables users to recycle their native rewards and claim other rewards.
     */
    function recycle() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows the caller to claim all their pending rewards.
     */
    function claimAll() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows the caller to claim their pending XNF rewards.
     */
    function claimXNF() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows the caller to claim XNF rewards and locks them in the veXNF contract for a year.
     */
    function claimVeXNF() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows the caller to claim their native rewards.
     */
    function claimNative() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Updates the statistics related to the provided user address.
     */
    function updateStats(address) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Allows the caller to recycle native rewards and claim all other rewards.
     */
    function claimAllAndRecycle() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Claims all pending rewards for a specific user.
     * @dev This function aggregates all rewards and claims them in a single transaction.
     * It should be invoked by the veXNF contract before any burn action.
     */
    function claimAllForUser(address) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Claims the accumulated veXNF rewards for a specific user.
     * @dev This function mints and transfers the veXNF tokens to the user.
     * It should be invoked by the veXNF contract.
     */
    function claimVeXNFForUser(address) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns specified batches of vXEN or YSL tokens to earn rewards.
     */
    function burn(bool, uint256) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the current cycle number of the auction.
     * @dev A cycle represents a specific duration or round in the auction process.
     * @return The current cycle number.
     */
    function currentCycle() external returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Updates and retrieves the current cycle number of the auction.
     * @dev A cycle represents a specific duration or round in the auction process.
     * @return The current cycle number.
     */
    function calculateCycle() external returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the number of the last active cycle.
     * @dev Useful for determining the most recent cycle with recorded activity.
     * @return The number of the last active cycle.
     */
    function lastActiveCycle() external returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Registers the caller as a burner by paying in native tokens.
     */
    function participateWithNative(uint256) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the current cycle number based on the time elapsed since the contract's initialization.
     * @return The current cycle number.
     */
    function getCurrentCycle() external view returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Calculates the pending native token rewards for a user based on their NFT ownership and recycling activities.
     * @return The amount of pending native token rewards.
     */
    function pendingNative(address) external view returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Determines the burn and native fee for a given number of batches, adjusting for the time within the current cycle.
     * @return The calculated burn and native fee.
     */
    function coefficientWrapper(uint256) external view returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Calculates the reward amount for a given cycle, adjusting for halving events.
     * @return The calculated reward amount.
     */
    function calculateRewardPerCycle(uint256) external view returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Calculates the pending native token rewards for a user for the current cycle based on their NFT ownership and recycling activities.
     * @return The amount of pending native token rewards.
     */
    function pendingNativeForCurrentCycle(address) external view returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Computes the pending XNF rewards for a user across various activities.
     * @return pendingXNFRewards An array containing the pending XNF rewards amounts for different activities.
     */
    function pendingXNF(address _user) external view returns (uint256, uint256, uint256);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Registers the caller as a swap user and earns rewards.
     */
    function registerSwapUser(bytes calldata, address, uint256, address) external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Computes the pending XNF rewards for a user for the current cycle across various activities.
     * @return pendingXNFRewards An array containing the pending XNF rewards amounts for different activities.
     */
    function pendingXNFForCurrentCycle(address _user) external view returns (uint256, uint256, uint256);

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

/*
 * @title IBurnableToken Interface
 *
 * @notice This interface defines a basic burn function for ERC20-like tokens.
 * Implementing contracts should fire a Transfer event with the burn address (0x0)
 * as the recipient when a burn occurs, in accordance with the ERC20 standard.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
interface IBurnableToken {

    /// --------------------------------- EXTERNAL FUNCTION --------------------------------- \\\

    /**
     * @notice Destroys `amount` tokens from `user`, reducing the total supply.
     * @dev This operation is irreversible. Implementations should emit an ERC20 Transfer event
     * with to set to the zero address. Implementations should also enforce necessary conditions
     * such as allowance and balance checks.
     * @param user The account to burn tokens from.
     * @param amount The amount of tokens to be burned.
     */
    function burn(
        address user,
        uint256 amount
    ) external;

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/*
 * @title IERC20Mintable
 *
 * @notice This interface defines the functions for minting ERC20 tokens.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
interface IERC20Mintable is IERC20 {

    /// --------------------------------- EXTERNAL FUNCTION --------------------------------- \\\

    /**
     * @notice Mints a specific amount of tokens to the given account.
     * @param account The address of the recipient who will receive the minted tokens.
     * @param amount The number of tokens to mint.
     */
    function mint(
        address account,
        uint256 amount
    ) external;

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

/*
 * @title IFeeSplitter Interface
 *
 * @notice This interface defines the methods for distributing fees in the FeeSplitter contract.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
interface IFeeSplitter {

    /// --------------------------------- EXTERNAL FUNCTION --------------------------------- \\\

    /**
     * @notice Distributes fees to a specified partner.
     */
    function distributeFees(address) external payable;

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

/*
 * @title IRecycle Interface
 *
 * @notice Interface for recycling and distributing assets within a contract.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
interface IRecycle {

    /// -------------------------------------- ERRORS --------------------------------------- \\\

    /**
     * @notice Error thrown when the transfer of native tokens failed.
     */
    error TransferFailed();

    /**
     * @notice Error thrown when an invalid address is provided.
     */
    error InvalidAddress();

    /**
     * @notice Error thrown when the provided native token amount is zero.
     */
    error ZeroNativeAmount();

    /**
     * @notice Error thrown when the caller is not authorized.
     */
    error UnauthorizedCaller();

    /**
     * @notice Error thrown when fees has been collected for current cycle.
     */
    error FeeCollected(uint256 lastClaimCycle);

    /**
     * @notice Error thrown when the contract is already initialised.
     */
    error ContractInitialised(address contractAddress);

    /// -------------------------------------- EVENTS --------------------------------------- \\\

    /**
     * @notice Emitted when native tokens are converted (recycled) into other tokens.
     * @param user Address of the user who initiated the recycle action.
     * @param nativeAmount Amount of native tokens recycled.
     */
    event RecycleAction(
        address indexed user,
        uint256 nativeAmount
    );

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Emitted when the protocol performs a buyback and then burns the purchased tokens.
     * @dev This event is used to log the successful execution of the buyback and burn operation.
     * It should be emitted after the protocol has used native tokens to buy back its own tokens
     * from the open market and subsequently burned them, effectively reducing the total supply.
     * The amount represents the native tokens spent in the buyback process before the burn.
     * @param creator Address of the entity or contract that initiated the buyback and burn.
     * @param amount The amount of native tokens used for the buyback operation.
     */
    event BuybackBurnAction(
        address indexed creator,
        uint256 amount
    );

    /// --------------------------------- EXTERNAL FUNCTIONS -------------------------------- \\\

    /**
     * @notice Collects fees for protocol owned liquidity.
     * @dev Implementing contracts should specify the mechanism for collecting fees.
     */
    function collectFees() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Recycles assets held within the contract.
     * @dev Implementing contracts should detail the recycling mechanism.
     * If the function is intended to handle Ether, it should be marked as payable.
     */
    function recycle() external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Sets the token ID for internal reference.
     * @dev Implementing contracts should specify how this ID is used within the protocol.
     */
    function setTokenId(uint256) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Executes a buyback, burning XNF tokens and distributing native tokens to the team.
     * @dev Swaps 50% of the sent value for XNF, burns it, and sends 10% to the team. The function
     * is non-reentrant and must have enough native balance to execute the swap and burn.
     */
    function executeBuybackBurn() external payable;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Executes a swap from XNF to native tokens (e.g., ETH), with a guaranteed minimum output.
     * @dev Swaps XNF for native tokens using swapRouter, transferring the output directly to the caller. A deadline for
     * the swap can be specified which is the timestamp after which the transaction is considered invalid. Before execution,
     * ensure swapRouter is secure and 'amountOutMinimum' accounts for slippage. The 'deadline' should be carefully set to allow
     * sufficient time for the transaction to be mined while protecting against market volatility.
     * @param amountIn The amount of XNF tokens to swap.
     * @param amountOut The minimum acceptable amount of native tokens in return.
     * @param deadline The timestamp by which the swap must be completed.
     */
    function swapXNF(uint256 amountIn, uint256 amountOut, uint256 deadline) external;

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

/*
 * @title IVeXNF Interface
 *
 * @notice Interface for querying "time-weighted" supply and balance of NFTs.
 * Provides methods to determine the total supply and user balance at specific points in time.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
interface IVeXNF {

    /// --------------------------------- EXTERNAL FUNCTIONS -------------------------------- \\\

    /**
     * @notice Merges all NFTs that user has into a single new NFT with 1 year lock period.
     */
    function mergeAll() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Records a global checkpoint for data tracking.
     */
    function checkpoint() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Withdraws all tokens from all expired NFT locks.
     */
    function withdrawAll() external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Withdraws all tokens from an expired NFT lock.
     */
    function withdraw(uint) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Merges multiple NFTs into a single new NFT.
     */
    function merge(uint[] memory) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Deposits tokens into a specific NFT lock.
     */
    function depositFor(uint, uint) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Splits a single NFT into multiple new NFTs with specified amounts.
     */
    function split(uint[] calldata, uint) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Extends the unlock time of a specific NFT lock.
     */
    function increaseUnlockTime(uint, uint) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the current total supply of tokens.
     * @return The current total token supply.
     */
    function totalSupply() external view returns (uint);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the end timestamp of a lock for a specific NFT.
     * @return The timestamp when the NFT's lock expires.
     */
    function lockedEnd(uint) external view returns (uint);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Creates a lock for a user for a specified amount and duration.
     * @return tokenId The identifier of the newly created NFT.
     */
    function createLock(uint, uint) external returns (uint);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Calculates the total voting power at a specific timestamp.
     * @return The total voting power at the specified timestamp.
     */
    function totalSupplyAtT(uint) external view returns (uint);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the balance of a specific NFT at a given timestamp.
     * @return The balance of the NFT at the given timestamp.
     */
    function balanceOfNFTAt(uint, uint) external view returns (uint);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the total token supply at a specific timestamp.
     * @return The total token supply at the given timestamp.
     */
    function getPastTotalSupply(uint256) external view returns (uint);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the most recent voting power decrease rate for a specific NFT.
     * @return The slope value representing the rate of voting power decrease.
     */
    function get_last_user_slope(uint) external view returns (int128);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Creates a new NFT lock for a specified address, locking a specific amount of tokens.
     * @return tokenId The identifier of the newly created NFT.
     */
    function createLockFor(uint, uint, address) external returns (uint);

    /// ------------------------------------------------------------------------------------- \\\

     /**
     * @notice Retrieves a list of NFT IDs owned by a specific address.
     * @return An array of NFT IDs owned by the specified address.
     */
    function userToIds(address) external view returns (uint256[] memory);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the timestamp of a specific checkpoint for an NFT.
     * @return The timestamp of the specified checkpoint.
     */
    function userPointHistory_ts(uint, uint) external view returns (uint);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Checks if an address is approved to manage a specific NFT or if it's the owner.
     * @return True if the address is approved or is the owner, false otherwise.
     */
    function isApprovedOrOwner(address, uint) external view returns (bool);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Retrieves the aggregate balance of NFTs owned by a specific user at a given epoch time.
     * @return totalBalance The total balance of the user's NFTs at the given timestamp.
     */
    function totalBalanceOfNFTAt(address, uint) external view returns (uint256);

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

/*
 * @title IWormholeReceiver Interface
 *
 * @notice Interface for a contract which can receive Wormhole messages.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
interface IWormholeReceiver {

    /// --------------------------------- EXTERNAL FUNCTION --------------------------------- \\\

    /**
     * @notice Called by the WormholeRelayer contract to deliver a Wormhole message to this contract.
     *
     * @dev This function should be implemented to include access controls to ensure that only
     *      the Wormhole Relayer contract can invoke it.
     *
     *      Implementations should:
     *      - Maintain a mapping of received `deliveryHash`s to prevent duplicate message delivery.
     *      - Verify the authenticity of `sourceChain` and `sourceAddress` to prevent unauthorized or malicious calls.
     *
     * @param payload The arbitrary data included in the message by the sender.
     * @param additionalVaas Additional VAAs that were requested to be included in this delivery.
     *                       Guaranteed to be in the same order as specified by the sender.
     * @param sourceAddress The Wormhole-formatted address of the message sender on the originating chain.
     * @param sourceChain The Wormhole Chain ID of the originating blockchain.
     * @param deliveryHash The VAA hash of the deliveryVAA, used to prevent duplicate delivery.
     *
     * Warning: The provided VAAs are NOT verified by the Wormhole core contract prior to this call.
     *          Always invoke `parseAndVerify()` on the Wormhole core contract to validate the VAAs before trusting them.
     */
    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory additionalVaas,
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 deliveryHash
    ) external payable;

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

import {ILayerZeroReceiver} from "@layerzerolabs/lz-evm-sdk-v1-0.7/contracts/interfaces/ILayerZeroReceiver.sol";
import {IWormholeReceiver} from "./IWormholeReceiver.sol";

/*
 * @title XNF interface
 *
 * @notice This is an interface outlining functiosn for XNF token with enhanced features such as token locking and specialized minting
 * and burning mechanisms. It's primarily used within a broader protocol to reward users who burn YSL or vXEN.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
interface IXNF
{
    /// -------------------------------------- ERRORS --------------------------------------- \\\

    /**
     * @notice This error is thrown when minting XNF to zero address.
     */
    error ZeroAddress();

    /**
     * @notice This error is thrown when trying to claim airdroped XNF before 2 hours passed.
     */
    error TooEarlyToClaim();

    /**
     * @notice Error thrown when minting would exceed the maximum allowed supply.
     */
    error ExceedsMaxSupply();

    /**
     * @notice This error is thrown when an invalid claim proof is provided.
     */
    error InvalidClaimProof();

    /**
     * @notice Error thrown when a function is called by an account other than the Auction contract.
     */
    error OnlyAuctionAllowed();

    /**
     * @notice This error is thrown when user tries to purchase XNF from protocol owned liquidity.
     */
    error CantPurchaseFromPOL();

    /**
     * @notice This error is thrown when user tries to sell XNF directly.
     */
    error CanSellOnlyViaRecycle();

    /**
     * @notice Error thrown when the calling contract does not support the required interface.
     */
    error UnsupportedInterface();

    /**
     * @notice This error is thrown when an airdrop has already been claimed.
     */
    error AirdropAlreadyClaimed();

    /**
     * @notice Error thrown when a user tries to transfer more unlocked tokens than they have.
     */
    error InsufficientUnlockedTokens();

    /**
     * @notice Error thrown when the contract is already initialised.
     */
    error ContractInitialised(address auction);

    /// ------------------------------------- STRUCTURES ------------------------------------ \\\

    /**
     * @notice Represents token lock details for a user.
     * @param amount Total tokens locked.
     * @param timestamp When the tokens were locked.
     * @param dailyUnlockAmount Tokens unlocked daily.
     * @param usedAmount Tokens transferred from the locked amount.
     */
    struct Lock {
        uint256 amount;
        uint256 timestamp;
        uint128 dailyUnlockAmount;
        uint128 usedAmount;
    }

    /// -------------------------------------- EVENTS --------------------------------------- \\\

    /**
     * @notice Emitted when a user successfully claims their airdrop.
     * @param user Address of the user claiming the airdrop.
     * @param amount Amount of Airdrop claimed.
     */
    event Airdropped(
        address indexed user,
        uint256 amount
    );

    /// --------------------------------- EXTERNAL FUNCTIONS -------------------------------- \\\

    /**
     * @notice Allows users to claim their airdropped tokens using a Merkle proof.
     * @dev Verifies the Merkle proof against the stored Merkle root and mints the claimed amount to the user.
     * @param proof Array of bytes32 values representing the Merkle proof.
     * @param account Address of the user claiming the airdrop.
     * @param amount Amount of tokens being claimed.
     */
    function claim(
        bytes32[] calldata proof,
        address account,
        uint256 amount
    ) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Mints XNF tokens to a specified account.
     * @dev Only the Auction contract can mint tokens, and the total supply cap is checked before minting.
     * @param account Address receiving the minted tokens.
     * @param amount Number of tokens to mint.
     */
    function mint(
        address account,
        uint256 amount
    ) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Sets the liquidity pool (LP) address.
     * @dev Only the Auction contract is allowed to call this function.
     * @param _lp The address of the liquidity pool to be set.
     */
    function setLPAddress(address _lp) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Burns a specified amount of tokens from a user's account.
     * @dev The calling contract must support the IBurnRedeemable interface.
     * @param user Address from which tokens will be burned.
     * @param amount Number of tokens to burn.
     */
    function burn(
        address user,
        uint256 amount
    ) external;

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Determines the number of days since a user's tokens were locked.
     * @dev If the elapsed days exceed the lock period, it returns the lock period.
     * @param _user Address of the user to check.
     * @return passedDays Number of days since the user's tokens were locked, capped at the lock period.
     */
    function daysPassed(address _user) external view returns (uint256 passedDays);

    /// ------------------------------------------------------------------------------------- \\\

    /**
     * @notice Computes the amount of unlocked tokens for a user based on the elapsed time since locking.
     * @dev If the user's tokens have been locked for the full lock period, all tokens are considered unlocked.
     * @param _user Address of the user to check.
     * @return unlockedTokens Number of tokens that are currently unlocked for the user.
     */
    function getUnlockedTokensAmount(address _user) external view returns (uint256 unlockedTokens);

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

/*
 * @title Math Library
 * @notice This library provides a method to compute the square root of a given number.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
library Math {

    /// -------------------------------- INTERNAL FUNCTIONS --------------------------------- \\\

    /**
     * @notice Calculates the square root of the given number.
     * @param y The number for which to calculate the square root.
     * @return z The square root of the given number.
     */
    function sqrt(uint160 y)
        internal
        pure
        returns (uint160 z)
    {
        if (y > 3) {
            z = y;
            uint160 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.18;

/*
 * @title SignatureHelper Library
 *
 * @notice A library to assist with signature operations.
 *
 * Co-Founders:
 * - Simran Dhillon: [email protected]
 * - Hardev Dhillon: [email protected]
 * - Dayana Plaz: [email protected]
 *
 * Official Links:
 * - Twitter: https://twitter.com/xenify_io
 * - Telegram: https://t.me/xenify_io
 * - Website: https://xenify.io
 *
 * Disclaimer:
 * This contract aligns with the principles of the Fair Crypto Foundation, promoting self-custody, transparency, consensus-based
 * trust, and permissionless value exchange. There are no administrative access keys, underscoring our commitment to decentralization.
 * Engaging with this contract involves technical and legal risks. Users must conduct their own due diligence and ensure compliance
 * with local laws and regulations. The software is provided "AS-IS," without warranties, and the co-founders and developers disclaim
 * all liability for any vulnerabilities, exploits, errors, or breaches that may occur. By using this contract, users accept all associated
 * risks and this disclaimer. The co-founders, developers, or related parties will not bear liability for any consequences of non-compliance.
 *
 * Redistribution and Use:
 * Redistribution, modification, or repurposing of this contract, in whole or in part, is strictly prohibited without express written
 * approval from all co-founders. Approval requests must be sent to the official email addresses of the co-founders, ensuring responses
 * are received directly from these addresses. Proposals for redistribution, modification, or repurposing must include a detailed explanation
 * of the intended changes or uses and the reasons behind them. The co-founders reserve the right to request additional information or
 * clarification as necessary. Approval is at the sole discretion of the co-founders and may be subject to conditions to uphold the
 * project’s integrity and the values of the Fair Crypto Foundation. Failure to obtain express written approval prior to any redistribution,
 * modification, or repurposing will result in a breach of these terms and immediate legal action.
 *
 * Copyright and License:
 * Copyright © 2023 Xenify (Simran Dhillon, Hardev Dhillon, Dayana Plaz). All rights reserved.
 * This software is provided 'as is' and may be used by the recipient. No permission is granted for redistribution,
 * modification, or repurposing of this contract. Any use beyond the scope defined herein may be subject to legal action.
 */
library SignatureHelper {

    /// -------------------------------- INTERNAL FUNCTIONS --------------------------------- \\\

    /**
     * @notice Returns message hash used for signature.
     * @dev Hash contains user, amount, partner, partnerPercent, feeSplitter, nonce, and chainId.
     * This message hash can be used for verification purposes in different parts of the contract.
     * @param user Address of user involved in the transaction.
     * @param amount Transaction amount.
     * @param partner Address of the partner involved in the transaction.
     * @param partnerPercent Percentage of the transaction amount allocated to the partner.
     * @param feeSplitter Address of the fee splitter contract.
     * @param nonce Transaction nonce, used to prevent replay attacks.
     * @return Message hash.
     */
    function _getMessageHash(
        address user,
        uint256 amount,
        address partner,
        uint256 partnerPercent,
        address feeSplitter,
        uint256 nonce
    )
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(
            user,
            amount,
            partner,
            partnerPercent,
            feeSplitter,
            nonce,
            block.chainid
            )
        );
    }

    /// ------------------------------------------------------------------------------ \\\

    /**
     * @notice Returns message hash used for signature in the context of split fee transactions.
     * @dev Hash contains user, amount, token, nonce, and chainId.
     * This specific message hash structure is tailored for transactions involving fee splitting.
     * @param user Address of user involved in the transaction.
     * @param amount Transaction amount.
     * @param token Address of the token involved in the transaction.
     * @param nonce Transaction nonce, used to prevent replay attacks.
     * @return Message hash.
     */
    function _getMessageHashForSplitFee(
        address user,
        uint256 amount,
        address token,
        uint256 nonce
    )
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(
            user,
            amount,
            token,
            nonce,
            block.chainid
            )
        );
    }

    /// ------------------------------------------------------------------------------ \\\

    /**
     * @notice Returns Ethereum signed message hash.
     * @dev Prepends Ethereum signed message header.
     * @param _messageHash Message hash.
     * @return Ethereum signed message hash.
     */
    function _getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash)
            );
    }

    /// ------------------------------------------------------------------------------ \\\

    /**
     * @notice Splits signature into r, s, v.
     * @dev Allows recovering signer from signature.
     * @param signature Signature to split.
     * @return r Recovery parameter.
     * @return s Recovery parameter.
     * @return v Recovery parameter.
     */
    function _splitSignature(bytes memory signature)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(
            signature.length == 65,
            "SignatureHelper: Invalid signature length"
        );
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
    }

    /// ------------------------------------------------------------------------------------- \\\
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS =
        0x000000000000000000636F6e736F6c652e6c6f67;

    function _sendLogPayloadImplementation(bytes memory payload) internal view {
        address consoleAddress = CONSOLE_ADDRESS;
        /// @solidity memory-safe-assembly
        assembly {
            pop(
                staticcall(
                    gas(),
                    consoleAddress,
                    add(payload, 32),
                    mload(payload),
                    0,
                    0
                )
            )
        }
    }

    function _castToPure(
      function(bytes memory) internal view fnIn
    ) internal pure returns (function(bytes memory) pure fnOut) {
        assembly {
            fnOut := fnIn
        }
    }

    function _sendLogPayload(bytes memory payload) internal pure {
        _castToPure(_sendLogPayloadImplementation)(payload);
    }

    function log() internal pure {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }
    function logInt(int256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
    }

    function logUint(uint256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function logString(string memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint256 p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function log(string memory p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint256 p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
    }

    function log(uint256 p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
    }

    function log(uint256 p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
    }

    function log(uint256 p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
    }

    function log(string memory p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
    }

    function log(bool p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint256 p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
    }

    function log(address p0, string memory p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
    }

    function log(uint256 p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
    }

    function log(uint256 p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
    }

    function log(uint256 p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
    }

    function log(uint256 p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
    }

    function log(string memory p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
    }

    function log(string memory p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
    }

    function log(string memory p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
    }

    function log(string memory p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
    }

    function log(string memory p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
    }

    function log(string memory p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
    }

    function log(string memory p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
    }

    function log(bool p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
    }

    function log(bool p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
    }

    function log(bool p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
    }

    function log(bool p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
    }

    function log(bool p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
    }

    function log(bool p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
    }

    function log(bool p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
    }

    function log(bool p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
    }

    function log(bool p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
    }

    function log(bool p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
    }

    function log(address p0, uint256 p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
    }

    function log(address p0, string memory p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
    }

    function log(address p0, string memory p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
    }

    function log(address p0, string memory p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
    }

    function log(address p0, string memory p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
    }

    function log(address p0, bool p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
    }

    function log(address p0, bool p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
    }

    function log(address p0, bool p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
    }

    function log(address p0, bool p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
    }

    function log(address p0, address p1, uint256 p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
    }

    function log(address p0, address p1, string memory p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
    }

    function log(address p0, address p1, bool p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
    }

    function log(address p0, address p1, address p2) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
    }

    function log(uint256 p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
    }

    function log(string memory p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
    }

    function log(bool p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, uint256 p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, string memory p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, bool p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, uint256 p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, string memory p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, bool p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, uint256 p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, string memory p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, bool p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
    }

    function log(address p0, address p1, address p2, address p3) internal pure {
        _sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
    }

}