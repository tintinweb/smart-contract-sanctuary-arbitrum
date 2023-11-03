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
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../trading-storage/interfaces/IGambitTradingStorageV1.sol";
import "../pair-infos/interfaces/IGambitPairInfosV1.sol";
import "../trading/interfaces/IGambitReferralsV1.sol";
import "../staking/interfaces/IGambitStakingV1.sol";

import "../common/IStableCoinDecimals.sol";

import "../GambitErrorsV1.sol";

import "./GambitTradingCallbacksV1StorageLayout.sol";

/**
 * @dev GambitTradingCallbacksV1Base implements events and modifiers and common functions
 */
abstract contract GambitTradingCallbacksV1Base is
    GambitTradingCallbacksV1StorageLayout
{
    // Custom data types
    struct AggregatorAnswer {
        uint orderId;
        uint price;
        uint conf;
        uint confMultiplierP;
    }

    // Useful to avoid stack too deep errors
    struct Values {
        uint posUsdc; // 1e6 (USDC) or 1e18 (DAI)
        uint levPosUsdc; // 1e6 (USDC) or 1e18 (DAI)
        uint tokenPriceUsdc; // 1e10
        int profitP; // 1e10
        uint price; // 1e10
        uint liqPrice; // 1e10
        uint usdcSentToTrader; // 1e6 (USDC) or 1e18 (DAI)
        uint reward1; // tmp value
        uint reward2; // tmp value
        uint reward3; // tmp value
    }

    // Events
    event MarketExecuted(
        uint indexed orderId,
        IGambitTradingStorageV1.Trade t,
        bool open,
        uint price,
        uint priceImpactP,
        uint positionSizeUsdc,
        int percentProfit,
        uint usdcSentToTrader
    );

    event LimitExecuted(
        uint indexed orderId,
        uint limitIndex,
        IGambitTradingStorageV1.Trade t,
        address indexed nftHolder,
        IGambitTradingStorageV1.LimitOrder orderType,
        uint price,
        uint priceImpactP,
        uint positionSizeUsdc,
        int percentProfit,
        uint usdcSentToTrader
    );

    event MarketOpenCanceled(
        uint indexed orderId,
        address indexed trader,
        uint indexed pairIndex
    );
    event MarketCloseCanceled(
        uint indexed orderId,
        address indexed trader,
        uint indexed pairIndex,
        uint index
    );

    event SlUpdated(
        uint indexed orderId,
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint newSl
    );
    event SlCanceled(
        uint indexed orderId,
        address indexed trader,
        uint indexed pairIndex,
        uint index
    );

    event CollateralRemoved(
        uint indexed orderId,
        address indexed trader,
        uint indexed pairIndex,
        uint index,
        uint amount, // removed collateral amount with fee deducted
        uint newLeverage // updated leverage
    );

    event CollateralRemoveCanceled(
        uint indexed orderId,
        address indexed trader,
        uint indexed pairIndex,
        uint index
    );

    event Pause(bool paused);
    event Done(bool done);

    event ClosingFeeSharesPUpdated(uint usdcVaultFeeP, uint sssFeeP);

    event DevGovFeeCharged(address indexed trader, uint valueUsdc);
    event ReferralFeeCharged(address indexed trader, uint valueUsdc);
    event UsdcVaultFeeCharged(address indexed trader, uint valueUsdc);
    event SssFeeCharged(address indexed trader, uint valueUsdc);

    // Modifiers
    modifier onlyGov() {
        if (msg.sender != storageT.gov()) revert GambitErrorsV1.NotGov();
        _;
    }
    modifier onlyPriceAggregator() {
        if (msg.sender != address(storageT.priceAggregator()))
            revert GambitErrorsV1.NotAggregator();
        _;
    }
    modifier notDone() {
        if (isDone) revert GambitErrorsV1.Done();
        _;
    }

    // Manage params
    function setClosingFeeSharesP(
        uint _usdcVaultFeeP,
        uint _sssFeeP
    ) external onlyGov {
        if (_usdcVaultFeeP + _sssFeeP != 100)
            revert GambitErrorsV1.WrongParams();

        usdcVaultFeeP = _usdcVaultFeeP;
        sssFeeP = _sssFeeP;

        emit ClosingFeeSharesPUpdated(_usdcVaultFeeP, _sssFeeP);
    }

    // Manage state
    function pause() external onlyGov {
        isPaused = !isPaused;

        emit Pause(isPaused);
    }

    function done() external onlyGov {
        isDone = !isDone;

        emit Done(isDone);
    }

    // internal helpers

    // Shared code between market & limit callbacks
    function registerTrade(
        IGambitTradingStorageV1.Trade memory trade,
        uint nftId,
        uint limitIndex
    ) internal returns (IGambitTradingStorageV1.Trade memory, uint) {
        AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();
        IGambitPairsStorageV1 pairsStored = aggregator.pairsStorage();

        Values memory v;

        v.levPosUsdc = (trade.positionSizeUsdc * trade.leverage) / 1e18;
        v.tokenPriceUsdc = aggregator.tokenPriceUsdc();

        // 1. Charge referral fee (if applicable) and send USDC amount to vault
        if (referrals.getTraderReferrer(trade.trader) != address(0)) {
            // Use this variable to store lev pos usdc for dev/gov fees after referral fees
            // and before volumeReferredUsdc increases
            v.posUsdc =
                (v.levPosUsdc *
                    (100 *
                        PRECISION -
                        referrals.getPercentOfOpenFeeP(trade.trader))) /
                100 /
                PRECISION;

            (uint reward, bool enabledUsdcReward) = referrals
                .distributePotentialReward(
                    trade.trader,
                    v.levPosUsdc,
                    pairsStored.pairOpenFeeP(trade.pairIndex),
                    v.tokenPriceUsdc
                );
            // referal fee in USDC
            v.reward1 = reward;

            if (enabledUsdcReward) {
                // Transfer USDC to Referrals contract if referral is rewarded in USDC
                storageT.transferUsdc(
                    address(storageT),
                    address(referrals),
                    v.reward1
                );
            } else {
                // Convert referal fee from USDC to token value
                v.reward2 =
                    (v.reward1 * (10 ** (18 - usdcDecimals())) * PRECISION) /
                    v.tokenPriceUsdc;
                storageT.handleTokens(address(referrals), v.reward2, true);
            }
            trade.positionSizeUsdc -= v.reward1;

            emit ReferralFeeCharged(trade.trader, v.reward1);
        }

        // 2. Charge opening fee - referral fee (if applicable)
        v.reward2 = storageT.handleDevGovFees(
            trade.pairIndex, // _pairIndex
            (v.posUsdc > 0 ? v.posUsdc : v.levPosUsdc), // _leveragedPositionSize
            true // _fullFee
        );

        trade.positionSizeUsdc -= v.reward2;

        emit DevGovFeeCharged(trade.trader, v.reward2);

        // 3. Set trade final details
        trade.index = storageT.firstEmptyTradeIndex(
            trade.trader,
            trade.pairIndex
        );
        trade.initialPosToken =
            (trade.positionSizeUsdc *
                (10 ** (18 - usdcDecimals())) *
                PRECISION) /
            v.tokenPriceUsdc;

        trade.tp = correctTp(
            trade.openPrice,
            trade.leverage,
            trade.tp,
            trade.buy
        );
        trade.sl = correctSl(
            trade.openPrice,
            trade.leverage,
            trade.sl,
            trade.buy
        );

        // 4. Call other contracts
        pairInfos.storeTradeInitialAccFees(
            trade.trader,
            trade.pairIndex,
            trade.index,
            trade.buy
        );
        pairsStored.updateGroupCollateral(
            trade.pairIndex,
            trade.positionSizeUsdc,
            trade.buy,
            true
        );

        // 5. Store final trade in storage contract
        storageT.storeTrade(
            trade,
            IGambitTradingStorageV1.TradeInfo({
                tokenId: 0,
                tokenPriceUsdc: v.tokenPriceUsdc,
                openInterestUsdc: (trade.positionSizeUsdc * trade.leverage) /
                    1e18,
                tpLastUpdated: 0,
                slLastUpdated: 0,
                beingMarketClosed: false
            })
        );

        return (trade, v.tokenPriceUsdc);
    }

    //
    function unregisterTrade(
        IGambitTradingStorageV1.Trade memory trade,
        bool marketOrder,
        int percentProfit, // PRECISION // = currentPercentProfit 아웃풋
        uint currentUsdcPos, // 1e6 (USDC) or 1e18 (DAI) // = v.levPosUsdc / t.leverage
        uint initialUsdcPos, // 1e6 (USDC) or 1e18 (DAI) // = i.openInterestUsdc / t.leverage
        uint closingFeeUsdc, // 1e6 (USDC) or 1e18 (DAI) // = pairsStorage.pairCloseFeeP() 읽어서 가공
        uint tokenPriceUsdc // PRECISION
    ) internal returns (uint usdcSentToTrader) {
        // 1. Calculate net PnL (after all closing fees)
        // 1e6 (USDC) or 1e18 (DAI)
        usdcSentToTrader = pairInfos.getTradeValue(
            trade.trader,
            trade.pairIndex,
            trade.index,
            trade.buy,
            currentUsdcPos,
            trade.leverage,
            percentProfit,
            closingFeeUsdc
        );

        Values memory v;

        // 2.1 Vault reward
        v.reward2 = (closingFeeUsdc * usdcVaultFeeP) / 100;
        storageT.transferUsdc(address(storageT), address(this), v.reward2);
        storageT.vault().distributeReward(v.reward2);

        emit UsdcVaultFeeCharged(trade.trader, v.reward2);

        // 2.2 SSS reward
        v.reward3 = (closingFeeUsdc * sssFeeP) / 100;
        distributeStakingReward(trade.trader, v.reward3);

        // 2.2 Take USDC from vault if winning trade
        // or send USDC to vault if losing trade
        uint usdcLeftInStorage = currentUsdcPos - v.reward2 - v.reward3;

        if (usdcSentToTrader > usdcLeftInStorage) {
            storageT.vault().sendAssets(
                usdcSentToTrader - usdcLeftInStorage,
                trade.trader
            );
            storageT.transferUsdc(
                address(storageT),
                trade.trader,
                usdcLeftInStorage
            );
        } else {
            sendToVault(usdcLeftInStorage - usdcSentToTrader, trade.trader);
            storageT.transferUsdc(
                address(storageT),
                trade.trader,
                usdcSentToTrader
            );
        }

        // 3. Calls to other contracts
        storageT.priceAggregator().pairsStorage().updateGroupCollateral(
            trade.pairIndex,
            initialUsdcPos,
            trade.buy,
            false
        );

        // 4. Unregister trade
        storageT.unregisterTrade(trade.trader, trade.pairIndex, trade.index);
    }

    // Utils
    function currentPercentProfit(
        uint openPrice,
        uint currentPrice,
        bool buy,
        uint leverage
    ) internal pure returns (int p) {
        int maxPnlP = int(MAX_GAIN_P) * int(PRECISION); // 최대 수익 제한

        p =
            ((
                buy
                    ? int(currentPrice) - int(openPrice)
                    : int(openPrice) - int(currentPrice)
            ) *
                100 *
                int(PRECISION) *
                int(leverage)) /
            int(openPrice) /
            1e18;

        p = p > maxPnlP ? maxPnlP : p;
    }

    function correctTp(
        uint openPrice,
        uint leverage,
        uint tp,
        bool buy
    ) internal pure returns (uint) {
        if (
            tp == 0 ||
            currentPercentProfit(openPrice, tp, buy, leverage) ==
            int(MAX_GAIN_P) * int(PRECISION)
        ) {
            uint tpDiff = ((openPrice * MAX_GAIN_P) * 1e18) / leverage / 100;

            return
                buy ? openPrice + tpDiff : tpDiff <= openPrice
                    ? openPrice - tpDiff
                    : 0;
        }

        return tp;
    }

    function correctSl(
        uint openPrice,
        uint leverage,
        uint sl,
        bool buy
    ) internal pure returns (uint) {
        if (
            sl > 0 &&
            currentPercentProfit(openPrice, sl, buy, leverage) <
            int(MAX_SL_P) * int(PRECISION) * -1
        ) {
            uint slDiff = ((openPrice * MAX_SL_P) * 1e18) / leverage / 100;

            return buy ? openPrice - slDiff : openPrice + slDiff;
        }

        return sl;
    }

    function marketExecutionPrice(
        uint price,
        uint conf,
        uint confMultiplierP,
        uint spreadReductionP,
        bool long
    ) internal pure returns (uint) {
        uint priceDiff = (conf *
            (confMultiplierP - (confMultiplierP * spreadReductionP) / 100)) /
            100 /
            PRECISION;

        return long ? price + priceDiff : price - priceDiff;
    }

    function distributeStakingReward(address trader, uint amountUsdc) internal {
        storageT.transferUsdc(address(storageT), address(this), amountUsdc);
        staking.distributeRewardUsdc(amountUsdc);
        emit SssFeeCharged(trader, amountUsdc);
    }

    function sendToVault(uint amountUsdc, address trader) internal {
        storageT.transferUsdc(address(storageT), address(this), amountUsdc);
        storageT.vault().receiveAssets(amountUsdc, trader);
    }

    function usdcDecimals() public pure virtual returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../trading-storage/interfaces/IGambitTradingStorageV1.sol";
import "../pair-infos/interfaces/IGambitPairInfosV1.sol";
import "../trading/interfaces/IGambitReferralsV1.sol";
import "../staking/interfaces/IGambitStakingV1.sol";

import "../common/IStableCoinDecimals.sol";

import "../GambitErrorsV1.sol";

import "./GambitTradingCallbacksV1Base.sol";

/**
 * @dev GambitTradingCallbacksV1Facet1 implements initialize, approveToVault, openTradeMarketCallback, closeTradeMarketCallback
 */
abstract contract GambitTradingCallbacksV1Facet1 is
    GambitTradingCallbacksV1Base
{
    constructor() {
        _disableInitializers();
    }

    function initialize(
        IGambitTradingStorageV1 _storageT,
        NftRewardsInterfaceV6 _nftRewards,
        IGambitPairInfosV1 _pairInfos,
        IGambitReferralsV1 _referrals,
        IGambitStakingV1 _staking,
        uint _usdcVaultFeeP,
        uint _sssFeeP
    ) external initializer {
        if (
            address(_storageT) == address(0) ||
            address(_nftRewards) == address(0) ||
            address(_pairInfos) == address(0) ||
            address(_referrals) == address(0) ||
            address(_staking) == address(0) ||
            _usdcVaultFeeP + _sssFeeP != 100
        ) revert GambitErrorsV1.WrongParams();

        if (
            IERC20MetadataUpgradeable(address(_storageT.usdc())).decimals() !=
            usdcDecimals()
        ) revert GambitErrorsV1.StablecoinDecimalsMismatch();

        storageT = _storageT;
        nftRewards = _nftRewards;
        pairInfos = _pairInfos;
        referrals = _referrals;
        staking = _staking;

        usdcVaultFeeP = _usdcVaultFeeP;
        sssFeeP = _sssFeeP;

        // approve USDC to staking
        SafeERC20Upgradeable.safeApprove(
            IERC20Upgradeable(address(storageT.usdc())),
            address(staking),
            type(uint256).max
        );

        // approve USDC to vault
        approveToVault();
    }

    /// @dev approve callback's USDC to vault. Call this function when
    // vault is changed in GambitTradingStorageV1 contract.
    function approveToVault() public {
        if (!_isInitializing() && msg.sender != storageT.gov())
            revert GambitErrorsV1.NoAuth();
        SafeERC20Upgradeable.forceApprove(
            IERC20Upgradeable(address(storageT.usdc())),
            address(storageT.vault()),
            type(uint256).max
        );
    }

    // Price Aggregator가 가격 취합 후 호출
    // Market Order 대상 콜백
    function openTradeMarketCallback(
        AggregatorAnswer calldata a
    ) external onlyPriceAggregator notDone {
        IGambitTradingStorageV1.PendingMarketOrder memory o = storageT
            .reqID_pendingMarketOrder(a.orderId);

        // 펜딩 데이터 유효한지 확인
        if (o.block == 0) {
            return;
        }

        IGambitTradingStorageV1.Trade memory t = o.trade;

        (uint priceImpactP, uint priceAfterImpact) = pairInfos
            .getTradePriceImpact(
                marketExecutionPrice(
                    a.price,
                    a.conf,
                    a.confMultiplierP,
                    o.spreadReductionP,
                    t.buy
                ),
                t.pairIndex,
                t.buy,
                (t.positionSizeUsdc * t.leverage) / 1e18
            );

        t.openPrice = priceAfterImpact;

        uint maxSlippage = (o.wantedPrice * o.slippageP) / 100 / PRECISION;

        // return `USDC - dev/gov fee` when trade cannot be opened
        if (
            isPaused || // while upgrading callback
            PausableInterfaceV5(storageT.trading()).isPaused() || // while upgrading trading
            a.price == 0 || // when invalid price from pyth network
            (
                t.buy
                    ? t.openPrice > o.wantedPrice + maxSlippage // slippage tolerance 초과
                    : t.openPrice < o.wantedPrice - maxSlippage // slippage tolerance 초과
            ) ||
            (t.tp > 0 && (t.buy ? t.openPrice >= t.tp : t.openPrice <= t.tp)) || // take profit 못하는 경우
            (t.sl > 0 && (t.buy ? t.openPrice <= t.sl : t.openPrice >= t.sl)) || // stop loss 못하는 경우
            !pairInfos.isWithinExposureLimits(
                IGambitPairInfosV1.ExposureCalcParamsStruct({
                    pairIndex: t.pairIndex,
                    buy: t.buy,
                    positionSizeUsdc: t.positionSizeUsdc,
                    leverage: t.leverage,
                    currentPrice: a.price,
                    openPrice: priceAfterImpact
                })
            ) ||
            (priceImpactP * t.leverage) / 1e18 >
            pairInfos.maxNegativePnlOnOpenP() // price impact out of case
        ) {
            uint devGovFeesUsdc = storageT.handleDevGovFees(
                t.pairIndex, // _pairIndex
                (t.positionSizeUsdc * t.leverage) / 1e18, // _leveragedPositionSize
                true // _fullFee
            );

            storageT.transferUsdc(
                address(storageT),
                t.trader,
                t.positionSizeUsdc - devGovFeesUsdc // 수수료 공제
            );

            emit DevGovFeeCharged(t.trader, devGovFeesUsdc);

            emit MarketOpenCanceled(a.orderId, t.trader, t.pairIndex);
        }
        // 조건 맞으니 거래 데이터 저장
        else {
            (
                IGambitTradingStorageV1.Trade memory finalTrade,
                uint tokenPriceUsdc
            ) = registerTrade(t, 1500, 0);

            emit MarketExecuted(
                a.orderId,
                finalTrade,
                true,
                finalTrade.openPrice,
                priceImpactP,
                (finalTrade.initialPosToken * tokenPriceUsdc) /
                    PRECISION /
                    (10 ** (18 - usdcDecimals())),
                0,
                0
            );
        }

        // 펜딩 데이터 삭제
        storageT.unregisterPendingMarketOrder(a.orderId, true);
    }

    function closeTradeMarketCallback(
        AggregatorAnswer calldata a
    ) external onlyPriceAggregator notDone {
        IGambitTradingStorageV1.PendingMarketOrder memory o = storageT
            .reqID_pendingMarketOrder(a.orderId);

        if (o.block == 0) {
            return;
        }

        IGambitTradingStorageV1.Trade memory t = storageT.openTrades(
            o.trade.trader,
            o.trade.pairIndex,
            o.trade.index
        );

        if (t.leverage > 0) {
            IGambitTradingStorageV1.TradeInfo memory i = storageT
                .openTradesInfo(t.trader, t.pairIndex, t.index);

            AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();
            IGambitPairsStorageV1 pairsStorage = aggregator.pairsStorage();

            Values memory v;

            v.levPosUsdc =
                ((t.initialPosToken * i.tokenPriceUsdc * t.leverage) / 1e18) /
                PRECISION /
                (10 ** (18 - usdcDecimals()));
            v.tokenPriceUsdc = aggregator.tokenPriceUsdc();

            // 유효하지 않은 가격 --> 오더 취소
            if (a.price == 0) {
                // Dev / gov rewards to pay for oracle cost
                // Charge in USDC if collateral in storage
                v.reward1 = storageT.handleDevGovFees(
                    t.pairIndex, // _pairIndex
                    v.levPosUsdc, // _leveragedPositionSize
                    true // _fullFee
                );

                t.initialPosToken -=
                    (v.reward1 * (10 ** (18 - usdcDecimals())) * PRECISION) /
                    i.tokenPriceUsdc;
                storageT.updateTrade(t);

                emit DevGovFeeCharged(t.trader, v.reward1);

                emit MarketCloseCanceled(
                    a.orderId,
                    t.trader,
                    t.pairIndex,
                    t.index
                );
            }
            // 유효한 가격 --> 오더 실행
            else {
                // 가능한 수익 계산
                v.profitP = currentPercentProfit(
                    t.openPrice,
                    a.price,
                    t.buy,
                    t.leverage
                );
                v.posUsdc = (v.levPosUsdc * 1e18) / t.leverage;

                v.usdcSentToTrader = unregisterTrade(
                    t, // trade
                    true, // marketOrder
                    v.profitP, // percentProfit
                    v.posUsdc, // currentUsdcPos
                    (i.openInterestUsdc * 1e18) / t.leverage, // initialUsdcPos
                    // closingFeeUsdc
                    (v.levPosUsdc * pairsStorage.pairCloseFeeP(t.pairIndex)) /
                        100 /
                        PRECISION,
                    v.tokenPriceUsdc // tokenPriceUsdc
                );

                emit MarketExecuted(
                    a.orderId,
                    t,
                    false,
                    a.price,
                    0,
                    v.posUsdc,
                    v.profitP,
                    v.usdcSentToTrader
                );
            }
        }

        storageT.unregisterPendingMarketOrder(a.orderId, false);
    }
}

/**
 * @dev GambitTradingCallbacksV1Facet1 with stablecoin decimals set to 6.
 */
contract GambitTradingCallbacksV1Facet1____6 is GambitTradingCallbacksV1Facet1 {
    function usdcDecimals() public pure override returns (uint8) {
        return 6;
    }
}

/**
 * @dev GambitTradingCallbacksV1Facet1 with stablecoin decimals set to 18.
 */
contract GambitTradingCallbacksV1Facet1____18 is
    GambitTradingCallbacksV1Facet1
{
    function usdcDecimals() public pure override returns (uint8) {
        return 18;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../trading-storage/interfaces/IGambitTradingStorageV1.sol";
import "../pair-infos/interfaces/IGambitPairInfosV1.sol";
import "../trading/interfaces/IGambitReferralsV1.sol";
import "../staking/interfaces/IGambitStakingV1.sol";

import "../common/IStableCoinDecimals.sol";

import "../GambitErrorsV1.sol";

contract GambitTradingCallbacksV1StorageLayout is Initializable {
    bytes32[63] private _gap0; // storage slot gap (1 slot for Initializeable)

    // Contracts (constant)
    IGambitTradingStorageV1 public storageT;
    NftRewardsInterfaceV6 public nftRewards;
    IGambitPairInfosV1 public pairInfos;
    IGambitReferralsV1 public referrals;
    IGambitStakingV1 public staking;

    bytes32[59] private _gap1; // storage slot gap (5 slots for above variables)

    // Params (constant)
    uint constant PRECISION = 1e10; // 10 decimals

    uint constant MAX_SL_P = 75; // -75% PNL
    uint constant MAX_GAIN_P = 900; // 900% PnL (10x)

    // Params (adjustable)
    uint public usdcVaultFeeP; // % of closing fee going to USDC vault (eg. 40)
    uint public sssFeeP; // % of closing fee going to CNG staking (eg. 40)

    bytes32[62] private _gap2; // storage slot gap (1 slot for above variable)

    // State
    bool public isPaused; // Prevent opening new trades
    bool public isDone; // Prevent any interaction with the contract

    bytes32[63] private _gap3; // storage slot gap (1 slot for above variable)
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
pragma solidity ^0.8.0;

interface IGambitPairInfosV1 {
    function maxNegativePnlOnOpenP() external view returns (uint); // PRECISION (%)

    function storeTradeInitialAccFees(
        address trader,
        uint pairIndex,
        uint index,
        bool long
    ) external;

    function getTradePriceImpact(
        uint openPrice, // PRECISION
        uint pairIndex,
        bool long,
        uint openInterest // 1e6 (USDC)
    )
        external
        view
        returns (
            uint priceImpactP, // PRECISION (%)
            uint priceAfterImpact // PRECISION
        );

    function getTradeLiquidationPrice(
        address trader,
        uint pairIndex,
        uint index,
        uint openPrice, // PRECISION
        bool long,
        uint collateral, // 1e6 (USDC)
        uint leverage
    ) external view returns (uint); // PRECISION

    function getTradeValue(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // 1e6 (USDC)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint closingFee // 1e6 (USDC)
    ) external returns (uint); // 1e6 (USDC)

    function getOpenPnL(
        uint pairIndex,
        uint currentPrice // 1e10
    ) external view returns (int pnl);

    function getOpenPnLSide(
        uint pairIndex,
        uint currentPrice, // 1e10
        bool buy // true = long, false = short
    ) external view returns (int pnl);

    struct ExposureCalcParamsStruct {
        uint pairIndex;
        bool buy;
        uint positionSizeUsdc;
        uint leverage;
        uint currentPrice; // 1e10
        uint openPrice; // 1e10
    }

    function isWithinExposureLimits(
        ExposureCalcParamsStruct memory params
    ) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGambitPairsStorageV1 {
    enum FeedCalculation {
        DEFAULT,
        INVERT,
        COMBINE
    } // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    struct Feed {
        address feed1;
        address feed2;
        bytes32 priceId1;
        bytes32 priceId2;
        FeedCalculation feedCalculation;
        uint maxDeviationP;
    } // PRECISION (%)

    function updateGroupCollateral(uint, uint, bool, bool) external;

    function pairJob(
        uint
    ) external returns (string memory, string memory, uint);

    function pairFeed(uint) external view returns (Feed memory);

    function pairConfMultiplierP(uint) external view returns (uint);

    function pairMinLeverage(uint) external view returns (uint);

    function pairMaxLeverage(uint) external view returns (uint);

    function groupCollateral(uint, bool) external view returns (uint);

    function guaranteedSlEnabled(uint) external view returns (bool);

    function pairOpenFeeP(uint) external view returns (uint);

    function pairCloseFeeP(uint) external view returns (uint);

    function pairOracleFeeP(uint) external view returns (uint);

    function pairNftLimitOrderFeeP(uint) external view returns (uint);

    function pairReferralFeeP(uint) external view returns (uint);

    function pairMinLevPosUsdc(uint) external view returns (uint);

    function pairsCount() external view returns (uint);

    function pairExposureUtilsP(uint) external view returns (uint);

    function groupMaxCollateralP(uint) external view returns (uint);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGambitStakingV1 {
    function storageT() external view returns (address);

    function token() external view returns (address);

    function usdc() external view returns (address);

    function accUsdcPerToken() external view returns (uint /* 1e18 */);

    function tokenBalance() external view returns (uint /* 1e18 */);

    function distributeRewardUsdc(
        uint amount // 1e6
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../../vault/interfaces/ISimpleGToken.sol";
import "../../pair-storage/interfaces/IGambitPairsStorageV1.sol";

import "./TokenInterfaceV5.sol";
import "./NftInterfaceV5.sol";

interface PausableInterfaceV5 {
    function isPaused() external view returns (bool);
}

interface IGambitTradingStorageV1 {
    enum LimitOrder {
        TP,
        SL,
        LIQ,
        OPEN
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

    function PRECISION() external pure returns (uint);

    function gov() external view returns (address);

    function dev() external view returns (address);

    function usdc() external view returns (IERC20);

    function usdcDecimals() external view returns (uint8);

    function token() external view returns (TokenInterfaceV5);

    function priceAggregator() external view returns (AggregatorInterfaceV6_2);

    function vault() external view returns (ISimpleGToken);

    function trading() external view returns (address);

    function callbacks() external view returns (address);

    function handleTokens(address, uint, bool) external;

    function transferUsdc(address, address, uint) external;

    function unregisterTrade(address, uint, uint) external;

    function unregisterPendingMarketOrder(uint, bool) external;

    function unregisterOpenLimitOrder(address, uint, uint) external;

    function hasOpenLimitOrder(
        address,
        uint,
        uint
    ) external view returns (bool);

    function storePendingMarketOrder(
        PendingMarketOrder memory,
        uint,
        bool
    ) external;

    function openTrades(
        address,
        uint,
        uint
    ) external view returns (Trade memory);

    function openTradesInfo(
        address,
        uint,
        uint
    ) external view returns (TradeInfo memory);

    function updateSl(address, uint, uint, uint) external;

    function updateTp(address, uint, uint, uint) external;

    function getOpenLimitOrder(
        address,
        uint,
        uint
    ) external view returns (OpenLimitOrder memory);

    function spreadReductionsP(uint) external view returns (uint);

    function storeOpenLimitOrder(OpenLimitOrder memory) external;

    function reqID_pendingMarketOrder(
        uint
    ) external view returns (PendingMarketOrder memory);

    function storePendingNftOrder(PendingNftOrder memory, uint) external;

    function updateOpenLimitOrder(OpenLimitOrder calldata) external;

    function reqID_pendingRemoveCollateralOrder(
        uint
    ) external view returns (PendingRemoveCollateralOrder memory);

    function storePendingRemoveCollateralOrder(
        PendingRemoveCollateralOrder memory,
        uint
    ) external;

    function unregisterPendingRemoveCollateralOrder(uint) external;

    function firstEmptyTradeIndex(address, uint) external view returns (uint);

    function firstEmptyOpenLimitIndex(
        address,
        uint
    ) external view returns (uint);

    function increaseNftRewards(uint, uint) external;

    function nftSuccessTimelock() external view returns (uint);

    function reqID_pendingNftOrder(
        uint
    ) external view returns (PendingNftOrder memory);

    function updateTrade(Trade memory) external;

    function nftLastSuccess(uint) external view returns (uint);

    function unregisterPendingNftOrder(uint) external;

    function handleDevGovFees(uint, uint, bool) external returns (uint);

    function getDevGovFees(uint, uint, bool) external view returns (uint);

    function distributeLpRewards(uint) external;

    function storeTrade(Trade memory, TradeInfo memory) external;

    function openLimitOrdersCount(address, uint) external view returns (uint);

    function openTradesCount(address, uint) external view returns (uint);

    function pendingMarketOpenCount(address, uint) external view returns (uint);

    function pendingMarketCloseCount(
        address,
        uint
    ) external view returns (uint);

    function maxTradesPerPair() external view returns (uint);

    function pendingOrderIdsCount(address) external view returns (uint);

    function maxPendingMarketOrders() external view returns (uint);

    function openInterestUsdc(uint, uint) external view returns (uint);

    function openInterestToken(uint, uint) external view returns (uint);

    function getPendingOrderIds(address) external view returns (uint[] memory);

    function nfts(uint) external view returns (NftInterfaceV5);

    function fakeBlockNumber() external view returns (uint); // Testing
}

interface AggregatorInterfaceV6_2 {
    enum OrderType {
        MARKET_OPEN,
        MARKET_CLOSE,
        LIMIT_OPEN,
        LIMIT_CLOSE,
        UPDATE_SL,
        REMOVE_COLLATERAL
    }

    function pyth() external returns (IPyth);

    function PYTH_PRICE_AGE() external returns (uint);

    function pairsStorage() external view returns (IGambitPairsStorageV1);

    function getPrice(uint, OrderType, uint) external returns (uint);

    function fulfill(
        uint orderId,
        bytes[] calldata priceUpdateData
    ) external payable returns (uint256 price, uint256 conf, bool success);

    function tokenPriceUsdc() external returns (uint);

    function openFeeP(uint) external view returns (uint);

    function pendingSlOrders(uint) external view returns (PendingSl memory);

    function storePendingSlOrder(uint orderId, PendingSl calldata p) external;

    function unregisterPendingSlOrder(uint orderId) external;

    struct PendingSl {
        address trader;
        uint pairIndex;
        uint index;
        uint openPrice;
        bool buy;
        uint newSl;
    }
}

interface NftRewardsInterfaceV6 {
    struct TriggeredLimitId {
        address trader;
        uint pairIndex;
        uint index;
        IGambitTradingStorageV1.LimitOrder order;
    }
    enum OpenLimitOrderType {
        LEGACY,
        REVERSAL,
        MOMENTUM
    }

    function storeFirstToTrigger(TriggeredLimitId calldata, address) external;

    function storeTriggerSameBlock(TriggeredLimitId calldata, address) external;

    function unregisterTrigger(TriggeredLimitId calldata) external;

    function distributeNftReward(TriggeredLimitId calldata, uint) external;

    function openLimitOrderTypes(
        address,
        uint,
        uint
    ) external view returns (OpenLimitOrderType);

    function setOpenLimitOrderType(
        address,
        uint,
        uint,
        OpenLimitOrderType
    ) external;

    function triggered(TriggeredLimitId calldata) external view returns (bool);

    function timedOut(TriggeredLimitId calldata) external view returns (bool);
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

interface TokenInterfaceV5 {
    function burn(address, uint256) external;

    function mint(address, uint256) external;

    function transfer(address, uint256) external returns (bool);

    function transferFrom(address, address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function approve(address, uint256) external returns (bool);

    function allowance(address, address) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGambitReferralsV1 {
    function registerPotentialReferrer(
        address trader,
        address referral
    ) external;

    function distributePotentialReward(
        address trader,
        uint volumeUsdc,
        uint pairOpenFeeP,
        uint tokenPriceUsdc
    ) external returns (uint referrerRewardValueUsdc, bool enabledUsdcReward);

    function getPercentOfOpenFeeP(address trader) external view returns (uint);

    function getTraderReferrer(
        address trader
    ) external view returns (address referrer);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISimpleGToken {
    function manager() external view returns (address);

    function gov() external view returns (address);

    function currentEpoch() external view returns (uint);

    function currentEpochStart() external view returns (uint);

    function currentEpochPositiveOpenPnl() external view returns (uint);

    function updateAccPnlPerTokenUsed(
        uint prevPositiveOpenPnl,
        uint newPositiveOpenPnl
    ) external returns (uint);

    function sendAssets(uint assets, address receiver) external;

    function receiveAssets(uint assets, address user) external;

    function distributeReward(uint assets) external;

    function currentBalanceUsdc() external view returns (uint);
}