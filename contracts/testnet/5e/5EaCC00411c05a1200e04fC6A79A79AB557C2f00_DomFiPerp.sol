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
// OpenZeppelin Contracts (last updated v4.8.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../lib/Shares.sol";

/**
 * @dev This (I)ERC4626 has been modified with a typedef for "shares" to reduce
 * bugs confusing "shares" and asset numbers. Same bytecode as OZ 6b17b3.
 *
 * For more information, please see @ openzeppelin/contracts/interfaces/IERC4626.sol
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, Shares shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        Shares shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (Shares shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(Shares shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (Shares shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (Shares shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (Shares maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(Shares shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(Shares shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (Shares shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (Shares shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external returns (Shares maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(Shares shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(
        Shares shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '../../lib/FixedPoint.sol';

interface IPriceFeed {
    function getPrice(bytes32 productId) external view returns (FPUnsigned);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '../../lib/FixedPoint.sol';

interface IDomFiPerp {
    struct Position {
        address owner;
        bytes32 productId;
        uint256 margin; // collateral provided for this position
        FPUnsigned leverage;
        FPUnsigned price; // price when position was increased. weighted average by size
        FPUnsigned oraclePrice;
        FPSigned funding; // funding + interest when position was last increased
        bytes16 ownerPositionId;
        uint64 timestamp; // last position increase
        bool isLong;
        bool isNextPrice;
    }

    struct ProductParams {
        bytes32 productId;
        FPUnsigned maxLeverage;
        FPUnsigned fee;
        bool isActive;
        FPUnsigned minPriceChange; // min oracle increase % for trader to close with profit
        FPUnsigned weight; // share of the max exposure
        FPUnsigned reserveMultiplier; // Virtual reserve used to calculate slippage, based on remaining exposure
        FPUnsigned exposureMultiplier;
        FPUnsigned liquidationThreshold; // positions are liquidated if losses >= liquidationThreshold % of margin
        FPUnsigned liquidationBounty; // upon liquidation, liquidationBounty % of remaining margin is given to liquidators
    }

    struct Product {
        bytes32 productId;
        FPUnsigned maxLeverage;
        FPUnsigned fee;
        bool isActive;
        FPUnsigned openInterestLong;
        FPUnsigned openInterestShort;
        FPUnsigned minPriceChange; // min oracle increase % for trader to close with profit
        FPUnsigned weight; // share of the max exposure
        FPUnsigned reserveMultiplier; // Virtual reserve used to calculate slippage, based on remaining exposure
        FPUnsigned exposureMultiplier;
        FPUnsigned liquidationThreshold; // positions are liquidated if losses >= liquidationThreshold % of margin
        FPUnsigned liquidationBounty; // upon liquidation, liquidationBounty % of remaining margin is given to liquidators
    }

    struct IncreasePositionParams {
        address user;
        bytes16 userPositionId;
        bytes32 productId;
        uint256 margin;
        bool isLong;
        FPUnsigned leverage;
    }

    struct DecreasePositionParams {
        address user;
        bytes16 userPositionId;
        uint256 margin;
    }

    function increasePositions(IncreasePositionParams[] calldata params) external;

    function removeMargin(bytes32 positionId, FPUnsigned marginFraction) external returns (uint256);

    function decreasePositions(DecreasePositionParams[] calldata params) external;

    function getProduct(bytes32 productId) external view returns (Product memory);

    function getPosition(address account, bytes16 accountPositionId) external view returns (Position memory);

    function getPositionId(address account, bytes16 accountPositionId) external view returns (bytes32);

    function getMaxExposure(FPUnsigned productWeight, FPUnsigned productExposureMultiplier)
        external
        view
        returns (FPUnsigned);

    function validateManager(address manager, address account) external returns(bool);

    function validateOI(uint256 balance) external view;

    function asset() external view returns (address);

    function getPositionPnLAndFunding(Position memory position, FPUnsigned price)
        external
        returns (FPSigned pnl, FPSigned funding);

    function totalOpenInterest() external view returns (FPUnsigned);

    function getTotalPnl() external returns (FPSigned);

    event ProductAdded(bytes32 productId, Product product);
    event ProductUpdated(bytes32 productId, Product product);
    event OwnerUpdated(address newOwner);
    event GuardianUpdated(address newGuardian);
    event GovUpdated(address newGov);

    event IncreasePosition(
        bytes32 indexed positionId,
        address indexed user,
        bytes32 indexed productId,
        uint256 fee,
        Position position
    );

    event DecreasePosition(
        bytes32 indexed positionId,
        address indexed user,
        bytes32 indexed productId,
        bool didLiquidate,
        uint256 fee,
        int256 netPnl,
        FPUnsigned exitPrice,
        Position position
    );

    event RemoveMargin(
        bytes32 indexed positionId,
        address indexed user,
        uint256 oldMargin,
        FPUnsigned oldLeverage,
        Position position
    );

    event PositionLiquidated(
        bytes32 indexed positionId,
        address indexed liquidator,
        uint256 liquidatorReward,
        uint256 remainingReward,
        Position position
    );
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '../IERC4626.sol';
import './IDomFiPerp.sol';

interface IVault {
    ///@notice EIP-712 signature
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function addReferralFee(uint256 amount, address user) external returns (Shares shares);

    function withdrawAndGetFee(address user, uint256 margin, FPSigned pnl, FPUnsigned fee, IDomFiPerp.Position memory position) external returns (uint256, int256);

    function withdrawWithoutFee(address positionOwner, uint256 amount) external;

    function approveAndUpdateLiquidatorReward(uint256 remainingReward, uint256 liquidatorReward, uint256 increaseBalance, address liquidator) external;

    struct WithdrawRequest {
        uint256 assets; // to lock in rate
        Shares shares; // request size (also locks in exchange rate)
        Shares sharesRedeemed;
        uint64 beginsAt;
        uint64 length;
    }
}

interface IDomFiVault is IVault, IERC4626 {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '../../lib/FixedPoint.sol';

interface IFeeCalculator {
    function getTradeFee(
        FPUnsigned productFee,
        address user,
        address sender
    ) external view returns (FPUnsigned);

    function getDepositFee(address sender) external view returns (FPUnsigned);
    function getWithdrawFee(address sender) external view returns (FPUnsigned);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '../../lib/FixedPoint.sol';

interface IFundingManager {
    function updateFunding(bytes32) external;

    function getCumulativeFunding(bytes32) external view returns (FPSigned);
    function getCumulativeInterest(bytes32) external view returns (FPUnsigned);

    function getFundingRate(bytes32) external view returns (FPSigned);
    function getInterestRate(bytes32) external view returns (FPUnsigned);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '../../lib/FixedPoint.sol';

interface IFeeDistributor {
    struct FeeAllocation {
        address recipient;
        FPUnsigned feeRatio; // fraction of incoming fees sent to this recipient
        FPUnsigned pendingFees;
        DistributionType distributionType;
    }

    enum DistributionType {
        DELETED, // Mark for fee distribution and deletion
        FORCE_DELETED, // Mark for deletion. Any accrued fees will be lost!!
        DISABLED, // Temporarily disabled; does not accrue or distribute fees
        DIRECT, // Distribute fees via IERC20.transfer
        NOTIFY // Distribute fees via IRewardRecipient.transferRewardAmount
    }

    function receiveFee(address caller) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { FPSigned, FPUnsigned, FixedPoint } from './FixedPoint.sol';
import { floor, ceil } from './FPUnsignedOperators.sol';

/**
 * @notice Adds two `FPSigned`s, reverting on overflow.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return the sum of `a` and `b`.
*/
function add(FPSigned a, FPSigned b) pure returns (FPSigned) {
    return FPSigned.wrap(FPSigned.unwrap(a) + FPSigned.unwrap(b));
}

/**
 * @notice Subtracts two `FPSigned`s, reverting on overflow.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return the difference of `a` and `b`.
*/
function sub(FPSigned a, FPSigned b) pure returns (FPSigned) {
    return FPSigned.wrap(FPSigned.unwrap(a) - FPSigned.unwrap(b));
}

/**
 * @notice Multiplies two `FPSigned`s, reverting on overflow.
 * @dev This will "floor" the product.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return the product of `a` and `b`.
*/
function mul(FPSigned a, FPSigned b) pure returns (FPSigned) {
    // There are two caveats with this computation:
    // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
    // stored internally as an int256 ~10^59.
    // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
    // would round to 3, but this computation produces the result 2.
    // No need to use SafeMath because FixedPoint.SFP_SCALING_FACTOR != 0.
    return FPSigned.wrap(FPSigned.unwrap(a) * FPSigned.unwrap(b) / FixedPoint.SFP_SCALING_FACTOR);
}

function neg(FPSigned a) pure returns (FPSigned) {
    return FPSigned.wrap(FPSigned.unwrap(a) * -1);
}

/**
 * @notice Divides one `FPSigned` by a `FPSigned`, reverting on overflow or division by 0.
 * @dev This will "floor" the quotient.
 * @param a a FPSigned numerator.
 * @param b a FPSigned denominator.
 * @return the quotient of `a` divided by `b`.
*/
function div(FPSigned a, FPSigned b) pure returns (FPSigned) {
    // There are two caveats with this computation:
    // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
    // 10^41 is stored internally as an int256 10^59.
    // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
    // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
    return FPSigned.wrap(FPSigned.unwrap(a) * FixedPoint.SFP_SCALING_FACTOR / FPSigned.unwrap(b));
}

/**
 * @notice Whether `a` is equal to `b`.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return True if equal, or False.
*/
function isEqual(FPSigned a, FPSigned b) pure returns (bool) {
    return FPSigned.unwrap(a) == FPSigned.unwrap(b);
}

/**
 * @notice Whether `a` is equal to `b`.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return True if equal, or False.
*/
function isNotEqual(FPSigned a, FPSigned b) pure returns (bool) {
    return FPSigned.unwrap(a) != FPSigned.unwrap(b);
}

/**
 * @notice Whether `a` is greater than `b`.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return True if `a > b`, or False.
*/
function isGreaterThan(FPSigned a, FPSigned b) pure returns (bool) {
    return FPSigned.unwrap(a) > FPSigned.unwrap(b);
}

/**
 * @notice Whether `a` is greater than or equal to `b`.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return True if `a >= b`, or False.
*/
function isGreaterThanOrEqual(FPSigned a, FPSigned b) pure returns (bool) {
    return FPSigned.unwrap(a) >= FPSigned.unwrap(b);
}

/**
 * @notice Whether `a` is less than `b`.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return True if `a < b`, or False.
*/
function isLessThan(FPSigned a, FPSigned b) pure returns (bool) {
    return FPSigned.unwrap(a) < FPSigned.unwrap(b);
}

/**
 * @notice Whether `a` is less than or equal to `b`.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return True if `a <= b`, or False.
*/
function isLessThanOrEqual(FPSigned a, FPSigned b) pure returns (bool) {
    return FPSigned.unwrap(a) <= FPSigned.unwrap(b);
}

/**
 * @notice Absolute value of a FPSigned
*/
function abs(FPSigned value) pure returns (FPUnsigned) {
    int256 x = FPSigned.unwrap(value);
    uint256 raw = (x < 0) ? uint256(-x) : uint256(x);
    return FPUnsigned.wrap(raw);
}

/**
 * @notice Convert a FPUnsigned to uint, "truncating" any decimal portion.
*/
function trunc(FPSigned value) pure returns (int256) {
    return FPSigned.unwrap(value) / FixedPoint.SFP_SCALING_FACTOR;
}

/**
 * @notice Round a trader's PnL in favor of liquidity providers
*/
function roundTraderPnl(FPSigned value) pure returns (FPSigned) {
    if (FPSigned.unwrap(value) >= 0) {
        // If the P/L is a trader gain/value loss, then fractional dust gained for the trader should be reduced
        FPUnsigned pnl = FixedPoint.fromSigned(value);
        return FixedPoint.fromUnsigned(floor(pnl));
    } else {
        // If the P/L is a trader loss/vault gain, then fractional dust lost should be magnified towards the trader
        return neg(FixedPoint.fromUnsigned(ceil(abs(value))));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { FPUnsigned, FPSigned, FixedPoint } from './FixedPoint.sol';

/**
 * @notice Whether `a` is equal to `b`.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return True if equal, or False.
*/
function isEqual(FPUnsigned a, FPUnsigned b) pure returns (bool) {
    return FPUnsigned.unwrap(a) == FPUnsigned.unwrap(b);
}

/**
 * @notice Whether `a` is equal to `b`.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return True if equal, or False.
*/
function isNotEqual(FPUnsigned a, FPUnsigned b) pure returns (bool) {
    return FPUnsigned.unwrap(a) != FPUnsigned.unwrap(b);
}

/**
 * @notice Whether `a` is greater than `b`.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return True if `a > b`, or False.
*/
function isGreaterThan(FPUnsigned a, FPUnsigned b) pure returns (bool) {
    return FPUnsigned.unwrap(a) > FPUnsigned.unwrap(b);
}

/**
 * @notice Whether `a` is greater than or equal to `b`.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return True if `a >= b`, or False.
*/
function isGreaterThanOrEqual(FPUnsigned a, FPUnsigned b) pure returns (bool) {
    return FPUnsigned.unwrap(a) >= FPUnsigned.unwrap(b);
}

/**
 * @notice Whether `a` is less than `b`.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return True if `a < b`, or False.
*/
function isLessThan(FPUnsigned a, FPUnsigned b) pure returns (bool) {
    return FPUnsigned.unwrap(a) < FPUnsigned.unwrap(b);
}

/**
 * @notice Whether `a` is less than or equal to `b`.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return True if `a <= b`, or False.
*/
function isLessThanOrEqual(FPUnsigned a, FPUnsigned b) pure returns (bool) {
    return FPUnsigned.unwrap(a) <= FPUnsigned.unwrap(b);
}

/**
 * @notice Adds two `FPUnsigned`s, reverting on overflow.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return the sum of `a` and `b`.
*/
function add(FPUnsigned a, FPUnsigned b) pure returns (FPUnsigned) {
    return FPUnsigned.wrap(FPUnsigned.unwrap(a) + FPUnsigned.unwrap(b));
}

/**
 * @notice Subtracts two `FPUnsigned`s, reverting on overflow.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return the difference of `a` and `b`.
*/
function sub(FPUnsigned a, FPUnsigned b) pure returns (FPUnsigned) {
    return FPUnsigned.wrap(FPUnsigned.unwrap(a) - FPUnsigned.unwrap(b));
}

/**
 * @notice Multiplies two `FPUnsigned`s, reverting on overflow.
 * @dev This will "floor" the product.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return the product of `a` and `b`.
*/
function mul(FPUnsigned a, FPUnsigned b) pure returns (FPUnsigned) {
    // There are two caveats with this computation:
    // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
    // stored internally as a uint256 ~10^59.
    // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
    // would round to 3, but this computation produces the result 2.
    // No need to use SafeMath because FixedPoint.FP_SCALING_FACTOR != 0.
    return FPUnsigned.wrap(FPUnsigned.unwrap(a) * FPUnsigned.unwrap(b) / FixedPoint.FP_SCALING_FACTOR);
}

/**
 * @notice Divides one `FPUnsigned` by an `FPUnsigned`, reverting on overflow or division by 0.
 * @dev This will "floor" the quotient.
 * @param a a FPUnsigned numerator.
 * @param b a FPUnsigned denominator.
 * @return the quotient of `a` divided by `b`.
*/
function div(FPUnsigned a, FPUnsigned b) pure returns (FPUnsigned) {
    // There are two caveats with this computation:
    // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
    // 10^41 is stored internally as a uint256 10^59.
    // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
    // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
    return FPUnsigned.wrap(FPUnsigned.unwrap(a) * FixedPoint.FP_SCALING_FACTOR / FPUnsigned.unwrap(b));
}

/**
 * @notice Convert a FPUnsigned.FPUnsigned to uint, rounding up any decimal portion.
*/
function roundUp(FPUnsigned value) pure returns (uint256) {
    return trunc(ceil(value));
}

/**
 * @notice Convert a FPUnsigned.FPUnsigned to uint, "truncating" any decimal portion.
*/
function trunc(FPUnsigned value) pure returns (uint256) {
    return FPUnsigned.unwrap(value) / FixedPoint.FP_SCALING_FACTOR;
}

/**
 * @notice Rounding a FPUnsigned.Unsigned down to the nearest integer.
*/
function floor(FPUnsigned value) pure returns (FPUnsigned) {
    return FixedPoint.fromUnscaledUint(trunc(value));
}

/**
 * @notice Round a FPUnsigned.Unsigned up to the nearest integer.
*/
function ceil(FPUnsigned value) pure returns (FPUnsigned) {
    FPUnsigned iPart = floor(value);
    FPUnsigned fPart = sub(value, iPart);
    if (FPUnsigned.unwrap(fPart) > 0) {
        return add(iPart, FixedPoint.ONE);
    } else {
        return iPart;
    }
}

function neg(FPUnsigned a) pure returns (FPSigned) {
    return FixedPoint.fromUnsigned(a).neg();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import './FPUnsignedOperators.sol' as FPUnsignedOperators;
import './FPSignedOperators.sol' as FPSignedOperators;

type FPUnsigned is uint256;
type FPSigned is int256;

using {
    FPUnsignedOperators.isEqual as ==,
    FPUnsignedOperators.isNotEqual as !=,
    FPUnsignedOperators.isGreaterThan as >,
    FPUnsignedOperators.isGreaterThanOrEqual as >=,
    FPUnsignedOperators.isLessThan as <,
    FPUnsignedOperators.isLessThanOrEqual as <=,
    FPUnsignedOperators.add as +,
    FPUnsignedOperators.sub as -,
    FPUnsignedOperators.mul as *,
    FPUnsignedOperators.div as /,

    FPUnsignedOperators.roundUp,
    FPUnsignedOperators.trunc,
    FPUnsignedOperators.neg
} for FPUnsigned global;

using {
    FPSignedOperators.isEqual as ==,
    FPSignedOperators.isNotEqual as !=,
    FPSignedOperators.isGreaterThan as >,
    FPSignedOperators.isGreaterThanOrEqual as >=,
    FPSignedOperators.isLessThan as <,
    FPSignedOperators.isLessThanOrEqual as <=,
    FPSignedOperators.add as +,
    FPSignedOperators.sub as -,
    FPSignedOperators.mul as *,
    FPSignedOperators.div as /,

    FPSignedOperators.neg,
    FPSignedOperators.abs,
    FPSignedOperators.roundTraderPnl,
    FPSignedOperators.trunc
} for FPSigned global;

library FixedPoint {

    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    uint256 constant FP_DECIMALS = 18;

    // For unsigned values:
    //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
    uint256 constant FP_SCALING_FACTOR = 10**18;

    // For signed values:
    //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
    int256 constant SFP_SCALING_FACTOR = 10**18;

    FPUnsigned constant ONE = FPUnsigned.wrap(10**18);
    FPUnsigned constant ZERO = FPUnsigned.wrap(0);

    // largest FPUnsigned which can be squared without reverting
    FPUnsigned constant MAX_UNSIGNED_FACTOR = FPUnsigned.wrap(340282366920938463463374607431768211455);
    // largest `FPSigned`s which can be squared without reverting
    FPSigned constant MIN_SIGNED_FACTOR = FPSigned.wrap(-240615969168004511545033772477625056927);
    FPSigned constant MAX_SIGNED_FACTOR = FPSigned.wrap(240615969168004511545033772477625056927);

    // largest FPUnsigned which can be cubed without reverting
    FPUnsigned constant MAX_UNSIGNED_CUBE_FACTOR = FPUnsigned.wrap(48740834812604276470692694885616);
    // largest `FPSigned`s which can be cubed without reverting
    FPSigned constant MIN_SIGNED_CUBE_FACTOR = FPSigned.wrap(-38685626227668133590597631999999);
    FPSigned constant MAX_SIGNED_CUBE_FACTOR = FPSigned.wrap(38685626227668133590597631999999);

    /**
    * @notice Constructs an `FPUnsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5*(10**18)`.
    * @param a uint to convert into a FixedPoint.
    * @return the converted FixedPoint.
    */
    function fromUnscaledUint(uint256 a) internal pure returns (FPUnsigned) {
        return FPUnsigned.wrap(a * FP_SCALING_FACTOR);
    }

    /**
    * @notice Given a uint with a certain number of decimal places, normalize it to a FixedPoint
    * @param value uint256, e.g. 10000000 wei USDC
    * @param decimals uint8 number of decimals to interpret `value` as, e.g. 6
    * @return output FPUnsigned, e.g. (10.000000)
    */
    function fromScalar(uint256 value, uint8 decimals) internal pure returns (FPUnsigned) {
        require(decimals <= FP_DECIMALS, 'FixedPoint: max decimals');
        return div(fromUnscaledUint(value), 10**decimals);
    }

    /**
    * @notice Constructs a `FPSigned` from an unscaled int, e.g., `b=5` gets stored internally as `5*(10**18)`.
    * @param a int to convert into a FPSigned.
    * @return the converted FPSigned.
    */
    function fromUnscaledInt(int256 a) internal pure returns (FPSigned) {
        return FPSigned.wrap(a * SFP_SCALING_FACTOR);
    }

    // --------- FPUnsigned
    function fromUnsigned(FPUnsigned a) internal pure returns (FPSigned) {
        require(FPUnsigned.unwrap(a) <= uint256(type(int256).max), 'FPUnsigned too large');
        return FPSigned.wrap(int256(FPUnsigned.unwrap(a)));
    }

    /**
    * @notice Adds an unscaled uint256 to an `FPUnsigned`, reverting on overflow.
    * @param a a FPUnsigned.
    * @param b a uint256.
    * @return the sum of `a` and `b`.
    */
    function add(FPUnsigned a, uint256 b) internal pure returns (FPUnsigned) {
        return FPUnsignedOperators.add(a, fromUnscaledUint(b));
    }

    /**
    * @notice Subtracts an unscaled uint256 from an `FPUnsigned`, reverting on overflow.
    * @param a a FPUnsigned.
    * @param b a uint256.
    * @return the difference of `a` and `b`.
    */
    function sub(FPUnsigned a, uint256 b) internal pure returns (FPUnsigned) {
        return FPUnsignedOperators.sub(a, fromUnscaledUint(b));
    }

    /**
    * @notice Multiplies an `FPUnsigned` and an unscaled uint256, reverting on overflow.
    * @dev This will "floor" the product.
    * @param a a FPUnsigned.
    * @param b a FPUnsigned.
    * @return the product of `a` and `b`.
    */
    function mul(FPUnsigned a, FPUnsigned b) internal pure returns (FPUnsigned) {
        return a * b;
    }

    /**
    * @notice Multiplies an `FPUnsigned` and an unscaled uint256, reverting on overflow.
    * @dev This will "floor" the product.
    * @param a a FPUnsigned.
    * @param b a uint256.
    * @return the product of `a` and `b`.
    */
    function mul(FPUnsigned a, uint256 b) internal pure returns (FPUnsigned) {
        return FPUnsigned.wrap(FPUnsigned.unwrap(a) * b);
    }

    /**
    * @notice Divides one `FPUnsigned` by an unscaled uint256, reverting on overflow or division by 0.
    * @dev This will "floor" the quotient.
    * @param a a FPUnsigned numerator.
    * @param b a uint256 denominator.
    * @return the quotient of `a` divided by `b`.
    */
    function div(FPUnsigned a, uint256 b) internal pure returns (FPUnsigned) {
        return FPUnsigned.wrap(FPUnsigned.unwrap(a) / b);
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FPUnsigned.
     * @param b a FPUnsigned.
     * @return the minimum of `a` and `b`.
    */
    function min(FPUnsigned a, FPUnsigned b) internal pure returns (FPUnsigned) {
        return FPUnsigned.unwrap(a) < FPUnsigned.unwrap(b) ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FPUnsigned.
     * @param b a FPUnsigned.
     * @return the maximum of `a` and `b`.
    */
    function max(FPUnsigned a, FPUnsigned b) internal pure returns (FPUnsigned) {
        return FPUnsigned.unwrap(a) > FPUnsigned.unwrap(b) ? a : b;
    }

    // --------- FPSigned

    function fromSigned(FPSigned a) internal pure returns (FPUnsigned) {
        require(FPSigned.unwrap(a) >= 0, 'Negative value provided');
        return FPUnsigned.wrap(uint256(FPSigned.unwrap(a)));
    }

    /**
     * @notice Adds a `FPSigned` to an `FPUnsigned`, reverting on overflow.
     * @param a a FPSigned.
     * @param b an FPUnsigned.
     * @return the sum of `a` and `b`.
    */
    function add(FPSigned a, FPUnsigned b) internal pure returns (FPSigned) {
        return FPSignedOperators.add(a, fromUnsigned(b));
    }

    /**
     * @notice Subtracts an unscaled int256 from a `FPSigned`, reverting on overflow.
     * @param a a FPSigned.
     * @param b an int256.
     * @return the difference of `a` and `b`.
    */
    function sub(FPSigned a, int256 b) internal pure returns (FPSigned) {
        return FPSignedOperators.sub(a, fromUnscaledInt(b));
    }

    /**
    * @notice Subtracts an `FPUnsigned` from a `FPSigned`, reverting on overflow.
    * @param a a FPSigned.
    * @param b a FPUnsigned.
    * @return the difference of `a` and `b`.
    */
    function sub(FPSigned a, FPUnsigned b) internal pure returns (FPSigned) {
        return FPSignedOperators.sub(a, fromUnsigned(b));
    }

    /**
    * @notice Subtracts an unscaled uint256 from a `FPSigned`, reverting on overflow.
    * @param a a FPSigned.
    * @param b a uint256.
    * @return the difference of `a` and `b`.
    */
    function sub(FPSigned a, uint256 b) internal pure returns (FPSigned) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
    * @notice Multiplies a `FPSigned` and an unscaled uint256, reverting on overflow.
    * @dev This will "floor" the product.
    * @param a a FPSigned.
    * @param b a uint256.
    * @return the product of `a` and `b`.
    */
    function mul(FPSigned a, uint256 b) internal pure returns (FPSigned) {
        return mul(a, fromUnscaledUint(b));
    }

    /**
    * @notice Multiplies a `FPSigned` and `FPUnsigned`, reverting on overflow.
    * @dev This will "floor" the product.
    * @param a a FPSigned.
    * @param b a FPUnsigned.
    * @return the product of `a` and `b`.
    */
    function mul(FPSigned a, FPUnsigned b) internal pure returns (FPSigned) {
        return FPSignedOperators.mul(a, fromUnsigned(b));
    }

    /**
    * @notice Divides one `FPSigned` by an `FPUnsigned`, reverting on overflow or division by 0.
    * @dev This will "floor" the quotient.
    * @param a a FPSigned numerator.
    * @param b a FPUnsigned denominator.
    * @return the quotient of `a` divided by `b`.
    */
    function div(FPSigned a, FPUnsigned b) internal pure returns (FPSigned) {
        return FPSignedOperators.div(a, fromUnsigned(b));
    }

    /**
    * @notice Divides one `FPSigned` by an unscaled uint256, reverting on overflow or division by 0.
    * @dev This will "floor" the quotient.
    * @param a a FPSigned numerator.
    * @param b a uint256 denominator.
    * @return the quotient of `a` divided by `b`.
    */
    function div(FPSigned a, uint256 b) internal pure returns (FPSigned) {
        return div(a, fromUnscaledUint(b));
    }

    /**
    * @notice The minimum of `a` and `b`.
    * @param a a FPSigned.
    * @param b a FPSigned.
    * @return the minimum of `a` and `b`.
    */
    function min(FPSigned a, FPSigned b) internal pure returns (FPSigned) {
        return FPSigned.unwrap(a) < FPSigned.unwrap(b) ? a : b;
    }

    /**
    * @notice The maximum of `a` and `b`.
    * @param a a FPSigned.
    * @param b a FPSigned.
    * @return the maximum of `a` and `b`.
    */
    function max(FPSigned a, FPSigned b) internal pure returns (FPSigned) {
        return FPSigned.unwrap(a) > FPSigned.unwrap(b) ? a : b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import './FixedPoint.sol';
import '../interfaces/perp/IFeeCalculator.sol';

library PerpLib {
    using FixedPoint for FPSigned;
    using FixedPoint for FPUnsigned;

    function _canTakeProfit(
        bool isLong,
        uint256 positionTimestamp,
        FPUnsigned positionOraclePrice,
        FPUnsigned oraclePrice,
        FPUnsigned minPriceChange,
        uint256 minProfitTime
    ) internal view returns (bool) {
        if (block.timestamp > positionTimestamp + minProfitTime) {
            return true;
        }
        return isLong
            ? oraclePrice > positionOraclePrice * (FixedPoint.ONE + minPriceChange)
            : oraclePrice < positionOraclePrice * (FixedPoint.ONE - minPriceChange);
    }

    function _getPnl(
        bool isLong,
        FPUnsigned positionPrice,
        FPUnsigned positionLeverage,
        uint256 margin,
        FPUnsigned price
    ) internal pure returns (FPSigned pnl) {
        pnl = (isLong
            ? price.fromUnsigned().sub(positionPrice)
            : positionPrice.fromUnsigned().sub(price)
            ).mul(margin).mul(positionLeverage).div(positionPrice);
    }

    function _getFundingPayment(
        bool isLong,
        FPUnsigned positionLeverage,
        uint256 margin,
        FPSigned funding,
        FPSigned cumulativeFunding,
        FPUnsigned cumulativeInterest
    ) internal pure returns (FPSigned) {
        FPSigned actualMargin = FixedPoint.fromUnscaledUint(margin).fromUnsigned();
        return
            actualMargin.mul(positionLeverage) * (
                isLong
                ? cumulativeFunding.add(cumulativeInterest) - funding
                : funding - (cumulativeFunding.sub(cumulativeInterest))
            );
    }

    function _getTradeFee(
        uint256 margin,
        FPUnsigned leverage,
        FPUnsigned productFee,
        address user,
        address sender,
        IFeeCalculator feeCalculator
    ) internal view returns (uint256) {
        FPUnsigned fee = feeCalculator.getTradeFee(productFee, user, sender);
        return (FixedPoint.fromUnscaledUint(margin) * leverage * fee).roundUp();
    }

    function getUtilizationRatio(
        FPUnsigned totalOpenInterest,
        uint256 balance,
        FPSigned totalPnl,
        uint256 pendingWithdraw,
        FPUnsigned healthyUtilizationRatio
    ) internal pure returns (bool instantRedeemAvailable, FPSigned utilizationRatio) {
        FPSigned divider = FixedPoint.fromUnscaledInt(int256(balance - pendingWithdraw)) - totalPnl;
        if (divider != FixedPoint.ZERO.fromUnsigned()) {
            utilizationRatio = totalOpenInterest.fromUnsigned() / divider;
            instantRedeemAvailable = utilizationRatio <= healthyUtilizationRatio.fromUnsigned();
        } else {
            utilizationRatio = FixedPoint.ZERO.fromUnsigned();
            instantRedeemAvailable = totalOpenInterest == FixedPoint.ZERO;
        }
    }

    /** @notice get the withdraw delay for a withdraw request with no history
     */
    function _getWithdrawDelay(
        uint256 pendingWithdraw,
        FPUnsigned requestedShareFraction,
        FPSigned sumPnL,
        uint256 balance,
        FPUnsigned healthyUtilizationRatio,
        FPUnsigned totalOpenInterest,
        uint256 maxWithdrawDelay,
        uint256 delayPerUtilizationRatio
    ) internal pure returns (uint64) {
        (bool instantRedeemAvailable, FPSigned utilizationRatio) = getUtilizationRatio(
            totalOpenInterest,
            balance,
            sumPnL,
            pendingWithdraw,
            healthyUtilizationRatio
        );

        if (instantRedeemAvailable) {
            return 0;
        }

        int256 rawDelay = (utilizationRatio - healthyUtilizationRatio.fromUnsigned())
            .mul(delayPerUtilizationRatio).mul(requestedShareFraction).trunc();
        return uint64(
            rawDelay < 0
                ? 0
                : rawDelay > int256(maxWithdrawDelay)
                    ? maxWithdrawDelay
                    : uint256(rawDelay)
        );
    }

    /** worst-case previousWithdrawDelay == previousActualWait -> 2x penalty
        without this delay, people could on average halve withdraw time by
        always keeping a withdraw request open.
        best-case, previousActualWait -> \inf and they receive no penalty
    */
    function _getDelayForFullWithdraw(
        FPUnsigned requestedShareFraction,
        FPSigned sumPnL,
        FPUnsigned healthyUtilizationRatio,
        FPUnsigned totalOpenInterest,
        uint256 balance,
        uint256 pendingWithdraw,
        uint256 maxWithdrawDelay,
        uint256 delayPerUtilizationRatio,
        uint64 previousWithdrawDelay,
        uint64 previousActualWait
    ) internal pure returns (uint64 delay, uint64 penalty) {
        delay = _getWithdrawDelay(
            pendingWithdraw,
            requestedShareFraction,
            sumPnL,
            balance,
            healthyUtilizationRatio,
            totalOpenInterest,
            maxWithdrawDelay,
            delayPerUtilizationRatio
        );

        // TODO: scale this by relative size of new request and remaining old request
        if (previousWithdrawDelay != 0 && previousActualWait >= previousWithdrawDelay ) {
            // no penalty for new requests or increments
            penalty = uint64(
                (FixedPoint.fromUnscaledUint(previousWithdrawDelay).div(previousActualWait))
                    .mul(delay).trunc()
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import './FixedPoint.sol';
using FixedPoint for FPUnsigned;

type Shares is uint256;

using {
    isLessThanOrEqual as <=,
    isLessThan as <,
    isGreaterThanOrEqual as >=,
    isGreaterThan as >,
    isEqualTo as ==,
    minus as -,
    plus as +,
    div,
    mul
} for Shares global;


/**
 * @notice Whether `a` is less than or equal to `b`.
 * @param a a Shares.
 * @param b b Shares.
 * @return True if `a <= b`, or False.
*/
function isLessThanOrEqual(Shares a, Shares b) pure returns (bool) {
    return Shares.unwrap(a) <= Shares.unwrap(b);
}

/// @notice Whether `a` is less than `b`.
function isLessThan(Shares a, Shares b) pure returns (bool) {
    return Shares.unwrap(a) < Shares.unwrap(b);
}

/// @notice Whether `a` is greater than or equal to `b`.
function isGreaterThanOrEqual(Shares a, Shares b) pure returns (bool) {
    return Shares.unwrap(a) >= Shares.unwrap(b);
}

/// @notice Whether `a` is greater than `b`.
function isGreaterThan(Shares a, Shares b) pure returns (bool) {
    return Shares.unwrap(a) > Shares.unwrap(b);
}

/// @notice Whether `a` is equal to `b`.
function isEqualTo(Shares a, Shares b) pure returns (bool) {
    return Shares.unwrap(a) == Shares.unwrap(b);
}

/// @notice Difference between `a` and `b` shares. Reverts if b > a
function minus(Shares a, Shares b) pure returns (Shares) {
    return Shares.wrap(Shares.unwrap(a) - Shares.unwrap(b));
}

/// @notice Sum of `a` and `b` shares.
function plus(Shares a, Shares b) pure returns (Shares) {
    return Shares.wrap(Shares.unwrap(a) + Shares.unwrap(b));
}

function div(Shares a, Shares b) pure returns (FPUnsigned) {
    return FixedPoint.fromUnscaledUint(Shares.unwrap(a)).div(Shares.unwrap(b));
}

function mul(Shares a, FPUnsigned b) pure returns (Shares) {
    return Shares.wrap(b.mul(Shares.unwrap(a)).trunc());
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '../interfaces/staking/IFeeDistributor.sol';
import '../interfaces/oracle/IPriceFeed.sol';
import '../interfaces/perp/IDomFiPerp.sol';
import '../interfaces/perp/IDomFiVault.sol';
import '../interfaces/perp/IFundingManager.sol';
import '../interfaces/perp/IFeeCalculator.sol';
import '../lib/PerpLib.sol';

/** @title Perpetual long/short levered instruments for Domination Finance
 */
contract DomFiPerp is IDomFiPerp, ReentrancyGuard {
    using FixedPoint for FPUnsigned;
    using FixedPoint for FPSigned;
    using SafeERC20 for IERC20;

    IERC20 private immutable _asset;

    address public owner; /// @notice manages vault parameters, products, managers
    address public guardian; /// @notice can pause trading
    address public gov; /// @notice can set owner, guardian, gov
    IPriceFeed public oracle;
    IFeeCalculator public feeCalculator;
    IFundingManager public fundingManager;
    IDomFiVault public domFiVault;
    IFeeDistributor public feeDistributor; /// @notice distributes trade/liquidity fees to vault LPs

    // trading:
    mapping(bytes32 => Position) private productTotalLongs;
    mapping(bytes32 => Position) private productTotalShorts;
    mapping(bytes32 => Position) private positions;
    mapping(address => bool) public nextPriceManagers;
    mapping(address => bool) public managers; /// @notice managers may make trades on behalf of other addresses
    mapping(address => mapping(address => bool)) public approvedManagers; /// @notice managers must be approved by users
    bool private isTradeEnabled = true;
    bool public isManagerOnlyForOpen = false;
    bool public isManagerOnlyForClose = false;
    uint256 public minProfitTime = 6 hours; /// @notice wait before trades can be cashed out with < minProfit
    uint256 public minMargin; ///@notice minimum margin increment; gas could make very small liquidations unprofitable

    /// @dev scaling factor for price shift that balances long and short exposure
    FPUnsigned public maxShift = FixedPoint.fromUnscaledUint(3).div(1000);
    /// @dev scale price shift to 1/3 (giving more favorable prices) for orders that reduce net exposure
    FPUnsigned public helpfulShiftScaler = FixedPoint.ONE.div(3);

    // liquidations:
    bool public allowPublicLiquidator = false;
    mapping(address => bool) public liquidators;

    // product controls:
    bytes32[] productIds;
    mapping(bytes32 => Product) private products;
    FPUnsigned public totalWeight; /// @notice total exposure weights of all products
    FPUnsigned public override totalOpenInterest; /// @notice total size of all outstanding positions in token wei
    /// @notice total open interest (long + short) limited to 10x vault balance
    FPUnsigned public utilizationMultiplier = FixedPoint.fromUnscaledUint(10);
    /// @notice open interest of a product limited at 3x its proportional share of maxExposure
    FPUnsigned public maxExposureMultiplier = FixedPoint.fromUnscaledUint(3);

    event AddressesSet(
        IPriceFeed oracle,
        IFeeCalculator feeCalculator,
        IFundingManager fundingManager,
        IFeeDistributor feeDistributor
    );

    constructor(
        IPriceFeed _oracle,
        IFeeCalculator _feeCalculator,
        IFundingManager _fundingManager,
        IDomFiVault _domFiVault,
        IFeeDistributor _feeDistributor
    ) {
        owner = msg.sender;
        guardian = msg.sender;
        gov = msg.sender;
        oracle = _oracle;
        fundingManager = _fundingManager;
        feeCalculator = _feeCalculator;
        domFiVault = _domFiVault;
        feeDistributor = _feeDistributor;
        _asset = IERC20(_domFiVault.asset());
    }

    function asset() external view override returns (address) {
        return address(_asset);
    }

    /** @notice Increase (or open) multiple positions simultaneously. Fails unless all succeed.
     */
    function increasePositions(
        IncreasePositionParams[] calldata params
    ) external override {
        require(isTradeEnabled, '!enabled');
        for (uint256 i = 0; i < params.length; i++) {
            _increasePosition(params[i]);
        }
    }

    function _increasePosition(
        IncreasePositionParams calldata params
    ) internal nonReentrant {
        require(validateManager(msg.sender, params.user) || (!isManagerOnlyForOpen && params.user == msg.sender), '!allowed');

        // Check params
        require(params.margin >= minMargin, '!margin');
        // Check product
        Product storage product = products[params.productId];
        require(product.isActive, '!active');
        require(params.leverage <= product.maxLeverage, '!max-lev');

        // process tradeFee
        uint256 tradeFee = PerpLib._getTradeFee(params.margin, params.leverage, product.fee, params.user, msg.sender, feeCalculator);        
        _asset.safeTransferFrom(msg.sender, address(feeDistributor), tradeFee);
        feeDistributor.receiveFee(msg.sender);

        // Transfer margin to vault
        _asset.safeTransferFrom(msg.sender, address(domFiVault), params.margin);

        FPUnsigned increaseMargin = FixedPoint.fromUnscaledUint(params.margin);
        FPUnsigned increaseSize = increaseMargin * params.leverage;

        FPUnsigned price = _calculatePrice(
            product.productId,
            params.isLong,
            product.openInterestLong,
            product.openInterestShort,
            getMaxExposure(product.weight, product.exposureMultiplier),
            product.reserveMultiplier,
            increaseSize.trunc()
        );

        _updateOpenInterest(params.productId, increaseSize, params.isLong, true);
        fundingManager.updateFunding(params.productId);

        FPSigned funding = fundingManager.getCumulativeFunding(params.productId);
        if (params.isLong) {
            funding = funding.add(fundingManager.getCumulativeInterest(params.productId));
        } else {
            funding = funding.sub(fundingManager.getCumulativeInterest(params.productId));
        }

        bytes32 positionId = getPositionId(params.user, params.userPositionId);
        Position storage prev = positions[positionId];
        if (prev.margin > 0) {
            require(prev.productId == params.productId, 'WRONG_PRODUCT');
        }
        (
            FPUnsigned newPrice,
            FPSigned newFunding,
            FPUnsigned newLeverage,
            uint256 newMargin
        ) = _aggregatePosition(price, prev, params, funding);

        // If this is a new position, `isNextPrice` depends only on the
        // sender being a `nextPriceManager`.
        //
        // Otherwise, for an existing position, it is `false` if the existing
        // position's `isNextPrice` is `false` or the sender is not a
        // `nextPriceManager`.

        positions[positionId] = Position({
            owner: params.user,
            ownerPositionId: params.userPositionId,
            productId: params.productId,
            margin: newMargin,
            leverage: newLeverage,
            price: newPrice,
            oraclePrice: oracle.getPrice(product.productId),
            timestamp: uint64(block.timestamp),
            isLong: params.isLong,
            isNextPrice: nextPriceManagers[msg.sender] && (prev.margin == 0 || (prev.isNextPrice)),
            funding: newFunding
        });

        emit IncreasePosition(
            positionId,
            params.user,
            params.productId,
            tradeFee,
            positions[positionId]
        );

        _increaseProductTotalPosition(params, funding, price);
    }

    /** @notice remove margin beyond what is required to avoid liquidation
     *  @param marginFraction fraction of safe margin to remove. [0,1)
     */
    function removeMargin(bytes32 positionId, FPUnsigned marginFraction) external override nonReentrant returns (uint256 withdrawAmount) {
        require(marginFraction <= FixedPoint.ONE, '!percent');

        Position storage position = positions[positionId];
        require(position.productId != 0, 'DomFiPerp: invalid position');
        require(validateManager(msg.sender, position.owner) || (msg.sender == position.owner), '!withdraw');

        bytes32[] memory positionIds = new bytes32[](1);
        positionIds[0] = positionId;
        (bool[] memory removeable, int256[] memory removeableMargin) = canRemove(positionIds);

        require(removeable[0], '!withdrawable');
        withdrawAmount = marginFraction.mul(uint256(removeableMargin[0])).trunc();

        // update position
        uint256 oldMargin = position.margin;
        uint256 newMargin = position.margin - withdrawAmount;
        FPUnsigned oldLeverage = position.leverage;
        FPUnsigned newLeverage = position.leverage.mul(oldMargin).div(newMargin);
        position.margin = newMargin;
        position.leverage = newLeverage;

        // withdraw margin
        domFiVault.withdrawWithoutFee(position.owner, withdrawAmount);

        emit RemoveMargin(positionId, msg.sender, oldMargin, oldLeverage, position);
    }

    function canRemove(bytes32[] memory positionIds)
        public
        returns (
            bool[] memory canRemove_,
            int256[] memory removeableMargin
        )
    {
        canRemove_ = new bool[](positionIds.length);
        removeableMargin = new int256[](positionIds.length);

        for (uint256 i = 0; i < positionIds.length; i++) {
            Position memory position = positions[positionIds[i]];
            removeableMargin[i] = _getMaxSafeWithdrawableMargin(
                _updateAndGetFunding(position),
                position,
                products[position.productId].maxLeverage,
                products[position.productId].liquidationThreshold
            );
            canRemove_[i] = removeableMargin[i] > 0;
        }
    }

    /** @notice Decrease (or close) multiple positions simultaneously. Fails unless all succeed.
     */
    function decreasePositions(
        DecreasePositionParams[] calldata params
    ) external {
        for (uint256 i = 0; i < params.length; i++) {
            decreasePositionWithId(
                getPositionId(params[i].user, params[i].userPositionId),
                params[i].margin
            );
        }
    }

    // Closes position from Position with id = positionId
    function decreasePositionWithId(bytes32 positionId, uint256 margin) public nonReentrant {
        // Check position
        Position storage position = positions[positionId];
        require(validateManager(msg.sender, position.owner) || (!isManagerOnlyForClose && msg.sender == position.owner), '!close');

        // Check product
        Product storage product = products[position.productId];

        bool isFullClose;
        if (margin >= position.margin) {
            margin = position.margin;
            isFullClose = true;
        }

        FPUnsigned decreaseMargin = FixedPoint.fromUnscaledUint(margin);
        FPUnsigned price = _calculatePrice(
            product.productId,
            !position.isLong,
            product.openInterestLong,
            product.openInterestShort,
            getMaxExposure(product.weight, product.exposureMultiplier),
            product.reserveMultiplier,
            (decreaseMargin * position.leverage).trunc()
        );

        (FPSigned pnl, , bool isLiquidatable) = _canLiquidate(
            position,
            price
        );
        if (isLiquidatable) {
            _updateOpenInterest(
                position.productId,
                decreaseMargin * position.leverage,
                position.isLong,
                false
            );

            margin = position.margin;
            pnl = decreaseMargin.neg();
        } else {
            // front running protection: if oracle price up change is smaller than threshold and minProfitTime has not passed
            // and either open or close order is not using next oracle price, the pnl is be set to 0
            if (
                pnl > FixedPoint.fromUnscaledInt(0) &&
                !PerpLib._canTakeProfit(
                    position.isLong,
                    uint64(position.timestamp),
                    position.oraclePrice,
                    oracle.getPrice(product.productId),
                    product.minPriceChange,
                    minProfitTime
                ) &&
                (!position.isNextPrice || !nextPriceManagers[msg.sender])
            ) {
                pnl = FixedPoint.fromUnscaledInt(0);
            }
        }
        _decreaseProductTotalPosition(position, margin);

        (uint256 totalFee, int256 netPnl) = domFiVault.withdrawAndGetFee(msg.sender, margin, pnl, product.fee, position);
        if (!isFullClose) {
            position.margin -= margin;
        }

        Position storage pos = position; // bump to top of stack
        emit DecreasePosition(
            positionId,
            pos.owner,
            pos.productId,
            isLiquidatable,
            totalFee,
            netPnl,
            price,
            pos
        );

        if (isFullClose) {
            delete positions[positionId];
        }
    }

    // Liquidate positionIds
    function liquidatePositions(bytes32[] calldata positionIds, address feeReceiver) external {
        require(liquidators[msg.sender] || allowPublicLiquidator, '!liquidator');

        uint256 totalLiquidatorReward;
        for (uint256 i = 0; i < positionIds.length; i++) {
            bytes32 positionId = positionIds[i];
            uint256 liquidatorReward = liquidatePosition(positionId);
            totalLiquidatorReward += liquidatorReward;
        }

        if (totalLiquidatorReward > 0) {
            IERC20(_asset).safeTransferFrom(address(domFiVault), feeReceiver, totalLiquidatorReward);
        }
    }

    function canLiquidate(bytes32[] calldata positionIds)
        external
        returns (
            FPSigned[] memory pnl,
            FPSigned[] memory funding,
            bool[] memory isLiquidatable
        )
    {
        pnl = new FPSigned[](positionIds.length);
        funding = new FPSigned[](positionIds.length);
        isLiquidatable = new bool[](positionIds.length);

        for (uint256 i = 0; i < positionIds.length; i++) {
            Position storage position = positions[positionIds[i]];
            FPUnsigned price = oracle.getPrice(position.productId);
            (
                FPSigned positionPnl,
                FPSigned positionFunding,
                bool positionLiquidatable
            ) = _canLiquidate(position, price);
            pnl[i] = positionPnl;
            funding[i] = positionFunding;
            isLiquidatable[i] = positionLiquidatable;
        }
    }

    function getPositionPnLAndFunding(Position memory position, FPUnsigned price)
        public
        override
        returns (
            FPSigned pnl,
            FPSigned funding
        )
    {
        require(position.productId != 0, 'DomFiPerp: invalid position');
        funding = _updateAndGetFunding(position);
        pnl = PerpLib._getPnl(position.isLong, position.price, position.leverage, position.margin, price) - funding;
    }

    function _canLiquidate(Position storage position, FPUnsigned price)
        internal
        returns (
            FPSigned pnl,
            FPSigned funding,
            bool isLiquidatable
        )
    {
        (pnl, funding) = getPositionPnLAndFunding(position, price);
        FPUnsigned positionMargin = FixedPoint.fromUnscaledUint(position.margin);
        Product memory product = products[position.productId];
        if (pnl <= (positionMargin * product.liquidationThreshold).neg()) {
            isLiquidatable = true;
        }
    }

    function liquidatePosition(bytes32 positionId) private returns (uint256 liquidatorReward) {
        Position storage position = positions[positionId];
        Product storage product = products[position.productId];

        FPUnsigned oraclePrice = oracle.getPrice(product.productId);
        (FPSigned pnl, , bool isLiquidatable) = _canLiquidate(
            position,
            oraclePrice
        );

        if (!isLiquidatable) {
            return 0;
        }

        _updateOpenInterest(
            position.productId,
            FixedPoint.fromUnscaledUint(position.margin) * position.leverage,
            position.isLong,
            false
        );

        require(pnl < FixedPoint.fromUnscaledInt(0), 'DomFiPerp: liquidatable');
        uint256 loss = pnl.abs().roundUp();

        int256 netPnl;
        uint256 remainingReward;
        if (position.margin > loss) {
            liquidatorReward = (FixedPoint.fromUnscaledUint(position.margin - loss) * product.liquidationBounty).trunc();
            remainingReward = position.margin - loss - liquidatorReward;
            netPnl = -int256(loss);
        } else {
            netPnl = -int256(position.margin);
        }
        domFiVault.approveAndUpdateLiquidatorReward(
            remainingReward,
            liquidatorReward,
            position.margin > loss ? loss : position.margin,
            msg.sender
        );

        emit DecreasePosition(
            positionId,
            position.owner,
            position.productId,
            true,
            0,
            netPnl,
            oraclePrice,
            position
        );

        emit PositionLiquidated(
            positionId,
            msg.sender,
            liquidatorReward,
            remainingReward,
            position
        );

        delete positions[positionId];

        return liquidatorReward;
    }

    function _checkOpenInterest(
        bytes32 productId,
        FPUnsigned totalOI,
        FPUnsigned maxExpo,
        FPUnsigned amount
    ) private view returns (FPUnsigned remainingExposure) {
        Product memory product = products[productId];
        FPUnsigned vaultBalance = FixedPoint.fromUnscaledUint(domFiVault.totalAssets());
        FPUnsigned newProductExposure = product.openInterestLong + product.openInterestShort + amount;

        FPUnsigned maxExposure = maxExpo * maxExposureMultiplier;

        require(
            totalOI <= vaultBalance * utilizationMultiplier &&
                newProductExposure < maxExposure,
            '!maxOI'
        );
        remainingExposure = maxExposure - newProductExposure;
    }

    function _updateOpenInterest(
        bytes32 productId,
        FPUnsigned amount,
        bool isLong,
        bool isIncrease
    ) private {
        Product storage product = products[productId];
        if (isIncrease) {
            totalOpenInterest = totalOpenInterest + amount;
            FPUnsigned maxExposure = getMaxExposure(product.weight, product.exposureMultiplier);

            _checkOpenInterest(productId, totalOpenInterest, maxExposure, amount);

            if (isLong) {
                product.openInterestLong = product.openInterestLong + amount;
                require(
                    product.openInterestLong <= maxExposure + product.openInterestShort,
                    '!exposure-long'
                );
            } else {
                product.openInterestShort = product.openInterestShort + amount;
                require(
                    product.openInterestShort <= maxExposure + product.openInterestLong,
                    '!exposure-short'
                );
            }
        } else {
            totalOpenInterest = totalOpenInterest - amount;
            if (isLong) {
                if (product.openInterestLong >= amount) {
                    product.openInterestLong = product.openInterestLong - amount;
                } else {
                    product.openInterestLong = FixedPoint.ZERO;
                }
            } else {
                if (product.openInterestShort >= amount) {
                    product.openInterestShort = product.openInterestShort - amount;
                } else {
                    product.openInterestShort = FixedPoint.ZERO;
                }
            }
        }
    }

    function validateManager(address manager, address account) public view returns (bool) {
        return managers[manager] && approvedManagers[account][manager];
    }

    function validateOI(uint256 balance) external view override {
        require(
            totalOpenInterest <= FixedPoint.fromUnscaledUint(balance) * utilizationMultiplier,
            '!utilized'
        );
    }

    // Getters

    function getTotalPnl() external override returns (FPSigned totalPnl) {
        for (uint i = 0; i < productIds.length; i++) {
            Position storage long = productTotalLongs[productIds[i]];
            Position storage short = productTotalShorts[productIds[i]];
            FPUnsigned currentPrice = oracle.getPrice(productIds[i]);
            if (long.productId != 0) { // unless there are no longs
                (FPSigned longPnl, ) = getPositionPnLAndFunding(
                    long, currentPrice
                );
                totalPnl = totalPnl + longPnl;
            }
            if (short.productId != 0) { // unless there are no shorts
                (FPSigned shortPnl, ) = getPositionPnLAndFunding(
                    short, currentPrice
                );
                totalPnl = totalPnl + shortPnl;
            }
        }
    }

    function getProduct(bytes32 productId) external view override returns (Product memory product) {
        product = products[productId];
    }

    function getPositionId(
        address account,
        bytes16 accountPositionId
    ) public view override returns (bytes32) {
        return keccak256(abi.encodePacked(block.chainid, address(this), account, accountPositionId));
    }

    function getPosition(address account, bytes16 accountPositionId)
        external
        view
        override
        returns (Position memory position)
    {
        position = positions[getPositionId(account, accountPositionId)];
    }

    function getPositions(bytes32[] calldata positionIds) external view returns (Position[] memory _positions) {
        uint256 length = positionIds.length;
        _positions = new Position[](length);
        for (uint256 i = 0; i < length; i++) {
            _positions[i] = positions[bytes32(positionIds[i])];
        }
    }

    function getMaxExposure(FPUnsigned productWeight, FPUnsigned productExposureMultiplier)
        public
        view
        override
        returns (FPUnsigned)
    {
        return productExposureMultiplier.mul(domFiVault.totalAssets()) * productWeight / totalWeight;
    }

    function _getMaxSafeWithdrawableMargin(
        FPSigned funding,
        Position memory position,
        FPUnsigned maxLeverage,
        FPUnsigned liquidationThreshold
    ) internal view returns (int256) {
        /** math logic to get the minimum safe margin
         * liquidation condition:   (pnl - funding) <= - margin * liquidationThreshold
         * safe condition:          (pnl - funding) > - margin * liquidationThreshold
         * = priceDiff * margin * leverage / (positionPrice) > funding - margin * liquidationThreshold
         */

        FPUnsigned oraclePrice = oracle.getPrice(position.productId);
        FPSigned priceDiff = position.isLong
            ? oraclePrice.fromUnsigned().sub(position.price)
            : position.price.fromUnsigned().sub(oraclePrice);

        uint256 newSafeMinMargin;
        if (priceDiff == FixedPoint.fromUnscaledInt(0)) { 
            /** 0 > funding - margin * liquidationThreshold
             * = margin > funding / liquidationThreshold
             */
            newSafeMinMargin = funding.div(liquidationThreshold).fromSigned().roundUp();
        } else {
            /** margin * (priceDiff * leverage / positionPrice + liquidationThreshold) > fudning
             * = margin > funding / (priceDiff * leverage / positionPrice + liquidationThreshold)
             */
            FPSigned signedNewSafeMinMargin = funding / (
                priceDiff.mul(maxLeverage).div(position.price).add(liquidationThreshold)
            );
            newSafeMinMargin = signedNewSafeMinMargin > FixedPoint.fromUnscaledInt(0) ? signedNewSafeMinMargin.fromSigned().roundUp() : 0;
        }

        return int256(position.margin) - int256(minMargin > newSafeMinMargin ? minMargin : newSafeMinMargin);
    }

    // Private methods

    function _aggregatePosition(
        FPUnsigned currentPrice,
        Position storage prevPosition,
        IncreasePositionParams memory params,
        FPSigned funding
    ) private view returns (
        FPUnsigned newPrice,
        FPSigned newFunding,
        FPUnsigned newLeverage,
        uint256 newMargin
    ) {
        newLeverage = params.leverage;
        newMargin = params.margin;
        newPrice = currentPrice;
        newFunding = funding;

        if (prevPosition.margin > 0) {
            FPUnsigned increaseMargin = FixedPoint.fromUnscaledUint(params.margin);
            FPUnsigned increaseSize = increaseMargin.mul(params.leverage);

            FPUnsigned prevMargin = FixedPoint.fromUnscaledUint(prevPosition.margin);
            FPUnsigned prevSize = prevMargin * prevPosition.leverage;
            // harmonic weighted mean
            newPrice = (prevSize + increaseSize) / (prevSize / prevPosition.price + increaseSize / newPrice);

            newFunding = (prevSize.fromUnsigned() * prevPosition.funding + funding * increaseSize.fromUnsigned())
                .div(prevSize + increaseSize);
            newLeverage = (prevSize + increaseSize) / (prevMargin + increaseMargin);
            newMargin = prevPosition.margin + params.margin;
        }

        require(newLeverage >= FixedPoint.ONE, '!lev');
    }

    /// TODO: does this need to subtract out current funding and/or price?
    function _subtractPosition(
        Position storage prevPosition,
        Position storage subtractedPosition,
        uint256 margin
    ) private view returns (
        FPSigned newFunding,
        FPUnsigned newLeverage,
        uint256 newMargin
    ) {
        FPUnsigned decreaseMargin = FixedPoint.min(
            FixedPoint.fromUnscaledUint(subtractedPosition.margin),
            FixedPoint.fromUnscaledUint(margin)
        );
        FPUnsigned decreaseSize = decreaseMargin.mul(subtractedPosition.leverage);

        FPUnsigned prevMargin = FixedPoint.fromUnscaledUint(prevPosition.margin);
        FPUnsigned prevSize = prevMargin * prevPosition.leverage;

        FPUnsigned remainingSize = prevSize - decreaseSize;
        FPUnsigned remainingMargin = prevMargin - decreaseMargin;

        newFunding = prevPosition.funding * (remainingSize / prevSize).fromUnsigned();
        newLeverage = remainingSize / remainingMargin;
        newMargin = remainingMargin.trunc();

        require(newLeverage >= FixedPoint.ONE, '!lev');
    }

    function _increaseProductTotalPosition(
        IncreasePositionParams calldata params,
        FPSigned funding,
        FPUnsigned price
    ) private {
        Position storage totalPosition = params.isLong
            ? productTotalLongs[params.productId]
            : productTotalShorts[params.productId];
        (
            totalPosition.price,
            totalPosition.funding,
            totalPosition.leverage,
            totalPosition.margin
        ) = _aggregatePosition(price, totalPosition, params, funding);
        if (totalPosition.productId == bytes32(0)) {
            totalPosition.productId = params.productId;
            totalPosition.isLong = params.isLong;
        }
    }

    function _decreaseProductTotalPosition(
        Position storage userPosition,
        uint256 decreaseMargin
    ) private {
        Position storage totalPosition;
        if (userPosition.isLong) {
            totalPosition = productTotalLongs[userPosition.productId];
            if (decreaseMargin >= totalPosition.margin) {
                delete productTotalLongs[userPosition.productId];
                return;
            }
        } else {
            totalPosition = productTotalShorts[userPosition.productId];
            if (decreaseMargin >= totalPosition.margin) {
                delete productTotalShorts[userPosition.productId];
                return;
            }
        }
        (
            totalPosition.funding,
            totalPosition.leverage,
            totalPosition.margin
        ) = _subtractPosition(totalPosition, userPosition, decreaseMargin);
    }

    // integrate current funding & interest rate and get the funding payment
    function _updateAndGetFunding(Position memory position) private returns (FPSigned funding) {
        fundingManager.updateFunding(position.productId);
        FPSigned cumulativeFunding = fundingManager.getCumulativeFunding(position.productId);
        FPUnsigned cumulativeInterest = fundingManager.getCumulativeInterest(position.productId);
        funding = PerpLib._getFundingPayment(
            position.isLong,
            position.leverage,
            position.margin,
            position.funding,
            cumulativeFunding,
            cumulativeInterest
        );
    }

    // Apply two kinds of slippage to oracle price:
    //     % penalty [0,∞) as amount approaches reserve. like typical constant-product dex slippage
    //     % offset [0,maxShift] proportional to current / max exposure. improves price for orders reducing exposure
    function _calculatePrice(
        bytes32 productId,
        bool isLong,
        FPUnsigned openInterestLong,
        FPUnsigned openInterestShort,
        FPUnsigned maxExposure,
        FPUnsigned reserveMultiplier,
        uint256 amount
    ) private view returns (FPUnsigned) {
        FPUnsigned reserve = _checkOpenInterest(
            productId,
            totalOpenInterest,
            maxExposure,
            FixedPoint.fromUnscaledUint(amount)
        );

        FPUnsigned slippage = reserveMultiplier == FixedPoint.ZERO
            ? FixedPoint.ONE
            : isLong
                ? reserve * reserveMultiplier / reserve.sub(amount)
                : reserve * reserveMultiplier / reserve.add(amount)
        ;

        FPSigned shift = openInterestLong.fromUnsigned()
            .sub(openInterestShort).mul(maxShift).div(maxExposure);
        bool decreasesExposure = isLong
            ? openInterestLong < openInterestShort
            : openInterestLong > openInterestShort;
        slippage = (slippage.fromUnsigned() + (decreasesExposure ? shift.mul(helpfulShiftScaler) : shift)).fromSigned();

        return oracle.getPrice(productId) * slippage;
    }

    // Owner methods
    function addProduct(ProductParams memory _product) external {
        onlyOwner();

        bytes32 productId = _product.productId;
        require(productId != 0, '!DomFiPerp: product id');

        Product memory oldProduct = products[productId];

        require(oldProduct.maxLeverage == FixedPoint.ZERO, 'DomFiPerp: duplicate product');
        require(_product.maxLeverage >= FixedPoint.ONE, 'DomFiPerp: product leverage');
        require(_product.liquidationThreshold > FixedPoint.fromUnscaledUint(50).div(100), 'DomFiPerp: product liquidationThreshold');

        products[productId] = Product({
            productId: productId,
            maxLeverage: _product.maxLeverage,
            fee: _product.fee,
            isActive: _product.isActive,
            openInterestLong: FixedPoint.ZERO,
            openInterestShort: FixedPoint.ZERO,
            minPriceChange: _product.minPriceChange,
            weight: _product.weight,
            reserveMultiplier: _product.reserveMultiplier,
            liquidationThreshold: _product.liquidationThreshold,
            liquidationBounty: _product.liquidationBounty,
            exposureMultiplier: _product.exposureMultiplier
        });
        productIds.push(productId);

        totalWeight = totalWeight + _product.weight;

        emit ProductAdded(productId, products[productId]);
    }

    // Set product parameters

    function updateProductMaxLeverage(bytes32 _productId, FPUnsigned _maxLeverage) external {
        onlyOwner();
        onlyValidProduct(_productId);

        require(_maxLeverage >= FixedPoint.ONE, 'DomFiPerp: maxLeverage');

        Product storage product = products[_productId];
        product.maxLeverage = _maxLeverage;
        emit ProductUpdated(_productId, product);
    }

    function updateProductFee(bytes32 _productId, FPUnsigned _fee) external {
        onlyOwner();
        onlyValidProduct(_productId);

        Product storage product = products[_productId];
        product.fee = _fee;
        emit ProductUpdated(_productId, product);
    }

    function updateProductActive(bytes32 _productId, bool _isActive) external {
        onlyOwner();
        onlyValidProduct(_productId);

        Product storage product = products[_productId];
        product.isActive = _isActive;
        emit ProductUpdated(_productId, product);
    }

    function updateProductMinPriceChange(bytes32 _productId, FPUnsigned _minPriceChange) external {
        onlyOwner();
        onlyValidProduct(_productId);

        Product storage product = products[_productId];
        product.minPriceChange = _minPriceChange;
        emit ProductUpdated(_productId, product);
    }

    function updateProductLiquidationBounty(bytes32 _productId, FPUnsigned _liquidationBounty) external {
        onlyOwner();
        onlyValidProduct(_productId);

        Product storage product = products[_productId];
        product.liquidationBounty = _liquidationBounty;
        emit ProductUpdated(_productId, product);
    }

    function updateProductExposureMultiplier(bytes32 _productId, FPUnsigned _exposureMultiplier) external {
        onlyOwner();
        onlyValidProduct(_productId);

        Product storage product = products[_productId];
        product.exposureMultiplier = _exposureMultiplier;
        emit ProductUpdated(_productId, product);
    }

    function updateProductReserveMultiplier(bytes32 _productId, FPUnsigned _reserveMultiplier) external {
        onlyOwner();
        onlyValidProduct(_productId);

        Product storage product = products[_productId];
        product.reserveMultiplier = _reserveMultiplier;
        emit ProductUpdated(_productId, product);
    }

    function updateProductWeight(bytes32 _productId, FPUnsigned _weight) external {
        onlyOwner();
        onlyValidProduct(_productId);

        Product storage product = products[_productId];
        totalWeight = totalWeight - product.weight + _weight;
        product.weight = _weight;
        emit ProductUpdated(_productId, product);
    }

    function updateProductLiquidationThreshold(bytes32 _productId, FPUnsigned _liquidationThreshold) external {
        onlyOwner();
        onlyValidProduct(_productId);

        require(
            _liquidationThreshold > FixedPoint.fromUnscaledUint(50).div(100),
            'DomFiPerp: product liquidationThreshold'
        );

        Product storage product = products[_productId];
        product.liquidationThreshold = _liquidationThreshold;
        emit ProductUpdated(_productId, product);
    }

    function setManager(address _manager, bool _isActive) external {
        onlyOwner();
        managers[_manager] = _isActive;
    }

    function setAccountManager(address _manager, bool _isActive) external {
        approvedManagers[msg.sender][_manager] = _isActive;
    }

    /**
     * @dev USD value of minMargin * liquidationThreshold * liquidationBounty should be greater than
     *      the typical USD value of gas to call `liquidatePosition` when the network is congested.
     */
    function setMinMargin(uint256 _minMargin) external {
        onlyOwner();
        minMargin = _minMargin;
    }

    function setTradeEnabled(bool _isTradeEnabled) external {
        require(msg.sender == owner || managers[msg.sender]);
        isTradeEnabled = _isTradeEnabled;
    }

    // Set parameter methods

    function setMaxShift(FPUnsigned _maxShift) external {
        onlyOwner();
        require(_maxShift <= FixedPoint.fromUnscaledUint(1).div(100));
        maxShift = _maxShift;
    }

    function setMinProfitTime(uint256 _minProfitTime) external {
        onlyOwner();
        require(_minProfitTime <= 24 hours);
        minProfitTime = _minProfitTime;
    }

    function setAllowPublicLiquidator(bool _allowPublicLiquidator) external {
        onlyOwner();
        allowPublicLiquidator = _allowPublicLiquidator;
    }

    function setIsManagerOnlyForOpen(bool _isManagerOnlyForOpen) external {
        onlyOwner();
        isManagerOnlyForOpen = _isManagerOnlyForOpen;
    }

    function setIsManagerOnlyForClose(bool _isManagerOnlyForClose) external {
        onlyOwner();
        isManagerOnlyForClose = _isManagerOnlyForClose;
    }

    function setUtilizationMultiplier(FPUnsigned _utilizationMultiplier) external {
        onlyOwner();
        utilizationMultiplier = _utilizationMultiplier;
    }

    function setMaxExposureMultiplier(FPUnsigned _maxExposureMultiplier) external {
        onlyOwner();
        require(_maxExposureMultiplier > FixedPoint.ZERO);
        maxExposureMultiplier = _maxExposureMultiplier;
    }

    function setHelpfulShiftScaler(FPUnsigned _helpfulShiftScaler) external {
        onlyOwner();
        require(_helpfulShiftScaler > FixedPoint.ZERO);
        helpfulShiftScaler = _helpfulShiftScaler;
    }

    function setAddresses(
        IPriceFeed _oracle,
        IFeeCalculator _feeCalculator,
        IFundingManager _fundingManager,
        IFeeDistributor _feeDistributor
    ) external {
        onlyOwner();
        oracle = _oracle;
        feeCalculator = _feeCalculator;
        fundingManager = _fundingManager;
        feeDistributor = _feeDistributor;
        emit AddressesSet(_oracle, _feeCalculator, _fundingManager, _feeDistributor);
    }

    function setLiquidator(address _liquidator, bool _isActive) external {
        onlyOwner();
        liquidators[_liquidator] = _isActive;
    }

    function setNextPriceManager(address _nextPriceManager, bool _isActive) external {
        onlyOwner();
        nextPriceManagers[_nextPriceManager] = _isActive;
    }

    function setOwner(address _owner) external {
        onlyGov();
        owner = _owner;
        emit OwnerUpdated(_owner);
    }

    function setGuardian(address _guardian) external {
        onlyGov();
        guardian = _guardian;
        emit GuardianUpdated(_guardian);
    }

    function setGov(address _gov) external {
        onlyGov();
        gov = _gov;
        emit GovUpdated(_gov);
    }

    function pauseTrading() external {
        require(msg.sender == guardian, '!guard');
        isTradeEnabled = false;
    }

    function onlyOwner() private view {
        require(msg.sender == owner, '!owner');
    }

    function onlyGov() private view {
        require(msg.sender == gov, '!gov');
    }

    function onlyValidProduct(bytes32 _productId) private view {
        require(
            _productId != 0 &&
                products[_productId].maxLeverage > FixedPoint.ZERO,
            '!DomFiPerp: product id'
        );
    }
}