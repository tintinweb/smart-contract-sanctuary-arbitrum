pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { SOwnable } from "../utils/SOwnable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SignedBaseMath } from "../lib/SignedBaseMath.sol";
import { IRewarder } from "../interface/IRewarder.sol";

/**
 * @title Rewarder contract
 * @dev Tracks stakers' and traders' contributions, calculates and pays rewards in SRP token.
 * Deployed per asset (per market) as a separate instance.
 * @author Strips Finance
 **/
contract Rewarder is
    SOwnable,
    ReentrancyGuardUpgradeable,
    IRewarder 
{
    using SignedBaseMath for int256;

    InitParams public params;

    // Info on each participant of the reward program (common for both traders and stakers)
    struct TraderInfo {
        bool hasTraded;

        /*Time when the position was opened. Use that to detect wash trades */
        uint256 lastTradeTime;

        /*Number of period when the trader did his last trade */
        uint256 lastPeriod;
        
        /* The value of total AMM trading volume for lastPeriod */
        int256 accInitial;
        
        /*Cummulative trader's trade volume for the period */
        int256 periodTradingVolume;

        /*Total current reward, it's not go to 0 if trader goes inactive, as you can claim at anytime */
        int256 reward;
    }

    struct StakerInfo{
        uint256 timeInitial;
        int256 accInitial;

        int256 slp;
        int256 reward;
    }

    int256 public totalTradingRewardsClaimed;
    int256 public totalStakingRewardsClaimed;

    uint256 public currentPeriod;
    uint256 public startTime;

    /*Staking */
    uint256 public lastStakeTime;
    int256 public supplyStakeTotal;
    int256 public accStakeTotal;

    /*Trading */
    uint256 public lastTradeTime;
    int256 public tradingVolumeTotal;
    int256 public accTradeTotal;

    struct PeriodData{
        bool isCalculated;
        int256 accumulator;
    }
    mapping(uint256 => PeriodData) public accPerPeriod;
    mapping(address => TraderInfo) public traders;
    mapping(address => StakerInfo) public stakers;

    function initialize(
        InitParams memory _params,
        address _owner,
        address _admin
    ) public initializer {
        __ReentrancyGuard_init();

        params = _params;
        startTime = 0;

        totalTradingRewardsClaimed = 0;
        totalStakingRewardsClaimed = 0;

        /*Init ownable */
        owner = _owner;
        admin = _admin;
        listed[admin] = true;

        strips = address(params.stripsProxy);
    }



    function currentTradingReward() external view override returns(int256)
    {
        return params.rewardTotalPerSecTrader;
    }

    function currentStakingReward() external view override returns (int256)
    {
        return params.rewardTotalPerSecStaker;
    }

    function changePeriodAndWashTime(uint256 _periodLength, uint256 _washTime) external ownerOrListed
    {
        params.periodLength = _periodLength;
        params.washTime = _washTime;
    }


    function changeTradingReward(int256 _newRewardPerSec) external ownerOrListed
    {
        uint oldPeriod = currentPeriod;
        uint newPeriod = _updatePeriod();

        if (oldPeriod == newPeriod && tradingVolumeTotal > 0){
            int256 timeDiff = int256(block.timestamp - lastTradeTime);
            accTradeTotal += timeDiff.toDecimal().muld(params.rewardTotalPerSecTrader).divd(tradingVolumeTotal);
        }

        params.rewardTotalPerSecTrader = _newRewardPerSec;
        lastTradeTime = block.timestamp;
    }

    function changeStakingReward(int256 _newRewardPerSec) external ownerOrListed
    {
        int256 timeDiff = int256(block.timestamp - lastStakeTime);
        accStakeTotal += timeDiff.toDecimal().muld(params.rewardTotalPerSecStaker).divd(supplyStakeTotal);

        params.rewardTotalPerSecStaker = _newRewardPerSec;
        lastStakeTime = block.timestamp;
    }

    function getDao() external view returns (address)
    {
        return params.dao;
    }

    function changeDao(address _newDao) external ownerOrListed
    {
        require(_newDao != address(0), "ZERO_DAO");
        params.dao = _newDao;
    }

    /**
     * @dev Should be called each time someone stake/unstake.
     * @param _staker address of the staker
     **/
    function rewardStaker(address _staker) external override nonReentrant ownerOrStrips {
        /*Accumulare reward for previous period and update accumulator */
        stakers[_staker].reward = totalStakerReward(_staker);

        /*Accumulate for the previous period if there was any supply */
        if (supplyStakeTotal > 0){
            int256 timeDiff = int256(block.timestamp - lastStakeTime);
            accStakeTotal += timeDiff.toDecimal().muld(params.rewardTotalPerSecStaker).divd(supplyStakeTotal);
        }
        lastStakeTime = block.timestamp;
        supplyStakeTotal = int256(IERC20(address(params.slpToken)).totalSupply());

        /*Update staker's stake*/
        stakers[_staker].accInitial = accStakeTotal;
        stakers[_staker].slp = int256(IERC20(address(params.slpToken)).balanceOf(_staker));
        stakers[_staker].timeInitial = block.timestamp;
    }

    function claimStakingReward(address _staker) external override nonReentrant ownerOrStrips {

        /*Accumulare reward and update staker's initial */
        //stakers[_staker].reward = totalStakerReward(_staker).muld(params.rewardTotalPerSecStaker);
        stakers[_staker].reward = totalStakerReward(_staker);

        if (stakers[_staker].reward <= 0){
            return;
        }

        int256 accInstant = accStakeTotal;
        if (supplyStakeTotal > 0){
            int256 timeDiff = int256(block.timestamp - lastStakeTime);
            accInstant += timeDiff.toDecimal().muld(params.rewardTotalPerSecStaker).divd(supplyStakeTotal);
        }


        SafeERC20.safeTransferFrom(params.strpToken, 
                                    params.dao, 
                                    _staker, 
                                    uint(stakers[_staker].reward));
        
        emit StakingRewardClaimed(
            block.timestamp,
            owner,
            _staker, 
            stakers[_staker].reward
        );

        totalStakingRewardsClaimed += stakers[_staker].reward;

        /*Reset reward and time*/
        stakers[_staker].reward = 0;
        stakers[_staker].timeInitial = block.timestamp;
        stakers[_staker].accInitial = accInstant;
    }

    function totalStakerReward(address _staker) public view override returns (int256 reward){
        /*If staker didn't stake he can't have reward yet */
        if (stakers[_staker].timeInitial == 0){
            return 0;
        }

        /*if supply is 0 it means that everyone usntake and no more accumulation */
        if (supplyStakeTotal <= 0){
            return stakers[_staker].reward;
        }

        /*Accumulate reward till current time */
        int256 timeDiff = int256(block.timestamp - lastStakeTime);
        int256 accInstant = accStakeTotal + timeDiff.toDecimal().muld(params.rewardTotalPerSecStaker).divd(supplyStakeTotal);

        return stakers[_staker].reward + stakers[_staker].slp.muld(accInstant - stakers[_staker].accInitial);
    }


    function totalTradeReward(address _trader) public view override returns (int256 reward){
        
        /*If trader never trade then it's 0 */
        if (traders[_trader].hasTraded == false){
            return 0;
        }

        (uint period,
            int256 periodAccumulator) = _calcPeriod(traders[_trader].lastPeriod);

        if (periodAccumulator == 0){
            return traders[_trader].reward;
        }

        return traders[_trader].reward + traders[_trader].periodTradingVolume.muld(periodAccumulator - traders[_trader].accInitial);
    }

    /**
     * @dev Should be called each time trader trader.
     * @param _trader address of the trader
     * @param _notional current trade position size
     **/
    function rewardTrader(address _trader, int256 _notional) external override nonReentrant ownerOrStrips {
        if (startTime == 0){
            /*Setup start time for all periods once first trader ever happened*/
            startTime = block.timestamp;
            currentPeriod = 0;
        }
        
        int256 boostedNotional = _notional.muld(_booster(_trader));
        if ((block.timestamp - traders[_trader].lastTradeTime) < params.washTime){
            /*If it's a wash trade just update period and return */
            _updatePeriod();
            _tradeHappened(boostedNotional);
            lastTradeTime = block.timestamp;
            return;
        }
        
        /*Accumulate all previous rewards */
        traders[_trader].reward = totalTradeReward(_trader);
        

        uint traderLastPeriod = traders[_trader].lastPeriod;
        (uint period,) = _calcPeriod(traderLastPeriod);

        if (traders[_trader].hasTraded && period != traderLastPeriod){
            traders[_trader].periodTradingVolume = boostedNotional;
        }else{
            traders[_trader].periodTradingVolume += boostedNotional;
        }

        _updatePeriod();
        _tradeHappened(boostedNotional);

        traders[_trader].lastPeriod = currentPeriod;
        traders[_trader].accInitial = accTradeTotal;
        traders[_trader].lastTradeTime = block.timestamp;
        traders[_trader].hasTraded = true;

        lastTradeTime = block.timestamp;
    }

    /**
     * @dev Send all current reward to the trader
     **/
    function claimTradingReward(address _trader) external override nonReentrant ownerOrStrips {
        
        if (traders[_trader].hasTraded == false){
            _updatePeriod();
            return;
        }


        traders[_trader].reward = totalTradeReward(_trader);

        if (traders[_trader].reward <= 0){
            _updatePeriod();
            return;
        }

        /*Transfer and RESET reward */
        SafeERC20.safeTransferFrom(params.strpToken, 
                                    params.dao, 
                                    _trader, 
                                    uint(traders[_trader].reward));

        emit TradingRewardClaimed(
            block.timestamp,
            owner,
            _trader, 
            traders[_trader].reward
        );

        totalTradingRewardsClaimed += traders[_trader].reward;
        traders[_trader].reward = 0;


        /*Update parameters */
        uint traderLastPeriod = traders[_trader].lastPeriod;
        (uint period, int256 periodAccumulator) = _calcPeriod(traderLastPeriod);
        
        if (period != traderLastPeriod){
            /*It's a switch for trader just rest everyting*/
            traders[_trader].periodTradingVolume = 0;
            traders[_trader].accInitial = 0;
            traders[_trader].hasTraded = false;
        }else{
            /*Claim in the same period update initial */
            traders[_trader].accInitial = periodAccumulator;
        }
        
        _updatePeriod();
    }

    function _calcPeriod(uint lastPeriod) private view returns (uint period,
                                                                int256 periodAccumulator)
    {
        period = (block.timestamp - startTime) / params.periodLength;

        if (period != lastPeriod){ /*Period changed*/

            if (accPerPeriod[lastPeriod].isCalculated == true){
                /*We already have accumulator for period, just return */
                periodAccumulator = accPerPeriod[lastPeriod].accumulator;
                return (period, periodAccumulator);
            }

            /*We didn't close lastPeriod -  accumualte*/
            if (tradingVolumeTotal == 0){  /*No trades in period */
                periodAccumulator = 0;
                return (period, periodAccumulator);
            }

            uint timeLeft = params.periodLength - (lastTradeTime - startTime) % params.periodLength;
            periodAccumulator = accTradeTotal + int256(timeLeft).toDecimal().muld(params.rewardTotalPerSecTrader).divd(tradingVolumeTotal);
            
            return (period, periodAccumulator);


        }else{ /*It's the same period */
            
            if (tradingVolumeTotal == 0){  /*No trades in period */
                periodAccumulator = 0;
                return (period, periodAccumulator);
            }

            /*Trade in the current period*/
            uint timeDiff = block.timestamp - lastTradeTime;
            periodAccumulator = accTradeTotal + int256(timeDiff).toDecimal().muld(params.rewardTotalPerSecTrader).divd(tradingVolumeTotal);

            return (period, periodAccumulator);
        }
    }

    function _updatePeriod() private returns (uint) {
        (uint period,
            int256 periodAccumulator) = _calcPeriod(currentPeriod);

        if (period != currentPeriod){
            /*Period switched */

            /*Save accumulator for period*/
            accPerPeriod[currentPeriod] = PeriodData({
                isCalculated: true,
                accumulator: periodAccumulator
            });

            /*Reset params*/
            tradingVolumeTotal = 0;
            accTradeTotal = 0;

            /*Switch period number */
            currentPeriod = period;
        }

        return period;
    }

    function _tradeHappened(int256 _notional) private {
        if (lastTradeTime != 0 && tradingVolumeTotal > 0){
            // If it's not the first trade in period OR the first trade EVER
            int256 timeDiff = int256(block.timestamp - lastTradeTime);
            accTradeTotal += (timeDiff.toDecimal().muld(params.rewardTotalPerSecTrader).divd(tradingVolumeTotal));
        }
        tradingVolumeTotal += _notional;
    }

    function _booster(address _trader) private returns (int256){
        uint supply = IERC20(address(params.slpToken)).totalSupply();
        uint balance = IERC20(address(params.slpToken)).balanceOf(_trader);
        if (supply == 0 || balance == 0) {
            return SignedBaseMath.oneDecimal();
        }
        int256 share = int256(balance).divd(int256(supply));

        return SignedBaseMath.oneDecimal() + share;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
    uint256[49] private __gap;
}

abstract contract SOwnable
{
    address public owner;
    address public admin; // used for managing admin functions like add remove to list
    address public strips;
    address public proposed;

    mapping (address => bool) public listed;

    modifier onlyProposed(){
        require(msg.sender == proposed, "NOT_PROPOSED");
        _;
    }


    modifier onlyOwner(){
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    modifier ownerOrAdmin(){
        require(msg.sender == owner || msg.sender == admin, "NOT_OWNER_NOR_ADMIN");
        _;
    }

    modifier ownerOrStrips(){
        require(msg.sender == owner || msg.sender == strips, "NOT_OWNER_NOR_STRIPS");
        _;
    }

    modifier onlyStrips(){
        require(msg.sender == strips, "NOT_STRIPS");
        _;
    }

    modifier ownerOrListed(){
        require(msg.sender == owner || listed[msg.sender] == true, "NOT_OWNER_NOR_LISTED");
        _;
    }

    function listAdd(address _new) public ownerOrAdmin {
        listed[_new] = true;
    }

    function listRemove(address _exist) public ownerOrAdmin {
        /*No check for existing */
        listed[_exist] = false;
    }

    function proposeOwner(address _new) public onlyOwner {
        require(_new != address(0), "ZERO_OWNER");
        require(_new != msg.sender, "ALREADY_AN_OWNER");

        proposed = _new;
    }

    function changeOwner() public onlyProposed {
        owner = proposed;

        /*Reset proposed */
        proposed = address(0);
    }

    function changeAdmin(address _new) public onlyOwner {
        admin = _new;
    }

    function changeStrips(address _new) public onlyOwner {
        strips = _new;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.8.0;

// We are using 0.8.0 with safemath inbuilt
// Need to implement mul and div operations only
// We have 18 for decimal part and  58 for integer part. 58+18 = 76 + 1 bit for sign
// so the maximum is 10**58.10**18 (should be enough :) )

library SignedBaseMath {
    uint8 constant DECIMALS = 18;
    int256 constant BASE = 10**18;
    int256 constant BASE_PERCENT = 10**16;

    function toDecimal(int256 x, uint8 decimals) internal pure returns (int256) {
        return x * int256(10**decimals);
    }

    function toDecimal(int256 x) internal pure returns (int256) {
        return x * BASE;
    }

    function oneDecimal() internal pure returns (int256) {
        return 1 * BASE;
    }

    function tenPercent() internal pure returns (int256) {
        return 10 * BASE_PERCENT;
    }

    function ninetyPercent() internal pure returns (int256) {
        return 90 * BASE_PERCENT;
    }

    function onpointOne() internal pure returns (int256) {
        return 110 * BASE_PERCENT;
    }


    function onePercent() internal pure returns (int256) {
        return 1 * BASE_PERCENT;
    }

    function muld(int256 x, int256 y) internal pure returns (int256) {
        return _muld(x, y, DECIMALS);
    }

    function divd(int256 x, int256 y) internal pure returns (int256) {
        if (y == 1){
            return x;
        }
        return _divd(x, y, DECIMALS);
    }

    function _muld(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return (x * y) / unit(decimals);
    }

    function _divd(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        return (x * unit(decimals)) / y;
    }

    function unit(uint8 decimals) internal pure returns (int256) {
        return int256(10**uint256(decimals));
    }
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "./IStripsLpToken.sol";
import { IStakebleEvents } from "../lib/events/Stakeble.sol";

interface IRewarder {
    event TradingRewardClaimed(
        uint256 indexed timestamp,
        address indexed asset,
        address indexed user, 
        int256 amount
    );


    event StakingRewardClaimed(
        uint256 indexed timestamp,
        address indexed asset,
        address indexed user, 
        int256 amount
    );

    struct InitParams {
        uint256 periodLength;
        uint256 washTime;

        IERC20 slpToken;
        IERC20 strpToken;

        address stripsProxy;
        address dao;

        int256 rewardTotalPerSecTrader;
        int256 rewardTotalPerSecStaker;
    }

    function claimStakingReward(address _staker) external;
    function claimTradingReward(address _trader) external;

    function totalStakerReward(address _staker) external view returns (int256 reward);
    function totalTradeReward(address _trader) external view returns (int256 reward);

    function rewardStaker(address _staker) external;
    function rewardTrader(address _trader, int256 _notional) external;

    function currentTradingReward() external view returns(int256);
    function currentStakingReward() external view returns (int256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IUniswapLpOracle } from "../interface/IUniswapLpOracle.sol";

interface IStripsLpToken {
    struct TokenParams {
        address stripsProxy;
        address pairOracle;

        address tradingToken;
        address stakingToken; 

        int256 penaltyPeriod;
        int256 penaltyFee;

        int256 unstakingTolerance;
    }

    struct ProfitParams{
        int256 unstakeAmountLP;
        int256 unstakeAmountERC20;

        int256 stakingProfit;   
        int256 stakingFee;

        int256 penaltyLeft;
        uint256 totalStaked;

        int256 lpPrice;

        int256 lpProfit;
        int256 usdcLoss;

        int256 currentVritualLpGrowth; 
        int256 currentVirtualUsdcGrowth;
        uint256 slpSupply;
    }
    
    function instantGrowth() external view returns (int256 usdcGrowth, int256 lpGrowth);
    function getParams() external view returns (TokenParams memory);
    function getBurnableToken() external view returns (address);
    function getPairPrice() external view returns (int256);
    function checkOwnership() external view returns (address);

    function totalPnl() external view returns (int256 usdcTotal, int256 lpTotal);
    function realisedTotalPnl() external view returns (int256 usdcRealized, int256 lpTotal);

    function accumulatePnl() external;
    function saveProfit(address staker) external;
    function mint(address staker, uint256 amount) external;
    function burn(address staker, uint256 amount) external;

    function calcFeeLeft(address staker) external view returns (int256 feeShare, int256 periodLeft);
    function calcProfit(address staker, uint256 amount) external view returns (ProfitParams memory);
    function nonCheckCalcProfit(address staker, uint256 amount) external view returns (ProfitParams memory profit);

    function claimProfit(address staker, uint256 amount) external returns (ProfitParams memory profit);
    function setPenaltyFee(int256 _fee) external;
    function setParams(TokenParams memory _params) external;
    function canUnstake(address staker, uint256 amount) external view;

    function changeTradingPnl(int256 amount) external;
    function changeStakingPnl(int256 amount) external;

    function changePairOracle(IUniswapLpOracle _oracle) external;

    function bothPrices() external view returns (int256 lpPrice, int256 strpPrice);
}

import { IStripsLpToken } from "../../interface/IStripsLpToken.sol";
import { IStakeble } from "../../interface/IStakeble.sol";
import { IMarket } from "../../interface/IMarket.sol";


interface IStakebleEvents {
    struct LogUnstakeParams {
        address asset;
        address staker;
        int256 slpAmount;
        int256 lpPaid; 
        int256 lpPnl; 
        int256 usdcPnl; 
        int256 lpFee;
        int256 marketPrice;
        int256 oraclePrice;
        int256 stakingLiquidity;
        int256 tradingLiquidity;
        int256 tvl;
    }

    struct LogStakeParams {
        address asset;
        address staker;
        uint256 lpAmount;
        int256 currentVritualLpGrowth;
        int256 currentVirtualUsdcGrowth;
        uint256 slpSupply;
        int256 lpPrice;
        int256 tradingLiquidity;
        int256 stakingLiquidity;
        int256 tvl;
        int256 marketPrice;
        int256 oraclePrice;
    }


    struct UnstakeParams{
        int256 currentVritualLpGrowth; // before he unstakes
        int256 currentVirtualUsdcGrowth; //before he unstakes
        uint256 slpSupply;
        int256 lpPrice;
        int256 stakingLiquidity;
        int256 tradingLiquidity;
        int256 tvl;
        int256 marketPrice;
        int256 oraclePrice;
    }


    event LogStake(
        uint256 indexed timestamp,
        address indexed asset,
        address indexed staker,
        uint256 lpAmount,
        int256 currentVritualLpGrowth, // before he stakes
        int256 currentVirtualUsdcGrowth, //before he stakes
        uint256 slpSupply,
        int256 lpPrice,
        int256 stakingLiquidity,
        int256 tradingLiquidity,
        int256 tvl,
        int256 marketPrice,
        int256 oraclePrice
    );

    event LogUnstake(
        uint256 indexed timestamp,
        address indexed asset,
        address indexed staker,
        int256 slpAmount,
        int256 lpPaid, // renamed   
        int256 lpPnl,  // renamed  (this is the lp that you earned or lost)
        int256 usdcPnl,  // renamed (this is the usdc that you earned or lost)
        int256 lpFee, // renamed
        IStakebleEvents.UnstakeParams params
    );

    event BurnAction(
        uint256 indexed timestamp,
        address indexed asset,
        int256 requiredAmount,
        int256 lpToBurnCalculated,
        int256 lp_diff,
        int256 usdc_diff,
        int256 lpPrice,
        int256 strpPrice
    );
}

library StakebleEvents {
    event LogStake(
        uint256 indexed timestamp,
        address indexed asset,
        address indexed staker,
        uint256 lpAmount,
        int256 currentVritualLpGrowth, // before he stakes
        int256 currentVirtualUsdcGrowth, //before he stakes
        uint256 slpSupply,
        int256 lpPrice,
        int256 stakingLiquidity,
        int256 tradingLiquidity,
        int256 tvl,
        int256 marketPrice,
        int256 oraclePrice
    );

    event LogUnstake(
        uint256 indexed timestamp,
        address indexed asset,
        address indexed staker,
        int256 slpAmount,
        int256 lpPaid, // renamed   
        int256 lpPnl,  // renamed  (this is the lp that you earned or lost)
        int256 usdcPnl,  // renamed (this is the usdc that you earned or lost)
        int256 lpFee, // renamed
        IStakebleEvents.UnstakeParams params
    );

    event BurnAction(
        uint256 indexed timestamp,
        address indexed asset,
        int256 requiredAmount,
        int256 lpToBurnCalculated,
        int256 lp_diff,
        int256 usdc_diff,
        int256 lpPrice,
        int256 strpPrice
    );

    function logStakeData(IStakebleEvents.LogStakeParams memory _params) internal {
        
        if (IStakeble(_params.asset).isInsurance() == false){
            (_params.marketPrice, _params.oraclePrice) = IMarket(_params.asset).getPrices();
        }             

        emit LogStake(
            block.timestamp,
            _params.asset,
            _params.staker,
            _params.lpAmount,
            _params.currentVritualLpGrowth, // before he stakes
            _params.currentVirtualUsdcGrowth, //before he stakes
            _params.slpSupply,
            _params.lpPrice,
            _params.stakingLiquidity,
            _params.tradingLiquidity,
            _params.tvl,
            _params.marketPrice,
            _params.oraclePrice
            );
    }


    function logUnstakeData(IStakebleEvents.LogUnstakeParams memory _params,
                            IStripsLpToken.ProfitParams memory _profit) internal {


        if (IStakeble(_params.asset).isInsurance() == false){
            (_params.marketPrice, _params.oraclePrice) = IMarket(_params.asset).getPrices();
        }             
            
            emit LogUnstake(
                block.timestamp,
                _params.asset,
                _params.staker,
                _params.slpAmount,

                _profit.unstakeAmountLP, // renamed   
                (_profit.stakingProfit - _profit.lpProfit),  // renamed  (this is the lp that you earned or lost)
                (_profit.unstakeAmountERC20 + _profit.usdcLoss),  // renamed (this is the usdc that you earned or lost)
                _profit.stakingFee, // renamed
                IStakebleEvents.UnstakeParams({
                    currentVritualLpGrowth:_profit.currentVritualLpGrowth,
                    currentVirtualUsdcGrowth:_profit.currentVirtualUsdcGrowth,
                    slpSupply:_profit.slpSupply,
                    lpPrice:_profit.lpPrice,
                    stakingLiquidity:_params.stakingLiquidity,
                    tradingLiquidity:_params.tradingLiquidity,
                    tvl: _params.tvl,
                    marketPrice: _params.marketPrice,
                    oraclePrice: _params.oraclePrice
                }));


    }

    function logBurnData(address _asset,
                            int256 _requiredAmount,
                            int256 _lpToBurnCalculated,
                            int256 _lp_diff,
                            int256 _usdc_diff,
                            int256 _lpPrice,
                            int256 _strpPrice) internal {
        emit BurnAction(
            block.timestamp,
            _asset,
            _requiredAmount,
            _lpToBurnCalculated,
            _lp_diff,
            _usdc_diff,
            _lpPrice,
            _strpPrice
        );
    }
}

pragma solidity >=0.8.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity ^0.8.0;

import { IMarket } from "./IMarket.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IInsuranceFund } from "./IInsuranceFund.sol";
import { IStripsLpToken } from "./IStripsLpToken.sol";

import { StorageStripsLib } from "../lib/StorageStrips.sol";
import { IStripsEvents } from "../lib/events/Strips.sol";

interface IStrips is IStripsEvents 
{
    /*
        for action:
        0 - open
        1 - close
        2 - liquidate
     */
    event TradeAction(
        uint256 indexed timestamp,
        address indexed marketAddress,
        bool indexed isLong,
        address traderAddress,
        uint256 action,   // 0- open, 1-close, 2-liquidate
        int256 notional,
        int256 ratio,
        int256 collateral,
        int256 feePaid,
        int256 slippage,
        int256 executedPrice,  //renamed from newPrice
        int256 marketPrice,
        int256 oraclePrice
    );

    event PnlTransfered(
        uint256 indexed timestamp,
        address indexed marketAddress,
        address indexed traderAddress,
        uint256 action,
        int256 collateral,
        int256 total_pnl,  
        int256 trading_pnl,
        int256 funding_pnl
    );

    event CollateralChanged(
        uint256 indexed timestamp,
        address indexed marketAddress,
        address indexed traderAddress,
        int256 notional,
        int256 total_pnl,
        int256 diff,
        int256 newMargin  // the new margin
    );

    struct ExtendedMarketData {
        bool created;
        address market;
    }


    /*
        State actions
     */
    enum StateActionType {
        ClaimRewards
    }

    /*request */
    struct ClaimRewardsParams {
        address account;
    }

    struct StateActionArgs {
        StateActionType actionType;
        bytes data;
    }


    /*
        View actions
     */
    enum ViewActionType {
        GetOracles,
        GetMarkets,
        CalcFeeAndSlippage,
        GetPosition,
        CalcClose,
        CalcRewards
    }

    /*request */
    struct CalcRewardsParams {
        address account;
    }
    /*response */
    struct CalcRewardsData {
        address account;
        int256 rewardsTotal;
    }


    /*request */
    struct CalcCloseParams {
        address market;
        address account;
        int256 closeRatio;
    }
    /*response */
    struct CalcCloseData {
        address market;
        int256 minimumMargin;
        int256 pnl;
        int256 marginLeft;
        int256 fee;
        int256 slippage;
        int256 whatIfPrice;
    }

    /*
        request 
        response: PositionParams or revert
    */
    struct GetPositionParams {
        address market;
        address account;
    }


    /*request */
    struct FeeAndSlippageParams {
        address market;
        int256 notional;
        int256 collateral;
        bool isLong;
    }

    /* response */
    struct FeeAndSlippageData{
        address market;
        int256 marketRate;
        int256 oracleRate;
        
        int256 fee;
        int256 whatIfPrice;
        int256 slippage;

        int256 minimumMargin;
        int256 estimatedMargin;
    }


    struct ViewActionArgs {
        ViewActionType actionType;
        bytes data;
    }


    /*
        Admin actions
     */

    enum AdminActionType {
        AddMarket,   
        AddOracle,  
        RemoveOracle,  
        ChangeOracle,
        SetInsurance,
        ChangeRisk
    }

    struct AddMarketParams{
        address market;
        address assetOracle;
    }

    struct AddOracleParams{
        address oracle;
        int256 keeperReward;
    }

    struct RemoveOracleParams{
        address oracle;
    }

    struct ChangeOracleParams{
        address oracle;
        int256 newReward;
    }

    struct SetInsuranceParams{
        address insurance;
    }

    struct ChangeRiskParams{
        StorageStripsLib.RiskParams riskParams;
    }


    struct AdminActionArgs {
        AdminActionType actionType;
        bytes data;
    }



    /*
        Events
     */
    event LogNewMarket(
        address indexed market,
        address indexed assetOracle
    );

    struct PositionParams {
        // true - for long, false - for short
        bool isLong;
        // is this position closed or not
        bool isActive;
        // is this position liquidated or not
        bool isLiquidated;

        //position size in USDC
        int256 notional;
        //collateral size in USDC
        int256 collateral;
        //initial price for position
        int256 initialPrice;
    }

    struct PositionData {
        //address of the market
        IMarket market;
        // total pnl - real-time profit or loss for this position
        int256 pnl;
        int256 trading_pnl;
        int256 funding_pnl;

        // this pnl is calculated based on whatIfPrice
        int256 pnlWhatIf;
        
        // current margin ratio of the position
        int256 marginRatio;
        PositionParams positionParams;
    }

    struct AssetData {
        bool isInsurance;
        
        address asset;
         // Address of SLP/SIP token
        address slpToken;

        int256 marketPrice;
        int256 oraclePrice;

        int256 maxLong;
        int256 maxShort;

        int256 tvl;
        int256 apy;

        int256 minimumMargin;
    }

    struct StakingData {
         //Market or Insurance address
        address asset; 

        //Collateral = slp amount
        uint256 totalStaked;


        //lpProfit
        int256 unrealizedLpProfit;
        //usdcProfit
        int256 unrealizedUsdcProfit;
    }

    /**
     * @notice Struct that keep real-time trading data
     */
    struct TradingInfo {
        //Includes also info about the current market prices, to show on dashboard
        AssetData[] assetData;
        PositionData[] positionData;
    }

    /**
     * @notice Struct that keep real-time staking data
     */
    struct StakingInfo {
        //Includes also info about the current market prices, to show on dashboard
        int256 lpPrice;
        AssetData[] assetData;
        StakingData[] stakingData;
    }

    /**
     * @notice Struct that keep staking and trading data
     */
    struct AllInfo {
        TradingInfo tradingInfo;
        StakingInfo stakingInfo;
    }

    function open(
        IMarket _market,
        bool isLong,
        int256 collateral,
        int256 leverage,
        int256 slippage
    ) external;

    function close(
        IMarket _market,
        int256 _closeRatio,
        int256 _slippage
    ) external;

    function changeCollateral(
        IMarket _market,
        int256 collateral,
        bool isAdd
    ) external;

    function ping() external;
    function getPositionsCount() external view returns (uint);
    function getPositionsForLiquidation(uint _start, uint _length) external view returns (StorageStripsLib.PositionMeta[] memory);
    function liquidatePosition(address _market, address account) external;
    function liquidatePositions(address[] memory markets, address[] memory accounts) external;

    function payKeeperReward(address keeper) external;

    /*
        Strips getters functions for Trader
     */
    function assetPnl(address _asset) external view virtual returns (int256);
    function getLpOracle() external view returns (address);

    function getAllMarkets() external view returns (ExtendedMarketData[] memory);

}

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface IUniswapLpOracle is KeeperCompatibleInterface {
    function getPrice() external view returns (int256);
    function strpPrice() external view returns (int256);
    function bothPrices() external view returns (int256 lpPrice, int256 strpPrice);
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "./IStripsLpToken.sol";
import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";
import { IUniswapLpOracle } from "../interface/IUniswapLpOracle.sol";
import { IAssetOracle } from "../interface/IAssetOracle.sol";
        
interface IMarket {        
    function getLongs() external view returns (int256);
    function getShorts() external view returns (int256);

    function priceChange(int256 notional, bool isLong) external view returns (int256);
    function currentPrice() external view returns (int256);
    function oraclePrice() external view returns (int256);
    
    function changeAssetOracle(IAssetOracle _oracle) external;
    function changePairOracle(IUniswapLpOracle _oracle) external;

    function getAssetOracle() external view returns (address);
    function getPairOracle() external view returns (address);
    function currentOracleIndex() external view returns (uint256);

    function getPrices() external view returns (int256 marketPrice, int256 oraclePrice);    
    function getLiquidity() external view returns (int256);

    /*Both returns the new value of virtual liquidity*/
    function changeVirtualLiquidity(int256 _new) external returns (int256);
    function getVirtualLiquidity() external view returns (int256);

    function openPosition(
        bool isLong,
        int256 notional
    ) external returns (int256 openPrice);

    function closePosition(
        bool isLong,
        int256 notional
    ) external returns (int256);

    function maxNotional() external view returns (int256 maxLong, int256 maxShort);

    /*Both returns the new value of fundingPeriod*/
    function getFundingPeriod() external view returns (int256);
    function changeFundingPeriod(int256 _newPeriod) external returns (int256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
import { IUniswapLpOracle } from "../interface/IUniswapLpOracle.sol";

interface IInsuranceFund {
    function borrow(address _to, int256 _amount) external;

    function getLiquidity() external view returns (int256);

    function changePairOracle(IUniswapLpOracle _oracle) external;

}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IStakeble } from "../interface/IStakeble.sol";
import { IAssetOracle } from "../interface/IAssetOracle.sol";
import { IInsuranceFund } from "../interface/IInsuranceFund.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";

import { SignedBaseMath } from "./SignedBaseMath.sol";
import { StorageMarketLib } from "./StorageMarket.sol";

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library StorageStripsLib {
    using SignedBaseMath for int256;
    
    struct MarketData {
        bool created;

        //TODO: any data about the
    }

    struct Position {
        IMarket market; //can be removed
        address trader;

        int256 initialPrice; //will become avg on _aggregation
        int256 entryPrice;   // always the "new market price"
        int256 prevAvgPrice; 

        int256 collateral; 
        int256 notional; 

        uint256 initialTimestamp;
        uint256 cummulativeIndex; 
        uint256 initialBlockNumber;
        uint256 posIndex;           // use this to find position by index
        uint256 lastChangeBlock;

        int256 unrealizedPnl;   //used to save funding_pnl for aggregation
        
        //TODO: refactor this
        bool isLong;
        bool isActive;
        bool isLiquidated;  
        
        //used only for AMM
        bool isAmm;
        int256 savedTradingPnl;    // use this to deal with div to zero when ammUpdatedNotional == 0
        int256 zeroParameter;
        int256 lastNotional;      // for amm we calculate funding based on notional from prev block always
        int256 lastInitialPrice;  // for amm
        bool lastIsLong;

        int256 oraclePriceUsed;
    }

    struct RiskParams {
        int256 fundFeeRatio; //the part of fee that goes to Fee Fund. insuranceFeeRatio = 1 - fundFeeRatio 
        int256 daoFeeRatio;

        int256 liquidatorFeeRatio; // used to calc the liquidator reward insuranceLiquidationFeeRatio = 1 - liquidatorFeeRatio
        int256 marketFeeRatio; // used to calc market ratio on Liquidation
        int256 insuranceProfitOnPositionClosed;

        int256 liquidationMarginRatio; // the minimum possible margin ratio.
        int256 minimumPricePossible; //use this when calculate fee
        int256 flatFee;
    }

    struct OracleData {
        bool isActive;
        int256 keeperReward; 
    }

    /*Use this struct for fast access to position */
    struct PositionMeta {
        bool isActive; // is Position active

        address _account; 
        IMarket _market;
        uint _posIndex;
    }


    //GENERAL STATE - keep aligned on update
    struct State {
        address dao;
        uint8 _currentLevel;

        /*Markets data */
        IMarket[] allMarkets;
        mapping (IMarket => MarketData) markets;

        /*Traders data */
        address[] allAccounts; // never pop
        mapping (address => bool) existingAccounts; // so to not add twice, and have o(1) check for addin

        mapping (address => mapping(IMarket => Position)) accounts; 
        
        uint[] allIndexes;  // if we need to loop through all positions we use this array. Reorder it to imporove effectivenes
        mapping (uint => PositionMeta) indexToPositionMeta;
        uint256 currentPositionIndex; //index of the latest created position

        /*Oracles */
        address[] allOracles;
        mapping(address => OracleData) oracles;

        /*Strips params */
        RiskParams riskParams;
        IInsuranceFund insuranceFund;
        IERC20 tradingToken;

        // last ping timestamp
        uint256 lastAlive;
        // the time interval during which contract methods are available that are marked with a modifier ifAlive
        uint256 keepAliveInterval;

        address lpOracle;
    }

    /*
        Oracles routines
    */
    function addOracle(
        State storage state,
        address _oracle,
        int256 _keeperReward
    ) internal {
        require(state.oracles[_oracle].isActive == false, "ORACLE_EXIST");
        
        state.oracles[_oracle].keeperReward = _keeperReward;
        state.oracles[_oracle].isActive = true;

        state.allOracles.push(_oracle);
    }

    function removeOracle(
        State storage state,
        address _oracle
    ) internal {
        require(state.oracles[_oracle].isActive == true, "NO_SUCH_ORACLE");
        state.oracles[_oracle].isActive = false;
    }


    function changeOracleReward(
        State storage state,
        address _oracle,
        int256 _newReward
    ) internal {
        require(state.oracles[_oracle].isActive == true, "NO_SUCH_ORACLE");
        state.oracles[_oracle].keeperReward = _newReward;
    }


    /*
    *******************************************************
    *   getters/setters for adding/removing data to state
    *******************************************************
    */

    function setInsurance(
        State storage state,
        IInsuranceFund _insurance
    ) internal
    {
        require(address(_insurance) != address(0), "ZERO_INSURANCE");

        state.insuranceFund = _insurance;
    }

    function getMarket(
        State storage state,
        IMarket _market
    ) internal view returns (MarketData storage market) {
        market = state.markets[_market];
        require(market.created == true, "NO_MARKET");
    }

    function addMarket(
        State storage state,
        IMarket _market
    ) internal {
        MarketData storage market = state.markets[_market];
        require(market.created == false, "MARKET_EXIST");

        state.markets[_market].created = true;
        state.allMarkets.push(_market);
    }

    function setRiskParams(
        State storage state,
        RiskParams memory _riskParams
    ) internal{
        state.riskParams = _riskParams;
    }



    // Not optimal 
    function checkPosition(
        State storage state,
        IMarket _market,
        address account
    ) internal view returns (Position storage){
        return state.accounts[account][_market];
    }

    // Not optimal 
    function getPosition(
        State storage state,
        IMarket _market,
        address _account
    ) internal view returns (Position storage position){
        position = state.accounts[_account][_market];
        require(position.isActive == true, "NO_POSITION");
    }

    function setPosition(
        State storage state,
        IMarket _market,
        address account,
        bool isLong,
        int256 collateral,
        int256 notional,
        int256 initialPrice,
        bool merge
    ) internal returns (uint256 index) {
        
        /*TODO: remove this */
        if (state.existingAccounts[account] == false){
            state.allAccounts.push(account); 
            state.existingAccounts[account] = true;
        }
        Position storage _position = state.accounts[account][_market];

        /*
            Update PositionMeta for faster itterate over positions.
            - it MUST be trader position
            - it should be closed or liquidated. 

            We DON'T update PositionMeta if it's merge of the position
         */
        if (address(_market) != account && _position.isActive == false)
        {            
            /*First ever position for this account-_market setup index */
            if (_position.posIndex == 0){
                if (state.currentPositionIndex == 0){
                    state.currentPositionIndex = 1;  // posIndex started from 1, to be able to do check above
                }

                _position.posIndex = state.currentPositionIndex;

                state.allIndexes.push(_position.posIndex);
                state.indexToPositionMeta[_position.posIndex] = PositionMeta({
                    isActive: true,
                    _account: account,
                    _market: _market,
                    _posIndex: _position.posIndex
                });

                /*INCREMENT index only if unique position was created */
                state.currentPositionIndex += 1;                
            }else{
                /*We don't change index if it's old position, just need to activate it */
                state.indexToPositionMeta[_position.posIndex].isActive = true;
            }
        }

        index = _position.posIndex;

        _position.trader = account;
        _position.lastChangeBlock = block.number;
        _position.isActive = true;
        _position.isLiquidated = false;

        _position.isLong = isLong;
        _position.market = _market;
        _position.cummulativeIndex = _market.currentOracleIndex();
        _position.initialTimestamp = block.timestamp;
        _position.initialBlockNumber = block.number;
        _position.entryPrice = initialPrice;

        int256 avgPrice = initialPrice;
        int256 prevAverage = _position.prevAvgPrice;
        if (prevAverage != 0){
            int256 prevNotional = _position.notional; //save 1 read
            avgPrice =(prevAverage.muld(prevNotional) + initialPrice.muld(notional)).divd(notional + prevNotional);
        }
        
        
        _position.prevAvgPrice = avgPrice;

        
        if (merge == true){
            _position.collateral +=  collateral; 
            _position.notional += notional;
            _position.initialPrice = avgPrice;
        }else{
            _position.collateral = collateral;
            _position.notional = notional;
            _position.initialPrice = initialPrice;
            
            //It's AMM need to deal with that in other places        
            if (address(_market) == account){
                _position.isAmm = true;
                _position.lastNotional = notional;
                _position.lastInitialPrice = initialPrice;
            }
        }
    }

    function unsetPosition(
        State storage state,
        Position storage _position
    ) internal {
        if (_position.isActive == false){
            return;
        } 

        /*
            Position is fully closed or liquidated, NEED to update PositionMeta 
            BUT
            we never reset the posIndex
        */
        state.indexToPositionMeta[_position.posIndex].isActive = false;

        _position.lastChangeBlock = block.number;
        _position.isActive = false;

        _position.entryPrice = 0;
        _position.collateral = 0; 
        _position.notional = 0; 
        _position.initialPrice = 0;
        _position.cummulativeIndex = 0;
        _position.initialTimestamp = 0;
        _position.initialBlockNumber = 0;
        _position.unrealizedPnl = 0;
        _position.prevAvgPrice = 0;
    }

    function partlyClose(
        State storage state,
        Position storage _position,
        int256 collateral,
        int256 notional,
        int256 unrealizedPaid
    ) internal {
        _position.collateral -= collateral; 
        _position.notional -= notional;
        _position.unrealizedPnl -= unrealizedPaid;
        _position.lastChangeBlock = block.number;
    }

    /*
    *******************************************************
    *******************************************************
    *   Liquidation related functions
    *******************************************************
    *******************************************************
    */
    function getLiquidationRatio(
        State storage state
    ) internal view returns (int256){
        return state.riskParams.liquidationMarginRatio;
    }


    //Integrity check outside
    function addCollateral(
        State storage state,
        Position storage _position,
        int256 collateral
    ) internal {
        _position.collateral += collateral;
    }

    function removeCollateral(
        State storage state,
        Position storage _position,
        int256 collateral
    ) internal {
        _position.collateral -= collateral;
        
        require(_position.collateral >= 0, "COLLATERAL_TOO_BIG");
    }



    /*
    *******************************************************
    *   Funds view/transfer utils
    *******************************************************
    */
    function depositToDao(
        State storage state,
        address _from,
        int256 _amount
    ) internal {
        require(_amount > 0, "WRONG_AMOUNT");
        require(state.dao != address(0), "ZERO_DAO");
        
        if (_from == address(this)){
            SafeERC20.safeTransfer(state.tradingToken,
                                        state.dao, 
                                        uint(_amount));
        }else{
            SafeERC20.safeTransferFrom(state.tradingToken, 
                                        _from, 
                                        state.dao, 
                                        uint(_amount));
        }

    }

    function depositToMarket(
        State storage state,
        IMarket _market,
        address _from,
        int256 _amount
    ) internal {
        require(_amount > 0, "WRONG_AMOUNT");

        getMarket(state, _market);

        int256 balanceBefore = int256(state.tradingToken.balanceOf(address(_market)));

        if (_from == address(this)){
            SafeERC20.safeTransfer(state.tradingToken, 
                                        address(_market), 
                                        uint(_amount));
        }else{
            SafeERC20.safeTransferFrom(state.tradingToken, 
                                        _from, 
                                        address(_market), 
                                        uint(_amount));
        }

        int256 diff = int256(state.tradingToken.balanceOf(address(_market))) - balanceBefore;

        IStakeble(address(_market)).externalLiquidityChanged(diff);

        IStakeble(address(_market)).changeTradingPnl(_amount);
    }
    
    function withdrawFromMarket(
        State storage state,
        IMarket _market,
        address _to,
        int256 _amount
    ) internal {
        require(_amount > 0, "WRONG_AMOUNT");

        getMarket(state, _market);

        IStakeble(address(_market)).ensureFunds(_amount);

        IStakeble(address(_market)).approveStrips(state.tradingToken, _amount);

        int256 balanceBefore = int256(state.tradingToken.balanceOf(address(_market)));

        SafeERC20.safeTransferFrom(state.tradingToken, 
                                    address(_market), 
                                    _to, 
                                    uint(_amount));
        
        int256 diff = int256(state.tradingToken.balanceOf(address(_market))) - balanceBefore;

        IStakeble(address(_market)).externalLiquidityChanged(diff);

        IStakeble(address(_market)).changeTradingPnl(0 - _amount);
    }

    function depositToInsurance(
        State storage state,
        address _from,
        int256 _amount
    ) internal {
        require(address(state.insuranceFund) != address(0), "BROKEN_INSURANCE_ADDRESS");

        int256 balanceBefore = int256(state.tradingToken.balanceOf(address(state.insuranceFund)));

        if (_from == address(this)){
            SafeERC20.safeTransfer(state.tradingToken, 
                                        address(state.insuranceFund), 
                                        uint(_amount));
        }else{
            SafeERC20.safeTransferFrom(state.tradingToken, 
                                        _from, 
                                        address(state.insuranceFund), 
                                        uint(_amount));
        }

        int256 diff = int256(state.tradingToken.balanceOf(address(state.insuranceFund))) - balanceBefore;

        IStakeble(address(state.insuranceFund)).externalLiquidityChanged(diff);

        IStakeble(address(state.insuranceFund)).changeTradingPnl(_amount);

    }
    
    function withdrawFromInsurance(
        State storage state,
        address _to,
        int256 _amount
    ) internal {
        
        require(address(state.insuranceFund) != address(0), "BROKEN_INSURANCE_ADDRESS");

        IStakeble(address(state.insuranceFund)).ensureFunds(_amount);

        state.insuranceFund.borrow(_to, _amount);

        IStakeble(address(state.insuranceFund)).changeTradingPnl(0 - _amount);
    }


}

interface IStripsEvents {
    event LogCheckData(
        address indexed account,
        address indexed market,
        CheckParams params
    );

    event LogCheckInsuranceData(
        address indexed insurance,
        CheckInsuranceParams params
    );

    struct CheckInsuranceParams{
        int256 lpLiquidity;
        int256 usdcLiquidity;
        uint256 sipTotalSupply;
    }

    // ============ Structs ============

    struct CheckParams{
        /*Integrity Checks */        
        int256 marketPrice;
        int256 oraclePrice;
        int256 tradersTotalPnl;
        int256 uniLpPrice;
        
        /*Market params */
        bool ammIsLong;
        int256 ammTradingPnl;
        int256 ammFundingPnl;
        int256 ammTotalPnl;
        int256 ammNotional;
        int256 ammInitialPrice;
        int256 ammEntryPrice;
        int256 ammTradingLiquidity;
        int256 ammStakingLiquidity;
        int256 ammTotalLiquidity;

        /*Trading params */
        bool isLong;
        int256 tradingPnl;
        int256 fundingPnl;
        int256 totalPnl;
        int256 marginRatio;
        int256 collateral;
        int256 notional;
        int256 initialPrice;
        int256 entryPrice;

        /*Staking params */
        int256 slpTradingPnl;
        int256 slpStakingPnl;
        int256 slpTradingCummulativePnl;
        int256 slpStakingCummulativePnl;
        int256 slpTradingPnlGrowth;
        int256 slpStakingPnlGrowth;
        int256 slpTotalSupply;

        int256 stakerInitialStakingPnl;
        int256 stakerInitialTradingPnl;
        uint256 stakerInitialBlockNum;
        int256 stakerUnrealizedStakingProfit;
        int256 stakerUnrealizedTradingProfit;

        /*Rewards params */
        int256 tradingRewardsTotal; 
        int256 stakingRewardsTotal;
    }
}

library StripsEvents {
    event LogCheckData(
        address indexed account,
        address indexed market,
        IStripsEvents.CheckParams params
    );

    event LogCheckInsuranceData(
        address indexed insurance,
        IStripsEvents.CheckInsuranceParams params
    );


    function logCheckData(address _account,
                            address _market, 
                            IStripsEvents.CheckParams memory _params) internal {
        
        emit LogCheckData(_account,
                        _market,
                        _params);
    }

    function logCheckInsuranceData(address insurance,
                                    IStripsEvents.CheckInsuranceParams memory _params) internal {
        
        emit LogCheckInsuranceData(insurance,
                                    _params);
    }

}

pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

interface IAssetOracle is KeeperCompatibleInterface {
    function getPrice() external view returns (int256);
    function calcOracleAverage(uint256 fromIndex) external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {

  /**
   * @notice checks if the contract requires work to be done.
   * @param checkData data passed to the contract when checking for upkeep.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with,
   * if upkeep is needed.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );

  /**
   * @notice Performs work on the contract. Executed by the keepers, via the registry.
   * @param performData is the data which was passed back from the checkData
   * simulation.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

pragma solidity ^0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "./IStripsLpToken.sol";
import { IStakebleEvents } from "../lib/events/Stakeble.sol";

interface IStakeble is IStakebleEvents {
    event BalanceChanged(
        uint256 indexed timestamp,
        address indexed asset,
        address indexed initiator,
        int256 diff,
        int256 currentBalance,
        int256 reason
    );

    event TokenAdded(
        address indexed asset,
        address indexed token
    );
    
    function changeSlp(IStripsLpToken _slpToken) external;

    function netLiquidity() external view virtual returns (int256);

    function totalStaked() external view returns (int256);
    function isInsurance() external view returns (bool);
    function liveTime() external view returns (uint);

    function getSlpToken() external view returns (address);
    function getStakingToken() external view returns (address);
    function getTradingToken() external view returns (address);
    function getStrips() external view returns (address);

    function ensureFunds(int256 amount) external;
    function stake(int256 amount) external;
    function unstake(int256 amount) external;

    function approveStrips(IERC20 _token, int256 _amount) external;
    function externalLiquidityChanged(int256 diff) external;

    function changeTradingPnl(int256 amount) external virtual;
    function changeStakingPnl(int256 amount) external virtual;

    function isRewardable() external view returns (bool);

    function changeSushiRouter(address _router) external;
    function getSushiRouter() external view returns (address);

    function getStrp() external view returns (address);
    
    function getPartedLiquidity() external view returns (int256 usdcLiquidity, int256 lpLiquidity);
    function getTvl() external view returns (int256);

    function isSwapOn() external view returns (bool);
    function changeSwapMode(bool _mode) external;

}

pragma solidity ^0.8.0;

import { SignedBaseMath } from "./SignedBaseMath.sol";
import { IMarket } from "../interface/IMarket.sol";
import { IStrips } from "../interface/IStrips.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IStripsLpToken } from "../interface/IStripsLpToken.sol";
import { IUniswapLpOracle } from "../interface/IUniswapLpOracle.sol";
import { IAssetOracle } from "../interface/IAssetOracle.sol";

import { IUniswapV2Pair } from "../external/interfaces/IUniswapV2Pair.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IRewarder } from "../interface/IRewarder.sol";

library StorageMarketLib {
    using SignedBaseMath for int256;

    /* Params that are set on contract creation */
    struct InitParams {
        IStrips stripsProxy;
        IAssetOracle assetOracle;
        IUniswapLpOracle pairOracle;

        int256 initialPrice;
        int256 burningCoef;

        IUniswapV2Pair stakingToken;
        IERC20 tradingToken;
        IERC20 strpToken;

        bool isRewardable;
        int256 notionalTolerance;

        int256 virtualLiquidity; // virtual liquidity that helps to decrease slippage
        int256 fundingPeriod;  // using for calculating funding_pnl (1 - default) should be 365 / k
    }

    /*Because of stack too deep error */
    struct Extended {
        address sushiRouter;
        uint createdAt;
        bool isSwapOn;
    }

    //Need to care about align here 
    struct State {
        address dao;
        
        InitParams params;
        IStripsLpToken slpToken;
        IRewarder rewarder;

        int256 totalLongs; //Real notional 
        int256 totalShorts; //Real notional
        
        int256 demand; //included proportion
        int256 supply; //included proportion
        
        int256 ratio;
        int256 _prevLiquidity;
        uint8 _currentLevel;
        
        Extended extend;
    }

    function pairPrice(
        State storage state
    ) internal view returns (int256){
        return state.params.pairOracle.getPrice();
    }

    //If required LP price conversions should be made here
    function calcStakingLiqudity(
        State storage state
    ) internal view returns (int256){
        return int256(state.params.stakingToken.balanceOf(address(this)));
    }

    function calcTradingLiqudity(
        State storage state
    ) internal view returns (int256){
        return int256(state.params.tradingToken.balanceOf(address(this)));
    }

    function netLiquidity(
        State storage state
    ) internal view returns (int256) {
        int256 stakingLiquidity = calcStakingLiqudity(state);
        
        if (stakingLiquidity != 0){
            stakingLiquidity = stakingLiquidity.muld(pairPrice(state)); //convert LP to USDC
        }

        int256 unrealizedPnl = state.params.stripsProxy.assetPnl(address(this));
        int256 exposure = state.totalLongs - state.totalShorts;
        if (exposure < 0){
            exposure *= -1;
        }

        return stakingLiquidity - exposure + unrealizedPnl + calcTradingLiqudity(state);
    }


    function getLiquidity(
        State storage state
    ) internal view returns (int256) {
        int256 stakingLiquidity = calcStakingLiqudity(state);
        
        if (stakingLiquidity != 0){
            stakingLiquidity = stakingLiquidity.muld(pairPrice(state)); //convert LP to USDC
        }

        return stakingLiquidity + calcTradingLiqudity(state);
    }

    //Should return the scalar
    function maxNotional(
        State storage state
    ) internal view returns (int256 maxLong, int256 maxShort) {
        int256 _liquidity = getLiquidity(state);

        if (_liquidity <= 0){
            return (0,0);
        }
        int256 unrealizedPnl = state.params.stripsProxy.assetPnl(address(this));
        int256 ammExposure = state.totalShorts - state.totalLongs;
        
        maxLong = (_liquidity + ammExposure + unrealizedPnl).muld(state.params.notionalTolerance);
        maxShort = (_liquidity - ammExposure + unrealizedPnl).muld(state.params.notionalTolerance);
    }


    function getPrices(
        State storage state
    ) internal view returns (int256 marketPrice, int256 oraclePrice){
        marketPrice = currentPrice(state);

        oraclePrice = IAssetOracle(state.params.assetOracle).getPrice();
    }

    function currentPrice(
        State storage state
    ) internal view returns (int256) {
        return state.params.initialPrice.muld(state.ratio);
    }


    function oraclePrice(
        State storage state
    ) internal view returns (int256) {
        return IAssetOracle(state.params.assetOracle).getPrice();
    }

    function approveStrips(
        State storage state,
        IERC20 _token,
        int256 _amount
    ) internal {
        require(_amount > 0, "BAD_AMOUNT");

        SafeERC20.safeApprove(_token, 
                                address(state.params.stripsProxy), 
                                uint(_amount));
    }
    
    function _updateRatio(
        State storage state,
        int256 _longAmount,
        int256 _shortAmount
    ) internal
    {
        /*
            supply = liquidity / (1 + ratio)
            demand = supply * ratio
            ratio = demand / supply

            Adding new liquidity (real or virtual) should not change the ratio.
        */
        int256 _liquidity = getLiquidity(state) + state.params.virtualLiquidity; 
        if (state._prevLiquidity == 0){
            /* initial setup */
            state.supply = _liquidity.divd(SignedBaseMath.oneDecimal() + state.ratio);
            state.demand = state.supply.muld(state.ratio);
            state._prevLiquidity = _liquidity;
        }

        int256 diff = _liquidity - state._prevLiquidity;

        state.demand += (_longAmount + diff.muld(state.ratio.divd(SignedBaseMath.oneDecimal() + state.ratio)));
        state.supply += (_shortAmount + diff.divd(SignedBaseMath.oneDecimal() + state.ratio));
        if (state.demand <= 0 || state.supply <= 0){
            require(0 == 1, "BROKEN_DEMAND_SUPPLY");
        }

        state.ratio = state.demand.divd(state.supply);
        state._prevLiquidity = _liquidity;
    }


    // we need this to be VIEW to use for priceChange calculations
    function _whatIfRatio(
        State storage state,
        int256 _longAmount,
        int256 _shortAmount
    ) internal view returns (int256){
        int256 ratio = state.ratio;
        int256 supply = state.supply;
        int256 demand = state.demand;
        int256 prevLiquidity = state._prevLiquidity;

        int256 _liquidity = getLiquidity(state) + state.params.virtualLiquidity;
        if (prevLiquidity == 0){
            supply = _liquidity.divd(SignedBaseMath.oneDecimal() + ratio);
            demand = supply.muld(ratio);
            prevLiquidity = _liquidity;
        }

        int256 diff = _liquidity - prevLiquidity;

        demand += (_longAmount + diff.muld(ratio.divd(SignedBaseMath.oneDecimal() + ratio)));
        supply += (_shortAmount + diff.divd(SignedBaseMath.oneDecimal() + ratio));
        if (demand <= 0 || supply <= 0){
            require(0 == 1, "BROKEN_DEMAND_SUPPLY");
        }

        return demand.divd(supply);

    }
}