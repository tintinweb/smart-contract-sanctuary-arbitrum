/**
 *Submitted for verification at Arbiscan on 2023-04-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    uint256 c = a + b;
    if (c < a) return (false, 0);
    return (true, c);
  }

  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b > a) return (false, 0);
    return (true, a - b);
  }

  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (a == 0) return (true, 0);
    uint256 c = a * b;
    if (c / a != b) return (false, 0);
    return (true, c);
  }

  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a / b);
  }

  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a % b);
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath: subtraction overflow');
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, 'SafeMath: division by zero');
    return a / b;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, 'SafeMath: modulo by zero');
    return a % b;
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    return a - b;
  }

  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a / b;
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a % b;
  }
}

library Address {
  function isContract(address account) internal view returns (bool) {

    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, 'Address: insufficient balance');
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }

  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, 'Address: low-level call failed');
  }

  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    return functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, 'Address: insufficient balance for call');
    require(isContract(target), 'Address: call to non-contract');
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
    return functionStaticCall(target, data, 'Address: low-level static call failed');
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), 'Address: static call to non-contract');
    (bool success, bytes memory returndata) = target.staticcall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), 'Address: delegate call to non-contract');

    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
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

library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(IERC20 token, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(IERC20 token, address spender, uint256 value) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(
      value,
      'SafeERC20: decreased allowance below zero'
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {

    bytes memory returndata = address(token).functionCall(data, 'SafeERC20: low-level call failed');
    if (returndata.length > 0) {
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}

// Note that this pool has no minter key of SKY (rewards).
// Instead, the governance will call SKY distributeReward method and send reward to this pool at the beginning.
contract SkyGenesisRewardPool {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // governance
  address public operator;

  // Info of each user.
  struct UserInfo {
    uint256 amount; // How many tokens the user has provided.
    uint256 rewardDebt; // Reward debt. See explanation below.
  }

  // Info of each pool.
  struct PoolInfo {
    IERC20 token; // Address of LP token contract.
    uint256 allocPoint; // How many allocation points assigned to this pool. SKY to distribute.
    uint256 lastRewardTime; // Last time that SKY distribution occurs.
    uint256 accSkyPerShare; // Accumulated SKY per share, times 1e18. See below.
    bool isStarted; // if lastRewardBlock has passed
    uint256 depositFee; // Deposit fee.
  }

  IERC20 public sky;

  // Info of each pool.
  PoolInfo[] public poolInfo;

  // Info of each user that stakes LP tokens.
  mapping(uint256 => mapping(address => UserInfo)) public userInfo;

  // Total allocation points. Must be the sum of all allocation points in all pools.
  uint256 public totalAllocPoint = 0;

  // The time when SKY mining starts.
  uint256 public poolStartTime;

  // The time when SKY mining ends.
  uint256 public poolEndTime;

  uint256 public skyPerSecond = 0.11574074074 ether; // 20000 SKY / (2 day * 24h * 60min * 60s)
  uint256 public runningTime = 2 days; // 2 days
  uint256 public constant TOTAL_REWARDS = 20000 ether;

  address public feeWallet;

  event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
  event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
  event RewardPaid(address indexed user, uint256 amount);

  constructor(address _sky, uint256 _poolStartTime) public {
    require(block.timestamp < _poolStartTime, 'late');
    if (_sky != address(0)) sky = IERC20(_sky);
    poolStartTime = _poolStartTime;
    poolEndTime = poolStartTime + runningTime;
    operator = msg.sender;
    feeWallet = msg.sender;
  }

  modifier onlyOperator() {
    require(operator == msg.sender, 'SkyGenesisPool: caller is not the operator');
    _;
  }

  function checkPoolDuplicate(IERC20 _token) internal view {
    uint256 length = poolInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      require(poolInfo[pid].token != _token, 'SkyGenesisPool: existing pool?');
    }
  }

  // Add a new token to the pool. Can only be called by the owner.
  function add(uint256 _allocPoint, IERC20 _token, bool _withUpdate, uint256 _lastRewardTime, uint256 _depositFee) public onlyOperator {
    checkPoolDuplicate(_token);
    if (_withUpdate) {
      massUpdatePools();
    }
    if (block.timestamp < poolStartTime) {
      // chef is sleeping
      if (_lastRewardTime == 0) {
        _lastRewardTime = poolStartTime;
      } else {
        if (_lastRewardTime < poolStartTime) {
          _lastRewardTime = poolStartTime;
        }
      }
    } else {
      // chef is cooking
      if (_lastRewardTime == 0 || _lastRewardTime < block.timestamp) {
        _lastRewardTime = block.timestamp;
      }
    }
    bool _isStarted = (_lastRewardTime <= poolStartTime) || (_lastRewardTime <= block.timestamp);
    require(_depositFee <= 10, 'Maximum deposit fee is 1%');
    poolInfo.push(
      PoolInfo({
        token: _token,
        allocPoint: _allocPoint,
        lastRewardTime: _lastRewardTime,
        accSkyPerShare: 0,
        isStarted: _isStarted,
        depositFee: _depositFee
      })
    );
    if (_isStarted) {
      totalAllocPoint = totalAllocPoint.add(_allocPoint);
    }
  }

  // Update the given pool's SKY allocation point. Can only be called by the owner.
  function set(uint256 _pid, uint256 _allocPoint) public onlyOperator {
    massUpdatePools();
    PoolInfo storage pool = poolInfo[_pid];
    if (pool.isStarted) {
      totalAllocPoint = totalAllocPoint.sub(pool.allocPoint).add(_allocPoint);
    }
    pool.allocPoint = _allocPoint;
  }

  // Return accumulate rewards over the given _from to _to block.
  function getGeneratedReward(uint256 _fromTime, uint256 _toTime) public view returns (uint256) {
    if (_fromTime >= _toTime) return 0;
    if (_toTime >= poolEndTime) {
      if (_fromTime >= poolEndTime) return 0;
      if (_fromTime <= poolStartTime) return poolEndTime.sub(poolStartTime).mul(skyPerSecond);
      return poolEndTime.sub(_fromTime).mul(skyPerSecond);
    } else {
      if (_toTime <= poolStartTime) return 0;
      if (_fromTime <= poolStartTime) return _toTime.sub(poolStartTime).mul(skyPerSecond);
      return _toTime.sub(_fromTime).mul(skyPerSecond);
    }
  }

  // View function to see pending SKY on frontend.
  function pendingSky(uint256 _pid, address _user) external view returns (uint256) {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_user];
    uint256 accSkyPerShare = pool.accSkyPerShare;
    uint256 tokenSupply = pool.token.balanceOf(address(this));
    if (block.timestamp > pool.lastRewardTime && tokenSupply != 0) {
      uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
      uint256 _skyReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
      accSkyPerShare = accSkyPerShare.add(_skyReward.mul(1e18).div(tokenSupply));
    }
    return user.amount.mul(accSkyPerShare).div(1e18).sub(user.rewardDebt);
  }

  // Update reward variables for all pools. Be careful of gas spending!
  function massUpdatePools() public {
    uint256 length = poolInfo.length;
    for (uint256 pid = 0; pid < length; ++pid) {
      updatePool(pid);
    }
  }

  // Update reward variables of the given pool to be up-to-date.
  function updatePool(uint256 _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    if (block.timestamp <= pool.lastRewardTime) {
      return;
    }
    uint256 tokenSupply = pool.token.balanceOf(address(this));
    if (tokenSupply == 0) {
      pool.lastRewardTime = block.timestamp;
      return;
    }
    if (!pool.isStarted) {
      pool.isStarted = true;
      totalAllocPoint = totalAllocPoint.add(pool.allocPoint);
    }
    if (totalAllocPoint > 0) {
      uint256 _generatedReward = getGeneratedReward(pool.lastRewardTime, block.timestamp);
      uint256 _skyReward = _generatedReward.mul(pool.allocPoint).div(totalAllocPoint);
      pool.accSkyPerShare = pool.accSkyPerShare.add(_skyReward.mul(1e18).div(tokenSupply));
    }
    pool.lastRewardTime = block.timestamp;
  }

  // Deposit LP tokens.
  function deposit(uint256 _pid, uint256 _amount) public {
    address _sender = msg.sender;
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_sender];
    updatePool(_pid);
    if (user.amount > 0) {
      uint256 _pending = user.amount.mul(pool.accSkyPerShare).div(1e18).sub(user.rewardDebt);
      if (_pending > 0) {
        safeSkyTransfer(_sender, _pending);
        emit RewardPaid(_sender, _pending);
      }
    }
    if (_amount > 0) {
      pool.token.safeTransferFrom(_sender, address(this), _amount);
      uint256 fee = _amount.mul(pool.depositFee).div(1000);
      pool.token.safeTransfer(feeWallet, fee);
      user.amount = user.amount.add(_amount.sub(fee));
    }
    user.rewardDebt = user.amount.mul(pool.accSkyPerShare).div(1e18);
    emit Deposit(_sender, _pid, _amount);
  }

  // Withdraw LP tokens.
  function withdraw(uint256 _pid, uint256 _amount) public {
    address _sender = msg.sender;
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][_sender];
    require(user.amount >= _amount, 'withdraw: not good');
    updatePool(_pid);
    uint256 _pending = user.amount.mul(pool.accSkyPerShare).div(1e18).sub(user.rewardDebt);
    if (_pending > 0) {
      safeSkyTransfer(_sender, _pending);
      emit RewardPaid(_sender, _pending);
    }
    if (_amount > 0) {
      user.amount = user.amount.sub(_amount);
      pool.token.safeTransfer(_sender, _amount);
    }
    user.rewardDebt = user.amount.mul(pool.accSkyPerShare).div(1e18);
    emit Withdraw(_sender, _pid, _amount);
  }

  // Withdraw without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw(uint256 _pid) public {
    PoolInfo storage pool = poolInfo[_pid];
    UserInfo storage user = userInfo[_pid][msg.sender];
    uint256 _amount = user.amount;
    user.amount = 0;
    user.rewardDebt = 0;
    pool.token.safeTransfer(msg.sender, _amount);
    emit EmergencyWithdraw(msg.sender, _pid, _amount);
  }

  // Safe SKY transfer function, just in case if rounding error causes pool to not have enough SKY.
  function safeSkyTransfer(address _to, uint256 _amount) internal {
    uint256 _skyBalance = sky.balanceOf(address(this));
    if (_skyBalance > 0) {
      if (_amount > _skyBalance) {
        sky.safeTransfer(_to, _skyBalance);
      } else {
        sky.safeTransfer(_to, _amount);
      }
    }
  }

  function setOperator(address _operator) external onlyOperator {
    operator = _operator;
  }

  function setFeeWallet(address _feeWallet) external onlyOperator {
    require(msg.sender == feeWallet, '!dev');
    require(_feeWallet != address(0), 'zero');
    feeWallet = _feeWallet;
  }
}