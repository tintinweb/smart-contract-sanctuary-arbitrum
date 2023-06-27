/*
    Roulette contract - Arbitrum Gambling
    Developed by Kerry <TG: campermon>
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./BasicLibraries/SafeMath.sol";
import "./BasicLibraries/Context.sol";
import "./BasicLibraries/Auth.sol";
import "./BasicLibraries/IBEP20.sol";
import "./Libraries/BetsManager.sol";
import "./Libraries/SpinsManager.sol";
import "./Libraries/ProfitsManager.sol";
import "./Libraries/ICasinoTreasury.sol";
import "./Libraries/IWETH.sol";
import "./Chainlink/VRFv2SubscriptionManager.sol";
import "./Chainlink/VRFCoordinatorV2Interface.sol";
import "./UniswapV3/IUniswapV3PoolActions.sol";
import "./UniswapV3/IUniswapV3PoolImmutables.sol";

contract Roulette is Context, Auth, VRFv2SubscriptionManager {
    using SafeMath for uint256;

    // Event perform bet
    event PerformBet(address indexed adr, uint256 indexed amountBet, uint256 spinsPerformedToday, uint256 spinsLeftToday, uint256 amountLeftForDailyMaxProfit, uint256 amountLeftForWeeklyMaxProfit);
    // Event claim bet
    event ClaimBet(address indexed adr, uint256 betIndex, uint256 indexed dollarsWon, uint256 currentDepositDollars);
    // Event solve bet
    event SolveBet(address indexed adr, uint256 betIndex, uint256 indexed _prizeType, uint256 _prizeSubtype);
    // Event cancel bet
    event CancelBet(address indexed adr, uint256 betIndex, uint256 indexed dollarsTransferred);
    // Fund subscription
    event FundSubscription(uint256 amount);

    // Casino treasury
    ICasinoTreasury casinoTreasury;

    // Bets manager
    BetsManager betsManager;

    // Profits manager
    ProfitsManager profitsManager;

    // Spins manager
    SpinsManager spinsManager;

    // LINK SWAPS
    IUniswapV3PoolActions linkLiqPoolActions;
    IUniswapV3PoolImmutables linkLiqPoolInmutables;
    // The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739; // ((1.0001^-887220)^(1/2))*2^96

    constructor (address _casinoTreasury, address _vrfCoord, address _linkAdr, address _linkPool) Auth(msg.sender) VRFv2SubscriptionManager(_vrfCoord, _linkAdr) { 
        casinoTreasury = ICasinoTreasury(_casinoTreasury);
        betsManager = new BetsManager(address(this), _casinoTreasury);
        profitsManager = new ProfitsManager(address(this));
        spinsManager = new SpinsManager(address(this), _casinoTreasury);
        linkLiqPoolActions = IUniswapV3PoolActions(_linkPool);
        linkLiqPoolInmutables = IUniswapV3PoolImmutables(_linkPool);  
    }

    //region VIEWS

    function getOwner() public view returns (address) {return owner;}
    function isEmptyString(string memory _string) public pure returns (bool) { return bytes(_string).length == 0; }

    //endregion

    //region MANAGERS VIEW

    function getBetManagerAdr() public view returns(address) { return address(betsManager); }
    function getProfitsManagerAdr() public view returns(address) { return address(profitsManager); }
    function getSpinsManagerAdr() public view returns(address) { return address(spinsManager); }
    function getCasinoTreasuryAdr() public view returns(address) { return address(casinoTreasury); }

    //endregion

    function performBet(uint256 betAmount) public {
        address adr = _msgSender();
        uint256 tokensRequired = casinoTreasury.calcTokensFromDollars(betAmount);
        require(tokensRequired <= casinoTreasury.balanceOf(adr), "You have not enough tokens");

        // Did you reach the max profit per day
        require(!profitsManager.maxDailyProfitReached(adr), "Max daily profit reached, try again tomorrow");

        // Did you reach the max profit per week
        require(!profitsManager.maxWeeklyProfitReached(adr), "Max weekly profit reached, try again soon");

        // Performs the bet
        betsManager._performBet(betAmount, adr);

        // Remove tokens from your balance
        casinoTreasury.UpdateBalancesSub(adr, tokensRequired);

        // Register the spin
        spinsManager.registerDailySpin(adr);

        // Register losses
        profitsManager.registerLosses(adr, betAmount);

        // Request random word for solving
        requestRandomWords();

        // Some of the amount will be send to the token contract as tax
        bool success = casinoTreasury.TaxPayment(tokensRequired);
        require(success, isEmptyString(casinoTreasury.withdrawError()) ? "Wait till owners replenish the token pool" : casinoTreasury.withdrawError());

        emit PerformBet(adr, betAmount, spinsManager.getUserDailySpinsPerformed(adr), spinsManager.getUserDailySpinsLeft(adr), profitsManager.amountLeftForDailyMaxProfit(adr), profitsManager.amountLeftForWeeklyMaxProfit(adr));
    }

    function claimBet(uint256 betIndex) public {
        address user = betsManager._getBetUser(betIndex);
        require(user == _msgSender() || isAuthorized(_msgSender()), "You are not bet owner or authorized");

        // Claim prize
        uint256 dollarsTransfer = betsManager._claimBet(betIndex);

        // Convert amount and send money to user balance
        if(dollarsTransfer > 0) {
            uint256 _nTokens = casinoTreasury.calcTokensFromDollars(dollarsTransfer);
            casinoTreasury.UpdateBalancesAdd(user, _nTokens);
            // Register profits
            profitsManager.registerProfits(user, dollarsTransfer);
        }

        emit ClaimBet(user, betIndex, dollarsTransfer, casinoTreasury.calcDollars(casinoTreasury.balanceOf(user)));
    }

    function cancelBet(uint256 betIndex) public {
        address user = betsManager._getBetUser(betIndex);
        require(user == _msgSender() || isAuthorized(_msgSender()), "You are not bet owner or authorized");

        // Cancel bet
        uint256 dollarsTransfer = betsManager._cancelBet(betIndex);

        // Convert amount and send money to user balance
        if(dollarsTransfer > 0) {
            uint256 _nTokens = casinoTreasury.calcTokensFromDollars(dollarsTransfer);
            casinoTreasury.UpdateBalancesAdd(user, _nTokens);
            // Register profits
            profitsManager.registerProfits(user, dollarsTransfer);
        }

        emit CancelBet(user, betIndex, dollarsTransfer);
    }

    //endregion   

    //region SOLVER

    function simulateSpin(uint256 randomBase10000) public view returns(uint8, uint8) { 
        return betsManager._simulateSpin(randomBase10000); 
    }

    // AUTHORIZED SOLVER
    function solveBet(uint256 betIndex, uint8 _prizeType, uint8 _prizeSubtype) external authorized {
        _solveBet(betIndex, _prizeType, _prizeSubtype);
    }

    function _solveBet(uint256 betIndex, uint8 _prizeType, uint8 _prizeSubtype) internal {
        address user = betsManager._getBetUser(betIndex);
        betsManager._solveBet(betIndex, _prizeType, _prizeSubtype);

        emit SolveBet(user, betIndex, _prizeType, _prizeSubtype);
    }

    //endregion

    //region CHAINLINK SOLVER

    function fulfillRandomWords(uint256 /*requestId*/, uint256[] memory randomWords) override internal {
        // Get pending bets and solve one, we dont care which one
        (uint8 _prizeType, uint8 _prizeSubtype) = simulateSpin(randomWords[0] % 10000);
        uint256 [] memory pendingBets = betsManager.getBetsPendingSolve(1);
        _solveBet(pendingBets[0], _prizeType, _prizeSubtype);
    }

    function fundSubscription() public payable {
        _fundSubscription(msg.value, true);
    }

    function _fundSubscription(uint256 _amountSent, bool _manual) internal {    
        // WRAP ETH
        IWETH wethI = IWETH(linkLiqPoolInmutables.token0()); // TOKEN0 WETH
        wethI.deposit{value: _amountSent}();
        // APPROVE POOL
        wethI.approve(address(linkLiqPoolActions), type(uint256).max);
              
        bool success = true;
        if(_manual) {
            linkLiqPoolActions.swap(address(this), true, int256(_amountSent), MIN_SQRT_RATIO + 1, abi.encode(0)/*abi.encode(path, payer)*/);
        } else {
            try linkLiqPoolActions.swap(address(this), true, int256(_amountSent), MIN_SQRT_RATIO + 1, abi.encode(0)/*abi.encode(path, payer)*/) {                
            } catch {
                success = false;
            }
        }

        if(success) {
            uint256 tokenBalance = LINKTOKEN.balanceOf(address(this));
            emit FundSubscription(tokenBalance);
            topUpSubscription(tokenBalance);
        }
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256, bytes calldata) external {
        require(msg.sender == address(linkLiqPoolActions), "Adr not allowed");
        require(amount0Delta > 0, "Not a buy?");

        address weth = linkLiqPoolInmutables.token0();
        IBEP20(weth).transfer(address(linkLiqPoolActions), uint256(amount0Delta));
    }

    //endregion

    //region ADMIN

    //region MAIN

    function clearStuckToken(address _tokenAddress, uint256 _tokens) public onlyOwner returns (bool) {
        if(_tokens == 0){
            _tokens = IBEP20 (_tokenAddress).balanceOf(address(this));
        }
        return IBEP20 (_tokenAddress).transfer(msg.sender, _tokens);
    }    

    function ClearStuckBalance() external onlyOwner { payable(msg.sender).transfer(address(this).balance); }  

    //endregion

    //region PROFITS MANAGER

    function setProfitsManagerAdr(address adr) external onlyOwner { profitsManager = ProfitsManager(adr); }

    function setMaxDailyWeeklyProfit(uint256 _maxDailyProfit, uint256 _maxWeeklyProfit) public onlyOwner {
        profitsManager._setMaxDailyWeeklyProfit(_maxDailyProfit, _maxWeeklyProfit);
    }

    //endregion

    //region SPINS MANAGER

    function setSpinsManagerAdr(address adr) external onlyOwner { spinsManager = SpinsManager(adr); }

    function setMaxDailySpins(uint256 _maxDailySpins) public onlyOwner {
        spinsManager._setMaxDailySpins(_maxDailySpins);
    }

    //endregion

    //region BETS MANAGER

    function setBetManagerAdr(address adr) external onlyOwner { betsManager = BetsManager(adr); }

    function setPrizeChanceOptions( 
        uint8 [] memory _prizeType, 
        uint8 [] memory _prizeSubtype,
        uint256 [] memory _chanceBase10000) public onlyOwner {
            betsManager._setPrizeChanceOptions(_prizeType, _prizeSubtype, _chanceBase10000);
    }

    function setCustomDollarPrize(uint8 _n, uint256 _amount) public onlyOwner { betsManager._setCustomDollarPrize(_n, _amount); }

    function setCustomNFTPrize(uint8 _n, address _address) public onlyOwner { betsManager._setCustomNFTPrize(_n, _address); }

    function enableDisableBetAmount(uint256 _dollarsAmount, bool _enabled) public onlyOwner { betsManager._enableDisableBetAmount(_dollarsAmount, _enabled); }

    //endregion

    //region CHAINLINK_REQ_CONFIG

    function setReqConfig(bytes32 _keyhash, uint32 _callbackGasLimit, uint16 _requestConfirmations, uint32 _numWords) external onlyOwner {
        _setReqConfig(_keyhash, _callbackGasLimit, _requestConfirmations, _numWords);
    }

    //endregion

    //endregion

    receive() external payable {
        _fundSubscription(msg.value, false);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

/*
    Roulette contract - Arbitrum Gambling
    Developed by Kerry <TG: campermon>
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DateTime.sol";
import "../BasicLibraries/SafeMath.sol";
import "./ICasinoTreasury.sol";

contract SpinsManager is DateTime {
    using SafeMath for uint256;

    address public rouletteCA;

    modifier onlyRoulette() {
        require(msg.sender == rouletteCA, "Only roulette"); _;
    }

    // Spins performed
    mapping (address => mapping (uint256 => uint256)) public dailySpinsPerformed;

    // Max spins per day
    uint256 public maxDailySpins = 50;

    // Casino treasury iface
    ICasinoTreasury casinoTreasury;

    constructor(address _rouletteCA, address _casinoTreasury) { 
        rouletteCA = _rouletteCA; 
        casinoTreasury = ICasinoTreasury(_casinoTreasury);
    }

    // region SPINS

    // Get user spins performed
    function getUserDailySpinsPerformed(address adr) public view returns(uint256) {
        return dailySpinsPerformed[adr][dayStartTimestamp(block.timestamp)];
    }

    // Get max dailt spins
    function getUserDailySpins() public view returns(uint256) {
        return maxDailySpins;
    }

    // Get user daily spins left
    function getUserDailySpinsLeft(address adr) public view returns(uint256) {
        uint256 userDailySpins = getUserDailySpins();
        uint256 userDailySpinsPerformed = getUserDailySpinsPerformed(adr);
        return userDailySpins.sub(userDailySpinsPerformed);
    }

    // Can user perform daily spin    
    function canUserPerformDailySpin(address adr) public view returns(bool) {
        return getUserDailySpinsLeft(adr) > 0;
    }

    // Register spin
    function registerDailySpin(address adr) public onlyRoulette {
        require(canUserPerformDailySpin(adr), "You have no spins left for today");
        dailySpinsPerformed[adr][dayStartTimestamp(block.timestamp)]++;
    }

    // endregion

    // region ADMIN

    function _setMaxDailySpins(uint256 _maxDailySpins) public onlyRoulette {
        require(_maxDailySpins >= 5, "Max daily spins has to be 5 or more");
        maxDailySpins = _maxDailySpins;
    }

    // endregion
}

/*
    Roulette contract - Arbitrum Gambling
    Developed by Kerry <TG: campermon>
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DateTime.sol";
import "../BasicLibraries/SafeMath.sol";

contract ProfitsManager is DateTime {
    using SafeMath for uint256;

    address public rouletteCA;

    modifier onlyRoulette() {
        require(msg.sender == rouletteCA, "Only roulette"); _;
    }

    // Daily profit
    mapping (address => mapping (uint256 => uint256)) public dailyProfit;
    // Daily losses
    mapping (address => mapping (uint256 => uint256)) public dailyLosses;
    // Weekly profit
    mapping (address => mapping (uint256 => uint256)) public weeklyProfit;
    // Weekly losses
    mapping (address => mapping (uint256 => uint256)) public weeklyLosses;

    // Max daily profit $ // Does not apply to free spins
    uint256 public maxDailyProfit = 50;
    // Max weekly profit $ // Does not apply to free spins   
    uint256 public maxWeeklyProfit = 300;

    constructor (address _rouletteCA) { rouletteCA = _rouletteCA; }

    //region VIEWS
    function getUserDailyProfit(address adr) public view returns(uint256) {
        return dailyProfit[adr][dayStartTimestamp(block.timestamp)];
    }

    function getUserWeeklyProfit(address adr) public view returns(uint256) {
        return weeklyProfit[adr][weekStartTimestamp(block.timestamp)];
    }

    function getUserDailyLosses(address adr) public view returns(uint256) {
        return dailyLosses[adr][dayStartTimestamp(block.timestamp)];
    }

    function getUserWeeklyLosses(address adr) public view returns(uint256) {
        return weeklyLosses[adr][weekStartTimestamp(block.timestamp)];
    }

    function amountLeftForDailyMaxProfit(address adr) public view returns(uint256) {
        uint256 _dailyProfit = getUserDailyProfit(adr);
        uint256 _dailyLosses = getUserDailyLosses(adr);

        if(_dailyProfit >= _dailyLosses) {
            uint256 _diff = _dailyProfit.sub(_dailyLosses);
            if(_diff >= maxDailyProfit) {
                return 0;
            } else {
                return maxDailyProfit.sub(_diff);
            }
        } else {
            return _dailyLosses.sub(_dailyProfit).add(maxDailyProfit);
        }
    }

    function amountLeftForWeeklyMaxProfit(address adr) public view returns(uint256) {
        uint256 _dailyProfit = getUserWeeklyProfit(adr);
        uint256 _dailyLosses = getUserWeeklyLosses(adr);

        if(_dailyProfit >= _dailyLosses) {
            uint256 _diff = _dailyProfit.sub(_dailyLosses);
            if(_diff >= maxWeeklyProfit) {
                return 0;
            } else {
                return maxWeeklyProfit.sub(_diff);
            }
        } else {
            return _dailyLosses.sub(_dailyProfit).add(maxWeeklyProfit);
        }
    }

    function maxDailyProfitReached(address adr) public view returns(bool) {
        uint256 _dailyProfit = getUserDailyProfit(adr);
        uint256 _dailyLosses = getUserDailyLosses(adr);

        return _dailyProfit > _dailyLosses.add(maxDailyProfit);
    }

    function maxWeeklyProfitReached(address adr) public view returns(bool) {
        uint256 _weeklyProfit = getUserWeeklyProfit(adr);
        uint256 _weeklyLosses = getUserWeeklyLosses(adr);

        return _weeklyProfit > _weeklyLosses.add(maxWeeklyProfit);
    }
    //endregion

    // Register profits
    function registerProfits(address adr, uint256 profitDollars) public onlyRoulette {
        dailyProfit[adr][dayStartTimestamp(block.timestamp)] += profitDollars;
        weeklyProfit[adr][weekStartTimestamp(block.timestamp)] += profitDollars;
    }

    // Register losses
    function registerLosses(address adr, uint256 lossesDollars) public onlyRoulette {
        dailyLosses[adr][dayStartTimestamp(block.timestamp)] += lossesDollars;
        weeklyLosses[adr][weekStartTimestamp(block.timestamp)] += lossesDollars;
    }

    // Admin
    function _setMaxDailyWeeklyProfit(uint256 _maxDailyProfit, uint256 _maxWeeklyProfit) public onlyRoulette {
        require(_maxDailyProfit >= 25, "Can not be lower than 25");
        require(_maxWeeklyProfit >= 100, "Can not be lower than 100");
        maxDailyProfit = _maxDailyProfit;
        maxWeeklyProfit = _maxWeeklyProfit;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;
    function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFT {
    function casinoMint(address _receiver) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICasinoTreasury {
    function UpdateBalancesAdd(address _adr, uint256 _nTokens) external;
    function UpdateBalancesSub(address _adr, uint256 _nTokens) external;
    function TaxPayment(uint256 _nTokens) external returns(bool);
    function balanceOf(address _adr) external returns(uint256);
    function withdrawError() external returns(string memory);
    function calcTokensFromDollars(uint256 _nDollars) external view returns(uint256);
    function calcDollars(uint256 _nTokens) external view returns(uint256);
    function tokenAdr() external returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DateTime {
        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
        struct _DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }

        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;

        uint16 constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint16 year) public pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

        function leapYearsBefore(uint year) public pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }

        function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory) {
                _DateTime memory dt;

                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;

                // Year
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

                // Month
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }

                // Day
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }

                // Hour
                dt.hour = getHour(timestamp);

                // Minute
                dt.minute = getMinute(timestamp);

                // Second
                dt.second = getSecond(timestamp);

                // Day of week.
                dt.weekday = getWeekday(timestamp);

                return dt;
        }

        function getYear(uint timestamp) public pure returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;

                // Year
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }

        function getMonth(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }

        function getMinute(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }

        function getSecond(uint timestamp) public pure returns (uint8) {
                return uint8(timestamp % 60);
        }

        function getWeekday(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, minute, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
                uint16 i;

                // Year
                for (i = ORIGIN_YEAR; i < year; i++) {
                        if (isLeapYear(i)) {
                                timestamp += LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                timestamp += YEAR_IN_SECONDS;
                        }
                }

                // Month
                uint8[12] memory monthDayCounts;
                monthDayCounts[0] = 31;
                if (isLeapYear(year)) {
                        monthDayCounts[1] = 29;
                }
                else {
                        monthDayCounts[1] = 28;
                }
                monthDayCounts[2] = 31;
                monthDayCounts[3] = 30;
                monthDayCounts[4] = 31;
                monthDayCounts[5] = 30;
                monthDayCounts[6] = 31;
                monthDayCounts[7] = 31;
                monthDayCounts[8] = 30;
                monthDayCounts[9] = 31;
                monthDayCounts[10] = 30;
                monthDayCounts[11] = 31;

                for (i = 1; i < month; i++) {
                        timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
                }

                // Day
                timestamp += DAY_IN_SECONDS * (day - 1);

                // Hour
                timestamp += HOUR_IN_SECONDS * (hour);

                // Minute
                timestamp += MINUTE_IN_SECONDS * (minute);

                // Second
                timestamp += second;

                return timestamp;
        }

        function dayStartTimestamp(uint _timestamp) public pure returns (uint timestamp) {
                return toTimestamp(getYear(_timestamp), getMonth(_timestamp), getDay(_timestamp));
        }

        function weekStartTimestamp(uint _timestamp) public pure returns (uint timestamp) {
                return toTimestamp(getYear(_timestamp), getMonth(_timestamp), ((getDay(_timestamp) / 7) * 7) + 1);
        }
}

/*
    Roulette contract - Arbitrum Gambling
    Developed by Kerry <TG: campermon>
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BasicLibraries/SafeMath.sol";
import "./INFT.sol";
import "./ICasinoTreasury.sol";

contract BetsManager {
    using SafeMath for uint256;

    address public rouletteCA;

    modifier onlyRoulette() {
        require(msg.sender == rouletteCA, "Only roulette"); _;
    }

    constructor(address _rouletteCA, address _casinoTreasury) { 
        rouletteCA = _rouletteCA; 
        casinoTreasury = ICasinoTreasury(_casinoTreasury);
    }

    //region VARIABLES

    // Casino treasury iface
    ICasinoTreasury casinoTreasury;

    // Next bet index
    uint256 public nextBet = 1;

    // Bets
    mapping (uint256 => bet) public bets;

    // User pending bets
    mapping (address => uint256 []) public userPendingBets;

    // User pending bets claim
    mapping (address => uint256 []) public userPendingBetsClaim;

    // Bet amounts enabled, in dollars
    mapping (uint256 => bool) public betsEnabled;
    
    // Custom dollars prizes
    mapping (uint8 => uint256) public customDollarPrizes;
    mapping (uint8 => address) public customNFTPrizes;

    // Roulette prizes chances
    prizeChance [] public prizeChancesOption;

    //endregion

    //region ENUMS

    //region Prizes types

    enum prizeType {
        none,
        x2reward,
        x5reward,
        x10reward,
        freeSpin,               // the tokens you used to bet will be returned to you
        customPrizeDollarAmount,
        NFT
    }

    //endregion

    //region Bets

    enum betType {
        none,
        paid
    }

    enum betState {
        none,
        pending,
        solved,
        claimed,
        cancelled                             // tokens will be returned to user
    }

    struct bet {
        uint256 index;
        address user;
        uint256 betAmount;                    // amount in dollars
        uint8 _type;                          // betType
        uint8 state;                          // betState
        uint8 prizeWon;                       // prizeType
        uint8 customPrizeDollarAmountWonType; // only if customPrizeDollarAmount
        uint8 NFTwonType;                     // only if NFT
    }

    //endregion

    //region Prizes chances

    struct prizeChance {
        uint8 _prizeType;                     // prizeType enum
        uint8 prizeSubtype;                   // customDollarPrizes or customNFTPrizes
        uint256 chanceBase10000;
    }

    //endregion

    //endregion

    //region VIEWS

    function _getBetUser(uint256 betIndex) public view returns(address) { return bets[betIndex].user; }

    function isBetEnabled(uint256 _bet) public view returns (bool) { return betsEnabled[_bet]; }

    function getUserPendingBets(address adr) public view returns(uint256 [] memory) { return userPendingBets[adr]; }

    function getUserPendingBetsClaim(address adr) public view returns(uint256 [] memory) { return userPendingBetsClaim[adr]; }

    function getBetsPendingSolve(uint8 nBets) public view returns(uint256 [] memory) {
        uint256 [] memory result = new uint256 [](nBets);
        uint256 _count = 0;
        for(uint256 _i = nextBet - 1; _i > 0; _i--) {
            if(bets[_i].state == 1) {
                result[_count] = bets[_i].index;
                _count++;
            }
            if(_count >= nBets) {
                break;
            }
        }
        return result;
    }

    //endregion

    //region USER

    // Perform bet (transferences and taxes managed on main contract)
    function _performBet(uint256 betAmount, address adr) public onlyRoulette {
        require(isBetEnabled(betAmount), "That amount is not enabled");

        bets[nextBet] = bet(
            nextBet,
            adr,
            betAmount,
            uint8(betType.paid),
            uint8(betState.pending),
            0,
            0,
            0
        );

        userPendingBets[bets[nextBet].user].push(nextBet);
        nextBet++;
    }

    // Claim bet prize, returns prize in dollars (transferences managed on main contract)
    function _claimBet(uint256 betIndex) public onlyRoulette returns(uint256) {
        require(bets[betIndex].state == uint8(betState.solved), "Bet is still not solved, can not be claimed");
        require(bets[betIndex].state != uint8(betState.claimed), "Bet was already claimed");
        require(bets[betIndex].state != uint8(betState.cancelled), "Bet was cancelled");

        _removeUserPendingBetClaim(betIndex);
        bets[betIndex].state = uint8(betState.claimed);

        // Send the prize
        if(bets[betIndex].prizeWon == uint8(prizeType.none)) {
            // You lost, nothing to do here
            return 0;
        } 
        if(bets[betIndex].prizeWon == uint8(prizeType.x2reward)) {
            // You get your bet amount x2
            return bets[betIndex].betAmount.mul(2);
        }
        if(bets[betIndex].prizeWon == uint8(prizeType.x5reward)) {
            // You get your bet amount x5
            return bets[betIndex].betAmount.mul(5);
        }
        if(bets[betIndex].prizeWon == uint8(prizeType.x10reward)) {
            // You get your bet amount x10
            return bets[betIndex].betAmount.mul(10);
        }
        if(bets[betIndex].prizeWon == uint8(prizeType.freeSpin)) {
            // Just your bet amount returns to you
            return bets[betIndex].betAmount;
        }
        if(bets[betIndex].prizeWon == uint8(prizeType.customPrizeDollarAmount)) {
            // You get a custom dollar amount            
            return customDollarPrizes[bets[betIndex].customPrizeDollarAmountWonType];
        }
        if(bets[betIndex].prizeWon == uint8(prizeType.NFT)) {
            // You get an NFT            
            address adrNFT = customNFTPrizes[bets[betIndex].NFTwonType];
            // Perform NFT mint and transfer
            INFT nftMintIFACE = INFT(adrNFT);
            nftMintIFACE.casinoMint(bets[betIndex].user);
            return 0;
        }

        // Should never reach here
        return 0;
    }    

    // Cancels the bet and returns the money to be returned to the address, only can be called for owner or user (transferences managed on main contract)
    function _cancelBet(uint256 betIndex) public onlyRoulette returns(uint256) {      
        require(bets[betIndex].state == uint8(betState.pending), "Bet is not pending");
        bets[betIndex].state = uint8(betState.cancelled);
        _removeUserPendingBet(betIndex);
        return bets[betIndex].betAmount;
    }

    //endregion

    //region BET SOLVER
    
    // Simulates an spin and returns the prize type won and subtype
    function _simulateSpin(uint256 randomBase10000) public view returns(uint8, uint8) {
        uint256 acum = 0;

        for(uint256 _i = 0; _i < prizeChancesOption.length; _i++) {
            uint256 previousAcum = acum;
            acum += prizeChancesOption[_i].chanceBase10000;
            if(randomBase10000 <= acum && randomBase10000 > previousAcum) {
                return (prizeChancesOption[_i]._prizeType, prizeChancesOption[_i].prizeSubtype);
            }
        }

        return (uint8(prizeType.none), 0);
    }

    // Solves the bet and sets the prize won
    function _solveBet(uint256 betIndex, uint8 _prizeType, uint8 prizeSubtype) public onlyRoulette {
        require(bets[betIndex].state == uint8(betState.pending), "Bet is not pending");

        // Solved
        bets[betIndex].state = uint8(betState.solved);

        // Prize type
        bets[betIndex].prizeWon = _prizeType;

        // Subtype
        if(bets[betIndex].prizeWon == uint8(prizeType.customPrizeDollarAmount)) {
            bets[betIndex].customPrizeDollarAmountWonType = prizeSubtype;
        }
        if(bets[betIndex].prizeWon == uint8(prizeType.NFT)) {
            bets[betIndex].NFTwonType = prizeSubtype;
        }

        // Set bet as pending to claim for user
        _removeUserPendingBet(betIndex);
        userPendingBetsClaim[bets[betIndex].user].push(betIndex);
    }

    //endregion

    //region ADMIN

    function _setCustomDollarPrize(uint8 _n, uint256 _amount) public onlyRoulette { customDollarPrizes[_n] = _amount; }

    function _setCustomNFTPrize(uint8 _n, address _address) public onlyRoulette { customNFTPrizes[_n] = _address; }

    function _enableDisableBetAmount(uint256 _dollarsAmount, bool _enabled) public onlyRoulette {
        require(_dollarsAmount <= 1000, "Too big ");
        betsEnabled[_dollarsAmount] = _enabled;
    }

    function _setPrizeChanceOptions(uint8 [] memory _prizeType, uint8 [] memory _prizeSubtype, uint256 [] memory _chanceBase10000) public onlyRoulette {
        require(_prizeType.length == _prizeSubtype.length, "Same size arrays are required here _prizeType != _prizeSubtype");
        require(_prizeSubtype.length == _chanceBase10000.length, "Same size arrays are required here _prizeSubtype != _chanceBase10000");
        require(_prizeType[_prizeType.length - 1] == uint8(prizeType.none), "Last element has to be the chance to lose");      

        delete prizeChancesOption;
        for(uint256 _i; _i < _prizeType.length; _i++) {
            prizeChancesOption.push(prizeChance(
                _prizeType[_i],
                _prizeSubtype[_i],
                _chanceBase10000[_i]));
        }
    }

    //endregion

    //region UTILS

    // Remove the bet from user pending bets list, only internal use
    function _removeUserPendingBet(uint256 betIndex) private {
        uint256 _indexDelete = 0;
        bool _found = false;
        for(uint256 _i = 0; _i < userPendingBets[bets[betIndex].user].length; _i++){
            if(userPendingBets[bets[betIndex].user][_i] == betIndex){
                _indexDelete = _i;
                _found = true;
                break;
            }
        }    

        if(_found){
            userPendingBets[bets[betIndex].user][_indexDelete] = userPendingBets[bets[betIndex].user][userPendingBets[bets[betIndex].user].length - 1];
            userPendingBets[bets[betIndex].user].pop();
        }
    }

    // Remove the bet from user pending claim bets list, only internal use
    function _removeUserPendingBetClaim(uint256 betIndex) private {
        uint256 _indexDelete = 0;
        bool _found = false;
        for(uint256 _i = 0; _i < userPendingBetsClaim[bets[betIndex].user].length; _i++){
            if(userPendingBetsClaim[bets[betIndex].user][_i] == betIndex){
                _indexDelete = _i;
                _found = true;
                break;
            }
        }

        if(_found){
            userPendingBetsClaim[bets[betIndex].user][_indexDelete] = userPendingBetsClaim[bets[betIndex].user][userPendingBetsClaim[bets[betIndex].user].length - 1];
            userPendingBetsClaim[bets[betIndex].user].pop();
        }
    }

    //endregion
}

// SPDX-License-Identifier: MIT
// An example of a consumer contract that also owns and manages the subscription
pragma solidity ^0.8.7;

import "./LinkTokenInterface.sol";
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

contract VRFv2SubscriptionManager is VRFConsumerBaseV2 {
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    // Sepolia coordinator. For other networks,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    //address vrfCoordinator = 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625;

    // Sepolia LINK token contract. For other networks, see
    // https://docs.chain.link/docs/vrf-contracts/#configurations
    //address link_token_contract = 0x779877A7B0D9E8603169DdbD7836e478b4624789;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf-contracts/#configurations
    bytes32 keyHash = 0x08ba8f62ff6c40a58877a106147661db43bc58dabfb814793847a839aa03367f;

    // A reasonable default is 2000000, but this value could be different
    // on other networks.
    uint32 callbackGasLimit = 2000000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWords = 1;

    // Storage parameters
    //uint256[] public s_randomWords;
    uint256 public s_requestId;
    uint64 public s_subscriptionId;
    address s_owner;

    constructor(address _vrfCoordinator, address _link_token_contract) VRFConsumerBaseV2(_vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        LINKTOKEN = LinkTokenInterface(_link_token_contract);
        s_owner = msg.sender;
        //Create a new subscription when you deploy the contract.
        createNewSubscription();
    }

    // Assumes the subscription is funded sufficiently.
    function requestRandomWords() internal {
        // Will revert if subscription is not set and funded.
        s_requestId = COORDINATOR.requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
    }

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal virtual override {
        //s_randomWords = randomWords;
    }

    // Create a new subscription when the contract is initially deployed.
    function createNewSubscription() internal {
        s_subscriptionId = COORDINATOR.createSubscription();
        // Add this contract as a consumer of its own subscription.
        COORDINATOR.addConsumer(s_subscriptionId, address(this));
    }

    // Assumes this contract owns link.
    // 1000000000000000000 = 1 LINK
    function topUpSubscription(uint256 amount) internal {
        LINKTOKEN.transferAndCall(
            address(COORDINATOR),
            amount,
            abi.encode(s_subscriptionId)
        );
    }

    function addConsumer(address consumerAddress) internal {
        // Add a consumer contract to the subscription.
        COORDINATOR.addConsumer(s_subscriptionId, consumerAddress);
    }

    function removeConsumer(address consumerAddress) internal {
        // Remove a consumer contract from the subscription.
        COORDINATOR.removeConsumer(s_subscriptionId, consumerAddress);
    }

    function cancelSubscription(address receivingWallet) internal {
        // Cancel the subscription and send the remaining LINK to a wallet address.
        COORDINATOR.cancelSubscription(s_subscriptionId, receivingWallet);
        s_subscriptionId = 0;
    }

    // Transfer this contract's funds to an address.
    // 1000000000000000000 = 1 LINK
    function withdraw(uint256 amount, address to) internal {
        LINKTOKEN.transfer(to, amount);
    }

    function _setReqConfig(bytes32 _keyhash, uint32 _callbackGasLimit, uint16 _requestConfirmations, uint32 _numWords) internal {
        keyHash = _keyhash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        numWords = _numWords;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig() external view returns (uint16, uint32, bytes32[] memory);

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(
    uint64 subId
  ) external view returns (uint96 balance, uint64 reqCount, address owner, address[] memory consumers);

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);

  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 amount) external;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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