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
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract CashGameCashier is Ownable {
  // Allowed stablecoins (USDT)
  mapping(uint256 => mapping(address => bool)) public allowedTokensPerChain;
  // Player deposit counts
  mapping(address => uint256) public playerDeposits;
  // Deposit counter
  uint256 public totalDeposits;
  // Default multiplier set to 100 times the deposit
  uint256 public maxMultiplier = 100;
  // Reserve percentage
  uint256 public reservePercentage = 5;

  // Events
  event CashIn(address indexed player, address indexed token, uint256 amount, uint tableType);
  event CashOut(address indexed player, address indexed token, uint256 amount);
  event Refund(address indexed player, address indexed token, uint256 amount);
  event Deposit(address indexed token, uint256 amount);
  event TakeProfit(address indexed token, uint256 amount);
  event ReBuy(address indexed player, address indexed token, uint256 amount, uint tableType, string tableId);

  constructor() Ownable(msg.sender) {
    setAllowedTokens();
  }

  function setAllowedTokens() internal {
    //ARBITRUM - chainID(42161)
    uint256 ARBITRUM_CHAIN_ID = 42161;
    address ARBITRUM_USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;
    allowedTokensPerChain[ARBITRUM_CHAIN_ID][ARBITRUM_USDT] = true;
  }

  function _isTokenAllowed(address token) internal view returns (bool) {
    return allowedTokensPerChain[block.chainid][token];
  }

  function _transferIn(address token, uint256 amount, address from) internal {
    require(token != address(0), 'Token address cannot be zero');
    require(_isTokenAllowed(token), 'Token not allowed');
    require(IERC20(token).transferFrom(from, address(this), amount), 'Transfer failed');
    playerDeposits[from] += amount;
    totalDeposits += amount;
  }

  function _transferOut(address to, address token, uint256 amount) internal {
    // Check for existing deposits first
    require(playerDeposits[to] > 0, 'The player has no deposits');

    // Calculate maximum allowed cash out based on the deposit and the multiplier
    uint256 maxAllowedCashOut = playerDeposits[to] * maxMultiplier;

    // Reduce the total deposits and reset the player's deposit amount
    totalDeposits -= playerDeposits[to];
    playerDeposits[to] = 0;

    // If amount is greater than 0, perform checks related to token transfer
    if (amount > 0) {
      require(IERC20(token).balanceOf(address(this)) >= amount, 'Insufficient balance');
      require(amount <= maxAllowedCashOut, 'Transfer out exceeds allowed limit');
      require(IERC20(token).transfer(to, amount), 'Transfer failed');
    }
  }

  function cashIn(address token, uint256 amount, uint tableType) public {
    _transferIn(token, amount, msg.sender);
    emit CashIn(msg.sender, token, amount, tableType);
  }

  function reBuy(address token, uint256 amount, uint tableType, string memory tableId) public {
    _transferIn(token, amount, msg.sender);
    emit ReBuy(msg.sender, token, amount, tableType, tableId);
  }

  function cashOut(address player, address token, uint256 amount) public onlyOwner {
    require(player != address(0), 'Player address cannot be zero');
    _transferOut(player, token, amount);
    emit CashOut(player, token, amount);
  }

  function refund(address player, address token, uint256 amount) public onlyOwner {
    require(player != address(0), 'Player address cannot be zero');
    _transferOut(player, token, amount);
    emit Refund(player, token, amount);
  }

  function deposit(address token, uint256 amount) public onlyOwner {
    _transferIn(token, amount, msg.sender);
    emit Deposit(token, amount);
  }

  function takeProfit(address token) public onlyOwner {
    uint256 reserve = (totalDeposits * reservePercentage) / 100;
    uint256 availableProfit = IERC20(token).balanceOf(address(this)) - reserve - totalDeposits;
    require(availableProfit > 0, 'Insufficient funds after reserves and deposits');
    IERC20(token).transfer(msg.sender, availableProfit);
    emit TakeProfit(token, availableProfit);
  }

  function changeOwner(address newOwner) public onlyOwner {
    transferOwnership(newOwner);
  }

  function viewTotalDeposits() public view returns (uint256) {
    return totalDeposits;
  }

  function viewReserve() public view returns (uint256) {
    return (totalDeposits * reservePercentage) / 100;
  }
}