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

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
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

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "./CheckerZeroAddr.sol";

abstract contract Timelock is
    Initializable,
    ContextUpgradeable,
    CheckerZeroAddr
{
    struct Transaction {
        address dest;
        uint256 value;
        string signature;
        bytes data;
        uint256 exTime;
    }

    enum ProccessType {
        ADDED,
        REMOVED,
        COMPLETED
    }

    /// @notice This event is emitted wwhen something happens with a transaction.
    /// @param transaction information about transaction
    /// @param proccessType action type
    event ProccessTransaction(
        Transaction transaction,
        ProccessType indexed proccessType
    );

    /// @notice error about that the set time is less than the delay
    error MinDelay();

    /// @notice error about that the transaction does not exist
    error NonExistTransaction();

    /// @notice error about that the minimum interval has not passed
    error ExTimeLessThanNow();

    /// @notice error about that the signature is null
    error NullSignature();

    /// @notice error about that the calling transaction is reverted
    error TransactionExecutionReverted(string revertReason);

    uint256 public constant DELAY = 2 days;

    mapping(bytes32 => bool) public transactions;

    modifier onlyInternalCall() {
        _onlyInternalCall();
        _;
    }

    function _addTransaction(
        Transaction memory transaction
    ) internal onlyNonZeroAddress(transaction.dest) returns (bytes32) {
        if (transaction.exTime < block.timestamp + DELAY) {
            revert MinDelay();
        }

        if (bytes(transaction.signature).length == 0) {
            revert NullSignature();
        }

        bytes32 txHash = _getHash(transaction);

        transactions[txHash] = true;

        emit ProccessTransaction(transaction, ProccessType.ADDED);

        return txHash;
    }

    function _removeTransaction(Transaction memory transaction) internal {
        bytes32 txHash = _getHash(transaction);

        transactions[txHash] = false;

        emit ProccessTransaction(transaction, ProccessType.REMOVED);
    }

    function _executeTransaction(
        Transaction memory transaction
    ) internal returns (bytes memory) {
        bytes32 txHash = _getHash(transaction);

        if (!transactions[txHash]) {
            revert NonExistTransaction();
        }

        if (block.timestamp < transaction.exTime) {
            revert ExTimeLessThanNow();
        }

        transactions[txHash] = false;

        bytes memory callData = abi.encodePacked(
            bytes4(keccak256(bytes(transaction.signature))),
            transaction.data
        );
        (bool success, bytes memory result) = transaction.dest.call{
            value: transaction.value
        }(callData);

        if (!success) {
            revert TransactionExecutionReverted(string(result));
        }

        emit ProccessTransaction(transaction, ProccessType.COMPLETED);

        return result;
    }

    function __Timelock_init_unchained() internal onlyInitializing {}

    function _onlyInternalCall() internal view {
        require(_msgSender() == address(this), "Timelock: only internal call");
    }

    function _getHash(
        Transaction memory transaction
    ) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    transaction.dest,
                    transaction.value,
                    transaction.signature,
                    transaction.data,
                    transaction.exTime
                )
            );
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/// @title IGMXRouter Interface
/// @notice An interface for the GmxRouter smart contract, providing functions
/// for staking, unstaking, compounding, and claiming fees.
interface IGMXRouter {
    /// @notice Stakes the specified amount of GMX tokens.
    /// @param amount The amount of GMX tokens to stake.
    function stakeGmx(uint256 amount) external;

    /// @notice Unstakes the specified amount of GMX tokens.
    /// @param amount The amount of GMX tokens to unstake.
    function unstakeGmx(uint256 amount) external;

    /// @notice Compounds staked GMX tokens.
    function compound() external;

    /// @notice Claims fees from the contract.
    function claimFees() external;

    /// @notice Mints and stakes GLP tokens.
    /// @param _token The address of the token.
    /// @param _amount The amount of tokens to mint and stake.
    /// @param _minUsdg The minimum amount of USDG tokens to receive.
    /// @param _minGlp The minimum amount of GLP tokens to receive.
    /// @return The actual amount of GLP tokens minted and staked.
    function mintAndStakeGlp(
        address _token,
        uint256 _amount,
        uint256 _minUsdg,
        uint256 _minGlp
    ) external returns (uint256);

    /// @notice Unstakes and redeems GLP tokens.
    /// @param _tokenOut The address of the token to receive.
    /// @param _glpAmount The amount of GLP tokens to unstake and redeem.
    /// @param _minOut The minimum amount of tokens to receive.
    /// @param _receiver The address to receive the tokens.
    /// @return The actual amount of tokens received.
    function unstakeAndRedeemGlp(
        address _tokenOut,
        uint256 _glpAmount,
        uint256 _minOut,
        address _receiver
    ) external returns (uint256);

    /// @notice Gets the address of the fee GLP tracker.
    /// @return The address of the fee GLP tracker.
    function feeGlpTracker() external view returns (address);

    /// @notice Gets the address of the fee GMX tracker.
    /// @return The address of the fee GMX tracker.
    function feeGmxTracker() external view returns (address);

    /// @notice Gets the address of the staked GMX tracker.
    /// @return The address of the staked GMX tracker.
    function stakedGmxTracker() external view returns (address);

    /// @notice Gets the address of the GLP manager.
    /// @return The address of the GLP manager.
    function glpManager() external view returns (address);

    /// @notice Gets the address of the GLP token.
    /// @return The address of the GLP token.
    function glp() external view returns (address);

    /// @notice Signals a transfer of ownership.
    /// @param _receiver The address of the new owner.
    function signalTransfer(address _receiver) external;

    /// @notice Accepts the transfer of ownership.
    /// @param _sender The address of the current owner.
    function acceptTransfer(address _sender) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IGMXTracker {
    function claim(address receiver) external;

    function claimable(address user) external view returns (uint256);

    function depositBalances(
        address user,
        address token
    ) external view returns (uint256);

    function stakedAmounts(address user) external view returns (uint256);

    function totalSupply() external view returns (uint256);
}

//SPDX-License-Identifier: MIT

import "../extensions/Timelock.sol";

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

    /**
     * @notice Represents a single user's position in a strategy.
     */
    struct UserPosition {
        uint256 tokenId;
        uint256 shares;
        uint256 deposited;
        uint256 lastStakedBlockNumber;
        uint256 reward;
        uint256 former;
        uint32 lastStakedTimestamp;
        bool created;
        bool closed;
    }

    /**
     * @notice Represents a single user's position in a strategy.
     * @dev holder address can be obtained from contract erc721
     */
    struct TokenInfo {
        uint256 strategyId;
        uint256 positionId;
    }

    /**
     * @param strategyId - an ID of an earning strategy.
     * @param positionId - an ID of a position.
     * @param user - a user who makes a staking.
     * @param amount - amount of staked tokens.
     * @param shares - fraction of the user's contribution
     * (calculated from the deposited amount and the total number of tokens)
     */
    event Staked(
        uint256 indexed strategyId,
        uint256 indexed positionId,
        address user,
        address indexed holder,
        uint256 amount,
        uint256 shares
    );

    /**
     * @param strategyId - an ID of an earning strategy.
     * @param positionId - an ID of a position.
     * @param user - a user who makes a withdrawal.
     * @param amount - amount of staked tokens (calculated from input shares).
     * @param shares - fraction of the user's contribution.
     */
    event Withdrawn(
        uint256 indexed strategyId,
        uint256 indexed positionId,
        address indexed user,
        address receiver,
        uint256 amount,
        uint256 currentFee,
        uint256 shares
    );

    /**
     * @param strategyId - an ID of an earning strategy.
     * @param blockNumber - block number in which the compound was made.
     * @param user - a user who makes compound.
     * @param amount - amount of staked tokens (calculated from input shares).
     */
    event Compounded(
        uint256 indexed strategyId,
        uint256 indexed blockNumber,
        address indexed user,
        uint256 amount
    );

    /**
     * @param positionId - an ID of a position.
     * @param user - a user for whom the position was created.
     * @param blockNumber - block number in which the position was created.
     */
    event PositionCreated(
        uint256 indexed positionId,
        address indexed user,
        uint256 blockNumber
    );

    /**
     * @param from - who sent the position.
     * @param to - recipient.
     * @param tokenId - id of recipient's position.
     */
    event PositionTransferred(
        address indexed from,
        address indexed to,
        uint256 tokenId
    );

    /**
     * @dev Whitelists a new token that can be accepted as the token for
     *      deposits and withdraws. Can only be called by the current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param token An address of a new token to add.
     */
    function addToken(uint256 strategyId, address token) external;

    /**
     * @dev Removes a token from a whitelist of tokens that can be accepted as
     *      the tokens for deposits and withdraws. Can only be called by the
     *      current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param token A token to remove.
     */
    function removeToken(uint256 strategyId, address token) external;

    /**
     * @dev Registers a new earning strategy on this contract. An earning
     *      strategy must be deployed before the calling of this method. Can
     *      only be called by the current owner.
     * @param strategy An address of a new earning strategy that should be added.
     * @param timelock A number of seconds during which users can't withdraw
     *                 their deposits after last deposit. Applies only for
     *                 earning strategy that is adding. Can be updated later.
     * @param cap A cap for the amount of deposited LP tokens.
     * @param rewardPerBlock A reward amount that will be distributed between
     *                       all users in a strategy every block. Can be updated
     *                       later.
     * @param initialFee A fees that will be applied for earning strategy that
     *                    is adding. Currently only withdrawal fee is supported.
     *                    Applies only for earning strategy that is adding. Can
     *                    be updated later. Each fee should contain 2 decimals:
     *                    5 = 0.05%, 10 = 0.1%, 100 = 1%, 1000 = 10%.
     *  @param rewardToken A reward token in which rewards will be paid. Can be
     *                     updated later.
     */
    function addStrategy(
        address strategy,
        uint32 timelock,
        uint256 cap,
        uint256 rewardPerBlock,
        uint256 initialFee,
        IERC20Upgradeable rewardToken,
        bool isActive
    ) external;

    /**
     * @dev Sets a new receiver for fees from all earning strategies. Can only
     *      be called by the current owner.
     * @param newFeesReceiver A wallet that will receive fees from all earning
     *                        strategies.
     */
    function setFeesReceiver(address newFeesReceiver) external;

    /**
     * @dev Sets a new fees for an earning strategy. Can only be called by the
     *      current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param newFee Fee that will be applied for earning strategy. Fee should contain
     *                2 decimals: 5 = 0.05%, 10 = 0.1%, 100 = 1%, 1000 = 10%.
     */
    function setFee(uint256 strategyId, uint256 newFee) external;

    /**
     * @dev Sets a timelock for withdrawals (in seconds). Timelock - period
     *      during which user is not able to make a withdrawal after last
     *      successful deposit. Can only be called by the current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param timelock A new timelock for withdrawals (in seconds).
     */
    function setTimelock(uint256 strategyId, uint32 timelock) external;

    /**
     * @dev Setups a reward amount that will be distributed between all users
     *      in a strategy every block. Can only be called by the current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param newRewardToken A new reward token in which rewards will be paid.
     */
    function setRewardToken(
        uint256 strategyId,
        IERC20Upgradeable newRewardToken
    ) external;

    /**
     * @dev Sets a new cap for the amount of deposited LP tokens. A new cap must
     *      be more or equal to the amount of staked LP tokens. Can only be
     *      called by the current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param cap A new cap for the amount of deposited LP tokens which will be
     *            applied for earning strategy.
     */
    function setCap(uint256 strategyId, uint256 cap) external;

    /**
     * @dev Sets a value for an earning strategy (in reward token) after which
     *      compound must be executed. The compound operation is performed
     *      during every deposit and withdrawal. And sometimes there may not be
     *      enough reward tokens to complete all the exchanges and liquidity
     *      additions. As a result, deposit and withdrawal transactions may
     *      fail. To avoid such a problem, this value is provided. And if the
     *      number of rewards is even less than it, compound does not occur.
     *      As soon as there are more of them, a compound immediately occurs in
     *      time of first deposit or withdrawal. Can only be called by the
     *      current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param compoundMinAmount A value in reward token after which compound
     *                          must be executed.
     */
    function setCompoundMinAmount(
        uint256 strategyId,
        uint256 compoundMinAmount
    ) external;

    /**
     * @notice Setups a reward amount that will be distributed between all users
     *         in a strategy every block. Can only be called by the current
     *         owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param rewardPerBlock A new reward per block.
     */
    function setRewardPerBlock(
        uint256 strategyId,
        uint256 rewardPerBlock
    ) external;

    /**
     * @notice Setups a strategy status. Sets permission or prohibition for
     *         depositing funds on the strategy. Can only be called by the
     *         current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param flag A strategy status. `false` - not active, `true` - active.
     */
    function setStrategyStatus(uint256 strategyId, bool flag) external;

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

    /** @notice Returns the positionInfo
     *   @param strategyId - an ID of an earning strategy.
     *   @param user The address of position holder
     *   @param positionId - id of the position.
     */
    function getPositionInfo(
        uint256 strategyId,
        address user,
        uint256 positionId
    ) external view returns (UserPosition memory);

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

      /**
     * @notice Adds a new transaction to the execution queue. Can only be called
     *         by the current owner.
     * @param transaction structure of:
     *                    dest - the address on which the method will be called;
     *                    value - the value of wei to send;
     *                    signature - method signature;
     *                    data - method call payload;
     *                    exTime - the time from which the transaction can be
     *                             executed. Must be less than the current
     *                             `block.timestamp` + `DELAY`.
     * @return A transaction hash.
     */
    function addTransaction(
        Timelock.Transaction memory transaction
    ) external returns (bytes32);

    /**
     * @notice Removes a transaction from the execution queue. Can only be
     *         called by the current owner.
     * @param transaction structure of:
     *                    dest - the address on which the method will be called;
     *                    value - the value of wei to send;
     *                    signature - method signature;
     *                    data - method call payload;
     *                    exTime - the time from which the transaction can be
     *                             executed. Must be less than the current
     *                             `block.timestamp` + `DELAY`.
     */
    function removeTransaction(
        Timelock.Transaction memory transaction
    ) external;

    /**
     * @notice Executes a transaction from the queue. Can only be called by the
     *         current owner.
     * @param transaction structure of:
     *                    dest - the address on which the method will be called;
     *                    value - the value of wei to send;
     *                    signature - method signature;
     *                    data - method call payload;
     *                    exTime - the time from which the transaction can be
     *                             executed. Must be less than the current
     *                             `block.timestamp` + `DELAY`.
     * @return Returned data.
     */
    function executeTransaction(
        Timelock.Transaction memory transaction
    ) external returns (bytes memory);

    /**
     * @notice Returns an amount of strategy final tokens (LPs) that are staked
     *         under a specified shares amount. Can be called by anyone.
     * @dev Staked == deposited + earned.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param shares An amount of shares for which to calculate a staked
     *               amount of tokens.
     * @return An amount of tokens that are staked under the shares amount.
     */
    function getStakedBySharesAmount(
        uint256 strategyId,
        uint256 shares
    ) external view returns (uint256);

    /**
     * @notice Returns an amount of strategy final (LPs) tokens earned by the
     *         specified shares amount in a specified earning strategy. Can be
     *         called by anyone.
    * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param user A holder of position.
     * @param positionId An ID of a position.
     * @param shares An amount of shares for which to calculate an earned
     *               amount of tokens.
     * @return An amount of earned by shares tokens.
     */
    function getEarnedBySharesAmount(
        uint256 strategyId,
        address user,
        uint256 positionId,
        uint256 shares
    ) external view returns (uint256);

    /**
     * @notice Returns an amount of strategy final tokens (LPs) earned by the
     *         specified user in a specified earning strategy. Can be called by
     *         anyone.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param user A user to check earned tokens amount.
     * @param positionId An ID of a position. Must be an existing position ID.
     * @return An amount of earned by user tokens.
     */
    function getEarnedByUserAmount(
        uint256 strategyId,
        address user,
        uint256 positionId
    ) external view returns (uint256);

    /**
     * @notice Returns claimable by the user amount of reward token in the
     *         position. Can be called by anyone.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param user A user to check earned reward tokens amount.
     * @param positionId An ID of a position. Must be an existing position ID.
     * @return Claimable by the user amount.
     */
    function getClaimableRewards(
        uint256 strategyId,
        address user,
        uint256 positionId
    ) external view returns (uint256);

    /**
     * @dev Withdraws an ETH token that accidentally ended up on an earning
     *      strategy contract and cannot be used in any way. Can only be called
     *      by the current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param amount A number of tokens to withdraw from this contract.
     * @param receiver A wallet that will receive withdrawing tokens.
     */
    function rescueNativeToken(
        uint256 strategyId,
        uint256 amount,
        address receiver
    ) external;

    /**
     * @dev Withdraws an ERC-20 token that accidentally ended up on an earning
     *      strategy contract and cannot be used in any way. Can only be called
     *      by the current owner.
     * @param strategyId An ID of an earning strategy. Must be an existing
     *                   earning strategy ID.
     * @param token A number of tokens to withdraw from this contract.
     * @param amount A number of tokens to withdraw from this contract.
     * @param receiver A wallet that will receive withdrawing tokens.
     */
    function rescueERC20Token(
        uint256 strategyId,
        address token,
        uint256 amount,
        address receiver
    ) external;

    /**
     * @notice Transfer position. Can be called by obly ERC721.
     * @param from A wallet from which token (user position) will be transferred.
     * @param to A wallet to which token (user position) will be transferred.
     * @param tokenId An ID of token to transfer.
     */
    function transferPositionFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
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
     *               holder - holder of position.
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
     *               holder - holder of position.
     *               data - additional data for strategy.
     */
    struct WithdrawParams {
        uint256[] amountsOutMin;
        address[][] paths;
        uint256 positionId;
        uint256 earned;
        uint256 amount;
        address receiver;
        address holder;
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

interface IWethMintable {
    function deposit() external payable;

    function withdraw(uint256 amount) external payable;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV2V3Interface.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/IParallaxStrategy.sol";
import "../interfaces/IParallax.sol";

import "../interfaces/IGMXRouter.sol";
import "../interfaces/IGMXTracker.sol";

import "../interfaces/IWethMintable.sol";
import "../extensions/TokensRescuer.sol";

error OnlyValidSlippage();
error OnlyParallax();
error OnlyCorrectPath();
error OnlyCorrectArrayLength();
error OnlyWhitelistedToken();
error OnlyValidOutputAmount();
error OnlyCorrectPathLength();

/**
 * @title A smart-contract that implements GMX farm earning strategy.
 */
contract GmxStrategyUpgradeable is
    IParallaxStrategy,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    TokensRescuer
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct InitParams {
        address _PARALLAX;
        address _WETH;
        address _GMX;
        address _GMX_TRACKER;
        address _GMX_REWARD_TRACKER;
        address _GMX_ROUTER;
        address _QUOTER;
        address _UNISWAP_V3_ROUTER;
        address _GMX_USD_ORACLE;
        address _WETH_USD_ORACLE;
        uint256 _EXPIRE_TIME;
        uint256 maxSlippage;
        uint256 initialCompoundMinAmount;
    }

    uint8 public constant ADDRESS_SIZE = 20;

    address public constant STRATEGY_AUTHOR = address(0);

    address public PARALLAX;

    address public GMX_ROUTER;
    address public GMX_TRACKER;
    address public GMX_REWARD_TRACKER;

    address public QUOTER;
    address public UNISWAP_V3_ROUTER;

    address public WETH;
    address public GMX;

    AggregatorV2V3Interface public GMX_USD_ORACLE;
    AggregatorV2V3Interface public WETH_USD_ORACLE;

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

    modifier onlyCorrectPathLength(bytes memory path) {
        _onlyCorrectPathLength(path);
        _;
    }

    modifier onlyCorrectPath(
        address tokenIn,
        address tokenOut,
        bytes memory path
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

    /// @inheritdoc IParallaxStrategy
    /// @notice Unsupported function in this strategy
    function claim(
        uint256 strategyId,
        address user,
        uint256 positionId
    ) external onlyParallax {}

    /**
     * @dev Initializes the contract
     * @param initParams Contains the following variables:
     *                   PARALLAX - address of the main contract that controls
     *                              all strategies in the system.
     *                   WETH - address of WETH token.
     *                   GMX - address of GMX token.
     *                   GMX_TRACKER - GMX tracker.
     *                   GMX_REWARD_TRACKER - address of GMX reward tracker.
     *                   GMX_ROUTER - address of the GMX farm staking
     *                                 smart-contract.
     *                   QUOTER - address of uniswap quoter for calculating
     *                           amountOut
     *                   UNISWAP_V3_ROUTER - address of the uniswap v3 router.
     *                   GMX_USD_ORACLE - GMX/USD chainLink oracle address.
     *                   WETH_USD_ORACLE - address of WETH/USD chainLink oracle.
     *                   EXPIRE_TIME - number (in seconds) during which
     *                                 all exchange transactions in this
     *                                 strategy are valid. If time elapsed,
     *                                 exchange and transaction will fail.
     *                   initialCompoundMinAmount - value in reward token
     *                                              after which compound must be
     *                                              executed.
     */
    function __GmxStrategy_init(
        InitParams memory initParams
    ) external initializer {
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __gmxStrategy_init_unchained(initParams);
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
     * @notice Sets a value (in GMX token) after which compound must
     *         be executed.The compound operation is performed during every
     *         deposit and withdrawal. And sometimes there may not be enough
     *         reward tokens to complete all the exchanges and liquidity.
     *         additions. As a result, deposit and withdrawal transactions
     *         may fail. To avoid such a problem, this value is provided.
     *         And if the number of rewards is even less than it, the compound
     *         does not occur. As soon as there are more of them, a compound
     *         immediately occurs in time of first deposit or withdrawal.
     *         Can only be called by the Parallax contact.
     * @param newCompoundMinAmount A value in GMX token after which compound
     *                             must be executed.
     */
    function setCompoundMinAmount(
        uint256 newCompoundMinAmount
    ) external onlyParallax {
        compoundMinAmount = newCompoundMinAmount;
    }

    /**
     * @notice deposits GMX tokens into the GMX staking.
     *         GMX tokens that are depositing must be approved to this contract.
     *         Executes compound before depositing.
     *         Can only be called by the Parallax contact.
     * @param params parameters for deposit.
     *               amount - amount of LP tokens for deposit
     *                holder - holder of position.
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
            IERC20Upgradeable(GMX).safeTransferFrom(
                params.user,
                address(this),
                params.amounts[0]
            );

            // Deposit (stake) GMX tokens in the GMX farm staking pool
            _deposit(params.amounts[0]);
        }

        return params.amounts[0];
    }

    /// @inheritdoc IParallaxStrategy
    function depositTokens(
        DepositParams memory
    ) external view onlyParallax returns (uint256) {
        revert();
    }

    /**
     * @notice accepts ETH token. Swaps it for GMX tokens
     *      Deposits GMX into the GMX staking smart-contract.
     *      Executes compound before depositing.
     *      Can only be called by the Parallax contact.
     * @param params parameters for deposit.
     *               amountsOutMin -  an array of minimum values
     *                 that will be received during exchanges,
     *                 withdrawals or deposits of liquidity, etc.
     *                 All values can be 0 that means
     *                 that you agreed with any output value.
     *                 For this strategy and this method
     *                 it must contain 1 elements:
     *                 0 - minimum amount of output GMX tokens
     *                  during swap of ETH tokens to GMX tokens on Uniswap v3.
     *               data - additional data for strategy.
     *                 For this strategy and this method
     *                 it must contain 1 elements:
     *                 0 - route for swap of ETH tokens to GMX tokens
     *                 (e.g.: [WETH, GMX], or [WETH, USDC, GMX]).
     *                 The first element must be WETH, the last one GMX.
     *                holder - holder of position.
     *                user - address of the user
     *                 to whose account the deposit will be made
     *                positionId - id of the position.
     * @return amount of deposited tokens
     */
    function depositAndSwapNativeToken(
        DepositParams memory params
    ) external payable nonReentrant onlyParallax returns (uint256) {
        _onlyCorrectArrayLength(params.data.length, 1);
        _onlyCorrectArrayLength(params.amountsOutMin.length, 1);

        if (msg.value > 0) {
            IWethMintable(WETH).deposit{ value: msg.value }();

            uint256 receivedGmx = _swapTokensForTokens(
                WETH,
                GMX,
                msg.value,
                params.amountsOutMin[0],
                params.data[0]
            );

            // Deposit
            _deposit(receivedGmx);

            return receivedGmx;
        }

        return 0;
    }

    /**
     * @notice accepts ERC20 token. Swaps it for GMX tokens
     *      Deposits GMX tokens into the GMX staking smart-contract.
     *      Executes compound before depositing.
     *      Can only be called by the Parallax contact.
     * @param params parameters for deposit.
     *               amount - amount of erc20 tokens for swap and deposit
     *               amountsOutMin -  an array of minimum values
     *                 that will be received during exchanges,
     *                 withdrawals or deposits of liquidity, etc.
     *                 All values can be 0 that means
     *                 that you agreed with any output value.
     *                 For this strategy and this method
     *                 it must contain 5 elements:
     *                 0 - minimum amount of output USDC tokens
     *                 during swap of ERC20 tokens to USDC tokens on Uniswap v3.
     *               user - address of the user
     *                 to whose account the deposit will be made
     *               holder - holder of position.
     *               positionId - id of the position.
     *               data - additional data for strategy.
     *                 For this strategy and this method
     *                 it must contain 1 elements:
     *                 0 - address of the ERC20 token.
     *                 1 - route for swap of ERC20 tokens to GMX tokens
     *                 (e.g.: [TOKEN, GMX], or [TOKEN, WETH, GMX]).
     * @return amount of deposited tokens
     */
    function depositAndSwapERC20Token(
        DepositParams memory params
    ) external nonReentrant onlyParallax returns (uint256) {
        _onlyCorrectArrayLength(params.data.length, 2);
        _onlyCorrectArrayLength(params.amountsOutMin.length, 1);

        address token = address(uint160(bytes20(params.data[0])));

        _onlyWhitelistedToken(token);

        if (params.amounts[0] > 0) {
            // Transfer whitelisted ERC20 tokens from a user to this contract
            IERC20Upgradeable(token).safeTransferFrom(
                params.user,
                address(this),
                params.amounts[0]
            );

            uint256 receivedGmx;
            if (token == GMX) {
                receivedGmx = params.amounts[0];
            } else {
                receivedGmx = _swapTokensForTokens(
                    token,
                    GMX,
                    params.amounts[0],
                    params.amountsOutMin[0],
                    params.data[1]
                );
            }

            //Deposit
            _deposit(receivedGmx);

            return receivedGmx;
        }

        return 0;
    }

    /**
     * @notice withdraws needed amount of staked GMX tokens
     *      from the GMX staking smart-contract.
     *      Sends to the user his GMX tokens
     *      and withdrawal fees to the fees receiver.
     *      Executes compound before withdrawing.
     *      Can only be called by the Parallax contact.
     *  @param params parameters for deposit.
     *                amount - amount of LP tokens to withdraw
     *                receiver - adress of recipient
     *                  to whom the assets will be sent
     *                holder - holder of position.
     *                earned - lp tokens earned in proportion to the amount of
     *                  withdrawal
     *                positionId - id of the position.
     *                data - additional data for strategy.
     */
    function withdrawLPs(
        WithdrawParams memory params
    ) external nonReentrant onlyParallax {
        if (params.amount > 0) {
            // Calculate withdrawal fee and actual witdraw
            (
                uint256 actualWithdraw,
                uint256 withdrawalFee
            ) = _calculateActualWithdrawAndWithdrawalFee(
                    params.amount,
                    params.earned
                );

            _withdraw(params.amount);

            // Send tokens to the receiver and withdrawal fee to the fees
            // receiver
            IERC20Upgradeable(GMX).safeTransfer(
                params.receiver,
                actualWithdraw
            );

            if (withdrawalFee > 0) {
                IERC20Upgradeable(GMX).safeTransfer(
                    IParallax(PARALLAX).feesReceiver(),
                    withdrawalFee
                );
            }
        }
    }

    /**
     * @notice withdraws needed amount of staked GMX tokens
     *      from the GMX staking smart-contract.
     *      Sends to the user his GMX tokens
     *      and withdrawal fees to the fees receiver.
     *      Executes compound before withdrawing.
     *      Can only be called by the Parallax contact.
     * @param params parameters for deposit.
     *               amount - amount of LP tokens to withdraw
     *               receiver - adress of recipient
     *                 to whom the assets will be sent
     *               holder - holder of position.
     *               earned - GMX tokens earned in proportion to the amount of
     *                 withdrawal
     *               positionId - id of the position.
     *               data - additional data for strategy.
     */
    function withdrawTokens(
        WithdrawParams memory params
    ) external nonReentrant onlyParallax {
        if (params.amount > 0) {
            // Calculate withdrawal fee and actual witdraw
            (
                uint256 actualWithdraw,
                uint256 withdrawalFee
            ) = _calculateActualWithdrawAndWithdrawalFee(
                    params.amount,
                    params.earned
                );

            _withdraw(params.amount);

            // Send tokens to the receiver and withdrawal fee to the fees
            // receiver
            IERC20Upgradeable(GMX).safeTransfer(
                params.receiver,
                actualWithdraw
            );

            _takeFee(withdrawalFee);
        }
    }

    /**
     * @notice withdraws needed amount of staked GMX tokens
     *      from the GMX staking smart-contract.
     *      Exchanges all received GMX tokens for ETH token.
     *      Sends to the user his token and withdrawal fees to the fees receiver
     *      Executes compound before withdrawing.
     *      Can only be called by the Parallax contact.
     * @param params parameters for deposit.
     *               amount - amount of GMX tokens to withdraw
     *               receiver - adress of recipient
     *                 to whom the assets will be sent
     *               holder - holder of position.
     *               amountsOutMin - an array of minimum values
     *                 that will be received during exchanges,
     *                 withdrawals or deposits of liquidity, etc.
     *                 All values can be 0 that means
     *                 that you agreed with any output value.
     *                 For this strategy and this method
     *                 it must contain 1 elements:
     *                 0 - minimum amount of output ETH tokens during
     *                 swap of GMX tokens to ETH tokens on Uniswap v3.
     *               earned - GMX tokens earned in proportion to the amount of
     *                 withdrawal
     *               positionId - id of the position.
     *               data - additional data for strategy.
     *                 For this strategy and this method
     *                 it must contain 1 elements:
     *                 0 - route for swap of GMX tokens to ETH tokens
     *                 (e.g.: [GMX, WETH], or [GMX, USDC, WETH]).
     */
    function withdrawAndSwapForNativeToken(
        WithdrawParams memory params
    ) external nonReentrant onlyParallax {
        _onlyCorrectArrayLength(params.data.length, 1);
        _onlyCorrectArrayLength(params.amountsOutMin.length, 1);

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
            _withdraw(params.amount);

            uint256 receivedEth = _swapTokensForTokens(
                GMX,
                WETH,
                actualWithdraw,
                params.amountsOutMin[0],
                params.data[0]
            );

            IWethMintable(WETH).withdraw(receivedEth);

            // Send tokens to the receiver and withdrawal fee to the fees
            // receiver
            AddressUpgradeable.sendValue(payable(params.receiver), receivedEth);

            _takeFee(withdrawalFee);
        }
    }

    /**
     * @notice withdraws needed amount of staked GMX tokens
     *      from the GMX staking smart-contract.
     *      Exchanges all received GMX tokens for ERC20 token.
     *      Sends to the user his token and withdrawal fees to the fees receiver
     *      Executes compound before withdrawing.
     *      Can only be called by the Parallax contact.
     * @param params parameters for deposit.
     *               amount - amount of GMX tokens to withdraw
     *               receiver - adress of recipient
     *                 to whom the assets will be sent
     *               holder - holder of position.
     *               amountsOutMin - an array of minimum values
     *                 that will be received during exchanges,
     *                 withdrawals or deposits of liquidity, etc.
     *                 All values can be 0 that means
     *                 that you agreed with any output value.
     *                 For this strategy and this method
     *                 it must contain 1 elements:
     *                 0 - minimum amount of output ERC20 tokens tokens during
     *                 swap of GMX tokens to ERC20 tokens on Uniswap v3.
     *               earned - GMX tokens earned in proportion to the amount of
     *                 withdrawal
     *               positionId - id of the position.
     *               data - additional data for strategy.
     *                 For this strategy and this method
     *                 it must contain 1 elements:
     *                 0 - route for swap of GMX tokens to ERC20 tokens
     *                 (e.g.: [GMX, ERC20], or [GMX, USDC, ERC20]).
     */
    function withdrawAndSwapForERC20Token(
        WithdrawParams memory params
    ) external nonReentrant onlyParallax {
        _onlyCorrectArrayLength(params.data.length, 2);
        _onlyCorrectArrayLength(params.amountsOutMin.length, 1);

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
            _withdraw(params.amount);

            // Swap GMX tokens for ERC20 tokens
            uint256 receivedERC20;

            if (token == GMX) {
                receivedERC20 += actualWithdraw;
            } else {
                receivedERC20 += _swapTokensForTokens(
                    GMX,
                    token,
                    actualWithdraw,
                    params.amountsOutMin[0],
                    params.data[1]
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

    /// @inheritdoc IParallaxStrategy
    function compound(
        uint256[] memory amountsOutMin,
        bool toRevertIfFail
    ) external nonReentrant onlyParallax returns (uint256) {
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

    /**
     * @notice Unchained initializer for this contract.
     * @param initParams An initial parameters.
     */
    function __gmxStrategy_init_unchained(
        InitParams memory initParams
    ) internal onlyInitializing {
        PARALLAX = initParams._PARALLAX;
        WETH = initParams._WETH;
        GMX = initParams._GMX;
        GMX_TRACKER = initParams._GMX_TRACKER;
        GMX_REWARD_TRACKER = initParams._GMX_REWARD_TRACKER;
        GMX_ROUTER = initParams._GMX_ROUTER;
        QUOTER = initParams._QUOTER;
        UNISWAP_V3_ROUTER = initParams._UNISWAP_V3_ROUTER;
        GMX_USD_ORACLE = AggregatorV2V3Interface(initParams._GMX_USD_ORACLE);
        WETH_USD_ORACLE = AggregatorV2V3Interface(initParams._WETH_USD_ORACLE);
        EXPIRE_TIME = initParams._EXPIRE_TIME;
        maxSlippage = initParams.maxSlippage;
        compoundMinAmount = initParams.initialCompoundMinAmount;
    }

    /**
     * @notice Deposits GMX tokens (LPs) into GMX's farm.
     * @param amount A deposit parameters.
     */
    function _deposit(uint256 amount) private {
        IERC20Upgradeable(GMX).approve(GMX_TRACKER, amount);
        IGMXRouter(GMX_ROUTER).stakeGmx(amount);
    }

    /**
     * @notice Withdraws tokens (LPs) from GMX's farm
     * @param amount A withdrawal parameters.
     */
    function _withdraw(uint256 amount) private {
        // Withdraw (unstake) GMX's tokens from the GMX's staking pool
        IGMXRouter(GMX_ROUTER).unstakeGmx(amount);
    }

    /**
     * @notice Harvests WETH tokens from GMX staking
     * @return receivedGmx An amount of GMX tokens received after WETH tokens
     *                     exchange.
     */
    function _harvest(
        bool toRevertIfFail
    ) private returns (uint256 receivedGmx) {
        //Harvest rewards from the Sorbettiere (in WETH tokens)
        IGMXTracker(GMX_REWARD_TRACKER).claim(address(this));

        uint256 wethBalance = IERC20Upgradeable(WETH).balanceOf(address(this));

        (uint256 wethUsdRate, , bool wethUsdFlag) = _getPrice(WETH_USD_ORACLE);
        (uint256 gmxUsdRate, , bool gmxUsdFlag) = _getPrice(GMX_USD_ORACLE);

        if (wethUsdFlag && gmxUsdFlag) {
            // Swap WETH rewards for GMX tokens
            if (wethBalance >= compoundMinAmount) {
                bytes memory path = abi.encodePacked(WETH, uint24(10000), GMX);
                uint256 amountOut = _getAmountOut(wethBalance, path);

                uint256 amountOutChainlink = (gmxUsdRate * wethBalance) /
                    wethUsdRate;

                bool priceIsCorrect = amountOut >=
                    (amountOutChainlink * (10000 - maxSlippage)) / 10000;

                if (priceIsCorrect) {
                    receivedGmx = _swapTokensForTokens(
                        WETH,
                        GMX,
                        wethBalance,
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
     * @notice Compounds earned GMX tokens to earn more rewards.
     * @return An amount of newly deposited (compounded) tokens (LPs).
     */
    function _compound(
        uint256[] memory,
        bool toRevertIfFail
    ) private returns (uint256) {
        // Harvest WETH tokens and swap them to GMX tokens
        _harvest(toRevertIfFail);

        IGMXRouter(GMX_ROUTER).compound();

        uint256 balanceGmx = IERC20Upgradeable(GMX).balanceOf(address(this));

        if (balanceGmx != 0) {
            // Reinvest swapped tokens (earned rewards)
            _deposit(balanceGmx);

            return balanceGmx;
        }

        return 0;
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
     * @notice Swaps `tokenIn` for `tokenOut` on GMXSwap using provided `path`.
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
        bytes memory path
    )
        private
        onlyCorrectPathLength(path)
        onlyCorrectPath(tokenIn, tokenOut, path)
        returns (uint256)
    {
        IERC20Upgradeable(tokenIn).safeIncreaseAllowance(
            UNISWAP_V3_ROUTER,
            amountIn
        );

        ISwapRouter.ExactInputParams memory params = ISwapRouter
            .ExactInputParams(
                path,
                address(this),
                _getDeadline(),
                amountIn,
                amountOutMin
            );

        uint256 amountOut = ISwapRouter(UNISWAP_V3_ROUTER).exactInput(params);

        return amountOut;
    }

    /**
     * @notice This function extracts a specific slice of the given byte array
     *         as an address.
     * @param input The byte array from which to extract the address.
     * @param start The starting index in the byte array to begin the extraction.
     * @return token The extracted address from the input bytes.
     */
    function _sliceAddress(
        bytes memory input,
        uint256 start
    ) public pure returns (address token) {
        bytes memory addressBytes = new bytes(ADDRESS_SIZE);

        assembly {
            let src := add(add(input, 32), start)
            let dst := add(addressBytes, 32)
            mstore(dst, mload(src))

            token := mload(add(addressBytes, ADDRESS_SIZE))
        }
    }

    /**
     * @notice A function that takes a specified fee.
     * @dev This is a private function to deduct fees.
     * @param withdrawalFee The amount of the fee to be taken
     */
    function _takeFee(uint256 withdrawalFee) private {
        if (withdrawalFee > 0) {
            accumulatedFees += withdrawalFee;

            IERC20Upgradeable(GMX).safeTransfer(
                IParallax(PARALLAX).feesReceiver(),
                withdrawalFee
            );
        }
    }

    /**
     * @notice Returns an amount of output tokens after the exchange of
     *         `amountIn` on GMXSwap using provided `path`.
     * @param amountIn An amount of tokens to exchange.
     * @param path A path that will be used for an exchange.
     * @return An amount of output tokens after an exchange of `amountIn` on
     *         GMXSwap using provided `path`.
     */
    function _getAmountOut(
        uint256 amountIn,
        bytes memory path
    ) private onlyCorrectPathLength(path) returns (uint256) {
        return IQuoter(QUOTER).quoteExactInput(path, amountIn);
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
     * @notice Returns a deadline timestamp for GMXSwap's exchanges.
     * @return A deadline timestamp for GMXSwap's exchanges
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
    function _onlyCorrectPathLength(bytes memory path) private pure {
        // 2*ADDRESS_SIZE + FEE_SIZE
        if (path.length < 43) {
            revert OnlyCorrectPathLength();
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
        bytes memory path
    ) private pure {
        address tokenA = _sliceAddress(path, 0);
        address tokenB = _sliceAddress(path, path.length - ADDRESS_SIZE);

        if (tokenIn != tokenA || tokenOut != tokenB) {
            revert OnlyCorrectPath();
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
}