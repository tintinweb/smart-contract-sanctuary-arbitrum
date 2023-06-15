//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NutPower is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    uint256 constant public WEEK = 604800;
    uint256 constant public PERIOD_COUNT = 7;

    enum Period {
        W1,
        W2,
        W4,
        W8,
        W16,
        W32,
        W64
    }

    struct RedeemRequest {
        uint256 nutAmount;
        uint256 claimed;
        uint256 startTime;
        uint256 endTime;
    }

    struct RequestsOfPeriod {
        uint256 index;
        RedeemRequest[] queue;
    }

    struct PowerInfo {
        // Amount of NP can be power down
        uint256 free;
        // Amount of NP has been locked, e.g. staked
        uint256 locked;
    }

    address public nut;
    // total locked nut
    uint256 public totalLockedNut;
    // total NP
    uint256 public totalSupply;

    mapping (address => PowerInfo) private powers;
    mapping (address => mapping (Period => uint256)) private depositInfos;
    uint256[7] private multipier = [1, 2, 4, 8, 16, 32, 64];
    mapping (address => mapping (Period => RequestsOfPeriod)) private requests;
    mapping (address => bool) public whitelists;

    event AdminChangeNut(address indexed oldNut, address indexed newNut);
    event AdminSetWhiteList(address indexed who, bool tag);

    event PowerUp(address indexed who, Period period, uint256 amount);
    event PowerDown(address indexed who, Period period, uint256 amount);
    event Upgrade(address indexed who, Period src, Period dest, uint256 amount);
    event Redeemd(address indexed who, uint256 amount);

    modifier onlyWhitelist {
        require(whitelists[msg.sender], "Address is not whitelisted");
        _;
    }

    constructor(address _nut) {
        require(_nut != address(0), "Invalid nut address");
        nut = _nut;
    }

    function adminSetNut(address _nut) external onlyOwner {
        require(_nut != address(0), "Invalid nut address");
        address oldNut = nut;
        nut = _nut;
        emit AdminChangeNut(oldNut, nut);
    }

    function adminSetWhitelist(address _who, bool _tag) external onlyOwner {
        require(_who != address(0), "Invalide address");
        whitelists[_who] = _tag;
        emit AdminSetWhiteList(_who, _tag);
    }

    function powerUp(uint256 _nutAmount, Period _period) external nonReentrant {
        require(_nutAmount > 0, "Invalid lock amount");
        IERC20(nut).transferFrom(msg.sender, address(this), _nutAmount);
        uint256 issuedNp = _nutAmount.mul(multipier[uint256(_period)]);
        // NUT is locked
        totalLockedNut = totalLockedNut.add(_nutAmount);
        totalSupply = totalSupply.add(issuedNp);
        powers[msg.sender].free = powers[msg.sender].free.add(issuedNp);
        depositInfos[msg.sender][_period] = depositInfos[msg.sender][_period].add(_nutAmount);

        emit PowerUp(msg.sender, _period, _nutAmount);
    }

    function powerDown(uint256 _npAmount, Period _period) external nonReentrant {
        uint256 downNut = _npAmount.div(multipier[uint256(_period)]);
        require(_npAmount > 0, "Invalid unlock NP");
        require(depositInfos[msg.sender][_period] >= downNut, "Insufficient free NUT");
        require(powers[msg.sender].free >= _npAmount, "Insufficient free NP");

        powers[msg.sender].free = powers[msg.sender].free.sub(_npAmount);
        depositInfos[msg.sender][_period] = depositInfos[msg.sender][_period].sub(downNut);
        // Add to redeem request queue
        requests[msg.sender][_period].queue.push(RedeemRequest ({
            nutAmount: downNut,
            claimed: 0,
            startTime: block.timestamp,
            endTime: block.timestamp.add(WEEK.mul(multipier[uint256(_period)]))
        }));
        totalLockedNut = totalLockedNut.sub(downNut);
        totalSupply = totalSupply.sub(_npAmount);
        emit PowerDown(msg.sender, _period, _npAmount);
    }

    function upgrade(uint256 _nutAmount, Period _src, Period _dest) external nonReentrant {
        uint256 srcLockedAmount = depositInfos[msg.sender][_src];
        require(_nutAmount > 0 && srcLockedAmount >= _nutAmount, "Invalid upgrade amount");
        require(uint256(_src) < uint256(_dest), 'Invalid period');

        depositInfos[msg.sender][_src] = depositInfos[msg.sender][_src].sub(_nutAmount);
        depositInfos[msg.sender][_dest] = depositInfos[msg.sender][_dest].add(_nutAmount);
        uint256 issuedNp = _nutAmount.mul(
                multipier[uint256(_dest)].sub(multipier[uint256(_src)])
            );
        powers[msg.sender].free = powers[msg.sender].free.add(issuedNp);
        totalSupply = totalSupply.add(issuedNp);

        emit Upgrade(msg.sender, _src, _dest, _nutAmount);
    }

    function redeem() external nonReentrant {
        uint256 avaliableRedeemNut = 0;
        for (uint256 period = 0; period < PERIOD_COUNT; period++) {
            for (uint256 idx = requests[msg.sender][Period(period)].index; idx < requests[msg.sender][Period(period)].queue.length; idx++) {
                uint256 claimable = _claimableNutOfRequest(requests[msg.sender][Period(period)].queue[idx]);
                requests[msg.sender][Period(period)].queue[idx].claimed = requests[msg.sender][Period(period)].queue[idx].claimed.add(claimable);
                // Ignore requests that has already claimed completely next time.
                if (requests[msg.sender][Period(period)].queue[idx].claimed == requests[msg.sender][Period(period)].queue[idx].nutAmount) {
                    requests[msg.sender][Period(period)].index = idx + 1;
                }

                if (claimable > 0) {
                    avaliableRedeemNut = avaliableRedeemNut.add(claimable);
                }
            }
        }

        require(IERC20(nut).balanceOf(address(this)) >= avaliableRedeemNut, "Inceficient balance of NUT");
        IERC20(nut).transfer(msg.sender, avaliableRedeemNut);
        emit Redeemd(msg.sender, avaliableRedeemNut);
    }

    function lock(address _who, uint256 _npAmount) external onlyWhitelist {
        require(powers[_who].free >= _npAmount, "Inceficient power to lock");
        powers[_who].free = powers[_who].free.sub(_npAmount);
        powers[_who].locked = powers[_who].locked.add(_npAmount);
    }

    function unlock(address _who, uint256 _npAmount) external onlyWhitelist {
        require(powers[_who].locked >= _npAmount, "Inceficient power to unlock");
        powers[_who].free = powers[_who].free.add(_npAmount);
        powers[_who].locked = powers[_who].locked.sub(_npAmount);
    }

    function name() external pure returns (string memory)  {
        return "Nut Power";
    }

    function symbol() external pure returns (string memory) {
        return "NP";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function balanceOf(address account) external view returns (PowerInfo memory) {
        return powers[account];
    }

    function redeemRequestCountOfPeriod(address _who, Period _period) external view returns (uint256 len) {
        len = requests[_who][_period].queue.length - requests[_who][_period].index;
    }

    function redeemRequestsOfPeriod(address _who, Period _period) external view returns (RedeemRequest[] memory reqs) {
        reqs = new RedeemRequest[](this.redeemRequestCountOfPeriod(_who, _period));
        for (uint i = requests[_who][_period].index; i < requests[_who][_period].queue.length; i++) {
            RedeemRequest storage req = requests[_who][_period].queue[i];
            reqs[i] = req;
        }
    }

    function firstRedeemRequest(address _who, Period _period) external view returns (RedeemRequest memory req) {
        if (requests[_who][_period].queue.length > 0) {
            req = requests[_who][_period].queue[requests[_who][_period].index];
        }
    }

    function lastRedeemRequest(address _who, Period _period) external view returns (RedeemRequest memory req) {
        if (requests[_who][_period].queue.length > 0) {
            req = requests[_who][_period].queue[requests[_who][_period].queue.length - 1];
        }
    }

    function claimableNut(address _who) external view returns (uint256 amount) {
        for (uint256 period = 0; period < PERIOD_COUNT; period++) {
            for (uint256 idx = requests[_who][Period(period)].index; idx < requests[_who][Period(period)].queue.length; idx++) {
                amount = amount.add(_claimableNutOfRequest(requests[_who][Period(period)].queue[idx]));
            }
        }
    }

    function lockedNutOfPeriod(address _who, Period _period) external view returns (uint256) {
        return depositInfos[_who][_period];
    }

    function _claimableNutOfRequest(RedeemRequest memory _req) private view returns (uint256 amount) {
        if (block.timestamp >= _req.endTime) {
            amount = _req.nutAmount.sub(_req.claimed);
        } else {
            amount = _req.nutAmount
                    .mul(block.timestamp.sub(_req.startTime))
                    .div(_req.endTime.sub(_req.startTime))
                    .sub(_req.claimed);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
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
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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