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
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Pool is Ownable {
    string private _name;
    address private _token;
    mapping(address => bool) private operators;
    uint256 private _outBalance;

    constructor(string memory name_, address token_) {
        _name = name_;
        _token = token_;
    }

    modifier onlyOperator() {
        require(operators[_msgSender()], "caller is not operator");
        _;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function token() public view returns (address) {
        return _token;
    }

    function outBalance() public view returns (uint256) {
        return _outBalance;
    }

    function emergencyWithdraw(uint256 amount) external onlyOwner {
        IERC20(_token).transfer(owner(), amount);
    }

    function withdraw(address receiver, uint256 amount) external onlyOperator {
        _outBalance += amount;
        IERC20(_token).transfer(receiver, amount);
    }

    function setOperator(address operator, bool state) external onlyOwner {
        operators[operator] = state;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {Pool} from "./Pool.sol";

struct Balances {
    uint256 pendingOut;
    uint256 pending;
    uint256 prizeOut;
    uint256 prize;
    uint256 groupOut;
    uint256 group;
    uint256 reserve;
    uint256 lastUpdated;
}

struct UserInfo {
    uint256 deposit;
    uint256 consenseReward;
    uint256 lastDeposit;
    uint16 risk;
}

struct DappInfo {
    uint256 deposit;
    uint256 lastDeposit;
    uint256 pendingOutBalance;
    uint256 pendingBalance;
    uint256 prizeOutBalance;
    uint256 prizeBalance;
    uint256 groupOutBalance;
    uint256 groupBalance;
    uint256 reserveBalance;
    address referrer;
    uint256 groupCounts;
    uint256 validGroupCounts;
    bool isRisk;
}

struct PoolInfo {
    uint256[2] nodePool;
    uint256[2] contractPool;
    uint256[2] consensePool;
    uint256[2] liquidPool;
}

contract Reserve is Ownable {
    uint256 public constant MIN_AMOUNT = 100 * 10**18;

    IERC20 private _token;

    Pool private _nodePool; // 10
    Pool private _contractPool; // 5
    Pool private _consensePool; // 5
    Pool private _liquidPool; // 80

    mapping (address => bool) private _whitelist;

    mapping (address => Balances) private _balances;

    mapping (address => UserInfo) private _userInfo;

    mapping (address => bool) private _userJoined;

    mapping (address => address) private _referrer;
    mapping (address => uint256) private _groupCounts;
    mapping (address => uint256) private _validGroupCounts;

    uint256 _consenseReward;
    uint16 _risk;

    constructor(IERC20 token_, Pool nodePool_, Pool contractPool_, Pool consensePool_, Pool liquidPool_) {
        _token = token_;
        _nodePool = nodePool_;
        _contractPool = contractPool_;
        _consensePool = consensePool_;
        _liquidPool = liquidPool_;
    }

    function dappInfo(address account) view external returns(DappInfo memory) {
        Balances memory balances = _balances[account];
        UserInfo memory userInfo = _userInfo[account];

        if (userInfo.deposit > 0) {
            uint256 liquidBalance = _token.balanceOf(address(_liquidPool));
            uint256 liquidOutBalance = _liquidPool.outBalance();

            uint256 pending = (userInfo.deposit * 15 / 1000) * (block.timestamp - balances.lastUpdated) / (1 days) * liquidBalance / (liquidBalance + liquidOutBalance);
            uint256 prize = _consenseReward - userInfo.consenseReward;

            uint256 free = balances.pending + balances.group + balances.prize;
            uint256 out = balances.pendingOut + balances.groupOut + balances.prizeOut;

            if (userInfo.risk < _risk && free + pending + prize >= userInfo.deposit) {
                if (userInfo.deposit > out) {
                    balances.reserve = userInfo.deposit - out;
                } else {
                    balances.reserve = 0;
                    balances.group = balances.groupOut;
                    balances.pending = balances.pendingOut;
                    balances.prize = balances.prizeOut;
                }
            }

            if ( pending > balances.reserve) {
                balances.pending += balances.reserve;
                balances.reserve = 0;
            } else {
                balances.pending += pending;
                balances.reserve -= pending;
            }

            if (prize > balances.reserve) {
                balances.prize += balances.reserve;
                balances.reserve = 0;
            } else {
                balances.prize += prize;
                balances.reserve -= prize;
            }
        }

        DappInfo memory info = DappInfo({
            deposit: userInfo.deposit,
            lastDeposit: userInfo.lastDeposit,
            pendingOutBalance: balances.pendingOut,
            pendingBalance: balances.pending,
            prizeOutBalance: balances.prizeOut,
            prizeBalance: balances.prize,
            groupOutBalance: balances.groupOut,
            groupBalance: balances.group,
            reserveBalance: balances.reserve,
            referrer: _referrer[account],
            groupCounts: _groupCounts[account],
            validGroupCounts: _validGroupCounts[account],
            isRisk: userInfo.risk < _risk
        });

        return info;
    }

    function poolInfo() view external returns(PoolInfo memory) {
        PoolInfo memory info = PoolInfo({
            nodePool: [_nodePool.outBalance(), _token.balanceOf(address(_nodePool))],
            contractPool: [_contractPool.outBalance(), _token.balanceOf(address(_contractPool))],
            consensePool: [_consensePool.outBalance(), _token.balanceOf(address(_consensePool))],
            liquidPool: [_liquidPool.outBalance(), _token.balanceOf(address(_liquidPool))]
        });

        return info;
    }

    function join(address referrer_) external {
        address account = _msgSender();

        require(_referrer[account] == address(0), "already has referrer");
        require(referrer_ != account, "not your self");
        require(_whitelist[referrer_] || _userInfo[referrer_].deposit > 0, "referrer not available");
        require(account.code.length + referrer_.code.length == 0, "stop! no contract");
        _referrer[account] = referrer_;

        _updateGroup(account, 8);
    }

    function deposit(uint256 amount) external {
        address account = _msgSender();

        require(amount >= MIN_AMOUNT, "amount less MIN_AMOUNT");
        require(amount >= _userInfo[account].lastDeposit * 11 / 10, "amount not available");
        require(_whitelist[account] || _referrer[account] != address(0), "please set referrer");
        require(msg.sender.code.length == 0, "no contract!");

        if (_validGroupCounts[account] < 30 || _userInfo[account].deposit < 5000 * 10**18) {
            _userInfo[account].consenseReward = _consenseReward;
        }
        _updateBalance(account);

        _token.transferFrom(account, address(_nodePool), amount * 10 / 100);
        _token.transferFrom(account, address(_contractPool), amount * 5 / 100);
        _token.transferFrom(account, address(_consensePool), amount * 5 / 100);
        _token.transferFrom(account, address(_liquidPool), amount * 80 / 100);
        _userInfo[account].deposit += amount;
        _userInfo[account].lastDeposit = amount;
        _userInfo[account].risk = _risk;
        _balances[account].reserve += amount * 15 / 10;
        _balances[account].lastUpdated = block.timestamp;

        if (!_userJoined[account]) {
            _updateValidGroup(account, 8);
        }

        _userJoined[account] = true;
        _userInfo[account].consenseReward = _consenseReward;
    }

    function withdraw() external {
        address account = _msgSender();

        require(_userInfo[account].deposit > 0, "not deposit");
        require(msg.sender.code.length == 0, "not contract!" );

        if (_validGroupCounts[account] < 30 || _userInfo[account].deposit < 5000 * 10**18) {
            _userInfo[account].consenseReward = _consenseReward;
        }
        _updateBalance(account);

        uint256 amount = _balances[account].pending - _balances[account].pendingOut + _balances[account].group - _balances[account].groupOut;

        if (amount > 0) {
            _liquidPool.withdraw(account, amount);
            _balances[account].groupOut = _balances[account].group;
            _balances[account].pendingOut = _balances[account].pending;
            _updateReferrerBalance(account, amount, 8);
        }

        if (_balances[account].prize - _balances[account].prizeOut > 0) {
            _consensePool.withdraw(account, _balances[account].prize - _balances[account].prizeOut);
            _balances[account].prizeOut = _balances[account].prize;
        }

        _userInfo[account].consenseReward = _consenseReward;

        // check out
        if (_balances[msg.sender].reserve < 10) {
            delete _userInfo[msg.sender];
            delete _balances[msg.sender];
        }
    }

    function addReward(uint256 amount) external onlyOwner {
        _consenseReward += amount;
    }

    function addRisk() external onlyOwner {
        _risk++;
    }

    function addWhitelist(address[] memory list) external onlyOwner {
        for (uint i = 0; i < list.length; i++) {
            _whitelist[list[i]] = true;
        }
    }

    function removeWhitelist(address[] memory list) external onlyOwner {
        for (uint i = 0; i < list.length; i++) {
            _whitelist[list[i]] = false;
        }
    }

    function _updateBalance(address account) internal {
        if (_userInfo[account].deposit == 0) return;

        Balances storage balances = _balances[account];
        UserInfo storage userInfo = _userInfo[account];

        uint256 liquidBalance = _token.balanceOf(address(_liquidPool));
        uint256 liquidOutBalance = _liquidPool.outBalance();

        uint256 pending = (userInfo.deposit * 15 / 1000) * (block.timestamp - balances.lastUpdated) / (1 days) * liquidBalance / (liquidBalance + liquidOutBalance);
        uint256 prize = _consenseReward - userInfo.consenseReward;

        uint256 free = balances.pending + balances.group + balances.prize;
        uint256 out = balances.pendingOut + balances.groupOut + balances.prizeOut;

        if (userInfo.risk < _risk && free + pending + prize >= userInfo.deposit) {
            if (userInfo.deposit > out) {
                balances.reserve = userInfo.deposit - out;
            } else {
                balances.reserve = 0;
                balances.group = balances.groupOut;
                balances.pending = balances.pendingOut;
                balances.prize = balances.prizeOut;
            }
        }

        if (pending > balances.reserve) {
            balances.pending += balances.reserve;
            balances.reserve = 0;
        } else {
            balances.pending += pending;
            balances.reserve -= pending;
        }

        if (prize > balances.reserve) {
            balances.prize += balances.reserve;
            balances.reserve = 0;
        } else {
            balances.prize += prize;
            balances.reserve -= prize;
        }

        balances.lastUpdated = block.timestamp;
    }

    function _updateReferrerBalance(address account, uint256 amount, uint8 deep) internal {
        if (deep == 0) return;

        address ref = _referrer[account];

        if (ref == address(0)) return;

        uint256 rewards;
        if (deep == 8) {
            rewards = amount;
        } else if (deep == 7) {
            rewards = amount / 2;
        } else if (deep >= 4) {
            rewards = amount / 5;
        } else {
            rewards = amount / 10;
        }

        if (rewards > _balances[ref].reserve) {
            _balances[ref].group += _balances[ref].reserve;
            _balances[ref].reserve = 0;
        } else {
            _balances[ref].group += rewards;
            _balances[ref].reserve -= rewards;
        }
        _updateReferrerBalance(ref, amount, deep - 1);
    }

    function _updateGroup(address account, uint8 deep) internal {
        if (deep == 0) return;

        address ref = _referrer[account];

        if (ref == address(0)) return;

        _groupCounts[ref] += 1;

        _updateGroup(ref, deep - 1);
    }

    function _updateValidGroup(address account, uint8 deep) internal {
        if (deep == 0) return;

        address ref = _referrer[account];

        if (ref == address(0)) return;

        _validGroupCounts[ref] += 1;

        _updateValidGroup(ref, deep - 1);
    }
}