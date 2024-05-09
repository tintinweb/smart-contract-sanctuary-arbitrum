// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

import "../libraries/SafeMath.sol";
import "../interfaces/IManager.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ITradeToken.sol";
import "../interfaces/IMarket.sol";

contract InviteManager {
    using SafeMath for uint256;
    address public manager;                                 //Manager address

    uint256 public constant RATE_PRECISION = 1e6;
    uint256 public constant AMOUNT_PRECISION = 1e20;               // amount decimal 1e20

    struct Tier {
        uint256 totalRebate;                                // e.g. 2400 for 24%
        uint256 discountShare;                              // 5000 for 50%/50%, 7000 for 30% rebates/70% discount
        uint256 upgradeTradeAmount;                         //upgrade trade amount
    }

    mapping(uint256 => Tier) public tiers;                  //level => Tier

    struct ReferralCode {
        address owner;
        uint256 registerTs;
        uint256 tierId;
    }

    mapping(bytes32 => ReferralCode) public codeOwners;     //referralCode => owner
    mapping(address => bytes32) public traderReferralCodes; //account => referralCode

    address public upgradeToken;
    address public tradeToken;
    address public inviteToken;
    uint256 public tradeTokenDecimals;
    uint256 public inviteTokenDecimals;
    bool public isUTPPaused = true;
    bool public isURPPaused = true;
    mapping(address => uint256) public tradeTokenBalance;
    mapping(address => uint256) public inviteTokenBalance;

    event SetTraderReferralCode(address account, bytes32 code);
    event RegisterCode(address account, bytes32 code, uint256 time);
    event SetCodeOwner(address account, address newAccount, bytes32 code);
    event SetTier(uint256 tierId, uint256 totalRebate, uint256 discountShare, uint256 upgradeTradeAmount);
    event SetReferrerTier(bytes32 code, uint256 tierId);
    event ClaimInviteToken(address account, uint256 amount);
    event ClaimTradeToken(address account, uint256 amount);
    event AddTradeTokenBalance(address account, uint256 amount);
    event AddInviteTokenBalance(address account, uint256 amount);
    event SetUpgradeToken(address token);
    event SetTradeToken(address tradeToken, uint256 decimals);
    event SetInviteToken(address inviteToken, uint256 decimals);
    event UpdateTradeValue(address account, uint256 value);
    event IsUTPPausedSettled(bool isUTPPaused);
    event IsURPPausedSettled(bool isURPPaused);

    constructor(address _manager) {
        require(_manager != address(0), "InviteManager: manager is zero address");
        manager = _manager;
    }

    modifier onlyController() {
        require(IManager(manager).checkController(msg.sender), "InviteManager: Must be controller");
        _;
    }

    modifier onlyRouter() {
        require(IManager(manager).checkRouter(msg.sender), "InviteManager: Must be router");
        _;
    }

    modifier onlyMarket(){
        require(IManager(manager).checkMarket(msg.sender), "InviteManager: no permission!");
        _;
    }

    modifier onlyPool(){
        require(IManager(manager).checkPool(msg.sender), "InviteManager: Must be pool!");
        _;
    }

    function setIsUTPPaused(bool _isUTPPaused) external onlyController {
        isUTPPaused = _isUTPPaused;
        emit IsUTPPausedSettled(_isUTPPaused);
    }

    function setIsURPPaused(bool _isURPPaused) external onlyController {
        isURPPaused = _isURPPaused;
        emit IsURPPausedSettled(_isURPPaused);
    }

    function setUpgradeToken(address _token) external onlyController {
        require(_token != address(0), "InviteManager: upgradeToken is zero address");
        upgradeToken = _token;
        emit SetUpgradeToken(_token);
    }

    function setTradeToken(address _tradeToken) external onlyController {
        require(_tradeToken != address(0), "InviteManager: tradeToken is zero address");
        tradeToken = _tradeToken;
        tradeTokenDecimals = IERC20(_tradeToken).decimals();
        emit SetTradeToken(_tradeToken, tradeTokenDecimals);
    }

    function setInviteToken(address _inviteToken) external onlyController {
        require(_inviteToken != address(0), "InviteManager: inviteToken is zero address");
        inviteToken = _inviteToken;
        inviteTokenDecimals = IERC20(_inviteToken).decimals();
        emit SetInviteToken(_inviteToken, inviteTokenDecimals);
    }

    function setTier(uint256 _tierId, uint256 _totalRebate, uint256 _discountShare, uint256 _upgradeTradeAmount) external onlyController {
        require(_totalRebate <= RATE_PRECISION, "InviteManager: invalid totalRebate");
        require(_discountShare <= RATE_PRECISION, "InviteManager: invalid discountShare");

        Tier memory tier = tiers[_tierId];
        tier.totalRebate = _totalRebate;
        tier.discountShare = _discountShare;
        tier.upgradeTradeAmount = _upgradeTradeAmount;
        tiers[_tierId] = tier;
        emit SetTier(_tierId, _totalRebate, _discountShare, _upgradeTradeAmount);
    }

    function setReferrerTier(bytes32 _code, uint256 _tierId) external onlyController {
        codeOwners[_code].tierId = _tierId;
        emit SetReferrerTier(_code, _tierId);
    }

    function upgradeReferrerTierByOwner(bytes32 _code) external {
        require(codeOwners[_code].owner == msg.sender, "InviteManager: invalid owner");
        require(IERC20(upgradeToken).balanceOf(msg.sender) >= tiers[codeOwners[_code].tierId].upgradeTradeAmount, "InviteManager: insufficient balance");

        IERC20(upgradeToken).transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), tiers[codeOwners[_code].tierId].upgradeTradeAmount);

        uint256 _tierId = codeOwners[_code].tierId.add(1);
        require(tiers[_tierId].totalRebate > 0, "InviteManager: invalid tierId");

        codeOwners[_code].tierId = _tierId;
        emit SetReferrerTier(_code, _tierId);
    }


    /// @notice set trader referral code, only router can call
    /// @param _account account address
    /// @param _code referral code
    function setTraderReferralCode(address _account, bytes32 _code) external onlyRouter {
        if (_code != bytes32(0) && traderReferralCodes[_account] != _code && codeOwners[_code].owner != _account) {
            traderReferralCodes[_account] = _code;
            emit SetTraderReferralCode(_account, _code);
        }
    }

    /// @notice set trader referral code, user can call
    /// @param _code referral code
    function setTraderReferralCodeByUser(bytes32 _code) external {
        require(_code != bytes32(0) && traderReferralCodes[msg.sender] != _code && codeOwners[_code].owner != msg.sender, "InviteManager: invalid _code");
        traderReferralCodes[msg.sender] = _code;
        emit SetTraderReferralCode(msg.sender, _code);

    }

    /// @notice register referral code
    /// @param _code referral code
    function registerCode(bytes32 _code) external {
        require(_code != bytes32(0), "InviteManager: invalid _code");
        require(codeOwners[_code].owner == address(0), "InviteManager: code already exists");

        codeOwners[_code].owner = msg.sender;
        codeOwners[_code].registerTs = block.timestamp;
        codeOwners[_code].tierId = 0;
        emit RegisterCode(msg.sender, _code, codeOwners[_code].registerTs);
    }

    /// @notice set code owner, only owner can call
    /// @param _code referral code
    /// @param _newAccount new account address
    function setCodeOwnerBySystem(bytes32 _code, address _newAccount) external onlyController {
        require(_code != bytes32(0), "InviteManager: invalid _code");
        codeOwners[_code].owner = _newAccount;
        emit SetCodeOwner(msg.sender, _newAccount, _code);
    }

    /// @notice get referral info
    /// @param _codes referral code[]
    function getCodeOwners(bytes32[] memory _codes) public view returns (address[] memory) {
        address[] memory owners = new address[](_codes.length);

        for (uint256 i = 0; i < _codes.length; i++) {
            bytes32 code = _codes[i];
            owners[i] = codeOwners[code].owner;
        }

        return owners;
    }

    function getReferrerCodeByTaker(address _taker) public view returns (bytes32 _code, address _codeOwner, uint256 _takerDiscountRate, uint256 _inviteRate) {
        _code = traderReferralCodes[_taker];
        _codeOwner = codeOwners[_code].owner;
        if (_codeOwner == address(0)) {
            return (_code, address(0), 0, 0);
        }
        _takerDiscountRate = tiers[codeOwners[_code].tierId].discountShare;
        _inviteRate = tiers[codeOwners[_code].tierId].totalRebate;
    }

    function addTradeTokenBalance(address _account, uint256 _amount) internal {
        tradeTokenBalance[_account] = tradeTokenBalance[_account].add(_amount);
        emit AddTradeTokenBalance(_account, _amount);
    }

    function addInviteTokenBalance(address _account, uint256 _amount) internal {
        inviteTokenBalance[_account] = inviteTokenBalance[_account].add(_amount);
        emit AddInviteTokenBalance(_account, _amount);
    }

    function claimInviteToken(address _account) external {
        uint256 amount = inviteTokenBalance[_account];
        require(amount > 0, "InviteManager: no invite token to claim");
        inviteTokenBalance[_account] = 0;
        ITradeToken(inviteToken).mint(_account, amount);
        emit ClaimInviteToken(_account, amount);
    }

    function claimTradeToken(address _account) external {
        uint256 amount = tradeTokenBalance[_account];
        require(amount > 0, "InviteManager: no trade token to claim");
        tradeTokenBalance[_account] = 0;
        ITradeToken(tradeToken).mint(_account, amount);
        emit ClaimTradeToken(_account, amount);
    }

    function updateTradeValue(uint8 _marketType, address _taker, address _inviter, uint256 _tradeValue) external onlyMarket {
        if (_marketType == 0 || _marketType == 1) {
            if (_inviter != address(0) && !isURPPaused) addInviteTokenBalance(_inviter, _tradeValue.mul(10 ** inviteTokenDecimals).div(AMOUNT_PRECISION));
            if (!isUTPPaused) addTradeTokenBalance(_taker, _tradeValue.mul(10 ** tradeTokenDecimals).div(AMOUNT_PRECISION));
            emit UpdateTradeValue(_taker, _tradeValue);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

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

import "../libraries/MarketDataStructure.sol";

interface IMarket {
    function setMarketConfig(MarketDataStructure.MarketConfig memory _config) external;

    function updateFundingGrowthGlobal() external;

    function getMarketConfig() external view returns (MarketDataStructure.MarketConfig memory);

    function marketType() external view returns (uint8);

    function positionModes(address) external view returns (MarketDataStructure.PositionMode);

    function fundingGrowthGlobalX96() external view returns (int256);

    function lastFrX96Ts() external view returns (uint256);

    function takerOrderTotalValues(address, int8) external view returns (int256);

    function pool() external view returns (address);

    function getPositionId(address _trader, int8 _direction) external view returns (uint256);

    function getPosition(uint256 _id) external view returns (MarketDataStructure.Position memory);

    function getOrderIds(address _trader) external view returns (uint256[] memory);

    function getOrder(uint256 _id) external view returns (MarketDataStructure.Order memory);

    function createOrder(MarketDataStructure.CreateInternalParams memory params) external returns (uint256 id);

    function cancel(uint256 _id) external;

    function executeOrder(uint256 _id) external returns (int256, uint256, bool);

    function updateMargin(uint256 _id, uint256 _updateMargin, bool isIncrease) external;

    function liquidate(uint256 _id, MarketDataStructure.OrderType action, uint256 clearPrice) external returns (uint256);

    function setTPSLPrice(uint256 _id, uint256 _profitPrice, uint256 _stopLossPrice, bool isExecutedByIndexPrice) external;

    function takerOrderNum(address, MarketDataStructure.OrderType) external view returns (uint256);

    function getLogicAddress() external view returns (address);

    function initialize(string memory _indexToken, address _clearAnchor, address _pool, uint8 _marketType) external;

    function switchPositionMode(address _taker, MarketDataStructure.PositionMode _mode) external;

    function orderID() external view returns (uint256);
    
    function triggerOrderID() external view returns (uint256);

    function marketLogic() external view returns (address);

    function token() external view returns (string memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;

interface ITradeToken {
    function mint(address _account, uint256 _amount) external;
    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

/// @notice data structure used by Pool

library MarketDataStructure {
    /// @notice enumerate of user trade order status
    enum OrderStatus {
        Open,
        Opened,
        OpenFail,
        Canceled
    }

    /// @notice enumerate of user trade order types
    enum OrderType{
        Open,
        Close,
        TriggerOpen,
        TriggerClose,
        Liquidate,
        TakeProfit,
        UserTakeProfit,
        UserStopLoss,
        ClearAll
    }

    /// @notice position mode, one-way or hedge
    enum PositionMode{
        Hedge,
        OneWay
    }

    enum PositionKey{
        Short,
        Long,
        OneWay
    }

    /// @notice Position data structure
    struct Position {
        uint256 id;                 // position id, generated by counter
        address taker;              // taker address
        address market;             // market address
        int8 direction;             // position direction
        uint16 takerLeverage;       // leverage used by trader
        uint256 amount;             // position amount
        uint256 value;              // position value
        uint256 takerMargin;        // margin of trader
        uint256 makerMargin;        // margin of maker(pool)
        uint256 multiplier;         // multiplier of quanto perpetual contracts
        int256 frLastX96;           // last settled funding global cumulative value
        uint256 stopLossPrice;      // stop loss price of this position set by trader
        uint256 takeProfitPrice;    // take profit price of this position set by trader
        bool useIP;                 // true if the tp/sl is executed by index price
        uint256 lastTPSLTs;         // last timestamp of trading setting the stop loss price or take profit price
        int256 fundingPayment;      // cumulative funding need to pay of this position
        uint256 debtShare;          // borrowed share of interest module
        int256 pnl;                 // cumulative realized pnl of this position
        bool isETH;                 // true if the margin is payed by ETH
        uint256 lastUpdateTs;       // last updated timestamp of this position
    }

    /// @notice data structure of trading orders
    struct Order {
        uint256 id;                             // order id, generated by counter
        address market;                         // market address
        address taker;                          // trader address
        int8 direction;                         // order direction
        uint16 takerLeverage;                   // order leverage
        int8 triggerDirection;                  // price condition if order is trigger order: {0: not available, 1: >=, -1: <= }
        uint256 triggerPrice;                   // trigger price, 0: not available
        bool useIP;                             // true if the order is executed by index price
        uint256 freezeMargin;                   // frozen margin of this order
        uint256 amount;                         // order amount
        uint256 multiplier;                     // multiplier of quanto perpetual contracts
        uint256 takerOpenPriceMin;              // minimum trading price for slippage control
        uint256 takerOpenPriceMax;              // maximum trading price for slippage control

        OrderType orderType;                    // order type
        uint256 riskFunding;                    // risk funding penalty if this is a liquidate order

        uint256 takerFee;                       // taker trade fee
        uint256 feeToInviter;                   // reward of trading fee to the inviter
        uint256 feeToExchange;                  // trading fee charged by protocol
        uint256 feeToMaker;                     // fee reward to the pool
        uint256 feeToDiscount;                  // fee discount
        uint256 executeFee;                     // execution fee
        bytes32 code;                           // invite code

        uint256 tradeTs;                        // trade timestamp
        uint256 tradePrice;                     // trade price
        uint256 tradeIndexPrice;                // index price when executing
        int256 rlzPnl;                          // realized pnl by this order

        int256 fundingPayment;                  // settled funding payment
        int256 frX96;                           // latest cumulative funding growth global
        int256 frLastX96;                       // last cumulative funding growth global
        int256 fundingAmount;                   // funding amount by this order, calculated by amount, frX96 and frLastX96

        uint256 interestPayment;                // settled interest amount
        
        uint256 createTs;                       // create timestamp
        OrderStatus status;                     // order status
        MarketDataStructure.PositionMode mode;  // margin mode, one-way or hedge
        bool isETH;                             // true if the margin is payed by ETH
    }

    /// @notice configuration of markets
    struct MarketConfig {
        uint256 mm;                             // maintenance margin ratio
        uint256 liquidateRate;                  // penalty ratio when position is liquidated, penalty = position.value * liquidateRate
        uint256 tradeFeeRate;                   // trading fee rate
        uint256 makerFeeRate;                   // ratio of trading fee that goes to the pool
        bool createOrderPaused;                 // true if order creation is paused
        bool setTPSLPricePaused;                // true if tpsl price setting is paused
        bool createTriggerOrderPaused;          // true if trigger order creation is paused
        bool updateMarginPaused;                // true if updating margin is paused
        uint256 multiplier;                     // multiplier of quanto perpetual contracts
        uint256 marketAssetPrecision;           // margin asset decimals
        uint256 DUST;                           // dust amount,scaled by AMOUNT_PRECISION (1e20)

        uint256 takerLeverageMin;               // minimum leverage that trader can use
        uint256 takerLeverageMax;               // maximum leverage that trader can use
        uint256 dMMultiplier;                   // used to calculate the initial margin when trading decrease position margin

        uint256 takerMarginMin;                 // minimum margin of a single trader order
        uint256 takerMarginMax;                 // maximum margin of a single trader order
        uint256 takerValueMin;                  // minimum value amount of a single trader order
        uint256 takerValueMax;                  // maximum value amount of a single trader order
        int256 takerValueLimit;                 // maximum position value of a single position
    }

    /// @notice internal parameter data structure when creating an order
    struct CreateInternalParams {
        address _taker;             // trader address
        uint256 id;                 // order id, generated by id counter
        uint256 minPrice;           // slippage: minimum trading price, validated in Router
        uint256 maxPrice;           // slippage: maximum trading price, validated in Router
        uint256 margin;             // order margin
        uint256 amount;             // close order amount, 0 if order is an open order
        uint16 leverage;            // order leverage, validated in MarketLogic
        int8 direction;             // order direction, validated in MarketLogic
        int8 triggerDirection;      // trigger condition, validated in MarketLogic
        uint256 triggerPrice;       // trigger price
        bool useIP;                 // true if the order is executed by index price
        uint8 reduceOnly;           // 0: false, 1: true
        bool isLiquidate;           // is liquidate order, liquidate orders are generated automatically
        bool isETH;                 // true if order margin payed in ETH
    }

    /// @notice returned data structure when an order is executed, used by MarketLogic.sol::trade
    struct TradeResponse {
        uint256 toTaker;            // refund to the taker
        uint256 tradeValue;         // value of the order
        uint256 leftInterestPayment;// interest payment on the remaining portion of the position
        bool isIncreasePosition;    // if the order causes position value increased
        bool isDecreasePosition;    // true if the order causes position value decreased
    }
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