/**
 *Submitted for verification at Arbiscan on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

contract Staking is Ownable {
  struct Staker {
    uint256 balance;
    uint256 depositTime;
    uint256 lockPeriod;
  }

  mapping(address => Staker) public stakers;
  uint256 public totalStaked;
  address[] public stakersArr;
  uint256 public constant YEAR_IN_SECONDS = 31536000;
  uint256 public constant SIX_MONTHS_IN_SECONDS = 15768000;
  uint256 public constant THREE_MONTHS_IN_SECONDS = 7884000;
  uint256 public constant ONE_MONTH_IN_SECONDS = 2628000;
  uint256 public constant ONE_WEEK_IN_SECONDS = 604800;
  IERC20 public SubwayWatcher;

  mapping(uint256 => uint256) public tokenAmountsPerLockPeriod;

  constructor(address _tokenContractAddress)
    Ownable(msg.sender)
  {
    SubwayWatcher = IERC20(_tokenContractAddress);
    tokenAmountsPerLockPeriod[ONE_WEEK_IN_SECONDS] = 100000*10**18;
    tokenAmountsPerLockPeriod[ONE_MONTH_IN_SECONDS] = 10000*10**18;
    tokenAmountsPerLockPeriod[THREE_MONTHS_IN_SECONDS] = 1000*10**18;
    tokenAmountsPerLockPeriod[SIX_MONTHS_IN_SECONDS] = 100*10**18;
    tokenAmountsPerLockPeriod[YEAR_IN_SECONDS] = 10*10**18;
  }

  event Deposit (address indexed sender, uint256 amount);
  event Withdraw (address indexed from, uint256 amount);

  // a user can deposit more funds if its lock period 
  // has been edited by the admin
  function deposit(
    uint256 _amount,
    uint256 _chosenLockPeriod
  )
    external
  {
    require(
      _amount > 0,
      "AMOUNT_INVALID"
    );
    require(
      tokenAmountsPerLockPeriod[_chosenLockPeriod] != 0,
      "INVALID_LOCK_PERIOD"
    );
    Staker storage staker = stakers[msg.sender];
    if (staker.balance > 0) {
      require(
        _amount + staker.balance >= tokenAmountsPerLockPeriod[_chosenLockPeriod], 
        "INSUFFICIENT_AMOUNT"
      );
      if(_chosenLockPeriod != staker.lockPeriod) {
        staker.lockPeriod = _chosenLockPeriod;
        staker.depositTime = block.timestamp;
      }
      staker.balance = staker.balance + _amount;
    } else {
      require(
        _amount >= tokenAmountsPerLockPeriod[_chosenLockPeriod], 
        "INSUFFICIENT_AMOUNT"
      );
      staker.balance = _amount;
      staker.depositTime = block.timestamp;
      staker.lockPeriod = _chosenLockPeriod;
      stakersArr.push(msg.sender);
    }
    totalStaked = totalStaked + _amount;
    SubwayWatcher.transferFrom(msg.sender, address(this), _amount);
    emit Deposit(msg.sender, _amount);
  }

  // a staker can withdraw part of the funds if its lock period
  // has been edited by the admin
  function withdraw(uint256 _amount) external {
    require(
      _amount > 0,
      "AMOUNT_INVALID"
    );
    Staker storage staker = stakers[msg.sender];
    require(
      staker.balance >= _amount,
      "INSUFFICIENT_BALANCE"
    );
    uint256 depositedTime = block.timestamp - staker.depositTime;
    if (depositedTime < staker.lockPeriod) {
      require(
        staker.balance - _amount >= tokenAmountsPerLockPeriod[staker.lockPeriod],
        "LOCK_PERIOD_NOT_ENDED"
      );
    } else {
      staker.lockPeriod = 0;
      staker.depositTime = 0;
    }
    staker.balance = staker.balance - _amount;
    totalStaked = totalStaked - _amount;
    SubwayWatcher.transfer(msg.sender, _amount);
    emit Withdraw(address(this), _amount);
  }

  function addOrEditLockPeriod(
    uint256 _period,
    uint256 _tokenAmount
  ) 
    external
    onlyOwner
  {
    require(
      _period > 0,
      "PERIOD_INVALID"
    );
    require(
      _tokenAmount > 0,
      "AMOUNT_INVALID"
    );
    tokenAmountsPerLockPeriod[_period] = _tokenAmount;
  }

  function removeLockPeriod(uint256 _period)
    external
    onlyOwner
  {
    unchecked {            
      uint256 length = stakersArr.length;
      for(uint256 i = 0; i < length; i++) {
        if(stakers[stakersArr[i]].lockPeriod == _period) {
          revert("STAKERS_WITH_THIS_LOCK_PERIOD");
        }
      }
      delete tokenAmountsPerLockPeriod[_period];
    }
  }

  function isStaker(address _stakerAddress) 
    external
    view
    returns (bool)
  {
    uint256 staked = stakers[_stakerAddress].balance;
    uint256 lockPeriod = stakers[_stakerAddress].lockPeriod;
    return staked > 0 && staked >= tokenAmountsPerLockPeriod[lockPeriod];
  }
}