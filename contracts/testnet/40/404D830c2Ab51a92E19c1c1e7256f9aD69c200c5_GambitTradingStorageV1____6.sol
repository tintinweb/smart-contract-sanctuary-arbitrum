// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
interface IERC20PermitUpgradeable {
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
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function forceApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
    function _callOptionalReturnBool(IERC20Upgradeable token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && AddressUpgradeable.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPythEvents.sol";

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @dev Please refer to the guidance at https://docs.pyth.network/consumers/best-practices for how to consume prices safely.
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(
        bytes32 id
    ) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(
        bytes32 id,
        uint age
    ) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(
        bytes[] calldata updateData
    ) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(
        bytes32 indexed id,
        uint64 publishTime,
        int64 price,
        uint64 conf
    );

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";

interface IGambitPriceAggregatorV1 {
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE,
        REMOVE_COLLATERAL
    }

    function pyth() external returns (IPyth);

    function PYTH_PRICE_AGE() external returns (uint);

    function getPrice(uint, OrderType, uint) external returns (uint);

    function tokenPriceUsdc() external view returns (uint);

    function openFeeP(uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStableCoinDecimals {
    function usdcDecimals() external pure returns (uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library GambitErrorsV1 {
    // msg.sender is not gov
    error NotGov();

    // msg.sender is not manager (GambitPairInfosV1)
    error NotManager();

    // msg.sender is not trading contract
    error NotTrading();

    // msg.sender is not callback contract
    error NotCallbacks();

    // msg.sender is not price aggregator contract
    error NotAggregator();

    error NotTimelockOwner();
    error NotTradingOrCallback();
    error NotNftRewardsOrReferralsOrCallbacks();
    error ZeroAddress();

    // Not authorized
    error NoAuth();

    // contract is not done
    error NotDone();

    // contract is done
    error Done();

    // contract is not paused
    error NotPaused();

    // contract is paused
    error Paused();

    // Wrong parameters
    error WrongParams();

    // Wrong length of array
    error WrongLength();

    // Wrong order of array
    error WrongOrder();

    // unknown group id
    error GroupNotListed();
    // unknown fee id
    error FeeNotListed();
    // unknown pair id
    error PairNotListed();

    error AlreadyListedPair();

    // invalid data for group
    error WrongGroup();
    // invalid data for pair
    error InvalidPair();
    // invalid data for fee
    error WrongFee();
    // invalid data for feed
    error WrongFeed();

    // stablecoin decimals mismatch
    error StablecoinDecimalsMismatch();

    // zero value
    error ZeroValue();

    // same value
    error SameValue();

    // trade errors
    error MaxTradesPerPair();
    error MaxPendingOrders();
    error NoTrade();
    error AboveMaxPos();
    error BelowMinPos();
    error AlreadyBeingClosed();
    error LeverageIncorrect();
    error NoCorrespondingNftSpreadReduction();
    error WrongTp();
    error WrongSl();
    error PriceImpactTooHigh();
    error NoLimit();
    error LimitTimelock();
    error AbovePos();
    error BelowFee();
    error WrongNftType();
    error NoNFT();
    error HasSl();
    error NoSl();
    error NoTp();
    error PriceFeedFailed();
    error WaitTimeout();
    error NotYourOrder();
    error WrongMarketOrderType();

    // address is zero
    error ZeroAdress();

    // pyth caller doesn't have enough balance to pay the fee
    error InsufficientPythFee();

    // value is too high
    error TooHigh();
    // value is too low
    error TooLow();

    // price errors
    error InvalidPrice();
    error InvalidChainlinkPrice();
    error InvalidPythPrice();
    error InvalidPythExpo();

    // nft reward trigger timing error
    error TooLate();
    error TooEarly();
    error SameBlockLimit();
    error NotTriggered();
    error NothingToClaim();

    // referral
    error InvalidTailingZero();
    error RewardUnavailable();

    // trading storage
    error AlreadyAddedToken();
    error NotOpenLimitOrder();

    // SimpleGToken
    error ZeroPrice();
    error PendingWithdrawal();
    error EndOfEpoch();
    error NotAllowed();
    error NotTradingPnlHandler();
    error NotPnlFeed();
    error MaxDailyPnl();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../callback/interfaces/IGambitPriceAggregatorV1.sol";

import "./interfaces/TokenInterfaceV5.sol";
import "./interfaces/NftInterfaceV5.sol";
import "./interfaces/PausableInterfaceV5.sol";

import "../common/IStableCoinDecimals.sol";

import "../GambitErrorsV1.sol";

abstract contract GambitTradingStorageV1 is IStableCoinDecimals, Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32[63] private _gap0; // storage slot gap (1 slot for Initializeable)

    // Constants
    uint public constant PRECISION = 1e10;

    // Contracts (constant)
    IERC20Upgradeable public usdc;

    bytes32[63] private _gap1; // storage slot gap (1 slot for above variable)

    // Contracts (updatable)
    IGambitPriceAggregatorV1 public priceAggregator;
    PausableInterfaceV5 public trading;
    PausableInterfaceV5 public callbacks;
    TokenInterfaceV5 public token; // FIXED: moved to constructor // NOTE: not used now
    NftInterfaceV5[5] public nfts; // FIXED: moved to constructor
    address public treasury; // NOTE: not used now
    address public vault;
    address public tokenDaiRouter;
    address public nftReward;
    address public referrals;

    bytes32[50] private _gap2; // storage slot gap (14 slots for above variables)

    // Params (adjustable)
    uint public maxTradesPerPair; // default: 3
    uint public maxTradesPerBlock; // default: 5
    uint public maxPendingMarketOrders; // default: 5
    uint public maxGainP; // default: 900; // % // DEPRECATED // TODO: remove with slot remaining
    uint public maxSlP; // default: 80; // % // DEPRECATED // TODO: remove with slot remaining
    uint public defaultLeverageUnlocked; // default: 50; // x // DEPRECATED // TODO: remove with slot remaining
    uint public nftSuccessTimelock; // default: 10; // 10 zksync batches
    uint[5] public spreadReductionsP; // default: [0, 0, 0, 0, 0]; // % // FIXED: no spread reduction // TODO: remove

    bytes32[52] private _gap3; // storage slot gap (12 slots for above variables)

    // Gov & dev & timelock addresses (updatable)
    address public timelockOwner; // TimelockController that has full control of updating any address
    address public gov; // FIXED: moved to constructor
    address public dev; // FIXED: moved to constructor

    bytes32[61] private _gap4; // storage slot gap (3 slots for above variables)

    // Gov & dev fees
    uint public devFeesToken; // 1e18 // NOTE: not used now
    uint public devFeesUsdc; // 1e6 (USDC) or 1e18 (DAI)
    uint public govFeesToken; // 1e18 // NOTE: not used now
    uint public govFeesUsdc; // 1e6 (USDC) or 1e18 (DAI)

    bytes32[60] private _gap5; // storage slot gap (4 slots for above variables)

    // Stats
    uint public tokensBurned; // 1e18 (CNG) // NOTE: not used now
    uint public tokensMinted; // 1e18 (CNG) // NOTE: not used now
    uint public nftRewards; // 1e18 (CNG) // NOTE: not used now

    bytes32[61] private _gap6; // storage slot gap (3 slots for above variables)

    // Enums
    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
    }

    // Structs
    struct Trader {
        uint leverageUnlocked;
        address referral;
        uint referralRewardsTotal; // 1e18 // TODO: check it is USDC or CNG
    }

    struct Trade {
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken; // 1e18
        uint positionSizeUsdc; // 1e6 (USDC) or 1e18 (DAI)
        uint openPrice; // PRECISION
        bool buy;
        uint leverage; // 1e18
        uint tp; // PRECISION
        uint sl; // PRECISION
    }

    struct TradeInfo {
        uint tokenId;
        uint tokenPriceUsdc; // PRECISION
        uint openInterestUsdc; // 1e6 (USDC) or 1e18 (DAI)
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder {
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize; // 1e6 (USDC) or 1e18 (DAI)
        uint spreadReductionP;
        bool buy;
        uint leverage; // 1e18
        uint tp; // PRECISION (%)
        uint sl; // PRECISION (%)
        uint minPrice; // PRECISION
        uint maxPrice; // PRECISION
        uint block;
        uint tokenId; // index in supportedTokens
    }
    struct PendingMarketOrder {
        Trade trade;
        uint block;
        uint wantedPrice; // PRECISION
        uint slippageP; // PRECISION (%)
        uint spreadReductionP;
        uint tokenId; // index in supportedTokens
    }
    struct PendingNftOrder {
        address nftHolder;
        uint nftId;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }

    struct PendingRemoveCollateralOrder {
        address trader;
        uint pairIndex;
        uint index;
        uint amount;
        uint openPrice;
        bool buy;
    }

    // Structs for proxy initialization
    struct ContractAddresses {
        IERC20Upgradeable usdc;
        IGambitPriceAggregatorV1 priceAggregator;
        PausableInterfaceV5 trading;
        PausableInterfaceV5 callbacks;
        address treasury;
        address vault;
        address nftReward;
        address referrals;
        address timelockOwner;
        address gov;
        address dev;
    }

    struct Parameters {
        uint maxTradesPerPair;
        uint maxTradesPerBlock;
        uint maxPendingMarketOrders;
        uint maxGainP;
        uint maxSlP;
        uint defaultLeverageUnlocked;
        uint nftSuccessTimelock;
    }

    // Supported tokens to open trades with
    address[] public supportedTokens;
    mapping(address => bool) public isSupportedToken;

    bytes32[62] private _gap7; // storage slot gap (2 slots for above variables)

    // User info mapping
    mapping(address => Trader) public traders;

    bytes32[63] private _gap8; // storage slot gap (1 slot for above variable)

    // Trades mappings
    mapping(address => mapping(uint => mapping(uint => Trade)))
        public openTrades;
    mapping(address => mapping(uint => mapping(uint => TradeInfo)))
        public openTradesInfo;
    mapping(address => mapping(uint => uint)) public openTradesCount;

    bytes32[61] private _gap9; // storage slot gap (3 slots for above variables)

    // Limit orders mappings
    mapping(address => mapping(uint => mapping(uint => uint)))
        public openLimitOrderIds;
    mapping(address => mapping(uint => uint)) public openLimitOrdersCount;
    OpenLimitOrder[] public openLimitOrders;

    bytes32[61] private _gap10; // storage slot gap (3 slots for above variables)

    // Pending orders mappings
    mapping(uint => PendingMarketOrder) public reqID_pendingMarketOrder;
    mapping(uint => PendingNftOrder) public reqID_pendingNftOrder;
    mapping(address => uint[]) public pendingOrderIds;
    mapping(address => mapping(uint => uint)) public pendingMarketOpenCount;
    mapping(address => mapping(uint => uint)) public pendingMarketCloseCount;

    mapping(uint => PendingRemoveCollateralOrder)
        public reqID_pendingRemoveCollateralOrder;
    mapping(address => mapping(uint => uint))
        public pendingRemoveCollateralOrderCount;

    bytes32[57] private _gap11; // storage slot gap (5 slots for above variables)

    // List of open trades & limit orders
    mapping(uint => address[]) public pairTraders;
    mapping(address => mapping(uint => uint)) public pairTradersId;

    bytes32[62] private _gap12; // storage slot gap (2 slots for above variables)

    // Current and max open interests for each pair (= positionSizeUsdc * leverage)
    mapping(uint => uint[3]) public openInterestUsdc; // 1e6 (USDC) or 1e18 (DAI) [long,short,max]

    bytes32[63] private _gap13; // storage slot gap (1 slot for above variable)

    // Current open position size in token for each pair (= positionSizeUsdc * leverage / openPrice)
    // Note that average open price (1e10) for each pair is `(openInterestUsdc * 1e19) / openInterestToken`
    mapping(uint => uint[2]) public openInterestToken; // 1e15 (USDC or DAI) [long,short]

    // Restrictions & Timelocks
    mapping(uint => uint) public tradesPerBlock;

    bytes32[62] private _gap14; // storage slot gap (2 slots for above variables)

    // Events
    event SupportedTokenAdded(address indexed a);
    event AddressUpdated(string name, address a);
    event NftsUpdated(NftInterfaceV5[5] nfts);
    event NumberUpdated(string name, uint value);
    event NumberUpdatedPair(string name, uint indexed pairIndex, uint value);
    event SpreadReductionsUpdated(uint[5]);

    constructor() {
        _disableInitializers();
    }

    function initialize(
        ContractAddresses calldata _contractAddresses,
        Parameters calldata _params,
        NftInterfaceV5[5] calldata _nfts
    ) external initializer {
        if (
            address(_contractAddresses.usdc) == address(0) ||
            address(_contractAddresses.priceAggregator) == address(0) ||
            address(_contractAddresses.trading) == address(0) ||
            address(_contractAddresses.callbacks) == address(0) ||
            _contractAddresses.treasury == address(0) ||
            _contractAddresses.vault == address(0) ||
            _contractAddresses.nftReward == address(0) ||
            _contractAddresses.referrals == address(0) ||
            _contractAddresses.timelockOwner == address(0) ||
            _contractAddresses.gov == address(0) ||
            _contractAddresses.dev == address(0)
        ) revert GambitErrorsV1.ZeroAddress();

        if (
            _params.maxTradesPerPair == 0 ||
            _params.maxTradesPerBlock == 0 ||
            _params.maxPendingMarketOrders == 0 ||
            _params.maxGainP <= 300 ||
            _params.maxSlP <= 50 ||
            _params.defaultLeverageUnlocked == 0
        ) revert GambitErrorsV1.WrongParams();

        if (
            IERC20MetadataUpgradeable(address(_contractAddresses.usdc))
                .decimals() != usdcDecimals()
        ) revert GambitErrorsV1.StablecoinDecimalsMismatch();

        // load contract addresses
        usdc = _contractAddresses.usdc;
        priceAggregator = _contractAddresses.priceAggregator;
        trading = _contractAddresses.trading;
        callbacks = _contractAddresses.callbacks;
        treasury = _contractAddresses.treasury;
        vault = _contractAddresses.vault;
        nftReward = _contractAddresses.nftReward;
        referrals = _contractAddresses.referrals;
        timelockOwner = _contractAddresses.timelockOwner;
        gov = _contractAddresses.gov;
        dev = _contractAddresses.dev;

        // load params
        maxTradesPerPair = _params.maxTradesPerPair;
        maxTradesPerBlock = _params.maxTradesPerBlock;
        maxPendingMarketOrders = _params.maxPendingMarketOrders;
        maxGainP = _params.maxGainP;
        maxSlP = _params.maxSlP;
        defaultLeverageUnlocked = _params.defaultLeverageUnlocked;
        nftSuccessTimelock = _params.nftSuccessTimelock;

        nfts = _nfts;
    }

    // Modifiers
    modifier onlyGov() {
        if (msg.sender != gov) revert GambitErrorsV1.NotGov();
        _;
    }

    modifier onlyTimelockOwner() {
        if (msg.sender != timelockOwner)
            revert GambitErrorsV1.NotTimelockOwner();
        _;
    }
    modifier onlyTrading() {
        if (msg.sender != address(trading)) revert GambitErrorsV1.NotTrading();
        _;
    }
    modifier onlyCallbacks() {
        if (msg.sender != address(callbacks))
            revert GambitErrorsV1.NotCallbacks();
        _;
    }

    modifier onlyTradingOrCallbacks() {
        if (msg.sender != address(trading) && msg.sender != address(callbacks))
            revert GambitErrorsV1.NotTradingOrCallback();
        _;
    }
    modifier onlyNftRewardsOrReferralsOrCallbacks() {
        if (
            msg.sender != address(nftReward) &&
            msg.sender != address(referrals) &&
            msg.sender != address(callbacks)
        ) revert GambitErrorsV1.NotNftRewardsOrReferralsOrCallbacks();
        _;
    }

    modifier nonZeroAddress(address a) {
        if (a == address(0)) revert GambitErrorsV1.ZeroAddress();
        _;
    }

    // Manage addresses
    function setGov(address _gov) external nonZeroAddress(_gov) onlyGov {
        gov = _gov;
        emit AddressUpdated("gov", _gov);
    }

    function setDev(address _dev) external nonZeroAddress(_dev) onlyGov {
        dev = _dev;
        emit AddressUpdated("dev", _dev);
    }

    function updateTimelockOwner(
        address _timelockOwner
    ) external nonZeroAddress(_timelockOwner) onlyTimelockOwner {
        timelockOwner = _timelockOwner;
        emit AddressUpdated("timelockOwner", _timelockOwner);
    }

    function updateToken(
        TokenInterfaceV5 _newToken
    ) external nonZeroAddress(address(_newToken)) onlyTimelockOwner {
        if (!trading.isPaused() || !callbacks.isPaused())
            revert GambitErrorsV1.NotPaused();
        token = _newToken;
        emit AddressUpdated("token", address(_newToken));
    }

    function updateTreasury(
        address _treasury
    ) external nonZeroAddress(_treasury) onlyTimelockOwner {
        treasury = _treasury;
        emit AddressUpdated("treasury", _treasury);
    }

    function updateNftReward(
        address _newValue
    ) external nonZeroAddress(_newValue) onlyTimelockOwner {
        nftReward = _newValue;
        emit AddressUpdated("nftReward", nftReward);
    }

    function updateReferrals(
        address _newValue
    ) external nonZeroAddress(_newValue) onlyTimelockOwner {
        referrals = _newValue;
        emit AddressUpdated("referrals", referrals);
    }

    function updateNfts(
        NftInterfaceV5[5] memory _nfts
    ) external nonZeroAddress(address(_nfts[0])) onlyTimelockOwner {
        nfts = _nfts;
        emit NftsUpdated(_nfts);
    }

    function addSupportedToken(
        address _token
    ) external nonZeroAddress(_token) onlyTimelockOwner {
        if (isSupportedToken[_token]) revert GambitErrorsV1.AlreadyAddedToken();
        supportedTokens.push(_token);
        isSupportedToken[_token] = true;
        emit SupportedTokenAdded(_token);
    }

    function setPriceAggregator(
        address _aggregator
    ) external nonZeroAddress(_aggregator) onlyTimelockOwner {
        priceAggregator = IGambitPriceAggregatorV1(_aggregator);
        emit AddressUpdated("priceAggregator", _aggregator);
    }

    function setVault(
        address _vault
    ) external nonZeroAddress(_vault) onlyTimelockOwner {
        vault = _vault;
        emit AddressUpdated("vault", _vault);
    }

    function setTrading(
        address _trading
    ) external nonZeroAddress(_trading) onlyTimelockOwner {
        trading = PausableInterfaceV5(_trading);
        emit AddressUpdated("trading", _trading);
    }

    function setCallbacks(
        address _callbacks
    ) external nonZeroAddress(_callbacks) onlyTimelockOwner {
        callbacks = PausableInterfaceV5(_callbacks);
        emit AddressUpdated("callbacks", _callbacks);
    }

    // Manage trading variables
    function setMaxTradesPerBlock(uint _maxTradesPerBlock) external onlyGov {
        if (_maxTradesPerBlock == 0) revert GambitErrorsV1.ZeroValue();
        maxTradesPerBlock = _maxTradesPerBlock;
        emit NumberUpdated("maxTradesPerBlock", _maxTradesPerBlock);
    }

    function setMaxTradesPerPair(uint _maxTradesPerPair) external onlyGov {
        if (_maxTradesPerPair == 0) revert GambitErrorsV1.ZeroValue();
        maxTradesPerPair = _maxTradesPerPair;
        emit NumberUpdated("maxTradesPerPair", _maxTradesPerPair);
    }

    function setMaxPendingMarketOrders(
        uint _maxPendingMarketOrders
    ) external onlyGov {
        if (_maxPendingMarketOrders == 0) revert GambitErrorsV1.ZeroValue();
        maxPendingMarketOrders = _maxPendingMarketOrders;
        emit NumberUpdated("maxPendingMarketOrders", _maxPendingMarketOrders);
    }

    function setMaxGainP(uint _max) external onlyGov {
        if (_max < 300) revert GambitErrorsV1.TooLow();
        maxGainP = _max;
        emit NumberUpdated("maxGainP", _max);
    }

    function setDefaultLeverageUnlocked(uint _lev) external onlyGov {
        if (_lev == 0) revert GambitErrorsV1.ZeroValue();
        defaultLeverageUnlocked = _lev;
        emit NumberUpdated("defaultLeverageUnlocked", _lev);
    }

    function setMaxSlP(uint _max) external onlyGov {
        if (_max < 50) revert GambitErrorsV1.TooLow();
        maxSlP = _max;
        emit NumberUpdated("maxSlP", _max);
    }

    function setNftSuccessTimelock(uint _blocks) external onlyGov {
        nftSuccessTimelock = _blocks;
        emit NumberUpdated("nftSuccessTimelock", _blocks);
    }

    function setSpreadReductionsP(uint[5] calldata _r) external onlyGov {
        if (
            _r[0] == 0 ||
            _r[1] <= _r[0] ||
            _r[2] <= _r[1] ||
            _r[3] <= _r[2] ||
            _r[4] <= _r[3]
        ) revert GambitErrorsV1.WrongOrder();
        spreadReductionsP = _r;
        emit SpreadReductionsUpdated(_r);
    }

    function setMaxOpenInterestUsdc(
        uint _pairIndex,
        uint _newMaxOpenInterest
    ) external onlyGov {
        // Can set max open interest to 0 to pause trading on this pair only
        openInterestUsdc[_pairIndex][2] = _newMaxOpenInterest;
        emit NumberUpdatedPair(
            "maxOpenInterestUsdc",
            _pairIndex,
            _newMaxOpenInterest
        );
    }

    // Manage stored trades

    // 콜백에서 호출
    //  - openTradeMarketCallback
    //  - executeNftOpenOrderCallback
    function storeTrade(
        Trade memory _trade,
        TradeInfo memory _tradeInfo
    ) external onlyCallbacks {
        _trade.index = firstEmptyTradeIndex(_trade.trader, _trade.pairIndex);
        openTrades[_trade.trader][_trade.pairIndex][_trade.index] = _trade;

        openTradesCount[_trade.trader][_trade.pairIndex] += 1;
        tradesPerBlock[block.number] += 1;

        if (openTradesCount[_trade.trader][_trade.pairIndex] == 1) {
            pairTradersId[_trade.trader][_trade.pairIndex] = pairTraders[
                _trade.pairIndex
            ].length;
            pairTraders[_trade.pairIndex].push(_trade.trader);
        }

        _tradeInfo.beingMarketClosed = false;
        openTradesInfo[_trade.trader][_trade.pairIndex][
            _trade.index
        ] = _tradeInfo;

        updateOpenInterestUsdc(
            _trade.pairIndex,
            _trade.openPrice,
            _tradeInfo.openInterestUsdc,
            true,
            _trade.buy
        );
    }

    function unregisterTrade(
        address trader,
        uint pairIndex,
        uint index
    ) external onlyCallbacks {
        Trade storage t = openTrades[trader][pairIndex][index];
        TradeInfo storage i = openTradesInfo[trader][pairIndex][index];
        if (t.leverage == 0) {
            return;
        }

        updateOpenInterestUsdc(
            pairIndex,
            t.openPrice,
            i.openInterestUsdc,
            false,
            t.buy
        );

        if (openTradesCount[trader][pairIndex] == 1) {
            uint _pairTradersId = pairTradersId[trader][pairIndex];
            address[] storage p = pairTraders[pairIndex];

            p[_pairTradersId] = p[p.length - 1];
            pairTradersId[p[_pairTradersId]][pairIndex] = _pairTradersId;

            delete pairTradersId[trader][pairIndex];
            p.pop();
        }

        delete openTrades[trader][pairIndex][index];
        delete openTradesInfo[trader][pairIndex][index];

        openTradesCount[trader][pairIndex] -= 1;
        tradesPerBlock[block.number] += 1;
    }

    // Manage pending market orders
    function storePendingMarketOrder(
        PendingMarketOrder memory _order,
        uint _id,
        bool _open
    ) external onlyTrading {
        pendingOrderIds[_order.trade.trader].push(_id);

        reqID_pendingMarketOrder[_id] = _order;
        reqID_pendingMarketOrder[_id].block = block.number;

        if (_open) {
            pendingMarketOpenCount[_order.trade.trader][
                _order.trade.pairIndex
            ] += 1;
        } else {
            pendingMarketCloseCount[_order.trade.trader][
                _order.trade.pairIndex
            ] += 1;
            openTradesInfo[_order.trade.trader][_order.trade.pairIndex][
                _order.trade.index
            ].beingMarketClosed = true;
        }
    }

    function unregisterPendingMarketOrder(
        uint _id,
        bool _open
    ) external onlyTradingOrCallbacks {
        PendingMarketOrder memory _order = reqID_pendingMarketOrder[_id];
        uint[] storage orderIds = pendingOrderIds[_order.trade.trader];

        for (uint i = 0; i < orderIds.length; i++) {
            if (orderIds[i] == _id) {
                if (_open) {
                    pendingMarketOpenCount[_order.trade.trader][
                        _order.trade.pairIndex
                    ] -= 1;
                } else {
                    pendingMarketCloseCount[_order.trade.trader][
                        _order.trade.pairIndex
                    ] -= 1;
                    openTradesInfo[_order.trade.trader][_order.trade.pairIndex][
                        _order.trade.index
                    ].beingMarketClosed = false;
                }

                orderIds[i] = orderIds[orderIds.length - 1];
                orderIds.pop();

                delete reqID_pendingMarketOrder[_id];
                return;
            }
        }
    }

    // Manage open interest
    function updateOpenInterestUsdc(
        uint _pairIndex,
        uint _openPrice, // 1e10
        uint _leveragedPosUsdc, // 1e6 (USDC) or 1e18 (DAI)
        bool _open,
        bool _long
    ) private {
        uint index = _long ? 0 : 1;
        uint[3] storage o = openInterestUsdc[_pairIndex];
        uint[2] storage pt = openInterestToken[_pairIndex]; // 1e15 (USDC or DAI)

        // 1e6 (USDC) or 1e18 (DAI)
        o[index] = _open
            ? o[index] + _leveragedPosUsdc
            : o[index] - _leveragedPosUsdc;

        // 1e19 (USDC) or 1e7 (DAI)
        uint d = 10 ** (25 - usdcDecimals());

        // USDC: 1e15 = 1e6  * "1e19" / 1e10
        // DAI:  1e15 = 1e18 * "1e7"  / 1e10
        pt[index] = _open
            ? pt[index] + (_leveragedPosUsdc * d) / _openPrice
            : pt[index] - (_leveragedPosUsdc * d) / _openPrice;
    }

    // Manage open limit orders
    function storeOpenLimitOrder(OpenLimitOrder memory o) external onlyTrading {
        o.index = firstEmptyOpenLimitIndex(o.trader, o.pairIndex);
        o.block = block.number;
        openLimitOrders.push(o);
        openLimitOrderIds[o.trader][o.pairIndex][o.index] =
            openLimitOrders.length -
            1;
        openLimitOrdersCount[o.trader][o.pairIndex] += 1;
    }

    function updateOpenLimitOrder(
        OpenLimitOrder calldata _o
    ) external onlyTrading {
        if (!hasOpenLimitOrder(_o.trader, _o.pairIndex, _o.index)) {
            return;
        }
        OpenLimitOrder storage o = openLimitOrders[
            openLimitOrderIds[_o.trader][_o.pairIndex][_o.index]
        ];
        o.positionSize = _o.positionSize;
        o.buy = _o.buy;
        o.leverage = _o.leverage;
        o.tp = _o.tp;
        o.sl = _o.sl;
        o.minPrice = _o.minPrice;
        o.maxPrice = _o.maxPrice;
        o.block = block.number;
    }

    function unregisterOpenLimitOrder(
        address _trader,
        uint _pairIndex,
        uint _index
    ) external onlyTradingOrCallbacks {
        if (!hasOpenLimitOrder(_trader, _pairIndex, _index)) {
            return;
        }

        // Copy last order to deleted order => update id of this limit order
        uint id = openLimitOrderIds[_trader][_pairIndex][_index];
        openLimitOrders[id] = openLimitOrders[openLimitOrders.length - 1];
        openLimitOrderIds[openLimitOrders[id].trader][
            openLimitOrders[id].pairIndex
        ][openLimitOrders[id].index] = id;

        // Remove
        delete openLimitOrderIds[_trader][_pairIndex][_index];
        openLimitOrders.pop();

        openLimitOrdersCount[_trader][_pairIndex] -= 1;
    }

    // Manage NFT orders
    function storePendingNftOrder(
        PendingNftOrder memory _nftOrder,
        uint _orderId
    ) external onlyTrading {
        reqID_pendingNftOrder[_orderId] = _nftOrder;
    }

    function unregisterPendingNftOrder(uint _order) external onlyCallbacks {
        delete reqID_pendingNftOrder[_order];
    }

    // Manage RemoveCollateral orders
    function storePendingRemoveCollateralOrder(
        PendingRemoveCollateralOrder memory _removeCollateralOrder,
        uint _orderId
    ) external onlyTrading {
        pendingOrderIds[_removeCollateralOrder.trader].push(_orderId);
        reqID_pendingRemoveCollateralOrder[_orderId] = _removeCollateralOrder;
    }

    function unregisterPendingRemoveCollateralOrder(
        uint _orderId
    ) external onlyCallbacks {
        PendingRemoveCollateralOrder
            memory order = reqID_pendingRemoveCollateralOrder[_orderId];
        uint[] storage orderIds = pendingOrderIds[order.trader];
        uint len = orderIds.length;
        for (uint i = 0; i < len; i++) {
            if (orderIds[i] == _orderId) {
                orderIds[i] = orderIds[len - 1];
                orderIds.pop();
                break;
            }
        }
        delete reqID_pendingRemoveCollateralOrder[_orderId];
    }

    // Manage open trade
    function updateSl(
        address _trader,
        uint _pairIndex,
        uint _index,
        uint _newSl
    ) external onlyTradingOrCallbacks {
        Trade storage t = openTrades[_trader][_pairIndex][_index];
        TradeInfo storage i = openTradesInfo[_trader][_pairIndex][_index];
        if (t.leverage == 0) {
            return;
        }
        t.sl = _newSl;
        i.slLastUpdated = block.number;
    }

    function updateTp(
        address _trader,
        uint _pairIndex,
        uint _index,
        uint _newTp
    ) external onlyTrading {
        Trade storage t = openTrades[_trader][_pairIndex][_index];
        TradeInfo storage i = openTradesInfo[_trader][_pairIndex][_index];
        if (t.leverage == 0) {
            return;
        }
        t.tp = _newTp;
        i.tpLastUpdated = block.number;
    }

    function updateTrade(Trade memory _t) external onlyTradingOrCallbacks {
        // useful when partial adding/closing
        Trade storage t = openTrades[_t.trader][_t.pairIndex][_t.index];
        if (t.leverage == 0) {
            return;
        }
        t.initialPosToken = _t.initialPosToken;
        t.positionSizeUsdc = _t.positionSizeUsdc;
        t.openPrice = _t.openPrice;
        t.leverage = _t.leverage;
    }

    // Manage referrals
    function storeReferral(
        address _trader,
        address _referral
    ) external onlyTrading {
        Trader storage trader = traders[_trader];
        trader.referral = _referral != address(0) &&
            trader.referral == address(0) &&
            _referral != _trader
            ? _referral
            : trader.referral;
    }

    function increaseReferralRewards(
        address _referral,
        uint _amount
    ) external onlyTrading {
        traders[_referral].referralRewardsTotal += _amount;
    }

    // Unlock next leverage
    function setLeverageUnlocked(
        address _trader,
        uint _newLeverage
    ) external onlyTrading {
        traders[_trader].leverageUnlocked = _newLeverage;
    }

    // Manage dev & gov fees
    function handleDevGovFees(
        uint _pairIndex,
        uint _leveragedPositionSize, // 1e6 (USDC) or 1e18 (DAI)
        bool _fullFee // if false, charge a quater of the fee
    )
        external
        onlyCallbacks
        returns (
            uint fee // 1e6 (USDC) or 1e18 (DAI)
        )
    {
        fee = getDevGovFees(_pairIndex, _leveragedPositionSize, _fullFee) / 2;

        govFeesUsdc += fee;
        devFeesUsdc += fee;

        fee = fee * 2;
    }

    function getDevGovFees(
        uint _pairIndex,
        uint _leveragedPositionSize, // 1e6 (USDC) or 1e18 (DAI)
        bool _fullFee // if false, charge a quater of the fee
    )
        public
        view
        returns (
            uint fee // 1e6 (USDC) or 1e18 (DAI)
        )
    {
        fee =
            (_leveragedPositionSize * priceAggregator.openFeeP(_pairIndex)) /
            PRECISION /
            100;
        if (!_fullFee) {
            fee /= 4;
        }

        fee = fee * 2;
    }

    function claimFees() external onlyGov {
        usdc.safeTransfer(gov, govFeesUsdc);
        usdc.safeTransfer(dev, devFeesUsdc);

        devFeesUsdc = 0;
        govFeesUsdc = 0;
    }

    // Manage tokens
    // TODO: after CNG integration, use treasury as an alternative source of CNG (mint/burn)
    function handleTokens(
        address _a,
        uint _amount,
        bool _mint
    ) external onlyNftRewardsOrReferralsOrCallbacks {
        // skip if token is not set yet.
        if (address(token) == address(0)) return;

        if (_mint) {
            tokensMinted += _amount;
            token.mint(_a, _amount);
        } else {
            tokensBurned += _amount;
            token.burn(_a, _amount);
        }
    }

    function transferUsdc(
        address _from,
        address _to,
        uint _amount
    ) external onlyTradingOrCallbacks {
        if (_from == address(this)) {
            usdc.safeTransfer(_to, _amount);
        } else {
            usdc.safeTransferFrom(_from, _to, _amount);
        }
    }

    // View utils functions
    function firstEmptyTradeIndex(
        address trader,
        uint pairIndex
    ) public view returns (uint index) {
        for (uint i = 0; i < maxTradesPerPair; i++) {
            if (openTrades[trader][pairIndex][i].leverage == 0) {
                index = i;
                break;
            }
        }
    }

    function firstEmptyOpenLimitIndex(
        address trader,
        uint pairIndex
    ) public view returns (uint index) {
        for (uint i = 0; i < maxTradesPerPair; i++) {
            if (!hasOpenLimitOrder(trader, pairIndex, i)) {
                index = i;
                break;
            }
        }
    }

    function hasOpenLimitOrder(
        address trader,
        uint pairIndex,
        uint index
    ) public view returns (bool) {
        if (openLimitOrders.length == 0) {
            return false;
        }
        OpenLimitOrder storage o = openLimitOrders[
            openLimitOrderIds[trader][pairIndex][index]
        ];
        return
            o.trader == trader && o.pairIndex == pairIndex && o.index == index;
    }

    // Additional getters
    function getReferral(address _trader) external view returns (address) {
        return traders[_trader].referral;
    }

    function getLeverageUnlocked(address _trader) external view returns (uint) {
        return traders[_trader].leverageUnlocked;
    }

    function pairTradersArray(
        uint _pairIndex
    ) external view returns (address[] memory) {
        return pairTraders[_pairIndex];
    }

    function getPendingOrderIds(
        address _trader
    ) external view returns (uint[] memory) {
        return pendingOrderIds[_trader];
    }

    function pendingOrderIdsCount(
        address _trader
    ) external view returns (uint) {
        return pendingOrderIds[_trader].length;
    }

    function getOpenLimitOrder(
        address _trader,
        uint _pairIndex,
        uint _index
    ) external view returns (OpenLimitOrder memory) {
        if (!hasOpenLimitOrder(_trader, _pairIndex, _index))
            revert GambitErrorsV1.NotOpenLimitOrder();
        return openLimitOrders[openLimitOrderIds[_trader][_pairIndex][_index]];
    }

    function getOpenLimitOrders()
        external
        view
        returns (OpenLimitOrder[] memory)
    {
        return openLimitOrders;
    }

    function getSupportedTokens() external view returns (address[] memory) {
        return supportedTokens;
    }

    function getSpreadReductionsArray() external view returns (uint[5] memory) {
        return spreadReductionsP;
    }

    function usdcDecimals() public pure virtual returns (uint8);
}

/**
 * @dev GambitTradingStorageV1 with stablecoin decimals set to 6.
 */
contract GambitTradingStorageV1____6 is GambitTradingStorageV1 {
    function usdcDecimals() public pure override returns (uint8) {
        return 6;
    }
}

/**
 * @dev GambitTradingStorageV1 with stablecoin decimals set to 18.
 */
contract GambitTradingStorageV1____18 is GambitTradingStorageV1 {
    function usdcDecimals() public pure override returns (uint8) {
        return 18;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface NftInterfaceV5 {
    function balanceOf(address) external view returns (uint);

    function ownerOf(uint) external view returns (address);

    function transferFrom(address, address, uint) external;

    function tokenOfOwnerByIndex(address, uint) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PausableInterfaceV5 {
    function isPaused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface TokenInterfaceV5 {
    function burn(address, uint256) external;

    function mint(address, uint256) external;

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function approve(address, uint256) external returns (bool);

    function allowance(address, address) external view returns (uint256);
}