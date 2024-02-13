// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";
import {Initializable} from "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:storage-location erc7201:openzeppelin.storage.Ownable
    struct OwnableStorage {
        address _owner;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Ownable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant OwnableStorageLocation = 0x9016d09d72d40fdae2fd8ceac6b6234c7706214fd39c1cd1e609a0528c199300;

    function _getOwnableStorage() private pure returns (OwnableStorage storage $) {
        assembly {
            $.slot := OwnableStorageLocation
        }
    }

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    function __Ownable_init(address initialOwner) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner);
    }

    function __Ownable_init_unchained(address initialOwner) internal onlyInitializing {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        OwnableStorage storage $ = _getOwnableStorage();
        return $._owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        OwnableStorage storage $ = _getOwnableStorage();
        address oldOwner = $._owner;
        $._owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.20;

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
     * @dev Storage of the initializable contract.
     *
     * It's implemented on a custom ERC-7201 namespace to reduce the risk of storage collisions
     * when using with upgradeable contracts.
     *
     * @custom:storage-location erc7201:openzeppelin.storage.Initializable
     */
    struct InitializableStorage {
        /**
         * @dev Indicates that the contract has been initialized.
         */
        uint64 _initialized;
        /**
         * @dev Indicates that the contract is in the process of being initialized.
         */
        bool _initializing;
    }

    // keccak256(abi.encode(uint256(keccak256("openzeppelin.storage.Initializable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant INITIALIZABLE_STORAGE = 0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    /**
     * @dev The contract is already initialized.
     */
    error InvalidInitialization();

    /**
     * @dev The contract is not initializing.
     */
    error NotInitializing();

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint64 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that in the context of a constructor an `initializer` may be invoked any
     * number of times. This behavior in the constructor can be useful during testing and is not expected to be used in
     * production.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        // Cache values to avoid duplicated sloads
        bool isTopLevelCall = !$._initializing;
        uint64 initialized = $._initialized;

        // Allowed calls:
        // - initialSetup: the contract is not in the initializing state and no previous version was
        //                 initialized
        // - construction: the contract is initialized at version 1 (no reininitialization) and the
        //                 current contract is just being deployed
        bool initialSetup = initialized == 0 && isTopLevelCall;
        bool construction = initialized == 1 && address(this).code.length == 0;

        if (!initialSetup && !construction) {
            revert InvalidInitialization();
        }
        $._initialized = 1;
        if (isTopLevelCall) {
            $._initializing = true;
        }
        _;
        if (isTopLevelCall) {
            $._initializing = false;
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
     * WARNING: Setting the version to 2**64 - 1 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint64 version) {
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing || $._initialized >= version) {
            revert InvalidInitialization();
        }
        $._initialized = version;
        $._initializing = true;
        _;
        $._initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        _checkInitializing();
        _;
    }

    /**
     * @dev Reverts if the contract is not in an initializing state. See {onlyInitializing}.
     */
    function _checkInitializing() internal view virtual {
        if (!_isInitializing()) {
            revert NotInitializing();
        }
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
        // solhint-disable-next-line var-name-mixedcase
        InitializableStorage storage $ = _getInitializableStorage();

        if ($._initializing) {
            revert InvalidInitialization();
        }
        if ($._initialized != type(uint64).max) {
            $._initialized = type(uint64).max;
            emit Initialized(type(uint64).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint64) {
        return _getInitializableStorage()._initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _getInitializableStorage()._initializing;
    }

    /**
     * @dev Returns a pointer to the storage namespace.
     */
    // solhint-disable-next-line var-name-mixedcase
    function _getInitializableStorage() private pure returns (InitializableStorage storage $) {
        assembly {
            $.slot := INITIALIZABLE_STORAGE
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;
import {Initializable} from "../proxy/utils/Initializable.sol";

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/Math.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Muldiv operation overflow.
     */
    error MathOverflowedMulDiv();

    enum Rounding {
        Floor, // Toward negative infinity
        Ceil, // Toward positive infinity
        Trunc, // Toward zero
        Expand // Away from zero
    }

    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
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
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
     * This differs from standard division with `/` in that it rounds towards infinity instead
     * of rounding towards zero.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b == 0) {
            // Guarantee the same behavior as in a regular Solidity division.
            return a / b;
        }

        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or
     * denominator == 0.
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv) with further edits by
     * Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0 = x * y; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            if (denominator <= prod1) {
                revert MathOverflowedMulDiv();
            }

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

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator.
            // Always >= 1. See https://cs.stackexchange.com/q/138556/92363.

            uint256 twos = denominator & (0 - denominator);
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

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also
            // works in modular arithmetic, doubling the correct bits in each step.
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (unsignedRoundsUp(rounding) && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded
     * towards zero.
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
            return result + (unsignedRoundsUp(rounding) && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2 of a positive value rounded towards zero.
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
            return result + (unsignedRoundsUp(rounding) && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10 of a positive value rounded towards zero.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (unsignedRoundsUp(rounding) && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256 of a positive value rounded towards zero.
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (unsignedRoundsUp(rounding) && 1 << (result << 3) < value ? 1 : 0);
        }
    }

    /**
     * @dev Returns whether a provided rounding mode is considered rounding up for unsigned integers.
     */
    function unsignedRoundsUp(Rounding rounding) internal pure returns (bool) {
        return uint8(rounding) % 2 == 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.20;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (utils/Strings.sol)

pragma solidity ^0.8.20;

import {Math} from "./math/Math.sol";
import {SignedMath} from "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant HEX_DIGITS = "0123456789abcdef";
    uint8 private constant ADDRESS_LENGTH = 20;

    /**
     * @dev The `value` string doesn't fit in the specified `length`.
     */
    error StringsInsufficientHexLength(uint256 value, uint256 length);

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
                    mstore8(ptr, byte(mod(value, 10), HEX_DIGITS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toStringSigned(int256 value) internal pure returns (string memory) {
        return string.concat(value < 0 ? "-" : "", toString(SignedMath.abs(value)));
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
        uint256 localValue = value;
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        if (localValue != 0) {
            revert StringsInsufficientHexLength(value, length);
        }
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return bytes(a).length == bytes(b).length && keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./utils/StrUtil.sol";

contract Hyperdust_Roles_Cfg is OwnableUpgradeable {
    using Strings for *;
    using StrUtil for *;

    mapping(address => bool) public _adminRole;
    mapping(address => bool) public _superAsdminRole;

    function initialize() public initializer {
        __Ownable_init(msg.sender);
        _adminRole[msg.sender] = true;
    }

    function addAdmin(address account) public onlyOwner {
        require(!_adminRole[account], "administrator already exists");
        _adminRole[account] = true;
    }

    function addSuperAdmin(address account) public onlyOwner {
        require(!_superAsdminRole[account], "administrator already exists");
        _superAsdminRole[account] = true;
    }

    function addAdmin2(address account) public {
        require(_superAsdminRole[msg.sender], "not super admin role");
        require(!_adminRole[account], "administrator already exists");
        _adminRole[account] = true;
    }

    function hasAdminRole(address account) public view returns (bool) {
        return _adminRole[account];
    }

    function deleteAdmin(address account) public onlyOwner {
        _adminRole[account] = false;
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../utils/StrUtil.sol";
import "../Hyperdust_Roles_Cfg.sol";
import "../MOSSAI_Storage.sol";

abstract contract IMOSSAIIsland {
    function getIsland(
        uint256 islandId
    )
        public
        view
        returns (
            uint256,
            string memory,
            string memory,
            string memory,
            string memory,
            address,
            address,
            uint256,
            uint32,
            bytes32
        )
    {}
}

abstract contract IMOSSAIIslandNFG {
    function getSeedOwer(uint32 seed) public view returns (address) {}
}

contract MOSSAI_Island_Airdrop is OwnableUpgradeable {
    using Strings for *;
    using StrUtil for *;

    uint256 private _rand;

    address public _MOSSAIRolesCfgAddress;
    address public _erc20Address;
    address public _MOSSAIIslandAddress;
    address public _MOSSAIIslandNFGAddress;
    address public _MOSSAIStorageAddress;

    function initialize(address onlyOwner) public initializer {
        _rand = 1;
        __Ownable_init(onlyOwner);
    }

    function setMOSSAIRolesCfgAddress(
        address MOSSAIRolesCfgAddress
    ) public onlyOwner {
        _MOSSAIRolesCfgAddress = MOSSAIRolesCfgAddress;
    }

    function setErc20Address(address erc20Address) public onlyOwner {
        _erc20Address = erc20Address;
    }

    function setMOSSAIIslandAddress(
        address MOSSAIIslandAddress
    ) public onlyOwner {
        _MOSSAIIslandAddress = MOSSAIIslandAddress;
    }

    function setMOSSAIIslandNFGAddress(
        address MOSSAIIslandNFGAddress
    ) public onlyOwner {
        _MOSSAIIslandNFGAddress = MOSSAIIslandNFGAddress;
    }

    function setMOSSAIStorageAddress(
        address MOSSAIStorageAddress
    ) public onlyOwner {
        _MOSSAIStorageAddress = MOSSAIStorageAddress;
    }

    event eveSave(uint256 id);

    event eveDelete(uint256 id);

    event eveReceiveAirdrop(uint256 id, address to, uint256 amount);

    function addIslandAirdrop(
        string memory name,
        uint256[] memory uint256Array,
        uint256 startTime,
        uint256 endTime,
        string memory airdropConfig,
        bytes1 status,
        address fromAddress,
        uint256 intervalTime
    ) public {
        require(
            Hyperdust_Roles_Cfg(_MOSSAIRolesCfgAddress).hasAdminRole(
                msg.sender
            ),
            "not admin role"
        );

        if (uint256Array[3] != 0) {
            (uint256 _id, , , , , , , , , ) = IMOSSAIIsland(
                _MOSSAIIslandAddress
            ).getIsland(uint256Array[3]);

            require(_id > 0, "island not found");
        }

        MOSSAI_Storage mossaiStorage = MOSSAI_Storage(_MOSSAIStorageAddress);

        uint256 id = mossaiStorage.getNextId();

        mossaiStorage.setString(mossaiStorage.genKey("name", id), name);
        mossaiStorage.setUint(
            mossaiStorage.genKey("totalAmount", id),
            uint256Array[0]
        );
        mossaiStorage.setUint(
            mossaiStorage.genKey("minRandomAmount", id),
            uint256Array[1]
        );

        mossaiStorage.setUint(
            mossaiStorage.genKey("maxRandomAmount", id),
            uint256Array[2]
        );

        mossaiStorage.setUint(mossaiStorage.genKey("startTime", id), startTime);
        mossaiStorage.setUint(mossaiStorage.genKey("endTime", id), endTime);
        mossaiStorage.setUint(
            mossaiStorage.genKey("islandId", id),
            uint256Array[3]
        );

        mossaiStorage.setString(
            mossaiStorage.genKey("airdropConfig", id),
            airdropConfig
        );

        mossaiStorage.setBytes1(mossaiStorage.genKey("status", id), status);

        mossaiStorage.setAddress(
            mossaiStorage.genKey("fromAddress", id),
            fromAddress
        );

        mossaiStorage.setUint(
            mossaiStorage.genKey("intervalTime", id),
            intervalTime
        );

        emit eveSave(id);
    }

    function updateIslandAirdrop(
        uint256 id,
        string memory name,
        uint256 minRandomAmount,
        uint256 maxRandomAmount,
        uint256 startTime,
        uint256 endTime,
        string memory airdropConfig,
        uint256 intervalTime,
        uint256 totalAmount,
        uint256 islandId
    ) public {
        require(
            Hyperdust_Roles_Cfg(_MOSSAIRolesCfgAddress).hasAdminRole(
                msg.sender
            ),
            "not admin role"
        );

        MOSSAI_Storage mossaiStorage = MOSSAI_Storage(_MOSSAIStorageAddress);

        if (islandId != 0) {
            (uint256 _id, , , , , , , , , ) = IMOSSAIIsland(
                _MOSSAIIslandAddress
            ).getIsland(islandId);

            require(_id > 0, "island not found");
        }

        string memory _name = mossaiStorage.getString(
            mossaiStorage.genKey("name", id)
        );

        require(bytes(_name).length > 0, "not found");

        uint256 releaseAmount = mossaiStorage.getUint(
            mossaiStorage.genKey("releaseAmount", id)
        );

        require(
            releaseAmount == 0,
            "airdrop has release amount,Update is not allowed"
        );

        mossaiStorage.setString(mossaiStorage.genKey("name", id), name);
        mossaiStorage.setUint(
            mossaiStorage.genKey("totalAmount", id),
            totalAmount
        );
        mossaiStorage.setUint(
            mossaiStorage.genKey("minRandomAmount", id),
            minRandomAmount
        );

        mossaiStorage.setUint(
            mossaiStorage.genKey("maxRandomAmount", id),
            maxRandomAmount
        );

        mossaiStorage.setUint(mossaiStorage.genKey("startTime", id), startTime);
        mossaiStorage.setUint(mossaiStorage.genKey("endTime", id), endTime);
        mossaiStorage.setUint(mossaiStorage.genKey("islandId", id), islandId);

        mossaiStorage.setString(
            mossaiStorage.genKey("airdropConfig", id),
            airdropConfig
        );

        mossaiStorage.setUint(
            mossaiStorage.genKey("intervalTime", id),
            intervalTime
        );

        emit eveSave(id);
    }

    function deleteIslandAirdrop(uint256 id) public {
        require(
            Hyperdust_Roles_Cfg(_MOSSAIRolesCfgAddress).hasAdminRole(
                msg.sender
            ),
            "not admin role"
        );

        MOSSAI_Storage mossaiStorage = MOSSAI_Storage(_MOSSAIStorageAddress);

        string memory _name = mossaiStorage.getString(
            mossaiStorage.genKey("name", id)
        );

        require(bytes(_name).length > 0, "not found");

        uint256 releaseAmount = mossaiStorage.getUint(
            mossaiStorage.genKey("releaseAmount", id)
        );

        require(
            releaseAmount == 0,
            "airdrop has release amount,Update is not allowed"
        );

        mossaiStorage.setString(mossaiStorage.genKey("name", id), "");

        emit eveDelete(id);
    }

    function updateStatus(uint256 id, bytes1 status) public {
        require(
            Hyperdust_Roles_Cfg(_MOSSAIRolesCfgAddress).hasAdminRole(
                msg.sender
            ),
            "not admin role"
        );

        MOSSAI_Storage mossaiStorage = MOSSAI_Storage(_MOSSAIStorageAddress);

        string memory _name = mossaiStorage.getString(
            mossaiStorage.genKey("name", id)
        );

        require(bytes(_name).length > 0, "not found");

        mossaiStorage.setBytes1(mossaiStorage.genKey("status", id), status);

        emit eveSave(id);
    }

    function getIslandAirdrop(
        uint256 id
    )
        public
        view
        returns (
            uint256[] memory,
            string memory,
            bytes1,
            address,
            string memory
        )
    {
        MOSSAI_Storage mossaiStorage = MOSSAI_Storage(_MOSSAIStorageAddress);

        string memory _name = mossaiStorage.getString(
            mossaiStorage.genKey("name", id)
        );

        require(bytes(_name).length > 0, "not found");

        uint256[] memory uint256Array = new uint256[](9);
        uint256Array[0] = id;
        uint256Array[1] = mossaiStorage.getUint(
            mossaiStorage.genKey("totalAmount", id)
        );
        uint256Array[2] = mossaiStorage.getUint(
            mossaiStorage.genKey("releaseAmount", id)
        );

        uint256Array[3] = mossaiStorage.getUint(
            mossaiStorage.genKey("minRandomAmount", id)
        );

        uint256Array[4] = mossaiStorage.getUint(
            mossaiStorage.genKey("maxRandomAmount", id)
        );

        uint256Array[5] = mossaiStorage.getUint(
            mossaiStorage.genKey("islandId", id)
        );

        uint256Array[6] = mossaiStorage.getUint(
            mossaiStorage.genKey("startTime", id)
        );

        uint256Array[7] = mossaiStorage.getUint(
            mossaiStorage.genKey("endTime", id)
        );

        uint256Array[8] = mossaiStorage.getUint(
            mossaiStorage.genKey("intervalTime", id)
        );

        return (
            uint256Array,
            mossaiStorage.getString(mossaiStorage.genKey("airdropConfig", id)),
            mossaiStorage.getBytes1(mossaiStorage.genKey("status", id)),
            mossaiStorage.getAddress(mossaiStorage.genKey("fromAddress", id)),
            _name
        );
    }

    function receiveAirdrop(uint256 id) public {
        MOSSAI_Storage mossaiStorage = MOSSAI_Storage(_MOSSAIStorageAddress);

        string memory _name = mossaiStorage.getString(
            mossaiStorage.genKey("name", id)
        );

        require(bytes(_name).length > 0, "not found");

        string memory lastReleaseTimeKey = string(
            abi.encodePacked("lastReleaseTime_", msg.sender.toHexString())
        );

        uint256 lastTime = mossaiStorage.getUint(lastReleaseTimeKey);

        bytes1 status = mossaiStorage.getBytes1(
            mossaiStorage.genKey("status", id)
        );

        require(status == 0x01, "island airdrop status is not open");

        uint256 timestamp = block.timestamp;

        uint256 startTime = mossaiStorage.getUint(
            mossaiStorage.genKey("startTime", id)
        );

        uint256 endTime = mossaiStorage.getUint(
            mossaiStorage.genKey("endTime", id)
        );

        require(
            timestamp >= startTime && timestamp < endTime,
            "Temporary Closed"
        );

        uint256 intervalTime = mossaiStorage.getUint(
            mossaiStorage.genKey("intervalTime", id)
        );

        require(
            timestamp - lastTime >= intervalTime,
            "Waiting for the next round drop."
        );

        uint256 minRandomAmount = mossaiStorage.getUint(
            mossaiStorage.genKey("minRandomAmount", id)
        );

        uint256 maxRandomAmount = mossaiStorage.getUint(
            mossaiStorage.genKey("maxRandomAmount", id)
        );

        uint256 releaseAmount = mossaiStorage.getUint(
            mossaiStorage.genKey("releaseAmount", id)
        );

        uint256 totalAmount = mossaiStorage.getUint(
            mossaiStorage.genKey("totalAmount", id)
        );

        uint256 randomAmount = _getRandom(minRandomAmount, maxRandomAmount);

        releaseAmount = releaseAmount + randomAmount;

        require(
            releaseAmount <= totalAmount,
            "This airdrop zone reached its limit."
        );

        address fromAddress = mossaiStorage.getAddress(
            mossaiStorage.genKey("fromAddress", id)
        );

        uint256 allowance = IERC20(_erc20Address).allowance(
            fromAddress,
            address(this)
        );

        require(allowance >= randomAmount, "Insufficient authorized amount");

        IERC20(_erc20Address).transferFrom(
            fromAddress,
            msg.sender,
            randomAmount
        );

        mossaiStorage.setUint(
            mossaiStorage.genKey("releaseAmount", id),
            releaseAmount
        );

        mossaiStorage.setUint(lastReleaseTimeKey, timestamp);

        emit eveReceiveAirdrop(id, msg.sender, randomAmount);

        emit eveSave(id);
    }

    function withdraw(uint256 id, uint256 amount) public {
        MOSSAI_Storage mossaiStorage = MOSSAI_Storage(_MOSSAIStorageAddress);
        string memory _name = mossaiStorage.getString(
            mossaiStorage.genKey("name", id)
        );

        require(bytes(_name).length > 0, "not found");

        uint256 islandId = mossaiStorage.getUint(
            mossaiStorage.genKey("islandId", id)
        );

        (, , , , , , , , uint32 seed, ) = IMOSSAIIsland(_MOSSAIIslandAddress)
            .getIsland(islandId);

        address seedOwer = IMOSSAIIslandNFG(_MOSSAIIslandNFGAddress)
            .getSeedOwer(seed);

        require(msg.sender == seedOwer, "not island ower");

        uint256 releaseAmount = mossaiStorage.getUint(
            mossaiStorage.genKey("releaseAmount", id)
        );

        uint256 totalAmount = mossaiStorage.getUint(
            mossaiStorage.genKey("totalAmount", id)
        );

        releaseAmount = releaseAmount + amount;

        require(releaseAmount <= totalAmount, "release amount is not enough");

        address fromAddress = mossaiStorage.getAddress(
            mossaiStorage.genKey("fromAddress", id)
        );

        uint256 allowance = IERC20(_erc20Address).allowance(
            fromAddress,
            address(this)
        );

        require(allowance >= amount, "Insufficient authorized amount");

        IERC20(_erc20Address).transferFrom(fromAddress, msg.sender, amount);

        mossaiStorage.setUint(
            mossaiStorage.genKey("releaseAmount", id),
            releaseAmount
        );

        emit eveReceiveAirdrop(id, msg.sender, amount);

        emit eveSave(id);
    }

    /**
     * @dev Generates a random number between _start and _end (exclusive) using block difficulty, timestamp and a private variable _rand.
     * @param _start The start of the range (inclusive).
     * @param _end The end of the range (exclusive).
     * @return A random number between _start and _end (exclusive).
     */
    function _getRandom(
        uint256 _start,
        uint256 _end
    ) private returns (uint256) {
        if (_start == _end) {
            return _start;
        }
        uint256 _length = _end - _start;
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(block.difficulty, block.timestamp, _rand)
            )
        );
        random = (random % _length) + _start;
        _rand++;
        return random;
    }

    function setContractAddress(
        address[] memory contractaddressArray
    ) public onlyOwner {
        _MOSSAIRolesCfgAddress = contractaddressArray[0];
        _erc20Address = contractaddressArray[1];
        _MOSSAIIslandAddress = contractaddressArray[2];
        _MOSSAIIslandNFGAddress = contractaddressArray[3];
        _MOSSAIStorageAddress = contractaddressArray[4];
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./utils/StrUtil.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

contract MOSSAI_Storage is Ownable {
    constructor(address onlyOwner) Ownable(onlyOwner) {}

    using Strings for *;
    using StrUtil for *;

    mapping(string => uint256) public uintStorage;
    mapping(string => address) public addressStorage;
    mapping(string => string) public stringStorage;
    mapping(string => bytes) public bytesStorage;
    mapping(string => bytes1) public bytes1Storage;
    mapping(string => bytes32) public bytes32Storage;

    mapping(string => bool) public boolStorage;

    mapping(string => uint256[]) public uintArrayStorage;
    mapping(string => address[]) public addressArrayStorage;
    mapping(string => string[]) public stringArrayStorage;
    mapping(string => bytes[]) public bytesArrayStorage;
    mapping(string => bool[]) public boolArrayStorage;

    uint256 public _id;

    address public _serviceAddress;

    function setServiceAddress(address serviceAddress) public onlyOwner {
        _serviceAddress = serviceAddress;
    }

    function setUint(string memory key, uint256 value) public {
        require(msg.sender == _serviceAddress, "only service can set");
        uintStorage[key] = value;
    }

    function getUint(string memory key) public view returns (uint256) {
        return uintStorage[key];
    }

    function setAddress(string memory key, address value) public {
        require(msg.sender == _serviceAddress, "only service can set");
        addressStorage[key] = value;
    }

    function getAddress(string memory key) public view returns (address) {
        return addressStorage[key];
    }

    function setString(string memory key, string memory value) public {
        require(msg.sender == _serviceAddress, "only service can set");
        stringStorage[key] = value;
    }

    function getString(string memory key) public view returns (string memory) {
        return stringStorage[key];
    }

    function setBytes(string memory key, bytes memory value) public {
        require(msg.sender == _serviceAddress, "only service can set");
        bytesStorage[key] = value;
    }

    function getBytes(string memory key) public view returns (bytes memory) {
        return bytesStorage[key];
    }

    function setBool(string memory key, bool value) public {
        require(msg.sender == _serviceAddress, "only service can set");
        boolStorage[key] = value;
    }

    function getBool(string memory key) public view returns (bool) {
        return boolStorage[key];
    }

    function getNextId() public returns (uint256) {
        require(msg.sender == _serviceAddress, "only service can set");
        _id++;
        return _id;
    }

    function setUintArray(
        string memory key,
        uint256[] memory uint256Array
    ) public {
        require(msg.sender == _serviceAddress, "only service can set");
        uintArrayStorage[key] = uint256Array;
    }

    function setUintArray(string memory key, uint256 value) public {
        require(msg.sender == _serviceAddress, "only service can set");
        uintArrayStorage[key].push(value);
    }

    function setUintArray(
        string memory key,
        uint256 index,
        uint256 value
    ) public {
        require(msg.sender == _serviceAddress, "only service can set");
        require(index < uintArrayStorage[key].length, "Index out of bounds");
        uintArrayStorage[key][index] = value;
    }

    function removeUintArray(string memory key, uint256 index) public {
        require(msg.sender == _serviceAddress, "only service can set");

        require(index < uintArrayStorage[key].length, "Index out of bounds");

        uintArrayStorage[key][index] = uintArrayStorage[key][
            uintArrayStorage[key].length - 1
        ];

        uintArrayStorage[key].pop();
    }

    function setBytes32(string memory key, bytes32 value) public {
        require(msg.sender == _serviceAddress, "only service can set");
        bytes32Storage[key] = value;
    }

    function getBytes32(string memory key) public view returns (bytes32) {
        return bytes32Storage[key];
    }

    function getUintArray(
        string memory key
    ) public view returns (uint256[] memory) {
        return uintArrayStorage[key];
    }

    function setAddressArray(
        string memory key,
        address[] memory addressArray
    ) public {
        require(msg.sender == _serviceAddress, "only service can set");
        addressArrayStorage[key] = addressArray;
    }

    function setAddressArray(string memory key, address value) public {
        require(msg.sender == _serviceAddress, "only service can set");
        addressArrayStorage[key].push(value);
    }

    function setAddressArray(
        string memory key,
        uint256 index,
        address value
    ) public {
        require(msg.sender == _serviceAddress, "only service can set");

        require(index < addressArrayStorage[key].length, "Index out of bounds");
        addressArrayStorage[key][index] = value;
    }

    function removeAddressArray(string memory key, uint256 index) public {
        require(msg.sender == _serviceAddress, "only service can set");

        require(index < addressArrayStorage[key].length, "Index out of bounds");

        addressArrayStorage[key][index] = addressArrayStorage[key][
            addressArrayStorage[key].length - 1
        ];

        addressArrayStorage[key].pop();
    }

    function getAddressArray(
        string memory key
    ) public view returns (address[] memory) {
        return addressArrayStorage[key];
    }

    function setStringArray(
        string memory key,
        string[] memory stringArray
    ) public {
        require(msg.sender == _serviceAddress, "only service can set");
        stringArrayStorage[key] = stringArray;
    }

    function setStringArray(string memory key, string memory value) public {
        require(msg.sender == _serviceAddress, "only service can set");
        stringArrayStorage[key].push(value);
    }

    function setStringArray(
        string memory key,
        uint256 index,
        string memory value
    ) public {
        require(msg.sender == _serviceAddress, "only service can set");
        require(index < stringArrayStorage[key].length, "Index out of bounds");
        stringArrayStorage[key][index] = value;
    }

    function removeStringArray(string memory key, uint256 index) public {
        require(msg.sender == _serviceAddress, "only service can set");

        require(index < stringArrayStorage[key].length, "Index out of bounds");

        stringArrayStorage[key][index] = stringArrayStorage[key][
            stringArrayStorage[key].length - 1
        ];

        stringArrayStorage[key].pop();
    }

    function getStringArray(
        string memory key
    ) public view returns (string[] memory) {
        return stringArrayStorage[key];
    }

    function setBytesArray(
        string memory key,
        bytes[] memory bytesArray
    ) public {
        require(msg.sender == _serviceAddress, "only service can set");
        bytesArrayStorage[key] = bytesArray;
    }

    function setBytesArray(string memory key, bytes memory value) public {
        require(msg.sender == _serviceAddress, "only service can set");
        bytesArrayStorage[key].push(value);
    }

    function setBytesArray(
        string memory key,
        uint256 index,
        bytes memory value
    ) public {
        require(msg.sender == _serviceAddress, "only service can set");
        require(index < bytesArrayStorage[key].length, "Index out of bounds");
        bytesArrayStorage[key][index] = value;
    }

    function removeBytesArray(string memory key, uint256 index) public {
        require(msg.sender == _serviceAddress, "only service can set");

        require(index < bytesArrayStorage[key].length, "Index out of bounds");

        bytesArrayStorage[key][index] = bytesArrayStorage[key][
            bytesArrayStorage[key].length - 1
        ];

        bytesArrayStorage[key].pop();
    }

    function getBytesArray(
        string memory key
    ) public view returns (bytes[] memory) {
        return bytesArrayStorage[key];
    }

    function setBoolArray(string memory key, bool[] memory boolArray) public {
        require(msg.sender == _serviceAddress, "only service can set");
        boolArrayStorage[key] = boolArray;
    }

    function setBoolArray(string memory key, bool value) public {
        require(msg.sender == _serviceAddress, "only service can set");
        boolArrayStorage[key].push(value);
    }

    function setBoolArray(string memory key, uint256 index, bool value) public {
        require(msg.sender == _serviceAddress, "only service can set");
        require(index < boolArrayStorage[key].length, "Index out of bounds");
        boolArrayStorage[key][index] = value;
    }

    function removeBoolArray(string memory key, uint256 index) public {
        require(msg.sender == _serviceAddress, "only service can set");

        require(index < boolArrayStorage[key].length, "Index out of bounds");

        boolArrayStorage[key][index] = boolArrayStorage[key][
            boolArrayStorage[key].length - 1
        ];

        boolArrayStorage[key].pop();
    }

    function getBoolArray(
        string memory key
    ) public view returns (bool[] memory) {
        return boolArrayStorage[key];
    }

    function setBytes1(string memory key, bytes1 value) public {
        require(msg.sender == _serviceAddress, "only service can set");
        bytes1Storage[key] = value;
    }

    function getBytes1(string memory key) public view returns (bytes1) {
        return bytes1Storage[key];
    }

    function genKey(
        string memory key,
        uint256 id
    ) public pure returns (string memory) {
        return string(abi.encodePacked(key, "_", id.toString()));
    }
}

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.8.0;

library StrUtil {
    struct slice {
        uint256 _len;
        uint256 _ptr;
    }

    function memcpy(uint256 dest, uint256 src, uint256 len) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint256 mask = type(uint256).max;
        if (len > 0) {
            mask = 256 ** (32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint256 ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns the length of a null-terminated bytes32 string.
     * @param self The value to find the length of.
     * @return The length of the string, from 0 to 32.
     */
    function len(bytes32 self) internal pure returns (uint256) {
        uint256 ret;
        if (self == 0) return 0;
        if (uint256(self) & type(uint128).max == 0) {
            ret += 16;
            self = bytes32(uint256(self) / 0x100000000000000000000000000000000);
        }
        if (uint256(self) & type(uint64).max == 0) {
            ret += 8;
            self = bytes32(uint256(self) / 0x10000000000000000);
        }
        if (uint256(self) & type(uint32).max == 0) {
            ret += 4;
            self = bytes32(uint256(self) / 0x100000000);
        }
        if (uint256(self) & type(uint16).max == 0) {
            ret += 2;
            self = bytes32(uint256(self) / 0x10000);
        }
        if (uint256(self) & type(uint8).max == 0) {
            ret += 1;
        }
        return 32 - ret;
    }

    /*
     * @dev Returns a slice containing the entire bytes32, interpreted as a
     *      null-terminated utf-8 string.
     * @param self The bytes32 value to convert to a slice.
     * @return A new slice containing the value of the input argument up to the
     *         first null.
     */
    function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
        // Allocate space for `self` in memory, copy it there, and point ret at it
        assembly {
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, 0x20))
            mstore(ptr, self)
            mstore(add(ret, 0x20), ptr)
        }
        ret._len = len(self);
    }

    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint256 l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint256 ptr = self._ptr - 31;
        uint256 end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly {
                b := and(mload(ptr), 0xFF)
            }
            if (b < 0x80) {
                ptr += 1;
            } else if (b < 0xE0) {
                ptr += 2;
            } else if (b < 0xF0) {
                ptr += 3;
            } else if (b < 0xF8) {
                ptr += 4;
            } else if (b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

    /*
     * @dev Returns a positive number if `other` comes lexicographically after
     *      `self`, a negative number if it comes before, or zero if the
     *      contents of the two slices are equal. Comparison is done per-rune,
     *      on unicode codepoints.
     * @param self The first slice to compare.
     * @param other The second slice to compare.
     * @return The result of the comparison.
     */
    function compare(
        slice memory self,
        slice memory other
    ) internal pure returns (int256) {
        uint256 shortest = self._len;
        if (other._len < self._len) shortest = other._len;

        uint256 selfptr = self._ptr;
        uint256 otherptr = other._ptr;
        for (uint256 idx = 0; idx < shortest; idx += 32) {
            uint256 a;
            uint256 b;
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }
            if (a != b) {
                // Mask out irrelevant bytes and check again
                uint256 mask = type(uint256).max; // 0xffff...
                if (shortest < 32) {
                    mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                unchecked {
                    uint256 diff = (a & mask) - (b & mask);
                    if (diff != 0) return int256(diff);
                }
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int256(self._len) - int256(other._len);
    }

    /*
     * @dev Returns true if the two slices contain the same text.
     * @param self The first slice to compare.
     * @param self The second slice to compare.
     * @return True if the slices are equal, false otherwise.
     */
    function equals(
        slice memory self,
        slice memory other
    ) internal pure returns (bool) {
        return compare(self, other) == 0;
    }

    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(
        slice memory self,
        slice memory rune
    ) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint256 l;
        uint256 b;
        // Load the first byte of the rune into the LSBs of b
        assembly {
            b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF)
        }
        if (b < 0x80) {
            l = 1;
        } else if (b < 0xE0) {
            l = 2;
        } else if (b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(
        slice memory self
    ) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint256 ret) {
        if (self._len == 0) {
            return 0;
        }

        uint256 word;
        uint256 length;
        uint256 divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly {
            word := mload(mload(add(self, 32)))
        }
        uint256 b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if (b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if (b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint256 i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(
        slice memory self,
        slice memory needle
    ) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(
                keccak256(selfptr, length),
                keccak256(needleptr, length)
            )
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(
                    keccak256(selfptr, length),
                    keccak256(needleptr, length)
                )
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(
        slice memory self,
        slice memory needle
    ) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint256 selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(
                keccak256(selfptr, length),
                keccak256(needleptr, length)
            )
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint256 selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(
                    keccak256(selfptr, length),
                    keccak256(needleptr, length)
                )
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(
        uint256 selflen,
        uint256 selfptr,
        uint256 needlelen,
        uint256 needleptr
    ) private pure returns (uint256) {
        uint256 ptr = selfptr;
        uint256 idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                uint256 end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr >= end) return selfptr + selflen;
                    ptr++;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(
        uint256 selflen,
        uint256 selfptr,
        uint256 needlelen,
        uint256 needleptr
    ) private pure returns (uint256) {
        uint256 ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask;
                if (needlelen > 0) {
                    mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));
                }

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr) return selfptr;
                    ptr--;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory) {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory) {
        uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(
        slice memory self,
        slice memory needle,
        slice memory token
    ) internal pure returns (slice memory) {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(
        slice memory self,
        slice memory needle,
        slice memory token
    ) internal pure returns (slice memory) {
        uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(
        slice memory self,
        slice memory needle
    ) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(
        slice memory self,
        slice memory needle
    ) internal pure returns (uint256 cnt) {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) +
            needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr =
                findPtr(
                    self._len - (ptr - self._ptr),
                    ptr,
                    needle._len,
                    needle._ptr
                ) +
                needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(
        slice memory self,
        slice memory needle
    ) internal pure returns (bool) {
        return
            rfindPtr(self._len, self._ptr, needle._len, needle._ptr) !=
            self._ptr;
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(
        slice memory self,
        slice memory other
    ) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }

    /*
     * @dev Joins an array of slices, using `self` as a delimiter, returning a
     *      newly allocated string.
     * @param self The delimiter to use.
     * @param parts A list of slices to join.
     * @return A newly allocated string containing all the slices in `parts`,
     *         joined with `self`.
     */
    function join(
        slice memory self,
        slice[] memory parts
    ) internal pure returns (string memory) {
        if (parts.length == 0) return "";

        uint256 length = self._len * (parts.length - 1);
        for (uint256 i = 0; i < parts.length; i++) length += parts[i]._len;

        string memory ret = new string(length);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        for (uint256 i = 0; i < parts.length; i++) {
            memcpy(retptr, parts[i]._ptr, parts[i]._len);
            retptr += parts[i]._len;
            if (i < parts.length - 1) {
                memcpy(retptr, self._ptr, self._len);
                retptr += self._len;
            }
        }

        return ret;
    }
}