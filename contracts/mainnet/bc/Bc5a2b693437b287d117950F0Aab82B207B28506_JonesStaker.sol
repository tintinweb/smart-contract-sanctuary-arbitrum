// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/IStaker.sol';
import './IMillinerV2.sol';
import './IPlsJonesRewardsDistro.sol';

contract JonesStaker is IStaker, Ownable {
  uint256 private constant POOL_ID = 1;

  // WETH-JONES SLP: 0xe8EE01aE5959D3231506FcDeF2d5F3E85987a39c
  IERC20 public immutable stakingToken;

  // JONES: 0x10393c20975cF177a3513071bC110f7962CD67da
  IERC20 public immutable rewardToken;

  // MillinerV2: 0xb94d1959084081c5a11C460012Ab522F5a0FD756
  IMillinerV2 public immutable underlyingFarm;

  address public operator;
  address public feeCollector;
  IPlsJonesRewardsDistro public rewardsDistro;

  uint256 public fee; // fee in bp

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
    _checkOperator();

    underlyingFarm.deposit(POOL_ID, _amount);
    emit Staked(_amount);
  }

  function withdraw(uint256 _amount, address _to) external {
    _checkOperator();

    underlyingFarm.withdraw(POOL_ID, _amount);
    stakingToken.transfer(_to, _amount);
  }

  function harvest() public {
    underlyingFarm.harvest(POOL_ID);

    uint256 rewardAmt = rewardToken.balanceOf(address(this));
    uint256 rewardAmtLessFee;

    if (isNotZero(rewardAmt)) {
      unchecked {
        uint256 feePayable = (rewardAmt * fee) / 1e4;

        if (isNotZero(feePayable)) {
          rewardToken.transfer(feeCollector, feePayable);
        }

        rewardAmtLessFee = rewardAmt - feePayable;

        rewardToken.transfer(address(rewardsDistro), rewardAmtLessFee);
        emit Harvested(address(rewardToken), rewardAmtLessFee);
      }
    }

    rewardsDistro.updateHarvestDetails(block.timestamp, rewardAmtLessFee);
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

  function _checkOperator() private view {
    if (msg.sender != operator) {
      revert UNAUTHORIZED();
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

    harvest();
  }

  function setFee(uint256 _fee) external onlyOwner {
    if (_fee > 1e4) {
      revert INVALID_FEE();
    }

    emit FeeChanged(_fee, fee);
    fee = _fee;
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
    emit RewardsDistroChanged(_newRewardsDistro, address(rewardsDistro));
    rewardsDistro = IPlsJonesRewardsDistro(_newRewardsDistro);
  }

  event Staked(uint256 _amt);
  event OperatorChanged(address _new, address indexed _old);
  event FeeCollectorChanged(address _new, address indexed _old);
  event RewardsDistroChanged(address _new, address indexed _old);
  event FeeChanged(uint256 _new, uint256 _old);
  event ExitedStaking(address _to, uint256 _amt);
  event Harvested(address indexed _token, uint256 _amt);

  error UNAUTHORIZED();
  error INVALID_FEE();
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

interface IStaker {
  function stake(uint256) external;

  function harvest() external;

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPlsJonesRewardsDistro {
  function updateHarvestDetails(uint256 _timestamp, uint256 _jones) external;
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