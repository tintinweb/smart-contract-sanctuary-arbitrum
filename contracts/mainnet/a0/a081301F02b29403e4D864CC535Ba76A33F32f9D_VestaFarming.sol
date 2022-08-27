// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import "./FullMath.sol";

import "./IVestaFarming.sol";

import "./MissingRewards.sol";

//// Modified version of https://github.com/Synthetixio/Unipool/blob/master/contracts/Unipool.sol
contract VestaFarming is IVestaFarming, OwnableUpgradeable {
	using SafeMathUpgradeable for uint256;
	using SafeERC20Upgradeable for IERC20Upgradeable;

	uint256 public constant DURATION = 1 weeks;

	IERC20Upgradeable public stakingToken;
	IERC20Upgradeable public vsta;

	uint256 public totalStaked;
	uint256 public oldTotalStaked;

	uint256 public rewardRate;
	uint256 public rewardPerTokenStored;
	uint256 public lastUpdateTime;

	mapping(address => uint256) public balances;
	mapping(address => uint256) public userRewardPerTokenPaid;
	mapping(address => uint256) public rewards;

	uint256 public totalSupply;

	uint64 public periodFinish;
	uint256 internal constant PRECISION = 1e30;
	uint64 public constant MONTHLY_DURATION = 2628000;

	MissingRewards public missingRewards;

	modifier cannotBeZero(uint256 amount) {
		require(amount > 0, "Amount cannot be Zero");
		_;
	}

	function setUp(
		address _stakingToken,
		address _vsta,
		uint256, /*_weeklyDistribution*/
		address _admin
	) external initializer {
		require(
			address(_stakingToken) != address(0),
			"Staking Token Cannot be zero!"
		);
		require(address(_vsta) != address(0), "VSTA Cannot be zero!");
		__Ownable_init();

		stakingToken = IERC20Upgradeable(_stakingToken);
		vsta = IERC20Upgradeable(_vsta);

		lastUpdateTime = block.timestamp;
		transferOwnership(_admin);
	}

	function setMissingRewards(address _missingReward) external onlyOwner {
		missingRewards = MissingRewards(_missingReward);
	}

	function stake(uint256 amount) external {
		if (amount == 0) return;

		uint256 accountBalance = balances[msg.sender];
		uint64 lastTimeRewardApplicable_ = lastTimeRewardApplicable();
		uint256 totalStake_ = totalStaked;
		uint256 rewardPerToken_ = _rewardPerToken(
			totalStake_,
			lastTimeRewardApplicable_,
			rewardRate
		);

		rewardPerTokenStored = rewardPerToken_;
		lastUpdateTime = lastTimeRewardApplicable_;
		rewards[msg.sender] = _earned(
			msg.sender,
			accountBalance,
			rewardPerToken_,
			rewards[msg.sender]
		);
		userRewardPerTokenPaid[msg.sender] = rewardPerToken_;

		totalStaked = totalStake_ + amount;
		balances[msg.sender] = accountBalance + amount;

		stakingToken.safeTransferFrom(msg.sender, address(this), amount);

		emit Staked(msg.sender, amount);
	}

	function withdraw(uint256 amount) public virtual {
		if (amount == 0) return;

		uint256 accountBalance = balances[msg.sender];
		uint64 lastTimeRewardApplicable_ = lastTimeRewardApplicable();
		uint256 totalStake_ = totalStaked;
		uint256 rewardPerToken_ = _rewardPerToken(
			totalStake_,
			lastTimeRewardApplicable_,
			rewardRate
		);

		rewardPerTokenStored = rewardPerToken_;
		lastUpdateTime = lastTimeRewardApplicable_;
		rewards[msg.sender] = _earned(
			msg.sender,
			accountBalance,
			rewardPerToken_,
			rewards[msg.sender]
		);
		userRewardPerTokenPaid[msg.sender] = rewardPerToken_;

		balances[msg.sender] = accountBalance - amount;

		totalStaked = totalStake_ - amount;

		stakingToken.safeTransfer(msg.sender, amount);

		emit Withdrawn(msg.sender, amount);
	}

	function exit() public virtual {
		uint256 accountBalance = balances[msg.sender];

		uint64 lastTimeRewardApplicable_ = lastTimeRewardApplicable();
		uint256 totalStake_ = totalStaked;
		uint256 rewardPerToken_ = _rewardPerToken(
			totalStake_,
			lastTimeRewardApplicable_,
			rewardRate
		);

		uint256 reward = _earned(
			msg.sender,
			accountBalance,
			rewardPerToken_,
			rewards[msg.sender]
		);
		if (reward > 0) {
			rewards[msg.sender] = 0;
		}

		rewardPerTokenStored = rewardPerToken_;
		lastUpdateTime = lastTimeRewardApplicable_;
		userRewardPerTokenPaid[msg.sender] = rewardPerToken_;

		balances[msg.sender] = 0;

		totalStaked = totalStake_ - accountBalance;

		stakingToken.safeTransfer(msg.sender, accountBalance);
		emit Withdrawn(msg.sender, accountBalance);

		if (reward > 0) {
			vsta.safeTransfer(msg.sender, reward);
			emit RewardPaid(msg.sender, reward);
		}
	}

	function getReward() public virtual {
		uint256 accountBalance = balances[msg.sender];
		uint64 lastTimeRewardApplicable_ = lastTimeRewardApplicable();
		uint256 totalStake_ = totalStaked;
		uint256 rewardPerToken_ = _rewardPerToken(
			totalStake_,
			lastTimeRewardApplicable_,
			rewardRate
		);

		uint256 reward = _earned(
			msg.sender,
			accountBalance,
			rewardPerToken_,
			rewards[msg.sender]
		);

		rewardPerTokenStored = rewardPerToken_;
		lastUpdateTime = lastTimeRewardApplicable_;
		userRewardPerTokenPaid[msg.sender] = rewardPerToken_;

		if (reward > 0) {
			missingRewards.eraseData(msg.sender);
			rewards[msg.sender] = 0;

			vsta.safeTransfer(msg.sender, reward);
			emit RewardPaid(msg.sender, reward);
		}
	}

	function lastTimeRewardApplicable() public view returns (uint64) {
		return
			block.timestamp < periodFinish
				? uint64(block.timestamp)
				: periodFinish;
	}

	function rewardPerToken() external view returns (uint256) {
		return
			_rewardPerToken(totalStaked, lastTimeRewardApplicable(), rewardRate);
	}

	function earned(address account) external view returns (uint256) {
		return
			_earned(
				account,
				balances[account],
				_rewardPerToken(
					totalStaked,
					lastTimeRewardApplicable(),
					rewardRate
				),
				rewards[account]
			);
	}

	/// @notice Lets a reward distributor start a new reward period. The reward tokens must have already
	/// been transferred to this contract before calling this function. If it is called
	/// when a reward period is still active, a new reward period will begin from the time
	/// of calling this function, using the leftover rewards from the old reward period plus
	/// the newly sent rewards as the reward.
	/// @dev If the reward amount will cause an overflow when computing rewardPerToken, then
	/// this function will revert.
	/// @param reward The amount of reward tokens to use in the new reward period.
	function notifyRewardAmount(uint256 reward) external onlyOwner {
		if (reward == 0) return;

		uint256 rewardRate_ = rewardRate;
		uint64 periodFinish_ = periodFinish;
		uint64 lastTimeRewardApplicable_ = block.timestamp < periodFinish_
			? uint64(block.timestamp)
			: periodFinish_;
		uint64 DURATION_ = MONTHLY_DURATION;
		uint256 totalStake_ = totalStaked;

		rewardPerTokenStored = _rewardPerToken(
			totalStake_,
			lastTimeRewardApplicable_,
			rewardRate_
		);
		lastUpdateTime = lastTimeRewardApplicable_;

		uint256 newRewardRate;
		if (block.timestamp >= periodFinish_) {
			newRewardRate = reward / DURATION_;
		} else {
			uint256 remaining = periodFinish_ - block.timestamp;
			uint256 leftover = remaining * rewardRate_;
			newRewardRate = (reward + leftover) / DURATION_;
		}

		if (newRewardRate >= ((type(uint256).max / PRECISION) / DURATION_)) {
			revert Error_AmountTooLarge();
		}

		rewardRate = newRewardRate;
		lastUpdateTime = uint64(block.timestamp);
		periodFinish = uint64(block.timestamp + DURATION_);

		emit RewardAdded(reward);
	}

	function _earned(
		address account,
		uint256 accountBalance,
		uint256 rewardPerToken_,
		uint256 accountRewards
	) internal view returns (uint256) {
		return
			FullMath.mulDiv(
				accountBalance,
				rewardPerToken_ - userRewardPerTokenPaid[account],
				PRECISION
			) +
			accountRewards +
			missingRewards.getMissingReward(account);
	}

	function _rewardPerToken(
		uint256 totalStake_,
		uint256 lastTimeRewardApplicable_,
		uint256 rewardRate_
	) internal view returns (uint256) {
		if (totalStake_ == 0) {
			return rewardPerTokenStored;
		}
		return
			rewardPerTokenStored +
			FullMath.mulDiv(
				(lastTimeRewardApplicable_ - lastUpdateTime) * PRECISION,
				rewardRate_,
				totalStake_
			);
	}

	function fixPool() external onlyOwner {
		periodFinish = uint64(block.timestamp);

		uint64 lastTimeRewardApplicable_ = lastTimeRewardApplicable();
		uint256 totalStake_ = totalStaked;
		uint256 rewardPerToken_ = _rewardPerToken(
			totalStake_,
			lastTimeRewardApplicable_,
			rewardRate
		);

		rewardPerTokenStored = rewardPerToken_;
		lastUpdateTime = lastTimeRewardApplicable_;

		totalSupply = 0;
		oldTotalStaked = 0;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
        IERC20PermitUpgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
library SafeMathUpgradeable {
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
pragma solidity >=0.8.0;

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
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
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
        result = mulDiv(a, b, denominator);
        unchecked {
            if (mulmod(a, b, denominator) > 0) {
                require(result < type(uint256).max);
                result++;
            }
        }
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >=0.8.0;

interface IVestaFarming {
	error Error_ZeroOwner();
	error Error_AlreadyInitialized();
	error Error_NotRewardDistributor();
	error Error_AmountTooLarge();

	event RewardAdded(uint256 reward);
	event Staked(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RewardPaid(address indexed user, uint256 reward);
	event EmergencyWithdraw(uint256 totalWithdrawn);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.11;

/**
 * After an update on the contract to fix a formula issue (which would cause a big issue at the end). We accidently reseted everyone's rewards
 * This contract holds all the affected users and is linked into the VestaFarming contract. So they get back their rewards once more.
 */
contract MissingRewards {
	mapping(address => uint256) private missingRewards;

	address public VSTA_ETHPool;

	constructor(address _VSTA_ETHPool) {
		VSTA_ETHPool = _VSTA_ETHPool;
		uint256 length = stakers.length;

		for (uint256 i = 0; i < length; ++i) {
			missingRewards[stakers[i]] = missing[i];
		}
	}

	function getMissingReward(address _user)
		external
		view
		returns (uint256)
	{
		return missingRewards[_user];
	}

	function eraseData(address _user) external {
		require(msg.sender == VSTA_ETHPool, "Caller is not the pool.");
		missingRewards[_user] = 0;
	}

	address[] private stakers = [
		0x501fd8F371887d89dF8Bc6B4b74D1Da402587282,
		0x1Fd2978aC57fB2f459EF1AB7812b58f29aB437BA,
		0x1425C88ce0780E5bcE5f405333C81f9336dC52eA,
		0x8d452c1f4bAE385B13933c83EcFf70D74229915F,
		0xFfD7Fd0B03B42f12C2079D2717f504fAE5597e56,
		0xf67D480D09FB18501385a17F12E09f565770EE17,
		0x8E15BA035e1D28052763780787e5E1b45F69E453,
		0x045e6664b0C1C589b114C1a1da23F662c654156f,
		0x0AB38B8c324d214bF175Dc1a94C44651AB0b31e9,
		0xbDfA4f4492dD7b7Cf211209C4791AF8d52BF5c50,
		0x651C636fC2adbB79fB2c8FBb1Cf3A6F76ff1fDd9,
		0xB5eB1cdda34E5a40bEbFE839dae65f3B42827721,
		0xdfFEF5d853E5E1DaD3B909E37Ba2DAE94087c3cC,
		0x834565044f65D99E33d78E2d399c3817697D7ba7,
		0xEE5CE06aCcCE11BC77c5A93723C8032D9108f22d,
		0x9dF3F3fC5eb4C3527Ab4C3Cc535FF4150d6880DF,
		0x36cf80D36fDA4530777aeD39ae7f398E38fbb25f,
		0x0A6CA057fF6ea5B5f9db057e595E14EeCd8f6d84,
		0xb5F54e7f3F5Cdcf0cE6E165fC2e3f826CfCd5457,
		0x72Ebe79eaD612eBeb52912eeDe9df947F291Dc90,
		0xBA73B6461E677221669B4674756768a05D752813,
		0x0056D1fd2ca3c0F3A7B6ed6CDd1F1F104B4BF9A9,
		0x7a855E3E13585368576a5A583c50451339AcC561,
		0x685C9d78F8dd97C48fB612501ecEd35d6810bE2C,
		0x667E2491Cec398C453EEeB708bF6eCBc2c6B5dA9,
		0x794B43550c4aF0C60E65d175862D3d675B474E79,
		0x69E0e70cF7fEdAEd41D82A046Df626b18C1ba230,
		0xC33f3c7B350E42d9CDA46A8170FAf7bDEA178D4b,
		0x4f7169715CFb078C1E83bDC738d72A5919Fa7248,
		0x5F153A7d31b315167Fe41dA83acBa1ca7F86E91d,
		0x720424FbE22271BA87cDf8Ce55928D18eeB65CcE,
		0x117EE6900439036DFd811Ad8DddccA8CfF9230Fd,
		0x90aBCf1598ed3077861bCFb3B11EFcd1D7277223,
		0x01076E09dCB258c16537670307F9bDCED007BF37,
		0x0f696812F40D52327B8cc419b1044b0e9C162ac9,
		0xf7411A3F727b36f56ff3A871163c21E56D672656,
		0x0cbe8aB8e5D680C4c75959231c33A036ad123995,
		0x2752513320580D76AC2244e9b73fc981A5fFB3f9,
		0x14AB9F431B7D25FcAd366EC9511DcE38E229745C,
		0x4ba6f7731e0c2240833c9E2d2Aa067AeDf8aEC09,
		0xC7F4cdb175b1885e95B8F49CCBbD3F929Ab7D1BA,
		0x870Dc279570833A8c5A72FC7972681Db9A96CFb7,
		0x388Ad6E8f54D90526ecE2668d9243481c1B46d3D,
		0x7DF36D3a5a2fF713A8Bfa7230C4dcCd20973515c,
		0x1F8460B860FcDaBaa28b569E47454d7A1820c2BD,
		0x653d63E4F2D7112a19f5Eb993890a3F27b48aDa5,
		0x8a17bCdCA83fe8F9F6Dddd5F6Fe638244465Fa18,
		0xFFc4dCdfC6755b524982c7d7dF383c25cC17F3Dd,
		0x0a8f4E308B17F836eAb6493F42E48ac07D30946D,
		0x4a32a2a2640aBAD3d4fE15100afc625355733077,
		0x7bfb43d4b0c7999D8aF691A3F626cf282bB82f52,
		0xBE73748446811eBC2a4DDdDcd55867d013D6136e,
		0xb7911c63824bD5cF0d3263466B94f0f8efDC5312,
		0x18ACc7e09e5b4adAF4d51DcE21Bc2ac616EA9440,
		0xD8CB3F2C57e84c880a247e3576E07F0B6Debc278,
		0x5E91d547A6f279E6d59086E30e25C964EFE4b463,
		0x652968C8e951709997418eB6B22B7f2f8E99fdfa,
		0xD5dE81E7e5E4F740a26Ebb254d6052e1D03B4787,
		0xfE0Edf298D6F07fD7f11A693c017044BCC46629A,
		0x2bb8Ab3C2A9837de97A83c228A07E16928B4f07f,
		0x87e4bC198026146D396320DA75676e6619C5fb62,
		0x6F58133f47F9473a199b3ff1aD510d79EADfB11E,
		0x641D99580f6cf034e1734287A9E8DaE4356641cA,
		0x147D740AaF617B46E85304d2590ACc20A90cEe7c,
		0x1C9e56aE6776C07df88960b80f41b45Cb5fdda2C,
		0xAd192a9eAEe1E342CAbB1Cd32f01de3b77D8598f,
		0x700d4EABCe794e75637564211C0DF62701Db59ac,
		0xbE79ADE774A6869F1FA5BAf96cC9427642219288,
		0x59D2e0a2be0DB463c36038A5fd2535F58Ab3B38F,
		0x9e6E058c06C7CEEb6090e8438fC722F7D34188A3,
		0xc3bD451D60C463cbE7C700488258FE0ce22F0513,
		0xDD59c746B1a08dD918F0Bad5c9868644bC349120,
		0x2Fd31744080b9cd293d13C4fD25DED7a8f2aBDfe,
		0xdA30B9dff1DD656c35489cb9Fc30B129206C2076,
		0xB6699cFb5973cB4A7c803b1cC06d7216d7a958fC,
		0x0f06943917EB4804f53015E34cdf3D2c287AD060,
		0x3DF9fbB6d0368Db9aE00Ebf17051F5cc92E7F49E,
		0xF9Fe2265e51580eC5682156BBD5b20B23C627dA2,
		0x2d61629359FBEf039e9d574700350ED33C932aFe,
		0xEBe3C3d23AFb897137e0e55844B8abe33C1E72a8,
		0xC26d7e895e1d19b0B987Acd1Fed75a12Df601190,
		0x630664594134b641D78c9D2823385d8BAC63d4fF,
		0x46F51aE30f51b04d40da51d7Fbb08f58A3fe5198,
		0x63Ce7C8d5336850AA0EC345E908B8cF6f979b913,
		0x17f838E5B73d144Af7CA67fD9f03c5aF47f287f0,
		0x9bb64e40DCBe4645F99F0a9e2507b5A53795fa70,
		0x8fd2a590ef899573d2141EE1d5F3C76462d69E5c,
		0x5181Cdf1bB20dA04bA788F82989F29E65B67314A,
		0x13977D29d97e524f5197e355Fb3CBd5cC11b6763,
		0xF16e9A5D117e0F6DE416779942D943365321cFca,
		0x477d7Ee756338f0B7f3A8bb6b097A78CCABf70f5,
		0x3AcfB8b4fddaEA21e9b213e6A3917Cf45e51e71F,
		0x476551e292547C70bB27307d87Df54bAeb0f644b,
		0x2F6C2c5Ec912449A914930442522368Ee99Fa845,
		0x2814c361BF1289cEf2958dB2fd9dE154f37a8963,
		0x1DC9ee19Bc6eCe2df030Eb1F4f5d775e817d798D,
		0x6Fa54473743BC51eD33C54348111745cCFD60eF9,
		0x5C7c6d069ba232718f37C27A9549b547C359E31C,
		0xDc8c1959C74ab2cb3819ADD153E62739d12be550,
		0x84d5b994739609797856B8D29721Ce9C40aE0E13,
		0xA5acf1B71B653662FCf881EDbf8c92460b1C387D,
		0xBEa645Da9c7f6De1f7E287759CcBFd5ab9f57C08,
		0x0212fBfB3bbA5d8566F09E8Ef78BCde68CCB30A3,
		0x2BAf193C2aE9d35a37B9b124a21221C86931cAd1,
		0x210fc3f8351efC0971E2a3770A82aC2544DD95a2,
		0x08ADD492D47eEe11790298D92B30BcA8d3AD27ea,
		0xaAcb61585B1043839290D15cb29B306918Dac480,
		0x435b7D470767Cb121F37dD296B2AC7913fDF5427,
		0xEd264b6dA420d6F366C0DC8Ee0A1caA557717D22,
		0xE868B8C09fD2c8c3F74D54f34f7325aB1c94c71F,
		0xCe462C13F461DEEB3Ec2dAaDd5e7d5F90Bb8F0b2,
		0x153B4F4f2c6c284f844A53eB2e097D23B7bfa4Dd,
		0x02a84163763Dd791328765b96aed43b6a915af48,
		0x67B98fa27f40028e9CAAf5a02535cf112dB833Aa,
		0xD30F2888E7928b52EA5bF4cb1D323e0531aFe272,
		0xB6F6bE9B684F5Cc39b562E94465A6689b561C0f0,
		0xd76A9CBA16b91f4a5927BD496F20De108ff445A7,
		0xeA7DF5291B94E0306A9635e48E75cA7FFe3b5568,
		0x8b7A6fec5C6638C1D667eF8126B457fEc09376Eb,
		0x7d00d2e2B36A4938C5E0CA847Fc82B616512A584,
		0x98A176a19c29128e296971c49e497eD48520Ca30,
		0x161D9B5d6e3eD8D9c1D36a7Caf971901C60B9222,
		0x538b072cFA961E6BfBe829c05F5EE42C80c3a774,
		0xE551388B683BB1E34e27E5a7b00eaBE79b080Bf7,
		0x725c1De2Af3F7861cE93D7D1A019484F7eDB2928,
		0x5658906351368362351fAC485B8D741EF6c4F5cA,
		0x4E2A7d0e465D8d38aA5A1852D438e60b5832C1b4,
		0x681769C6d44E86250fc95A3B7e0A28A427E55B64,
		0x03B7C016E60B4207A775BDAbeCE62069f862A5CD,
		0x707ACc9693237C9f6F200C3bf7C114803a6FC10F,
		0x20eBE30b746fc22803DC5A8516DEaae07dddBB76,
		0xE310b900915AbFE76a39432564a223271937695f,
		0x4b6DE0ea8eA2948B3bFFDbcB7daE53A1f9c2d457,
		0x8180281Fac472bA14EF6dF8a63a259DC71a3a23e,
		0xD8f6398d1D8ABc9AdFede2f8d8C0Fb641D9E4734,
		0x9Fc07b0147a6eb9a77daA882C33de465B97b401c,
		0x33753142F4e5bF25f5529c9C05C30B5452Da71e2,
		0x8714a2586DA66911636525c3Fe16343EF4a28907,
		0x350773fCf465043a059b23DFF9A6AC65d2ca82c8,
		0x1D198A0c5ceAef1FB6730865eD55C382f6EBbC25,
		0xD22f76ABcF04b0194B3594073587912f9B9e56f9,
		0x722E895A12d2A11BE99ed69dBc1FEdbB9F3Cd8fe,
		0xA5Cc7F3c81681429b8e4Fc074847083446CfDb99,
		0x8c75351c8136B750f818206b300988206A15f7bc,
		0x32a59b87352e980dD6aB1bAF462696D28e63525D,
		0x02b6E3488B382C93F3f80aBB237EB9FEF16283be,
		0xf00A1C365aDB1666183608e329e69ceDDb7fd674,
		0xEfA117fC408c83E82427fcc22A7d06302c542346,
		0xf3A5bEdB1078bFE047cEf4409DCf92E95D1b6DFC,
		0x2518b186320206e2Ea9315d867944891dc1f1036,
		0x646953F3EB3EbBD2e07c515d7f1364c42EbE32Ba,
		0x4A8D850A5dE7efbF578F808aA9D9359E769Ffcf6,
		0x2f4f48331E936F2500db409e691edf6DeaF1020F,
		0x0c930e30E9e1AAa041109E58801a52595392a405,
		0x7273855cdb7A023274106517265bA2c7832401fc,
		0xF15540a1d0cC918771C2fE2DDC49B762BF635a47,
		0x307923a41F1fe2Cf876B2Cb103e24438b56ABa91,
		0x0429C8D18b916dFFa9d3Ac0bC56D34D9014456ef,
		0x6D4ed8a1599DEe2655D51B245f786293E03d58f7,
		0x9128D7a95b7811af2da2cEd9116b04C78792b84F,
		0x8c1216b27f7Eb48d27986DB4F351fCB9f8EA39EF,
		0xD54d23200E2bf7cB7A7d6792a55DA1377A697799,
		0x575957E047d5264512aF6aE591817faD51e5e9B2,
		0x5e67DE62b9B10ad982f5777365940E0C68EB4599,
		0xb6D0981639716A5C7054D3b9726d6AF3B3AAA024,
		0xB1Ec171401c914b437D331994b328aC01D904671,
		0xe40bc036feB3260051A20c491c2Bc3D0dCdc1a2c,
		0xd3E249558B6668a7bBE6a12d3091c93c49BEE685,
		0x8D8CC393220DA84a53667E48c25e767499DCE4fB,
		0x6f198139B06D312E05b602489eDffB44c5621Fe0,
		0x5dd9746a6b2Ad0abaa08F1885a9CD4b4b61659e1,
		0x2B9a28D252CE8912cC2aD18dEbBfD26c65b192B0,
		0x851497cf9B1362858C095CdD577B506d24F57336,
		0x0dD48Cd239Db288f20B4EbFE3327a6DF425c3010,
		0x66A9B4aa270B987054D372D9Bcd4E67e0A1DdA69,
		0x319dc91B2a9AA6E0600225A957667887818f3Df2,
		0x1E9B7ed825C0ACb6bCf0E2Ab53C99DC32b48BD29,
		0xBa66377997909ddCBa9D3482CFacB57A84D50FA9,
		0x86f2d48Ab653D192AC8395d7A92439BEb43337Cb,
		0x3165dC7D1571CaA03F83f321Deb924E7F2c931a5,
		0x75F95C0fe097BB7d63396D64aC491dAf9667A796,
		0xDAaEEaE253931D8f90143da88eA6cb9647f797EB,
		0xf4058C6d3D71a6be19061bb87d5c57C9646AEDbA,
		0xc0ea3704c21163ddAc1C662f642Aa138233b29C1,
		0xD9c044a8f6Cb4872Fda96811DC743093f193699b,
		0xd8d928337679E274Bc5b4EC4883F26419D46eE50,
		0xc0DD6706c461eeE71634Baa5cc8006918764649d,
		0x5FCF239d3Ef633345AB8Db3eac76f69f1AE16B13,
		0x548a18e98D90ba67482547148f4f32Ee6389AfF4,
		0xC4C61Bf34fd970506F71862Bc57ac7417C6F1680,
		0xc845bFfA5c0818405420A37750ee381Ea2C86b0f,
		0xf7A2571eA4d6F478448551F7423085df61BD7cf4,
		0xe9017c8De5040968D9752A18d805cD2A983E558c,
		0xB1f72d694711FcE55C62eA97BD3739Ff11ceF986,
		0x0d82d69485e3a6c520942169E61F9C6432aeE158,
		0x8EB044c25D230Cd966a99C45D1B664c71fD70FE7,
		0x6592978Bc047B2fDdDDBF11899C7B981A72F5489,
		0x50D52d86458f73005858a9345CF4ce89E5a6F410,
		0xd874387eBb001a6B0BEa98072f8dE05f8965E51E,
		0x14B5Eb80797280066665602246b6AcBE77bfb90e,
		0x5fc13f8353b09fEE5621f55377BEa82014840029,
		0x730bBE154972F467062b3d91130aD36E67E55Ca2,
		0xb12292711373c6919aB9b10329601855EBC9fdE2,
		0x38148eCC2078dA7f65E6233DDA28eFaf4C51E96F,
		0x4b7ec805ae47e8696c212Ee1E259a291316440d4,
		0x358a0beC7FD9469fDDDe458527510994ca2217Bc,
		0x6f6a4Fe5b944424c115DAb4302AAf26f0C7dB83F,
		0xbEE2D469AACB46251aE33Cca91F482e26c971dFF,
		0xE3EdC693C22D69716565A9493359CBa6CD3d0349,
		0x66f2e146AD18b761a6Be38e6F427b7899Be8ef90,
		0xD9b5bC014707AAEa25b14B2C3886a0c68C3B5bF7,
		0xC43Ea5617a6b38b7560eDfB0474031a661d86BEC,
		0x6Bd30F52535CC8cdb66D60c862Ee2eaf21d43fD9,
		0x5E454643B3827dBc833A45b109a08CB61e1E8014,
		0xD18f91C1F576e5cCCbD576046f027d34C7E748FC,
		0x4A2B2eDdDBb8264D009D2931FA96350A911EE69c,
		0xFdD548a51286213Fe7F87546c9Add036D99eC038,
		0x8473b1826D89BD200368437972F9520E80f7Fb88,
		0x20D6F60eE3B5053CbC86f6E4F57DB09f03a544B2,
		0x8D842a732A846a1D9BD3C9F3675B54066c8BAA0b,
		0xB714fa495c0332b49D580F2aabD3dA667D068b0c,
		0x677133cbF3784C8E58A7e2c3649d8E0BFB42848E,
		0x43a05149917AEc6480062015Cfe0c0775E568A35,
		0xFfA0F764a4E7411298CeFd937c6845407138008A,
		0xEa4B4242f2915bA771146C1C427B2d44C513a445,
		0x13210647AF3f8Dc20d45F5f5565F9B90A39481f9,
		0x3759fA6D9BAc4257d5a468CAF1210d0eB81a5B9c,
		0x0D4aEA0f52513c5F18299B0721cdB31565Cb673f,
		0x4d5eA105DECcFF5BCd373C31D742A455351A663B,
		0x8450A7852495DaFe063C3E436d0750698777965C,
		0x4e3178335a6c09C7B0eA61bE3C278E5a898312CD,
		0xE3f5e632d07D39b0AE46AB2538e5260E8BE31e4e,
		0x9A43E2d3f7D28f0BB8A6B5952dC563AB51B8cb55,
		0x24E219EBf46093dC5c5A748Cb20B8c83e86bf09d,
		0x71a92cFC6bf93F4E447f1C2a9644965d52014eb1,
		0x1A1b1504139909F6673951338Ca8574Df3267c9D,
		0x464fd6B8E4DDe4352117940a07d7cc93269a77Bb,
		0x2407Ae4297D548CFFd44b34048Bd835f486F5135,
		0xe4e3486DfCE91Ba87060228d44f8DB7C59A86139,
		0x4fcb2161e087F3A4153545A25304Bd4E123A0e07,
		0x44ad5FA4D36Dc37b7B83bAD6Ac6F373C47C3C837,
		0x7dAbBED7360B0c921df854c8f9FC8D8173082096,
		0x49c6fB6CBe27Ce0E773B85840Cb072791368e5Bb,
		0x6ffbb6C376d0cf590289671D652Ae92213614828,
		0xeAf681Dd7195797C56B7DF42749B0187555A4544,
		0xe3a6C906A3f13588Ed44De67dba7DC7E49bd1459,
		0xFFe4E3986d18333402564EA64f3a83FCC1907b52,
		0x65D7624883aC2a33855AAE52969b5BD80EB4bf4C,
		0x52F00b86cD0A23f03821aD2f9FA0C4741e692821,
		0x020EB226e93362D1304BC97A3dD07231B1Cdf097,
		0x0f8361eF329B43fA48aC66A7cD8F619C517274f1,
		0xF116569b3f888D639372a5485685A6D8EE28A593,
		0x4eCDEcc6a287864EDFbFC949d5eC5Bbe3ac7Fa70,
		0xe0dDa4f11dA57F5b01D360072Ca1627Ea5bf93df,
		0xbebd24c6ddafD20880cb1f3cF80BaF640774dF34,
		0x79aB78Fe4b4B166da1B868527E587bc9b8B6A3AE,
		0x8b3f91Dc0042DCe3828b6b97aF153ED92843f356,
		0xCD729A90C9855f04488FbB5234C8026B71B80568,
		0xF17ac82CB2c92853100f150591973857B1b48D7F,
		0x8D73e98e7E123e765814e887a0071A5a7601aBbC,
		0x9caB8CB4DE8231aD9c8658CF0B746E5bF822dBd9,
		0x578768D2C7c5bEb60cccFc148A563c8378e281ec
	];

	uint256[] private missing = [
		691298628413414987806,
		7936681967472255236199,
		2340434539471703268876,
		191987581677108683335,
		4372193867018415551214,
		40475242348388375906,
		1344858402206668135449,
		8361437459453520775,
		813769185557836030835,
		273237608859380398371,
		4026545746515209607,
		248250873628640163539,
		352872733493328102686,
		118430483443660356796,
		122662830762561451932,
		40414915788812747499,
		301700159756885837065,
		9021440523449869387,
		64517341283807655934,
		27781410852889916783,
		161838789142155145880,
		1316362163838188217037,
		862055915235966907106,
		80845122143579728169,
		65791342411266959596,
		61924519496943889583,
		24586448494880338411,
		689511898372891606550,
		12454082036818780053283,
		16141372838498463681,
		79830086256137029674,
		71988621986980031119,
		559587897480025419514,
		4031537417754124033085,
		4109393044059647305,
		5351934040058434089341,
		168521078862784401646,
		144296221389209229073,
		47544890113465262599,
		88068599716942569653,
		54347886813131884972,
		72339174722776631204,
		7730005644323130263,
		46039576254720087132,
		293449664600603302342,
		297175008719542836061,
		132158953824507235575,
		105669040935082087907,
		2011197697743569208744,
		359468897596172183313,
		42421007292322324522,
		419154546559553128732,
		12901875595970848282,
		66058048938577255927,
		59452424786014320616,
		11193109093067876659855,
		12522904916349959770,
		8858290156587348382,
		344023437419072456570,
		2020828027024886844902,
		86903606088284748546,
		127523364217576666123,
		1752032469742208323871,
		584926217178204923897,
		59086920170228346024,
		5380774114172897546154,
		10635475211010144575,
		100522802694691308533,
		1568314828624385472,
		75714984558680219673,
		167862867322246857338,
		21048378730113094573,
		250118593420944678850,
		216442293291823499098,
		1176825935987754372579,
		201086126058458111621,
		49857576102977609660,
		19028443563221769244,
		1028665387377827156,
		520351123027890066644,
		39298240099621047809,
		191058465030654673055,
		404918443339086439082,
		548702111692901774646,
		10967581103869125050,
		155009985458062968879,
		59518317634442074908,
		88315374124162428164,
		316890944574225852464,
		265746081939443962323,
		25779060120260163211,
		63702168431564476604,
		2768315615930567552530,
		259238456209785963804,
		12546058780316286458,
		6333977108574813052,
		5491738567098025549,
		2544684234863365770845,
		5283220798875828431,
		208891932464493400759,
		414725384851618410270,
		1273560317035385686843,
		87384637607012108397,
		184723589575904530339,
		46899839335558862295,
		430509068516335587769,
		112866323506235542110,
		3070696818131195494,
		265009508817077650591,
		147209621564871174419,
		9761599912020339171,
		37120663138517729999,
		217905657847289018006,
		448807080049891158857,
		126199587284619122961,
		743492467103719049377,
		27079599991275147214,
		129706225388589930533,
		293936798307266243205,
		7312339749491493145,
		2158993190552584212,
		58616218698531219092,
		19801145131953173610,
		428704352063787723613,
		80786097349845752823,
		226822231841436609670,
		3407467281476003942,
		7218959439663110843,
		29989646616726175449,
		51337986809359966186,
		104686987188961328215,
		69579536284503082901,
		140504210147521631793,
		10299714145901151999,
		63971623489965978010,
		13698526898583272288,
		1668448090801481605979,
		383463386711518164367,
		126410152776634074118,
		63374321759658851417,
		17356396338101397293,
		104395003751047748070,
		26969943193657569867,
		244445509772279801016,
		41179521769830640483,
		286341453850954190867,
		388198022429763901570,
		1441835037178155818,
		98401209090525660608,
		138449156012110323431,
		86607401871665039987,
		5244957448855195965,
		3313472690425702237250,
		106123064531873715416,
		281539944848864244928,
		1629891431501956237417,
		1958102958183279956523,
		13852759344330274724,
		1494108890253859019,
		66892715906511441739,
		18185930765421540566,
		35950342686438860857,
		42249794331836543218,
		216535535271551601750,
		253133170211651583506,
		26129902438987128198,
		5181676800301239329,
		2096512081420268628,
		501845912305794669329,
		6244004909954886576,
		33720458773872138667,
		30318888799140618525,
		27030404494947119507,
		125763830407810082884,
		68838090752616145380,
		32722996943068455090,
		96972052792881166995,
		10552192528043252369,
		105196186951905558883,
		40933398954388193876,
		11314913144857966818,
		206148280570027155248,
		5685463868665751330,
		1260006100071554894609,
		6127797318440000086,
		6501464466451038843,
		422319481354840267910,
		39615961782546178899,
		123542029585553818722,
		1160599237203320136284,
		36529524459811784715,
		10010575570607755145,
		223892939584172712894,
		21159421340597089594,
		41164983158835495413,
		384768513841006451478,
		31442546948118604934,
		75729682543333786901,
		1941436840572722555,
		7819591823894300989,
		757985875357287581123,
		12913858790631938905,
		88741262291298104835,
		25423786312852523115,
		2915627791530296800,
		70383655687378770679,
		28933885389506911847,
		1179883805175337438,
		14174722109904877357,
		33985168910489289597,
		64739859417219359795,
		76683865809352363347,
		76695808962519916143,
		79579137226260511478,
		94112412381984012124,
		52056605276161817172,
		64768379896763077454,
		51801928493851698790,
		1249128130885456495,
		179286056833214857040,
		3153167330275967174,
		4153662592262594995,
		4126431784579703489,
		7753663982269645048,
		2509321270815287279,
		2177830208716556661,
		2650399598298142348,
		41982056729151982862,
		99805525867665851164,
		35948644203589127068,
		20331998396250592518,
		13147623830152748734,
		46495496582059188489,
		6033565848043468357,
		29577245078114619855,
		33262179870335531308,
		6907565137931052697,
		16306503974439124513,
		1686515479018078562,
		4517887492021582216,
		23469414375350074330,
		9592325917099984719,
		506238802378404082706,
		5512255039917921107,
		6732639495731051592,
		16718220586931389878,
		153213379470789830377,
		17896239593307443239,
		45859790859642579727,
		24913251066661722136,
		1648655360487910542,
		11769087506064626133,
		104302712075225999875,
		1976601654663338675,
		10726312453551016370,
		7510731799866244782,
		33334686165307388177,
		3904441631853676052,
		1740125341124139337,
		219872151618745867117,
		2378971426674631547,
		4012613632766402854
	];
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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}