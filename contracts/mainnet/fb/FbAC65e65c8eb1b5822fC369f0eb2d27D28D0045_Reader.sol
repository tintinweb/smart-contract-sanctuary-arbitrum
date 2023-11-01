// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
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

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
library SafeMathUpgradeable {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableMap.sol)

pragma solidity ^0.8.0;

import "./EnumerableSetUpgradeable.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an array of EnumerableMap.
 * ====
 */
library EnumerableMapUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSetUpgradeable.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 * ```
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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../../interfaces/IProxyFactory.sol";

import "./libs/LibGmx.sol";
import "./libs/LibUtils.sol";
import "./Storage.sol";
import "./Debt.sol";
import "./Position.sol";

contract Config is Storage, Debt, Position {
    using LibUtils for bytes32;
    using LibUtils for address;
    using LibUtils for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    function _updateConfigs() internal virtual {
        address token = _account.indexToken;
        (uint32 latestProjectVersion, uint32 latestAssetVersion) = IProxyFactory(_factory).getConfigVersions(
            PROJECT_ID,
            token
        );
        if (_localProjectVersion < latestProjectVersion) {
            _updateProjectConfigs();
            _localProjectVersion = latestProjectVersion;
        }
        // pull configs from factory
        if (_localAssetVersions[token] < latestAssetVersion) {
            _updateAssetConfigs();
            _localAssetVersions[token] = latestAssetVersion;
        }
        _patch();
    }

    function _updateProjectConfigs() internal {
        uint256[] memory values = IProxyFactory(_factory).getProjectConfig(PROJECT_ID);
        require(values.length >= uint256(ProjectConfigIds.END), "MissingConfigs");

        address newPositionRouter = values[uint256(ProjectConfigIds.POSITION_ROUTER)].toAddress();
        address newOrderBook = values[uint256(ProjectConfigIds.ORDER_BOOK)].toAddress();
        _onGmxAddressUpdated(
            _projectConfigs.positionRouter,
            _projectConfigs.orderBook,
            newPositionRouter,
            newOrderBook
        );
        _projectConfigs.vault = values[uint256(ProjectConfigIds.VAULT)].toAddress();
        _projectConfigs.positionRouter = newPositionRouter;
        _projectConfigs.orderBook = newOrderBook;
        _projectConfigs.router = values[uint256(ProjectConfigIds.ROUTER)].toAddress();
        _projectConfigs.referralCode = bytes32(values[uint256(ProjectConfigIds.REFERRAL_CODE)]);
        _projectConfigs.marketOrderTimeoutSeconds = values[uint256(ProjectConfigIds.MARKET_ORDER_TIMEOUT_SECONDS)]
            .toU32();
        _projectConfigs.limitOrderTimeoutSeconds = values[uint256(ProjectConfigIds.LIMIT_ORDER_TIMEOUT_SECONDS)]
            .toU32();
        _projectConfigs.fundingAssetId = values[uint256(ProjectConfigIds.FUNDING_ASSET_ID)].toU8();
    }

    function _onGmxAddressUpdated(
        address previousPositionRouter,
        address previousOrderBook,
        address newPostitionRouter,
        address newOrderBook
    ) internal virtual {
        bool cancelPositionRouter = previousPositionRouter != newPostitionRouter;
        bool cancelOrderBook = previousOrderBook != newOrderBook;
        bytes32[] memory pendingKeys = _pendingOrders.values();
        for (uint256 i = 0; i < pendingKeys.length; i++) {
            bytes32 key = pendingKeys[i];
            if (cancelPositionRouter) {
                LibGmx.cancelOrderFromPositionRouter(previousPositionRouter, key);
                _removePendingOrder(key);
            }
            if (cancelOrderBook) {
                LibGmx.cancelOrderFromOrderBook(previousOrderBook, key);
                _removePendingOrder(key);
            }
        }
    }

    function _updateAssetConfigs() internal {
        uint256[] memory values = IProxyFactory(_factory).getProjectAssetConfig(PROJECT_ID, _account.collateralToken);
        require(values.length >= uint256(TokenConfigIds.END), "MissingConfigs");
        _assetConfigs.boostFeeRate = values[uint256(TokenConfigIds.BOOST_FEE_RATE)].toU32();
        _assetConfigs.initialMarginRate = values[uint256(TokenConfigIds.INITIAL_MARGIN_RATE)].toU32();
        _assetConfigs.maintenanceMarginRate = values[uint256(TokenConfigIds.MAINTENANCE_MARGIN_RATE)].toU32();
        _assetConfigs.liquidationFeeRate = values[uint256(TokenConfigIds.LIQUIDATION_FEE_RATE)].toU32();
        _assetConfigs.referrenceOracle = values[uint256(TokenConfigIds.REFERRENCE_ORACLE)].toAddress();
        _assetConfigs.referenceDeviation = values[uint256(TokenConfigIds.REFERRENCE_ORACLE_DEVIATION)].toU32();
    }

    // TODO: remove me on next deploy
    function _patch() internal {
        if (_account.collateralDecimals == 0) {
            _account.collateralDecimals = IERC20MetadataUpgradeable(_account.collateralToken).decimals();
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../interfaces/ILiquidityPool.sol";
import "../../interfaces/IProxyFactory.sol";

import "./libs/LibGmx.sol";
import "./libs/LibUtils.sol";
import "./Storage.sol";

contract Debt is Storage {
    using LibUtils for uint256;
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    event SetBoostRate(uint256 previousRate, uint256 newRate);
    event SetLiquidityPool(address previousLiquidityPool, address newLiquidityPool);
    event BorrowAsset(
        uint256 amount,
        uint256 boostFee,
        uint256 cumulativeDebt,
        uint256 cumulativeFee,
        uint256 debtEntryFunding
    );
    event RepayAsset(
        uint256 amount,
        uint256 paidDebt,
        uint256 paidFee,
        uint256 boostFee,
        uint256 badDebt,
        uint256 cumulativeDebt,
        uint256 cumulativeFee,
        uint256 debtEntryFunding
    );

    // virtual methods
    function _borrowFromPool(uint256 amount, uint256 fee) internal returns (uint256 amountOut) {
        amountOut = IProxyFactory(_factory).borrowAsset(PROJECT_ID, _account.collateralToken, amount, fee);
    }

    function _repayToPool(
        uint256 amount,
        uint256 fee,
        uint256 badDebt
    ) internal {
        IERC20Upgradeable(_account.collateralToken).safeTransfer(_liquidityPool, amount + fee);
        IProxyFactory(_factory).repayAsset(PROJECT_ID, _account.collateralToken, amount, fee, badDebt);
    }

    // implementations
    function _getBitoroFundingFee() internal view returns (uint256 fundingFee, uint256 newFunding) {
        if (_account.isLong) {
            uint8 assetId = IProxyFactory(_factory).getAssetId(PROJECT_ID, _account.collateralToken);
            if (assetId == VIRTUAL_ASSET_ID) {
                fundingFee = 0;
                newFunding = 0;
            } else {
                ILiquidityPool.Asset memory asset = ILiquidityPool(_liquidityPool).getAssetInfo(assetId);
                newFunding = asset.longCumulativeFundingRate; // 1e18
                fundingFee = ((newFunding - _account.debtEntryFunding) * _account.cumulativeDebt) / 1e18; // collateral.decimal
            }
        } else {
            ILiquidityPool.Asset memory asset = ILiquidityPool(_liquidityPool).getAssetInfo(
                _projectConfigs.fundingAssetId
            );
            newFunding = asset.shortCumulativeFunding;
            address token = ILiquidityPool(_liquidityPool).getAssetAddress(_projectConfigs.fundingAssetId);
            fundingFee =
                (((newFunding - _account.debtEntryFunding) * _account.cumulativeDebt) * 1e12) /
                LibGmx.getOraclePrice(_projectConfigs, token, false); // collateral.decimal
        }
    }

    function _updateBitoroFundingFee() internal returns (uint256) {
        (uint256 fundingFee, uint256 newFunding) = _getBitoroFundingFee();
        _account.cumulativeFee += fundingFee;
        _account.debtEntryFunding = newFunding;
        return fundingFee;
    }

    function _borrowCollateral(uint256 toBorrow) internal returns (uint256 borrowed, uint256 paidFee) {
        _updateBitoroFundingFee();
        uint256 boostFee = toBorrow.rate(_assetConfigs.boostFeeRate);
        borrowed = toBorrow - boostFee;
        paidFee = boostFee;
        _borrowFromPool(toBorrow, boostFee);
        _account.cumulativeDebt += toBorrow;
        emit BorrowAsset(
            toBorrow,
            boostFee,
            _account.cumulativeDebt,
            _account.cumulativeFee,
            _account.debtEntryFunding
        );
    }

    function _partialRepayCollateral(uint256 borrow, uint256 balance)
        internal
        returns (
            uint256 toUser,
            uint256 toRepay,
            uint256 fee
        )
    {
        _updateBitoroFundingFee();

        toUser = balance;
        toRepay = _account.cumulativeDebt.min(borrow);
        require(balance >= toRepay, "InsufficientBalance");
        fee = toRepay.rate(_assetConfigs.boostFeeRate);
        _account.cumulativeDebt -= toRepay;
        toUser -= toRepay;
        if (toUser >= fee) {
            toUser -= fee;
        } else {
            _account.cumulativeFee += fee;
        }
        _repayToPool(toRepay, fee, 0);
        emit RepayAsset(
            balance,
            toRepay,
            fee,
            fee,
            0,
            _account.cumulativeDebt,
            _account.cumulativeFee,
            _account.debtEntryFunding
        );
    }

    function _repayCollateral(uint256 balance, uint256 inflightBorrow)
        internal
        returns (
            uint256 remain,
            uint256 toRepay,
            uint256 fee
        )
    {
        _updateBitoroFundingFee();
        toRepay = _account.cumulativeDebt - inflightBorrow;
        uint256 boostFee = toRepay.rate(_assetConfigs.boostFeeRate);
        fee = boostFee + _account.cumulativeFee;
        remain = balance;
        // 1. pay the debt, missing part will be turned into bad debt
        toRepay = toRepay.min(remain);
        remain -= toRepay;
        // 2. pay the fee, if possible
        fee = fee.min(remain);
        remain -= fee;
        uint256 badDebt = _account.cumulativeDebt - inflightBorrow - toRepay;
        // cumulativeDebt - inflightBorrow = paidDebt - badDebt
        _account.cumulativeDebt = inflightBorrow;
        _account.cumulativeFee = 0;
        _repayToPool(toRepay, fee, badDebt);

        emit RepayAsset(
            balance,
            toRepay,
            fee,
            boostFee,
            badDebt,
            _account.cumulativeDebt,
            _account.cumulativeFee,
            _account.debtEntryFunding
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../../interfaces/IGmxRouter.sol";
import "../../interfaces/ILiquidityPool.sol";
import "../../interfaces/IProxyFactory.sol";
import "../../components/ImplementationGuard.sol";

import "./libs/LibGmx.sol";
import "./libs/LibOracle.sol";

import "./Type.sol";
import "./Storage.sol";
import "./Config.sol";
import "./Debt.sol";
import "./Position.sol";

contract GmxAdapter is Storage, Debt, Position, Config, ReentrancyGuardUpgradeable, ImplementationGuard {
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.Bytes32ToBytes32Map;

    // bitoro flags
    uint8 constant POSITION_MARKET_ORDER = 0x40;
    uint8 constant POSITION_TPSL_ORDER = 0x08;

    address internal immutable _WETH;

    event Withdraw(
        uint256 cumulativeDebt,
        uint256 cumulativeFee,
        bool isLiquidation,
        uint256 balance,
        uint256 userWithdrawal,
        uint256 paidDebt,
        uint256 paidFee
    );

    constructor(address weth) ImplementationGuard() {
        _WETH = weth;
    }

    receive() external payable {}

    modifier onlyTraderOrFactory() {
        require(msg.sender == _account.account || msg.sender == _factory, "OnlyTraderOrFactory");
        _;
    }

    modifier onlyKeeperOrFactory() {
        require(IProxyFactory(_factory).isKeeper(msg.sender) || msg.sender == _factory, "onlyKeeper");
        _;
    }

    function initialize(
        uint256 projectId,
        address liquidityPool,
        address account,
        address collateralToken,
        address assetToken,
        bool isLong
    ) external initializer onlyDelegateCall {
        require(liquidityPool != address(0), "InvalidLiquidityPool");
        require(projectId == PROJECT_ID, "InvalidProject");

        _factory = msg.sender;
        _liquidityPool = liquidityPool;
        _gmxPositionKey = keccak256(abi.encodePacked(address(this), collateralToken, assetToken, isLong));
        _account.account = account;
        _account.collateralToken = collateralToken;
        _account.indexToken = assetToken;
        _account.isLong = isLong;
        _account.collateralDecimals = IERC20MetadataUpgradeable(collateralToken).decimals();
        _updateConfigs();
    }

    function debtStates()
        external
        view
        returns (uint256 cumulativeDebt, uint256 cumulativeFee, uint256 debtEntryFunding)
    {
        cumulativeDebt = _account.cumulativeDebt;
        cumulativeFee = _account.cumulativeFee;
        debtEntryFunding = _account.debtEntryFunding;
    }

    function bitoroAccountState() external view returns (AccountState memory) {
        return _account;
    }

    function getPendingGmxOrderKeys() external view returns (bytes32[] memory) {
        return _getPendingOrders();
    }

    function getTpslOrderKeys(bytes32 orderKey) external view returns (bytes32, bytes32) {
        return _getTpslOrderIndexes(orderKey);
    }

    /// @notice Place a openning request on GMX.
    /// - market order => positionRouter
    /// - limit order => orderbook
    /// token: swapInToken(swapInAmount) => _account.collateralToken => _account.indexToken.
    function openPosition(
        address swapInToken,
        uint256 swapInAmount, // tokenIn.decimals
        uint256 minSwapOut, // collateral.decimals
        uint256 borrow, // collateral.decimals
        uint256 sizeUsd, // 1e18
        uint96 priceUsd, // 1e18
        uint96 tpPriceUsd,
        uint96 slPriceUsd,
        uint8 flags // MARKET, TRIGGER
    ) external payable onlyTraderOrFactory nonReentrant {
        require(!_account.isLiquidating, "TradeForbidden");

        _updateConfigs();
        _tryApprovePlugins();
        _cleanOrders();

        bytes32 orderKey;
        orderKey = _openPosition(
            swapInToken,
            swapInAmount, // tokenIn.decimals
            minSwapOut, // collateral.decimals
            borrow, // collateral.decimals
            sizeUsd, // 1e18
            priceUsd, // 1e18
            flags // MARKET, TRIGGER
        );

        if (flags & POSITION_TPSL_ORDER > 0) {
            bytes32 tpOrderKey;
            bytes32 slOrderKey;
            if (tpPriceUsd > 0) {
                tpOrderKey = _closePosition(0, sizeUsd, tpPriceUsd, 0);
            }
            if (slPriceUsd > 0) {
                slOrderKey = _closePosition(0, sizeUsd, slPriceUsd, 0);
            }
            _openTpslOrderIndexes.set(orderKey, LibGmx.encodeTpslIndex(tpOrderKey, slOrderKey));
        }
    }

    function _openPosition(
        address swapInToken,
        uint256 swapInAmount, // tokenIn.decimals
        uint256 minSwapOut, // collateral.decimals
        uint256 borrow, // collateral.decimals
        uint256 sizeUsd, // 1e18
        uint96 priceUsd, // 1e18
        uint8 flags // MARKET, TRIGGER
    ) internal returns (bytes32 orderKey) {
        require(!_account.isLiquidating, "TradeForbidden");

        _updateConfigs();
        _tryApprovePlugins();
        _cleanOrders();

        OpenPositionContext memory context = OpenPositionContext({
            sizeUsd: sizeUsd * GMX_DECIMAL_MULTIPLIER,
            priceUsd: priceUsd * GMX_DECIMAL_MULTIPLIER,
            isMarket: _isMarketOrder(flags),
            borrow: borrow,
            fee: 0,
            amountIn: 0,
            amountOut: 0,
            gmxOrderIndex: 0,
            executionFee: 0
        });
        if (swapInToken == _WETH) {
            IWETH(_WETH).deposit{ value: swapInAmount }();
        }
        if (swapInToken != _account.collateralToken) {
            context.amountOut = LibGmx.swap(
                _projectConfigs,
                swapInToken,
                _account.collateralToken,
                swapInAmount,
                minSwapOut
            );
        } else {
            context.amountOut = swapInAmount;
        }
        uint256 borrowed;
        (borrowed, context.fee) = _borrowCollateral(borrow);
        context.amountIn = context.amountOut + borrowed;
        IERC20Upgradeable(_account.collateralToken).approve(_projectConfigs.router, context.amountIn);

        return _openPosition(context);
    }

    /// @notice Place a closing request on GMX.
    function closePosition(
        uint256 collateralUsd, // collateral.decimals
        uint256 sizeUsd, // 1e18
        uint96 priceUsd, // 1e18
        uint96 tpPriceUsd, // 1e18
        uint96 slPriceUsd, // 1e18
        uint8 flags // MARKET, TRIGGER
    ) external payable onlyTraderOrFactory nonReentrant {
        require(!_account.isLiquidating, "TradeForbidden");
        _updateConfigs();
        _cleanOrders();

        if (flags & POSITION_TPSL_ORDER > 0) {
            if (_account.isLong) {
                require(tpPriceUsd >= slPriceUsd, "WrongPrice");
            } else {
                require(tpPriceUsd <= slPriceUsd, "WrongPrice");
            }
            bytes32 tpOrderKey = _closePosition(
                collateralUsd, // collateral.decimals
                sizeUsd, // 1e18
                tpPriceUsd, // 1e18
                0 // MARKET, TRIGGER
            );
            _closeTpslOrderIndexes.add(tpOrderKey);
            bytes32 slOrderKey = _closePosition(
                collateralUsd, // collateral.decimals
                sizeUsd, // 1e18
                slPriceUsd, // 1e18
                0 // MARKET, TRIGGER
            );
            _closeTpslOrderIndexes.add(slOrderKey);
        } else {
            _closePosition(
                collateralUsd, // collateral.decimals
                sizeUsd, // 1e18
                priceUsd, // 1e18
                flags // MARKET, TRIGGER
            );
        }
    }

    function updateOrder(
        bytes32 orderKey,
        uint256 collateralDelta,
        uint256 sizeDelta,
        uint256 triggerPrice,
        bool triggerAboveThreshold
    ) external onlyTraderOrFactory nonReentrant {
        _updateConfigs();
        _cleanOrders();

        LibGmx.OrderHistory memory history = LibGmx.decodeOrderHistoryKey(orderKey);
        if (history.receiver == LibGmx.OrderReceiver.OB_INC) {
            IGmxOrderBook(_projectConfigs.orderBook).updateIncreaseOrder(
                history.index,
                sizeDelta,
                triggerPrice,
                triggerAboveThreshold
            );
        } else if (history.receiver == LibGmx.OrderReceiver.OB_DEC) {
            IGmxOrderBook(_projectConfigs.orderBook).updateDecreaseOrder(
                history.index,
                collateralDelta,
                sizeDelta,
                triggerPrice,
                triggerAboveThreshold
            );
        } else {
            revert("InvalidOrderType");
        }
    }

    function _closePosition(
        uint256 collateralUsd, // collateral.decimals
        uint256 sizeUsd, // 1e18
        uint96 priceUsd, // 1e18
        uint8 flags // MARKET, TRIGGER
    ) internal returns (bytes32) {
        require(!_account.isLiquidating, "TradeForbidden");
        _updateConfigs();
        _cleanOrders();

        ClosePositionContext memory context = ClosePositionContext({
            collateralUsd: collateralUsd * GMX_DECIMAL_MULTIPLIER,
            sizeUsd: sizeUsd * GMX_DECIMAL_MULTIPLIER,
            priceUsd: priceUsd * GMX_DECIMAL_MULTIPLIER,
            isMarket: _isMarketOrder(flags),
            gmxOrderIndex: 0,
            executionFee: 0
        });
        return _closePosition(context);
    }

    function liquidatePosition(uint256 liquidatePrice) external payable onlyKeeperOrFactory nonReentrant {
        _updateConfigs();
        _cleanOrders();

        IGmxVault.Position memory position = _getGmxPosition();
        require(position.sizeUsd > 0, "NoPositionToLiquidate");
        _checkLiquidatePrice(liquidatePrice);
        _liquidatePosition(position, liquidatePrice);
        _account.isLiquidating = true;
    }

    function withdraw() external nonReentrant {
        _updateConfigs();
        _cleanOrders();

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            if (_account.collateralToken == _WETH) {
                IWETH(_WETH).deposit{ value: ethBalance }();
            } else {
                AddressUpgradeable.sendValue(payable(_account.account), ethBalance);
            }
        }
        IGmxVault.Position memory position = _getGmxPosition();
        uint256 balance = IERC20Upgradeable(_account.collateralToken).balanceOf(address(this));
        uint256 userAmount;
        uint256 paidDebt;
        uint256 paidFee;
        bool isLiquidation = _account.isLiquidating;
        // partially close
        if (position.sizeUsd != 0) {
            require(
                _isMarginSafe(
                    position,
                    0,
                    0,
                    LibGmx.getOraclePrice(_projectConfigs, _account.indexToken, !_account.isLong),
                    _assetConfigs.initialMarginRate
                ),
                "ImMarginUnsafe"
            );
            userAmount = balance;
            paidDebt = 0;
            paidFee = 0;
            _transferToUser(userAmount);
            (uint256 fundingFee, uint256 newFunding) = _getBitoroFundingFee();
            _account.cumulativeFee += fundingFee;
            _account.debtEntryFunding = newFunding;
        } else {
            // safe
            uint256 inflightBorrow = _calcInflightBorrow(); // collateral
            (userAmount, paidDebt, paidFee) = _repayCollateral(balance, inflightBorrow);
            if (userAmount > 0) {
                _transferToUser(userAmount);
            }
            _account.isLiquidating = false;
            // clean tpsl orders
            _cleanTpslOrders();
        }
        emit Withdraw(
            _account.cumulativeDebt,
            _account.cumulativeFee,
            isLiquidation,
            balance,
            userAmount,
            paidDebt,
            paidFee
        );
    }

    function cancelOrders(bytes32[] memory keys) external onlyTraderOrFactory nonReentrant {
        _cleanOrders();
        _cancelOrders(keys);
    }

    function cancelTimeoutOrders(bytes32[] memory keys) external nonReentrant onlyKeeperOrFactory {
        _cleanOrders();
        _cancelTimeoutOrders(keys);
    }

    function _tryApprovePlugins() internal {
        IGmxRouter(_projectConfigs.router).approvePlugin(_projectConfigs.orderBook);
        IGmxRouter(_projectConfigs.router).approvePlugin(_projectConfigs.positionRouter);
    }

    function _transferToUser(uint256 amount) internal {
        if (_account.collateralToken == _WETH) {
            IWETH(_WETH).withdraw(amount);
            Address.sendValue(payable(_account.account), amount);
        } else {
            IERC20Upgradeable(_account.collateralToken).safeTransfer(_account.account, amount);
        }
    }

    function _checkLiquidatePrice(uint256 liquidatePrice) internal view {
        require(liquidatePrice != 0, "ZeroLiquidationPrice"); // broker price = 0
        if (_assetConfigs.referrenceOracle == address(0)) {
            return;
        }
        uint96 oraclePrice = LibOracle.readChainlink(_assetConfigs.referrenceOracle);
        require(oraclePrice != 0, "ZeroOralcePrice"); // broker price = 0

        uint256 bias = liquidatePrice >= oraclePrice ? liquidatePrice - oraclePrice : oraclePrice - liquidatePrice;
        bias = (bias * LibUtils.RATE_DENOMINATOR) / oraclePrice;
        require(bias <= _assetConfigs.referenceDeviation, "LiquidatePriceNotMet");
    }

    function _isMarketOrder(uint8 flags) internal pure returns (bool) {
        return (flags & POSITION_MARKET_ORDER) != 0;
    }

    function _cancelOrders(bytes32[] memory keys) internal {
        uint256 canceledBorrow = 0;
        for (uint256 i = 0; i < keys.length; i++) {
            bytes32 orderKey = keys[i];
            LibGmx.OrderHistory memory history = LibGmx.decodeOrderHistoryKey(orderKey);
            canceledBorrow += history.borrow;
            // must cancel order && tpsl
            require(_cancelOrder(orderKey), "CancelFailed");
            _cancelTpslOrders(orderKey);
        }
        _repayCanceledBorrow(canceledBorrow);
    }

    function _cancelTimeoutOrders(bytes32[] memory keys) internal {
        uint256 _now = block.timestamp;
        uint256 marketTimeout = _projectConfigs.marketOrderTimeoutSeconds;
        uint256 limitTimeout = _projectConfigs.limitOrderTimeoutSeconds;
        uint256 canceledBorrow = 0;
        for (uint256 i = 0; i < keys.length; i++) {
            bytes32 orderKey = keys[i];
            LibGmx.OrderHistory memory history = LibGmx.decodeOrderHistoryKey(orderKey);
            uint256 elapsed = _now - history.timestamp;
            if (
                ((history.receiver == LibGmx.OrderReceiver.PR_INC || history.receiver == LibGmx.OrderReceiver.PR_DEC) &&
                    elapsed >= marketTimeout) ||
                ((history.receiver == LibGmx.OrderReceiver.OB_INC || history.receiver == LibGmx.OrderReceiver.OB_DEC) &&
                    elapsed >= limitTimeout)
            ) {
                if (_cancelOrder(orderKey)) {
                    canceledBorrow += history.borrow;
                    _cancelTpslOrders(orderKey);
                }
            }
        }
        _repayCanceledBorrow(canceledBorrow);
    }

    function _cleanTpslOrders() internal {
        // open tpsl orders
        uint256 openLength = _openTpslOrderIndexes.length();
        bytes32[] memory openKeys = new bytes32[](openLength);
        for (uint256 i = 0; i < openLength; i++) {
            (openKeys[i], ) = _openTpslOrderIndexes.at(i);
        }
        for (uint256 i = 0; i < openLength; i++) {
            // clean all tpsl orders paired with orders that already filled
            if (!_pendingOrders.contains(openKeys[i])) {
                _cancelTpslOrders(openKeys[i]);
            }
        }
        // close tpsl orders
        uint256 closeLength = _closeTpslOrderIndexes.length();
        bytes32[] memory closeKeys = new bytes32[](closeLength);
        for (uint256 i = 0; i < closeLength; i++) {
            closeKeys[i] = _closeTpslOrderIndexes.at(i);
        }
        for (uint256 i = 0; i < closeLength; i++) {
            // clean all tpsl orders paired with orders that already filled
            _cancelOrder(closeKeys[i]);
        }
    }

    function _cleanOrders() internal {
        bytes32[] memory pendingKeys = _pendingOrders.values();
        for (uint256 i = 0; i < pendingKeys.length; i++) {
            bytes32 orderKey = pendingKeys[i];
            (bool notExist, ) = LibGmx.getOrder(_projectConfigs, orderKey);
            if (notExist) {
                _removePendingOrder(orderKey);
            }
        }
    }

    function _repayCanceledBorrow(uint256 borrow) internal {
        if (borrow == 0) {
            return;
        }
        uint256 ethBalance = address(this).balance;
        if (_account.collateralToken == _WETH && ethBalance > 0) {
            IWETH(_WETH).deposit{ value: ethBalance }();
        }
        uint256 balance = IERC20Upgradeable(_account.collateralToken).balanceOf(address(this));
        if (_account.collateralToken == _WETH) {
            balance += address(this).balance;
        }
        (uint256 toUser, , ) = _partialRepayCollateral(borrow, balance);
        _transferToUser(toUser);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../../../interfaces/IGmxOrderBook.sol";
import "../../../interfaces/IGmxPositionRouter.sol";
import "../../../interfaces/IGmxVault.sol";
import "../../../interfaces/IWETH.sol";

import "../Type.sol";

library LibGmx {
    using SafeERC20 for IERC20;

    enum OrderCategory {
        NONE,
        OPEN,
        CLOSE,
        LIQUIDATE
    }

    enum OrderReceiver {
        PR_INC,
        PR_DEC,
        OB_INC,
        OB_DEC
    }

    struct OrderHistory {
        OrderCategory category; // 4
        OrderReceiver receiver; // 4
        uint64 index; // 64
        uint96 borrow; // 96
        uint88 timestamp; // 80
    }

    function getOraclePrice(
        ProjectConfigs storage projectConfigs,
        address token,
        bool useMaxPrice
    ) internal view returns (uint256 price) {
        // open long = max
        // open short = min
        // close long = min
        // close short = max
        price = useMaxPrice //isOpen == isLong
            ? IGmxVault(projectConfigs.vault).getMaxPrice(token)
            : IGmxVault(projectConfigs.vault).getMinPrice(token);
        require(price != 0, "ZeroOraclePrice");
    }

    function swap(
        ProjectConfigs memory projectConfigs,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minOut
    ) public returns (uint256 amountOut) {
        IERC20(tokenIn).safeTransfer(projectConfigs.vault, amountIn);
        amountOut = IGmxVault(projectConfigs.vault).swap(tokenIn, tokenOut, address(this));
        require(amountOut >= minOut, "AmountOutNotReached");
    }

    function getOrderIndex(
        ProjectConfigs memory projectConfigs,
        OrderReceiver receiver
    ) public view returns (uint256 index) {
        if (receiver == OrderReceiver.PR_INC) {
            index = IGmxPositionRouter(projectConfigs.positionRouter).increasePositionsIndex(address(this));
        } else if (receiver == OrderReceiver.PR_DEC) {
            index = IGmxPositionRouter(projectConfigs.positionRouter).decreasePositionsIndex(address(this));
        } else if (receiver == OrderReceiver.OB_INC) {
            index = IGmxOrderBook(projectConfigs.orderBook).increaseOrdersIndex(address(this)) - 1;
        } else if (receiver == OrderReceiver.OB_DEC) {
            index = IGmxOrderBook(projectConfigs.orderBook).decreaseOrdersIndex(address(this)) - 1;
        }
    }

    function getOrder(
        ProjectConfigs memory projectConfigs,
        bytes32 key
    ) public view returns (bool isFilled, OrderHistory memory history) {
        history = decodeOrderHistoryKey(key);
        if (history.receiver == OrderReceiver.PR_INC) {
            IGmxPositionRouter.IncreasePositionRequest memory request = IGmxPositionRouter(
                projectConfigs.positionRouter
            ).increasePositionRequests(encodeOrderKey(address(this), history.index));
            isFilled = request.account == address(0);
        } else if (history.receiver == OrderReceiver.PR_DEC) {
            IGmxPositionRouter.DecreasePositionRequest memory request = IGmxPositionRouter(
                projectConfigs.positionRouter
            ).decreasePositionRequests(encodeOrderKey(address(this), history.index));
            isFilled = request.account == address(0);
        } else if (history.receiver == OrderReceiver.OB_INC) {
            (address collateralToken, , , , , , , , ) = IGmxOrderBook(projectConfigs.orderBook).getIncreaseOrder(
                address(this),
                history.index
            );
            isFilled = collateralToken == address(0);
        } else if (history.receiver == OrderReceiver.OB_DEC) {
            (address collateralToken, , , , , , , ) = IGmxOrderBook(projectConfigs.orderBook).getDecreaseOrder(
                address(this),
                history.index
            );
            isFilled = collateralToken == address(0);
        } else {
            revert();
        }
    }

    function cancelOrderFromPositionRouter(address positionRouter, bytes32 key) public returns (bool success) {
        OrderHistory memory history = decodeOrderHistoryKey(key);
        success = false;
        if (history.receiver == OrderReceiver.PR_INC) {
            try
                IGmxPositionRouter(positionRouter).cancelIncreasePosition(
                    encodeOrderKey(address(this), history.index),
                    payable(address(this))
                )
            returns (bool _success) {
                success = _success;
            } catch {}
        } else if (history.receiver == OrderReceiver.PR_DEC) {
            try
                IGmxPositionRouter(positionRouter).cancelDecreasePosition(
                    encodeOrderKey(address(this), history.index),
                    payable(address(this))
                )
            returns (bool _success) {
                success = _success;
            } catch {}
        }
    }

    function cancelOrderFromOrderBook(address orderBook, bytes32 key) public returns (bool success) {
        OrderHistory memory history = decodeOrderHistoryKey(key);
        success = false;
        if (history.receiver == OrderReceiver.OB_INC) {
            try IGmxOrderBook(orderBook).cancelIncreaseOrder(history.index) {
                success = true;
            } catch {}
        } else if (history.receiver == OrderReceiver.OB_DEC) {
            try IGmxOrderBook(orderBook).cancelDecreaseOrder(history.index) {
                success = true;
            } catch {}
        }
    }

    function cancelOrder(ProjectConfigs memory projectConfigs, bytes32 key) public returns (bool success) {
        OrderHistory memory history = decodeOrderHistoryKey(key);
        success = false;
        if (history.receiver == OrderReceiver.PR_INC) {
            try
                IGmxPositionRouter(projectConfigs.positionRouter).cancelIncreasePosition(
                    encodeOrderKey(address(this), history.index),
                    payable(address(this))
                )
            returns (bool _success) {
                success = _success;
            } catch {}
        } else if (history.receiver == OrderReceiver.PR_DEC) {
            try
                IGmxPositionRouter(projectConfigs.positionRouter).cancelDecreasePosition(
                    encodeOrderKey(address(this), history.index),
                    payable(address(this))
                )
            returns (bool _success) {
                success = _success;
            } catch {}
        } else if (history.receiver == OrderReceiver.OB_INC) {
            try IGmxOrderBook(projectConfigs.orderBook).cancelIncreaseOrder(history.index) {
                success = true;
            } catch {}
        } else if (history.receiver == OrderReceiver.OB_DEC) {
            try IGmxOrderBook(projectConfigs.orderBook).cancelDecreaseOrder(history.index) {
                success = true;
            } catch {}
        } else {
            revert();
        }
    }

    function getPnl(
        ProjectConfigs memory projectConfigs,
        address indexToken,
        uint256 size,
        uint256 averagePriceUsd,
        bool isLong,
        uint256 priceUsd,
        uint256 lastIncreasedTime
    ) public view returns (bool, uint256) {
        uint256 priceDelta = averagePriceUsd > priceUsd ? averagePriceUsd - priceUsd : priceUsd - averagePriceUsd;
        uint256 delta = (size * priceDelta) / averagePriceUsd;
        bool hasProfit;
        if (isLong) {
            hasProfit = priceUsd > averagePriceUsd;
        } else {
            hasProfit = averagePriceUsd > priceUsd;
        }
        uint256 minProfitTime = IGmxVault(projectConfigs.vault).minProfitTime();
        uint256 minProfitBasisPoints = IGmxVault(projectConfigs.vault).minProfitBasisPoints(indexToken);
        uint256 minBps = block.timestamp > lastIncreasedTime + minProfitTime ? 0 : minProfitBasisPoints;
        if (hasProfit && delta * 10000 <= size * minBps) {
            delta = 0;
        }
        return (hasProfit, delta);
    }

    function encodeOrderKey(address account, uint256 index) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, index));
    }

    function decodeOrderHistoryKey(bytes32 key) internal pure returns (OrderHistory memory history) {
        //            252          248                184          88           0
        // +------------+------------+------------------+-----------+-----------+
        // | category 4 | receiver 4 | gmxOrderIndex 64 | borrow 96 |  time 88  |
        // +------------+------------+------------------+-----------+-----------+
        history.category = OrderCategory(uint8(bytes1(key)) >> 4);
        history.receiver = OrderReceiver(uint8(bytes1(key)) & 0x0f);
        history.index = uint64(bytes8(key << 8));
        history.borrow = uint96(uint256(key >> 88));
        history.timestamp = uint88(uint256(key));
    }

    function encodeOrderHistoryKey(
        OrderCategory category,
        OrderReceiver receiver,
        uint256 index,
        uint256 borrow,
        uint256 timestamp
    ) internal pure returns (bytes32 data) {
        //            252          248                184          88           0
        // +------------+------------+------------------+-----------+-----------+
        // | category 4 | receiver 4 | gmxOrderIndex 64 | borrow 96 |  time 88  |
        // +------------+------------+------------------+-----------+-----------+
        require(index < type(uint64).max, "GmxOrderIndexOverflow");
        require(borrow < type(uint96).max, "BorrowOverflow");
        require(timestamp < type(uint88).max, "FeeOverflow");
        data =
            bytes32(uint256(category) << 252) | // 256 - 4
            bytes32(uint256(receiver) << 248) | // 256 - 4 - 4
            bytes32(uint256(index) << 184) | // 256 - 4 - 4 - 64
            bytes32(uint256(borrow) << 88) | // 256 - 4 - 4 - 64 - 96
            bytes32(uint256(timestamp));
    }

    function encodeTpslIndex(bytes32 tpOrderKey, bytes32 slOrderKey) internal pure returns (bytes32) {
        //            252          248                184
        // +------------+------------+------------------+
        // | category 4 | receiver 4 | gmxOrderIndex 64 |
        // +------------+------------+------------------+
        // store head of orderkey without timestamp, since tpsl orders should have the same timestamp as the open order.
        return bytes32(bytes9(tpOrderKey)) | (bytes32(bytes9(slOrderKey)) >> 128);
    }

    function decodeTpslIndex(
        bytes32 orderKey,
        bytes32 tpslIndex
    ) internal pure returns (bytes32 tpOrderKey, bytes32 slOrderKey) {
        bytes32 timestamp = bytes32(uint256(uint88(uint256(orderKey))));
        // timestamp of all tpsl orders (main +tp +sl) are same
        tpOrderKey = bytes32(bytes16(tpslIndex));
        tpOrderKey = tpOrderKey != bytes32(0) ? tpOrderKey | timestamp : tpOrderKey;
        slOrderKey = (tpslIndex << 128);
        slOrderKey = slOrderKey != bytes32(0) ? slOrderKey | timestamp : slOrderKey;
    }

    function getPrExecutionFee(ProjectConfigs memory projectConfigs) public view returns (uint256) {
        return IGmxPositionRouter(projectConfigs.positionRouter).minExecutionFee();
    }

    function getObExecutionFee(ProjectConfigs memory projectConfigs) public view returns (uint256) {
        return IGmxOrderBook(projectConfigs.orderBook).minExecutionFee() + 1;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "../../../interfaces/IChainLink.sol";

import "./LibUtils.sol";

library LibOracle {
    function readChainlink(address referenceOracle) internal view returns (uint96) {
        int256 ref = IChainlinkV2V3(referenceOracle).latestAnswer();
        require(ref > 0, "P=0"); // oracle Price <= 0
        ref *= 1e10; // decimals 8 => 18
        return LibUtils.toU96(uint256(ref));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

library LibUtils {
    uint256 internal constant RATE_DENOMINATOR = 1e5;

    function toAddress(bytes32 value) internal pure returns (address) {
        return address(bytes20(value));
    }

    function toAddress(uint256 value) internal pure returns (address) {
        return address(bytes20(bytes32(value)));
    }

    function toU256(address value) internal pure returns (uint256) {
        return uint256(uint160(value));
    }

    function toU32(bytes32 value) internal pure returns (uint32) {
        require(uint256(value) <= type(uint32).max, "OU32");
        return uint32(uint256(value));
    }

    function toU32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "OU32");
        return uint32(value);
    }

    function toU8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "OU8");
        return uint8(value);
    }

    function toU96(uint256 n) internal pure returns (uint96) {
        require(n <= type(uint96).max, "OU96"); // uint96 Overflow
        return uint96(n);
    }

    function rate(uint256 value, uint32 rate_) internal pure returns (uint256) {
        return (value * rate_) / RATE_DENOMINATOR;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "../../interfaces/ILiquidityPool.sol";
import "../../interfaces/IProxyFactory.sol";

import "./libs/LibGmx.sol";
import "./libs/LibUtils.sol";
import "./Storage.sol";
import "./Debt.sol";

contract Position is Storage, Debt {
    using LibUtils for uint256;
    using MathUpgradeable for uint256;
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using EnumerableMapUpgradeable for EnumerableMapUpgradeable.Bytes32ToBytes32Map;

    uint256 internal constant GMX_DECIMAL_MULTIPLIER = 1e12; // 30 - 18
    uint256 internal constant MAX_PENDING_ORDERS = 64;

    event AddPendingOrder(
        LibGmx.OrderCategory category,
        LibGmx.OrderReceiver receiver,
        uint256 index,
        uint256 borrow,
        uint256 timestamp
    );
    event RemovePendingOrder(bytes32 key);
    event CancelOrder(bytes32 key, bool success);

    event OpenPosition(address collateralToken, address indexToken, bool isLong, OpenPositionContext context);
    event ClosePosition(address collateralToken, address indexToken, bool isLong, ClosePositionContext context);
    event LiquidatePosition(
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 liquidationPrice,
        uint256 estimateliquidationFee,
        IGmxVault.Position position
    );

    function _hasPendingOrder(bytes32 key) internal view returns (bool) {
        return _pendingOrders.contains(key);
    }

    function _getPendingOrders() internal view returns (bytes32[] memory) {
        return _pendingOrders.values();
    }

    function _getTpslOrderIndexes(bytes32 orderKey) internal view returns (bytes32 tpOrderIndex, bytes32 slOrderIndex) {
        (bool exists, bytes32 tpslIndex) = _openTpslOrderIndexes.tryGet(orderKey);
        if (exists) {
            (tpOrderIndex, slOrderIndex) = LibGmx.decodeTpslIndex(orderKey, tpslIndex);
        }
    }

    function _isIncreasingOrder(bytes32 key) internal pure returns (bool) {
        LibGmx.OrderReceiver receiver = LibGmx.OrderReceiver(uint8(bytes1(key << 8)));
        return receiver == LibGmx.OrderReceiver.PR_INC || receiver == LibGmx.OrderReceiver.OB_INC;
    }

    function _getMarginValue(
        IGmxVault.Position memory position,
        uint256 deltaCollateral,
        uint256 priceUsd
    ) internal view returns (uint256 accountValue, bool isNegative) {
        bool hasProfit = false;
        uint256 gmxPnlUsd = 0;
        uint256 gmxFundingFeeUsd = 0;
        // 1. gmx pnl and funding, 1e30
        if (position.sizeUsd != 0) {
            (hasProfit, gmxPnlUsd) = LibGmx.getPnl(
                _projectConfigs,
                _account.indexToken,
                position.sizeUsd,
                position.averagePrice,
                _account.isLong,
                priceUsd,
                position.lastIncreasedTime
            );
            gmxFundingFeeUsd = IGmxVault(_projectConfigs.vault).getFundingFee(
                _account.collateralToken,
                position.sizeUsd,
                position.entryFundingRate
            );
        }
        (uint256 bitoroFundingFee, ) = _getBitoroFundingFee();
        uint256 inflightBorrow = _calcInflightBorrow(); // collateral
        int256 value = int256(position.collateralUsd) +
            (hasProfit ? int256(gmxPnlUsd) : -int256(gmxPnlUsd)) -
            int256(gmxFundingFeeUsd);
        int256 effectiveDebt = (int256(_account.cumulativeDebt + _account.cumulativeFee + bitoroFundingFee) -
            int256(inflightBorrow + deltaCollateral));
        if (_account.isLong) {
            value -= (effectiveDebt * int256(position.averagePrice)) / int256(10 ** _account.collateralDecimals); // 1e30
        } else {
            uint256 tokenPrice = LibGmx.getOraclePrice(_projectConfigs, _account.collateralToken, false); // 1e30
            value -= (effectiveDebt * int256(tokenPrice)) / int256(10 ** _account.collateralDecimals); // 1e30
        }
        if (value > 0) {
            accountValue = uint256(value);
            isNegative = false;
        } else {
            accountValue = uint256(-value);
            isNegative = true;
        }
    }

    function _isMarginSafe(
        IGmxVault.Position memory position,
        uint256 deltaCollateralUsd,
        uint256 deltaSizeUsd,
        uint256 priceUsd,
        uint32 threshold
    ) internal view returns (bool) {
        if (position.sizeUsd == 0) {
            return true;
        }
        (uint256 accountValue, bool isNegative) = _getMarginValue(position, deltaCollateralUsd, priceUsd); // 1e30
        if (isNegative) {
            return false;
        }
        uint256 liquidationFeeUsd = IGmxVault(_projectConfigs.vault).liquidationFeeUsd();
        return accountValue >= (position.sizeUsd + deltaSizeUsd).rate(threshold).max(liquidationFeeUsd);
    }

    function _getGmxPosition() internal view returns (IGmxVault.Position memory) {
        return IGmxVault(_projectConfigs.vault).positions(_gmxPositionKey);
    }

    function _openPosition(OpenPositionContext memory context) internal returns (bytes32 orderKey) {
        require(_pendingOrders.length() <= MAX_PENDING_ORDERS, "TooManyPendingOrders");
        IGmxVault.Position memory position = _getGmxPosition();
        require(
            _isMarginSafe(
                position,
                context.amountIn,
                context.sizeUsd,
                LibGmx.getOraclePrice(_projectConfigs, _account.indexToken, !_account.isLong),
                _assetConfigs.initialMarginRate
            ),
            "ImMarginUnsafe"
        );
        address[] memory path = new address[](1);
        path[0] = _account.collateralToken;
        if (context.isMarket) {
            context.executionFee = LibGmx.getPrExecutionFee(_projectConfigs);
            IGmxPositionRouter(_projectConfigs.positionRouter).createIncreasePosition{ value: context.executionFee }(
                path,
                _account.indexToken,
                context.amountIn,
                0,
                context.sizeUsd,
                _account.isLong,
                _account.isLong ? type(uint256).max : 0,
                context.executionFee,
                _projectConfigs.referralCode,
                address(0)
            );
            (context.gmxOrderIndex, orderKey) = _addPendingOrder(
                LibGmx.OrderCategory.OPEN,
                LibGmx.OrderReceiver.PR_INC,
                context.borrow
            );
        } else {
            context.executionFee = LibGmx.getObExecutionFee(_projectConfigs);
            IGmxOrderBook(_projectConfigs.orderBook).createIncreaseOrder{ value: context.executionFee }(
                path,
                context.amountIn,
                _account.indexToken,
                0,
                context.sizeUsd,
                _account.collateralToken,
                _account.isLong,
                context.priceUsd,
                !_account.isLong,
                context.executionFee,
                false
            );
            (context.gmxOrderIndex, orderKey) = _addPendingOrder(
                LibGmx.OrderCategory.OPEN,
                LibGmx.OrderReceiver.OB_INC,
                context.borrow
            );
        }
        emit OpenPosition(_account.collateralToken, _account.indexToken, _account.isLong, context);
    }

    function _closePosition(ClosePositionContext memory context) internal returns (bytes32 orderKey) {
        require(_pendingOrders.length() <= MAX_PENDING_ORDERS * 2, "TooManyPendingOrders");

        IGmxVault.Position memory position = _getGmxPosition();
        require(
            _isMarginSafe(
                position,
                0,
                0,
                LibGmx.getOraclePrice(_projectConfigs, _account.indexToken, !_account.isLong),
                _assetConfigs.maintenanceMarginRate
            ),
            "MmMarginUnsafe"
        );

        address[] memory path = new address[](1);
        path[0] = _account.collateralToken;
        if (context.isMarket) {
            context.executionFee = LibGmx.getPrExecutionFee(_projectConfigs);
            context.priceUsd = _account.isLong ? 0 : type(uint256).max;
            IGmxPositionRouter(_projectConfigs.positionRouter).createDecreasePosition{ value: context.executionFee }(
                path, // no swap for collateral
                _account.indexToken,
                context.collateralUsd,
                context.sizeUsd,
                _account.isLong, // no swap for collateral
                address(this),
                context.priceUsd,
                0,
                context.executionFee,
                false,
                address(0)
            );
            (context.gmxOrderIndex, orderKey) = _addPendingOrder(
                LibGmx.OrderCategory.CLOSE,
                LibGmx.OrderReceiver.PR_DEC,
                0
            );
        } else {
            context.executionFee = LibGmx.getObExecutionFee(_projectConfigs);
            uint256 oralcePrice = LibGmx.getOraclePrice(_projectConfigs, _account.indexToken, !_account.isLong);
            uint256 priceUsd = context.priceUsd;
            IGmxOrderBook(_projectConfigs.orderBook).createDecreaseOrder{ value: context.executionFee }(
                _account.indexToken,
                context.sizeUsd,
                _account.collateralToken,
                context.collateralUsd,
                _account.isLong,
                priceUsd,
                priceUsd >= oralcePrice
            );
            (context.gmxOrderIndex, orderKey) = _addPendingOrder(
                LibGmx.OrderCategory.CLOSE,
                LibGmx.OrderReceiver.OB_DEC,
                0
            );
        }
        emit ClosePosition(_account.collateralToken, _account.indexToken, _account.isLong, context);
    }

    function _liquidatePosition(IGmxVault.Position memory position, uint256 liquidationPrice) internal {
        require(
            !_isMarginSafe(position, 0, 0, liquidationPrice * 1e12, _assetConfigs.maintenanceMarginRate),
            "MmMarginSafe"
        );
        uint256 executionFee = msg.value;
        // cancel all orders inflight
        bytes32[] memory pendingKeys = _pendingOrders.values();
        for (uint256 i = 0; i < pendingKeys.length; i++) {
            LibGmx.cancelOrder(_projectConfigs, pendingKeys[i]);
        }
        // place market liquidate order
        uint256 markPrice = _account.isLong ? 0 : type(uint256).max;
        address[] memory path = new address[](1);
        path[0] = _account.collateralToken;
        IGmxPositionRouter(_projectConfigs.positionRouter).createDecreasePosition{ value: executionFee }(
            path,
            _account.indexToken,
            0,
            position.sizeUsd,
            _account.isLong,
            address(this),
            markPrice,
            0,
            executionFee,
            false,
            address(0)
        );
        _addPendingOrder(LibGmx.OrderCategory.LIQUIDATE, LibGmx.OrderReceiver.PR_INC, 0);
        emit LiquidatePosition(
            _account.collateralToken,
            _account.indexToken,
            _account.isLong,
            liquidationPrice,
            _account.liquidationFee,
            position
        );
    }

    function _cancelOrder(bytes32 orderKey) internal returns (bool success) {
        if (!_hasPendingOrder(orderKey)) {
            success = true;
        } else {
            success = LibGmx.cancelOrder(_projectConfigs, orderKey);
            if (success) {
                _removePendingOrder(orderKey);
                emit CancelOrder(orderKey, success);
            }
        }
    }

    function _cancelTpslOrders(bytes32 orderKey) internal returns (bool success) {
        (bool exists, bytes32 tpslIndex) = _openTpslOrderIndexes.tryGet(orderKey);
        if (!exists) {
            success = true;
        } else {
            (bytes32 tpOrderKey, bytes32 slOrderKey) = LibGmx.decodeTpslIndex(orderKey, tpslIndex);
            if (_cancelOrder(tpOrderKey) && _cancelOrder(slOrderKey)) {
                _openTpslOrderIndexes.remove(orderKey);
                success = true;
            }
        }
    }

    // the tp/sl order may be canceled earlier
    function _tryCancelOrder(bytes32 key) internal returns (bool) {
        if (!_cancelOrder(key)) {
            return false;
        }
        (bool exists, bytes32 tpslIndex) = _openTpslOrderIndexes.tryGet(key);
        if (exists) {
            (bytes32 tpOrderKey, bytes32 slOrderKey) = LibGmx.decodeTpslIndex(key, tpslIndex);
            if (_cancelOrder(tpOrderKey) && _cancelOrder(slOrderKey)) {
                _openTpslOrderIndexes.remove(key);
            }
        }
        return true;
    }

    function _removePendingOrder(bytes32 key) internal {
        _pendingOrders.remove(key);
        _closeTpslOrderIndexes.remove(key);
        emit RemovePendingOrder(key);
    }

    function _addPendingOrder(
        LibGmx.OrderCategory category,
        LibGmx.OrderReceiver receiver,
        uint256 borrow
    ) internal returns (uint256 index, bytes32 orderKey) {
        index = LibGmx.getOrderIndex(_projectConfigs, receiver);
        orderKey = LibGmx.encodeOrderHistoryKey(category, receiver, index, borrow, block.timestamp);
        require(_pendingOrders.add(orderKey), "AddFailed");
        emit AddPendingOrder(category, receiver, index, borrow, block.timestamp);
    }

    function _calcInflightBorrow() internal view returns (uint256 inflightBorrow) {
        bytes32[] memory pendingKeys = _pendingOrders.values();
        for (uint256 i = 0; i < pendingKeys.length; i++) {
            bytes32 key = pendingKeys[i];
            if (_hasPendingOrder(key) && _isIncreasingOrder(key)) {
                (bool isFilled, LibGmx.OrderHistory memory history) = LibGmx.getOrder(_projectConfigs, key);
                if (!isFilled) {
                    inflightBorrow += history.borrow;
                }
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./Type.sol";

contract Storage is Initializable {
    uint256 internal constant PROJECT_ID = 1;
    uint256 internal constant VIRTUAL_ASSET_ID = 255;

    uint32 internal _localProjectVersion;
    mapping(address => uint32) _localAssetVersions;

    address internal _factory;
    address internal _liquidityPool;
    bytes32 internal _gmxPositionKey;

    ProjectConfigs internal _projectConfigs;
    TokenConfigs internal _assetConfigs;

    AccountState internal _account;
    EnumerableSetUpgradeable.Bytes32Set internal _pendingOrders;
    EnumerableMapUpgradeable.Bytes32ToBytes32Map internal _openTpslOrderIndexes;
    EnumerableSetUpgradeable.Bytes32Set internal _closeTpslOrderIndexes;

    bytes32[48] private __gaps;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

enum ProjectConfigIds {
    VAULT,
    POSITION_ROUTER,
    ORDER_BOOK,
    ROUTER,
    REFERRAL_CODE,
    MARKET_ORDER_TIMEOUT_SECONDS,
    LIMIT_ORDER_TIMEOUT_SECONDS,
    FUNDING_ASSET_ID,
    END
}

enum TokenConfigIds {
    BOOST_FEE_RATE,
    INITIAL_MARGIN_RATE,
    MAINTENANCE_MARGIN_RATE,
    LIQUIDATION_FEE_RATE,
    REFERRENCE_ORACLE,
    REFERRENCE_ORACLE_DEVIATION,
    END
}

struct ProjectConfigs {
    address vault;
    address positionRouter;
    address orderBook;
    address router;
    bytes32 referralCode;
    // ========================
    uint32 marketOrderTimeoutSeconds;
    uint32 limitOrderTimeoutSeconds;
    uint8 fundingAssetId;
    bytes32[19] reserved;
}

struct TokenConfigs {
    address referrenceOracle;
    // --------------------------
    uint32 referenceDeviation;
    uint32 boostFeeRate;
    uint32 initialMarginRate;
    uint32 maintenanceMarginRate;
    uint32 liquidationFeeRate;
    // --------------------------
    bytes32[20] reserved;
}

struct AccountState {
    address account;
    uint256 cumulativeDebt;
    uint256 cumulativeFee;
    uint256 debtEntryFunding;
    address collateralToken;
    // --------------------------
    address indexToken; // 160
    uint8 deprecated0; // 8
    bool isLong; // 8
    uint8 collateralDecimals;
    // reserve 80
    // --------------------------
    uint256 liquidationFee;
    bool isLiquidating;
    bytes32[18] reserved;
}

struct OpenPositionContext {
    // parameters
    uint256 amountIn;
    uint256 sizeUsd;
    uint256 priceUsd;
    bool isMarket;
    // calculated
    uint256 fee;
    uint256 borrow;
    uint256 amountOut;
    uint256 gmxOrderIndex;
    uint256 executionFee;
}

struct ClosePositionContext {
    uint256 collateralUsd;
    uint256 sizeUsd;
    uint256 priceUsd;
    bool isMarket;
    uint256 gmxOrderIndex;
    uint256 executionFee;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

contract ImplementationGuard {
    address private immutable _this;

    constructor() {
        _this = address(this);
    }

    modifier onlyDelegateCall() {
        require(address(this) != _this);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IChainlink {
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

interface IChainlinkV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface IChainlinkV2V3 is IChainlink, IChainlinkV3 {}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface IGmxBasePositionManager {
    function maxGlobalLongSizes(address _token) external view returns (uint256);
    function maxGlobalShortSizes(address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGmxOrderBook {
    event CreateIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event CancelIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event ExecuteIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address purchaseToken,
        uint256 purchaseTokenAmount,
        address collateralToken,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 executionPrice
    );
    event UpdateIncreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 sizeDelta,
        uint256 triggerPrice,
        bool triggerAboveThreshold
    );
    event CreateDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event CancelDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee
    );
    event ExecuteDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 executionPrice
    );
    event UpdateDecreaseOrder(
        address indexed account,
        uint256 orderIndex,
        address collateralToken,
        uint256 collateralDelta,
        address indexToken,
        uint256 sizeDelta,
        bool isLong,
        uint256 triggerPrice,
        bool triggerAboveThreshold
    );

    function minExecutionFee() external view returns (uint256);

    function getIncreaseOrder(
        address _account,
        uint256 _orderIndex
    )
        external
        view
        returns (
            address purchaseToken,
            uint256 purchaseTokenAmount,
            address collateralToken,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function getDecreaseOrder(
        address _account,
        uint256 _orderIndex
    )
        external
        view
        returns (
            address collateralToken,
            uint256 collateralDelta,
            address indexToken,
            uint256 sizeDelta,
            bool isLong,
            uint256 triggerPrice,
            bool triggerAboveThreshold,
            uint256 executionFee
        );

    function increaseOrdersIndex(address account) external view returns (uint256);

    function decreaseOrdersIndex(address account) external view returns (uint256);

    function cancelMultiple(
        uint256[] memory _swapOrderIndexes,
        uint256[] memory _increaseOrderIndexes,
        uint256[] memory _decreaseOrderIndexes
    ) external;

    function createIncreaseOrder(
        address[] memory _path,
        uint256 _amountIn,
        address _indexToken,
        uint256 _minOut,
        uint256 _sizeDelta,
        address _collateralToken,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        uint256 _executionFee,
        bool _shouldWrap
    ) external payable;

    function cancelIncreaseOrder(uint256 _orderIndex) external;

    function createDecreaseOrder(
        address _indexToken,
        uint256 _sizeDelta,
        address _collateralToken,
        uint256 _collateralDelta,
        bool _isLong,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external payable;

    function cancelDecreaseOrder(uint256 _orderIndex) external;

    function updateIncreaseOrder(
        uint256 _orderIndex,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function updateDecreaseOrder(
        uint256 _orderIndex,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold
    ) external;

    function executeDecreaseOrder(address, uint256, address payable) external;

    function executeIncreaseOrder(address, uint256, address payable) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IGmxPositionRouter {
    struct IncreasePositionRequest {
        address account;
        // address[] path;
        address indexToken;
        uint256 amountIn;
        uint256 minOut;
        uint256 sizeDelta;
        bool isLong;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool hasCollateralInETH;
    }

    struct DecreasePositionRequest {
        address account;
        // address[] path;
        address indexToken;
        uint256 collateralDelta;
        uint256 sizeDelta;
        bool isLong;
        address receiver;
        uint256 acceptablePrice;
        uint256 minOut;
        uint256 executionFee;
        uint256 blockNumber;
        uint256 blockTime;
        bool withdrawETH;
    }

    function setPositionKeeper(address _account, bool _isActive) external;

    function increasePositionRequests(bytes32) external view returns (IncreasePositionRequest memory);

    function decreasePositionRequests(bytes32) external view returns (DecreasePositionRequest memory);

    function minExecutionFee() external view returns (uint256);

    function increasePositionsIndex(address account) external view returns (uint256);

    function decreasePositionsIndex(address account) external view returns (uint256);

    function createIncreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _amountIn,
        uint256 _minOut,
        uint256 _sizeDelta,
        bool _isLong,
        uint256 _acceptablePrice,
        uint256 _executionFee,
        bytes32 _referralCode,
        address _callbackTarget
    ) external payable returns (bytes32);

    function createDecreasePosition(
        address[] memory _path,
        address _indexToken,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        bool _isLong,
        address _receiver,
        uint256 _acceptablePrice,
        uint256 _minOut,
        uint256 _executionFee,
        bool _withdrawETH,
        address _callbackTarget
    ) external payable returns (bytes32);

    function cancelIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool); // callback

    function cancelDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool); // callback

    function executeIncreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);

    function executeDecreasePosition(bytes32 _key, address payable _executionFeeReceiver) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IGmxRouter {
    function approvedPlugins(address, address) external view returns (bool);

    function approvePlugin(address _plugin) external;

    function denyPlugin(address _plugin) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGmxVault {
    struct Position {
        uint256 sizeUsd;
        uint256 collateralUsd;
        uint256 averagePrice;
        uint256 entryFundingRate;
        uint256 reserveAmount;
        int256 realisedPnlUsd;
        uint256 lastIncreasedTime;
    }

    event BuyUSDG(address account, address token, uint256 tokenAmount, uint256 usdgAmount, uint256 feeBasisPoints);
    event SellUSDG(address account, address token, uint256 usdgAmount, uint256 tokenAmount, uint256 feeBasisPoints);
    event Swap(
        address account,
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOut,
        uint256 amountOutAfterFees,
        uint256 feeBasisPoints
    );

    event IncreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        uint256 fee
    );
    event DecreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralDelta,
        uint256 sizeDelta,
        bool isLong,
        uint256 price,
        uint256 fee
    );
    event LiquidatePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        bool isLong,
        uint256 size,
        uint256 collateral,
        uint256 reserveAmount,
        int256 realisedPnl,
        uint256 markPrice
    );
    event UpdatePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        uint256 entryFundingRate,
        uint256 reserveAmount,
        int256 realisedPnl
    );
    event ClosePosition(
        bytes32 key,
        uint256 size,
        uint256 collateral,
        uint256 averagePrice,
        uint256 entryFundingRate,
        uint256 reserveAmount,
        int256 realisedPnl
    );

    event UpdateFundingRate(address token, uint256 fundingRate);
    event UpdatePnl(bytes32 key, bool hasProfit, uint256 delta);

    event CollectSwapFees(address token, uint256 feeUsd, uint256 feeTokens);
    event CollectMarginFees(address token, uint256 feeUsd, uint256 feeTokens);

    event DirectPoolDeposit(address token, uint256 amount);
    event IncreasePoolAmount(address token, uint256 amount);
    event DecreasePoolAmount(address token, uint256 amount);
    event IncreaseUsdgAmount(address token, uint256 amount);
    event DecreaseUsdgAmount(address token, uint256 amount);
    event IncreaseReservedAmount(address token, uint256 amount);
    event DecreaseReservedAmount(address token, uint256 amount);
    event IncreaseGuaranteedUsd(address token, uint256 amount);
    event DecreaseGuaranteedUsd(address token, uint256 amount);

    function swap(
        address _tokenIn,
        address _tokenOut,
        address _receiver
    ) external returns (uint256);

    function getPositionDelta(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (bool, uint256);

    function getDelta(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _lastIncreasedTime
    ) external view returns (bool, uint256);

    function getFundingFee(
        address _token,
        uint256 _size,
        uint256 _entryFundingRate
    ) external view returns (uint256);

    function getMaxPrice(address _token) external view returns (uint256);

    function getMinPrice(address _token) external view returns (uint256);

    function getNextAveragePrice(
        address _indexToken,
        uint256 _size,
        uint256 _averagePrice,
        bool _isLong,
        uint256 _nextPrice,
        uint256 _sizeDelta,
        uint256 _lastIncreasedTime
    ) external view returns (uint256);

    function positions(bytes32 key) external view returns (Position memory);

    /**
     * [0] size,
     * [1] collateral,
     * [2] averagePrice,
     * [3] entryFundingRate,
     * [4] reserveAmount,
     * [5] realisedPnl,
     * [6] realisedPnl >= 0,
     * [7] lastIncreasedTime
     */
    function getPosition(
        address account,
        address collateralToken,
        address indexToken,
        bool isLong
    )
        external
        view
        returns (
            uint256 size,
            uint256 collateral,
            uint256 averagePrice,
            uint256 entryFundingRate,
            uint256 reserveAmount,
            uint256 realisedPnl,
            bool hasRealisedPnl,
            uint256 lastIncreasedTime
        );

    function liquidatePosition(
        address _account,
        address _collateralToken,
        address _indexToken,
        bool _isLong,
        address _feeReceiver
    ) external;

    function usdgAmounts(address) external view returns (uint256);

    function tokenWeights(address) external view returns (uint256);

    function totalTokenWeights() external view returns (uint256);

    function liquidationFeeUsd() external view returns (uint256);

    function taxBasisPoints() external view returns (uint256);

    function stableTaxBasisPoints() external view returns (uint256);

    function swapFeeBasisPoints() external view returns (uint256);

    function stableSwapFeeBasisPoints() external view returns (uint256);

    function marginFeeBasisPoints() external view returns (uint256);

    function priceFeed() external view returns (address);

    function poolAmounts(address token) external view returns (uint256);

    function bufferAmounts(address token) external view returns (uint256);

    function reservedAmounts(address token) external view returns (uint256);

    function getRedemptionAmount(address token, uint256 usdgAmount) external view returns (uint256);

    function minProfitTime() external view returns (uint256);

    function minProfitBasisPoints(address token) external view returns (uint256);

    function maxUsdgAmounts(address token) external view returns (uint256);

    function globalShortSizes(address token) external view returns (uint256);

    function maxGlobalShortSizes(address token) external view returns (uint256);

    function guaranteedUsd(address token) external view returns (uint256);

    function stableTokens(address token) external view returns (bool);

    function fundingRateFactor() external view returns (uint256);

    function stableFundingRateFactor() external view returns (uint256);

    function cumulativeFundingRates(address token) external view returns (uint256);

    function getNextFundingRate(address token) external view returns (uint256);

    function getEntryFundingRate(
        address _collateralToken,
        address _indexToken,
        bool _isLong
    ) external view returns (uint256);

    function gov() external view returns (address);

    function setLiquidator(address, bool) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILiquidityPool {
    struct Asset {
        // slot
        // assets with the same symbol in different chains are the same asset. they shares the same bitoroToken. so debts of the same symbol
        // can be accumulated across chains (see Reader.AssetState.deduct). ex: ERC20(fBNB).symbol should be "BNB", so that BNBs of
        // different chains are the same.
        // since bitoroToken of all stable coins is the same and is calculated separately (see Reader.ChainState.stableDeduct), stable coin
        // symbol can be different (ex: "USDT", "USDT.e" and "fUSDT").
        bytes32 symbol;
        // slot
        address tokenAddress; // erc20.address
        uint8 id;
        uint8 decimals; // erc20.decimals
        uint56 flags; // a bitset of ASSET_*
        uint24 _flagsPadding;
        // slot
        uint32 initialMarginRate; // 1e5
        uint32 maintenanceMarginRate; // 1e5
        uint32 minProfitRate; // 1e5
        uint32 minProfitTime; // 1e0
        uint32 positionFeeRate; // 1e5
        // note: 96 bits remaining
        // slot
        address referenceOracle;
        uint32 referenceDeviation; // 1e5
        uint8 referenceOracleType;
        uint32 halfSpread; // 1e5
        // note: 24 bits remaining
        // slot
        uint128 _reserved1;
        uint128 _reserved2;
        // slot
        uint96 collectedFee;
        uint32 liquidationFeeRate; // 1e5
        uint96 spotLiquidity;
        // note: 32 bits remaining
        // slot
        uint96 maxLongPositionSize;
        uint96 totalLongPosition;
        // note: 64 bits remaining
        // slot
        uint96 averageLongPrice;
        uint96 maxShortPositionSize;
        // note: 64 bits remaining
        // slot
        uint96 totalShortPosition;
        uint96 averageShortPrice;
        // note: 64 bits remaining
        // slot, less used
        address bitoroTokenAddress; // bitoroToken.address. all stable coins share the same bitoroTokenAddress
        uint32 spotWeight; // 1e0
        uint32 longFundingBaseRate8H; // 1e5
        uint32 longFundingLimitRate8H; // 1e5
        // slot
        uint128 longCumulativeFundingRate; // Σ_t fundingRate_t
        uint128 shortCumulativeFunding; // Σ_t fundingRate_t * indexPrice_t
    }

    function borrowAsset(
        address borrower,
        uint8 assetId,
        uint256 rawAmount,
        uint256 rawFee
    ) external returns (uint256);

    function repayAsset(
        address repayer,
        uint8 assetId,
        uint256 rawAmount,
        uint256 rawFee,
        uint256 rawBadDebt // debt amount that cannot be recovered
    ) external;

    function getAssetAddress(uint8 assetId) external view returns (address);

    function getLiquidityPoolStorage()
        external
        view
        returns (
            // [0] shortFundingBaseRate8H
            // [1] shortFundingLimitRate8H
            // [2] lastFundingTime
            // [3] fundingInterval
            // [4] liquidityBaseFeeRate
            // [5] liquidityDynamicFeeRate
            // [6] sequence. note: will be 0 after 0xffffffff
            // [7] strictStableDeviation
            uint32[8] memory u32s,
            // [0] blpPriceLowerBound
            // [1] blpPriceUpperBound
            uint96[2] memory u96s
        );

    function getAssetInfo(uint8 assetId) external view returns (Asset memory);

    function setLiquidityManager(address liquidityManager, bool enable) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IProxyFactory {
    function weth() external view returns (address);

    function getProxiesOf(address account) external view returns (address[] memory);

    function isKeeper(address keeper) external view returns (bool);

    function getProjectConfig(uint256 projectId) external view returns (uint256[] memory);

    function getProjectAssetConfig(uint256 projectId, address assetToken) external view returns (uint256[] memory);

    function getBorrowStates(uint256 projectId, address assetToken)
        external
        view
        returns (
            uint256 totalBorrow,
            uint256 borrowLimit,
            uint256 badDebt
        );

    function referralCode() external view returns (bytes32);

    function getAssetId(uint256 projectId, address token) external view returns (uint8);

    function borrowAsset(
        uint256 projectId,
        address collateralToken,
        uint256 amount,
        uint256 fee
    ) external returns (uint256 amountOut);

    function repayAsset(
        uint256 projectId,
        address collateralToken,
        uint256 amount,
        uint256 fee,
        uint256 badDebt_
    ) external;

    function getConfigVersions(uint256 projectId, address assetToken)
        external
        view
        returns (uint32 projectConfigVersion, uint32 assetConfigVersion);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IGmxVault.sol";
import "../interfaces/IGmxBasePositionManager.sol";
import "../interfaces/IGmxPositionRouter.sol";
import "../interfaces/IGmxOrderBook.sol";
import "../interfaces/IProxyFactory.sol";
import "../aggregators/gmx/Type.sol";
import "../aggregators/gmx/GmxAdapter.sol";
import "../aggregators/gmx/libs/LibGmx.sol";

contract Reader {
    IProxyFactory public immutable aggregatorFactory;
    IGmxVault public immutable gmxVault;
    IERC20 public immutable weth;
    IERC20 public immutable usdg;

    uint256 internal constant GMX_PROJECT_ID = 1;

    constructor(IProxyFactory aggregatorFactory_, IGmxVault gmxVault_, IERC20 weth_, IERC20 usdg_) {
        aggregatorFactory = aggregatorFactory_;
        gmxVault = gmxVault_;
        weth = weth_;
        usdg = usdg_;
    }

    struct GmxAdapterStorage {
        BitoroCollateral[] collaterals;
        GmxCoreStorage gmx;
    }

    function getGmxAdapterStorage(
        IGmxBasePositionManager gmxPositionManager,
        IGmxPositionRouter gmxPositionRouter,
        IGmxOrderBook gmxOrderBook,
        address[] memory aggregatorCollateralAddresses,
        address[] memory gmxTokenAddresses
    ) public view returns (GmxAdapterStorage memory store) {
        // gmx
        store.collaterals = _getBitoroCollaterals(GMX_PROJECT_ID, aggregatorCollateralAddresses);
        store.gmx = _getGmxCoreStorage(gmxPositionRouter, gmxOrderBook);
        store.gmx.tokens = _getGmxCoreTokens(gmxPositionManager, gmxTokenAddresses);
    }

    struct BitoroCollateral {
        // config
        uint256 boostFeeRate; // 1e5
        uint256 initialMarginRate; // 1e5
        uint256 maintenanceMarginRate; // 1e5
        uint256 liquidationFeeRate; // 1e5
        // state
        uint256 totalBorrow; // token.decimals
        uint256 borrowLimit; // token.decimals
    }

    function _getBitoroCollaterals(
        uint256 projectId,
        address[] memory tokenAddresses
    ) internal view returns (BitoroCollateral[] memory tokens) {
        tokens = new BitoroCollateral[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            BitoroCollateral memory token = tokens[i];
            // config
            uint256[] memory values = IProxyFactory(aggregatorFactory).getProjectAssetConfig(
                projectId,
                tokenAddresses[i]
            );
            require(values.length >= uint256(TokenConfigIds.END), "MissingConfigs");
            token.boostFeeRate = uint256(values[uint256(TokenConfigIds.BOOST_FEE_RATE)]);
            token.initialMarginRate = uint256(values[uint256(TokenConfigIds.INITIAL_MARGIN_RATE)]);
            token.maintenanceMarginRate = uint256(values[uint256(TokenConfigIds.MAINTENANCE_MARGIN_RATE)]);
            token.liquidationFeeRate = uint256(values[uint256(TokenConfigIds.LIQUIDATION_FEE_RATE)]);
            // state
            (token.totalBorrow, token.borrowLimit, ) = IProxyFactory(aggregatorFactory).getBorrowStates(
                projectId,
                tokenAddresses[i]
            );
        }
    }

    struct GmxCoreStorage {
        // config
        uint256 totalTokenWeights; // 1e0
        uint256 minProfitTime; // 1e0
        uint256 minExecutionFee;
        uint256 liquidationFeeUsd; // 1e30
        uint256 _marginFeeBasisPoints; // 1e4. note: do NOT use this one. the real fee is in TimeLock
        uint256 swapFeeBasisPoints; // 1e4
        uint256 stableSwapFeeBasisPoints; // 1e4
        uint256 taxBasisPoints; // 1e4
        uint256 stableTaxBasisPoints; // 1e4
        // state
        uint256 usdgSupply; // 1e18
        GmxToken[] tokens;
    }

    function _getGmxCoreStorage(
        IGmxPositionRouter gmxPositionRouter,
        IGmxOrderBook gmxOrderBook
    ) internal view returns (GmxCoreStorage memory store) {
        store.totalTokenWeights = gmxVault.totalTokenWeights();
        store.minProfitTime = gmxVault.minProfitTime();
        uint256 exec1 = gmxPositionRouter.minExecutionFee();
        uint256 exec2 = gmxOrderBook.minExecutionFee();
        store.minExecutionFee = exec1 > exec2 ? exec1 : exec2;
        store.liquidationFeeUsd = gmxVault.liquidationFeeUsd();
        store._marginFeeBasisPoints = gmxVault.marginFeeBasisPoints();
        store.swapFeeBasisPoints = gmxVault.swapFeeBasisPoints();
        store.stableSwapFeeBasisPoints = gmxVault.stableSwapFeeBasisPoints();
        store.taxBasisPoints = gmxVault.taxBasisPoints();
        store.stableTaxBasisPoints = gmxVault.stableTaxBasisPoints();
        store.usdgSupply = usdg.totalSupply();
    }

    struct GmxToken {
        // config
        uint256 minProfit;
        uint256 weight;
        uint256 maxUsdgAmounts;
        uint256 maxGlobalShortSize;
        uint256 maxGlobalLongSize;
        // storage
        uint256 poolAmount;
        uint256 reservedAmount;
        uint256 usdgAmount;
        uint256 redemptionAmount;
        uint256 bufferAmounts;
        uint256 globalShortSize;
        uint256 contractMinPrice;
        uint256 contractMaxPrice;
        uint256 guaranteedUsd;
        uint256 fundingRate;
        uint256 cumulativeFundingRate;
    }

    function _getGmxCoreTokens(
        IGmxBasePositionManager gmxPositionManager,
        address[] memory tokenAddresses
    ) internal view returns (GmxToken[] memory tokens) {
        tokens = new GmxToken[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            address tokenAddress = tokenAddresses[i];
            GmxToken memory token = tokens[i];

            // config
            token.minProfit = gmxVault.minProfitBasisPoints(tokenAddress);
            token.weight = gmxVault.tokenWeights(tokenAddress);
            token.maxUsdgAmounts = gmxVault.maxUsdgAmounts(tokenAddress);
            token.maxGlobalShortSize = gmxPositionManager.maxGlobalShortSizes(tokenAddress);
            token.maxGlobalLongSize = gmxPositionManager.maxGlobalLongSizes(tokenAddress);

            // storage
            token.poolAmount = gmxVault.poolAmounts(tokenAddress);
            token.reservedAmount = gmxVault.reservedAmounts(tokenAddress);
            token.usdgAmount = gmxVault.usdgAmounts(tokenAddress);
            token.redemptionAmount = gmxVault.getRedemptionAmount(tokenAddress, 10 ** 30);
            token.bufferAmounts = gmxVault.bufferAmounts(tokenAddress);
            token.globalShortSize = gmxVault.globalShortSizes(tokenAddress);
            token.contractMinPrice = gmxVault.getMinPrice(tokenAddress);
            token.contractMaxPrice = gmxVault.getMaxPrice(tokenAddress);
            token.guaranteedUsd = gmxVault.guaranteedUsd(tokenAddress);

            // funding
            uint256 fundingRateFactor = gmxVault.stableTokens(tokenAddress)
                ? gmxVault.stableFundingRateFactor()
                : gmxVault.fundingRateFactor();
            if (token.poolAmount > 0) {
                token.fundingRate = (fundingRateFactor * token.reservedAmount) / token.poolAmount;
            }
            uint256 acc = gmxVault.cumulativeFundingRates(tokenAddress);
            if (acc > 0) {
                uint256 nextRate = gmxVault.getNextFundingRate(tokenAddress);
                uint256 baseRate = gmxVault.cumulativeFundingRates(tokenAddress);
                token.cumulativeFundingRate = baseRate + nextRate;
            }
        }
    }

    struct AggregatorSubAccount {
        // key
        address proxyAddress;
        uint256 projectId;
        address collateralAddress;
        address assetAddress;
        bool isLong;
        // store
        bool isLiquidating;
        uint256 cumulativeDebt; // token.decimals
        uint256 cumulativeFee; // token.decimals
        uint256 debtEntryFunding; // 1e18
        uint256 proxyCollateralBalance; // token.decimals. collateral erc20 balance of the proxy
        uint256 proxyEthBalance; // 1e18. native balance of the proxy
        // if gmx
        GmxCoreAccount gmx;
        GmxAdapterOrder[] gmxOrders;
    }

    // for UI
    function getAggregatorSubAccountsOfAccount(
        IGmxPositionRouter gmxPositionRouter,
        IGmxOrderBook gmxOrderBook,
        address accountAddress
    ) public view returns (AggregatorSubAccount[] memory subAccounts) {
        address[] memory proxyAddresses = aggregatorFactory.getProxiesOf(accountAddress);
        return getAggregatorSubAccountsOfProxy(gmxPositionRouter, gmxOrderBook, proxyAddresses);
    }

    // for keeper
    function getAggregatorSubAccountsOfProxy(
        IGmxPositionRouter gmxPositionRouter,
        IGmxOrderBook gmxOrderBook,
        address[] memory proxyAddresses
    ) public view returns (AggregatorSubAccount[] memory subAccounts) {
        subAccounts = new AggregatorSubAccount[](proxyAddresses.length);
        for (uint256 i = 0; i < proxyAddresses.length; i++) {
            // if gmx
            GmxAdapter adapter = GmxAdapter(payable(proxyAddresses[i]));
            subAccounts[i] = _getBitoroAggregatorSubAccountForGmxAdapter(adapter);
            AggregatorSubAccount memory subAccount = subAccounts[i];
            subAccount.gmx = _getGmxCoreAccount(
                address(adapter),
                subAccount.collateralAddress,
                subAccount.assetAddress,
                subAccount.isLong
            );
            subAccount.gmxOrders = _getGmxAdapterOrders(gmxPositionRouter, gmxOrderBook, adapter);
        }
    }

    function _getBitoroAggregatorSubAccountForGmxAdapter(
        GmxAdapter adapter
    ) internal view returns (AggregatorSubAccount memory account) {
        account.projectId = GMX_PROJECT_ID;
        AccountState memory bitoroAccount = adapter.bitoroAccountState();
        account.proxyAddress = address(adapter);
        account.collateralAddress = bitoroAccount.collateralToken;
        account.assetAddress = bitoroAccount.indexToken;
        account.isLong = bitoroAccount.isLong;
        account.isLiquidating = bitoroAccount.isLiquidating;
        (account.cumulativeDebt, account.cumulativeFee, account.debtEntryFunding) = adapter.debtStates();
        account.proxyCollateralBalance = IERC20(account.collateralAddress).balanceOf(account.proxyAddress);
        account.proxyEthBalance = account.proxyAddress.balance;
    }

    struct GmxCoreAccount {
        uint256 sizeUsd; // 1e30
        uint256 collateralUsd; // 1e30
        uint256 lastIncreasedTime;
        uint256 entryPrice; // 1e30
        uint256 entryFundingRate; // 1e6
    }

    function _getGmxCoreAccount(
        address accountAddress,
        address collateralAddress,
        address indexAddress,
        bool isLong
    ) internal view returns (GmxCoreAccount memory account) {
        (
            uint256 size,
            uint256 collateral,
            uint256 averagePrice,
            uint256 entryFundingRate,
            ,
            ,
            ,
            uint256 lastIncreasedTime
        ) = gmxVault.getPosition(accountAddress, collateralAddress, indexAddress, isLong);
        account.sizeUsd = size;
        account.collateralUsd = collateral;
        account.lastIncreasedTime = lastIncreasedTime;
        account.entryPrice = averagePrice;
        account.entryFundingRate = entryFundingRate;
    }

    struct GmxAdapterOrder {
        // aggregator order
        bytes32 orderHistoryKey; // see LibGmx.decodeOrderHistoryKey
        // gmx order
        bool isFillOrCancel;
        uint256 amountIn; // increase only, collateral.decimals
        uint256 collateralDeltaUsd; // decrease only, 1e30
        uint256 sizeDeltaUsd; // 1e30
        uint256 triggerPrice; // 0 if market order, 1e30
        bool triggerAboveThreshold;
        // tp/sl strategy only
        bytes32 tpOrderHistoryKey;
        bytes32 slOrderHistoryKey;
    }

    function _getGmxAdapterOrders(
        IGmxPositionRouter gmxPositionRouter,
        IGmxOrderBook gmxOrderBook,
        GmxAdapter aggregator
    ) internal view returns (GmxAdapterOrder[] memory orders) {
        bytes32[] memory pendingKeys = aggregator.getPendingGmxOrderKeys();
        orders = new GmxAdapterOrder[](pendingKeys.length);
        for (uint256 i = 0; i < pendingKeys.length; i++) {
            orders[i] = _getGmxAdapterOrder(gmxPositionRouter, gmxOrderBook, aggregator, pendingKeys[i]);
        }
    }

    function _getGmxAdapterOrder(
        IGmxPositionRouter gmxPositionRouter,
        IGmxOrderBook gmxOrderBook,
        GmxAdapter aggregator,
        bytes32 key
    ) internal view returns (GmxAdapterOrder memory order) {
        LibGmx.OrderHistory memory entry = LibGmx.decodeOrderHistoryKey(key);
        order.orderHistoryKey = key;
        if (entry.receiver == LibGmx.OrderReceiver.PR_INC) {
            IGmxPositionRouter.IncreasePositionRequest memory request = gmxPositionRouter.increasePositionRequests(
                LibGmx.encodeOrderKey(address(aggregator), entry.index)
            );
            order.isFillOrCancel = request.account == address(0);
            order.amountIn = request.amountIn;
            order.sizeDeltaUsd = request.sizeDelta;
        } else if (entry.receiver == LibGmx.OrderReceiver.PR_DEC) {
            IGmxPositionRouter.DecreasePositionRequest memory request = gmxPositionRouter.decreasePositionRequests(
                LibGmx.encodeOrderKey(address(aggregator), entry.index)
            );
            order.isFillOrCancel = request.account == address(0);
            order.collateralDeltaUsd = request.collateralDelta;
            order.sizeDeltaUsd = request.sizeDelta;
        } else if (entry.receiver == LibGmx.OrderReceiver.OB_INC) {
            (
                ,
                uint256 purchaseTokenAmount,
                address collateralToken,
                ,
                uint256 sizeDelta,
                ,
                uint256 triggerPrice,
                bool triggerAboveThreshold,

            ) = gmxOrderBook.getIncreaseOrder(address(aggregator), entry.index);
            order.isFillOrCancel = collateralToken == address(0);
            order.amountIn = purchaseTokenAmount;
            order.sizeDeltaUsd = sizeDelta;
            order.triggerPrice = triggerPrice;
            order.triggerAboveThreshold = triggerAboveThreshold;
        } else if (entry.receiver == LibGmx.OrderReceiver.OB_DEC) {
            (
                address collateralToken,
                uint256 collateralDelta,
                ,
                uint256 sizeDelta,
                ,
                uint256 triggerPrice,
                bool triggerAboveThreshold,

            ) = gmxOrderBook.getDecreaseOrder(address(aggregator), entry.index);
            order.isFillOrCancel = collateralToken == address(0);
            order.collateralDeltaUsd = collateralDelta;
            order.sizeDeltaUsd = sizeDelta;
            order.triggerPrice = triggerPrice;
            order.triggerAboveThreshold = triggerAboveThreshold;
        }
        (order.tpOrderHistoryKey, order.slOrderHistoryKey) = aggregator.getTpslOrderKeys(key);
    }
}