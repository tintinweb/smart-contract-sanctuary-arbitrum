// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import { IRewardsDistro } from './PlsJonesRewardsDistro.sol';
import { IWhitelist } from '../Whitelist.sol';

/**
  Assumptions:
  Total stake: <= 309_485_009 * 1e18 tokens
  Individual stake: <= 309_485_009 * 1e18 tokens
  DPX max supply: 5e23
  JONES max siupply: 1e25
  PLS max supply: 1e26
 */
contract PlsJonesPlutusChef is Ownable {
  uint256 private constant MUL_CONSTANT = 1e14;
  IRewardsDistro public immutable rewardsDistro;
  IERC20 public immutable plsJones;

  // Info of each user.
  struct UserInfo {
    uint96 amount; // Staking tokens the user has provided
    int128 plsRewardDebt;
    int128 plsDpxRewardDebt;
    int128 plsJonesRewardDebt;
    int128 jonesRewardDebt;
  }

  IWhitelist public whitelist;
  address public operator;

  uint128 public accPlsPerShare;
  uint96 private shares; // total staked
  uint32 public lastRewardSecond;

  // Treasury
  uint128 public accPlsDpxPerShare;
  uint128 public accPlsJonesPerShare;

  // Farm
  uint128 public accJonesPerShare;

  mapping(address => UserInfo) public userInfo;

  constructor(address _rewardsDistro, address _plsJones) {
    rewardsDistro = IRewardsDistro(_rewardsDistro);
    plsJones = IERC20(_plsJones);
  }

  function deposit(uint96 _amount) external {
    _isEligibleSender();
    _deposit(msg.sender, _amount);
  }

  function withdraw(uint96 _amount) external {
    _isEligibleSender();
    _withdraw(msg.sender, _amount);
  }

  function harvest() external {
    _isEligibleSender();
    _harvest(msg.sender);
  }

  /**
   * Withdraw without caring about rewards. EMERGENCY ONLY.
   */
  function emergencyWithdraw() external {
    _isEligibleSender();
    UserInfo storage user = userInfo[msg.sender];

    uint96 _amount = user.amount;

    user.amount = 0;
    user.plsRewardDebt = 0;

    if (shares >= _amount) {
      shares -= _amount;
    } else {
      shares = 0;
    }

    plsJones.transfer(msg.sender, _amount);
    emit EmergencyWithdraw(msg.sender, _amount);
  }

  /**
    Keep reward variables up to date. Ran before every mutative function.
   */
  function updateShares() public {
    // if block.timestamp <= lastRewardSecond, already updated.
    if (block.timestamp <= lastRewardSecond) {
      return;
    }

    // if pool has no supply
    if (shares == 0) {
      lastRewardSecond = uint32(block.timestamp);
      return;
    }

    (uint80 pls_, uint80 plsDpx_, uint80 plsJones_, uint80 pendingJonesLessFee_) = rewardsDistro.updateInfo();

    unchecked {
      accPlsPerShare += rewardPerShare(pls_);
      accPlsDpxPerShare += rewardPerShare(plsDpx_);
      accPlsJonesPerShare += rewardPerShare(plsJones_);

      accJonesPerShare += uint128((pendingJonesLessFee_ * MUL_CONSTANT) / shares);
    }

    rewardsDistro.harvestFromUnderlyingFarm();
    lastRewardSecond = uint32(block.timestamp);
  }

  /** OPERATOR */
  function depositFor(address _user, uint88 _amount) external {
    if (msg.sender != operator) revert UNAUTHORIZED();
    _deposit(_user, _amount);
  }

  function withdrawFor(address _user, uint88 _amount) external {
    if (msg.sender != operator) revert UNAUTHORIZED();
    _withdraw(_user, _amount);
  }

  function harvestFor(address _user) external {
    if (msg.sender != operator) revert UNAUTHORIZED();
    _harvest(_user);
  }

  /** VIEWS */

  /**
    Calculates the reward per share since `lastRewardSecond` was updated
  */
  function rewardPerShare(uint80 _rewardRatePerSecond) public view returns (uint128) {
    // duration = block.timestamp - lastRewardSecond;
    // tokenReward = duration * _rewardRatePerSecond;
    // tokenRewardPerShare = (tokenReward * MUL_CONSTANT) / shares;

    unchecked {
      return uint128(((block.timestamp - lastRewardSecond) * uint256(_rewardRatePerSecond) * MUL_CONSTANT) / shares);
    }
  }

  /**
    View function to see pending rewards on frontend
   */
  function pendingRewards(address _user)
    external
    view
    returns (
      uint256 _pendingPls,
      uint256 _pendingPlsDpx,
      uint256 _pendingPlsJones,
      uint256 _pendingJones
    )
  {
    uint256 _accPlsPerShare = accPlsPerShare;
    uint256 _accPlsDpxPerShare = accPlsDpxPerShare;
    uint256 _accPlsJonesPerShare = accPlsJonesPerShare;
    uint256 _accJonesPerShare = accJonesPerShare;

    (uint80 pls_, uint80 plsDpx_, uint80 plsJones_, uint80 pendingJonesLessFee_) = rewardsDistro.updateInfo();

    if (block.timestamp > lastRewardSecond && shares != 0) {
      _accPlsPerShare += rewardPerShare(pls_);
      _accPlsDpxPerShare += rewardPerShare(plsDpx_);
      _accPlsJonesPerShare += rewardPerShare(plsJones_);

      _accJonesPerShare += uint256((pendingJonesLessFee_ * MUL_CONSTANT) / shares);
    }

    UserInfo memory user = userInfo[_user];

    _pendingPls = _calculatePending(user.plsRewardDebt, _accPlsPerShare, user.amount);
    _pendingPlsDpx = _calculatePending(user.plsDpxRewardDebt, _accPlsDpxPerShare, user.amount);
    _pendingPlsJones = _calculatePending(user.plsJonesRewardDebt, _accPlsJonesPerShare, user.amount);
    _pendingJones = _calculatePending(user.jonesRewardDebt, _accJonesPerShare, user.amount);
  }

  /** PRIVATE */
  function _isEligibleSender() private view {
    if (msg.sender != tx.origin && whitelist.isWhitelisted(msg.sender) == false) revert UNAUTHORIZED();
  }

  function _calculatePending(
    int128 _rewardDebt,
    uint256 _accPerShare, // Stay 256;
    uint96 _amount
  ) private pure returns (uint128) {
    if (_rewardDebt < 0) {
      return uint128(_calculateRewardDebt(_accPerShare, _amount)) + uint128(-_rewardDebt);
    } else {
      return uint128(_calculateRewardDebt(_accPerShare, _amount)) - uint128(_rewardDebt);
    }
  }

  function _calculateRewardDebt(uint256 _accPlsPerShare, uint96 _amount) private pure returns (uint256) {
    unchecked {
      return (_amount * _accPlsPerShare) / MUL_CONSTANT;
    }
  }

  function _deposit(address _user, uint96 _amount) private {
    UserInfo storage user = userInfo[_user];
    if (_amount == 0) revert DEPOSIT_ERROR();
    updateShares();

    uint256 _prev = plsJones.balanceOf(address(this));

    unchecked {
      user.amount += _amount;
      shares += _amount;
    }

    user.plsRewardDebt = user.plsRewardDebt + int128(uint128(_calculateRewardDebt(accPlsPerShare, _amount)));

    user.plsDpxRewardDebt = user.plsDpxRewardDebt + int128(uint128(_calculateRewardDebt(accPlsDpxPerShare, _amount)));

    user.plsJonesRewardDebt =
      user.plsJonesRewardDebt +
      int128(uint128(_calculateRewardDebt(accPlsJonesPerShare, _amount)));

    user.jonesRewardDebt = user.jonesRewardDebt + int128(uint128(_calculateRewardDebt(accJonesPerShare, _amount)));

    plsJones.transferFrom(_user, address(this), _amount);

    unchecked {
      if (_prev + _amount != plsJones.balanceOf(address(this))) revert DEPOSIT_ERROR();
    }

    emit Deposit(_user, _amount);
  }

  function _withdraw(address _user, uint96 _amount) private {
    UserInfo storage user = userInfo[_user];
    if (user.amount < _amount || _amount == 0) revert WITHDRAW_ERROR();
    updateShares();

    unchecked {
      user.amount -= _amount;
      shares -= _amount;
    }

    user.plsRewardDebt = user.plsRewardDebt - int128(uint128(_calculateRewardDebt(accPlsPerShare, _amount)));

    user.plsDpxRewardDebt = user.plsDpxRewardDebt - int128(uint128(_calculateRewardDebt(accPlsDpxPerShare, _amount)));

    user.plsJonesRewardDebt =
      user.plsJonesRewardDebt -
      int128(uint128(_calculateRewardDebt(accPlsJonesPerShare, _amount)));

    user.jonesRewardDebt = user.jonesRewardDebt - int128(uint128(_calculateRewardDebt(accJonesPerShare, _amount)));

    plsJones.transfer(_user, _amount);
    emit Withdraw(_user, _amount);
  }

  function _harvest(address _user) private {
    updateShares();
    UserInfo storage user = userInfo[_user];

    uint128 plsPending = _calculatePending(user.plsRewardDebt, accPlsPerShare, user.amount);

    uint128 plsDpxPending = _calculatePending(user.plsDpxRewardDebt, accPlsDpxPerShare, user.amount);

    uint128 plsJonesPending = _calculatePending(user.plsJonesRewardDebt, accPlsJonesPerShare, user.amount);

    uint128 jonesPending = _calculatePending(user.jonesRewardDebt, accJonesPerShare, user.amount);

    user.plsRewardDebt = int128(uint128(_calculateRewardDebt(accPlsPerShare, user.amount)));

    user.plsDpxRewardDebt = int128(uint128(_calculateRewardDebt(accPlsDpxPerShare, user.amount)));

    user.plsJonesRewardDebt = int128(uint128(_calculateRewardDebt(accPlsJonesPerShare, user.amount)));

    user.jonesRewardDebt = int128(uint128(_calculateRewardDebt(accJonesPerShare, user.amount)));

    rewardsDistro.sendRewards(_user, plsPending, plsDpxPending, plsJonesPending, jonesPending);
  }

  /** OWNER FUNCTIONS */
  function setWhitelist(address _whitelist) external onlyOwner {
    whitelist = IWhitelist(_whitelist);
  }

  function setOperator(address _operator) external onlyOwner {
    operator = _operator;
  }

  function setStartTime(uint32 _startTime) external onlyOwner {
    if (lastRewardSecond == 0) {
      lastRewardSecond = _startTime;
    }
  }

  error DEPOSIT_ERROR();
  error WITHDRAW_ERROR();
  error UNAUTHORIZED();

  event Deposit(address indexed _user, uint256 _amount);
  event Withdraw(address indexed _user, uint256 _amount);
  event EmergencyWithdraw(address indexed _user, uint256 _amount);
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
pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import { IJonesStaker } from './JonesStaker.sol';
import { IPendingRewards } from '../PendingRewards.sol';

interface IRewardsDistro {
  function updateInfo()
    external
    view
    returns (
      uint80 pls_,
      uint80 plsDpx_,
      uint80 plsJones_,
      uint80 pendingJonesLessFee_
    );

  function sendRewards(
    address _to,
    uint128 _plsAmt,
    uint128 _plsDpxAmt,
    uint128 _plsJonesAmt,
    uint128 _jonesAmt
  ) external;

  function harvestFromUnderlyingFarm() external;
}

contract PlsJonesRewardsDistro is IRewardsDistro, Ownable {
  IJonesStaker public immutable staker;
  IPendingRewards public immutable pendingRewards;

  IERC20 public immutable pls;
  IERC20 public immutable plsDpx;
  IERC20 public immutable plsJones;
  IERC20 public immutable jones;

  address public plutusChef;
  address public rewardsController;
  uint80 public plsPerSecond;
  uint80 public plsDpxPerSecond;
  uint80 public plsJonesPerSecond;

  constructor(
    address _pendingRewards,
    address _staker,
    address _pls,
    address _plsDpx,
    address _plsJones,
    address _jones
  ) {
    pendingRewards = IPendingRewards(_pendingRewards);
    staker = IJonesStaker(_staker);
    pls = IERC20(_pls);
    plsDpx = IERC20(_plsDpx);
    plsJones = IERC20(_plsJones);
    jones = IERC20(_jones);

    rewardsController = msg.sender;
  }

  function sendRewards(
    address _to,
    uint128 _plsAmt,
    uint128 _plsDpxAmt,
    uint128 _plsJonesAmt,
    uint128 _jonesAmt
  ) external {
    if (msg.sender != plutusChef) revert UNAUTHORIZED();

    if (isNotZero(_plsAmt)) {
      _safeTokenTransfer(pls, _to, _plsAmt);
    }

    // Treasury yields
    if (isNotZero(_plsDpxAmt) || isNotZero(_plsJonesAmt)) {
      _safeTokenTransfer(plsDpx, _to, _plsDpxAmt);
      _safeTokenTransfer(plsJones, _to, _plsJonesAmt);
    }

    // Underlying yields
    if (isNotZero(_jonesAmt)) {
      _safeTokenTransfer(jones, _to, _jonesAmt);
    }
  }

  function harvestFromUnderlyingFarm() external {
    if (msg.sender != plutusChef) revert UNAUTHORIZED();
    staker.harvest();
  }

  /** VIEWS */

  /**
  Returns emissions of all the yield sources for frontend
 */
  function getEmissions()
    external
    view
    returns (
      uint80 pls_,
      uint80 plsDpx_,
      uint80 plsJones_,
      uint80 jones_
    )
  {
    // PLS emissions
    pls_ = plsPerSecond;

    // Treasury yield
    plsDpx_ = plsDpxPerSecond;
    plsJones_ = plsJonesPerSecond;

    // Underlying farm yield less fee
    jones_ = uint80(staker.jonesPerSecondLessFee());
  }

  /**
    Info needed for PlutusChef updates.
   */
  function updateInfo()
    external
    view
    returns (
      uint80 pls_,
      uint80 plsDpx_,
      uint80 plsJones_,
      uint80 pendingJonesLessFee_
    )
  {
    // PLS emissions
    pls_ = plsPerSecond;

    // Treasury yield
    plsDpx_ = plsDpxPerSecond;
    plsJones_ = plsJonesPerSecond;

    // Pending Jones
    pendingJonesLessFee_ = uint80(pendingRewards.pendingJonesLessFee());
  }

  /** PRIVATE FUNCTIONS */
  function isNotZero(uint256 _num) private pure returns (bool result) {
    assembly {
      result := gt(_num, 0)
    }
  }

  function isZero(uint256 _num) private pure returns (bool result) {
    assembly {
      result := iszero(_num)
    }
  }

  function _safeTokenTransfer(
    IERC20 _token,
    address _to,
    uint256 _amount
  ) private {
    uint256 bal = _token.balanceOf(address(this));

    if (_amount > bal) {
      _token.transfer(_to, bal);
    } else {
      _token.transfer(_to, _amount);
    }
  }

  /** CONTROLLER FUNCTIONS */

  function _isRewardsController() private view {
    if (msg.sender != rewardsController) revert UNAUTHORIZED();
  }

  function updatePlsEmission(uint80 _newPlsRate) external {
    _isRewardsController();
    plsPerSecond = _newPlsRate;
  }

  function updatePlsDpxEmissions(uint80 _newPlsDpxRate) external {
    _isRewardsController();
    plsDpxPerSecond = _newPlsDpxRate;
  }

  function updatePlsJonesEmissions(uint80 _newPlsJonesRate) external {
    _isRewardsController();
    plsJonesPerSecond = _newPlsJonesRate;
  }

  /** OWNER FUNCTIONS */

  /**
    Owner can retrieve stuck funds
   */
  function retrieve(IERC20 token) external onlyOwner {
    if (isNotZero(address(this).balance)) {
      payable(owner()).transfer(address(this).balance);
    }

    token.transfer(owner(), token.balanceOf(address(this)));
  }

  function setPlutusChef(address _newPlutusChef) external onlyOwner {
    plutusChef = _newPlutusChef;
  }

  function setRewardsController(address _newController) external onlyOwner {
    rewardsController = _newController;
  }

  error UNAUTHORIZED();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import '@openzeppelin/contracts/access/Ownable.sol';

interface IWhitelist {
  function isWhitelisted(address) external view returns (bool);
}

contract Whitelist is IWhitelist, Ownable {
  mapping(address => bool) public isWhitelisted;

  constructor(address _gov) {
    transferOwnership(_gov);
  }

  function whitelistAdd(address _addr) external onlyOwner {
    isWhitelisted[_addr] = true;
    emit AddedToWhitelist(_addr);
  }

  function whitelistRemove(address _addr) external onlyOwner {
    isWhitelisted[_addr] = false;
    emit RemovedFromWhitelist(_addr);
  }

  event RemovedFromWhitelist(address indexed _addr);
  event AddedToWhitelist(address indexed _addr);
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
pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/IStaker.sol';
import './IMillinerV2.sol';

interface IJonesStaker {
  function harvest() external;

  function pendingRewardsLessFee() external view returns (uint256);

  function jonesPerSecondLessFee() external view returns (uint256);
}

contract JonesStaker is IStaker, IJonesStaker, Ownable {
  uint256 public constant POOL_ID = 1;
  uint256 private constant FEE_DIVISOR = 1e4;

  // WETH-JONES SLP: 0xe8EE01aE5959D3231506FcDeF2d5F3E85987a39c
  IERC20 public immutable stakingToken;

  // JONES: 0x10393c20975cF177a3513071bC110f7962CD67da
  IERC20 public immutable rewardToken;

  // MillinerV2: 0xb94d1959084081c5a11C460012Ab522F5a0FD756
  IMillinerV2 public immutable underlyingFarm;

  address public operator;
  address public feeCollector;
  address public rewardsDistro;

  uint128 public fee; // fee in bp
  uint128 public totalHarvested;

  constructor(
    address _feeCollector,
    address _stakingToken,
    address _rewardToken,
    address _underlyingFarm
  ) {
    feeCollector = _feeCollector;

    stakingToken = IERC20(_stakingToken);
    rewardToken = IERC20(_rewardToken);
    underlyingFarm = IMillinerV2(_underlyingFarm);
    fee = 1000; // 10%

    stakingToken.approve(address(underlyingFarm), type(uint256).max);
  }

  function stake(uint256 _amount) external {
    if (msg.sender != operator) {
      revert UNAUTHORIZED();
    }

    underlyingFarm.deposit(POOL_ID, _amount);
    emit Staked(_amount);
  }

  function withdraw(uint256 _amount, address _to) external {
    if (msg.sender != operator) {
      revert UNAUTHORIZED();
    }

    underlyingFarm.withdraw(POOL_ID, _amount);
    stakingToken.transfer(_to, _amount);
    emit Withdrew(_to, _amount);
  }

  function harvest() external {
    if (msg.sender != rewardsDistro) revert UNAUTHORIZED();
    _harvest();
  }

  /** VIEWS */
  function pendingRewardsLessFee() external view returns (uint256) {
    unchecked {
      return (underlyingFarm.pendingJones(POOL_ID, address(this)) * (FEE_DIVISOR - fee)) / FEE_DIVISOR;
    }
  }

  function jonesPerSecondLessFee() external view returns (uint256) {
    unchecked {
      return (underlyingFarm.jonesPerSecond() * (FEE_DIVISOR - fee)) / FEE_DIVISOR;
    }
  }

  /** PRIVATE FUNCTIONS */
  function _harvest() private {
    underlyingFarm.harvest(POOL_ID);

    uint256 rewardAmt = rewardToken.balanceOf(address(this));
    uint256 rewardAmtLessFee;

    if (isNotZero(rewardAmt)) {
      unchecked {
        uint256 feePayable = (rewardAmt * fee) / FEE_DIVISOR;

        rewardAmtLessFee = rewardAmt - feePayable;
        totalHarvested += uint128(rewardAmtLessFee);

        if (isNotZero(feePayable)) {
          rewardToken.transfer(feeCollector, feePayable);
        }

        rewardToken.transfer(address(rewardsDistro), rewardAmtLessFee);
        emit Harvested(address(rewardToken), rewardAmtLessFee);
      }
    }
  }

  /** CHECKS */
  function isNotZero(uint256 _num) private pure returns (bool result) {
    assembly {
      result := gt(_num, 0)
    }
  }

  function isZero(uint256 _num) private pure returns (bool result) {
    assembly {
      result := iszero(_num)
    }
  }

  /** OWNER FUNCTIONS */

  /**
    Retrieve stuck funds or new reward tokens
   */
  function retrieve(IERC20 token) external onlyOwner {
    if (isNotZero(address(this).balance)) {
      payable(owner()).transfer(address(this).balance);
    }

    token.transfer(owner(), token.balanceOf(address(this)));
  }

  /**
    Exit farm for veBoost migration
   */
  function exit() external onlyOwner {
    uint256 balance = underlyingFarm.deposited(POOL_ID, address(this));
    address owner = owner();

    underlyingFarm.withdraw(POOL_ID, balance);
    stakingToken.transfer(owner, balance);
    emit ExitedStaking(owner, balance);

    _harvest();
  }

  function setFee(uint128 _fee) external onlyOwner {
    if (_fee > FEE_DIVISOR) {
      revert INVALID_FEE();
    }

    emit FeeChanged(_fee, fee);
    fee = _fee;
  }

  function ownerHarvest() external onlyOwner {
    _harvest();
  }

  function setOperator(address _newOperator) external onlyOwner {
    emit OperatorChanged(_newOperator, operator);
    operator = _newOperator;
  }

  function setFeeCollector(address _newFeeCollector) external onlyOwner {
    emit FeeCollectorChanged(_newFeeCollector, feeCollector);
    feeCollector = _newFeeCollector;
  }

  function setRewardsDistro(address _newRewardsDistro) external onlyOwner {
    emit RewardsDistroChanged(_newRewardsDistro, rewardsDistro);
    rewardsDistro = _newRewardsDistro;
  }

  event Staked(uint256 _amt);
  event Withdrew(address indexed _to, uint256 _amt);
  event OperatorChanged(address indexed _new, address _old);
  event FeeCollectorChanged(address indexed _new, address _old);
  event RewardsDistroChanged(address indexed _new, address _old);
  event FeeChanged(uint256 indexed _new, uint256 _old);
  event ExitedStaking(address indexed _to, uint256 _amt);
  event Harvested(address indexed _token, uint256 _amt);

  error UNAUTHORIZED();
  error INVALID_FEE();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './plsJONES/IMillinerV2.sol';
import './plsDPX/IDpxStakingRewards.sol';

interface IStaker {
  function fee() external view returns (uint256);
}

interface IPendingRewards {
  function pendingDpxRewardsLessFee() external view returns (uint256 _pendingDpx, uint256 _pendingRdpx);

  function pendingJonesLessFee() external view returns (uint256 _pendingJones);
}

contract PendingRewards is IPendingRewards {
  uint256 private constant FEE_DIVISOR = 1e4;

  address private constant JONES_STAKER = 0x668BB973c3e35759269DAc6D5BF118EA9729110E;
  IMillinerV2 private constant MILLINER_V2 = IMillinerV2(0xb94d1959084081c5a11C460012Ab522F5a0FD756);
  uint256 private constant POOL_ID = 1;

  address private constant DPX_STAKER = 0xC046F44ED68014f048ECa0010A642749Ebe34b03;
  IDpxStakingRewards private constant DPX_STAKING_REWARDS =
    IDpxStakingRewards(0xc6D714170fE766691670f12c2b45C1f34405AAb6);

  function pendingDpxRewardsLessFee() external view returns (uint256 _pendingDpx, uint256 _pendingRdpx) {
    uint256 fee = IStaker(DPX_STAKER).fee();
    (uint256 dpxEarned, uint256 rdpxEarned) = DPX_STAKING_REWARDS.earned(DPX_STAKER);

    unchecked {
      _pendingDpx = (dpxEarned * (FEE_DIVISOR - fee)) / FEE_DIVISOR;
      _pendingRdpx = (rdpxEarned * (FEE_DIVISOR - fee)) / FEE_DIVISOR;
    }
  }

  function pendingJonesLessFee() external view returns (uint256 _pendingJones) {
    unchecked {
      _pendingJones =
        (MILLINER_V2.pendingJones(POOL_ID, JONES_STAKER) * (FEE_DIVISOR - IStaker(JONES_STAKER).fee())) /
        FEE_DIVISOR;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IStaker {
  function stake(uint256) external;

  function withdraw(uint256, address) external;

  function exit() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IMillinerV2 {
  function deposit(uint256 _pid, uint256 _amount) external;

  function compound(uint256 _pid) external;

  function withdraw(uint256 _pid, uint256 _amount) external;

  function emergencyWithdraw(uint256 _pid) external;

  function harvest(uint256 _pid) external;

  /** VIEWS */

  function deposited(uint256 _pid, address _user) external view returns (uint256);

  function jonesPerSecond() external view returns (uint256);

  function pendingJones(uint256 _pid, address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IDpxStakingRewards {
  function stake(uint256) external;

  function exit() external;

  function compound() external;

  function withdraw(uint256) external;

  function getReward(uint256) external;

  /** VIEWS */

  function balanceOf(address account) external view returns (uint256);

  function rewardRateDPX() external view returns (uint256);

  function rewardRateRDPX() external view returns (uint256);

  function earned(address account) external view returns (uint256 DPXtokensEarned, uint256 RDPXtokensEarned);
}