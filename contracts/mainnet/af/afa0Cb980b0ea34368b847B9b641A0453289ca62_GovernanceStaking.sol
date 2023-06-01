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
pragma solidity 0.8.18;

import "./utils/IterableMappingBool.sol";
import "./interfaces/IGovernanceStaking.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GovernanceStaking is Ownable, IGovernanceStaking {

    using IterableMappingBool for IterableMappingBool.Map;

    uint256 public constant MAX_LOCK_PERIOD = 31_536_000; // 1 year

    IERC20 public token;

    uint256 public totalStaked;
    mapping(address => uint256) public userStaked;
    mapping(address => uint256) public lockEnd;
    mapping(address => mapping(address => uint256)) public userPaid; // user => token => amount
    mapping(address => uint256) public accRewardsPerToken;
    IterableMappingBool.Map private rewardTokens;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event RewardDistributed(address token, uint256 amount);
    event TokenWhitelisted(address token);

    constructor(IERC20 _token) {
        token = _token;
    }

    /**
     *  @notice Allows a user to stake a specified amount of tokens
     *  @param _amount The amount of tokens to be staked
     *  @param _duration The duration for which tokens will be staked
     */
    function stake(uint256 _amount, uint256 _duration) external {
        token.transferFrom(msg.sender, address(this), _amount);
        _claim(msg.sender);
        userStaked[msg.sender] += _amount;
        totalStaked = totalStaked + _amount;
        if (_duration != 0) {
            uint256 oldLockEnd = lockEnd[msg.sender];
            uint256 newLockEnd = oldLockEnd == 0 ? block.timestamp + _duration : oldLockEnd += _duration;
            require(newLockEnd <= block.timestamp + MAX_LOCK_PERIOD, "Lock period too long");
            lockEnd[msg.sender] = newLockEnd;
        }
        _updateUserPaid(msg.sender);
        emit Staked(msg.sender, _amount);
    }

    /**
     *  @notice Allows a user to unstake a specified amount of tokens
     *  @param _amount The amount of tokens to be unstaked
     */
    function unstake(uint256 _amount) external {
        require(block.timestamp >= lockEnd[msg.sender], "Locked");
        _claim(msg.sender);
        userStaked[msg.sender] -= _amount;
        totalStaked = totalStaked - _amount;
        _updateUserPaid(msg.sender);
        token.transfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount);
    }

    /**
     * @notice Allows a user to claim their rewards
     */
    function claim() external {
        _claim(msg.sender);
    }

    /**
     * @notice Distribute rewards to stakers
     * @param _token The address of the token to be distributed
     * @param _amount The amount of tokens to be distributed
     */
    function distribute(address _token, uint256 _amount) external {
        if (rewardTokens.size() == 0 || totalStaked == 0 || !rewardTokens.get(_token)) return;
        try IERC20(_token).transferFrom(msg.sender, address(this), _amount) {
            accRewardsPerToken[_token] += _amount*1e18/totalStaked;
            emit RewardDistributed(_token, _amount);
        } catch {
            return;
        }
    }

    /**
     * @notice Owner can whitelist a new token
     * @param _rewardToken The token address to be whitelisted
     */
    function whitelistReward(address _rewardToken) external onlyOwner {
        require(!rewardTokens.get(_rewardToken), "Already whitelisted");
        rewardTokens.set(_rewardToken);
        emit TokenWhitelisted(_rewardToken);
    }

    /**
     * @dev Logic for claiming rewards
     * @param _user The address that claims the rewards
     */
    function _claim(address _user) internal {
        address[] memory _tokens = rewardTokens.keys;
        uint256 _len = _tokens.length;
        for (uint256 i=0; i<_len; i++) {
            address _token = _tokens[i];
            uint256 _pending = pending(_user, _token);
            if (_pending != 0) {
                userPaid[_user][_token] += _pending;
                IERC20(_token).transfer(_user, _pending);
                emit RewardClaimed(_user, _pending);
            }
        }
    }

    /**
     * @dev Logic for updating userPaid variable for pending calculations
     * @param _user The address whose userPaid value is updated
     */
    function _updateUserPaid(address _user) internal {
        address[] memory _tokens = rewardTokens.keys;
        uint256 _len = _tokens.length;
        for (uint256 i=0; i<_len; i++) {
            address _token = _tokens[i];
            userPaid[_user][_token] = userStaked[_user] * accRewardsPerToken[_token] / 1e18;
        }
    }

    /**
     * @notice Check pending token rewards for an address
     * @param _user The address whose pending rewards are read
     * @param _token The address of the reward token
     * @return Pending token reward amount
     */
    function pending(address _user, address _token) public view returns (uint256) {
        return userStaked[_user]*accRewardsPerToken[_token]/1e18 - userPaid[_user][_token]; 
    }

    /**
     * @notice View the staked amount of an address increased by the lock duration for governance use
     * @param _user The address of whose stake is read
     * @return Weighted stake amount
     */
    function weightedStake(address _user) public view returns (uint256) {
        uint256 _compareTimestamp = block.timestamp > lockEnd[_user] ? block.timestamp : lockEnd[_user];
        return userStaked[_user] + userStaked[_user] * (_compareTimestamp - block.timestamp) / MAX_LOCK_PERIOD;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IGovernanceStaking {
    function stake(uint256 _amount, uint256 _duration) external;
    function unstake(uint256 _amount) external;
    function claim() external;
    function distribute(address _token, uint256 _amount) external;
    function whitelistReward(address _rewardToken) external;
    function pending(address _user, address _token) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library IterableMappingBool {
    // Iterable mapping from address to bool;
    struct Map {
        address[] keys;
        mapping(address => bool) values;
        mapping(address => uint) indexOf;
    }

    function get(Map storage map, address key) internal view returns (bool) {
        return map.values[key];
    }

    function getKeyAtIndex(Map storage map, uint index) internal view returns (address) {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key) internal {
        if (!map.values[key]) {
            map.values[key] = true;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) internal {
        if (map.values[key]) {
            delete map.values[key];

            uint index = map.indexOf[key];
            address lastKey = map.keys[map.keys.length - 1];

            map.indexOf[lastKey] = index;
            delete map.indexOf[key];

            map.keys[index] = lastKey;
            map.keys.pop();
        }
    }

}