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

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
        uint256 len = _length(set._inner);
        bytes32[] memory arr = new bytes32[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function toArray(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        uint256 len = _length(set._inner);
        address[] memory arr = new address[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function toArray(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 len = _length(set._inner);
        uint256[] memory arr = new uint256[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC173Internal } from './IERC173Internal.sol';

/**
 * @title Contract ownership standard interface
 * @dev see https://eips.ethereum.org/EIPS/eip-173
 */
interface IERC173 is IERC173Internal {
    /**
     * @notice get the ERC173 contract owner
     * @return conrtact owner
     */
    function owner() external view returns (address);

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC173 interface needed by internal functions
 */
interface IERC173Internal {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { ReentrancyGuardStorage } from './ReentrancyGuardStorage.sol';

/**
 * @title Utility contract for preventing reentrancy attacks
 */
abstract contract ReentrancyGuard {
    error ReentrancyGuard__ReentrantCall();

    modifier nonReentrant() {
        ReentrancyGuardStorage.Layout storage l = ReentrancyGuardStorage
            .layout();
        if (l.status == 2) revert ReentrancyGuard__ReentrantCall();
        l.status = 2;
        _;
        l.status = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

library ReentrancyGuardStorage {
    struct Layout {
        uint256 status;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ReentrancyGuard');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { OTCVestingLib } from "../libraries/OTCVestingLib.sol";
import { IOTCVesting } from "../interfaces/IOTCVesting.sol";
import { DiamondOwnable } from "../helpers/DiamondOwnable.sol";
import { WithACLModifiers, WithPausableModifiers } from "../utils/Mixins.sol";
import { StructuredLinkedList } from "solidity-linked-list/contracts/StructuredLinkedList.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";
import { ReentrancyGuard } from "@solidstate/contracts/utils/ReentrancyGuard.sol";
import { VestingPosition, Distribution, DistributionInterval, IntervalOwnership } from "../storage/OTCVestingStorage.sol";

contract OTCVestingFacet is IOTCVesting, WithACLModifiers, WithPausableModifiers, ReentrancyGuard {
    using StructuredLinkedList for StructuredLinkedList.List;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    ///@inheritdoc IOTCVesting
    function transferVestingPosition(uint256 rootVestingId) external override whenNotPaused {
        OTCVestingLib.transferVestingPosition(rootVestingId);
    }

    ///@inheritdoc IOTCVesting
    function addVestingPosition(
        address owner,
        uint256 parentPosition,
        uint256 amount,
        uint256 startTime,
        bool isParentBurn
    ) external override onlyVestingManagers whenNotPaused {
        OTCVestingLib.addVestingPosition(owner, parentPosition, amount, startTime, isParentBurn);
    }

    ///@inheritdoc IOTCVesting
    function burn(uint256 positionId, uint256 amount) external override onlyAdmin whenNotPaused {
        OTCVestingLib.burn(positionId, amount);
    }

    ///@inheritdoc IOTCVesting
    function burnAll(uint256 positionId) external override onlyAdmin whenNotPaused {
        OTCVestingLib.burnAll(positionId);
    }

    ///@inheritdoc IOTCVesting
    function claimAllGFly() external override nonReentrant whenNotPaused {
        OTCVestingLib.claimAllGFly();
    }

    ///@inheritdoc IOTCVesting
    function claimGFly(uint256 positionId) external override nonReentrant whenNotPaused {
        OTCVestingLib.claimGFly(positionId);
    }

    ///@inheritdoc IOTCVesting
    function totalVestedOf(address account) external view override returns (uint256) {
        return OTCVestingLib.totalVestedOf(account);
    }

    ///@inheritdoc IOTCVesting
    function vestedOf(uint256 positionId) external view override returns (uint256) {
        return OTCVestingLib.vestedOf(positionId);
    }

    ///@inheritdoc IOTCVesting
    function totalClaimableOf(address account) external view override returns (uint256) {
        return OTCVestingLib.totalClaimableOf(account);
    }

    ///@inheritdoc IOTCVesting
    function claimableOf(uint256 positionId) external view override returns (uint256) {
        return OTCVestingLib.claimableOf(positionId);
    }

    ///@inheritdoc IOTCVesting
    function totalClaimedOf(address account) external view override returns (uint256) {
        return OTCVestingLib.totalClaimedOf(account);
    }

    ///@inheritdoc IOTCVesting
    function claimedOf(uint256 positionId) external view override returns (uint256) {
        return OTCVestingLib.claimedOf(positionId);
    }

    ///@inheritdoc IOTCVesting
    function totalBalance(address account) external view override returns (uint256) {
        return OTCVestingLib.totalBalance(account);
    }

    ///@inheritdoc IOTCVesting
    function balanceOfVesting(uint256 positionId) external view override returns (uint256) {
        return OTCVestingLib.balanceOfVesting(positionId);
    }

    ///@inheritdoc IOTCVesting
    function claimableOfAtTimestamp(uint256 positionId, uint256 timestamp) external view override returns (uint256) {
        return OTCVestingLib.claimableOfAtTimestamp(positionId, timestamp);
    }

    ///@inheritdoc IOTCVesting
    function getVestingIdsOfAddress(address account) external view override returns (uint256[] memory) {
        return OTCVestingLib.getVestingIdsOfAddress(account);
    }

    ///@inheritdoc IOTCVesting
    function maxBurnable(uint256 positionId) external view override returns (uint256) {
        return OTCVestingLib.maxBurnable(positionId);
    }

    ///@inheritdoc IOTCVesting
    function gFLY() external view override returns (address) {
        return OTCVestingLib.gFLY();
    }

    ///@inheritdoc IOTCVesting
    function vestedGFly() external view override returns (address) {
        return OTCVestingLib.vestedGFly();
    }

    ///@inheritdoc IOTCVesting
    function totalVestingPositions() external view override returns (uint256) {
        return OTCVestingLib.totalVestingPositions();
    }

    ///@inheritdoc IOTCVesting
    function totalDistributions() external view override returns (uint256) {
        return OTCVestingLib.totalDistributions();
    }

    ///@inheritdoc IOTCVesting
    function getVestingPosition(uint256 positionId) external view override returns (VestingPosition memory) {
        return OTCVestingLib.getVestingPosition(positionId);
    }

    ///@inheritdoc IOTCVesting
    function getDistribution(uint256 distributionId) external view override returns (Distribution memory) {
        return OTCVestingLib.getDistribution(distributionId);
    }

    ///@inheritdoc IOTCVesting
    function getDistributionInterval(
        uint256 distributionIntervalId
    ) external view override returns (DistributionInterval memory) {
        return OTCVestingLib.getDistributionInterval(distributionIntervalId);
    }

    ///@inheritdoc IOTCVesting
    function getIntervalOwnership(
        address owner,
        uint256 distributionIntervalId
    ) external view override returns (IntervalOwnership memory) {
        return OTCVestingLib.getIntervalOwnership(owner, distributionIntervalId);
    }

    ///@inheritdoc IOTCVesting
    function getVestingPositionsOfUser(address user) external view override returns (uint256[] memory) {
        return OTCVestingLib.getVestingPositionsOfUser(user);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import { LibDiamond } from "./LibDiamond.sol";
import { IERC173 } from "@solidstate/contracts/interfaces/IERC173.sol";

abstract contract DiamondOwnable is IERC173 {
    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    /**
     * @notice get the ERC173 contract owner
     * @return conrtact owner
     */
    function owner() public view returns (address) {
        return LibDiamond.contractOwner();
    }

    /**
     * @notice transfer contract ownership to new account
     * @param account address of new owner
     */
    function transferOwnership(address account) external onlyOwner {
        LibDiamond.setContractOwner(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(oldFacetAddress, selector);
            // add function
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGFly is IERC20 {
    function MAX_SUPPLY() external returns (uint256);

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { VestingPosition, Distribution, DistributionInterval, IntervalOwnership } from "../storage/OTCVestingStorage.sol";

/**
 * @title OTC Vesting
 * @notice Interface for gFLY OTC Vesting management
 */
interface IOTCVesting {
    event VestingPositionTransfered(uint256 rootVestingId, uint256 newVestingId, uint256 otcVestingId, address owner);
    event VestingPositionAdded(
        address owner,
        uint256 parentPosition,
        uint256 totalVestingPositions,
        uint256 amount,
        uint256 startTime,
        bool isParentBurn
    );
    event Burned(address owner, uint256 position, uint256 amount);
    event PositionClaimed(address owner, uint256 position, uint256 claimable);

    /**
     * @notice Transfers a vesting position to the OTC contract to make it OTC-tradeable.
     * @param rootVestingId the vesting position id to transfer
     */
    function transferVestingPosition(uint256 rootVestingId) external;

    /**
     * @notice Adds a vesting position from an existing OTC-tradeable vesting position
     * @param owner the owner of the new position
     * @param parentPosition the existing position to create the new position from
     * @param amount the amount of gFLY to transfer from the existing to the new position
     * @param startTime the timestamp when the transfer should start
     * @param isParentBurn Whether this is a burn of the parent position or not (used to simulate burns for unburnable positions)
     */
    function addVestingPosition(
        address owner,
        uint256 parentPosition,
        uint256 amount,
        uint256 startTime,
        bool isParentBurn
    ) external;

    /**
     * @notice Burns (part) of an OTC-tradeable vesting position
     * @param positionId the position to burn the gFLY from
     * @param amount the amount of gFLY to burn from the position
     */
    function burn(uint256 positionId, uint256 amount) external;

    /**
     * @notice Burns all the remaining gFLY of an OTC-tradeable vesting position (this actually transfers all remaning gFLY to the treasury address)
     * @param positionId the position to burn the gFLY from
     */
    function burnAll(uint256 positionId) external;

    /**
     * @notice Claims all gFLY eligible by the sender
     */
    function claimAllGFly() external;

    /**
     * @notice Claims all gFLY from an OTC-tradeable vesting position
     * @param positionId the position to claim the gFLY from
     */
    function claimGFly(uint256 positionId) external;

    /**
     * @notice Get the total amount of vested tokens of an account.
     * @param account the address to get the total amount from
     * @return the total amount of vested tokens of an account.
     */
    function totalVestedOf(address account) external view returns (uint256);

    /**
     * @notice Get the amount of vested tokens of vesting object.
     * @param positionId the position to get the vested tokens from
     * @return the amount of vested tokens of vesting object.
     */
    function vestedOf(uint256 positionId) external view returns (uint256);

    /**
     * @notice Get the total amount of claimable GFly of an account.
     * @param account the address to get the total amount from
     * @return the total amount of claimable GFly of an account.
     */
    function totalClaimableOf(address account) external view returns (uint256);

    /**
     * @notice Get the amount of claimable GFly of a vesting object.
     * @param positionId the position to get the claimable amount from
     * @return the amount of claimable GFly of the vesting object.
     */
    function claimableOf(uint256 positionId) external view returns (uint256);

    /**
     * @notice Get the total claimed amount of VestedGFly of an account.
     * @param account the address to get the total claimed amount from
     * @return the total claimed amount of VestedGFly of an account.
     */
    function totalClaimedOf(address account) external view returns (uint256);

    /**
     * @notice Get the claimed amount of VestedGFly of a vesting object
     * @param positionId the position to get the claimed amount from
     * @return the claimed amount of VestedGFly of a vesting object
     */
    function claimedOf(uint256 positionId) external view returns (uint256);

    /**
     * @notice Get the total balance of vestedGFly of an account.
     * @param account the address to get the total balance from
     * @return the total balance of vestedGFly of an account.
     */
    function totalBalance(address account) external view returns (uint256);

    /**
     * @notice Get the VestedGFly balance of a vesting object.
     * @param positionId the position to get VestedGFly balance from
     * @return the VestedGFly balance of a vesting object.
     */
    function balanceOfVesting(uint256 positionId) external view returns (uint256);

    /**
     * @notice Get the amount of claimable GFly of a vesting object at a certain point in time.
     * @param positionId the position to get the information from
     * @param timestamp the timestamp to get the information from
     * @return the amount of claimable GFly of a vesting object at a certain point in time.
     */
    function claimableOfAtTimestamp(uint256 positionId, uint256 timestamp) external view returns (uint256);

    /**
     * @notice Get the vestingIds of an address
     * @param account the address to get the total balance from
     * @return a list of vetsing ids of an address
     */
    function getVestingIdsOfAddress(address account) external view returns (uint256[] memory);

    /**
     * @notice Get maximum burnable amount of a vesting object.
     * This is based on the time difference since when an employee started working and the current time on a 36 months timeline.
     * @param positionId the position to get the information from
     * @return the maximum amount of burnable gFLY
     */
    function maxBurnable(uint256 positionId) external view returns (uint256);

    /**
     * @notice returns the gFLY address
     * @return the gFLY address
     */
    function gFLY() external view returns (address);

    /**
     * @notice returns the vgFLY address
     * @return the vgFLY address
     */
    function vestedGFly() external view returns (address);

    /**
     * @notice returns the total amount of vesting positions
     * @return the total amount of vesting positions
     */
    function totalVestingPositions() external view returns (uint256);

    /**
     * @notice returns the total amount of distributions
     * @return the total amount of distributions
     */
    function totalDistributions() external view returns (uint256);

    /**
     * @notice gets a vesting position object
     * @param positionId the id of the position object
     * @return a vesting position object
     */
    function getVestingPosition(uint256 positionId) external view returns (VestingPosition memory);

    /**
     * @notice gets a distribution object
     * @param distributionId the id of the distribution object
     * @return a distribution object
     */
    function getDistribution(uint256 distributionId) external view returns (Distribution memory);

    /**
     * @notice gets a distribution interval object
     * @param distributionIntervalId the id of the distribution interval object
     * @return a distribution interval object
     */
    function getDistributionInterval(
        uint256 distributionIntervalId
    ) external view returns (DistributionInterval memory);

    /**
     * @notice gets a interval ownership object
     * @param owner the address of the owner
     * @param distributionIntervalId the id of the distribution interval object
     * @return a interval ownership object
     */
    function getIntervalOwnership(
        address owner,
        uint256 distributionIntervalId
    ) external view returns (IntervalOwnership memory);

    /**
     * @notice gets an array of vesting position ids belonging to a user
     * @param user the address of the user
     * @return an array of vesting position ids belonging to a user
     */
    function getVestingPositionsOfUser(address user) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVestedGFly is IERC20 {
    struct VestingPosition {
        bool burnable;
        bool minted;
        address owner;
        uint256 startTime;
        uint256 lastBurnTime;
        uint256 employmentTimestamp;
        uint256 remainingAllocation;
        uint256 initialAllocation;
        uint256 initialUnlockable;
        uint256 burnt;
        uint256 vestedAtLastBurn;
        uint256 employeeBurnt;
    }

    function addVestingPosition(
        address owner,
        uint256 amount,
        bool burnable,
        uint256 initialUnlockable,
        uint256 employmentTimestamp
    ) external;

    function mint() external;

    function burn(uint256 vestingId, uint256 amount) external;

    function burnAll(uint256 vestingId) external;

    function transferVestingPosition(uint256 vestingId, uint256 amount, address newOwner) external;

    function claimAllGFly() external;

    function claimGFly(uint256 vestingId) external;

    function totalVestedOf(address account) external view returns (uint256 total);

    function vestedOf(uint256 vestingId) external view returns (uint256);

    function totalClaimableOf(address account) external view returns (uint256 total);

    function claimableOf(uint256 vestingId) external view returns (uint256);

    function totalClaimedOf(address account) external view returns (uint256 total);

    function claimedOf(uint256 vestingId) external view returns (uint256);

    function totalBalance(address account) external view returns (uint256 total);

    function balanceOfVesting(uint256 vestingId) external view returns (uint256);

    function getVestingIdsOfAddress(address account) external view returns (uint256[] memory);

    function maxBurnable(uint256 vestingId) external view returns (uint256 burnable);

    function claimableOfAtTimestamp(uint256 vestingId, uint256 timestamp) external view returns (uint256);

    function unminted() external returns (uint256);

    function vestingPosition(uint256 vestingId) external view returns (VestingPosition memory);

    function currentVestingId() external view returns (uint256 currentVestingId);

    event VestingPositionAdded(
        address indexed owner,
        uint256 indexed vestingId,
        uint256 amount,
        bool burnable,
        uint256 initialUnlockable,
        uint256 startTime
    );
    event Minted(address indexed owner, uint256 indexed vestingId, uint256 amount);
    event Burned(address indexed owner, uint256 indexed vestingId, uint256 amount);
    event GFlyClaimed(address indexed owner, uint256 indexed vestingId, uint256 amount);
    event VestingPositionTransfered(
        address indexed owner,
        uint256 indexed vestingId,
        address indexed newOwner,
        uint256 newVestingId,
        uint256 amount
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../storage/OTCVestingStorage.sol";
import "../interfaces/IVestedGFly.sol";
import "../interfaces/IGFly.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import { StructuredLinkedList } from "solidity-linked-list/contracts/StructuredLinkedList.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

library OTCVestingLib {
    error InvalidOwner(uint256 rootVestingId, address account);
    error CannotAddPositionInPast(address owner, uint256 amount, uint256 parentPosition);
    error InvalidVestingAmount(uint256 amount);
    error NonExistingDistribution(uint256 position);
    error TooMuchDistributed(uint256 intervalId, uint256 toClaim, uint256 totalDistributed);
    error ClaimedExceedsClaimable(uint256 intervalId, uint256 claimed, uint256 claimable);
    error NonBurnable(uint256 position);
    error BurnAmountExceeded(uint256 position);
    error VestedAmountExceeded(uint256 position, uint256 amount, uint256 toBeVested);
    error NotOwnerOfVestingPosition(uint256 position, address account);

    event VestingPositionTransfered(uint256 rootVestingId, uint256 newVestingId, uint256 otcVestingId, address owner);
    event VestingPositionAdded(
        address owner,
        uint256 parentPosition,
        uint256 totalVestingPositions,
        uint256 amount,
        uint256 startTime,
        bool isParentBurn
    );
    event Burned(address owner, uint256 position, uint256 amount);
    event PositionClaimed(address owner, uint256 position, uint256 claimable);

    using StructuredLinkedList for StructuredLinkedList.List;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct IntervalSplitStruct {
        address owner;
        uint256 startTime;
        uint256 endTime;
        uint256 start;
        uint256 end;
        uint256 percentageToReservePerInterval;
        uint256 totalIntervalOwners;
        uint256 next;
    }

    function transferVestingPosition(uint256 rootVestingId) internal {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        IVestedGFly.VestingPosition memory rootVestingPosition = IVestedGFly(s.vestedGFly).vestingPosition(
            rootVestingId
        );
        if (msg.sender != rootVestingPosition.owner) revert InvalidOwner(rootVestingId, msg.sender);

        //calculate total transferable from old position + transfer to new position
        uint256 transferableFromRootPosition = IVestedGFly(s.vestedGFly).balanceOfVesting(rootVestingId) -
            IVestedGFly(s.vestedGFly).claimableOf(rootVestingId);
        IVestedGFly(s.vestedGFly).transferVestingPosition(rootVestingId, transferableFromRootPosition, address(this));
        uint256 newVestingId = IVestedGFly(s.vestedGFly).currentVestingId();

        //increase counters
        ++s.totalDistributions;
        ++s.totalVestingPositions;
        ++s.totalIntervals;

        //create new distribution
        s.distributions[s.totalDistributions].owner = msg.sender;
        s.distributions[s.totalDistributions].rootId = newVestingId;
        s.distributions[s.totalDistributions].employmentTimestamp = rootVestingPosition.employmentTimestamp;
        s.distributions[s.totalDistributions].initialAllocation = rootVestingPosition.initialAllocation;
        s.distributions[s.totalDistributions].distributionIntervalHead = s.totalIntervals;
        s.distributions[s.totalDistributions].distributionIntervalStart = s.totalIntervals;
        s.distributions[s.totalDistributions].totalIntervals = 1;
        s.distributionIntervalIds[s.totalDistributions].pushFront(s.totalIntervals);

        //create new distribution interval and link to distribution
        uint256 end = IVestedGFly(s.vestedGFly).vestingPosition(newVestingId).startTime +
            (36 * OTCVestingStorage.MONTH);
        s.distributionIntervals[s.totalIntervals].start = block.timestamp;
        s.distributionIntervals[s.totalIntervals].end = end;
        s.distributionIntervals[s.totalIntervals].claimable = IVestedGFly(s.vestedGFly).claimableOfAtTimestamp(
            newVestingId,
            end
        );
        s.distributionIntervals[s.totalIntervals].totalOwners = 1;
        s.ownersPerDistributionInterval[s.totalIntervals].add(msg.sender);
        s.ownershipPerDistributionInterval[s.totalIntervals][msg.sender] = IntervalOwnership({
            owner: msg.sender,
            percentageInWei: OTCVestingStorage.ONE
        });

        //add new vesting position
        s.vestingPositions[s.totalVestingPositions].owner = msg.sender;
        s.vestingPositions[s.totalVestingPositions].distribution = s.totalDistributions;
        s.vestingPositions[s.totalVestingPositions].initialAllocation = transferableFromRootPosition;
        s.vestingPositions[s.totalVestingPositions].burnable = rootVestingPosition.burnable;
        s.vestingPositions[s.totalVestingPositions].burnt = 0;
        s.vestingPositions[s.totalVestingPositions].startTime = block.timestamp;
        s.allUserVestingPositions[msg.sender].add(s.totalVestingPositions);
        emit VestingPositionTransfered(rootVestingId, newVestingId, s.totalVestingPositions, msg.sender);
    }

    function addVestingPosition(
        address owner,
        uint256 parentPosition,
        uint256 amount,
        uint256 startTime,
        bool isParentBurn
    ) internal {
        //TODO: make sure you can't fill in one round 2 times from same origin position.
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        if (startTime < block.timestamp) revert CannotAddPositionInPast(owner, amount, parentPosition);
        //claim outstanding gFLY
        _claim(parentPosition);

        //compute vested gFLY allocated to parent position for the next 12 months (or remaining months when we need to burn the position)
        Distribution storage distribution = s.distributions[s.vestingPositions[parentPosition].distribution];
        uint256 parentStartTime = IVestedGFly(s.vestedGFly).vestingPosition(distribution.rootId).startTime;
        uint256 endTime = isParentBurn ? parentStartTime + (OTCVestingStorage.MONTH * 36) : startTime + 365 days;
        uint256 allocatedToParent = _allocatedAmount(parentPosition, startTime, endTime);
        // We can only sell 50% of next 12 months (unless we burn the position).
        if (
            amount == 0 ||
            (!isParentBurn && amount > (allocatedToParent / 2)) ||
            (isParentBurn && amount > allocatedToParent)
        ) revert InvalidVestingAmount(amount);

        //calculate percentage to be distributed to new position + modify intervals to do this
        uint256 percentageToReservePerInterval = (amount * OTCVestingStorage.ONE) / allocatedToParent;
        _setDistributionIntervalsForNewVestingPosition(
            owner,
            parentPosition,
            startTime,
            endTime,
            percentageToReservePerInterval
        );

        // add new vesting position
        ++s.totalVestingPositions;
        s.vestingPositions[s.totalVestingPositions].owner = owner;
        s.vestingPositions[s.totalVestingPositions].distribution = s.vestingPositions[parentPosition].distribution;
        s.vestingPositions[s.totalVestingPositions].initialAllocation = amount;
        s.vestingPositions[s.totalVestingPositions].startTime = startTime;
        s.vestingPositions[parentPosition].burnt += amount;
        s.allUserVestingPositions[owner].add(s.totalVestingPositions);
        emit VestingPositionAdded(owner, parentPosition, s.totalVestingPositions, amount, startTime, isParentBurn);
    }

    /**
     * @dev Function to burn VestedGFly from vested positions
     */
    function burn(uint256 positionId, uint256 amount) internal {
        _burn(positionId, amount, false);
    }

    /**
     * @dev Function to burn all VestedGFly from vested positions
     */
    function burnAll(uint256 positionId) internal {
        _burn(positionId, 0, true);
    }

    /**
     * @dev Function to claim all GFly (burn VestedGFly following vesting schedule and mint GFly 1 to 1)
     */
    function claimAllGFly() internal {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        for (uint256 i = 0; i < s.allUserVestingPositions[msg.sender].toArray().length; i++) {
            uint256 position = s.allUserVestingPositions[msg.sender].at(i);
            _claimGFly(position, msg.sender);
        }
    }

    /**
     * @dev Function to claim GFly for a specific vestingId (burn VestedGFly following vesting schedule and mint GFly 1 to 1)
     */
    function claimGFly(uint256 positionId) internal {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        if (s.vestingPositions[positionId].owner != msg.sender)
            revert NotOwnerOfVestingPosition(positionId, msg.sender);
        _claimGFly(positionId, msg.sender);
    }

    /**
     * @dev Get the total amount of vested tokens of an account.
     */
    function totalVestedOf(address account) internal view returns (uint256 total) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        for (uint256 i = 0; i < s.allUserVestingPositions[account].toArray().length; i++) {
            uint256 positionId = s.allUserVestingPositions[account].at(i);
            (uint256 vested, , ) = _vestingSnapshot(positionId, block.timestamp);
            total += vested;
        }
    }

    /**
     * @dev Get the amount of vested tokens of vesting object.
     */
    function vestedOf(uint256 positionId) internal view returns (uint256) {
        (uint256 vested, , ) = _vestingSnapshot(positionId, block.timestamp);
        return vested;
    }

    /**
     * @dev Get the total amount of claimable GFly of an account.
     */
    function totalClaimableOf(address account) internal view returns (uint256 total) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        for (uint256 i = 0; i < s.allUserVestingPositions[account].toArray().length; i++) {
            uint256 positionId = s.allUserVestingPositions[account].at(i);
            (uint256 vested, uint256 claimed, uint256 balance) = _vestingSnapshot(positionId, block.timestamp);
            uint256 claimable = vested >= claimed ? vested - claimed : 0;
            total += Math.min(claimable, balance);
        }
    }

    /**
     * @dev Get the amount of claimable GFly of a vesting object.
     */
    function claimableOf(uint256 positionId) internal view returns (uint256) {
        (uint256 vested, uint256 claimed, uint256 balance) = _vestingSnapshot(positionId, block.timestamp);
        uint256 claimable = vested >= claimed ? vested - claimed : 0;
        return Math.min(claimable, balance);
    }

    /**
     * @dev Get the total claimed amount of VestedGFly of an account.
     */
    function totalClaimedOf(address account) internal view returns (uint256 total) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        for (uint256 i = 0; i < s.allUserVestingPositions[account].toArray().length; i++) {
            uint256 positionId = s.allUserVestingPositions[account].at(i);
            (, uint256 claimed, ) = _vestingSnapshot(positionId, block.timestamp);
            total += claimed;
        }
    }

    /**
     * @dev Get the claimed amount of VestedGFly of a vesting object
     */
    function claimedOf(uint256 positionId) internal view returns (uint256) {
        (, uint256 claimed, ) = _vestingSnapshot(positionId, block.timestamp);
        return claimed;
    }

    /**
     * @dev Get the total balance of vestedGFly of an account.
     */
    function totalBalance(address account) internal view returns (uint256 total) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        for (uint256 i = 0; i < s.allUserVestingPositions[account].toArray().length; i++) {
            uint256 positionId = s.allUserVestingPositions[account].at(i);
            (, , uint256 balance) = _vestingSnapshot(positionId, block.timestamp);
            total += balance;
        }
    }

    /**
     * @dev Get the VestedGFly balance of a vesting object.
     */
    function balanceOfVesting(uint256 positionId) internal view returns (uint256) {
        (, , uint256 balance) = _vestingSnapshot(positionId, block.timestamp);
        return balance;
    }

    /**
     * @dev Get the amount of claimable GFly of a vesting object at a certain point in time.
     */
    function claimableOfAtTimestamp(uint256 positionId, uint256 timestamp) internal view returns (uint256) {
        (uint256 vested, uint256 claimed, uint256 balance) = _vestingSnapshot(
            positionId,
            Math.max(block.timestamp, timestamp)
        );
        uint256 claimable = vested >= claimed ? vested - claimed : 0;
        return Math.min(claimable, balance);
    }

    /**
     * @dev Get the vestingIds of an address
     */
    function getVestingIdsOfAddress(address account) internal view returns (uint256[] memory) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        return s.allUserVestingPositions[account].toArray();
    }

    /**
     * @dev Get maximum burnable amount of a vesting object.
     * This is based on the time difference since when an employee started working and the current time on a 36 months timeline.
     */
    function maxBurnable(uint256 positionId) internal view returns (uint256 burnable) {
        burnable = 0;
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        VestingPosition memory position = s.vestingPositions[positionId];
        if (position.burnable) {
            uint256 elapsedTime = Math.min(
                block.timestamp - s.distributions[position.distribution].employmentTimestamp,
                OTCVestingStorage.MONTH * 36
            );
            burnable =
                s.distributions[position.distribution].initialAllocation -
                ((elapsedTime * s.distributions[position.distribution].initialAllocation) /
                    (OTCVestingStorage.MONTH * 36));
        }
    }

    function gFLY() internal view returns (address) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        return s.gFLY;
    }

    function vestedGFly() internal view returns (address) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        return s.vestedGFly;
    }

    function totalVestingPositions() internal view returns (uint256) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        return s.totalVestingPositions;
    }

    function totalDistributions() internal view returns (uint256) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        return s.totalDistributions;
    }

    function getVestingPosition(uint256 positionId) internal view returns (VestingPosition memory) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        return s.vestingPositions[positionId];
    }

    function getDistribution(uint256 distributionId) internal view returns (Distribution memory) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        return s.distributions[distributionId];
    }

    function getDistributionInterval(
        uint256 distributionIntervalId
    ) internal view returns (DistributionInterval memory) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        return s.distributionIntervals[distributionIntervalId];
    }

    function getIntervalOwnership(
        address owner,
        uint256 distributionIntervalId
    ) internal view returns (IntervalOwnership memory) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        return s.ownershipPerDistributionInterval[distributionIntervalId][owner];
    }

    function getVestingPositionsOfUser(address user) internal view returns (uint256[] memory) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        return s.allUserVestingPositions[user].toArray();
    }

    function _vestingSnapshot(uint256 positionId, uint256 timestamp) internal view returns (uint256, uint256, uint256) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        VestingPosition memory position = s.vestingPositions[positionId];
        uint256 claimed = position.claimed;
        uint256 balance = position.initialAllocation - position.burnt - claimed;
        return (_totalVestedOf(positionId, timestamp), claimed, balance);
    }

    function _totalVestedOf(uint256 vestingId, uint256 currentTime) internal view returns (uint256 vested) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        VestingPosition storage position = s.vestingPositions[vestingId];
        //return 0 if vesting position has not yet started
        if (currentTime < position.startTime) {
            return 0;
        }
        Distribution storage distribution = s.distributions[position.distribution];

        //set next to start interval.
        uint256 next = distribution.distributionIntervalStart;
        uint256 totalVestedOverFullRange;
        uint256 totalVestedUntilCurrentTime = IVestedGFly(s.vestedGFly).vestedOf(distribution.rootId) +
            (IVestedGFly(s.vestedGFly).claimableOfAtTimestamp(distribution.rootId, currentTime) -
                IVestedGFly(s.vestedGFly).claimableOfAtTimestamp(distribution.rootId, block.timestamp));
        uint256 totalClaimableAtRunningInterval;
        uint256 percentageOwnedAtRunningInterval;
        uint256 vestedAtRunningInterval;

        //iterate over all intervals
        while (next != 0) {
            DistributionInterval storage interval = s.distributionIntervals[next];
            if (position.startTime < interval.end && currentTime > interval.start) {
                //when the position is included in the interval
                if (interval.end <= currentTime) {
                    // when the interval has already passed, calculate the total vested amount allocated
                    // to this position in this interval.
                    uint256 totalClaimable = interval.claimable;
                    uint256 percentageOwned = s.ownershipPerDistributionInterval[next][position.owner].percentageInWei;
                    vested += (totalClaimable * percentageOwned) / OTCVestingStorage.ONE;
                    totalVestedOverFullRange += interval.claimable;
                } else {
                    // when the interval is in progress, store the percentage owned for this position as we need it to
                    // calculate at the end.
                    totalClaimableAtRunningInterval = interval.claimable;
                    totalVestedOverFullRange += interval.claimable;
                    percentageOwnedAtRunningInterval = s
                    .ownershipPerDistributionInterval[next][position.owner].percentageInWei;
                }
            } else if (position.startTime > interval.end) {
                //when the interval is older than the position, add the claimable amount to the total vested amount
                totalVestedOverFullRange += interval.claimable;
            } else {
                //break as we don't need interval data past the position's range
                break;
            }
            (, next) = s.distributionIntervalIds[position.distribution].getNextNode(next);
        }
        //calculate how much is vested at the running interval
        vestedAtRunningInterval =
            totalClaimableAtRunningInterval -
            (totalVestedOverFullRange - totalVestedUntilCurrentTime);
        //total vested is vested in the past + vested at running interval
        vested = vested + ((vestedAtRunningInterval * percentageOwnedAtRunningInterval) / OTCVestingStorage.ONE);
    }

    function _claimGFly(uint256 positionId, address account) internal {
        _claim(positionId);
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        VestingPosition memory position = s.vestingPositions[positionId];
        uint256 claimable = s.claimableGFlyPerDistribution[position.distribution][account];
        if (claimable > 0) {
            // Never claim more than allowed. This can happen because of rounding precision errors for interval ownership
            if (position.initialAllocation - position.burnt < position.claimed + claimable) {
                claimable -= (position.claimed + claimable) - (position.initialAllocation - position.burnt);
            }
            s.vestingPositions[positionId].claimed += claimable;
            s.claimableGFlyPerDistribution[position.distribution][account] = 0;
            IGFly(s.gFLY).transfer(account, claimable);
            emit PositionClaimed(account, positionId, claimable);
        }
    }

    function _burn(uint256 positionId, uint256 amount, bool isBurnAll) internal {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        VestingPosition memory position = s.vestingPositions[positionId];
        if (!position.burnable) revert NonBurnable(positionId);
        if (position.burnt + amount > maxBurnable(positionId)) revert BurnAmountExceeded(positionId);

        //calculate total amount still to be vested on root vgFLY position + verify amount does not exceed it.
        uint256 rootId = s.distributions[s.vestingPositions[positionId].distribution].rootId;
        uint256 rootStartTime = IVestedGFly(s.vestedGFly).vestingPosition(rootId).startTime;
        uint256 toBeVested = IVestedGFly(s.vestedGFly).claimableOfAtTimestamp(
            rootId,
            rootStartTime + (OTCVestingStorage.MONTH * 36)
        ) - IVestedGFly(s.vestedGFly).claimableOfAtTimestamp(rootId, block.timestamp);
        if (amount > toBeVested) revert VestedAmountExceeded(positionId, amount, toBeVested);

        //if burnAll we take the max burnable amount instead
        if (isBurnAll) {
            amount = Math.min(toBeVested, maxBurnable(positionId));
        }

        //claim outstanding gFLY + allocate vesting position to treasury
        //(burning is not really possible because transfered positions are not burnable (see vgFLY))
        _claimGFly(positionId, position.owner);
        addVestingPosition(s.treasury, positionId, amount, block.timestamp, true);
        emit Burned(s.vestingPositions[positionId].owner, positionId, amount);
    }

    function _allocatedAmount(
        uint256 parentPosition,
        uint256 startTime,
        uint256 endTime
    ) internal view returns (uint256 allocated) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        VestingPosition memory parentVestingPosition = s.vestingPositions[parentPosition];

        //Make sure parent position and the distribution exist
        if (parentPosition > 0 && parentVestingPosition.distribution > 0) {
            Distribution storage distribution = s.distributions[parentVestingPosition.distribution];

            //start at the head of the active intervals
            uint256 next = distribution.distributionIntervalHead;

            //loop till the end of the intervals
            while (next != 0) {
                DistributionInterval storage interval = s.distributionIntervals[next];
                uint256 start = interval.start;
                uint256 end = interval.end;

                //Make sure the interval falls within the time range
                if (startTime < end && start < endTime) {
                    //Set specific start and/or end when the range starts/end mid interval
                    if (startTime > start) {
                        start = startTime;
                    }
                    if (endTime < end) {
                        end = endTime;
                    }

                    //Calculate amount claimable in timeframe
                    uint256 totalClaimable = IVestedGFly(s.vestedGFly).claimableOfAtTimestamp(
                        distribution.rootId,
                        end
                    ) - IVestedGFly(s.vestedGFly).claimableOfAtTimestamp(distribution.rootId, start);

                    //loop over all interval owners and find the total percentage of
                    //this interval allocated to the position owner
                    uint256 percentageFilled;
                    for (uint256 j = 0; j < s.ownersPerDistributionInterval[next].length(); j++) {
                        if (
                            parentVestingPosition.owner ==
                            s.ownershipPerDistributionInterval[next][s.ownersPerDistributionInterval[next].at(j)].owner
                        ) {
                            percentageFilled += s
                            .ownershipPerDistributionInterval[next][s.ownersPerDistributionInterval[next].at(j)]
                                .percentageInWei;
                        }
                    }
                    allocated += (totalClaimable * percentageFilled) / OTCVestingStorage.ONE;
                }
                (, next) = s.distributionIntervalIds[parentVestingPosition.distribution].getNextNode(next);
            }
        }
    }

    function _setDistributionIntervalsForNewVestingPosition(
        address owner,
        uint256 parentPosition,
        uint256 startTime,
        uint256 endTime,
        uint256 percentageToReservePerInterval
    ) internal {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        VestingPosition storage parentVestingPosition = s.vestingPositions[parentPosition];
        Distribution storage distribution = s.distributions[parentVestingPosition.distribution];
        //start at the head of the active intervals
        uint256 next = distribution.distributionIntervalHead;
        //loop till the end of the intervals
        while (next != 0) {
            DistributionInterval storage interval = s.distributionIntervals[next];
            uint256 start = interval.start;
            uint256 end = interval.end;
            uint256 totalIntervalOwners = interval.totalOwners;
            //Make sure the interval falls within the time range
            if (
                startTime < end &&
                start < endTime &&
                s.ownersPerDistributionInterval[next].contains(parentVestingPosition.owner)
            ) {
                if (startTime > start && endTime >= end) {
                    // split up --> interval overlaps at start
                    IntervalSplitStruct memory intervalSplitStruct = IntervalSplitStruct(
                        owner,
                        startTime,
                        endTime,
                        start,
                        end,
                        percentageToReservePerInterval,
                        totalIntervalOwners,
                        next
                    );
                    next = _splitUpIntervalAtStart(interval, distribution, parentVestingPosition, intervalSplitStruct);
                } else if (startTime <= start && endTime < end) {
                    // split up --> interval overlaps at end
                    IntervalSplitStruct memory intervalSplitStruct = IntervalSplitStruct(
                        owner,
                        startTime,
                        endTime,
                        start,
                        end,
                        percentageToReservePerInterval,
                        totalIntervalOwners,
                        next
                    );
                    next = _splitUpIntervalAtEnd(interval, distribution, parentVestingPosition, intervalSplitStruct);
                } else if (start < startTime && end > endTime) {
                    // split up --> interval overlaps at start and end
                    IntervalSplitStruct memory intervalSplitStruct = IntervalSplitStruct(
                        owner,
                        startTime,
                        endTime,
                        start,
                        end,
                        percentageToReservePerInterval,
                        totalIntervalOwners,
                        next
                    );
                    next = _splitUpIntervalAtStartAndEnd(
                        interval,
                        distribution,
                        parentVestingPosition,
                        intervalSplitStruct
                    );
                } else {
                    // split up --> interval falls in range
                    IntervalSplitStruct memory intervalSplitStruct = IntervalSplitStruct(
                        owner,
                        startTime,
                        endTime,
                        start,
                        end,
                        percentageToReservePerInterval,
                        totalIntervalOwners,
                        next
                    );
                    next = _splitUpIntervalInRange(parentVestingPosition, intervalSplitStruct);
                }
            } else {
                (, next) = s.distributionIntervalIds[parentVestingPosition.distribution].getNextNode(next);
            }
        }
    }

    function _splitUpIntervalAtStart(
        DistributionInterval storage interval,
        Distribution storage distribution,
        VestingPosition storage parentVestingPosition,
        IntervalSplitStruct memory intervalSplitStruct
    ) internal returns (uint256) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        // split up --> interval overlaps at start
        // split up in 2 intervals and add the new position to the second interval
        uint256 newClaimable = IVestedGFly(s.vestedGFly).claimableOfAtTimestamp(
            distribution.rootId,
            intervalSplitStruct.end
        ) - IVestedGFly(s.vestedGFly).claimableOfAtTimestamp(distribution.rootId, intervalSplitStruct.startTime);
        //set state of existing interval
        interval.end = intervalSplitStruct.startTime - 1;
        interval.claimable = interval.claimable - newClaimable;
        //create new interval
        uint256 totalIntervals = ++s.totalIntervals;
        ++distribution.totalIntervals;
        s.distributionIntervals[totalIntervals].start = intervalSplitStruct.startTime;
        s.distributionIntervals[totalIntervals].end = intervalSplitStruct.end;
        s.distributionIntervals[totalIntervals].claimable = newClaimable;
        //add new owner to new interval.
        _copyOwnersToNewIntervals(
            intervalSplitStruct.next,
            totalIntervals,
            0,
            parentVestingPosition.owner,
            intervalSplitStruct.owner,
            intervalSplitStruct.percentageToReservePerInterval
        );
        // insert new interval in linked list.
        s.distributionIntervalIds[parentVestingPosition.distribution].insertAfter(
            intervalSplitStruct.next,
            totalIntervals
        );
        (, uint256 next) = s.distributionIntervalIds[parentVestingPosition.distribution].getNextNode(totalIntervals);
        return next;
    }

    function _splitUpIntervalAtEnd(
        DistributionInterval storage interval,
        Distribution storage distribution,
        VestingPosition storage parentVestingPosition,
        IntervalSplitStruct memory intervalSplitStruct
    ) internal returns (uint256) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        // split up --> interval overlaps at end
        // split up 2 intervals and the new position to the first interval

        //create new interval
        uint256 totalIntervals = ++s.totalIntervals;
        ++distribution.totalIntervals;
        s.distributionIntervals[totalIntervals].start = interval.start;
        s.distributionIntervals[totalIntervals].end = intervalSplitStruct.endTime;
        s.distributionIntervals[totalIntervals].claimed = interval.claimed;
        //set state of existing interval
        uint256 newClaimable = IVestedGFly(s.vestedGFly).claimableOfAtTimestamp(
            distribution.rootId,
            intervalSplitStruct.end
        ) - IVestedGFly(s.vestedGFly).claimableOfAtTimestamp(distribution.rootId, intervalSplitStruct.endTime);
        s.distributionIntervals[totalIntervals].claimable = newClaimable;
        interval.start = intervalSplitStruct.endTime + 1;
        interval.claimable = interval.claimable - newClaimable;
        interval.claimed = 0;
        //add new owner to new interval.
        _copyOwnersToNewIntervals(
            intervalSplitStruct.next,
            totalIntervals,
            0,
            parentVestingPosition.owner,
            intervalSplitStruct.owner,
            intervalSplitStruct.percentageToReservePerInterval
        );
        // insert new interval in linked list.
        s.distributionIntervalIds[parentVestingPosition.distribution].insertBefore(
            intervalSplitStruct.next,
            totalIntervals
        );
        (, uint256 next) = s.distributionIntervalIds[parentVestingPosition.distribution].getNextNode(
            intervalSplitStruct.next
        );
        return next;
    }

    function _splitUpIntervalAtStartAndEnd(
        DistributionInterval storage interval,
        Distribution storage distribution,
        VestingPosition storage parentVestingPosition,
        IntervalSplitStruct memory intervalSplitStruct
    ) internal returns (uint256) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        // split up --> interval overlaps at start and end
        // split up 3 intervals and add the new position to the middle interval
        uint256 endClaimable = IVestedGFly(s.vestedGFly).claimableOfAtTimestamp(
            distribution.rootId,
            intervalSplitStruct.end
        ) - IVestedGFly(s.vestedGFly).claimableOfAtTimestamp(distribution.rootId, intervalSplitStruct.endTime);
        uint256 newClaimable = IVestedGFly(s.vestedGFly).claimableOfAtTimestamp(
            distribution.rootId,
            intervalSplitStruct.end
        ) -
            IVestedGFly(s.vestedGFly).claimableOfAtTimestamp(distribution.rootId, intervalSplitStruct.startTime) -
            endClaimable;
        //set state of existing interval
        interval.end = intervalSplitStruct.startTime - 1;
        interval.claimable = interval.claimable - (newClaimable + endClaimable);
        s.totalIntervals = s.totalIntervals + 2;
        distribution.totalIntervals += 2;
        uint256 totalIntervals = s.totalIntervals;
        //create middle interval
        s.distributionIntervals[totalIntervals - 1].start = intervalSplitStruct.startTime;
        s.distributionIntervals[totalIntervals - 1].end = intervalSplitStruct.endTime;
        s.distributionIntervals[totalIntervals - 1].claimable = newClaimable;
        //create last interval
        s.distributionIntervals[totalIntervals].start = intervalSplitStruct.endTime + 1;
        s.distributionIntervals[totalIntervals].end = intervalSplitStruct.end;
        s.distributionIntervals[totalIntervals].claimable = endClaimable;
        //add new owner to middle interval.
        _copyOwnersToNewIntervals(
            intervalSplitStruct.next,
            totalIntervals - 1,
            totalIntervals,
            parentVestingPosition.owner,
            intervalSplitStruct.owner,
            intervalSplitStruct.percentageToReservePerInterval
        );
        // insert new intervals in linked list.
        s.distributionIntervalIds[parentVestingPosition.distribution].insertAfter(
            intervalSplitStruct.next,
            totalIntervals - 1
        );
        s.distributionIntervalIds[parentVestingPosition.distribution].insertAfter(totalIntervals - 1, totalIntervals);
        (, uint256 next) = s.distributionIntervalIds[parentVestingPosition.distribution].getNextNode(totalIntervals);
        return next;
    }

    function _splitUpIntervalInRange(
        VestingPosition storage parentVestingPosition,
        IntervalSplitStruct memory intervalSplitStruct
    ) internal returns (uint256) {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        // split up --> interval falls in range
        // No need to splitup, add the new position to the existing interval
        _copyOwnersToNewIntervals(
            intervalSplitStruct.next,
            intervalSplitStruct.next,
            0,
            parentVestingPosition.owner,
            intervalSplitStruct.owner,
            intervalSplitStruct.percentageToReservePerInterval
        );
        (, uint256 next) = s.distributionIntervalIds[parentVestingPosition.distribution].getNextNode(
            intervalSplitStruct.next
        );
        return next;
    }

    function _copyOwnersToNewIntervals(
        uint256 oldIntervalId,
        uint256 newIntervalId1,
        uint256 newIntervalId2,
        address oldOwner,
        address newOwner,
        uint256 percentageOwnership
    ) internal {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        uint256 totalOwners = s.ownersPerDistributionInterval[oldIntervalId].length();
        //iterate over all owners of original interval
        for (uint256 j = 0; j < totalOwners; j++) {
            //When the ownership equals the old owner, we have to modify the ownership percentage and add a new owner
            //for part of the interval
            address intervalOwner = s.ownersPerDistributionInterval[oldIntervalId].at(j);
            if (intervalOwner == oldOwner) {
                IntervalOwnership storage oldOwnership = s.ownershipPerDistributionInterval[oldIntervalId][oldOwner];
                uint256 percentageForNewOwner = (oldOwnership.percentageInWei * percentageOwnership) /
                    OTCVestingStorage.ONE;
                uint256 percentageForOldOwner = oldOwnership.percentageInWei - percentageForNewOwner;
                s.ownershipPerDistributionInterval[newIntervalId1][oldOwner] = IntervalOwnership({
                    owner: oldOwner,
                    percentageInWei: percentageForOldOwner
                });
                s.ownershipPerDistributionInterval[newIntervalId1][newOwner] = IntervalOwnership({
                    owner: newOwner,
                    percentageInWei: percentageForNewOwner
                });
                s.ownersPerDistributionInterval[newIntervalId1].add(newOwner);
                if (oldIntervalId == newIntervalId1) {
                    s.distributionIntervals[newIntervalId1].totalOwners += 1;
                } else {
                    s.ownersPerDistributionInterval[newIntervalId1].add(oldOwner);
                    s.distributionIntervals[newIntervalId1].totalOwners += 2;
                }
                if (newIntervalId2 > 0) {
                    //We have 3 intervals where only the middle one needs to have an ownership change
                    //the last interval can just copy the ownership of the first interval
                    s.ownershipPerDistributionInterval[newIntervalId2][oldOwner] = oldOwnership;
                    s.ownersPerDistributionInterval[newIntervalId2].add(oldOwner);
                    s.distributionIntervals[newIntervalId2].totalOwners += 1;
                }
            } else if (oldIntervalId != newIntervalId1) {
                //if the ownership does not equal the old owner and the old and new interval are not the same
                //we just copy over the ownership as it can stay the same
                IntervalOwnership storage oldOwnership = s.ownershipPerDistributionInterval[oldIntervalId][
                    intervalOwner
                ];
                s.ownershipPerDistributionInterval[newIntervalId1][intervalOwner] = oldOwnership;
                s.ownersPerDistributionInterval[newIntervalId1].add(intervalOwner);
                s.distributionIntervals[newIntervalId1].totalOwners += 1;
            }
        }
    }

    function _claim(uint256 positionId) internal {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        uint256 distributionId = s.vestingPositions[positionId].distribution;
        if (distributionId == 0) revert NonExistingDistribution(positionId);
        Distribution storage distribution = s.distributions[distributionId];

        //claim from vgFLY contract
        uint256 beforeClaim = IGFly(s.gFLY).balanceOf(address(this));
        IVestedGFly(s.vestedGFly).claimGFly(distribution.rootId);
        uint256 totalClaimed = IGFly(s.gFLY).balanceOf(address(this)) - beforeClaim;

        //start at the head of the active intervals
        uint256 next = distribution.distributionIntervalHead;
        //loop till the end of the intervals
        while (next != 0) {
            DistributionInterval storage interval = s.distributionIntervals[next];
            if (block.timestamp < interval.start) {
                // break the loop when we reach an interval that has not yet started
                break;
            } else if (block.timestamp >= interval.end) {
                // we already passed the end ot this interval. Distribute claimable amount and move head to interval
                uint256 toClaim = interval.claimable - interval.claimed;
                _distributeClaim(distributionId, next, toClaim);
                totalClaimed -= toClaim;
                (, next) = s.distributionIntervalIds[distributionId].getNextNode(next);
                distribution.distributionIntervalHead = next;
            } else if (block.timestamp > interval.start) {
                // We are currently within this interval. Distribute claimable amount but don't move head
                uint256 toClaim = totalClaimed;
                _distributeClaim(distributionId, next, toClaim);
                (, next) = s.distributionIntervalIds[distributionId].getNextNode(next);
            }
        }
    }

    function _distributeClaim(uint256 distributionId, uint256 intervalId, uint256 toClaim) internal {
        OTCVestingStorage.Layout storage s = OTCVestingStorage.layout();
        DistributionInterval storage interval = s.distributionIntervals[intervalId];
        uint256 totalDistributed;

        //distribute claimed gFLY to all interval owners based on their ownership percentage
        for (uint j = 0; j < interval.totalOwners; j++) {
            uint256 individualClaim = (toClaim *
                s
                .ownershipPerDistributionInterval[intervalId][s.ownersPerDistributionInterval[intervalId].at(j)]
                    .percentageInWei) / OTCVestingStorage.ONE;
            s.claimableGFlyPerDistribution[distributionId][
                s.ownershipPerDistributionInterval[intervalId][s.ownersPerDistributionInterval[intervalId].at(j)].owner
            ] += individualClaim;
            totalDistributed += individualClaim;
        }

        interval.claimed += toClaim;

        //sanity checks
        if (totalDistributed > toClaim) revert TooMuchDistributed(intervalId, toClaim, totalDistributed);
        if (interval.claimed > interval.claimable)
            revert ClaimedExceedsClaimable(intervalId, interval.claimed, interval.claimable);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library OTCAdminStorage {
    struct Layout {
        bool paused;
        mapping(address => bool) admins;
        mapping(address => bool) pauseGuardians;
        mapping(address => bool) vestingManagers;
        mapping(address => bool) battleflyBots;
        // IMPORTANT: For update append only, do not re-order fields!
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("battlefly.storage.otc.admin");

    /* solhint-disable */
    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;
import { StructuredLinkedList } from "solidity-linked-list/contracts/StructuredLinkedList.sol";
import { EnumerableSet } from "@solidstate/contracts/data/EnumerableSet.sol";

struct VestingPosition {
    address owner;
    uint256 distribution;
    uint256 initialAllocation;
    uint256 claimed;
    bool burnable;
    uint256 burnt;
    uint256 startTime;
}

struct Distribution {
    address owner;
    uint256 rootId;
    uint256 employmentTimestamp;
    uint256 initialAllocation;
    uint256 distributionIntervalStart;
    uint256 distributionIntervalHead;
    uint256 totalIntervals;
}

struct DistributionInterval {
    uint256 start;
    uint256 end;
    uint256 claimed;
    uint256 claimable;
    uint256 totalOwners;
}

struct IntervalOwnership {
    address owner;
    uint256 percentageInWei;
}

library OTCVestingStorage {
    using StructuredLinkedList for StructuredLinkedList.List;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Layout {
        uint256 totalVestingPositions;
        uint256 totalDistributions;
        uint256 totalIntervals;
        address vestedGFly;
        address gFLY;
        address treasury;
        mapping(uint256 => VestingPosition) vestingPositions;
        mapping(uint256 => Distribution) distributions;
        mapping(uint256 => DistributionInterval) distributionIntervals;
        mapping(uint256 => StructuredLinkedList.List) distributionIntervalIds;
        mapping(address => EnumerableSet.UintSet) allUserVestingPositions;
        mapping(uint256 => mapping(address => uint256)) claimableGFlyPerDistribution;
        mapping(uint256 => EnumerableSet.AddressSet) ownersPerDistributionInterval;
        mapping(uint256 => mapping(address => IntervalOwnership)) ownershipPerDistributionInterval;
        // IMPORTANT: For update append only, do not re-order fields!
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("battlefly.storage.otc.vesting");

    //constants
    uint256 public constant MONTH = 2628000;
    uint256 public constant ONE = 1e18;

    /* solhint-disable */
    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../storage/OTCAdminStorage.sol";

abstract contract WithCommonModifiers {
    error IllegalAddress(address illegalAddress);

    modifier nonZeroAddress(address toCheck) {
        if (toCheck == address(0)) revert IllegalAddress(toCheck);
        _;
    }
}

abstract contract WithPausableModifiers {
    error Paused();
    error NotPaused();

    modifier whenNotPaused() {
        if (OTCAdminStorage.layout().paused) revert Paused();
        _;
    }

    modifier whenPaused() {
        if (!OTCAdminStorage.layout().paused) revert NotPaused();
        _;
    }
}

abstract contract WithACLModifiers {
    error AccessDenied();

    modifier onlyAdmin() {
        if (!OTCAdminStorage.layout().admins[msg.sender]) revert AccessDenied();
        _;
    }

    modifier onlyPauseGuardians() {
        if (!OTCAdminStorage.layout().pauseGuardians[msg.sender]) revert AccessDenied();
        _;
    }

    modifier onlyVestingManagers() {
        if (!OTCAdminStorage.layout().vestingManagers[msg.sender]) revert AccessDenied();
        _;
    }

    modifier onlyBattleflyBots() {
        if (!OTCAdminStorage.layout().battleflyBots[msg.sender]) revert AccessDenied();
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IStructureInterface {
    function getValue(uint256 _id) external view returns (uint256);
}

/**
 * @title StructuredLinkedList
 * @author Vittorio Minacori (https://github.com/vittominacori)
 * @dev An utility library for using sorted linked list data structures in your Solidity project.
 */
library StructuredLinkedList {
    uint256 private constant _NULL = 0;
    uint256 private constant _HEAD = 0;

    bool private constant _PREV = false;
    bool private constant _NEXT = true;

    struct List {
        uint256 size;
        mapping(uint256 => mapping(bool => uint256)) list;
    }

    /**
     * @dev Checks if the list exists
     * @param self stored linked list from contract
     * @return bool true if list exists, false otherwise
     */
    function listExists(List storage self) internal view returns (bool) {
        // if the head nodes previous or next pointers both point to itself, then there are no items in the list
        if (self.list[_HEAD][_PREV] != _HEAD || self.list[_HEAD][_NEXT] != _HEAD) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Checks if the node exists
     * @param self stored linked list from contract
     * @param _node a node to search for
     * @return bool true if node exists, false otherwise
     */
    function nodeExists(List storage self, uint256 _node) internal view returns (bool) {
        if (self.list[_node][_PREV] == _HEAD && self.list[_node][_NEXT] == _HEAD) {
            if (self.list[_HEAD][_NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Returns the number of elements in the list
     * @param self stored linked list from contract
     * @return uint256
     */
    function sizeOf(List storage self) internal view returns (uint256) {
        return self.size;
    }

    /**
     * @dev Returns the links of a node as a tuple
     * @param self stored linked list from contract
     * @param _node id of the node to get
     * @return bool, uint256, uint256 true if node exists or false otherwise, previous node, next node
     */
    function getNode(List storage self, uint256 _node) internal view returns (bool, uint256, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0, 0);
        } else {
            return (true, self.list[_node][_PREV], self.list[_node][_NEXT]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @param _direction direction to step in
     * @return bool, uint256 true if node exists or false otherwise, node in _direction
     */
    function getAdjacent(List storage self, uint256 _node, bool _direction) internal view returns (bool, uint256) {
        if (!nodeExists(self, _node)) {
            return (false, 0);
        } else {
            return (true, self.list[_node][_direction]);
        }
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_NEXT`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, next node
     */
    function getNextNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _NEXT);
    }

    /**
     * @dev Returns the link of a node `_node` in direction `_PREV`.
     * @param self stored linked list from contract
     * @param _node id of the node to step from
     * @return bool, uint256 true if node exists or false otherwise, previous node
     */
    function getPreviousNode(List storage self, uint256 _node) internal view returns (bool, uint256) {
        return getAdjacent(self, _node, _PREV);
    }

    /**
     * @dev Can be used before `insert` to build an ordered list.
     * @dev Get the node and then `insertBefore` or `insertAfter` basing on your list order.
     * @dev If you want to order basing on other than `structure.getValue()` override this function
     * @param self stored linked list from contract
     * @param _structure the structure instance
     * @param _value value to seek
     * @return uint256 next node with a value less than _value
     */
    function getSortedSpot(List storage self, address _structure, uint256 _value) internal view returns (uint256) {
        if (sizeOf(self) == 0) {
            return 0;
        }

        uint256 next;
        (, next) = getAdjacent(self, _HEAD, _NEXT);
        while ((next != 0) && ((_value < IStructureInterface(_structure).getValue(next)) != _NEXT)) {
            next = self.list[next][_NEXT];
        }
        return next;
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_NEXT`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function insertAfter(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _NEXT);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_PREV`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @return bool true if success, false otherwise
     */
    function insertBefore(List storage self, uint256 _node, uint256 _new) internal returns (bool) {
        return _insert(self, _node, _new, _PREV);
    }

    /**
     * @dev Removes an entry from the linked list
     * @param self stored linked list from contract
     * @param _node node to remove from the list
     * @return uint256 the removed node
     */
    function remove(List storage self, uint256 _node) internal returns (uint256) {
        if ((_node == _NULL) || (!nodeExists(self, _node))) {
            return 0;
        }
        _createLink(self, self.list[_node][_PREV], self.list[_node][_NEXT], _NEXT);
        delete self.list[_node][_PREV];
        delete self.list[_node][_NEXT];

        self.size -= 1; // NOT: SafeMath library should be used here to decrement.

        return _node;
    }

    /**
     * @dev Pushes an entry to the head of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @return bool true if success, false otherwise
     */
    function pushFront(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _NEXT);
    }

    /**
     * @dev Pushes an entry to the tail of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the tail
     * @return bool true if success, false otherwise
     */
    function pushBack(List storage self, uint256 _node) internal returns (bool) {
        return _push(self, _node, _PREV);
    }

    /**
     * @dev Pops the first entry from the head of the linked list
     * @param self stored linked list from contract
     * @return uint256 the removed node
     */
    function popFront(List storage self) internal returns (uint256) {
        return _pop(self, _NEXT);
    }

    /**
     * @dev Pops the first entry from the tail of the linked list
     * @param self stored linked list from contract
     * @return uint256 the removed node
     */
    function popBack(List storage self) internal returns (uint256) {
        return _pop(self, _PREV);
    }

    /**
     * @dev Pushes an entry to the head of the linked list
     * @param self stored linked list from contract
     * @param _node new entry to push to the head
     * @param _direction push to the head (_NEXT) or tail (_PREV)
     * @return bool true if success, false otherwise
     */
    function _push(List storage self, uint256 _node, bool _direction) private returns (bool) {
        return _insert(self, _HEAD, _node, _direction);
    }

    /**
     * @dev Pops the first entry from the linked list
     * @param self stored linked list from contract
     * @param _direction pop from the head (_NEXT) or the tail (_PREV)
     * @return uint256 the removed node
     */
    function _pop(List storage self, bool _direction) private returns (uint256) {
        uint256 adj;
        (, adj) = getAdjacent(self, _HEAD, _direction);
        return remove(self, adj);
    }

    /**
     * @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _new  new node to insert
     * @param _direction direction to insert node in
     * @return bool true if success, false otherwise
     */
    function _insert(List storage self, uint256 _node, uint256 _new, bool _direction) private returns (bool) {
        if (!nodeExists(self, _new) && nodeExists(self, _node)) {
            uint256 c = self.list[_node][_direction];
            _createLink(self, _node, _new, _direction);
            _createLink(self, _new, c, _direction);

            self.size += 1; // NOT: SafeMath library should be used here to increment.

            return true;
        }

        return false;
    }

    /**
     * @dev Creates a bidirectional link between two nodes on direction `_direction`
     * @param self stored linked list from contract
     * @param _node existing node
     * @param _link node to link to in the _direction
     * @param _direction direction to insert node in
     */
    function _createLink(List storage self, uint256 _node, uint256 _link, bool _direction) private {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }
}