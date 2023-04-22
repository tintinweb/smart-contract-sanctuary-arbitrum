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
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import './interfaces/oracle/IPriceFeed.sol';
import './interfaces/oracle/IDIAOracle.sol';
import './access/Governable.sol';
import './lib/FixedPoint.sol';
import './lib/PerpLib.sol';

contract PriceFeed is Governable, IPriceFeed {
    using FixedPoint for FixedPoint.Unsigned;

    struct PriceFeedKey {
        string key;
        uint8 decimals;
    }

    address owner;
    IDIAOracle public diaOracle;
    mapping(bytes32 => PriceFeedKey) public productFeeds;

    event SetOwner(address owner);
    event SetDiaOracle(address newOracle, address prevOracle);
    event SetProductFeed(bytes32 productId, PriceFeedKey key);

    constructor(IDIAOracle _diaOracle) {
        owner = msg.sender;
        diaOracle = _diaOracle;
    }

    function setProductFeed(bytes32 productId, PriceFeedKey memory feedKey) external onlyOwner {
        productFeeds[productId] = feedKey;
        require(feedKey.decimals <= 18, '!decimals');

        emit SetProductFeed(productId, feedKey);
    }

    function getPrice(bytes32 productId) public view override returns (FixedPoint.Unsigned price) {
        PriceFeedKey memory feedKey = productFeeds[productId];
        require(bytes(feedKey.key).length > 0, '!productId');

        (uint128 value, ) = diaOracle.getValue(feedKey.key);

        price = FixedPoint.fromScalar(uint256(value), feedKey.decimals);
    }

    function setDiaOracle(IDIAOracle newOracle) external onlyOwner {
        require(address(newOracle) != address(0) && newOracle != diaOracle, '!invalid oracle');

        emit SetDiaOracle(address(newOracle), address(diaOracle));

        diaOracle = newOracle;
    }

    function setOwner(address _owner) external onlyGov {
        owner = _owner;
        emit SetOwner(_owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, '!owner');
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Governable {
    address public gov;

    constructor() {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, 'Governable: forbidden');
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

pragma solidity ^0.8.0;

interface IDIAOracle {
    function setValue(
        string memory key,
        uint128 value,
        uint128 timestamp
    ) external;

    function getValue(string memory key) external view returns (uint128, uint128);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../lib/FixedPoint.sol';

interface IPriceFeed {
    function getPrice(bytes32 productId) external view returns (FixedPoint.Unsigned);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../lib/FixedPoint.sol';

interface IFeeCalculator {
    function getFee(
        FixedPoint.Unsigned productFee,
        address user,
        address sender
    ) external view returns (FixedPoint.Unsigned);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../lib/FixedPoint.sol';

interface IFundingManager {
    function updateFunding(bytes32) external;

    function getFunding(bytes32) external view returns (FixedPoint.Signed);

    function getFundingRate(bytes32) external view returns (FixedPoint.Signed);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.8;

/**
 * @title Library for fixed point arithmetic on (u)ints
 */
library FixedPoint {
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For unsigned values:
    //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
    uint256 private constant FP_DECIMALS = 18;
    uint256 private constant FP_SCALING_FACTOR = 10**FP_DECIMALS;

    // --------------------------------------- UNSIGNED -----------------------------------------------------------------------------
    type Unsigned is uint256;

    /**
     * @notice Constructs an `Unsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a uint to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledUint(uint256 a) internal pure returns (Unsigned) {
        return Unsigned.wrap(a * FP_SCALING_FACTOR);
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned a, uint256 b) internal pure returns (bool) {
        return Unsigned.unwrap(a) == Unsigned.unwrap(fromUnscaledUint(b));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(a) == Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(a) > Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned a, uint256 b) internal pure returns (bool) {
        return Unsigned.unwrap(a) > Unsigned.unwrap(fromUnscaledUint(b));
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(uint256 a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(fromUnscaledUint(a)) > Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(a) >= Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned a, uint256 b) internal pure returns (bool) {
        return Unsigned.unwrap(a) >= Unsigned.unwrap(fromUnscaledUint(b));
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(uint256 a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(fromUnscaledUint(a)) >= Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(a) < Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned a, uint256 b) internal pure returns (bool) {
        return Unsigned.unwrap(a) < Unsigned.unwrap(fromUnscaledUint(b));
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(uint256 a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(fromUnscaledUint(a)) < Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(a) <= Unsigned.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned a, uint256 b) internal pure returns (bool) {
        return Unsigned.unwrap(a) <= Unsigned.unwrap(fromUnscaledUint(b));
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(uint256 a, Unsigned b) internal pure returns (bool) {
        return Unsigned.unwrap(fromUnscaledUint(a)) <= Unsigned.unwrap(b);
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the minimum of `a` and `b`.
     */
    function min(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        return Unsigned.unwrap(a) < Unsigned.unwrap(b) ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the maximum of `a` and `b`.
     */
    function max(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        return Unsigned.unwrap(a) > Unsigned.unwrap(b) ? a : b;
    }

    /**
     * @notice Adds two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        return Unsigned.wrap(Unsigned.unwrap(a) + Unsigned.unwrap(b));
    }

    /**
     * @notice Adds an `Unsigned` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        return Unsigned.wrap(Unsigned.unwrap(a) - Unsigned.unwrap(b));
    }

    /**
     * @notice Subtracts an unscaled uint256 from an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from an unscaled uint256, reverting on overflow.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(uint256 a, Unsigned b) internal pure returns (Unsigned) {
        return sub(fromUnscaledUint(a), b);
    }

    /**
     * @notice Multiplies two `Unsigned`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as a uint256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because FP_SCALING_FACTOR != 0.
        return Unsigned.wrap(Unsigned.unwrap(a) * Unsigned.unwrap(b) / FP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        return Unsigned.wrap(Unsigned.unwrap(a) * b);
    }

    /**
     * @notice Multiplies two `Unsigned`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        uint256 mulRaw = Unsigned.unwrap(a) * Unsigned.unwrap(b);
        uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
        uint256 mod = mulRaw % FP_SCALING_FACTOR;
        if (mod != 0) {
            return Unsigned.wrap(mulFloor + 1);
        } else {
            return Unsigned.wrap(mulFloor);
        }
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        // Since b is an uint, there is no risk of truncation and we can just mul it normally
        return Unsigned.wrap(Unsigned.unwrap(a) * b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as a uint256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Unsigned.wrap(Unsigned.unwrap(a) * FP_SCALING_FACTOR / Unsigned.unwrap(b));
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        return Unsigned.wrap(Unsigned.unwrap(a) / b);
    }

    /**
     * @notice Divides one unscaled uint256 by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a uint256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(uint256 a, Unsigned b) internal pure returns (Unsigned) {
        return div(fromUnscaledUint(a), b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned a, Unsigned b) internal pure returns (Unsigned) {
        uint256 aScaled = Unsigned.unwrap(a) * FP_SCALING_FACTOR;
        uint256 divFloor = aScaled / Unsigned.unwrap(b);
        uint256 mod = aScaled % Unsigned.unwrap(b);
        if (mod != 0) {
            return Unsigned.wrap(divFloor + 1);
        } else {
            return Unsigned.wrap(divFloor);
        }
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned a, uint256 b) internal pure returns (Unsigned) {
        // Because it is possible that a quotient gets truncated, we can't just call "Unsigned(Unsigned.unwrap(a).div(b))"
        // similarly to mulCeil with a uint256 as the second parameter. Therefore we need to convert b into an Unsigned.
        // This creates the possibility of overflow if b is very large.
        return divCeil(a, fromUnscaledUint(b));
    }

    /**
     * @notice Raises an `Unsigned` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return output is `a` to the power of `b`.
     */
    function pow(Unsigned a, uint256 b) internal pure returns (Unsigned output) {
        output = fromUnscaledUint(1);
        for (uint256 i = 0; i < b; i++) {
            output = mul(output, a);
        }
    }

    // ------------------------------------------------- SIGNED -------------------------------------------------------------
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For signed values:
    //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
    int256 private constant SFP_SCALING_FACTOR = 10**18;

    type Signed is int256;

    function fromSigned(Signed a) internal pure returns (Unsigned) {
        require(Signed.unwrap(a) >= 0, 'Negative value provided');
        return Unsigned.wrap(uint256(Signed.unwrap(a)));
    }

    function fromUnsigned(Unsigned a) internal pure returns (Signed) {
        require(Unsigned.unwrap(a) <= uint256(type(int256).max), 'Unsigned too large');
        return Signed.wrap(int256(Unsigned.unwrap(a)));
    }

    /**
     * @notice Constructs a `Signed` from an unscaled int, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a int to convert into a FixedPoint.Signed.
     * @return the converted FixedPoint.Signed.
     */
    function fromUnscaledInt(int256 a) internal pure returns (Signed) {
        return Signed.wrap(a * SFP_SCALING_FACTOR);
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a int256.
     * @return True if equal, or False.
     */
    function isEqual(Signed a, int256 b) internal pure returns (bool) {
        return Signed.unwrap(a) == Signed.unwrap(fromUnscaledInt(b));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if equal, or False.
     */
    function isEqual(Signed a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(a) == Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(a) > Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed a, int256 b) internal pure returns (bool) {
        return Signed.unwrap(a) > Signed.unwrap(fromUnscaledInt(b));
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(int256 a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(fromUnscaledInt(a)) > Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(a) >= Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed a, int256 b) internal pure returns (bool) {
        return Signed.unwrap(a) >= Signed.unwrap(fromUnscaledInt(b));
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(int256 a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(fromUnscaledInt(a)) >= Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(a) < Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed a, int256 b) internal pure returns (bool) {
        return Signed.unwrap(a) < Signed.unwrap(fromUnscaledInt(b));
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(int256 a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(fromUnscaledInt(a)) < Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(a) <= Signed.unwrap(b);
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed a, int256 b) internal pure returns (bool) {
        return Signed.unwrap(a) <= Signed.unwrap(fromUnscaledInt(b));
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(int256 a, Signed b) internal pure returns (bool) {
        return Signed.unwrap(fromUnscaledInt(a)) <= Signed.unwrap(b);
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the minimum of `a` and `b`.
     */
    function min(Signed a, Signed b) internal pure returns (Signed) {
        return Signed.unwrap(a) < Signed.unwrap(b) ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the maximum of `a` and `b`.
     */
    function max(Signed a, Signed b) internal pure returns (Signed) {
        return Signed.unwrap(a) > Signed.unwrap(b) ? a : b;
    }

    /**
     * @notice Adds two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the sum of `a` and `b`.
     */
    function add(Signed a, Signed b) internal pure returns (Signed) {
        return Signed.wrap(Signed.unwrap(a) + Signed.unwrap(b));
    }

    /**
     * @notice Adds a `Signed` to an unscaled int, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the sum of `a` and `b`.
     */
    function add(Signed a, int256 b) internal pure returns (Signed) {
        return add(a, fromUnscaledInt(b));
    }

    /**
     * @notice Adds a `Signed` to an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an Unsigned.
     * @return the sum of `a` and `b`.
     */
    function add(Signed a, Unsigned b) internal pure returns (Signed) {
        return add(a, fromUnsigned(b));
    }

    /**
     * @notice Adds a `Signed` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(Signed a, uint256 b) internal pure returns (Signed) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed a, Signed b) internal pure returns (Signed) {
        return Signed.wrap(Signed.unwrap(a) - Signed.unwrap(b));
    }

    /**
     * @notice Subtracts an unscaled int256 from a `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed a, int256 b) internal pure returns (Signed) {
        return sub(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from a `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Unsigned.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed a, Unsigned b) internal pure returns (Signed) {
        return sub(a, fromUnsigned(b));
    }

    /**
     * @notice Subtracts an unscaled uint256 from a `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed a, uint256 b) internal pure returns (Signed) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts a `Signed` from an unscaled int256, reverting on overflow.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(int256 a, Signed b) internal pure returns (Signed) {
        return sub(fromUnscaledInt(a), b);
    }

    /**
     * @notice Multiplies two `Signed`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mul(Signed a, Signed b) internal pure returns (Signed) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as an int256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because SFP_SCALING_FACTOR != 0.
        return Signed.wrap(Signed.unwrap(a) * Signed.unwrap(b) / SFP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies a `Signed` and an unscaled int256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the product of `a` and `b`.
     */
    function mul(Signed a, int256 b) internal pure returns (Signed) {
        return Signed.wrap(Signed.unwrap(a) * b);
    }

    /**
     * @notice Multiplies a `Signed` and `Unsigned`, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Unsigned.
     * @return the product of `a` and `b`.
     */
    function mul(Signed a, Unsigned b) internal pure returns (Signed) {
        return mul(a, fromUnsigned(b));
    }

    /**
     * @notice Multiplies a `Signed` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(Signed a, uint256 b) internal pure returns (Signed) {
        return mul(a, fromUnscaledUint(b));
    }

    function neg(Signed a) internal pure returns (Signed) {
        return mul(a, -1);
    }

    /**
     * @notice Multiplies two `Signed`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed a, Signed b) internal pure returns (Signed) {
        int256 mulRaw = Signed.unwrap(a) * Signed.unwrap(b);
        int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = mulRaw % SFP_SCALING_FACTOR;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed.wrap(mulTowardsZero + valueToAdd);
        } else {
            return Signed.wrap(mulTowardsZero);
        }
    }

    /**
     * @notice Multiplies a `Signed` and an unscaled int256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed a, int256 b) internal pure returns (Signed) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Signed.wrap(Signed.unwrap(a) * b);
    }

    /**
     * @notice Divides one `Signed` by a `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed a, Signed b) internal pure returns (Signed) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as an int256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Signed.wrap(Signed.unwrap(a) * SFP_SCALING_FACTOR / Signed.unwrap(b));
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed a, int256 b) internal pure returns (Signed) {
        return Signed.wrap(Signed.unwrap(a) / b);
    }

    /**
     * @notice Divides one `Signed` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint.Signed numerator.
     * @param b a FixedPoint.Unsigned denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed a, Unsigned b) internal pure returns (Signed) {
        return div(a, fromUnsigned(b));
    }

    /**
     * @notice Divides one `Signed` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed a, uint256 b) internal pure returns (Signed) {
        return div(a, fromUnscaledUint(b));
    }

    /**
     * @notice Divides one unscaled int256 by a `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a an int256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(int256 a, Signed b) internal pure returns (Signed) {
        return div(fromUnscaledInt(a), b);
    }

    /**
     * @notice Divides one `Signed` by a `Signed` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed a, Signed b) internal pure returns (Signed) {
        int256 aScaled = Signed.unwrap(a) * SFP_SCALING_FACTOR;
        int256 divTowardsZero = aScaled / Signed.unwrap(b);
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = aScaled % Signed.unwrap(b);
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed.wrap(divTowardsZero + valueToAdd);
        } else {
            return Signed.wrap(divTowardsZero);
        }
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed a, int256 b) internal pure returns (Signed) {
        // Because it is possible that a quotient gets truncated, we can't just call "Signed(Signed.unwrap(a).div(b))"
        // similarly to mulCeil with an int256 as the second parameter. Therefore we need to convert b into an Signed.
        // This creates the possibility of overflow if b is very large.
        return divAwayFromZero(a, fromUnscaledInt(b));
    }

    /**
     * @notice Raises a `Signed` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint.Signed.
     * @param b a uint256 (negative exponents are not allowed).
     * @return output is `a` to the power of `b`.
     */
    function pow(Signed a, uint256 b) internal pure returns (Signed output) {
        output = fromUnscaledInt(1);
        for (uint256 i = 0; i < b; i++) {
            output = mul(output, a);
        }
    }

    /**
     * @notice Absolute value of a FixedPoint.Signed
     */
    function abs(Signed value) internal pure returns (Unsigned) {
        int256 x = Signed.unwrap(value);
        uint256 raw = (x < 0) ? uint256(-x) : uint256(x);
        return Unsigned.wrap(raw);
    }

    /**
     * @notice Convert a FixedPoint.Unsigned to uint, "truncating" any decimal portion.
     */
    function trunc(FixedPoint.Unsigned value) internal pure returns (uint256) {
        return Unsigned.unwrap(value) / FP_SCALING_FACTOR;
    }

    /**
     * @notice Convert a FixedPoint.Unsigned to uint, "truncating" any decimal portion.
     */
    function trunc(FixedPoint.Signed value) internal pure returns (int256) {
        return Signed.unwrap(value) / SFP_SCALING_FACTOR;
    }

    /**
     * @notice Rounding a FixedPoint.Unsigned down to the nearest integer.
     */
    function floor(FixedPoint.Unsigned value) internal pure returns (FixedPoint.Unsigned) {
        return FixedPoint.fromUnscaledUint(trunc(value));
    }

    /**
     * @notice Round a FixedPoint.Unsigned up to the nearest integer.
     */
    function ceil(FixedPoint.Unsigned value) internal pure returns (FixedPoint.Unsigned) {
        FixedPoint.Unsigned iPart = floor(value);
        FixedPoint.Unsigned fPart = sub(value, iPart);
        if (Unsigned.unwrap(fPart) > 0) {
            return add(iPart, fromUnscaledUint(1));
        } else {
            return iPart;
        }
    }

    /**
     * @notice Given a uint with a certain number of decimal places, normalize it to a FixedPoint
     * @param value uint256, e.g. 10000000 wei USDC
     * @param decimals uint8 number of decimals to interpret `value` as, e.g. 6
     * @return output FixedPoint.Unsigned, e.g. (10.000000)
     */
    function fromScalar(uint256 value, uint8 decimals) internal pure returns (FixedPoint.Unsigned) {
        require(decimals <= FP_DECIMALS, 'FixedPoint: max decimals');
        return div(fromUnscaledUint(value), 10**decimals);
    }

    /**
     * @notice Convert a FixedPoint.Unsigned to uint, rounding up any decimal portion.
     */
    function roundUp(FixedPoint.Unsigned value) internal pure returns (uint256) {
        return trunc(ceil(value));
    }

    /**
     * @notice Round a trader's PnL in favor of liquidity providers
     */
    function roundTraderPnl(FixedPoint.Signed value) internal pure returns (FixedPoint.Signed) {
        if (Signed.unwrap(value) >= 0) {
            // If the P/L is a trader gain/value loss, then fractional dust gained for the trader should be reduced
            FixedPoint.Unsigned pnl = fromSigned(value);
            return fromUnsigned(floor(pnl));
        } else {
            // If the P/L is a trader loss/vault gain, then fractional dust lost should be magnified towards the trader
            return neg(fromUnsigned(ceil(abs(value))));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import './FixedPoint.sol';

import '../interfaces/perp/IFeeCalculator.sol';
import '../interfaces/perp/IFundingManager.sol';

library PerpLib {
    using FixedPoint for FixedPoint.Unsigned;
    using FixedPoint for FixedPoint.Signed;

    function _canTakeProfit(
        bool isLong,
        uint256 positionTimestamp,
        FixedPoint.Unsigned positionOraclePrice,
        FixedPoint.Unsigned oraclePrice,
        FixedPoint.Unsigned minPriceChange,
        uint256 minProfitTime
    ) internal view returns (bool) {
        if (block.timestamp > positionTimestamp + minProfitTime) {
            return true;
        } else if (isLong && oraclePrice.isGreaterThan(positionOraclePrice.mul(minPriceChange.add(1)))) {
            return true;
        } else if (
            !isLong &&
            oraclePrice.isLessThan(positionOraclePrice.mul(FixedPoint.fromUnscaledUint(1).sub(minPriceChange)))
        ) {
            return true;
        }
        return false;
    }

    function _getPnl(
        bool isLong,
        FixedPoint.Unsigned positionPrice,
        FixedPoint.Unsigned positionLeverage,
        uint256 margin,
        FixedPoint.Unsigned price
    ) internal pure returns (FixedPoint.Signed pnl) {
        pnl = (isLong
            ? FixedPoint.fromUnsigned(price).sub(positionPrice)
            : FixedPoint.fromUnsigned(positionPrice).sub(price)
            ).mul(margin).mul(positionLeverage).div(positionPrice);
    }

    function _getFundingPayment(
        bool isLong,
        FixedPoint.Unsigned positionLeverage,
        uint256 margin,
        FixedPoint.Signed funding,
        FixedPoint.Signed cumulativeFunding
    ) internal pure returns (FixedPoint.Signed) {
        FixedPoint.Signed actualMargin = FixedPoint.fromUnscaledUint(margin).fromUnsigned();
        return
            actualMargin.mul(positionLeverage).mul(
                isLong ? (cumulativeFunding.sub(funding)) : (funding.sub(cumulativeFunding))
            );
    }

    function _getTradeFee(
        uint256 margin,
        FixedPoint.Unsigned leverage,
        FixedPoint.Unsigned productFee,
        address user,
        address sender,
        IFeeCalculator feeCalculator
    ) internal view returns (uint256) {
        FixedPoint.Unsigned fee = feeCalculator.getFee(productFee, user, sender);
        return FixedPoint.fromUnscaledUint(margin).mul(leverage).mul(fee).roundUp();
    }
}