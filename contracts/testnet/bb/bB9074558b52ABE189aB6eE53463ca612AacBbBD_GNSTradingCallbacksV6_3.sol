// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
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
import './PairsStorageInterfaceV6.sol';
pragma solidity ^0.8.7;

interface AggregatorInterfaceV6_2{
    enum OrderType { MARKET_OPEN, MARKET_CLOSE, LIMIT_OPEN, LIMIT_CLOSE, UPDATE_SL }
    function pairsStorage() external view returns(PairsStorageInterfaceV6);
    //function nftRewards() external view returns(NftRewardsInterfaceV6); //6.0有
    function getPrice(uint,OrderType,uint) external returns(uint);
    function tokenPriceDai() external returns(uint);  //6.0有view
    function linkFee(uint,uint) external view returns(uint);
    function tokenDaiReservesLp() external view returns(uint, uint);
    function openFeeP(uint) external view returns(uint);
    function pendingSlOrders(uint) external view returns(PendingSl memory);
    function storePendingSlOrder(uint orderId, PendingSl calldata p) external;
    function unregisterPendingSlOrder(uint orderId) external;
    struct PendingSl{address trader; uint pairIndex; uint index; uint openPrice; bool buy; uint newSl; }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface GNSPairInfosInterfaceV6{
    function maxNegativePnlOnOpenP() external view returns(uint); // PRECISION (%)

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
        uint openInterest // 1e18 (DAI)
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
        uint collateral, // 1e18 (DAI)
        uint leverage
    ) external view returns(uint); // PRECISION

    function getTradeValue(
        address trader,
        uint pairIndex,
        uint index,
        bool long,
        uint collateral,   // 1e18 (DAI)
        uint leverage,
        int percentProfit, // PRECISION (%)
        uint closingFee    // 1e18 (DAI)
    ) external returns(uint amount, uint rolloverFee); // 1e18 (DAI)
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IGToken{
    struct LockedDeposit {
        address owner;
        uint shares;          // 1e18
        uint assetsDeposited; // 1e18
        uint assetsDiscount;  // 1e18
        uint atTimestamp;     // timestamp
        uint lockDuration;    // timestamp
    }

    function sendAssets(uint assets, address receiver) external;
    function receiveAssets(uint assets, address user) external;
    function distributeReward(uint assets) external;

    function currentBalanceDai() external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface NftInterfaceV5{
    function balanceOf(address) external view returns (uint);
    function ownerOf(uint) external view returns (address);
    function transferFrom(address, address, uint) external;
    function tokenOfOwnerByIndex(address, uint) external view returns(uint);
}

// SPDX-License-Identifier: MIT
import './StorageInterfaceV5.sol';
pragma solidity ^0.8.7;

interface NftRewardsInterfaceV6{
    struct TriggeredLimitId{ address trader; uint pairIndex; uint index; StorageInterfaceV5.LimitOrder order; }
    enum OpenLimitOrderType{ LEGACY, REVERSAL, MOMENTUM }
    function storeFirstToTrigger(TriggeredLimitId calldata, address) external;
    function storeTriggerSameBlock(TriggeredLimitId calldata, address) external;
    function unregisterTrigger(TriggeredLimitId calldata) external;
    function distributeNftReward(TriggeredLimitId calldata, uint) external;
    function openLimitOrderTypes(address, uint, uint) external view returns(OpenLimitOrderType);
    function setOpenLimitOrderType(address, uint, uint, OpenLimitOrderType) external;
    function triggered(TriggeredLimitId calldata) external view returns(bool);
    function timedOut(TriggeredLimitId calldata) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface PairsStorageInterfaceV6{
    enum FeedCalculation { DEFAULT, INVERT, COMBINE }    // FEED 1, 1 / (FEED 1), (FEED 1)/(FEED 2)
    struct Feed{ address feed1; address feed2; FeedCalculation feedCalculation; uint maxDeviationP; } // PRECISION (%)
    function incrementCurrentOrderId() external returns(uint);
    function updateGroupCollateral(uint, uint, bool, bool) external;
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
    function pairMinLevPosDai(uint) external view returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface PausableInterfaceV5{
    function isPaused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface PoolInterfaceV5{
    function increaseAccTokensPerLp(uint) external;
}

// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './UniswapRouterInterfaceV5.sol';
import './TokenInterfaceV5.sol';
import './NftInterfaceV5.sol';
import './IGToken.sol';
import './PairsStorageInterfaceV6.sol';
import './PoolInterfaceV5.sol';
import './PausableInterfaceV5.sol';
import './AggregatorInterfaceV6_2.sol';
pragma solidity ^0.8.7;

interface StorageInterfaceV5{
    enum LimitOrder { TP, SL, LIQ, OPEN }
    struct Trader{
        uint leverageUnlocked;
        address referral;
        uint referralRewardsTotal;  // 1e18
    }
    struct Trade{
        address trader;
        uint pairIndex;
        uint index;
        uint initialPosToken;       // 1e18
        uint positionSizeDai;       // 1e18
        uint openPrice;             // PRECISION
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION
        uint sl;                    // PRECISION
    }
    struct TradeInfo{
        uint tokenId;
        uint tokenPriceDai;         // PRECISION
        uint openInterestDai;       // 1e18
        uint tpLastUpdated;
        uint slLastUpdated;
        bool beingMarketClosed;
    }
    struct OpenLimitOrder{
        address trader;
        uint pairIndex;
        uint index;
        uint positionSize;          // 1e18 (DAI or GFARM2)
        uint spreadReductionP;
        bool buy;
        uint leverage;
        uint tp;                    // PRECISION (%)
        uint sl;                    // PRECISION (%)
        uint minPrice;              // PRECISION
        uint maxPrice;              // PRECISION
        uint block;
        uint tokenId;               // index in supportedTokens
    }
    struct PendingMarketOrder{
        Trade trade;
        uint block;
        uint wantedPrice;           // PRECISION
        uint slippageP;             // PRECISION (%)
        uint spreadReductionP;
        uint tokenId;               // index in supportedTokens
    }
    struct PendingNftOrder{
        address nftHolder;
        uint nftId;
        address trader;
        uint pairIndex;
        uint index;
        LimitOrder orderType;
    }
    function PRECISION() external pure returns(uint);
    function gov() external view returns(address);
    function dai() external view returns(IERC20);
    function token() external view returns(TokenInterfaceV5);
    function linkErc677() external view returns(TokenInterfaceV5);
    function tokenDaiRouter() external view returns(UniswapRouterInterfaceV5);
    function priceAggregator() external view returns(AggregatorInterfaceV6_2);
    function vault() external view returns(IGToken);
    function trading() external view returns(address);
    function callbacks() external view returns(address);
    function transferDai(address, address, uint) external;
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
    function spreadReductionsP(uint) external view returns(uint);
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
    function currentPercentProfit(uint,uint,bool,uint) external view returns(int);
    function reqID_pendingNftOrder(uint) external view returns(PendingNftOrder memory);
    function setNftLastSuccess(uint) external;
    function updateTrade(Trade memory) external;
    function nftLastSuccess(uint) external view returns(uint);
    function unregisterPendingNftOrder(uint) external;
    function handleDevGovFees(uint, uint) external returns(uint);
    function distributeLpRewards(uint) external;
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
    function openInterestDai(uint, uint) external view returns(uint);
    function getPendingOrderIds(address) external view returns(uint[] memory);
    function traders(address) external view returns(Trader memory);
    function nfts(uint) external view returns(NftInterfaceV5);
    function fakeBlockNumber() external view returns(uint); // Testing
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface TokenInterfaceV5{
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
pragma solidity ^0.8.7;

interface UniswapRouterInterfaceV5{
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
}

// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import '../interfaces/StorageInterfaceV5.sol';
import '../interfaces/GNSPairInfosInterfaceV6.sol';
import '../interfaces/NftRewardsInterfaceV6.sol';

pragma solidity 0.8.17;

contract GNSTradingCallbacksV6_3 {
    using SafeERC20 for IERC20;

    // Contracts (constant)
    StorageInterfaceV5 public storageT;
    NftRewardsInterfaceV6 public nftRewards;
    GNSPairInfosInterfaceV6 public pairInfos;

    bool public isInitialized;
    // Params (constant)
    uint constant PRECISION = 1e10;  // 10 decimals

    uint constant MAX_SL_P = 75;     // -75% PNL
    uint constant MAX_GAIN_P = 900;  // 900% PnL (10x)

    // Params (adjustable)
    uint public daiVaultFeeP;  // % of closing fee going to DAI vault (eg. 40)
    uint public lpFeeP;        // % of closing fee going to GNS/DAI LPs (eg. 20)
    uint public sssFeeP;       // % of closing fee going to GNS staking (eg. 40)

    // State
    bool public isPaused;  // Prevent opening new trades
    bool public isDone;    // Prevent any interaction with the contract

    // Custom data types
    struct AggregatorAnswer{
        uint orderId;
        uint price;
        uint spreadP;
    }

    // Useful to avoid stack too deep errors
    struct Values{
        uint posDai; 
        uint levPosDai; 
        uint tokenPriceDai; 
        int profitP; 
        uint price;
        uint liqPrice;
        uint daiSentToTrader;
        uint reward1;
        uint reward2;
        uint reward3;
    }

    // Events
    event MarketExecuted(
        uint indexed orderId,
        StorageInterfaceV5.Trade t,
        bool open,
        uint price,
        uint priceImpactP,
        uint positionSizeDai,
        int percentProfit,
        uint daiSentToTrader
    );

    event LimitExecuted(
        uint indexed orderId,
        uint limitIndex,
        StorageInterfaceV5.Trade t,
        address indexed nftHolder,
        StorageInterfaceV5.LimitOrder orderType,
        uint price,
        uint priceImpactP,
        uint positionSizeDai,
        int percentProfit,
        uint daiSentToTrader
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

    event ClosingFeeSharesPUpdated(
        uint daiVaultFeeP,
        uint lpFeeP,
        uint sssFeeP
    );
    
    event Pause(bool paused);
    event Done(bool done);

    event DevGovFeeCharged(address indexed trader, uint valueDai);
    event ClosingRolloverFeeCharged(address indexed trader, uint valueDai);

    function initialize(
        StorageInterfaceV5 _storageT,
        NftRewardsInterfaceV6 _nftRewards,
        GNSPairInfosInterfaceV6 _pairInfos,
        address vaultToApprove,
        uint _daiVaultFeeP,
        uint _lpFeeP,
        uint _sssFeeP
    ) external{
        require(!isInitialized, "GNSTradingCallbacksV6_3: already initialized");
        isInitialized = true;
        require(address(_storageT) != address(0)
            && address(_nftRewards) != address(0)
            && address(_pairInfos) != address(0)
            && _daiVaultFeeP + _lpFeeP + _sssFeeP == 100, "WRONG_PARAMS");

        storageT = _storageT;
        nftRewards = _nftRewards;
        pairInfos = _pairInfos;

        daiVaultFeeP = _daiVaultFeeP;
        lpFeeP = _lpFeeP;
        sssFeeP = _sssFeeP;

        storageT.dai().safeApprove(vaultToApprove, type(uint256).max);
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
    modifier notDone(){
        require(!isDone, "DONE");
        _;
    }

    // Manage params
    function setClosingFeeSharesP(
        uint _daiVaultFeeP,
        uint _lpFeeP,
        uint _sssFeeP
    ) external onlyGov{

        require(_daiVaultFeeP + _lpFeeP + _sssFeeP == 100, "SUM_NOT_100");
        
        daiVaultFeeP = _daiVaultFeeP;
        lpFeeP = _lpFeeP;
        sssFeeP = _sssFeeP;

        emit ClosingFeeSharesPUpdated(_daiVaultFeeP, _lpFeeP, _sssFeeP);
    }

    // Manage state
    function pause() external onlyGov{
        isPaused = !isPaused;

        emit Pause(isPaused); 
    }
    function done() external onlyGov{
        isDone = !isDone;

        emit Done(isDone); 
    }

    // Callbacks
    function openTradeMarketCallback(
        AggregatorAnswer memory a
    ) external onlyPriceAggregator notDone{

        StorageInterfaceV5.PendingMarketOrder memory o = 
            storageT.reqID_pendingMarketOrder(a.orderId);

        if(o.block == 0){ return; }
        
        StorageInterfaceV5.Trade memory t = o.trade;

        (uint priceImpactP, uint priceAfterImpact) = pairInfos.getTradePriceImpact(
            marketExecutionPrice(a.price, a.spreadP, o.spreadReductionP, t.buy),
            t.pairIndex,
            t.buy,
            t.positionSizeDai * t.leverage
        );

        t.openPrice = priceAfterImpact;

        uint maxSlippage = o.wantedPrice * o.slippageP / 100 / PRECISION;

        if(isPaused || a.price == 0
        || (t.buy ?
            t.openPrice > o.wantedPrice + maxSlippage :
            t.openPrice < o.wantedPrice - maxSlippage)
        || (t.tp > 0 && (t.buy ?
            t.openPrice >= t.tp :
            t.openPrice <= t.tp))
        || (t.sl > 0 && (t.buy ?
            t.openPrice <= t.sl :
            t.openPrice >= t.sl))
        || !withinExposureLimits(t.pairIndex, t.buy, t.positionSizeDai, t.leverage)
        || priceImpactP * t.leverage > pairInfos.maxNegativePnlOnOpenP()){

            uint devGovFeesDai = storageT.handleDevGovFees(
                t.pairIndex, 
                t.positionSizeDai * t.leverage
            );

            storageT.transferDai(
                address(storageT),
                t.trader,
                t.positionSizeDai - devGovFeesDai
            );

            emit DevGovFeeCharged(t.trader, devGovFeesDai);

            emit MarketOpenCanceled(
                a.orderId,
                t.trader,
                t.pairIndex
            );

        }else{
            (StorageInterfaceV5.Trade memory finalTrade, uint tokenPriceDai) = registerTrade(
                t, 1500, 0
            );

            emit MarketExecuted(
                a.orderId,
                finalTrade,
                true,
                finalTrade.openPrice,
                priceImpactP,
                finalTrade.initialPosToken * tokenPriceDai / PRECISION,
                0,
                0
            );
        }

        storageT.unregisterPendingMarketOrder(a.orderId, true);
    }

    function closeTradeMarketCallback(
        AggregatorAnswer memory a
    ) external onlyPriceAggregator notDone{
        
        StorageInterfaceV5.PendingMarketOrder memory o = storageT.reqID_pendingMarketOrder(
            a.orderId
        );

        if(o.block == 0){ return; }

        StorageInterfaceV5.Trade memory t = storageT.openTrades(
            o.trade.trader, o.trade.pairIndex, o.trade.index
        );

        if(t.leverage > 0){
            StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(
                t.trader, t.pairIndex, t.index
            );

            AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();
            PairsStorageInterfaceV6 pairsStorage = aggregator.pairsStorage();
            
            Values memory v;

            v.levPosDai = t.initialPosToken * i.tokenPriceDai * t.leverage / PRECISION;
            v.tokenPriceDai = aggregator.tokenPriceDai();

            if(a.price == 0){

                // Dev / gov rewards to pay for oracle cost
                // Charge in DAI if collateral in storage or token if collateral in vault
                v.reward1 = storageT.handleDevGovFees(
                        t.pairIndex,
                        v.levPosDai
                    );

                t.initialPosToken -= v.reward1 * PRECISION / i.tokenPriceDai;
                storageT.updateTrade(t);

                emit DevGovFeeCharged(t.trader, v.reward1);

                emit MarketCloseCanceled(
                    a.orderId,
                    t.trader,
                    t.pairIndex,
                    t.index
                );

            }else{
                v.profitP = currentPercentProfit(t.openPrice, a.price, t.buy, t.leverage);
                v.posDai = v.levPosDai / t.leverage;

                v.daiSentToTrader = unregisterTrade(
                    t,
                    v.profitP,
                    v.posDai,
                    i.openInterestDai / t.leverage,
                    v.levPosDai * pairsStorage.pairCloseFeeP(t.pairIndex) / 100 / PRECISION
                );

                emit MarketExecuted(
                    a.orderId,
                    t,
                    false,
                    a.price,
                    0,
                    v.posDai,
                    v.profitP,
                    v.daiSentToTrader
                );
            }
        }

        storageT.unregisterPendingMarketOrder(a.orderId, false);
    }

    function executeNftOpenOrderCallback(
        AggregatorAnswer memory a
    ) external onlyPriceAggregator notDone{

        StorageInterfaceV5.PendingNftOrder memory n = storageT.reqID_pendingNftOrder(a.orderId);

        if(!isPaused && a.price > 0
        && storageT.hasOpenLimitOrder(n.trader, n.pairIndex, n.index)
        && block.number >= storageT.nftLastSuccess(n.nftId) + storageT.nftSuccessTimelock()){

            StorageInterfaceV5.OpenLimitOrder memory o = storageT.getOpenLimitOrder(
                n.trader, n.pairIndex, n.index
            );

            NftRewardsInterfaceV6.OpenLimitOrderType t = nftRewards.openLimitOrderTypes(
                n.trader, n.pairIndex, n.index
            );

            (uint priceImpactP, uint priceAfterImpact) = pairInfos.getTradePriceImpact(
                marketExecutionPrice(a.price, a.spreadP, o.spreadReductionP, o.buy),
                o.pairIndex,
                o.buy,
                o.positionSize * o.leverage
            );

            a.price = priceAfterImpact;

            if((t == NftRewardsInterfaceV6.OpenLimitOrderType.LEGACY ?
                    (a.price >= o.minPrice && a.price <= o.maxPrice) :
                t == NftRewardsInterfaceV6.OpenLimitOrderType.REVERSAL ?
                    (o.buy ?
                        a.price <= o.maxPrice :
                        a.price >= o.minPrice) :
                    (o.buy ?
                        a.price >= o.minPrice :
                        a.price <= o.maxPrice))
                && withinExposureLimits(o.pairIndex, o.buy, o.positionSize, o.leverage)
                && priceImpactP * o.leverage <= pairInfos.maxNegativePnlOnOpenP()){

                (StorageInterfaceV5.Trade memory finalTrade, uint tokenPriceDai) = registerTrade(
                    StorageInterfaceV5.Trade(
                        o.trader,
                        o.pairIndex,
                        0,
                        0,
                        o.positionSize,
                        t == NftRewardsInterfaceV6.OpenLimitOrderType.REVERSAL ?
                            o.maxPrice : // o.minPrice = o.maxPrice in that case
                            a.price,
                        o.buy,
                        o.leverage,
                        o.tp,
                        o.sl
                    ), 
                    n.nftId,
                    n.index
                );

                storageT.unregisterOpenLimitOrder(o.trader, o.pairIndex, o.index);

                emit LimitExecuted(
                    a.orderId,
                    n.index,
                    finalTrade,
                    n.nftHolder,
                    StorageInterfaceV5.LimitOrder.OPEN,
                    finalTrade.openPrice,
                    priceImpactP,
                    finalTrade.initialPosToken * tokenPriceDai / PRECISION,
                    0,
                    0
                );
            }
        }

        nftRewards.unregisterTrigger(
            NftRewardsInterfaceV6.TriggeredLimitId(n.trader, n.pairIndex, n.index, n.orderType)
        );

        storageT.unregisterPendingNftOrder(a.orderId);
    }

    function executeNftCloseOrderCallback(
        AggregatorAnswer memory a
    ) external onlyPriceAggregator notDone{
        
        StorageInterfaceV5.PendingNftOrder memory o = storageT.reqID_pendingNftOrder(a.orderId);

        StorageInterfaceV5.Trade memory t = storageT.openTrades(
            o.trader, o.pairIndex, o.index
        );

        AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();

        if(a.price > 0 && t.leverage > 0
        && block.number >= storageT.nftLastSuccess(o.nftId) + storageT.nftSuccessTimelock()){

            StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(
                t.trader, t.pairIndex, t.index
            );

            PairsStorageInterfaceV6 pairsStored = aggregator.pairsStorage();
            
            Values memory v;

            v.price =
                pairsStored.guaranteedSlEnabled(t.pairIndex) ?
                    o.orderType == StorageInterfaceV5.LimitOrder.TP ?
                        t.tp : 
                    o.orderType == StorageInterfaceV5.LimitOrder.SL ?
                        t.sl :
                    a.price :
                a.price;

            v.profitP = currentPercentProfit(t.openPrice, v.price, t.buy, t.leverage);
            v.levPosDai = t.initialPosToken * i.tokenPriceDai * t.leverage / PRECISION;
            v.posDai = v.levPosDai / t.leverage;

            if(o.orderType == StorageInterfaceV5.LimitOrder.LIQ){

                v.liqPrice = pairInfos.getTradeLiquidationPrice(
                    t.trader,
                    t.pairIndex,
                    t.index,
                    t.openPrice,
                    t.buy,
                    v.posDai,
                    t.leverage
                );

                // NFT reward in DAI
                v.reward1 = (t.buy ?
                        a.price <= v.liqPrice :
                        a.price >= v.liqPrice
                    ) ?
                        v.posDai * 5 / 100 : 0;

            }else{

                // NFT reward in DAI
                v.reward1 =
                    (o.orderType == StorageInterfaceV5.LimitOrder.TP && t.tp > 0 &&
                        (t.buy ?
                            a.price >= t.tp :
                            a.price <= t.tp)
                    ||
                    o.orderType == StorageInterfaceV5.LimitOrder.SL && t.sl > 0 &&
                        (t.buy ?
                            a.price <= t.sl :
                            a.price >= t.sl)
                    ) ? 1 : 0;
            }

            // If can be triggered
            if(v.reward1 > 0){
                v.tokenPriceDai = aggregator.tokenPriceDai();

                v.daiSentToTrader = unregisterTrade(
                    t,
                    v.profitP,
                    v.posDai,
                    i.openInterestDai / t.leverage,
                    v.levPosDai * pairsStored.pairCloseFeeP(t.pairIndex) / 100 / PRECISION
                );

                // Convert NFT bot fee from DAI to token value
                v.reward2 = 0;

                nftRewards.distributeNftReward(
                    NftRewardsInterfaceV6.TriggeredLimitId(o.trader, o.pairIndex, o.index, o.orderType),
                    v.reward2
                );

                storageT.increaseNftRewards(o.nftId, v.reward2);

                emit LimitExecuted(
                    a.orderId,
                    o.index,
                    t,
                    o.nftHolder,
                    o.orderType,
                    v.price,
                    0,
                    v.posDai,
                    v.profitP,
                    v.daiSentToTrader
                );
            }
        }

        nftRewards.unregisterTrigger(
            NftRewardsInterfaceV6.TriggeredLimitId(o.trader, o.pairIndex, o.index, o.orderType)
        );

        storageT.unregisterPendingNftOrder(a.orderId);
    }

    function updateSlCallback(
        AggregatorAnswer memory a
    ) external onlyPriceAggregator notDone{
        
        AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();
        AggregatorInterfaceV6_2.PendingSl memory o = aggregator.pendingSlOrders(a.orderId);
        
        StorageInterfaceV5.Trade memory t = storageT.openTrades(
            o.trader, o.pairIndex, o.index
        );

        if(t.leverage > 0){
            StorageInterfaceV5.TradeInfo memory i = storageT.openTradesInfo(
                o.trader, o.pairIndex, o.index
            );

            Values memory v;

            v.tokenPriceDai = aggregator.tokenPriceDai();
            v.levPosDai = t.initialPosToken * i.tokenPriceDai * t.leverage / PRECISION / 2;

            // Charge in DAI if collateral in storage or token if collateral in vault
            v.reward1 = t.positionSizeDai > 0 ?
                storageT.handleDevGovFees(
                    t.pairIndex,
                    v.levPosDai
                ) :
                storageT.handleDevGovFees(
                    t.pairIndex,
                    v.levPosDai * PRECISION / v.tokenPriceDai
                ) * v.tokenPriceDai / PRECISION;

            t.initialPosToken -= v.reward1 * PRECISION / i.tokenPriceDai;
            storageT.updateTrade(t);

            emit DevGovFeeCharged(t.trader, v.reward1);

            if(a.price > 0 && t.buy == o.buy && t.openPrice == o.openPrice
            && (t.buy ?
                o.newSl <= a.price :
                o.newSl >= a.price)
            ){
                storageT.updateSl(o.trader, o.pairIndex, o.index, o.newSl);

                emit SlUpdated(
                    a.orderId,
                    o.trader,
                    o.pairIndex,
                    o.index,
                    o.newSl
                );
                
            }else{
                emit SlCanceled(
                    a.orderId,
                    o.trader,
                    o.pairIndex,
                    o.index
                );
            }
        }

        aggregator.unregisterPendingSlOrder(a.orderId);
    }

    // Shared code between market & limit callbacks
    function registerTrade(
        StorageInterfaceV5.Trade memory trade, 
        uint nftId, 
        uint limitIndex
    ) private returns(StorageInterfaceV5.Trade memory, uint){

        AggregatorInterfaceV6_2 aggregator = storageT.priceAggregator();
        PairsStorageInterfaceV6 pairsStored = aggregator.pairsStorage();

        Values memory v;

        v.levPosDai = trade.positionSizeDai * trade.leverage;
        v.tokenPriceDai = aggregator.tokenPriceDai();

        // 2. Charge opening fee - referral fee (if applicable)
        v.reward2 = storageT.handleDevGovFees(trade.pairIndex, v.levPosDai);

        trade.positionSizeDai -= v.reward2;

        emit DevGovFeeCharged(trade.trader, v.reward2);

        // 3.1 Distribute NFT fee and send DAI amount to vault (if applicable)
        if(nftId < 1500){
            // Convert NFT bot fee from DAI to token value
            v.reward3 = 0;

            nftRewards.distributeNftReward(
                NftRewardsInterfaceV6.TriggeredLimitId(
                    trade.trader, trade.pairIndex, limitIndex, StorageInterfaceV5.LimitOrder.OPEN
                ), v.reward3
            );

            storageT.increaseNftRewards(nftId, v.reward3);
        }

        // 4. Set trade final details
        trade.index = storageT.firstEmptyTradeIndex(trade.trader, trade.pairIndex);
        trade.initialPosToken = trade.positionSizeDai * PRECISION / v.tokenPriceDai;

        trade.tp = correctTp(trade.openPrice, trade.leverage, trade.tp, trade.buy);
        trade.sl = correctSl(trade.openPrice, trade.leverage, trade.sl, trade.buy);

        // 5. Call other contracts
        pairInfos.storeTradeInitialAccFees(trade.trader, trade.pairIndex, trade.index, trade.buy);
        pairsStored.updateGroupCollateral(trade.pairIndex, trade.positionSizeDai, trade.buy, true);

        // 6. Store final trade in storage contract
        storageT.storeTrade(
            trade,
            StorageInterfaceV5.TradeInfo(
                0, 
                v.tokenPriceDai, 
                trade.positionSizeDai * trade.leverage,
                0,
                0,
                false
            )
        );

        return (trade, v.tokenPriceDai);
    }

    function unregisterTrade(
        StorageInterfaceV5.Trade memory trade,
        int percentProfit,   // PRECISION
        uint currentDaiPos,  // 1e18
        uint initialDaiPos,  // 1e18
        uint closingFeeDai  // 1e18
    ) private returns(uint daiSentToTrader){
        uint rolloverFee;
        Values memory v;

        // 1. Calculate net PnL (after all closing fees)
        (daiSentToTrader, rolloverFee) = pairInfos.getTradeValue(
            trade.trader,
            trade.pairIndex,
            trade.index,
            trade.buy,
            currentDaiPos,
            trade.leverage,
            percentProfit,
            closingFeeDai
        );

        // 3.1 If collateral in storage (opened after update)
        if(trade.positionSizeDai > 0){

            // 3.1.1 DAI vault reward
            // rollover fee and closing fee to govAddr
            v.reward2 = closingFeeDai * daiVaultFeeP / 100 + rolloverFee;
            storageT.transferDai(address(storageT), storageT.gov(), v.reward2);
            //storageT.vault().distributeReward(v.reward2);
            
            emit ClosingRolloverFeeCharged(trade.trader, v.reward2);

            // 3.1.3 Take DAI from vault if winning trade
            // or send DAI to vault if losing trade
            uint daiLeftInStorage = currentDaiPos - v.reward2;

            if(daiSentToTrader > daiLeftInStorage){
                storageT.vault().sendAssets(daiSentToTrader - daiLeftInStorage, trade.trader);
                storageT.transferDai(address(storageT), trade.trader, daiLeftInStorage);

            }else{
                sendToVault(daiLeftInStorage - daiSentToTrader, trade.trader); // funding fee & reward
                storageT.transferDai(address(storageT), trade.trader, daiSentToTrader);
            }

        // 3.2 If collateral in vault (opened before update)
        }else{
            storageT.vault().sendAssets(daiSentToTrader, trade.trader);
        }

        // 4. Calls to other contracts
        storageT.priceAggregator().pairsStorage().updateGroupCollateral(
            trade.pairIndex, initialDaiPos, trade.buy, false
        );

        // 5. Unregister trade
        storageT.unregisterTrade(trade.trader, trade.pairIndex, trade.index);
    }

    // Utils
    function withinExposureLimits(
        uint pairIndex,
        bool buy,
        uint positionSizeDai,
        uint leverage
    ) private view returns(bool){
        PairsStorageInterfaceV6 pairsStored = storageT.priceAggregator().pairsStorage();
        
        return storageT.openInterestDai(pairIndex, buy ? 0 : 1)
            + positionSizeDai * leverage <= storageT.openInterestDai(pairIndex, 2)
            && pairsStored.groupCollateral(pairIndex, buy)
            + positionSizeDai <= pairsStored.groupMaxCollateral(pairIndex);
    }
    function currentPercentProfit(
        uint openPrice,
        uint currentPrice,
        bool buy,
        uint leverage
    ) private pure returns(int p){
        int maxPnlP = int(MAX_GAIN_P) * int(PRECISION);
        
        p = (buy ?
                int(currentPrice) - int(openPrice) :
                int(openPrice) - int(currentPrice)
            ) * 100 * int(PRECISION) * int(leverage) / int(openPrice);

        p = p > maxPnlP ? maxPnlP : p;
    }
    function correctTp(
        uint openPrice,
        uint leverage,
        uint tp,
        bool buy
    ) private pure returns(uint){
        if(tp == 0
        || currentPercentProfit(openPrice, tp, buy, leverage) == int(MAX_GAIN_P) * int(PRECISION)){

            uint tpDiff = openPrice * MAX_GAIN_P / leverage / 100;

            return buy ? 
                openPrice + tpDiff :
                tpDiff <= openPrice ?
                    openPrice - tpDiff :
                0;
        }
        
        return tp;
    }
    function correctSl(
        uint openPrice,
        uint leverage,
        uint sl,
        bool buy
    ) private pure returns(uint){
        if(sl > 0
        && currentPercentProfit(openPrice, sl, buy, leverage) < int(MAX_SL_P) * int(PRECISION) * -1){

            uint slDiff = openPrice * MAX_SL_P / leverage / 100;

            return buy ?
                openPrice - slDiff :
                openPrice + slDiff;
        }
        
        return sl;
    }
    function marketExecutionPrice(
        uint price,
        uint spreadP,
        uint spreadReductionP,
        bool long
    ) private pure returns (uint){
        uint priceDiff = price * (spreadP - spreadP * spreadReductionP / 100) / 100 / PRECISION;

        return long ?
            price + priceDiff :
            price - priceDiff;
    }

    function sendToVault(uint amountDai, address trader) private{
        storageT.transferDai(address(storageT), address(this), amountDai);
        storageT.vault().receiveAssets(amountDai, trader);
    }
}