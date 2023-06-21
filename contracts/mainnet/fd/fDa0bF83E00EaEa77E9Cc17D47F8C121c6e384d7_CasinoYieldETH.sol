/**
 *Submitted for verification at Arbiscan on 2023-06-21
*/

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: contracts/1_Storage.sol


pragma solidity ^0.8.15;


/*
✅ Casino Yield ETH Liquidity Protocol Official Smart Contract.
Stake, Earn Daily Rewards.
*/

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

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

contract CasinoYieldETH is Ownable, Pausable, ReentrancyGuard {

    using SafeMath for uint256;
    bool public started;
    uint256 public apr = 150;  // Daily apr is 1.5%
    uint256 public percentRate = 10000;
    uint256[3] public STAKE_PERCENTAGES = [500, 200, 100]; // Stake Referral Percentage: Level 1: 5%, Level 2: 2%, Level 3: 1%
    uint256[3] public CLAIM_PERCENTAGES = [1000, 500, 200]; // Claim Referral Percentage: Level 1: 10%, Level 2: 5%, Level 3: 2%
   
    address public devAddress;
    uint256 public devFee = 300;
    uint256 public totalInvestors = 0;
    uint256 public totalReward = 0;
    uint256 public totalInvested = 0;    
    mapping(address => bool) public left;
    mapping(address => Stake) public stake;
    mapping(address => address[]) public level1;
    mapping(address => address[]) public level2;
    mapping(address => address[]) public level3;    

    struct Stake {
        uint256 stake;
        uint256 notWithdrawn;
        uint256 timestamp;
        address partner;
        uint256 totalRefReward;
    }

    event StakeChanged(address indexed user, address indexed partner, uint256 amount);

    modifier whenStarted {
        require(started, "Not started yet");
        _;
    }

     constructor(address _devAddress) {      
         devAddress = _devAddress;
    }


    receive() external payable {}

    function start() external payable onlyOwner {
        started = true;
    }

    function getLevel1Data(address account) external view returns(address[] memory){
        return level1[account];
    }

    function getLevel2Data(address account) external view returns(address[] memory){
        return level2[account];
    }

    function getLevel3Data(address account) external view returns(address[] memory){
        return level3[account];
    }

    function deposit(address partner) external payable whenStarted nonReentrant {
        require(!left[_msgSender()], "Left");       
        if (stake[_msgSender()].timestamp == 0) {
            require(partner != _msgSender(), "Cannot set your own address as partner");
            stake[_msgSender()].partner = partner;
            if(partner != address(0)) {
                address _partner = partner;
                uint i = 0;
                while(_partner != address(0)) {
                    if(i == 0) {
                        level1[_partner].push(_msgSender());
                    } else if(i == 1) {
                        level2[_partner].push(_msgSender());
                    } else if(i ==2) {
                        level3[_partner].push(_msgSender());
                    } else {
                        break;
                    }
                    _partner = stake[_partner].partner;
                    i++;
                }
            }
            totalInvestors = totalInvestors.add(1);
        }
        uint256 depositFee = (msg.value * devFee).div(percentRate);
        payable(devAddress).transfer(depositFee);

         _updateNotWithdrawn();
        stake[_msgSender()].stake = stake[_msgSender()].stake + (msg.value - depositFee);
        totalInvested = totalInvested.add(msg.value - depositFee);
        sendReferralAmount(msg.sender, (msg.value - depositFee), true);
        emit StakeChanged(_msgSender(), stake[_msgSender()].partner, stake[_msgSender()].stake);
    }

    function reinvest() external whenStarted nonReentrant {
        _updateNotWithdrawn();
        require(stake[_msgSender()].notWithdrawn > 20000000000000000, "Too low amount to reinvest");
        require(!left[_msgSender()], "Left");
        stake[_msgSender()].stake += stake[_msgSender()].notWithdrawn;
        stake[_msgSender()].notWithdrawn = 0;
        emit StakeChanged(_msgSender(), stake[_msgSender()].partner, stake[_msgSender()].stake);
    }

    function getStakerInfo(address _investorAddress) public view returns(
        address investor,
        uint256 totalLocked,
        uint256 startTime,
        uint256 lastCalculationDate,
        uint256 claimableAmount
        ){
        investor = _investorAddress;
        totalLocked = stake[_investorAddress].stake;
        startTime = stake[_investorAddress].timestamp;
        lastCalculationDate = stake[_investorAddress].timestamp;
        claimableAmount = pendingReward(_investorAddress);
    }

    
    function leaveCasinoYield() external {
        require(stake[_msgSender()].stake > 0, "You didn't deposit yet");
        require(!left[_msgSender()], "This wallet address has already left CasinoYield.io");
        claimReward();
        left[_msgSender()] = true;
        _updateNotWithdrawn();
    }

    function claimReward() public whenStarted whenNotPaused nonReentrant {
        require(!left[_msgSender()], "Left");
        _updateNotWithdrawn();
        uint256 amount = stake[_msgSender()].notWithdrawn;
        require( amount > 0, "Balance too low");
        stake[_msgSender()].notWithdrawn = 0;
        payable(_msgSender()).transfer(amount);
        totalReward = totalReward.add(amount);
        sendReferralAmount(msg.sender, amount, false);
    }

    function claimContributeBonus() private whenStarted whenNotPaused{
        uint256 amount = stake[_msgSender()].stake / 100;
        require( amount > 0, "Balance too low");
        payable(_msgSender()).transfer(amount);
        totalReward = totalReward.add(amount);
    }

    function pendingReward(address account) public view returns(uint256) {
        return ((stake[account].stake * (block.timestamp - stake[account].timestamp) * apr) / 86400 / 10000);
    }

    function _updateNotWithdrawn() private {
        uint256 pending = pendingReward(_msgSender());
        stake[_msgSender()].timestamp = block.timestamp;
        stake[_msgSender()].notWithdrawn += pending;
    }

    function sendReferralAmount(address investor, uint256 amount, bool isStakingReferral) internal {
        address _partner = stake[investor].partner;
        for(uint256 i = 0; i < 3; i++) {                
            if(_partner == address(0)) break;
            uint256 refAmount = (amount * (isStakingReferral ? STAKE_PERCENTAGES[i] : CLAIM_PERCENTAGES[i])).div(percentRate);
            payable(_partner).transfer(refAmount);
            stake[_partner].totalRefReward = stake[_partner].totalRefReward.add(refAmount);
            _partner = stake[_partner].partner;
        }
    }

    function updateApr(uint256 _apr) public onlyOwner {
        require(_apr <= 500, "Maximum Daily APR is 5%");
        apr = _apr;
    }

    function getReferralInfo(address account) external view returns(
        uint256 referralCounts,
        uint256 totalDepoited,
        uint256 earnedReward,
        uint256 claimableReward){
            for(uint8 i = 0; i < level1[account].length; i++) {
                totalDepoited = totalDepoited.add(stake[level1[account][i]].stake);
                earnedReward = earnedReward.add(stake[level1[account][i]].totalRefReward);
                claimableReward = claimableReward.add(stake[level1[account][i]].notWithdrawn);
            }
            for(uint8 i = 0; i < level2[account].length; i++) {
                totalDepoited = totalDepoited.add(stake[level2[account][i]].stake);
                earnedReward = earnedReward.add(stake[level2[account][i]].totalRefReward);
                claimableReward = claimableReward.add(stake[level2[account][i]].notWithdrawn);
            }
            for(uint8 i = 0; i < level3[account].length; i++) {
                totalDepoited = totalDepoited.add(stake[level3[account][i]].stake);
                earnedReward = earnedReward.add(stake[level3[account][i]].totalRefReward);
                claimableReward = claimableReward.add(stake[level3[account][i]].notWithdrawn);
            }
        referralCounts = level1[account].length + level2[account].length + level3[account].length;
    }

    function withdrawCapital() external {
        require(left[_msgSender()], "Error");
        require(block.timestamp - stake[_msgSender()].timestamp > 7 days, "Error: Withdrawing ALL balance (Deposit + Rewards) is available 7 days after Leaving Casino Yield - Read FAQ");
        require(stake[_msgSender()].stake > 0, "Zero Balance");
        claimContributeBonus();
        uint256 amount = stake[_msgSender()].notWithdrawn + stake[_msgSender()].stake;
        stake[_msgSender()].notWithdrawn = 0;
        stake[_msgSender()].stake = 0;
        left[_msgSender()] = false;
        payable(_msgSender()).transfer(amount);
    }

    function deinitialize() external onlyOwner {
        _pause();
    }

    function initialize() external onlyOwner {
        _unpause();
    }
}