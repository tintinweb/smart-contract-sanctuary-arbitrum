// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
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
        if (_initialized < type(uint8).max) {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
import './IPairsStorage.sol';
pragma solidity 0.8.17;

interface IAggregator{
    enum OrderType { MARKET_OPEN, MARKET_CLOSE, LIMIT_OPEN, LIMIT_CLOSE, UPDATE_SL, ADL_CLOSE }
    function pairsStorage() external view returns(IPairsStorage);
    function getPrice(uint,OrderType,uint) external returns(uint);
    function batchGetPrice(uint[] calldata,OrderType,uint) external returns(uint);
    function linkFee(uint,uint) external view returns(uint);
    function openFeeP(uint) external view returns(uint);
    function pendingSlOrders(uint) external view returns(PendingSl memory);
    function storePendingSlOrder(uint orderId, PendingSl calldata p) external;
    function unregisterPendingSlOrder(uint orderId) external;
    struct PendingSl{address trader; uint pairIndex; uint index; uint openPrice; bool buy; uint newSl; }
}

// SPDX-License-Identifier: MIT
import './IReferralStorage.sol';

pragma solidity 0.8.17;

interface ICallbacks{
    struct Values{
        uint posUsdt; 
        uint levPosUsdt; 
        int profitP; 
        uint price;
        uint liqPrice;
        uint usdtSentToTrader;
        uint reward1;
        uint reward2;
        uint reward3;
        uint referralSaveFee;
    }

    struct Fees{
        uint rolloverFee;
        int fundingFee;
        uint closingFee;
    }

    struct AggregatorAnswer{ 
        uint orderId; 
        uint price; 
        uint spreadP; 
    }

    function usdtVaultFeeP() external view returns(uint);
    function nftPassSaveFeeP() external view returns(uint);
    function lpFeeP() external view returns(uint);
    function sssFeeP() external view returns(uint);
    function MAX_SL_P() external view returns(uint);
    function MIN_SL_P() external view returns(uint);
    function MAX_GAIN_P() external view returns(uint);
    function MIN_GAIN_P() external view returns(uint);
    function openTradeMarketCallback(AggregatorAnswer memory) external;
    function closeTradeMarketCallback(AggregatorAnswer memory) external;
    function executeNftOpenOrderCallback(AggregatorAnswer memory) external;
    function executeNftCloseOrderCallback(AggregatorAnswer memory) external;
    function updateSlCallback(AggregatorAnswer memory) external;
    function withinExposureLimits(uint, bool, uint, uint) external view returns(bool);
    function callSendToVault(uint, address) external;
    function callVaultSendToTrader     (uint, address ) external;
    function referralStorage() external view returns(IReferralStorage);
    function executionFee() external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IMonthPassNft{
    function paused() external view returns (bool);
    function exists(uint256) external view returns (bool);
    function isUsable(uint256) external view returns (bool);
    function balanceOf(address, uint256 ) external view returns (uint256);
    function isTokenIdExist(uint256) external view returns (bool);
    function isValidTokenId(uint256) external pure returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPairsStorage{
    enum FeedCalculation { DEFAULT, INVERT, COMBINE }    // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    struct Pair{string from; string to; Feed feed; uint spreadP; uint groupIndex; uint feeIndex;}
    struct Feed{ address feed1; address feed2; FeedCalculation feedCalculation; uint maxDeviationP; } // PRECISION (%)
    function updateGroupCollateral(uint, uint, bool, bool) external;
    function pairsCount() external view returns (uint);
    function pairJob(uint) external returns(string memory, string memory, bytes32, uint);
    function pairFeed(uint) external view returns(Feed memory);
    function pairSpreadP(uint) external view returns(uint);
    function pairMinLeverage(uint) external view returns(uint);
    function pairMaxLeverage(uint) external view returns(uint);
    function groupMaxCollateral(uint) external view returns(uint);
    function groupCollateral(uint, bool) external view returns(uint);
    function guaranteedSlEnabled(uint) external view returns(bool);
    function pairOpenFeeP(uint) external view returns(uint);
    function pairCloseFeeP(uint) external view returns(uint);
    function pairOracleFeeP(uint) external view returns(uint);
    function pairNftLimitOrderFeeP(uint) external view returns(uint);
    function pairReferralFeeP(uint) external view returns(uint);
    function pairMinLevPosUsdt(uint) external view returns(uint);
    function pairMaxLevPosUsdt(uint) external view returns(uint);
    function pairMaxGainP(uint) external view returns(uint);
    function getPairs(uint _index) external view returns(Pair memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPausable{
    function isPaused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPEXPairInfos{
    function maxNegativePnlOnOpenP() external view returns(uint); // PRECISION (%)
    function LIQ_THRESHOLD_P() external view returns(uint);

    function storeTradeInitialAccFees(
        address trader,
        uint pairIndex,
        uint index,
        bool long
    ) external;

    function getTradePriceImpact(
        uint openPrice,   // PRECISION
        uint pairIndex,
        bool long,
        uint openInterest // USDT
    ) external view returns(
        uint priceImpactP,      // PRECISION (%)
        uint priceAfterImpact   // PRECISION
    );

   function getTradeLiquidationPrice(
        address trader,
        uint pairIndex,
        uint index,
        uint openPrice,  // PRECISION
        bool long,
        uint collateral, // USDT
        uint leverage
    ) external view returns(uint); // PRECISION

    function getTradeRolloverFee(
        address trader,
        uint pairIndex,
        uint index,
        uint collateral // USDT
    ) external view returns(uint);

    function getTradeFundingFee(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral, // USDT
        uint leverage
    ) external view returns(int);

    function getTradeValue(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral,   // USDT
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint closingFee    // USDT
    ) external returns(uint amount, uint rolloverFee); // USDT

    function adlStoreAccFundingFees(uint pairIndex) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPToken{
    function sendAssets(uint assets, address receiver) external;
    function receiveAssets(uint assets, address user) external;
    function currentBalanceUsdt() external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IReferralStorage {
    function getTraderReferralInfo(
        address _account
    ) external returns (bytes32, address);

    function distributeReferralAndSaveFee(
        address trader,
        uint256 tradeVolume,
        uint256 fee
    ) external returns (uint256 fessSave);

    function claimRebate() external;

    function claimSave() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './ITokenV1.sol';
import './IPToken.sol';
import './IPairsStorage.sol';
import './IPausable.sol';
import './IAggregator.sol';
import './ITradeRegister.sol';
import './IMonthPassNft.sol';

interface IStorageT{
    enum LimitOrder { TP, SL, LIQ, OPEN }
    enum AdlOrder { ADLTP, ADLSL }
    struct Trader{
        uint leverageUnlocked;
        address referral;
        uint referralRewardsTotal;
    }
    struct Trade{
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosUSDT;        // !!! use as if nft used (cause proxy update)
        uint positionSizeUsdt;
        uint openPrice;             // PRECISION
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION
        uint sl;                    // PRECISION
    }
    struct TradeInfo{
        uint openInterestUsdt;
        uint storeTradeBlock;
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder{
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize;
        uint spreadReductionP;
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION (%)
        uint sl;                    // PRECISION (%)
        uint minPrice;              // PRECISION
        uint maxPrice;              // PRECISION
        uint block;
        uint tokenId;               // !!! use as if nft used (cause proxy update)
    }
    struct PendingMarketOrder{
        Trade trade;
        uint block;
        uint wantedPrice;           // PRECISION
        uint slippageP;             // PRECISION (%)
        uint spreadReductionP;
        uint tokenId;               // !!! index in supportedTokens
    }
    struct PendingNftOrder{
        address nftHolder;
        uint nftId;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }
    struct PendingAdlOrder{
        address nftHolder;
        address trader;
        uint pairIndex;
        uint index;
        AdlOrder adlType;
    }
    function PRECISION() external pure returns(uint);
    function gov() external view returns(address);
    function usdt() external view returns(IERC20);
    function token() external view returns(ITokenV1);
    function linkErc677() external view returns(ITokenV1);
    function priceAggregator() external view returns(IAggregator);
    function vault() external view returns(IPToken);
    function trading() external view returns(address);
    function callbacks() external view returns(address);
    function transferUsdt(address, address, uint) external;
    function transferLinkToAggregator(address, uint, uint) external;
    function unregisterTrade(address, uint, uint) external;
    function unregisterPendingMarketOrder(uint, bool) external;
    function unregisterOpenLimitOrder(address, uint, uint) external;
    function hasOpenLimitOrder(address, uint, uint) external view returns(bool);
    function storePendingMarketOrder(PendingMarketOrder memory, uint, bool) external;
    function storeReferral(address, address) external;
    function openTrades(address, uint, uint) external view returns(Trade memory);
    function openTradesInfo(address, uint, uint) external view returns(TradeInfo memory);
    function updateSl(address, uint, uint, uint) external;
    function updateTp(address, uint, uint, uint) external;
    function getOpenLimitOrder(address, uint, uint) external view returns(OpenLimitOrder memory);
    function positionSizeTokenDynamic(uint,uint) external view returns(uint);
    function maxSlP() external view returns(uint);
    function storeOpenLimitOrder(OpenLimitOrder memory) external;
    function reqID_pendingMarketOrder(uint) external view returns(PendingMarketOrder memory);
    function storePendingNftOrder(PendingNftOrder memory, uint) external;
    function updateOpenLimitOrder(OpenLimitOrder calldata) external;
    function firstEmptyTradeIndex(address, uint) external view returns(uint);
    function firstEmptyOpenLimitIndex(address, uint) external view returns(uint);
    function increaseNftRewards(uint, uint) external;
    function nftSuccessTimelock() external view returns(uint);
    function currentPercentProfit(uint,uint,uint,bool,uint) external view returns(int);
    function reqID_pendingNftOrder(uint) external view returns(PendingNftOrder memory);
    function setNftLastSuccess(uint) external;
    function updateTrade(Trade memory) external;
    function nftLastSuccess(uint) external view returns(uint);
    function unregisterPendingNftOrder(uint) external;
    function handleDevGovFees(uint, uint) external view returns(uint);
    function getReferral(address) external view returns(address);
    function increaseReferralRewards(address, uint) external;
    function storeTrade(Trade memory, TradeInfo memory) external;
    function setLeverageUnlocked(address, uint) external;
    function getLeverageUnlocked(address) external view returns(uint);
    function openLimitOrdersCount(address, uint) external view returns(uint);
    function maxOpenLimitOrdersPerPair() external view returns(uint);
    function openTradesCount(address, uint) external view returns(uint);
    function pendingMarketOpenCount(address, uint) external view returns(uint);
    function pendingMarketCloseCount(address, uint) external view returns(uint);
    function maxTradesPerPair() external view returns(uint);
    function maxTradesPerBlock() external view returns(uint);
    function tradesPerBlock(uint) external view returns(uint);
    function pendingOrderIdsCount(address) external view returns(uint);
    function maxPendingMarketOrders() external view returns(uint);
    function maxGainP() external view returns(uint);
    function defaultLeverageUnlocked() external view returns(uint);
    function openInterestUsdt(uint, uint) external view returns(uint);
    function getPendingOrderIds(address) external view returns(uint[] memory);
    function traders(address) external view returns(Trader memory);
    function isBotListed(address) external view returns (bool);
    function increaseUpnlLastId() external;
    function getUpnlLastId() external view returns(uint256);
    function storePendingAdlOrder(PendingAdlOrder memory, uint ) external;
    function adlCallbacks() external view returns(address);
    function adlClosing() external view returns(address);
    function unregisterPendingAdlOrder(uint) external;
    function pendingAdlOrders(uint) external view returns(PendingAdlOrder[] memory);
    function pendingAdlOrdersCount(uint) external view returns(uint);
    function tradeRegister() external view returns(ITradeRegister);
    function monthPassNft() external view returns(IMonthPassNft);
    function handlePlatFormFeeFromNft(address, uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITokenV1{
    function burn(address, uint256) external;
    function mint(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns(bool);
    function balanceOf(address) external view returns(uint256);
    function hasRole(bytes32, address) external view returns (bool);
    function approve(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import './IStorageT.sol';

interface ITradeRegister{
    struct Fees{ uint rolloverFee; int fundingFee; uint closingFee; }
    function registerTrade(IStorageT.Trade memory, uint, uint) external returns (IStorageT.Trade memory);
    function unregisterTrade(IStorageT.Trade memory, int, uint, uint, uint) external returns (uint, Fees memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import '../interfaces/IStorageT.sol';
import '../interfaces/IPEXPairInfos.sol';
import '../interfaces/ICallbacks.sol';
import '../interfaces/IReferralStorage.sol';

contract PEXAdlCallbacksV1_1 is Initializable {
    using SafeERC20 for IERC20;

    // Contracts (constant)
    IStorageT public storageT;
    IPEXPairInfos public pairInfos;
    ICallbacks public callbacks;

    // Params (constant)
    uint constant PRECISION = 1e10;  // 10 decimals

    // Params (adjustable)
    uint public maxProfitP; // max profit position should less than vault usdt balance * maxProfitP
    uint public adlSlUpnlP; // adl loss positions upnl should > adlSlUpnlP

    // State
    bool public isPaused;

    // Custom data types
    struct AggregatorBatchAnswer{
        uint orderId;
        uint[] pairIndices;
        uint[] prices;
        uint[] spreadPs;
    }

    struct AdlConditionInfo {
        IStorageT.PendingAdlOrder[] o;
        uint totalAdlOrderLength;
        uint totalSendToGov;
        uint totalSendToVault;
        uint totalSendToTrader;
    }

    struct Values{
        uint posUsdt; 
        uint levPosUsdt; 
        int profitP; 
        uint price;
        uint usdtSentToTrader;
        uint realSentToTrader;
        uint storageTSentToTrader;
        uint sentToGov;
        bool isVaultToTrader;
    }

    struct UsdtFlowInfo {
        uint vaultSentToTrader;
        uint storageTSentToTrader;
    }

    struct Fees{
        uint rolloverFee;
        int fundingFee;
        uint closingFee;
        uint referralSaveFee;
    }

    // adl pair prices
    mapping (uint => uint) public aggregatorPrices;

    // adl independent traders
    address[] public adlBatchTraders;
    mapping(address => uint) public adlTradesCount;
    mapping(address => UsdtFlowInfo) public adlTradersUsdtFlows;

    // Events
    event Paused(bool isPaused);
    event AddressUpdated(string name, address a);
    event NumberUpdated(string name,uint value);

    event AdlClosingExecuted(
        uint indexed orderId,
        address indexed trader,
        uint adlIndex,
        IStorageT.Trade t,
        address indexed botAddr,
        IStorageT.AdlOrder orderType,
        uint price,
        uint priceImpactP,
        uint positionSizeUsdt,
        int percentProfit,
        uint usdtSentToTrader,
        uint rolloverFee,
        int fundingFee,
        uint fee
    );

    event AdlUsdtFlow(
        uint indexed orderId,
        address indexed botAddr,
        uint totalStorageTSendToGov,
        uint totalStorageTSendToVault,
        uint vaultSendToTrader
    );

    function initialize(
        IStorageT _storageT,
        IPEXPairInfos _pairInfos,
        ICallbacks _callbacks
    ) external initializer{
        require(address(_storageT) != address(0)
            && address(_pairInfos) != address(0)
            && address(_callbacks) != address(0), "WRONG_PARAMS");

        storageT = _storageT;
        pairInfos = _pairInfos;
        callbacks = _callbacks;

        maxProfitP = 50;
        adlSlUpnlP = 50;
    }

    // Modifiers
    modifier onlyGov(){
        require(msg.sender == storageT.gov(), "GOV_ONLY");
        _;
    }
    modifier onlyPriceAggregator(){
        require(msg.sender == address(storageT.priceAggregator()), "AGGREGATOR_ONLY");
        _;
    }
    modifier notPaused(){
        require(!isPaused, "PAUSED");
        _;
    }

    // Manage state
    function paused() external onlyGov{
        isPaused = !isPaused;

        emit Paused(isPaused); 
    }

    // Manage params
    function setPairInfos(address _pairInfos) external onlyGov{
        require(_pairInfos != address(0));
        pairInfos = IPEXPairInfos(_pairInfos);
        emit AddressUpdated("pairInfos", _pairInfos);
    }

    function setCallbacks(address _callbacks) external onlyGov{
        require(_callbacks != address(0));
        callbacks = ICallbacks(_callbacks);
        emit AddressUpdated("callbacks", _callbacks);
    }

    function updateMaxProfitP(uint _maxProfitP) external onlyGov{
        require(_maxProfitP > 0);
        maxProfitP = _maxProfitP;
        emit NumberUpdated("maxProfitP", _maxProfitP);
    }

    function updateAdlSlUpnlP(uint _adlSlUpnlP) external onlyGov{
        require(_adlSlUpnlP > 0);
        adlSlUpnlP = _adlSlUpnlP;
        emit NumberUpdated("adlSlUpnlP", _adlSlUpnlP);
    }

    // Callbacks
    function executeAdlCloseOrderCallback(
        AggregatorBatchAnswer memory a
    ) external onlyPriceAggregator notPaused{

        AdlConditionInfo memory adlConditionInfo;
        Values memory v;

        Fees memory fees;
        IStorageT.Trade memory t;
        IStorageT.TradeInfo memory tradeInfo;

        adlConditionInfo.o = storageT.pendingAdlOrders(a.orderId);
        adlConditionInfo.totalAdlOrderLength = storageT.pendingAdlOrdersCount(a.orderId);

        IAggregator aggregator = storageT.priceAggregator();
        IPairsStorage pairsStorage = aggregator.pairsStorage();

        adlConditionInfo.totalSendToVault = 0;
        adlConditionInfo.totalSendToTrader = 0;
        adlConditionInfo.totalSendToGov = 0;

        // mapping aggregator price
        for(uint i = 0; i < a.pairIndices.length; i++) {
            aggregatorPrices[a.pairIndices[i]] = a.prices[i];
        }

        // loop all adl target positions, and confirm whether adl conditions are satisfied
        // Simultaneously categorize and record positions according to traders, along with their profits and losses.
        for(uint i = 0; i < adlConditionInfo.totalAdlOrderLength; i++) {

            t = storageT.openTrades(
                adlConditionInfo.o[i].trader, adlConditionInfo.o[i].pairIndex, adlConditionInfo.o[i].index
            );

            tradeInfo = storageT.openTradesInfo(
                t.trader, t.pairIndex, t.index
            );

            require(aggregatorPrices[t.pairIndex] > 0, "AggregatorPrice Wrong");
            require(t.leverage > 0, "Leverage Wrong");
            require(uint(adlConditionInfo.o[i].adlType) < 2, "AdlTypes Wrong");


            // get adl position infos
            v.price = aggregatorPrices[t.pairIndex];
            v.profitP = currentPercentProfit(t.pairIndex, t.openPrice, v.price, t.buy, t.leverage);
            v.levPosUsdt = t.positionSizeUsdt * t.leverage;
            v.posUsdt = v.levPosUsdt / t.leverage;

            (v.isVaultToTrader ,v.usdtSentToTrader, v.storageTSentToTrader, v.sentToGov, fees) = getVaultToTradersPure(
                t,
                v.profitP,
                v.posUsdt,
                v.levPosUsdt * pairsStorage.pairCloseFeeP(t.pairIndex) / 100 / PRECISION
            );

            if(v.isVaultToTrader){
                v.realSentToTrader = v.usdtSentToTrader + v.storageTSentToTrader;
            }else {
                v.realSentToTrader = v.storageTSentToTrader;
            }

            uint maxProfitUsdtBalance = storageT.vault().currentBalanceUsdt() * maxProfitP /100;

            // 1.
            // check adl Tp position net pnl > vault usdt balance 50%
            if (adlConditionInfo.o[i].adlType == IStorageT.AdlOrder.ADLTP) {

                if(v.usdtSentToTrader > maxProfitUsdtBalance && v.isVaultToTrader == true ){

                    adlConditionInfo.totalSendToTrader += v.usdtSentToTrader;
                } else {
                    
                    revert("Condition1 Wrong");
                }
            }

            uint newTotalSendToVault;

            // 2.
            // check adl sl position upnl > 50%
            if (adlConditionInfo.o[i].adlType == IStorageT.AdlOrder.ADLSL) {

                if(v.profitP <= -50 && v.isVaultToTrader == false){

                    newTotalSendToVault = adlConditionInfo.totalSendToVault + v.usdtSentToTrader;
                } else {

                    revert("Condition2 Wrong");
                }
            }

            // 3.
            // Determine if the flow of funds from the loss positions to the vault 
            // can just cover (equal to or less than) the actual outflow of funds from the profit positions to users,
            // without exceeding the required position.
            if (newTotalSendToVault <= adlConditionInfo.totalSendToTrader) {

                adlConditionInfo.totalSendToVault = newTotalSendToVault;
            } else {

                // If the sum of new loss positions (trader -> vault) 
                // is still less than or equal to the sum of profit positions (vault -> trader)
                // then add this loss position
                if (newTotalSendToVault - adlConditionInfo.totalSendToTrader <= v.usdtSentToTrader) {

                    adlConditionInfo.totalSendToVault = newTotalSendToVault;
                } else {

                    revert("Condition3 Wrong");
                }
            }

            // calculate same trader positions should be transfered amount
            // To record how many different traders participated in this ADL batch
            adlTradesCount[t.trader]++;
            if(adlTradesCount[t.trader] == 1) {
                adlBatchTraders.push(t.trader);
            }

            // get usdt flow
            // adlConditionInfo.totalSendToVault  // 1. adl loss position total loss collateral send to vault
            adlConditionInfo.totalSendToGov += v.sentToGov; // 2. total fee to gov
            adlTradersUsdtFlows[t.trader].storageTSentToTrader += v.storageTSentToTrader; // 3. adl storageT remain collateral back to user
            if(v.isVaultToTrader){
                adlTradersUsdtFlows[t.trader].vaultSentToTrader += v.usdtSentToTrader; // 4. adl profit positions vault send to trader
            }

            // unregister trades
            // avoid stack too deep
            unregistAndEmit(a, t, tradeInfo, adlConditionInfo.o[i], v, fees);
        }

        // delete aggregator price
        for(uint i = 0; i < a.pairIndices.length; i++) {
            delete aggregatorPrices[a.pairIndices[i]];
        }

        // transfer usdt
        callbacks.callSendToVault(adlConditionInfo.totalSendToVault, adlConditionInfo.o[0].nftHolder); // 1. total loss position collateral from storageT to vault
        storageT.transferUsdt(address(storageT), storageT.gov(), adlConditionInfo.totalSendToGov); // 2. total fee to gov

        for(uint i = 0; i < adlBatchTraders.length; i++) {

            // 3 adl loss or profit postion storageT remain collateral to traders
            if (adlTradersUsdtFlows[adlBatchTraders[i]].storageTSentToTrader > 0) {
                storageT.transferUsdt(address(storageT), adlBatchTraders[i], adlTradersUsdtFlows[adlBatchTraders[i]].storageTSentToTrader);
            }

            // 4. adl profit positions vault to traders
            if (adlTradersUsdtFlows[adlBatchTraders[i]].vaultSentToTrader > 0) {
                callbacks.callVaultSendToTrader(adlTradersUsdtFlows[adlBatchTraders[i]].vaultSentToTrader, adlBatchTraders[i]);
            }

            delete adlTradesCount[adlBatchTraders[i]];
            delete adlTradersUsdtFlows[adlBatchTraders[i]];
        }
        
        delete adlBatchTraders;

        emit AdlUsdtFlow(
            a.orderId,
            adlConditionInfo.o[0].nftHolder,
            adlConditionInfo.totalSendToGov,
            adlConditionInfo.totalSendToVault,
            adlConditionInfo.totalSendToTrader
        );
    }

    //Utils
    function currentPercentProfit(
        uint pairIndex,
        uint openPrice,
        uint currentPrice,
        bool buy,
        uint leverage
    ) private view returns(int p){
        IAggregator aggregator = storageT.priceAggregator();
        IPairsStorage pairsStorage = aggregator.pairsStorage();

        int maxPnlP = int(pairsStorage.pairMaxGainP(pairIndex)) * int(PRECISION);
        p = (buy ?
                int(currentPrice) - int(openPrice) :
                int(openPrice) - int(currentPrice)
            ) * 100 * int(PRECISION) * int(leverage) / int(openPrice);

        p = p > maxPnlP ? maxPnlP : p;
    }

    function eventPercentProfit(
        uint positionSizeUsdt,
        uint usdtSentToTrader
    ) private pure returns(int p){ // PRECISION (%)
        require(positionSizeUsdt > 0, "WRONG_PARAMS");
        int pnl = int(usdtSentToTrader) - int(positionSizeUsdt);
        p = pnl * 100 * int(PRECISION) / int(positionSizeUsdt);
    }

    function getNetPnl(
        int percentProfit,
        uint currentUsdtPos,
        Fees memory fees
    ) private view returns(uint usdtSentToTrader){

        int value = int(currentUsdtPos)
            + int(currentUsdtPos) * percentProfit / int(PRECISION) / 100
            - int(fees.rolloverFee) - fees.fundingFee;

        if(value <= int(currentUsdtPos) * int(100 - pairInfos.LIQ_THRESHOLD_P()) / 100){
            return 0;
        }

        value -= int(fees.closingFee);

        if(value > 0){
            return uint(value);
        }else {
            return 0;
        }
    }

    function getVaultToTradersPure(
        IStorageT.Trade memory trade,
        int percentProfit,
        uint currentUsdtPos,
        uint closingFeeUsdt
    ) private returns(bool isVaultToTrader, uint vaultSentToTrader,uint storageTSentToTrader, uint sentToGov, Fees memory fees){
        pairInfos.adlStoreAccFundingFees(trade.pairIndex);

        fees = getFee(trade, currentUsdtPos, closingFeeUsdt);

        uint usdtSentToTrader = getNetPnl(
            percentProfit,
            currentUsdtPos,
            fees
        );

        sentToGov = fees.closingFee + fees.rolloverFee;
        uint usdtLeftInStorage = currentUsdtPos - sentToGov;

        sentToGov = sentToGov - fees.referralSaveFee;

        if(usdtSentToTrader > usdtLeftInStorage){
            return (true, usdtSentToTrader - usdtLeftInStorage, usdtLeftInStorage, sentToGov, fees);
        } else {
            return (false, usdtLeftInStorage - usdtSentToTrader, usdtSentToTrader, sentToGov, fees);
        }

    }

    // avoid stack too deep
    function getFee(
        IStorageT.Trade memory trade,
        uint currentUsdtPos,
        uint closingFeeUsdt
    ) private returns (Fees memory fees){

        fees.rolloverFee = pairInfos.getTradeRolloverFee(trade.trader, trade.pairIndex, trade.index, currentUsdtPos);
        fees.fundingFee = pairInfos.getTradeFundingFee(trade.trader, trade.pairIndex, trade.index, trade.buy, currentUsdtPos, trade.leverage);

        uint nftSaveP = trade.initialPosUSDT > 0 ? callbacks.nftPassSaveFeeP() : 0;
        fees.closingFee = closingFeeUsdt * callbacks.usdtVaultFeeP() / 100;
        fees.closingFee = fees.closingFee - (fees.closingFee * nftSaveP / PRECISION / 100);

        fees.referralSaveFee = callbacks.referralStorage().distributeReferralAndSaveFee(trade.trader, currentUsdtPos * trade.leverage, fees.closingFee);
    }

    function unregistAndEmit(
        AggregatorBatchAnswer memory a,
        IStorageT.Trade memory t,
        IStorageT.TradeInfo memory tradeInfo,
        IStorageT.PendingAdlOrder memory o,
        Values memory v,
        Fees memory fees
    )private {

        // Calls to other contracts
        storageT.priceAggregator().pairsStorage().updateGroupCollateral(
            t.pairIndex, tradeInfo.openInterestUsdt / t.leverage, t.buy, false
        );

        // Unregister trade
        storageT.unregisterTrade(t.trader, t.pairIndex, t.index);
        storageT.increaseUpnlLastId();

        // emit event
        emit AdlClosingExecuted(
            a.orderId,
            t.trader,
            o.index,
            t,
            o.nftHolder,
            o.adlType,
            v.price,
            0,
            v.posUsdt,
            eventPercentProfit(v.posUsdt, v.realSentToTrader),
            v.realSentToTrader,
            fees.rolloverFee,
            fees.fundingFee,
            fees.closingFee
        );
    }
}