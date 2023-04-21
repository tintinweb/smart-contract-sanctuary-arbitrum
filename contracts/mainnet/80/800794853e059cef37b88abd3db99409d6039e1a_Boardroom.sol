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

contract ContractGuard {
  mapping(uint256 => mapping(address => bool)) private _status;

  function checkSameOriginReentranted() internal view returns (bool) {
    return _status[block.number][tx.origin];
  }

  function checkSameSenderReentranted() internal view returns (bool) {
    return _status[block.number][msg.sender];
  }

  modifier onlyOneBlock() {
    require(!checkSameOriginReentranted(), 'ContractGuard: one block, one function');
    require(!checkSameSenderReentranted(), 'ContractGuard: one block, one function');

    _;

    _status[block.number][tx.origin] = true;
    _status[block.number][msg.sender] = true;
  }
}

interface IBasisAsset {
  function mint(address recipient, uint256 amount) external returns (bool);

  function burn(uint256 amount) external;

  function burnFrom(address from, uint256 amount) external;

  function isOperator() external returns (bool);

  function operator() external view returns (address);

  function transferOperator(address newOperator_) external;
}

interface ITreasury {
  function epoch() external view returns (uint256);

  function nextEpochPoint() external view returns (uint256);

  function getSkyPrice() external view returns (uint256);

  function buyBonds(uint256 amount, uint256 targetPrice) external;

  function redeemBonds(uint256 amount, uint256 targetPrice) external;
}

contract ShareWrapper {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  IERC20 public sshare;

  uint256 private _totalSupply;
  mapping(address => uint256) private _balances;

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

  function stake(uint256 amount) public virtual {
    _totalSupply = _totalSupply.add(amount);
    _balances[msg.sender] = _balances[msg.sender].add(amount);
    sshare.safeTransferFrom(msg.sender, address(this), amount);
  }

  function withdraw(uint256 amount) public virtual {
    uint256 memberShare = _balances[msg.sender];
    require(memberShare >= amount, 'Boardroom: withdraw request greater than staked amount');
    _totalSupply = _totalSupply.sub(amount);
    _balances[msg.sender] = memberShare.sub(amount);
    sshare.safeTransfer(msg.sender, amount);
  }
}

contract Boardroom is ShareWrapper, ContractGuard {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  /* ========== DATA STRUCTURES ========== */

  struct Memberseat {
    uint256 lastSnapshotIndex;
    uint256 rewardEarned;
    uint256 epochTimerStart;
  }

  struct BoardroomSnapshot {
    uint256 time;
    uint256 rewardReceived;
    uint256 rewardPerShare;
  }

  /* ========== STATE VARIABLES ========== */

  // governance
  address public operator;

  // flags
  bool public initialized = false;

  IERC20 public sky;
  ITreasury public treasury;

  mapping(address => Memberseat) public members;
  BoardroomSnapshot[] public boardroomHistory;

  uint256 public withdrawLockupEpochs;
  uint256 public rewardLockupEpochs;

  /* ========== EVENTS ========== */

  event Initialized(address indexed executor, uint256 at);
  event Staked(address indexed user, uint256 amount);
  event Withdrawn(address indexed user, uint256 amount);
  event RewardPaid(address indexed user, uint256 reward);
  event RewardAdded(address indexed user, uint256 reward);

  /* ========== Modifiers =============== */

  modifier onlyOperator() {
    require(operator == msg.sender, 'Boardroom: caller is not the operator');
    _;
  }

  modifier memberExists() {
    require(balanceOf(msg.sender) > 0, 'Boardroom: The member does not exist');
    _;
  }

  modifier updateReward(address member) {
    if (member != address(0)) {
      Memberseat memory seat = members[member];
      seat.rewardEarned = earned(member);
      seat.lastSnapshotIndex = latestSnapshotIndex();
      members[member] = seat;
    }
    _;
  }

  modifier notInitialized() {
    require(!initialized, 'Boardroom: already initialized');
    _;
  }

  /* ========== GOVERNANCE ========== */

  function initialize(IERC20 _sky, IERC20 _sshare, ITreasury _treasury) public notInitialized {
    sky = _sky;
    sshare = _sshare;
    treasury = _treasury;

    BoardroomSnapshot memory genesisSnapshot = BoardroomSnapshot({
      time: block.number,
      rewardReceived: 0,
      rewardPerShare: 0
    });
    boardroomHistory.push(genesisSnapshot);

    withdrawLockupEpochs = 6; // Lock for 6 epochs (36h) before release withdraw
    rewardLockupEpochs = 3; // Lock for 3 epochs (18h) before release claimReward

    initialized = true;
    operator = msg.sender;
    emit Initialized(msg.sender, block.number);
  }

  function setOperator(address _operator) external onlyOperator {
    operator = _operator;
  }

  function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external onlyOperator {
    require(
      _withdrawLockupEpochs >= _rewardLockupEpochs && _withdrawLockupEpochs <= 56,
      '_withdrawLockupEpochs: out of range'
    ); // <= 2 week
    withdrawLockupEpochs = _withdrawLockupEpochs;
    rewardLockupEpochs = _rewardLockupEpochs;
  }

  /* ========== VIEW FUNCTIONS ========== */

  // =========== Snapshot getters

  function latestSnapshotIndex() public view returns (uint256) {
    return boardroomHistory.length.sub(1);
  }

  function getLatestSnapshot() internal view returns (BoardroomSnapshot memory) {
    return boardroomHistory[latestSnapshotIndex()];
  }

  function getLastSnapshotIndexOf(address member) public view returns (uint256) {
    return members[member].lastSnapshotIndex;
  }

  function getLastSnapshotOf(address member) internal view returns (BoardroomSnapshot memory) {
    return boardroomHistory[getLastSnapshotIndexOf(member)];
  }

  function canWithdraw(address member) external view returns (bool) {
    return members[member].epochTimerStart.add(withdrawLockupEpochs) <= treasury.epoch();
  }

  function canClaimReward(address member) external view returns (bool) {
    return members[member].epochTimerStart.add(rewardLockupEpochs) <= treasury.epoch();
  }

  function epoch() external view returns (uint256) {
    return treasury.epoch();
  }

  function nextEpochPoint() external view returns (uint256) {
    return treasury.nextEpochPoint();
  }

  function getSkyPrice() external view returns (uint256) {
    return treasury.getSkyPrice();
  }

  // =========== Member getters

  function rewardPerShare() public view returns (uint256) {
    return getLatestSnapshot().rewardPerShare;
  }

  function earned(address member) public view returns (uint256) {
    uint256 latestRPS = getLatestSnapshot().rewardPerShare;
    uint256 storedRPS = getLastSnapshotOf(member).rewardPerShare;

    return balanceOf(member).mul(latestRPS.sub(storedRPS)).div(1e18).add(members[member].rewardEarned);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  function stake(uint256 amount) public override onlyOneBlock updateReward(msg.sender) {
    require(amount > 0, 'Boardroom: Cannot stake 0');
    super.stake(amount);
    members[msg.sender].epochTimerStart = treasury.epoch(); // reset timer
    emit Staked(msg.sender, amount);
  }

  function withdraw(uint256 amount) public override onlyOneBlock memberExists updateReward(msg.sender) {
    require(amount > 0, 'Boardroom: Cannot withdraw 0');
    require(
      members[msg.sender].epochTimerStart.add(withdrawLockupEpochs) <= treasury.epoch(),
      'Boardroom: still in withdraw lockup'
    );
    claimReward();
    super.withdraw(amount);
    emit Withdrawn(msg.sender, amount);
  }

  function exit() external {
    withdraw(balanceOf(msg.sender));
  }

  function claimReward() public updateReward(msg.sender) {
    uint256 reward = members[msg.sender].rewardEarned;
    if (reward > 0) {
      require(
        members[msg.sender].epochTimerStart.add(rewardLockupEpochs) <= treasury.epoch(),
        'Boardroom: still in reward lockup'
      );
      members[msg.sender].epochTimerStart = treasury.epoch(); // reset timer
      members[msg.sender].rewardEarned = 0;
      sky.safeTransfer(msg.sender, reward);
      emit RewardPaid(msg.sender, reward);
    }
  }

  function allocateSeigniorage(uint256 amount) external onlyOneBlock onlyOperator {
    require(amount > 0, 'Boardroom: Cannot allocate 0');
    require(totalSupply() > 0, 'Boardroom: Cannot allocate when totalSupply is 0');

    // Create & add new snapshot
    uint256 prevRPS = getLatestSnapshot().rewardPerShare;
    uint256 nextRPS = prevRPS.add(amount.mul(1e18).div(totalSupply()));

    BoardroomSnapshot memory newSnapshot = BoardroomSnapshot({
      time: block.number,
      rewardReceived: amount,
      rewardPerShare: nextRPS
    });
    boardroomHistory.push(newSnapshot);

    sky.safeTransferFrom(msg.sender, address(this), amount);
    emit RewardAdded(msg.sender, amount);
  }

  function governanceRecoverUnsupported(IERC20 _token, uint256 _amount, address _to) external onlyOperator {
    // do not allow to drain core tokens
    require(address(_token) != address(sky), 'sky');
    require(address(_token) != address(sshare), 'sshare');
    _token.safeTransfer(_to, _amount);
  }
}