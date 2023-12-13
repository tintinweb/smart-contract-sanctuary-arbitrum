// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
        return a > b ? a : b;
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
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

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
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
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
     * @dev Tries to returns the value associated with `key`. O(1).
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
     * @dev Returns the value associated with `key`. O(1).
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
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
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
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
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
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
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
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
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
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../../interfaces/IPriceHub.sol";

import "./libraries/LibGmxV2.sol";
import "./libraries/LibUtils.sol";
import "./Storage.sol";

abstract contract Getter is Storage {
    using LibUtils for IGmxV2Adatper.GmxAdapterStoreV2;
    using LibGmxV2 for IGmxV2Adatper.GmxAdapterStoreV2;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    function positionKey() external view returns (bytes32) {
        return _store.positionKey;
    }

    function muxAccountState() external view returns (AccountState memory) {
        return _store.account;
    }

    function getPendingOrders() external view returns (PendingOrder[] memory pendingOrders) {
        uint256 count = _store.pendingOrderIndexes.length();
        if (count == 0) {
            return pendingOrders;
        }
        pendingOrders = new PendingOrder[](count);
        for (uint256 i = 0; i < count; i++) {
            bytes32 key = _store.pendingOrderIndexes.at(i);
            OrderRecord memory record = _store.pendingOrders[key];
            pendingOrders[i] = PendingOrder({
                key: key,
                debtCollateralAmount: record.debtCollateralAmount,
                timestamp: record.timestamp,
                blockNumber: record.blockNumber,
                isIncreasing: record.isIncreasing
            });
        }
    }

    // 1e18
    function getMarginRate(Prices memory prices) external view returns (uint256) {
        return _store.getMarginRate(prices); // 1e18
    }

    function isLiquidateable(Prices memory prices) external view returns (bool) {
        return _store.getMarginRate(prices) < uint256(_store.marketConfigs.maintenanceMarginRate) * 1e13;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../../components/ImplementationGuard.sol";
import "./interfaces/gmx/IOrderCallbackReceiver.sol";
import "./interfaces/gmx/IRoleStore.sol";

import "./libraries/LibGmxV2.sol";
import "./libraries/LibDebt.sol";
import "./libraries/LibConfig.sol";

import "./Storage.sol";
import "./Getter.sol";

contract GmxV2Adapter is
    Storage,
    Getter,
    Initializable,
    ReentrancyGuardUpgradeable,
    ImplementationGuard,
    IOrderCallbackReceiver
{
    using LibUtils for uint256;
    using MathUpgradeable for uint256;

    using LibGmxV2 for GmxAdapterStoreV2;
    using LibConfig for GmxAdapterStoreV2;
    using LibDebt for GmxAdapterStoreV2;
    using LibUtils for GmxAdapterStoreV2;

    receive() external payable {}

    modifier onlyTrader() {
        require(_isValidCaller(), "OnlyTraderOrFactory");
        _;
    }

    modifier onlyKeeper() {
        require(IProxyFactory(_store.factory).isKeeper(msg.sender), "onlyKeeper");
        _;
    }

    modifier onlyValidCallbackSender() {
        require(_isValidCallbackSender(), "InvalidCallbackSender");
        _;
    }

    modifier onlyNotLiquidating() {
        require(!_store.account.isLiquidating, "Liquidating");
        _;
    }

    function initialize(
        uint256 projectId_,
        address liquidityPool,
        address owner,
        address collateralToken,
        address market,
        bool isLong
    ) external initializer onlyDelegateCall {
        require(liquidityPool != address(0), "InvalidLiquidityPool");
        require(projectId_ == PROJECT_ID, "InvalidProject");

        _store.factory = msg.sender;
        _store.liquidityPool = liquidityPool;
        _store.positionKey = keccak256(abi.encode(address(this), market, collateralToken, isLong));
        _store.account.isLong = isLong;
        _store.account.market = market;
        _store.account.owner = owner;

        _store.updateConfigs();
        _store.setupTokens(collateralToken);
        _store.setupCallback();
    }

    /// @notice Place a openning request on GMXv2.
    function placeOrder(
        OrderCreateParams memory createParams
    ) external payable onlyTrader onlyNotLiquidating nonReentrant returns (bytes32) {
        _store.updateConfigs();
        if (_isIncreasing(createParams.orderType)) {
            return _store.openPosition(createParams);
        } else {
            return _store.closePosition(createParams);
        }
    }

    function updateOrder(
        bytes32 key,
        uint256 sizeDeltaUsd,
        uint256 acceptablePrice,
        uint256 triggerPrice
    ) external onlyTrader onlyNotLiquidating nonReentrant {
        _store.updateConfigs();
        _store.updateOrder(key, sizeDeltaUsd, acceptablePrice, triggerPrice);
    }

    function liquidatePosition(
        Prices memory prices,
        uint256 executionFee,
        uint256 callbackGasLimit
    ) external payable onlyKeeper onlyNotLiquidating nonReentrant {
        _store.updateConfigs();
        _store.liquidatePosition(prices, executionFee, callbackGasLimit);
    }

    function cancelOrder(bytes32 key) external onlyTrader onlyNotLiquidating nonReentrant {
        _store.updateConfigs();
        _store.cancelOrder(key);
    }

    function cancelExpiredOrder(bytes32 key) external onlyNotLiquidating nonReentrant {
        _store.updateConfigs();
        _store.cancelExpiredOrder(key);
    }

    // =========================================== fee && reward ===========================================
    function claimFundingFees(
        address[] memory markets,
        address[] memory tokens
    ) external payable returns (uint256[] memory) {
        return
            IExchangeRouter(_store.projectConfigs.exchangeRouter).claimFundingFees(
                markets,
                tokens,
                _store.account.owner
            );
    }

    function claimToken(address token) external returns (uint256) {
        return _store.claimToken(token);
    }

    function claimNativeToken() external returns (uint256) {
        return _store.claimNativeToken();
    }

    // =========================================== calbacks ===========================================
    function afterOrderExecution(
        bytes32 key,
        IOrder.Props memory,
        IEvent.EventLogData memory
    ) external onlyValidCallbackSender {
        uint256 oldDebtCollateralAmount = _store.account.debtCollateralAmount;
        uint256 oldInflightDebtCollateralAmount = _store.account.inflightDebtCollateralAmount;
        uint256 oldPendingFeeCollateralAmount = _store.account.pendingFeeCollateralAmount;
        uint256 oldDebtEntryFunding = _store.account.debtEntryFunding;
        require(!_store.isOrderExist(key), "OrderNotFilled");
        OrderRecord memory pendingOrder = _store.removeOrder(key);
        if (!pendingOrder.isIncreasing) {
            Prices memory prices = _store.getOraclePrices();
            _store.repayDebt(prices);
        }
        _store.claimNativeToken();
        IEventEmitter(_store.projectConfigs.eventEmitter).onUpdateDebt(
            _store.account.owner,
            key,
            oldDebtCollateralAmount,
            oldInflightDebtCollateralAmount,
            oldPendingFeeCollateralAmount,
            oldDebtEntryFunding,
            _store.account.debtCollateralAmount,
            _store.account.inflightDebtCollateralAmount,
            _store.account.pendingFeeCollateralAmount,
            _store.account.debtEntryFunding
        );
    }

    function afterOrderCancellation(
        bytes32 key,
        IOrder.Props memory,
        IEvent.EventLogData memory
    ) external onlyValidCallbackSender {
        uint256 oldDebtCollateralAmount = _store.account.debtCollateralAmount;
        uint256 oldInflightDebtCollateralAmount = _store.account.inflightDebtCollateralAmount;
        uint256 oldPendingFeeCollateralAmount = _store.account.pendingFeeCollateralAmount;
        uint256 oldDebtEntryFunding = _store.account.debtEntryFunding;
        require(!_store.isOrderExist(key), "OrderNotCancelled");
        OrderRecord memory pendingOrder = _store.removeOrder(key);
        if (pendingOrder.isIncreasing) {
            _store.repayCancelledDebt(pendingOrder.collateralAmount, pendingOrder.debtCollateralAmount);
        }
        _store.claimNativeToken();
        IEventEmitter(_store.projectConfigs.eventEmitter).onUpdateDebt(
            _store.account.owner,
            key,
            oldDebtCollateralAmount,
            oldInflightDebtCollateralAmount,
            oldPendingFeeCollateralAmount,
            oldDebtEntryFunding,
            _store.account.debtCollateralAmount,
            _store.account.inflightDebtCollateralAmount,
            _store.account.pendingFeeCollateralAmount,
            _store.account.debtEntryFunding
        );
    }

    function afterOrderFrozen(
        bytes32 key,
        IOrder.Props memory,
        IEvent.EventLogData memory
    ) external onlyValidCallbackSender {}

    // =========================================== internals ===========================================
    function _isValidCallbackSender() internal view returns (bool) {
        if (IProxyFactory(_store.factory).isKeeper(msg.sender)) {
            return true;
        }
        // let it pass if the caller is a gmx controller
        IRoleStore roleStore = IRoleStore(IDataStore(_store.projectConfigs.dataStore).roleStore());
        if (roleStore.hasRole(msg.sender, CONTROLLER)) {
            return true;
        }
        return false;
    }

    function _isValidCaller() internal view returns (bool) {
        if (msg.sender == _store.factory) {
            return true;
        }
        if (msg.sender == _store.account.owner) {
            return true;
        }
        return false;
    }

    function _isIncreasing(IOrder.OrderType orderType) internal pure returns (bool) {
        return orderType == IOrder.OrderType.MarketIncrease || orderType == IOrder.OrderType.LimitIncrease;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

bytes32 constant MIN_COLLATERAL_USD = keccak256(abi.encode("MIN_COLLATERAL_USD"));
bytes32 constant POSITION_LIST = keccak256(abi.encode("POSITION_LIST"));

interface IDataStore {
    function roleStore() external view returns (address);

    function getUint(bytes32 key) external view returns (uint256);

    function getInt(bytes32 key) external view returns (int256);

    function getAddress(bytes32 key) external view returns (address);

    function getBool(bytes32 key) external view returns (bool);

    function getString(bytes32 key) external view returns (string memory);

    function getBytes32(bytes32 key) external view returns (bytes32);

    function getUintArray(bytes32 key) external view returns (uint256[] memory);

    function getIntArray(bytes32 key) external view returns (int256[] memory);

    function getAddressArray(bytes32 key) external view returns (address[] memory);

    function getBoolArray(bytes32 key) external view returns (bool[] memory);

    function getStringArray(bytes32 key) external view returns (string[] memory);

    function getBytes32Array(bytes32 key) external view returns (bytes32[] memory);

    function containsBytes32(bytes32 setKey, bytes32 value) external view returns (bool);

    function getBytes32Count(bytes32 setKey) external view returns (uint256);

    function getBytes32ValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (bytes32[] memory);

    function containsAddress(bytes32 setKey, address value) external view returns (bool);

    function getAddressCount(bytes32 setKey) external view returns (uint256);

    function getAddressValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (address[] memory);

    function containsUint(bytes32 setKey, uint256 value) external view returns (bool);

    function getUintCount(bytes32 setKey) external view returns (uint256);

    function getUintValuesAt(bytes32 setKey, uint256 start, uint256 end) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

interface IEvent {
    struct EmitPositionDecreaseParams {
        bytes32 key;
        address account;
        address market;
        address collateralToken;
        bool isLong;
    }

    struct EventLogData {
        AddressItems addressItems;
        UintItems uintItems;
        IntItems intItems;
        BoolItems boolItems;
        Bytes32Items bytes32Items;
        BytesItems bytesItems;
        StringItems stringItems;
    }

    struct AddressItems {
        AddressKeyValue[] items;
        AddressArrayKeyValue[] arrayItems;
    }

    struct UintItems {
        UintKeyValue[] items;
        UintArrayKeyValue[] arrayItems;
    }

    struct IntItems {
        IntKeyValue[] items;
        IntArrayKeyValue[] arrayItems;
    }

    struct BoolItems {
        BoolKeyValue[] items;
        BoolArrayKeyValue[] arrayItems;
    }

    struct Bytes32Items {
        Bytes32KeyValue[] items;
        Bytes32ArrayKeyValue[] arrayItems;
    }

    struct BytesItems {
        BytesKeyValue[] items;
        BytesArrayKeyValue[] arrayItems;
    }

    struct StringItems {
        StringKeyValue[] items;
        StringArrayKeyValue[] arrayItems;
    }

    struct AddressKeyValue {
        string key;
        address value;
    }

    struct AddressArrayKeyValue {
        string key;
        address[] value;
    }

    struct UintKeyValue {
        string key;
        uint256 value;
    }

    struct UintArrayKeyValue {
        string key;
        uint256[] value;
    }

    struct IntKeyValue {
        string key;
        int256 value;
    }

    struct IntArrayKeyValue {
        string key;
        int256[] value;
    }

    struct BoolKeyValue {
        string key;
        bool value;
    }

    struct BoolArrayKeyValue {
        string key;
        bool[] value;
    }

    struct Bytes32KeyValue {
        string key;
        bytes32 value;
    }

    struct Bytes32ArrayKeyValue {
        string key;
        bytes32[] value;
    }

    struct BytesKeyValue {
        string key;
        bytes value;
    }

    struct BytesArrayKeyValue {
        string key;
        bytes[] value;
    }

    struct StringKeyValue {
        string key;
        string value;
    }

    struct StringArrayKeyValue {
        string key;
        string[] value;
    }

    event EventLog(address msgSender, string eventName, string indexed eventNameHash, IEvent.EventLogData eventData);

    event EventLog1(
        address msgSender,
        string eventName,
        string indexed eventNameHash,
        bytes32 indexed topic1,
        IEvent.EventLogData eventData
    );

    event EventLog2(
        address msgSender,
        string eventName,
        string indexed eventNameHash,
        bytes32 indexed topic1,
        bytes32 indexed topic2,
        IEvent.EventLogData eventData
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IOrder.sol";

interface IExchangeRouter {
    struct CreateOrderParams {
        CreateOrderParamsAddresses addresses;
        CreateOrderParamsNumbers numbers;
        IOrder.OrderType orderType;
        IOrder.DecreasePositionSwapType decreasePositionSwapType;
        bool isLong;
        bool shouldUnwrapNativeToken;
        bytes32 referralCode;
    }

    // @param receiver for order.receiver
    // @param callbackContract for order.callbackContract
    // @param market for order.market
    // @param initialCollateralToken for order.initialCollateralToken
    // @param swapPath for order.swapPath
    struct CreateOrderParamsAddresses {
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    // @param sizeDeltaUsd for order.sizeDeltaUsd
    // @param triggerPrice for order.triggerPrice
    // @param acceptablePrice for order.acceptablePrice
    // @param executionFee for order.executionFee
    // @param callbackGasLimit for order.callbackGasLimit
    // @param minOutputAmount for order.minOutputAmount
    struct CreateOrderParamsNumbers {
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
    }

    function sendWnt(address receiver, uint256 amount) external payable;

    function sendTokens(address token, address receiver, uint256 amount) external payable;

    function sendNativeToken(address receiver, uint256 amount) external payable;

    function depositHandler() external view returns (address);

    function withdrawalHandler() external view returns (address);

    function orderHandler() external view returns (address);

    /**
     * @dev Creates a new order with the given amount, order parameters. The order is
     * created by transferring the specified amount of collateral tokens from the caller's account to the
     * order store, and then calling the `createOrder()` function on the order handler contract. The
     * referral code is also set on the caller's account using the referral storage contract.
     */
    function createOrder(CreateOrderParams calldata params) external payable returns (bytes32);

    function setSavedCallbackContract(address market, address callbackContract) external payable;

    /**
     * @dev Updates the given order with the specified size delta, acceptable price, and trigger price.
     * The `updateOrder()` feature must be enabled for the given order type. The caller must be the owner
     * of the order, and the order must not be a market order. The size delta, trigger price, and
     * acceptable price are updated on the order, and the order is unfrozen. Any additional WNT that is
     * transferred to the contract is added to the order's execution fee. The updated order is then saved
     * in the order store, and an `OrderUpdated` event is emitted.
     *
     * @param key The unique ID of the order to be updated
     * @param sizeDeltaUsd The new size delta for the order
     * @param acceptablePrice The new acceptable price for the order
     * @param triggerPrice The new trigger price for the order
     */
    function updateOrder(
        bytes32 key,
        uint256 sizeDeltaUsd,
        uint256 acceptablePrice,
        uint256 triggerPrice,
        uint256 minOutputAmount
    ) external payable;

    /**
     * @dev Cancels the given order. The `cancelOrder()` feature must be enabled for the given order
     * type. The caller must be the owner of the order, and the order must not be a market order. The
     * order is cancelled by calling the `cancelOrder()` function in the `OrderUtils` contract. This
     * function also records the starting gas amount and the reason for cancellation, which is passed to
     * the `cancelOrder()` function.
     *
     * @param key The unique ID of the order to be cancelled
     */
    function cancelOrder(bytes32 key) external payable;

    /**
     * @dev Claims funding fees for the given markets and tokens on behalf of the caller, and sends the
     * fees to the specified receiver. The length of the `markets` and `tokens` arrays must be the same.
     * For each market-token pair, the `claimFundingFees()` function in the `MarketUtils` contract is
     * called to claim the fees for the caller.
     *
     * @param markets An array of market addresses
     * @param tokens An array of token addresses, corresponding to the given markets
     * @param receiver The address to which the claimed fees should be sent
     */
    function claimFundingFees(
        address[] memory markets,
        address[] memory tokens,
        address receiver
    ) external payable returns (uint256[] memory);

    function claimCollateral(
        address[] memory markets,
        address[] memory tokens,
        uint256[] memory timeKeys,
        address receiver
    ) external payable returns (uint256[] memory);

    /**
     * @dev Claims affiliate rewards for the given markets and tokens on behalf of the caller, and sends
     * the rewards to the specified receiver. The length of the `markets` and `tokens` arrays must be
     * the same. For each market-token pair, the `claimAffiliateReward()` function in the `ReferralUtils`
     * contract is called to claim the rewards for the caller.
     *
     * @param markets An array of market addresses
     * @param tokens An array of token addresses, corresponding to the given markets
     * @param receiver The address to which the claimed rewards should be sent
     */
    function claimAffiliateRewards(
        address[] memory markets,
        address[] memory tokens,
        address receiver
    ) external payable returns (uint256[] memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IPrice.sol";

interface IMarket {
    struct Props {
        address marketToken;
        address indexToken;
        address longToken;
        address shortToken;
    }

    struct MarketPrices {
        IPrice.Props indexTokenPrice;
        IPrice.Props longTokenPrice;
        IPrice.Props shortTokenPrice;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./IExchangeRouter.sol";

interface IOrder {
    enum OrderType {
        // @dev MarketSwap: swap token A to token B at the current market price
        // the order will be cancelled if the minOutputAmount cannot be fulfilled
        MarketSwap,
        // @dev LimitSwap: swap token A to token B if the minOutputAmount can be fulfilled
        LimitSwap,
        // @dev MarketIncrease: increase position at the current market price
        // the order will be cancelled if the position cannot be increased at the acceptablePrice
        MarketIncrease,
        // @dev LimitIncrease: increase position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitIncrease,
        // @dev MarketDecrease: decrease position at the current market price
        // the order will be cancelled if the position cannot be decreased at the acceptablePrice
        MarketDecrease,
        // @dev LimitDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        LimitDecrease,
        // @dev StopLossDecrease: decrease position if the triggerPrice is reached and the acceptablePrice can be fulfilled
        StopLossDecrease,
        // @dev Liquidation: allows liquidation of positions if the criteria for liquidation are met
        Liquidation
    }

    enum DecreasePositionSwapType {
        NoSwap,
        SwapPnlTokenToCollateralToken,
        SwapCollateralTokenToPnlToken
    }

    struct Addresses {
        address account;
        address receiver;
        address callbackContract;
        address uiFeeReceiver;
        address market;
        address initialCollateralToken;
        address[] swapPath;
    }

    struct Numbers {
        OrderType orderType;
        DecreasePositionSwapType decreasePositionSwapType;
        uint256 sizeDeltaUsd;
        uint256 initialCollateralDeltaAmount;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        uint256 minOutputAmount;
        uint256 updatedAtBlock;
    }

    struct Flags {
        bool isLong;
        bool shouldUnwrapNativeToken;
        bool isFrozen;
    }

    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.0;

import "./IEvent.sol";
import "./IOrder.sol";

// @title IOrderCallbackReceiver
// @dev interface for an order callback contract
interface IOrderCallbackReceiver {
    // @dev called after an order execution
    // @param key the key of the order
    // @param order the order that was executed
    function afterOrderExecution(bytes32 key, IOrder.Props memory order, IEvent.EventLogData memory eventData) external;

    // @dev called after an order cancellation
    // @param key the key of the order
    // @param order the order that was cancelled
    function afterOrderCancellation(
        bytes32 key,
        IOrder.Props memory order,
        IEvent.EventLogData memory eventData
    ) external;

    // @dev called after an order has been frozen, see OrderUtils.freezeOrder in OrderHandler for more info
    // @param key the key of the order
    // @param order the order that was frozen
    function afterOrderFrozen(bytes32 key, IOrder.Props memory order, IEvent.EventLogData memory eventData) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IPosition {
    struct Props {
        Addresses addresses;
        Numbers numbers;
        Flags flags;
    }

    struct Addresses {
        address account;
        address market;
        address collateralToken;
    }
    struct Numbers {
        uint256 sizeInUsd;
        uint256 sizeInTokens;
        uint256 collateralAmount;
        uint256 borrowingFactor;
        uint256 fundingFeeAmountPerSize;
        uint256 longTokenClaimableFundingAmountPerSize;
        uint256 shortTokenClaimableFundingAmountPerSize;
        uint256 increasedAtBlock;
        uint256 decreasedAtBlock;
    }

    struct Flags {
        bool isLong;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IPrice.sol";

interface IPositionPricing {
    struct PositionBorrowingFees {
        uint256 borrowingFeeUsd;
        uint256 borrowingFeeAmount;
        uint256 borrowingFeeReceiverFactor;
        uint256 borrowingFeeAmountForFeeReceiver;
    }

    struct PositionFundingFees {
        uint256 fundingFeeAmount;
        uint256 claimableLongTokenAmount;
        uint256 claimableShortTokenAmount;
        uint256 latestFundingFeeAmountPerSize;
        uint256 latestLongTokenClaimableFundingAmountPerSize;
        uint256 latestShortTokenClaimableFundingAmountPerSize;
    }

    struct PositionReferralFees {
        bytes32 referralCode;
        address affiliate;
        address trader;
        uint256 totalRebateFactor;
        uint256 traderDiscountFactor;
        uint256 totalRebateAmount;
        uint256 traderDiscountAmount;
        uint256 affiliateRewardAmount;
    }

    struct PositionUiFees {
        address uiFeeReceiver;
        uint256 uiFeeReceiverFactor;
        uint256 uiFeeAmount;
    }

    struct PositionFees {
        PositionReferralFees referral;
        PositionFundingFees funding;
        PositionBorrowingFees borrowing;
        PositionUiFees ui;
        IPrice.Props collateralTokenPrice;
        uint256 positionFeeFactor;
        uint256 protocolFeeAmount;
        uint256 positionFeeReceiverFactor;
        uint256 feeReceiverAmount;
        uint256 feeAmountForPool;
        uint256 positionFeeAmountForPool;
        uint256 positionFeeAmount;
        uint256 totalCostAmountExcludingFunding;
        uint256 totalCostAmount;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IPrice {
    struct Props {
        uint256 min;
        uint256 max;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IPrice.sol";
import "./IOrder.sol";
import "./IMarket.sol";
import "./IPosition.sol";
import "./IPositionPricing.sol";

interface IReader {
    struct ExecutionPriceResult {
        int256 priceImpactUsd;
        uint256 priceImpactDiffUsd;
        uint256 executionPrice;
    }

    struct PositionInfo {
        IPosition.Props position;
        IPositionPricing.PositionFees fees;
        ExecutionPriceResult executionPriceResult;
        int256 basePnlUsd;
        int256 uncappedBasePnlUsd;
        int256 pnlAfterPriceImpactUsd;
    }

    function getPositionInfo(
        address dataStore,
        address referralStorage,
        bytes32 positionKey,
        IMarket.MarketPrices memory prices,
        uint256 sizeDeltaUsd,
        address uiFeeReceiver,
        bool usePositionSizeAsSizeDeltaUsd
    ) external view returns (PositionInfo memory);

    function getPosition(address dataStore, bytes32 key) external view returns (IPosition.Props memory);

    function getOrder(address dataStore, bytes32 key) external view returns (IOrder.Props memory);

    function getAccountOrders(
        address dataStore,
        address account,
        uint256 start,
        uint256 end
    ) external view returns (IOrder.Props[] memory);

    function getMarket(address dataStore, address key) external view returns (IMarket.Props memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IMarket.sol";

interface IReaderLite {
    function getMarketTokens(
        address dataStore,
        address key
    ) external view returns (address marketToken, address indexToken, address longToken, address shortToken);

    function isOrderExist(address dataStore, bytes32 orderKey) external view returns (bool);

    function getPositionSizeInUsd(address dataStore, bytes32 positionKey) external view returns (uint256);

    function getPositionMarginInfo(
        address dataStore,
        address referralStorage,
        bytes32 positionKey,
        IMarket.MarketPrices memory prices
    )
        external
        view
        returns (uint256 collateralAmount, uint256 sizeInUsd, uint256 totalCostAmount, int256 pnlAfterPriceImpactUsd);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

bytes32 constant CONTROLLER = keccak256(abi.encode("CONTROLLER"));

interface IRoleStore {
    function hasRole(address account, bytes32 roleKey) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "../interfaces/IGmxV2Adatper.sol";

interface IEventEmitter {
    event PlacePositionOrder(
        address indexed proxy,
        address indexed proxyOwner,
        IGmxV2Adatper.OrderCreateParams createParams,
        IGmxV2Adatper.PositionResult result
    );
    event PlaceLiquidateOrder(address indexed proxy, address indexed proxyOwner, IGmxV2Adatper.PositionResult result);
    event BorrowCollateral(address indexed proxy, address indexed proxyOwner, IGmxV2Adatper.DebtResult result);
    event RepayCollateral(address indexed proxy, address indexed proxyOwner, IGmxV2Adatper.DebtResult result);
    event UpdateOrder(
        address indexed proxy,
        address indexed proxyOwner,
        bytes32 indexed key,
        uint256 sizeDeltaUsd,
        uint256 acceptablePrice,
        uint256 triggerPrice
    );
    event CancelOrder(address indexed proxy, address indexed proxyOwner, bytes32 key);
    event UpdateDebt(
        address indexed proxy,
        address indexed proxyOwner,
        bytes32 indexed key,
        uint256 oldDebtCollateralAmount,
        uint256 oldInflightDebtCollateralAmount,
        uint256 oldPendingFeeCollateralAmount,
        uint256 oldDebtEntryFunding,
        uint256 newDebtCollateralAmount,
        uint256 newInflightDebtCollateralAmount,
        uint256 newPendingFeeCollateralAmount,
        uint256 newDebtEntryFunding
    );

    function onPlacePositionOrder(
        address proxyOwner,
        IGmxV2Adatper.OrderCreateParams calldata createParams,
        IGmxV2Adatper.PositionResult calldata result
    ) external;

    function onPlaceLiquidateOrder(address proxyOwner, IGmxV2Adatper.PositionResult calldata result) external;

    function onBorrowCollateral(address proxyOwner, IGmxV2Adatper.DebtResult calldata result) external;

    function onRepayCollateral(address proxyOwner, IGmxV2Adatper.DebtResult calldata result) external;

    function onUpdateOrder(
        address proxyOwner,
        bytes32 key,
        uint256 sizeDeltaUsd,
        uint256 acceptablePrice,
        uint256 triggerPrice
    ) external;

    function onCancelOrder(address proxyOwner, bytes32 key) external;

    function onUpdateDebt(
        address proxyOwner,
        bytes32 key,
        uint256 oldDebtCollateralAmount, // collateral decimals
        uint256 oldInflightDebtCollateralAmount, // collateral decimals
        uint256 oldPendingFeeCollateralAmount, // collateral decimals
        uint256 oldDebtEntryFunding,
        uint256 newDebtCollateralAmount, // collateral decimals
        uint256 newInflightDebtCollateralAmount, // collateral decimals
        uint256 newPendingFeeCollateralAmount, // collateral decimals
        uint256 newDebtEntryFunding
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";

import "./gmx/IOrder.sol";

address constant WETH = address(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);

uint256 constant PROJECT_ID = 2;
uint256 constant VIRTUAL_ASSET_ID = 255;

uint8 constant POSITION_MARKET_ORDER = 0x40;
uint8 constant POSITION_TPSL_ORDER = 0x08;

interface IGmxV2Adatper {
    enum ProjectConfigIds {
        SWAP_ROUTER,
        EXCHANGE_ROUTER,
        ORDER_VAULT,
        DATA_STORE,
        REFERRAL_STORE,
        READER,
        PRICE_HUB,
        EVENT_EMITTER,
        REFERRAL_CODE,
        FUNDING_ASSET_ID,
        FUNDING_ASSET,
        LIMIT_ORDER_EXPIRED_SECONDS,
        END
    }

    enum MarketConfigIds {
        BOOST_FEE_RATE,
        INITIAL_MARGIN_RATE,
        MAINTENANCE_MARGIN_RATE,
        LIQUIDATION_FEE_RATE,
        EMERGENCY_SWAP_SLIPPAGE,
        INDEX_DECIMALS,
        IS_BOOSTABLE,
        END
    }

    enum OrderCategory {
        Open,
        Close,
        TakeProfit,
        StopLoss,
        Liquidate
    }

    struct OrderRecord {
        bool isIncreasing;
        uint64 timestamp;
        uint256 blockNumber;
        uint256 collateralAmount;
        uint256 debtCollateralAmount;
    }

    struct PendingOrder {
        bytes32 key;
        uint256 debtCollateralAmount;
        uint256 timestamp;
        uint256 blockNumber;
        bool isIncreasing;
    }

    struct GmxAdapterStoreV2 {
        // =========
        address factory;
        address liquidityPool;
        bytes32 positionKey;
        // ==========
        uint32 projectConfigVersion;
        uint32 marketConfigVersion;
        uint8 shortTokenDecimals;
        uint8 longTokenDecimals;
        uint8 collateralTokenDecimals;
        ProjectConfigs projectConfigs;
        MarketConfigs marketConfigs;
        AccountState account;
        mapping(bytes32 => OrderRecord) pendingOrders;
        EnumerableSetUpgradeable.Bytes32Set pendingOrderIndexes;
        bytes32[50] __gaps;
    }

    struct ProjectConfigs {
        address swapRouter;
        address exchangeRouter;
        address orderVault;
        address dataStore;
        address referralStore;
        address reader;
        address priceHub;
        address eventEmitter;
        bytes32 referralCode;
        uint8 fundingAssetId;
        address fundingAsset;
        uint256 limitOrderExpiredSeconds;
        bytes32[9] reserved;
    }

    struct MarketConfigs {
        uint32 boostFeeRate;
        uint32 initialMarginRate;
        uint32 maintenanceMarginRate;
        uint32 liquidationFeeRate; // an extra fee rate for liquidation
        uint32 deleted0;
        uint8 indexDecimals;
        bool isBoostable;
        bytes32[10] reserved;
    }

    struct AccountState {
        address owner;
        address market;
        address indexToken;
        address longToken;
        address shortToken;
        address collateralToken;
        bool isLong;
        // --------------------------
        uint256 debtCollateralAmount; // collateral decimals
        uint256 inflightDebtCollateralAmount; // collateral decimals
        uint256 pendingFeeCollateralAmount; // collateral decimals
        uint256 debtEntryFunding;
        bool isLiquidating;
        bytes32[10] reserved;
    }

    struct OrderCreateParams {
        bytes swapPath;
        uint256 initialCollateralAmount;
        uint256 tokenOutMinAmount;
        uint256 borrowCollateralAmount;
        uint256 sizeDeltaUsd;
        uint256 triggerPrice;
        uint256 acceptablePrice;
        uint256 executionFee;
        uint256 callbackGasLimit;
        IOrder.OrderType orderType;
    }

    struct Prices {
        uint256 collateralPrice;
        uint256 indexTokenPrice;
        uint256 longTokenPrice;
        uint256 shortTokenPrice;
    }

    struct PositionResult {
        Prices prices;
        address gasToken;
        uint256 collateralAmount;
        uint256 borrowedCollateralAmount;
        bytes32 orderKey;
    }

    struct DebtResult {
        // common
        Prices prices;
        // repay
        uint256 collateralBalance;
        uint256 secondaryTokenBalance;
        uint256 debtCollateralAmount;
        // fee
        uint256 fundingFeeCollateralAmount;
        uint256 boostFeeCollateralAmount;
        uint256 liquidationFeeCollateralAmount;
        uint256 totalFeeCollateralAmount;
        // result
        uint256 repaidDebtCollateralAmount;
        uint256 repaidFeeCollateralAmount;
        uint256 repaidDebtSecondaryTokenAmount;
        uint256 repaidFeeSecondaryTokenAmount;
        uint256 unpaidDebtCollateralAmount;
        uint256 unpaidFeeCollateralAmount;
        // refund
        uint256 refundCollateralAmount;
        uint256 refundSecondaryTokenAmount;
        // borrow
        uint256 borrowedCollateralAmount;
    }

    function muxAccountState() external view returns (AccountState memory);

    function getPendingOrders() external view returns (PendingOrder[] memory pendingOrders);

    function placeOrder(OrderCreateParams memory createParams) external payable returns (bytes32);

    function updateOrder(bytes32 key, uint256 sizeDeltaUsd, uint256 acceptablePrice, uint256 triggerPrice) external;

    function cancelOrder(bytes32 key) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "../../../interfaces/IProxyFactory.sol";
import "../interfaces/IGmxV2Adatper.sol";

import "../libraries/LibUtils.sol";

library LibConfig {
    using LibUtils for uint256;

    function updateConfigs(IGmxV2Adatper.GmxAdapterStoreV2 storage store) internal {
        address market = store.account.market;

        (uint32 remoteProjectVersion, uint32 remoteMarketVersion) = IProxyFactory(store.factory).getConfigVersions(
            PROJECT_ID,
            market
        );

        if (store.projectConfigVersion < remoteProjectVersion) {
            updateProjectConfigs(store);
            store.projectConfigVersion = remoteProjectVersion;
        }
        // pull configs from factory
        if (store.marketConfigVersion < remoteMarketVersion) {
            updateMarketConfigs(store, market);
            store.marketConfigVersion = remoteMarketVersion;
        }
    }

    function updateProjectConfigs(IGmxV2Adatper.GmxAdapterStoreV2 storage store) public {
        uint256[] memory values = IProxyFactory(store.factory).getProjectConfig(PROJECT_ID);
        require(values.length >= uint256(IGmxV2Adatper.ProjectConfigIds.END), "MissingConfigs");
        store.projectConfigs.swapRouter = values[uint256(IGmxV2Adatper.ProjectConfigIds.SWAP_ROUTER)].toAddress();
        store.projectConfigs.exchangeRouter = values[uint256(IGmxV2Adatper.ProjectConfigIds.EXCHANGE_ROUTER)]
            .toAddress();
        store.projectConfigs.orderVault = values[uint256(IGmxV2Adatper.ProjectConfigIds.ORDER_VAULT)].toAddress();
        store.projectConfigs.dataStore = values[uint256(IGmxV2Adatper.ProjectConfigIds.DATA_STORE)].toAddress();
        store.projectConfigs.referralStore = values[uint256(IGmxV2Adatper.ProjectConfigIds.REFERRAL_STORE)].toAddress();
        store.projectConfigs.reader = values[uint256(IGmxV2Adatper.ProjectConfigIds.READER)].toAddress();
        store.projectConfigs.priceHub = values[uint256(IGmxV2Adatper.ProjectConfigIds.PRICE_HUB)].toAddress();
        store.projectConfigs.eventEmitter = values[uint256(IGmxV2Adatper.ProjectConfigIds.EVENT_EMITTER)].toAddress();
        store.projectConfigs.referralCode = values[uint256(IGmxV2Adatper.ProjectConfigIds.REFERRAL_CODE)].toBytes32();
        store.projectConfigs.fundingAssetId = values[uint256(IGmxV2Adatper.ProjectConfigIds.FUNDING_ASSET_ID)].toU8();
        store.projectConfigs.fundingAsset = values[uint256(IGmxV2Adatper.ProjectConfigIds.FUNDING_ASSET)].toAddress();
        store.projectConfigs.limitOrderExpiredSeconds = values[
            uint256(IGmxV2Adatper.ProjectConfigIds.LIMIT_ORDER_EXPIRED_SECONDS)
        ];
    }

    function updateMarketConfigs(IGmxV2Adatper.GmxAdapterStoreV2 storage store, address market) public {
        uint256[] memory values = IProxyFactory(store.factory).getProjectAssetConfig(PROJECT_ID, market);
        require(values.length >= uint256(IGmxV2Adatper.MarketConfigIds.END), "MissingConfigs");
        store.marketConfigs.boostFeeRate = values[uint256(IGmxV2Adatper.MarketConfigIds.BOOST_FEE_RATE)].toU32();
        store.marketConfigs.initialMarginRate = values[uint256(IGmxV2Adatper.MarketConfigIds.INITIAL_MARGIN_RATE)]
            .toU32();
        store.marketConfigs.maintenanceMarginRate = values[
            uint256(IGmxV2Adatper.MarketConfigIds.MAINTENANCE_MARGIN_RATE)
        ].toU32();
        store.marketConfigs.liquidationFeeRate = values[uint256(IGmxV2Adatper.MarketConfigIds.LIQUIDATION_FEE_RATE)]
            .toU32();
        store.marketConfigs.indexDecimals = values[uint256(IGmxV2Adatper.MarketConfigIds.INDEX_DECIMALS)].toU8();
        store.marketConfigs.isBoostable = values[uint256(IGmxV2Adatper.MarketConfigIds.IS_BOOSTABLE)] > 0;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../../interfaces/ILiquidityPool.sol";
import "../../../interfaces/IProxyFactory.sol";
import "../../../interfaces/ILendingPool.sol";
import "../../../interfaces/IWETH.sol";
import "../../../interfaces/IPriceHub.sol";

import "../interfaces/IGmxV2Adatper.sol";
import "../interfaces/IEventEmitter.sol";

import "./LibGmxV2.sol";
import "./LibUtils.sol";

library LibDebt {
    using LibUtils for uint256;
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    using LibGmxV2 for IGmxV2Adatper.GmxAdapterStoreV2;
    using LibUtils for IGmxV2Adatper.GmxAdapterStoreV2;

    uint56 internal constant ASSET_IS_STABLE = 0x00000000000001; // is stable

    // implementations
    function updateMuxFundingFee(IGmxV2Adatper.GmxAdapterStoreV2 storage store) internal returns (uint256) {
        (uint256 fundingFee, uint256 nextFunding) = getNextMuxFunding(store);
        store.account.pendingFeeCollateralAmount += fundingFee;
        store.account.debtEntryFunding = nextFunding;
        return fundingFee;
    }

    function getMuxFundingFee(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store
    ) internal view returns (uint256 fundingFee) {
        (fundingFee, ) = getNextMuxFunding(store);
    }

    function getNextMuxFunding(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store
    ) internal view returns (uint256 fundingFee, uint256 newFunding) {
        uint8 collateralId = IProxyFactory(store.factory).getAssetId(PROJECT_ID, store.account.collateralToken);
        // is virtual
        if (collateralId == VIRTUAL_ASSET_ID) {
            fundingFee = 0;
            newFunding = 0;
            return (fundingFee, newFunding);
        }
        ILiquidityPool.Asset memory asset = ILiquidityPool(store.liquidityPool).getAssetInfo(collateralId);
        if (asset.flags & ASSET_IS_STABLE == 0) {
            // unstable
            newFunding = asset.longCumulativeFundingRate; // 1e18
            fundingFee = ((newFunding - store.account.debtEntryFunding) * store.account.debtCollateralAmount) / 1e18; // collateral.decimal
        } else {
            // stable
            ILiquidityPool.Asset memory fundingAsset = ILiquidityPool(store.liquidityPool).getAssetInfo(
                store.projectConfigs.fundingAssetId
            );
            newFunding = fundingAsset.shortCumulativeFunding; // 1e18
            uint256 fundingTokenPrice = IPriceHub(store.projectConfigs.priceHub).getPriceByToken(
                store.projectConfigs.fundingAsset
            ); // 1e18
            fundingFee =
                ((newFunding - store.account.debtEntryFunding) * store.account.debtCollateralAmount) /
                fundingTokenPrice; // collateral.decimal
        }
    }

    function borrowCollateral(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        uint256 borrowCollateralAmount
    ) internal returns (uint256 borrowedCollateralAmount, uint256 boostFeeCollateralAmount) {
        boostFeeCollateralAmount = (borrowCollateralAmount * store.marketConfigs.boostFeeRate) / 1e5;
        borrowedCollateralAmount = borrowCollateralAmount - boostFeeCollateralAmount;
        borrow(store, borrowCollateralAmount, boostFeeCollateralAmount);
        store.account.debtCollateralAmount += borrowCollateralAmount;
    }

    function repayCancelledDebt(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        uint256 totalCollateralAmount,
        uint256 debtCollateralAmount
    ) internal {
        if (debtCollateralAmount == 0) {
            return;
        }
        IGmxV2Adatper.DebtResult memory result;
        result.fundingFeeCollateralAmount = updateMuxFundingFee(store);
        result.collateralBalance = IERC20Upgradeable(store.account.collateralToken).balanceOf(address(this));
        require(result.collateralBalance >= totalCollateralAmount, "NotEnoughBalance");
        (
            result.refundCollateralAmount,
            result.repaidDebtCollateralAmount,
            result.repaidFeeCollateralAmount
        ) = repayCancelledCollateral(store, debtCollateralAmount, totalCollateralAmount);
        transferTokenToOwner(store, store.account.collateralToken, result.refundCollateralAmount);
    }

    function repayCancelledCollateral(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        uint256 debtCollateralAmount,
        uint256 balance
    )
        internal
        returns (uint256 toUserCollateralAmount, uint256 repayCollateralAmount, uint256 boostFeeCollateralAmount)
    {
        toUserCollateralAmount = balance;
        // return collateral
        repayCollateralAmount = store.account.debtCollateralAmount.min(debtCollateralAmount);
        require(balance >= repayCollateralAmount, "InsufficientBalance");
        store.account.debtCollateralAmount -= repayCollateralAmount;
        toUserCollateralAmount -= repayCollateralAmount;
        // pay fee
        boostFeeCollateralAmount = repayCollateralAmount.rate(store.marketConfigs.boostFeeRate);
        if (toUserCollateralAmount >= boostFeeCollateralAmount) {
            // pay fee this time
            toUserCollateralAmount -= boostFeeCollateralAmount;
        } else {
            // pay fee next time
            store.account.pendingFeeCollateralAmount += boostFeeCollateralAmount;
            boostFeeCollateralAmount = 0;
        }
        repay(store, store.account.collateralToken, repayCollateralAmount, boostFeeCollateralAmount, 0);
    }

    function repayDebt(IGmxV2Adatper.GmxAdapterStoreV2 storage store, IGmxV2Adatper.Prices memory prices) internal {
        IGmxV2Adatper.DebtResult memory result;
        if (store.account.collateralToken == WETH) {
            IWETH(WETH).deposit{ value: address(this).balance }();
        }
        // 1. get oracle price and gmx position
        uint256 sizeInUsd = IReaderLite(store.projectConfigs.reader).getPositionSizeInUsd(
            store.projectConfigs.dataStore,
            store.positionKey
        );
        result.prices = prices;
        // 2. get balance in proxy
        result.fundingFeeCollateralAmount = updateMuxFundingFee(store);
        result.collateralBalance = IERC20Upgradeable(store.account.collateralToken).balanceOf(address(this));
        if (sizeInUsd != 0) {
            if (store.isOpenSafe(result.prices, 0, 0)) {
                result.refundCollateralAmount = result.collateralBalance;
                transferTokenToOwner(store, store.account.collateralToken, result.refundCollateralAmount);
            }
        } else {
            // check secondary token
            address secondaryToken = store.getSecondaryToken();
            result.secondaryTokenBalance = IERC20Upgradeable(secondaryToken).balanceOf(address(this));
            // totalDebt
            result.debtCollateralAmount =
                store.account.debtCollateralAmount -
                store.account.inflightDebtCollateralAmount;
            // totalFee
            result.boostFeeCollateralAmount = result.debtCollateralAmount.rate(store.marketConfigs.boostFeeRate);
            if (store.account.isLiquidating) {
                result.liquidationFeeCollateralAmount = result.debtCollateralAmount.rate(
                    store.marketConfigs.liquidationFeeRate
                );
            }
            result.totalFeeCollateralAmount =
                result.boostFeeCollateralAmount +
                store.account.pendingFeeCollateralAmount +
                result.liquidationFeeCollateralAmount;
            // repay by collateral
            result = repayByCollateral(store, result);
            if (result.unpaidDebtCollateralAmount > 0 || result.unpaidFeeCollateralAmount > 0) {
                // if there is secondary token, but debt has not been fully repaid
                // try repay left debt with secondary token ...
                result = repayBySecondaryToken(store, result, secondaryToken);
            } else {
                // or give all secondary token back to user
                result.refundSecondaryTokenAmount = result.secondaryTokenBalance;
            }
            store.account.debtCollateralAmount = store.account.inflightDebtCollateralAmount;
            store.account.pendingFeeCollateralAmount = 0;

            transferTokenToOwner(store, store.account.collateralToken, result.refundCollateralAmount);
            transferTokenToOwner(store, secondaryToken, result.refundSecondaryTokenAmount);
            store.account.isLiquidating = false;
        }
        IEventEmitter(store.projectConfigs.eventEmitter).onRepayCollateral(store.account.owner, result);
    }

    function repayByCollateral(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        IGmxV2Adatper.DebtResult memory result
    ) internal returns (IGmxV2Adatper.DebtResult memory) {
        // 0. total fee to repay
        result.refundCollateralAmount = result.collateralBalance;
        // 1. pay the debt, missing part will be turned into bad debt
        result.repaidDebtCollateralAmount = result.debtCollateralAmount.min(result.refundCollateralAmount);
        result.refundCollateralAmount -= result.repaidDebtCollateralAmount;
        // 2. pay the fee, if possible
        if (result.refundCollateralAmount > 0) {
            result.repaidFeeCollateralAmount = result.refundCollateralAmount.min(result.totalFeeCollateralAmount);
            result.refundCollateralAmount -= result.repaidFeeCollateralAmount;
        }
        result.unpaidDebtCollateralAmount = result.debtCollateralAmount - result.repaidDebtCollateralAmount;
        result.unpaidFeeCollateralAmount = result.totalFeeCollateralAmount - result.repaidFeeCollateralAmount;
        repay(
            store,
            store.account.collateralToken,
            result.repaidDebtCollateralAmount,
            result.repaidFeeCollateralAmount,
            0
        );
        return result;
    }

    function repayBySecondaryToken(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        IGmxV2Adatper.DebtResult memory result,
        address secondaryToken
    ) internal returns (IGmxV2Adatper.DebtResult memory) {
        uint256 collateralPrice = result.prices.collateralPrice;
        uint256 secondaryPrice = secondaryToken == store.account.longToken
            ? result.prices.longTokenPrice
            : result.prices.shortTokenPrice;

        uint8 collateralDecimals = store.collateralTokenDecimals;
        uint8 secondaryDecimals = IERC20MetadataUpgradeable(secondaryToken).decimals();
        if (result.secondaryTokenBalance > 0) {
            uint256 debtSecondaryAmount = ((result.unpaidDebtCollateralAmount * collateralPrice) / secondaryPrice)
                .toDecimals(collateralDecimals, secondaryDecimals);

            result.repaidDebtSecondaryTokenAmount = result.secondaryTokenBalance.min(debtSecondaryAmount);
            result.refundSecondaryTokenAmount = result.secondaryTokenBalance - result.repaidDebtSecondaryTokenAmount;

            if (result.refundSecondaryTokenAmount > 0) {
                uint256 debtFeeSecondaryAmount = ((result.unpaidFeeCollateralAmount * collateralPrice) / secondaryPrice)
                    .toDecimals(collateralDecimals, secondaryDecimals);
                result.repaidFeeSecondaryTokenAmount = result.refundSecondaryTokenAmount.min(debtFeeSecondaryAmount);
                result.refundSecondaryTokenAmount -= result.repaidFeeSecondaryTokenAmount;
            }
            result.unpaidDebtCollateralAmount -=
                (result.repaidDebtSecondaryTokenAmount.toDecimals(secondaryDecimals, collateralDecimals) *
                    secondaryPrice) /
                collateralPrice;
            result.unpaidFeeCollateralAmount -=
                (result.repaidFeeSecondaryTokenAmount.toDecimals(secondaryDecimals, collateralDecimals) *
                    secondaryPrice) /
                collateralPrice;
        }
        repay(
            store,
            secondaryToken,
            result.repaidDebtSecondaryTokenAmount,
            result.repaidFeeSecondaryTokenAmount,
            result.unpaidDebtCollateralAmount
        );
        return result;
    }

    // virtual methods
    function borrow(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        uint256 amount,
        uint256 fee
    ) internal returns (uint256 amountOut) {
        amountOut = IProxyFactory(store.factory).borrowAsset(PROJECT_ID, store.account.collateralToken, amount, fee);
    }

    function repay(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        address token,
        uint256 debtAmount,
        uint256 feeAmount,
        uint256 badDebt
    ) internal {
        IERC20Upgradeable(token).safeTransfer(store.factory, debtAmount + feeAmount);
        IProxyFactory(store.factory).repayAsset(PROJECT_ID, token, debtAmount, feeAmount, badDebt);
    }

    function transferTokenToOwner(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        address token,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }
        // TODO: send failed try/catch
        if (token == WETH) {
            IWETH(WETH).withdraw(amount);
            payable(store.account.owner).transfer(amount);
        } else {
            IERC20Upgradeable(token).safeTransfer(store.account.owner, amount);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../../../interfaces/IWETH.sol";
import "../interfaces/gmx/IReader.sol";
import "../interfaces/gmx/IDataStore.sol";
import "../interfaces/gmx/IExchangeRouter.sol";
import "../interfaces/IGmxV2Adatper.sol";
import "../interfaces/IEventEmitter.sol";

import "./LibSwap.sol";
import "./LibDebt.sol";
import "./LibUtils.sol";

library LibGmxV2 {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
    using LibSwap for IGmxV2Adatper.GmxAdapterStoreV2;
    using LibDebt for IGmxV2Adatper.GmxAdapterStoreV2;
    using LibUtils for IGmxV2Adatper.GmxAdapterStoreV2;
    using LibUtils for uint256;

    uint256 constant MAX_ORDER_COUNT = 32;

    struct GmxPositionInfo {
        uint256 collateralAmount;
        uint256 sizeInUsd;
        uint256 totalCostAmount;
        int256 pnlAfterPriceImpactUsd;
    }

    // ===================================== READ =============================================

    function getMarginValueUsd(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        uint256 collateralAmount,
        uint256 totalCostAmount,
        int256 pnlAfterPriceImpactUsd,
        uint256 collateralPrice
    ) internal view returns (uint256) {
        int256 collateralUsd = int256(
            ((collateralAmount * collateralPrice) / 1e18).toDecimals(store.collateralTokenDecimals, 30)
        ); // to 30

        int256 gmxPnlUsd = pnlAfterPriceImpactUsd;
        int256 gmxCostUsd = int256(
            (totalCostAmount * collateralPrice).toDecimals(store.collateralTokenDecimals + 18, 30)
        ); // to 30
        uint256 muxDebt = store.account.debtCollateralAmount +
            store.account.pendingFeeCollateralAmount +
            store.getMuxFundingFee() -
            store.account.inflightDebtCollateralAmount;
        int256 muxDebtUsd = int256(((muxDebt * collateralPrice) / 1e18).toDecimals(store.collateralTokenDecimals, 30)); // to 30
        int256 marginValueUsd = collateralUsd + gmxPnlUsd - gmxCostUsd - muxDebtUsd;

        return marginValueUsd >= 0 ? uint256(marginValueUsd) : 0; // truncate to 0
    }

    function makeGmxPrices(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        IGmxV2Adatper.Prices memory prices
    ) internal view returns (IMarket.MarketPrices memory) {
        uint256 indexTokenPrice = prices.indexTokenPrice.toDecimals(18, 30 - store.marketConfigs.indexDecimals);
        uint256 longTokenPrice = prices.longTokenPrice.toDecimals(18, 30 - store.longTokenDecimals);
        uint256 shortTokenPrice = prices.shortTokenPrice.toDecimals(18, 30 - store.shortTokenDecimals);

        return
            IMarket.MarketPrices({
                indexTokenPrice: IPrice.Props({ max: indexTokenPrice, min: indexTokenPrice }),
                longTokenPrice: IPrice.Props({ max: longTokenPrice, min: longTokenPrice }),
                shortTokenPrice: IPrice.Props({ max: shortTokenPrice, min: shortTokenPrice })
            });
    }

    // 1e18
    function getMarginRate(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        IGmxV2Adatper.Prices memory prices
    ) public view returns (uint256) {
        uint256 sizeInUsd = IReaderLite(store.projectConfigs.reader).getPositionSizeInUsd(
            store.projectConfigs.dataStore,
            store.positionKey
        );
        if (sizeInUsd == 0) {
            return 0;
        }
        GmxPositionInfo memory info;
        (info.collateralAmount, info.sizeInUsd, info.totalCostAmount, info.pnlAfterPriceImpactUsd) = IReaderLite(
            store.projectConfigs.reader
        ).getPositionMarginInfo(
                store.projectConfigs.dataStore,
                store.projectConfigs.referralStore,
                store.positionKey,
                makeGmxPrices(store, prices)
            );
        uint256 marginValueUsd = getMarginValueUsd(
            store,
            info.collateralAmount,
            info.totalCostAmount,
            info.pnlAfterPriceImpactUsd,
            prices.collateralPrice
        );
        return ((marginValueUsd) * 1e18) / (info.sizeInUsd);
    }

    function isMarginSafe(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        IGmxV2Adatper.Prices memory prices,
        uint256 deltaCollateralAmount, // without delta debt
        uint256 deltaSizeUsd,
        uint256 marginRateThreshold // 1e18
    ) public view returns (bool) {
        if (!store.marketConfigs.isBoostable) {
            return true;
        }
        uint256 sizeInUsd = IReaderLite(store.projectConfigs.reader).getPositionSizeInUsd(
            store.projectConfigs.dataStore,
            store.positionKey
        );
        if (sizeInUsd > 0) {
            GmxPositionInfo memory info;
            (info.collateralAmount, info.sizeInUsd, info.totalCostAmount, info.pnlAfterPriceImpactUsd) = IReaderLite(
                store.projectConfigs.reader
            ).getPositionMarginInfo(
                    store.projectConfigs.dataStore,
                    store.projectConfigs.referralStore,
                    store.positionKey,
                    makeGmxPrices(store, prices)
                );
            uint256 marginUsd = getMarginValueUsd(
                store,
                info.collateralAmount,
                info.totalCostAmount,
                info.pnlAfterPriceImpactUsd,
                prices.collateralPrice
            ); // 1e30
            if (marginUsd == 0) {
                // already bankrupt
                return false;
            }
            uint256 collateralUsd = ((deltaCollateralAmount * prices.collateralPrice) / 1e18).toDecimals(
                store.collateralTokenDecimals,
                30
            );
            uint256 nextMarginRate = ((marginUsd + collateralUsd) * 1e30) / (sizeInUsd + deltaSizeUsd) / 1e12; // 1e18
            if (nextMarginRate < marginRateThreshold) {
                return false;
            }
        } else {
            if (deltaSizeUsd == 0) {
                return true;
            }
            uint256 collateralUsd = ((deltaCollateralAmount * prices.collateralPrice) / 1e18).toDecimals(
                store.collateralTokenDecimals,
                30
            );
            uint256 nextMarginRate = ((collateralUsd) * 1e30) / (deltaSizeUsd) / 1e12; // 1e18
            if (nextMarginRate < marginRateThreshold) {
                return false;
            }
        }

        return true;
    }

    function isOpenSafe(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        IGmxV2Adatper.Prices memory prices,
        uint256 deltaCollateralAmount, // without delta debt
        uint256 deltaSizeUsd
    ) public view returns (bool) {
        return
            isMarginSafe(
                store,
                prices,
                deltaCollateralAmount,
                deltaSizeUsd,
                uint256(store.marketConfigs.initialMarginRate) * 1e13
            );
    }

    function isCloseSafe(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        IGmxV2Adatper.Prices memory prices
    ) public view returns (bool) {
        return isMarginSafe(store, prices, 0, 0, uint256(store.marketConfigs.maintenanceMarginRate) * 1e13);
    }

    // ===================================== WRITE =============================================
    function openPosition(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        IGmxV2Adatper.OrderCreateParams memory createParams
    ) external returns (bytes32) {
        require(store.pendingOrderIndexes.length() < MAX_ORDER_COUNT, "ExceedsMaxOrderCount");

        IGmxV2Adatper.PositionResult memory result;
        // swap
        if (createParams.swapPath.length != 0) {
            // swap tokenIn => collateral
            result.collateralAmount = store.swapCollateral(
                createParams.swapPath,
                createParams.initialCollateralAmount,
                createParams.tokenOutMinAmount,
                address(this)
            );
        } else {
            // no swap
            result.collateralAmount = createParams.initialCollateralAmount;
        }
        if (store.marketConfigs.isBoostable) {
            result.prices = store.getOraclePrices(); // check account safe
            require(
                isOpenSafe(store, result.prices, result.collateralAmount, createParams.sizeDeltaUsd),
                "UnsafeToOpen"
            );
        }
        // borrow
        if (createParams.borrowCollateralAmount > 0) {
            require(store.marketConfigs.isBoostable, "NotBoostable");
            result.borrowedCollateralAmount = borrowCollateral(
                store,
                result.prices,
                createParams.borrowCollateralAmount
            );
        }
        // place order
        uint256 totalCollateralAmount = result.collateralAmount + result.borrowedCollateralAmount;
        // execution fee
        IERC20Upgradeable(store.account.collateralToken).safeTransfer(
            store.projectConfigs.orderVault,
            totalCollateralAmount
        );
        createParams.initialCollateralAmount = totalCollateralAmount;
        // primary order
        result.orderKey = placeOrder(store, createParams);
        store.appendOrder(result.orderKey, totalCollateralAmount, createParams.borrowCollateralAmount, true);
        IEventEmitter(store.projectConfigs.eventEmitter).onPlacePositionOrder(
            store.account.owner,
            createParams,
            result
        );
        return result.orderKey;
    }

    function closePosition(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        IGmxV2Adatper.OrderCreateParams memory createParams
    ) external returns (bytes32) {
        require(store.pendingOrderIndexes.length() < MAX_ORDER_COUNT, "ExceedsMaxOrderCount");
        require(createParams.swapPath.length == 0, "SwapPathNotAvailable");
        // price
        IGmxV2Adatper.PositionResult memory result;
        if (store.marketConfigs.isBoostable) {
            result.prices = store.getOraclePrices();
            require(isCloseSafe(store, result.prices), "MarginUnsafe");
        }
        result.collateralAmount = createParams.initialCollateralAmount;
        // place order
        result.orderKey = placeOrder(store, createParams);
        store.appendOrder(result.orderKey);
        IEventEmitter(store.projectConfigs.eventEmitter).onPlacePositionOrder(
            store.account.owner,
            createParams,
            result
        );
        return result.orderKey;
    }

    function liquidatePosition(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        IGmxV2Adatper.Prices memory prices,
        uint256 executionFee,
        uint256 callbackGasLimit
    ) external {
        require(executionFee == msg.value, "WrongExecutionFee");
        IWETH(WETH).deposit{ value: executionFee }();
        IGmxV2Adatper.PositionResult memory result;
        result.prices = prices;
        result = placeLiquidateOrder(store, executionFee, callbackGasLimit, result);
        // cancel all orders
        bytes32[] memory pendingKeys = store.pendingOrderIndexes.values();
        IEventEmitter(store.projectConfigs.eventEmitter).onPlaceLiquidateOrder(store.account.owner, result);
        for (uint256 i = 0; i < pendingKeys.length; i++) {
            cancelOrder(store, pendingKeys[i], true);
        }
    }

    function placeLiquidateOrder(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        uint256 executionFee,
        uint256 callbackGasLimit,
        IGmxV2Adatper.PositionResult memory result
    ) internal returns (IGmxV2Adatper.PositionResult memory) {
        // if no position, no need to liquidate
        uint256 sizeInUsd = IReaderLite(store.projectConfigs.reader).getPositionSizeInUsd(
            store.projectConfigs.dataStore,
            store.positionKey
        );
        require(sizeInUsd > 0, "NoPositionToLiquidate");
        // if position is safe, no need to liquidate
        require(!isCloseSafe(store, result.prices), "MarginSafe");
        // place market liquidate order
        result.orderKey = placeOrder(
            store,
            IGmxV2Adatper.OrderCreateParams({
                swapPath: "",
                initialCollateralAmount: 0,
                tokenOutMinAmount: 0,
                borrowCollateralAmount: 0,
                sizeDeltaUsd: sizeInUsd,
                triggerPrice: 0,
                acceptablePrice: store.account.isLong ? 0 : type(uint256).max,
                executionFee: executionFee,
                callbackGasLimit: callbackGasLimit,
                orderType: IOrder.OrderType.MarketDecrease
            })
        );
        store.appendOrder(result.orderKey);
        store.account.isLiquidating = true;
        return result;
    }

    function placeOrder(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        IGmxV2Adatper.OrderCreateParams memory orderParams
    ) internal returns (bytes32 orderKey) {
        address exchangeRouter = store.projectConfigs.exchangeRouter;
        require(exchangeRouter != address(0), "ExchangeRouterUnset");
        // execution fee (weth)
        IERC20Upgradeable(WETH).safeTransfer(store.projectConfigs.orderVault, orderParams.executionFee);
        // place order
        orderKey = IExchangeRouter(store.projectConfigs.exchangeRouter).createOrder(
            IExchangeRouter.CreateOrderParams({
                addresses: IExchangeRouter.CreateOrderParamsAddresses({
                    receiver: address(this),
                    callbackContract: address(this),
                    uiFeeReceiver: address(0),
                    market: store.account.market,
                    initialCollateralToken: store.account.collateralToken,
                    swapPath: new address[](0)
                }),
                numbers: IExchangeRouter.CreateOrderParamsNumbers({
                    sizeDeltaUsd: orderParams.sizeDeltaUsd,
                    initialCollateralDeltaAmount: orderParams.initialCollateralAmount,
                    triggerPrice: orderParams.triggerPrice,
                    acceptablePrice: orderParams.acceptablePrice,
                    executionFee: orderParams.executionFee,
                    callbackGasLimit: orderParams.callbackGasLimit,
                    minOutputAmount: 0
                }),
                orderType: orderParams.orderType,
                decreasePositionSwapType: IOrder.DecreasePositionSwapType.SwapPnlTokenToCollateralToken,
                isLong: store.account.isLong,
                shouldUnwrapNativeToken: false,
                referralCode: store.projectConfigs.referralCode
            })
        );
    }

    function updateOrder(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        bytes32 key,
        uint256 sizeDeltaUsd,
        uint256 acceptablePrice,
        uint256 triggerPrice
    ) external {
        address exchangeRouter = store.projectConfigs.exchangeRouter;
        require(exchangeRouter != address(0), "ExchangeRouterUnset");
        IExchangeRouter(exchangeRouter).updateOrder(key, sizeDeltaUsd, acceptablePrice, triggerPrice, 0);

        IEventEmitter(store.projectConfigs.eventEmitter).onUpdateOrder(
            store.account.owner,
            key,
            sizeDeltaUsd,
            acceptablePrice,
            triggerPrice
        );
    }

    function cancelOrder(IGmxV2Adatper.GmxAdapterStoreV2 storage store, bytes32 key) external {
        if (store.pendingOrderIndexes.contains(key)) {
            cancelOrder(store, key, false);
        }
    }

    function cancelExpiredOrder(IGmxV2Adatper.GmxAdapterStoreV2 storage store, bytes32 key) external {
        if (store.pendingOrderIndexes.contains(key)) {
            IGmxV2Adatper.OrderRecord memory record = store.pendingOrders[key];
            require(
                record.isIncreasing &&
                    block.timestamp > record.timestamp + store.projectConfigs.limitOrderExpiredSeconds,
                "NotExpired"
            );
            cancelOrder(store, key, false);
        }
    }

    function cancelOrder(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        bytes32 key,
        bool ignoreFailure
    ) internal returns (bool) {
        address exchangeRouter = store.projectConfigs.exchangeRouter;
        require(exchangeRouter != address(0), "ExchangeRouterUnset");
        try IExchangeRouter(exchangeRouter).cancelOrder(key) {
            return true;
        } catch {
            require(ignoreFailure, "CancelOrderFailed");
            return false;
        }
    }

    function borrowCollateral(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        IGmxV2Adatper.Prices memory prices,
        uint256 borrowCollateralAmount
    ) internal returns (uint256 borrowedCollateralAmount) {
        IGmxV2Adatper.DebtResult memory result;
        result.prices = prices;
        result.fundingFeeCollateralAmount = store.updateMuxFundingFee();
        (result.borrowedCollateralAmount, result.boostFeeCollateralAmount) = store.borrowCollateral(
            borrowCollateralAmount
        );
        borrowedCollateralAmount = result.borrowedCollateralAmount;
        IEventEmitter(store.projectConfigs.eventEmitter).onBorrowCollateral(store.account.owner, result);
    }

    function claimToken(IGmxV2Adatper.GmxAdapterStoreV2 storage store, address token) internal returns (uint256) {
        uint256 sizeInUsd = IReaderLite(store.projectConfigs.reader).getPositionSizeInUsd(
            store.projectConfigs.dataStore,
            store.positionKey
        );
        require(sizeInUsd == 0 && store.account.debtCollateralAmount == 0, "NotAllowed");
        uint256 balance = IERC20Upgradeable(token).balanceOf(address(this));
        IERC20Upgradeable(token).safeTransfer(store.account.owner, balance);
        return balance;
    }

    function isOrderExist(IGmxV2Adatper.GmxAdapterStoreV2 storage store, bytes32 key) external view returns (bool) {
        return IReaderLite(store.projectConfigs.reader).isOrderExist(store.projectConfigs.dataStore, key);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "../../../interfaces/IPriceHub.sol";
import "../interfaces/IGmxV2Adatper.sol";

library LibSwap {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function swapCollateral(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        bytes memory swapPath,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient
    ) internal returns (uint256 amountOut) {
        address tokenIn = decodeInputToken(swapPath);
        require(tokenIn != store.account.collateralToken, "IllegalTokenIn");
        amountOut = swap(store, swapPath, tokenIn, amountIn, minAmountOut, recipient);
    }

    function swap(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        bytes memory swapPath,
        address tokenIn,
        uint256 amountIn,
        uint256 minAmountOut,
        address recipient
    ) internal returns (uint256 amountOut) {
        address swapRouter = store.projectConfigs.swapRouter;
        require(swapRouter != address(0), "swapRouterUnset");
        // exact input swap to convert exact amount of tokens into usdc
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: swapPath,
            recipient: recipient,
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: minAmountOut
        });
        // executes the swap on uniswap pool
        IERC20Upgradeable(tokenIn).approve(store.projectConfigs.swapRouter, amountIn);
        // since exact input swap tokens used = token amount passed
        amountOut = ISwapRouter(store.projectConfigs.swapRouter).exactInput(params);
    }

    // function emergencySwap(
    //     IGmxV2Adatper.GmxAdapterStoreV2 storage store,
    //     bytes memory swapPath,
    //     address tokenIn,
    //     uint256 totalBalance,
    //     uint256 expAmountOut,
    //     uint256 minAmountOut,
    //     address recipient
    // ) external returns (uint256 amountIn, uint256 amountOut) {
    //     address swapRouter = store.projectConfigs.swapRouter;
    //     require(swapRouter != address(0), "swapRouterUnset");

    //     IERC20Upgradeable(tokenIn).approve(swapRouter, totalBalance);
    //     ISwapRouter.ExactOutputParams memory exactOutParams = ISwapRouter.ExactOutputParams({
    //         path: swapPath,
    //         recipient: recipient,
    //         deadline: block.timestamp,
    //         amountOut: expAmountOut,
    //         amountInMaximum: totalBalance
    //     });
    //     try ISwapRouter(swapRouter).exactOutput(exactOutParams) returns (uint256 amountIn_) {
    //         amountIn = amountIn_;
    //         amountOut = expAmountOut;
    //     } catch {
    //         // uint256 minAmountOut = (amountOut * (1e18 - slippageTolerance)) / 1e18;
    //         ISwapRouter.ExactInputParams memory exactInParams = ISwapRouter.ExactInputParams({
    //             path: swapPath,
    //             recipient: recipient,
    //             deadline: block.timestamp,
    //             amountIn: amountIn,
    //             amountOutMinimum: minAmountOut
    //         });
    //         // executes the swap on uniswap pool
    //         IERC20Upgradeable(tokenIn).approve(swapRouter, amountIn);
    //         // since exact input swap tokens used = token amount passed
    //         amountOut = ISwapRouter(swapRouter).exactInput(exactInParams);
    //         amountIn = totalBalance;
    //     }
    // }

    function decodeInputToken(bytes memory _bytes) internal pure returns (address) {
        require(_bytes.length >= 20, "outOfBounds");
        address tempAddress;
        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), 0)), 0x1000000000000000000000000)
        }
        return tempAddress;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";

import "../../../interfaces/IProxyFactory.sol";
import "../../../interfaces/IArbSys.sol";
import "../../../interfaces/IPriceHub.sol";

import "../interfaces/IGmxV2Adatper.sol";
import "../interfaces/gmx/IMarket.sol";
import "../interfaces/gmx/IReaderLite.sol";

library LibUtils {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

    uint256 internal constant RATE_DENOMINATOR = 1e5;
    address internal constant ARB_SYS = address(100);
    uint256 internal constant ARBITRUM_CHAIN_ID = 42161;

    function toDecimals(uint256 n, uint8 decimalsFrom, uint8 decimalsTo) internal pure returns (uint256) {
        if (decimalsFrom > decimalsTo) {
            return n / (10 ** (decimalsFrom - decimalsTo));
        } else if (decimalsFrom < decimalsTo) {
            return n * (10 ** (decimalsTo - decimalsFrom));
        } else {
            return n;
        }
    }

    function toAddress(bytes32 value) internal pure returns (address) {
        return address(bytes20(value));
    }

    function toAddress(uint256 value) internal pure returns (address) {
        return address(bytes20(bytes32(value)));
    }

    function toBytes32(uint256 value) internal pure returns (bytes32) {
        return bytes32(value);
    }

    function toU256(address value) internal pure returns (uint256) {
        return uint256(bytes32(bytes20(uint160(value))));
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

    function setupTokens(IGmxV2Adatper.GmxAdapterStoreV2 storage store, address collateralToken) internal {
        (, address indexToken, address longToken, address shortToken) = IReaderLite(store.projectConfigs.reader)
            .getMarketTokens(store.projectConfigs.dataStore, store.account.market);
        store.account.indexToken = indexToken;
        store.account.longToken = longToken;
        store.account.shortToken = shortToken;
        store.account.collateralToken = collateralToken;
        store.collateralTokenDecimals = IERC20MetadataUpgradeable(collateralToken).decimals();
        store.longTokenDecimals = IERC20MetadataUpgradeable(longToken).decimals();
        store.shortTokenDecimals = IERC20MetadataUpgradeable(shortToken).decimals();
        require(
            collateralToken == store.account.longToken || collateralToken == store.account.shortToken,
            "InvalidToken"
        );
    }

    function getOraclePrices(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store
    ) internal view returns (IGmxV2Adatper.Prices memory prices) {
        IPriceHub priceHub = IPriceHub(store.projectConfigs.priceHub);
        prices.indexTokenPrice = priceHub.getPriceByToken(store.account.indexToken);
        prices.longTokenPrice = priceHub.getPriceByToken(store.account.longToken);
        prices.shortTokenPrice = priceHub.getPriceByToken(store.account.shortToken);
        prices.collateralPrice = store.account.collateralToken == store.account.longToken
            ? prices.longTokenPrice
            : prices.shortTokenPrice;
    }

    function getSecondaryToken(IGmxV2Adatper.GmxAdapterStoreV2 storage store) internal view returns (address) {
        if (store.account.collateralToken == store.account.longToken) {
            return store.account.shortToken;
        } else {
            return store.account.longToken;
        }
    }

    function claimNativeToken(IGmxV2Adatper.GmxAdapterStoreV2 storage store) internal returns (uint256) {
        if (store.account.collateralToken != WETH) {
            uint256 balance = address(this).balance;
            AddressUpgradeable.sendValue(payable(store.account.owner), balance);
            return balance;
        } else {
            return 0;
        }
    }

    function appendOrder(IGmxV2Adatper.GmxAdapterStoreV2 storage store, bytes32 key) internal {
        appendOrder(store, key, 0, 0, false);
    }

    function appendOrder(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        bytes32 key,
        uint256 collateralAmount, // collateral + debt
        uint256 debtCollateralAmount,
        bool isIncreasing
    ) internal {
        store.pendingOrders[key] = IGmxV2Adatper.OrderRecord({
            isIncreasing: isIncreasing,
            timestamp: uint64(block.timestamp),
            blockNumber: getBlockNumber(),
            collateralAmount: collateralAmount,
            debtCollateralAmount: debtCollateralAmount
        });
        store.pendingOrderIndexes.add(key);
        store.account.inflightDebtCollateralAmount += debtCollateralAmount;
    }

    function removeOrder(
        IGmxV2Adatper.GmxAdapterStoreV2 storage store,
        bytes32 key
    ) internal returns (IGmxV2Adatper.OrderRecord memory orderRecord) {
        // main order
        //     \_ store.tpOrderKeys => tp order
        //     \_ store.slOrderKeys => sl order
        orderRecord = store.pendingOrders[key];
        uint256 debtCollateralAmount = orderRecord.debtCollateralAmount;
        delete store.pendingOrders[key];
        store.pendingOrderIndexes.remove(key);
        store.account.inflightDebtCollateralAmount -= debtCollateralAmount;
    }

    function getBlockNumber() internal view returns (uint256) {
        if (block.chainid == ARBITRUM_CHAIN_ID) {
            return IArbSys(address(100)).arbBlockNumber();
        }
        return block.number;
    }

    function setupCallback(IGmxV2Adatper.GmxAdapterStoreV2 storage store) internal {
        IExchangeRouter(store.projectConfigs.exchangeRouter).setSavedCallbackContract(
            store.account.market,
            address(this)
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IGmxV2Adatper.sol";

abstract contract Storage is IGmxV2Adatper {
    GmxAdapterStoreV2 internal _store;
    bytes32[50] private __gaps;
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IArbSys {
    function arbBlockNumber() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

uint256 constant STATE_IS_ENABLED = 0x1;
uint256 constant STATE_IS_BORROWABLE = 0x2;
uint256 constant STATE_IS_REPAYABLE = 0x4;
uint256 constant STATE_IS_DEPOSITABLE = 0x8;
uint256 constant STATE_IS_WITHDRAWABLE = 0x10;

interface ILendingPool {
    struct BorrowState {
        uint256 flags;
        uint256 supplyAmount;
        uint256 borrowFeeAmount;
        uint256 totalAmountOut;
        uint256 totalAmountIn;
        uint256 badDebtAmount;
        bytes32[10] __reserves;
    }

    struct LendingPoolStore {
        address priceHub;
        address swapRouter;
        address liquidityPool;
        uint256 totalBorrowUsd;
        uint256 totalRepayUsd;
        mapping(address => uint256) borrowUsds;
        mapping(address => uint256) repayUsds;
        mapping(address => bool) borrowers;
        mapping(address => bool) maintainers;
        mapping(address => BorrowState) borrowStates;
        bytes32[50] __reserves;
    }

    event BorrowToken(address indexed borrower, address indexed token, uint256 borrowAmount, uint256 borrowFee);
    event RepayToken(
        address indexed repayer,
        address indexed token,
        uint256 repayAmount,
        uint256 borrowFee,
        uint256 badDebt
    );
    event SetMaintainer(address indexed maintainer, bool enabled);
    event SetBorrower(address indexed borrower, bool enabled);
    event SetSwapRouter(address indexed swapRouter);
    event SetFlags(address indexed token, uint256 enables, uint256 disables, uint256 result);
    event Deposit(address indexed token, uint256 amount);
    event Withdraw(address indexed token, uint256 amount);
    event ClaimFee(address indexed token, address recipient, uint256 amount);

    function borrowToken(
        uint256 projectId,
        address borrower,
        address token,
        uint256 borrowAmount,
        uint256 borrowFee
    ) external returns (uint256);

    function repayToken(
        uint256 projectId,
        address repayer,
        address token,
        uint256 repayAmount,
        uint256 borrowFee,
        uint256 badDebt
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ILiquidityPool {
    struct Asset {
        // slot
        // assets with the same symbol in different chains are the same asset. they shares the same muxToken. so debts of the same symbol
        // can be accumulated across chains (see Reader.AssetState.deduct). ex: ERC20(fBNB).symbol should be "BNB", so that BNBs of
        // different chains are the same.
        // since muxToken of all stable coins is the same and is calculated separately (see Reader.ChainState.stableDeduct), stable coin
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
        uint96 credit;
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
        address muxTokenAddress; // muxToken.address. all stable coins share the same muxTokenAddress
        uint32 spotWeight; // 1e0
        uint32 longFundingBaseRate8H; // 1e5
        uint32 longFundingLimitRate8H; // 1e5
        // slot
        uint128 longCumulativeFundingRate; // Σ_t fundingRate_t
        uint128 shortCumulativeFunding; // Σ_t fundingRate_t * indexPrice_t
    }

    function borrowAsset(address borrower, uint8 assetId, uint256 rawAmount, uint256 rawFee) external returns (uint256);

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
            // [0] mlpPriceLowerBound
            // [1] mlpPriceUpperBound
            uint96[2] memory u96s
        );

    function getAssetInfo(uint8 assetId) external view returns (Asset memory);

    function setLiquidityManager(address liquidityManager, bool enable) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.17;

interface IMuxOrderBook {
    struct PositionOrderExtra {
        // tp/sl strategy
        uint96 tpPrice; // take-profit price. decimals = 18. only valid when flags.POSITION_TPSL_STRATEGY.
        uint96 slPrice; // stop-loss price. decimals = 18. only valid when flags.POSITION_TPSL_STRATEGY.
        uint8 tpslProfitTokenId; // only valid when flags.POSITION_TPSL_STRATEGY.
        uint32 tpslDeadline; // only valid when flags.POSITION_TPSL_STRATEGY.
    }

    /**
     * @notice Liquidity Order can be filled after this time in seconds.
     */
    function liquidityLockPeriod() external view returns (uint32);

    /**
     * @notice Market Order MUST NOT be filled after this time in seconds.
     */
    function marketOrderTimeout() external view returns (uint32);

    /**
     * @notice Limit/Trigger Order MUST NOT be filled after this time in seconds.
     */
    function maxLimitOrderTimeout() external view returns (uint32);

    /**
     * @notice Return true if the filling of position order is temporarily paused.
     */
    function isPositionOrderPaused() external view returns (bool);

    /**
     * @notice Return true if the filling of liquidity/rebalance order is temporarily paused.
     */
    function isLiquidityOrderPaused() external view returns (bool);

    /**
     * @notice Get an Order by orderId.
     */
    function getOrder(uint64 orderId) external view returns (bytes32[3] memory, bool);

    /**
     * @notice Get more parameters (ex: tp/sl strategy parameters) of a position order by orderId.
     */
    function positionOrderExtras(uint64 orderId) external view returns (PositionOrderExtra memory);

    /**
     * @notice Cancel an Order by orderId.
     */
    function cancelOrder(uint64 orderId) external;

    /**
     * @notice Open/close position. called by Trader.
     *
     *         Market order will expire after marketOrderTimeout seconds.
     *         Limit/Trigger order will expire after deadline.
     * @param  subAccountId       sub account id. see LibSubAccount.decodeSubAccountId.
     * @param  collateralAmount   deposit collateral before open; or withdraw collateral after close. decimals = erc20.decimals.
     * @param  size               position size. decimals = 18.
     * @param  price              limit price. decimals = 18.
     * @param  profitTokenId      specify the profitable asset.id when closing a position and making a profit.
     *                            take no effect when opening a position or loss.
     * @param  flags              a bitset of LibOrder.POSITION_*.
     *                            POSITION_OPEN                     this flag means openPosition; otherwise closePosition
     *                            POSITION_MARKET_ORDER             this flag means ignore limitPrice
     *                            POSITION_WITHDRAW_ALL_IF_EMPTY    this flag means auto withdraw all collateral if position.size == 0
     *                            POSITION_TRIGGER_ORDER            this flag means this is a trigger order (ex: stop-loss order). otherwise this is a limit order (ex: take-profit order)
     * @param  deadline           a unix timestamp after which the limit/trigger order MUST NOT be filled. fill 0 for market order.
     * @param  referralCode       set referral code of the trading account.
     */
    function placePositionOrder2(
        bytes32 subAccountId,
        uint96 collateralAmount, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 profitTokenId,
        uint8 flags,
        uint32 deadline, // 1e0
        bytes32 referralCode
    ) external payable;

    function placePositionOrder3(
        bytes32 subAccountId,
        uint96 collateralAmount, // erc20.decimals
        uint96 size, // 1e18
        uint96 price, // 1e18
        uint8 profitTokenId,
        uint8 flags,
        uint32 deadline, // 1e0
        bytes32 referralCode,
        PositionOrderExtra memory extra
    ) external payable;

    /**
     * @notice Add/remove liquidity. called by Liquidity Provider.
     *
     *         Can be filled after liquidityLockPeriod seconds.
     * @param  assetId   asset.id that added/removed to.
     * @param  rawAmount asset token amount. decimals = erc20.decimals.
     * @param  isAdding  true for add liquidity, false for remove liquidity.
     */
    function placeLiquidityOrder(
        uint8 assetId,
        uint96 rawAmount, // erc20.decimals
        bool isAdding
    ) external payable;

    /**
     * @notice Withdraw collateral/profit. called by Trader.
     *
     *         This order will expire after marketOrderTimeout seconds.
     * @param  subAccountId       sub account id. see LibSubAccount.decodeSubAccountId.
     * @param  rawAmount          collateral or profit asset amount. decimals = erc20.decimals.
     * @param  profitTokenId      specify the profitable asset.id.
     * @param  isProfit           true for withdraw profit. false for withdraw collateral.
     */
    function placeWithdrawalOrder(
        bytes32 subAccountId,
        uint96 rawAmount, // erc20.decimals
        uint8 profitTokenId,
        bool isProfit
    ) external;

    /**
     * @notice Rebalance pool liquidity. Swap token 0 for token 1.
     *
     *         msg.sender must implement IMuxRebalancerCallback.
     * @param  tokenId0      asset.id to be swapped out of the pool.
     * @param  tokenId1      asset.id to be swapped into the pool.
     * @param  rawAmount0    token 0 amount. decimals = erc20.decimals.
     * @param  maxRawAmount1 max token 1 that rebalancer is willing to pay. decimals = erc20.decimals.
     * @param  userData      any user defined data.
     */
    function placeRebalanceOrder(
        uint8 tokenId0,
        uint8 tokenId1,
        uint96 rawAmount0, // erc20.decimals
        uint96 maxRawAmount1, // erc20.decimals
        bytes32 userData
    ) external;

    function setAggregator(address aggregatorAddress, bool isEnable) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IPriceHub {
    function getPriceByToken(address token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../interfaces/IMuxOrderBook.sol";

interface IProxyFactory {
    struct OpenPositionArgsV2 {
        uint256 projectId;
        address collateralToken;
        address assetToken;
        bool isLong;
        address tokenIn;
        uint256 amountIn; // tokenIn.decimals
        uint256 minOut; // collateral.decimals
        uint256 borrow; // collateral.decimals
        uint256 sizeUsd; // 1e18
        uint96 priceUsd; // 1e18
        uint96 tpPriceUsd; // 1e18
        uint96 slPriceUsd; // 1e18
        uint8 flags; // MARKET, TRIGGER
        bytes32 referralCode;
    }
    struct ClosePositionArgsV2 {
        uint256 projectId;
        address collateralToken;
        address assetToken;
        bool isLong;
        uint256 collateralUsd; // collateral.decimals
        uint256 sizeUsd; // 1e18
        uint96 priceUsd; // 1e18
        uint96 tpPriceUsd; // 1e18
        uint96 slPriceUsd; // 1e18
        uint8 flags; // MARKET, TRIGGER
        bytes32 referralCode;
    }

    struct MuxOrderParams {
        bytes32 subAccountId;
        uint96 collateralAmount; // erc20.decimals
        uint96 size; // 1e18
        uint96 price; // 1e18
        uint8 profitTokenId;
        uint8 flags;
        uint32 deadline; // 1e0
        bytes32 referralCode;
        IMuxOrderBook.PositionOrderExtra extra;
    }

    struct PositionOrderExtra {
        // tp/sl strategy
        uint96 tpPrice; // take-profit price. decimals = 18. only valid when flags.POSITION_TPSL_STRATEGY.
        uint96 slPrice; // stop-loss price. decimals = 18. only valid when flags.POSITION_TPSL_STRATEGY.
        uint8 tpslProfitTokenId; // only valid when flags.POSITION_TPSL_STRATEGY.
        uint32 tpslDeadline; // only valid when flags.POSITION_TPSL_STRATEGY.
    }

    struct OrderParams {
        bytes32 orderKey;
        uint256 collateralDelta;
        uint256 sizeDelta;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
    }

    struct ProxyCallParams {
        uint256 projectId;
        address collateralToken;
        address assetToken;
        bool isLong;
        bytes32 referralCode;
        uint256 value;
        bytes proxyCallData;
    }

    event SetMaintainer(address maintainer, bool enable);
    event SetKeeper(address keeper, bool enable);
    event SetBorrowConfig(
        uint256 projectId,
        address assetToken,
        uint8 prevAssetId,
        uint8 newAssetId,
        uint256 prevLimit,
        uint256 newLimit
    );
    event DisableBorrowConfig(uint256 projectId, address assetToken);
    event MuxCall(address target, uint256 value, bytes data);
    event SetLiquiditySource(uint256 indexed projectId, uint256 sourceId, address source);

    function weth() external view returns (address);

    function getProxiesOf(address account) external view returns (address[] memory);

    function isKeeper(address keeper) external view returns (bool);

    function getProjectConfig(uint256 projectId) external view returns (uint256[] memory);

    function getProjectAssetConfig(uint256 projectId, address assetToken) external view returns (uint256[] memory);

    function getBorrowStates(
        uint256 projectId,
        address assetToken
    ) external view returns (uint256 totalBorrow, uint256 borrowLimit, uint256 badDebt);

    function getAssetId(uint256 projectId, address token) external view returns (uint8);

    function getConfigVersions(
        uint256 projectId,
        address assetToken
    ) external view returns (uint32 projectConfigVersion, uint32 assetConfigVersion);

    function getProxyProjectId(address proxy) external view returns (uint256);

    function getLiquiditySource(uint256 projectId) external view returns (uint256 sourceId, address source);

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
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IWETH {
    function deposit() external payable;

    function approve(address spender, uint256 value) external;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function balanceOf(address) external view returns (uint256);
}