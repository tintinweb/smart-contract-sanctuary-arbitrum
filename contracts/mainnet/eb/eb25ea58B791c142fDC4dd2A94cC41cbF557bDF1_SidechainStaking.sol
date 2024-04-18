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
pragma solidity ^0.8.4;

import {PRECISION} from "../../utils/Globals.sol";

/**
 * @notice The AbstractValueDistributor module
 *
 * Contract module for distributing value among users based on their shares.
 *
 * The algorithm ensures that the distribution is proportional to the shares
 * held by each user and takes into account changes in the cumulative sum over time.
 *
 * This contract can be used as a base contract for implementing various distribution mechanisms,
 * such as token staking, profit sharing, or dividend distribution.
 *
 * It includes hooks for performing additional logic
 * when shares are added or removed, or when value is distributed.
 */
abstract contract AbstractValueDistributor {
    struct UserDistribution {
        uint256 shares;
        uint256 cumulativeSum;
        uint256 owedValue;
    }

    uint256 private _totalShares;
    uint256 private _cumulativeSum;
    uint256 private _updatedAt;

    mapping(address => UserDistribution) private _userDistributions;

    event SharesAdded(address user, uint256 amount);
    event SharesRemoved(address user, uint256 amount);
    event ValueDistributed(address user, uint256 amount);

    /**
     * @notice Returns the total number of shares.
     * @return The total number of shares.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @notice Returns the cumulative sum of value that has been distributed.
     * @return The cumulative sum of value that has been distributed.
     */
    function cumulativeSum() public view returns (uint256) {
        return _cumulativeSum;
    }

    /**
     * @notice Returns the timestamp of the last update.
     * @return The timestamp of the last update.
     */
    function updatedAt() public view returns (uint256) {
        return _updatedAt;
    }

    /**
     * @notice Returns the distribution details for a specific user.
     * @param user_ The address of the user.
     * @return The distribution details including user's shares, cumulative sum and value owed.
     */
    function userDistribution(address user_) public view returns (UserDistribution memory) {
        return _userDistributions[user_];
    }

    /**
     * @notice Gets the amount of value owed to a specific user.
     * @param user_ The address of the user.
     * @return The total owed value to the user.
     */
    function getOwedValue(address user_) public view returns (uint256) {
        UserDistribution storage userDist = _userDistributions[user_];

        return
            (userDist.shares *
                (_getFutureCumulativeSum(block.timestamp) - userDist.cumulativeSum)) /
            PRECISION +
            userDist.owedValue;
    }

    /**
     * @notice Adds shares to a user's distribution.
     * @param user_ The address of the user.
     * @param amount_ The amount of shares to add.
     */
    function _addShares(address user_, uint256 amount_) internal virtual {
        require(user_ != address(0), "ValueDistributor: zero address is not allowed");
        require(amount_ > 0, "ValueDistributor: amount has to be more than 0");

        _update(user_);

        _totalShares += amount_;
        _userDistributions[user_].shares += amount_;

        emit SharesAdded(user_, amount_);

        _afterAddShares(user_, amount_);
    }

    /**
     * @notice Removes shares from a user's distribution.
     * @param user_ The address of the user.
     * @param amount_ The amount of shares to remove.
     */
    function _removeShares(address user_, uint256 amount_) internal virtual {
        require(amount_ > 0, "ValueDistributor: amount has to be more than 0");
        require(
            amount_ <= _userDistributions[user_].shares,
            "ValueDistributor: insufficient amount"
        );

        _update(user_);

        _totalShares -= amount_;
        _userDistributions[user_].shares -= amount_;

        emit SharesRemoved(user_, amount_);

        _afterRemoveShares(user_, amount_);
    }

    /**
     * @notice Distributes value to a specific user.
     * @param user_ The address of the user.
     * @param amount_ The amount of value to distribute.
     */
    function _distributeValue(address user_, uint256 amount_) internal virtual {
        _update(user_);

        require(amount_ > 0, "ValueDistributor: amount has to be more than 0");
        require(
            amount_ <= _userDistributions[user_].owedValue,
            "ValueDistributor: insufficient amount"
        );

        _userDistributions[user_].owedValue -= amount_;

        emit ValueDistributed(user_, amount_);

        _afterDistributeValue(user_, amount_);
    }

    /**
     * @notice Hook function that is called after shares have been added to a user's distribution.
     *
     * This function can be used to perform any additional logic that is required,
     * such as transferring tokens.
     *
     * @param user_ The address of the user.
     * @param amount_ The amount of shares added.
     */
    function _afterAddShares(address user_, uint256 amount_) internal virtual {}

    /**
     * @notice Hook function that is called after shares have been removed from a user's distribution.
     *
     * This function can be used to perform any additional logic that is required,
     * such as transferring tokens.
     *
     * @param user_ The address of the user.
     * @param amount_ The amount of shares removed.
     */
    function _afterRemoveShares(address user_, uint256 amount_) internal virtual {}

    /**
     * @notice Hook function that is called after value has been distributed to a user.
     *
     * This function can be used to perform any additional logic that is required,
     * such as transferring tokens.
     *
     * @param user_ The address of the user.
     * @param amount_ The amount of value distributed.
     */
    function _afterDistributeValue(address user_, uint256 amount_) internal virtual {}

    /**
     * @notice Updates the cumulative sum of tokens that have been distributed.
     *
     * This function should be called whenever user shares are modified or value distribution occurs.
     *
     * @param user_ The address of the user.
     */
    function _update(address user_) internal {
        _cumulativeSum = _getFutureCumulativeSum(block.timestamp);
        _updatedAt = block.timestamp;

        if (user_ != address(0)) {
            UserDistribution storage userDist = _userDistributions[user_];

            userDist.owedValue +=
                (userDist.shares * (_cumulativeSum - userDist.cumulativeSum)) /
                PRECISION;
            userDist.cumulativeSum = _cumulativeSum;
        }
    }

    /**
     * @notice Gets the value to be distributed for a given time period.
     *
     * Note: It will usually be required to override this function to provide custom distribution mechanics.
     *
     * @param timeUpTo_ The end timestamp of the period.
     * @param timeLastUpdate_ The start timestamp of the period.
     * @return The value to be distributed for the period.
     */
    function _getValueToDistribute(
        uint256 timeUpTo_,
        uint256 timeLastUpdate_
    ) internal view virtual returns (uint256);

    /**
     * @notice Gets the expected cumulative sum of value per token staked distributed at a given timestamp.
     * @param timeUpTo_ The timestamp up to which to calculate the value distribution.
     * @return The future cumulative sum of value per token staked that has been distributed.
     */
    function _getFutureCumulativeSum(uint256 timeUpTo_) internal view returns (uint256) {
        if (_totalShares == 0) {
            return _cumulativeSum;
        }

        uint256 value_ = _getValueToDistribute(timeUpTo_, _updatedAt);

        return _cumulativeSum + (value_ * PRECISION) / _totalShares;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

uint256 constant PRECISION = 10 ** 25;
uint256 constant DECIMAL = 10 ** 18;
uint256 constant PERCENTAGE_100 = 10 ** 27;

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ITokenDistributionManager} from "./ITokenDistributionManager.sol";

interface ISidechainStaking {
    error ErrStakingEnded();
    error ErrStakingStarted();
    error ErrStakingNotEnded();
    error ErrStakingNotStarted();
    error ErrRefBalancesNotAllowed();
    error ErrNewTimestampOutDate();
    error ErrStartTimestampInPast();
    error ErrStartTimestampBiggerEnd();

    event RateUpdated(uint256 newRate);

    function __Staking_init(
        uint256 rate_,
        uint256 stakingStartTime_,
        uint256 stakingEndTime_,
        ITokenDistributionManager manager_,
        bool allowRefBalance_
    ) external;

    function stakeUsingBalance(uint256 amount_) external;
    function stakeUsingRefBalance(uint256 amount_) external;
    function setRate(uint256 rate_) external;
    function setManager(ITokenDistributionManager manager_) external;
    function setStartTimestamp(uint256 newTs_) external;
    function setEndTimestamp(uint256 newTs_) external;
    function update(address user_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ITokenDistributionManager.sol";

interface IStaking {
    error ErrStakingEnded();
    error ErrStakingStarted();
    error ErrClaimingStarted();
    error ErrStakingNotEnded();
    error ErrStakingNotStarted();
    error ErrClaimingNotAllowed();
    error ErrNewTimestampOutDate();
    error ErrRefBalancesNotAllowed();
    error ErrWithdrawingNotAllowed();
    error ErrWithdrawingTimestampError();

    event RateUpdated(uint256 newRate);

    function __Staking_init(
        uint256 rate_,
        uint256 stakingStartTime_,
        uint256 stakingEndTime_,
        uint256 claimingStartTime_,
        uint256 withdrawingTimestamp_,
        uint256 vestingStartTime_,
        uint256 vestingEndTime_,
        uint256 unlockPercent_,
        IERC20 token_,
        ITokenDistributionManager manager_,
        bool allowRefBalance_
    ) external;

    function stakeUsingBalance(uint256 amount_) external;
    function stakeUsingRefBalance(uint256 amount_) external;
    function claim() external returns (uint256 owedValue);
    function withdraw(bool claim_) external returns (uint256 shares);
    function setRate(uint256 rate_) external;
    function setManager(ITokenDistributionManager storage_) external;
    function setStartTimestamp(uint256 newTs_) external;
    function setClaimTimestamp(uint256 newTs_) external;
    function setEndTimestamp(uint256 newTs_) external;
    function setAllowanceForRefBalance(bool allowRefBalance_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ITokenDistributionManager {
    function withdrawUserBalance(address user_, uint256 amount_) external;

    function withdrawRefBalance(address user_, uint256 amount_) external;

    function recoverErc20(address token_, uint256 amount_) external;

    function getRefUserBalance(address user_) external view returns (uint256);

    function getPurchasedUserBalance(address user_) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {AbstractValueDistributor} from "@solarity/solidity-lib/finance/staking/AbstractValueDistributor.sol";

import {ITokenDistributionManager} from "../interfaces/ITokenDistributionManager.sol";
import {IStaking} from "../interfaces/IStaking.sol";
import {ISidechainStaking} from "../interfaces/ISidechainStaking.sol";

contract SidechainStaking is AbstractValueDistributor, OwnableUpgradeable, ISidechainStaking {
    uint256 public rate;
    uint256 public startTimestamp;
    uint256 public endTimestamp;

    bool public allowRefBalance;

    ITokenDistributionManager public manager;

    modifier duringStaking() {
        if (block.timestamp < startTimestamp) {
            revert ErrStakingNotStarted();
        } else if (block.timestamp > endTimestamp) {
            revert ErrStakingEnded();
        }
        _;
    }

    function __Staking_init(
        uint256 rate_,
        uint256 stakingStartTime_,
        uint256 stakingEndTime_,
        ITokenDistributionManager manager_,
        bool allowRefBalance_
    ) external initializer {
        __Ownable_init(_msgSender());

        _setRate(rate_);

        if (block.timestamp > stakingStartTime_) {
            revert ErrStartTimestampInPast();
        }

        if (stakingStartTime_ > stakingEndTime_) {
            revert ErrStartTimestampBiggerEnd();
        }

        startTimestamp = stakingStartTime_;
        endTimestamp = stakingEndTime_;
        manager = manager_;
        allowRefBalance = allowRefBalance_;
    }

    function stakeUsingBalance(uint256 amount_) external duringStaking {
        manager.withdrawUserBalance(_msgSender(), amount_);
        _addShares(_msgSender(), amount_);
    }

    function stakeUsingRefBalance(uint256 amount_) external duringStaking {
        if (!allowRefBalance) {
            revert ErrRefBalancesNotAllowed();
        }

        manager.withdrawRefBalance(_msgSender(), amount_);
        _addShares(_msgSender(), amount_);
    }

    function setRate(uint256 rate_) external onlyOwner {
        _update(address(0));
        _setRate(rate_);
    }

    function setManager(ITokenDistributionManager manager_) external onlyOwner {
        _update(address(0));
        manager = manager_;
    }

    function setStartTimestamp(uint256 newTs_) external onlyOwner {
        if (startTimestamp <= block.timestamp) {
            revert ErrStakingStarted();
        }

        if (newTs_ <= block.timestamp) {
            revert ErrNewTimestampOutDate();
        }

        startTimestamp = newTs_;
    }

    function setEndTimestamp(uint256 newTs_) external onlyOwner {
        if (endTimestamp <= block.timestamp) {
            revert ErrStakingEnded();
        }

        if (newTs_ <= block.timestamp) {
            revert ErrNewTimestampOutDate();
        }

        endTimestamp = newTs_;
    }

    function setAllowanceForRefBalance(bool allowRefBalance_) external onlyOwner {
        allowRefBalance = allowRefBalance_;
    }

    function update(address user_) external {
        _update(user_);
    }

    function _setRate(uint256 rate_) internal {
        rate = rate_;
        emit RateUpdated(rate_);
    }

    function _getValueToDistribute(
        uint256 timeUpTo_,
        uint256 timeLastUpdate_
    ) internal view override returns (uint256) {
        if (endTimestamp < timeLastUpdate_) {
            return 0;
        }

        return rate * (Math.min(timeUpTo_, endTimestamp) - timeLastUpdate_);
    }

    uint256[40] __gap;
}