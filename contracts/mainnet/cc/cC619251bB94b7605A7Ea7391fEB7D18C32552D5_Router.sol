// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

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
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "../libraries/SafeMath.sol";
import "../libraries/MarketDataStructure.sol";
import "../libraries/TransferHelper.sol";
import "../libraries/SafeCast.sol";
import "../libraries/SignedSafeMath.sol";
import "../libraries/ReentrancyGuard.sol";
import "../interfaces/IManager.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWrappedCoin.sol";
import "../interfaces/IMarket.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IFundingLogic.sol";
import "../interfaces/IInviteManager.sol";
import "../interfaces/IMarketLogic.sol";
import "../interfaces/IRewardRouter.sol";
import "../interfaces/IOrder.sol";

contract Router is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint32;
    using SignedSafeMath for int256;
    using SafeCast for int256;
    using SafeCast for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    address public manager;
    address inviteManager;
    address marketLogic;
    address poolOrder;

    //taker => market => orderId[]
    mapping(address => mapping(address => EnumerableSet.UintSet)) internal notExecuteOrderIds; // not executed order ids
    address public WETH;


    event OrderCreated(address market, uint256 id);
    event Cancel(address market, uint256 id);
    event SetStopProfitAndLossPrice(uint256 id, address market, uint256 _profitPrice, uint256 _stopLossPrice, bool _isExecutedByIndexPrice);
    event SetParams(address _inviteManager, address _marketLogic, address _order);
    event SetMakerTPSLPrice(address pool, uint256 positionId, uint256 profitPrice, uint256 stopLossPrice);

    constructor(address _manager, address _WETH) {
        manager = _manager;
        WETH = _WETH;
    }

    modifier whenNotPaused() {
        require(!IManager(manager).paused(), "RWN0");
        _;
    }

    modifier onlyController() {
        require(IManager(manager).checkController(msg.sender), "ROC0");
        _;
    }

    modifier onlyTreasurer() {
        require(IManager(manager).checkTreasurer(msg.sender), "ROT0");
        _;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'RE0');
        _;
    }

    modifier validateMarket(address _market){
        require(IManager(manager).checkMarket(_market), "RVM0");
        _;
    }

    modifier validatePool(address _pool){
        require(IManager(manager).checkPool(_pool), "RVP0");
        _;
    }

    /// @notice set params, only controller can call
    /// @param _inviteManager invite manager contract address
    /// @param _marketLogic market logic contract address
    /// @param _order order address
    function setConfigParams(address _inviteManager, address _marketLogic, address _order) external onlyController {
        require(_inviteManager != address(0) && _marketLogic != address(0) && _order != address(0), "RSC0");
        inviteManager = _inviteManager;
        marketLogic = _marketLogic;
        poolOrder = _order;
        emit SetParams(_inviteManager, _marketLogic, _order);
    }

    /// @notice user open position parameters
    struct TakerOpenParams {
        address _market;            // market contract address
        bytes32 inviterCode;        // inviter code
        uint128 minPrice;           // min price for the slippage
        uint128 maxPrice;           // max price for the slippage
        uint256 margin;             // margin of this order
        uint16 leverage;
        int8 direction;             // order direction, 1: long, -1: short
        int8 triggerDirection;      // trigger flag {1: index price >= trigger price, -1: index price <= trigger price}
        uint256 triggerPrice;
        bool isExecutedByIndexPrice;
        uint256 deadline;
    }

    /// @notice user close position parameters
    struct TakerCloseParams {
        address _market;            // market contract address
        uint256 id;                 // position id
        bytes32 inviterCode;        // inviter code
        uint128 minPrice;           // min price for the slippage
        uint128 maxPrice;           // max price for the slippage
        uint256 amount;             // position amount to close
        int8 triggerDirection;      // trigger flag {1: index price >= trigger price, -1: index price <= trigger price}
        uint256 triggerPrice;
        bool isExecutedByIndexPrice;
        uint256 deadline;
    }

    /// @notice place an open-position order, margined by both erc20 and eth
    /// @param params order params, detailed in the data structure declaration
    /// @return id order id
    function takerOpen(TakerOpenParams memory params) external payable ensure(params.deadline) validateMarket(params._market) whenNotPaused nonReentrant returns (uint256 id) {
        require(params.minPrice <= params.maxPrice, "RTOP0");

        setReferralCode(params.inviterCode);

        address marginAsset = getMarketMarginAsset(params._market);
        uint256 fee = getExecuteOrderFee();
        bool isETH = marginAsset == WETH && msg.value > fee;
        if (isETH) {
            params.margin = msg.value.sub(fee);
        } else {
            require(msg.value == fee, "RTOE2");
        }
        require(params.margin > 0, "RTOE1");

        _transfer(marginAsset, params._market, params.margin, isETH);

        id = IMarket(params._market).createOrder(MarketDataStructure.CreateInternalParams({
            _taker: msg.sender,
            id: 0,
            minPrice: params.minPrice,
            maxPrice: params.maxPrice,
            margin: params.margin,
            amount: 0,
            leverage: params.leverage,
            direction: params.direction,
            triggerDirection: params.triggerDirection,
            triggerPrice: params.triggerPrice,
            useIP: params.isExecutedByIndexPrice,
            reduceOnly: 0,
            isLiquidate: false,
            isETH: isETH
        }));

        EnumerableSet.add(notExecuteOrderIds[msg.sender][params._market], id);
        emit OrderCreated(params._market, id);
    }

    /// @notice place a close-position order
    /// @param params order parameters, detailed in the data structure declaration
    /// @return id order id
    function takerClose(TakerCloseParams memory params) external payable ensure(params.deadline) validateMarket(params._market) whenNotPaused nonReentrant returns (uint256 id){
        require(params.minPrice <= params.maxPrice, "RTCL0");
        uint256 executeOrderFee = getExecuteOrderFee();
        require(msg.value == executeOrderFee, "RTCL1");

        setReferralCode(params.inviterCode);

        id = IMarket(params._market).createOrder(MarketDataStructure.CreateInternalParams({
            _taker: msg.sender,
            id: params.id,
            minPrice: params.minPrice,
            maxPrice: params.maxPrice,
            margin: 0,
            amount: params.amount,
            leverage: 0,
            direction: 0,
            triggerDirection: params.triggerDirection,
            triggerPrice: params.triggerPrice,
            useIP: params.isExecutedByIndexPrice,
            reduceOnly: 1,
            isLiquidate: false,
            isETH: false
        }));

        EnumerableSet.add(notExecuteOrderIds[msg.sender][params._market], id);
        emit OrderCreated(params._market, id);
    }

    /// @notice  add margin to a position, margined by ERC20 tokens
    /// @param _market  market contract address
    /// @param _id  position id
    /// @param _value  add margin value 
    function increaseMargin(address _market, uint256 _id, uint256 _value) external payable nonReentrant {
        address marginAsset = getMarketMarginAsset(_market);
        bool isETH = marginAsset == WETH && msg.value > 0;
        _value = isETH ? msg.value : _value;
        _transfer(marginAsset, IManager(manager).vault(), _value, isETH);
        _updateMargin(_market, _id, _value, true);
    }

    /// @notice  remove margin from a position
    /// @param _market  market contract address
    /// @param _id  position id
    /// @param _value  remove margin value
    function decreaseMargin(address _market, uint256 _id, uint256 _value) external nonReentrant {
        _updateMargin(_market, _id, _value, false);
    }

    function _updateMargin(address _market, uint256 _id, uint256 _deltaMargin, bool isIncrease) internal whenNotPaused {
        require(_deltaMargin != 0, "MUM0");
        MarketDataStructure.Position memory position = IMarket(_market).getPosition(_id);
        MarketDataStructure.MarketConfig memory marketConfig = IMarket(_market).getMarketConfig();
        require(position.taker == msg.sender && position.amount > 0, "MUM1");

        if (isIncrease) {
            position.takerMargin = position.takerMargin.add(_deltaMargin);
            require(position.takerMargin <= marketConfig.takerMarginMax && position.makerMargin >= position.takerMargin, 'MUM2');
        } else {
            //get max decrease margin amount
            (uint256 maxDecreaseMargin) = IMarketLogic(marketLogic).getMaxTakerDecreaseMargin(position);
            if (maxDecreaseMargin < _deltaMargin) _deltaMargin = maxDecreaseMargin;
        }

        IMarket(_market).updateMargin(_id, _deltaMargin, isIncrease);
    }

    /// @notice user or system cancel an order that open or failed
    /// @param _market market address
    /// @param id order id
    function orderCancel(address _market, uint256 id) external validateMarket(_market) nonReentrant {
        address marginAsset = getMarketMarginAsset(_market);
        MarketDataStructure.Order memory order = IMarket(_market).getOrder(id);
        require(order.taker == msg.sender && order.createTs.add(IManager(manager).cancelElapse()) <= block.timestamp, "MORC0");

        IMarket(_market).cancel(id);

        uint256 toTransferEth;
        if (order.freezeMargin > 0) {
            if (!order.isETH) {
                TransferHelper.safeTransfer(marginAsset, order.taker, order.freezeMargin);
            } else {
                IWrappedCoin(marginAsset).withdraw(order.freezeMargin);
                toTransferEth = toTransferEth.add(order.freezeMargin);
            }
        }

        if (order.status == MarketDataStructure.OrderStatus.Open) toTransferEth = toTransferEth.add(order.executeFee);

        EnumerableSet.remove(notExecuteOrderIds[order.taker][_market], id);

        if(toTransferEth > 0) TransferHelper.safeTransferETH(order.taker, toTransferEth);
        
        emit Cancel(_market, id);
    }

    /// @notice user set prices for take-profit and stop-loss
    /// @param _market  market contract address
    /// @param _id  position id
    /// @param _profitPrice take-profit price
    /// @param _stopLossPrice stop-loss price
    function setTPSLPrice(address _market, uint256 _id, uint256 _profitPrice, uint256 _stopLossPrice, bool _isExecutedByIndexPrice) external nonReentrant whenNotPaused {
        MarketDataStructure.Position memory position = IMarket(_market).getPosition(_id);
        require(position.taker == msg.sender && position.amount > 0, "MSTP0");
        IMarket(_market).setTPSLPrice(_id, _profitPrice, _stopLossPrice, _isExecutedByIndexPrice);
        emit SetStopProfitAndLossPrice(_id, _market, _profitPrice, _stopLossPrice, _isExecutedByIndexPrice);
    }

    /// @notice user modify position mode
    /// @param _market  market contract address
    /// @param _mode  position mode
    function switchPositionMode(address _market, MarketDataStructure.PositionMode _mode) external nonReentrant {
        IMarketLogic(IMarket(_market).marketLogic()).checkSwitchMode(_market, msg.sender, _mode);
        IMarket(_market).switchPositionMode(msg.sender, _mode);
    }

    /// @notice create pool order
    /// @param _params order params
    /// @param _deadline deadline
    function createPoolOrder(IOrder.CreateOrderParams memory _params, uint256 _deadline) external payable nonReentrant ensure(_deadline) validatePool(_params.pool) {
        uint256 fee = getExecuteOrderFee();
        _params.executeFee = fee;
        _params.maker = msg.sender;
        if (_params.orderType == IOrder.PoolOrderType.Increase) {
            address baseAsset = IPool(_params.pool).getBaseAsset();
            _params.isETH = baseAsset == WETH && msg.value > fee;
            if (_params.isETH) {
                _params.margin = msg.value.sub(fee);
            } else {
                require(msg.value == fee, "MCRP1");
            }
            _transfer(baseAsset, poolOrder, _params.margin, _params.isETH);
        } else {
            require(msg.value == fee, "MCRP2");
        }

        IOrder(poolOrder).createOrder(_params);
    }

    /// @notice cancel pool order
    //// @param _orderId order id
    function cancelPoolOrder(uint256 _orderId) external nonReentrant {
        IOrder.PoolOrder memory order = IOrder(poolOrder).getPoolOrder(_orderId);
        require(
            order.maker == msg.sender
            && order.status == IOrder.PoolOrderStatus.Submit
            && order.createTs.add(uint32(IManager(manager).cancelElapse())) <= block.timestamp,
            "MCPO0"
        );
        IOrder(poolOrder).updatePoolOrder(order.id, IOrder.PoolOrderStatus.Cancel);
        TransferHelper.safeTransferETH(order.maker, order.executeFee);
    }

    /// @notice set the take-profit and stop-loss price for a maker position
    /// @param _pool pool address
    /// @param _positionId position id
    /// @param _profitPrice take-profit price
    /// @param _stopLossPrice stop-loss price
    function setMakerTPSLPrice(address _pool, uint256 _positionId, uint256 _profitPrice, uint256 _stopLossPrice) external nonReentrant {
        IPool(_pool).setTPSLPrice(msg.sender, _positionId, _profitPrice, _stopLossPrice);
        require(_profitPrice > _stopLossPrice, "SM0");
        emit SetMakerTPSLPrice(_pool, _positionId, _profitPrice, _stopLossPrice);
    }

    /// @notice add margin to a maker position
    /// @param pool pool address
    /// @param positionId position id
    /// @param addMargin add margin value
    function addMakerPositionMargin(address pool, uint256 positionId, uint256 addMargin) external payable validatePool(pool) nonReentrant {
        address baseAsset = IPool(pool).getBaseAsset();
        bool isETH = baseAsset == WETH && msg.value > 0;
        addMargin = isETH ? msg.value : addMargin;
        _transfer(baseAsset, IManager(manager).vault(), addMargin, isETH);
        IPool(pool).addMakerPositionMargin(positionId, addMargin);
    }

    function _transfer(address asset, address to, uint256 amount, bool isETH) internal {
        if (isETH) {
            IWrappedCoin(asset).deposit{value: amount}();
            TransferHelper.safeTransfer(asset, to, amount);
        } else {
            TransferHelper.safeTransferFrom(asset, msg.sender, to, amount);
        }
    }

    /// @notice set the referral code for the trader
    /// @param inviterCode the inviter code
    function setReferralCode(bytes32 inviterCode) internal {
        IInviteManager(inviteManager).setTraderReferralCode(msg.sender, inviterCode);
    }

    /// @notice get the not execute order ids
    /// @param _market market address
    /// @param _taker taker address
    /// @return ids order ids
    function getNotExecuteOrderIds(address _market, address _taker) external view returns (uint256[] memory){
        uint256[] memory ids = new uint256[](EnumerableSet.length(notExecuteOrderIds[_taker][_market]));
        for (uint256 i = 0; i < EnumerableSet.length(notExecuteOrderIds[_taker][_market]); i++) {
            ids[i] = EnumerableSet.at(notExecuteOrderIds[_taker][_market], i);
        }
        return ids;
    }

    /// @notice get the margin asset of an market
    function getMarketMarginAsset(address _market) internal view returns (address){
        return IManager(manager).getMarketMarginAsset(_market);
    }

    /// @notice get the configured execution fee of an order
    function getExecuteOrderFee() internal view returns (uint256){
        return IManager(manager).executeOrderFee();
    }

    /// @notice transfer the execution fee to the update router by the treasurer
    function withdrawExecuteFee() external onlyTreasurer {
        TransferHelper.safeTransferETH(IManager(manager).router(), address(this).balance);
    }

    function executorTransfer(address to, uint256 amount) external {
        IManager(manager).checkExecutorRouter(msg.sender);

        TransferHelper.safeTransferETH(to, amount);
    }

    function removeNotExecuteOrderId(address taker, address market, uint256 orderId) external {
        IManager(manager).checkExecutorRouter(msg.sender);
        
        EnumerableSet.remove(notExecuteOrderIds[taker][market], orderId);
    }

    receive() external payable {
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

import "../libraries/MarketDataStructure.sol";

interface IFundingLogic {
    function getFunding(address market) external view returns (int256 fundingGrowthGlobalX96, int256 deltaFundingRate);

    function getFundingPayment(address market, uint256 positionId, int256 fundingGrowthGlobalX96) external view returns (int256 fundingPayment);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;

interface IInviteManager {
    function setTraderReferralCode(address _account, bytes32 _code) external;

    function getReferrerCodeByTaker(address _taker) external view returns (bytes32, address, uint256, uint256);

    function updateTradeValue(uint8 _marketType, address _taker, address _inviter, uint256 _tradeValue) external;
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
pragma abicoder v2;

import "../libraries/MarketDataStructure.sol";

interface IMarketLogic {
    struct LiquidityInfoParams {
        MarketDataStructure.Position position;
        MarketDataStructure.OrderType action;
        uint256 discountRate;
        uint256 inviteRate;
        uint256 clearPrice;
    }

    struct LiquidateInfoResponse {
        int256 pnl;
        uint256 takerFee;
        uint256 feeToMaker;
        uint256 feeToExchange;
        uint256 feeToInviter;
        uint256 feeToDiscount;
        uint256 riskFunding;
        uint256 payInterest;
        uint256 toTaker;
        uint256 tradeValue;
        uint256 price;
        uint256 indexPrice;
    }

    function trade(uint256 id, uint256 positionId, uint256, uint256) external returns (MarketDataStructure.Order memory order, MarketDataStructure.Position memory position, MarketDataStructure.TradeResponse memory response);

    function createOrderInternal(MarketDataStructure.CreateInternalParams memory params) external view returns (MarketDataStructure.Order memory order);

    function getLiquidateInfo(LiquidityInfoParams memory params) external returns (LiquidateInfoResponse memory response);

    function isLiquidateOrProfitMaximum(MarketDataStructure.Position memory position, uint256 mm, uint256 indexPrice, uint256 toPrecision) external view returns (bool);

    function getMaxTakerDecreaseMargin(MarketDataStructure.Position memory position) external view returns (uint256 maxDecreaseMargin);

    function checkOrder(uint256 id) external view;

    function checkSwitchMode(address _market, address _taker, MarketDataStructure.PositionMode _mode) external view;

    function getIndexOrMarketPrice(address _market, bool _maximise, bool isIndexPrice) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

interface IOrder {
    enum PoolOrderType {
        Increase,
        Decrease
    }

    enum PoolOrderStatus {
        Submit,
        Success,
        Fail,
        Cancel
    }

    struct PoolOrder {
        uint256 id;                 // the id of the order
        address maker;              // the address of the maker
        address pool;               // the address of the pool
        uint256 liquidity;          // the liquidity to decrease
        uint256 margin;             // the amount of margin to increase
        uint16 leverage;           // the leverage of the margin
        uint256 executeFee;         // the fee of the order
        bool isStakeLp;             // whether the maker wants to stake LP token by increasing liquidity
        bool isUnStakeLp;           // whether the maker wants to unstake LP token by decreasing liquidity
        bool isETH;                 // whether the maker wants to receive or send ETH
        PoolOrderStatus status;     // the status of the order
        PoolOrderType orderType;    // the type of the order
        uint32 createTs;            // the timestamp of the order
    }

    struct CreateOrderParams {
        address pool;               // the address of the pool
        address maker;              // the address of the maker
        uint256 liquidity;          // the liquidity to decrease , only for decrease order
        uint256 margin;             // the amount of margin to increase, only for increase order
        uint16 leverage;           // the leverage of the margin, only for increase order
        uint256 executeFee;         // the fee of the order, not necessary
        bool isStakeLp;             // whether the maker wants to stake LP token by increasing liquidity, only for increase order
        bool isUnStakeLp;           // whether the maker wants to unstake LP token by decreasing liquidity , only for decrease order
        bool isETH;                 // whether the maker wants to receive ETH by decreasing liquidity , only for decrease order
        PoolOrderType orderType;    // the type of the order {Increase:0, Decrease:1}
    }

    event ModifyManager(address indexed newManager);
    event ModifyOrderNumLimit(uint256 newOrderNumLimit);
    event CreatePoolOrder(address indexed maker, address indexed pool, uint256 orderId, uint256 liquidity, uint256 margin, uint16 leverage, uint256 executeFee, bool isStakeLp, bool isUnStakeLp, PoolOrderType orderType, uint32 createTs);
    event UpdatePoolOrder(address indexed maker, address indexed pool, uint256 orderId, PoolOrderStatus status);

    function getPoolOrder(uint256 _orderId) external view returns (PoolOrder memory);

    function createOrder(CreateOrderParams memory params) external;

    function updatePoolOrder(uint256 _orderId, PoolOrderStatus status) external;
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
pragma solidity >=0.6.0 <0.8.0;

interface IRewardRouter {
    function stakeLpForAccount(address _account, address _lp, uint256 _amount) external returns (uint256);

    function unstakeLpForAccount(address _account, address _lp, uint256 _amount, bool isLiquidate) external returns (uint256);

    function modifyStakedPosition(address market, address taker, bool isCloseAll) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

interface IWrappedCoin {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
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
contract ReentrancyGuard {
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

    constructor () {
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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * copy from openzeppelin-contracts
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "./SafeCast.sol";

library SignedSafeMath {
    using SafeCast for int256;

    int256 constant private _INT256_MIN = - 2 ** 255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == - 1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == - 1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }


    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }

    function abs(int256 value) internal pure returns (uint256) {
        return value >= 0 ? value.toUint256() : neg256(value).toUint256();
    }

    function neg256(int256 a) internal pure returns (int256) {
        require(a > - 2 ** 255, "PerpMath: inversion overflow");
        return - a;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "../interfaces/IERC20.sol";

library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        // usdt of tron mainnet TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t: 0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c
        /*
        if (token == address(0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c)){
            IERC20(token).transfer(to, value);
            return;
        }
        */

        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success,) = to.call{value : value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}