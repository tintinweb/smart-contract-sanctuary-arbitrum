// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import './interfaces/IGarbiTimeLock.sol';

contract ISwapTrade {
    uint256 public TRADE_FEE; //0.01% 10/100000
} 

contract GarbiswapFeeMachine is Ownable{
    
    using SafeMath for uint256;

    IERC20 public GRB;
    
    address public performanceMachineContract;
    address public safuFundContract;

    IGarbiTimeLock public garbiTimeLockContract;

    uint256 public PERFORMANCE_FEE = 50; //50% 50/100 from 0.01% trade fee 
    uint256 public SAFU_FUND = 0; //0%

    uint256 public DISTRIBUTE_GARBI_AMOUNT = 5 * 1e17;

    uint256 public DAY_PERIOD = 1 days;

    mapping (address => bool) public pairs;
    mapping (address => mapping(uint256 => uint256)) public feeOf;
    mapping (address => uint256) public timeOfCreateNewFee;
    mapping (address => uint256) public totalDays;

    event onDistributeGarbi(address _trader, uint256 _amount);
    
    constructor(
        IERC20 _grb,
        address _performanceMachineContract, 
        address _safuFundContract,
        IGarbiTimeLock _garbiTimeLockContract
        ) {
        garbiTimeLockContract = _garbiTimeLockContract;
        performanceMachineContract = _performanceMachineContract;
        safuFundContract = _safuFundContract;

        GRB = _grb;
    }

    function setDayPeriod(uint256 _value) public onlyOwner {
        DAY_PERIOD = _value;
    }
    function addPair(address _pair) public onlyOwner {
        require(pairs[_pair] != true, "IN_THE_LIST");
        pairs[_pair] = true;
    }

    function removePair(address _pair) public onlyOwner {
        require(pairs[_pair] == true, "NOT_IN_THE_LIST");
        pairs[_pair] = false;
    }

    function setDistributeGarbiAmount(uint256 _amount) public onlyOwner {
        DISTRIBUTE_GARBI_AMOUNT = _amount;
    }


    function setPerformanceMachine() public onlyOwner {

        require(garbiTimeLockContract.isQueuedTransaction(address(this), 'setPerformanceMachine'), "INVALID_PERMISSION");

        address _performanceMachine = garbiTimeLockContract.getAddressChangeOnTimeLock(address(this), 'setPerformanceMachine', 'performanceMachine');

        require(_performanceMachine != address(0), "INVALID_ADDRESS");

        performanceMachineContract = _performanceMachine;

        garbiTimeLockContract.clearFieldValue('setPerformanceMachine', 'performanceMachine', 1);
        garbiTimeLockContract.doneTransactions('setPerformanceMachine');
    }

    function setSafuFundContract() public onlyOwner {

        require(garbiTimeLockContract.isQueuedTransaction(address(this), 'setSafuFundContract'), "INVALID_PERMISSION");

        address _safuFundContract = garbiTimeLockContract.getAddressChangeOnTimeLock(address(this), 'setSafuFundContract', 'safuFundContract');

        require(_safuFundContract != address(0), "INVALID_ADDRESS");

        safuFundContract = _safuFundContract;

        garbiTimeLockContract.clearFieldValue('setSafuFundContract', 'safuFundContract', 1);
        garbiTimeLockContract.doneTransactions('setSafuFundContract');
    }

    function setPerformanceFee() public onlyOwner {

        require(garbiTimeLockContract.isQueuedTransaction(address(this), 'setPerformanceFee'), "INVALID_PERMISSION");

        PERFORMANCE_FEE = garbiTimeLockContract.getUintChangeOnTimeLock(address(this), 'setPerformanceFee', 'PERFORMANCE_FEE');

        garbiTimeLockContract.clearFieldValue('setPerformanceFee', 'PERFORMANCE_FEE', 2);
        garbiTimeLockContract.doneTransactions('setPerformanceFee');
    }

    function setSafuFee() public onlyOwner {

        require(garbiTimeLockContract.isQueuedTransaction(address(this), 'setSafuFee'), "INVALID_PERMISSION");

        SAFU_FUND = garbiTimeLockContract.getUintChangeOnTimeLock(address(this), 'setSafuFee', 'SAFU_FUND');

        garbiTimeLockContract.clearFieldValue('setSafuFee', 'SAFU_FUND', 2);
        garbiTimeLockContract.doneTransactions('setSafuFee');
    }

    function processTradeFee(IERC20 token, address trader) public {

        require(pairs[msg.sender] == true, "PAIR_NOT_CORRECT");

        uint256 tokenBalance = token.balanceOf(address(this)); 
        require(tokenBalance > 0, "TOKEN_BALANCE_ZERO");
        uint256 performanceFee = tokenBalance.mul(PERFORMANCE_FEE).div(100);
        uint256 safuFundAmount = tokenBalance.mul(SAFU_FUND).div(100);
        token.transfer(performanceMachineContract, performanceFee);
        token.transfer(safuFundContract, safuFundAmount);
        token.transfer(msg.sender, token.balanceOf(address(this))); //send back the trade fee after cut 50%

        _distributeGarbi(trader);
        _updateDailyFee(msg.sender, tokenBalance);
    }

    function _updateDailyFee(address _lp, uint256 _fee) private {
        if (timeOfCreateNewFee[_lp].add(DAY_PERIOD) <= block.timestamp) {
            totalDays[_lp] += 1;
            timeOfCreateNewFee[_lp] = block.timestamp;
        } 
        feeOf[_lp][totalDays[_lp]] = feeOf[_lp][totalDays[_lp]].add(_fee);
    }

    function _distributeGarbi(address trader) private {
        uint256 _grbBal = GRB.balanceOf(address(this));
        uint256 _distributeAmt = DISTRIBUTE_GARBI_AMOUNT;

        if (_distributeAmt > _grbBal) {
            _distributeAmt = _grbBal;
        }
        if (_distributeAmt > 0) {
            GRB.transfer(trader, _distributeAmt);
            emit onDistributeGarbi(trader, _distributeAmt);
        }
    }
    function getTradeFeeAPY(IERC20 _lp) public view returns(uint256) {
        uint256 _totalSupply = _lp.totalSupply(); // Base and Token = 2 * total supply
        uint256 _totalDays = totalDays[address(_lp)];
        uint256 _count = 0;
        uint256 _totalFee = 0;
        for (uint256 idx = _totalDays; idx >= 0; idx--) {
            _count += 1;
            _totalFee = _totalFee.add(feeOf[address(_lp)][idx]);
            if (_count >= 7) {
                break;
            }
        }
        if (_count <= 0) {
            return 0;
        }
        if (_totalSupply <= 0) {
            return 0;
        }
        uint256 _dailyFee = _totalFee.div(_count);
        return _dailyFee.mul(1e12).mul(365).div(_totalSupply.mul(2));
    }
    function getVolume(address _lp) public view returns(uint256) {
        uint256 _tradeFee = ISwapTrade(_lp).TRADE_FEE();
        uint256 _feeOnLastDay = feeOf[_lp][totalDays[_lp]];
        // TRADE_FEE = 35; //0.035% 35/100000
        // $1000 => fee = 1000*0.035/100 => 0.35
        // => Volume = 100000 * fee / TRADE_FEE
        return _feeOnLastDay.mul(100000).div(_tradeFee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IGarbiTimeLock {
	function doneTransactions(string memory _functionName) external;
	function clearFieldValue(string memory _functionName, string memory _fieldName, uint8 _typeOfField) external;
	function getAddressChangeOnTimeLock(address _contractCall, string memory _functionName, string memory _fieldName) external view returns(address); 
	function getUintChangeOnTimeLock(address _contractCall, string memory _functionName, string memory _fieldName) external view returns(uint256);
	function isQueuedTransaction(address _contractCall, string memory _functionName) external view returns(bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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