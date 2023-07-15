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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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

pragma solidity 0.8.9;

contract Constants {
    uint8 internal constant STAKING_PID_FOR_CHARGE_FEE = 1;
    uint256 internal constant BASIS_POINTS_DIVISOR = 100000;
    uint256 internal constant LIQUIDATE_THRESHOLD_DIVISOR = 10 * BASIS_POINTS_DIVISOR;
    uint256 internal constant DEFAULT_VLP_PRICE = 100000;
    uint256 internal constant FUNDING_RATE_PRECISION = BASIS_POINTS_DIVISOR ** 3; // 1e15
    uint256 internal constant MAX_DEPOSIT_WITHDRAW_FEE = 10000; // 10%
    uint256 internal constant MAX_DELTA_TIME = 24 hours;
    uint256 internal constant MAX_COOLDOWN_DURATION = 30 days;
    uint256 internal constant MAX_FEE_BASIS_POINTS = 5000; // 5%
    uint256 internal constant MAX_PRICE_MOVEMENT_PERCENT = 10000; // 10%
    uint256 internal constant MAX_BORROW_FEE_FACTOR = 500; // 0.5% per hour
    uint256 internal constant MAX_FUNDING_RATE = FUNDING_RATE_PRECISION / 10; // 10% per hour
    uint256 internal constant MAX_STAKING_UNSTAKING_FEE = 10000; // 10%
    uint256 internal constant MAX_EXPIRY_DURATION = 60; // 60 seconds
    uint256 internal constant MAX_SELF_EXECUTE_COOLDOWN = 300; // 5 minutes
    uint256 internal constant MAX_TOKENFARM_COOLDOWN_DURATION = 4 weeks;
    uint256 internal constant MAX_TRIGGER_GAS_FEE = 1e8 gwei;
    uint256 internal constant MAX_MARKET_ORDER_GAS_FEE = 1e8 gwei;
    uint256 internal constant MAX_VESTING_DURATION = 700 days;
    uint256 internal constant MIN_LEVERAGE = 10000; // 1x
    uint256 internal constant POSITION_MARKET = 0;
    uint256 internal constant POSITION_LIMIT = 1;
    uint256 internal constant POSITION_STOP_MARKET = 2;
    uint256 internal constant POSITION_STOP_LIMIT = 3;
    uint256 internal constant POSITION_TRAILING_STOP = 4;
    uint256 internal constant PRICE_PRECISION = 10 ** 30;
    uint256 internal constant TRAILING_STOP_TYPE_AMOUNT = 0;
    uint256 internal constant TRAILING_STOP_TYPE_PERCENT = 1;
    uint256 internal constant VLP_DECIMALS = 18;

    function uintToBytes(uint v) internal pure returns (bytes32 ret) {
        if (v == 0) {
            ret = "0";
        } else {
            while (v > 0) {
                ret = bytes32(uint(ret) / (2 ** 8));
                ret |= bytes32(((v % 10) + 48) * 2 ** (8 * 31));
                v /= 10;
            }
        }
        return ret;
    }

    function checkSlippage(bool isLong, uint256 allowedPrice, uint256 actualMarketPrice) internal pure {
        if (isLong) {
            require(
                actualMarketPrice <= allowedPrice,
                string(
                    abi.encodePacked(
                        "long: slippage exceeded ",
                        uintToBytes(actualMarketPrice),
                        " ",
                        uintToBytes(allowedPrice)
                    )
                )
            );
        } else {
            require(
                actualMarketPrice >= allowedPrice,
                string(
                    abi.encodePacked(
                        "short: slippage exceeded ",
                        uintToBytes(actualMarketPrice),
                        " ",
                        uintToBytes(allowedPrice)
                    )
                )
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {Position, Order, OrderType} from "../structs.sol";

interface ILiquidateVault {
    function validateLiquidationWithPosid(uint256 _posId) external view returns (bool, int256, int256, int256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOperators {
    function getOperatorLevel(address op) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {Order, OrderType, OrderStatus, AddPositionOrder, DecreasePositionOrder, PositionTrigger} from "../structs.sol";

interface IOrderVault {
    function addTrailingStop(address _account, uint256 _posId, uint256[] memory _params) external;

    function addTriggerOrders(
        uint256 _posId,
        address _account,
        bool[] memory _isTPs,
        uint256[] memory _prices,
        uint256[] memory _amountPercents
    ) external;

    function cancelPendingOrder(address _account, uint256 _posId) external;

    function updateOrder(
        uint256 _posId,
        uint256 _positionType,
        uint256 _collateral,
        uint256 _size,
        OrderStatus _status
    ) external;

    function cancelMarketOrder(uint256 _posId) external;

    function createNewOrder(
        uint256 _posId,
        address _accout,
        bool _isLong,
        uint256 _tokenId,
        uint256 _positionType,
        uint256[] memory _params,
        address _refer
    ) external;

    function createAddPositionOrder(
        address _owner,
        uint256 _posId,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _allowedPrice,
        uint256 _fee
    ) external;

    function createDecreasePositionOrder(uint256 _posId, uint256 _sizeDelta, uint256 _allowedPrice) external;

    function cancelAddPositionOrder(uint256 _posId) external;

    function deleteAddPositionOrder(uint256 _posId) external;

    function deleteDecreasePositionOrder(uint256 _posId) external;

    function getOrder(uint256 _posId) external view returns (Order memory);

    function getAddPositionOrder(uint256 _posId) external view returns (AddPositionOrder memory);

    function getDecreasePositionOrder(uint256 _posId) external view returns (DecreasePositionOrder memory);

    function getTriggerOrderInfo(uint256 _posId) external view returns (PositionTrigger memory);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {Position, Order, OrderType, PaidFees} from "../structs.sol";

interface IPositionVault {
    function newPositionOrder(
        address _account,
        uint256 _tokenId,
        bool _isLong,
        OrderType _orderType,
        uint256[] memory _params,
        address _refer
    ) external;

    function addOrRemoveCollateral(address _account, uint256 _posId, bool isPlus, uint256 _amount) external;

    function createAddPositionOrder(
        address _account,
        uint256 _posId,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _allowedPrice
    ) external;

    function createDecreasePositionOrder(
        uint256 _posId,
        address _account,
        uint256 _sizeDelta,
        uint256 _allowedPrice
    ) external;

    function increasePosition(
        uint256 _posId,
        address _account,
        uint256 _tokenId,
        bool _isLong,
        uint256 _price,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _fee
    ) external;

    function decreasePosition(uint256 _posId, uint256 _price, uint256 _sizeDelta) external;

    function decreasePositionByOrderVault(uint256 _posId, uint256 _price, uint256 _sizeDelta) external;

    function removeUserAlivePosition(address _user, uint256 _posId) external;

    function removeUserOpenOrder(address _user, uint256 _posId) external;

    function lastPosId() external view returns (uint256);

    function getPosition(uint256 _posId) external view returns (Position memory);

    function getUserPositionIds(address _account) external view returns (uint256[] memory);

    function getUserOpenOrderIds(address _account) external view returns (uint256[] memory);

    function getPaidFees(uint256 _posId) external view returns (PaidFees memory);

    function getVaultUSDBalance() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IPriceManager {
    function getLastPrice(uint256 _tokenId) external view returns (uint256);

    function maxLeverage(uint256 _tokenId) external view returns (uint256);

    function tokenToUsd(address _token, uint256 _tokenAmount) external view returns (uint256);

    function usdToToken(address _token, uint256 _usdAmount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ISettingsManager {
    function decreaseOpenInterest(uint256 _tokenId, address _sender, bool _isLong, uint256 _amount) external;

    function increaseOpenInterest(uint256 _tokenId, address _sender, bool _isLong, uint256 _amount) external;

    function openInterestPerAssetPerSide(uint256 _tokenId, bool _isLong) external view returns (uint256);

    function openInterestPerUser(address _sender) external view returns (uint256);

    function bountyPercent() external view returns (uint32, uint32);

    function checkBanList(address _delegate) external view returns (bool);

    function checkDelegation(address _master, address _delegate) external view returns (bool);

    function minCollateral() external view returns (uint256);

    function closeDeltaTime() external view returns (uint256);

    function expiryDuration() external view returns (uint256);

    function selfExecuteCooldown() external view returns (uint256);

    function cooldownDuration() external view returns (uint256);

    function liquidationPendingTime() external view returns (uint256);

    function depositFee(address token) external view returns (uint256);

    function withdrawFee(address token) external view returns (uint256);

    function feeManager() external view returns (address);

    function feeRewardBasisPoints() external view returns (uint256);

    function defaultBorrowFeeFactor() external view returns (uint256);

    function borrowFeeFactor(uint256 tokenId) external view returns (uint256);

    function totalOpenInterest() external view returns (uint256);

    function basisFundingRateFactor() external view returns (uint256);

    function deductFeePercent(address _account) external view returns (uint256);

    function referrerTiers(address _referrer) external view returns (uint256);

    function tierFees(uint256 _tier) external view returns (uint256);

    function fundingIndex(uint256 _tokenId) external view returns (int256);

    function fundingRateFactor(uint256 _tokenId) external view returns (uint256);

    function slippageFactor(uint256 _tokenId) external view returns (uint256);

    function getFundingFee(
        uint256 _tokenId,
        bool _isLong,
        uint256 _size,
        int256 _fundingIndex
    ) external view returns (int256);

    function getFundingChange(uint256 _tokenId) external view returns (int256);

    function getBorrowRate(uint256 _tokenId, bool _isLong) external view returns (uint256);

    function getFundingRate(uint256 _tokenId) external view returns (int256);

    function getTradingFee(
        address _account,
        uint256 _tokenId,
        bool _isLong,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getPnl(
        uint256 _tokenId,
        bool _isLong,
        uint256 _size,
        uint256 _averagePrice,
        uint256 _lastPrice,
        uint256 _lastIncreasedTime,
        uint256 _accruedBorrowFee,
        int256 _fundingIndex
    ) external view returns (int256, int256, int256);

    function updateFunding(uint256 _tokenId) external;

    function getBorrowFee(
        uint256 _borrowedSize,
        uint256 _lastIncreasedTime,
        uint256 _tokenId,
        bool _isLong
    ) external view returns (uint256);

    function getUndiscountedTradingFee(
        uint256 _tokenId,
        bool _isLong,
        uint256 _sizeDelta
    ) external view returns (uint256);

    function getReferFee(address _refer) external view returns (uint256);

    function getPriceWithSlippage(
        uint256 _tokenId,
        bool _isLong,
        uint256 _size,
        uint256 _price
    ) external view returns (uint256);

    function getDelegates(address _master) external view returns (address[] memory);

    function isDeposit(address _token) external view returns (bool);

    function isStakingEnabled(address _token) external view returns (bool);

    function isUnstakingEnabled(address _token) external view returns (bool);

    function isIncreasingPositionDisabled(uint256 _tokenId) external view returns (bool);

    function isDecreasingPositionDisabled(uint256 _tokenId) external view returns (bool);

    function isWhitelistedFromCooldown(address _addr) external view returns (bool);

    function isWhitelistedFromTransferCooldown(address _addr) external view returns (bool);

    function isWithdraw(address _token) external view returns (bool);

    function lastFundingTimes(uint256 _tokenId) external view returns (uint256);

    function liquidateThreshold(uint256) external view returns (uint256);

    function tradingFee(uint256 _tokenId, bool _isLong) external view returns (uint256);

    function defaultMaxOpenInterestPerUser() external view returns (uint256);

    function maxProfitPercent(uint256 _tokenId) external view returns (uint256);

    function defaultMaxProfitPercent() external view returns (uint256);

    function maxOpenInterestPerAssetPerSide(uint256 _tokenId, bool _isLong) external view returns (uint256);

    function priceMovementPercent() external view returns (uint256);

    function maxOpenInterestPerUser(address _account) external view returns (uint256);

    function stakingFee(address token) external view returns (uint256);

    function unstakingFee(address token) external view returns (uint256);

    function triggerGasFee() external view returns (uint256);

    function marketOrderGasFee() external view returns (uint256);

    function maxTriggerPerPosition() external view returns (uint256);

    function maxFundingRate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IVault {
    function accountDeltaIntoTotalUSD(bool _isIncrease, uint256 _delta) external;

    function distributeFee(uint256 _fee, address _refer) external;

    function takeVUSDIn(address _account, uint256 _amount) external;

    function takeVUSDOut(address _account, uint256 _amount) external;

    function lastStakedAt(address _account) external view returns (uint256);

    function getVaultUSDBalance() external view returns (uint256);

    function getVLPPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

enum OrderType {
    MARKET,
    LIMIT,
    STOP,
    STOP_LIMIT
}

enum OrderStatus {
    NONE,
    PENDING,
    FILLED,
    CANCELED
}

enum TriggerStatus {
    NONE,
    PENDING,
    OPEN,
    TRIGGERED,
    CANCELLED
}

struct Order {
    OrderStatus status;
    uint256 lmtPrice;
    uint256 size;
    uint256 collateral;
    uint256 positionType;
    uint256 stepAmount;
    uint256 stepType;
    uint256 stpPrice;
    uint256 timestamp;
}

struct AddPositionOrder {
    address owner;
    uint256 collateral;
    uint256 size;
    uint256 allowedPrice;
    uint256 timestamp;
    uint256 fee;
}

struct DecreasePositionOrder {
    uint256 size;
    uint256 allowedPrice;
    uint256 timestamp;
}

struct Position {
    address owner;
    address refer;
    bool isLong;
    uint256 tokenId;
    uint256 averagePrice;
    uint256 collateral;
    int256 fundingIndex;
    uint256 lastIncreasedTime;
    uint256 size;
    uint256 accruedBorrowFee;
}

struct PaidFees {
    uint256 paidPositionFee;
    uint256 paidBorrowFee;
    int256 paidFundingFee;
}

struct Temp {
    uint256 a;
    uint256 b;
    uint256 c;
    uint256 d;
    uint256 e;
}

struct TriggerInfo {
    bool isTP;
    uint256 amountPercent;
    uint256 createdAt;
    uint256 price;
    uint256 triggeredAmount;
    uint256 triggeredAt;
    TriggerStatus status;
}

struct PositionTrigger {
    TriggerInfo[] triggers;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../tokens/interfaces/IMintable.sol";
import "../tokens/interfaces/IVUSD.sol";
import "./interfaces/IPositionVault.sol";
import "./interfaces/ILiquidateVault.sol";
import "./interfaces/IOrderVault.sol";
import "./interfaces/IPriceManager.sol";
import "./interfaces/ISettingsManager.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IOperators.sol";
import {Constants} from "../access/Constants.sol";
import {Position, OrderStatus, OrderType} from "./structs.sol";

contract Vault is Constants, Initializable, ReentrancyGuardUpgradeable, IVault {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // constants
    IPositionVault private positionVault;
    IOrderVault private orderVault;
    ILiquidateVault private liquidateVault;
    IOperators public operators;
    IPriceManager private priceManager;
    ISettingsManager private settingsManager;
    address private vlp;
    address private vusd;
    bool private isInitialized;

    // variables
    uint256 public totalUSD;
    mapping(address => uint256) public override lastStakedAt;
    IERC20Upgradeable private USDC;
    mapping(address => uint256) public lastStakedBlockAt;

    event Deposit(address indexed account, address indexed token, uint256 amount);
    event Withdraw(address indexed account, address indexed token, uint256 amount);
    event Stake(address indexed account, address token, uint256 amount, uint256 mintAmount);
    event Unstake(address indexed account, address token, uint256 vlpAmount, uint256 amountOut);
    event ForceClose(uint256 indexed posId, address indexed account, uint256 exceededPnl);
    event ReferFeeTransfer(address indexed account, uint256 amount);

    modifier onlyVault() {
        _onlyVault();
        _;
    }

    function _onlyVault() private view {
        require(
            msg.sender == address(positionVault) ||
                msg.sender == address(liquidateVault) ||
                msg.sender == address(orderVault),
            "Only vault"
        );
    }

    modifier preventBanners(address _account) {
        _preventBanners(_account);
        _;
    }

    function _preventBanners(address _account) private view {
        require(!settingsManager.checkBanList(_account), "Account banned");
    }

    modifier onlyOperator(uint256 level) {
        _onlyOperator(level);
        _;
    }

    function _onlyOperator(uint256 level) private view {
        require(operators.getOperatorLevel(msg.sender) >= level, "invalid operator");
    }

    /* ========== INITIALIZE FUNCTIONS ========== */

    function initialize(address _operators, address _vlp, address _vusd) public initializer {
        require(AddressUpgradeable.isContract(_operators), "operators invalid");

        __ReentrancyGuard_init();
        operators = IOperators(_operators);
        vlp = _vlp;
        vusd = _vusd;
    }

    function setVaultSettings(
        IPriceManager _priceManager,
        ISettingsManager _settingsManager,
        IPositionVault _positionVault,
        IOrderVault _orderVault,
        ILiquidateVault _liquidateVault
    ) external onlyOperator(4) {
        require(!isInitialized, "initialized");
        require(AddressUpgradeable.isContract(address(_priceManager)), "priceManager invalid");
        require(AddressUpgradeable.isContract(address(_settingsManager)), "settingsManager invalid");
        require(AddressUpgradeable.isContract(address(_positionVault)), "positionVault invalid");
        require(AddressUpgradeable.isContract(address(_orderVault)), "orderVault invalid");
        require(AddressUpgradeable.isContract(address(_liquidateVault)), "liquidateVault invalid");

        priceManager = _priceManager;
        settingsManager = _settingsManager;
        positionVault = _positionVault;
        orderVault = _orderVault;
        liquidateVault = _liquidateVault;
        isInitialized = true;
    }

    function setUSDC(IERC20Upgradeable _token) external onlyOperator(3) {
        USDC = _token;
    }

    /* ========== CORE FUNCTIONS ========== */

    // deposit stablecoin to mint vusd
    function deposit(address _account, address _token, uint256 _amount) public nonReentrant preventBanners(msg.sender) {
        require(settingsManager.isDeposit(_token), "deposit not allowed");
        require(_amount > 0, "zero amount");
        if (_account != msg.sender) {
            require(settingsManager.checkDelegation(_account, msg.sender), "Not allowed");
        }

        IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 usdAmount = priceManager.tokenToUsd(_token, _amount);
        uint256 depositFee = (usdAmount * settingsManager.depositFee(_token)) / BASIS_POINTS_DIVISOR;
        _distributeFee(depositFee, address(0));

        IVUSD(vusd).mint(_account, usdAmount - depositFee);

        emit Deposit(_account, _token, _amount);
    }

    function depositSelf(address _token, uint256 _amount) external {
        deposit(msg.sender, _token, _amount);
    }

    function depositSelfUSDC(uint256 _amount) external {
        deposit(msg.sender, address(USDC), _amount);
    }

    function depositSelfAllUSDC() external {
        deposit(msg.sender, address(USDC), USDC.balanceOf(msg.sender));
    }

    // burn vusd to withdraw stablecoin
    function withdraw(address _token, uint256 _amount) public nonReentrant preventBanners(msg.sender) {
        require(settingsManager.isWithdraw(_token), "withdraw not allowed");
        require(_amount > 0, "zero amount");

        IVUSD(vusd).burn(address(msg.sender), _amount);

        uint256 withdrawFee = (_amount * settingsManager.withdrawFee(_token)) / BASIS_POINTS_DIVISOR;
        _distributeFee(withdrawFee, address(0));

        uint256 tokenAmount = priceManager.usdToToken(_token, _amount - withdrawFee);
        IERC20Upgradeable(_token).safeTransfer(msg.sender, tokenAmount);

        emit Withdraw(address(msg.sender), _token, tokenAmount);
    }

    function withdrawUSDC(uint256 _amount) external {
        withdraw(address(USDC), _amount);
    }

    function withdrawAllUSDC() external {
        withdraw(address(USDC), IVUSD(vusd).balanceOf(msg.sender));
    }

    // stake stablecoin to mint vlp
    function stake(address _account, address _token, uint256 _amount) public nonReentrant preventBanners(msg.sender) {
        require(settingsManager.isStakingEnabled(_token), "staking disabled");
        require(_amount > 0, "zero amount");
        if (_account != msg.sender) require(settingsManager.checkDelegation(_account, msg.sender), "Not allowed");

        IERC20Upgradeable(_token).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 usdAmount = priceManager.tokenToUsd(_token, _amount);
        uint256 stakingFee = (usdAmount * settingsManager.stakingFee(_token)) / BASIS_POINTS_DIVISOR;
        uint256 usdAmountAfterFee = usdAmount - stakingFee;

        uint256 mintAmount;
        uint256 totalVLP = IERC20Upgradeable(vlp).totalSupply();
        if (totalVLP == 0) {
            mintAmount =
                (usdAmountAfterFee * DEFAULT_VLP_PRICE * (10 ** VLP_DECIMALS)) /
                (PRICE_PRECISION * BASIS_POINTS_DIVISOR);
        } else {
            mintAmount = (usdAmountAfterFee * totalVLP) / totalUSD;
        }

        _distributeFee(stakingFee, address(0));

        totalUSD += usdAmountAfterFee;
        lastStakedAt[_account] = block.timestamp;
        lastStakedBlockAt[_account] = block.number;
        IMintable(vlp).mint(_account, mintAmount);

        emit Stake(_account, _token, _amount, mintAmount);
    }

    function stakeSelf(address _token, uint256 _amount) external {
        stake(msg.sender, _token, _amount);
    }

    function stakeSelfUSDC(uint256 _amount) external {
        stake(msg.sender, address(USDC), _amount);
    }

    function stakeSelfAllUSDC() external {
        stake(msg.sender, address(USDC), USDC.balanceOf(msg.sender));
    }

    // burn vlp to unstake stablecoin
    // vlp cannot be unstaked or transferred within cooldown period, except whitelisted contracts
    function unstake(address _tokenOut, uint256 _vlpAmount) public nonReentrant preventBanners(msg.sender) {
        require(settingsManager.isUnstakingEnabled(_tokenOut), "unstaking disabled");
        uint256 totalVLP = IERC20Upgradeable(vlp).totalSupply();
        require(_vlpAmount > 0 && _vlpAmount <= totalVLP, "vlpAmount error");
        require(block.number > lastStakedBlockAt[msg.sender], "current block not yet passed");
        if (settingsManager.isWhitelistedFromCooldown(msg.sender) == false) {
            require(
                lastStakedAt[msg.sender] + settingsManager.cooldownDuration() <= block.timestamp,
                "cooldown duration not yet passed"
            );
        }

        IMintable(vlp).burn(msg.sender, _vlpAmount);

        uint256 usdAmount = (_vlpAmount * totalUSD) / totalVLP;
        uint256 unstakingFee = (usdAmount * settingsManager.unstakingFee(_tokenOut)) / BASIS_POINTS_DIVISOR;

        _distributeFee(unstakingFee, address(0));

        totalUSD -= usdAmount;
        uint256 tokenAmountOut = priceManager.usdToToken(_tokenOut, usdAmount - unstakingFee);
        IERC20Upgradeable(_tokenOut).safeTransfer(msg.sender, tokenAmountOut);

        emit Unstake(msg.sender, _tokenOut, _vlpAmount, tokenAmountOut);
    }

    function unstakeUSDC(uint256 _vlpAmount) external {
        unstake(address(USDC), _vlpAmount);
    }

    function unstakeAllUSDC() external {
        unstake(address(USDC), IERC20Upgradeable(vlp).balanceOf(msg.sender));
    }

    // submit order to create a new position
    function newPositionOrder(
        uint256 _tokenId,
        bool _isLong,
        OrderType _orderType,
        // 0 -> market order
        // 1 -> limit order
        // 2 -> stop-market order
        // 3 -> stop-limit order
        uint256[] memory _params,
        // for market order:  _params[0] -> allowed price (revert if exceeded)
        // for limit order: _params[0] -> limit price
        // In stop-market order: _params[1] -> stop price,
        // In stop-limit order: _params[0] -> limit price, _params[1] -> stop price
        // for all orders: _params[2] -> collateral
        // for all orders: _params[3] -> size
        address _refer
    ) public payable nonReentrant preventBanners(msg.sender) {
        if (_orderType == OrderType.MARKET) {
            require(msg.value == settingsManager.marketOrderGasFee(), "invalid marketOrderGasFee");
        } else {
            require(msg.value == settingsManager.triggerGasFee(), "invalid triggerGasFee");
        }
        (bool success, ) = payable(settingsManager.feeManager()).call{value: msg.value}("");
        require(success, "failed to send fee");
        require(_refer != msg.sender, "Refer error");
        positionVault.newPositionOrder(msg.sender, _tokenId, _isLong, _orderType, _params, _refer);
    }

    function newPositionOrderPacked(uint256 a, uint256 b, uint256 c) external payable {
        uint256 tokenId = a / 2 ** 240; //16 bits for tokenId
        uint256 tmp = (a % 2 ** 240) / 2 ** 232;
        bool isLong = tmp / 2 ** 7 == 1; // 1 bit for isLong
        OrderType orderType = OrderType(tmp % 2 ** 7); // 7 bits for orderType
        address refer = address(uint160(a)); //last 160 bit for refer
        uint256[] memory params = new uint256[](4);
        params[0] = b / 2 ** 128; //price
        params[1] = b % 2 ** 128; //price
        params[2] = c / 2 ** 128; //collateral
        params[3] = c % 2 ** 128; //size
        newPositionOrder(tokenId, isLong, orderType, params, refer);
    }

    // submit order to create a new position with take profit / stop loss orders
    function newPositionOrderWithTPSL(
        uint256 _tokenId,
        bool _isLong,
        OrderType _orderType,
        // 0 -> market order
        // 1 -> limit order
        // 2 -> stop-market order
        // 3 -> stop-limit order
        uint256[] memory _params,
        // for market order:  _params[0] -> allowed price (revert if exceeded)
        // for limit order: _params[0] -> limit price
        // In stop-market order: _params[1] -> stop price,
        // In stop-limit order: _params[0] -> limit price, _params[1] -> stop price
        // for all orders: _params[2] -> collateral
        // for all orders: _params[3] -> size
        address _refer,
        bool[] memory _isTPs,
        uint256[] memory _prices,
        uint256[] memory _amountPercents
    ) external payable nonReentrant preventBanners(msg.sender) {
        if (_orderType == OrderType.MARKET) {
            require(
                msg.value == settingsManager.marketOrderGasFee() + _prices.length * settingsManager.triggerGasFee(),
                "invalid marketOrderGasFee"
            );
        } else {
            require(msg.value == (_prices.length + 1) * settingsManager.triggerGasFee(), "invalid triggerGasFee");
        }
        (bool success, ) = payable(settingsManager.feeManager()).call{value: msg.value}("");
        require(success, "failed to send fee");
        require(_refer != msg.sender, "Refer error");
        positionVault.newPositionOrder(msg.sender, _tokenId, _isLong, _orderType, _params, _refer);
        orderVault.addTriggerOrders(positionVault.lastPosId() - 1, msg.sender, _isTPs, _prices, _amountPercents);
    }

    // submit market order to increase size of exisiting position
    function addPosition(
        uint256 _posId,
        uint256 _collateralDelta,
        uint256 _sizeDelta,
        uint256 _allowedPrice
    ) public payable nonReentrant preventBanners(msg.sender) {
        require(msg.value == settingsManager.marketOrderGasFee(), "invalid triggerGasFee");
        (bool success, ) = payable(settingsManager.feeManager()).call{value: msg.value}("");
        require(success, "failed to send fee");

        positionVault.createAddPositionOrder(msg.sender, _posId, _collateralDelta, _sizeDelta, _allowedPrice);
    }

    function addPositionPacked(uint256 a, uint256 b) external payable {
        uint256 posId = a / 2 ** 128;
        uint256 collateralDelta = a % 2 ** 128;
        uint256 sizeDelta = b / 2 ** 128;
        uint256 allowedPrice = b % 2 ** 128;
        addPosition(posId, collateralDelta, sizeDelta, allowedPrice);
    }

    // add collateral to reduce leverage
    function addCollateral(uint256 _posId, uint256 _amount) public nonReentrant preventBanners(msg.sender) {
        positionVault.addOrRemoveCollateral(msg.sender, _posId, true, _amount);
    }

    // remove collateral to increase leverage
    function removeCollateral(uint256 _posId, uint256 _amount) public payable nonReentrant preventBanners(msg.sender) {
        require(msg.value == settingsManager.marketOrderGasFee(), "invalid triggerGasFee");
        (bool success, ) = payable(settingsManager.feeManager()).call{value: msg.value}("");
        require(success, "failed to send fee");

        positionVault.addOrRemoveCollateral(msg.sender, _posId, false, _amount);
    }

    function addOrRemoveCollateralPacked(uint256 a) external {
        uint256 posId = a >> 128;
        bool isPlus = (a >> 127) % 2 == 1;
        uint256 amount = a % 2 ** 127;
        if (isPlus) {
            return addCollateral(posId, amount);
        } else {
            return removeCollateral(posId, amount);
        }
    }

    // submit market order to decrease size of exisiting position
    function decreasePosition(
        uint256 _sizeDelta,
        uint256 _allowedPrice,
        uint256 _posId
    ) public payable nonReentrant preventBanners(msg.sender) {
        require(msg.value == settingsManager.marketOrderGasFee(), "invalid marketOrderGasFee");
        (bool success, ) = payable(settingsManager.feeManager()).call{value: msg.value}("");
        require(success, "failed to send fee");

        positionVault.createDecreasePositionOrder(_posId, msg.sender, _sizeDelta, _allowedPrice);
    }

    function decreasePositionPacked(uint256 a, uint256 _posId) external payable {
        uint256 sizeDelta = a / 2 ** 128;
        uint256 allowedPrice = a % 2 ** 128;
        return decreasePosition(sizeDelta, allowedPrice, _posId);
    }

    function addTPSL(
        uint256 _posId,
        bool[] memory _isTPs,
        uint256[] memory _prices,
        uint256[] memory _amountPercents
    ) public payable nonReentrant preventBanners(msg.sender) {
        require(msg.value == settingsManager.triggerGasFee() * _prices.length, "invalid triggerGasFee");
        (bool success, ) = payable(settingsManager.feeManager()).call{value: msg.value}("");
        require(success, "failed to send fee");

        orderVault.addTriggerOrders(_posId, msg.sender, _isTPs, _prices, _amountPercents);
    }

    function addTPSLPacked(uint256 a, uint256[] calldata _tps) external payable {
        uint256 posId = a / 2 ** 128;
        uint256 length = _tps.length;
        bool[] memory isTPs = new bool[](length);
        uint256[] memory prices = new uint256[](length);
        uint256[] memory amountPercents = new uint256[](length);
        for (uint i; i < length; ++i) {
            prices[i] = _tps[i] / 2 ** 128;
            isTPs[i] = (_tps[i] / 2 ** 127) % 2 == 1;
            amountPercents[i] = _tps[i] % 2 ** 127;
        }
        addTPSL(posId, isTPs, prices, amountPercents);
    }

    // submit trailing stop order to decrease size of exisiting position
    function addTrailingStop(
        uint256 _posId,
        uint256[] memory _params
    ) external payable nonReentrant preventBanners(msg.sender) {
        require(msg.value == settingsManager.triggerGasFee(), "invalid triggerGasFee");
        (bool success, ) = payable(settingsManager.feeManager()).call{value: msg.value}("");
        require(success, "failed to send fee");

        orderVault.addTrailingStop(msg.sender, _posId, _params);
    }

    // cancel pending newPositionOrder / trailingStopOrder
    function cancelPendingOrder(uint256 _posId) public nonReentrant preventBanners(msg.sender) {
        orderVault.cancelPendingOrder(msg.sender, _posId);
    }

    // cancel multiple pending newPositionOrder / trailingStopOrder
    function cancelPendingOrders(uint256[] memory _posIds) external preventBanners(msg.sender) {
        for (uint i = 0; i < _posIds.length; ++i) {
            orderVault.cancelPendingOrder(msg.sender, _posIds[i]);
        }
    }

    /* ========== HELPER FUNCTIONS ========== */

    // account trader's profit / loss into vault
    function accountDeltaIntoTotalUSD(bool _isIncrease, uint256 _delta) external override onlyVault {
        if (_delta > 0) {
            if (_isIncrease) {
                totalUSD += _delta;
            } else {
                require(totalUSD >= _delta, "exceeded VLP bottom");
                totalUSD -= _delta;
            }
        }
    }

    function distributeFee(uint256 _fee, address _refer) external override onlyVault {
        _distributeFee(_fee, _refer);
    }

    // to distribute fee among referrer, vault and feeManager
    function _distributeFee(uint256 _fee, address _refer) internal {
        if (_fee > 0) {
            if (_refer != address(0)) {
                uint256 referFee = (_fee * settingsManager.getReferFee(_refer)) / BASIS_POINTS_DIVISOR;
                IVUSD(vusd).mint(_refer, referFee);
                _fee -= referFee;
                emit ReferFeeTransfer(_refer, referFee);
            }

            uint256 feeForVLP = (_fee * settingsManager.feeRewardBasisPoints()) / BASIS_POINTS_DIVISOR;
            totalUSD += feeForVLP;
            IVUSD(vusd).mint(settingsManager.feeManager(), _fee - feeForVLP);
        }
    }

    function takeVUSDIn(address _account, uint256 _amount) external override onlyVault {
        IVUSD(vusd).burn(_account, _amount);
    }

    function takeVUSDOut(address _account, uint256 _amount) external override onlyVault {
        IVUSD(vusd).mint(_account, _amount);
    }

    /* ========== OPERATOR FUNCTIONS ========== */

    // allow admin to force close a user's position if the position profit > max profit % of totalUSD
    function forceClosePosition(uint256 _posId) external payable nonReentrant onlyOperator(1) {
        Position memory position = positionVault.getPosition(_posId);
        uint256 price = priceManager.getLastPrice(position.tokenId);
        (int256 pnl, , ) = settingsManager.getPnl(
            position.tokenId,
            position.isLong,
            position.size,
            position.averagePrice,
            price,
            position.lastIncreasedTime,
            position.accruedBorrowFee,
            position.fundingIndex
        );
        uint256 _maxProfitPercent = settingsManager.maxProfitPercent(position.tokenId) == 0
            ? settingsManager.defaultMaxProfitPercent()
            : settingsManager.maxProfitPercent(position.tokenId);
        uint256 maxPnl = (totalUSD * _maxProfitPercent) / BASIS_POINTS_DIVISOR;
        require(pnl > int256(maxPnl), "not allowed");
        positionVault.decreasePosition(_posId, price, position.size);
        uint256 exceededPnl = uint256(pnl) - maxPnl;
        IVUSD(vusd).burn(position.owner, exceededPnl); // cap user's pnl to maxPnl
        totalUSD += exceededPnl; // send pnl back to vault
        emit ForceClose(_posId, position.owner, exceededPnl);
    }

    /* ========== VIEW FUNCTIONS ========== */

    function getVLPPrice() external view returns (uint256) {
        uint256 totalVLP = IERC20Upgradeable(vlp).totalSupply();
        if (totalVLP == 0) {
            return DEFAULT_VLP_PRICE;
        } else {
            return (BASIS_POINTS_DIVISOR * (10 ** VLP_DECIMALS) * totalUSD) / (totalVLP * PRICE_PRECISION);
        }
    }

    function getVaultUSDBalance() external view override returns (uint256) {
        return totalUSD;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IMintable {
    function burn(address _account, uint256 _amount) external;

    function mint(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IVUSD {
    function burn(address _account, uint256 _amount) external;

    function mint(address _account, uint256 _amount) external;

    function balanceOf(address _account) external view returns (uint256);
}