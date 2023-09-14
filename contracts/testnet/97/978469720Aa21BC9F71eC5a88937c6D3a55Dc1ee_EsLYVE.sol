// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract EsLYVE is ReentrancyGuard{
    using SafeMath for uint256;

    IERC20 public lyveToken;
    uint256 public totalEsLYVE;
    uint256 public nextVestingId = 1;
    mapping(address => uint256) public esLyveBalance;

    address public owner;
    bool public stoped;

    event Deposited(address indexed beneficiary, uint256 amount);
    event StartedVesting(address indexed account, uint256 amount, uint256 vestingId);
    event ClaimedVested(address indexed account, uint256 amount, uint256 vestingId);
    event DeleteVested(address indexed account, uint256 amount, uint256 id);

    struct Vesting {
        uint256 id;
        uint256 totalAmount;
        uint256 claimedAmount;
        uint256 lockedLYVE;
        uint256 startTime;
    }

   // mapping(address => Vesting[]) public vestings;
    mapping(address => mapping(uint256 => Vesting)) public vestings;

    mapping(address => uint256[]) public userVestingIds;

    constructor(address _lyveToken) {
        lyveToken = IERC20(_lyveToken);
        owner = msg.sender;
        stoped = false;
    }
    modifier onlyOwner() {
        require(msg.sender == owner ,"onlyFactory");
        _;
    }
   modifier notStoped() {
        require(!stoped ,"onlyFactory");
        _;
    }
    function setOwner(address _owner) external onlyOwner{        
        owner = _owner;
    }

    function stop(bool _stop) external onlyOwner{        
        stoped = _stop;
    }
    
    function depositEsLYVE(uint256 amount, address beneficiary)  external  nonReentrant{
        require(lyveToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        esLyveBalance[beneficiary] = esLyveBalance[beneficiary].add(amount);
        totalEsLYVE = totalEsLYVE.add(amount);

        emit Deposited(beneficiary, amount);
    }

    function startVesting(uint256 amount) external notStoped nonReentrant {
        require(amount > 0,"error amount");
        require(esLyveBalance[msg.sender] >= amount, "Insufficient esLYVE balance");
        require(lyveToken.transferFrom(msg.sender, address(this), amount), "LYVE transfer failed");

        esLyveBalance[msg.sender] = esLyveBalance[msg.sender].sub(amount);
        totalEsLYVE = totalEsLYVE.sub(amount);

        Vesting memory newVesting = Vesting({
            id: nextVestingId,   //  nextVestingId not vestings[msg.sender].length
            totalAmount: amount,
            claimedAmount: 0,
            lockedLYVE : amount,
            startTime: block.timestamp
        });
        vestings[msg.sender][nextVestingId] = newVesting;
        userVestingIds[msg.sender].push(nextVestingId);
        nextVestingId = nextVestingId.add(1);  //  nextVestingId 
        emit StartedVesting(msg.sender, amount, newVesting.id);
    }
    
    function claimAll( ) external notStoped  {        
        uint256[] memory vestingIds = userVestingIds[msg.sender];
        require(vestingIds.length > 0);
        for(uint256 i=0;i<vestingIds.length;i++){
            _claimVestedById(vestingIds[i]);
        }
    }
    function claimVestedById(uint256 id) external notStoped {        
        _claimVestedById(id);
    }
     function _claimVestedById(uint256 id) internal nonReentrant {        
        require(vestings[msg.sender][id].startTime != 0, "Invalid ID");  
        Vesting storage v = vestings[msg.sender][id];
        (uint256 claimable ,uint256 claimLockedLYVE)= _calculateClaimable(v);
        uint256 totalCalimable = claimable + claimLockedLYVE;
        require(totalCalimable > 0, "Nothing to claim");

        v.claimedAmount = v.claimedAmount.add(claimable);
        v.lockedLYVE = v.lockedLYVE.sub(claimLockedLYVE) ;
        require(v.lockedLYVE >= 0,"error lockedLYVE");
        require(lyveToken.transfer(msg.sender, totalCalimable), "Transfer failed");

        if (v.claimedAmount == v.totalAmount && block.timestamp.sub(v.startTime) >= 7 days
            && v.lockedLYVE == 0
         ) {
            delete vestings[msg.sender][id];  // delete vesting
            _removeUserVesting(msg.sender,id);
            emit DeleteVested(msg.sender, claimable, id);
        }
        emit ClaimedVested(msg.sender, claimable, id);
    }
    function _removeUserVesting(address _user, uint256 _vestingId) internal {
        uint256[] storage vestingIds = userVestingIds[_user];
        uint256 index;
        bool found = false;

        for (uint256 i = 0; i < vestingIds.length; i++) {
            if (vestingIds[i] == _vestingId) {
                index = i;
                found = true;
                break;
            }
        }
        require(found, "Vesting ID not found");
        // Swap the found vesting ID with the last element
        vestingIds[index] = vestingIds[vestingIds.length - 1];
        // Remove the last element
        vestingIds.pop();
    }

    function calculateClaimable(address account,uint256 id) external view returns (uint256,uint256) {
        Vesting memory v = vestings[account][id];
        if(v.startTime == 0){
            return (0,0);
        }
        return _calculateClaimable(v);
    }
    function _calculateClaimable(Vesting memory v) internal view returns (uint256,uint256) {
        uint256 timeElapsed = block.timestamp.sub(v.startTime);
        uint256 claimable;
        uint256 claimLockedLYVE ;

        if (timeElapsed >= 7 days) {
            claimable = v.totalAmount.sub(v.claimedAmount);
            claimLockedLYVE = v.lockedLYVE;
        } else {
            claimable = v.totalAmount.mul(timeElapsed).div(7 days).sub(v.claimedAmount);
        }
    
        return (claimable, claimLockedLYVE); 
    }

    function getBalanceRatio(address account) external view returns (uint256) {
        if (totalEsLYVE == 0) return 0;
        return esLyveBalance[account].mul(1e18).div(totalEsLYVE);
    }
    function getAllVesting(address account) public view returns ( Vesting[] memory ) {
        uint256[] memory vestingIds = userVestingIds[account];
        uint256 count = 0;
       for(uint256 i = 0;i < vestingIds.length ;i++){
            uint256 id = vestingIds[i];
            Vesting memory vesting = vestings[account][id];
            if(!_isNull(vesting)) count ++;
                
       }
       Vesting[] memory userVesting = new Vesting[](count);
        uint256 index = 0;
       for(uint256 i = 0;i < vestingIds.length ;i++){
            uint256 id = vestingIds[i];
            Vesting memory vesting = vestings[account][id];
            if( !_isNull(vesting)){
                userVesting[index] = vesting;
                index++;
            }
       }
      return userVesting;
    }
    function _isNull(Vesting memory vesting) internal pure returns(bool){
      return vesting.startTime == 0 && vesting.id == 0;
    }
    
}