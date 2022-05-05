// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './interfaces/IStakingRewards.sol';
import './interfaces/IEpochStaking.sol';
import './interfaces/IWhitelist.sol';

contract PlutusEpochStaking is IEpochStaking, Ownable, Pausable {
  IERC20 public immutable pls;
  uint32 public immutable lockDuration;

  struct StakedDetails {
    uint112 amount;
    uint32 lastCheckpoint;
  }

  struct EpochCheckpoint {
    uint32 startedAt;
    uint32 endedAt;
    uint112 totalStaked;
  }

  address public operator;
  IStakingRewards public stakingRewards;
  IWhitelist public whitelist;

  bool public stakingWindowOpen;
  uint112 public currentTotalStaked;
  uint32 public currentEpochStartedAt;
  uint32 public currentEpoch;
  mapping(address => StakedDetails) public stakedDetails;

  mapping(uint32 => EpochCheckpoint) public epochCheckpoints;
  mapping(address => mapping(uint32 => uint112)) public stakedCheckpoints;

  constructor(
    address _pls,
    address _operator,
    address _governance,
    uint32 _lockDuration
  ) {
    operator = _operator;
    lockDuration = _lockDuration;
    pls = IERC20(_pls);
    _pause();
    transferOwnership(_governance);
  }

  function stake(uint112 _amt) external onlyEligibleSender whenNotPaused whenStakingOpen {
    _stake(_amt, msg.sender);
  }

  function unstake() external onlyEligibleSender whenNotPaused whenStakingOpen {
    _unstake(msg.sender, msg.sender);
  }

  function claimRewards(uint32 _epoch) external onlyEligibleSender whenNotPaused {
    _claimRewards(_epoch, msg.sender, msg.sender);
  }

  /** MODIFIERS */
  modifier whenStakingOpen() {
    require(stakingWindowOpen, '!Open');
    _;
  }
  modifier onlyEligibleSender() {
    require(msg.sender == tx.origin || whitelist.isWhitelisted(msg.sender), '!Eligible');
    _;
  }

  modifier onlyOwnerOrOperator() {
    require(msg.sender == operator || msg.sender == owner(), '!Unauthorized');
    _;
  }

  /** INTERNAL */
  function _stake(uint112 _amt, address _user) internal {
    require(_amt > 0, '<0');

    StakedDetails storage _staked = stakedDetails[_user];

    if (_staked.lastCheckpoint != currentEpoch) {
      // Checkpoint previous epochs

      for (uint32 i = _staked.lastCheckpoint; i < currentEpoch; i++) {
        stakedCheckpoints[_user][i] = _staked.amount;
      }

      _staked.lastCheckpoint = currentEpoch;
    }

    _staked.amount += _amt;
    currentTotalStaked += _amt;

    pls.transferFrom(_user, address(this), _amt);
    emit Staked(_user, _amt, currentEpoch);
  }

  function _unstake(address _user, address _to) internal {
    require(lockDuration == 0 || currentEpoch > lockDuration - 1, 'Locked');

    StakedDetails storage _staked = stakedDetails[_user];

    uint112 deposited = _staked.amount;

    require(deposited > 0, '!Staked');

    if (_staked.lastCheckpoint != currentEpoch) {
      // Checkpoint previous epochs

      for (uint32 i = _staked.lastCheckpoint; i < currentEpoch; i++) {
        stakedCheckpoints[_user][i] = deposited;
      }

      _staked.lastCheckpoint = currentEpoch;
    }

    _staked.amount = 0;
    currentTotalStaked -= deposited;

    pls.transfer(_to, deposited);
    emit Unstaked(_user, deposited, currentEpoch);
  }

  function _claimRewards(
    uint32 _epoch,
    address _user,
    address _to
  ) internal {
    uint32 _currentEpoch = currentEpoch;
    require(_epoch < _currentEpoch, 'Epoch !Ended');

    StakedDetails storage _staked = stakedDetails[_user];
    if (_staked.lastCheckpoint != _currentEpoch) {
      // Checkpoint previous epochs

      for (uint32 i = _staked.lastCheckpoint; i < _currentEpoch; i++) {
        stakedCheckpoints[_user][i] = _staked.amount;
      }

      _staked.lastCheckpoint = _currentEpoch;
    }

    stakingRewards.claimRewardsFor(_epoch, _currentEpoch, _user, _to);

    emit ClaimedRewards(_user, _epoch);
  }

  /** OPERATOR FUNCTIONS */
  function stakeFor(uint112 _amt, address _user) external onlyOwnerOrOperator {
    _stake(_amt, _user);
  }

  function unstakeFor(address _user, address _to) external onlyOwnerOrOperator {
    _unstake(_user, _to);
  }

  function claimRewardsFor(
    uint32 _epoch,
    address _user,
    address _to
  ) external onlyOwnerOrOperator {
    _claimRewards(_epoch, _user, _to);
  }

  function advanceEpoch() external onlyOwnerOrOperator {
    epochCheckpoints[currentEpoch] = EpochCheckpoint({
      startedAt: currentEpochStartedAt,
      endedAt: uint32(block.timestamp),
      totalStaked: currentTotalStaked
    });

    currentEpoch += 1;
    currentEpochStartedAt = uint32(block.timestamp);

    if (lockDuration == 0 || currentEpoch > lockDuration - 1) {
      openStakingWindow();
    }

    emit AdvanceEpoch();
  }

  function setCurrentEpochStart(uint32 _timestamp) public onlyOwnerOrOperator {
    currentEpochStartedAt = _timestamp;
  }

  function init() external onlyOwnerOrOperator {
    setCurrentEpochStart(uint32(block.timestamp));
    _unpause();
    openStakingWindow();
  }

  function closeStakingWindow() public onlyOwnerOrOperator {
    stakingWindowOpen = false;
  }

  function openStakingWindow() public onlyOwnerOrOperator {
    stakingWindowOpen = true;
  }

  function setWhitelist(address _whitelist) external onlyOwnerOrOperator {
    whitelist = IWhitelist(_whitelist);
  }

  function pause() external onlyOwnerOrOperator {
    _pause();
  }

  function unpause() external onlyOwnerOrOperator {
    _unpause();
  }

  /** GOVERNANCE FUNCTIONS */
  function setOperator(address _operator) public onlyOwner {
    address _old = operator;
    operator = _operator;
    emit OperatorChange(_operator, _old);
  }

  function setRewards(address _stakingRewards) public onlyOwner {
    stakingRewards = IStakingRewards(_stakingRewards);
  }

  event AdvanceEpoch();
  event OperatorChange(address indexed _to, address indexed _from);
  event Staked(address indexed _from, uint112 _amt, uint32 _epoch);
  event Unstaked(address indexed _from, uint112 _amt, uint32 _epoch);
  event ClaimedRewards(address indexed _user, uint32 _epoch);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
pragma solidity 0.8.9;

interface IStakingRewards {
  function claimRewardsFor(
    uint32,
    uint32,
    address,
    address
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IEpochStaking {
  function currentEpoch() external view returns (uint32);

  function epochCheckpoints(uint32)
    external
    view
    returns (
      uint32,
      uint32,
      uint112
    );

  function stakedCheckpoints(address, uint32) external view returns (uint112);

  function advanceEpoch() external;

  function init() external;

  function setWhitelist(address) external;

  function pause() external;

  function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IWhitelist {
  function isWhitelisted(address) external view returns (bool);
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