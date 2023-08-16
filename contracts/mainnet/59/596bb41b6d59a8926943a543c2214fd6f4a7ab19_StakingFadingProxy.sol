/**
 *Submitted for verification at Arbiscan on 2023-08-16
*/

// File: contracts/staking/interfaces/ISnapshottable.sol



pragma solidity ^0.8.0;

interface ISnapshottable {
    function snapshot() external;
}
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/staking/Interpolating.sol




pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;

contract Interpolating {
    using SafeMath for uint256;

    struct Interpolation {
        uint256 startOffset;
        uint256 endOffset;
        uint256 startScale;
        uint256 endScale;
    }
    uint256 public constant INTERPOLATION_DIVISOR = 1000000;


    function lerp(uint256 startOffset, uint256 endOffset, uint256 startScale, uint256 endScale, uint256 current) public pure returns (uint256) {
        if (endOffset <= startOffset) {
            // If the end is less than or equal to the start, then the value is always endValue.
            return endScale;
        }

        if (current <= startOffset) {
            // If the current value is less than or equal to the start, then the value is always startValue.
            return startScale;
        }

        if (current >= endOffset) {
            // If the current value is greater than or equal to the end, then the value is always endValue.
            return endScale;
        }

        uint256 range = endOffset.sub(startOffset);
        if (endScale > startScale) {
            // normal increasing value
            return current.sub(startOffset).mul(endScale.sub(startScale)).div(range).add(startScale);
        } else {
            // decreasing value requires different calculation
            return endOffset.sub(current).mul(startScale.sub(endScale)).div(range).add(endScale);
        }
    }

    function lerpValue(Interpolation memory data, uint256 current, uint256 value) public pure returns (uint256) {
        return lerp(data.startOffset, data.endOffset, data.startScale, data.endScale, current).mul(value).div(INTERPOLATION_DIVISOR);
    }
}
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: contracts/staking/interfaces/IStaking.sol





pragma solidity ^0.8.0;


struct UserStake {
    uint256 amount;
    uint256 depositBlock;
    uint256 withdrawBlock;
    uint256 emergencyWithdrawalBlock;

    uint256 lastSnapshotBlockNumber;
}


interface IStaking is ISnapshottable {
    function getStake(address) external view returns (UserStake memory);
    function isPenaltyCollector(address) external view returns (bool);
    function token() external view returns (IERC20);
    function penalty() external view returns (uint256);

    function stake(uint256 amount) external;
    function stakeFor(address account, uint256 amount) external;
    function withdraw(uint256 amount) external;
    function emergencyWithdraw(uint256 amount) external;
    function changeOwner(address newOwner) external;
    function sendPenalty(address to) external returns (uint256);
    function setPenaltyCollector(address collector, bool status) external;
    function getVestedTokens(address user) external view returns (uint256);
    function getVestedTokensAtSnapshot(address user, uint256 blockNumber) external view returns (uint256);
    function getWithdrawable(address user) external view returns (uint256);
    function getEmergencyWithdrawPenalty(address user) external view returns (uint256);
    function getVestedTokensPercentage(address user) external view returns (uint256);
    function getWithdrawablePercentage(address user) external view returns (uint256);
    function getEmergencyWithdrawPenaltyPercentage(address user) external view returns (uint256);
    function getEmergencyWithdrawPenaltyAmountReturned(address user, uint256 amount) external view returns (uint256);

    function getStakersCount() external view returns (uint256);
    function getStakers(uint256 idx) external view returns (address);
    function setStakers(address[] calldata _stakers) external;
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/staking/StakingFadingProxy.sol



pragma solidity 0.8.19;






contract StakingFadingProxy is Ownable, Interpolating, IStaking {
    IStaking public stakingInstance;
    Interpolation public fadeInterpolation;

    mapping(address => bool) public isSnapshotter;
    
    constructor(address _stakingInstance) {
        require(_stakingInstance != address(0), "Invalid staking contract address");
        stakingInstance = IStaking(_stakingInstance);
        // default to no interpolation
        fadeInterpolation = Interpolation(1, 2, 1000000, 1000000);
    }
    
    // some housekeeping
    function setStaking(address _stakingInstance) external onlyOwner {
        require(_stakingInstance != address(0), "Invalid staking contract address");
        stakingInstance = IStaking(_stakingInstance);
    }
    function setFade(Interpolation calldata _fadeInterpolation) external onlyOwner {
        require(_fadeInterpolation.startOffset > block.number, "Must start in the future");
        fadeInterpolation = _fadeInterpolation;
    }
    function setSnapshotter(address _snapshotter, bool _state) external onlyOwner {
        isSnapshotter[_snapshotter] = _state;
    }
    modifier onlySnapshotter() {
        require(isSnapshotter[msg.sender], "Only snapshotter can call this function");
        _;
    }

    // altered proxy calls
    function scaleAmount(uint256 _amount, uint256 _blockNumber) public view returns (uint256) {
        return lerpValue(fadeInterpolation, _blockNumber, _amount);
    }
    function getStake(address account) external view override returns (UserStake memory) {
        UserStake memory result = stakingInstance.getStake(account);
        // update the amount based on the fade
        result.amount = scaleAmount(result.amount, block.number);
        return result;
    }
    function getVestedTokens(address user) external override view returns (uint256) {
        return scaleAmount(stakingInstance.getVestedTokens(user), block.number);
    }
    function getVestedTokensPercentage(address user) external override view returns (uint256) {
        return scaleAmount(stakingInstance.getVestedTokensPercentage(user), block.number);
    }
    function getVestedTokensAtSnapshot(address user, uint256 blockNumber) external override view returns (uint256) {
        return scaleAmount(stakingInstance.getVestedTokensAtSnapshot(user, blockNumber), blockNumber);
    }

    // refused proxy calls
    function penalty() external view override returns (uint256) {
        require(false, 'Not implemented for proxy, use real contract');
    }
    function isPenaltyCollector(address user) external view override returns (bool) {
        require(false, 'Not implemented for proxy, use real contract');
    }
    function stake(uint256 amount) external override {
        require(false, 'Not implemented for proxy, use real contract');
    }
    function stakeFor(address account, uint256 amount) external override {
        require(false, 'Not implemented for proxy, use real contract');
    }
    function withdraw(uint256 amount) external override {
        require(false, 'Not implemented for proxy, use real contract');
    }
    function emergencyWithdraw(uint256 amount) external override {
        require(false, 'Not implemented for proxy, use real contract');
    }
    function changeOwner(address newOwner) external override {
        require(false, 'Not implemented for proxy, use real contract');
    }
    function sendPenalty(address to) external override returns (uint256) {
        require(false, 'Not implemented for proxy, use real contract');
    }
    function setPenaltyCollector(address collector, bool status) external override {
        require(false, 'Not implemented for proxy, use real contract');
    }
    function setStakers(address[] calldata _stakers) external override {
        require(false, 'Not implemented for proxy, use real contract');
    }

    // unaltered proxy calls
    function token() external view override returns (IERC20) {
        return stakingInstance.token();
    }
    function snapshot() external override onlySnapshotter {
        stakingInstance.snapshot();
    }
    function getWithdrawable(address user) external override view returns (uint256) {
        return stakingInstance.getWithdrawable(user);
    }
    function getEmergencyWithdrawPenalty(address user) external override view returns (uint256) {
        return stakingInstance.getEmergencyWithdrawPenalty(user);
    }
    function getWithdrawablePercentage(address user) external override view returns (uint256) {
        return stakingInstance.getWithdrawablePercentage(user);
    }
    function getEmergencyWithdrawPenaltyPercentage(address user) external override view returns (uint256) {
        return stakingInstance.getEmergencyWithdrawPenaltyPercentage(user);
    }
    function getEmergencyWithdrawPenaltyAmountReturned(address user, uint256 amount) external override view returns (uint256) {
        return stakingInstance.getEmergencyWithdrawPenaltyAmountReturned(user, amount);
    }
    function getStakersCount() external override view returns (uint256) {
        return stakingInstance.getStakersCount();
    }
    function getStakers(uint256 idx) external override view returns (address) {
        return stakingInstance.getStakers(idx);
    }
}