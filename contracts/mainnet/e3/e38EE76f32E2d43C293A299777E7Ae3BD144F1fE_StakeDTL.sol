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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
pragma solidity ^0.8.18;

library MerkleTree {
    struct Tree {
        address[] data;
        mapping(address => uint256) index;
    }

    function insertData(Tree storage self, address staker, uint256 amount, uint256 shares) internal {
        if (self.index[staker] == 0) {
            self.data.push(staker);
            self.index[staker] = self.data.length;
        }
    }

    function removeData(Tree storage self, address staker, uint256 amount, uint256 shares) internal {
        uint256 stakerIndex = self.index[staker];
        require(stakerIndex != 0, "Staker not found");

        // If staker has no more shares, remove them from the tree
        if (shares == 0) {
            uint256 lastIndex = self.data.length - 1;
            address lastStaker = self.data[lastIndex];

            // Swap the last element with the element to remove
            self.data[stakerIndex - 1] = lastStaker;
            self.index[lastStaker] = stakerIndex;

            // Remove the last element
            self.data.pop();
            delete self.index[staker];
        }
    }

    function addressAt(Tree storage self, uint256 index) internal view returns (address) {
        require(index < self.data.length, "Index out of bounds");
        return self.data[index];
    }

    function length(Tree storage self) internal view returns (uint256) {
        return self.data.length;
    }
}

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./MerkleTree.sol";

interface Token {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract StakeDTL is Pausable, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using MerkleTree for MerkleTree.Tree;
    
    MerkleTree.Tree private stakerTree;

    Token dtlToken;
    Token rewardToken;

    uint256[3] public lockPeriods = [7 * 86400, 30 * 86400, 90 * 86400];
    uint256[3] public sharesPerToken = [20, 15, 10];

    uint256 public totalShares;
    uint256 public totalRewards;
    uint256 public totalStakers;
    uint256 public lastRewardDistribution;
    uint256 public rewardPercentage = 5;
    uint256 private constant PRECISION = 10**18;


    struct StakeInfo {
        uint256 startTS;
        uint256 endTS;
        uint256 amount;
        uint256 shares;
        uint8 lockPeriodIndex;
    }

   
    event Staked(address indexed from, uint256 amount, uint8 lockPeriodIndex);
    event Claimed(address indexed from, uint256 amount);

    mapping(address => StakeInfo[]) public stakeInfos;
    mapping(address => uint256) public userTotalShares;
    mapping(address => uint256) public unclaimedRewards;   
    mapping(address => uint256) public claimedRewards;
  



    constructor(Token _dtlTokenAddress, Token _rewardTokenAddress) {
        require(address(_dtlTokenAddress) != address(0), "DTL Token Address cannot be address 0");
        require(address(_rewardTokenAddress) != address(0), "Reward Token Address cannot be address 0");

        dtlToken = _dtlTokenAddress;
        rewardToken = _rewardTokenAddress;

        totalShares = 0;
        totalRewards = 0;
        lastRewardDistribution = block.timestamp;
    
    }


    function addReward(uint256 amount) external onlyOwner {
        require(rewardToken.transferFrom(_msgSender(), address(this), amount), "Token transfer failed!");
        totalRewards += amount;
    }
    


function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "division by zero");
    return a.mul(PRECISION).add(b.sub(1)).div(b); // Support precision
}



  
 function distributeRewards() internal {
    if (totalStakers == 0) {
        return;
    }

    require(totalShares > 0, "No shares available");

    uint256 elapsedTime = block.timestamp.sub(lastRewardDistribution);

    if (elapsedTime > 0) {
        // Calculate rewardsToDistribute based on the rewardPercentage of the total rewards
        uint256 rewardsForTwentyFourHours = totalRewards.mul(rewardPercentage).div(100);
        uint256 rewardsToDistribute = divCeil(rewardsForTwentyFourHours.mul(elapsedTime), 86400).div(PRECISION); // Proportional to the elapsed time, rounded up and divided by PRECISION

        require(rewardToken.balanceOf(address(this)) >= rewardsToDistribute, "Insufficient reward token balance");

        uint256 rewardsPerShare = divCeil(rewardsToDistribute, totalShares); // Round up to avoid decimals

        totalRewards = totalRewards.sub(rewardsToDistribute);
        lastRewardDistribution = block.timestamp;

        for (uint256 i = 0; i < totalStakers; i++) {
            address staker = stakerTree.addressAt(i);
            uint256 stakerShares = userTotalShares[staker];

            // Check if stake time is expired for any stake instances of the staker
            bool stakeTimeExpired = false;
            for (uint256 j = 0; j < stakeInfos[staker].length; j++) {
                if (stakeInfos[staker][j].endTS < lastRewardDistribution) {
                    stakeTimeExpired = true;
                    break;
                }
            }

            // If stake time is not expired, distribute rewards
            if (!stakeTimeExpired) {
                uint256 stakerReward = stakerShares.mul(rewardsPerShare).div(PRECISION); // Divide by PRECISION to get the original scale
                unclaimedRewards[staker] = unclaimedRewards[staker].add(stakerReward);
            }
        }
    }
}

        
    function claimAllRewards() external nonReentrant {
                distributeRewards();
              

        uint256 stakerUnclaimedRewards = unclaimedRewards[_msgSender()];
        require(stakerUnclaimedRewards > 0, "No unclaimed rewards");
        require(rewardToken.transfer(_msgSender(), stakerUnclaimedRewards), "Token transfer failed!");
        claimedRewards[_msgSender()] += stakerUnclaimedRewards;

        unclaimedRewards[_msgSender()] = 0;
        emit Claimed(_msgSender(), stakerUnclaimedRewards);
    }

 


    function stakeToken(uint256 stakeAmount, uint8 lockPeriodIndex) external whenNotPaused nonReentrant {
         distributeRewards();
        require(stakeAmount > 0, "Stake amount should be correct");
        require(lockPeriodIndex < lockPeriods.length, "Invalid lock period");
        require(dtlToken.balanceOf(_msgSender()) >= stakeAmount, "Insufficient Balance");
        require(dtlToken.transferFrom(_msgSender(), address(this), stakeAmount), "Token transfer failed!");

        uint256 shares = stakeAmount / sharesPerToken[lockPeriodIndex];
        totalShares += shares;
        userTotalShares[_msgSender()] += shares;

        stakeInfos[_msgSender()].push(StakeInfo({
            startTS: block.timestamp,
            endTS: block.timestamp + lockPeriods[lockPeriodIndex],
            amount: stakeAmount,
            shares: shares,
            lockPeriodIndex: lockPeriodIndex
        }));

        stakerTree.insertData(_msgSender(), stakeAmount, shares);  // Update totalStakers if necessary
        if (userTotalShares[_msgSender()] == shares) {
            totalStakers += 1;
        }



        emit Staked(_msgSender(), stakeAmount, lockPeriodIndex);
    }

    function unstake(uint256 stakeIndex) external nonReentrant {
        distributeRewards();

        require(stakeInfos[_msgSender()].length > stakeIndex, "Invalid stake index");
        require(stakeInfos[_msgSender()][stakeIndex].endTS < block.timestamp, "Stake Time is not over yet");

        uint256 stakeAmount = stakeInfos[_msgSender()][stakeIndex].amount;
        uint256 stakeShares = stakeInfos[_msgSender()][stakeIndex].shares;

        require(dtlToken.transfer(_msgSender(), stakeAmount), "Token transfer failed!");

        totalShares -= stakeShares;
        userTotalShares[_msgSender()] -= stakeShares;

        // Remove the stake instance from the stakeInfos mapping
        delete stakeInfos[_msgSender()][stakeIndex];

        // If no stake instances left for the user, remove the user's data from the MerkleTree
        if (stakeInfos[_msgSender()].length == 0) {
            stakerTree.removeData(_msgSender(), stakeAmount, stakeShares);
            // Update totalStakers if necessary
            if (userTotalShares[_msgSender()] == 0) {
                totalStakers -= 1;
            }
        }

         // Automatically claim all unclaimed rewards after unstaking
        uint256 stakerUnclaimedRewards = unclaimedRewards[_msgSender()];
        if (stakerUnclaimedRewards > 0) {
            require(rewardToken.transfer(_msgSender(), stakerUnclaimedRewards), "Token transfer failed!");
            claimedRewards[_msgSender()] += stakerUnclaimedRewards;

            unclaimedRewards[_msgSender()] = 0;
            emit Claimed(_msgSender(), stakerUnclaimedRewards);
        }

    
    }

    function getStakeInstances(address user) external view returns (StakeInfo[] memory) {
        return stakeInfos[user];
    }

    function getTokenExpiry(uint256 stakeIndex) external view returns (uint256) {
        require(stakeInfos[_msgSender()].length > stakeIndex, "Invalid stake index");
        return stakeInfos[_msgSender()][stakeIndex].endTS;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getClaimedRewards(address user) external view returns (uint256) {
        return claimedRewards[user];
    }

    function distributeRewardsPublic() external onlyOwner {
    distributeRewards();
    }
 
    function setRewardPercentage(uint256 newRewardPercentage) external onlyOwner {
        require(newRewardPercentage > 0 && newRewardPercentage <= 100, "Reward percentage must be between 1 and 100");
        rewardPercentage = newRewardPercentage;
    }


    function emergencyWithdraw(uint256 amount) external onlyOwner {
        require(amount > 0, "Withdrawal amount must be greater than zero");
        require(rewardToken.balanceOf(address(this)) >= amount, "Insufficient reward token balance");

        require(rewardToken.transfer(owner(), amount), "Token transfer failed!");
        emit EmergencyWithdraw(owner(), amount);
    }

    event EmergencyWithdraw(address indexed to, uint256 amount);
}