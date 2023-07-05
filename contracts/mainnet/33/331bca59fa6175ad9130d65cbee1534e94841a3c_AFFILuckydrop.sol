/**
 *Submitted for verification at Arbiscan on 2023-07-05
*/

/*
██████╗░██╗░░░██╗██╗░░░██╗  ░█████╗░███████╗███████╗██╗
██╔══██╗██║░░░██║╚██╗░██╔╝  ██╔══██╗██╔════╝██╔════╝██║
██████╦╝██║░░░██║░╚████╔╝░  ███████║█████╗░░█████╗░░██║
██╔══██╗██║░░░██║░░╚██╔╝░░  ██╔══██║██╔══╝░░██╔══╝░░██║
██████╦╝╚██████╔╝░░░██║░░░  ██║░░██║██║░░░░░██║░░░░░██║
╚═════╝░░╚═════╝░░░░╚═╝░░░  ╚═╝░░╚═╝╚═╝░░░░░╚═╝░░░░░╚═╝

███████╗░█████╗░██████╗░███╗░░██╗  ██╗░░░██╗░██████╗██████╗░░█████╗░
██╔════╝██╔══██╗██╔══██╗████╗░██║  ██║░░░██║██╔════╝██╔══██╗██╔══██╗
█████╗░░███████║██████╔╝██╔██╗██║  ██║░░░██║╚█████╗░██║░░██║██║░░╚═╝
██╔══╝░░██╔══██║██╔══██╗██║╚████║  ██║░░░██║░╚═══██╗██║░░██║██║░░██╗
███████╗██║░░██║██║░░██║██║░╚███║  ╚██████╔╝██████╔╝██████╔╝╚█████╔╝

**Rewarding the highest buyer every 30minutes with $USDC
**Lets trade $AFFI shall we!!!
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}


pragma solidity 0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * From https://github.com/OpenZeppelin/openzeppelin-contracts
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
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

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
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
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


pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

}

pragma solidity 0.6.12;

/**
 * @dev Interface of the SellToken standard as defined in the EIP.
 * From https://github.com/OpenZeppelin/openzeppelin-contracts
 */
interface ISellToken {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function receivedAmount(address recipient) external view returns (uint256);
  function balanceOf(address recipient) external view returns (uint256);

}


// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

//import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}



pragma solidity 0.6.12;


contract AFFILuckydrop is Initializable {
  using SafeMath for uint256;
  // Todo : Update when deploy to production

  address public ADMIN; //deployer of this contract;
  address public AUTHORIZED_CALLER; //official token contract
  address public REWARD_TOKEN; //busd or usdt or token for reward
  mapping (uint => address) private playeraddr;
  mapping (uint => uint256) private playeramount; 
  mapping (address => uint256) public totalWalletWon; 
  uint private playersavedlevel = 1;
  uint public limit = 5;
  bool public jackpotsystem = true;
  address private constant DEAD = 0x000000000000000000000000000000000000dEaD;
  address private constant ZERO = 0x0000000000000000000000000000000000000000;

  address private currleaderwallet;
  uint256 private currleadertokenpurchased;
  
  address private lastleaderwallet;
  uint256 private lastleaderamountwon;
  
  uint256 public nextdistributetime;
  uint256 public timedifference;
  uint public currentround;
  uint public totalplayers;
  
  uint256 public totalusdtwon;
  uint256 public lastusdtwon;
  
  modifier onlyAdmin() {
    require(msg.sender == ADMIN, 'INVALID ADMIN');
    _;
  }
  
  modifier onlyAuthorizedCaller() {
    require(msg.sender == AUTHORIZED_CALLER, 'INVALID AUTHORIZED CALLER');
    _;
  }  
  
  event Winner(address winner, uint256 amountwon, uint timestamp);

  constructor() public {}

  function Bootup(
    address _Admin,
    address _RewardToken,
    address _AuthorizedCaller,
	  uint256 _timedifference
  ) public initializer {
    ADMIN = _Admin;
    AUTHORIZED_CALLER = _AuthorizedCaller;
	  REWARD_TOKEN = _RewardToken;
    timedifference = _timedifference;
  }


  function lottery(address wallet, uint256 amountpurchased) public onlyAuthorizedCaller {
    //a players wallet is recorded as a player, and a leader if no body else exceeds his buy amount.
	if (amountpurchased > currleadertokenpurchased && wallet != ZERO && jackpotsystem == true) {
    //new leader detected, push winner updards and replace the currleadertokenpurchased.
    currleaderwallet = wallet;
	  currleadertokenpurchased = amountpurchased;
    totalplayers ++;
		} 
     
    //update playersavedlevel
    playeraddr[playersavedlevel] = wallet;
    playeramount[playersavedlevel] = amountpurchased;
    if (playersavedlevel < limit) {
         playersavedlevel ++;
       }


	  //if time has exceeded, pay current leader and reset all values
	  if (jackpotsystem == true && block.timestamp > nextdistributetime) {
		  //time has exceeded, pay current leader
          uint256 initialtimestamp = block.timestamp;
		  uint256 tokensincontract = IERC20(REWARD_TOKEN).balanceOf(address(this));
          address winnerswallet = currleaderwallet;
		  currleaderwallet = ZERO; //address(0)
		      nextdistributetime = initialtimestamp + timedifference;
          lastleaderwallet = winnerswallet; //save last winner wallet
          lastleaderamountwon = currleadertokenpurchased; //save last leader usdt
          currleadertokenpurchased = 0;
          playersavedlevel = 1;
          currentround ++;

		  if (tokensincontract > 0) {
          IERC20(REWARD_TOKEN).transfer(winnerswallet, tokensincontract);
          totalusdtwon += tokensincontract;
          lastusdtwon = tokensincontract;
          totalWalletWon[winnerswallet] += tokensincontract;
		  emit Winner(winnerswallet, tokensincontract, initialtimestamp); 
		  }
		} 
    }
  
  
 function erasetotalenteries() public onlyAdmin {
   playersavedlevel = 1;
    }
 function updatejackpotsystem(bool _status) public onlyAdmin {
    jackpotsystem = _status; //enables or disables jackpot
  } 

  function updateCurrLimit(uint _limit) public onlyAdmin {
    limit = _limit;
  } 

 function updateAuthorizedCaller(address authorized_caller) public onlyAdmin {
    AUTHORIZED_CALLER = authorized_caller;
  }
  
 function updateTimedifference(uint _timedifference) public onlyAdmin {
    timedifference = _timedifference; //increase or decrease next pay time
  }

 function getplayer(uint rowtofetch) external view returns(address, uint256) {
      return (playeraddr[rowtofetch], playeramount[rowtofetch]);
 }
 
 function getLastwinner() external view returns(address, uint256) {
      return (lastleaderwallet, lastleaderamountwon);
 }

 function getCurrwinner() external view returns(address, uint256) {
      return (currleaderwallet, currleadertokenpurchased);
 }

 function currentrow() external view returns(uint)  {
  return playersavedlevel;
  }

 function currentcontractrewardbal() external view returns(uint256)  {
  return IERC20(REWARD_TOKEN).balanceOf(address(this));
  }

}