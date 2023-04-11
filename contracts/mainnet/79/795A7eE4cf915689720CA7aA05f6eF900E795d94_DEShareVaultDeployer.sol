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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import {IUniswapV3PoolImmutables} from './pool/IUniswapV3PoolImmutables.sol';
import {IUniswapV3PoolState} from './pool/IUniswapV3PoolState.sol';
import {IUniswapV3PoolDerivedState} from './pool/IUniswapV3PoolDerivedState.sol';
import {IUniswapV3PoolActions} from './pool/IUniswapV3PoolActions.sol';
import {IUniswapV3PoolOwnerActions} from './pool/IUniswapV3PoolOwnerActions.sol';
import {IUniswapV3PoolErrors} from './pool/IUniswapV3PoolErrors.sol';
import {IUniswapV3PoolEvents} from './pool/IUniswapV3PoolEvents.sol';

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
    IUniswapV3PoolErrors,
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

/// @title Errors emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolErrors {
    error LOK();
    error TLU();
    error TLM();
    error TUM();
    error AI();
    error M0();
    error M1();
    error AS();
    error IIA();
    error L();
    error F0();
    error F1();
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
    /// @return tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// @return observationIndex The index of the last oracle observation that was written,
    /// @return observationCardinality The current maximum number of observations stored in the pool,
    /// @return observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// @return feeProtocol The protocol fee for both tokens of the pool.
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
    /// @return The liquidity at the current price of the pool
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper
    /// @return liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// @return feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// @return feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// @return tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// @return secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// @return secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// @return initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
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
    /// @return liquidity The amount of liquidity in the position,
    /// @return feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// @return feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// @return tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// @return tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 liquidity,
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
    /// @return tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// @return secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// @return initialized whether the observation has been initialized and the values are safe to use
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (0 - denominator) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            result = mulDiv(a, b, denominator);
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    error T();
    error R();

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
            if (absTick > uint256(int256(MAX_TICK))) revert T();

            uint256 ratio = absTick & 0x1 != 0
                ? 0xfffcb933bd6fad37aa2d162d1a594001
                : 0x100000000000000000000000000000000;
            if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
            if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
            if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
            if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
            if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
            if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
            if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
            if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
            if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
            if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
            if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
            if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
            if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
            if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
            if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
            if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
            if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
            if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
            if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

            if (tick > 0) ratio = type(uint256).max / ratio;

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
        }
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        unchecked {
            // second inequality must be < because the price can never reach the price at the max tick
            if (!(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO)) revert R();
            uint256 ratio = uint256(sqrtPriceX96) << 32;

            uint256 r = ratio;
            uint256 msb = 0;

            assembly {
                let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(5, gt(r, 0xFFFFFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(4, gt(r, 0xFFFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(3, gt(r, 0xFF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(2, gt(r, 0xF))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := shl(1, gt(r, 0x3))
                msb := or(msb, f)
                r := shr(f, r)
            }
            assembly {
                let f := gt(r, 0x1)
                msb := or(msb, f)
            }

            if (msb >= 128) r = ratio >> (msb - 127);
            else r = ratio << (127 - msb);

            int256 log_2 = (int256(msb) - 128) << 64;

            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(63, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(62, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(61, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(60, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(59, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(58, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(57, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(56, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(55, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(54, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(53, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(52, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(51, f))
                r := shr(f, r)
            }
            assembly {
                r := shr(127, mul(r, r))
                let f := shr(128, r)
                log_2 := or(log_2, shl(50, f))
            }

            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

library PositionKey {
    /// @dev Returns the key of the position in the core library
    function compute(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

// AccountManager - store records for each accounts collateral debt, & functioanlity for liquidation and redemptions, 

import './base/UnboundBase.sol';

import './interfaces/IAccountManager.sol';
import './libraries/UniswapV2PriceProvider.sol';

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract AccountManager is UnboundBase, IAccountManager, Initializable{

    address public override borrowerOperations;

    address public override chainLinkRegistry;

    uint256 public override maxPercentDiff;
    uint256 public override allowedDelay;


    address public override governanceFeeAddress;


    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation,
        closedByRedemption
    }

    // Store the necessary data for a account
    struct Account {
        uint debt;
        uint coll;
        Status status;
        uint128 arrayIndex;
    }

    struct ContractsCache {
        IMainPool mainPool;
        IUNDToken undToken;
        ISortedAccounts sortedAccounts;
        ICollSurplusPool collSurplusPool;
        IERC20 depositToken;
        IUnboundFeesFactory unboundFeesFactory;
    }

    /*
    * --- Variable container structs for liquidations ---
    *
    * These structs are used to hold, return and assign variables inside the liquidation functions,
    * in order to avoid the error: "CompilerError: Stack too deep".
    **/

    struct LocalVariables_LiquidationSequence {
        uint i;
        uint ICR;
        address user;
        uint entireSystemDebt;
        uint entireSystemColl;
    }

    struct LiquidationTotals {
        uint totalCollInSequence;
        uint totalDebtInSequence;
        uint totalLiquidationProfit;
        uint totalCollToSendToLiquidator;
    }

    struct LiquidationValues {
        uint accountDebt;
        uint accountColl;
        uint liquidationProfit;
        uint collToSendToLiquidator;
    }

    // --- Variable container structs for redemptions ---

    struct RedemptionTotals {
        uint remainingUND;
        uint totalUNDToRedeem;
        uint totalCollateralDrawn;
        uint CollateralFee;
        uint CollateralToSendToRedeemer;
        uint decayedBaseRate;
        uint price;
        uint totalUNDSupplyAtStart;
    }

    struct SingleRedemptionValues {
        uint UNDLot;
        uint CollateralLot;
        bool cancelledPartial;
    }

    mapping (address => Account) public Accounts;


    // Array of all active account addresses - used to to compute an approximate hint off-chain, for the sorted list insertion
    address[] public AccountOwners;

    function initialize (
        address _feeFactory,
        address _borrowerOperations,
        address _mainPool,
        address _undToken,
        address _sortedAccounts,
        address _collSurplusPool,
        address _depositToken,
        address _chainLinkRegistry,
        uint256 _maxPercentDiff,
        uint256 _allowedDelay,
        address _governanceFeeAddress,
        uint256 _MCR
    ) 
        public 
        initializer
    {
        unboundFeesFactory = IUnboundFeesFactory(_feeFactory);
        borrowerOperations = _borrowerOperations;
        mainPool = IMainPool(_mainPool);
        undToken = IUNDToken(_undToken);
        sortedAccounts = ISortedAccounts(_sortedAccounts);
        depositToken = IERC20(_depositToken);
        collSurplusPool = ICollSurplusPool(_collSurplusPool);
        chainLinkRegistry = _chainLinkRegistry;
        maxPercentDiff = _maxPercentDiff;
        allowedDelay = _allowedDelay;
        governanceFeeAddress = _governanceFeeAddress;
        MCR = _MCR;
    }

    // --- Getters ---

    function getAccountOwnersCount() external view override returns (uint) {
        return AccountOwners.length;
    }

    function getAccountFromAccountOwnersArray(uint _index) external view override returns (address) {
        return AccountOwners[_index];
    }

    // --- Account Liquidation functions ---

    // Single liquidation function. Closes the account if its ICR is lower than the minimum collateral ratio.
    function liquidate(address _borrower) external override {
        _requireAccountIsActive(_borrower);

        address[] memory borrowers = new address[](1);
        borrowers[0] = _borrower;
        batchLiquidateAccounts(borrowers);
    }

    // --- Inner single liquidation functions ---

    // Liquidate one account.
    function _liquidate(
        IMainPool _mainPool,
        address _borrower,
        uint _price
    )
        internal
        returns (LiquidationValues memory singleLiquidation)
    {

        singleLiquidation.accountDebt = Accounts[_borrower].debt;
        singleLiquidation.accountColl = Accounts[_borrower].coll;

        uint256 _debtWorthOfColl = (singleLiquidation.accountDebt * DECIMAL_PRECISION) / _price;

        if(singleLiquidation.accountColl > _debtWorthOfColl){  
            singleLiquidation.liquidationProfit = singleLiquidation.accountColl - _debtWorthOfColl;
        }

        singleLiquidation.collToSendToLiquidator = singleLiquidation.accountColl;

        // unstake collateral from farming contract
        _mainPool.unstake(_borrower, singleLiquidation.accountColl);

        _closeAccount(_borrower, Status.closedByLiquidation);
        emit AccountLiquidated(_borrower, singleLiquidation.accountDebt, singleLiquidation.accountColl, AccountManagerOperation.liquidation);
        emit AccountUpdated(_borrower, 0, 0, AccountManagerOperation.liquidation);
        return singleLiquidation;
    }

    /*
    * Liquidate a sequence of accounts. Closes a maximum number of n under-collateralized Accounts,
    * starting from the one with the lowest collateral ratio in the system, and moving upwards
    */
    function liquidateAccounts(uint _n) external override {

        ContractsCache memory contractsCache = ContractsCache(
            mainPool,
            undToken,
            sortedAccounts,
            collSurplusPool,
            depositToken,
            unboundFeesFactory
        );

        LiquidationTotals memory totals;

        // get price of pool token from oracle
        uint256 price = uint256 (UniswapV2PriceProvider.latestAnswer(IAccountManager(address(this))));

        // Perform the appropriate liquidation sequence - tally the values, and obtain their totals
        totals = _getTotalsFromLiquidateAccountsSequence(contractsCache.mainPool, contractsCache.sortedAccounts, price, _n);

        require(totals.totalDebtInSequence > 0, "AccountManager: nothing to liquidate");

        // decrease UND debt and burn UND from user account
        contractsCache.mainPool.decreaseUNDDebt(totals.totalDebtInSequence);
        contractsCache.undToken.burn(msg.sender, totals.totalDebtInSequence);

        // send collateral to liquidator
        contractsCache.mainPool.sendCollateral(contractsCache.depositToken, msg.sender, totals.totalCollToSendToLiquidator);

        emit Liquidation(totals.totalDebtInSequence, totals.totalCollInSequence, totals.totalLiquidationProfit);

    }

    function _getTotalsFromLiquidateAccountsSequence
    (
        IMainPool _mainPool,
        ISortedAccounts _sortedAccounts,
        uint _price,
        uint _n
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;


        for (vars.i = 0; vars.i < _n; vars.i++) {
            vars.user = _sortedAccounts.getLast();
            vars.ICR = getCurrentICR(vars.user, _price);

            if (vars.ICR < MCR) {
                singleLiquidation = _liquidate(_mainPool, vars.user, _price);

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

            } else break;  // break if the loop reaches a Account with ICR >= MCR
        }
    }

    /*
    * Attempt to liquidate a custom list of accounts provided by the caller.
    */
    function batchLiquidateAccounts(address[] memory _accountArray) public override {
        require(_accountArray.length != 0, "AccountManager: Calldata address array must not be empty");

        IMainPool mainPoolCached = mainPool;
        IUNDToken undTokenCached = undToken;
        IERC20 depositTokenCached = depositToken;

        LiquidationTotals memory totals;

        // get price of pool token from oracle
        uint256 price = uint256 (UniswapV2PriceProvider.latestAnswer(IAccountManager(address(this))));

        // Perform the appropriate liquidation sequence - tally values and obtain their totals.
        totals = _getTotalsFromBatchLiquidate(mainPoolCached, price, _accountArray);

        require(totals.totalDebtInSequence > 0, "AccountManager: nothing to liquidate");

        // decrease UND debt and burn UND from user account
        mainPoolCached.decreaseUNDDebt(totals.totalDebtInSequence);
        undTokenCached.burn(msg.sender, totals.totalDebtInSequence);

        // send collateral to liquidator
        mainPoolCached.sendCollateral(depositTokenCached, msg.sender, totals.totalCollToSendToLiquidator);

        emit Liquidation(totals.totalDebtInSequence, totals.totalCollInSequence, totals.totalLiquidationProfit);
    }

    function _getTotalsFromBatchLiquidate
    (
        IMainPool _mainPool,
        uint _price,
        address[] memory _accountArray
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;


        for (vars.i = 0; vars.i < _accountArray.length; vars.i++) {
            vars.user = _accountArray[vars.i];
            vars.ICR = getCurrentICR(vars.user, _price);

            if (vars.ICR < MCR) {
                singleLiquidation = _liquidate(_mainPool, vars.user, _price);

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);
            }
        }
    }

        // --- Liquidation helper functions ---

    function _addLiquidationValuesToTotals(LiquidationTotals memory oldTotals, LiquidationValues memory singleLiquidation)
    internal pure returns(LiquidationTotals memory newTotals) {

        // Tally all the values with their respective running totals
        newTotals.totalDebtInSequence = oldTotals.totalDebtInSequence + singleLiquidation.accountDebt;
        newTotals.totalCollInSequence = oldTotals.totalCollInSequence + singleLiquidation.accountColl;
        newTotals.totalLiquidationProfit = oldTotals.totalLiquidationProfit + singleLiquidation.liquidationProfit;
        newTotals.totalCollToSendToLiquidator = oldTotals.totalCollToSendToLiquidator + singleLiquidation.collToSendToLiquidator;

        return newTotals;
    }

    // --- Redemption functions ---

    // Redeem as much collateral as possible from _borrower's Account in exchange for UND up to _maxUNDamount
    function _redeemCollateralFromAccount(
        ContractsCache memory _contractsCache,
        address _borrower,
        uint _maxUNDamount,
        uint _price,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR
    )
        internal returns (SingleRedemptionValues memory singleRedemption)
    {

        uint256 userCurrentDebt = Accounts[_borrower].debt;
        uint256 userCurrentColl = Accounts[_borrower].coll;

         // Determine the remaining amount (lot) to be redeemed, capped by the entire debt of the Account
        singleRedemption.UNDLot = UnboundMath._min(_maxUNDamount, userCurrentDebt);

        // Get the CollateralLot of equivalent value in USD
        singleRedemption.CollateralLot = (singleRedemption.UNDLot * DECIMAL_PRECISION) / _price;

        // Decrease the debt and collateral of the current Account according to the UND lot and corresponding collateral to send
        uint newDebt = userCurrentDebt - singleRedemption.UNDLot;
        uint newColl = userCurrentColl - singleRedemption.CollateralLot;

        if (newDebt == 0) {
            // unstake collateral from farming contract
            _contractsCache.mainPool.unstake(_borrower, userCurrentColl);
            
            // No debt left in the Account (except for the liquidation reserve), therefore the account gets closed
            _closeAccount(_borrower, Status.closedByRedemption);
            _redeemCloseAccount(_contractsCache, _borrower, newColl);
            emit AccountUpdated(_borrower, 0, 0, AccountManagerOperation.redeemCollateral);

        } else {
            uint newNICR = UnboundMath._computeNominalCR(newColl, newDebt);

            /*
            * If the provided hint is out of date, we bail since trying to reinsert without a good hint will almost
            * certainly result in running out of gas. 
            *
            * If the resultant net debt of the partial is less than the minimum, net debt we bail.
            */
            if (newNICR != _partialRedemptionHintNICR || newDebt < MIN_NET_DEBT) {
                singleRedemption.cancelledPartial = true;
                return singleRedemption;
            }

            // unstake collateral from farming contract
            _contractsCache.mainPool.unstake(_borrower, singleRedemption.CollateralLot);

            _contractsCache.sortedAccounts.reInsert(_borrower, newNICR, _upperPartialRedemptionHint, _lowerPartialRedemptionHint);
        
            Accounts[_borrower].debt = newDebt;
            Accounts[_borrower].coll = newColl;

            emit AccountUpdated(
                _borrower,
                newDebt, newColl,
                AccountManagerOperation.redeemCollateral
            );
        }

        return singleRedemption;
    }

    /*
    * Called when a full redemption occurs, and closes the account.
    * The redeemer swaps (debt - liquidation reserve) UND for (debt - liquidation reserve) worth of Collateral, so the _redeemCloseAccount liquidation reserve left corresponds to the remaining debt.
    * In order to close the account, the _redeemCloseAccount liquidation reserve is burned, and the corresponding debt is removed from the main pool.
    * The debt recorded on the account's struct is zero'd elswhere, in _closeAccount.
    * Any surplus Collateral left in the account, is sent to the Coll surplus pool, and can be later claimed by the borrower.
    */
    function _redeemCloseAccount(ContractsCache memory _contractsCache, address _borrower, uint _Collateral) internal {
        // send collateral from Main Pool to CollSurplus Pool
        _contractsCache.collSurplusPool.accountSurplus(_borrower, _Collateral);
        _contractsCache.mainPool.sendCollateral(_contractsCache.depositToken, address(_contractsCache.collSurplusPool), _Collateral);
    }


    function _isValidFirstRedemptionHint(ISortedAccounts _sortedAccounts, address _firstRedemptionHint, uint _price) internal view returns (bool) {
        if (_firstRedemptionHint == address(0) ||
            !_sortedAccounts.contains(_firstRedemptionHint) ||
            getCurrentICR(_firstRedemptionHint, _price) < MCR
        ) {
            return false;
        }

        address nextAccount = _sortedAccounts.getNext(_firstRedemptionHint);
        return nextAccount == address(0) || getCurrentICR(nextAccount, _price) < MCR;
    }

    /* Send _UNDamount UND to the system and redeem the corresponding amount of collateral from as many Accounts as are needed to fill the redemption
    * request.
    *
    * Note that if _amount is very large, this function can run out of gas, specially if traversed accounts are small. This can be easily avoided by
    * splitting the total _amount in appropriate chunks and calling the function multiple times.
    *
    * Param `_maxIterations` can also be provided, so the loop through Account is capped (if it’s zero, it will be ignored).This makes it easier to
    * avoid OOG for the frontend, as only knowing approximately the average cost of an iteration is enough, without needing to know the “topology”
    * of the account list. It also avoids the need to set the cap in stone in the contract, nor doing gas calculations, as both gas price and opcode
    * costs can vary.
    *
    * All Accounts that are redeemed from -- with the likely exception of the last one -- will end up with no debt left, therefore they will be closed.
    * If the last Account does have some remaining debt, it has a finite ICR, and the reinsertion could be anywhere in the list, therefore it requires a hint.
    * A frontend should use getRedemptionHints() to calculate what the ICR of this Account will be after redemption, and pass a hint for its position
    * in the sortedAccounts list along with the ICR value that the hint was found for.
    *
    * If another transaction modifies the list between calling getRedemptionHints() and passing the hints to redeemCollateral(), it
    * is very likely that the last (partially) redeemed Account would end up with a different ICR than what the hint is for. In this case the
    * redemption will stop after the last completely redeemed Account and the sender will keep the remaining UND amount, which they can attempt
    * to redeem later.
    */

    function redeemCollateral(
        uint _UNDamount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFeePercentage
    )
        external
        override
    {

        ContractsCache memory contractsCache = ContractsCache(
            mainPool,
            undToken,
            sortedAccounts,
            collSurplusPool,
            depositToken,
            unboundFeesFactory
        );

        RedemptionTotals memory totals;

        _requireValidMaxFeePercentage(_maxFeePercentage);

        // get price of pool token from oracle
        totals.price = uint256 (UniswapV2PriceProvider.latestAnswer(IAccountManager(address(this))));
        _requireAmountGreaterThanZero(_UNDamount);
        _requireUNDBalanceCoversRedemption(contractsCache.undToken, msg.sender, _UNDamount);

        totals.totalUNDSupplyAtStart = contractsCache.undToken.totalSupply();
        // Confirm redeemer's balance is less than total UND supply
        assert(contractsCache.undToken.balanceOf(msg.sender) <= totals.totalUNDSupplyAtStart);

        totals.remainingUND = _UNDamount;
        address currentBorrower;

        if (_isValidFirstRedemptionHint(contractsCache.sortedAccounts, _firstRedemptionHint, totals.price)) {
            currentBorrower = _firstRedemptionHint;
        } else {
            currentBorrower = contractsCache.sortedAccounts.getLast();
            // Find the first account with ICR >= MCR
            while (currentBorrower != address(0) && getCurrentICR(currentBorrower, totals.price) < MCR) {
                currentBorrower = contractsCache.sortedAccounts.getPrev(currentBorrower);
            }
        }

        // Loop through the Accounts starting from the one with lowest collateral ratio until _amount of UND is exchanged for collateral
        if (_maxIterations == 0) { _maxIterations = type(uint256).max; }

        while (currentBorrower != address(0) && totals.remainingUND > 0 && _maxIterations > 0) {
            _maxIterations--;

            // Save the address of the Account preceding the current one, before potentially modifying the list
            address nextUserToCheck = contractsCache.sortedAccounts.getPrev(currentBorrower);

            SingleRedemptionValues memory singleRedemption = _redeemCollateralFromAccount(
                contractsCache,
                currentBorrower,
                totals.remainingUND,
                totals.price,
                _upperPartialRedemptionHint,
                _lowerPartialRedemptionHint,
                _partialRedemptionHintNICR
            );

            if (singleRedemption.cancelledPartial) break; // Partial redemption was cancelled (out-of-date hint, or new net debt < minimum), therefore we could not redeem from the last Account

            totals.totalUNDToRedeem  = totals.totalUNDToRedeem + singleRedemption.UNDLot;
            totals.totalCollateralDrawn = totals.totalCollateralDrawn + singleRedemption.CollateralLot;

            totals.remainingUND = totals.remainingUND - singleRedemption.UNDLot;
            currentBorrower = nextUserToCheck;
        }

        require(totals.totalCollateralDrawn > 0, "AccountManager: Unable to redeem any amount");

        // Decay the baseRate due to time passed, and then increase it according to the size of this redemption.
        // Use the saved total UND supply value, from before it was reduced by the redemption.
        contractsCache.unboundFeesFactory.updateBaseRateFromRedemption(totals.totalCollateralDrawn, totals.price, totals.totalUNDSupplyAtStart);
    
        // Calculate the Collateral fee
        totals.CollateralFee = contractsCache.unboundFeesFactory.getRedemptionFee(totals.totalCollateralDrawn);
    
        _requireUserAcceptsFee(totals.CollateralFee, totals.totalCollateralDrawn, _maxFeePercentage);
    
        // Send the Collateral fee to the governance fee address
        contractsCache.mainPool.sendCollateral(contractsCache.depositToken, governanceFeeAddress, totals.CollateralFee);

        totals.CollateralToSendToRedeemer = totals.totalCollateralDrawn - totals.CollateralFee;

        emit Redemption(_UNDamount, totals.totalUNDToRedeem, totals.totalCollateralDrawn, totals.CollateralFee);

        // Burn the total UND that is cancelled with debt, and send the redeemed Collateral to msg.sender
        contractsCache.undToken.burn(msg.sender, totals.totalUNDToRedeem);
        // Update Main Pool UND, and send Collateral to account
        contractsCache.mainPool.decreaseUNDDebt(totals.totalUNDToRedeem);
        contractsCache.mainPool.sendCollateral(contractsCache.depositToken, msg.sender, totals.CollateralToSendToRedeemer);
    }

    /**
     * Return Unbound Fees Factory contract address (to validate minter in UND contract)
     */
    function factory() external view returns(address){
        return address(unboundFeesFactory);
    }

    // // --- Account property getters ---

    function getAccountStatus(address _borrower) external override view returns (uint) {
        return uint(Accounts[_borrower].status);
    }

    function getAccountDebt(address _borrower) external view override returns (uint) {
        return Accounts[_borrower].debt;
    }

    function getAccountColl(address _borrower) external view override returns (uint) {
        return Accounts[_borrower].coll;
    }

    // --- Helper functions ---

    // Return the nominal collateral ratio (ICR) of a given Account, without the price. Takes a Account's pending coll and debt rewards from redistributions into account.
    function getNominalICR(address _borrower) public override view returns (uint) {
        (uint currentCollateral, uint currentUNDDebt) = _getCurrentAccountAmounts(_borrower);

        uint NICR = UnboundMath._computeNominalCR(currentCollateral, currentUNDDebt);
        return NICR;
    }

    // Return the current collateral ratio (ICR) of a given Account. Takes a account's pending coll and debt rewards from redistributions into account.
    function getCurrentICR(address _borrower, uint _price) public view override returns (uint) {
        (uint currentCollateral, uint currentUNDDebt) = _getCurrentAccountAmounts(_borrower);

        uint ICR = UnboundMath._computeCR(currentCollateral, currentUNDDebt, _price);
        return ICR;
    }

    // Return the Accounts entire debt and coll
    function getEntireDebtAndColl(
        address _borrower
    )
        public
        view
        override
        returns (uint debt, uint coll)
    {
        debt = Accounts[_borrower].debt;
        coll = Accounts[_borrower].coll;
    }

    function _getCurrentAccountAmounts(address _borrower) internal view returns (uint, uint) {
        uint currentCollateral = Accounts[_borrower].coll;
        uint currentUNDDebt = Accounts[_borrower].debt;

        return (currentCollateral, currentUNDDebt);
    }


    function closeAccount(address _borrower) external override {
        _requireCallerIsBorrowerOperations();
        return _closeAccount(_borrower, Status.closedByOwner);
    }

    function _closeAccount(address _borrower, Status closedStatus) internal {
        assert(closedStatus != Status.nonExistent && closedStatus != Status.active);

        uint AccountOwnersArrayLength = AccountOwners.length;

        Accounts[_borrower].status = closedStatus;
        Accounts[_borrower].coll = 0;
        Accounts[_borrower].debt = 0;

        _removeAccountOwner(_borrower, AccountOwnersArrayLength);
        sortedAccounts.remove(_borrower);

        Accounts[_borrower].arrayIndex = 0;
    }

    // Push the owner's address to the Account owners list, and record the corresponding array index on the Account struct
    function addAccountOwnerToArray(address _borrower) external override returns (uint index) {
        _requireCallerIsBorrowerOperations();
        index = _addAccountOwnerToArray(_borrower);
    }

    function _addAccountOwnerToArray(address _borrower) internal returns (uint128 index) {
        /* Max array size is 2**128 - 1, i.e. ~3e30 accounts. No risk of overflow, since accounts have minimum UND
        debt of liquidation reserve plus MIN_NET_DEBT. 3e30 UND dwarfs the value of all wealth in the world ( which is < 1e15 USD). */

        // Push the AccountOwner to the array
        AccountOwners.push(_borrower);

        // Record the index of the new AccountOwner on their Account struct
        index = uint128(AccountOwners.length - 1);
        Accounts[_borrower].arrayIndex = index;

        return index;
    }
    
    /*
    * Remove a Account owner from the AccountOwners array, not preserving array order. Removing owner 'B' does the following:
    * [A B C D E] => [A E C D], and updates E's Account struct to point to its new array index.
    */
    function _removeAccountOwner(address _borrower, uint AccountOwnersArrayLength) internal {
        Status accountStatus = Accounts[_borrower].status;
        // It’s set in caller function `_closeAccount`
        assert(accountStatus != Status.nonExistent && accountStatus != Status.active);

        uint128 index = Accounts[_borrower].arrayIndex;
        uint length = AccountOwnersArrayLength;
        uint idxLast = length - 1;

        assert(index <= idxLast);

        address addressToMove = AccountOwners[idxLast];

        AccountOwners[index] = addressToMove;
        Accounts[addressToMove].arrayIndex = index;
        emit AccountIndexUpdated(addressToMove, index);

        AccountOwners.pop();
    }

    // --- Account property setters, called by BorrowerOperations ---

    function setAccountStatus(address _borrower, uint _num) external override{
        _requireCallerIsBorrowerOperations();
        Accounts[_borrower].status = Status(_num);
    }

    function increaseAccountColl(address _borrower, uint _collIncrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newColl = Accounts[_borrower].coll + _collIncrease;
        Accounts[_borrower].coll = newColl;
        return newColl;
    }

    function decreaseAccountColl(address _borrower, uint _collDecrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newColl = Accounts[_borrower].coll - _collDecrease;
        Accounts[_borrower].coll = newColl;
        return newColl;
    }

    function increaseAccountDebt(address _borrower, uint _debtIncrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newDebt = Accounts[_borrower].debt + _debtIncrease;
        Accounts[_borrower].debt = newDebt;
        return newDebt;
    }

    function decreaseAccountDebt(address _borrower, uint _debtDecrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newDebt = Accounts[_borrower].debt - _debtDecrease;
        Accounts[_borrower].debt = newDebt;
        return newDebt;
    }

    // --- 'require' wrapper functions ---

    function _requireCallerIsBorrowerOperations() internal view {
        require(msg.sender == borrowerOperations, "AccountManager: Caller is not the BorrowerOperations contract");
    }

    function _requireAccountIsActive(address _borrower) internal view {
        require(Accounts[_borrower].status == Status.active, "AccountManager: Account does not exist or is closed");
    }

    function _requireUNDBalanceCoversRedemption(IUNDToken _undToken, address _redeemer, uint _amount) internal view {
        require(_undToken.balanceOf(_redeemer) >= _amount, "AccountManager: Requested redemption amount must be <= user's UND token balance");
    }

    function _requireAmountGreaterThanZero(uint _amount) internal pure {
        require(_amount > 0, "AccountManager: Amount must be greater than zero");
    }

    function _requireValidMaxFeePercentage(uint _maxFeePercentage) internal view {
        uint256 redemptionFeeFloor = REDEMPTION_FEE_FLOOR();
        require(_maxFeePercentage >= redemptionFeeFloor && _maxFeePercentage <= DECIMAL_PRECISION,
            "AccountManager: Max fee percentage must be between 0.5% and 100%");
    }

    function _requireUserAcceptsFee(uint _fee, uint _amount, uint _maxFeePercentage) internal pure {
        uint feePercentage = (_fee * DECIMAL_PRECISION) / _amount;
        require(feePercentage <= _maxFeePercentage, "AccountManager: Fee exceeded provided maximum");
    }
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
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/ICollSurplusPool.sol";
import "./interfaces/IAccountManager.sol";

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract CollSurplusPool is ICollSurplusPool, Initializable{
    using SafeERC20 for IERC20;

    address public borrowerOperations;
    address public accountManager;

    // deposited collateral tracker
    uint256 internal _collateral;
    // Collateral surplus claimable by account owners
    mapping (address => uint) internal balances;

    event CollBalanceUpdated(address indexed _account, uint _newBalance);
    event CollateralSent(address _to, uint _amount);

    function initialize(address _accountManager, address _borrowerOperations) public initializer {
        accountManager = _accountManager;
        borrowerOperations = _borrowerOperations;
    }

    /* Returns the collateral state variable at MainPool address.
       Not necessarily equal to the raw ether balance - ether can be forcibly sent to contracts. */
    function getTotalCollateral() external view override returns (uint) {
        return _collateral;
    }

    function getUserCollateral(address _account) external view override returns (uint) {
        return balances[_account];
    }

    // --- Pool functionality ---

    function accountSurplus(address _account, uint _amount) external override {
        _requireCallerIsAccountManager();

        uint newAmount = balances[_account] + _amount;
        balances[_account] = newAmount;

        _collateral = _collateral + _amount;

        emit CollBalanceUpdated(_account, newAmount);
    }   

    function claimColl(IERC20 _depositToken, address _account) external override {
        _requireCallerIsBorrowerOperations();
        uint claimableColl = balances[_account];
        require(claimableColl > 0, "CollSurplusPool: No collateral available to claim");

        balances[_account] = 0;
        emit CollBalanceUpdated(_account, 0);

        _collateral = _collateral - claimableColl;
        emit CollateralSent(_account, claimableColl);

        _depositToken.safeTransfer(_account, claimableColl);
    }

    // --- 'require' functions ---

    function _requireCallerIsBorrowerOperations() internal view {
        require(
            msg.sender == borrowerOperations,
            "CollSurplusPool: Caller is not Borrower Operations");
    }

    function _requireCallerIsAccountManager() internal view {
        require(
            msg.sender == accountManager,
            "CollSurplusPool: Caller is not AccountManager");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

// AccountManager - store records for each accounts collateral debt, & functioanlity for liquidation and redemptions, 

import '../base/UnboundBase.sol';

import '../interfaces/IDEAccountManager.sol';
import '../libraries/DESharePriceProvider.sol';

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract DEAccountManager is UnboundBase, IDEAccountManager, Initializable{

    address public override borrowerOperations;

    address public override chainLinkRegistry;

    uint256 public override allowedDelay;


    address public override governanceFeeAddress;


    enum Status {
        nonExistent,
        active,
        closedByOwner,
        closedByLiquidation,
        closedByRedemption
    }

    // Store the necessary data for a account
    struct Account {
        uint debt;
        uint coll;
        Status status;
        uint128 arrayIndex;
    }

    struct ContractsCache {
        IMainPool mainPool;
        IUNDToken undToken;
        ISortedAccounts sortedAccounts;
        ICollSurplusPool collSurplusPool;
        IERC20 depositToken;
        IUnboundFeesFactory unboundFeesFactory;
    }

    /*
    * --- Variable container structs for liquidations ---
    *
    * These structs are used to hold, return and assign variables inside the liquidation functions,
    * in order to avoid the error: "CompilerError: Stack too deep".
    **/

    struct LocalVariables_LiquidationSequence {
        uint i;
        uint ICR;
        address user;
        uint entireSystemDebt;
        uint entireSystemColl;
    }

    struct LiquidationTotals {
        uint totalCollInSequence;
        uint totalDebtInSequence;
        uint totalLiquidationProfit;
        uint totalCollToSendToLiquidator;
    }

    struct LiquidationValues {
        uint accountDebt;
        uint accountColl;
        uint liquidationProfit;
        uint collToSendToLiquidator;
    }

    // --- Variable container structs for redemptions ---

    struct RedemptionTotals {
        uint remainingUND;
        uint totalUNDToRedeem;
        uint totalCollateralDrawn;
        uint CollateralFee;
        uint CollateralToSendToRedeemer;
        uint decayedBaseRate;
        uint price;
        uint totalUNDSupplyAtStart;
    }

    struct SingleRedemptionValues {
        uint UNDLot;
        uint CollateralLot;
        bool cancelledPartial;
    }

    mapping (address => Account) public Accounts;


    // Array of all active account addresses - used to to compute an approximate hint off-chain, for the sorted list insertion
    address[] public AccountOwners;

    function initialize (
        address _feeFactory,
        address _borrowerOperations,
        address _mainPool,
        address _undToken,
        address _sortedAccounts,
        address _collSurplusPool,
        address _depositToken,
        address _chainLinkRegistry,
        uint256 _allowedDelay,
        address _governanceFeeAddress,
        uint256 _MCR
    ) 
        public 
        initializer 
    {
        unboundFeesFactory = IUnboundFeesFactory(_feeFactory);
        borrowerOperations = _borrowerOperations;
        mainPool = IMainPool(_mainPool);
        undToken = IUNDToken(_undToken);
        sortedAccounts = ISortedAccounts(_sortedAccounts);
        depositToken = IERC20(_depositToken);
        collSurplusPool = ICollSurplusPool(_collSurplusPool);
        chainLinkRegistry = _chainLinkRegistry;
        allowedDelay = _allowedDelay;
        governanceFeeAddress = _governanceFeeAddress;
        MCR = _MCR;
    }

    // --- Getters ---

    function getAccountOwnersCount() external view override returns (uint) {
        return AccountOwners.length;
    }

    function getAccountFromAccountOwnersArray(uint _index) external view override returns (address) {
        return AccountOwners[_index];
    }

    // --- Account Liquidation functions ---

    // Single liquidation function. Closes the account if its ICR is lower than the minimum collateral ratio.
    function liquidate(address _borrower) external override {
        _requireAccountIsActive(_borrower);

        address[] memory borrowers = new address[](1);
        borrowers[0] = _borrower;
        batchLiquidateAccounts(borrowers);
    }

    // --- Inner single liquidation functions ---

    // Liquidate one account.
    function _liquidate(
        IMainPool _mainPool,
        address _borrower,
        uint _price
    )
        internal
        returns (LiquidationValues memory singleLiquidation)
    {

        singleLiquidation.accountDebt = Accounts[_borrower].debt;
        singleLiquidation.accountColl = Accounts[_borrower].coll;

        uint256 _debtWorthOfColl = (singleLiquidation.accountDebt * DECIMAL_PRECISION) / _price;

        if(singleLiquidation.accountColl > _debtWorthOfColl){  
            singleLiquidation.liquidationProfit = singleLiquidation.accountColl - _debtWorthOfColl;
        }

        singleLiquidation.collToSendToLiquidator = singleLiquidation.accountColl;

        // unstake collateral from farming contract
        _mainPool.unstake(_borrower, singleLiquidation.accountColl);

        _closeAccount(_borrower, Status.closedByLiquidation);
        emit AccountLiquidated(_borrower, singleLiquidation.accountDebt, singleLiquidation.accountColl, AccountManagerOperation.liquidation);
        emit AccountUpdated(_borrower, 0, 0, AccountManagerOperation.liquidation);
        return singleLiquidation;
    }

    /*
    * Liquidate a sequence of accounts. Closes a maximum number of n under-collateralized Accounts,
    * starting from the one with the lowest collateral ratio in the system, and moving upwards
    */
    function liquidateAccounts(uint _n) external override {

        ContractsCache memory contractsCache = ContractsCache(
            mainPool,
            undToken,
            sortedAccounts,
            collSurplusPool,
            depositToken,
            unboundFeesFactory
        );

        LiquidationTotals memory totals;

        // get price of pool token from oracle
        uint256 price = uint256 (DESharePriceProvider.latestAnswer(IDEAccountManager(address(this))));

        // Perform the appropriate liquidation sequence - tally the values, and obtain their totals
        totals = _getTotalsFromLiquidateAccountsSequence(contractsCache.mainPool, contractsCache.sortedAccounts, price, _n);

        require(totals.totalDebtInSequence > 0, "AccountManager: nothing to liquidate");

        // decrease UND debt and burn UND from user account
        contractsCache.mainPool.decreaseUNDDebt(totals.totalDebtInSequence);
        contractsCache.undToken.burn(msg.sender, totals.totalDebtInSequence);

        // send collateral to liquidator
        contractsCache.mainPool.sendCollateral(contractsCache.depositToken, msg.sender, totals.totalCollToSendToLiquidator);

        emit Liquidation(totals.totalDebtInSequence, totals.totalCollInSequence, totals.totalLiquidationProfit);

    }

    function _getTotalsFromLiquidateAccountsSequence
    (
        IMainPool _mainPool,
        ISortedAccounts _sortedAccounts,
        uint _price,
        uint _n
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;


        for (vars.i = 0; vars.i < _n; vars.i++) {
            vars.user = _sortedAccounts.getLast();
            vars.ICR = getCurrentICR(vars.user, _price);

            if (vars.ICR < MCR) {
                singleLiquidation = _liquidate(_mainPool, vars.user, _price);

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);

            } else break;  // break if the loop reaches a Account with ICR >= MCR
        }
    }

    /*
    * Attempt to liquidate a custom list of accounts provided by the caller.
    */
    function batchLiquidateAccounts(address[] memory _accountArray) public override {
        require(_accountArray.length != 0, "AccountManager: Calldata address array must not be empty");

        IMainPool mainPoolCached = mainPool;
        IUNDToken undTokenCached = undToken;
        IERC20 depositTokenCached = depositToken;

        LiquidationTotals memory totals;

        // get price of pool token from oracle
        uint256 price = uint256 (DESharePriceProvider.latestAnswer(IDEAccountManager(address(this))));

        // Perform the appropriate liquidation sequence - tally values and obtain their totals.
        totals = _getTotalsFromBatchLiquidate(mainPoolCached, price, _accountArray);

        require(totals.totalDebtInSequence > 0, "AccountManager: nothing to liquidate");

        // decrease UND debt and burn UND from user account
        mainPoolCached.decreaseUNDDebt(totals.totalDebtInSequence);
        undTokenCached.burn(msg.sender, totals.totalDebtInSequence);

        // send collateral to liquidator
        mainPoolCached.sendCollateral(depositTokenCached, msg.sender, totals.totalCollToSendToLiquidator);

        emit Liquidation(totals.totalDebtInSequence, totals.totalCollInSequence, totals.totalLiquidationProfit);
    }

    function _getTotalsFromBatchLiquidate
    (
        IMainPool _mainPool,
        uint _price,
        address[] memory _accountArray
    )
        internal
        returns(LiquidationTotals memory totals)
    {
        LocalVariables_LiquidationSequence memory vars;
        LiquidationValues memory singleLiquidation;


        for (vars.i = 0; vars.i < _accountArray.length; vars.i++) {
            vars.user = _accountArray[vars.i];
            vars.ICR = getCurrentICR(vars.user, _price);

            if (vars.ICR < MCR) {
                singleLiquidation = _liquidate(_mainPool, vars.user, _price);

                // Add liquidation values to their respective running totals
                totals = _addLiquidationValuesToTotals(totals, singleLiquidation);
            }
        }
    }

        // --- Liquidation helper functions ---

    function _addLiquidationValuesToTotals(LiquidationTotals memory oldTotals, LiquidationValues memory singleLiquidation)
    internal pure returns(LiquidationTotals memory newTotals) {

        // Tally all the values with their respective running totals
        newTotals.totalDebtInSequence = oldTotals.totalDebtInSequence + singleLiquidation.accountDebt;
        newTotals.totalCollInSequence = oldTotals.totalCollInSequence + singleLiquidation.accountColl;
        newTotals.totalLiquidationProfit = oldTotals.totalLiquidationProfit + singleLiquidation.liquidationProfit;
        newTotals.totalCollToSendToLiquidator = oldTotals.totalCollToSendToLiquidator + singleLiquidation.collToSendToLiquidator;

        return newTotals;
    }

    // --- Redemption functions ---

    // Redeem as much collateral as possible from _borrower's Account in exchange for UND up to _maxUNDamount
    function _redeemCollateralFromAccount(
        ContractsCache memory _contractsCache,
        address _borrower,
        uint _maxUNDamount,
        uint _price,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR
    )
        internal returns (SingleRedemptionValues memory singleRedemption)
    {

        uint256 userCurrentDebt = Accounts[_borrower].debt;
        uint256 userCurrentColl = Accounts[_borrower].coll;

         // Determine the remaining amount (lot) to be redeemed, capped by the entire debt of the Account
        singleRedemption.UNDLot = UnboundMath._min(_maxUNDamount, userCurrentDebt);

        // Get the CollateralLot of equivalent value in USD
        singleRedemption.CollateralLot = (singleRedemption.UNDLot * DECIMAL_PRECISION) / _price;

        // Decrease the debt and collateral of the current Account according to the UND lot and corresponding collateral to send
        uint newDebt = userCurrentDebt - singleRedemption.UNDLot;
        uint newColl = userCurrentColl - singleRedemption.CollateralLot;

        if (newDebt == 0) {
            // unstake collateral from farming contract
            _contractsCache.mainPool.unstake(_borrower, userCurrentColl);
            
            // No debt left in the Account (except for the liquidation reserve), therefore the account gets closed
            _closeAccount(_borrower, Status.closedByRedemption);
            _redeemCloseAccount(_contractsCache, _borrower, newColl);
            emit AccountUpdated(_borrower, 0, 0, AccountManagerOperation.redeemCollateral);

        } else {
            uint newNICR = UnboundMath._computeNominalCR(newColl, newDebt);

            /*
            * If the provided hint is out of date, we bail since trying to reinsert without a good hint will almost
            * certainly result in running out of gas. 
            *
            * If the resultant net debt of the partial is less than the minimum, net debt we bail.
            */
            if (newNICR != _partialRedemptionHintNICR || newDebt < MIN_NET_DEBT) {
                singleRedemption.cancelledPartial = true;
                return singleRedemption;
            }

            // unstake collateral from farming contract
            _contractsCache.mainPool.unstake(_borrower, singleRedemption.CollateralLot);

            _contractsCache.sortedAccounts.reInsert(_borrower, newNICR, _upperPartialRedemptionHint, _lowerPartialRedemptionHint);
        
            Accounts[_borrower].debt = newDebt;
            Accounts[_borrower].coll = newColl;

            emit AccountUpdated(
                _borrower,
                newDebt, newColl,
                AccountManagerOperation.redeemCollateral
            );
        }

        return singleRedemption;
    }

    /*
    * Called when a full redemption occurs, and closes the account.
    * The redeemer swaps (debt - liquidation reserve) UND for (debt - liquidation reserve) worth of Collateral, so the _redeemCloseAccount liquidation reserve left corresponds to the remaining debt.
    * In order to close the account, the _redeemCloseAccount liquidation reserve is burned, and the corresponding debt is removed from the main pool.
    * The debt recorded on the account's struct is zero'd elswhere, in _closeAccount.
    * Any surplus Collateral left in the account, is sent to the Coll surplus pool, and can be later claimed by the borrower.
    */
    function _redeemCloseAccount(ContractsCache memory _contractsCache, address _borrower, uint _Collateral) internal {
        // send collateral from Main Pool to CollSurplus Pool
        _contractsCache.collSurplusPool.accountSurplus(_borrower, _Collateral);
        _contractsCache.mainPool.sendCollateral(_contractsCache.depositToken, address(_contractsCache.collSurplusPool), _Collateral);
    }


    function _isValidFirstRedemptionHint(ISortedAccounts _sortedAccounts, address _firstRedemptionHint, uint _price) internal view returns (bool) {
        if (_firstRedemptionHint == address(0) ||
            !_sortedAccounts.contains(_firstRedemptionHint) ||
            getCurrentICR(_firstRedemptionHint, _price) < MCR
        ) {
            return false;
        }

        address nextAccount = _sortedAccounts.getNext(_firstRedemptionHint);
        return nextAccount == address(0) || getCurrentICR(nextAccount, _price) < MCR;
    }

    /* Send _UNDamount UND to the system and redeem the corresponding amount of collateral from as many Accounts as are needed to fill the redemption
    * request.
    *
    * Note that if _amount is very large, this function can run out of gas, specially if traversed accounts are small. This can be easily avoided by
    * splitting the total _amount in appropriate chunks and calling the function multiple times.
    *
    * Param `_maxIterations` can also be provided, so the loop through Account is capped (if it’s zero, it will be ignored).This makes it easier to
    * avoid OOG for the frontend, as only knowing approximately the average cost of an iteration is enough, without needing to know the “topology”
    * of the account list. It also avoids the need to set the cap in stone in the contract, nor doing gas calculations, as both gas price and opcode
    * costs can vary.
    *
    * All Accounts that are redeemed from -- with the likely exception of the last one -- will end up with no debt left, therefore they will be closed.
    * If the last Account does have some remaining debt, it has a finite ICR, and the reinsertion could be anywhere in the list, therefore it requires a hint.
    * A frontend should use getRedemptionHints() to calculate what the ICR of this Account will be after redemption, and pass a hint for its position
    * in the sortedAccounts list along with the ICR value that the hint was found for.
    *
    * If another transaction modifies the list between calling getRedemptionHints() and passing the hints to redeemCollateral(), it
    * is very likely that the last (partially) redeemed Account would end up with a different ICR than what the hint is for. In this case the
    * redemption will stop after the last completely redeemed Account and the sender will keep the remaining UND amount, which they can attempt
    * to redeem later.
    */

    function redeemCollateral(
        uint _UNDamount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFeePercentage
    )
        external
        override
    {

        ContractsCache memory contractsCache = ContractsCache(
            mainPool,
            undToken,
            sortedAccounts,
            collSurplusPool,
            depositToken,
            unboundFeesFactory
        );

        RedemptionTotals memory totals;

        _requireValidMaxFeePercentage(_maxFeePercentage);

        // get price of pool token from oracle
        totals.price = uint256 (DESharePriceProvider.latestAnswer(IDEAccountManager(address(this))));
        _requireAmountGreaterThanZero(_UNDamount);
        _requireUNDBalanceCoversRedemption(contractsCache.undToken, msg.sender, _UNDamount);

        totals.totalUNDSupplyAtStart = contractsCache.undToken.totalSupply();
        // Confirm redeemer's balance is less than total UND supply
        assert(contractsCache.undToken.balanceOf(msg.sender) <= totals.totalUNDSupplyAtStart);

        totals.remainingUND = _UNDamount;
        address currentBorrower;

        if (_isValidFirstRedemptionHint(contractsCache.sortedAccounts, _firstRedemptionHint, totals.price)) {
            currentBorrower = _firstRedemptionHint;
        } else {
            currentBorrower = contractsCache.sortedAccounts.getLast();
            // Find the first account with ICR >= MCR
            while (currentBorrower != address(0) && getCurrentICR(currentBorrower, totals.price) < MCR) {
                currentBorrower = contractsCache.sortedAccounts.getPrev(currentBorrower);
            }
        }

        // Loop through the Accounts starting from the one with lowest collateral ratio until _amount of UND is exchanged for collateral
        if (_maxIterations == 0) { _maxIterations = type(uint256).max; }

        while (currentBorrower != address(0) && totals.remainingUND > 0 && _maxIterations > 0) {
            _maxIterations--;

            // Save the address of the Account preceding the current one, before potentially modifying the list
            address nextUserToCheck = contractsCache.sortedAccounts.getPrev(currentBorrower);

            SingleRedemptionValues memory singleRedemption = _redeemCollateralFromAccount(
                contractsCache,
                currentBorrower,
                totals.remainingUND,
                totals.price,
                _upperPartialRedemptionHint,
                _lowerPartialRedemptionHint,
                _partialRedemptionHintNICR
            );

            if (singleRedemption.cancelledPartial) break; // Partial redemption was cancelled (out-of-date hint, or new net debt < minimum), therefore we could not redeem from the last Account

            totals.totalUNDToRedeem  = totals.totalUNDToRedeem + singleRedemption.UNDLot;
            totals.totalCollateralDrawn = totals.totalCollateralDrawn + singleRedemption.CollateralLot;

            totals.remainingUND = totals.remainingUND - singleRedemption.UNDLot;
            currentBorrower = nextUserToCheck;
        }

        require(totals.totalCollateralDrawn > 0, "AccountManager: Unable to redeem any amount");

        // Decay the baseRate due to time passed, and then increase it according to the size of this redemption.
        // Use the saved total UND supply value, from before it was reduced by the redemption.
        contractsCache.unboundFeesFactory.updateBaseRateFromRedemption(totals.totalCollateralDrawn, totals.price, totals.totalUNDSupplyAtStart);
    
        // Calculate the Collateral fee
        totals.CollateralFee = contractsCache.unboundFeesFactory.getRedemptionFee(totals.totalCollateralDrawn);
    
        _requireUserAcceptsFee(totals.CollateralFee, totals.totalCollateralDrawn, _maxFeePercentage);
    
        // Send the Collateral fee to the governance fee address
        contractsCache.mainPool.sendCollateral(contractsCache.depositToken, governanceFeeAddress, totals.CollateralFee);

        totals.CollateralToSendToRedeemer = totals.totalCollateralDrawn - totals.CollateralFee;

        emit Redemption(_UNDamount, totals.totalUNDToRedeem, totals.totalCollateralDrawn, totals.CollateralFee);

        // Burn the total UND that is cancelled with debt, and send the redeemed Collateral to msg.sender
        contractsCache.undToken.burn(msg.sender, totals.totalUNDToRedeem);
        // Update Main Pool UND, and send Collateral to account
        contractsCache.mainPool.decreaseUNDDebt(totals.totalUNDToRedeem);
        contractsCache.mainPool.sendCollateral(contractsCache.depositToken, msg.sender, totals.CollateralToSendToRedeemer);
    }

    /**
     * Return Unbound Fees Factory contract address (to validate minter in UND contract)
     */
    function factory() external view returns(address){
        return address(unboundFeesFactory);
    }

    // // --- Account property getters ---

    function getAccountStatus(address _borrower) external override view returns (uint) {
        return uint(Accounts[_borrower].status);
    }

    function getAccountDebt(address _borrower) external view override returns (uint) {
        return Accounts[_borrower].debt;
    }

    function getAccountColl(address _borrower) external view override returns (uint) {
        return Accounts[_borrower].coll;
    }

    // --- Helper functions ---

    // Return the nominal collateral ratio (ICR) of a given Account, without the price. Takes a Account's pending coll and debt rewards from redistributions into account.
    function getNominalICR(address _borrower) public override view returns (uint) {
        (uint currentCollateral, uint currentUNDDebt) = _getCurrentAccountAmounts(_borrower);

        uint NICR = UnboundMath._computeNominalCR(currentCollateral, currentUNDDebt);
        return NICR;
    }

    // Return the current collateral ratio (ICR) of a given Account. Takes a account's pending coll and debt rewards from redistributions into account.
    function getCurrentICR(address _borrower, uint _price) public view override returns (uint) {
        (uint currentCollateral, uint currentUNDDebt) = _getCurrentAccountAmounts(_borrower);

        uint ICR = UnboundMath._computeCR(currentCollateral, currentUNDDebt, _price);
        return ICR;
    }

    // Return the Accounts entire debt and coll
    function getEntireDebtAndColl(
        address _borrower
    )
        public
        view
        override
        returns (uint debt, uint coll)
    {
        debt = Accounts[_borrower].debt;
        coll = Accounts[_borrower].coll;
    }

    function _getCurrentAccountAmounts(address _borrower) internal view returns (uint, uint) {
        uint currentCollateral = Accounts[_borrower].coll;
        uint currentUNDDebt = Accounts[_borrower].debt;

        return (currentCollateral, currentUNDDebt);
    }


    function closeAccount(address _borrower) external override {
        _requireCallerIsBorrowerOperations();
        return _closeAccount(_borrower, Status.closedByOwner);
    }

    function _closeAccount(address _borrower, Status closedStatus) internal {
        assert(closedStatus != Status.nonExistent && closedStatus != Status.active);

        uint AccountOwnersArrayLength = AccountOwners.length;

        Accounts[_borrower].status = closedStatus;
        Accounts[_borrower].coll = 0;
        Accounts[_borrower].debt = 0;

        _removeAccountOwner(_borrower, AccountOwnersArrayLength);
        sortedAccounts.remove(_borrower);

        Accounts[_borrower].arrayIndex = 0;
    }

    // Push the owner's address to the Account owners list, and record the corresponding array index on the Account struct
    function addAccountOwnerToArray(address _borrower) external override returns (uint index) {
        _requireCallerIsBorrowerOperations();
        index = _addAccountOwnerToArray(_borrower);
    }

    function _addAccountOwnerToArray(address _borrower) internal returns (uint128 index) {
        /* Max array size is 2**128 - 1, i.e. ~3e30 accounts. No risk of overflow, since accounts have minimum UND
        debt of liquidation reserve plus MIN_NET_DEBT. 3e30 UND dwarfs the value of all wealth in the world ( which is < 1e15 USD). */

        // Push the AccountOwner to the array
        AccountOwners.push(_borrower);

        // Record the index of the new AccountOwner on their Account struct
        index = uint128(AccountOwners.length - 1);
        Accounts[_borrower].arrayIndex = index;

        return index;
    }
    
    /*
    * Remove a Account owner from the AccountOwners array, not preserving array order. Removing owner 'B' does the following:
    * [A B C D E] => [A E C D], and updates E's Account struct to point to its new array index.
    */
    function _removeAccountOwner(address _borrower, uint AccountOwnersArrayLength) internal {
        Status accountStatus = Accounts[_borrower].status;
        // It’s set in caller function `_closeAccount`
        assert(accountStatus != Status.nonExistent && accountStatus != Status.active);

        uint128 index = Accounts[_borrower].arrayIndex;
        uint length = AccountOwnersArrayLength;
        uint idxLast = length - 1;

        assert(index <= idxLast);

        address addressToMove = AccountOwners[idxLast];

        AccountOwners[index] = addressToMove;
        Accounts[addressToMove].arrayIndex = index;
        emit AccountIndexUpdated(addressToMove, index);

        AccountOwners.pop();
    }

    // --- Account property setters, called by BorrowerOperations ---

    function setAccountStatus(address _borrower, uint _num) external override{
        _requireCallerIsBorrowerOperations();
        Accounts[_borrower].status = Status(_num);
    }

    function increaseAccountColl(address _borrower, uint _collIncrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newColl = Accounts[_borrower].coll + _collIncrease;
        Accounts[_borrower].coll = newColl;
        return newColl;
    }

    function decreaseAccountColl(address _borrower, uint _collDecrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newColl = Accounts[_borrower].coll - _collDecrease;
        Accounts[_borrower].coll = newColl;
        return newColl;
    }

    function increaseAccountDebt(address _borrower, uint _debtIncrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newDebt = Accounts[_borrower].debt + _debtIncrease;
        Accounts[_borrower].debt = newDebt;
        return newDebt;
    }

    function decreaseAccountDebt(address _borrower, uint _debtDecrease) external override returns (uint) {
        _requireCallerIsBorrowerOperations();
        uint newDebt = Accounts[_borrower].debt - _debtDecrease;
        Accounts[_borrower].debt = newDebt;
        return newDebt;
    }

    // --- 'require' wrapper functions ---

    function _requireCallerIsBorrowerOperations() internal view {
        require(msg.sender == borrowerOperations, "AccountManager: Caller is not the BorrowerOperations contract");
    }

    function _requireAccountIsActive(address _borrower) internal view {
        require(Accounts[_borrower].status == Status.active, "AccountManager: Account does not exist or is closed");
    }

    function _requireUNDBalanceCoversRedemption(IUNDToken _undToken, address _redeemer, uint _amount) internal view {
        require(_undToken.balanceOf(_redeemer) >= _amount, "AccountManager: Requested redemption amount must be <= user's UND token balance");
    }

    function _requireAmountGreaterThanZero(uint _amount) internal pure {
        require(_amount > 0, "AccountManager: Amount must be greater than zero");
    }

    function _requireValidMaxFeePercentage(uint _maxFeePercentage) internal view {
        uint256 redemptionFeeFloor = REDEMPTION_FEE_FLOOR();
        require(_maxFeePercentage >= redemptionFeeFloor && _maxFeePercentage <= DECIMAL_PRECISION,
            "AccountManager: Max fee percentage must be between 0.5% and 100%");
    }

    function _requireUserAcceptsFee(uint _fee, uint _amount, uint _maxFeePercentage) internal pure {
        uint feePercentage = (_fee * DECIMAL_PRECISION) / _amount;
        require(feePercentage <= _maxFeePercentage, "AccountManager: Fee exceeded provided maximum");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '../base/UnboundBase.sol';

import '../interfaces/IBorrowoperations.sol';
import '../interfaces/IDEAccountManager.sol';

import '../libraries/DESharePriceProvider.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

// BorrowOperations - add collatreral, remove collaral, mint UND, repay UND, 
contract DEBorrowOperations is UnboundBase, Initializable, IBorrowoperations {

    using SafeERC20 for IERC20;

    IDEAccountManager public accountManager;

    address public override governanceFeeAddress;

    struct ContractsCache {
        IDEAccountManager accountManager;
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
        accountManager = IDEAccountManager(_accountManager);
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
        vars.price = uint256 (DESharePriceProvider.latestAnswer(contractsCache.accountManager));

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
        vars.price = uint256 (DESharePriceProvider.latestAnswer(contractsCache.accountManager));

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
     * Return Collateral Price in USD, for UI. Use static call to fetch price
     */
    function getCollPrice() external returns(uint256){
        return uint256 (DESharePriceProvider.latestAnswer(accountManager));
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
        IDEAccountManager _accountManager,
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

    function _requireAccountisActive(IDEAccountManager _accountManager, address _borrower) internal view {
        uint status = _accountManager.getAccountStatus(_borrower);
        require(status == 1, "BorrowerOps: Account does not exist or is closed");
    }

    function _requireSufficientUNDBalance(IUNDToken _undToken, address _borrower, uint _debtRepayment) internal view {
        require(_undToken.balanceOf(_borrower) >= _debtRepayment, "BorrowerOps: Caller doesnt have enough UND to make repayment");
    }

    function _requireAccountisNotActive(IDEAccountManager _accountManager, address _borrower) internal view {
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

        newColl = _isCollIncrease ? _coll + _collChange :  _coll - _collChange;
        newDebt = _isDebtIncrease ? _debt + _debtChange : _debt - _debtChange;

        return (newColl, newDebt);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/proxy/Clones.sol";
import '@openzeppelin/contracts/access/Ownable.sol';

//local imports
import "./DEAccountManager.sol";
import "./DEBorrowOperations.sol";
import "../CollSurplusPool.sol";
import "../MainPool.sol";
import "../SortedAccounts.sol";
import "../HintHelpers.sol";
import "../MultiAccountGetter.sol";

contract DEShareVaultDeployer is Ownable{

    // implementation addresses to clone and deploy new vaults
    address public accountManager;
    address public borrowOperations;
    address public collSurplusPool;
    address public mainPool;
    address public sortedAccounts;
    address public hintHelpers;
    address public multiAccountGetter;

    address public goveranceFeeAddress; // address where borrowing and redemption fee will be sent

    address public unboundFeesFactory; // unbound fees factory address
    address public undToken; // UND token address

    uint256 public vaultId = 0; // id of the next vault which is going to be deployed

    event NewVaultDeployed (
        address accountManager,
        address borrowOperations,
        address collSurplusPool,
        address mainPool,
        address sortedAccounts,
        address depositToken,
        address hintHelpers,
        address multiAccountGetter
    );

    struct VaultAddresses{
        address accountManager;
        address borrowOperations;
        address collSurplusPool;
        address mainPool;
        address sortedAccounts;
        address depositToken;
        address hintHelpers;
        address multiAccountGetter;
    }

    // to get rid of stack too deep error
    struct LocalVariables {
        uint256 _minimumCollateralRatio;
        address _chainLinkRegistry;
        uint256 _allowedDelay;
    }

    // map vault vaultId with vault addresses struct
    mapping ( uint256 => VaultAddresses ) public vaultAddresses;

    /// @dev Deploys a vaults with given parameters
    /// @param _depositToken Collateral token address
    /// @param _minimumCollateralRatio Minimum collateral ratio for the vault
    /// @param _chainLinkRegistry Chainlink registry address
    /// @param _allowedDelay Allowed delay for price update in chainlink feed
    /// @param _mainPoolContractOwner Owner address of the mainPool contract
    function deployVault(
        address _depositToken,
        uint256 _minimumCollateralRatio,
        address _chainLinkRegistry,
        uint256 _allowedDelay,
        address _mainPoolContractOwner
    ) public onlyOwner {

        VaultAddresses memory vault;

        vault.depositToken = _depositToken;

        vault.accountManager = Clones.clone(accountManager);
        vault.borrowOperations = Clones.clone(borrowOperations);
        vault.collSurplusPool = Clones.clone(collSurplusPool);
        vault.mainPool = Clones.clone(mainPool);
        vault.sortedAccounts = Clones.clone(sortedAccounts);
        vault.hintHelpers = Clones.clone(hintHelpers);
        vault.multiAccountGetter = Clones.clone(multiAccountGetter);

        LocalVariables memory _inputs = LocalVariables(_minimumCollateralRatio, _chainLinkRegistry, _allowedDelay);
        _initAccManager(vault, _inputs);
        _initborrowOps(vault);
        _initCollSurPlusPool(vault);
        _initMainPool(vault, _mainPoolContractOwner);
        _initSortedAccounts(vault);
        _initHintHelpers(vault);
        _initMultiAccountGetter(vault);

        vaultAddresses[vaultId] = vault;
        vaultId++;

        emit NewVaultDeployed(
            vault.accountManager,
            vault.borrowOperations,
            vault.collSurplusPool,
            vault.mainPool,
            vault.sortedAccounts,
            vault.depositToken,
            vault.hintHelpers,
            vault.multiAccountGetter
        );
    }

    function _initAccManager(
        VaultAddresses memory _vault,
        LocalVariables memory _inputs
    ) internal {

        DEAccountManager _accManager = DEAccountManager(_vault.accountManager);

        _accManager.initialize(
            unboundFeesFactory, 
            _vault.borrowOperations, 
            _vault.mainPool, 
            undToken, 
            _vault.sortedAccounts, 
            _vault.collSurplusPool, 
            _vault.depositToken, 
            _inputs._chainLinkRegistry, 
            _inputs._allowedDelay,
            goveranceFeeAddress, 
            _inputs._minimumCollateralRatio
        );
    }

    function _initborrowOps(VaultAddresses memory _vault) internal {
        DEBorrowOperations _borrowOps = DEBorrowOperations(_vault.borrowOperations);

        _borrowOps.initialize(_vault.accountManager);
    }

    function _initCollSurPlusPool(VaultAddresses memory _vault) internal {
        CollSurplusPool _collSurPlusPool = CollSurplusPool(_vault.collSurplusPool);

        _collSurPlusPool.initialize(_vault.accountManager, _vault.borrowOperations);
    }

    function _initMainPool(VaultAddresses memory _vault, address _owner) internal {
        MainPool _mainPool = MainPool(_vault.mainPool); 

        _mainPool.initialize(_vault.accountManager, _vault.borrowOperations, _vault.depositToken, _owner);
    }

    function _initSortedAccounts(VaultAddresses memory _vault) internal {
        SortedAccounts _sortedAccounts = SortedAccounts(_vault.sortedAccounts);

        _sortedAccounts.initialize(_vault.accountManager, _vault.borrowOperations);
    }

    function _initHintHelpers(VaultAddresses memory _vault) internal {
        HintHelpers _hintHelper = HintHelpers(_vault.hintHelpers);

        _hintHelper.initialize(_vault.accountManager, _vault.sortedAccounts);
    }

    function _initMultiAccountGetter(VaultAddresses memory _vault) internal {
        MultiAccountGetter _multiAccountGetter = MultiAccountGetter(_vault.multiAccountGetter);

        _multiAccountGetter.initialize(_vault.accountManager, _vault.sortedAccounts);
    }

    /// @dev Set all required contract address
    /// @param _accountManager DEAccountManager contracts implementation address
    /// @param _borrowOperations DEBorrowOperations contract implementation address
    /// @param _collSurplusPool CollSurplusPool contract implementation address
    /// @param _mainPool MainPool contract implementation address
    /// @param _sortedAccounts SortedAccounts contract implementation address
    /// @param _hintHelpers HintHelpers contract implementation address
    /// @param _multiAccountGetter MultiAccountGetter contract implementation address
    /// @param _unboundFeesFactory Unbound fees factory contracts
    /// @param _undToken UND token contract address
    /// @param _goveranceFeeAddress governance address where all the borrowing & redemption fees will be sent
    function setAddresses(
        address _accountManager,
        address _borrowOperations,
        address _collSurplusPool,
        address _mainPool,
        address _sortedAccounts,
        address _hintHelpers,
        address _multiAccountGetter,
        address _unboundFeesFactory,
        address _undToken,
        address _goveranceFeeAddress
    ) public onlyOwner {
        accountManager = _accountManager;
        borrowOperations = _borrowOperations;
        collSurplusPool = _collSurplusPool;
        mainPool = _mainPool;
        sortedAccounts = _sortedAccounts;
        hintHelpers = _hintHelpers;
        multiAccountGetter = _multiAccountGetter;
        unboundFeesFactory = _unboundFeesFactory;
        undToken = _undToken;
        goveranceFeeAddress = _goveranceFeeAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import './base/UnboundBase.sol';

import './interfaces/IAccountManager.sol';
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract HintHelpers is UnboundBase, Initializable{

    IAccountManager public accountManager;

    function initialize(
        address _accountManager,
        address _sortedAccounts
    ) public initializer {
        accountManager = IAccountManager(_accountManager);
        sortedAccounts = ISortedAccounts(_sortedAccounts);
        MCR = accountManager.MCR();
    }

    // --- Functions ---

    /* getRedemptionHints() - Helper function for finding the right hints to pass to redeemCollateral().
     *
     * It simulates a redemption of `_UNDamount` to figure out where the redemption sequence will start and what state the final Account
     * of the sequence will end up in.
     *
     * Returns three hints:
     *  - `firstRedemptionHint` is the address of the first Account with ICR >= MCR (i.e. the first Account that will be redeemed).
     *  - `partialRedemptionHintNICR` is the final nominal ICR of the last Account of the sequence after being hit by partial redemption,
     *     or zero in case of no partial redemption.
     *  - `truncatedUNDamount` is the maximum amount that can be redeemed out of the the provided `_UNDamount`. This can be lower than
     *    `_UNDamount` when redeeming the full amount would leave the last Account of the redemption sequence with less net debt than the
     *    minimum allowed value (i.e. MIN_NET_DEBT).
     *
     * The number of Accounts to consider for redemption can be capped by passing a non-zero value as `_maxIterations`, while passing zero
     * will leave it uncapped.
     */

    function getRedemptionHints(
        uint _UNDamount, 
        uint _price,
        uint _maxIterations
    )
        external
        view
        returns (
            address firstRedemptionHint,
            uint partialRedemptionHintNICR,
            uint truncatedUNDamount
        )
    {
        ISortedAccounts sortedAccountsCached = sortedAccounts;

        uint remainingUND = _UNDamount;
        address currentAccountuser = sortedAccountsCached.getLast();

        while (currentAccountuser != address(0) && accountManager.getCurrentICR(currentAccountuser, _price) < MCR) {
            currentAccountuser = sortedAccountsCached.getPrev(currentAccountuser);
        }

        firstRedemptionHint = currentAccountuser;

        if (_maxIterations == 0) {
            _maxIterations = type(uint256).max;
        }

        while (currentAccountuser != address(0) && remainingUND > 0 && _maxIterations > 0) {
            uint netUNDDebt = accountManager.getAccountDebt(currentAccountuser);
            if (netUNDDebt > remainingUND) {
                if (netUNDDebt > MIN_NET_DEBT) {
                    uint maxRedeemableUND = UnboundMath._min(remainingUND, netUNDDebt - MIN_NET_DEBT);

                    uint Collateral = accountManager.getAccountColl(currentAccountuser);

                    uint newColl = Collateral - ((maxRedeemableUND * DECIMAL_PRECISION) / _price);
                    uint newDebt = netUNDDebt - maxRedeemableUND;

                    partialRedemptionHintNICR = UnboundMath._computeNominalCR(newColl, newDebt);

                    remainingUND = remainingUND - maxRedeemableUND;

                }
                break;
            } else {
                remainingUND = remainingUND - netUNDDebt;
            }

            currentAccountuser = sortedAccountsCached.getPrev(currentAccountuser);
            _maxIterations--;
        }

        truncatedUNDamount = _UNDamount - remainingUND;
    }


    /* getApproxHint() - return address of a Account that is, on average, (length / numTrials) positions away in the 
    sortedAccounts list from the correct insert position of the Account to be inserted. 
    
    Note: The output address is worst-case O(n) positions away from the correct insert position, however, the function 
    is probabilistic. Input can be tuned to guarantee results to a high degree of confidence, e.g:

    Submitting numTrials = k * sqrt(length), with k = 15 makes it very, very likely that the ouput address will 
    be <= sqrt(length) positions away from the correct insert position.
    */

    function getApproxHint(uint _CR, uint _numTrials, uint _inputRandomSeed)
        external
        view
        returns (address hintAddress, uint diff, uint latestRandomSeed)
    {
        uint arrayLength = accountManager.getAccountOwnersCount();

        if (arrayLength == 0) {
            return (address(0), 0, _inputRandomSeed);
        }

        hintAddress = sortedAccounts.getLast();
        diff = UnboundMath._getAbsoluteDifference(_CR, accountManager.getNominalICR(hintAddress));
        latestRandomSeed = _inputRandomSeed;

        uint i = 1;

        while (i < _numTrials) {
            latestRandomSeed = uint(keccak256(abi.encodePacked(latestRandomSeed)));

            uint arrayIndex = latestRandomSeed % arrayLength;
            address currentAddress = accountManager.getAccountFromAccountOwnersArray(arrayIndex);
            uint currentNICR = accountManager.getNominalICR(currentAddress);

            // check if abs(current - CR) > abs(closest - CR), and update closest if current is closer
            uint currentDiff = UnboundMath._getAbsoluteDifference(currentNICR, _CR);

            if (currentDiff < diff) {
                diff = currentDiff;
                hintAddress = currentAddress;
            }
            i++;
        }

    }

    function computeNominalCR(uint _coll, uint _debt) external pure returns (uint) {
        return UnboundMath._computeNominalCR(_coll, _debt);
    }

    function computeCR(uint _coll, uint _debt, uint _price) external pure returns (uint) {
        return UnboundMath._computeCR(_coll, _debt, _price);
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

import "./IUnboundBase.sol";
interface IDEAccountManager is IUnboundBase{

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

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

interface IDefiEdgeStrategy {
    struct Tick {
        int24 tickLower;
        int24 tickUpper;
    }

    function getTicks() external view returns (Tick[] memory);

    function decimals() external view returns(uint256);
    
    function totalSupply() external view returns (uint256);

    function pool() external view returns (IUniswapV3Pool);

    function getAUMWithFees(bool _includeFee)
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 totalFee0,
            uint256 totalFee1
        );

    function burn(
        uint256 _shares,
        uint256 _amount0Min,
        uint256 _amount1Min
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IFarmingManager {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function depositAll() external;
    function withdrawAll() external;
    function distributeRewards(IERC20 _rewardToken) external returns(uint256 reward);
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

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

import "@chainlink/contracts/src/v0.8/Denominations.sol";

import "@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/PositionKey.sol";
import "@uniswap/v3-core/contracts/libraries/FixedPoint128.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/IChainlinkAggregatorV3Interface.sol";
import "../interfaces/IDEAccountManager.sol";
import "../interfaces/IUnboundBase.sol";
import "../interfaces/IDefiEdgeStrategy.sol";

library DESharePriceProvider {

    uint256 constant BASE = 1e18;

    // to get rid of stack too deep error
    struct LocalVariable_PositionData {
        uint128 liquidity;
        uint256 feeGrowthInside0Last;
        uint256 feeGrowthInside1Last;
        uint128 tokensOwed0;
        uint128 tokensOwed1;
        uint256 position0;
        uint256 position1;
        uint256 fee0;
        uint256 fee1;
    }

    struct LocalVariables_FeesData {
        uint256 feeGrowthGlobal0X;
        uint256 feeGrowthGlobal1X;
        uint256 feeGrowthOutside0XLower;
        uint256 feeGrowthOutside1XLower;
        uint256 feeGrowthOutside0XUpper;
        uint256 feeGrowthOutside1XUpper;
        uint256 feeGrowthBelow0X;
        uint256 feeGrowthBelow1X;
        uint256 feeGrowthAbove0X;
        uint256 feeGrowthAbove1X;
        uint256 feeGrowthInside0X;
        uint256 feeGrowthInside1X;
    }

    /**
     * Calculates the price of the pair token using the formula of arithmetic mean.
     * @param _shareToken Address of the Uniswap V2 pair
     * @param _reserve0 Total usd value for token 0.
     * @param _reserve1 Total usd value for token 1.
     * @return Arithematic mean of _reserve0 and _reserve1
     */
    function getArithmeticMean(
        IDefiEdgeStrategy _shareToken,
        uint256 _reserve0,
        uint256 _reserve1
    ) internal view returns (uint256) {
        uint256 totalValue = _reserve0 + _reserve1;
        return (totalValue * BASE) / getTotalSupply(_shareToken);
    }

    /**
     * @notice Returns Uniswap V2 pair total supply at the time of withdrawal.
     * @param _shareToken Address of the pair
     * @return totalSupply Total supply of the Defiedge share token at the time user withdraws
     */
    function getTotalSupply(IDefiEdgeStrategy _shareToken)
        internal
        view
        returns (uint256 totalSupply)
    {
        totalSupply = _shareToken.totalSupply();
        return totalSupply;
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
            normalised = uint256(_value) * 10**(missingDecimals);
        } else if (_decimals > 18) {
            uint256 extraDecimals = _decimals - uint256(18);
            normalised = uint256(_value) / 10**(extraDecimals);
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
    ) internal view returns (uint256 price) {
        (, int256 _price, , uint256 updatedAt, ) = _registry.latestRoundData(
            _base,
            _quote
        );

        // check if the oracle is expired
        require(block.timestamp - updatedAt < _validPeriod, "OLD_PRICE");
        require(_price > 0, "ERR_NO_ORACLE_PRICE");

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
        uint256 _reserve,
        uint256 _decimals
    ) internal pure returns (uint256) {
        uint256 reservePrice = normalise(_reserve, _decimals);
        return (reservePrice * _price) / BASE;
    }

    function getSqrtRatioForPrice(
        uint256 _token0Price,
        uint256 _token1Price,
        uint256 _token0Decimals,
        uint256 _token1Decimals
    ) internal pure returns (uint160 sqrtRatioX96) {
        sqrtRatioX96 = toUint160(
            sqrt(
                ((_token0Price * (10 ** _token1Decimals)) * (1 << 96)) /
                    (_token1Price * (10 ** _token0Decimals))
            ) << 48
        );
    }

    /**
     * @notice Calculate strategy AUM
     * @param _strategy Defiedge strategy contract instance
     * @param _pool UniswapV3 pool instance
     */
    function _getStrategyReserves(
        IDefiEdgeStrategy _strategy,
        IUniswapV3Pool _pool,
        uint160 sqrtRatioX96
    ) internal view returns (uint256 reserve0, uint256 reserve1) {

        // query all ticks from strategy
        IDefiEdgeStrategy.Tick[] memory ticks = _strategy.getTicks();

        // get unused amounts
        reserve0 = IERC20(_pool.token0()).balanceOf(address(_strategy));
        reserve1 = IERC20(_pool.token1()).balanceOf(address(_strategy));

        (, int24 tick, , , , , ) = _pool.slot0();

        // get AUM from each tick
        for (uint256 i = 0; i < ticks.length; i++) {
            IDefiEdgeStrategy.Tick memory _currTick = ticks[i];

            (uint256 amount0, uint256 amount1) = _calculateAUMAtTick(
                _currTick,
                _strategy,
                _pool,
                sqrtRatioX96,
                tick
            );

            reserve0 += amount0;
            reserve1 += amount1;
        }
    }

    // calculate strategy liquidity at specific tick
    function _calculateAUMAtTick(
        IDefiEdgeStrategy.Tick memory _tick,
        IDefiEdgeStrategy _strategy,
        IUniswapV3Pool _pool,
        uint160 sqrtRatioX96,
        int24 _tickSlot0
    ) internal view returns (uint256 amount0, uint256 amount1) {
        LocalVariable_PositionData memory _posData;
        // get current liquidity of strategy from the pool
        (
            _posData.liquidity,
            _posData.feeGrowthInside0Last,
            _posData.feeGrowthInside1Last,
            _posData.tokensOwed0,
            _posData.tokensOwed1
        ) = _pool.positions(
            PositionKey.compute(
                address(_strategy),
                _tick.tickLower,
                _tick.tickUpper
            )
        );

        // calculate x positions in the pool from liquidity
        (_posData.position0, _posData.position1) = LiquidityAmounts
            .getAmountsForLiquidity(
                sqrtRatioX96,
                TickMath.getSqrtRatioAtTick(_tick.tickLower),
                TickMath.getSqrtRatioAtTick(_tick.tickUpper),
                _posData.liquidity
            );

        // compute current fees earned
        (_posData.fee0, _posData.fee1) = _calculateUnclaimedFeesTotal(
            _posData.feeGrowthInside0Last,
            _posData.feeGrowthInside1Last,
            _tickSlot0,
            _posData.liquidity,
            _pool,
            _tick.tickLower,
            _tick.tickUpper
        );

        // sum of liquidity at specific tick, generated fees and tokenOwed
        amount0 +=
            _posData.position0 +
            _posData.fee0 +
            uint256(_posData.tokensOwed0);
        amount1 +=
            _posData.position1 +
            _posData.fee1 +
            uint256(_posData.tokensOwed1);
    }

    // calculate unclaimed fees for token0 and token1
    function _calculateUnclaimedFeesTotal(
        uint256 feeGrowthInside0Last,
        uint256 feeGrowthInside1Last,
        int24 tickCurrent,
        uint128 liquidity,
        IUniswapV3Pool pool,
        int24 lowerTick,
        int24 upperTick
    ) internal view returns (uint256 fee0, uint256 fee1) {
        LocalVariables_FeesData memory feesData;

        feesData.feeGrowthGlobal0X = pool.feeGrowthGlobal0X128();
        feesData.feeGrowthGlobal1X = pool.feeGrowthGlobal1X128();

        ( , , feesData.feeGrowthOutside0XLower, feesData.feeGrowthOutside1XLower, , , ,) = pool.ticks(lowerTick);
        ( , , feesData.feeGrowthOutside0XUpper, feesData.feeGrowthOutside1XUpper, , , ,) = pool.ticks(upperTick);

        // calculate fee growth below
        if (tickCurrent >= lowerTick) {
            feesData.feeGrowthBelow0X = feesData.feeGrowthOutside0XLower;
            feesData.feeGrowthBelow1X = feesData.feeGrowthOutside1XLower;
        } else {
            feesData.feeGrowthBelow0X =
                feesData.feeGrowthGlobal0X -
                feesData.feeGrowthOutside0XLower;
            feesData.feeGrowthBelow1X =
                feesData.feeGrowthGlobal1X -
                feesData.feeGrowthOutside1XLower;
        }

        // calculate fee growth above
        if (tickCurrent < upperTick) {
            feesData.feeGrowthAbove0X = feesData.feeGrowthOutside0XUpper;
            feesData.feeGrowthAbove1X = feesData.feeGrowthOutside1XUpper;
        } else {
            feesData.feeGrowthAbove0X =
                feesData.feeGrowthGlobal0X -
                feesData.feeGrowthOutside0XUpper;
            feesData.feeGrowthAbove1X =
                feesData.feeGrowthGlobal1X -
                feesData.feeGrowthOutside1XUpper;
        }

        feesData.feeGrowthInside0X =
            feesData.feeGrowthGlobal0X -
            feesData.feeGrowthBelow0X -
            feesData.feeGrowthAbove0X;
        feesData.feeGrowthInside1X =
            feesData.feeGrowthGlobal1X -
            feesData.feeGrowthBelow1X -
            feesData.feeGrowthAbove1X;

        fee0 = FullMath.mulDiv(
            feesData.feeGrowthInside0X - feeGrowthInside0Last,
            liquidity,
            FixedPoint128.Q128
        );

        fee1 = FullMath.mulDiv(
            feesData.feeGrowthInside1X - feeGrowthInside1Last,
            liquidity,
            FixedPoint128.Q128
        );
    }

    function _requireNoReentrant(IDefiEdgeStrategy defiedgeStrategy)
        internal
    {

        // revert if stratgy call failed with reentrant call error
        try defiedgeStrategy.burn(type(uint256).max, 0, 0) {} catch Error(
            string memory reason
        ) {
            if (
                keccak256(abi.encodePacked(reason)) ==
                keccak256(abi.encodePacked("ReentrancyGuard: reentrant call"))
            ) {
                revert(reason);
            }
        }
    }

    /**
     * @dev Returns the pair's price.
     *   It calculates the price using Chainlink as an external price source and the pair's tokens reserves using the arithmetic mean formula.
     * @param _accountManager Instance of AccountManager contract
     * @return int256 price
     */
    function latestAnswer(IDEAccountManager _accountManager)
        internal
        returns (int256)
    {
        FeedRegistryInterface chainLinkRegistry = FeedRegistryInterface(
            _accountManager.chainLinkRegistry()
        );

        uint256 _allowedDelay = _accountManager.allowedDelay();

        IDefiEdgeStrategy defiedgeStrategy = IDefiEdgeStrategy(
            address(_accountManager.depositToken())
        );

        // prevent reentrant calls from defiedge strategy contract
        _requireNoReentrant(defiedgeStrategy);

        IUniswapV3Pool pool = defiedgeStrategy.pool();

        uint256 token0Decimals = IERC20Metadata(pool.token0()).decimals();
        uint256 token1Decimals = IERC20Metadata(pool.token1()).decimals();

        uint256 chainlinkPrice0 = uint256(
            getChainlinkPrice(
                chainLinkRegistry,
                pool.token0(),
                Denominations.USD,
                _allowedDelay
            )
        );
        uint256 chainlinkPrice1 = uint256(
            getChainlinkPrice(
                chainLinkRegistry,
                pool.token1(),
                Denominations.USD,
                _allowedDelay
            )
        );

        // calculate sqrtRatio for defined chainlink price
        uint160 sqrtRatioX96 = getSqrtRatioForPrice(
            chainlinkPrice0,
            chainlinkPrice1,
            token0Decimals,
            token1Decimals
        );

        //Get token reserves in strategy
        (uint256 reserve0, uint256 reserve1) = _getStrategyReserves(
            defiedgeStrategy,
            pool,
            sqrtRatioX96
        );

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

        //Calculate the arithmetic mean
        return
            int256(
                getArithmeticMean(
                    defiedgeStrategy,
                    reserveInStablecoin0,
                    reserveInStablecoin1
                )
            );
    }

    function toUint160(uint256 x) private pure returns (uint160 z) {
        require((z = uint160(x)) == x, "uint160-overflow");
    }

    // FROM https://github.com/abdk-consulting/abdk-libraries-solidity/blob/16d7e1dd8628dfa2f88d5dadab731df7ada70bdd/ABDKMath64x64.sol#L687
    function sqrt(uint256 _x) private pure returns (uint128) {
        if (_x == 0) return 0;
        else {
            uint256 xx = _x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {
                xx >>= 128;
                r <<= 64;
            }
            if (xx >= 0x10000000000000000) {
                xx >>= 64;
                r <<= 32;
            }
            if (xx >= 0x100000000) {
                xx >>= 32;
                r <<= 16;
            }
            if (xx >= 0x10000) {
                xx >>= 16;
                r <<= 8;
            }
            if (xx >= 0x100) {
                xx >>= 8;
                r <<= 4;
            }
            if (xx >= 0x10) {
                xx >>= 4;
                r <<= 2;
            }
            if (xx >= 0x8) {
                r <<= 1;
            }
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = _x / r;
            return uint128(r < r1 ? r : r1);
        }
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import './interfaces/IMainPool.sol';
import './interfaces/IAccountManager.sol';
import './interfaces/IFarmingManager.sol';
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/*
 * The Main Pool holds the LP collateral and UND debt (but not UND tokens) for all active accounts.
 *
 * When a account is liquidated, it's LP Collateral and UND debt are transferred from the Main Pool, to liquidator. 
 * Also this pool will be responsible for all the farming operations and it's rewards
 *
 */

 contract MainPool is IMainPool, Ownable, ReentrancyGuard, Initializable {
    using SafeERC20 for IERC20;

    address public borrowerOperations;
    address public accountManager;

    uint256 internal _collateral;  // deposited collateral tracker
    uint256 internal _UNDDebt;

    uint256 public override undMintLimit;

    uint256 public farmingContractAddTime;
    address public pendingFarmingContract;

    /* ========== FARMING REWARD STATE VARIABLES ========== */

    struct Reward {
        uint256 lastDistributedReward;
        uint256 rewardPerTokenStored;
    }

    mapping(address => Reward) public rewardData;
    address[] public rewardTokens;
    
    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    IERC20 public depositToken;

    IFarmingManager public farmingManager;

    event NewFarmingManagerPurposed(address _newFarmingManager);
    event NewFarmingManagerEnabled(address _newFarmingManager);

     // user -> reward token -> amount
    mapping(address => mapping(address => uint256)) public userRewardPerTokenPaid;
    mapping(address => mapping(address => uint256)) public rewards;

    function initialize(address _accountManager, address _borrowerOperations, address _depositToken, address _owner) public initializer {
        accountManager = _accountManager;
        borrowerOperations = _borrowerOperations;
        depositToken = IERC20(_depositToken);

        _transferOwnership(_owner);
    }

    // --- Pool functionality ---
    
    function increaseCollateral(uint _amount) external override {
        _requireCallerIsBO();
        uint256 newCollateral = _collateral + _amount;
        _collateral  = newCollateral;
        emit MainPoolCollateralBalanceUpdated(newCollateral);
    }

    function sendCollateral(IERC20 _depositToken, address _account, uint _amount) external override {
        _requireCallerIsAccountManagerOrBO();
        uint256 newCollateral = _collateral - _amount;
        _collateral  = newCollateral;
        emit MainPoolCollateralBalanceUpdated(newCollateral);
        emit CollateralSent(_account, _amount);

        _depositToken.safeTransfer(_account, _amount);
    }

    function increaseUNDDebt(uint _amount) external override {
        _requireCallerIsBO();
        uint256 newDebt = _UNDDebt + _amount;
        _UNDDebt  = newDebt;
        emit MainPoolUNDDebtUpdated(newDebt);
    }

    function decreaseUNDDebt(uint _amount) external override {
        _requireCallerIsAccountManagerOrBO();
        uint256 newDebt = _UNDDebt - _amount;
        _UNDDebt  = newDebt;
        emit MainPoolUNDDebtUpdated(newDebt);
    }

    // --- Getters for public variables. Required by IPool interface ---

    /*
    * Returns the state variable.
    *
    *Not necessarily equal to the the contract's raw Collateral balance - LP can be forcibly sent to contracts.
    */
    function getCollateral() external view override returns (uint) {
        return _collateral;
    }

    function getUNDDebt() external view override returns (uint) {
        return _UNDDebt;
    }

    // change UND mint limit for this specific vault
    function changeUNDMintLimit(uint256 _newMintLimit) external onlyOwner{
        undMintLimit = _newMintLimit;
        emit UNDMintLimitChanged(_newMintLimit);
    }

    // --- 'require' functions ---

    function _requireCallerIsBO() internal view {
        require(
            msg.sender == borrowerOperations,
            "MainPool: Caller is not BorrowerOperations");
    }
    
    function _requireCallerIsAccountManagerOrBO() internal view {
        require(
            msg.sender == borrowerOperations || msg.sender == accountManager,
            "MainPool: Caller is not BorrowerOperations or AccountManager");
    }

    // ----- FARMING section -----

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function rewardPerToken(address _rewardsToken) public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardData[_rewardsToken].rewardPerTokenStored;
        }
        return
            rewardData[_rewardsToken].rewardPerTokenStored + ((rewardData[_rewardsToken].lastDistributedReward * 1e18) / _totalSupply);
    }

    function earned(address account, address _rewardsToken) public view returns (uint256) {
        return ((_balances[account] * (rewardData[_rewardsToken].rewardPerTokenStored - userRewardPerTokenPaid[account][_rewardsToken])) / 1e18) + rewards[account][_rewardsToken];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */ 

    function addReward(
        address _rewardsToken
    )
        public
        onlyOwner
    {
        rewardTokens.push(_rewardsToken);
    }

    function removeReward(
        uint256 _rewardsTokenIndex
    )
        public
        updateReward(address(0))
        onlyOwner
    {
        address _rewardsToken = rewardTokens[_rewardsTokenIndex];

        if(rewardTokens.length > 1){
            address lastElement = rewardTokens[rewardTokens.length - 1];
            rewardTokens[_rewardsTokenIndex] = lastElement;
        }

        rewardTokens.pop();

        rewardData[_rewardsToken].lastDistributedReward = 0;

        IERC20(_rewardsToken).safeTransfer(owner(), IERC20(_rewardsToken).balanceOf(address(this)));
    }

    function addFarmingManagerContract(address _farmingManager) external onlyOwner {
        farmingContractAddTime = block.timestamp;
        pendingFarmingContract = _farmingManager;

        emit NewFarmingManagerPurposed(_farmingManager);
    }

    // Withdraw all existing staked tokens, change farmingManager address and deposit al tokens to new farming contract
    function enableFarmingManagerContract() external onlyOwner updateReward(address(0)){
        require(farmingContractAddTime > 0, "MainPool: Nothing to enable");
        require(block.timestamp - farmingContractAddTime >= 3 days, "MainPool: too early");

        // revoke approve permission from old farming manager if have any & withdraw all staked tokens
        if(address(farmingManager) != address(0)){
            depositToken.safeApprove(address(farmingManager), 0);
            farmingManager.withdrawAll();
        }

        require(depositToken.balanceOf(address(this)) >= _collateral, "MainPool: Insufficient collateral");

        farmingManager = IFarmingManager(pendingFarmingContract);

        pendingFarmingContract = address(0);
        farmingContractAddTime = 0;
        
        // approve farming manager contract & stake all tokens to new farming contract
        if(address(farmingManager) != address(0)){
            depositToken.safeApprove(address(farmingManager), type(uint256).max); 
            farmingManager.depositAll();
        }

        emit NewFarmingManagerEnabled(address(farmingManager));
    }

    function stake(address user, uint256 amount) external override nonReentrant updateReward(user) {
        _requireCallerIsBO();

        _totalSupply = _totalSupply + amount;
        _balances[user] = _balances[user] + amount;
        
        if(address(farmingManager) != address(0)){

            farmingManager.deposit(amount);
            emit Staked(user, amount);
        }
    }

    function unstake(address user, uint256 amount) external override nonReentrant updateReward(user) {
        _requireCallerIsAccountManagerOrBO();
        
        _totalSupply = _totalSupply - amount;
        _balances[user] = _balances[user] - amount;
        
        if(address(farmingManager) != address(0)){

            farmingManager.withdraw(amount);
            emit Unstaked(user, amount);
        }
    }

    function getReward() public nonReentrant updateReward(msg.sender) returns(uint256 reward){
        for (uint i; i < rewardTokens.length; i++) {
            address _rewardsToken = rewardTokens[i];
            reward = rewards[msg.sender][_rewardsToken];
            if (reward > 0) {
                rewards[msg.sender][_rewardsToken] = 0;
                IERC20(_rewardsToken).safeTransfer(msg.sender, reward);
                emit RewardPaid(msg.sender, _rewardsToken, reward);
            }
        }
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {

        if(address(farmingManager) != address(0)){

            for (uint i; i < rewardTokens.length; i++) {

                address token = rewardTokens[i];

                uint256 _reward = farmingManager.distributeRewards(IERC20(token));

                rewardData[token].lastDistributedReward = _reward;
                rewardData[token].rewardPerTokenStored = rewardPerToken(token);

                if (account != address(0)) {
                    rewards[account][token] = earned(account, token);
                    userRewardPerTokenPaid[account][token] = rewardData[token].rewardPerTokenStored;
                }
            }
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address indexed rewardsToken, uint256 reward);
    event RewardsDurationUpdated(address token, uint256 newDuration);
 }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./AccountManager.sol";
import "./interfaces/ISortedAccounts.sol";

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/*  Helper contract for grabbing Account data for the front end. Not part of the core Unbound system. */
contract MultiAccountGetter is Initializable{
    struct CombinedAccountData {
        address owner;
        uint debt;
        uint coll;
    }

    AccountManager public accountManager;
    ISortedAccounts public sortedAccounts;

    function initialize(address _accountManager, address _sortedAccounts) public initializer {
        accountManager = AccountManager(_accountManager);
        sortedAccounts = ISortedAccounts(_sortedAccounts);
    }

    function getMultipleSortedAccounts(int _startIdx, uint _count)
        external view returns (CombinedAccountData[] memory _accounts)
    {
        uint startIdx;
        bool descend;

        if (_startIdx >= 0) {
            startIdx = uint(_startIdx);
            descend = true;
        } else {
            startIdx = uint(-(_startIdx + 1));
            descend = false;
        }

        uint sortedAccountsSize = sortedAccounts.getSize();

        if (startIdx >= sortedAccountsSize) {
            _accounts = new CombinedAccountData[](0);
        } else {
            uint maxCount = sortedAccountsSize - startIdx;

            if (_count > maxCount) {
                _count = maxCount;
            }

            if (descend) {
                _accounts = _getMultipleSortedAccountsFromHead(startIdx, _count);
            } else {
                _accounts = _getMultipleSortedAccountsFromTail(startIdx, _count);
            }
        }
    }

    function _getMultipleSortedAccountsFromHead(uint _startIdx, uint _count)
        internal view returns (CombinedAccountData[] memory _accounts)
    {
        address currentAccountowner = sortedAccounts.getFirst();

        for (uint idx = 0; idx < _startIdx; ++idx) {
            currentAccountowner = sortedAccounts.getNext(currentAccountowner);
        }

        _accounts = new CombinedAccountData[](_count);

        for (uint idx = 0; idx < _count; ++idx) {
            _accounts[idx].owner = currentAccountowner;
            (
                _accounts[idx].debt,
                _accounts[idx].coll,
                /* status */,
                /* arrayIndex */
            ) = accountManager.Accounts(currentAccountowner);

            currentAccountowner = sortedAccounts.getNext(currentAccountowner);
        }
    }

    function _getMultipleSortedAccountsFromTail(uint _startIdx, uint _count)
        internal view returns (CombinedAccountData[] memory _accounts)
    {
        address currentAccountowner = sortedAccounts.getLast();

        for (uint idx = 0; idx < _startIdx; ++idx) {
            currentAccountowner = sortedAccounts.getPrev(currentAccountowner);
        }

        _accounts = new CombinedAccountData[](_count);

        for (uint idx = 0; idx < _count; ++idx) {
            _accounts[idx].owner = currentAccountowner;
            (
                _accounts[idx].debt,
                _accounts[idx].coll,
                /* status */,
                /* arrayIndex */
            ) = accountManager.Accounts(currentAccountowner);

            currentAccountowner = sortedAccounts.getPrev(currentAccountowner);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./interfaces/ISortedAccounts.sol";
import "./interfaces/IAccountManager.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/*
* A sorted doubly linked list with nodes sorted in descending order.
*
* Nodes map to active Accounts in the system - the ID property is the address of a Account owner.
* Nodes are ordered according to their current nominal individual collateral ratio (NICR),
* which is like the ICR but without the price, i.e., just collateral / debt.
*
* The list optionally accepts insert position hints.
*
* NICRs are computed dynamically at runtime, and not stored on the Node. This is because NICRs of active Accounts
* change dynamically as liquidation events occur.
*
* The list relies on the fact that liquidation events preserve ordering: a liquidation decreases the NICRs of all active Accounts,
* but maintains their order. A node inserted based on current NICR will maintain the correct position,
* relative to it's peers, as rewards accumulate, as long as it's raw collateral and debt have not changed.
* Thus, Nodes remain sorted by current NICR.
*
* Nodes need only be re-inserted upon a Account operation - when the owner adds or removes collateral or debt
* to their position.
*
* The list is a modification of the following audited SortedDoublyLinkedList:
* https://github.com/livepeer/protocol/blob/master/contracts/libraries/SortedDoublyLL.sol
*
*
* Changes made in the Unbound implementation:
*
* - Keys have been removed from nodes
*
* - Ordering checks for insertion are performed by comparing an NICR argument to the current NICR, calculated at runtime.
*   The list relies on the property that ordering by ICR is maintained as the LP:USD price varies.
*
* - Public functions with parameters have been made internal to save gas, and given an external wrapper function for external access
*/
contract SortedAccounts is ISortedAccounts, Initializable {

    address public borrowerOperations;

    IAccountManager public accountManager;

    // Information for a node in the list
    struct Node {
        bool exists;
        address nextId;                  // Id of next node (smaller NICR) in the list
        address prevId;                  // Id of previous node (larger NICR) in the list
    }

    // Information for the list
    struct Data {
        address head;                        // Head of the list. Also the node in the list with the largest NICR
        address tail;                        // Tail of the list. Also the node in the list with the smallest NICR
        uint256 maxSize;                     // Maximum size of the list
        uint256 size;                        // Current size of the list
        mapping (address => Node) nodes;     // Track the corresponding ids for each node in the list
    }

    Data public data;


    function initialize(address _accountManager, address _borrowerOperations) public initializer {
        data.maxSize = type(uint256).max;

        accountManager = IAccountManager(_accountManager);
        borrowerOperations = _borrowerOperations;
    }

    /*
     * @dev Add a node to the list
     * @param _id Node's id
     * @param _NICR Node's NICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */

    function insert (address _id, uint256 _NICR, address _prevId, address _nextId) external override {
        IAccountManager accountManagerCached = accountManager;

        _requireCallerIsBOorAccountM(accountManagerCached);
        _insert(accountManagerCached, _id, _NICR, _prevId, _nextId);
    }

    function _insert(IAccountManager _accountManager, address _id, uint256 _NICR, address _prevId, address _nextId) internal {
        // List must not be full
        require(!isFull(), "SortedAccounts: List is full");
        // List must not already contain node
        require(!contains(_id), "SortedAccounts: List already contains the node");
        // Node id must not be null
        require(_id != address(0), "SortedAccounts: Id cannot be zero");
        // NICR must be non-zero
        require(_NICR > 0, "SortedAccounts: NICR must be positive");

        address prevId = _prevId;
        address nextId = _nextId;

        if (!_validInsertPosition(_accountManager, _NICR, prevId, nextId)) {
            // Sender's hint was not a valid insert position
            // Use sender's hint to find a valid insert position
            (prevId, nextId) = _findInsertPosition(_accountManager, _NICR, prevId, nextId);
        }

         data.nodes[_id].exists = true;

        if (prevId == address(0) && nextId == address(0)) {
            // Insert as head and tail
            data.head = _id;
            data.tail = _id;
        } else if (prevId == address(0)) {
            // Insert before `prevId` as the head
            data.nodes[_id].nextId = data.head;
            data.nodes[data.head].prevId = _id;
            data.head = _id;
        } else if (nextId == address(0)) {
            // Insert after `nextId` as the tail
            data.nodes[_id].prevId = data.tail;
            data.nodes[data.tail].nextId = _id;
            data.tail = _id;
        } else {
            // Insert at insert position between `prevId` and `nextId`
            data.nodes[_id].nextId = nextId;
            data.nodes[_id].prevId = prevId;
            data.nodes[prevId].nextId = _id;
            data.nodes[nextId].prevId = _id;
        }

        data.size = data.size + 1;
        emit NodeAdded(_id, _NICR);
    }

    function remove(address _id) external override {
        _requireCallerIsAccountManager();
        _remove(_id);
    }

    /*
     * @dev Remove a node from the list
     * @param _id Node's id
     */
    function _remove(address _id) internal {
        // List must contain the node
        require(contains(_id), "SortedAccounts: List does not contain the id");

        if (data.size > 1) {
            // List contains more than a single node
            if (_id == data.head) {
                // The removed node is the head
                // Set head to next node
                data.head = data.nodes[_id].nextId;
                // Set prev pointer of new head to null
                data.nodes[data.head].prevId = address(0);
            } else if (_id == data.tail) {
                // The removed node is the tail
                // Set tail to previous node
                data.tail = data.nodes[_id].prevId;
                // Set next pointer of new tail to null
                data.nodes[data.tail].nextId = address(0);
            } else {
                // The removed node is neither the head nor the tail
                // Set next pointer of previous node to the next node
                data.nodes[data.nodes[_id].prevId].nextId = data.nodes[_id].nextId;
                // Set prev pointer of next node to the previous node
                data.nodes[data.nodes[_id].nextId].prevId = data.nodes[_id].prevId;
            }
        } else {
            // List contains a single node
            // Set the head and tail to null
            data.head = address(0);
            data.tail = address(0);
        }

        delete data.nodes[_id];
        data.size = data.size - 1;
        emit NodeRemoved(_id);
    }

    /*
     * @dev Re-insert the node at a new position, based on its new NICR
     * @param _id Node's id
     * @param _newNICR Node's new NICR
     * @param _prevId Id of previous node for the new insert position
     * @param _nextId Id of next node for the new insert position
     */
    function reInsert(address _id, uint256 _newNICR, address _prevId, address _nextId) external override {
        IAccountManager accountManagerCached = accountManager;

        _requireCallerIsBOorAccountM(accountManagerCached);
        // List must contain the node
        require(contains(_id), "SortedAccounts: List does not contain the id");
        // NICR must be non-zero
        require(_newNICR > 0, "SortedAccounts: NICR must be positive");

        // Remove node from the list
        _remove(_id);

        _insert(accountManagerCached, _id, _newNICR, _prevId, _nextId);
    }

    /*
     * @dev Checks if the list contains a node
     */
    function contains(address _id) public view override returns (bool) {
        return data.nodes[_id].exists;
    }

    /*
     * @dev Checks if the list is full
     */
    function isFull() public view override returns (bool) {
        return data.size == data.maxSize;
    }

    /*
     * @dev Checks if the list is empty
     */
    function isEmpty() public view override returns (bool) {
        return data.size == 0;
    }

    /*
     * @dev Returns the current size of the list
     */
    function getSize() external view override returns (uint256) {
        return data.size;
    }

    /*
     * @dev Returns the maximum size of the list
     */
    function getMaxSize() external view override returns (uint256) {
        return data.maxSize;
    }

    /*
     * @dev Returns the first node in the list (node with the largest NICR)
     */
    function getFirst() external view override returns (address) {
        return data.head;
    }

    /*
     * @dev Returns the last node in the list (node with the smallest NICR)
     */
    function getLast() external view override returns (address) {
        return data.tail;
    }

    /*
     * @dev Returns the next node (with a smaller NICR) in the list for a given node
     * @param _id Node's id
     */
    function getNext(address _id) external view override returns (address) {
        return data.nodes[_id].nextId;
    }

    /*
     * @dev Returns the previous node (with a larger NICR) in the list for a given node
     * @param _id Node's id
     */
    function getPrev(address _id) external view override returns (address) {
        return data.nodes[_id].prevId;
    }

    /*
     * @dev Check if a pair of nodes is a valid insertion point for a new node with the given NICR
     * @param _NICR Node's NICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */
    function validInsertPosition(uint256 _NICR, address _prevId, address _nextId) external view override returns (bool) {
        return _validInsertPosition(accountManager, _NICR, _prevId, _nextId);
    }

    function _validInsertPosition(IAccountManager _accountManager, uint256 _NICR, address _prevId, address _nextId) internal view returns (bool) {
        if (_prevId == address(0) && _nextId == address(0)) {
            // `(null, null)` is a valid insert position if the list is empty
            return isEmpty();
        } else if (_prevId == address(0)) {
            // `(null, _nextId)` is a valid insert position if `_nextId` is the head of the list
            return data.head == _nextId && _NICR >= _accountManager.getNominalICR(_nextId);
        } else if (_nextId == address(0)) {
            // `(_prevId, null)` is a valid insert position if `_prevId` is the tail of the list
            return data.tail == _prevId && _NICR <= _accountManager.getNominalICR(_prevId);
        } else {
            // `(_prevId, _nextId)` is a valid insert position if they are adjacent nodes and `_NICR` falls between the two nodes' NICRs
            return data.nodes[_prevId].nextId == _nextId &&
                   _accountManager.getNominalICR(_prevId) >= _NICR &&
                   _NICR >= _accountManager.getNominalICR(_nextId);
        }
    }

    /*
     * @dev Descend the list (larger NICRs to smaller NICRs) to find a valid insert position
     * @param _accountManager AccountManager contract, passed in as param to save SLOAD’s
     * @param _NICR Node's NICR
     * @param _startId Id of node to start descending the list from
     */
    function _descendList(IAccountManager _accountManager, uint256 _NICR, address _startId) internal view returns (address, address) {
        // If `_startId` is the head, check if the insert position is before the head
        if (data.head == _startId && _NICR >= _accountManager.getNominalICR(_startId)) {
            return (address(0), _startId);
        }

        address prevId = _startId;
        address nextId = data.nodes[prevId].nextId;

        // Descend the list until we reach the end or until we find a valid insert position
        while (prevId != address(0) && !_validInsertPosition(_accountManager, _NICR, prevId, nextId)) {
            prevId = nextId;
            nextId = data.nodes[prevId].nextId;
        }

        return (prevId, nextId);
    }

    /*
     * @dev Ascend the list (smaller NICRs to larger NICRs) to find a valid insert position
     * @param _accountManager AccountManager contract, passed in as param to save SLOAD’s
     * @param _NICR Node's NICR
     * @param _startId Id of node to start ascending the list from
     */
    function _ascendList(IAccountManager _accountManager, uint256 _NICR, address _startId) internal view returns (address, address) {
        // If `_startId` is the tail, check if the insert position is after the tail
        if (data.tail == _startId && _NICR <= _accountManager.getNominalICR(_startId)) {
            return (_startId, address(0));
        }

        address nextId = _startId;
        address prevId = data.nodes[nextId].prevId;

        // Ascend the list until we reach the end or until we find a valid insertion point
        while (nextId != address(0) && !_validInsertPosition(_accountManager, _NICR, prevId, nextId)) {
            nextId = prevId;
            prevId = data.nodes[nextId].prevId;
        }

        return (prevId, nextId);
    }

    /*
     * @dev Find the insert position for a new node with the given NICR
     * @param _NICR Node's NICR
     * @param _prevId Id of previous node for the insert position
     * @param _nextId Id of next node for the insert position
     */
    function findInsertPosition(uint256 _NICR, address _prevId, address _nextId) external view override returns (address, address) {
        return _findInsertPosition(accountManager, _NICR, _prevId, _nextId);
    }

    function _findInsertPosition(IAccountManager _accountManager, uint256 _NICR, address _prevId, address _nextId) internal view returns (address, address) {
        address prevId = _prevId;
        address nextId = _nextId;

        if (prevId != address(0)) {
            if (!contains(prevId) || _NICR > _accountManager.getNominalICR(prevId)) {
                // `prevId` does not exist anymore or now has a smaller NICR than the given NICR
                prevId = address(0);
            }
        }

        if (nextId != address(0)) {
            if (!contains(nextId) || _NICR < _accountManager.getNominalICR(nextId)) {
                // `nextId` does not exist anymore or now has a larger NICR than the given NICR
                nextId = address(0);
            }
        }

        if (prevId == address(0) && nextId == address(0)) {
            // No hint - descend list starting from head
            return _descendList(_accountManager, _NICR, data.head);
        } else if (prevId == address(0)) {
            // No `prevId` for hint - ascend list starting from `nextId`
            return _ascendList(_accountManager, _NICR, nextId);
        } else if (nextId == address(0)) {
            // No `nextId` for hint - descend list starting from `prevId`
            return _descendList(_accountManager, _NICR, prevId);
        } else {
            // Descend list starting from `prevId`
            return _descendList(_accountManager, _NICR, prevId);
        }
    }

    // --- 'require' functions ---

    function _requireCallerIsAccountManager() internal view {
        require(msg.sender == address(accountManager), "SortedAccounts: Caller is not the AccountManager");
    }

    function _requireCallerIsBOorAccountM(IAccountManager _accountManager) internal view {
        require(msg.sender == borrowerOperations || msg.sender == address(_accountManager),
                "SortedAccounts: Caller is neither BO nor AccountManager");
    }
}