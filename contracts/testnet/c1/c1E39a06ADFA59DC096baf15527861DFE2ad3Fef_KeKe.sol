// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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


pragma solidity ^0.8.17;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

contract KeKe is IERC20 , ReentrancyGuard {
      // TYPES DEFINITIONS
    using SafeMath for uint256;
    using Address for address;

    // state variables
    string public name;
    string public symbol;
    uint256 public decimals;
    uint256 public burnFee;
    uint256 public reflectFee;
    uint256 public minDistributeThreshold;

    uint256 private _totalSupply;
    uint256 private holders = 0;

    address private Owner; //owner


    // mappings
    mapping(address => uint256) private _balances; // balance mapping
    mapping(uint256 => address) private ownerToBalance; 
    mapping(address => mapping(address => uint256)) private _allowances; //allowance mapping
    mapping(address => bool) private _isExcludedFromFee; //fee exclusion mapping
    mapping(address => bool) private _isExcludedFromReflection; //rward exclusion mapping

    // events -- name defines the event comments unneeded
    event ExcludeFromFee(address indexed account, bool isExcluded);
    event SetFeePercentage(uint256 feePercentage , uint256 timestamp);
    event TransferOwnership(address indexed previousOwner , address indexed newOwner , uint256 timestamp);

    //Constructor
    /* 
    Basis Fee : 1 = 0.01 %
    */

    constructor(string memory _name, string memory _symbol, uint256 tottalsupply , uint256 _fee1 , uint256 _fee2 , uint256 _decimals, uint256 _threshhold) {
        _totalSupply = tottalsupply * (10**_decimals);
        _balances[msg.sender] = _totalSupply;
        ownerToBalance[holders] = msg.sender;
        name = _name;
        symbol = _symbol;
        reflectFee = _fee1;  
        burnFee = _fee2;
        decimals= _decimals;
        Owner = msg.sender;
        excludeFromFee(msg.sender);
        minDistributeThreshold = _threshhold * (10 ** decimals);
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /*
    View / Getter Functions
     */

    function getTotalHolders() public view returns(uint256){
        return holders.sub(1);
    }

    function getDividendPoolBalance() public view returns(uint256){
        return balanceOf(address(this));
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     function remainingSupply() public view returns (uint256) {
        uint256 totSupply = _totalSupply - _balances[address(0)];
        return totSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owwner, address spender) public view returns (uint256) {
        return _allowances[owwner][spender];
    }

    function getHolderIdByAddress(address account) public view returns (uint256) {
        for (uint256 i = 0; i < holders; i++) {
            if (ownerToBalance[i] == account) {
                return i; 
            }
        }
        revert("Holder not found for the given address");
    }

    function getHolderAdress(uint256 nonce) public view returns(address){
        return ownerToBalance[nonce];
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function owner() public view returns (address) {
        return Owner;
    }

    function isApproved(address account) public view returns (bool) {
        return _allowances[account][owner()] > 0;
    }

    function holderExists(address account) public view returns (bool) {
        return ownerToBalance[0] == account;
    }

    function getCurrentThreshHold() public view returns(uint256){
        return minDistributeThreshold;
    }

    /*
    Checks if wallet is Excluded from  Fee Mechanism

    returns bool
    */
    
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isExcludedFromReflection(address account) public view returns (bool) {
        return _isExcludedFromReflection[account];
    }
     /*
      * @dev transfer token 
      * @param recipient => the token recipient
      * @param amount => tokenAmount
      * returns bool
    */

    function transfer(address recipient, uint256 amount) public returns (bool) {
        if(!holderExists(recipient) && recipient != address(this) && recipient != address(0))
        {
            uint256 nonce = holders.add(1);
            ownerToBalance[nonce] = recipient;
            holders++;
        }
        if(balanceOf(msg.sender).sub(amount) == 0){
         uint256 id = getHolderIdByAddress(msg.sender);
         delete ownerToBalance[id];
        }
        if (_isExcludedFromFee[msg.sender]) {
            _transfer(msg.sender, recipient, amount);
        }else{
            uint256 feeAmount1 = amount.mul(burnFee).div(10000);
            uint256 feeAmount2 = amount.mul(reflectFee).div(10000);
            uint256 totalFee = feeAmount1.add(feeAmount2);
            uint256 amtAfterFee = amount.sub(totalFee);

            //transfer applicable fee and transfers tokens after fee to reciever

            _transfer(msg.sender, recipient, amtAfterFee);
            _transfer(msg.sender, address(0), feeAmount1);
            _transfer(msg.sender, address(this), feeAmount2);  
        }
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _allowances[sender][msg.sender] = currentAllowance.sub(amount);
        if(!holderExists(recipient) && recipient != address(this) && recipient != address(0))
        {
            uint256 nonce = holders.add(1);
            ownerToBalance[nonce] = recipient;
            holders++;
        }
        if(balanceOf(sender).sub(amount) == 0){
         uint256 id = getHolderIdByAddress(sender);
         delete ownerToBalance[id];
        }
        if (_isExcludedFromFee[msg.sender]) {
            _transfer(sender, recipient, amount);
        } else {
            uint256 feeAmount1 = amount.mul(burnFee).div(10000);
            uint256 feeAmount2 = amount.mul(reflectFee).div(10000);
            uint256 totalFee = feeAmount1.add(feeAmount2);
            uint256 amtAfterFee = amount.sub(totalFee);

            //transfer applicable fee and transfers tokens after fee to reciever

            _transfer(sender, recipient, amtAfterFee);
            _transfer(sender,address(0), feeAmount1);
            _transfer(sender, address(this), feeAmount2);
        }
        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal nonReentrant {
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount); 
        emit Transfer(sender, recipient, amount);
    }

    //Burn Function

    function burn(uint256 amount) public returns(bool) {
        require(_balances[msg.sender] >= amount, "ERC20: burn amount exceeds balance");
        _balances[msg.sender] -= amount;
        _balances[address(0)] += amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    //DAO Functions to Set Fee and Fee Reciever

    function setFee(uint256 _fee1, uint256 _fee2) public returns(bool) {
        require(msg.sender == owner(), "Only the owner can set the fee");
        burnFee = _fee1;
        reflectFee = _fee2;
        emit SetFeePercentage(_fee1 + _fee2 , block.timestamp);
        return true;
    }

    //DAO Functions to set Limits and Exceptions
    function excludeFromFee(address account) public returns(bool){
        require(msg.sender == owner(), "Only the owner can exclude addresses from fees");
        require(_isExcludedFromFee[account] == false ,"account already excluded");
        _isExcludedFromFee[account] = true;
        emit ExcludeFromFee(account, true);
        return true;
    }
    function excludeFromReflection(address account) public returns(bool){
        require(msg.sender == owner(), "Only the owner can exclude addresses from fees");
        require(_isExcludedFromReflection[account] == false ,"account already excluded");
        _isExcludedFromReflection[account] = true;
        return true;
    }
    function includeInReflection(address account) public returns(bool){
        require(msg.sender == owner(), "Only the owner can exclude addresses from fees");
        require(_isExcludedFromReflection[account] == true ,"account already excluded");
        _isExcludedFromReflection[account] = false;
        return true;
    }

    function includeInFee(address account) public returns(bool) {
        require(msg.sender == owner(), "Only the owner can exclude addresses from fees");
        require(_isExcludedFromFee[account] == true ,"account already included");
        _isExcludedFromFee[account] = false;
        emit ExcludeFromFee(account, false);
        return true;
    }

    //Transfer Ownership

    function transferOwnership(address newOwner) public returns(bool){
        require (msg.sender == Owner,"OnlyOwner can do this");
        address oldOwner = Owner;
        Owner = newOwner;
        emit TransferOwnership(oldOwner , newOwner , block.timestamp);
        return true;
    }
    
    function distributeDividends() external returns(bool){
        uint256 totalBalance = _balances[address(this)];
        require(totalBalance > minDistributeThreshold, "Distribution Limit Not Reached");

        for (uint256 i = 0; i < holders; i++) {
            address holder = ownerToBalance[i];
            uint256 holderBalance = _balances[holder];
            uint256 distributionAmount = totalBalance.mul(holderBalance).div(_totalSupply);
            if(!_isExcludedFromReflection[holder]){
                _transfer(address(this), holder , distributionAmount);
            }
        }
        return true;
    }

    function changeThreshold(uint256 newThreshold) public returns(bool){
        require(msg.sender == Owner,"Need To Be Owner");
        minDistributeThreshold = newThreshold;
        return true;
    }
}