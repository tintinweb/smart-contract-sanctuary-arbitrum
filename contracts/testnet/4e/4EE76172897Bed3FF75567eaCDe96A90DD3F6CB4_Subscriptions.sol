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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/utils/math/SignedMath.sol';

/// @title Graph subscriptions contract.
/// @notice This contract is designed to allow users of the Graph Protocol to pay gateways for their services with limited risk of losing tokens.
/// It also allows registering authorized signers with the gateway that can create subscription tickets on behalf of the user.
/// This contract makes no assumptions about how the subscription rate is interpreted by the
/// gateway.
contract Subscriptions is Ownable {
    // -- State --
    /// @notice A Subscription represents a lockup of `rate` tokens per second for the half-open
    /// timestamp range [start, end).
    struct Subscription {
        uint64 start;
        uint64 end;
        uint128 rate;
    }
    /// @notice An epoch defines the end of a span of blocks, the length of which is defined by
    /// `epochSeconds`. These exist to facilitate a relatively efficient `collect` implementation
    /// while allowing users to recover unlocked tokens at a block granularity.
    struct Epoch {
        int128 delta;
        int128 extra;
    }

    /// @notice ERC-20 token held by this contract.
    IERC20 public immutable token;
    /// @notice Duration of each epoch in seconds.
    uint64 public immutable epochSeconds;
    /// @notice Mapping of users to their most recent subscription.
    mapping(address => Subscription) public subscriptions;
    /// @notice Mapping of epoch numbers to their payloads.
    mapping(uint256 => Epoch) public epochs;
    /// @notice Epoch cursor position.
    uint256 public uncollectedEpoch;
    /// @notice Epoch cursor value.
    int128 public collectPerEpoch;
    /// @notice Mapping of user to set of authorized signers.
    mapping(address => mapping(address => bool)) public authorizedSigners;
    /// @notice Mapping of user to pending subscription.
    mapping(address => Subscription) public pendingSubscriptions;

    // -- Events --
    event Init(address token, uint64 epochSeconds);
    event Subscribe(
        address indexed user,
        uint256 indexed epoch,
        uint64 start,
        uint64 end,
        uint128 rate
    );
    event Unsubscribe(address indexed user, uint256 indexed epoch);
    event PendingSubscriptionCreated(
        address indexed user,
        uint256 indexed epoch,
        uint64 start,
        uint64 end,
        uint128 rate
    );
    event AuthorizedSignerAdded(
        address indexed subscriptionOwner,
        address indexed authorizedSigner
    );
    event AuthorizedSignerRemoved(
        address indexed subscriptionOwner,
        address indexed authorizedSigner
    );
    event TokensCollected(
        address indexed owner,
        uint256 amount,
        uint256 indexed startEpoch,
        uint256 indexed endEpoch
    );

    // -- Functions --
    /// @param _token The ERC-20 token held by this contract
    /// @param _epochSeconds The Duration of each epoch in seconds.
    /// @dev Contract ownership must be transfered to the gateway after deployment.
    constructor(address _token, uint64 _epochSeconds) {
        token = IERC20(_token);
        epochSeconds = _epochSeconds;
        uncollectedEpoch = block.timestamp / _epochSeconds;

        emit Init(_token, _epochSeconds);
    }

    /// @notice Create a subscription for the sender.
    /// Will override an active subscription if one exists.
    /// @param start Start timestamp for the new subscription.
    /// @param end End timestamp for the new subscription.
    /// @param rate Rate for the new subscription.
    function subscribe(uint64 start, uint64 end, uint128 rate) public {
        _subscribe(msg.sender, start, end, rate);
    }

    /// @notice Remove the sender's subscription. Unlocked tokens will be transfered to the sender.
    function unsubscribe() public {
        _unsubscribe(msg.sender);
    }

    /// @notice Collect a subset of the locked tokens held by this contract.
    function collect() public onlyOwner {
        collect(0);
    }

    /// @notice Collect a subset of the locked tokens held by this contract.
    /// @param _offset epochs before the current epoch to end collection. This should be zero unless
    /// this call would otherwise be expected to run out of gas.
    function collect(uint256 _offset) public onlyOwner {
        address owner = owner();
        uint256 startEpoch = uncollectedEpoch;
        uint256 endEpoch = currentEpoch() - _offset;

        int128 total = 0;
        uint256 _uncollectedEpoch = uncollectedEpoch;
        while (_uncollectedEpoch < endEpoch) {
            Epoch storage epoch = epochs[_uncollectedEpoch];
            collectPerEpoch += epoch.delta;
            total += collectPerEpoch + epoch.extra;
            delete epochs[_uncollectedEpoch];

            unchecked {
                ++_uncollectedEpoch;
            }
        }
        uncollectedEpoch = _uncollectedEpoch;

        // This should never happen but we need to check due to the int > uint cast below
        require(total >= 0, 'total must be non-negative');
        uint256 amount = uint128(total);

        bool success = token.transfer(owner, amount);
        require(success, 'IERC20 token transfer failed');

        emit TokensCollected(owner, amount, startEpoch, endEpoch);
    }

    /// @notice Creates a subscription template without requiring funds. Expected to be used with
    /// `fulfil`.
    /// @param start Start timestamp for the pending subscription.
    /// @param end End timestamp for the pending subscription.
    /// @param rate Rate for the pending subscription.
    function setPendingSubscription(
        uint64 start,
        uint64 end,
        uint128 rate
    ) public {
        address user = msg.sender;
        pendingSubscriptions[user] = Subscription({
            start: start,
            end: end,
            rate: rate
        });
        uint256 epoch = currentEpoch();
        emit PendingSubscriptionCreated(user, epoch, start, end, rate);
    }

    /// @notice Fulfil method for the payment fulfilment service
    /// @param _to Owner of the new subscription.
    /// @notice Equivalent to calling `subscribe` with the previous `setPendingSubscription`
    /// arguments for the same user.
    function fulfil(address _to, uint256 _amount) public {
        Subscription storage pendingSub = pendingSubscriptions[_to];
        require(
            pendingSub.start != 0 && pendingSub.end != 0,
            'No pending subscription'
        );

        uint64 subStart = uint64(Math.max(pendingSub.start, block.timestamp));
        require(subStart < pendingSub.end, 'Pending subscription has expired');
        uint256 subAmount = pendingSub.rate * (pendingSub.end - subStart);
        require(
            _amount >= subAmount,
            'Insufficient funds to create subscription'
        );

        // Create the subscription using the pending subscription details
        _subscribe(_to, pendingSub.start, pendingSub.end, pendingSub.rate);
        delete pendingSubscriptions[_to];

        // Send any extra tokens back to the user
        uint256 extra = _amount - subAmount;

        if (extra > 0) {
            bool pullSuccess = token.transferFrom(
                msg.sender,
                address(this),
                extra
            );
            require(pullSuccess, 'IERC20 token transfer failed');

            bool transferSuccess = token.transfer(_to, extra);
            require(transferSuccess, 'IERC20 token transfer failed');
        }
    }

    /// @param _signer Address to be authorized to sign messages on the sender's behalf.
    function addAuthorizedSigner(address _signer) public {
        address user = msg.sender;
        require(user != _signer, 'user is always an authorized signer');
        authorizedSigners[user][_signer] = true;

        emit AuthorizedSignerAdded(user, _signer);
    }

    /// @param _signer Address to become unauthorized to sign messages on the sender's behalf.
    function removeAuthorizedSigner(address _signer) public {
        address user = msg.sender;
        require(user != _signer, 'user is always an authorized signer');
        delete authorizedSigners[user][_signer];

        emit AuthorizedSignerRemoved(user, _signer);
    }

    /// @param _user Subscription owner.
    /// @param _signer Address authorized to sign messages on the owners behalf.
    /// @return isAuthorized True if the given signer is set as an authorized signer for the given
    /// user, false otherwise.
    function checkAuthorizedSigner(
        address _user,
        address _signer
    ) public view returns (bool) {
        if (_user == _signer) {
            return true;
        }
        return authorizedSigners[_user][_signer];
    }

    /// @param _timestamp Block timestamp, in seconds.
    /// @return epoch Epoch number, rouded up to the next epoch Boundary.
    function timestampToEpoch(
        uint256 _timestamp
    ) public view returns (uint256) {
        return (_timestamp / epochSeconds) + 1;
    }

    /// @return epoch Current epoch number, rouded up to the next epoch Boundary.
    function currentEpoch() public view returns (uint256) {
        return timestampToEpoch(block.timestamp);
    }

    /// @dev Defined as `rate * max(0, min(now, end) - start)`.
    /// @param _subStart Start timestamp of the active subscription.
    /// @param _subEnd End timestamp of the active subscription.
    /// @param _subRate Active subscription rate.
    /// @return lockedTokens Amount of locked tokens for the given subscription, which are
    /// collectable by the contract owner and are not recoverable by the user.
    function locked(
        uint64 _subStart,
        uint64 _subEnd,
        uint128 _subRate
    ) public view returns (uint128) {
        uint256 len = uint256(
            SignedMath.max(
                0,
                int256(Math.min(block.timestamp, _subEnd)) - int64(_subStart)
            )
        );
        return _subRate * uint128(len);
    }

    /// @dev Defined as `rate * max(0, min(now, end) - start)`.
    /// @param _user Address of the active subscription owner.
    /// @return lockedTokens Amount of locked tokens for the given subscription, which are
    /// collectable by the contract owner and are not recoverable by the user.
    function locked(address _user) public view returns (uint128) {
        Subscription storage sub = subscriptions[_user];
        return locked(sub.start, sub.end, sub.rate);
    }

    /// @dev Defined as `rate * max(0, end - max(now, start))`.
    /// @param _subStart Start timestamp of the active subscription.
    /// @param _subEnd End timestamp of the active subscription.
    /// @param _subRate Active subscription rate.
    /// @return unlockedTokens Amount of unlocked tokens, which are recoverable by the user, and are
    /// not collectable by the contract owner.
    function unlocked(
        uint64 _subStart,
        uint64 _subEnd,
        uint128 _subRate
    ) public view returns (uint128) {
        uint256 len = uint256(
            SignedMath.max(
                0,
                int256(int64(_subEnd)) -
                    int256(Math.max(block.timestamp, _subStart))
            )
        );
        return _subRate * uint128(len);
    }

    /// @dev Defined as `rate * max(0, end - max(now, start))`.
    /// @param _user Address of the active subscription owner.
    /// @return unlockedTokens Amount of unlocked tokens, which are recoverable by the user, and are
    /// not collectable by the contract owner.
    function unlocked(address _user) public view returns (uint128) {
        Subscription storage sub = subscriptions[_user];
        return unlocked(sub.start, sub.end, sub.rate);
    }

    /// @notice Create a subscription for a user
    /// Will override an active subscription if one exists.
    /// @param user Owner for the new subscription.
    /// @param start Start timestamp for the new subscription.
    /// @param end End timestamp for the new subscription.
    /// @param rate Rate for the new subscription.
    function _subscribe(
        address user,
        uint64 start,
        uint64 end,
        uint128 rate
    ) private {
        require(user != address(0), 'user is null');
        require(user != address(this), 'invalid user');
        start = uint64(Math.max(start, block.timestamp));
        require(start < end, 'start must be less than end');

        // This avoids unexpected behavior from truncation, especially in `locked` and `unlocked`.
        require(end <= uint64(type(int64).max), 'end too large');

        // Overwrite an active subscription if there is one
        if (subscriptions[user].end > block.timestamp) {
            // Note: This could potentially lead to a reentrancy vulnerability, since `_unsubscribe`
            // may call `token.transfer` here prior to contract state changes below. Consider the
            // following scenario:
            //   - The user has an active subscription, and `_unsubscribe` is called here.
            //   - Tokens are transfered to the user (for a refund), giving an opportunity for
            //     reentrancy.
            //   - This reentrancy occurs before `subscriptions[user]` is modified, and the new
            //     epoch state gets updated.
            // However, this would cause the attacker to lose money, as their old subscription data
            // is overwritten with the new, with no chance to retrieve the funds for the old.
            _unsubscribe(user);
        }

        subscriptions[user] = Subscription({
            start: start,
            end: end,
            rate: rate
        });
        _setEpochs(start, end, int128(rate));

        uint256 subTotal = rate * (end - start);
        bool success = token.transferFrom(msg.sender, address(this), subTotal);
        require(success, 'IERC20 token transfer failed');

        uint256 epoch = currentEpoch();
        emit Subscribe(user, epoch, start, end, rate);
    }

    /// @notice Remove the user's subscription. Unlocked tokens will be transfered to the user.
    /// @param user Owner of the subscription to be removed.
    function _unsubscribe(address user) private {
        Subscription storage sub = subscriptions[user];
        require(sub.start != 0, 'no active subscription');

        uint64 _now = uint64(block.timestamp);
        require(sub.end > _now, 'Subscription has expired');

        uint128 tokenAmount = unlocked(sub.start, sub.end, sub.rate);

        _setEpochs(sub.start, sub.end, -int128(sub.rate));
        if (sub.start <= _now) {
            _setEpochs(sub.start, _now, int128(sub.rate));
            subscriptions[user].end = _now;
        } else {
            delete subscriptions[user];
        }

        bool success = token.transfer(user, tokenAmount);
        require(success, 'IERC20 token transfer failed');

        uint256 epoch = currentEpoch();
        emit Unsubscribe(user, epoch);
    }

    function _setEpochs(uint64 start, uint64 end, int128 rate) private {
        /*
        Example subscription layout using
            epochSeconds = 6
            sub = {start: 2, end: 9, rate: 1}

        blocks: |0 |1 |2 |3 |4 |5 |6 |7 |8 |9 |10|11|
                                      ^ currentBlock
                       ^start               ^end
        epochs: |                1|                2|
                               e1^               e2^
        */

        uint256 e = currentEpoch();
        uint256 e1 = timestampToEpoch(start);
        if (e <= e1) {
            epochs[e1].delta += rate * int64(epochSeconds);
            epochs[e1].extra -=
                rate *
                int64(start - (uint64(e1 - 1) * epochSeconds));
        }
        uint256 e2 = timestampToEpoch(end);
        if (e <= e2) {
            epochs[e2].delta -= rate * int64(epochSeconds);
            epochs[e2].extra +=
                rate *
                int64(end - (uint64(e2 - 1) * epochSeconds));
        }
    }
}