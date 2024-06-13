// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
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
// OpenZeppelin Contracts (last updated v4.9.4) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * ==== Security Considerations
 *
 * There are two important considerations concerning the use of `permit`. The first is that a valid permit signature
 * expresses an allowance, and it should not be assumed to convey additional meaning. In particular, it should not be
 * considered as an intention to spend the allowance in any specific way. The second is that because permits have
 * built-in replay protection and can be submitted by anyone, they can be frontrun. A protocol that uses permits should
 * take this into consideration and allow a `permit` call to fail. Combining these two aspects, a pattern that may be
 * generally recommended is:
 *
 * ```solidity
 * function doThingWithPermit(..., uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public {
 *     try token.permit(msg.sender, address(this), value, deadline, v, r, s) {} catch {}
 *     doThing(..., value);
 * }
 *
 * function doThing(..., uint256 value) public {
 *     token.safeTransferFrom(msg.sender, address(this), value);
 *     ...
 * }
 * ```
 *
 * Observe that: 1) `msg.sender` is used as the owner, leaving no ambiguity as to the signer intent, and 2) the use of
 * `try/catch` allows the permit to fail and makes the code tolerant to frontrunning. (See also
 * {SafeERC20-safeTransferFrom}).
 *
 * Additionally, note that smart contract wallets (such as Argent or Safe) are not able to produce permit signatures, so
 * contracts should have entry points that don't rely on permit.
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
     *
     * CAUTION: See Security Considerations above.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { UintUtils } from '../../utils/UintUtils.sol';
import { IAccessControlInternal } from './IAccessControlInternal.sol';
import { AccessControlStorage } from './AccessControlStorage.sol';

/**
 * @title Role-based access control system
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract AccessControlInternal is IAccessControlInternal {
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using UintUtils for uint256;

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /*
     * @notice query whether role is assigned to account
     * @param role role to query
     * @param account account to query
     * @return whether role is assigned to account
     */
    function _hasRole(
        bytes32 role,
        address account
    ) internal view virtual returns (bool) {
        return
            AccessControlStorage.layout().roles[role].members.contains(account);
    }

    /**
     * @notice revert if sender does not have given role
     * @param role role to query
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, msg.sender);
    }

    /**
     * @notice revert if given account does not have given role
     * @param role role to query
     * @param account to query
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        'AccessControl: account ',
                        account.toString(),
                        ' is missing role ',
                        uint256(role).toHexString(32)
                    )
                )
            );
        }
    }

    /*
     * @notice query admin role for given role
     * @param role role to query
     * @return admin role
     */
    function _getRoleAdmin(
        bytes32 role
    ) internal view virtual returns (bytes32) {
        return AccessControlStorage.layout().roles[role].adminRole;
    }

    /**
     * @notice set role as admin role
     * @param role role to set
     * @param adminRole admin role to set
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = _getRoleAdmin(role);
        AccessControlStorage.layout().roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /*
     * @notice assign role to given account
     * @param role role to assign
     * @param account recipient of role assignment
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.add(account);
        emit RoleGranted(role, account, msg.sender);
    }

    /*
     * @notice unassign role from given account
     * @param role role to unassign
     * @parm account
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.remove(account);
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @notice relinquish role
     * @param role role to relinquish
     */
    function _renounceRole(bytes32 role) internal virtual {
        _revokeRole(role, msg.sender);
    }

    /**
     * @notice query role for member at given index
     * @param role role to query
     * @param index index to query
     */
    function _getRoleMember(
        bytes32 role,
        uint256 index
    ) internal view virtual returns (address) {
        return AccessControlStorage.layout().roles[role].members.at(index);
    }

    /**
     * @notice query role for member count
     * @param role role to query
     */
    function _getRoleMemberCount(
        bytes32 role
    ) internal view virtual returns (uint256) {
        return AccessControlStorage.layout().roles[role].members.length();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';

library AccessControlStorage {
    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.AccessControl');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial AccessControl interface needed by internal functions
 */
interface IAccessControlInternal {
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(
        Bytes32Set storage set,
        uint256 index
    ) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function at(
        AddressSet storage set,
        uint256 index
    ) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(
        UintSet storage set,
        uint256 index
    ) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function contains(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function contains(
        AddressSet storage set,
        address value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(
        UintSet storage set,
        uint256 value
    ) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(
        Bytes32Set storage set,
        bytes32 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, value);
    }

    function indexOf(
        AddressSet storage set,
        address value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(
        UintSet storage set,
        uint256 value
    ) internal view returns (uint256) {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _add(set._inner, value);
    }

    function add(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(
        Bytes32Set storage set,
        bytes32 value
    ) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function remove(
        AddressSet storage set,
        address value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(
        UintSet storage set,
        uint256 value
    ) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(
        Bytes32Set storage set
    ) internal view returns (bytes32[] memory) {
        return set._inner._values;
    }

    function toArray(
        AddressSet storage set
    ) internal view returns (address[] memory) {
        bytes32[] storage values = set._inner._values;
        address[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function toArray(
        UintSet storage set
    ) internal view returns (uint256[] memory) {
        bytes32[] storage values = set._inner._values;
        uint256[] storage array;

        assembly {
            array.slot := values.slot
        }

        return array;
    }

    function _at(
        Set storage set,
        uint256 index
    ) private view returns (bytes32) {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(
        Set storage set,
        bytes32 value
    ) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _indexOf(
        Set storage set,
        bytes32 value
    ) private view returns (uint256) {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            status = true;
        }
    }

    function _remove(
        Set storage set,
        bytes32 value
    ) private returns (bool status) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            status = true;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    /**
     * @notice execute arbitrary external call with limited gas usage and amount of copied return data
     * @dev derived from https://github.com/nomad-xyz/ExcessivelySafeCall (MIT License)
     * @param target recipient of call
     * @param gasAmount gas allowance for call
     * @param value native token value to include in call
     * @param maxCopy maximum number of bytes to copy from return data
     * @param data encoded call data
     * @return success whether call is successful
     * @return returnData copied return data
     */
    function excessivelySafeCall(
        address target,
        uint256 gasAmount,
        uint256 value,
        uint16 maxCopy,
        bytes memory data
    ) internal returns (bool success, bytes memory returnData) {
        returnData = new bytes(maxCopy);

        assembly {
            // execute external call via assembly to avoid automatic copying of return data
            success := call(
                gasAmount,
                target,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )

            // determine whether to limit amount of data to copy
            let toCopy := returndatasize()

            if gt(toCopy, maxCopy) {
                toCopy := maxCopy
            }

            // store the length of the copied bytes
            mstore(returnData, toCopy)

            // copy the bytes from returndata[0:toCopy]
            returndatacopy(add(returnData, 0x20), 0, toCopy)
        }
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library LibAccessControl {
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
    bytes32 internal constant WHITELIST_ADMIN_ROLE = keccak256("WHITELIST_ADMIN_ROLE");
    bytes32 internal constant WHITELISTED_ROLE = keccak256("WHITELISTED_ROLE");
    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 internal constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library LibCommonConsts {
    uint256 internal constant BASIS_POINTS = 10_000;
    address internal constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /**
        INNER_STRUCT is used for storing inner struct in mappings within diamond storage
     */
    bytes32 internal constant INNER_STRUCT = keccak256("floki.common.consts.inner.struct");
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;
pragma abicoder v2;

import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is IERC721Enumerable {
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
    function positions(
        uint256 tokenId
    )
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
    function mint(MintParams calldata params) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

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
    function increaseLiquidity(IncreaseLiquidityParams calldata params) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

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
    function decreaseLiquidity(DecreaseLiquidityParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

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

    function factory() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface IPriceOracleManager {
    /**
     * Fetches the USD price for a token if required
     */
    function fetchPriceInUSD(address sourceToken) external;

    /**
     * Returns the price of the token in USD, normalized to the expected decimals param.
     */
    function getPriceInUSD(address token, uint256 expectedDecimals) external view returns (uint256 price);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ISwapRouterV3 {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    // solhint-disable-next-line func-name-mixedcase
    function WETH9() external pure returns (address);

    function factory() external pure returns (address);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address pool);

    function refundETH() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { KeeperCompatibleInterface } from "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
import { AccessControlInternal } from "@solidstate/contracts/access/access_control/AccessControlInternal.sol";

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IUniswapV2Pair } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import { LibAccessControl } from "../../common/admin/libraries/LibAccessControl.sol";
import { LibCommonConsts } from "../../common/admin/libraries/LibCommonConsts.sol";
import { LibLockerConsts } from "../libraries/LibLockerConsts.sol";
import { LibTokenSwapperStorage } from "../libraries/LibTokenSwapperStorage.sol";
import { ITokenSwapperFacet } from "../interfaces/ITokenSwapperFacet.sol";
import { INonfungiblePositionManager } from "../../common/interfaces/INonfungiblePositionManager.sol";
import { IPriceOracleManager } from "../../common/interfaces/IPriceOracleManager.sol";
import { ISwapRouterV3 } from "../../common/interfaces/ISwapRouterV3.sol";

contract TokenSwapperFacet is ITokenSwapperFacet, KeeperCompatibleInterface, AccessControlInternal {
    using SafeERC20 for IERC20Metadata;

    struct TokenForSwap {
        address tokenAddress;
        uint256 amount;
    }

    function setSellDelay(uint256 newDelay) external override onlyAdmin {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        uint256 oldDelay = ds.sellDelay;
        ds.sellDelay = newDelay;

        emit LibTokenSwapperStorage.SellDelayUpdated(oldDelay, newDelay);
    }

    function setSlippageBasisPoints(uint256 newSlippage) external override onlyAdmin {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        uint256 oldSlippage = ds.slippageBasisPoints;
        ds.slippageBasisPoints = newSlippage;
        emit LibTokenSwapperStorage.SlippageUpdated(oldSlippage, newSlippage);
    }

    function setSlippagePerToken(uint256 slippage, address token) external override onlyAdmin {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        uint256 oldSlippage = ds.perTokenSlippage[token];
        ds.perTokenSlippage[token] = slippage;
        emit LibTokenSwapperStorage.SlippagePerTokenUpdated(oldSlippage, slippage, token);
    }

    function setRequireOraclePrice(bool requires) external override onlyAdmin {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        ds.requireOraclePrice = requires;
    }

    function setRouterForFloki(address routerAddress, bool isV2Router) external override onlyAdmin {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        ds.routerForFloki = routerAddress;
        ds.v2Routers[routerAddress] = isV2Router;
    }

    function setWethToUsdV3PoolFee(uint24 newFee) external override onlyAdmin {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        ds.wethToUsdV3PoolFee = newFee;
    }

    function addTokenForSwapping(TokenSwapInfo memory params, uint256 addedTime) external override onlyTokenSwapperAdmin {
        // Update timestamp before checking whether token was already in the
        // set of locked LP tokens, because otherwise the timestamp would
        // not be updated on repeated calls (within the selling timeframe).

        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        ds.lastAdded[params.tokenAddress] = addedTime;
        ds.tokens[LibCommonConsts.INNER_STRUCT].push(
            TokenSwapInfo({
                tokenAddress: params.tokenAddress,
                routerFactory: params.routerFactory,
                isV2: params.isV2,
                referrer: params.referrer,
                vault: params.vault,
                amount: params.amount,
                v3PoolFee: params.v3PoolFee
            })
        );
        emit LibTokenSwapperStorage.TokenAdded(params.tokenAddress);
    }

    function clearTokensFromSwapping() external override onlyTokenSwapperAdmin {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        delete ds.tokens[LibCommonConsts.INNER_STRUCT];
    }

    function removeTokensFromSwappingByIndexes(uint256[] memory indexes) external override onlyTokenSwapperAdmin {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        for (uint256 i = 0; i < indexes.length; i++) {
            uint256 index = indexes[i];
            address tokenAddress = ds.tokens[LibCommonConsts.INNER_STRUCT][index].tokenAddress;
            ds.tokens[LibCommonConsts.INNER_STRUCT][index] = ds.tokens[LibCommonConsts.INNER_STRUCT][ds.tokens[LibCommonConsts.INNER_STRUCT].length - 1];
            ds.tokens[LibCommonConsts.INNER_STRUCT].pop();
            emit LibTokenSwapperStorage.TokenRemoved(tokenAddress);
        }
    }

    function removeTokenFromSwapping(address tokenAddress) external override onlyTokenSwapperAdmin {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        for (uint256 i = ds.tokens[LibCommonConsts.INNER_STRUCT].length; i > 0; i--) {
            if (ds.tokens[LibCommonConsts.INNER_STRUCT][i - 1].tokenAddress == tokenAddress) {
                ds.tokens[LibCommonConsts.INNER_STRUCT][i - 1] = ds.tokens[LibCommonConsts.INNER_STRUCT][ds.tokens[LibCommonConsts.INNER_STRUCT].length - 1];
                ds.tokens[LibCommonConsts.INNER_STRUCT].pop();
                break;
            }
        }
    }

    function getTokensForSwapping() external view override returns (TokenSwapInfo[] memory) {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        return ds.tokens[LibCommonConsts.INNER_STRUCT];
    }

    function isTokenReadyForSwapping(address tokenAddress) external view override returns (bool) {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        return (ds.lastAdded[tokenAddress] + ds.sellDelay) < block.timestamp;
    }

    function addRouter(address routerAddress, bool isV2) external override onlyTokenSwapperAdmin {
        require(routerAddress != address(0), "TokenSwapperFacet::addRouter::ZERO: Router cannot be zero address.");
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        ds.routerByFactory[IUniswapV2Router02(routerAddress).factory()] = routerAddress;
        ds.v2Routers[routerAddress] = isV2;
    }

    function getRouter(address tokenAddress) external view override returns (address) {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        return ds.routerByFactory[IUniswapV2Pair(tokenAddress).factory()];
    }

    function isRouterFactorySupported(address factory) external view override returns (bool) {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        return ds.routerByFactory[factory] != address(0);
    }

    function isV2LiquidityPoolToken(address token) external view override returns (bool) {
        bool success = false;
        bytes memory data;
        address tokenAddress;

        (success, data) = token.staticcall(abi.encodeWithSelector(IUniswapV2Pair.token0.selector));
        if (!success) {
            return false;
        }
        assembly {
            tokenAddress := mload(add(data, 32))
        }
        if (!_isContract(tokenAddress)) {
            return false;
        }

        (success, data) = token.staticcall(abi.encodeWithSelector(IUniswapV2Pair.token1.selector));
        if (!success) {
            return false;
        }
        assembly {
            tokenAddress := mload(add(data, 32))
        }
        if (!_isContract(tokenAddress)) {
            return false;
        }

        return true;
    }

    function _isContract(address externalAddress) private view returns (bool) {
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(externalAddress)
        }
        return codeSize > 0;
    }

    function isV3LiquidityPoolToken(address tokenAddress, uint256 tokenId) external view override returns (bool) {
        (address token0, address token1, , ) = getV3Position(tokenAddress, tokenId);
        return token0 != address(0) && token1 != address(0);
    }

    function getV3Position(address tokenAddress, uint256 tokenId) public view override returns (address, address, uint128, uint24) {
        try INonfungiblePositionManager(tokenAddress).positions(tokenId) returns (
            uint96,
            address,
            address token0,
            address token1,
            uint24 fee,
            int24,
            int24,
            uint128 liquidity,
            uint256,
            uint256,
            uint128,
            uint128
        ) {
            return (token0, token1, liquidity, fee);
        } catch {
            return (address(0), address(0), 0, 0);
        }
    }

    // Check whether any LP tokens are owned to sell.
    function checkUpkeep(bytes memory /* checkData */) external view override returns (bool upkeepNeeded, bytes memory performData) {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        uint256 loopLimit = ds.tokens[LibCommonConsts.INNER_STRUCT].length;

        if (loopLimit == 0) {
            return (false, abi.encode(""));
        }

        for (uint256 i = 0; i < loopLimit; i++) {
            TokenSwapInfo memory tokenInfo = ds.tokens[LibCommonConsts.INNER_STRUCT][i];
            if ((ds.lastAdded[tokenInfo.tokenAddress] + ds.sellDelay) < block.timestamp) {
                address routerAddress = ds.routerByFactory[tokenInfo.routerFactory];
                if (routerAddress != address(0)) {
                    // We only need one token ready for processing
                    return (true, abi.encode(""));
                }
            }
        }
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        uint256 tokensLength = ds.tokens[LibCommonConsts.INNER_STRUCT].length;
        if (tokensLength == 0) {
            return;
        }
        for (uint256 i = 0; i < tokensLength; i++) {
            bool success = _processTokenSwapping(i);
            if (success) break; // only process one token per transaction
        }
    }

    function processTokenSwapping(address token) external override {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        for (uint256 i = 0; i < ds.tokens[LibCommonConsts.INNER_STRUCT].length; i++) {
            if (ds.tokens[LibCommonConsts.INNER_STRUCT][i].tokenAddress == token) {
                _processTokenSwapping(i);
                break;
            }
        }
    }

    function processTokenSwappingByIndex(uint256 index) external override {
        _processTokenSwapping(index);
    }

    function _processTokenSwapping(uint256 index) private returns (bool) {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        TokenSwapInfo memory info = ds.tokens[LibCommonConsts.INNER_STRUCT][index];
        address routerAddress = ds.routerByFactory[info.routerFactory];
        require(routerAddress != address(0), "TokenSwapperFacet::_processTokenSwapping: Unsupported router.");
        require(
            (ds.lastAdded[info.tokenAddress] + ds.sellDelay) < block.timestamp,
            "TokenSwapperFacet::_processTokenSwapping: Token is not ready for processing."
        );

        uint256 earnedFees = 0;
        if (info.tokenAddress != ds.feeToken) {
            earnedFees = _swapByFeeToken(info, routerAddress);
        } else {
            // If the token to be processed is the fee token itself, there is no need to swap.
            earnedFees = info.amount;
        }

        _processFees(info, earnedFees);
        ds.tokens[LibCommonConsts.INNER_STRUCT][index] = ds.tokens[LibCommonConsts.INNER_STRUCT][ds.tokens[LibCommonConsts.INNER_STRUCT].length - 1];
        ds.tokens[LibCommonConsts.INNER_STRUCT].pop();
        emit LibTokenSwapperStorage.TokenProcessed(info.tokenAddress);
        return true;
    }

    function _swapByFeeToken(TokenSwapInfo memory info, address routerAddress) private returns (uint256) {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();

        TokenForSwap[] memory tokens = new TokenForSwap[](2);
        uint256 initialEthBalance = 0;
        address wETH;

        uint256 initialFeeAmount = IERC20Metadata(ds.feeToken).balanceOf(address(this));
        if (info.isV2) {
            // V2 LP Tokens - unpairs the liquidity pool token and swap the unpaired tokens by wrapped native token (e.g. WETH, WBNB).
            wETH = IUniswapV2Router02(routerAddress).WETH();
            initialEthBalance = IERC20Metadata(wETH).balanceOf(address(this));
            (address token0, address token1, uint256 earned0, uint256 earned1) = _swapV2TokenByNativeToken(info.tokenAddress, info.amount, routerAddress, wETH);
            tokens[0] = TokenForSwap({ tokenAddress: token0, amount: earned0 });
            tokens[1] = TokenForSwap({ tokenAddress: token1, amount: earned1 });
        } else {
            // V3 LP Tokens - they already come unpaired, so we just need to swap them for wrapped native token (e.g. WETH, WBNB).
            ISwapRouterV3 router = ISwapRouterV3(routerAddress);
            wETH = router.WETH9();
            initialEthBalance = IERC20Metadata(wETH).balanceOf(address(this));
            bool success = _swapTokensWithV3Router(info.tokenAddress, info.amount, wETH, info.v3PoolFee, address(this), routerAddress);
            require(success, "TokenSwapperFacet::_processTokenSwapping: Failed to swap ERC20 token by ds.feeToken.");
            tokens[0] = TokenForSwap({ tokenAddress: info.tokenAddress, amount: info.amount });
        }
        uint256 earnedEth = IERC20Metadata(wETH).balanceOf(address(this)) - initialEthBalance;
        if (info.tokenAddress == wETH) {
            // If the token to be processed is WETH, there is no swap, so the balance of WETH is not increased.
            // We need to manually increase the "earnedEth" otherwise their difference will be zero.
            earnedEth += info.amount;
        }
        // Swap ETH by feeToken
        _swapEthByFeeToken(earnedEth, wETH);

        // Ensure we received the expected amount of fees
        uint256 newFeeAmount = IERC20Metadata(ds.feeToken).balanceOf(address(this));
        if (info.tokenAddress == ds.feeToken) {
            // If the feeToken is the same as the token to be processed, there is no swap, so the balance of feeToken is not increased.
            // We need to manually increase the "newFeeAmount" otherwise their difference will be zero.
            newFeeAmount += info.amount;
        }
        uint256 earnedFees = newFeeAmount - initialFeeAmount;
        if (ds.requireOraclePrice) {
            uint256 expectedFees = _calculateExpectedFees(tokens);
            require(earnedFees >= expectedFees, "TokenSwapperFacet::_processTokenSwapping: Earned fees are less than expected fees.");
        }
        return earnedFees;
    }

    function _swapEthByFeeToken(uint256 amount, address weth) private {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        if (amount == 0) return;

        if (ds.v2Routers[ds.routerForFloki]) {
            address[] memory path = new address[](2);
            path[0] = weth;
            path[1] = ds.feeToken;
            bool success = _swapTokensWithV2Router(amount, path, address(this), ds.routerForFloki);
            require(success, "TokenSwapperFacet::_processTokenSwapping: Failed to swap WETH by ds.feeToken using V2.");
        } else {
            bool success = _swapTokensWithV3Router(weth, amount, ds.feeToken, ds.wethToUsdV3PoolFee, address(this), ds.routerForFloki);
            require(success, "TokenSwapperFacet::_processTokenSwapping: Failed to swap WETH by ds.feeToken using V3.");
        }
    }

    function _calculateExpectedFees(TokenForSwap[] memory tokens) private returns (uint256) {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        uint256 expectedUsd = 0;
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i].tokenAddress;
            uint256 amount = tokens[i].amount;
            if (amount == 0) continue;
            IPriceOracleManager(ds.priceOracle).fetchPriceInUSD(token);
            uint256 price = IPriceOracleManager(ds.priceOracle).getPriceInUSD(token, IERC20Metadata(ds.feeToken).decimals());
            require(price > 0 || !ds.requireOraclePrice, "TokenSwapperFacet::_calculateExpectedUsd: Price is zero.");
            expectedUsd += (amount * price) / 10 ** IERC20Metadata(token).decimals();
        }
        return expectedUsd;
    }

    /**
     * Unpairs the liquidity pool token and swap the unpaired tokens by wrapped native token (e.g. WETH, WBNB).
     */
    function _swapV2TokenByNativeToken(
        address tokenAddress,
        uint256 lpBalance,
        address routerAddress,
        address weth
    ) private returns (address token0, address token1, uint256 earnedToken0, uint256 earnedToken1) {
        require(routerAddress != address(0), "TokenSwapperFacet::_swapV2TokenByNativeToken: Unsupported router.");
        IUniswapV2Pair pairToken = IUniswapV2Pair(tokenAddress);
        pairToken.approve(routerAddress, lpBalance);

        token0 = pairToken.token0();
        token1 = pairToken.token1();

        uint256 initialToken0Balance = IERC20Metadata(token0).balanceOf(address(this));
        uint256 initialToken1Balance = IERC20Metadata(token1).balanceOf(address(this));
        // we can't use the amounts returned from "removeLiquidity"
        //  because it doesn't take fees/taxes into account
        IUniswapV2Router02(routerAddress).removeLiquidity(token0, token1, lpBalance, 0, 0, address(this), block.timestamp);
        earnedToken0 = IERC20Metadata(token0).balanceOf(address(this)) - initialToken0Balance;
        earnedToken1 = IERC20Metadata(token1).balanceOf(address(this)) - initialToken1Balance;

        address[] memory path = new address[](2);
        path[0] = token0;
        path[1] = weth;
        bool success = _swapTokensWithV2Router(IERC20Metadata(token0).balanceOf(address(this)), path, address(this), routerAddress);
        require(success, "TokenSwapperFacet::_swapV2TokenByNativeToken.FeeToken: Failed to swap token0 to weth.");
        path[0] = token1;
        success = _swapTokensWithV2Router(IERC20Metadata(token1).balanceOf(address(this)), path, address(this), routerAddress);
        require(success, "TokenSwapperFacet::_swapV2TokenByNativeToken.FeeToken: Failed to swap token1 to weth.");
    }

    function _burnFloki(uint256 feeAmount, address vault) private returns (uint256) {
        // Burn floki
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        if (ds.flokiToken != address(0)) {
            uint256 burnShare = (feeAmount * LibLockerConsts.BURN_BASIS_POINTS) / LibCommonConsts.BASIS_POINTS;
            feeAmount -= burnShare;
            uint256 flokiBurnedInitial = IERC20Metadata(ds.flokiToken).balanceOf(LibCommonConsts.BURN_ADDRESS);
            address[] memory path = new address[](3);
            path[0] = ds.feeToken;
            path[1] = IUniswapV2Router02(ds.routerForFloki).WETH();
            path[2] = ds.flokiToken;
            _swapTokensWithV2Router(burnShare, path, LibCommonConsts.BURN_ADDRESS, ds.routerForFloki);
            uint256 flokiBurned = IERC20Metadata(ds.flokiToken).balanceOf(LibCommonConsts.BURN_ADDRESS) - flokiBurnedInitial;
            emit LibTokenSwapperStorage.FlokiBurned(ds.flokiBurnedLastBlock, vault, feeAmount, flokiBurned);
            ds.flokiBurnedLastBlock = block.number;
        }
        return feeAmount;
    }

    function _processFees(TokenSwapInfo memory info, uint256 feeBalance) private {
        // Pay referrers
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        uint256 treasuryShare = _burnFloki(feeBalance, info.vault);
        if (info.referrer != address(0)) {
            uint256 referrerShare = (feeBalance * LibLockerConsts.REFERRER_BASIS_POINTS) / LibCommonConsts.BASIS_POINTS;
            treasuryShare -= referrerShare;
            IERC20Metadata(ds.feeToken).safeTransfer(info.referrer, referrerShare);
            emit LibTokenSwapperStorage.ReferrerSharedPaid(ds.referrerShareLastBlock, info.vault, info.referrer, referrerShare);
            ds.referrerShareLastBlock = block.number;
        }
        IERC20Metadata(ds.feeToken).safeTransfer(ds.treasury, treasuryShare);
        emit LibTokenSwapperStorage.FeeCollected(ds.feeCollectedLastBlock, info.vault, treasuryShare);
        ds.feeCollectedLastBlock = block.number;
    }

    function _swapTokensWithV2Router(uint256 sourceAmount, address[] memory path, address receiver, address routerAddress) private returns (bool) {
        IERC20Metadata token = IERC20Metadata(path[0]);
        // if they happen to be the same, no need to swap, just transfer
        if (path[0] == path[path.length - 1]) {
            if (receiver == address(this)) return true;
            token.safeTransfer(receiver, sourceAmount);
            return true;
        }
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);

        uint256 allowed = token.allowance(address(this), routerAddress);
        if (allowed > 0) {
            token.safeApprove(routerAddress, 0);
        }
        token.safeApprove(routerAddress, sourceAmount);

        // We validate if we received enough "amountOut" later in the tx
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(sourceAmount, 0, path, receiver, block.timestamp);
        return true;
    }

    function _swapTokensWithV3Router(
        address sourceToken,
        uint256 sourceAmount,
        address destinationToken,
        uint24 poolFee,
        address receiver,
        address routerAddress
    ) private returns (bool) {
        IERC20Metadata token = IERC20Metadata(sourceToken);
        // if they happen to be the same, no need to swap, just transfer
        if (sourceToken == destinationToken) {
            if (receiver == address(this)) return true;
            token.safeTransfer(receiver, sourceAmount);
            return true;
        }
        ISwapRouterV3 router = ISwapRouterV3(routerAddress);
        bytes memory path = abi.encodePacked(sourceToken, poolFee, destinationToken);

        uint256 allowed = token.allowance(address(this), routerAddress);
        if (allowed > 0) {
            token.safeApprove(routerAddress, 0);
        }
        token.safeApprove(routerAddress, sourceAmount);

        ISwapRouterV3.ExactInputParams memory params = ISwapRouterV3.ExactInputParams({
            path: path,
            recipient: receiver,
            amountIn: sourceAmount,
            amountOutMinimum: 0 // we validate if we received enough tokens later in the tx
        });
        try router.exactInput(params) returns (uint256) {} catch (bytes memory /* lowLevelData */) {
            return false;
        }
        return true;
    }

    function _getPriceInFeeTokenWithSlippage(address token, address feeToken) private returns (uint256) {
        LibTokenSwapperStorage.DiamondStorage storage ds = LibTokenSwapperStorage.diamondStorage();
        IPriceOracleManager(ds.priceOracle).fetchPriceInUSD(token);
        // the USD price in the same decimals as the feeToken token
        uint256 price = IPriceOracleManager(ds.priceOracle).getPriceInUSD(token, IERC20Metadata(feeToken).decimals());
        require(price > 0 || !ds.requireOraclePrice, "TokenSwapperFacet::_getPriceWithSlippage: Price is zero.");
        uint256 slippage = ds.perTokenSlippage[token];
        if (slippage == 0) {
            slippage = ds.slippageBasisPoints;
        }
        return price - ((price * slippage) / LibCommonConsts.BASIS_POINTS);
    }

    function adminWithdraw(address tokenAddress, uint256 amount, address destination) external override onlyAdmin {
        if (tokenAddress == address(0)) {
            // We specifically ignore this return value.
            (bool success, ) = payable(destination).call{ value: amount }("");
            require(success, "Failed to withdraw ETH");
        } else {
            IERC20Metadata(tokenAddress).safeTransfer(destination, amount);
        }
    }

    // solhint-disable-next-line func-name-mixedcase
    function TOKEN_SWAPPER_ADMIN_ROLE() public pure returns (bytes32) {
        return LibLockerConsts.TOKEN_SWAPPER_ADMIN_ROLE;
    }

    modifier onlyAdmin() {
        require(_hasRole(LibAccessControl.DEFAULT_ADMIN_ROLE, msg.sender) || msg.sender == address(this), "TokenSwapperFacet: caller is not an admin");
        _;
    }

    modifier onlyTokenSwapperAdmin() {
        require(_hasRole(LibLockerConsts.TOKEN_SWAPPER_ADMIN_ROLE, msg.sender), "TokenSwapperFacet: caller is not an LP admin");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

interface ITokenSwapperFacet {
    struct TokenSwapInfo {
        address tokenAddress;
        address routerFactory;
        bool isV2;
        address referrer;
        address vault;
        uint256 amount;
        uint24 v3PoolFee;
    }

    function addRouter(address routerAddress, bool isV2) external;

    function addTokenForSwapping(TokenSwapInfo memory params, uint256 addedTime) external;

    function adminWithdraw(address tokenAddress, uint256 amount, address destination) external;

    function clearTokensFromSwapping() external;

    function getTokensForSwapping() external view returns (TokenSwapInfo[] memory);

    function getRouter(address lpTokenAddress) external view returns (address);

    function getV3Position(address tokenAddress, uint256 tokenId) external view returns (address, address, uint128, uint24);

    function isRouterFactorySupported(address factory) external view returns (bool);

    function isTokenReadyForSwapping(address tokenAddress) external view returns (bool);

    function isV2LiquidityPoolToken(address tokenAddress) external view returns (bool);

    function isV3LiquidityPoolToken(address tokenAddress, uint256 tokenId) external view returns (bool);

    function processTokenSwapping(address token) external;

    function processTokenSwappingByIndex(uint256 index) external;

    function removeTokenFromSwapping(address tokenAddress) external;

    function removeTokensFromSwappingByIndexes(uint256[] memory indexes) external;

    function setRequireOraclePrice(bool requires) external;

    function setRouterForFloki(address routerAddress, bool isV2Router) external;

    function setSellDelay(uint256 newDelay) external;

    function setSlippageBasisPoints(uint256 newSlippage) external;

    function setSlippagePerToken(uint256 slippage, address token) external;

    function setWethToUsdV3PoolFee(uint24 newFee) external;

    // solhint-disable-next-line func-name-mixedcase
    function TOKEN_SWAPPER_ADMIN_ROLE() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

library LibLockerConsts {
    bytes32 internal constant PRODUCT_ID = keccak256("flokifi.locker");
    uint256 internal constant BURN_BASIS_POINTS = 2_500; // 25%
    uint256 internal constant REFERRER_BASIS_POINTS = 2_500; // 25%

    bytes32 internal constant TOKEN_SWAPPER_ADMIN_ROLE = keccak256("TOKEN_SWAPPER_ADMIN_ROLE");
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { ITokenSwapperFacet } from "../interfaces/ITokenSwapperFacet.sol";

library LibTokenSwapperStorage {
    using SafeERC20 for IERC20Metadata;

    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("flokifi.locker.tokenswapper.diamond.storage");

    struct DiamondStorage {
        mapping(address => address) routerByFactory;
        mapping(address => bool) v2Routers;
        address routerForFloki;
        uint256 sellDelay;
        mapping(address => uint256) lastAdded;
        mapping(bytes32 => ITokenSwapperFacet.TokenSwapInfo[]) tokens;
        uint256 slippageBasisPoints;
        mapping(address => uint256) perTokenSlippage;
        bool requireOraclePrice;
        address priceOracle;
        uint24 wethToUsdV3PoolFee;
        uint256 feeCollectedLastBlock;
        uint256 flokiBurnedLastBlock;
        uint256 referrerShareLastBlock;
        address feeToken;
        address flokiToken;
        address treasury;
    }

    event TokenAdded(address indexed tokenAddress);
    event TokenProcessed(address indexed tokenAddress);
    event TokenRemoved(address indexed tokenAddress);
    event SellDelayUpdated(uint256 indexed oldDelay, uint256 indexed newDelay);
    event SlippageUpdated(uint256 oldSlippage, uint256 newSlippage);
    event SlippagePerTokenUpdated(uint256 oldSlippage, uint256 newSlippage, address token);
    event FeeCollected(uint256 indexed previousBlock, address indexed vault, uint256 feeAmount);
    event ReferrerSharedPaid(uint256 indexed previousBlock, address indexed vault, address referrer, uint256 feeAmount);
    event FlokiBurned(uint256 indexed previousBlock, address indexed vault, uint256 feeAmount, uint256 flokiAmount);

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
    }
}