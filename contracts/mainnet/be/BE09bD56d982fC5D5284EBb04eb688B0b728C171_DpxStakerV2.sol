// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import { IStaker, IDPXVotingEscrow, IVoting, IFeeDistro } from './interfaces.sol';

contract DpxStakerV2 is Ownable, IStaker {
  uint256 private constant MAXTIME = 4 * 365 * 86400;
  uint256 private constant WEEK = 7 * 86400;

  IERC20 public immutable dpx;
  address public immutable escrow;
  address public depositor;
  address public operator;
  address public gaugeController;
  address public voter;

  uint208 public unlockTime;
  uint32 public newMaxTime;
  bool public maxTimeChanged;

  constructor(address _dpx, address _escrow) {
    dpx = IERC20(_dpx);
    escrow = _escrow;
    dpx.approve(escrow, type(uint256).max);
  }

  function stake(uint256 _amount) external {
    if (msg.sender != depositor) revert UNAUTHORIZED();

    IERC20(dpx).balanceOf(address(this));

    // increase amount
    IDPXVotingEscrow(escrow).increase_amount(_amount);

    uint256 unlockAt = block.timestamp + MAXTIME;

    // accomodate future change in max locking time
    if (maxTimeChanged) {
      unlockAt = block.timestamp + uint256(newMaxTime);
    }

    uint256 unlockInWeeks = (unlockAt / WEEK) * WEEK;

    // increase time too if over 1 week buffer
    if (unlockInWeeks - unlockTime >= 1) {
      IDPXVotingEscrow(escrow).increase_unlock_time(unlockAt);
      unlockTime = uint208(unlockInWeeks);
    }
  }

  function voteGaugeWeight(address _gauge, uint256 _weight) external returns (bool) {
    if (msg.sender != voter) revert UNAUTHORIZED();
    IVoting(gaugeController).vote_for_gauge_weights(_gauge, _weight);
    return true;
  }

  function claimFees(
    address _distroContract,
    address _token,
    address _claimTo
  ) external returns (uint256) {
    if (msg.sender != operator) revert UNAUTHORIZED();
    IFeeDistro(_distroContract).getYield();
    uint256 _balance = IERC20(_token).balanceOf(address(this));
    IERC20(_token).transfer(_claimTo, _balance);
    return _balance;
  }

  function execute(
    address _to,
    uint256 _value,
    bytes calldata _data
  ) external returns (bool, bytes memory) {
    if (msg.sender != voter && msg.sender != operator) revert UNAUTHORIZED();
    (bool success, bytes memory result) = _to.call{ value: _value }(_data);
    return (success, result);
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
    Owner can retrieve stuck funds
   */
  function retrieve(IERC20 token) external onlyOwner {
    if (isNotZero(address(this).balance)) {
      payable(owner()).transfer(address(this).balance);
    }

    token.transfer(owner(), token.balanceOf(address(this)));
  }

  function initialLock(address _feeDistro) external onlyOwner {
    uint256 unlockAt = block.timestamp + MAXTIME;
    unlockTime = uint208((unlockAt / WEEK) * WEEK);
    IDPXVotingEscrow(escrow).create_lock(dpx.balanceOf(address(this)), unlockAt);
    IFeeDistro(_feeDistro).checkpoint();
  }

  function release() external onlyOwner {
    emit Release();
    IDPXVotingEscrow(escrow).withdraw();
  }

  function setOperator(address _newOperator) external onlyOwner {
    emit OperatorChanged(_newOperator, operator);
    operator = _newOperator;
  }

  function setDepositor(address _newDepositor) external onlyOwner {
    emit DepositorChanged(_newDepositor, depositor);
    depositor = _newDepositor;
  }

  function setVoter(address _newVoter) external onlyOwner {
    emit VoterChanged(_newVoter, voter);
    voter = _newVoter;
  }

  function setGaugeController(address _newGauge) external onlyOwner {
    emit GaugeChanged(_newGauge, gaugeController);
    gaugeController = _newGauge;
  }

  function setNewMaxTime(bool _changed, uint32 _newMaxTime) external onlyOwner {
    emit MaxTimeUpdated(_newMaxTime);
    maxTimeChanged = _changed;
    newMaxTime = _newMaxTime;
  }

  event MaxTimeUpdated(uint32 _newMaxTime);
  event Release();
  event GaugeChanged(address indexed _new, address _old);
  event VoterChanged(address indexed _new, address _old);
  event OperatorChanged(address indexed _new, address _old);
  event DepositorChanged(address indexed _new, address _old);

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

// IDPXVotingEscrow v1.0.0
interface IDPXVotingEscrow {
  function get_last_user_slope(address addr) external view returns (int128);

  function user_point_history__ts(address _addr, uint256 _idx) external view returns (uint256);

  function locked__end(address _addr) external view returns (uint256);

  function checkpoint() external;

  function deposit_for(address _addr, uint256 _value) external;

  function create_lock(uint256 _value, uint256 _unlock_time) external;

  function increase_amount(uint256 _value) external;

  function increase_unlock_time(uint256 _unlock_time) external;

  function withdraw() external;

  function balanceOf(address addr) external view returns (uint256);

  function balanceOfAtT(address addr, uint256 _t) external view returns (uint256);

  function balanceOfAt(address addr, uint256 _block) external view returns (uint256);

  function totalSupply() external view returns (uint256);

  function totalSupplyAtT(uint256 t) external view returns (uint256);

  function totalSupplyAt(uint256 _block) external view returns (uint256);

  function token() external view returns (address);

  function supply() external view returns (uint256);

  function locked(address addr) external view returns (int128 amount, uint256 end);

  function epoch() external view returns (uint256);

  function point_history(uint256 arg0)
    external
    view
    returns (
      int128 bias,
      int128 slope,
      uint256 ts,
      uint256 blk
    );

  function user_point_history(address arg0, uint256 arg1)
    external
    view
    returns (
      int128 bias,
      int128 slope,
      uint256 ts,
      uint256 blk
    );

  function user_point_epoch(address arg0) external view returns (uint256);

  function slope_changes(uint256 arg0) external view returns (int128);

  function controller() external view returns (address);

  function transfersEnabled() external view returns (bool);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function version() external view returns (string memory);

  function decimals() external view returns (uint8);
}

interface IFeeDistro {
  function checkpoint() external;

  function getYield() external;

  function earned(address _account) external view returns (uint256);
}

interface IStaker {
  function stake(uint256) external;

  function release() external;

  function voteGaugeWeight(address _gauge, uint256 _weight) external returns (bool);

  function claimFees(
    address _distroContract,
    address _token,
    address _claimTo
  ) external returns (uint256);
}

interface IVoting {
  function vote_for_gauge_weights(address, uint256) external;
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