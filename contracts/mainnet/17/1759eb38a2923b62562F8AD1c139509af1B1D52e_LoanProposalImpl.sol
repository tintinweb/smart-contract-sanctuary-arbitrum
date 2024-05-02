// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

library Constants {
    uint256 internal constant YEAR_IN_SECONDS = 365 days;
    uint256 internal constant BASE = 1e18;
    uint256 internal constant MAX_FEE_PER_ANNUM = 0.05e18; // 5% max in base
    uint256 internal constant MAX_SWAP_PROTOCOL_FEE = 0.01e18; // 1% max in base
    uint256 internal constant MAX_TOTAL_PROTOCOL_FEE = 0.05e18; // 5% max in base
    uint256 internal constant MAX_P2POOL_PROTOCOL_FEE = 0.05e18; // 5% max in base
    uint256 internal constant MIN_TIME_BETWEEN_EARLIEST_REPAY_AND_EXPIRY =
        1 days;
    uint256 internal constant MAX_PRICE_UPDATE_TIMESTAMP_DIVERGENCE = 1 days;
    uint256 internal constant SEQUENCER_GRACE_PERIOD = 1 hours;
    uint256 internal constant MIN_UNSUBSCRIBE_GRACE_PERIOD = 1 days;
    uint256 internal constant MAX_UNSUBSCRIBE_GRACE_PERIOD = 14 days;
    uint256 internal constant MIN_CONVERSION_GRACE_PERIOD = 1 days;
    uint256 internal constant MIN_REPAYMENT_GRACE_PERIOD = 1 days;
    uint256 internal constant LOAN_EXECUTION_GRACE_PERIOD = 1 days;
    uint256 internal constant MAX_CONVERSION_AND_REPAYMENT_GRACE_PERIOD =
        30 days;
    uint256 internal constant MIN_TIME_UNTIL_FIRST_DUE_DATE = 1 days;
    uint256 internal constant MIN_TIME_BETWEEN_DUE_DATES = 7 days;
    uint256 internal constant MIN_WAIT_UNTIL_EARLIEST_UNSUBSCRIBE = 60 seconds;
    uint256 internal constant MAX_ARRANGER_FEE = 0.5e18; // 50% max in base
    uint256 internal constant LOAN_TERMS_UPDATE_COOL_OFF_PERIOD = 15 minutes;
    uint256 internal constant MAX_REPAYMENT_SCHEDULE_LENGTH = 20;
    uint256 internal constant SINGLE_WRAPPER_MIN_MINT = 1000; // in wei
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Errors {
    error UnregisteredVault();
    error InvalidDelegatee();
    error InvalidSender();
    error InvalidFee();
    error InsufficientSendAmount();
    error NoOracle();
    error InvalidOracleAnswer();
    error InvalidOracleDecimals();
    error InvalidOracleVersion();
    error InvalidAddress();
    error InvalidArrayLength();
    error InvalidQuote();
    error OutdatedQuote();
    error InvalidOffChainSignature();
    error InvalidOffChainMerkleProof();
    error InvalidCollUnlock();
    error InvalidAmount();
    error UnknownOnChainQuote();
    error NeitherTokenIsGOHM();
    error NoLpTokens();
    error ZeroReserve();
    error IncorrectGaugeForLpToken();
    error InvalidGaugeIndex();
    error AlreadyStaked();
    error InvalidWithdrawAmount();
    error InvalidBorrower();
    error OutsideValidRepayWindow();
    error InvalidRepayAmount();
    error ReclaimAmountIsZero();
    error UnregisteredGateway();
    error NonWhitelistedOracle();
    error NonWhitelistedCompartment();
    error NonWhitelistedCallback();
    error NonWhitelistedToken();
    error LtvHigherThanMax();
    error InsufficientVaultFunds();
    error InvalidInterestRateFactor();
    error InconsistentUnlockTokenAddresses();
    error InvalidEarliestRepay();
    error InvalidNewMinNumOfSigners();
    error AlreadySigner();
    error InvalidArrayIndex();
    error InvalidSignerRemoveInfo();
    error InvalidSendAmount();
    error TooSmallLoanAmount();
    error DeadlinePassed();
    error WithdrawEntered();
    error DuplicateAddresses();
    error OnChainQuoteAlreadyAdded();
    error OffChainQuoteHasBeenInvalidated();
    error Uninitialized();
    error InvalidRepaymentScheduleLength();
    error FirstDueDateTooCloseOrPassed();
    error InvalidGracePeriod();
    error UnregisteredLoanProposal();
    error NotInSubscriptionPhase();
    error NotInUnsubscriptionPhase();
    error InsufficientBalance();
    error InsufficientFreeSubscriptionSpace();
    error BeforeEarliestUnsubscribe();
    error InconsistentLastLoanTermsUpdateTime();
    error InvalidActionForCurrentStatus();
    error FellShortOfTotalSubscriptionTarget();
    error InvalidRollBackRequest();
    error UnsubscriptionAmountTooLarge();
    error InvalidSubscriptionRange();
    error InvalidMaxTotalSubscriptions();
    error OutsideConversionTimeWindow();
    error OutsideRepaymentTimeWindow();
    error NoDefault();
    error LoanIsFullyRepaid();
    error RepaymentIdxTooLarge();
    error AlreadyClaimed();
    error AlreadyConverted();
    error InvalidDueDates();
    error LoanTokenDueIsZero();
    error WaitForLoanTermsCoolOffPeriod();
    error ZeroConversionAmount();
    error InvalidNewOwnerProposal();
    error CollateralMustBeCompartmentalized();
    error InvalidCompartmentForToken();
    error InvalidSignature();
    error InvalidUpdate();
    error CannotClaimOutdatedStatus();
    error DelegateReducedBalance();
    error FundingPoolAlreadyExists();
    error InvalidLender();
    error NonIncreasingTokenAddrs();
    error NonIncreasingNonFungibleTokenIds();
    error TransferToWrappedTokenFailed();
    error TransferFromWrappedTokenFailed();
    error StateAlreadySet();
    error ReclaimableCollateralAmountZero();
    error InvalidSwap();
    error InvalidUpfrontFee();
    error InvalidOracleTolerance();
    error ReserveRatiosSkewedFromOraclePrice();
    error SequencerDown();
    error GracePeriodNotOver();
    error LoanExpired();
    error NoDsEth();
    error TooShortTwapInterval();
    error TooLongTwapInterval();
    error TwapExceedsThreshold();
    error Reentrancy();
    error TokenNotStuck();
    error InconsistentExpTransferFee();
    error InconsistentExpVaultBalIncrease();
    error DepositLockActive();
    error DisallowedSubscriptionLockup();
    error IncorrectLoanAmount();
    error Disabled();
    error CannotRemintUnlessZeroSupply();
    error TokensStillMissingFromWrapper();
    error OnlyMintFromSingleTokenWrapper();
    error NonMintableTokenState();
    error NoTokensTransferred();
    error TokenAlreadyCountedInWrapper();
    error TokenNotOwnedByWrapper();
    error TokenDoesNotBelongInWrapper(address tokenAddr, uint256 tokenId);
    error InvalidMintAmount();
    error QuoteViolatesPolicy();
    error AlreadyPublished();
    error PolicyAlreadySet();
    error NoPolicyToDelete();
    error InvalidTenorBounds();
    error InvalidLtvBounds();
    error InvalidLoanPerCollBounds();
    error InvalidMinApr();
    error NoPolicy();
    error InvalidMinFee();
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DataTypesPeerToPeer} from "../peer-to-peer/DataTypesPeerToPeer.sol";
import {DataTypesPeerToPool} from "../peer-to-pool/DataTypesPeerToPool.sol";

interface IMysoTokenManager {
    function processP2PBorrow(
        uint128[2] memory currProtocolFeeParams,
        DataTypesPeerToPeer.BorrowTransferInstructions
            calldata borrowInstructions,
        DataTypesPeerToPeer.Loan calldata loan,
        address lenderVault
    ) external returns (uint128[2] memory applicableProtocolFeeParams);

    function processP2PCreateVault(
        uint256 numRegisteredVaults,
        address vaultCreator,
        address newLenderVaultAddr
    ) external;

    function processP2PCreateWrappedTokenForERC721s(
        address tokenCreator,
        DataTypesPeerToPeer.WrappedERC721TokenInfo[] calldata tokensToBeWrapped,
        bytes calldata mysoTokenManagerData
    ) external;

    function processP2PCreateWrappedTokenForERC20s(
        address tokenCreator,
        DataTypesPeerToPeer.WrappedERC20TokenInfo[] calldata tokensToBeWrapped,
        bytes calldata mysoTokenManagerData
    ) external;

    function processP2PoolDeposit(
        address fundingPool,
        address depositor,
        uint256 depositAmount,
        uint256 depositLockupDuration,
        uint256 transferFee
    ) external;

    function processP2PoolSubscribe(
        address fundingPool,
        address subscriber,
        address loanProposal,
        uint256 subscriptionAmount,
        uint256 subscriptionLockupDuration,
        uint256 totalSubscriptions,
        DataTypesPeerToPool.LoanTerms calldata loanTerms
    ) external;

    function processP2PoolLoanFinalization(
        address loanProposal,
        address fundingPool,
        address arranger,
        address borrower,
        uint256 grossLoanAmount,
        bytes calldata mysoTokenManagerData
    ) external;

    function processP2PoolCreateLoanProposal(
        address fundingPool,
        address proposalCreator,
        address collToken,
        uint256 arrangerFee,
        uint256 numLoanProposals
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library DataTypesPeerToPeer {
    struct Loan {
        // address of borrower
        address borrower;
        // address of coll token
        address collToken;
        // address of loan token
        address loanToken;
        // timestamp after which any portion of loan unpaid defaults
        uint40 expiry;
        // timestamp before which borrower cannot repay
        uint40 earliestRepay;
        // initial collateral amount of loan
        uint128 initCollAmount;
        // loan amount given
        uint128 initLoanAmount;
        // full repay amount at start of loan
        uint128 initRepayAmount;
        // amount repaid (loan token) up until current time
        // note: partial repayments are allowed
        uint128 amountRepaidSoFar;
        // amount reclaimed (coll token) up until current time
        // note: partial repayments are allowed
        uint128 amountReclaimedSoFar;
        // flag tracking if collateral has been unlocked by vault
        bool collUnlocked;
        // address of the compartment housing the collateral
        address collTokenCompartmentAddr;
    }

    struct QuoteTuple {
        // loan amount per one unit of collateral if no oracle
        // LTV in terms of the constant BASE (10 ** 18) if using oracle
        uint256 loanPerCollUnitOrLtv;
        // interest rate percentage in BASE (can be negative but greater than -BASE)
        // i.e. -100% < interestRatePct since repay amount of 0 is not allowed
        // also interestRatePctInBase is not annualized
        int256 interestRatePctInBase;
        // fee percentage,in BASE, which will be paid in upfront in collateral
        uint256 upfrontFeePctInBase;
        // length of the loan in seconds
        uint256 tenor;
    }

    struct GeneralQuoteInfo {
        // address of collateral token
        address collToken;
        // address of loan token
        address loanToken;
        // address of oracle (optional)
        address oracleAddr;
        // min loan amount (in loan token) prevent griefing attacks or
        // amounts lender feels isn't worth unlocking on default
        uint256 minLoan;
        // max loan amount (in loan token) if lender wants a cap
        uint256 maxLoan;
        // timestamp after which quote automatically invalidates
        uint256 validUntil;
        // time, in seconds, that loan cannot be exercised
        uint256 earliestRepayTenor;
        // address of compartment implementation (optional)
        address borrowerCompartmentImplementation;
        // will invalidate quote after one use
        // if false, will be a standing quote
        bool isSingleUse;
        // whitelist address (optional)
        address whitelistAddr;
        // flag indicating whether whitelistAddr refers to a single whitelisted
        // borrower or to a whitelist authority that can whitelist multiple addresses
        bool isWhitelistAddrSingleBorrower;
    }

    struct OnChainQuote {
        // general quote info
        GeneralQuoteInfo generalQuoteInfo;
        // array of quote parameters
        QuoteTuple[] quoteTuples;
        // provides more distinguishability of quotes to reduce
        // likelihood of collisions w.r.t. quote creations and invalidations
        bytes32 salt;
    }

    struct OffChainQuote {
        // general quote info
        GeneralQuoteInfo generalQuoteInfo;
        // root of the merkle tree, where the merkle tree encodes all QuoteTuples the lender accepts
        bytes32 quoteTuplesRoot;
        // provides more distinguishability of quotes to reduce
        // likelihood of collisions w.r.t. quote creations and invalidations
        bytes32 salt;
        // for invalidating multiple parallel quotes in one click
        uint256 nonce;
        // array of compact signatures from vault signers
        bytes[] compactSigs;
    }

    struct LoanRepayInstructions {
        // loan id being repaid
        uint256 targetLoanId;
        // repay amount after transfer fees in loan token
        uint128 targetRepayAmount;
        // expected transfer fees in loan token (=0 for tokens without transfer fee)
        // note: amount that borrower sends is targetRepayAmount + expectedTransferFee
        uint128 expectedTransferFee;
        // deadline to prevent stale transactions
        uint256 deadline;
        // e.g., for using collateral to payoff debt via DEX
        address callbackAddr;
        // any data needed by callback
        bytes callbackData;
    }

    struct BorrowTransferInstructions {
        // amount of collateral sent
        uint256 collSendAmount;
        // sum of (i) protocol fee and (ii) transfer fees (if any) associated with sending any collateral to vault
        uint256 expectedProtocolAndVaultTransferFee;
        // transfer fees associated with sending any collateral to compartment (if used)
        uint256 expectedCompartmentTransferFee;
        // deadline to prevent stale transactions
        uint256 deadline;
        // slippage protection if oracle price is too loose
        uint256 minLoanAmount;
        // e.g., for one-click leverage
        address callbackAddr;
        // any data needed by callback
        bytes callbackData;
        // any data needed by myso token manager
        bytes mysoTokenManagerData;
    }

    struct TransferInstructions {
        // collateral token receiver
        address collReceiver;
        // effective upfront fee in collateral tokens (vault or compartment)
        uint256 upfrontFee;
    }

    struct WrappedERC721TokenInfo {
        // address of the ERC721_TOKEN
        address tokenAddr;
        // array of ERC721_TOKEN ids
        uint256[] tokenIds;
    }

    struct WrappedERC20TokenInfo {
        // token addresse
        address tokenAddr;
        // token amounts
        uint256 tokenAmount;
    }

    struct OnChainQuoteInfo {
        // hash of on chain quote
        bytes32 quoteHash;
        // valid until timestamp
        uint256 validUntil;
    }

    enum WhitelistState {
        // not whitelisted
        NOT_WHITELISTED,
        // can be used as loan or collateral token
        ERC20_TOKEN,
        // can be be used as oracle
        ORACLE,
        // can be used as compartment
        COMPARTMENT,
        // can be used as callback contract
        CALLBACK,
        // can be used as loan or collateral token, but if collateral then must
        // be used in conjunction with a compartment (e.g., for stETH with possible
        // negative rebase that could otherwise affect other borrowers in the vault)
        ERC20_TOKEN_REQUIRING_COMPARTMENT,
        // can be used in conjunction with an ERC721 wrapper
        ERC721_TOKEN,
        // can be used as ERC721 wrapper contract
        ERC721WRAPPER,
        // can be used as ERC20 wrapper contract
        ERC20WRAPPER,
        // can be used as MYSO token manager contract
        MYSO_TOKEN_MANAGER,
        // can be used as quote policy manager contract
        QUOTE_POLICY_MANAGER
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library DataTypesPeerToPool {
    struct Repayment {
        // The loan token amount due for given period; initially, expressed in relative terms (100%=BASE), once
        // finalized in absolute terms (in loanToken)
        uint128 loanTokenDue;
        // The coll token amount that can be converted for given period; initially, expressed in relative terms w.r.t.
        // loanTokenDue (e.g., convert every 1 loanToken for 8 collToken), once finalized in absolute terms (in collToken)
        uint128 collTokenDueIfConverted;
        // Timestamp when repayment is due
        uint40 dueTimestamp;
    }

    struct LoanTerms {
        // Min subscription amount (in loan token) that the borrower deems acceptable
        uint128 minTotalSubscriptions;
        // Max subscription amount (in loan token) that the borrower deems acceptable
        uint128 maxTotalSubscriptions;
        // The number of collateral tokens the borrower pledges per loan token borrowed as collateral for default case
        uint128 collPerLoanToken;
        // Borrower who can finalize given loan proposal
        address borrower;
        // Array of scheduled repayments
        Repayment[] repaymentSchedule;
    }

    struct StaticLoanProposalData {
        // Factory address from which the loan proposal is created
        address factory;
        // Funding pool address that is associated with given loan proposal and from which loan liquidity can be
        // sourced
        address fundingPool;
        // Address of collateral token to be used for given loan proposal
        address collToken;
        // Address of arranger who can manage the loan proposal contract
        address arranger;
        // Address of whitelist authority who can manage the lender whitelist (optional)
        address whitelistAuthority;
        // Unsubscribe grace period (in seconds), i.e., after acceptance by borrower lenders can unsubscribe and
        // remove liquidity for this duration before being locked-in
        uint256 unsubscribeGracePeriod;
        // Conversion grace period (in seconds), i.e., lenders can exercise their conversion right between
        // [dueTimeStamp, dueTimeStamp+conversionGracePeriod]
        uint256 conversionGracePeriod;
        // Repayment grace period (in seconds), i.e., borrowers can repay between
        // [dueTimeStamp+conversionGracePeriod, dueTimeStamp+conversionGracePeriod+repaymentGracePeriod]
        uint256 repaymentGracePeriod;
    }

    struct DynamicLoanProposalData {
        // Arranger fee charged on final loan amount, initially in relative terms (100%=BASE), and after finalization
        // in absolute terms (in loan token)
        uint256 arrangerFee;
        // The gross loan amount; initially this is zero and gets set once loan proposal gets accepted and finalized;
        // note that the borrower receives the gross loan amount minus any arranger and protocol fees
        uint256 grossLoanAmount;
        // Final collateral amount reserved for defaults; initially this is zero and gets set once loan proposal got
        // accepted and finalized
        uint256 finalCollAmountReservedForDefault;
        // Final collateral amount reserved for conversions; initially this is zero and gets set once loan proposal got
        // accepted and finalized
        uint256 finalCollAmountReservedForConversions;
        // Timestamp when the loan terms get accepted by borrower and after which they cannot be changed anymore
        uint256 loanTermsLockedTime;
        // Current repayment index, mapping to currently relevant repayment schedule element; note the
        // currentRepaymentIdx (initially 0) only ever gets incremented on repay
        uint256 currentRepaymentIdx;
        // Status of current loan proposal
        DataTypesPeerToPool.LoanStatus status;
        // Protocol fee, initially in relative terms (100%=BASE), and after finalization in absolute terms (in loan token);
        // note that the relative protocol fee is locked in at the time when the loan proposal is created
        uint256 protocolFee;
    }

    enum LoanStatus {
        WITHOUT_LOAN_TERMS,
        IN_NEGOTIATION,
        LOAN_TERMS_LOCKED,
        READY_TO_EXECUTE,
        ROLLBACK,
        LOAN_DEPLOYED,
        DEFAULTED
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IFactory {
    event LoanProposalCreated(
        address indexed loanProposalAddr,
        address indexed fundingPool,
        address indexed sender,
        address collToken,
        uint256 arrangerFee,
        uint256 unsubscribeGracePeriod,
        uint256 numLoanProposals
    );
    event FundingPoolCreated(
        address indexed newFundingPool,
        address indexed depositToken,
        uint256 numFundingPools
    );
    event ProtocolFeeUpdated(uint256 oldProtocolFee, uint256 newProtocolFee);
    event LenderWhitelistStatusClaimed(
        address indexed whitelistAuthority,
        address indexed lender,
        uint256 whitelistedUntil
    );
    event LenderWhitelistUpdated(
        address indexed whitelistAuthority,
        address[] indexed lender,
        uint256 whitelistedUntil
    );
    event MysoTokenManagerUpdated(
        address oldTokenManager,
        address newTokenManager
    );

    /**
     * @notice Creates a new loan proposal
     * @param _fundingPool The address of the funding pool from which lenders are allowed to subscribe, and -if loan proposal is successful- from where loan amount is sourced
     * @param _collToken The address of collateral token to be provided by borrower
     * @param _whitelistAuthority The address of the whitelist authority that can manage the lender whitelist (optional)
     * @param _arrangerFee The relative arranger fee (where 100% = BASE)
     * @param _unsubscribeGracePeriod The unsubscribe grace period, i.e., after a loan gets accepted by the borrower lenders can still unsubscribe for this time period before being locked-in
     * @param _conversionGracePeriod The grace period during which lenders can convert
     * @param _repaymentGracePeriod The grace period during which borrowers can repay
     */
    function createLoanProposal(
        address _fundingPool,
        address _collToken,
        address _whitelistAuthority,
        uint256 _arrangerFee,
        uint256 _unsubscribeGracePeriod,
        uint256 _conversionGracePeriod,
        uint256 _repaymentGracePeriod
    ) external;

    /**
     * @notice Creates a new funding pool
     * @param _depositToken The address of the deposit token to be accepted by the given funding pool
     */
    function createFundingPool(address _depositToken) external;

    /**
     * @notice Sets the protocol fee
     * @dev Can only be called by the loan proposal factory owner
     * @param _newProtocolFee The given protocol fee; note that this amount must be smaller than Constants.MAX_P2POOL_PROTOCOL_FEE (<5%)
     */
    function setProtocolFee(uint256 _newProtocolFee) external;

    /**
     * @notice Allows user to claim whitelisted status
     * @param whitelistAuthority Address of whitelist authorithy
     * @param whitelistedUntil Timestamp until when user is whitelisted
     * @param compactSig Compact signature from whitelist authority
     * @param salt Salt to make signature unique
     */
    function claimLenderWhitelistStatus(
        address whitelistAuthority,
        uint256 whitelistedUntil,
        bytes calldata compactSig,
        bytes32 salt
    ) external;

    /**
     * @notice Allows a whitelist authority to set the whitelistedUntil state for a given lender
     * @dev Anyone can create their own whitelist, and borrowers can decide if and which whitelist they want to use
     * @param lenders Array of lender addresses
     * @param whitelistedUntil Timestamp until which lenders shall be whitelisted under given whitelist authority
     */
    function updateLenderWhitelist(
        address[] calldata lenders,
        uint256 whitelistedUntil
    ) external;

    /**
     * @notice Sets a new MYSO token manager contract
     * @dev Can only be called by registry owner
     * @param newTokenManager Address of the new MYSO token manager contract
     */
    function setMysoTokenManager(address newTokenManager) external;

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     * @param newOwner the proposed new owner address
     */
    function transferOwnership(address newOwner) external;

    /**
     * @notice Returns the address of the funding pool implementation
     * @return The address of the funding pool implementation
     */
    function fundingPoolImpl() external view returns (address);

    /**
     * @notice Returns the address of the proposal implementation
     * @return The address of the proposal implementation
     */
    function loanProposalImpl() external view returns (address);

    /**
     * @notice Returns the address of a registered loan proposal
     * @param idx The index of the given loan proposal
     * @return The address of a registered loan proposal
     */
    function loanProposals(uint256 idx) external view returns (address);

    /**
     * @notice Returns the address of a registered funding pool
     * @param idx The index of the given funding pool
     * @return The address of a registered funding pool
     */
    function fundingPools(uint256 idx) external view returns (address);

    /**
     * @notice Returns flag whether given address is a registered loan proposal contract
     * @param addr The address to check if its a registered loan proposal
     * @return Flag indicating whether address is a registered loan proposal contract
     */
    function isLoanProposal(address addr) external view returns (bool);

    /**
     * @notice Returns flag whether given address is a registered funding pool contract
     * @param addr The address to check if its a registered funding pool
     * @return Flag indicating whether address is a registered funding pool contract
     */
    function isFundingPool(address addr) external view returns (bool);

    /**
     * @notice Returns the protocol fee
     * @return The protocol fee
     */
    function protocolFee() external view returns (uint256);

    /**
     * @notice Returns the address of the owner of this contract
     * @return The address of the owner of this contract
     */
    function owner() external view returns (address);

    /**
     * @notice Returns address of the pending owner
     * @return Address of the pending owner
     */
    function pendingOwner() external view returns (address);

    /**
     * @notice Returns the address of the MYSO token manager
     * @return Address of the MYSO token manager contract
     */
    function mysoTokenManager() external view returns (address);

    /**
     * @notice Returns boolean flag indicating whether the lender has been whitelisted by whitelistAuthority
     * @param whitelistAuthority Addresses of the whitelist authority
     * @param lender Addresses of the lender
     * @return Boolean flag indicating whether the lender has been whitelisted by whitelistAuthority
     */
    function isWhitelistedLender(
        address whitelistAuthority,
        address lender
    ) external view returns (bool);

    /**
     * @notice Returns the number of loan proposals created
     * @return Number of loan proposals created
     */
    function numLoanProposals() external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IFundingPoolImpl {
    event Deposited(
        address user,
        uint256 amount,
        uint256 depositLockupDuration
    );
    event Withdrawn(address user, uint256 amount);
    event Subscribed(
        address indexed user,
        address indexed loanProposalAddr,
        uint256 amount,
        uint256 subscriptionLockupDuration
    );
    event Unsubscribed(
        address indexed user,
        address indexed loanProposalAddr,
        uint256 amount
    );
    event LoanProposalExecuted(
        address indexed loanProposal,
        address indexed borrower,
        uint256 grossLoanAmount,
        uint256 arrangerFee,
        uint256 protocolFee
    );

    /**
     * @notice Initializes funding pool
     * @param _factory Address of the factory contract spawning the given funding pool
     * @param _depositToken Address of the deposit token for the given funding pool
     */
    function initialize(address _factory, address _depositToken) external;

    /**
     * @notice function allows users to deposit into funding pool
     * @param amount amount to deposit
     * @param transferFee this accounts for any transfer fee token may have (e.g. paxg token)
     * @param depositLockupDuration the duration for which the deposit shall be locked (optional for tokenomics)
     */
    function deposit(
        uint256 amount,
        uint256 transferFee,
        uint256 depositLockupDuration
    ) external;

    /**
     * @notice function allows users to withdraw from funding pool
     * @param amount amount to withdraw
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice function allows users from funding pool to subscribe as lenders to a proposal
     * @param loanProposal address of the proposal to which user wants to subscribe
     * @param minAmount the desired minimum subscription amount
     * @param maxAmount the desired maximum subscription amount
     * @param subscriptionLockupDuration the duration for which the subscription shall be locked (optional for tokenomics)
     */
    function subscribe(
        address loanProposal,
        uint256 minAmount,
        uint256 maxAmount,
        uint256 subscriptionLockupDuration
    ) external;

    /**
     * @notice function allows subscribed lenders to unsubscribe from a proposal
     * @dev there is a cooldown period after subscribing to mitigate possible griefing attacks
     * of subscription followed by quick unsubscription
     * @param loanProposal address of the proposal to which user wants to unsubscribe
     * @param amount amount of subscription removed
     */
    function unsubscribe(address loanProposal, uint256 amount) external;

    /**
     * @notice function allows execution of a proposal
     * @param loanProposal address of the proposal executed
     */
    function executeLoanProposal(address loanProposal) external;

    /**
     * @notice function returns factory address
     */
    function factory() external view returns (address);

    /**
     * @notice function returns address of deposit token for pool
     */
    function depositToken() external view returns (address);

    /**
     * @notice function returns balance deposited into pool
     * note: balance is tracked only through using deposit function
     * direct transfers into pool are not credited
     */
    function balanceOf(address) external view returns (uint256);

    /**
     * @notice function tracks total subscription amount for a given proposal address
     */
    function totalSubscriptions(address) external view returns (uint256);

    /**
     * @notice function tracks subscription amounts for a given proposal address and subsciber address
     */
    function subscriptionAmountOf(
        address,
        address
    ) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {DataTypesPeerToPool} from "../DataTypesPeerToPool.sol";

interface ILoanProposalImpl {
    event LoanTermsProposed(DataTypesPeerToPool.LoanTerms loanTerms);
    event LoanTermsLocked();
    event LoanTermsAndTransferCollFinalized(
        uint256 grossLoanAmount,
        uint256[2] collAmounts,
        uint256[2] fees
    );
    event Rolledback(address sender);
    event LoanDeployed();
    event ConversionExercised(
        address indexed sender,
        uint256 amount,
        uint256 repaymentIdx
    );
    event RepaymentClaimed(
        address indexed sender,
        uint256 amount,
        uint256 repaymentIdx
    );
    event Repaid(
        uint256 remainingLoanTokenDue,
        uint256 collTokenLeftUnconverted,
        uint256 repaymentIdx
    );
    event LoanDefaulted();
    event DefaultProceedsClaimed(address indexed sender);

    /**
     * @notice Initializes loan proposal
     * @param _factory Address of the factory contract from which proposal is created
     * @param _arranger Address of the arranger of the proposal
     * @param _fundingPool Address of the funding pool to be used to source liquidity, if successful
     * @param _collToken Address of collateral token to be used in loan
     * @param _whitelistAuthority Address of whitelist authority who can manage the lender whitelist (optional)
     * @param _arrangerFee Arranger fee in percent (where 100% = BASE)
     * @param _unsubscribeGracePeriod The unsubscribe grace period, i.e., after a loan gets accepted by the borrower 
     lenders can still unsubscribe for this time period before being locked-in
     * @param _conversionGracePeriod The grace period during which lenders can convert
     * @param _repaymentGracePeriod The grace period during which borrowers can repay
     */
    function initialize(
        address _factory,
        address _arranger,
        address _fundingPool,
        address _collToken,
        address _whitelistAuthority,
        uint256 _arrangerFee,
        uint256 _unsubscribeGracePeriod,
        uint256 _conversionGracePeriod,
        uint256 _repaymentGracePeriod
    ) external;

    /**
     * @notice Propose new loan terms
     * @param newLoanTerms The new loan terms
     * @dev Can only be called by the arranger
     */
    function updateLoanTerms(
        DataTypesPeerToPool.LoanTerms calldata newLoanTerms
    ) external;

    /**
     * @notice Lock loan terms
     * @param loanTermsUpdateTime The timestamp at which loan terms are locked
     * @dev Can only be called by the arranger or borrower
     */
    function lockLoanTerms(uint256 loanTermsUpdateTime) external;

    /**
     * @notice Finalize the loan terms and transfer final collateral amount
     * @param expectedTransferFee The expected transfer fee (if any) of the collateral token
     * @param mysoTokenManagerData Data to be passed to MysoTokenManager
     * @dev Can only be called by the borrower
     */
    function finalizeLoanTermsAndTransferColl(
        uint256 expectedTransferFee,
        bytes calldata mysoTokenManagerData
    ) external;

    /**
     * @notice Rolls back the loan proposal
     * @dev Can be called by borrower during the unsubscribe grace period or by anyone in case the total totalSubscriptions fell below the minTotalSubscriptions
     */
    function rollback() external;

    /**
     * @notice Checks and updates the status of the loan proposal from 'READY_TO_EXECUTE' to 'LOAN_DEPLOYED'
     * @dev Can only be called by funding pool in conjunction with executing the loan proposal and settling amounts, i.e., sending loan amount to borrower and fees
     */
    function checkAndUpdateStatus() external;

    /**
     * @notice Allows lenders to exercise their conversion right for given repayment period
     * @dev Can only be called by entitled lenders and during conversion grace period of given repayment period
     */
    function exerciseConversion() external;

    /**
     * @notice Allows borrower to repay
     * @param expectedTransferFee The expected transfer fee (if any) of the loan token
     * @dev Can only be called by borrower and during repayment grace period of given repayment period. If borrower doesn't repay in time the loan can be marked as defaulted and borrowers loses control over pledged collateral. Note that the repayment amount can be lower than the loanTokenDue if lenders convert (potentially 0 if all convert, in which case borrower still needs to call the repay function to not default). Also note that on repay any unconverted collateral token reserved for conversions for that period get transferred back to borrower.
     */
    function repay(uint256 expectedTransferFee) external;

    /**
     * @notice Allows lenders to claim any repayments for given repayment period
     * @param repaymentIdx the given repayment period index
     * @dev Can only be called by entitled lenders and if they didn't make use of their conversion right
     */
    function claimRepayment(uint256 repaymentIdx) external;

    /**
     * @notice Marks loan proposal as defaulted
     * @dev Can be called by anyone but only if borrower failed to repay during repayment grace period
     */
    function markAsDefaulted() external;

    /**
     * @notice Allows lenders to claim default proceeds
     * @dev Can only be called if borrower defaulted and loan proposal was marked as defaulted; default proceeds are whatever is left in collateral token in loan proposal contract; proceeds are splitted among all lenders taking into account any conversions lenders already made during the default period.
     */
    function claimDefaultProceeds() external;

    /**
     * @notice Returns the amount of subscriptions that converted for given repayment period
     * @param repaymentIdx The respective repayment index of given period
     * @return The total amount of subscriptions that converted for given repayment period
     */
    function totalConvertedSubscriptionsPerIdx(
        uint256 repaymentIdx
    ) external view returns (uint256);

    /**
     * @notice Returns the amount of collateral tokens that were converted during given repayment period
     * @param repaymentIdx The respective repayment index of given period
     * @return The total amount of collateral tokens that were converted during given repayment period
     */
    function collTokenConverted(
        uint256 repaymentIdx
    ) external view returns (uint256);

    /**
     * @notice Returns core dynamic data for given loan proposal
     * @return arrangerFee The arranger fee, which initially is expressed in relative terms (i.e., 100% = BASE) and once the proposal gets finalized is in absolute terms (e.g., 1000 USDC)
     * @return grossLoanAmount The final loan amount, which initially is zero and gets set once the proposal gets finalized
     * @return finalCollAmountReservedForDefault The final collateral amount reserved for default case, which initially is zero and gets set once the proposal gets finalized.
     * @return finalCollAmountReservedForConversions The final collateral amount reserved for lender conversions, which initially is zero and gets set once the proposal gets finalized
     * @return loanTermsLockedTime The timestamp when loan terms got locked in, which initially is zero and gets set once the proposal gets finalized
     * @return currentRepaymentIdx The current repayment index, which gets incremented on every repay
     * @return status The current loan proposal status.
     * @return protocolFee The protocol fee, which initially is expressed in relative terms (i.e., 100% = BASE) and once the proposal gets finalized is in absolute terms (e.g., 1000 USDC). Note that the relative protocol fee is locked in at the time when the proposal is first created
     * @dev Note that finalCollAmountReservedForDefault is a lower bound for the collateral amount that lenders can claim in case of a default. This means that in case all lenders converted and the borrower defaults then this amount will be distributed as default recovery value on a pro-rata basis to lenders. In the other case where no lenders converted then finalCollAmountReservedForDefault plus finalCollAmountReservedForConversions will be available as default recovery value for lenders, hence finalCollAmountReservedForDefault is a lower bound for a lender's default recovery value.
     */
    function dynamicData()
        external
        view
        returns (
            uint256 arrangerFee,
            uint256 grossLoanAmount,
            uint256 finalCollAmountReservedForDefault,
            uint256 finalCollAmountReservedForConversions,
            uint256 loanTermsLockedTime,
            uint256 currentRepaymentIdx,
            DataTypesPeerToPool.LoanStatus status,
            uint256 protocolFee
        );

    /**
     * @notice Returns core static data for given loan proposal
     * @return factory The address of the factory contract from which the proposal was created
     * @return fundingPool The address of the funding pool from which lenders can subscribe, and from which 
     -upon acceptance- the final loan amount gets sourced
     * @return collToken The address of the collateral token to be provided by the borrower
     * @return arranger The address of the arranger of the proposal
     * @return whitelistAuthority Addresses of the whitelist authority who can manage a lender whitelist (optional)
     * @return unsubscribeGracePeriod Unsubscribe grace period until which lenders can unsubscribe after a loan 
     proposal got accepted by the borrower
     * @return conversionGracePeriod Conversion grace period during which lenders can convert, i.e., between 
     [dueTimeStamp, dueTimeStamp+conversionGracePeriod]
     * @return repaymentGracePeriod Repayment grace period during which borrowers can repay, i.e., between 
     [dueTimeStamp+conversionGracePeriod, dueTimeStamp+conversionGracePeriod+repaymentGracePeriod]
     */
    function staticData()
        external
        view
        returns (
            address factory,
            address fundingPool,
            address collToken,
            address arranger,
            address whitelistAuthority,
            uint256 unsubscribeGracePeriod,
            uint256 conversionGracePeriod,
            uint256 repaymentGracePeriod
        );

    /**
     * @notice Returns the timestamp of when loan terms were last updated
     * @return lastLoanTermsUpdateTime The timestamp when the loan terms were last updated
     */
    function lastLoanTermsUpdateTime()
        external
        view
        returns (uint256 lastLoanTermsUpdateTime);

    /**
     * @notice Returns the current loan terms
     * @return The current loan terms
     */
    function loanTerms()
        external
        view
        returns (DataTypesPeerToPool.LoanTerms memory);

    /**
     * @notice Returns flag indicating whether lenders can currently unsubscribe from loan proposal
     * @return Flag indicating whether lenders can currently unsubscribe from loan proposal
     */
    function canUnsubscribe() external view returns (bool);

    /**
     * @notice Returns flag indicating whether lenders can currently subscribe to loan proposal
     * @return Flag indicating whether lenders can currently subscribe to loan proposal
     */
    function canSubscribe() external view returns (bool);

    /**
     * @notice Returns indicative final loan terms
     * @param _tmpLoanTerms The current (or assumed) relative loan terms
     * @param totalSubscriptions The current (or assumed) total subscription amount
     * @param loanTokenDecimals The loan token decimals
     * @return loanTerms The loan terms in absolute terms
     * @return collAmounts Array containing collateral amount reserved for default and for conversions
     * @return fees Array containing arranger fee and protocol fee
     */
    function getAbsoluteLoanTerms(
        DataTypesPeerToPool.LoanTerms memory _tmpLoanTerms,
        uint256 totalSubscriptions,
        uint256 loanTokenDecimals
    )
        external
        view
        returns (
            DataTypesPeerToPool.LoanTerms memory loanTerms,
            uint256[2] memory collAmounts,
            uint256[2] memory fees
        );
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Constants} from "../Constants.sol";
import {DataTypesPeerToPool} from "./DataTypesPeerToPool.sol";
import {Errors} from "../Errors.sol";
import {IFactory} from "./interfaces/IFactory.sol";
import {IFundingPoolImpl} from "./interfaces/IFundingPoolImpl.sol";
import {ILoanProposalImpl} from "./interfaces/ILoanProposalImpl.sol";
import {IMysoTokenManager} from "../interfaces/IMysoTokenManager.sol";

/**
 * Loan Proposal Process:
 *
 * 1) Arranger initiates the loan proposal
 *    - Function: factory.createLoanProposal()
 *
 * 2) Arranger adjusts loan terms
 *    - Function: loanProposal.lockLoanTerms()
 *    - NOTE: This triggers a cool-off period during which the arranger cannot modify loan terms.
 *    - Lenders can subscribe or unsubscribe at any time during this phase.
 *      - Functions: fundingPool.subscribe(), fundingPool.unsubscribe()
 *
 * 3) Arranger (or borrower) finalizes the loan terms
 *    3.1) This action triggers a subscribe/unsubscribe grace period, during which lenders can still subscribe/unsubscribe.
 *         - Functions: fundingPool.subscribe(), fundingPool.unsubscribe()
 *    3.2) After the grace period, a loan execution grace period begins.
 *
 * 4) Borrower finalizes the loan terms and transfers collateral within the loan execution grace period.
 *    - Function: loanProposal.finalizeLoanTermsAndTransferColl()
 *    - NOTE: This must be done within the loan execution grace period.
 *
 * 5) The loan proposal execution can be triggered by anyone, concluding the process.
 */
contract LoanProposalImpl is Initializable, ILoanProposalImpl {
    using SafeERC20 for IERC20Metadata;

    mapping(uint256 => uint256) public totalConvertedSubscriptionsPerIdx; // denominated in loan Token
    mapping(uint256 => uint256) public collTokenConverted;
    DataTypesPeerToPool.DynamicLoanProposalData public dynamicData;
    DataTypesPeerToPool.StaticLoanProposalData public staticData;
    uint256 public lastLoanTermsUpdateTime;
    uint256 internal _totalSubscriptionsThatClaimedOnDefault;
    mapping(address => mapping(uint256 => bool))
        internal _lenderExercisedConversion;
    mapping(address => mapping(uint256 => bool))
        internal _lenderClaimedRepayment;
    mapping(address => bool) internal _lenderClaimedCollateralOnDefault;
    DataTypesPeerToPool.LoanTerms internal _loanTerms;
    mapping(uint256 => uint256) internal _loanTokenRepaid;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _factory,
        address _arranger,
        address _fundingPool,
        address _collToken,
        address _whitelistAuthority,
        uint256 _arrangerFee,
        uint256 _unsubscribeGracePeriod,
        uint256 _conversionGracePeriod,
        uint256 _repaymentGracePeriod
    ) external initializer {
        if (_arrangerFee > Constants.MAX_ARRANGER_FEE) {
            revert Errors.InvalidFee();
        }
        if (
            _unsubscribeGracePeriod < Constants.MIN_UNSUBSCRIBE_GRACE_PERIOD ||
            _unsubscribeGracePeriod > Constants.MAX_UNSUBSCRIBE_GRACE_PERIOD ||
            _conversionGracePeriod < Constants.MIN_CONVERSION_GRACE_PERIOD ||
            _repaymentGracePeriod < Constants.MIN_REPAYMENT_GRACE_PERIOD ||
            _conversionGracePeriod + _repaymentGracePeriod >
            Constants.MAX_CONVERSION_AND_REPAYMENT_GRACE_PERIOD
        ) {
            revert Errors.InvalidGracePeriod();
        }
        // @dev: staticData struct fields don't change after initialization
        staticData.factory = _factory;
        staticData.fundingPool = _fundingPool;
        staticData.collToken = _collToken;
        staticData.arranger = _arranger;
        if (_whitelistAuthority != address(0)) {
            staticData.whitelistAuthority = _whitelistAuthority;
        }
        staticData.unsubscribeGracePeriod = _unsubscribeGracePeriod;
        staticData.conversionGracePeriod = _conversionGracePeriod;
        staticData.repaymentGracePeriod = _repaymentGracePeriod;
        // @dev: dynamicData struct fields are overwritten later when converting from
        // relative to absolute amounts
        dynamicData.arrangerFee = _arrangerFee;
        dynamicData.protocolFee = IFactory(_factory).protocolFee();
    }

    function updateLoanTerms(
        DataTypesPeerToPool.LoanTerms calldata newLoanTerms
    ) external {
        _checkIsAuthorizedSender(staticData.arranger);
        DataTypesPeerToPool.LoanStatus status = dynamicData.status;
        if (
            status != DataTypesPeerToPool.LoanStatus.WITHOUT_LOAN_TERMS &&
            status != DataTypesPeerToPool.LoanStatus.IN_NEGOTIATION
        ) {
            revert Errors.InvalidActionForCurrentStatus();
        }
        // @dev: enforce loan-terms-update-cool-off-period to prevent borrower from being spammed by frequent
        // loan proposal updates, which otherwise could create friction for borrower when trying to lock in terms
        if (
            block.timestamp <
            lastLoanTermsUpdateTime +
                Constants.LOAN_TERMS_UPDATE_COOL_OFF_PERIOD
        ) {
            revert Errors.WaitForLoanTermsCoolOffPeriod();
        }
        if (
            newLoanTerms.minTotalSubscriptions == 0 ||
            newLoanTerms.minTotalSubscriptions >
            newLoanTerms.maxTotalSubscriptions
        ) {
            revert Errors.InvalidSubscriptionRange();
        }
        address fundingPool = staticData.fundingPool;
        _repaymentScheduleCheck(
            newLoanTerms.minTotalSubscriptions,
            newLoanTerms.repaymentSchedule
        );
        uint256 totalSubscriptions = IFundingPoolImpl(fundingPool)
            .totalSubscriptions(address(this));
        if (totalSubscriptions > newLoanTerms.maxTotalSubscriptions) {
            revert Errors.InvalidMaxTotalSubscriptions();
        }
        _loanTerms = newLoanTerms;
        if (status != DataTypesPeerToPool.LoanStatus.IN_NEGOTIATION) {
            dynamicData.status = DataTypesPeerToPool.LoanStatus.IN_NEGOTIATION;
        }
        lastLoanTermsUpdateTime = block.timestamp;
        emit LoanTermsProposed(newLoanTerms);
    }

    function lockLoanTerms(uint256 _loanTermsUpdateTime) external {
        if (
            msg.sender != staticData.arranger &&
            msg.sender != _loanTerms.borrower
        ) {
            revert Errors.InvalidSender();
        }
        _checkStatus(DataTypesPeerToPool.LoanStatus.IN_NEGOTIATION);
        // @dev: check if "remaining" time until first due date is "sufficiently"
        // far enough in the future
        if (
            _loanTerms.repaymentSchedule[0].dueTimestamp <
            block.timestamp +
                staticData.unsubscribeGracePeriod +
                Constants.LOAN_EXECUTION_GRACE_PERIOD +
                Constants.MIN_TIME_UNTIL_FIRST_DUE_DATE
        ) {
            revert Errors.FirstDueDateTooCloseOrPassed();
        }
        if (_loanTermsUpdateTime != lastLoanTermsUpdateTime) {
            revert Errors.InconsistentLastLoanTermsUpdateTime();
        }
        dynamicData.loanTermsLockedTime = block.timestamp;
        dynamicData.status = DataTypesPeerToPool.LoanStatus.LOAN_TERMS_LOCKED;

        emit LoanTermsLocked();
    }

    function finalizeLoanTermsAndTransferColl(
        uint256 expectedTransferFee,
        bytes calldata mysoTokenManagerData
    ) external {
        _checkIsAuthorizedSender(_loanTerms.borrower);
        // revert if loan terms are locked or lender cutoff time hasn't passed yet
        if (
            dynamicData.status !=
            DataTypesPeerToPool.LoanStatus.LOAN_TERMS_LOCKED ||
            block.timestamp < _lenderInOrOutCutoffTime() ||
            block.timestamp >
            _lenderInOrOutCutoffTime() + Constants.LOAN_EXECUTION_GRACE_PERIOD
        ) {
            revert Errors.InvalidActionForCurrentStatus();
        }
        address fundingPool = staticData.fundingPool;
        uint256 totalSubscriptions = IFundingPoolImpl(fundingPool)
            .totalSubscriptions(address(this));
        DataTypesPeerToPool.LoanTerms memory _unfinalizedLoanTerms = _loanTerms;
        if (totalSubscriptions < _unfinalizedLoanTerms.minTotalSubscriptions) {
            revert Errors.FellShortOfTotalSubscriptionTarget();
        }

        dynamicData.status = DataTypesPeerToPool.LoanStatus.READY_TO_EXECUTE;
        // note: now that final subscription amounts are known, convert relative values
        // to absolute, i.e.:
        // i) loanTokenDue from relative (e.g., 25% of final loan amount) to absolute (e.g., 25 USDC),
        // ii) collTokenDueIfConverted from relative (e.g., convert every
        // 1 loanToken for 8 collToken) to absolute (e.g., 200 collToken)
        (
            DataTypesPeerToPool.LoanTerms memory _finalizedLoanTerms,
            uint256[2] memory collAmounts,
            uint256[2] memory fees
        ) = getAbsoluteLoanTerms(
                _unfinalizedLoanTerms,
                totalSubscriptions,
                IERC20Metadata(IFundingPoolImpl(fundingPool).depositToken())
                    .decimals()
            );
        for (uint256 i; i < _finalizedLoanTerms.repaymentSchedule.length; ) {
            _loanTerms.repaymentSchedule[i].loanTokenDue = _finalizedLoanTerms
                .repaymentSchedule[i]
                .loanTokenDue;
            _loanTerms
                .repaymentSchedule[i]
                .collTokenDueIfConverted = _finalizedLoanTerms
                .repaymentSchedule[i]
                .collTokenDueIfConverted;
            unchecked {
                ++i;
            }
        }
        dynamicData.arrangerFee = fees[0];
        dynamicData.protocolFee = fees[1];
        dynamicData.grossLoanAmount = totalSubscriptions;
        dynamicData.finalCollAmountReservedForDefault = collAmounts[0];
        dynamicData.finalCollAmountReservedForConversions = collAmounts[1];
        address mysoTokenManager = IFactory(staticData.factory)
            .mysoTokenManager();
        if (mysoTokenManager != address(0)) {
            IMysoTokenManager(mysoTokenManager).processP2PoolLoanFinalization(
                address(this),
                fundingPool,
                staticData.arranger,
                msg.sender,
                totalSubscriptions,
                mysoTokenManagerData
            );
        }

        // note: final collToken amount that borrower needs to transfer is sum of:
        // 1) amount reserved for lenders in case of default, and
        // 2) amount reserved for lenders in case all convert
        address collToken = staticData.collToken;
        uint256 preBal = IERC20Metadata(collToken).balanceOf(address(this));
        IERC20Metadata(collToken).safeTransferFrom(
            msg.sender,
            address(this),
            collAmounts[0] + collAmounts[1] + expectedTransferFee
        );
        if (
            IERC20Metadata(collToken).balanceOf(address(this)) !=
            preBal + collAmounts[0] + collAmounts[1]
        ) {
            revert Errors.InvalidSendAmount();
        }

        emit LoanTermsAndTransferCollFinalized(
            totalSubscriptions,
            collAmounts,
            fees
        );
    }

    function rollback() external {
        // @dev: cannot be called anymore once finalizeLoanTermsAndTransferColl() called
        _checkStatus(DataTypesPeerToPool.LoanStatus.LOAN_TERMS_LOCKED);
        uint256 totalSubscriptions = IFundingPoolImpl(staticData.fundingPool)
            .totalSubscriptions(address(this));
        uint256 lenderInOrOutCutoffTime = _lenderInOrOutCutoffTime();
        if (
            msg.sender == _loanTerms.borrower ||
            msg.sender == staticData.arranger ||
            (block.timestamp >= lenderInOrOutCutoffTime &&
                totalSubscriptions < _loanTerms.minTotalSubscriptions) ||
            (block.timestamp >=
                lenderInOrOutCutoffTime + Constants.LOAN_EXECUTION_GRACE_PERIOD)
        ) {
            dynamicData.status = DataTypesPeerToPool.LoanStatus.ROLLBACK;
        } else {
            revert Errors.InvalidRollBackRequest();
        }

        emit Rolledback(msg.sender);
    }

    function checkAndUpdateStatus() external {
        _checkIsAuthorizedSender(staticData.fundingPool);
        _checkStatus(DataTypesPeerToPool.LoanStatus.READY_TO_EXECUTE);
        dynamicData.status = DataTypesPeerToPool.LoanStatus.LOAN_DEPLOYED;

        emit LoanDeployed();
    }

    function exerciseConversion() external {
        (, uint256 lenderContribution) = _checkIsLender();
        _checkStatus(DataTypesPeerToPool.LoanStatus.LOAN_DEPLOYED);
        uint256 repaymentIdx = _checkAndGetCurrRepaymentIdx();
        mapping(uint256 => bool)
            storage lenderExercisedConversionPerRepaymentIdx = _lenderExercisedConversion[
                msg.sender
            ];
        if (lenderExercisedConversionPerRepaymentIdx[repaymentIdx]) {
            revert Errors.AlreadyConverted();
        }
        // must be after when the period of this loan is due, but before borrower can repay
        // note: conversion can be done if blocktime is in the half-open interval of:
        // [dueTimestamp, dueTimestamp + conversionGracePeriod)
        DataTypesPeerToPool.Repayment memory _repayment = _loanTerms
            .repaymentSchedule[repaymentIdx];
        if (
            block.timestamp < _repayment.dueTimestamp ||
            block.timestamp >=
            _repayment.dueTimestamp + staticData.conversionGracePeriod
        ) {
            revert Errors.OutsideConversionTimeWindow();
        }
        uint256 totalConvertedSubscriptions = totalConvertedSubscriptionsPerIdx[
            repaymentIdx
        ];
        uint256 conversionAmount;
        address collToken = staticData.collToken;
        if (
            dynamicData.grossLoanAmount ==
            totalConvertedSubscriptions + lenderContribution
        ) {
            // Note: case where "last lender" converts
            // @dev: use remainder (rather than pro-rata) to mitigate potential rounding errors
            conversionAmount =
                _repayment.collTokenDueIfConverted -
                collTokenConverted[repaymentIdx];
            ++dynamicData.currentRepaymentIdx;
            // @dev: increment repayment idx (no need to do repay with 0 amount)
            if (_loanTerms.repaymentSchedule.length == repaymentIdx + 1) {
                // @dev: if "last lender" converts in last period then send remaining collateral back to borrower
                IERC20Metadata(collToken).safeTransfer(
                    _loanTerms.borrower,
                    IERC20Metadata(collToken).balanceOf(address(this)) -
                        conversionAmount
                );
            }
        } else {
            // Note: all other cases
            // @dev: distribute collateral token on pro-rata basis
            conversionAmount =
                (_repayment.collTokenDueIfConverted * lenderContribution) /
                dynamicData.grossLoanAmount;
        }
        if (conversionAmount == 0) {
            revert Errors.ZeroConversionAmount();
        }
        collTokenConverted[repaymentIdx] += conversionAmount;
        totalConvertedSubscriptionsPerIdx[repaymentIdx] += lenderContribution;
        lenderExercisedConversionPerRepaymentIdx[repaymentIdx] = true;
        IERC20Metadata(collToken).safeTransfer(msg.sender, conversionAmount);

        emit ConversionExercised(msg.sender, conversionAmount, repaymentIdx);
    }

    function repay(uint256 expectedTransferFee) external {
        _checkIsAuthorizedSender(_loanTerms.borrower);
        _checkStatus(DataTypesPeerToPool.LoanStatus.LOAN_DEPLOYED);
        uint256 repaymentIdx = _checkAndGetCurrRepaymentIdx();
        // must be after when the period of this loan when lenders can convert,
        // but before default period for this period
        // note: repayment can be done in the half-open interval of:
        // [dueTimestamp + conversionGracePeriod, dueTimestamp + conversionGracePeriod + repaymentGracePeriod)
        DataTypesPeerToPool.Repayment memory _repayment = _loanTerms
            .repaymentSchedule[repaymentIdx];
        uint256 currConversionCutoffTime = _repayment.dueTimestamp +
            staticData.conversionGracePeriod;
        uint256 currRepaymentCutoffTime = currConversionCutoffTime +
            staticData.repaymentGracePeriod;
        if (
            (block.timestamp < currConversionCutoffTime) ||
            (block.timestamp >= currRepaymentCutoffTime)
        ) {
            revert Errors.OutsideRepaymentTimeWindow();
        }
        address fundingPool = staticData.fundingPool;
        address loanToken = IFundingPoolImpl(fundingPool).depositToken();
        uint256 collTokenLeftUnconverted = _repayment.collTokenDueIfConverted -
            collTokenConverted[repaymentIdx];
        uint256 remainingLoanTokenDue = (_repayment.loanTokenDue *
            collTokenLeftUnconverted) / _repayment.collTokenDueIfConverted;
        _loanTokenRepaid[repaymentIdx] = remainingLoanTokenDue;
        ++dynamicData.currentRepaymentIdx;

        uint256 preBal = IERC20Metadata(loanToken).balanceOf(address(this));
        if (remainingLoanTokenDue + expectedTransferFee > 0) {
            IERC20Metadata(loanToken).safeTransferFrom(
                msg.sender,
                address(this),
                remainingLoanTokenDue + expectedTransferFee
            );
            if (
                IERC20Metadata(loanToken).balanceOf(address(this)) !=
                remainingLoanTokenDue + preBal
            ) {
                revert Errors.InvalidSendAmount();
            }
        }

        // if final repayment, send all remaining coll token back to borrower
        // else send only unconverted coll token back to borrower
        address collToken = staticData.collToken;
        uint256 collSendAmount = _loanTerms.repaymentSchedule.length ==
            repaymentIdx + 1
            ? IERC20Metadata(collToken).balanceOf(address(this))
            : collTokenLeftUnconverted;
        if (collSendAmount > 0) {
            IERC20Metadata(collToken).safeTransfer(msg.sender, collSendAmount);
        }

        emit Repaid(remainingLoanTokenDue, collSendAmount, repaymentIdx);
    }

    function claimRepayment(uint256 repaymentIdx) external {
        (address fundingPool, uint256 lenderContribution) = _checkIsLender();
        // the currentRepaymentIdx (initially 0) gets incremented on repay or if all lenders converted for given period;
        // hence any `repaymentIdx` smaller than `currentRepaymentIdx` will always map to a valid repayment claim
        if (repaymentIdx >= dynamicData.currentRepaymentIdx) {
            revert Errors.RepaymentIdxTooLarge();
        }
        DataTypesPeerToPool.LoanStatus status = dynamicData.status;
        if (
            status != DataTypesPeerToPool.LoanStatus.LOAN_DEPLOYED &&
            status != DataTypesPeerToPool.LoanStatus.DEFAULTED
        ) {
            revert Errors.InvalidActionForCurrentStatus();
        }
        // note: users can claim as soon as repaid, no need to check _getRepaymentCutoffTime(...)
        mapping(uint256 => bool)
            storage lenderClaimedRepaymentPerRepaymentIdx = _lenderClaimedRepayment[
                msg.sender
            ];
        if (
            lenderClaimedRepaymentPerRepaymentIdx[repaymentIdx] ||
            _lenderExercisedConversion[msg.sender][repaymentIdx]
        ) {
            revert Errors.AlreadyClaimed();
        }
        // repaid amount for that period split over those who didn't convert in that period
        uint256 subscriptionsEntitledToRepayment = dynamicData.grossLoanAmount -
            totalConvertedSubscriptionsPerIdx[repaymentIdx];
        uint256 claimAmount = (_loanTokenRepaid[repaymentIdx] *
            lenderContribution) / subscriptionsEntitledToRepayment;
        lenderClaimedRepaymentPerRepaymentIdx[repaymentIdx] = true;
        IERC20Metadata(IFundingPoolImpl(fundingPool).depositToken())
            .safeTransfer(msg.sender, claimAmount);

        emit RepaymentClaimed(msg.sender, claimAmount, repaymentIdx);
    }

    function markAsDefaulted() external {
        _checkStatus(DataTypesPeerToPool.LoanStatus.LOAN_DEPLOYED);
        // this will check if loan has been fully repaid yet in this instance
        // note: loan can be marked as defaulted if no repayment and blocktime is in half-open interval of:
        // [dueTimestamp + conversionGracePeriod + repaymentGracePeriod, infty)
        uint256 repaymentIdx = _checkAndGetCurrRepaymentIdx();
        if (block.timestamp < _getRepaymentCutoffTime(repaymentIdx)) {
            revert Errors.NoDefault();
        }
        dynamicData.status = DataTypesPeerToPool.LoanStatus.DEFAULTED;
        emit LoanDefaulted();
    }

    function claimDefaultProceeds() external {
        _checkStatus(DataTypesPeerToPool.LoanStatus.DEFAULTED);
        (, uint256 lenderContribution) = _checkIsLender();
        if (_lenderClaimedCollateralOnDefault[msg.sender]) {
            revert Errors.AlreadyClaimed();
        }
        uint256 lastPeriodIdx = dynamicData.currentRepaymentIdx;
        address collToken = staticData.collToken;
        uint256 totalSubscriptions = dynamicData.grossLoanAmount;
        uint256 stillToBeConvertedCollTokens = _loanTerms
            .repaymentSchedule[lastPeriodIdx]
            .collTokenDueIfConverted - collTokenConverted[lastPeriodIdx];

        // if only some lenders converted, then split 'stillToBeConvertedCollTokens'
        // fairly among lenders who didn't already convert in default period to not
        // put them at an unfair disadvantage
        uint256 totalUnconvertedSubscriptionsFromLastIdx = totalSubscriptions -
            totalConvertedSubscriptionsPerIdx[lastPeriodIdx];
        uint256 totalCollTokenClaim;
        if (!_lenderExercisedConversion[msg.sender][lastPeriodIdx]) {
            totalCollTokenClaim =
                (stillToBeConvertedCollTokens * lenderContribution) /
                totalUnconvertedSubscriptionsFromLastIdx;
            collTokenConverted[lastPeriodIdx] += totalCollTokenClaim;
            totalConvertedSubscriptionsPerIdx[
                lastPeriodIdx
            ] += lenderContribution;
            _lenderExercisedConversion[msg.sender][lastPeriodIdx] = true;
        }
        // determine pro-rata share on remaining non-conversion related collToken balance
        totalCollTokenClaim +=
            ((IERC20Metadata(collToken).balanceOf(address(this)) -
                stillToBeConvertedCollTokens) * lenderContribution) /
            (totalSubscriptions - _totalSubscriptionsThatClaimedOnDefault);
        if (totalCollTokenClaim == 0) {
            revert Errors.AlreadyClaimed();
        }
        _lenderClaimedCollateralOnDefault[msg.sender] = true;
        _totalSubscriptionsThatClaimedOnDefault += lenderContribution;
        IERC20Metadata(collToken).safeTransfer(msg.sender, totalCollTokenClaim);

        emit DefaultProceedsClaimed(msg.sender);
    }

    function loanTerms()
        external
        view
        returns (DataTypesPeerToPool.LoanTerms memory)
    {
        return _loanTerms;
    }

    function canUnsubscribe() external view returns (bool) {
        return
            canSubscribe() ||
            dynamicData.status == DataTypesPeerToPool.LoanStatus.ROLLBACK;
    }

    function canSubscribe() public view returns (bool) {
        DataTypesPeerToPool.LoanStatus status = dynamicData.status;
        return (status == DataTypesPeerToPool.LoanStatus.IN_NEGOTIATION ||
            (status == DataTypesPeerToPool.LoanStatus.LOAN_TERMS_LOCKED &&
                block.timestamp < _lenderInOrOutCutoffTime()));
    }

    function getAbsoluteLoanTerms(
        DataTypesPeerToPool.LoanTerms memory _tmpLoanTerms,
        uint256 totalSubscriptions,
        uint256 loanTokenDecimals
    )
        public
        view
        returns (
            DataTypesPeerToPool.LoanTerms memory,
            uint256[2] memory collAmounts,
            uint256[2] memory fees
        )
    {
        uint256 _arrangerFee = (dynamicData.arrangerFee * totalSubscriptions) /
            Constants.BASE;
        uint256 _protocolFee = (dynamicData.protocolFee * totalSubscriptions) /
            Constants.BASE;
        uint256 _finalCollAmountReservedForDefault = (totalSubscriptions *
            _tmpLoanTerms.collPerLoanToken) / (10 ** loanTokenDecimals);
        // note: convert relative terms into absolute values, i.e.:
        // i) loanTokenDue relative to grossLoanAmount (e.g., 25% of final loan amount),
        // ii) collTokenDueIfConverted relative to loanTokenDue (e.g., convert every
        // 1 loanToken for 8 collToken)
        uint256 _finalCollAmountReservedForConversions;
        for (uint256 i; i < _tmpLoanTerms.repaymentSchedule.length; ) {
            _tmpLoanTerms.repaymentSchedule[i].loanTokenDue = SafeCast
                .toUint128(
                    (totalSubscriptions *
                        _tmpLoanTerms.repaymentSchedule[i].loanTokenDue) /
                        Constants.BASE
                );
            _tmpLoanTerms
                .repaymentSchedule[i]
                .collTokenDueIfConverted = SafeCast.toUint128(
                (_tmpLoanTerms.repaymentSchedule[i].loanTokenDue *
                    _tmpLoanTerms
                        .repaymentSchedule[i]
                        .collTokenDueIfConverted) / (10 ** loanTokenDecimals)
            );
            _finalCollAmountReservedForConversions += _tmpLoanTerms
                .repaymentSchedule[i]
                .collTokenDueIfConverted;
            unchecked {
                ++i;
            }
        }
        return (
            _tmpLoanTerms,
            [
                _finalCollAmountReservedForDefault,
                _finalCollAmountReservedForConversions
            ],
            [_arrangerFee, _protocolFee]
        );
    }

    function _checkAndGetCurrRepaymentIdx()
        internal
        view
        returns (uint256 currRepaymentIdx)
    {
        // @dev: currentRepaymentIdx increments on every repay or if all lenders converted in a given period;
        // if and only if loan was fully repaid, then currentRepaymentIdx == _loanTerms.repaymentSchedule.length
        currRepaymentIdx = dynamicData.currentRepaymentIdx;
        if (currRepaymentIdx == _loanTerms.repaymentSchedule.length) {
            revert Errors.LoanIsFullyRepaid();
        }
    }

    function _lenderInOrOutCutoffTime() internal view returns (uint256) {
        return
            dynamicData.loanTermsLockedTime + staticData.unsubscribeGracePeriod;
    }

    function _repaymentScheduleCheck(
        uint256 minTotalSubscriptions,
        DataTypesPeerToPool.Repayment[] memory repaymentSchedule
    ) internal view {
        uint256 repaymentScheduleLen = repaymentSchedule.length;
        if (
            repaymentScheduleLen == 0 ||
            repaymentScheduleLen > Constants.MAX_REPAYMENT_SCHEDULE_LENGTH
        ) {
            revert Errors.InvalidRepaymentScheduleLength();
        }
        // @dev: assuming loan terms are directly locked, then loan can get executed earliest after:
        // block.timestamp + unsubscribeGracePeriod + Constants.LOAN_EXECUTION_GRACE_PERIOD
        if (
            repaymentSchedule[0].dueTimestamp <
            block.timestamp +
                staticData.unsubscribeGracePeriod +
                Constants.LOAN_EXECUTION_GRACE_PERIOD +
                Constants.MIN_TIME_UNTIL_FIRST_DUE_DATE
        ) {
            revert Errors.FirstDueDateTooCloseOrPassed();
        }
        // @dev: the minimum time required between due dates is
        // max{ MIN_TIME_BETWEEN_DUE_DATES, conversion + repayment grace period }
        uint256 minTimeBetweenDueDates = _getConversionAndRepaymentGracePeriod();
        minTimeBetweenDueDates = minTimeBetweenDueDates >
            Constants.MIN_TIME_BETWEEN_DUE_DATES
            ? minTimeBetweenDueDates
            : Constants.MIN_TIME_BETWEEN_DUE_DATES;
        for (uint256 i; i < repaymentScheduleLen; ) {
            if (
                SafeCast.toUint128(
                    (repaymentSchedule[i].loanTokenDue *
                        minTotalSubscriptions) / Constants.BASE
                ) == 0
            ) {
                revert Errors.LoanTokenDueIsZero();
            }
            if (
                i > 0 &&
                repaymentSchedule[i].dueTimestamp <
                repaymentSchedule[i - 1].dueTimestamp + minTimeBetweenDueDates
            ) {
                revert Errors.InvalidDueDates();
            }
            unchecked {
                ++i;
            }
        }
    }

    function _getRepaymentCutoffTime(
        uint256 repaymentIdx
    ) internal view returns (uint256 repaymentCutoffTime) {
        repaymentCutoffTime =
            _loanTerms.repaymentSchedule[repaymentIdx].dueTimestamp +
            _getConversionAndRepaymentGracePeriod();
    }

    function _getConversionAndRepaymentGracePeriod()
        internal
        view
        returns (uint256)
    {
        return
            staticData.conversionGracePeriod + staticData.repaymentGracePeriod;
    }

    function _checkIsAuthorizedSender(address authorizedSender) internal view {
        if (msg.sender != authorizedSender) {
            revert Errors.InvalidSender();
        }
    }

    function _checkIsLender()
        internal
        view
        returns (address fundingPool, uint256 lenderContribution)
    {
        fundingPool = staticData.fundingPool;
        lenderContribution = IFundingPoolImpl(fundingPool).subscriptionAmountOf(
            address(this),
            msg.sender
        );
        if (lenderContribution == 0) {
            revert Errors.InvalidSender();
        }
    }

    function _checkStatus(DataTypesPeerToPool.LoanStatus status) internal view {
        if (dynamicData.status != status) {
            revert Errors.InvalidActionForCurrentStatus();
        }
    }
}