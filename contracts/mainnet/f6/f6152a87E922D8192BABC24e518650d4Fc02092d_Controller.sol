// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6 <0.9.0;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';

/// @title Uniswap V3 Static Oracle
/// @notice Oracle contract for calculating price quoting against Uniswap V3
interface IStaticOracle {
  /// @notice Returns the address of the Uniswap V3 factory
  /// @dev This value is assigned during deployment and cannot be changed
  /// @return The address of the Uniswap V3 factory
  function UNISWAP_V3_FACTORY() external view returns (IUniswapV3Factory);

  /// @notice Returns how many observations are needed per minute in Uniswap V3 oracles, on the deployed chain
  /// @dev This value is assigned during deployment and cannot be changed
  /// @return Number of observation that are needed per minute
  function CARDINALITY_PER_MINUTE() external view returns (uint8);

  /// @notice Returns all supported fee tiers
  /// @return The supported fee tiers
  function supportedFeeTiers() external view returns (uint24[] memory);

  /// @notice Returns whether a specific pair can be supported by the oracle
  /// @dev The pair can be provided in tokenA/tokenB or tokenB/tokenA order
  /// @return Whether the given pair can be supported by the oracle
  function isPairSupported(address tokenA, address tokenB) external view returns (bool);

  /// @notice Returns all existing pools for the given pair
  /// @dev The pair can be provided in tokenA/tokenB or tokenB/tokenA order
  /// @return All existing pools for the given pair
  function getAllPoolsForPair(address tokenA, address tokenB) external view returns (address[] memory);

  /// @notice Returns a quote, based on the given tokens and amount, by querying all of the pair's pools
  /// @dev If some pools are not configured correctly for the given period, then they will be ignored
  /// @dev Will revert if there are no pools available/configured for the pair and period combination
  /// @param baseAmount Amount of token to be converted
  /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
  /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
  /// @param period Number of seconds from which to calculate the TWAP
  /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
  /// @return queriedPools The pools that were queried to calculate the quote
  function quoteAllAvailablePoolsWithTimePeriod(
    uint128 baseAmount,
    address baseToken,
    address quoteToken,
    uint32 period
  ) external view returns (uint256 quoteAmount, address[] memory queriedPools);

  /// @notice Returns a quote, based on the given tokens and amount, by querying only the specified fee tiers
  /// @dev Will revert if the pair does not have a pool for one of the given fee tiers, or if one of the pools
  /// is not prepared/configured correctly for the given period
  /// @param baseAmount Amount of token to be converted
  /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
  /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
  /// @param feeTiers The fee tiers to consider when calculating the quote
  /// @param period Number of seconds from which to calculate the TWAP
  /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
  /// @return queriedPools The pools that were queried to calculate the quote
  function quoteSpecificFeeTiersWithTimePeriod(
    uint128 baseAmount,
    address baseToken,
    address quoteToken,
    uint24[] calldata feeTiers,
    uint32 period
  ) external view returns (uint256 quoteAmount, address[] memory queriedPools);

  /// @notice Returns a quote, based on the given tokens and amount, by querying only the specified pools
  /// @dev Will revert if one of the pools is not prepared/configured correctly for the given period
  /// @param baseAmount Amount of token to be converted
  /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
  /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
  /// @param pools The pools to consider when calculating the quote
  /// @param period Number of seconds from which to calculate the TWAP
  /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
  function quoteSpecificPoolsWithTimePeriod(
    uint128 baseAmount,
    address baseToken,
    address quoteToken,
    address[] calldata pools,
    uint32 period
  ) external view returns (uint256 quoteAmount);

  /// @notice Will initialize all existing pools for the given pair, so that they can be queried with the given period in the future
  /// @dev Will revert if there are no pools available for the pair and period combination
  /// @param tokenA One of the pair's tokens
  /// @param tokenB The other of the pair's tokens
  /// @param period The period that will be guaranteed when quoting
  /// @return preparedPools The pools that were prepared
  function prepareAllAvailablePoolsWithTimePeriod(
    address tokenA,
    address tokenB,
    uint32 period
  ) external returns (address[] memory preparedPools);

  /// @notice Will initialize the pair's pools with the specified fee tiers, so that they can be queried with the given period in the future
  /// @dev Will revert if the pair does not have a pool for a given fee tier
  /// @param tokenA One of the pair's tokens
  /// @param tokenB The other of the pair's tokens
  /// @param feeTiers The fee tiers to consider when searching for the pair's pools
  /// @param period The period that will be guaranteed when quoting
  /// @return preparedPools The pools that were prepared
  function prepareSpecificFeeTiersWithTimePeriod(
    address tokenA,
    address tokenB,
    uint24[] calldata feeTiers,
    uint32 period
  ) external returns (address[] memory preparedPools);

  /// @notice Will initialize all given pools, so that they can be queried with the given period in the future
  /// @param pools The pools to initialize
  /// @param period The period that will be guaranteed when quoting
  function prepareSpecificPoolsWithTimePeriod(address[] calldata pools, uint32 period) external;

  /// @notice Will increase observations for all existing pools for the given pair, so they start accruing information for twap calculations
  /// @dev Will revert if there are no pools available for the pair and period combination
  /// @param tokenA One of the pair's tokens
  /// @param tokenB The other of the pair's tokens
  /// @param cardinality The cardinality that will be guaranteed when quoting
  /// @return preparedPools The pools that were prepared
  function prepareAllAvailablePoolsWithCardinality(
    address tokenA,
    address tokenB,
    uint16 cardinality
  ) external returns (address[] memory preparedPools);

  /// @notice Will increase the pair's pools with the specified fee tiers observations, so they start accruing information for twap calculations
  /// @dev Will revert if the pair does not have a pool for a given fee tier
  /// @param tokenA One of the pair's tokens
  /// @param tokenB The other of the pair's tokens
  /// @param feeTiers The fee tiers to consider when searching for the pair's pools
  /// @param cardinality The cardinality that will be guaranteed when quoting
  /// @return preparedPools The pools that were prepared
  function prepareSpecificFeeTiersWithCardinality(
    address tokenA,
    address tokenB,
    uint24[] calldata feeTiers,
    uint16 cardinality
  ) external returns (address[] memory preparedPools);

  /// @notice Will increase all given pools observations, so they start accruing information for twap calculations
  /// @param pools The pools to initialize
  /// @param cardinality The cardinality that will be guaranteed when quoting
  function prepareSpecificPoolsWithCardinality(address[] calldata pools, uint16 cardinality) external;

  /// @notice Adds support for a new fee tier
  /// @dev Will revert if the given tier is invalid, or already supported
  /// @param feeTier The new fee tier to add
  function addNewFeeTier(uint24 feeTier) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: BSL-1.1

// Copyright (c)
// All rights reserved.

// This software is released under the Business Source License 1.1.
// For full license terms, see the LICENSE file.

/*
    This file is part of the ADD3 Protocol.
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/


pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IController.sol";
import "../vault/IVault.sol";
import "../vault/Vault.sol";
import "../../extensions/implementations/StakingBase.sol";
import "../../core/utils/ERC712Custom.sol";
import "../../core/utils/ModifierCustom.sol";
import "../../libraries/ExtraLib.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";


import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "../../extensions/fee-manager/FeeManager.sol";
import { IERC20 as IERC20v2 } from "@uniswap/v2-core/contracts/interfaces/IERC20.sol";
import "@mean-finance/uniswap-v3-oracle/solidity/interfaces/IStaticOracle.sol";

/// @title Controller Contract
/// @author Augusto Francesco D'Intino - [email protected]
contract Controller is
    ERC712Custom,
    IController,
    ReentrancyGuard,
    ModifierCustom
{
    //address check for all inputs
    using Address for address;

    // the system ensures totalRewardsAllProducts and availableReward change
    // simultaneously wrt vaultBalance

    mapping(address => Product) public products;

    address private immutable vaultAddress;
    address private immutable rewardToken;
    address public immutable feeManager;
    address private immutable WETH;
    address private immutable USD;
    address public immutable Oracle;
    address[] public WETHUSDpools;


    uint256 public totalRewardsAllProducts;

    event Strategy_Already_Registered();
    event Refund(address indexed sender, uint256 amount);

    error Error_Cannot_Interact_While_Product_Working();
    error Error_Invalid_Oracle_Address();
    error Error_Denied_Decrement_More_Than_Ninety_Percent();
    error Error_No_Fee_Sent_To_Add3();
    error Error_No_Fee_Value();
    error Error_Invalid_USD_address();
    error Error_Invalid_WETH();
    error Error_Not_Owner();
    error Error_Not_Owner_Or_Active_Product();
    error Error_Not_Active_Product();
    error Error_Not_Operator_Or_Owner();
    error Error_Invalid_Vault_Address();
    error Error_Invalid_PrivilegedAddressRegistry_Address();
    error Error_Invalid_Registration_Reward_Amount();
    error Error_Invalid_Product_Address();
    error Error_Invalid_Decrement_Reward();
    error Error_Product_Balance_Not_Zero();
    error Error_Can_Directly_Extract_Only_Rewards_Not_Pledged_As_Supply();
    error Error_Not_Refunded();
    error Error_Invalid_Pair();
    error Error_Invalid_Reward_Token();
    error Error_Mismatch_Pair_Tokens();
    error Error_No_Quote_From_Oracle();

    constructor(
        address _rewardToken,
        address _privilegedAddressRegistryAddress,
        address _oracle,
        address _WETH,
        address _USD,
        address _WETHUSDpool
    ) EIP712("Controller Contract", "6") {
        if (!_rewardToken.isContract()) {
            revert Error_Invalid_Reward_Token();
        }
        rewardToken = _rewardToken;

        if (!_privilegedAddressRegistryAddress.isContract()) {
            revert Error_Invalid_PrivilegedAddressRegistry_Address();
        }
        privilegedAddressObj = IPrivilegedAddressRegistry(
            _privilegedAddressRegistryAddress
        );
        
        vaultAddress = address(new Vault(rewardToken));
        if (!vaultAddress.isContract()) {
            revert Error_Invalid_Vault_Address();
        } 

        feeManager = address(new FeeManager());

        if (!_oracle.isContract()) {
            revert Error_Invalid_Oracle_Address();
        }
        Oracle = _oracle;

        if (!_WETH.isContract()) {
            revert Error_Invalid_WETH();
        }
        WETH = _WETH;

        if (!_USD.isContract()) {
            revert Error_Invalid_USD_address();
        }
        USD = _USD;


        if (!IStaticOracle(Oracle).isPairSupported(USD, WETH) || !_WETHUSDpool.isContract()){
            revert Error_Invalid_Pair();
        }

        address token0 = IUniswapV3Pool(_WETHUSDpool).token0();
        address token1 = IUniswapV3Pool(_WETHUSDpool).token1();

        if ((token0 == WETH && token1 == USD) || (token0 == USD && token1 == WETH) ){
            WETHUSDpools = new address[](1); 
            WETHUSDpools[0] = _WETHUSDpool;    
        } else { revert Error_Mismatch_Pair_Tokens(); }

    }

    modifier onlyClientOrActive() {
        if (
            msg.sender != privilegedAddressObj.getPrivilegedAddress() &&
            !products[msg.sender].active
        ) {
            revert Error_Not_Owner_Or_Active_Product();
        }
        _;
    }

    modifier onlyActiveProduct() {
        if ( !products[msg.sender].active) {
            revert Error_Not_Active_Product();
        }
        _;
    }

    modifier onlySelectedIsActiveProduct(address productAddress) {
        if ( !products[productAddress].active) {
            revert Error_Not_Active_Product();
        }
        _;
    }

    modifier onlyOperatorOrOwner(address productAddress) {
        if (msg.sender != products[productAddress].operator && msg.sender != privilegedAddressObj.getPrivilegedAddress()) {
            revert Error_Not_Operator_Or_Owner();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                EIP 712
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant _TYPEHASH_SET_OPERATOR =
        keccak256(
            "SetOperator(address _operator,address productAddress,address _owner,uint256 nonce,uint256 deadline)"
        );

    modifier onlyAuthorizedSetOperator(
        address _operator,
        address productAddress,
        uint256 deadline, 
        bytes32 _typehash, 
        bytes memory signature){
            processSignatureVerification(
            abi.encode(
                _typehash,
                _operator,
                productAddress,
                privilegedAddressObj.getPrivilegedAddress(),
                nonces[privilegedAddressObj.getPrivilegedAddress()],
                deadline
            ),
            signature,
            deadline,
            privilegedAddressObj.getPrivilegedAddress()
        );
        _;
        }

    bytes32 public constant _REGISTER_PRODUCT_TYPEHASH =
        keccak256(
            "RegisterProduct(address productAddress,address pool,uint256 rewardAmount,FeeStrategy feeStrategy,address _owner,uint256 nonce,uint256 deadline)FeeStrategy(uint256 add3TxFeeBps,uint256 adminFeeBps,uint256 add3FeeBps,address admin,address add3)"
        );

    modifier onlyAuthorizedRegisterProduct(
        address productAddress,
        address pool,
        uint256 rewardAmount,
        FeeManager.FeeStrategy memory newStrategy,
        uint256 deadline,
        bytes32 _typehash,
        bytes32 _secondary_typehash,
        bytes memory signature
    ) {
        processSignatureVerification(
            abi.encode(
                _typehash,
                productAddress,
                pool,
                rewardAmount,
                keccak256(abi.encode(_secondary_typehash,newStrategy.add3TxFeeBps,newStrategy.adminFeeBps,newStrategy.add3FeeBps,newStrategy.admin,newStrategy.add3)),
                privilegedAddressObj.getPrivilegedAddress(),
                nonces[privilegedAddressObj.getPrivilegedAddress()],
                deadline
            ),
            signature,
            deadline,
            privilegedAddressObj.getPrivilegedAddress()
        );
        _;
    }

    bytes32 public constant _SET_REMOVE_PRODUCT_TYPEHASH =
        keccak256(
            "RemoveProduct(address productAddress,address _owner,uint256 nonce,uint256 deadline)"
        );

    modifier onlyAuthorizedRemoveProduct(
        address productAddress,
        uint256 deadline,
        bytes32 _typehash,
        bytes memory signature
    ) {
        processSignatureVerification(
            abi.encode(
                _typehash,
                productAddress,
                privilegedAddressObj.getPrivilegedAddress(),
                nonces[privilegedAddressObj.getPrivilegedAddress()],
                deadline
            ),
            signature,
            deadline,
            privilegedAddressObj.getPrivilegedAddress()
        );
        _;
    }

    bytes32 public constant _EXTRACT_FROM_VAULT_TYPEHASH =
        keccak256(
            "ExtractFromVault(uint256 extractedAmount,address _owner,uint256 nonce,uint256 deadline)"
        );

    modifier onlyAuthorizedExtractFromVault(
        uint256 extractedAmount,
        uint256 deadline,
        bytes32 _typehash,
        bytes memory signature
    ) {
            processSignatureVerification(
                abi.encode(
                    _typehash,
                    extractedAmount,
                    privilegedAddressObj.getPrivilegedAddress(),
                    nonces[privilegedAddressObj.getPrivilegedAddress()],
                    deadline
                ),
                signature,
                deadline,
                privilegedAddressObj.getPrivilegedAddress()
            );
        _;
    }

    bytes32 public constant _TOP_UP_VAULT_TYPEHASH =
        keccak256(
            "TopUpVault(address incrementer,uint256 incrementAmount,address _owner,uint256 nonce,uint256 deadline)"
        );

    modifier onlyAuthorizedTopUpVault(
        address incrementer,
        uint256 incrementAmount,
        uint256 deadline,
        bytes32 _typehash,
        bytes memory signature
    ) {
            processSignatureVerification(
                abi.encode(
                    _typehash,
                    incrementer,
                    incrementAmount,
                    privilegedAddressObj.getPrivilegedAddress(),
                    nonces[privilegedAddressObj.getPrivilegedAddress()],
                    deadline
                ),
                signature,
                deadline,
                privilegedAddressObj.getPrivilegedAddress()
            );
        _;
    }

    bytes32 public constant _SET_INCREMENT_REWARD_TYPEHASH =
        keccak256(
            "IncrementReward(address incrementer,address productAddress,uint256 incrementAmount,address _owner,uint256 nonce,uint256 deadline)"
        );

    modifier onlyAuthorizedIncrementReward(
        address incrementer,
        address productAddress,
        uint256 incrementAmount,
        uint256 deadline,
        bytes32 _typehash,
        bytes memory signature
    ) {
            processSignatureVerification(
                abi.encode(
                    _typehash,
                    incrementer,
                    productAddress,
                    incrementAmount,
                    privilegedAddressObj.getPrivilegedAddress(),
                    nonces[privilegedAddressObj.getPrivilegedAddress()],
                    deadline
                ),
                signature,
                deadline,
                privilegedAddressObj.getPrivilegedAddress()
            );
        _;
    }

    modifier onlyWhenProductNotOperating(address productAddress){
        if (StakingBase(payable(productAddress)).locked()){ revert Error_Cannot_Interact_While_Product_Working();}
        StakingBase(payable(productAddress)).setLocked(true);
        _;
        StakingBase(payable(productAddress)).setLocked(false);
    }

    modifier onlyWhenProductNotOperatingUpdateRate(address productAddress){
        if (StakingBase(payable(productAddress)).locked()){ revert Error_Cannot_Interact_While_Product_Working();}
        StakingBase(payable(productAddress)).setLocked(true);
        _;
        StakingBase(payable(productAddress)).setLocked(false);
        StakingBase(payable(productAddress)).updateRate();
    }

    bytes32 public constant _SET_DECREMENT_REWARD_TYPEHASH =
        keccak256(
            "DecrementReward(address productAddress,uint256 decrementAmount,address _owner,uint256 nonce,uint256 deadline)"
        );

    modifier onlyAuthorizedDecrementReward(
        address productAddress,
        uint256 decrementAmount,
        uint256 deadline,
        bytes32 _typehash,
        bytes memory signature
    ) {
        processSignatureVerification(
            abi.encode(
                _typehash,
                productAddress,
                decrementAmount,
                privilegedAddressObj.getPrivilegedAddress(),
                nonces[privilegedAddressObj.getPrivilegedAddress()],
                deadline
            ),
            signature,
            deadline,
            privilegedAddressObj.getPrivilegedAddress()
        );
        _;
    }

    modifier feeReturner(address productAddress){
        IFeeManager.FeeStrategy memory feeStrat = IFeeManager(feeManager).getFeeStrategy(payable(productAddress));
        (bool sentAdd3,uint feeToAdd3) = sendToAdd3(ExtraLib.PERCENT_DIVISOR,feeStrat.add3);
        if (!sentAdd3 || feeToAdd3 == 0){ revert Error_No_Fee_Sent_To_Add3();}
        _;
    }

    function sendToAdd3(uint add3Fee, address add3) internal returns(bool sentAdd3,uint feeToAdd3){
        uint256 ethInputFee = getEthInputFee();
        // Refund if user sent more than it should
        if (msg.value > ethInputFee) {
            uint256 refundAmount = msg.value - ethInputFee;

            // Transfer the refund amount to the sender
            (bool refunded,) = payable(msg.sender).call{value: refundAmount}("");

            // Emit the refund event
            if (refunded) {
                emit Refund(msg.sender, refundAmount);
            }
        }
        if (address(this).balance < ethInputFee ){ revert Error_No_Fee_Value();}
        feeToAdd3 = address(this).balance * add3Fee / ExtraLib.PERCENT_DIVISOR;
        (sentAdd3,) = payable(add3).call{value: feeToAdd3}("FeeAdd3");
    }
    /*//////////////////////////////////////////////////////////////
                            FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // get Product reward
    // @param address of the Product being checked for the reward
    function productReward(
        address productAddress
    ) external view onlyClientOrActive() returns (uint256) {
        return products[productAddress].availableReward;
    }

    function previewCheckValidDeposit(
        uint256 amount,
        uint256 reward,
        uint256 contractBalance,
        uint256 interestPercentageBps
    ) external view onlyActiveProduct() returns (bool approvedDepoosit) {
        // check vault reward amount is greater than set reward amount
            // at any point of time given stake patterns the vault must have the APY of the contract balance
            address productAddress = msg.sender;
            uint previewDemand = ((contractBalance + amount) * interestPercentageBps * StakingBase(payable(productAddress)).minLockSeconds()) / (10000 * 365 days);
            uint unconverted = IVault(vaultAddress).getAvailableTokens() - reward - (totalRewardsAllProducts - products[productAddress].availableReward);
            uint previewSupply = products[productAddress].stakingToken == rewardToken ? unconverted : getDataForQuote(msg.sender,unconverted,false);
            if ( previewDemand <= previewSupply ) { approvedDepoosit = true; } 
    }

        function getEthInputFee() public view returns(uint256 feeInEth){
        // if is not Gnosis or Chiado - use 1 xDai = 1 USD
        feeInEth = 1 ether;
        if ( block.chainid != 100 && block.chainid != 10200) {
            uint8 USDdecimals = IERC20v2(USD).decimals(); 
            uint128 dollarsFee = (block.chainid == 1 || block.chainid == 5 || block.chainid == 11155111) ? uint128(3*10**USDdecimals) : uint128(10**USDdecimals) ; // 3 dollars for Ethereum 1 dollar for others

            try IStaticOracle(Oracle).quoteSpecificPoolsWithTimePeriod(dollarsFee,USD,WETH,WETHUSDpools,1000) returns (uint feeEth) {
                feeInEth = feeEth;
            } catch (bytes memory /* error */) {
                revert Error_No_Quote_From_Oracle();
            }
        }
    }

    function getDataForQuote( address productAddress,uint inputTokenAmount, bool isOutputRewardToken) public view onlySelectedIsActiveProduct(productAddress) returns (uint outputTokenAmount) {
             if (isOutputRewardToken){
                outputTokenAmount = IStaticOracle(Oracle).quoteSpecificPoolsWithTimePeriod(uint128(inputTokenAmount),products[productAddress].stakingToken,rewardToken,products[productAddress].pools,1000);
                }
             else {
                outputTokenAmount = IStaticOracle(Oracle).quoteSpecificPoolsWithTimePeriod(uint128(inputTokenAmount),rewardToken,products[productAddress].stakingToken,products[productAddress].pools,1000);
                }
    }

    // Function to claim a reward for a user deduct add3 and admin fees, if any
    // @param rewardRate so we dont over subscribe
    // @modifiers nonReentrant
    function claimReward(uint256 claimAmount
    ) external nonReentrant onlyActiveProduct() returns (uint256 netClaimed) {
        // deductions from reward as admin and add3 fees (set earlier by Client)
        address productAddress = msg.sender;
        IFeeManager.FeeStrategy memory feeStrat = IFeeManager(feeManager).getFeeStrategy(payable(productAddress));

        // Platform declares that some tokens will be deducted as platform fees(add3+admin fees) from the rewards
        // expecting 2 decimal shifted percentages, Bps
        uint256 adminDeductions = ((feeStrat.adminFeeBps) * claimAmount) /10000 == 0 && feeStrat.adminFeeBps != 0 && claimAmount > 2 ? 1 : ((feeStrat.adminFeeBps) * claimAmount) /10000;

        if (adminDeductions > 0) {
            IVault(vaultAddress).withdrawFromVault(feeStrat.admin,adminDeductions);
        }

        uint256 add3Deductions = ((feeStrat.add3FeeBps) * claimAmount) / 10000 == 0 && claimAmount > 2 ? 1 : ((feeStrat.add3FeeBps) * claimAmount) / 10000;

        if (add3Deductions > 0) {
            IVault(vaultAddress).withdrawFromVault(feeStrat.add3,add3Deductions);
        }
        netClaimed = claimAmount - (adminDeductions + add3Deductions);
        products[productAddress].availableReward -= claimAmount;

        totalRewardsAllProducts -= claimAmount;
        IVault(vaultAddress).withdrawFromVault(productAddress,netClaimed);
    }

    // Registers new Product supported by the controller/vault
    // @param contractAddress so that we can add to spend list
    // @param rewardAmount so we cant over-subscribe
    // @param productTypes so we know what kind if Product is being registered
    // productTypes, 0 - Static Staking, 1 - Dynamic Staking
    // @modifiers nonReentrant
    function registerProduct(
        RegisterProduct memory reg
    )
        external
        nonReentrant onlyAuthorizedRegisterProduct(reg.productAddress,reg.pool ,reg.rewardAmount,reg.feeStrategy,reg.deadline,_REGISTER_PRODUCT_TYPEHASH,FeeManager(feeManager)._FEE_STRATEGY_STRUCT_TYPEHASH(),reg.signature)
        customModifier((products[reg.productAddress].active == true),customTypes.PRODUCT_REGISTERED)
    {
        address prod = reg.productAddress;
        // when a new Product is added, add reward tokens to it
        // now totalRewardsAllProducts has all rewards needed across all products
        // current vault balance - to-be-registered Product's rewards should be >= totalRewardsAllProducts
        if (!(reg.rewardAmount > 0)) {revert Error_Invalid_Registration_Reward_Amount();}
        if (!StakingBase(payable(prod)).supportsInterface(type(StakingBase).interfaceId)) {revert Error_Invalid_Product_Address();}

        products[prod].productType = StakingBase(payable(prod)).productType();
        products[prod].stakingToken = address(StakingBase(payable(prod)).erc20StakingToken());
        products[prod].availableReward = reg.rewardAmount;
    
        // if reward and staking tokens are different check if supported by the oracle
        if (products[prod].stakingToken != rewardToken){
            if (!IStaticOracle(Oracle).isPairSupported(products[prod].stakingToken, rewardToken)){
            revert Error_Invalid_Pair();
            }
            address inputPool = reg.pool;
            address token0 = IUniswapV3Pool(inputPool).token0();
            address token1 = IUniswapV3Pool(inputPool).token1();

            if ((token0 == rewardToken && token1 == products[prod].stakingToken) || (token0 == products[prod].stakingToken && token1 == rewardToken) ){
                products[prod].pools = new address[](1); 
                products[prod].pools[0] = inputPool;    
            } else { revert Error_Mismatch_Pair_Tokens(); }

        }

        // add fee strategy to FeeManager, data is included in the initial function call and is authorized by the owner yet
        try FeeManager(feeManager).registerFeeStrategy(reg.feeStrategy,reg.productAddress, block.timestamp + 30 minutes, '0x') {} catch  {
            emit Strategy_Already_Registered();
        }

        totalRewardsAllProducts += reg.rewardAmount;
        IVault(vaultAddress).depositToVault(
            privilegedAddressObj.getPrivilegedAddress(),
            products[prod].availableReward
        );
        products[prod].active = true;
    }

    function setOperator(address _operator,address productAddress, uint256 deadline,bytes memory signature) external nonReentrant onlyAuthorizedSetOperator(_operator,productAddress,deadline, _TYPEHASH_SET_OPERATOR, signature){
        // if is address(0) it means operator is disabled
        products[productAddress].operator = _operator;
    }

    // Removes the Product from the controller (users will be told to unstake or exit funds.)
    // @param Address of the deployed Product
    // @modifiers nonReentrant
    function removeProduct(
        RemoveProduct memory removeInput
    )
        external
        nonReentrant
        onlyAuthorizedRemoveProduct(
            removeInput.productAddress,
            removeInput.deadline,
            _SET_REMOVE_PRODUCT_TYPEHASH,
            removeInput.signature
        )
        customModifier(
            (products[removeInput.productAddress].active != true),
            customTypes.PRODUCT_NOT_REGISTERED
        )
        payable feeReturner(removeInput.productAddress)
        onlyWhenProductNotOperating(removeInput.productAddress)
    {
        address productAddress = removeInput.productAddress; 
        // check if contract is 0 balance i.e. withdrawn invested + rewards (vault)
        if ( StakingBase(payable(productAddress)).contractStakedBalance() != 0) {
            revert Error_Product_Balance_Not_Zero();
        }

        //upon deregistering admin wallet will recieve the leftover available rewards from vault, if any

        totalRewardsAllProducts -= products[productAddress].availableReward;

        products[productAddress].active = false;
        uint tempAvailableReward = products[productAddress].availableReward;
        products[productAddress].availableReward = 0;

        // if rewards to transfer
        IVault(vaultAddress).withdrawFromVault(
            privilegedAddressObj.getPrivilegedAddress(),
            tempAvailableReward
        );
    }

    // @param productAddress
    // @param Address of the deployed Product
    // @param Amount to increment the reward
    function incrementRewardFromOwner(
        address incrementer,
        address productAddress,
        uint256 incrementAmount,
        uint256 deadline,
        bytes memory signature
    ) external 
        nonReentrant
        onlyAuthorizedIncrementReward(
            incrementer,
            productAddress,
            incrementAmount,
            deadline,
            _SET_INCREMENT_REWARD_TYPEHASH,
            signature
        )
         payable feeReturner(productAddress)
    {
        _incrementReward(incrementer,productAddress,incrementAmount);
    }

    function incrementReward(
        uint256 incrementAmount) external onlyActiveProduct(){
            _incrementReward(msg.sender,msg.sender,incrementAmount);
        }

    function _incrementReward(address incrementer,address productAddress,uint256 incrementAmount) internal customModifier(
            (products[productAddress].active != true),
            customTypes.PRODUCT_NOT_REGISTERED
        ) {
        products[productAddress].availableReward += incrementAmount;

        totalRewardsAllProducts += incrementAmount;
        if (products[productAddress].productType == 1 && !StakingBase(payable(productAddress)).locked()){
            StakingBase(payable(productAddress)).updateRate();
            }

        IVault(vaultAddress).depositToVault(incrementer, incrementAmount);
    }

    // Decrements the reward amount for a certain Product and transfers it to owner
    // @param Address of the deployed Product
    // @param Amount to decrement the reward
    function decrementReward(
        ProductAmountDeadlineSignature memory decrementInput
    )
        external
        nonReentrant
        onlyWhenProductNotOperatingUpdateRate(decrementInput.addr)
        onlyAuthorizedDecrementReward(
            decrementInput.addr,// productAddress
            decrementInput.amount,
            decrementInput.deadline,
            _SET_DECREMENT_REWARD_TYPEHASH,
            decrementInput.signature
        )
        payable feeReturner(decrementInput.addr)
        customModifier( (products[decrementInput.addr].active != true), customTypes.PRODUCT_NOT_REGISTERED
        )
    {
            address prod = decrementInput.addr;
            uint decrementAmount = decrementInput.amount;
            uint256 interestPercentageBps = StakingBase(payable(prod)).ratesHistory()[StakingBase(payable(prod)).ratesHistory().length - 1].value;
        
        if (StakingBase(payable(prod)).contractStakedBalance() != 0 && decrementAmount != 0 ) {

            uint stakedBalance = StakingBase(payable(prod)).contractStakedBalance();
            if ( IVault(vaultAddress).getAvailableTokens() + products[prod].availableReward >= totalRewardsAllProducts + decrementAmount){
                uint equivalentFromVault = IVault(vaultAddress).getAvailableTokens() + products[prod].availableReward - totalRewardsAllProducts - decrementAmount;
                
                if (products[prod].stakingToken != rewardToken){
                equivalentFromVault = getDataForQuote(prod,equivalentFromVault,false);
                }
                
                if (products[prod].productType == 0 && !((stakedBalance * interestPercentageBps * StakingBase(payable(prod)).minLockSeconds()) /(10000 * 365 days) <= equivalentFromVault)) {revert Error_Invalid_Decrement_Reward();}
            } else {revert Error_Invalid_Decrement_Reward();}
        } 
        if (products[prod].availableReward * 9000/ 10000 < decrementAmount){ revert Error_Denied_Decrement_More_Than_Ninety_Percent();}
        products[prod].availableReward -= decrementAmount;
        totalRewardsAllProducts -= decrementAmount;
        // client wallet refund after decrement
        IVault(vaultAddress).withdrawFromVault(privilegedAddressObj.getPrivilegedAddress(),decrementAmount);
        // this is done after since it will try to get back tokens as reward
        // for this the updated Vault balance has to be in place
    }

    function getVaultAddress() external view returns (address) {return vaultAddress;}
    function getRewardToken() external view returns (address) {return rewardToken;}
    function getPrivilegedRegistryAddress() external view returns (address) {return address(privilegedAddressObj);}
    function amIActive() external view returns (bool){ return products[msg.sender].active;}

    function topUpVault(
        ProductAmountDeadlineSignature memory topupInput
    ) external nonReentrant
        onlyAuthorizedTopUpVault(
            topupInput.addr,//refiller
            topupInput.amount,// topUpAmount,
            topupInput.deadline,
            _TOP_UP_VAULT_TYPEHASH,
            topupInput.signature
        )  {
        IVault(vaultAddress).depositToVault(topupInput.addr, topupInput.amount);
    }

    function extractFromVault(
        uint256 extractedAmount,
        uint256 deadline,
        bytes memory signature
    ) external onlyAuthorizedExtractFromVault(extractedAmount,deadline,_EXTRACT_FROM_VAULT_TYPEHASH,signature) {
        if (extractedAmount > IVault(vaultAddress).getAvailableTokens() - totalRewardsAllProducts){ revert Error_Can_Directly_Extract_Only_Rewards_Not_Pledged_As_Supply();}
        IVault(vaultAddress).withdrawFromVault(privilegedAddressObj.getPrivilegedAddress(),extractedAmount);
    }

    function getFeeStrategy() external view onlyActiveProduct() returns (IFeeManager.FeeStrategy memory feeStrat) {
        feeStrat = IFeeManager(feeManager).getFeeStrategy(msg.sender);}

    // supposes the Vault has extra tokens as reserve , the reserve is "IVault(vaultAddress).getAvailableTokens() - totalRewardsAllProducts"
    // if yes reduce the reserve and add it to the product that requires it
    // NOTE no transfer of tokens here, but is an "internal" adjustment
    function addSupplyToProductFromVault(address productAddress,uint incrementAmount) external onlyActiveProduct() returns(bool assigned) {
        if ( IVault(vaultAddress).getAvailableTokens() - totalRewardsAllProducts >= incrementAmount && incrementAmount != 0) {
        products[productAddress].availableReward += incrementAmount;

        totalRewardsAllProducts += incrementAmount;

            assigned = true;
        } else {
            assigned = false;
        }
    }
    // With this an operator authorized by the owner can keep apy updated, effective only if staking type is dynamic
    function updateRate(address productAddress) payable feeReturner(productAddress) external onlyOperatorOrOwner(productAddress) onlyWhenProductNotOperating(productAddress) {
        if(products[productAddress].productType == 1) {
            StakingBase(payable(productAddress)).updateRate();
        }
    }
}

// SPDX-License-Identifier: BSL-1.1

// Copyright (c)
// All rights reserved.

// This software is released under the Business Source License 1.1.
// For full license terms, see the LICENSE file.

/*
    This file is part of the ADD3 Protocol.
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/


pragma solidity ^0.8.19;

import "../../extensions/fee-manager/IFeeManager.sol";

/// @title IController Interface
/// @author Augusto Francesco D'Intino - [email protected]
interface IController {

    enum productTypes{
        STATIC_STAKING,
        DYNAMIC_STAKING
    }

        struct Product {
        uint8 productType;
        bool active;
        uint256 availableReward;
        address stakingToken;
        address operator;
        address[] pools;
    }

    struct RegisterProduct{
        address productAddress;
        address pool;
        uint256 rewardAmount;
        IFeeManager.FeeStrategy feeStrategy;
        uint256 deadline;
        bytes  signature;
    }

    struct RemoveProduct {
        address productAddress; 
        uint256 deadline; 
        bytes signature;
    }

    struct ProductAmountDeadlineSignature {
        address addr; 
        uint256 amount;
        uint256 deadline; 
        bytes signature;
    }
    // Checks reward balance for the product
    // @param address of the product being used
    function productReward(address) external view returns (uint256);

    // Checks if a user deposit is doable and the vault has enough tokens to reward that user
    // @param amount of tokens being deposited
    // @param address of the product being used
    // @param balance of the product being used
    // @param interest rate of the product being used    
    function previewCheckValidDeposit(uint256, uint256, uint256, uint256) external returns (bool);

    // Function to claim a reward for a user
    // @param productAddress to reduce the tokens available 
    // @param claimAmount totalTokens to be claimed from the vault 
    // @modifiers onlyAdd3, nonReentrant
    function claimReward( uint256) external returns(uint256);

    // Registers new product supported by the controller/vault 
    // @param contractAddress so that we can add to spend list
    // @param rewardAmount so we cant over-subscribe
    // @param productTypes so we know what kind if product is being registered, uint8
    // @param adapter address
    // @param deadline expiry
    // @param signature
    // @modifiers onlyAdd3, enoughRewards, nonReentrant
    function registerProduct(RegisterProduct memory reg) external;

    // Removes the product from the controller (users will be told to unstake or exit funds.)
    // @param Address of the deployed product
    // @param Address of the token
    // @param deadline expiry
    // @param signature
    function removeProduct(RemoveProduct memory) payable external;

    // Increments the reward amount for a certain product
    // @param Address of the deployed product
    // @param Amount to increment the reward, for owner. Has NoReentrant policy
    function incrementRewardFromOwner(address, address, uint256, uint256, bytes memory) payable external;
    
    // Increments the reward amount for a certain product
    // @param Address of the deployed product
    // @param Amount to increment the reward, for adapter
    function incrementReward( uint256) external;
    // Decrements the reward amount for a certain product
    // @param Address of the deployed product
    // @param Amount to increment the reward
    function decrementReward(ProductAmountDeadlineSignature memory) payable external;

    // Adds Rewards Tokens to the Vault without attaching to any product
    // @param Address of the refiller
    // @param Amount to increment the Vault
    function topUpVault(ProductAmountDeadlineSignature memory) external;

    // Extracts Reward Tokens amount the is not pledged as supply for any product
    // @param Amount to extract from Vault
    function extractFromVault( uint256, uint256, bytes memory) external;
    
    function addSupplyToProductFromVault(address,uint ) external returns(bool);
    
    function getEthInputFee() external view returns(uint256 );
    
    function getVaultAddress() external view returns(address);
    
    function getFeeStrategy() external view returns(IFeeManager.FeeStrategy memory);

    function getDataForQuote(address productAddress, uint inputTokenAmount, bool isOutputRewardToken) external view returns (uint outputTokenAmount);

    function updateRate(address productAddress) payable external;

    function setOperator(address,address,uint256,bytes memory) external;

    function getPrivilegedRegistryAddress() external returns(address);

    function getRewardToken() external returns (address);

    function amIActive() external returns (bool);
}

// SPDX-License-Identifier: BSL-1.1

// Copyright (c)
// All rights reserved.

// This software is released under the Business Source License 1.1.
// For full license terms, see the LICENSE file.

/*
    This file is part of the ADD3 Protocol.
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/


pragma solidity ^0.8.19;

/// @title IPrivilegedAddressRegistry Interface
/// @author Augusto - ADD3.io
interface IPrivilegedAddressRegistry {

    function getPrivilegedAddress() external view returns (address);
    function getPrivilegedPenaltyRecipientAddress() external view returns (address);
}

// SPDX-License-Identifier: BSL-1.1

// Copyright (c)
// All rights reserved.

// This software is released under the Business Source License 1.1.
// For full license terms, see the LICENSE file.

pragma solidity ^0.8.19;

/// @author Augusto <[email protected]>
/// @title ERC712Custom
/// This abstract class can be inherited and used by all contracts using the EIP712 functions

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "../privilegedaddressregistry/IPrivilegedAddressRegistry.sol";

abstract contract ERC712Custom is EIP712 {

    using ECDSA for bytes32;

    mapping(address => uint256) public nonces;

    IPrivilegedAddressRegistry privilegedAddressObj;

    error Error_Unauthorized_Signature();
    error Error_Unauthorized_Deadline_Expired();

    function processSignatureVerification(bytes memory encodedParams, bytes memory signature, uint256 deadline, address verificationAddr) internal{ 

        if (msg.sender != verificationAddr){
            if(block.timestamp > deadline){ revert Error_Unauthorized_Deadline_Expired();}

            address signer = ECDSA.recover(digest(encodedParams), signature);
            nonces[verificationAddr]++;
            if (verificationAddr != signer){ revert Error_Unauthorized_Signature();} } 
    }
    
    function digest( bytes memory encodedParams ) public view returns (bytes32){
        return _hashTypedDataV4(keccak256(encodedParams));
    }

}

// SPDX-License-Identifier: BSL-1.1

// Copyright (c)
// All rights reserved.

// This software is released under the Business Source License 1.1.
// For full license terms, see the LICENSE file.

pragma solidity ^0.8.19;

/// @author Augusto <[email protected]>
/// @title ERC712CustomUpgradeable
/// This abstract class can be inherited and used by all contracts using the EIP712 functions

import "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import "../privilegedaddressregistry/IPrivilegedAddressRegistry.sol";

abstract contract ERC712CustomUpgradeable is EIP712Upgradeable {

    using ECDSAUpgradeable for bytes32;

    mapping(address => uint256) public nonces;

    IPrivilegedAddressRegistry privilegedAddressObj;

    error Error_Unauthorized_Signature();
    error Error_Unauthorized_Deadline_Expired();

    function processSignatureVerification(bytes memory encoded_params, bytes memory signature, uint256 deadline, address verificationAddr) internal{ 

        if (msg.sender != verificationAddr){
            if(block.timestamp > deadline){ revert Error_Unauthorized_Deadline_Expired();}

            address signer = ECDSAUpgradeable.recover(digest(encoded_params), signature);
            nonces[verificationAddr]++;
            if (verificationAddr != signer){ revert Error_Unauthorized_Signature();} } 
    }

    function digest( bytes memory encodedParams ) public view returns (bytes32){
        return _hashTypedDataV4(keccak256(encodedParams));
    }

}

// SPDX-License-Identifier: BSL-1.1

// Copyright (c)
// All rights reserved.

// This software is released under the Business Source License 1.1.
// For full license terms, see the LICENSE file.

pragma solidity ^0.8.19;

/// @author Augusto <[email protected]>
/// @title ModifierCustom
/// This abstract class is inherited and used by all contracts which need to limit resetting of the state addresses/variables, which should be set once only.

abstract contract ModifierCustom {

    enum customTypes{
        ADAPTER_NOT_SET,
        ARE_RATES_SET,
        ARE_RATES_NOT_SET,
        FEE_STRATEGY_SET,
        PRODUCT_REGISTERED,
        PRODUCT_NOT_REGISTERED
    }

    error Error_Adapter_Not_Set();
    error Error_Fee_Strategy_Set();
    error Error_Product_Registered();
    error Error_Product_Not_Registered();
    error Error_Rates_Are_Set_Yet();
    error Error_Rates_Are_Not_Set_Yet();

    modifier customModifier(bool valueVar, customTypes customType) { 
        
        if(customType == customTypes.ADAPTER_NOT_SET){if (!valueVar) { revert Error_Adapter_Not_Set(); } }

        else if(customType == customTypes.ARE_RATES_SET){if (valueVar) { revert Error_Rates_Are_Set_Yet(); } }

        else if(customType == customTypes.ARE_RATES_NOT_SET){if (!valueVar) { revert Error_Rates_Are_Not_Set_Yet(); } }

        else if(customType == customTypes.FEE_STRATEGY_SET){if (valueVar) { revert Error_Fee_Strategy_Set(); } }

        else if(customType == customTypes.PRODUCT_REGISTERED){if (valueVar) { revert Error_Product_Registered(); } }

        else if(customType == customTypes.PRODUCT_NOT_REGISTERED){if (valueVar) { revert Error_Product_Not_Registered(); } }

        _;
    }

}

// SPDX-License-Identifier: BSL-1.1

// Copyright (c)
// All rights reserved.

// This software is released under the Business Source License 1.1.
// For full license terms, see the LICENSE file.

/*
    This file is part of the Add3 protocol.

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity ^0.8.19;

/// @title IVault Interface
/// @author Augusto Francesco D'Intino - Add3 <[email protected]>
interface IVault {
    function depositToVault(address depositor, uint256 amount) external;

    function withdrawFromVault(address claimer, uint256 claimAmount) external;

    function getAvailableTokens() external view returns(uint256);

}

// SPDX-License-Identifier: BSL-1.1

// Copyright (c)
// All rights reserved.

// This software is released under the Business Source License 1.1.
// For full license terms, see the LICENSE file.

pragma solidity ^0.8.19;

/// @author Augusto - ADD3.io

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IVault.sol";

contract Vault is IVault {
    using SafeERC20 for IERC20;
    //address check for all inputs
    using Address for address;

    error Only_Controller_Callable();
    error Error_Invalid_Asset_Address();

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw( address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    address public controller;
    uint256 public timestampLastVaultSet;

    modifier onlyController{ if(msg.sender != controller) {revert Only_Controller_Callable();} _; }

    IERC20 public immutable asset;

    constructor( address _asset){ 
        if (!_asset.isContract()){ revert Error_Invalid_Asset_Address(); }
        asset = IERC20(_asset);
        
        controller = msg.sender; 
        }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function depositToVault(address depositor, uint256 amount) external onlyController {
        timestampLastVaultSet = block.timestamp;
        asset.safeTransferFrom(depositor, address(this), amount); }

    // used to withdraw Tokens from the vault, through the controller
    function withdrawFromVault(address claimer, uint256 claimAmount) external onlyController {
        timestampLastVaultSet = block.timestamp;
        asset.safeTransfer(claimer, claimAmount); }

    function getAvailableTokens() external view returns(uint256){ return asset.balanceOf(address(this)); }

}

// SPDX-License-Identifier: BSL-1.1

// Copyright (c)
// All rights reserved.

// This software is released under the Business Source License 1.1.
// For full license terms, see the LICENSE file.

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Address.sol";
import "../../core/utils/ERC712Custom.sol";
import "../../core/utils/ModifierCustom.sol";
import "./IFeeManager.sol";

/// @author Augusto - <Add3>
/// @title - Feemanager contract

contract FeeManager is ERC712Custom, IFeeManager, ModifierCustom{

    //address check for all inputs
    using Address for address;

    mapping(address => FeeStrategy) public feeStrategies;

    error Error_Invalid_Add3Bps_Percentage();
    error Error_Invalid_Admin_Address();
    error Error_Invalid_Add3_Address();
    error Error_Invalid_AdminBps_And_Add3Bps_Percentages();
    error Error_Invalid_Add3TxBps_Percentage();
    error Error_Only_Controller_Can_Register_Strategy();

    address immutable public controller;

    constructor()EIP712("FeeManager Contract", "4"){
        controller = msg.sender;
    }

    bytes32 public constant _REGISTER_FEE_STRATEGY_TYPEHASH = keccak256("RegisterFeeStrategy(FeeStrategy _newStrategy,address _implementation,address _owner,uint256 nonce,uint256 deadline)FeeStrategy(uint256 add3TxFeeBps,uint256 adminFeeBps,uint256 add3FeeBps,address admin,address add3)");
    bytes32 public constant _FEE_STRATEGY_STRUCT_TYPEHASH = keccak256("FeeStrategy(uint256 add3TxFeeBps,uint256 adminFeeBps,uint256 add3FeeBps,address admin,address add3)");
// set second typehash as parameter
    modifier onlyController(FeeStrategy calldata newStrategy, address implementation, uint256 deadline,bytes32 _typehash,bytes32 _secondary_typehash, bytes memory signature) {
        if(msg.sender != controller) { revert Error_Only_Controller_Can_Register_Strategy();}
        _; }

    function getFeeStrategy(address implementation) external view returns (FeeStrategy memory){
        return feeStrategies[implementation];
    }

    function registerFeeStrategy(FeeStrategy calldata newStrategy, address implementation, uint256 deadline, bytes memory signature) external onlyController(newStrategy, implementation,deadline, _REGISTER_FEE_STRATEGY_TYPEHASH,_FEE_STRATEGY_STRUCT_TYPEHASH, signature) customModifier((feeStrategies[implementation].add3FeeBps!=0 && feeStrategies[implementation].add3TxFeeBps!=0), customTypes.FEE_STRATEGY_SET){
        // checking valid addresses
        if (newStrategy.admin == address(0)){
             revert Error_Invalid_Admin_Address(); 
        }
        feeStrategies[implementation].admin = newStrategy.admin;
        if (newStrategy.add3 == address(0)){ revert Error_Invalid_Add3_Address(); }
        if (feeStrategies[implementation].add3 == address(0)){
            feeStrategies[implementation].add3 = newStrategy.add3;
        }
        // checking sum of fees not more than 100%
        if (newStrategy.adminFeeBps + newStrategy.add3FeeBps > 5000){revert Error_Invalid_AdminBps_And_Add3Bps_Percentages();}
        if ( newStrategy.add3TxFeeBps < 9000 || newStrategy.add3TxFeeBps > 10000){revert Error_Invalid_Add3TxBps_Percentage();}
        
        // add3 fees cannot be 0
        if (newStrategy.add3FeeBps == 0){ revert Error_Invalid_Add3Bps_Percentage(); }
        feeStrategies[implementation].add3FeeBps = newStrategy.add3FeeBps;
        feeStrategies[implementation].add3TxFeeBps = newStrategy.add3TxFeeBps;

        // previous check on sum of fees does not require to check here if adminFee is > 100%
        feeStrategies[implementation].adminFeeBps = newStrategy.adminFeeBps;
    }
}

// SPDX-License-Identifier: BSL-1.1

// Copyright (c)
// All rights reserved.

// This software is released under the Business Source License 1.1.
// For full license terms, see the LICENSE file.

/*
    This file is part of the Add3 protocol.

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity ^0.8.19;
pragma abicoder v2;

/// @title IFeeManager Interface
/// @author Add3 <[email protected]>
interface IFeeManager {
    struct FeeStrategy{
        uint256 add3TxFeeBps;
        uint256 adminFeeBps; // percentage reward
        uint256 add3FeeBps; // percentage reward
        address admin; 
        address add3;}

    function getFeeStrategy(address implementation) external view returns (FeeStrategy memory);

    function registerFeeStrategy(FeeStrategy calldata newStrategy, address implementation, uint256 deadline, bytes memory signature) external;
    
}

// SPDX-License-Identifier: BSL-1.1

// Copyright (c)
// All rights reserved.

// This software is released under the Business Source License 1.1.
// For full license terms, see the LICENSE file.

// WARNING this contract has not been independently tested or audited
// DO NOT use this contract with funds of real value until officially tested and audited by an independent expert or group

/// @title Staking Contract interface 

pragma solidity ^0.8.19;

/// @author Add3 - Augusto Francesco D'Intino <[email protected]>
/// @review Add3 - Augusto Francesco D'Intino <[email protected]>
/// @review Add3 - Nuno Cervaens <[email protected]>

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "../../core/utils/ERC712CustomUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../core/utils/ModifierCustom.sol";
import "../../core/controller/IController.sol";
import "../../libraries/ExtraLib.sol";
import "../fee-manager/IFeeManager.sol";

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

abstract contract StakingBase is ERC712CustomUpgradeable,ModifierCustom,ReentrancyGuardUpgradeable {

    //address check for all inputs
    using AddressUpgradeable for address;

    // Library usage
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // ERC20 contract address
    IERC20Upgradeable public erc20StakingToken;
    IERC20Upgradeable public erc20RewardToken;

    uint8 public productType; // 0 static , 1 dynamic 

    // Building Blocks of logic
    struct HistoryEntry {
        uint256 value;
        uint256 timestamp;
        uint256 cumulatedValue; // since value_0 is in place between timestamp_0 and timestamp_1 it is the summatory of each, value_0* (timestamp_1 - timestamp_0)
        }
    struct DetailedBalance {
        uint256 value;
        uint256 timestamp;
        uint256 interestHistoryIndex;
        }

    struct InitializeStruct {
        address _erc20_contract_address;
        address _controller; 
        uint256 _cap;
        uint256 _startTime;
        uint256  _stopTime;
        uint256 _minStake;
        uint256 _maxStake;
        uint64 _penaltyRate; 
        uint64 _minLockDays;
        bool _itAutocompounds;
    }

    struct StakingStruct {
        uint256 amount;
        uint256 minRewards;
    }

    HistoryEntry[] public historyInterestRate; // here "value" is the interest rate, it has to be passed in the form of bps , 1 bps = 0.01%
    
    function ratesHistory() public view returns (HistoryEntry[] memory){
        return historyInterestRate;
    }

    // this is contract staked tokens Balance 
    uint256 public contractStakedBalance;
    // rewards balance - NOTE this is populated only when non autocompound contract
    uint256 public contractRewardsBalance;

    DetailedBalance public globalUnmaterializedRewards;
    // user balances history
    mapping(address => uint256) public rewardsBalance;

    function balanceOf(address user) public view virtual returns (uint256){}

    // staking policy & terms
    uint64 public penaltyRate; // has to be in bps
    uint64 public minLockSeconds;
    uint256 public cap; // !== 0 in case of capped contract
    uint256 public startTime;
    uint256 public stopTime;
    uint256 public minStake;
    uint256 public maxStake;
    
    mapping(address => uint256) public stakeTime; 
    mapping(address => bool) public isBlacklisted; 

    event Warning_Failed_To_Add(uint256 amount);
    event DesiredAPYset(uint256 apy);

    event RewardHarvested(address to, uint256 amount);
    event RewardsOutOfStock(address to, uint256 amount);
    event TokensUnstaked(address to, uint256 amount);
    event TokensWithdrawn(address to, uint256 amount, uint256 rewards);
    event Refund(address indexed sender, uint256 amount);

    // set of boolean varaibles to prevent reentrancy
    bool public locked;
    bool internal areRatesSet;

    // staking type defining variables
    bool public itAutocompounds;
    bool public isRewardSameToken;

    IController public Controller;

    function setInterestRate(uint256 apy ,uint256 deadline,bytes memory signature) payable external virtual{}

    // overridden in implementing contracts
    function updateRate() external onlyController virtual{}
    function stakeTokens(StakingStruct memory stake) payable external virtual{}
    function getRewardsAndAccountThem(uint256 minRewards) internal virtual returns (uint rewards){} 
    function unstakeTokens(StakingStruct memory unstake) payable external virtual{}

    function _withdrawLogic(uint256 amount) internal virtual {}

    function _depositLogic(uint256 amount) internal virtual {}

    function _harvestAndWithdrawRewards(uint256 minRewards) internal customModifier(areRatesSet, customTypes.ARE_RATES_NOT_SET) onlyWhenInteractionEnabled(false) onlyAfterStaked() onlyWhitelisted returns (uint amountRewards){
            getRewardsAndAccountThem(minRewards);
            amountRewards = reduceAndZeroRewardsBalance();
            erc20RewardToken.safeTransfer(msg.sender, amountRewards); 
        }
    // errors
    error Error_Only_Owner();
    error Error_Not_Staked_Yet();
    error Error_Blacklisted_User();
    error Error_Oustide_Stake_Range();
    error Error_Already_In_Desired_List_State();
    error Error_No_Fee_Sent_To_Add3();
    error Error_No_Fee_Sent_To_Privileged_Address();
    error Error_transferAccidentallyLockedTokens_Token_address_Invalid();
    error Error_transferAccidentallyLockedTokens_Token_address_ERC20();
    error Error_No_Reentrancy();
    error Error_Invalid_StakingAdapter_Address();
    error Error_Global_Unmaterialized_Rewards_Not_Initialized();
    error Error_Too_High_Materialized_Reward();
    error Error_Only_Non_Autocompound();
    error Error_Only_If_Dynamic_Staking();
    error Error_Only_Controller_Authorized();
    error Error_Utilization_Levels_Not_Strictly_Ascendant();
    error Error_Rates_Levels_Not_Strictly_Descendant();
    error Error_Fixed_Staking_Has_One_Rate_Only();
    error Error_Not_Equal_Rates_Length();
    error Error_Not_Valid_Rates_Length();
    error Error_Cannot_Withdraw_Before_Lock_Period_Elapsed_Or_If_Not_Staked();
    error Error_Interaction_Not_Enabled();
    error Error_No_More_Than_Hundred_Percent_Rate();
    error Error_No_Fee_Value();
    error Error_Controller_Get_Rewards();
    error Error_Rewards_For_Product_Out_Of_Stock(address due_to,uint256 ExpectedReward,uint256 ActualReward);

    // Modifier
    /**
     * @dev Prevents reentrancy
     */
    modifier noReentrant() {
        if (locked){ revert Error_No_Reentrancy(); }
        locked = true;
        _;
        locked = false; }


    modifier onlyAfterStaked(){
        // cannot unstake without having staked
        if (stakeTime[msg.sender] == 0 ){ revert Error_Not_Staked_Yet();}
        _;
    }

    modifier onlyWhitelisted(){
        if (isBlacklisted[msg.sender]){ revert Error_Blacklisted_User();}
        _;
    }
    
    // since this is added to each payable function using 
    // "address(this).balance" is preferable than "msg.value",
    // since it enforces the balance to be clean
    // by eventual division residuals at each time
    modifier onlyWhenInteractionEnabled(bool withEnd){  
        if (block.timestamp < startTime || ( withEnd && stopTime != 0 && block.timestamp > stopTime)){ revert Error_Interaction_Not_Enabled();}

        (uint add3TxFee,address add3wallet) = getFeeStrategy();
        (bool sentAdd3, uint feeToAdd3) = sendToAdd3(add3TxFee,add3wallet);
        uint feeToPrivileged = address(this).balance;
        if (!sentAdd3 || feeToAdd3 == 0){ revert Error_No_Fee_Sent_To_Add3();}
            (bool sentPrivileged, ) = payable(privilegedAddressObj.getPrivilegedAddress()).call{value: feeToPrivileged}("Fee_Owner");
            if (!sentPrivileged){ revert Error_No_Fee_Sent_To_Privileged_Address();}
        _;
    }

    modifier feeReturner(){
        (,address add3wallet) = getFeeStrategy();
        (bool sentAdd3,uint feeToAdd3) = sendToAdd3(ExtraLib.PERCENT_DIVISOR,add3wallet);
        if (!sentAdd3 || feeToAdd3 == 0){ revert Error_No_Fee_Sent_To_Add3();}
        _;
    }

    function sendToAdd3(uint add3Fee, address add3) internal returns(bool sentAdd3,uint feeToAdd3){
        uint256 ethInputFee = Controller.getEthInputFee();
        // Refund if user sent more than it should
        if (msg.value > ethInputFee) {
            uint256 refundAmount = msg.value - ethInputFee;

            // Transfer the refund amount to the sender
            (bool refunded,) = payable(msg.sender).call{value: refundAmount}("");

            // Emit the refund event
            if (refunded) {
                emit Refund(msg.sender, refundAmount);
            }
        }
        if (address(this).balance < ethInputFee ){ revert Error_No_Fee_Value();}
        feeToAdd3 = address(this).balance * add3Fee / ExtraLib.PERCENT_DIVISOR;
        (sentAdd3,) = payable(add3).call{value: feeToAdd3}("FeeAdd3");
    }

    modifier onlyController(){
        if ( msg.sender != address(Controller)){ revert Error_Only_Controller_Authorized();}
        _;
    }

    modifier minMaxStake(uint amount ){
        if (( maxStake != 0 && amount > maxStake ) || (minStake != 0 && amount < minStake)){ revert Error_Oustide_Stake_Range();}
        _;
    }

    modifier onlyOwner{if (msg.sender!=privilegedAddressObj.getPrivilegedAddress()){ revert Error_Only_Owner(); } _;}

    modifier onlyAuthorizedSetStakingAdapter(address stakingAdapter, uint256 deadline,bytes32 _typehash, bytes memory signature) {
        address privilegedOwner = privilegedAddressObj.getPrivilegedAddress();
        processSignatureVerification(abi.encode(_typehash, stakingAdapter, privilegedOwner,nonces[privilegedOwner],deadline), signature, deadline, privilegedOwner);
        _; }

    modifier onlyAuthorizedBlackOrWhiteList(address recipient, bool toBlackList, uint deadline, bytes32 _typehash, bytes memory signature){
        address privilegedOwner = privilegedAddressObj.getPrivilegedAddress();
        processSignatureVerification(abi.encode(_typehash, recipient, toBlackList, privilegedOwner,nonces[privilegedOwner],deadline), signature, deadline, privilegedOwner);
        _;
    }

    modifier onlyAuthorizedSetInterestRate(uint256 apy , uint256 deadline,bytes32 _typehash, bytes memory signature) {
        // we do not do any check here , apy can be 0% or any value
        // It will fail che stake check if too high
        // 'apy' has to be provided in bps 100 bps = 1%
        address privilegedOwner = privilegedAddressObj.getPrivilegedAddress();
        processSignatureVerification(abi.encode(_typehash, apy, privilegedOwner,nonces[privilegedOwner],deadline), signature, deadline, privilegedOwner);
        _; }

    function setLocked(bool isLocked) external onlyController {
        locked = isLocked;
    }

    function getFeeStrategy() internal view returns (uint add3TxPerc , address add3address) {
        IFeeManager.FeeStrategy memory strategy = Controller.getFeeStrategy();
        add3TxPerc = strategy.add3TxFeeBps;
        add3address = strategy.add3;
    }

    function _harvestRewardsFromVault(uint256 rewards) internal virtual returns(uint256 realRewards) {
        uint availableHarvest = rewards< Controller.productReward(address(this)) ? rewards : Controller.productReward(address(this));
        if (availableHarvest < rewards) { 
            emit RewardsOutOfStock(msg.sender, rewards);
            revert Error_Rewards_For_Product_Out_Of_Stock(msg.sender,rewards,availableHarvest);
        }

        realRewards = controllerGetRewards(availableHarvest);
        
        emit RewardHarvested(msg.sender, realRewards);
    }

    function getOutputFromInput( uint inputAmount, bool isOutputRewardToken) internal view returns (uint){
        if (!isRewardSameToken){
            return Controller.getDataForQuote(address(this),inputAmount,isOutputRewardToken);
        }
        return inputAmount;
    }

    function controllerGetRewards(uint256 amount) internal returns (uint256){
        try Controller.claimReward( amount) returns(uint256 rewards ) { return rewards; }
        catch (bytes memory) { revert Error_Controller_Get_Rewards(); }
    }

// does not need other modifiers than noReentrant since "_harvestAndWithdrawRewards" has them yet, so implicitly they are set yet
    function _withdrawAll(uint256 minRewards) internal {
        uint256 amountRewards = _harvestAndWithdrawRewards(minRewards);
        uint256 amount = balanceOf(msg.sender) ;
        
        _withdrawLogic(amount);    
            // subtract from contractRewardsBalance
        emit TokensWithdrawn(msg.sender, amount , amountRewards); 
    }
    function harvestAndWithdrawRewards(uint256 minRewards) payable noReentrant external virtual returns (uint ) {
        return _harvestAndWithdrawRewards(minRewards);
    } 
    
    function autoCompoundAccounting(uint rewards) internal returns(uint ){
        if (!itAutocompounds){
            contractRewardsBalance += rewards;
            rewardsBalance[msg.sender] += rewards;
            return 0;
        } else { return rewards;}
    }

    function reduceAndZeroRewardsBalance()internal returns (uint){
        uint amount = rewardsBalance[msg.sender];
        contractRewardsBalance -= amount;
        rewardsBalance[msg.sender] = 0;
        return amount;
    }

    function getRewardsValue(StakingBase.DetailedBalance memory maturingBalance, HistoryEntry[] memory historyInterestRateVar,uint256 blockTimestamp,uint256 stakeTimeUser,uint256 minLockSecondsVar,bool isUser,bool isDynamicType) internal pure returns (uint ) {
        uint256 timeElapsed = blockTimestamp - maturingBalance.timestamp;
        if ( timeElapsed > 0){
            { // scope to avoid stack too deep errors
                uint256 timeFromStakeToMinLock = stakeTimeUser + minLockSecondsVar;
                if (isUser && !isDynamicType && maturingBalance.timestamp >= timeFromStakeToMinLock ){
                    timeElapsed = 0;
                }
                // maturingBalance between stakeTime and timeFromStakeToMinLock
                // timeElapsed should use timeFromStakeToMinLock as reference
                else if (isUser && !isDynamicType && blockTimestamp > timeFromStakeToMinLock ){
                    timeElapsed = timeFromStakeToMinLock - maturingBalance.timestamp;
                }
            }
            uint256 rate = historyInterestRateVar[historyInterestRateVar.length-1].value * timeElapsed;
            
            if (isDynamicType && maturingBalance.interestHistoryIndex < historyInterestRateVar.length-1){
            uint256 dCumulated = 0;
                        // Here is used the cumulatedVaue in the HistoryEntry struct
                if (historyInterestRateVar.length-1 - maturingBalance.interestHistoryIndex >= 2){
                    dCumulated = historyInterestRateVar[historyInterestRateVar.length -1].cumulatedValue - historyInterestRateVar[maturingBalance.interestHistoryIndex+1].cumulatedValue;
                }
                rate = historyInterestRateVar[maturingBalance.interestHistoryIndex].value*(historyInterestRateVar[maturingBalance.interestHistoryIndex+1].timestamp - maturingBalance.timestamp) + historyInterestRateVar[historyInterestRateVar.length -1].value * (blockTimestamp - historyInterestRateVar[historyInterestRateVar.length -1].timestamp) + dCumulated;
            }
            return (maturingBalance.value * rate)/ (uint256(ExtraLib.SECONDS_PER_YEAR) * uint256(ExtraLib.PERCENT_DIVISOR));
        }else{
            return 0; // no time elapsed since last balance update -> no reward gained
        }

    }

    function blackListAddress(address recipient, uint deadline, bytes memory signature) noReentrant external payable feeReturner onlyAuthorizedBlackOrWhiteList(recipient, true, deadline, ExtraLib._BLACK_OR_WHITE_LIST_TYPEHASH, signature) {
        if (isBlacklisted[recipient]){ revert Error_Already_In_Desired_List_State();}
        isBlacklisted[recipient] = true;
    }

    function whiteListAddress(address recipient, uint deadline, bytes memory signature) noReentrant external payable feeReturner onlyAuthorizedBlackOrWhiteList(recipient, false, deadline, ExtraLib._BLACK_OR_WHITE_LIST_TYPEHASH, signature) {
        if (!isBlacklisted[recipient]){ revert Error_Already_In_Desired_List_State();}
        isBlacklisted[recipient] = false;
    }

    /// @dev Transfer accidentally locked ERC20 tokens.
    /// @param token - ERC20 token address.
    /// @param amount of ERC20 tokens to remove.
    function transferAccidentallyLockedTokens(address token, uint256 amount) public noReentrant onlyOwner payable feeReturner {
        // This function can not access the official timelocked tokens; just other random ERC20 tokens that may have been accidently sent here
        if(IERC20Upgradeable(token) == erc20StakingToken){ revert Error_transferAccidentallyLockedTokens_Token_address_ERC20(); }
        // Transfer the amount of the specified ERC20 tokens, to the owner of this contract
        IERC20Upgradeable(token).safeTransfer(msg.sender, amount);}

    function supportsInterface(bytes4 interfaceId) external virtual view returns (bool);

}

// SPDX-License-Identifier: BSL-1.1

// Copyright (c)
// All rights reserved.

// This software is released under the Business Source License 1.1.
// For full license terms, see the LICENSE file.

// WARNING this contract has not been independently tested or audited
// DO NOT use this contract with funds of real value until officially tested and audited by an independent expert or group

/// @title Staking Contract interface 

pragma solidity ^0.8.19;

/// @author Add3 Augusto
import "../extensions/implementations/StakingBase.sol";

library ExtraLib {
    uint256 public constant PERCENT_DIVISOR = 10000;
    uint256 public constant MAX_INT = 2**256 - 1;
    uint256 public constant SECONDS_PER_YEAR = 31536000;
    bytes32 public constant _SET_INTEREST_RATE_TYPEHASH = keccak256("SetInterestRate(uint256 apy,address _owner,uint256 nonce,uint256 deadline)");
    bytes32 public constant _BLACK_OR_WHITE_LIST_TYPEHASH = keccak256("BlackOrWhitelistAddress(address recipient,bool toBlacklist,address _owner,uint256 nonce,uint256 deadline)");
}