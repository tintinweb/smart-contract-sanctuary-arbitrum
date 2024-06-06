// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC20.sol";

struct Staking {
    uint amount;
    uint rewardAmount;
    uint stakeTime;
    uint claimTime;
}

contract UnibitStakingContractv2 is Ownable {

    uint public divider;
    uint public dailyRate;
    uint public totalStaked;
    uint public currentStaked;
    address public token;
    mapping (address => Staking[]) public userStakings;

    constructor (address _token) Ownable(msg.sender) {
        dailyRate = 411;
        divider = 100000;
        token = _token;
    }

    function stake(uint _amount) external {
        require (_amount >= 100 ether, "Cannot stake less than 100 tokens.");

        IERC20(token).transferFrom(msg.sender, address(this), _amount);
        userStakings[msg.sender].push(Staking(_amount, 0, block.timestamp, 0));
        totalStaked += _amount;
        currentStaked += _amount;
    }

    function getStakingEarnings(uint _stakingId) public view returns (uint[2] memory) {
        Staking memory _staking = userStakings[msg.sender][_stakingId];
        uint claimTime = block.timestamp;
        if (_staking.claimTime > 0) {
            return [_staking.rewardAmount, _staking.claimTime];
        }
        uint difference = claimTime - _staking.stakeTime;

        uint earningsAmount;

        uint stakedDays = difference / 1 days;

        if (stakedDays > 365 days) {
            stakedDays = 365 days;
        }

        uint earnings = _staking.amount * dailyRate * stakedDays / divider;
        earningsAmount = _staking.amount + earnings;

        return [earningsAmount, claimTime];
    }

    function claimRewards(uint _stakingId) external {
        Staking memory _staking = userStakings[msg.sender][_stakingId];
        uint[2] memory _stakingEarnings = getStakingEarnings(_stakingId);

        require(_staking.claimTime == 0, "Already claimed rewards.");

        if (_stakingEarnings[0] > 0) {
            IERC20(token).transfer(msg.sender, _stakingEarnings[0]);
        }   

        _staking.rewardAmount = _stakingEarnings[0];
        _staking.claimTime = _stakingEarnings[1];

        userStakings[msg.sender][_stakingId] = _staking;
        currentStaked -= _staking.amount;
    }

    // ADMIN

    function updateDailyRate(uint _value) external onlyOwner {
        dailyRate = _value;
    }

    // USER NUMBERS

    function getTotalStakedUntilNow() external view returns (uint) {
        uint _totalStaked = 0;
        for (uint i = 0; i < userStakings[msg.sender].length; i++) {
            _totalStaked += userStakings[msg.sender][i].amount;
        }
        return _totalStaked;
    }

    function getTotalRewardsUntilNow() external view returns (uint) {
        uint _totalRewards = 0;
        for (uint i = 0; i < userStakings[msg.sender].length; i++) {
            _totalRewards += userStakings[msg.sender][i].rewardAmount;
        }
        return _totalRewards;
    }

    function getUserStakings() external view returns (Staking[] memory) {
        return userStakings[msg.sender];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20 {
    function transferFrom(
        address from, 
        address to, 
        uint256 value
    ) external returns (bool);
    function transfer(
        address to, 
        uint256 value
    ) external returns (bool);
    function balanceOf(
        address account
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (access/Ownable.sol)

pragma solidity ^0.8.20;

import {Context} from "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * The initial owner is set to the address provided by the deployer. This can
 * later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    /**
     * @dev The caller account is not authorized to perform an operation.
     */
    error OwnableUnauthorizedAccount(address account);

    /**
     * @dev The owner is not a valid owner account. (eg. `address(0)`)
     */
    error OwnableInvalidOwner(address owner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the address provided by the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
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
        if (owner() != _msgSender()) {
            revert OwnableUnauthorizedAccount(_msgSender());
        }
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
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
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
// OpenZeppelin Contracts (last updated v5.0.1) (utils/Context.sol)

pragma solidity ^0.8.20;

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

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }
}