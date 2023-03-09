/**
 *Submitted for verification at Arbiscan on 2023-03-08
*/

/*
    LLamiFi Miner - Arbitrum ETH Miner
    Developed by Kraitor <TG: kraitordev>
*/

// SPDX-License-Identifier: MIT

// File: LLamiFiMiner/BasicLibraries/Auth.sol


pragma solidity ^0.8.9;

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}
// File: LLamiFiMiner/Libraries/InvestorsManager.sol


pragma solidity ^0.8.9;

contract InvestorsManager {

    //INVESTORS DATA
    uint64 private nInvestors = 0;
    uint64 private totalReferralsUses = 0;
    uint256 private totalReferralsRewardTokens = 0;
    mapping (address => investor) private investors; //Investor data mapped by address
    mapping (uint64 => address) private investors_addresses; //Investors addresses mapped by index

    struct investor {
        address investorAddress;//Investor address        
        uint256 investment;     //Total investor investment on miner (real BNB, presales/airdrops not taken into account)
        uint256 withdrawal;     //Total investor withdraw BNB from the miner
        uint256 hiredMiners;    //Total hired miners
        uint256 claimedRTokens; //Total reward tokens claimed (produced by miners)
        uint256 lastHire;       //Last time you hired machines
        uint256 sellsTimestamp; //Last time you sold your reward tokens
        uint256 nSells;         //Number of sells you did
        uint256 referralRTokens;//Number of reward tokens you got from people that used your referral address
        uint256 referralETH;    //ETH invested from people that used your referral address
        address referral;       //Referral address you used for joining the miner
        uint256 lastSellAmount; //Last sell amount
        uint256 customSellTaxes;//Custom tax set by admin
        uint256 referralUses;   //Number of addresses that used his referral address
        uint256 joinTimestamp;  //Timestamp when the user joined the miner
        uint256 tokenSpent;     //Amount of BNB spent on buying tokens
        uint256 minersSelling;  //Amount of miners on market
        uint8 discountMiners;   //Discount on miners sell
    }

    function initializeInvestor(address adr) internal {
        if(investors[adr].investorAddress != adr){
            investors_addresses[nInvestors] = adr;
            investors[adr].investorAddress = adr;
            investors[adr].sellsTimestamp = block.timestamp;
            investors[adr].joinTimestamp = block.timestamp;
            nInvestors++;
        }
    }

    function getNumberInvestors() public view returns(uint64) { return nInvestors; }

    function getTotalReferralsUses() public view returns(uint64) { return totalReferralsUses; }

    function getTotalReferralsRewardTokens() public view returns(uint256) { return totalReferralsRewardTokens; }

    function getInvestorData(uint64 investor_index) public view returns(investor memory) { return investors[investors_addresses[investor_index]]; }

    function getInvestorData(address addr) public view returns(investor memory) { return investors[addr]; }

    function getInvestorInvestment(address addr) public view returns(uint256) { return investors[addr].investment; }

    function getInvestorWithdrawal(address addr) public view returns(uint256) { return investors[addr].withdrawal; }

    function getInvestorMiners(address addr) public view returns(uint256) { return investors[addr].hiredMiners; }

    function getInvestorClaimedRTokens(address addr) public view returns(uint256) { return investors[addr].claimedRTokens; }

    function getInvestorMinersSelling(address addr) public view returns(uint256) { return investors[addr].minersSelling; }

    function getInvestorMinersDiscount(address addr) public view returns(uint8) { return investors[addr].discountMiners; }

    function getReferral(address addr) public view returns(address) { return investors[addr].referral; }

    function getReferralData(address addr) public view returns(investor memory) { return investors[investors[addr].referral]; }

    function getReferralUses(address addr) public view returns(uint256) { return investors[addr].referralUses; }

    function getInvestorJoinTimestamp(address addr) public view returns(uint256) { return investors[addr].joinTimestamp; }

    function getInvestorSellsTimestamp(address addr) public view returns(uint256) { return investors[addr].sellsTimestamp; }

    function getInvestorTokenSpent(address addr) public view returns(uint256) { return investors[addr].tokenSpent; }

    function getReferralETH(address addr) public view returns(uint256) { return investors[addr].referralETH; }

    function fundsRecovered(address addr) public view returns(bool) { return investors[addr].withdrawal >= investors[addr].investment; }

    function setInvestorAddress(address addr) internal { investors[addr].investorAddress = addr; }

    function addInvestorInvestment(address addr, uint256 investment) internal { investors[addr].investment += investment; }

    function addInvestorWithdrawal(address addr, uint256 withdrawal) internal { investors[addr].withdrawal += withdrawal; }

    function addReferralETH(address addr, uint256 eth) internal { investors[addr].referralETH += eth; }

    function setInvestorHiredMiners(address addr, uint256 hiredMiners) internal { investors[addr].hiredMiners = hiredMiners; }

    function setInvestorMinersSelling(address addr, uint256 _minersSelling) internal { 
        require(_minersSelling <= investors[addr].hiredMiners, 'You do not have that amount of miners'); 
        investors[addr].minersSelling = _minersSelling; 
    }

    function setInvestorDiscountMiners(address addr, uint8 _minersDiscount) internal {
        require(_minersDiscount <= 10, 'You can not sell your miners cheaper than 80% of current price');
        investors[addr].discountMiners = _minersDiscount;
    }

    function setInvestorClaimedRTokens(address addr, uint256 claimedRTokens) internal { investors[addr].claimedRTokens = claimedRTokens; }

    function setInvestorRTokensByReferral(address addr, uint256 rTokens) internal { 
        if(addr != address(0)){
            totalReferralsRewardTokens += rTokens; 
            totalReferralsRewardTokens -= investors[addr].referralRTokens; 
        }
        investors[addr].referralRTokens = rTokens; 
    }    

    function setInvestorLastHire(address addr, uint256 lastHire) internal { investors[addr].lastHire = lastHire; }

    function setInvestorSellsTimestamp(address addr, uint256 sellsTimestamp) internal { investors[addr].sellsTimestamp = sellsTimestamp; }

    function setInvestorNsells(address addr, uint256 nSells) internal { investors[addr].nSells = nSells; }

    function setInvestorReferral(address addr, address referral) internal { investors[addr].referral = referral; investors[referral].referralUses++; totalReferralsUses++; }

    function setInvestorLastSell(address addr, uint256 amount) internal { investors[addr].lastSellAmount = amount; }

    function setInvestorCustomSellTaxes(address addr, uint256 customTax) internal { investors[addr].customSellTaxes = customTax; }

    function increaseReferralUses(address addr) internal { investors[addr].referralUses++; }

    function increaseInvestorTokenSpent(address addr, uint256 _spent) internal { investors[addr].tokenSpent += _spent; }

    constructor(){}
}
// File: LLamiFiMiner/Libraries/IProject.sol


pragma solidity ^0.8.9;

interface IProject {
    function reinvestment(address _who) external payable;
}
// File: LLamiFiMiner/Libraries/IProjectBonus.sol


pragma solidity ^0.8.9;

interface IProjectBonus {
    function getMinerROIBonus(address _who) external view returns(uint8);
}
// File: LLamiFiMiner/Libraries/IERC20.sol


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

// File: LLamiFiMiner/Libraries/IDEXRouter.sol


pragma solidity ^0.8.9;

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}
// File: LLamiFiMiner/BasicLibraries/Context.sol


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

// File: LLamiFiMiner/BasicLibraries/Ownable.sol


pragma solidity ^0.8.9;


contract Ownable is Context {
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
    function owner() public view returns (address) {
      return _owner;
    }

    
    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

    function renounceOwnership() public onlyOwner {
      emit OwnershipTransferred(_owner, address(0));
      _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
}
// File: LLamiFiMiner/BasicLibraries/SafeMath.sol


pragma solidity ^0.8.9;

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
// File: LLamiFiMiner/Timer.sol


pragma solidity ^0.8.9;



/**
 * @title Universal store of current contract time for testing environments.
 */
contract Timer is Auth {
    using SafeMath for uint256;
    uint256 private currentTime;

    bool enabled = false;

    constructor() Auth(msg.sender) { }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set `currentTime` to.
     */
    function setCurrentTime(uint256 time) external authorized {
        require(time >= currentTime, "Return to the future Doc!");
        currentTime = time;
    }

    function enable(bool _enabled) external authorized {
        require(enabled == false, 'Can not be disabled');
        enabled = _enabled;
    }

    function increaseDays(uint256 _days) external authorized {
        currentTime = getCurrentTime().add(uint256(1 days).mul(_days));
    }

    function increaseMinutes(uint256 _minutes) external authorized {
        currentTime = getCurrentTime().add(uint256(1 minutes).mul(_minutes));
    }

    function increaseSeconds(uint256 _seconds) external authorized {
        currentTime = getCurrentTime().add(uint256(1 seconds).mul(_seconds));
    }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint256 for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        if(enabled){
            return currentTime;
        }
        else{
            return block.timestamp;
        }
    }
}
// File: LLamiFiMiner/Libraries/Testable.sol


pragma solidity ^0.8.9;


/**
 * @title Base class that provides time overrides, but only if being run in test mode.
 */
abstract contract Testable {
    // If the contract is being run on the test network, then `timerAddress` will be the 0x0 address.
    // Note: this variable should be set on construction and never modified.
    address public timerAddress;

    /**
     * @notice Constructs the Testable contract. Called by child contracts.
     * @param _timerAddress Contract that stores the current time in a testing environment.
     * Must be set to 0x0 for production environments that use live time.
     */
    constructor(address _timerAddress) {
        timerAddress = _timerAddress;
    }

    /**
     * @notice Reverts if not running in test mode.
     */
    modifier onlyIfTest {
        require(timerAddress != address(0x0));
        _;
    }

    /**
     * @notice Sets the current time.
     * @dev Will revert if not running in test mode.
     * @param time timestamp to set current Testable time to.
     */
    // function setCurrentTime(uint256 time) external onlyIfTest {
    //     Timer(timerAddress).setCurrentTime(time);
    // }

    /**
     * @notice Gets the current time. Will return the last time set in `setCurrentTime` if running in test mode.
     * Otherwise, it will return the block timestamp.
     * @return uint for the current Testable timestamp.
     */
    function getCurrentTime() public view returns (uint256) {
        if (timerAddress != address(0x0)) {
            return Timer(timerAddress).getCurrentTime();
        } else {
            return block.timestamp;
        }
    }
}
// File: LLamiFiMiner/Libraries/MinerBasic.sol


pragma solidity ^0.8.9;





abstract contract MinerBasic {

    using SafeMath for uint256;

    //region Basic
    event Hire(address indexed adr, uint256 rTokens, uint256 amount);
    event Sell(address indexed adr, uint256 rTokens, uint256 amount, uint256 penalty);
    event RehireMiners(address _investor, uint256 _newMiners, uint256 _hiredMiners, uint256 _nInvestors, uint256 _referralRTokens, uint256 _marketRTokens, uint256 _RTokensUsed);
    function hireMiners(address ref) public payable virtual;
    function rehireMiners() public virtual;
    function sellRewards() public virtual;

    uint32 internal REWARD_TOKENS_TO_HIRE_1MINER = 2880000; // 2880000/24*60*60 = 33.333 days to recover your investment (100/33.333 = 3% DAILY ROI)
    uint16 internal constant PSN = 10000;
    uint16 internal constant PSNH = 5000;
    bool internal initialized = false;
    uint256 internal marketRewardTokens;  // This variable is responsible for inflation.
    uint256 constant internal sellInflation = 60;
    uint256 constant internal rehireInflation = 20;
    function isInitialized() public view returns (bool) { return initialized; }
    function seedMarket() public virtual payable;
    function _seedMarket() internal {
        require(marketRewardTokens == 0);
        initialized = true;
        marketRewardTokens = 108000000000;
    }
    function getMarketRewardTokens() public view returns(uint256) { return marketRewardTokens; }
    function applyInflation(uint256 _rewardTokens, bool isSell) internal { marketRewardTokens += _rewardTokens.mul(isSell ? sellInflation : rehireInflation).div(100); }
    function applyMinersBurn(uint256 _minersBurned) internal { marketRewardTokens -= _minersBurned.mul(REWARD_TOKENS_TO_HIRE_1MINER).mul(rehireInflation).div(100); }
    function applyFundsRecoveredPenalty(uint256 _amount, bool recovered) public pure returns(uint256) { return recovered ? _amount.div(2) : _amount; }                                         
    function min(uint256 a, uint256 b) internal pure returns (uint256) { return a < b ? a : b; }
    function max(uint256 a, uint256 b) internal pure returns (uint256) { return a < b ? b : a; }
    function isContract(address account) internal view returns (bool) { return account.code.length > 0; }
    //endregion

    //region Hire bonus
    function hireBonusByDeposit(uint256 _tAmount, uint256 _paymentETH) public pure returns(uint256) {
        if(_paymentETH > 5 ether){
            return _tAmount.mul(110).div(100);
        }
        if(_paymentETH > 4 ether){
            return _tAmount.mul(109).div(100);
        }
        if(_paymentETH > 3 ether){
            return _tAmount.mul(108).div(100);
        }
        if(_paymentETH > 2 ether){
            return _tAmount.mul(107).div(100);
        }
        if(_paymentETH > 1 ether){
            return _tAmount.mul(106).div(100);
        }
        if(_paymentETH > 0.5 ether){
            return _tAmount.mul(105).div(100);
        }
        return _tAmount;
    }
    uint8 public tempHireBonus = 0;
    function setHireBonusTemp(uint8 _pcBonus) public virtual;
    function _setHireBonusTemp(uint8 _pcBonus) internal {
        require(_pcBonus <= 20, 'Temporal hire bonus can not be bigger than 20%');
        tempHireBonus = _pcBonus;
    }
    function applyHireBonusTemp(uint256 _amount) public view returns(uint256) { return _amount.mul(100 + tempHireBonus).div(100); }
    //endregion

    //region ROI bonus
    address internal roiBonus1;
    address internal roiBonus2;
    function setROIBonusProjects(address _roiBonus1, address _roiBonus2) public virtual;
    function roiBonusByProject(uint256 _tAmount, address _who) public view returns(uint256) {
        uint256 _max = _tAmount.mul(130).div(100); // 30% total bonus max
        bool isValid = true;
        try IProjectBonus(roiBonus1).getMinerROIBonus(_who) {}catch{ isValid = false; }
        if(isValid){
            uint8 bonus = IProjectBonus(roiBonus1).getMinerROIBonus(_who);
            _tAmount = _tAmount.mul(100 + bonus).div(100);
        }
        isValid = true;
        try IProjectBonus(roiBonus2).getMinerROIBonus(_who) {}catch{ isValid = false; }
        if(isValid){
            uint8 bonus = IProjectBonus(roiBonus2).getMinerROIBonus(_who);
            _tAmount = _tAmount.mul(100 + bonus).div(100);
        }
        return min(_tAmount, _max);
    }
    //endregion

    //region Referrals
    uint8 internal referralPcReward = 10; // Referral receives 10% from people using his link
    address internal defaultReferral = address(0);
    function getDefaultReferral() public view returns(address) { return defaultReferral; }
    function setDefaultReferral(address _defaultReferral) public virtual; //owner
    function applyRefBonus(uint256 _amount, uint256 _ethInvestedRefs) public pure returns(uint256) {
        if(_ethInvestedRefs >= 10 ether){
            return _amount.mul(5).div(3); //x1.66 -> 3% -> 5% ROI
        }
        if(_ethInvestedRefs >= 3 ether){
            return _amount.mul(4).div(3); //x1.33 -> 3% -> 4% ROI
        }
        if(_ethInvestedRefs >= 1 ether){
            return _amount.mul(7).div(6); //x1.166 -> 3% -> 3.5% ROI
        }
        if(_ethInvestedRefs >= 0.5 ether){
            return _amount.mul(11).div(10); //x1.1 -> 3% -> 3.3% ROI
        }
        return _amount;
    }    
    function getReferralPcReward(uint256 _amount) public view returns(uint256) { return _amount.mul(referralPcReward).div(100); }
    //endregion

    //region Taxes
    uint8 constant public depositTaxOver1000 = 25; // 2.5%
    function applyDepositTax(uint256 _amount) public pure returns(uint256, uint256) { 
        uint256 taxed = _amount.mul(depositTaxOver1000).div(1000);
        return (_amount.sub(taxed), taxed);
    }
    function getWithdrawTax(uint256 _timestampNow, uint256 _lastWithdrawTimestamp, bool reinvest) public pure returns(uint256) {
        uint256 _secs = _timestampNow > _lastWithdrawTimestamp ? _timestampNow.sub(_lastWithdrawTimestamp) : 0;
        uint256 _days = _secs.div(3600).div(24);
        uint256 _tax = reinvest ? 3 : 5;
        if(_days >= 0){
            _tax = reinvest ? 15 : 30;
        }
        if(_days >= 3){
            _tax = reinvest ? 10 : 20;
        }
        if(_days >= 5){
            _tax = reinvest ? 5 : 10;
        }
        if(_days >= 7){
            _tax = reinvest ? 3 : 5;
        }
        if(_days >= 10){
            _tax = reinvest ? 2 : 3;
        }
        if(_days >= 12){
            _tax = reinvest ? 1 : 2;
        }
        if(_days >= 14){
            _tax = 0;
        }
        return _tax;
    }
    function applyWithdrawTax(uint256 _amount, uint256 _timestampNow, uint256 _lastWithdrawTimestamp, bool reinvest) public pure returns(uint256, uint256){
        uint256 _tax = getWithdrawTax(_timestampNow, _lastWithdrawTimestamp, reinvest);
        uint256 _taxedAmount = _amount.mul(_tax).div(100);
        return (_amount.sub(_taxedAmount), _taxedAmount);
    }
    //endregion

    //region Taxes receivers
    address public tokenLiqReceiver;    // liquidity added to token and sent here    
    address public proy1Receiver;
    //TLV
    address public treasuryReceiver;
    address public charityReceiver;
    address public stakingPoolReceiver; // tokens are bought and sent here
    function _setTaxReceivers(address _tokenLiqReceiver, address _proy1Receiver, address _treasuryReceiver, address _charityReceiver, address _stakingPoolReceiver) internal {
        tokenLiqReceiver = _tokenLiqReceiver;   
        proy1Receiver = _proy1Receiver;
        treasuryReceiver = _treasuryReceiver;
        charityReceiver = _charityReceiver;
        stakingPoolReceiver = _stakingPoolReceiver;
    }
    function setTaxReceivers(address _tokenLiqReceiver, address _proy1Receiver, address _treasuryReceiver, address _charityReceiver, address _stakingPoolReceiver) public virtual; // owner
    //endregion

    //region Tax distribution
    uint8 public tokenLiq = 35;
    uint8 public proy1 = 0;
    uint8 public TLV = 10;
    uint8 public treasury = 40;
    uint8 public charity = 0;
    uint8 public stakingPool = 15;
    function _setTaxDistribution(uint8 _tokenLiq, uint8 _proy1, uint8 _TLV, uint8 _treasury, uint8 _charity, uint8 _stakingPool) internal {
        require(_tokenLiq + _proy1 + _TLV + _treasury + _charity + _stakingPool == 100, 'Tax distribution has to sum up 100');
        tokenLiq = _tokenLiq;
        proy1 = _proy1;
        TLV = _TLV;
        treasury = _treasury;
        charity = _charity;
        stakingPool = _stakingPool;
    }
    function setTaxDistribution(uint8 _tokenLiq, uint8 _proy1, uint8 _TLV, uint8 _treasury, uint8 _charity, uint8 _stakingPool) public virtual; //owner
    //endregion

    //region Router for related token payments
    IDEXRouter dexRouter;
    IERC20 tokenIface;
    function _approve() internal { try tokenIface.approve(address(dexRouter), type(uint256).max) {}catch{} }
    function _setDexRouter(address _adr) internal { 
        bool isValid = true;
        require(isContract(_adr), "The address is not a contract");
        dexRouter = IDEXRouter(_adr); 
        try dexRouter.WETH() {}catch{ isValid = false; }
        require(isValid, "You can only set a valid router");
        _approve();
    }
    function setDexRouter(address _adr) public virtual; //owner
    function _setToken(address _tokenAdr) internal { 
        bool isValid = true;
        require(isContract(_tokenAdr), "The address is not a contract");
        tokenIface = IERC20(_tokenAdr);
        try tokenIface.balanceOf(address(this)) {}catch{ isValid = false; }
        require(isValid, "You can only set a valid token");
        _approve(); 
    }
    function setToken(address _tokenAdr) public virtual; //owner
    //endregion

    //region Tax payment
    function taxPayment(uint256 _amountTaxedETH) internal {
        uint256 _tokenLiq = _amountTaxedETH.mul(tokenLiq).div(100);
        uint256 _proy1 = _amountTaxedETH.mul(proy1).div(100);
        //uint256 _TLV = _amountTaxedETH.mul(TLV).div(100); //stays in contract
        uint256 _treasury = _amountTaxedETH.mul(treasury).div(100);
        uint256 _charity = _amountTaxedETH.mul(charity).div(100);
        uint256 _stakingPool = _amountTaxedETH.mul(stakingPool).div(100);

        bool success;
        if(_proy1 > 0 && proy1Receiver != address(0)){ success = payable(proy1Receiver).send(_proy1); }
        if(_treasury > 0 && treasuryReceiver != address(0)){ success = payable(treasuryReceiver).send(_treasury); }
        if(_charity > 0 && charityReceiver != address(0)){ success = payable(charityReceiver).send(_charity); }
        success = true;

        if(isContract(address(dexRouter)) && isContract(address(tokenIface))){
            try dexRouter.WETH() {}catch{ success = false; }

            if(success){
                address [] memory path = new address[](2);
                path[0] = dexRouter.WETH();
                path[1] = address(tokenIface);

                // _tokenLiq, add liq to token
                if(_tokenLiq > 0){
                    uint256 oldBal = tokenIface.balanceOf(address(this));
                    try dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value:_tokenLiq.div(2)}(
                        0,
                        path,
                        address(this),
                        block.timestamp
                    ) {}catch{}
                    uint256 newBal = tokenIface.balanceOf(address(this));
                    uint256 tokensBought = newBal.sub(oldBal);
                    try dexRouter.addLiquidityETH{value:_tokenLiq.div(2)}(
                        address(tokenIface),
                        tokensBought,
                        0,
                        0,
                        tokenLiqReceiver,
                        block.timestamp
                    ) {}catch{}
                }

                // _stakingPool, buy tokens send them to staking pool
                if(_stakingPool > 0){
                    uint256 oldBal = tokenIface.balanceOf(address(this));
                    try dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value:_stakingPool}(
                        0,
                        path,
                        address(this),
                        block.timestamp
                    ) {}catch{}
                    uint256 newBal = tokenIface.balanceOf(address(this));
                    uint256 tokensBought = newBal.sub(oldBal);
                    try tokenIface.transfer(stakingPoolReceiver, tokensBought) {}catch{}
                }
            }
        }
    }
    //endregion

    //region Max buy
    uint256 internal maxBuy = (100 ether);
    function getMaxBuy() public view returns(uint256) { return maxBuy; }
    function setMaxBuy(uint256 _maxBuy) public virtual; //owner
    function isUnderMaxBuy(uint256 _amount) public view returns(bool) { return _amount <= maxBuy; }
    //endregion

    //region Max sell % of TLV default 1%
    uint256 internal maxSellNum = 10; // Max sell TVL num
    uint256 internal maxSellDiv = 1000; // Max sell TVL div //For example: 10 and 1000 -> 10/1000 = 1/100 = 1% of TVL max sell
    function getMaxSell() public view returns(uint256) { return getBalance().mul(maxSellNum).div(maxSellDiv); }
    function setMaxSell(uint256 _maxSellNum, uint256 _maxSellDiv) public virtual; //owner 
    function capToMaxSell(uint256 _ethAmount) public view returns(uint256, uint256) { 
        uint256 maxSell = getMaxSell();
        if(maxSell > _ethAmount){
            return (_ethAmount, 0);
        }else{
            return (maxSell, _ethAmount.sub(maxSell));
        }
    }  
    //endregion    

    //region Open/close miner
    bool internal openPublic = false;
    function openToPublic(bool _openPublic) public virtual; //owner
    function isOpened() public view returns(bool) { return openPublic; }
    //endregion

    //region Basic functions to calculate miners hire sell values etc
    function getBalance() public view returns(uint256) { return address(this).balance; }
    function getMinersFromRewardTokens(uint256 rTokens) public view returns(uint256) { return rTokens.div(REWARD_TOKENS_TO_HIRE_1MINER); }
    function _getRewardTokensSinceLastHire(uint256 currTime, uint256 lastHire, uint256 hiredMiners) public view returns(uint256) {        
        uint256 secondsPassed=min(REWARD_TOKENS_TO_HIRE_1MINER, SafeMath.sub(currTime, lastHire));
        return SafeMath.mul(secondsPassed, hiredMiners);
    }
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) private pure returns(uint256) {
        uint256 valueTrade = SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
        return valueTrade;
    }
    function calculateHireMiners(uint256 eth,uint256 contractBalance) public view returns(uint256) {
        if(eth > 0){
            return calculateTrade(eth, contractBalance, getMarketRewardTokens());
        }
        else{
            return 0;
        }
    }
    function calculateHireMinersSimple(uint256 eth) public view returns(uint256) {
        if(eth > 0){
            return calculateHireMiners(eth, getBalance());
        }
        else{
            return 0;
        }
    }
    function calculateRewardTokenSell(uint256 rewardTokens) public view returns(uint256) {
        if(rewardTokens > 0){
            return calculateTrade(rewardTokens, getMarketRewardTokens(), getBalance());
        }
        else{
            return 0;
        }
    }

    function calculateTokensLeft(uint256 rTokens1, uint256 value1, uint256 remainingValue) public pure returns(uint256) {
        return remainingValue.mul(rTokens1).div(value1);
    }
    //endregion

    constructor (uint8 estimatedROI, uint8 _referralPcReward) { 
        REWARD_TOKENS_TO_HIRE_1MINER = uint32(uint256(100).mul(3600).mul(24).div(estimatedROI)); 
        referralPcReward = _referralPcReward;
    }

    // This function is called by anyone who want to contribute to TVL
    function ContributeToTVL() public payable { }
}
// File: LLamiFiMiner/Libraries/MinerExtended.sol


pragma solidity ^0.8.9;




abstract contract MinerExtended is MinerBasic {

    using SafeMath for uint256;

    //region Extended
    function burnMiners() public virtual;
    function buyMiners(address seller) public payable virtual;
    function sellMiners(uint256 _amount, uint8 discount) public virtual;
    function buyToken(address _receiver) public virtual;

    bool internal extendedEnabled = false;
    function isExtendedEnabled() public view returns(bool) { return extendedEnabled; }
    function enableExtended(bool enable) public virtual;
    function _enableExtended(bool enable) internal { extendedEnabled = enable; }
    mapping(uint256 => address) posibleReinvestments;
    function addToEcosystem(address _adr, uint256 _i) public virtual;
    function _addToEcosystem(address _adr, uint256 _i) internal {
        require(posibleReinvestments[_i] == address(0), "Only can add new projects to empty slots");
        require(isContract(_adr), "The address is not a contract");
        posibleReinvestments[_i] = _adr;
    }
    function reinvest(uint256 _adrPrjIndex, uint256 _payment) public virtual;
    function _reinvest(uint256 _adrPrjIndex, uint256 _payment, address _who) internal {
        IProject(posibleReinvestments[_adrPrjIndex]).reinvestment{value:_payment}(_who);
    }
    //endregion

    constructor (uint8 estimatedROI, uint8 _referralPcReward) MinerBasic(estimatedROI, _referralPcReward) { }
}
// File: LLamiFiMiner/LlaminuMiner.sol

/*
    LLamiFi Miner - Arbitrum ETH Miner
    Developed by Kraitor <TG: kraitordev>
*/

pragma solidity ^0.8.9;






contract LLamiFiMiner is Ownable, MinerExtended, InvestorsManager, Testable {
    using SafeMath for uint256;
    using SafeMath for uint64;
    using SafeMath for uint32;
    using SafeMath for uint8;

    constructor(uint8 estimatedROI, uint8 referralPcRewards, address timerAddr) Testable(timerAddr) MinerExtended(estimatedROI, referralPcRewards) { }

    //region CONFIG
    function setTaxReceivers(
        address _tokenLiqReceiver, 
        address _proy1Receiver, 
        address _treasuryReceiver, 
        address _charityReceiver, 
        address _stakingPoolReceiver
        ) public override onlyOwner {
            _setTaxReceivers(_tokenLiqReceiver, _proy1Receiver, _treasuryReceiver, _charityReceiver, _stakingPoolReceiver);
    }
    function setTaxDistribution(uint8 _tokenLiq, uint8 _proy1, uint8 _TLV, uint8 _treasury, uint8 _charity, uint8 _stakingPool) public override onlyOwner {
        _setTaxDistribution(_tokenLiq, _proy1, _TLV, _treasury, _charity, _stakingPool);
    }
    function setDefaultReferral(address _defaultReferral) public override onlyOwner { defaultReferral = _defaultReferral; }
    function setDexRouter(address _adr) public override onlyOwner { _setDexRouter(_adr); }
    function setToken(address _tokenAdr) public override onlyOwner { _setToken(_tokenAdr); }
    function setMaxBuy(uint256 _maxBuyTwoDecs) public override onlyOwner { require(false, "Not implemented"); maxBuy = _maxBuyTwoDecs; }
    function setMaxSell(uint256 _maxSellNum, uint256 _maxSellDiv) public override onlyOwner {
        require(_maxSellDiv <= 1000 && _maxSellDiv >= 10, "Invalid values");
        require(_maxSellNum < _maxSellDiv && uint256(1000).mul(_maxSellNum) >= _maxSellDiv, "Min max sell is 0.1% of TLV");
        maxSellNum = _maxSellNum;
        maxSellDiv = _maxSellDiv;
    }
    function openToPublic(bool _openPublic) public override onlyOwner { 
        require(_openPublic, "Trade only can be opened");
        openPublic = true; 
    }
    function addToEcosystem(address _adr, uint256 _i) public override onlyOwner { _addToEcosystem(_adr, _i); }
    function setROIBonusProjects(address _roiBonus1, address _roiBonus2) public override onlyOwner {
        require(isContract(_roiBonus1), "The address 1 is not a contract");
        require(isContract(_roiBonus2), "The address 2 is not a contract");
        roiBonus1 = _roiBonus1;
        roiBonus2 = _roiBonus2;
    }    
    function setHireBonusTemp(uint8 _pcBonus) public override onlyOwner { _setHireBonusTemp(_pcBonus); }
    //endregion//////////////////////

    //region BASIC
    function seedMarket() public override payable onlyOwner { _seedMarket(); }

    function clearStuckToken(address tokenAddress, uint256 tokens) public onlyOwner returns (bool) {
        if(tokens == 0){
            tokens = IERC20(tokenAddress).balanceOf(address(this));
        }
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function hireMiners(address ref) public override payable {
        require(isInitialized());
        require(isOpened() || owner() == msg.sender, 'Miner still not opened');
        require(getMaxBuy() == 0 || isUnderMaxBuy(msg.value));

        _hireMiners(ref, msg.sender, msg.value);
    }

    function rehireMiners() public override { _rehireMiners(msg.sender, address(0)); }

    function sellRewards() public override { _sellRTokens(msg.sender); }

    function burnMiners() public override {
        require(isInitialized());
        require(!fundsRecovered(msg.sender), "You already recovered your funds");
        uint256 amountInvested = getInvestorInvestment(msg.sender);
        uint256 maxAmountRecover = amountInvested.div(2);
        uint256 amountRecovered = getInvestorWithdrawal(msg.sender);
        require(maxAmountRecover > amountRecovered, "You already recovered 1/2 of your funds");
        uint256 amountRecover = maxAmountRecover.sub(amountRecovered);

        addInvestorWithdrawal(msg.sender, amountRecover);
        applyMinersBurn(getInvestorMiners(msg.sender));
        setInvestorHiredMiners(msg.sender, 1); //Burn

        if(amountRecover > 0){
            // 30% TLV
            // 20% Treasury
            bool success = payable(treasuryReceiver).send(amountInvested.mul(20).div(100));
            success = true;
        }

        payable (msg.sender).transfer(amountRecover);
    }

    function _rehireMiners(address _sender, address ref) private {
        require(isInitialized());

        if(ref == _sender) {
            ref = address(0);
        }

        if(ref == address(0)){
            ref = defaultReferral;
        }
                
        if(getInvestorData(_sender).referral == address(0) && getInvestorData(_sender).referral != _sender && getInvestorData(_sender).referral != ref) {
            setInvestorReferral(_sender, ref);
        }
        
        uint256 rTokensUsed = getMyRewardTokens(_sender);
        uint256 newMiners = getMinersFromRewardTokens(rTokensUsed);

        if(newMiners > 0 && getInvestorData(_sender).hiredMiners == 0){            
            initializeInvestor(_sender);
        }

        setInvestorHiredMiners(_sender, SafeMath.add(getInvestorData(_sender).hiredMiners, newMiners));
        setInvestorClaimedRTokens(_sender, 0);
        setInvestorLastHire(_sender, getCurrentTime());
        
        //referral tokens
        setInvestorRTokensByReferral(getReferralData(_sender).investorAddress, getReferralData(_sender).referralRTokens.add(getReferralPcReward(rTokensUsed)));
        setInvestorClaimedRTokens(getReferralData(_sender).investorAddress, SafeMath.add(getReferralData(_sender).claimedRTokens, getReferralPcReward(rTokensUsed))); 

        //20% inflation
        applyInflation(rTokensUsed, false);

        emit RehireMiners(_sender, newMiners, getInvestorData(_sender).hiredMiners, getNumberInvestors(), getReferralData(_sender).claimedRTokens, getMarketRewardTokens(), rTokensUsed);
    }

    function _sellRTokens(address _sender) private { _spendReward(_sender, _sender, true); }

    function buyToken(address _receiver) public override { _spendReward(msg.sender, _receiver, false); }

    function getWithdrawTaxAdr(address _sender, bool _reinvest) public view returns(uint256) {
        return getWithdrawTax(getCurrentTime(), getInvestorSellsTimestamp(_sender), _reinvest);
    }

    function _spendReward(address _sender, address _receiver, bool isSell) private {
        require(isInitialized());

        uint256 hasRTokens = getMyRewardTokens(_sender);
        uint256 rTokenValue = calculateRewardTokenSell(hasRTokens);
        (uint256 _rTokenValue, uint256 rTokensValueLeft) = capToMaxSell(rTokenValue);
        (uint256 __rTokenValue, uint256 sellTax) = applyWithdrawTax(_rTokenValue, getCurrentTime(), getInvestorSellsTimestamp(_sender), !isSell);
        uint256 penalty = getWithdrawTaxAdr(_sender, !isSell);

        applyInflation(calculateTokensLeft(hasRTokens, rTokenValue, _rTokenValue), true);
        setInvestorClaimedRTokens(_sender, calculateTokensLeft(hasRTokens, rTokenValue, rTokensValueLeft));
        setInvestorLastHire(_sender, getCurrentTime());
        taxPayment(sellTax);
        addInvestorWithdrawal(_sender, _rTokenValue);
        setInvestorLastSell(_sender, _rTokenValue);

        if(isSell){
            payable (_receiver).transfer(__rTokenValue);
        }else{
            increaseInvestorTokenSpent(_sender, _rTokenValue);
            _buyToken(__rTokenValue, _receiver);
        }

        // Push the timestamp
        setInvestorSellsTimestamp(_sender, getCurrentTime());
        setInvestorNsells(_sender, getInvestorData(_sender).nSells.add(1));

        emit Sell(_sender, _rTokenValue, __rTokenValue, penalty);
    }

    function _hireMiners(address _ref, address _sender, uint256 _amount) private {        
        uint256 rTokensBought = calculateHireMiners(_amount, SafeMath.sub(getBalance(), _amount));
        rTokensBought = hireBonusByDeposit(rTokensBought, _amount);
        rTokensBought = applyHireBonusTemp(rTokensBought);

        (rTokensBought,) = applyDepositTax(rTokensBought);
        (,uint256 fee) = applyDepositTax(_amount);     
        if(fee > 0){   
            taxPayment(fee);
        }
        setInvestorClaimedRTokens(_sender, SafeMath.add(getInvestorData(_sender).claimedRTokens, rTokensBought));
        addInvestorInvestment(_sender, _amount);
        _rehireMiners(_sender, _ref);
        addReferralETH(getInvestorData(_sender).referral, _amount);

        emit Hire(_sender, rTokensBought, _amount);
    }
    //endregion

    //region EXTENDED
    function enableExtended(bool enable) public override onlyOwner { 
        require(enable, "Extended functions only can be enabled");
        _enableExtended(enable); 
    }
    function buyMinersFromETH(address seller, uint256 amount) public view returns(uint256) {
        require(isInitialized());
        require(isExtendedEnabled(), "Still not enabled");
        uint256 hiredMiners = getInvestorMiners(seller);
        uint256 minersSelling = getInvestorMinersSelling(seller);
        uint8 minersDiscount = getInvestorMinersDiscount(seller);
        
        uint256 minersBuy = getMinersFromRewardTokens(calculateHireMinersSimple(amount));
        minersBuy = minersBuy.mul(100 + minersDiscount).div(100);
        require(hiredMiners >= minersSelling, "The seller does not have that amount of miners");
        require(minersBuy <= minersSelling, "The seller does not have that amount available");
        return minersBuy;
    }

    function buyMiners(address seller) public override payable {
        require(isInitialized());
        require(isExtendedEnabled(), "Still not enabled");
        require(msg.sender != seller, "You can not buy your own miners");
        require(getInvestorJoinTimestamp(msg.sender) > 0, "Only investors can buy miners");
        uint256 minersBuy = buyMinersFromETH(seller, msg.value);
        
        // Update seller miners
        uint256 hiredMiners = getInvestorMiners(seller);
        uint256 minersSelling = getInvestorMinersSelling(seller);
        setInvestorHiredMiners(seller, hiredMiners.sub(minersBuy));
        setInvestorMinersSelling(seller, minersSelling.sub(minersBuy));

        // Update buyers miners
        uint256 hiredMinersBuyer = getInvestorMiners(msg.sender);
        setInvestorHiredMiners(msg.sender, hiredMinersBuyer.add(minersBuy));
        setInvestorLastHire(msg.sender, getCurrentTime());

        // Taxes
        uint256 sellerTax = sellMinersTaxOver100(seller);
        //60% tax to TLV 40% will follow deposit/withdraw distribution
        uint256 taxedAmount = msg.value.mul(sellerTax).div(100);
        //uint256 taxedAmountTLV = taxedAmount.mul(60).div(100); //keeps on TLV
        uint256 taxedAmountPay = taxedAmount.mul(40).div(100);
        taxPayment(taxedAmountPay);

        // Payment to seller
        payable(seller).transfer(msg.value.sub(taxedAmount));
    }

    function sellMinersTaxOver100(address adr) public view returns(uint256) {
        require(isInitialized());
        require(isExtendedEnabled(), "Still not enabled");
        uint256 tax = 100;
        uint256 investment = getInvestorInvestment(adr);
        uint256 withdrawal = getInvestorWithdrawal(adr);
        withdrawal = min(investment, withdrawal);

        tax = tax.mul(withdrawal).div(investment);
        tax = tax.add(5); //5% additional tax
        return min(tax, 100);
    }

    function sellMiners(uint256 _amount, uint8 discount) public override {
        require(isInitialized());
        require(isExtendedEnabled(), "Still not enabled");
        setInvestorMinersSelling(msg.sender, _amount);
        setInvestorDiscountMiners(msg.sender, discount);
    }

    function reinvest(uint256 _adrPrjIndex, uint256 _payment) public override { 
        require(isInitialized());
        require(isExtendedEnabled(), "Still not enabled");

        uint256 hasRTokens = getMyRewardTokens(msg.sender);
        uint256 rTokenValue = calculateRewardTokenSell(hasRTokens);
        (uint256 _rTokenValue, uint256 rTokensValueLeft) = capToMaxSell(rTokenValue);
        require(_rTokenValue >= _payment, "You do not have that amount or can not spend that much at one time");
        (, uint256 sellTax) = applyWithdrawTax(_payment, getCurrentTime(), getInvestorSellsTimestamp(msg.sender), true);

        require(_rTokenValue >= _payment.add(sellTax), "You do not have that amount or can not spend that much at one time");        
        applyInflation(calculateTokensLeft(hasRTokens, rTokenValue, _payment), true);
        // we return the remaining rewards
        uint256 valueLeft = rTokensValueLeft.add(_rTokenValue.sub(_payment.add(sellTax)));
        uint256 rTokensReturn = calculateTokensLeft(hasRTokens, rTokenValue, valueLeft);
        setInvestorClaimedRTokens(msg.sender, rTokensReturn);
        setInvestorLastHire(msg.sender, getCurrentTime());        
        taxPayment(sellTax);
        addInvestorWithdrawal(msg.sender, _payment);
        setInvestorLastSell(msg.sender, _payment);

        // Push the timestamp
        setInvestorSellsTimestamp(msg.sender, getCurrentTime());
        setInvestorNsells(msg.sender, getInvestorData(msg.sender).nSells.add(1));

        _reinvest(_adrPrjIndex, _payment, msg.sender); 
    }
    //endregion

    //region Rewards  
    function rewardTokenRewards(address adr) public view returns(uint256) { return calculateRewardTokenSell(getMyRewardTokens(adr)); }
    
    function getMyRewardTokens(address adr) public view returns(uint256) { return SafeMath.add(getInvestorData(adr).claimedRTokens, getRewardTokensSinceLastHire(adr)); }
    
    function getRewardTokensSinceLastHire(address adr) public view returns(uint256) {
        uint256 generated = _getRewardTokensSinceLastHire(getCurrentTime(), getInvestorData(adr).lastHire, getInvestorData(adr).hiredMiners);
        generated = applyRefBonus(generated, getInvestorData(adr).referralETH);
        generated = roiBonusByProject(generated, adr);
        return applyFundsRecoveredPenalty(generated, fundsRecovered(adr));
    }
    //endregion//////

    //region Token buys
    function _buyToken(uint256 amountETH, address _adr) private {
        address [] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(tokenIface);
        try dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value:amountETH}(
            0,
            path,
            _adr,
            block.timestamp
        ) {}catch{}
    }
    //endregion

    receive() external payable {}
}