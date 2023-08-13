// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
pragma solidity ^0.8.19;

import '../../lib/FixedPoint.sol';

interface IFeeReferral {
    function referrers(address account) external view returns (address referrer);
    function getReferrerRedirect(address referrer) external view returns (FPUnsigned);
    function getReferrerDiscount(address referrer) external view returns (FPUnsigned);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { FPSigned, FPUnsigned, FixedPoint } from './FixedPoint.sol';
import { floor, ceil } from './FPUnsignedOperators.sol';

/**
 * @notice Adds two `FPSigned`s, reverting on overflow.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return the sum of `a` and `b`.
*/
function add(FPSigned a, FPSigned b) pure returns (FPSigned) {
    return FPSigned.wrap(FPSigned.unwrap(a) + FPSigned.unwrap(b));
}

/**
 * @notice Subtracts two `FPSigned`s, reverting on overflow.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return the difference of `a` and `b`.
*/
function sub(FPSigned a, FPSigned b) pure returns (FPSigned) {
    return FPSigned.wrap(FPSigned.unwrap(a) - FPSigned.unwrap(b));
}

/**
 * @notice Multiplies two `FPSigned`s, reverting on overflow.
 * @dev This will "floor" the product.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return the product of `a` and `b`.
*/
function mul(FPSigned a, FPSigned b) pure returns (FPSigned) {
    // There are two caveats with this computation:
    // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
    // stored internally as an int256 ~10^59.
    // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
    // would round to 3, but this computation produces the result 2.
    // No need to use SafeMath because FixedPoint.SFP_SCALING_FACTOR != 0.
    return FPSigned.wrap(FPSigned.unwrap(a) * FPSigned.unwrap(b) / FixedPoint.SFP_SCALING_FACTOR);
}

function neg(FPSigned a) pure returns (FPSigned) {
    return FPSigned.wrap(FPSigned.unwrap(a) * -1);
}

/**
 * @notice Divides one `FPSigned` by a `FPSigned`, reverting on overflow or division by 0.
 * @dev This will "floor" the quotient.
 * @param a a FPSigned numerator.
 * @param b a FPSigned denominator.
 * @return the quotient of `a` divided by `b`.
*/
function div(FPSigned a, FPSigned b) pure returns (FPSigned) {
    // There are two caveats with this computation:
    // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
    // 10^41 is stored internally as an int256 10^59.
    // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
    // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
    return FPSigned.wrap(FPSigned.unwrap(a) * FixedPoint.SFP_SCALING_FACTOR / FPSigned.unwrap(b));
}

/**
 * @notice Whether `a` is equal to `b`.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return True if equal, or False.
*/
function isEqual(FPSigned a, FPSigned b) pure returns (bool) {
    return FPSigned.unwrap(a) == FPSigned.unwrap(b);
}

/**
 * @notice Whether `a` is equal to `b`.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return True if equal, or False.
*/
function isNotEqual(FPSigned a, FPSigned b) pure returns (bool) {
    return FPSigned.unwrap(a) != FPSigned.unwrap(b);
}

/**
 * @notice Whether `a` is greater than `b`.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return True if `a > b`, or False.
*/
function isGreaterThan(FPSigned a, FPSigned b) pure returns (bool) {
    return FPSigned.unwrap(a) > FPSigned.unwrap(b);
}

/**
 * @notice Whether `a` is greater than or equal to `b`.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return True if `a >= b`, or False.
*/
function isGreaterThanOrEqual(FPSigned a, FPSigned b) pure returns (bool) {
    return FPSigned.unwrap(a) >= FPSigned.unwrap(b);
}

/**
 * @notice Whether `a` is less than `b`.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return True if `a < b`, or False.
*/
function isLessThan(FPSigned a, FPSigned b) pure returns (bool) {
    return FPSigned.unwrap(a) < FPSigned.unwrap(b);
}

/**
 * @notice Whether `a` is less than or equal to `b`.
 * @param a a FPSigned.
 * @param b a FPSigned.
 * @return True if `a <= b`, or False.
*/
function isLessThanOrEqual(FPSigned a, FPSigned b) pure returns (bool) {
    return FPSigned.unwrap(a) <= FPSigned.unwrap(b);
}

/**
 * @notice Absolute value of a FPSigned
*/
function abs(FPSigned value) pure returns (FPUnsigned) {
    int256 x = FPSigned.unwrap(value);
    uint256 raw = (x < 0) ? uint256(-x) : uint256(x);
    return FPUnsigned.wrap(raw);
}

/**
 * @notice Convert a FPUnsigned to uint, "truncating" any decimal portion.
*/
function trunc(FPSigned value) pure returns (int256) {
    return FPSigned.unwrap(value) / FixedPoint.SFP_SCALING_FACTOR;
}

/**
 * @notice Round a trader's PnL in favor of liquidity providers
*/
function roundTraderPnl(FPSigned value) pure returns (FPSigned) {
    if (FPSigned.unwrap(value) >= 0) {
        // If the P/L is a trader gain/value loss, then fractional dust gained for the trader should be reduced
        FPUnsigned pnl = FixedPoint.fromSigned(value);
        return FixedPoint.fromUnsigned(floor(pnl));
    } else {
        // If the P/L is a trader loss/vault gain, then fractional dust lost should be magnified towards the trader
        return neg(FixedPoint.fromUnsigned(ceil(abs(value))));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import { FPUnsigned, FPSigned, FixedPoint } from './FixedPoint.sol';

/**
 * @notice Whether `a` is equal to `b`.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return True if equal, or False.
*/
function isEqual(FPUnsigned a, FPUnsigned b) pure returns (bool) {
    return FPUnsigned.unwrap(a) == FPUnsigned.unwrap(b);
}

/**
 * @notice Whether `a` is equal to `b`.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return True if equal, or False.
*/
function isNotEqual(FPUnsigned a, FPUnsigned b) pure returns (bool) {
    return FPUnsigned.unwrap(a) != FPUnsigned.unwrap(b);
}

/**
 * @notice Whether `a` is greater than `b`.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return True if `a > b`, or False.
*/
function isGreaterThan(FPUnsigned a, FPUnsigned b) pure returns (bool) {
    return FPUnsigned.unwrap(a) > FPUnsigned.unwrap(b);
}

/**
 * @notice Whether `a` is greater than or equal to `b`.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return True if `a >= b`, or False.
*/
function isGreaterThanOrEqual(FPUnsigned a, FPUnsigned b) pure returns (bool) {
    return FPUnsigned.unwrap(a) >= FPUnsigned.unwrap(b);
}

/**
 * @notice Whether `a` is less than `b`.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return True if `a < b`, or False.
*/
function isLessThan(FPUnsigned a, FPUnsigned b) pure returns (bool) {
    return FPUnsigned.unwrap(a) < FPUnsigned.unwrap(b);
}

/**
 * @notice Whether `a` is less than or equal to `b`.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return True if `a <= b`, or False.
*/
function isLessThanOrEqual(FPUnsigned a, FPUnsigned b) pure returns (bool) {
    return FPUnsigned.unwrap(a) <= FPUnsigned.unwrap(b);
}

/**
 * @notice Adds two `FPUnsigned`s, reverting on overflow.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return the sum of `a` and `b`.
*/
function add(FPUnsigned a, FPUnsigned b) pure returns (FPUnsigned) {
    return FPUnsigned.wrap(FPUnsigned.unwrap(a) + FPUnsigned.unwrap(b));
}

/**
 * @notice Subtracts two `FPUnsigned`s, reverting on overflow.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return the difference of `a` and `b`.
*/
function sub(FPUnsigned a, FPUnsigned b) pure returns (FPUnsigned) {
    return FPUnsigned.wrap(FPUnsigned.unwrap(a) - FPUnsigned.unwrap(b));
}

/**
 * @notice Multiplies two `FPUnsigned`s, reverting on overflow.
 * @dev This will "floor" the product.
 * @param a a FPUnsigned.
 * @param b b FPUnsigned.
 * @return the product of `a` and `b`.
*/
function mul(FPUnsigned a, FPUnsigned b) pure returns (FPUnsigned) {
    // There are two caveats with this computation:
    // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
    // stored internally as a uint256 ~10^59.
    // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
    // would round to 3, but this computation produces the result 2.
    // No need to use SafeMath because FixedPoint.FP_SCALING_FACTOR != 0.
    return FPUnsigned.wrap(FPUnsigned.unwrap(a) * FPUnsigned.unwrap(b) / FixedPoint.FP_SCALING_FACTOR);
}

/**
 * @notice Divides one `FPUnsigned` by an `FPUnsigned`, reverting on overflow or division by 0.
 * @dev This will "floor" the quotient.
 * @param a a FPUnsigned numerator.
 * @param b a FPUnsigned denominator.
 * @return the quotient of `a` divided by `b`.
*/
function div(FPUnsigned a, FPUnsigned b) pure returns (FPUnsigned) {
    // There are two caveats with this computation:
    // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
    // 10^41 is stored internally as a uint256 10^59.
    // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
    // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
    return FPUnsigned.wrap(FPUnsigned.unwrap(a) * FixedPoint.FP_SCALING_FACTOR / FPUnsigned.unwrap(b));
}

/**
 * @notice Convert a FPUnsigned.FPUnsigned to uint, rounding up any decimal portion.
*/
function roundUp(FPUnsigned value) pure returns (uint256) {
    return trunc(ceil(value));
}

/**
 * @notice Convert a FPUnsigned.FPUnsigned to uint, "truncating" any decimal portion.
*/
function trunc(FPUnsigned value) pure returns (uint256) {
    return FPUnsigned.unwrap(value) / FixedPoint.FP_SCALING_FACTOR;
}

/**
 * @notice Rounding a FPUnsigned.Unsigned down to the nearest integer.
*/
function floor(FPUnsigned value) pure returns (FPUnsigned) {
    return FixedPoint.fromUnscaledUint(trunc(value));
}

/**
 * @notice Round a FPUnsigned.Unsigned up to the nearest integer.
*/
function ceil(FPUnsigned value) pure returns (FPUnsigned) {
    FPUnsigned iPart = floor(value);
    FPUnsigned fPart = sub(value, iPart);
    if (FPUnsigned.unwrap(fPart) > 0) {
        return add(iPart, FixedPoint.ONE);
    } else {
        return iPart;
    }
}

function neg(FPUnsigned a) pure returns (FPSigned) {
    return FixedPoint.fromUnsigned(a).neg();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.19;

import './FPUnsignedOperators.sol' as FPUnsignedOperators;
import './FPSignedOperators.sol' as FPSignedOperators;

type FPUnsigned is uint256;
type FPSigned is int256;

using {
    FPUnsignedOperators.isEqual as ==,
    FPUnsignedOperators.isNotEqual as !=,
    FPUnsignedOperators.isGreaterThan as >,
    FPUnsignedOperators.isGreaterThanOrEqual as >=,
    FPUnsignedOperators.isLessThan as <,
    FPUnsignedOperators.isLessThanOrEqual as <=,
    FPUnsignedOperators.add as +,
    FPUnsignedOperators.sub as -,
    FPUnsignedOperators.mul as *,
    FPUnsignedOperators.div as /,

    FPUnsignedOperators.roundUp,
    FPUnsignedOperators.trunc,
    FPUnsignedOperators.neg
} for FPUnsigned global;

using {
    FPSignedOperators.isEqual as ==,
    FPSignedOperators.isNotEqual as !=,
    FPSignedOperators.isGreaterThan as >,
    FPSignedOperators.isGreaterThanOrEqual as >=,
    FPSignedOperators.isLessThan as <,
    FPSignedOperators.isLessThanOrEqual as <=,
    FPSignedOperators.add as +,
    FPSignedOperators.sub as -,
    FPSignedOperators.mul as *,
    FPSignedOperators.div as /,

    FPSignedOperators.neg,
    FPSignedOperators.abs,
    FPSignedOperators.roundTraderPnl,
    FPSignedOperators.trunc
} for FPSigned global;

library FixedPoint {

    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    uint256 constant FP_DECIMALS = 18;

    // For unsigned values:
    //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
    uint256 constant FP_SCALING_FACTOR = 10**18;

    // For signed values:
    //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
    int256 constant SFP_SCALING_FACTOR = 10**18;

    FPUnsigned constant ONE = FPUnsigned.wrap(10**18);
    FPUnsigned constant ZERO = FPUnsigned.wrap(0);

    // largest FPUnsigned which can be squared without reverting
    FPUnsigned constant MAX_UNSIGNED_FACTOR = FPUnsigned.wrap(340282366920938463463374607431768211455);
    // largest `FPSigned`s which can be squared without reverting
    FPSigned constant MIN_SIGNED_FACTOR = FPSigned.wrap(-240615969168004511545033772477625056927);
    FPSigned constant MAX_SIGNED_FACTOR = FPSigned.wrap(240615969168004511545033772477625056927);

    // largest FPUnsigned which can be cubed without reverting
    FPUnsigned constant MAX_UNSIGNED_CUBE_FACTOR = FPUnsigned.wrap(48740834812604276470692694885616);
    // largest `FPSigned`s which can be cubed without reverting
    FPSigned constant MIN_SIGNED_CUBE_FACTOR = FPSigned.wrap(-38685626227668133590597631999999);
    FPSigned constant MAX_SIGNED_CUBE_FACTOR = FPSigned.wrap(38685626227668133590597631999999);

    /**
    * @notice Constructs an `FPUnsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5*(10**18)`.
    * @param a uint to convert into a FixedPoint.
    * @return the converted FixedPoint.
    */
    function fromUnscaledUint(uint256 a) internal pure returns (FPUnsigned) {
        return FPUnsigned.wrap(a * FP_SCALING_FACTOR);
    }

    /**
    * @notice Given a uint with a certain number of decimal places, normalize it to a FixedPoint
    * @param value uint256, e.g. 10000000 wei USDC
    * @param decimals uint8 number of decimals to interpret `value` as, e.g. 6
    * @return output FPUnsigned, e.g. (10.000000)
    */
    function fromScalar(uint256 value, uint8 decimals) internal pure returns (FPUnsigned) {
        require(decimals <= FP_DECIMALS, 'FixedPoint: max decimals');
        return div(fromUnscaledUint(value), 10**decimals);
    }

    /**
    * @notice Constructs a `FPSigned` from an unscaled int, e.g., `b=5` gets stored internally as `5*(10**18)`.
    * @param a int to convert into a FPSigned.
    * @return the converted FPSigned.
    */
    function fromUnscaledInt(int256 a) internal pure returns (FPSigned) {
        return FPSigned.wrap(a * SFP_SCALING_FACTOR);
    }

    // --------- FPUnsigned
    function fromUnsigned(FPUnsigned a) internal pure returns (FPSigned) {
        require(FPUnsigned.unwrap(a) <= uint256(type(int256).max), 'FPUnsigned too large');
        return FPSigned.wrap(int256(FPUnsigned.unwrap(a)));
    }

    /**
    * @notice Adds an unscaled uint256 to an `FPUnsigned`, reverting on overflow.
    * @param a a FPUnsigned.
    * @param b a uint256.
    * @return the sum of `a` and `b`.
    */
    function add(FPUnsigned a, uint256 b) internal pure returns (FPUnsigned) {
        return FPUnsignedOperators.add(a, fromUnscaledUint(b));
    }

    /**
    * @notice Subtracts an unscaled uint256 from an `FPUnsigned`, reverting on overflow.
    * @param a a FPUnsigned.
    * @param b a uint256.
    * @return the difference of `a` and `b`.
    */
    function sub(FPUnsigned a, uint256 b) internal pure returns (FPUnsigned) {
        return FPUnsignedOperators.sub(a, fromUnscaledUint(b));
    }

    /**
    * @notice Multiplies an `FPUnsigned` and an unscaled uint256, reverting on overflow.
    * @dev This will "floor" the product.
    * @param a a FPUnsigned.
    * @param b a FPUnsigned.
    * @return the product of `a` and `b`.
    */
    function mul(FPUnsigned a, FPUnsigned b) internal pure returns (FPUnsigned) {
        return a * b;
    }

    /**
    * @notice Multiplies an `FPUnsigned` and an unscaled uint256, reverting on overflow.
    * @dev This will "floor" the product.
    * @param a a FPUnsigned.
    * @param b a uint256.
    * @return the product of `a` and `b`.
    */
    function mul(FPUnsigned a, uint256 b) internal pure returns (FPUnsigned) {
        return FPUnsigned.wrap(FPUnsigned.unwrap(a) * b);
    }

    /**
    * @notice Divides one `FPUnsigned` by an unscaled uint256, reverting on overflow or division by 0.
    * @dev This will "floor" the quotient.
    * @param a a FPUnsigned numerator.
    * @param b a uint256 denominator.
    * @return the quotient of `a` divided by `b`.
    */
    function div(FPUnsigned a, uint256 b) internal pure returns (FPUnsigned) {
        return FPUnsigned.wrap(FPUnsigned.unwrap(a) / b);
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FPUnsigned.
     * @param b a FPUnsigned.
     * @return the minimum of `a` and `b`.
    */
    function min(FPUnsigned a, FPUnsigned b) internal pure returns (FPUnsigned) {
        return FPUnsigned.unwrap(a) < FPUnsigned.unwrap(b) ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FPUnsigned.
     * @param b a FPUnsigned.
     * @return the maximum of `a` and `b`.
    */
    function max(FPUnsigned a, FPUnsigned b) internal pure returns (FPUnsigned) {
        return FPUnsigned.unwrap(a) > FPUnsigned.unwrap(b) ? a : b;
    }

    // --------- FPSigned

    function fromSigned(FPSigned a) internal pure returns (FPUnsigned) {
        require(FPSigned.unwrap(a) >= 0, 'Negative value provided');
        return FPUnsigned.wrap(uint256(FPSigned.unwrap(a)));
    }

    /**
     * @notice Adds a `FPSigned` to an `FPUnsigned`, reverting on overflow.
     * @param a a FPSigned.
     * @param b an FPUnsigned.
     * @return the sum of `a` and `b`.
    */
    function add(FPSigned a, FPUnsigned b) internal pure returns (FPSigned) {
        return FPSignedOperators.add(a, fromUnsigned(b));
    }

    /**
     * @notice Subtracts an unscaled int256 from a `FPSigned`, reverting on overflow.
     * @param a a FPSigned.
     * @param b an int256.
     * @return the difference of `a` and `b`.
    */
    function sub(FPSigned a, int256 b) internal pure returns (FPSigned) {
        return FPSignedOperators.sub(a, fromUnscaledInt(b));
    }

    /**
    * @notice Subtracts an `FPUnsigned` from a `FPSigned`, reverting on overflow.
    * @param a a FPSigned.
    * @param b a FPUnsigned.
    * @return the difference of `a` and `b`.
    */
    function sub(FPSigned a, FPUnsigned b) internal pure returns (FPSigned) {
        return FPSignedOperators.sub(a, fromUnsigned(b));
    }

    /**
    * @notice Subtracts an unscaled uint256 from a `FPSigned`, reverting on overflow.
    * @param a a FPSigned.
    * @param b a uint256.
    * @return the difference of `a` and `b`.
    */
    function sub(FPSigned a, uint256 b) internal pure returns (FPSigned) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
    * @notice Multiplies a `FPSigned` and an unscaled uint256, reverting on overflow.
    * @dev This will "floor" the product.
    * @param a a FPSigned.
    * @param b a uint256.
    * @return the product of `a` and `b`.
    */
    function mul(FPSigned a, uint256 b) internal pure returns (FPSigned) {
        return mul(a, fromUnscaledUint(b));
    }

    /**
    * @notice Multiplies a `FPSigned` and `FPUnsigned`, reverting on overflow.
    * @dev This will "floor" the product.
    * @param a a FPSigned.
    * @param b a FPUnsigned.
    * @return the product of `a` and `b`.
    */
    function mul(FPSigned a, FPUnsigned b) internal pure returns (FPSigned) {
        return FPSignedOperators.mul(a, fromUnsigned(b));
    }

    /**
    * @notice Divides one `FPSigned` by an `FPUnsigned`, reverting on overflow or division by 0.
    * @dev This will "floor" the quotient.
    * @param a a FPSigned numerator.
    * @param b a FPUnsigned denominator.
    * @return the quotient of `a` divided by `b`.
    */
    function div(FPSigned a, FPUnsigned b) internal pure returns (FPSigned) {
        return FPSignedOperators.div(a, fromUnsigned(b));
    }

    /**
    * @notice Divides one `FPSigned` by an unscaled uint256, reverting on overflow or division by 0.
    * @dev This will "floor" the quotient.
    * @param a a FPSigned numerator.
    * @param b a uint256 denominator.
    * @return the quotient of `a` divided by `b`.
    */
    function div(FPSigned a, uint256 b) internal pure returns (FPSigned) {
        return div(a, fromUnscaledUint(b));
    }

    /**
    * @notice The minimum of `a` and `b`.
    * @param a a FPSigned.
    * @param b a FPSigned.
    * @return the minimum of `a` and `b`.
    */
    function min(FPSigned a, FPSigned b) internal pure returns (FPSigned) {
        return FPSigned.unwrap(a) < FPSigned.unwrap(b) ? a : b;
    }

    /**
    * @notice The maximum of `a` and `b`.
    * @param a a FPSigned.
    * @param b a FPSigned.
    * @return the maximum of `a` and `b`.
    */
    function max(FPSigned a, FPSigned b) internal pure returns (FPSigned) {
        return FPSigned.unwrap(a) > FPSigned.unwrap(b) ? a : b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/perp/IFeeReferral.sol';
import '../lib/FixedPoint.sol';

contract FeeReferral is Ownable, IFeeReferral {
    using FixedPoint for FPUnsigned;

    mapping (address => address) public referrers;

    // FeeCalculator
    mapping(address => FPUnsigned) public referrerDiscounts;
    FPUnsigned public MAX_REFERRER_TRADE_DISCOUNT = FixedPoint.fromUnscaledUint(50).div(100);
    FPUnsigned public DEFAULT_REFFERER_TRADE_DISCOUNT = FixedPoint.fromUnscaledUint(5).div(100);

    // FeeDistributor
    mapping(address => FPUnsigned) public referralRedirect;
    FPUnsigned public MAX_REFERRER_REDIRECT = FixedPoint.fromUnscaledUint(50).div(100);
    FPUnsigned public DEFAULT_REFERRAL_REDIRECT = FixedPoint.fromUnscaledUint(5).div(100);

    // events
    event ReferrerRedirectSet(address referrer, FPUnsigned redirect);
    event ReferrerSet(address user, address referrer);
    event ReferrerFeeDiscountSet(address referer, FPUnsigned discounts);

    function setReferrerRedirect(address referrer, FPUnsigned redirect) external onlyOwner {
        require(redirect <= MAX_REFERRER_REDIRECT, '!max');
        referralRedirect[referrer] = redirect;
        emit ReferrerRedirectSet(referrer, redirect);
    }

    function setReferrerFeeDiscount(
        address referrer,
        FPUnsigned discount
    ) external onlyOwner {
        require(discount <= MAX_REFERRER_TRADE_DISCOUNT, '!max');
        referrerDiscounts[referrer] = discount;
        emit ReferrerFeeDiscountSet(referrer, discount);
    }
    
    function setReferrer(address user, address referrer) external {
        if (msg.sender != owner()) {
            require(msg.sender == user && referrers[user] == address(0), "!user" );
        }

        referrers[user] = referrer;
        emit ReferrerSet(user, referrer);
    }

    function getReferrerDiscount(address referrer) external override view returns (FPUnsigned) {
        if (referrer == address(0)) {
            return FixedPoint.ZERO;
        }
        if (referrerDiscounts[referrer] > FixedPoint.ZERO) {
            return referrerDiscounts[referrer];
        }
        return DEFAULT_REFFERER_TRADE_DISCOUNT;
    }

    function getReferrerRedirect(address referrer) external override view returns (FPUnsigned) {
        if (referrer == address(0)) {
            return FixedPoint.ZERO;
        }
        if (referralRedirect[referrer] > FixedPoint.ZERO) {
            return referralRedirect[referrer];
        }
        return DEFAULT_REFERRAL_REDIRECT;
    }
}