// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20MetadataUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import { Multicall } from "../libraries/Multicall.sol";
import { IAddressProvider } from "../interfaces/IAddressProvider.sol";
import { IClaim } from "../interfaces/IClaim.sol";
import { IBaseReward } from "../rewards/interfaces/IBaseReward.sol";
import { IVaultRewardDistributor } from "../rewards/interfaces/IVaultRewardDistributor.sol";
import { ICreditManager } from "./interfaces/ICreditManager.sol";
import { ICreditTokenStaker } from "./interfaces/ICreditTokenStaker.sol";
import { ICreditUser } from "./interfaces/ICreditUser.sol";
import { ICreditAggregator } from "./interfaces/ICreditAggregator.sol";
import { IDepositor } from "../depositors/interfaces/IDepositor.sol";
import { IWETH } from "../interfaces/IWETH.sol";
import { ICreditCaller } from "./interfaces/ICreditCaller.sol";

contract CreditCaller is Initializable, ReentrancyGuardUpgradeable, OwnableUpgradeable, Multicall, ICreditCaller {
    using SafeERC20Upgradeable for IERC20MetadataUpgradeable;
    using AddressUpgradeable for address;

    address private constant ZERO = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant MIN_RATIO = 100; // min ratio is 1
    uint256 private constant MAX_RATIO = 1000; // max ratio is 10
    uint256 private constant RATIO_PRECISION = 100;
    uint256 private constant MAX_SUM_RATIO = 10;
    uint256 private constant LIQUIDATE_THRESHOLD = 100; // 10%
    uint256 private constant LIQUIDATE_DENOMINATOR = 1000;
    uint256 private constant LIQUIDATE_FEE = 1; // 0.1%
    uint256 private constant LIQUIDATE_PRECISION = 1000;
    uint256 private constant MAX_LOAN_DURATION = 1 days * 365;

    struct Strategy {
        bool listed;
        address collateralReward;
        mapping(address => address) vaultReward; // vaults => VaultRewardDistributor
    }

    address public addressProvider;
    address public wethAddress;
    address public creditUser;
    address public creditTokenStaker;
    address public allowlist;

    mapping(address => Strategy) public strategies; // depositor => Strategy
    mapping(address => address) public vaultManagers; // borrow token => manager

    // @custom:oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {}

    function initialize(address _addressProvider, address _wethAddress) external initializer {
        require(_addressProvider != address(0), "CreditCaller: _addressProvider cannot be 0x0");
        require(_wethAddress != address(0), "CreditCaller: _wethAddress cannot be 0x0");

        require(_addressProvider.isContract(), "CreditCaller: _addressProvider is not a contract");
        require(_wethAddress.isContract(), "CreditCaller: _wethAddress is not a contract");

        __ReentrancyGuard_init();
        __Ownable_init_unchained();

        addressProvider = _addressProvider;
        wethAddress = _wethAddress;
    }

    function openLendCredit(
        address _depositor,
        address _token,
        uint256 _amountIn,
        address[] calldata _borrowedTokens,
        uint256[] calldata _ratios,
        address _recipient
    ) external payable override nonReentrant {
        require(_token != address(0), "CreditCaller: _token cannot be 0x0");
        require(_amountIn > 0, "CreditCaller: _amountIn cannot be 0");

        if (allowlist != address(0)) {
            bytes memory data = allowlist.functionCall(abi.encodeWithSignature("can(address)", _recipient));

            require(abi.decode(data, (bool)), "CreditCaller: Not whitelisted");
        }

        if (_token == ZERO) {
            _wrapETH(_amountIn);

            _token = wethAddress;
        } else {
            uint256 before = IERC20MetadataUpgradeable(_token).balanceOf(address(this));
            IERC20MetadataUpgradeable(_token).safeTransferFrom(msg.sender, address(this), _amountIn);
            _amountIn = IERC20MetadataUpgradeable(_token).balanceOf(address(this)) - before;
        }

        _approve(_token, _depositor, _amountIn);

        (, uint256 collateralMintedAmount) = IDepositor(_depositor).mint(_token, _amountIn);

        ICreditUser.UserLendCredit memory userLendCredit;

        userLendCredit.depositor = _depositor;
        userLendCredit.token = _token;
        userLendCredit.amountIn = _amountIn;
        userLendCredit.borrowedTokens = _borrowedTokens;
        userLendCredit.ratios = _ratios;

        return _lendCredit(userLendCredit, collateralMintedAmount, _recipient);
    }

    function _lendCredit(
        ICreditUser.UserLendCredit memory _userLendCredit,
        uint256 _collateralMintedAmount,
        address _recipient
    ) internal {
        _requireValidRatio(_userLendCredit.ratios);

        Strategy storage strategy = strategies[_userLendCredit.depositor];

        require(strategy.listed, "CreditCaller: Mismatched strategy");
        require(_userLendCredit.borrowedTokens.length == _userLendCredit.ratios.length, "CreditCaller: Length mismatch");

        uint256 borrowedIndex = ICreditUser(creditUser).accrueSnapshot(_recipient);

        ICreditUser(creditUser).createUserLendCredit(
            _recipient,
            borrowedIndex,
            _userLendCredit.depositor,
            _userLendCredit.token,
            _userLendCredit.amountIn,
            _userLendCredit.borrowedTokens,
            _userLendCredit.ratios
        );

        uint256[] memory borrowedAmountOuts = new uint256[](_userLendCredit.borrowedTokens.length);
        uint256[] memory borrowedMintedAmount = new uint256[](_userLendCredit.borrowedTokens.length);
        address[] memory creditManagers = new address[](_userLendCredit.borrowedTokens.length);

        for (uint256 i = 0; i < _userLendCredit.borrowedTokens.length; i++) {
            borrowedAmountOuts[i] = calcBorrowAmount(
                _userLendCredit.amountIn,
                _userLendCredit.token,
                _userLendCredit.ratios[i],
                _userLendCredit.borrowedTokens[i]
            );
            creditManagers[i] = vaultManagers[_userLendCredit.borrowedTokens[i]];

            _approve(_userLendCredit.borrowedTokens[i], _userLendCredit.depositor, borrowedAmountOuts[i]);

            ICreditManager(creditManagers[i]).borrow(_recipient, borrowedAmountOuts[i]);

            (, borrowedMintedAmount[i]) = IDepositor(_userLendCredit.depositor).mint(_userLendCredit.borrowedTokens[i], borrowedAmountOuts[i]);

            address vaultRewardDistributor = strategy.vaultReward[ICreditManager(creditManagers[i]).vault()];

            ICreditTokenStaker(creditTokenStaker).stake(vaultRewardDistributor, borrowedMintedAmount[i]);

            emit CalcBorrowAmount(_userLendCredit.borrowedTokens[i], borrowedIndex, borrowedAmountOuts[i], borrowedMintedAmount[i]);
        }

        ICreditTokenStaker(creditTokenStaker).stakeFor(strategy.collateralReward, _recipient, _collateralMintedAmount);

        ICreditUser(creditUser).createUserBorrowed(
            _recipient,
            borrowedIndex,
            creditManagers,
            borrowedAmountOuts,
            _collateralMintedAmount,
            borrowedMintedAmount
        );

        emit LendCredit(
            _recipient,
            borrowedIndex,
            _userLendCredit.depositor,
            _userLendCredit.token,
            _userLendCredit.amountIn,
            _userLendCredit.borrowedTokens,
            _userLendCredit.ratios,
            block.timestamp
        );
    }

    function repayCredit(uint256 _borrowedIndex) external override nonReentrant returns (uint256) {
        uint256 lastestIndex = ICreditUser(creditUser).getUserCounts(msg.sender);

        require(_borrowedIndex > 0, "CreditCaller: Minimum limit exceeded");
        require(_borrowedIndex <= lastestIndex, "CreditCaller: Index out of range");

        bool isTerminated = ICreditUser(creditUser).isTerminated(msg.sender, _borrowedIndex);

        require(!isTerminated, "CreditCaller: Already terminated");

        return _repayCredit(msg.sender, _borrowedIndex, address(0));
    }

    function _repayCredit(
        address _recipient,
        uint256 _borrowedIndex,
        address _liquidator
    ) internal returns (uint256) {
        ICreditUser.UserLendCredit memory userLendCredit;
        ICreditUser.UserBorrowed memory userBorrowed;

        (userLendCredit.depositor, userLendCredit.token, , userLendCredit.borrowedTokens, ) = ICreditUser(creditUser).getUserLendCredit(
            _recipient,
            _borrowedIndex
        );

        uint256 totalMintedAmount;

        (
            userBorrowed.creditManagers,
            userBorrowed.borrowedAmountOuts,
            userBorrowed.collateralMintedAmount,
            userBorrowed.borrowedMintedAmount,
            totalMintedAmount
        ) = ICreditUser(creditUser).getUserBorrowed(_recipient, _borrowedIndex);

        Strategy storage strategy = strategies[userLendCredit.depositor];

        for (uint256 i = 0; i < userBorrowed.creditManagers.length; i++) {
            uint256 usedMintedAmount = _withdrawBorrowedAmount(userLendCredit.depositor, userLendCredit.borrowedTokens[i], userBorrowed.borrowedAmountOuts[i]);

            totalMintedAmount = totalMintedAmount - usedMintedAmount;

            _approve(userLendCredit.borrowedTokens[i], userBorrowed.creditManagers[i], userBorrowed.borrowedAmountOuts[i]);
            ICreditManager(userBorrowed.creditManagers[i]).repay(_recipient, userBorrowed.borrowedAmountOuts[i]);

            address vaultRewardDistributor = strategy.vaultReward[ICreditManager(userBorrowed.creditManagers[i]).vault()];

            ICreditTokenStaker(creditTokenStaker).withdraw(vaultRewardDistributor, userBorrowed.borrowedMintedAmount[i]);
        }

        uint256 collateralAmountOut = IDepositor(userLendCredit.depositor).withdraw(userLendCredit.token, totalMintedAmount, 0);

        if (_liquidator != address(0)) {
            uint256 liquidatorFee = (collateralAmountOut * LIQUIDATE_FEE) / LIQUIDATE_PRECISION;
            collateralAmountOut = collateralAmountOut - liquidatorFee;
            IERC20MetadataUpgradeable(userLendCredit.token).safeTransfer(_liquidator, liquidatorFee);

            emit LiquidatorFee(_liquidator, liquidatorFee, _borrowedIndex);
        }

        IERC20MetadataUpgradeable(userLendCredit.token).safeTransfer(_recipient, collateralAmountOut);
        ICreditTokenStaker(creditTokenStaker).withdrawFor(strategy.collateralReward, _recipient, userBorrowed.collateralMintedAmount);
        ICreditUser(creditUser).destroy(_recipient, _borrowedIndex);

        emit RepayCredit(_recipient, _borrowedIndex, userLendCredit.token, collateralAmountOut, block.timestamp);

        return collateralAmountOut;
    }

    function _withdrawBorrowedAmount(
        address _depositor,
        address _borrowedTokens,
        uint256 _borrowedAmountOuts
    ) internal returns (uint256) {
        uint256 usedMintedAmount = _sellGlpFromAmount(_borrowedTokens, _borrowedAmountOuts);

        uint256 amountOut = IDepositor(_depositor).withdraw(_borrowedTokens, usedMintedAmount, 0);

        require(amountOut >= _borrowedAmountOuts, "CreditCaller: Insufficient balance");

        return usedMintedAmount;
    }

    function liquidate(address _recipient, uint256 _borrowedIndex) external override nonReentrant {
        uint256 lastestIndex = ICreditUser(creditUser).getUserCounts(_recipient);

        require(_borrowedIndex > 0, "CreditCaller: Minimum limit exceeded");
        require(_borrowedIndex <= lastestIndex, "CreditCaller: Index out of range");

        bool isTerminated = ICreditUser(creditUser).isTerminated(_recipient, _borrowedIndex);
        bool isTimeout = ICreditUser(creditUser).isTimeout(_recipient, _borrowedIndex, MAX_LOAN_DURATION);

        require(!isTerminated, "CreditCaller: Already terminated");

        (, , , address[] memory borrowedTokens, ) = ICreditUser(creditUser).getUserLendCredit(_recipient, _borrowedIndex);
        (address[] memory creditManagers, uint256[] memory borrowedAmountOuts, , , uint256 mintedAmount) = ICreditUser(creditUser).getUserBorrowed(
            _recipient,
            _borrowedIndex
        );

        uint256 borrowedMinted;

        for (uint256 i = 0; i < creditManagers.length; i++) {
            borrowedMinted = borrowedMinted + _sellGlpFromAmount(borrowedTokens[i], borrowedAmountOuts[i]);
        }

        uint256 health = ((mintedAmount - borrowedMinted) * LIQUIDATE_DENOMINATOR) / mintedAmount;

        if (health <= LIQUIDATE_THRESHOLD || isTimeout) {
            _repayCredit(_recipient, _borrowedIndex, msg.sender);

            emit Liquidate(_recipient, _borrowedIndex, health, block.timestamp);
        }
    }

    function addStrategy(
        address _depositor,
        address _collateralReward,
        address[] calldata _vaults,
        address[] calldata _vaultRewardDistributors
    ) external onlyOwner {
        require(_vaults.length == _vaultRewardDistributors.length, "CreditCaller: Length mismatch");
        require(_depositor != address(0), "CreditCaller: _depositor cannot be 0x0");
        require(_collateralReward != address(0), "CreditCaller: _collateralReward cannot be 0x0");

        Strategy storage strategy = strategies[_depositor];

        strategy.listed = true;
        strategy.collateralReward = _collateralReward;

        for (uint256 i = 0; i < _vaults.length; i++) {
            strategy.vaultReward[_vaults[i]] = _vaultRewardDistributors[i];
        }

        emit AddStrategy(_depositor, _collateralReward, _vaults, _vaultRewardDistributors);
    }

    function addVaultManager(address _underlyingToken, address _creditManager) external onlyOwner {
        require(_underlyingToken != address(0), "CreditCaller: _underlyingToken cannot be 0x0");
        require(_creditManager != address(0), "CreditCaller: _creditManager cannot be 0x0");
        require(vaultManagers[_underlyingToken] == address(0), "CreditCaller: Cannot run this function twice");

        vaultManagers[_underlyingToken] = _creditManager;

        emit AddVaultManager(_underlyingToken, _creditManager);
    }

    function setCreditUser(address _creditUser) external onlyOwner {
        require(_creditUser != address(0), "CreditCaller: _creditUser cannot be 0x0");
        require(creditUser == address(0), "CreditCaller: Cannot run this function twice");
        creditUser = _creditUser;

        emit SetCreditUser(_creditUser);
    }

    function setCreditTokenStaker(address _creditTokenStaker) external onlyOwner {
        require(_creditTokenStaker != address(0), "CreditCaller: _creditTokenStaker cannot be 0x0");
        require(creditTokenStaker == address(0), "CreditCaller: Cannot run this function twice");
        creditTokenStaker = _creditTokenStaker;

        emit SetCreditTokenStaker(creditTokenStaker);
    }

    function setAllowlist(address _allowlist) external onlyOwner {
        allowlist = _allowlist;
    }

    function claimFor(address _target, address _recipient) external nonReentrant {
        IClaim(_target).claim(_recipient);
    }

    function _calcFormula(
        uint256 _collateralAmountIn,
        address _collateralToken,
        uint256 _ratio,
        address _borrowedToken
    ) internal view returns (uint256) {
        uint256 collateralPrice = _tokenPrice(_collateralToken);
        uint256 borrowedPrice = _tokenPrice(_borrowedToken);

        return (_collateralAmountIn * collateralPrice * _ratio) / borrowedPrice / RATIO_PRECISION;
    }

    function calcBorrowAmount(
        uint256 _collateralAmountIn,
        address _collateralToken,
        uint256 _ratio,
        address _borrowedToken
    ) public view returns (uint256) {
        uint256 collateralDecimals = IERC20MetadataUpgradeable(_collateralToken).decimals();
        uint256 borrowedTokenDecimals = IERC20MetadataUpgradeable(_borrowedToken).decimals();

        return (_calcFormula(_collateralAmountIn, _collateralToken, _ratio, _borrowedToken) * 10**borrowedTokenDecimals) / 10**collateralDecimals;
    }

    function _approve(
        address _token,
        address _spender,
        uint256 _amount
    ) internal {
        IERC20MetadataUpgradeable(_token).safeApprove(_spender, 0);
        IERC20MetadataUpgradeable(_token).safeApprove(_spender, _amount);
    }

    function _requireValidRatio(uint256[] memory _ratios) internal pure {
        require(_ratios.length > 0, "CreditCaller: Ratios cannot be empty");

        uint256 total;

        for (uint256 i = 0; i < _ratios.length; i++) total = total + _ratios[i];

        require(total <= MAX_RATIO, "CreditCaller: MAX_RATIO limit exceeded");
        require(total >= MIN_RATIO, "CreditCaller: MIN_RATIO limit exceeded");
    }

    function _tokenPrice(address _token) internal view returns (uint256) {
        address aggregator = IAddressProvider(addressProvider).getCreditAggregator();

        return ICreditAggregator(aggregator).getTokenPrice(_token);
    }

    function _sellGlpFromAmount(address _swapToken, uint256 _amountIn) internal view returns (uint256) {
        address aggregator = IAddressProvider(addressProvider).getCreditAggregator();

        (uint256 amountOut, ) = ICreditAggregator(aggregator).getSellGlpFromAmount(_swapToken, _amountIn);

        return amountOut;
    }

    function _wrapETH(uint256 _amountIn) internal {
        require(msg.value == _amountIn, "CreditCaller: ETH amount mismatch");

        IWETH(wethAddress).deposit{ value: _amountIn }();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface ICreditAggregator {
    function getGlpPrice(bool _isBuying) external view returns (uint256);

    function getBuyGlpToAmount(address _fromToken, uint256 _tokenAmountIn) external view returns (uint256, uint256);

    function getSellGlpToAmount(address _toToken, uint256 _glpAmountIn) external view returns (uint256, uint256);

    function getBuyGlpFromAmount(address _toToken, uint256 _glpAmountIn) external view returns (uint256, uint256);

    function getSellGlpFromAmount(address _fromToken, uint256 _tokenAmountIn) external view returns (uint256, uint256);

    function getTokenPrice(address _token) external view returns (uint256);

    function adjustForDecimals(
        uint256 _amountIn,
        uint256 _divDecimals,
        uint256 _mulDecimals
    ) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface ICreditCaller {
    function openLendCredit(
        address _depositor,
        address _token,
        uint256 _amountIn,
        address[] calldata _borrowedTokens,
        uint256[] calldata _ratios,
        address _recipient
    ) external payable;

    function repayCredit(uint256 _borrowedIndex) external returns (uint256);

    function liquidate(address _recipient, uint256 _borrowedIndex) external;

    event LendCredit(
        address indexed _recipient,
        uint256 _borrowedIndex,
        address _depositor,
        address _token,
        uint256 _amountIn,
        address[] _borrowedTokens,
        uint256[] _ratios,
        uint256 _timestamp
    );
    event CalcBorrowAmount(address indexed _borrowedToken, uint256 _borrowedIndex, uint256 _borrowedAmountOuts, uint256 _borrowedMintedAmount);
    event RepayCredit(address indexed _recipient, uint256 _borrowedIndex, address _collateralToken, uint256 _collateralAmountOut, uint256 _timestamp);
    event Liquidate(address _recipient, uint256 _borrowedIndex, uint256 _health, uint256 _timestamp);
    event LiquidatorFee(address _liquidator, uint256 _fee, uint256 _borrowedIndex);
    event AddStrategy(address _depositor, address _collateralReward, address[] _vaults, address[] _vaultRewards);
    event AddVaultManager(address _underlying, address _creditManager);
    event SetCreditUser(address _creditUser);
    event SetCreditTokenStaker(address _creditTokenStaker);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface ICreditManager {
    function vault() external view returns (address);

    function borrow(address _recipient, uint256 _borrowedAmount) external;

    function repay(address _recipient, uint256 _borrowedAmount) external;

    function claim(address _recipient) external returns (uint256 claimed);

    function balanceOf(address _recipient) external view returns (uint256);

    function harvest() external returns (uint256);

    event Borrow(address _recipient, uint256 _borrowedAmount, uint256 _totalShares, uint256 _shares);
    event Repay(address _recipient, uint256 _borrowedAmount, uint256 _totalShares, uint256 _shares);
    event Harvest(uint256 _claimed, uint256 _accRewardPerShare);
    event Claim(address _recipient, uint256 _claimed);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface ICreditTokenStaker {
    function creditToken() external view returns (address);

    function stake(address _vaultRewardDistributor, uint256 _amountIn) external returns (bool);

    function withdraw(address _vaultRewardDistributor, uint256 _amountOut) external returns (bool);

    function stakeFor(
        address _collateralReward,
        address _recipient,
        uint256 _amountIn
    ) external returns (bool);

    function withdrawFor(
        address _collateralReward,
        address _recipient,
        uint256 _amountOut
    ) external returns (bool);

    event NewOwner(address indexed _sender, address _owner);
    event RemoveOwner(address indexed _sender, address _owner);
    event Stake(address indexed _owner, address _vaultRewardDistributor, uint256 _amountIn);
    event Withdraw(address indexed _owner, address _vaultRewardDistributor, uint256 _amountOut);
    event StakeFor(address indexed _owner, address _collateralReward, address _recipient, uint256 _amountIn);
    event WithdrawFor(address indexed _owner, address _collateralReward, address _recipient, uint256 _amountOut);
    event SetCreditToken(address _creditToken);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface ICreditUser {
    struct UserLendCredit {
        address depositor;
        address token;
        uint256 amountIn;
        address[] borrowedTokens;
        uint256[] ratios;
        bool terminated;
    }

    struct UserBorrowed {
        address[] creditManagers;
        uint256[] borrowedAmountOuts;
        uint256 collateralMintedAmount;
        uint256[] borrowedMintedAmount;
        uint256 borrowedAt;
    }

    function accrueSnapshot(address _recipient) external returns (uint256);

    function createUserLendCredit(
        address _recipient,
        uint256 _borrowedIndex,
        address _depositor,
        address _token,
        uint256 _amountIn,
        address[] calldata _borrowedTokens,
        uint256[] calldata _ratios
    ) external;

    function createUserBorrowed(
        address _recipient,
        uint256 _borrowedIndex,
        address[] calldata _creditManagers,
        uint256[] calldata _borrowedAmountOuts,
        uint256 _collateralMintedAmount,
        uint256[] calldata _borrowedMintedAmount
    ) external;

    function destroy(address _recipient, uint256 _borrowedIndex) external;

    function isTerminated(address _recipient, uint256 _borrowedIndex) external view returns (bool);

    function isTimeout(
        address _recipient,
        uint256 _borrowedIndex,
        uint256 _duration
    ) external view returns (bool);

    function getUserLendCredit(address _recipient, uint256 _borrowedIndex)
        external
        view
        returns (
            address depositor,
            address token,
            uint256 amountIn,
            address[] memory borrowedTokens,
            uint256[] memory ratio
        );

    function getUserBorrowed(address _user, uint256 _borrowedIndex)
        external
        view
        returns (
            address[] memory creditManagers,
            uint256[] memory borrowedAmountOuts,
            uint256 collateralMintedAmount,
            uint256[] memory borrowedMintedAmount,
            uint256 mintedAmount
        );

    function getUserCounts(address _recipient) external view returns (uint256);

    function getLendCreditUsers(uint256 _borrowedIndex) external view returns (address);

    event CreateUserLendCredit(
        address indexed _recipient,
        uint256 _borrowedIndex,
        address _depositor,
        address _token,
        uint256 _amountIn,
        address[] _borrowedTokens,
        uint256[] _ratios
    );

    event CreateUserBorrowed(
        address indexed _recipient,
        uint256 _borrowedIndex,
        address[] _creditManagers,
        uint256[] _borrowedAmountOuts,
        uint256 _collateralMintedAmount,
        uint256[] _borrowedMintedAmount,
        uint256 _borrowedAt
    );

    event Destroy(address indexed _recipient, uint256 _borrowedIndex);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IDepositor {
    function mint(address _token, uint256 _amountIn) external payable returns (address, uint256);

    function withdraw(
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minOut
    ) external payable returns (uint256);

    function harvest() external returns (uint256);

    event Mint(address _token, uint256 _amountIn, uint256 _amountOut);
    event Withdraw(address _token, uint256 _amountIn, uint256 _amountOut);
    event Harvest(address _rewardToken, uint256 _rewards, uint256 _fees);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IAddressProvider {
    function getGmxRewardRouterV1() external view returns (address);

    function getGmxRewardRouter() external view returns (address);

    function getCreditAggregator() external view returns (address);

    event AddressSet(bytes32 indexed _key, address indexed _value);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IClaim {
    function claim(address _recipient) external returns (uint256 claimed);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;
pragma abicoder v2;

/// @title Multicall interface
/// @notice Enables calling multiple methods in a single call to the contract
interface IMulticall {
    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @dev The `msg.value` should not be trusted for any method callable from multicall.
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data)
        external
        payable
        returns (bytes[] memory results);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function depositTo(address account) external payable;

    function withdrawTo(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;
pragma abicoder v2;

import "../interfaces/IMulticall.sol";

/// @title Multicall
/// @notice Enables calling multiple methods in a single call to the contract
abstract contract Multicall is IMulticall {
    /// @inheritdoc IMulticall
    function multicall(bytes[] calldata data) public payable override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import { ICommonReward } from "./ICommonReward.sol";

interface IBaseReward is ICommonReward {
    function stakeFor(address _recipient, uint256 _amountIn) external;

    function withdraw(uint256 _amountOut) external returns (uint256);

    function withdrawFor(address _recipient, uint256 _amountOut) external returns (uint256);

    function claim(address _recipient) external returns (uint256 claimed);

    function pendingRewards(address _recipient) external view returns (uint256);

    function balanceOf(address _recipient) external view returns (uint256);

    event StakeFor(address indexed _recipient, uint256 _amountIn, uint256 _totalSupply, uint256 _totalUnderlying);
    event Withdraw(address indexed _recipient, uint256 _amountOut, uint256 _totalSupply, uint256 _totalUnderlying);
    event Claim(address indexed _recipient, uint256 _claimed);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

interface ICommonReward {
    function stakingToken() external view returns (address);

    function rewardToken() external view returns (address);

    function distribute(uint256 _rewards) external;

    event Distribute(uint256 _rewards, uint256 _accRewardPerShare);
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.4;

import { ICommonReward } from "./ICommonReward.sol";

interface IVaultRewardDistributor is ICommonReward {
    function stake(uint256 _amountIn) external;

    function withdraw(uint256 _amountOut) external returns (uint256);

    event SetSupplyRewardPoolRatio(uint256 _ratio);
    event SetBorrowedRewardPoolRatio(uint256 _ratio);
    event SetSupplyRewardPool(address _rewardPool);
    event SetBorrowedRewardPool(address _rewardPool);
    event Stake(uint256 _amountIn);
    event Withdraw(uint256 _amountOut);
}