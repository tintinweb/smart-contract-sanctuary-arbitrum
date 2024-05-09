// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

//import "../libraries/PoolDataStructure.sol";
import "../interfaces/IPool.sol";

contract PoolStorage {
    //
    // data for this pool
    //

    // constant
    uint256 constant RATE_PRECISION = 1e6;                     // example rm lp fee rate 1000/1e6=0.001
    uint256 constant PRICE_PRECISION = 1e10;
    uint256 constant AMOUNT_PRECISION = 1e20;

    // contracts addresses used
    address vault;                                              // vault address
    address baseAsset;                                          // base token address
    address marketPriceFeed;                                    // price feed contract address
    uint256 baseAssetDecimals;                                  // base token decimals
    address interestLogic;                                      // interest logic address
    address WETH;                                               // WETH address 

    bool public addPaused = false;                              // flag for adding liquidity
    bool public removePaused = false;                           // flag for remove liquidity
    uint256 public minRemoveLiquidityAmount;                    // minimum amount (lp) for removing liquidity
    uint256 public minAddLiquidityAmount;                       // minimum amount (asset) for add liquidity
    uint256 public removeLiquidityFeeRate = 1000;               // fee ratio for removing liquidity
    uint256 public mm;                                          // maintenance margin ratio
    bool public clearAll;
    uint256 public minLeverage;
    uint256 public maxLeverage;
    uint256 public penaltyRate;

    int256 public balance;                                      // balance that is available to use of this pool
    int256 public balanceReal;
    uint256 public reserveRate;                                 // reserve ratio
    uint256 sharePrice;                                         // net value
    uint256 public cumulateRmLiqFee;                            // cumulative fee collected when removing liquidity
    uint256 public autoId;                                      // liquidity operations order id
    uint256 eventId;                                            // event count

    address[] marketList;                                       // supported markets array
    mapping(address => bool) public isMarket;                   // supported markets mapping
    mapping(address => MarketConfig) public marketConfigs;      // mapping of market configs
    mapping(address => DataByMarket) public poolDataByMarkets;  // mapping of market data
    mapping(int8 => IPool.InterestData) public interestData;    // mapping of interest data for position directions (long or short)
    mapping(uint256 => IPool.Position) public makerPositions;   // mapping of liquidity positions for addresses
    mapping(address => uint256) public makerPositionIds;        // mapping of liquidity positions for addresses

    //structs
    struct MarketConfig {
        uint256 marketType;
        uint256 fundUtRateLimit;                                // fund utilization ratio limit, 0: cant't open; example 200000  r = fundUtRateLimit/RATE_PRECISION=0.2
        uint256 openLimit;                                      // 0: 0 authorized credit limit; > 0 limit is min(openLimit, fundUtRateLimit * balance)
    }

    struct DataByMarket {
        int256 rlzPNL;                                          // realized profit and loss
        uint256 cumulativeFee;                                  // cumulative trade fee for pool
        uint256 longMakerFreeze;                                // user total long margin freeze, that is the pool short margin freeze
        uint256 shortMakerFreeze;                               // user total short margin freeze, that is pool long margin freeze
        uint256 takerTotalMargin;                               // all taker's margin
        int256 makerFundingPayment;                             // pending fundingPayment
        uint256 interestPayment;                                // interestPayment          
        uint256 longAmount;                                     // sum asset for long pos
        uint256 longOpenTotal;                                  // sum value  for long pos
        uint256 shortAmount;                                    // sum asset for short pos
        uint256 shortOpenTotal;                                 // sum value for short pos
    }

    struct PoolParams {
        uint256 _minAmount;
        uint256 _minLiquidity;
        address _market;
        uint256 _openRate;
        uint256 _openLimit;
        uint256 _reserveRate;
        uint256 _ratio;
        bool _add;
        bool _remove;
        address _interestLogic;
        address _marketPriceFeed;
        uint256 _mm;
        uint256 _minLeverage;
        uint256 _maxLeverage;
        uint256 _penaltyRate;
    }

    struct GlobalHf {
        uint256 sharePrice;
        uint256[] indexPrices;
        uint256 allMakerFreeze;
        DataByMarket allMarketPos;
        uint256 poolInterest;
        int256 totalUnPNL;
        uint256 poolTotalTmp;
    }

    event RegisterMarket(address market);
    event AddLiquidity(uint256 id, uint256 orderId, address maker, uint256 positionId, uint256 initMargin, uint256 liquidity, uint256 entryValue, uint256 sharePrice, uint256 totalValue);
    event RemoveLiquidity(uint256 id, uint256 orderId, address maker, uint256 positionId, uint256 rmMargin, uint256 rmLiquidity, uint256 rmValue, int256 pnl, int256 toMaker, uint256 sharePrice, uint256 rmFee, uint256 totalValue, uint256 actionType);
    event Liquidate(uint256 id, address maker,uint256 positionId, uint256 rmMargin, uint256 rmLiquidity, uint256 rmValue, int256 pnl, int256 toMaker,uint256 penalty, uint256 sharePrice, uint256 totalValue);
    event ActivatedClearAll(uint256 ts, uint256[] indexPrices);
    event AddMakerPositionMargin(uint256 id, uint256 positionId, uint256 addMargin);
    event ReStarted(address pool);
    event OpenUpdate(
        uint256 indexed id,
        address indexed market,
        address taker,
        address inviter,
        uint256 feeToExchange,
        uint256 feeToMaker,
        uint256 feeToInviter,
        uint256 sharePrice,
        uint256 shortValue,
        uint256 longValue
    );
    event CloseUpdate(
        uint256 indexed id,
        address indexed market,
        address taker,
        address inviter,
        uint256 feeToExchange,
        uint256 feeToMaker,
        uint256 feeToInviter,
        uint256 riskFunding,
        int256 rlzPnl,
        int256 fundingPayment,
        uint256 interestPayment,
        uint256 sharePrice,
        uint256 shortValue,
        uint256 longValue
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

interface IManager {
    function vault() external view returns (address);

    function riskFunding() external view returns (address);

    function checkSuperSigner(address _signer) external view returns (bool);

    function checkSigner(address signer, uint8 sType) external view returns (bool);

    function checkController(address _controller) view external returns (bool);

    function checkRouter(address _router) external view returns (bool);

    function checkExecutorRouter(address _executorRouter) external view returns (bool);

    function checkMarket(address _market) external view returns (bool);

    function checkPool(address _pool) external view returns (bool);

    function checkMarketLogic(address _logic) external view returns (bool);

    function checkMarketPriceFeed(address _feed) external view returns (bool);

    function cancelElapse() external view returns (uint256);

    function triggerOrderDuration() external view returns (uint256);

    function paused() external returns (bool);
    
    function getMakerByMarket(address maker) external view returns (address);

    function getMarketMarginAsset(address) external view returns (address);

    function isFundingPaused(address market) external view returns (bool);

    function isInterestPaused(address pool) external view returns (bool);

    function executeOrderFee() external view returns (uint256);

    function inviteManager() external view returns (address);

    function getAllMarkets() external view returns (address[] memory);

    function getAllPools() external view returns (address[] memory);

    function orderNumLimit() external view returns (uint256);

    function checkTreasurer(address _treasurer) external view returns (bool);

    function checkExecutor(address _executor, uint8 eType) external view returns (bool);
    
    function communityExecuteOrderDelay() external view returns (uint256);

    function modifySingleInterestStatus(address pool, bool _interestPaused) external;

    function modifySingleFundingStatus(address market, bool _fundingPaused) external;
    
    function router() external view returns (address);

    function executorRouter() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "../core/PoolStorage.sol";

interface IPool {
    struct InterestData {
        uint256 totalBorrowShare;
        uint256 lastInterestUpdateTs;
        uint256 borrowIG;
    }
    
    struct UpdateParams {
        uint256 orderId;
        uint256 makerMargin;//reduce maker margin，taker margin，amount，value
        uint256 takerMargin;
        uint256 amount;
        uint256 total;
        int256 makerProfit;
        uint256 makerFee;   //trade fee to maker
        int256 fundingPayment;//settled funding payment
        int8 takerDirection;//old position direction
        uint256 marginToVault;// reduce position size ,order margin should be to record in vault
        uint256 deltaDebtShare;//reduce position debt share
        uint256 payInterest;//settled interest payment
        bool isOutETH;//margin is ETH
        uint256 toRiskFund;
        uint256 toTaker;//balance of reduce position to taker
        address taker;//taker address
        uint256 feeToInviter; //trade fee to inviter
        address inviter;//inviter address
        uint256 feeToExchange;//fee to exchange
        bool isClearAll;
    }

    struct Position{
        address maker;
        uint256 initMargin;
        uint256 liquidity;
        uint256 entryValue;
        uint256 lastAddTime;
        uint256 makerStopLossPrice;
        uint256 makerProfitPrice;
    }
    
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function canOpen(address _market, uint256 _makerMargin) external view returns (bool);

    function getMakerOrderIds(address _maker) external view returns (uint256[] memory);

    function makerPositions(uint256 positionId) external view returns (Position memory);

    function openUpdate(UpdateParams memory params) external;

    function closeUpdate(UpdateParams memory params) external;

    function takerUpdateMargin(address _market, address, int256 _margin, bool isOutETH) external;

    function addLiquidity(uint256 orderId, address sender, uint256 amount, uint256 leverage) external returns(uint256 liquidity);

    function removeLiquidity(uint256 orderId, address sender, uint256 liquidity, bool isETH, bool isSystem) external returns (uint256 settleLiquidity);

    function liquidate(uint256 positionId) external ;

    function registerMarket(address _market) external returns (bool);

    function updateFundingPayment(address _market, int256 _fundingPayment) external;

    function getMarketAmount(address _market) external view returns (uint256, uint256, uint256);

    function getCurrentBorrowIG(int8 _direction) external view returns (uint256 _borrowRate, uint256 _borrowIG);

    function getCurrentAmount(int8 _direction, uint256 share) external view returns (uint256);

    function getCurrentShare(int8 _direction, uint256 amount) external view returns (uint256);

    function updateBorrowIG() external;

    function getBaseAsset() external view returns (address);

    function minRemoveLiquidityAmount() external view returns (uint256);

    function minAddLiquidityAmount() external view returns (uint256);

    function removeLiquidityFeeRate() external view returns (uint256);

    function reserveRate() external view returns (uint256);

    function addPaused() external view returns (bool);

    function removePaused() external view returns (bool);

    function clearAll() external view returns (bool);

    function makerPositionIds(address maker) external view returns (uint256);
    
    function mm()external view returns (uint256);
    
    function globalHf()external view returns (bool status, uint256 poolTotalTmp, int256 totalUnPNL);

    function addMakerPositionMargin(uint256 positionId, uint256 addMargin) external;

    function setTPSLPrice(address maker, uint256 positionId, uint256 tp, uint256 sl) external;
    
    function balance() external view returns (int256);
    
    function balanceReal() external view returns (int256);
    
    function getMarketList() external view returns (address[] memory);

    function poolDataByMarkets(address market) external view returns (int256, uint256, uint256, uint256, uint256, int256, uint256, uint256, uint256, uint256, uint256);
    
    function interestData(int8 direction) external view returns (IPool.InterestData memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;
import "../libraries/Tick.sol";

interface IPriceHelper {
    struct MarketTickConfig {
        bool isLinear;
        uint8 marketType;
        uint8 liquidationIndex;
        uint256 baseAssetDivisor;
        uint256 multiplier; // different precision from rate divisor
        uint256 maxLiquidity;
        Tick.Config[7] tickConfigs;
    }

    struct CalcTradeInfoParams {
        address pool;
        address market;
        uint256 indexPrice;
        bool isTakerLong;
        bool liquidation;
        uint256 deltaSize;
        uint256 deltaValue;
    }

    function calcTradeInfo(CalcTradeInfoParams memory params) external returns(uint256 deltaSize, uint256 volTotal, uint256 tradePrice);
    function onLiquidityChanged(address pool, address market, uint256 indexPrice) external;
    function modifyMarketTickConfig(address pool, address market, MarketTickConfig memory cfg, uint256 indexPrice) external;
    function getMarketPrice(address market, uint256 indexPrice) external view returns (uint256 marketPrice);
    function getFundingRateX96PerSecond(address market) external view returns(int256 fundingRateX96);

    event TickConfigChanged(address market, MarketTickConfig cfg);
    event TickInfoChanged(address market, uint8 index, uint256 size, uint256 premiumX96);
    event Slot0StateChanged(address market, uint256 netSize, uint256 premiumX96, bool isLong, uint8 currentTick);
    event LiquidationBufferSizeChanged(address market, uint8 index, uint256 bufferSize);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

library Constant {
    uint256 constant Q96 = 1 << 96;
    uint256 constant RATE_DIVISOR = 1e8;
    uint256 constant PRICE_DIVISOR = 1e10;// 1e10
    uint256 constant SIZE_DIVISOR = 1e20;// 1e20 for AMOUNT_PRECISION
    uint256 constant TICK_LENGTH = 7;
    uint256 constant MULTIPLIER_DIVISOR = 1e6;

    int256 constant FundingRate1_10000X96 = int256(Q96) * 1 / 10000;
    int256 constant FundingRate4_10000X96 = int256(Q96) * 4 / 10000;
    int256 constant FundingRate5_10000X96 = int256(Q96) * 5 / 10000;
    int256 constant FundingRate6_10000X96 = int256(Q96) * 6 / 10000;
    int256 constant FundingRateMaxX96 = int256(Q96) * 375 / 100000;
    int256 constant FundingRate8Hours = 8 hours;
    int256 constant FundingRate24Hours = 24 hours;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

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
        require(c >= a, "SafeMath: addition overflow");

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
        require(c / a == b, "SafeMath: multiplication overflow");

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
        return div(a, b, "SafeMath: division by zero");
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
     *
     * _Available since v2.4.0._
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
        return mod(a, b, "SafeMath: modulo by zero");
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import "./Tick.sol";
import "./SafeMath.sol";
import "./Constant.sol";

library SwapMath {
    using SafeMath for uint256;

    struct SwapStep {
        Tick.Info lower;
        Tick.Info current;
        Tick.Info upper;
    }

    function convertPrecision(uint256 val, uint256 from, uint256 to) internal pure returns(uint256 res) {
        if(from == to) {
            res = val;
        } else {
            res = val.mul(to).div(from);
        }
    }

    function validateSwapStep(SwapStep memory step) internal pure {
        require(step.lower.size <= step.current.size && step.lower.premiumX96 <= step.current.premiumX96, "tick error 1");
        require(step.current.size <= step.upper.size && step.current.premiumX96 <= step.upper.premiumX96, "tick error 2");
    }

    function calcTradePrice(uint256 indexPrice, uint256 premium1, uint256 premium2, bool slippageAdd) internal pure returns (uint256 tradePrice) {
        if(slippageAdd){
            tradePrice = indexPrice.mul((Constant.Q96 << 1).add(premium1).add(premium2)).div(Constant.Q96 << 1);
        } else {
            tradePrice = indexPrice.mul((Constant.Q96 << 1).sub(premium1).sub(premium2)).div(Constant.Q96 << 1);
        }
    }

    function sizeToVol(uint256 tradePrice, uint256 size, bool isLinear) internal pure returns(uint256 vol){
        if(size == 0) {
            vol = 0;
        } else {
            if(isLinear){
                vol = size.mul(tradePrice).div(Constant.PRICE_DIVISOR);
            } else {
                vol = size.mul(Constant.PRICE_DIVISOR).div(tradePrice);
            }
        }
    }

    function volToSize(uint256 tradePrice, uint256 vol, bool isLinear) internal pure returns(uint256 size) {
        if(vol == 0) {
            size = 0;
        } else {
            if(isLinear) {
                size = vol.mul(Constant.PRICE_DIVISOR).div(tradePrice);
            } else {
                size = vol.mul(tradePrice).div(Constant.PRICE_DIVISOR);
            }
        }
    }

    function avgTradePrice(uint256 size, uint256 vol, bool isLinear) internal pure returns(uint256 _avgTradePrice) {
        if(isLinear) {
            _avgTradePrice = vol.mul(Constant.PRICE_DIVISOR).div(size);
        } else {
            _avgTradePrice = size.mul(Constant.PRICE_DIVISOR).div(vol);
        }
    }

    function stepMaxLiquidity (uint256 indexPrice, SwapStep memory step, bool slippageAdd, bool premiumIncrease, bool isLinear) internal pure returns(uint256 sizeMax, uint256 volMax) {
        validateSwapStep(step);
        uint256 premiumX96End;
        if(premiumIncrease){
            sizeMax = step.upper.size.sub(step.current.size);
            premiumX96End = step.upper.premiumX96;
        } else {
            sizeMax = step.current.size.sub(step.lower.size);
            premiumX96End = step.lower.premiumX96;
        }
        uint256 tradePrice = calcTradePrice(indexPrice, step.current.premiumX96, premiumX96End, slippageAdd);
        volMax = sizeToVol(tradePrice, sizeMax, isLinear);
    }

    function estimateSwapSizeInTick(
        uint256  vol,
        uint256 indexPrice,
        SwapStep memory step,
        bool slippageAdd,
        bool premiumIncrease,
        bool isLinear
    ) internal pure returns(uint256 sizeRecommended)
    {
        validateSwapStep(step);
        uint256 estimateEndPremiumX96;
        uint256 estimatePricePrice;
        if(premiumIncrease){
            if(slippageAdd){
                estimateEndPremiumX96 = isLinear ? step.upper.premiumX96 : step.current.premiumX96;
            } else {
                estimateEndPremiumX96 = isLinear ? step.current.premiumX96 : step.upper.premiumX96;
            }
        } else {
            if(slippageAdd){
                estimateEndPremiumX96 = isLinear ? step.current.premiumX96 : step.lower.premiumX96;
            } else {
                estimateEndPremiumX96 = isLinear ? step.lower.premiumX96 : step.current.premiumX96;
            }
        }

        estimatePricePrice = calcTradePrice(indexPrice, step.current.premiumX96, estimateEndPremiumX96, slippageAdd);
        sizeRecommended = volToSize(estimatePricePrice, vol, isLinear);
        
    }

    function computeSwapStep(
        uint256 amountSpecified,
        uint256 indexPrice,
        SwapStep memory step,
        bool slippageAdd,
        bool premiumIncrease,
        bool isLinear,
        bool exactSize
    ) internal view returns (bool crossTick, uint256 tradeSize, uint256 tradeVol, Tick.Info memory endTick)
    {
        validateSwapStep(step);

        (uint256 sizeMax, uint256 volMax) = stepMaxLiquidity(indexPrice, step, slippageAdd, premiumIncrease, isLinear);
        if(premiumIncrease){
            endTick.size = step.upper.size;
            endTick.premiumX96 = step.upper.premiumX96;
        } else {
            endTick.size = step.lower.size;
            endTick.premiumX96 = step.lower.premiumX96;
        }

        uint256 premiumX96End;

        crossTick = exactSize ? (amountSpecified >= sizeMax) : (amountSpecified >= volMax);

        if(crossTick){
            tradeSize = sizeMax;
            tradeVol = volMax;
        } else {
            if(exactSize) {
                tradeSize = amountSpecified;
                premiumX96End = calcInMiddlePremiumX96(step, tradeSize, premiumIncrease);
                endTick.premiumX96 = premiumX96End;
                endTick.size = premiumIncrease ? step.current.size.add(tradeSize) : step.current.size.sub(tradeSize);
                uint256 tradePrice = calcTradePrice(indexPrice, step.current.premiumX96, premiumX96End, slippageAdd);
                tradeVol = sizeToVol(tradePrice, tradeSize, isLinear);
            } else {
                uint256 sizeRecommended = estimateSwapSizeInTick(amountSpecified, indexPrice, step, slippageAdd, premiumIncrease, isLinear);
                return computeSwapStep(sizeRecommended, indexPrice, step, slippageAdd, premiumIncrease, isLinear, true);
            }
        }
    }

    function calcInMiddlePremiumX96(SwapStep memory step, uint256 size, bool premiumIncrease) internal pure returns(uint256 premiumX96End) {
        uint256 sizeDelta;
        uint256 premiumX96Delta;
        uint256 premiumX96Impact;
        if(step.lower.size == step.upper.size){
            require(step.lower.premiumX96 == step.upper.premiumX96,"tick error =");
            return step.upper.premiumX96;
        }
        premiumX96Delta = step.upper.premiumX96.sub(step.lower.premiumX96);
        sizeDelta = step.upper.size.sub(step.lower.size);

        premiumX96Impact = size.mul(premiumX96Delta); // SafeMath.mul(size, premiumX96Delta);
        premiumX96Impact = premiumX96Impact.div(sizeDelta); // SafeMath.div(premiumX96Impact, sizeDelta);

        if(premiumIncrease){
            return step.current.premiumX96.add(premiumX96Impact);
        } else {
            return step.current.premiumX96.sub(premiumX96Impact);
        }
    }

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;
import "./Constant.sol";
import "./SafeMath.sol";

library Tick {
    using SafeMath for uint256;

    struct Info {
        uint256 size;
        uint256 premiumX96;
    }

    struct Config {
        uint32 sizeRate;
        uint32 premium;
    }

    function calcTickInfo(uint32 sizeRate, uint32 premium, bool isLinear, uint256 liquidity, uint256 indexPrice) internal pure returns (uint256 size, uint256 premiumX96){
        if(isLinear) {
            size = liquidity.mul(sizeRate).div(Constant.RATE_DIVISOR);
            size = size.mul(Constant.PRICE_DIVISOR).div(indexPrice);
        } else {
            size = liquidity.mul(sizeRate).div(Constant.RATE_DIVISOR);
            size = size.mul(indexPrice).div(Constant.PRICE_DIVISOR);
        }

        premiumX96 = uint256(premium).mul(Constant.Q96).div(Constant.RATE_DIVISOR);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import "../libraries/SafeMath.sol";
import "../libraries/Tick.sol";
import "../libraries/Constant.sol";
import "../libraries/SwapMath.sol";
import "../interfaces/IPriceHelper.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IManager.sol";

contract PriceHelper is IPriceHelper {
    using SafeMath for uint256;

    uint8 constant TICK_LENGTH = 7;
    uint8 constant MAX_TICK = TICK_LENGTH - 1;
    
    struct MarketSlot0 {
        uint256 netSize;
        uint256 premiumX96;
        uint256 totalBufferSize;
        bool isLong;
        bool initialized;
        uint8 currentTick;
        uint8 pendingTick;
        uint8 liquidationIndex;
        Tick.Info[TICK_LENGTH] ticks;
        uint256[TICK_LENGTH] liquidationBufferSize;
    }

    address public manager;
    mapping(address => MarketSlot0) public marketSlot0;
    mapping(address => MarketTickConfig) public marketConfig;

    constructor(address _manager) {
        manager = _manager;
    }

    modifier onlyMarketPriceFeed() {
        require(IManager(manager).checkMarketPriceFeed(msg.sender), "only manager");
        _;
    }

    function onMarketConfigModified(address market, uint256 liquidity, uint256 indexPrice) internal {
        _modifyHigherTickInfo(market, liquidity, indexPrice);
    }

    function _validateMarketTickConfig(MarketTickConfig memory cfg) internal pure{
        require(cfg.tickConfigs.length == TICK_LENGTH && cfg.liquidationIndex < TICK_LENGTH,"error tick config length");
        require(cfg.tickConfigs[0].sizeRate == 0 && cfg.tickConfigs[0].premium == 0, "error tick config 0");
        require(
            cfg.tickConfigs[MAX_TICK].sizeRate <= Constant.RATE_DIVISOR &&
            cfg.tickConfigs[MAX_TICK].premium <= Constant.RATE_DIVISOR,
            "error tick config max value"
        );

        uint8 i;
        for(i = 1; i < TICK_LENGTH; i ++){
            Tick.Config memory previous = cfg.tickConfigs[i-1];
            Tick.Config memory next = cfg.tickConfigs[i];
            require(previous.sizeRate <= next.sizeRate && previous.premium <= next.premium,"error tick config");
        }
    }

    function modifyMarketTickConfig(address pool, address market, MarketTickConfig memory cfg, uint256 indexPrice) public override onlyMarketPriceFeed {
        _validateMarketTickConfig(cfg);
        uint8 i = 0;

        MarketTickConfig storage _config = marketConfig[market];
        MarketSlot0 storage slot0 = marketSlot0[market];

        if (slot0.initialized) {
            require(_config.baseAssetDivisor == cfg.baseAssetDivisor, "base asset divisor can not be changed");
            require(_config.multiplier == cfg.multiplier, "multiplier can not be changed");
            require(_config.marketType == cfg.marketType, "market type can not be changed");
        } else {
            _config.marketType = cfg.marketType;
            _config.isLinear = _config.marketType == 1 ? false : true;
            _config.baseAssetDivisor = cfg.baseAssetDivisor;
            _config.multiplier = cfg.multiplier;
            slot0.initialized = true;
        }

        for (i = 0; i < TICK_LENGTH; i ++) {
            _config.tickConfigs[i] = cfg.tickConfigs[i];
        }

        _config.liquidationIndex = cfg.liquidationIndex;
        slot0.liquidationIndex = cfg.liquidationIndex;
        _config.maxLiquidity = cfg.maxLiquidity;
        
        uint256 liquidity = _getMarketLiquidity(pool, market);

        onMarketConfigModified(market, liquidity, indexPrice);
        emit TickConfigChanged(market, cfg);
    }

    function _modifyTicksRange(address market, uint256 liquidity, uint8 startIndex, uint8 endIndex, uint256 indexPrice) internal {
        if (endIndex < MAX_TICK) {
            Tick.Info memory endTick = marketSlot0[market].ticks[endIndex];
            Tick.Info memory nextTick = marketSlot0[market].ticks[endIndex + 1];
            if (endTick.size >= nextTick.size || endTick.premiumX96 >= nextTick.premiumX96) {
                endIndex = MAX_TICK;
            }
        }
        _modifyTicksInfo(market, liquidity, startIndex, endIndex, indexPrice);
    }

    function _modifyHigherTickInfo(address market, uint256 liquidity, uint256 indexPrice) internal {
        uint8 start = marketSlot0[market].currentTick;
        marketSlot0[market].pendingTick = start;
        _modifyTicksInfo(market, liquidity, start, MAX_TICK, indexPrice);
    }

    function _modifyTicksInfo(address market, uint256 liquidity, uint8 startIndex, uint8 endIndex, uint256 indexPrice) internal {
        bool isLiner = marketConfig[market].isLinear;
        for (uint8 i = startIndex + 1; i <= endIndex; i++) {
            uint32 sizeRate = marketConfig[market].tickConfigs[i].sizeRate;
            uint32 premium = marketConfig[market].tickConfigs[i].premium;
            (uint256 sizeAfter, uint256 premiumX96After) = Tick.calcTickInfo(sizeRate, premium, isLiner, liquidity, indexPrice);

            if (i > 1) {
                Tick.Info memory previous = marketSlot0[market].ticks[i - 1];
                if (previous.size >= sizeAfter || previous.premiumX96 >= premiumX96After) {
                    (sizeAfter, premiumX96After) = (previous.size, previous.premiumX96);
                }
            }

            marketSlot0[market].ticks[i].size = sizeAfter;
            marketSlot0[market].ticks[i].premiumX96 = premiumX96After;
            emit TickInfoChanged(market, i, sizeAfter, premiumX96After);

            if (i == endIndex && endIndex < MAX_TICK) {
                Tick.Info memory next = marketSlot0[market].ticks[i + 1];
                if (sizeAfter >= next.size || premiumX96After >= next.premiumX96) {
                    endIndex = MAX_TICK;
                }
            }
        }
    }

    /// @notice trade related functions
    struct TradeVars {
        bool isTakerLong;
        bool premiumIncrease;
        bool slippageAdd;
        bool liquidation;
        bool isLinear;
        bool exactSize;
    }

    function _validateTradeParas(CalcTradeInfoParams memory params) internal view{
        require(params.deltaSize > 0 || params.deltaValue > 0, "invalid size and value");
        require(params.indexPrice > 0, "invalid index price");
        require(marketSlot0[params.market].initialized, "market price helper not initialized");
    }

    /// @notice calculate trade info
    /// @param params trade parameters
    /// @return tradeSize trade size
    /// @return tradeVol trade volume
    /// @return tradePrice trade price
    function calcTradeInfo(CalcTradeInfoParams memory params) public override onlyMarketPriceFeed returns (uint256 tradeSize, uint256 tradeVol, uint256 tradePrice) {
        MarketSlot0 storage slot0 = marketSlot0[params.market];
        TradeVars memory vars;
        uint256 amountSpecified;

        vars.isTakerLong = params.isTakerLong;
        if (params.deltaSize > 0) {
            amountSpecified = params.deltaSize;
            vars.exactSize = true;
        } else {
            amountSpecified = params.deltaValue;
            vars.exactSize = false;
        }

        if (params.liquidation) {
            require(vars.exactSize, "liquidation trade should be exact size");
        }

        if (slot0.netSize == 0) {
            vars.premiumIncrease = true;
            slot0.isLong = !params.isTakerLong;
        } else {
            vars.premiumIncrease = (params.isTakerLong != slot0.isLong);
        }

        vars.slippageAdd = !slot0.isLong;
        vars.isLinear = marketConfig[params.market].isLinear;
        vars.liquidation = params.liquidation;
        

        (tradeSize, tradeVol) = _calcTradeInfoOneSide(
            params.market,
            slot0,
            params.indexPrice,
            amountSpecified,
            vars
        );
        
        if (vars.exactSize) {
            amountSpecified = amountSpecified.sub(tradeSize);
        } else {
            amountSpecified = amountSpecified.sub(tradeVol);
        }

        if (vars.premiumIncrease) {
            slot0.isLong = !params.isTakerLong;
            if (vars.exactSize) {
                require(amountSpecified == 0, "out of liquidity");
            }
        } else {
            if (slot0.pendingTick > slot0.currentTick) {
                uint256 liquidity = _getMarketLiquidity(params.pool, params.market);
                _modifyTicksRange(params.market, liquidity, slot0.currentTick, slot0.pendingTick, params.indexPrice);
                slot0.pendingTick = slot0.currentTick;
            }

            if (slot0.netSize > 0) {
                // should finish the trade
                if (vars.exactSize) {
                    require(amountSpecified == 0, "exact size decrease premium error");
                }
            } else {
                if (amountSpecified > 0) {
                    slot0.isLong = !slot0.isLong;
                    vars.premiumIncrease = true;
                    vars.slippageAdd = !vars.slippageAdd;
                    (uint256 tradeSizePart2, uint256 tradeVolPart2) = _calcTradeInfoOneSide(
                        params.market,
                        slot0,
                        params.indexPrice,
                        amountSpecified,
                        vars
                    );
                    tradeSize = tradeSize.add(tradeSizePart2);
                    tradeVol = tradeVol.add(tradeVolPart2);
                }
            }
        }

        if (tradeSize > 0 && tradeVol > 0) {
            tradePrice = SwapMath.avgTradePrice(tradeSize, tradeVol, vars.isLinear);
        } else {
            tradePrice = _calcMarketPrice(params.indexPrice, slot0.premiumX96, vars.slippageAdd);
        }
        
        emit Slot0StateChanged(params.market, slot0.netSize, slot0.premiumX96, slot0.isLong, slot0.currentTick);
    }


    struct CalcTradeInfoOneSideVars {
        uint8 maxTick;
        uint256 sizeUsed;
        uint256 volUsed;
        uint256 tradePrice;
        bool crossTick;
    }

    function _calcTradeInfoOneSide(
        address market,
        MarketSlot0 storage slot0,
        uint256 indexPrice,
        uint256 amountSpecified,
        TradeVars memory vars
    ) internal returns (uint256 tradeSize, uint256 tradeVol) {

        if (slot0.currentTick == 0) {
            slot0.currentTick = 1;
        }

        uint8 index;
        CalcTradeInfoOneSideVars memory tmp;
        SwapMath.SwapStep memory step = SwapMath.SwapStep({
            current: Tick.Info(0, 0),
            lower: Tick.Info(0, 0),
            upper: Tick.Info(0, 0)
        });

        index = slot0.currentTick;
        tmp.maxTick = TICK_LENGTH;

        if (vars.liquidation && vars.premiumIncrease) {
            tmp.maxTick = slot0.liquidationIndex + 1;
        }

        while (amountSpecified > 0 && index > 0 && index < tmp.maxTick) {
            Tick.Info memory endTick;
            step.lower = slot0.ticks[index - 1];
            step.upper = slot0.ticks[index];

            step.current.size = slot0.netSize;
            step.current.premiumX96 = slot0.premiumX96;

            if (!vars.premiumIncrease) {
                // premium goes to lower tick, user liquidation buffer size first
                uint256 bufferedSize = slot0.liquidationBufferSize[index];
                if (bufferedSize > 0) {
                    tmp.tradePrice = _calcMarketPrice(indexPrice, step.current.premiumX96, vars.slippageAdd);

                    if (vars.exactSize) {
                        tmp.sizeUsed = amountSpecified < bufferedSize ? amountSpecified : bufferedSize;
                        tmp.volUsed = SwapMath.sizeToVol(tmp.tradePrice, tmp.sizeUsed, vars.isLinear);
                        amountSpecified = amountSpecified.sub(tmp.sizeUsed);
                    } else {
                        uint256 maxBufferedVol = SwapMath.sizeToVol(tmp.tradePrice, bufferedSize, vars.isLinear);
                        tmp.volUsed = amountSpecified < maxBufferedVol ? amountSpecified : maxBufferedVol;
                        tmp.sizeUsed = SwapMath.volToSize(tmp.tradePrice, tmp.volUsed, vars.isLinear);
                        amountSpecified = amountSpecified.sub(tmp.volUsed);
                    }
                    tradeSize = tradeSize.add(tmp.sizeUsed);
                    tradeVol = tradeVol.add(tmp.volUsed);

                    bufferedSize = bufferedSize.sub(tmp.sizeUsed);
                    slot0.liquidationBufferSize[index] = bufferedSize;
                    slot0.totalBufferSize = slot0.totalBufferSize.sub(tmp.sizeUsed);
                    emit LiquidationBufferSizeChanged(market, index, bufferedSize);
                }
            }

            if (amountSpecified == 0) {
                break;
            }

            (tmp.crossTick, tmp.sizeUsed, tmp.volUsed, endTick) = SwapMath.computeSwapStep(
                amountSpecified,
                indexPrice,
                step,
                vars.slippageAdd,
                vars.premiumIncrease,
                vars.isLinear,
                vars.exactSize
            );

            vars.premiumIncrease ? index ++ : index --;
            tradeSize = tradeSize.add(tmp.sizeUsed);
            tradeVol = tradeVol.add(tmp.volUsed);
            slot0.netSize = endTick.size;
            slot0.premiumX96 = endTick.premiumX96;

            if (vars.exactSize) {
                amountSpecified = amountSpecified.sub(tmp.sizeUsed);
            } else {
                amountSpecified = amountSpecified.sub(tmp.volUsed);
            }

            if (tmp.crossTick && index < TICK_LENGTH) {
                slot0.currentTick = index;
            }

            if (amountSpecified == 0) {
                break;
            }

            // when exactSize == false, the final trade vol is not equal to requested amountSpecified
            // and if !crossTick the trade must be finished.
            if (!tmp.crossTick) {
                require(!vars.exactSize, "trade info calc error");
                break;
            }
        }

        // vars.liquidation = true indicates vars.exactSize = true;
        if (vars.liquidation && vars.premiumIncrease && amountSpecified > 0) {
            require(vars.exactSize, "liquidation should be exact size");
            tmp.tradePrice = _calcMarketPrice(indexPrice, slot0.premiumX96, vars.slippageAdd);
            tmp.volUsed = SwapMath.sizeToVol(tmp.tradePrice, amountSpecified, vars.isLinear);

            slot0.totalBufferSize = slot0.totalBufferSize.add(amountSpecified);
            slot0.liquidationBufferSize[slot0.liquidationIndex] = slot0.liquidationBufferSize[slot0.liquidationIndex].add(amountSpecified);

            tradeSize = tradeSize.add(amountSpecified);
            tradeVol = tradeVol.add(tmp.volUsed);
            amountSpecified = 0;
            emit LiquidationBufferSizeChanged(market, slot0.liquidationIndex, slot0.liquidationBufferSize[slot0.liquidationIndex]);
        }
    }

    /// @notice modify market liquidity
    /// @param pool pool address
    /// @param market market address
    /// @param indexPrice index price
    function onLiquidityChanged(address pool, address market, uint256 indexPrice) external override onlyMarketPriceFeed {
        uint256 liquidity = _getMarketLiquidity(pool, market);
        _modifyHigherTickInfo(market, liquidity, indexPrice);
    }

    function _calcMarketPrice(uint256 indexPrice, uint256 premiumX96, bool slippageAdd) internal pure returns (uint256 marketPrice) {
        if (slippageAdd) {
            marketPrice = indexPrice.mul(Constant.Q96.add(premiumX96)).div(Constant.Q96);
        } else {
            marketPrice = indexPrice.mul(Constant.Q96.sub(premiumX96)).div(Constant.Q96);
        }
        require(marketPrice > 0, "market price 0");
    }

    function _getMarketLiquidity(address pool, address market) internal view returns (uint256 liquidity) {
        (,, liquidity) = IPool(pool).getMarketAmount(market);// baseAssetPrecision ---> AMOUNT_PRECISION
        MarketTickConfig memory cfg = marketConfig[market];
        if(liquidity > cfg.maxLiquidity) {
            liquidity = cfg.maxLiquidity;
        }
        liquidity = SwapMath.convertPrecision(liquidity, marketConfig[market].baseAssetDivisor, Constant.SIZE_DIVISOR);
        if(cfg.marketType == 2) {
            liquidity = liquidity.mul(Constant.MULTIPLIER_DIVISOR).div(cfg.multiplier);
        }
    }
    
    function getMarketPrice(address market, uint256 indexPrice) external view override returns (uint256 marketPrice) {
        marketPrice = _calcMarketPrice(indexPrice, marketSlot0[market].premiumX96, !marketSlot0[market].isLong);
    }

    function _getMarketConfigByIndex(address market, uint8 index) internal view returns (uint32, uint32){
        Tick.Config memory cfg = marketConfig[market].tickConfigs[index];
        return (cfg.sizeRate, cfg.premium);
    }

    function getPremiumInfoByMarket(address market) external view returns (MarketSlot0 memory slot0, MarketTickConfig memory tickConfig){
        slot0 = marketSlot0[market];
        tickConfig = marketConfig[market];
    }

    function getFundingRateX96PerSecond(address market) external view override returns (int256 fundingRateX96) {
        MarketSlot0 memory slot0 = marketSlot0[market];
        require(slot0.initialized, "market premium is not initialized");

        int256 premiumX96 = int256(slot0.premiumX96);

        if (slot0.isLong) {
            // premium <  0
            if (premiumX96 > Constant.FundingRate4_10000X96) {
                fundingRateX96 = Constant.FundingRate5_10000X96 - premiumX96;
            } else {
                fundingRateX96 = Constant.FundingRate1_10000X96;
            }
        } else {
            if (premiumX96 < Constant.FundingRate6_10000X96) {
                fundingRateX96 = Constant.FundingRate1_10000X96;
            } else {
                fundingRateX96 = premiumX96 - Constant.FundingRate5_10000X96;
            }
        }

        if (fundingRateX96 < (- Constant.FundingRateMaxX96)) {
            fundingRateX96 = - Constant.FundingRateMaxX96;
        }

        if (fundingRateX96 > Constant.FundingRateMaxX96) {
            fundingRateX96 = Constant.FundingRateMaxX96;
        }
        fundingRateX96 = fundingRateX96 / Constant.FundingRate8Hours;
    }

    function getConstantValues() public pure returns (int256, int256, int256, int256, int256, int256, int256){
        return (
            Constant.FundingRate4_10000X96,
            Constant.FundingRate6_10000X96,
            Constant.FundingRate5_10000X96,
            Constant.FundingRate1_10000X96,
            Constant.FundingRateMaxX96,
            Constant.FundingRate8Hours,
            Constant.FundingRate1_10000X96 / Constant.FundingRate8Hours
        );
    }
}