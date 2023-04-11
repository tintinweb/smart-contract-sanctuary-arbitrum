// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Denominations {
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

  // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
  address public constant USD = address(840);
  address public constant GBP = address(826);
  address public constant EUR = address(978);
  address public constant JPY = address(392);
  address public constant KRW = address(410);
  address public constant CNY = address(156);
  address public constant AUD = address(36);
  address public constant CAD = address(124);
  address public constant CHF = address(756);
  address public constant ARS = address(32);
  address public constant PHP = address(608);
  address public constant NZD = address(554);
  address public constant SGD = address(702);
  address public constant NGN = address(566);
  address public constant ZAR = address(710);
  address public constant RUB = address(643);
  address public constant INR = address(356);
  address public constant BRL = address(986);
}

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
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./AggregatorV2V3Interface.sol";

interface FeedRegistryInterface {
  struct Phase {
    uint16 phaseId;
    uint80 startingAggregatorRoundId;
    uint80 endingAggregatorRoundId;
  }

  event FeedProposed(
    address indexed asset,
    address indexed denomination,
    address indexed proposedAggregator,
    address currentAggregator,
    address sender
  );
  event FeedConfirmed(
    address indexed asset,
    address indexed denomination,
    address indexed latestAggregator,
    address previousAggregator,
    uint16 nextPhaseId,
    address sender
  );

  // V3 AggregatorV3Interface

  function decimals(address base, address quote) external view returns (uint8);

  function description(address base, address quote) external view returns (string memory);

  function version(address base, address quote) external view returns (uint256);

  function latestRoundData(address base, address quote)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function getRoundData(
    address base,
    address quote,
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // V2 AggregatorInterface

  function latestAnswer(address base, address quote) external view returns (int256 answer);

  function latestTimestamp(address base, address quote) external view returns (uint256 timestamp);

  function latestRound(address base, address quote) external view returns (uint256 roundId);

  function getAnswer(
    address base,
    address quote,
    uint256 roundId
  ) external view returns (int256 answer);

  function getTimestamp(
    address base,
    address quote,
    uint256 roundId
  ) external view returns (uint256 timestamp);

  // Registry getters

  function getFeed(address base, address quote) external view returns (AggregatorV2V3Interface aggregator);

  function getPhaseFeed(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (AggregatorV2V3Interface aggregator);

  function isFeedEnabled(address aggregator) external view returns (bool);

  function getPhase(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (Phase memory phase);

  // Round helpers

  function getRoundFeed(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (AggregatorV2V3Interface aggregator);

  function getPhaseRange(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (uint80 startingRoundId, uint80 endingRoundId);

  function getPreviousRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (uint80 previousRoundId);

  function getNextRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (uint80 nextRoundId);

  // Feed management

  function proposeFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  function confirmFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  // Proposed aggregator

  function getProposedFeed(address base, address quote)
    external
    view
    returns (AggregatorV2V3Interface proposedAggregator);

  function proposedGetRoundData(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function proposedLatestRoundData(address base, address quote)
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // Phases
  function getCurrentPhaseId(address base, address quote) external view returns (uint16 currentPhaseId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../libraries/UnboundMath.sol";

import '../interfaces/IUNDToken.sol';
import '../interfaces/ISortedAccounts.sol';
import '../interfaces/IMainPool.sol';
import '../interfaces/IUnboundBase.sol';
import '../interfaces/IUnboundFeesFactory.sol';
import '../interfaces/ICollSurplusPool.sol';

contract UnboundBase is IUnboundBase{

    uint256 public constant DECIMAL_PRECISION = 1e18;

    // Minimum collateral ratio for individual accounts
    uint256 public override MCR; // 1e18 is 100%

    // Minimum amount of net UND debt a account must have
    uint256 constant public MIN_NET_DEBT = 50e18; //100 UND - 100e18

    ISortedAccounts public override sortedAccounts;
    IUNDToken public override undToken;
    IERC20 public override depositToken;
    IMainPool public override mainPool;

    IUnboundFeesFactory public override unboundFeesFactory;

    ICollSurplusPool public override collSurplusPool;

    function getEntireSystemColl() public view returns (uint256 entireSystemColl) {
        entireSystemColl = mainPool.getCollateral();
    }

    function getEntireSystemDebt() public view returns (uint256 entireSystemDebt) {
        entireSystemDebt = mainPool.getUNDDebt();
    }

    function BORROWING_FEE_FLOOR() public view returns (uint256 borrowingFeeFloor) {
        borrowingFeeFloor = unboundFeesFactory.BORROWING_FEE_FLOOR();
    }

    function REDEMPTION_FEE_FLOOR() public view returns (uint256 redemptionFeeFloor) {
        redemptionFeeFloor = unboundFeesFactory.REDEMPTION_FEE_FLOOR();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import './base/UnboundBase.sol';

import './interfaces/IAccountManager.sol';
import './interfaces/IBorrowoperations.sol';

import './libraries/UniswapV2PriceProvider.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

// BorrowOperations - add collatreral, remove collaral, mint UND, repay UND, 
contract BorrowOperations is UnboundBase, IBorrowoperations, Initializable {

    using SafeERC20 for IERC20;

    IAccountManager public accountManager;

    address public override governanceFeeAddress;

    struct ContractsCache {
        IAccountManager accountManager;
        IMainPool mainPool;
        IERC20 depositToken;
        IUNDToken undToken;
        IUnboundFeesFactory unboundFeesFactory;
        address governanceFeeAddress;
    }

    struct LocalVariables_openAccount {
        uint price;
        uint UNDFee;
        uint netDebt;
        uint ICR;
        uint NICR;
        uint arrayIndex;
    }

    /* --- Variable container structs  ---

    Used to hold, return and assign variables inside a function, in order to avoid the error:
    "CompilerError: Stack too deep". */

     struct LocalVariables_adjustAccount {
        uint price;
        uint collChange;
        uint netDebtChange;
        bool isCollIncrease;
        uint debt;
        uint coll;
        uint oldICR;
        uint newICR;
        uint UNDFee;
        uint newDebt;
        uint newColl;
    }

    function initialize (
        address _accountManager
    ) 
        public 
        initializer
    {
        accountManager = IAccountManager(_accountManager);
        undToken = accountManager.undToken();
        sortedAccounts = accountManager.sortedAccounts();
        depositToken = accountManager.depositToken();
        mainPool = accountManager.mainPool();
        unboundFeesFactory = accountManager.unboundFeesFactory();
        collSurplusPool = accountManager.collSurplusPool();
        governanceFeeAddress = accountManager.governanceFeeAddress();
        MCR = accountManager.MCR();
    }

    function openAccount(uint256 _maxFeePercentage, uint256 _collAmount, uint256 _UNDAmount, address _upperHint, address _lowerHint) external override {
        ContractsCache memory contractsCache = ContractsCache(accountManager, mainPool, depositToken, undToken, unboundFeesFactory, governanceFeeAddress);
        LocalVariables_openAccount memory vars;

        // check if fee percentage is valid
        _requireValidMaxFeePercentage(_maxFeePercentage);

        // check if account is already created or not
        _requireAccountisNotActive(contractsCache.accountManager, msg.sender);

        // get price of pool token from oracle
        vars.price = uint256 (UniswapV2PriceProvider.latestAnswer(contractsCache.accountManager));

        vars.UNDFee;
        vars.netDebt = _UNDAmount;

        vars.UNDFee = _triggerBorrowingFee(contractsCache.unboundFeesFactory, contractsCache.undToken, _UNDAmount, _maxFeePercentage, contractsCache.governanceFeeAddress);
        vars.netDebt = vars.netDebt + vars.UNDFee;

        _requireAtLeastMinNetDebt(vars.netDebt);
        _requireMaxUNDMintLimitNotReached(contractsCache.mainPool, vars.netDebt);

        // ICR is based on the net debt, i.e. the requested UND amount + UND borrowing fee.
        vars.ICR = UnboundMath._computeCR(_collAmount, vars.netDebt, vars.price);
        vars.NICR = UnboundMath._computeNominalCR(_collAmount, vars.netDebt);

        _requireICRisAboveMCR(vars.ICR);

        // Set the account struct's properties
        contractsCache.accountManager.setAccountStatus(msg.sender, 1);
        contractsCache.accountManager.increaseAccountColl(msg.sender, _collAmount);
        contractsCache.accountManager.increaseAccountDebt(msg.sender, vars.netDebt);

        sortedAccounts.insert(msg.sender, vars.NICR, _upperHint, _lowerHint);
        vars.arrayIndex = contractsCache.accountManager.addAccountOwnerToArray(msg.sender);
        emit AccountCreated(msg.sender, vars.arrayIndex);

        // Move the LP collateral to the this contract, and mint the UNDAmount to the borrower
        _mainPoolAddColl(contractsCache.depositToken, contractsCache.mainPool, _collAmount);

        //stake collaterar to farming contract for rewards
        contractsCache.mainPool.stake(msg.sender, _collAmount);

        _withdrawUND(contractsCache.mainPool, contractsCache.undToken, msg.sender, _UNDAmount, vars.netDebt);

        emit AccountUpdated(msg.sender, vars.netDebt, _collAmount, BorrowerOperation.openAccount);
        emit UNDBorrowingFeePaid(msg.sender, vars.UNDFee);

    }

    // Send LP token as collateral to a account
    function addColl(uint256 _collDeposit, address _upperHint, address _lowerHint) external override {
        _adjustAccount(msg.sender, _collDeposit, 0, 0, false, _upperHint, _lowerHint, 0);
    }

    // Withdraw LP token collateral from a account
    function withdrawColl(uint _collWithdrawal, address _upperHint, address _lowerHint) external override {
        _adjustAccount(msg.sender, 0, _collWithdrawal, 0, false, _upperHint, _lowerHint, 0);
    }

    // Withdraw UND tokens from a account: mint new UND tokens to the owner, and increase the account's debt accordingly
    function withdrawUND(uint _maxFeePercentage, uint _UNDAmount, address _upperHint, address _lowerHint) external override {
        _adjustAccount(msg.sender, 0, 0, _UNDAmount, true, _upperHint, _lowerHint, _maxFeePercentage);
    }

    // Repay UND tokens to a Account: Burn the repaid UND tokens, and reduce the account's debt accordingly
    function repayUND(uint _UNDAmount, address _upperHint, address _lowerHint) external override {
        _adjustAccount(msg.sender, 0, 0, _UNDAmount, false, _upperHint, _lowerHint, 0);
    }

    function adjustAccount(uint _maxFeePercentage, uint256 _collDeposit, uint _collWithdrawal, uint _UNDChange, bool _isDebtIncrease, address _upperHint, address _lowerHint) external override {
        _adjustAccount(msg.sender, _collDeposit, _collWithdrawal, _UNDChange, _isDebtIncrease, _upperHint, _lowerHint, _maxFeePercentage);
    }

    /*
    * _adjustAccount(): Alongside a debt change, this function can perform either a collateral top-up or a collateral withdrawal. 
    *
    * It therefore expects either a positive msg.value, or a positive _collWithdrawal argument.
    *
    * If both are positive, it will revert.
    */
    function _adjustAccount(address _borrower, uint256 _collDeposit, uint _collWithdrawal, uint _UNDChange, bool _isDebtIncrease, address _upperHint, address _lowerHint, uint _maxFeePercentage) internal {
        ContractsCache memory contractsCache = ContractsCache(accountManager, mainPool, depositToken, undToken, unboundFeesFactory, governanceFeeAddress);
        LocalVariables_adjustAccount memory vars;

        // get price of pool token from oracle
        vars.price = uint256 (UniswapV2PriceProvider.latestAnswer(contractsCache.accountManager));

        if (_isDebtIncrease) {
            _requireValidMaxFeePercentage(_maxFeePercentage);
            _requireNonZeroDebtChange(_UNDChange);
        }
        _requireSingularCollChange(_collDeposit, _collWithdrawal);
        _requireNonZeroAdjustment(_collDeposit, _collWithdrawal, _UNDChange);
        _requireAccountisActive(contractsCache.accountManager, _borrower);

        // Get the collChange based on whether or not Coll was sent in the transaction
        (vars.collChange, vars.isCollIncrease) = _getCollChange(_collDeposit, _collWithdrawal);

        vars.netDebtChange = _UNDChange;

        // If the adjustment incorporates a debt increase, then trigger a borrowing fee
        if (_isDebtIncrease) { 
            vars.UNDFee = _triggerBorrowingFee(contractsCache.unboundFeesFactory, contractsCache.undToken, _UNDChange, _maxFeePercentage, contractsCache.governanceFeeAddress);
            vars.netDebtChange = vars.netDebtChange + vars.UNDFee; // The raw debt change includes the fee
            _requireMaxUNDMintLimitNotReached(contractsCache.mainPool, vars.netDebtChange);
        }

        vars.debt = contractsCache.accountManager.getAccountDebt(_borrower);
        vars.coll = contractsCache.accountManager.getAccountColl(_borrower);
        
        _requireValidCollWithdrawal(_collWithdrawal, vars.coll);

        // When the adjustment is a debt repayment, check it's a valid amount and that the caller has enough UND
        if (!_isDebtIncrease && _UNDChange > 0) {
            _requireValidUNDRepayment(vars.debt, vars.netDebtChange);
            _requireAtLeastMinNetDebt(vars.debt - vars.netDebtChange);
            _requireSufficientUNDBalance(contractsCache.undToken, _borrower, vars.netDebtChange);
        }

        // Get the account's old ICR before the adjustment, and what its new ICR will be after the adjustment
        vars.oldICR = UnboundMath._computeCR(vars.coll, vars.debt, vars.price);
        vars.newICR = _getNewICRFromAccountChange(vars.coll, vars.debt, vars.collChange, vars.isCollIncrease, vars.netDebtChange, _isDebtIncrease, vars.price);

        // Check the adjustment satisfies all conditions
        _requireICRisAboveMCR(vars.newICR);
        // _requireValidAdjustment(_isDebtIncrease, vars);

        (vars.newColl, vars.newDebt) = _updateAccountFromAdjustment(contractsCache.accountManager, _borrower, vars.collChange, vars.isCollIncrease, vars.netDebtChange, _isDebtIncrease);
        
        // Re-insert account in to the sorted list
        uint newNICR = UnboundMath._computeNominalCR(vars.newColl, vars.newDebt);
        sortedAccounts.reInsert(_borrower, newNICR, _upperHint, _lowerHint);

        emit AccountUpdated(_borrower, vars.newDebt, vars.newColl, BorrowerOperation.adjustAccount);
        emit UNDBorrowingFeePaid(msg.sender,  vars.UNDFee);

        // Use the unmodified _UNDChange here, as we don't send the fee to the user
        _moveTokensAndCollateralfromAdjustment(
            contractsCache.depositToken,
            contractsCache.mainPool,
            contractsCache.undToken,
            msg.sender,
            vars.collChange,
            vars.isCollIncrease,
            _UNDChange,
            _isDebtIncrease,
            vars.netDebtChange
        );
    }

    function closeAccount() external override {
        ContractsCache memory contractsCache = ContractsCache(accountManager, mainPool, depositToken, undToken, unboundFeesFactory, governanceFeeAddress);

        _requireAccountisActive(contractsCache.accountManager, msg.sender);

        // accountManagerCached.applyPendingRewards(msg.sender);

        uint coll = contractsCache.accountManager.getAccountColl(msg.sender);
        uint debt = contractsCache.accountManager.getAccountDebt(msg.sender);

        _requireSufficientUNDBalance(contractsCache.undToken, msg.sender, debt);

        // accountManagerCached.removeStake(msg.sender);
        contractsCache.accountManager.closeAccount(msg.sender);

        emit AccountUpdated(msg.sender, 0, 0, BorrowerOperation.closeAccount);

        // Burn the repaid UND from the user's balance
        _repayUND(contractsCache.mainPool, contractsCache.undToken, msg.sender, debt);

        // unstake collateral from farming contract
        contractsCache.mainPool.unstake(msg.sender, coll);

        // Send the collateral back to the user
        contractsCache.mainPool.sendCollateral(contractsCache.depositToken, msg.sender, coll);
    }

    /**
     * Claim remaining collateral from a redemption
     */
    function claimCollateral() external override {
        // send ETH from CollSurplus Pool to owner
        collSurplusPool.claimColl(depositToken, msg.sender);
    }

    /**
     * Return Unbound Fees Factory contract address (to validate minter in UND contract)
     */
    function factory() external override view returns(address){
        return address(unboundFeesFactory);
    }

    /**
     * Return Collateral Price in USD, for UI
     */
    function getCollPrice() external view returns(uint256){
        return uint256 (UniswapV2PriceProvider.latestAnswer(accountManager));
    }

    // --- Helper functions ---

    function _triggerBorrowingFee(IUnboundFeesFactory _unboundFeesFactory, IUNDToken _undToken, uint _UNDAmount, uint _maxFeePercentage, address safu) internal returns (uint) {
        _unboundFeesFactory.decayBaseRateFromBorrowing(); // decay the baseRate state variable
        uint UNDFee = _unboundFeesFactory.getBorrowingFee(_UNDAmount);

        _requireUserAcceptsFee(UNDFee, _UNDAmount, _maxFeePercentage);
        
        // Send fees to governance fee address address
        _undToken.mint(safu, UNDFee);

        return UNDFee;
    }

    function _getCollChange(
        uint _collReceived,
        uint _requestedCollWithdrawal
    )
        internal
        pure
        returns(uint collChange, bool isCollIncrease)
    {
        if (_collReceived != 0) {
            collChange = _collReceived;
            isCollIncrease = true;
        } else {
            collChange = _requestedCollWithdrawal;
        }
    }

    // Update account's coll and debt based on whether they increase or decrease
    function _updateAccountFromAdjustment
    (
        IAccountManager _accountManager,
        address _borrower,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease
    )
        internal
        returns (uint, uint)
    {
        uint newColl = (_isCollIncrease) ? _accountManager.increaseAccountColl(_borrower, _collChange)
                                        : _accountManager.decreaseAccountColl(_borrower, _collChange);
        uint newDebt = (_isDebtIncrease) ? _accountManager.increaseAccountDebt(_borrower, _debtChange)
                                        : _accountManager.decreaseAccountDebt(_borrower, _debtChange);

        return (newColl, newDebt);
    }

    function _moveTokensAndCollateralfromAdjustment
    (
        IERC20 _depositToken,
        IMainPool _mainPool,
        IUNDToken _undToken,
        address _borrower,
        uint _collChange,
        bool _isCollIncrease,
        uint _UNDChange,
        bool _isDebtIncrease,
        uint _netDebtChange
    )
        internal
    {
        if (_isDebtIncrease) {
            _withdrawUND(_mainPool, _undToken, _borrower, _UNDChange, _netDebtChange);
        } else {
            _repayUND(_mainPool, _undToken, _borrower, _UNDChange);
        }

        if (_isCollIncrease) {
            _mainPoolAddColl(_depositToken, _mainPool, _collChange);
            _mainPool.stake(_borrower, _collChange);
        } else {
            _mainPool.unstake(_borrower, _collChange);
            _mainPool.sendCollateral(_depositToken, _borrower, _collChange);
        }
    }

    // Send Collateral from user to this contract and increase its recorded Collateral balance
    function _mainPoolAddColl(IERC20 _depositToken, IMainPool _mainPool, uint _amount) internal {
        
        // transfer tokens from user to mainPool contract
        _depositToken.safeTransferFrom(msg.sender, address(_mainPool), _amount);
        
        _mainPool.increaseCollateral(_amount);
    }

    // Issue the specified amount of UND to _account and increases the total active debt (_netDebtIncrease potentially includes a UNDFee)
    function _withdrawUND(IMainPool _mainPool, IUNDToken _undToken, address _account, uint _UNDAmount, uint _netDebtIncrease) internal {
        _mainPool.increaseUNDDebt(_netDebtIncrease);
        _undToken.mint(_account, _UNDAmount);
    }

    // Burn the specified amount of UND from _account and decreases the total active debt
    function _repayUND(IMainPool _mainPool, IUNDToken _undToken, address _account, uint _UND) internal {
        _mainPool.decreaseUNDDebt(_UND);
        _undToken.burn(_account, _UND);
    }

    // --- 'Require' wrapper functions ---

    function _requireSingularCollChange(uint256 _collDeposit, uint256 _collWithdrawal) internal pure {
        require(_collDeposit == 0 || _collWithdrawal == 0, "BorrowerOperations: Cannot withdraw and add coll");
    }

    function _requireNonZeroAdjustment(uint256 _collDeposit, uint256 _collWithdrawal, uint256 _UNDChange) internal pure {
        require(_collDeposit != 0 || _collWithdrawal != 0 || _UNDChange != 0, "BorrowerOps: There must be either a collateral change or a debt change");
    }

    function _requireICRisAboveMCR(uint _newICR) internal view {
        require(_newICR >= MCR, "BorrowerOps: An operation that would result in ICR < MCR is not permitted");
    }

    function _requireAtLeastMinNetDebt(uint _netDebt) internal pure {
        require (_netDebt >= MIN_NET_DEBT, "BorrowerOps: Account's net debt must be greater than minimum");
    }

    function _requireValidUNDRepayment(uint _currentDebt, uint _debtRepayment) internal pure {
        require(_debtRepayment <= _currentDebt, "BorrowerOps: Amount repaid must not be larger than the Account's debt");
    }

    function _requireValidCollWithdrawal(uint _collWithdraw, uint _currentColl) internal pure {
        require(_collWithdraw <= _currentColl, "BorrowerOps: Account collateral withdraw amount can not be greater than current collateral amount");
    }

    function _requireAccountisActive(IAccountManager _accountManager, address _borrower) internal view {
        uint status = _accountManager.getAccountStatus(_borrower);
        require(status == 1, "BorrowerOps: Account does not exist or is closed");
    }

    function _requireSufficientUNDBalance(IUNDToken _undToken, address _borrower, uint _debtRepayment) internal view {
        require(_undToken.balanceOf(_borrower) >= _debtRepayment, "BorrowerOps: Caller doesnt have enough UND to make repayment");
    }

    function _requireAccountisNotActive(IAccountManager _accountManager, address _borrower) internal view {
        uint status = _accountManager.getAccountStatus(_borrower);
        require(status != 1, "BorrowerOps: Account is active");
    }

    function _requireUserAcceptsFee(uint _fee, uint _amount, uint _maxFeePercentage) internal pure {
        uint feePercentage = (_fee * DECIMAL_PRECISION) / _amount;
        require(feePercentage <= _maxFeePercentage, "BorrowerOps: Fee exceeded provided maximum");
    }

    function _requireNonZeroDebtChange(uint _UNDChange) internal pure {
        require(_UNDChange > 0, "BorrowerOps: Debt increase requires non-zero debtChange");
    }

    function _requireValidMaxFeePercentage(uint _maxFeePercentage) internal view {
        require(_maxFeePercentage >= BORROWING_FEE_FLOOR() && _maxFeePercentage <= DECIMAL_PRECISION,
            "BorrowerOps: Max fee percentage must be between 0.5% and 100%");
    }

    function _requireMaxUNDMintLimitNotReached(IMainPool _mainPool, uint256 _UNDChange) internal view {
        uint256 currentDebt = getEntireSystemDebt();
        uint256 mintLimit = _mainPool.undMintLimit();
        require(currentDebt + _UNDChange <= mintLimit, "BorrowerOps: UND max mint limit reached");
    }

    // --- ICR getters ---

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewICRFromAccountChange
    (
        uint _coll,
        uint _debt,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease,
        uint _price
    )
        pure
        internal
        returns (uint)
    {
        (uint newColl, uint newDebt) = _getNewAccountAmounts(_coll, _debt, _collChange, _isCollIncrease, _debtChange, _isDebtIncrease);

        uint newICR = UnboundMath._computeCR(newColl, newDebt, _price);
        return newICR;
    }

    function _getNewAccountAmounts(
        uint _coll,
        uint _debt,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease
    )
        internal
        pure
        returns (uint, uint)
    {
        uint newColl = _coll;
        uint newDebt = _debt;

        newColl = _isCollIncrease ? _coll  + _collChange :  _coll - _collChange;
        newDebt = _isDebtIncrease ? _debt + _debtChange : _debt - _debtChange;

        return (newColl, newDebt);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IUnboundBase.sol";
interface IAccountManager is IUnboundBase{

    enum AccountManagerOperation {
        liquidation,
        redeemCollateral
    }
    
    event AccountIndexUpdated(address _borrower, uint _newIndex);
    event AccountUpdated(address indexed _borrower, uint _debt, uint _coll, AccountManagerOperation _operation);
    event Redemption(uint _attemptedUNDAmount, uint _actualUNDAmount, uint _CollateralSent, uint _CollateralFee);
    event AccountLiquidated(address indexed _borrower, uint _debt, uint _coll, AccountManagerOperation _operation);
    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _liquidationCompensation);

    function borrowerOperations() external view returns(address);
    
    function maxPercentDiff() external view returns (uint256);
    function allowedDelay() external view returns (uint256);

    function governanceFeeAddress() external view returns (address);

    function chainLinkRegistry() external view returns (address);

    function getAccountOwnersCount() external view returns (uint);
    function getAccountFromAccountOwnersArray(uint256 _index) external view returns (address);

    function getAccountStatus(address _borrower) external view returns (uint);
    function getAccountDebt(address _borrower) external view returns (uint);
    function getAccountColl(address _borrower) external view returns (uint);
    function getEntireDebtAndColl(address _borrower) external view returns(uint256 debt, uint256 coll);

    function getNominalICR(address _borrower) external view returns (uint);
    function getCurrentICR(address _borrower, uint _price) external view returns (uint);
    
    function setAccountStatus(address _borrower, uint _num) external;
    function increaseAccountColl(address _borrower, uint _collIncrease) external returns (uint);
    function decreaseAccountColl(address _borrower, uint _collDecrease) external returns (uint);
    function increaseAccountDebt(address _borrower, uint _debtIncrease) external returns (uint);
    function decreaseAccountDebt(address _borrower, uint _debtDecrease) external returns (uint);
    
    function addAccountOwnerToArray(address _borrower) external returns (uint index);

    function closeAccount(address _borrower) external;

    function redeemCollateral(
        uint _UNDamount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFeePercentage
    ) external;

    function liquidate(address _borrower) external;

    function liquidateAccounts(uint _n) external;
    
    function batchLiquidateAccounts(address[] memory _accountArray) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./IUnboundBase.sol";
interface IBorrowoperations is IUnboundBase{

    enum BorrowerOperation {
        openAccount,
        closeAccount,
        adjustAccount
    }

    event AccountCreated(address indexed _borrower, uint arrayIndex);
    event AccountUpdated(address indexed _borrower, uint _debt, uint _coll, BorrowerOperation operation);
    event UNDBorrowingFeePaid(address indexed _borrower, uint _UNDFee);

    function governanceFeeAddress() external view returns (address);
    function factory() external view returns(address);

    function openAccount(uint256 _maxFeePercentage, uint256 _colAmount, uint256 _UNDAmount, address _upperHint, address _lowerHint) external;

    function addColl(uint256 _collDeposit, address _upperHint, address _lowerHint) external;
    function withdrawColl(uint _collWithdrawal, address _upperHint, address _lowerHint) external;
    function withdrawUND(uint _maxFeePercentage, uint _UNDAmount, address _upperHint, address _lowerHint) external;
    function repayUND(uint _UNDAmount, address _upperHint, address _lowerHint) external;
    function adjustAccount(uint _maxFeePercentage, uint256 _collDeposit, uint _collWithdrawal, uint _UNDChange, bool _isDebtIncrease, address _upperHint, address _lowerHint) external;

    function closeAccount() external;

    function claimCollateral() external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.7.6;

interface IChainlinkAggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
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
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface ICollSurplusPool {

    function getTotalCollateral() external view returns (uint);

    function getUserCollateral(address _account) external view returns (uint);

    function claimColl(IERC20 _depositToken, address _account) external;

    function accountSurplus(address _account, uint _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IMainPool {

    event MainPoolCollateralUpdated(uint _amount);
    event MainPoolUNDDebtUpdated(uint _amount);
    event MainPoolCollateralBalanceUpdated(uint _amount);
    event CollateralSent(address _account, uint _amount);
    event UNDMintLimitChanged(uint _newMintLimit);



    function undMintLimit() external view returns(uint256);
    
    function increaseCollateral(uint _amount) external;
    function increaseUNDDebt(uint _amount) external;
    function decreaseUNDDebt(uint _amount) external;
    function getCollateral() external view returns (uint);

    function getUNDDebt() external view returns (uint);

    function sendCollateral(IERC20 _depositToken, address _account, uint _amount) external;

    function stake(address user, uint256 amount) external;
    function unstake(address user, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

// Common interface for the SortedAccounts Doubly Linked List.
interface ISortedAccounts {

    // --- Events ---
    
    event NodeAdded(address _id, uint _NICR);
    event NodeRemoved(address _id);

    // --- Functions ---
    
    function insert(address _id, uint256 _ICR, address _prevId, address _nextId) external;

    function remove(address _id) external;

    function reInsert(address _id, uint256 _newICR, address _prevId, address _nextId) external;

    function contains(address _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNext(address _id) external view returns (address);

    function getPrev(address _id) external view returns (address);

    function validInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (bool);

    function findInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../interfaces/IUNDToken.sol';
import '../interfaces/ISortedAccounts.sol';
import '../interfaces/IMainPool.sol';
import '../interfaces/ICollSurplusPool.sol';
import '../interfaces/IUnboundFeesFactory.sol';

interface IUnboundBase {
    function MCR() external view returns (uint256);
    function undToken() external view returns (IUNDToken);
    function sortedAccounts() external view returns (ISortedAccounts);
    function depositToken() external view returns (IERC20);
    function mainPool() external view returns (IMainPool);
    function unboundFeesFactory() external view returns (IUnboundFeesFactory);
    function collSurplusPool() external view returns (ICollSurplusPool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IUnboundFeesFactory {
    
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event AccountManagerUpdated(address _accManager, bool _status);
    event BorrowOpsUpdated(address _borrowOps, bool _status);

    function REDEMPTION_FEE_FLOOR() external view returns (uint);
    function BORROWING_FEE_FLOOR() external view returns (uint);

    function getBorrowingRate() external view returns (uint);
    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint _UNDDebt) external view returns (uint);
    function getBorrowingFeeWithDecay(uint _UNDDebt) external view returns (uint);

    function getRedemptionRate() external view returns (uint);
    function getRedemptionFee(uint _UNDDebt) external view returns (uint);
    function getRedemptionRateWithDecay() external view returns (uint);
    function getRedemptionFeeWithDecay(uint _CollateralDrawn) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function updateBaseRateFromRedemption(uint _CollateralDrawn,  uint _price, uint _totalUNDSupply) external returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IUNDToken {

    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
    function balanceOf(address _account) external view returns(uint256);
    function totalSupply() external view returns(uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

library UnboundMath {

    uint internal constant DECIMAL_PRECISION = 1e18;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
     *
     * - Making it “too high” could lead to overflows.
     * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division. 
     *
     * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 LPTs,
     * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
     *
     */
    uint internal constant NICR_PRECISION = 1e20;

    function _min(uint _a, uint _b) internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a : _b;
    }

    /* 
    * Multiply two decimal numbers and use normal rounding rules:
    * -round product up if 19'th mantissa digit >= 5
    * -round product down if 19'th mantissa digit < 5
    *
    * Used only inside the exponentiation, _decPow().
    */
    function decMul(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = x * y;

        decProd = (prod_xy + (DECIMAL_PRECISION / 2)) / DECIMAL_PRECISION;
    }

    /* 
    * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
    * 
    * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity. 
    * 
    * Called by two functions that represent time in units of minutes:
    * 1) UnboundFeesFactory._calcDecayedBaseRate
    * 2) CommunityIssuance._getCumulativeIssuanceFraction 
    * 
    * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
    * "minutes in 1000 years": 60 * 24 * 365 * 1000
    * 
    * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
    * negligibly different from just passing the cap, since: 
    *
    * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
    * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
    */
    function _decPow(uint _base, uint _minutes) internal pure returns (uint) {
       
        if (_minutes > 525600000) {_minutes = 525600000;}  // cap to avoid overflow
    
        if (_minutes == 0) {return DECIMAL_PRECISION;}

        uint y = DECIMAL_PRECISION;
        uint x = _base;
        uint n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n / 2;
            } else { // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n - 1) / 2;
            }
        }

        return decMul(x, y);
  }

    function _getAbsoluteDifference(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a - _b : _b - _a;
    }

    function _computeNominalCR(uint _coll, uint _debt) internal pure returns (uint) {
        if (_debt > 0) {
            return (_coll * NICR_PRECISION) / _debt;
        }
        // Return the maximal value for uint256 if the Account has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1;
        }
    }

    function _computeCR(uint _coll, uint _debt, uint _price) internal pure returns (uint) {
        if (_debt > 0) {
            uint newCollRatio = (_coll * _price) / _debt;

            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Account has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1; 
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

import "@chainlink/contracts/src/v0.8/Denominations.sol";

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import '../interfaces/IChainlinkAggregatorV3Interface.sol';
import '../interfaces/IAccountManager.sol';
import '../interfaces/IUnboundBase.sol';

library UniswapV2PriceProvider {

    uint256 constant BASE = 1e18;

    /**
     * @notice Returns square root using Babylon method
     * @param y value of which the square root should be calculated
     * @return z Sqrt of the y
     */
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    /**
     * Returns geometric mean of both reserves, multiplied by price of Chainlink.
     * @param _pair Address of the Uniswap V2 pair
     * @param _reserve0 reserves of the first asset
     * @param _reserve1 reserves of second asset
     * @return Geometric mean of given values
     */
    function getGeometricMean(
        address _pair,
        uint256 _reserve0,
        uint256 _reserve1
    ) internal view returns (uint256) {
        uint256 totalValue = _reserve0 * _reserve1;
        return
            (sqrt(totalValue) * uint256(2) * BASE) /  getTotalSupplyAtWithdrawal(_pair);
    }

    /**
     * Calculates the price of the pair token using the formula of arithmetic mean.
     * @param _pair Address of the Uniswap V2 pair
     * @param _reserve0 Total eth for token 0.
     * @param _reserve1 Total eth for token 1.
     * @return Arithematic mean of _reserve0 and _reserve1
     */
    function getArithmeticMean(
        address _pair,
        uint256 _reserve0,
        uint256 _reserve1
    ) internal view returns (uint256) {
        uint256 totalValue = _reserve0 + _reserve1;
        return (totalValue * BASE) / getTotalSupplyAtWithdrawal(_pair);
    }

    /**
     * @notice Returns Uniswap V2 pair total supply at the time of withdrawal.
     * @param _pair Address of the pair
     * @return totalSupply Total supply of the Uniswap V2 pair at the time user withdraws
     */
    function getTotalSupplyAtWithdrawal(address _pair)
        internal
        view
        returns (uint256 totalSupply)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(_pair);
        totalSupply = pair.totalSupply();
        address feeTo = IUniswapV2Factory(pair.factory()).feeTo();
        bool feeOn = feeTo != address(0);
        if (feeOn) {
            uint256 kLast = pair.kLast();
            if (kLast != 0) {
                (uint112 reserve_0, uint112 reserve_1, ) = pair.getReserves();
                uint256 rootK = sqrt(uint256(reserve_0) * uint256(reserve_1));
                uint256 rootKLast = sqrt(kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply * (rootK - rootKLast);
                    uint256 denominator = (rootK * 5) + rootKLast;
                    uint256 liquidity = numerator / denominator;
                    totalSupply = totalSupply + liquidity;
                }
            }
        }
    }

    /**
     * @notice Returns normalised value in 18 digits
     * @param _value Value which we want to normalise
     * @param _decimals Number of decimals from which we want to normalise
     * @return normalised Returns normalised value in 1e18 format
     */
    function normalise(uint256 _value, uint256 _decimals)
        internal
        pure
        returns (uint256 normalised)
    {
        normalised = _value;
        if (_decimals < 18) {
            uint256 missingDecimals = uint256(18) - _decimals;
            normalised = uint256(_value) * (10**(missingDecimals));
        } else if (_decimals > 18) {
            uint256 extraDecimals = _decimals - uint256(18);
            normalised = uint256(_value) / (10**(extraDecimals));
        }
    }

    /**
     * @notice Returns latest Chainlink price, and normalise it
     * @param _registry registry
     * @param _base Base Asset
     * @param _quote Quote Asset
     * @param _validPeriod period for last oracle price update
     */
    function getChainlinkPrice(
        FeedRegistryInterface _registry,
        address _base,
        address _quote,
        uint256 _validPeriod
    )
        internal
        view
        returns (uint256 price)
    {
        (, int256 _price, , uint256 updatedAt, ) = _registry.latestRoundData(_base, _quote);

        // check if the oracle is expired
        require(block.timestamp - updatedAt < _validPeriod, "OLD_PRICE");
        
        if (_price <= 0) {
            return 0;
        }

        // normalise the price to 18 decimals
        uint256 _decimals = _registry.decimals(_base, _quote);

        if (_decimals < 18) {
            uint256 missingDecimals = uint256(18) - _decimals;
            price = uint256(_price) * (10**(missingDecimals));
        } else if (_decimals > 18) {
            uint256 extraDecimals = _decimals - uint256(18);
            price = uint256(_price) / (10**(extraDecimals));
        }

        return price;
    }

    /**
     * @notice Returns reserve value in dollars
     * @param _price Chainlink Price.
     * @param _reserve Token reserves.
     * @param _decimals Number of decimals in the the reserve value
     * @return Returns normalised reserve value in 1e18
     */
    function getReserveValue(
        uint256 _price,
        uint112 _reserve,
        uint256 _decimals
    ) internal pure returns (uint256) {
        require(_price > 0, 'ERR_NO_ORACLE_PRICE');
        uint256 reservePrice = normalise(_reserve, _decimals);
        return (uint256(reservePrice) * _price) / BASE;
    }

    /**
     * @notice Returns true if there is price difference
     * @param _reserve0 Reserve value of first reserve in stablecoin.
     * @param _reserve1 Reserve value of first reserve in stablecoin.
     * @param _maxPercentDiff Maximum deviation at which geometric mean should take in effect
     * @return result True if there is different in both prices, false if not.
     */
    function hasPriceDifference(
        uint256 _reserve0,
        uint256 _reserve1,
        uint256 _maxPercentDiff
    ) internal pure returns (bool result) {
        uint256 diff = (_reserve0 * BASE) / _reserve1;
        if (
            diff > (BASE + _maxPercentDiff) ||
            diff < (BASE - _maxPercentDiff)
        ) {
            return true;
        }
        diff = (_reserve1 * BASE) / _reserve0;
        if (
            diff > (BASE + _maxPercentDiff) ||
            diff < (BASE - _maxPercentDiff)
        ) {
            return true;
        }
        return false;
    }

    /**
     * @dev Returns the pair's price.
     *   It calculates the price using Chainlink as an external price source and the pair's tokens reserves using the arithmetic mean formula.
     *   If there is a price deviation, instead of the reserves, it uses a weighted geometric mean with constant invariant K.
     * @param _accountManager Instance of AccountManager contract
     * @return int256 price
     */
    function latestAnswer(
        IAccountManager _accountManager
    ) internal view returns (int256) {

        FeedRegistryInterface  chainLinkRegistry = FeedRegistryInterface(_accountManager.chainLinkRegistry());

        uint256 _maxPercentDiff = _accountManager.maxPercentDiff();
        uint256 _allowedDelay = _accountManager.allowedDelay();

        IUniswapV2Pair pair = IUniswapV2Pair(address(_accountManager.depositToken()));

        address token0 = pair.token0();
        address token1 = pair.token1();

        uint256 token0Decimals = IUniswapV2Pair(token0).decimals();
        uint256 token1Decimals = IUniswapV2Pair(token1).decimals();

        uint256 chainlinkPrice0 = uint256(getChainlinkPrice(chainLinkRegistry, token0, Denominations.USD, _allowedDelay));
        uint256 chainlinkPrice1 = uint256(getChainlinkPrice(chainLinkRegistry, token1, Denominations.USD, _allowedDelay));

        //Get token reserves in ethers
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();

        uint256 reserveInStablecoin0 = getReserveValue(
            chainlinkPrice0,
            reserve0,
            token0Decimals
        );
        uint256 reserveInStablecoin1 = getReserveValue(
            chainlinkPrice1,
            reserve1,
            token1Decimals
        );

        if (
            hasPriceDifference(
                reserveInStablecoin0,
                reserveInStablecoin1,
                _maxPercentDiff
            )
        ) {
            //Calculate the weighted geometric mean
            return
                int256(
                    getGeometricMean(
                        address(pair),
                        reserveInStablecoin0,
                        reserveInStablecoin1
                    )
                );
        } else {
            //Calculate the arithmetic mean
            return
                int256(
                    getArithmeticMean(
                        address(pair),
                        reserveInStablecoin0,
                        reserveInStablecoin1
                    )
                );
        }
    }
}