// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
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
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

error OnlyNonZeroAddress();

abstract contract CheckerZeroAddr is Initializable {
    modifier onlyNonZeroAddress(address addr) {
        _onlyNonZeroAddress(addr);
        _;
    }

    function __CheckerZeroAddr_init_unchained() internal onlyInitializing {}

    function _onlyNonZeroAddress(address addr) private pure {
        if (addr == address(0)) {
            revert OnlyNonZeroAddress();
        }
    }

    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/ITokensRescuer.sol";

import "./CheckerZeroAddr.sol";

abstract contract TokensRescuer is
    Initializable,
    ITokensRescuer,
    CheckerZeroAddr
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function __TokensRescuer_init_unchained() internal onlyInitializing {}

    function _rescueNativeToken(
        uint256 amount,
        address receiver
    ) internal onlyNonZeroAddress(receiver) {
        AddressUpgradeable.sendValue(payable(receiver), amount);
    }

    function _rescueERC20Token(
        address token,
        uint256 amount,
        address receiver
    ) internal virtual onlyNonZeroAddress(receiver) onlyNonZeroAddress(token) {
        IERC20Upgradeable(token).safeTransfer(receiver, amount);
    }

    uint256[50] private __gap;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICurve is IERC20 {
    /**
     * @notice Wrap underlying coins and deposit them in the pool
     * @param amounts List of amounts of underlying coins to deposit
     * @param minMintAmount Minimum amount of LP tokens to mint from the
     *                      deposit
     * @return Amount of LP tokens received by depositing
     **/
    function add_liquidity(
        uint256[2] calldata amounts,
        uint256 minMintAmount
    ) external returns (uint256);

    /**
     * @notice Withdraw and unwrap coins from the pool
     * @dev Withdrawal amounts are based on current deposit ratios
     * @param amount Quantity of LP tokens to burn in the withdrawal
     * @param minAmounts Minimum amounts of underlying coins to receive
     * @return List of amounts of underlying coins that were withdrawn
     **/
    function remove_liquidity(
        uint256 amount,
        uint256[2] calldata minAmounts
    ) external returns (uint256[2] memory);

    /**
     * @notice Calculate addition or reduction in token supply from a deposit
     *         or withdrawal
     * @dev This calculation accounts for slippage, but not fees.
     *      Needed to prevent front-running, not for precise calculations!
     * @param amounts Amount of each underlying coin being deposited
     * @param isDeposit set True for deposits, False for withdrawals
     * @return Expected amount of LP tokens received
     **/
    function calc_token_amount(
        uint256[2] calldata amounts,
        bool isDeposit
    ) external view returns (uint256);

    /**
     * @notice Returns a balance of a specified coin in the Curve's liquidity
     *         pool.
     * @param coinId An ID (index) of a coin to check its balance in the
     *        liquidity pool.
     * @return A balance of a specified coin in the Curve's liquidity pool.
     */
    function balances(uint256 coinId) external view returns (uint256);

    /**
     * @notice Returns a total supply of Curve's liquidity pool
     * @return A total supply of Curve's liquidity pool
     */
    function totalSupply() external view returns (uint256);
}

//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

pragma solidity 0.8.15;

interface IParallax {
    /**
     * @notice Represents a single strategy with its relevant data.
     */
    struct Strategy {
        uint256 fee;
        uint256 totalStaked;
        uint256 totalShares;
        uint256 lastCompoundTimestamp;
        uint256 cap;
        uint256 rewardPerBlock;
        uint256 rewardPerShare;
        uint256 lastUpdatedBlockNumber;
        address strategy;
        uint32 timelock;
        bool isActive;
        IERC20Upgradeable rewardToken;
        uint256 usersCount;
    }

    /// @notice The view method for getting current feesReceiver.
    function feesReceiver() external view returns (address);

    /**
     * @notice The view method for getting current withdrawal fee by strategy.
     * @param strategy An address of a strategy.
     * @return Withdrawal fee.
     **/
    function getFee(address strategy) external view returns (uint256);

    /** @notice Returns the ID of the NFT owned by the specified user at the
     *           given index.
     *  @param user The address of the user who owns the NFT.
     *  @param index The index of the NFT to return.
     *  @return The ID of the NFT at the given index, owned by the specified
     *          user.
     */
    function getNftByUserAndIndex(
        address user,
        uint256 index
    ) external view returns (uint256);

    /**
     * @notice The view method to check if the token is in the whitelist.
     * @param strategy An address of a strategy.
     * @param token An address of a token to check.
     * @return Boolean flag.
     **/
    function tokensWhitelist(
        address strategy,
        address token
    ) external view returns (bool);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./ITokensRescuer.sol";

interface IParallaxStrategy is ITokensRescuer {
    /**
     * @param params parameters for deposit.
     *               amountsOutMin -  an array of minimum values
     *                 that will be received during exchanges,
     *                 withdrawals or deposits of liquidity, etc.
     *                 All values can be 0 that means
     *                 that you agreed with any output value.
     *               paths - paths that will be used during swaps.
     *               user - user from whom assets are debited for the deposit.
     *               holder - user to whose address the deposit is made.
     *               positionId - id of the position.
     *               amounts - array of amounts to deposit.
     *               data - additional data for strategy.
     */
    struct DepositParams {
        uint256[] amountsOutMin;
        address[][] paths;
        address user;
        address holder;
        uint256 positionId;
        uint256[] amounts;
        bytes[] data;
    }

    /**
     * @param params parameters for withdraw.
     *               amountsOutMin -  an array of minimum values
     *                 that will be received during exchanges,
     *                 withdrawals or deposits of liquidity, etc.
     *                 All values can be 0 that means
     *                 that you agreed with any output value.
     *               paths - paths that will be used during swaps.
     *               positionId - id of the position.
     *               earned - earnings for the current number of shares.
     *               amounts - array of amounts to deposit.
     *               receiver - address of the user who will receive
     *                          the withdrawn assets.
     *               data - additional data for strategy.
     */
    struct WithdrawParams {
        uint256[] amountsOutMin;
        address[][] paths;
        uint256 positionId;
        uint256 earned;
        uint256 amount;
        address receiver;
        bytes[] data;
    }

    /**
     * @notice Sets the minimum amount required for compounding.
     * @param compoundMinAmount The new minimum amount for compounding.
     */
    function setCompoundMinAmount(uint256 compoundMinAmount) external;

    /**
     * @notice Allows to deposit LP tokens directly
     *         Executes compound before depositing.
     *         Tokens that is depositing must be approved to this contract.
     *         Can only be called by the Parallax contact.
     * @param params Parameters for deposit.
     * @return amount of deposited tokens
     */
    function depositLPs(DepositParams memory params) external returns (uint256);

    /**
     * @notice Allows to deposit strategy tokens directly.
     *         Executes compound before depositing.
     *         Tokens that is depositing must be approved to this contract.
     *         Can only be called by the Parallax contact.
     * @param params Parameters for deposit.
     * @return amount of deposited tokens
     */
    function depositTokens(
        DepositParams memory params
    ) external returns (uint256);

    /**
     * @notice Allows to deposit native tokens.
     *         Executes compound before depositing.
     *         Can only be called by the Parallax contact.
     * @param params Parameters for deposit.
     * @return amount of deposited tokens.
     */
    function depositAndSwapNativeToken(
        DepositParams memory params
    ) external payable returns (uint256);

    /**
     * @notice Allows to deposit whitelisted ERC-20 token.
     *      ERC-20 token that is depositing must be approved to this contract.
     *      Executes compound before depositing.
     *      Can only be called by the Parallax contact.
     * @param params Parameters for deposit.
     * @return amount of deposited tokens
     */
    function depositAndSwapERC20Token(
        DepositParams memory params
    ) external returns (uint256);

    /**
     * @notice withdraws needed amount of staked LPs
     *      Sends to the user his LP tokens
     *      and withdrawal fees to the fees receiver.
     *      Executes compound before withdrawing.
     *      Can only be called by the Parallax contact.
     * @param params Parameters for withdraw.
     */
    function withdrawLPs(WithdrawParams memory params) external;

    /**
     * @notice withdraws needed amount of staked LPs
     *      from the Sorbettiere staking smart-contract.
     *      Sends to the user his strategy tokens
     *      and withdrawal fees to the fees receiver.
     *      Executes compound before withdrawing.
     *      Can only be called by the Parallax contact.
     * @param params Parameters for withdraw.
     */
    function withdrawTokens(WithdrawParams memory params) external;

    /**
     * @notice withdraws needed amount of staked LPs
     *      Exchanges all received strategy tokens for ETH token.
     *      Sends to the user his token and withdrawal fees to the fees receiver
     *      Executes compound before withdrawing.
     *      Can only be called by the Parallax contact.
     * @param params Parameters for withdraw.
     */
    function withdrawAndSwapForNativeToken(
        WithdrawParams memory params
    ) external;

    /**
     * @notice withdraws needed amount of staked LPs
     *      Exchanges all received strategy tokens for whitelisted ERC20 token.
     *      Sends to the user his token and withdrawal fees to the fees receiver
     *      Executes compound before withdrawing.
     *      Can only be called by the Parallax contact.
     * @param params Parameters for withdraw.
     */
    function withdrawAndSwapForERC20Token(
        WithdrawParams memory params
    ) external;

    /**
     * @notice Informs the strategy about the position transfer
     * @param from A wallet from which token (user position) will be transferred.
     * @param to A wallet to which token (user position) will be transferred.
     * @param tokenId An ID of a token to transfer which is related to user
     *                position.
     */
    function transferPositionFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @notice Informs the strategy about the claim rewards.
     * @param strategyId An ID of an earning strategy.
     * @param user Holder of position.
     * @param positionId An ID of a position.
     */
    function claim(
        uint256 strategyId,
        address user,
        uint256 positionId
    ) external;

    /**
     * @notice claims all rewards
     *      Then exchanges them for strategy tokens.
     *      Receives LP tokens for liquidity and deposits received LP tokens to
     *      increase future rewards.
     *      Can only be called by the Parallax contact.
     * @param amountsOutMin an array of minimum values
     *                      that will be received during exchanges,
     *                      withdrawals or deposits of liquidity, etc.
     *                      All values can be 0 that means
     *                      that you agreed with any output value.
     * @return received LP tokens earned with compound.
     */
    function compound(
        uint256[] memory amountsOutMin,
        bool toRevertIfFail
    ) external returns (uint256);

    /**
     * @notice Returns the maximum commission values for the current strategy.
     *      Can not be updated after the deployment of the strategy.
     *      Can be called by anyone.
     * @return max fee for this strategy
     */
    function getMaxFee() external view returns (uint256);

    /**
     * @notice A function that returns the accumulated fees.
     * @dev This is an external view function that returns the current
     *      accumulated fees.
     * @return The current accumulated fees as a uint256 value.
     */
    function accumulatedFees() external view returns (uint256);

    /**
     * @notice A function that returns the address of the strategy author.
     * @dev This is an external view function that returns the address
     *      associated with the author of the strategy.
     * @return The address of the strategy author as an 'address' type.
     */
    function STRATEGY_AUTHOR() external view returns (address);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ISorbettiere {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 remainingIceTokenReward;
    }

    struct PoolInfo {
        IERC20 stakingToken;
        uint256 stakingTokenTotalAmount;
        uint256 accIcePerShare;
        uint32 lastRewardTime;
        uint16 allocPoint;
    }

    /// @notice Deposit staking tokens to Sorbettiere for ICE allocation.
    function deposit(uint256 pid, uint256 amount) external;

    /// @notice Withdraw staked tokens from Sorbettiere.
    function withdraw(uint256 pid, uint256 amount) external;

    /// @notice Info of each user.
    function userInfo(
        uint256 pid,
        address user
    ) external view returns (UserInfo memory);

    /**
     * @notice View function to see pending ICE.
     *         stakingToken - How many LP tokens the user has provided.
     *         rewardDebt -  Reward debt. See explanation below.
     *         remainingIceTokenReward - ICE Tokens that weren't distributed
     *         for user per pool.
     */
    function pendingIce(
        uint256 pid,
        address user
    ) external view returns (uint256);

    /**
     * @notice View function to see info of each pool.
     *         amount - How many LP tokens the user has provided.
     *         stakingTokenTotalAmount -  Total amount of deposited tokens.
     *         accIcePerShare - Accumulated ICE per share, times 1e12.
     *                          See below.
     *         lastRewardTime - Last timestamp number that ICE distribution
     *                          occurs.
     *         allocPoint - How many allocation points assigned to this pool.
     *                      ICE to distribute per second.
     */
    function poolInfo(uint256 pid) external view returns (PoolInfo memory);

    /// @notice Time on which the reward calculation should end
    function endTime() external view returns (uint256);

    /// @notice Ice tokens vested per second.
    function icePerSecond() external view returns (uint256);

    /// @notice Total allocation poitns. Must be the sum of all allocation
    ///         points in all pools.
    function totalAllocPoint() external view returns (uint256);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface ITokensRescuer {
    /**
     * @dev withdraws an ETH token that accidentally ended up
     *      on this contract and cannot be used in any way.
     *      Can only be called by the current owner.
     * @param amount - a number of tokens to withdraw from this contract.
     * @param receiver - a wallet that will receive withdrawing tokens.
     */
    function rescueNativeToken(uint256 amount, address receiver) external;

    /**
     * @dev withdraws an ERC-20 token that accidentally ended up
     *      on this contract and cannot be used in any way.
     *      Can only be called by the current owner.
     * @param token - a number of tokens to withdraw from this contract.
     * @param amount - a number of tokens to withdraw from this contract.
     * @param receiver - a wallet that will receive withdrawing tokens.
     */
    function rescueERC20Token(
        address token,
        uint256 amount,
        address receiver
    ) external;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/IParallaxStrategy.sol";
import "../interfaces/IParallax.sol";

import "../interfaces/ISorbettiere.sol";
import "../interfaces/ICurve.sol";

import "../extensions/TokensRescuer.sol";

error OnlyValidSlippage();
error OnlyParallax();
error OnlyCorrectPath();
error OnlyWhitelistedToken();
error OnlyValidOutputAmount();
error OnlyCorrectPathLength();
error OnlyCorrectArrayLength();

/**
 * @title A smart-contract that implements Curve's USDC-USDT/MIM LP
 *        Sorbettiere earning strategy.
 */
contract CurveMIM3CRVSorbettiereStrategyUpgradeable is
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    TokensRescuer,
    IParallaxStrategy
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct InternalDepositParams {
        uint256 usdcAmount;
        uint256 usdtAmount;
        uint256 mimAmount;
        uint256 usdcUsdtLPsAmountOutMin;
        uint256 mimUsdcUsdtLPsAmountOutMin;
    }

    struct InternalWithdrawParams {
        uint256 amount;
        uint256 actualWithdraw;
        uint256 mimAmountOutMin;
        uint256 usdcUsdtLPsAmountOutMin;
        uint256 usdcAmountOutMin;
        uint256 usdtAmountOutMin;
    }

    struct InitParams {
        address _PARALLAX;
        address _SORBETTIERE;
        address _SPELL;
        address _WETH;
        address _USDC;
        address _USDT;
        address _MIM;
        address _SUSHI_SWAP_ROUTER;
        address _USDC_USDT_POOL;
        address _MIM_USDC_USDT_LP_POOL;
        address _MIM_USD_ORACLE;
        address _SPELL_USD_ORACLE;
        uint256 _EXPIRE_TIME;
        uint256 maxSlippage;
        uint256 initialCompoundMinAmount;
    }

    address public constant STRATEGY_AUTHOR = address(0);

    address public PARALLAX;

    address public SORBETTIERE;
    address public SPELL;

    address public WETH;
    address public USDC;
    address public USDT;
    address public MIM;

    address public SUSHI_SWAP_ROUTER;

    address public USDC_USDT_POOL;
    address public MIM_USDC_USDT_LP_POOL;

    AggregatorV2V3Interface public MIM_USD_ORACLE;
    AggregatorV2V3Interface public SPELL_USD_ORACLE;

    uint256 public EXPIRE_TIME;

    uint256 public maxSlippage;

    uint256 public accumulatedFees;

    uint256 public compoundMinAmount;

    // The maximum withdrawal commission. On this strategy can't be more than
    // 10000 = 100%
    uint256 public constant MAX_WITHDRAW_FEE = 10000;

    // The maximum uptime of oracle data
    uint256 public constant STALE_PRICE_DELAY = 24 hours;
    
    modifier onlyParallax() {
        _onlyParallax();
        _;
    }

    modifier onlyCorrectPathLength(address[] memory path) {
        _onlyCorrectPathLength(path);
        _;
    }

    modifier onlyCorrectPath(
        address tokenIn,
        address tokenOut,
        address[] memory path
    ) {
        _onlyCorrectPath(tokenIn, tokenOut, path);
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev Initializes the contract
     * @param initParams Contains the following variables:
     *                   PARALLAX - address of the main contract that controls
     *                              all strategies in the system.
     *                   SORBETTIERE - address of the Sorbettiere's staking
     *                                 smart-contract.
     *                   SPELL - address of SPELL token.
     *                   WETH - address of WETH token.
     *                   MIM - address of MIM token.
     *                   USDC - address of USDC token.
     *                   USDT - address of USDT token.
     *                   SUSHI_SWAP_ROUTER - address of the SushiSwap's Router
     *                                       smart-contract used in the strategy
     *                                       for exchanges.
     *                   USDC_USDT_POOL - address of Curve's USDC/USDT pool
     *                                    (2CRV, Curve.fi USDC/USDT) used.
     *                   MIM_USDC_USDT_LP_POOL - address of Curve's
     *                                           MIM/USDC-USDT LP pool
     *                                           (MIM3CRV-f, Curve.fi Factory
     *                                           USD Metapool: MIM).
     *                   MIM_USD_ORACLE - address of MIM/USD chainLink oracle.
     *                   SPELL_USD_ORACLE - SPELL/USD chainLink oracle address.
     *                   EXPIRE_TIME - number (in seconds) during which
     *                                 all exchange transactions in this
     *                                 strategy are valid. If time elapsed,
     *                                 exchange and transaction will fail.
     *                   initialCompoundMinAmount - value in reward token
     *                                              after which compound must be
     *                                              executed.
     */
    function __CurveMIM3CRVSorbettiereStrategy_init(
        InitParams memory initParams
    ) external initializer {
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __CurveMIM3CRVSorbettiereStrategy_init_unchained(initParams);
    }

    /**
     * @notice Sets a new max slippage for SPELL-MIM swaps during compound.
     *         Can only be called by the Parallax contact (via Timelock).
     * @dev 10.00% is the max possible slippage.
     * @param newMaxSlippage Maximum deviation during swap from the oracle
     *                       rate. 100 = 1.00%, 500 = 5.00%
     */
    function setMaxSlippage(uint256 newMaxSlippage) external onlyParallax {
        if (newMaxSlippage > 1000) {
            revert OnlyValidSlippage();
        }

        maxSlippage = newMaxSlippage;
    }

    /**
     * @notice Sets a value (in SPELL token) after which compound must
     *         be executed.The compound operation is performed during every
     *         deposit and withdrawal. And sometimes there may not be enough
     *         reward tokens to complete all the exchanges and liquidity.
     *         additions. As a result, deposit and withdrawal transactions
     *         may fail. To avoid such a problem, this value is provided.
     *         And if the number of rewards is even less than it, the compound
     *         does not occur. As soon as there are more of them, a compound
     *         immediately occurs in time of first deposit or withdrawal.
     *         Can only be called by the Parallax contact.
     * @param newCompoundMinAmount A value in SPELL token after which compound
     *                             must be executed.
     */
    function setCompoundMinAmount(
        uint256 newCompoundMinAmount
    ) external onlyParallax {
        compoundMinAmount = newCompoundMinAmount;
    }

    /**
     * @notice deposits Curve's MIM/USDC-USDT LPs into the vault
     *         deposits these LPs into the Sorbettiere's staking smart-contract.
     *         LP tokens that are depositing must be approved to this contract.
     *         Executes compound before depositing.
     *         Can only be called by the Parallax contact.
     * @param params parameters for deposit.
     *               amount - amount of LP tokens for deposit
     *               user - address of the user
     *                 to whose account the deposit will be made
     *               positionId - id of the position.
     *               data - additional data for strategy.
     * @return amount of deposited tokens
     */
    function depositLPs(
        DepositParams memory params
    ) external nonReentrant onlyParallax returns (uint256) {
        if (params.amounts[0] > 0) {
            IERC20Upgradeable(MIM_USDC_USDT_LP_POOL).safeTransferFrom(
                params.user,
                address(this),
                params.amounts[0]
            );

            // Deposit (stake) Curve's MIM/USDC-USDT LP tokens
            // in the Sorbettiere staking pool
            _sorbettiereDeposit(params.amounts[0]);
        }

        return params.amounts[0];
    }

    /**
     *  @notice accepts USDC, USDT, and MIM tokens in equal parts.
     *       Provides USDC and USDT tokens
     *       to the Curve's USDC/USDT liquidity pool.
     *       Provides received LPs (from Curve's USDC/USDT liquidity pool)
     *       and MIM tokens to the Curve's MIM/USDC-USDT LP liquidity pool.
     *       Deposits MIM/USDC-USDT LPs into the Sorbettiere's staking
     *       smart-contract. USDC, USDT, and MIM tokens that are depositing
     *       must be approved to this contract.
     *       Executes compound before depositing.
     *       Can only be called by the Parallax contact.
     * @param params parameters for deposit.
     *               amount - must be set in USDC/USDT tokens (with 6 decimals).
     *                 MIM token will be charged the same as USDC and USDT
     *                 but with 18 decimal places
     *                 (18-6=12 additional zeros will be added).
     *                amountsOutMin -  an array of minimum values
     *                 that will be received during exchanges,
     *                 withdrawals or deposits of liquidity, etc.
     *                 All values can be 0 that means
     *                 that you agreed with any output value.
     *                 For this strategy and this method
     *                 it must contain 2 elements:
     *                 0 - minimum amount of output USDC/USDT LP tokens
     *                 during add liquidity to Curve's USDC/USDT liquidity pool.
     *                 1 - minimum amount of output MIM/USDC-USDT LP tokens
     *                 during add liquidity to Curve's
     *                 MIM/USDC-USDT liquidity pool.
     *               user - address of the user
     *                 to whose account the deposit will be made
     *               positionId - id of the position.
     *               data - additional data for strategy.
     * @return amount of deposited tokens
     */
    function depositTokens(
        DepositParams memory params
    ) external nonReentrant onlyParallax returns (uint256) {
        _onlyCorrectArrayLength(params.amountsOutMin.length, 2);

        if (
            params.amounts[0] > 0 ||
            params.amounts[1] > 0 ||
            params.amounts[2] > 0
        ) {
            // Transfer equal amounts of USDC, USDT, and MIM tokens
            // from a user to this contract

            IERC20Upgradeable(USDC).safeTransferFrom(
                params.user,
                address(this),
                params.amounts[0]
            );
            IERC20Upgradeable(USDT).safeTransferFrom(
                params.user,
                address(this),
                params.amounts[1]
            );
            IERC20Upgradeable(MIM).safeTransferFrom(
                params.user,
                address(this),
                params.amounts[2]
            );

            // Deposit
            uint256 deposited = _deposit(
                InternalDepositParams({
                    usdcAmount: params.amounts[0],
                    usdtAmount: params.amounts[1],
                    mimAmount: params.amounts[2],
                    usdcUsdtLPsAmountOutMin: params.amountsOutMin[0],
                    mimUsdcUsdtLPsAmountOutMin: params.amountsOutMin[1]
                })
            );

            return deposited;
        }

        return 0;
    }

    /**
     * @notice accepts ETH token.
     *      Swaps third of it for USDC, third for USDT, and third for MIM tokens
     *      Provides USDC and USDT tokens to the
     *      Curve's USDC/USDT liquidity pool.
     *      Provides received LPs (from Curve's USDC/USDT liquidity pool)
     *      and MIM tokens to the Curve's MIM/USDC-USDT LP liquidity pool.
     *      Deposits MIM/USDC-USDT LPs into the Sorbettiere's
     *      staking smart-contract.
     *      Executes compound before depositing.
     *      Can only be called by the Parallax contact.
     * @param params parameters for deposit.
     *               amountsOutMin -  an array of minimum values
     *                 that will be received during exchanges,
     *                 withdrawals or deposits of liquidity, etc.
     *                 All values can be 0 that means
     *                 that you agreed with any output value.
     *                 For this strategy and this method
     *                 it must contain 5 elements:
     *                 0 - minimum amount of output USDC tokens
     *                 during swap of ETH tokens to USDC tokens on SushiSwap.
     *                 1 - minimum amount of output USDT tokens
     *                 during swap of ETH tokens to USDT tokens on SushiSwap.
     *                 2 - minimum amount of output MIM tokens
     *                 during swap of ETH tokens to MIM tokens on SushiSwap.
     *                 3 - minimum amount of output USDC/USDT LP tokens
     *                 during add liquidity to Curve's USDC/USDT liquidity pool.
     *                 4 - minimum amount of output MIM/USDC-USDT LP tokens
     *                 during add liquidity to Curve's MIM/USDC-USDT
     *                 liquidity pool.
     *               paths - paths that will be used during swaps.
     *                 For this strategy and this method
     *                 it must contain 3 elements:
     *                 0 - route for swap of ETH tokens to USDC tokens
     *                 (e.g.: [WETH, USDC], or [WETH, MIM, USDC]).
     *                 The first element must be WETH, the last one USDC.
     *                 1 - route for swap of ETH tokens to USDT tokens
     *                 (e.g.: [WETH, USDT], or [WETH, MIM, USDT]).
     *                 The first element must be WETH, the last one USDT.
     *                 2 - route for swap of ETH tokens to MIM tokens
     *                 (e.g.: [WETH, MIM], or [WETH, USDC, MIM]).
     *                 The first element must be WETH, the last one MIM.
     *                positionId - id of the position.
     *                data - additional data for strategy.
     * @return amount of deposited tokens
     */
    function depositAndSwapNativeToken(
        DepositParams memory params
    ) external payable nonReentrant onlyParallax returns (uint256) {
        _onlyCorrectArrayLength(params.amountsOutMin.length, 5);
        _onlyCorrectArrayLength(params.paths.length, 3);

        if (msg.value > 0) {
            // Swap native tokens for USDC, USDT, and MIM tokens in equal parts
            uint256 third = msg.value / 3;
            uint256 receivedUsdc = _swapETHForTokens(
                USDC,
                third,
                params.amountsOutMin[0],
                params.paths[0]
            );
            uint256 receivedUsdt = _swapETHForTokens(
                USDT,
                third,
                params.amountsOutMin[1],
                params.paths[1]
            );
            uint256 receivedMim = _swapETHForTokens(
                MIM,
                msg.value - 2 * third,
                params.amountsOutMin[2],
                params.paths[2]
            );

            // Deposit
            uint256 deposited = _deposit(
                InternalDepositParams({
                    usdcAmount: receivedUsdc,
                    usdtAmount: receivedUsdt,
                    mimAmount: receivedMim,
                    usdcUsdtLPsAmountOutMin: params.amountsOutMin[3],
                    mimUsdcUsdtLPsAmountOutMin: params.amountsOutMin[4]
                })
            );

            return deposited;
        }

        return 0;
    }

    /**
     * @notice accepts any whitelisted ERC-20 token.
     *      Swaps third of it for USDC, third for USDT, and third for MIM tokens
     *      Provides USDC and USDT tokens
     *      to the Curve's USDC/USDT liquidity pool.
     *      Provides received LPs (from Curve's USDC/USDT liquidity pool)
     *      and MIM tokens to the Curve's MIM/USDC-USDT LP liquidity pool.
     *      After that deposits MIM/USDC-USDT LPs
     *      into the Sorbettiere's staking smart-contract.
     *      ERC-20 token that is depositing must be approved to this contract.
     *      Executes compound before depositing.
     *      Can only be called by the Parallax contact.
     * @param params parameters for deposit.
     *               amount - amount of erc20 tokens for swap and deposit
     *               token - address of erc20 token
     *               amountsOutMin -  an array of minimum values
     *                 that will be received during exchanges,
     *                 withdrawals or deposits of liquidity, etc.
     *                 All values can be 0 that means
     *                 that you agreed with any output value.
     *                 For this strategy and this method
     *                 it must contain 5 elements:
     *                 0 - minimum amount of output USDC tokens
     *                 during swap of ETH tokens to USDC tokens on SushiSwap.
     *                 1 - minimum amount of output USDT tokens
     *                 during swap of ETH tokens to USDT tokens on SushiSwap.
     *                 2 - minimum amount of output MIM tokens
     *                 during swap of ETH tokens to MIM tokens on SushiSwap.
     *                 3 - minimum amount of output USDC/USDT LP tokens
     *                 during add liquidity to Curve's USDC/USDT liquidity pool.
     *                 4 - minimum amount of output MIM/USDC-USDT LP tokens
     *                 during add liquidity to Curve's MIM/USDC-USDT
     *                 liquidity pool.
     *               paths - paths that will be used during swaps.
     *                 For this strategy and this method
     *                 it must contain 3 elements:
     *                 0 - route for swap of ETH tokens to USDC tokens
     *                 (e.g.: [WETH, USDC], or [WETH, MIM, USDC]).
     *                 The first element must be WETH, the last one USDC.
     *                 1 - route for swap of ETH tokens to USDT tokens
     *                 (e.g.: [WETH, USDT], or [WETH, MIM, USDT]).
     *                 The first element must be WETH, the last one USDT.
     *                 2 - route for swap of ETH tokens to MIM tokens
     *                 (e.g.: [WETH, MIM], or [WETH, USDC, MIM]).
     *                 The first element must be WETH, the last one MIM.
     *               user - address of the user
     *                 to whose account the deposit will be made
     *               positionId - id of the position.
     *               data - additional data for strategy.
     * @return amount of deposited tokens
     */
    function depositAndSwapERC20Token(
        DepositParams memory params
    ) external nonReentrant onlyParallax returns (uint256) {
        _onlyCorrectArrayLength(params.amountsOutMin.length, 5);
        _onlyCorrectArrayLength(params.paths.length, 3);
        _onlyCorrectArrayLength(params.data.length, 1);

        address token = address(uint160(bytes20(params.data[0])));
        _onlyWhitelistedToken(token);

        if (params.amounts[0] > 0) {
            // Transfer whitelisted ERC20 tokens from a user to this contract
            IERC20Upgradeable(token).safeTransferFrom(
                params.user,
                address(this),
                params.amounts[0]
            );

            // Swap ERC20 tokens for USDC, USDT, and MIM tokens in equal parts
            uint256 third = params.amounts[0] / 3;

            uint256 receivedUsdc;
            if (token == USDC) {
                receivedUsdc = third;
            } else {
                receivedUsdc = _swapTokensForTokens(
                    token,
                    USDC,
                    third,
                    params.amountsOutMin[0],
                    params.paths[0]
                );
            }

            uint256 receivedUsdt;
            if (token == USDT) {
                receivedUsdt = third;
            } else {
                receivedUsdt = _swapTokensForTokens(
                    token,
                    USDT,
                    third,
                    params.amountsOutMin[1],
                    params.paths[1]
                );
            }

            uint256 receivedMim;
            if (token == MIM) {
                receivedMim = third;
            } else {
                receivedMim = _swapTokensForTokens(
                    token,
                    MIM,
                    third,
                    params.amountsOutMin[2],
                    params.paths[2]
                );
            }

            // Deposit
            uint256 deposited = _deposit(
                InternalDepositParams({
                    usdcAmount: receivedUsdc,
                    usdtAmount: receivedUsdt,
                    mimAmount: receivedMim,
                    usdcUsdtLPsAmountOutMin: params.amountsOutMin[3],
                    mimUsdcUsdtLPsAmountOutMin: params.amountsOutMin[4]
                })
            );

            return deposited;
        }

        return 0;
    }

    /**
     * @notice withdraws needed amount of staked Curve's MIM/USDC-USDT LPs
     *      from the Sorbettiere staking smart-contract.
     *      Sends to the user his MIM/USDC-USDT LP tokens
     *      and withdrawal fees to the fees receiver.
     *      Executes compound before withdrawing.
     *      Can only be called by the Parallax contact.
     *  @param params parameters for deposit.
     *                amount - amount of LP tokens to withdraw
     *                receiver - adress of recipient
     *                  to whom the assets will be sent
     *                earned - lp tokens earned in proportion to the amount of
     *                  withdrawal
     *                positionId - id of the position.
     *                data - additional data for strategy.
     */
    function withdrawLPs(
        WithdrawParams memory params
    ) external nonReentrant onlyParallax {
        if (params.amount > 0) {
            // Withdraw (unstake) Curve's MIM/USDC-USDT LP tokens from the
            // Sorbettiere staking pool
            _sorbettiereWithdraw(params.amount);

            // Calculate withdrawal fee and actual witdraw
            (
                uint256 actualWithdraw,
                uint256 withdrawalFee
            ) = _calculateActualWithdrawAndWithdrawalFee(
                    params.amount,
                    params.earned
                );

            // Send tokens to the receiver and withdrawal fee to the fees
            // receiver
            IERC20Upgradeable(MIM_USDC_USDT_LP_POOL).safeTransfer(
                params.receiver,
                actualWithdraw
            );

            _takeFee(withdrawalFee);
        }
    }

    /**
     * @notice withdraws needed amount of staked Curve's MIM/USDC-USDT LPs
     *      from the Sorbettiere staking smart-contract.
     *      Then removes the liquidity from the
     *      Curve's MIM/USDC-USDT liquidity pool.
     *      Using received USDC/USDT LPs removes the liquidity
     *      form the Curve's USDC/USDT liquidity pool.
     *      Sends to the user his USDC, USDT, and MIM tokens
     *      and withdrawal fees to the fees receiver.
     *      Executes compound before withdrawing.
     *      Can only be called by the Parallax contact.
     * @param params parameters for deposit.
     *               amount - amount of LP tokens to withdraw
     *               receiver - adress of recipient
     *                 to whom the assets will be sent
     *               amountsOutMin - an array of minimum values
     *                 that will be received during exchanges, withdrawals
     *                 or deposits of liquidity, etc.
     *                 All values can be 0 that means
     *                 that you agreed with any output value.
     *                 For this strategy and this method
     *                 it must contain 4 elements:
     *                 0 - minimum amount of output MIM tokens during
     *                 remove liquidity from Curve's MIM/USDC-USDT liquidity pool.
     *                 1 - minimum amount of output USDC/USDT LP tokens during
     *                 remove liquidity from Curve's MIM/USDC-USDT liquidity pool.
     *                 2 - minimum amount of output USDC tokens during removing liquidity
     *                 from Curve's USDC/USDT liquidity pool.
     *                 3 - minimum amount of output USDT tokens during
     *                 remove liquidity from Curve's USDC/USDT liquidity pool.
     *               earned - lp tokens earned in proportion to the amount of
     *                 withdrawal
     *               positionId - id of the position.
     *               data - additional data for strategy.
     */
    function withdrawTokens(
        WithdrawParams memory params
    ) external nonReentrant onlyParallax {
        _onlyCorrectArrayLength(params.amountsOutMin.length, 4);

        if (params.amount > 0) {
            // Calculate withdrawal fee and actual witdraw
            (
                uint256 actualWithdraw,
                uint256 withdrawalFee
            ) = _calculateActualWithdrawAndWithdrawalFee(
                    params.amount,
                    params.earned
                );
            // Withdraw
            (
                uint256 usdcLiquidity,
                uint256 usdtLiquidity,
                uint256 mimLiquidity
            ) = _withdraw(
                    InternalWithdrawParams({
                        amount: params.amount,
                        actualWithdraw: actualWithdraw,
                        mimAmountOutMin: params.amountsOutMin[0],
                        usdcUsdtLPsAmountOutMin: params.amountsOutMin[1],
                        usdcAmountOutMin: params.amountsOutMin[2],
                        usdtAmountOutMin: params.amountsOutMin[3]
                    })
                );

            // Send tokens to the receiver and withdrawal fee to the fees
            // receiver
            IERC20Upgradeable(USDC).safeTransfer(
                params.receiver,
                usdcLiquidity
            );
            IERC20Upgradeable(USDT).safeTransfer(
                params.receiver,
                usdtLiquidity
            );
            IERC20Upgradeable(MIM).safeTransfer(params.receiver, mimLiquidity);

            _takeFee(withdrawalFee);
        }
    }

    /**
     * @notice withdraws needed amount of staked Curve's MIM/USDC-USDT LPs
     *      from the Sorbettiere staking smart-contract.
     *      Then removes the liquidity from the
     *      Curve's MIM/USDC-USDT liquidity pool.
     *      Using received USDC/USDT LPs removes the liquidity
     *      form the Curve's USDC/USDT liquidity pool.
     *      Exchanges all received USDC, USDT, and MIM tokens for ETH token.
     *      Sends to the user his token and withdrawal fees to the fees receiver
     *      Executes compound before withdrawing.
     *      Can only be called by the Parallax contact.
     * @param params parameters for deposit.
     *               amount - amount of LP tokens to withdraw
     *               receiver - adress of recipient
     *                 to whom the assets will be sent
     *               amountsOutMin - an array of minimum values
     *                 that will be received during exchanges,
     *                 withdrawals or deposits of liquidity, etc.
     *                 All values can be 0 that means
     *                 that you agreed with any output value.
     *                 For this strategy and this method
     *                 it must contain 4 elements:
     *                 0 - minimum amount of output MIM tokens during
     *                 remove liquidity from Curve's MIM/USDC-USDT liquidity pool.
     *                 1 - minimum amount of output USDC/USDT LP tokens during
     *                 remove liquidity from Curve's MIM/USDC-USDT liquidity pool.
     *                 2 - minimum amount of output USDC tokens during
     *                 remove liquidity from Curve's USDC/USDT liquidity pool.
     *                 3 - minimum amount of output USDT tokens during
     *                 remove liquidity from Curve's USDC/USDT liquidity pool.
     *                 4 - minimum amount of output ETH tokens during
     *                 swap of USDC tokens to ETH tokens on SushiSwap.
     *                 5 - minimum amount of output ETH tokens during
     *                 swap of USDT tokens to ETH tokens on SushiSwap.
     *                 6 - minimum amount of output ETH tokens during
     *                 swap of MIM tokens to ETH tokens on SushiSwap.
     *               paths - paths that will be used during swaps.
     *                 For this strategy and this method
     *                 it must contain 3 elements:
     *                 0 - route for swap of USDC tokens to ETH tokens
     *                 (e.g.: [USDC, WETH], or [USDC, MIM, WETH]).
     *                 The first element must be USDC, the last one WETH.
     *                 1 - route for swap of USDT tokens to ETH tokens
     *                 (e.g.: [USDT, WETH], or [USDT, MIM, WETH]).
     *                 The first element must be USDT, the last one WETH.
     *                 2 - route for swap of MIM tokens to ETH tokens
     *                 (e.g.: [MIM, WETH], or [MIM, USDC, WETH]).
     *                 The first element must be MIM, the last one WETH.
     *               earned - lp tokens earned in proportion to the amount of
     *                 withdrawal
     *               positionId - id of the position.
     *               data - additional data for strategy.
     */
    function withdrawAndSwapForNativeToken(
        WithdrawParams memory params
    ) external nonReentrant onlyParallax {
        _onlyCorrectArrayLength(params.amountsOutMin.length, 7);
        _onlyCorrectArrayLength(params.paths.length, 3);

        if (params.amount > 0) {
            // Calculate withdrawal fee and actual witdraw
            (
                uint256 actualWithdraw,
                uint256 withdrawalFee
            ) = _calculateActualWithdrawAndWithdrawalFee(
                    params.amount,
                    params.earned
                );
            // Withdraw
            (
                uint256 usdcLiquidity,
                uint256 usdtLiquidity,
                uint256 mimLiquidity
            ) = _withdraw(
                    InternalWithdrawParams({
                        amount: params.amount,
                        actualWithdraw: actualWithdraw,
                        mimAmountOutMin: params.amountsOutMin[0],
                        usdcUsdtLPsAmountOutMin: params.amountsOutMin[1],
                        usdcAmountOutMin: params.amountsOutMin[2],
                        usdtAmountOutMin: params.amountsOutMin[3]
                    })
                );

            // Swap USDC, USDT, and MIM tokens for native tokens
            uint256 receivedETH = _swapTokensForETH(
                USDC,
                usdcLiquidity,
                params.amountsOutMin[4],
                params.paths[0]
            );

            receivedETH += _swapTokensForETH(
                USDT,
                usdtLiquidity,
                params.amountsOutMin[5],
                params.paths[1]
            );
            receivedETH += _swapTokensForETH(
                MIM,
                mimLiquidity,
                params.amountsOutMin[6],
                params.paths[2]
            );

            // Send tokens to the receiver and withdrawal fee to the fees
            // receiver
            AddressUpgradeable.sendValue(payable(params.receiver), receivedETH);

            _takeFee(withdrawalFee);
        }
    }

    /**
     * @notice withdraws the needed amount of staked Curve's MIM/USDC-USDT LPs
     *      from the Sorbettiere staking smart-contract. Then removes the
     *      liquidity from the Curve's MIM/USDC-USDT liquidity pool. Using
     *      received USDC/USDT LPs removes the liquidity from the Curve's
     *      USDC/USDT liquidity pool. Exchanges all received USDC, USDT, and
     *      MIM tokens for chosen by the user whitelisted ERC-20 token. Sends
     *      to the user his token and withdrawal fees to the fees receiver.
     *      Executes compound before withdrawing.
     *      Can only be called by the Parallax contact.
     * @param params parameters for deposit.
     *               amount - amount of LP tokens to withdraw
     *               receiver - adress of recipient
     *                 to whom the assets will be sent
     *               amountsOutMin - an array of minimum values
     *                 that will be received during exchanges,
     *                 withdrawals or deposits of liquidity, etc.
     *                 All values can be 0 that means
     *                 that you agreed with any output value.
     *                 For this strategy and this method
     *                 it must contain 7 elements:
     *                 0 - minimum amount of output MIM tokens during removing
     *                 liquidity from Curve's MIM/USDC-USDT liquidity pool.
     *                 1 - minimum amount of output USDC/USDT LP tokens during
     *                 removing liquidity from Curve's MIM/USDC-USDT liquidity pool.
     *                 2 - minimum amount of output USDC tokens during removing
     *                 liquidity from Curve's USDC/USDT liquidity pool.
     *                 3 - minimum amount of output USDT tokens during removing
     *                 liquidity from Curve's USDC/USDT liquidity pool.
     *                 4 - minimum amount of output user's ERC-20 tokens during
     *                 the swap of USDC tokens to user's ERC-20 tokens on SushiSwap.
     *                 5 - minimum amount of output user's ERC-20 tokens during
     *                 the swap of USDT tokens to user's ERC-20 tokens on SushiSwap.
     *                 6 - minimum amount of output user's ERC-20 tokens during
     *                 the swap of MIM tokens to user's ERC-20 tokens on SushiSwap.
     *               earned - lp tokens earned in proportion to the amount of
     *                 withdrawal
     *               token - address of chosen ERC20 token
     *               paths - paths that will be used during swaps.
     *                 0 - route for the swap of USDC tokens to the user's ERC-20
     *                 tokens (e.g.: [USDC, ERC-20], or [USDC, MIM, ERC-20]).
     *                 The first element must be USDC, and the last one user's
     *                 ERC-20.
     *                 1 - route for the swap of USDT tokens to the user's ERC-20
     *                 tokens (e.g.: [USDT, ERC-20], or [USDT, MIM, ERC-20]).
     *                 The first element must be USDT, and the last one user's
     *                 ERC-20.
     *                 2 - route for the swap of MIM tokens to the user's ERC-20
     *                 tokens (e.g.: [MIM, ERC-20], or [MIM, USDC, ERC-20]).
     *                 The first element must be MIM, and the last one user's
     *                 ERC-20.
     *               positionId - id of the position.
     *               data - additional data for strategy.
     */
    function withdrawAndSwapForERC20Token(
        WithdrawParams memory params
    ) external nonReentrant onlyParallax {
        _onlyCorrectArrayLength(params.amountsOutMin.length, 7);
        _onlyCorrectArrayLength(params.paths.length, 3);
        _onlyCorrectArrayLength(params.data.length, 1);

        address token = address(uint160(bytes20(params.data[0])));
        _onlyWhitelistedToken(token);

        if (params.amount > 0) {
            // Calculate withdrawal fee and actual witdraw
            (
                uint256 actualWithdraw,
                uint256 withdrawalFee
            ) = _calculateActualWithdrawAndWithdrawalFee(
                    params.amount,
                    params.earned
                );
            // Withdraw
            (
                uint256 usdcLiquidity,
                uint256 usdtLiquidity,
                uint256 mimLiquidity
            ) = _withdraw(
                    InternalWithdrawParams({
                        amount: params.amount,
                        actualWithdraw: actualWithdraw,
                        mimAmountOutMin: params.amountsOutMin[0],
                        usdcUsdtLPsAmountOutMin: params.amountsOutMin[1],
                        usdcAmountOutMin: params.amountsOutMin[2],
                        usdtAmountOutMin: params.amountsOutMin[3]
                    })
                );

            // Swap USDC, USDT, and MIM tokens for ERC20 tokens
            uint256 receivedERC20;

            if (token == USDC) {
                receivedERC20 += usdcLiquidity;
            } else {
                receivedERC20 += _swapTokensForTokens(
                    USDC,
                    token,
                    usdcLiquidity,
                    params.amountsOutMin[4],
                    params.paths[0]
                );
            }

            if (token == USDT) {
                receivedERC20 += usdtLiquidity;
            } else {
                receivedERC20 += _swapTokensForTokens(
                    USDT,
                    token,
                    usdtLiquidity,
                    params.amountsOutMin[5],
                    params.paths[1]
                );
            }

            if (token == MIM) {
                receivedERC20 += mimLiquidity;
            } else {
                receivedERC20 += _swapTokensForTokens(
                    MIM,
                    token,
                    mimLiquidity,
                    params.amountsOutMin[6],
                    params.paths[2]
                );
            }

            // Send tokens to the receiver and withdrawal fee to the fees
            // receiver
            IERC20Upgradeable(token).safeTransfer(
                params.receiver,
                receivedERC20
            );

            _takeFee(withdrawalFee);
        }
    }

    /**
     * @notice claims all rewards
     *      from the Sorbettiere's staking smart-contract (in SPELL token).
     *      Then exchanges them for USDC, USDT, and MIM tokens in equal parts.
     *      Adds exchanged tokens to the Curve's liquidity pools
     *      and deposits received LP tokens to increase future rewards.
     *      Can only be called by the Parallax contact.
     * @param amountsOutMin an array of minimum values
     *                      that will be received during exchanges,
     *                      withdrawals or deposits of liquidity, etc.
     *                      All values can be 0 that means
     *                      that you agreed with any output value.
     *                      For this strategy and this method
     *                      it must contain 4 elements:
     *                      0 - minimum amount of output USDC tokens during
     *                      swap of MIM tokens to USDC tokens on SushiSwap.
     *                      1 - minimum amount of output USDT tokens during
     *                      swap of MIM tokens to USDT tokens on SushiSwap.
     *                      2 - minimum amount of output USDC/USDT LP tokens
     *                      during add liquidity to
     *                      Curve's USDC/USDT liquidity pool.
     *                      3 - minimum amount of output MIM/USDC-USDT LP tokens
     *                      during add liquidity to
     *                      Curve's MIM/USDC-USDT liquidity pool.
     * @return received LP tokens from MimUsdcUsdt pool
     */
    function compound(
        uint256[] memory amountsOutMin,
        bool toRevertIfFail
    ) external nonReentrant onlyParallax returns (uint256) {
        _onlyCorrectArrayLength(amountsOutMin.length, 4);

        return _compound(amountsOutMin, toRevertIfFail);
    }

    /// @inheritdoc ITokensRescuer
    function rescueNativeToken(
        uint256 amount,
        address receiver
    ) external onlyParallax {
        _rescueNativeToken(amount, receiver);
    }

    /// @inheritdoc ITokensRescuer
    function rescueERC20Token(
        address token,
        uint256 amount,
        address receiver
    ) external onlyParallax {
        _rescueERC20Token(token, amount, receiver);
    }

    /// @inheritdoc IParallaxStrategy
    function getMaxFee() external pure returns (uint256) {
        return MAX_WITHDRAW_FEE;
    }

    /// @inheritdoc IParallaxStrategy
    /// @notice Unsupported function in this strategy
    function transferPositionFrom(
        address from,
        address to,
        uint256 tokenId
    ) external onlyParallax {}

    /// @inheritdoc IParallaxStrategy
    /// @notice Unsupported function in this strategy
    function claim(
        uint256 strategyId,
        address user,
        uint256 positionId
    ) external onlyParallax {}

    /**
     * @notice Unchained initializer for this contract.
     * @param initParams An initial parameters.
     */
    function __CurveMIM3CRVSorbettiereStrategy_init_unchained(
        InitParams memory initParams
    ) internal onlyInitializing {
        PARALLAX = initParams._PARALLAX;
        SORBETTIERE = initParams._SORBETTIERE;
        SPELL = initParams._SPELL;
        WETH = initParams._WETH;
        MIM = initParams._MIM;
        USDC = initParams._USDC;
        USDT = initParams._USDT;
        SUSHI_SWAP_ROUTER = initParams._SUSHI_SWAP_ROUTER;
        USDC_USDT_POOL = initParams._USDC_USDT_POOL;
        MIM_USDC_USDT_LP_POOL = initParams._MIM_USDC_USDT_LP_POOL;
        MIM_USD_ORACLE = AggregatorV2V3Interface(initParams._MIM_USD_ORACLE);
        SPELL_USD_ORACLE = AggregatorV2V3Interface(
            initParams._SPELL_USD_ORACLE
        );
        EXPIRE_TIME = initParams._EXPIRE_TIME;
        maxSlippage = initParams.maxSlippage;
        compoundMinAmount = initParams.initialCompoundMinAmount;
    }

    /**
     * @notice Adds a liquidity to Curve's liquidity pools and deposits tokens
     *         (LPs) into Abracadabra's farm.
     * @param params A deposit parameters.
     * @return An amount of Curve's LP tokens after deposit.
     */
    function _deposit(
        InternalDepositParams memory params
    ) private returns (uint256) {
        // Add liquidity to the Curve's USDC/USDT and MIM/USDC-USDT liquidity
        // pools
        uint256 receivedUsdcUsdtLPs = _curveAddLiquidity(
            USDC_USDT_POOL,
            USDC,
            params.usdcAmount,
            USDT,
            params.usdtAmount,
            params.usdcUsdtLPsAmountOutMin
        );
        uint256 receivedMimUsdcUsdtLPs = _curveAddLiquidity(
            MIM_USDC_USDT_LP_POOL,
            MIM,
            params.mimAmount,
            USDC_USDT_POOL,
            receivedUsdcUsdtLPs,
            params.mimUsdcUsdtLPsAmountOutMin
        );

        // Deposit (stake) Curve's MIM/USDC-USDT LP tokens in the Sorbettiere's
        // staking pool
        _sorbettiereDeposit(receivedMimUsdcUsdtLPs);

        return receivedMimUsdcUsdtLPs;
    }

    /**
     * @notice Withdraws tokens (LPs) from Abracadabra's farm and removes a
     *         liquidity from Curve's liquidity pools.
     * @param params A withdrawal parameters.
     * @return A tuple with received USDC, USDT and MIM amounts.
     */
    function _withdraw(
        InternalWithdrawParams memory params
    ) private returns (uint256, uint256, uint256) {
        // Withdraw (unstake) Curve's MIM/USDC-USDT LP tokens rom the
        // Sorbettiere's staking pool
        _sorbettiereWithdraw(params.amount);

        // Remove liquidity from the Curve's MIM/USDC-USDT and USDC/USDT
        // liquidity pools
        uint256[2] memory mimUsdcUsdtLPsLiquidity = _curveRemoveLiquidity(
            MIM_USDC_USDT_LP_POOL,
            params.actualWithdraw,
            params.mimAmountOutMin,
            params.usdcUsdtLPsAmountOutMin
        );
        uint256[2] memory usdcUsdtLiquidity = _curveRemoveLiquidity(
            USDC_USDT_POOL,
            mimUsdcUsdtLPsLiquidity[1],
            params.usdcAmountOutMin,
            params.usdtAmountOutMin
        );

        return (
            usdcUsdtLiquidity[0],
            usdcUsdtLiquidity[1],
            mimUsdcUsdtLPsLiquidity[0]
        );
    }

    /**
     * @notice Harvests SPELL tokens from Abracadabra's farm and swaps them for
     *         MIM tokens.
     * @return receivedMim An amount of MIM tokens received after SPELL tokens
     *                     exchange.
     */
    function _harvest(bool toRevertIfFail) private returns (uint256 receivedMim) {
        // Harvest rewards from the Sorbettiere (in SPELL tokens)
        _sorbettiereDeposit(0);

        uint256 spellBalance = IERC20Upgradeable(SPELL).balanceOf(
            address(this)
        );
        (uint256 mimUsdRate, , bool mimUsdFlag) = _getPrice(MIM_USD_ORACLE);
        (uint256 spellUsdRate, , bool spellUsdFlag) = _getPrice(
            SPELL_USD_ORACLE
        );

        if (mimUsdFlag && spellUsdFlag) {
            // Swap Sorbettiere rewards (SPELL tokens) for MIM tokens
            if (spellBalance >= compoundMinAmount) {
                address[] memory path = _toDynamicArray([SPELL, WETH, MIM]);
                uint256 amountOut = _getAmountOut(spellBalance, path);
                uint256 amountOutChainlink = (spellUsdRate * spellBalance) /
                    mimUsdRate;

                bool priceIsCorrect =
                    amountOut >=
                    (amountOutChainlink * (10000 - maxSlippage)) / 10000;

                if (priceIsCorrect) {
                    receivedMim = _swapTokensForTokens(
                        SPELL,
                        MIM,
                        spellBalance,
                        amountOut,
                        path
                    );
                } else if (toRevertIfFail) {
                    revert OnlyValidOutputAmount();
                }
            }
        }
    }

    /**
     * @notice Compounds earned SPELL tokens to earn more rewards.
     * @param amountsOutMin An array with minimum receivable amounts during
     *                      swaps and liquidity addings.
     * @return An amount of newly deposited (compounded) tokens (LPs).
     */
    function _compound(
        uint256[] memory amountsOutMin,
        bool toRevertIfFail
    ) private returns (uint256) {
        // Harvest SPELL tokens and swap them to MIM tokens
        uint256 receivedMim = _harvest(toRevertIfFail);

        if (receivedMim != 0) {
            // Swap one third of MIM tokens for USDC and another third for USDT
            _swapThirdOfMimToUsdcAndThirdToUsdt(
                receivedMim,
                amountsOutMin[0],
                amountsOutMin[1]
            );

            // Reinvest swapped tokens (earned rewards)
            return
                _deposit(
                    InternalDepositParams({
                        usdcAmount: IERC20Upgradeable(USDC).balanceOf(
                            address(this)
                        ),
                        usdtAmount: IERC20Upgradeable(USDT).balanceOf(
                            address(this)
                        ),
                        mimAmount: IERC20Upgradeable(MIM).balanceOf(
                            address(this)
                        ),
                        usdcUsdtLPsAmountOutMin: amountsOutMin[2],
                        mimUsdcUsdtLPsAmountOutMin: amountsOutMin[3]
                    })
                );
        }

        return 0;
    }

    /**
     * @notice Deposits an amount of tokens (LPs) to Abracadabra's farm.
     * @param amount An amount of tokens (LPs) to deposit.
     */
    function _sorbettiereDeposit(uint256 amount) private {
        ICurve(MIM_USDC_USDT_LP_POOL).approve(SORBETTIERE, amount);
        ISorbettiere(SORBETTIERE).deposit(0, amount);
    }

    /**
     * @notice Withdraws an amount of tokens (LPs) from Abracadabra's farm.
     * @param amount An amount of tokens (LPs) to withdraw.
     */
    function _sorbettiereWithdraw(uint256 amount) private {
        ISorbettiere(SORBETTIERE).withdraw(0, amount);
    }

    /**
     * @notice Returns a price of a token in a specified oracle.
     * @param oracle An address of an oracle which will return a price of asset.
     * @return A tuple with a price of token, token decimals and a flag that
     *         indicates if data is actual (fresh) or not.
     */
    function _getPrice(
        AggregatorV2V3Interface oracle
    ) private view returns (uint256, uint8, bool) {
        (
            uint80 roundID,
            int256 answer,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = oracle.latestRoundData();
        bool dataIsActual = answeredInRound >= roundID &&
            answer > 0 &&
            block.timestamp <= updatedAt + STALE_PRICE_DELAY;
        uint8 decimals = oracle.decimals();

        return (uint256(answer), decimals, dataIsActual);
    }

    /**
     * @notice Adds a liquidity in `tokenA` and `tokenB` to a Curve's `pool`.
     * @param pool A Curve's pool address for liquidity adding.
     * @param tokenA An address of token A.
     * @param amountA An amount of token A.
     * @param tokenB An address of token B.
     * @param amountB An amount of token B.
     * @param amountOutMin A minimum receivable LP token amount after a adding
     *                     of liquidity.
     * @return An amount of LP tokens after liquidity adding.
     */
    function _curveAddLiquidity(
        address pool,
        address tokenA,
        uint256 amountA,
        address tokenB,
        uint256 amountB,
        uint256 amountOutMin
    ) private returns (uint256) {
        IERC20(tokenA).approve(pool, amountA);
        IERC20(tokenB).approve(pool, amountB);

        return ICurve(pool).add_liquidity([amountA, amountB], amountOutMin);
    }

    /**
     * @notice Removes an `amount` of liquidity from a Curve's `pool`.
     * @param pool A Curve's pool address for liquidity removing.
     * @param amount An amount of LP tokens to remove from a liquidity pool.
     * @param minAmountOutA A minimum receivable A token amount after a removing
     *                      of liquidity.
     * @param minAmountOutB A minimum receivable B token amount after a removing
     *                      of liquidity.
     * @return An array with token A and token B amounts that were removed from
     *         a Curve's liquidity pool.
     */
    function _curveRemoveLiquidity(
        address pool,
        uint256 amount,
        uint256 minAmountOutA,
        uint256 minAmountOutB
    ) private returns (uint256[2] memory) {
        ICurve(pool).approve(pool, amount);

        return
            ICurve(pool).remove_liquidity(
                amount,
                [minAmountOutA, minAmountOutB]
            );
    }

    /**
     * @notice Swaps 1/3 of MIM tokens for USDC and 1/3 for USDT on SushiSwap
     *         using hardcoded paths (through WETH).
     * @param mimTokensAmount A minimum receivable MIM amount after an exchange.
     * @param usdcAmountOutMin A minimum receivable USDC amount after an
     *                         exchange.
     * @param usdtAmountOutMin A minimum receivable USDT amount after an
     *                         exchange.
     * @return receivedUsdc An amount of output USDC tokens after an exchange.
     * @return receivedUsdt An amount of output USDT tokens after an exchange.
     * @return remainingMim An amount of remaining MIM tokens.
     */
    function _swapThirdOfMimToUsdcAndThirdToUsdt(
        uint256 mimTokensAmount,
        uint256 usdcAmountOutMin,
        uint256 usdtAmountOutMin
    )
        private
        returns (
            uint256 receivedUsdc,
            uint256 receivedUsdt,
            uint256 remainingMim
        )
    {
        uint256 third = mimTokensAmount / 3;

        receivedUsdc = _swapTokensForTokens(
            MIM,
            USDC,
            third,
            usdcAmountOutMin,
            _toDynamicArray([MIM, WETH, USDC])
        );
        receivedUsdt = _swapTokensForTokens(
            MIM,
            USDT,
            third,
            usdtAmountOutMin,
            _toDynamicArray([MIM, WETH, USDT])
        );
        remainingMim = third;
    }

    /**
     * @notice Swaps ETH for `tokenOut` on SushiSwap using provided `path`.
     * @param tokenOut An address of output token.
     * @param amountIn An amount of ETH tokens to exchange.
     * @param amountOutMin A minimum receivable amount after an exchange.
     * @param path A path that will be used for an exchange.
     * @return An amount of output tokens after an exchange.
     */
    function _swapETHForTokens(
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    )
        private
        onlyCorrectPathLength(path)
        onlyCorrectPath(WETH, tokenOut, path)
        returns (uint256)
    {
        uint256[] memory amounts = IUniswapV2Router02(SUSHI_SWAP_ROUTER)
            .swapExactETHForTokens{ value: amountIn }(
            amountOutMin,
            path,
            address(this),
            _getDeadline()
        );

        return amounts[amounts.length - 1];
    }

    /**
     * @notice Swaps `tokenIn` for ETH on SushiSwap using provided `path`.
     * @param tokenIn An address of input token.
     * @param amountIn An amount of tokens to exchange.
     * @param amountOutMin A minimum receivable amount after an exchange.
     * @param path A path that will be used for an exchange.
     * @return An amount of output ETH tokens after an exchange.
     */
    function _swapTokensForETH(
        address tokenIn,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    )
        private
        onlyCorrectPathLength(path)
        onlyCorrectPath(tokenIn, WETH, path)
        returns (uint256)
    {
        IERC20Upgradeable(tokenIn).safeIncreaseAllowance(
            SUSHI_SWAP_ROUTER,
            amountIn
        );

        uint256[] memory amounts = IUniswapV2Router02(SUSHI_SWAP_ROUTER)
            .swapExactTokensForETH(
                amountIn,
                amountOutMin,
                path,
                address(this),
                _getDeadline()
            );

        return amounts[amounts.length - 1];
    }

    /**
     * @notice Swaps `tokenIn` for `tokenOut` on SushiSwap using provided `path`.
     * @param tokenIn An address of input token.
     * @param tokenOut An address of output token.
     * @param amountIn An amount of tokens to exchange.
     * @param amountOutMin A minimum receivable amount after an exchange.
     * @param path A path that will be used for an exchange.
     * @return An amount of output tokens after an exchange.
     */
    function _swapTokensForTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path
    )
        private
        onlyCorrectPathLength(path)
        onlyCorrectPath(tokenIn, tokenOut, path)
        returns (uint256)
    {
        IERC20Upgradeable(tokenIn).safeIncreaseAllowance(
            SUSHI_SWAP_ROUTER,
            amountIn
        );

        uint256[] memory amounts = IUniswapV2Router02(SUSHI_SWAP_ROUTER)
            .swapExactTokensForTokens(
                amountIn,
                amountOutMin,
                path,
                address(this),
                _getDeadline()
            );

        return amounts[amounts.length - 1];
    }

    /**
     * @notice A function that takes a specified fee.
     * @dev This is a private function to deduct fees.
     * @param withdrawalFee The amount of the fee to be taken
     */
    function _takeFee(uint256 withdrawalFee) private {
        if (withdrawalFee > 0) {
            accumulatedFees += withdrawalFee;

            IERC20Upgradeable(MIM_USDC_USDT_LP_POOL).safeTransfer(
                IParallax(PARALLAX).feesReceiver(),
                withdrawalFee
            );
        }
    }

    /**
     * @notice Returns an amount of output tokens after the exchange of
     *         `amountIn` on SushiSwap using provided `path`.
     * @param amountIn An amount of tokens to exchange.
     * @param path A path that will be used for an exchange.
     * @return An amount of output tokens after an exchange of `amountIn` on
     *         SushiSwap using provided `path`.
     */
    function _getAmountOut(
        uint256 amountIn,
        address[] memory path
    ) private view onlyCorrectPathLength(path) returns (uint256) {
        uint256[] memory amounts = IUniswapV2Router02(SUSHI_SWAP_ROUTER)
            .getAmountsOut(amountIn, path);

        return amounts[amounts.length - 1];
    }

    /**
     * @notice Calculates an actual withdraw and withdrawal fee amounts.
     *         Withdrawal fee is charged only from earned tokens (LPs).
     * @param withdrawalAmount An amount of tokens (LPs) to withdraw.
     * @param earnedAmount An amount of earned tokens (LPs) in withdrawal amount.
     * @return actualWithdraw An amount of tokens (LPs) that will be withdrawn
     *                        actually.
     * @return withdrawalFee A fee that will be charged from an earned tokens
     *                       (LPs) amount.
     */
    function _calculateActualWithdrawAndWithdrawalFee(
        uint256 withdrawalAmount,
        uint256 earnedAmount
    ) private view returns (uint256 actualWithdraw, uint256 withdrawalFee) {
        uint256 actualEarned = (earnedAmount *
            (10000 - IParallax(PARALLAX).getFee(address(this)))) / 10000;

        withdrawalFee = earnedAmount - actualEarned;
        actualWithdraw = withdrawalAmount - withdrawalFee;
    }

    /**
     * @notice Returns a deadline timestamp for SushiSwap's exchanges.
     * @return A deadline timestamp for SushiSwap's exchanges
     */
    function _getDeadline() private view returns (uint256) {
        return block.timestamp + EXPIRE_TIME;
    }

    /**
     * @notice Checks if provided token address is whitelisted. Fails otherwise.
     * @param token A token address to check.
     */
    function _onlyWhitelistedToken(address token) private view {
        if (!IParallax(PARALLAX).tokensWhitelist(address(this), token)) {
            revert OnlyWhitelistedToken();
        }
    }

    /**
     * @notice Checks if `msg.sender` is equal to the Parallax contract address.
     *         Fails otherwise.
     */
    function _onlyParallax() private view {
        if (_msgSender() != PARALLAX) {
            revert OnlyParallax();
        }
    }

    /**
     * @notice Checks if path length is greater or equal to 2. Fails otherwise.
     * @param path A path which length to check.
     */
    function _onlyCorrectPathLength(address[] memory path) private pure {
        if (path.length < 2) {
            revert OnlyCorrectPathLength();
        }
    }

    /**
     * @notice Checks array length.
     * @param actualLength An actual length of array.
     * @param expectedlength An expected length of array.
     */
    function _onlyCorrectArrayLength(
        uint256 actualLength,
        uint256 expectedlength
    ) private pure {
        if (actualLength != expectedlength) {
            revert OnlyCorrectArrayLength();
        }
    }

    /**
     * @notice Checks if provided path is proper. Fails otherwise.
     * @dev Proper means that the first element of the `path` is equal to the
     *      `tokenIn` and the last element of the `path` is equal to `tokenOut`.
     * @param tokenIn An address of input token.
     * @param tokenOut An address of output token.
     * @param path A path to check.
     */
    function _onlyCorrectPath(
        address tokenIn,
        address tokenOut,
        address[] memory path
    ) private pure {
        if (tokenIn != path[0] || tokenOut != path[path.length - 1]) {
            revert OnlyCorrectPath();
        }
    }

    /**
     * @notice Converts an array from 3 elements to dynamyc array.
     * @param input An array from 3 elements to convert to dynamic array.
     * @return A newly created dynamic array.
     */
    function _toDynamicArray(
        address[3] memory input
    ) private pure returns (address[] memory) {
        address[] memory output = new address[](3);

        for (uint256 i = 0; i < input.length; ++i) {
            output[i] = input[i];
        }

        return output;
    }
}