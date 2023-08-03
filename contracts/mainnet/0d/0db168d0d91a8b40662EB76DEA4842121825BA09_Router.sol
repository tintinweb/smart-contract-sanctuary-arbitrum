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

import "../libraries/PoolDataStructure.sol";
import "../interfaces/IPool.sol";

contract PoolStorage {
    //
    // data for this pool
    //

    // constant
    uint256  constant RATE_PRECISION = 1e6;                     // example rm lp fee rate 1000/1e6=0.001
    uint256  constant PRICE_PRECISION = 1e10;
    uint256  constant AMOUNT_PRECISION = 1e20;

    // contracts addresses used
    address public vault;                                       // vault address
    address baseAsset;                                          // base token address
    address marketPriceFeed;                                    // price feed contract address
    uint256 public baseAssetDecimals;                           // base token decimals
    address public interestLogic;                               // interest logic address
    address public WETH;                                        // WETH address 

    bool public addPaused = false;                              // flag for adding liquidity
    bool public removePaused = false;                           // flag for remove liquidity
    uint256 public minRemoveLiquidityAmount;                    // minimum amount (lp) for removing liquidity
    uint256 public minAddLiquidityAmount;                       // minimum amount (asset) for add liquidity
    uint256 public removeLiquidityFeeRate = 1000;               // fee ratio for removing liquidity

    uint256 public balance;                                     // balance that is available to use of this pool
    uint256 public reserveRate;                                 // reserve ratio
    uint256 public sharePrice;                                  // net value
    uint256 public cumulateRmLiqFee;                            // cumulative fee collected when removing liquidity
    uint256 public autoId = 1;                                  // liquidity operations order id
    mapping(address => uint256) lastOperationTime;              // mapping of last operation timestamp for addresses

    address[] public marketList;                                // supported markets array
    mapping(address => bool) public isMarket;                   // supported markets mapping
    mapping(uint256 => PoolDataStructure.MakerOrder) makerOrders;           // liquidity orders
    mapping(address => uint256[]) public makerOrderIds;         // mapping of liquidity orders for addresses
    mapping(address => uint256) public freezeBalanceOf;         // frozen liquidity amount when removing
    mapping(address => MarketConfig) public marketConfigs;      // mapping of market configs
    mapping(address => DataByMarket) public poolDataByMarkets;  // mapping of market data
    mapping(int8 => IPool.InterestData) public interestData;    // mapping of interest data for position directions (long or short)

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
        uint256 longAmount;                                     // sum asset for long pos
        uint256 longOpenTotal;                                  // sum value  for long pos
        uint256 shortAmount;                                    // sum asset for short pos
        uint256 shortOpenTotal;                                 // sum value for short pos
    }

    event RegisterMarket(address market);
    event SetMinAddLiquidityAmount(uint256 minAmount);
    event SetMinRemoveLiquidity(uint256 minLp);
    event SetOpenRateAndLimit(address market, uint256 openRate, uint256 openLimit);
    event SetReserveRate(uint256 reserveRate);
    event SetRemoveLiquidityFeeRatio(uint256 feeRate);
    event SetPaused(bool addPaused, bool removePaused);
    event SetInterestLogic(address interestLogic);
    event SetMarketPriceFeed(address marketPriceFeed);
    event ExecuteAddLiquidityOrder(uint256 orderId, address maker, uint256 amount, uint256 share, uint256 sharePrice);
    event ExecuteRmLiquidityOrder(uint256 orderId, address maker, uint256 rmAmount, uint256 rmShare, uint256 sharePrice, uint256 rmFee);
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
import "../libraries/PoolDataStructure.sol";
import "../libraries/MarketDataStructure.sol";
import "../libraries/TransferHelper.sol";
import "../interfaces/IManager.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IWrappedCoin.sol";
import "../interfaces/IMarket.sol";
import "../interfaces/IRiskFunding.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IFundingLogic.sol";
import "../interfaces/IFastPriceFeed.sol";
import "../interfaces/IInviteManager.sol";
import "../interfaces/IMarketLogic.sol";
import "../interfaces/IRewardRouter.sol";

contract Router {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public batchExecuteLimit = 10;  //max batch execution orders limit
    address public manager;
    address fastPriceFeed;
    address riskFunding;
    address inviteManager;
    address marketLogic;
    address rewardRouter;

    //taker => market => orderId[]
    mapping(address => mapping(address => EnumerableSet.UintSet)) internal notExecuteOrderIds; // not executed order ids
    address public WETH;


    event TakerOpen(address market, uint256 id);
    event Open(address market, uint256 id, uint256 orderid);
    event TakerClose(address market, uint256 id);
    event Liquidate(address market, uint256 id, uint256 orderid, address liquidator);
    event TakeProfit(address market, uint256 id, uint256 orderid);
    event Cancel(address market, uint256 id);
    event ChangeStatus(address market, uint256 id);
    event AddLiquidity(uint256 id, address pool, uint256 amount);
    event RemoveLiquidity(uint256 id, address pool, uint256 liquidity);
    event ExecuteAddLiquidityOrder(uint256 id, address pool);
    event ExecuteRmLiquidityOrder(uint256 id, address pool);
    event SetStopProfitAndLossPrice(uint256 id, address market, uint256 _profitPrice, uint256 _stopLossPrice);
    event SetParams(address _fastPriceFeed, address _riskFunding, address _inviteManager, address _marketLogic, uint256 _batchExecuteLimit);

    constructor(address _manager, address _WETH) {
        manager = _manager;
        WETH = _WETH;
    }

    modifier whenNotPaused() {
        require(!IManager(manager).paused(), "Market:system paused");
        _;
    }

    modifier onlyController() {
        require(IManager(manager).checkController(msg.sender), "Router: Must be controller");
        _;
    }

    modifier onlyPriceProvider() {
        require(IManager(manager).checkSigner(msg.sender), "Router: caller is not the price provider");
        _;
    }

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, 'Router: EXPIRED');
        _;
    }

    modifier validateMarket(address _market){
        require(IManager(manager).checkMarket(_market), "Router: market not registered");
        _;
    }

    modifier validatePool(address _pool){
        require(IManager(manager).checkPool(_pool), "Router: pool not registered");
        _;
    }

    /// @notice set params, only controller can call
    /// @param _fastPriceFeed fast price feed contract address
    /// @param _riskFunding risk funding contract address
    /// @param _inviteManager invite manager contract address
    /// @param _marketLogic market logic contract address
    /// @param _batchExecuteLimit max batch execute limit
    function setConfigParams(address _fastPriceFeed, address _riskFunding, address _inviteManager, address _marketLogic, address _rewardRouter, uint256 _batchExecuteLimit) external onlyController {
        require(_fastPriceFeed != address(0) && _riskFunding != address(0) && _inviteManager != address(0) && _marketLogic != address(0) && _batchExecuteLimit > 0, "Router: error params");
        fastPriceFeed = _fastPriceFeed;
        riskFunding = _riskFunding;
        inviteManager = _inviteManager;
        marketLogic = _marketLogic;
        rewardRouter = _rewardRouter;
        batchExecuteLimit = _batchExecuteLimit;
        emit SetParams(_fastPriceFeed, _riskFunding, _inviteManager, _marketLogic, _batchExecuteLimit);
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
        uint256 deadline;
    }

    /// @notice place an open-position order, margined by erc20 tokens
    /// @param params order params, detailed in the data structure declaration
    /// @return id order id
    function takerOpen(TakerOpenParams memory params) external payable ensure(params.deadline) validateMarket(params._market) returns (uint256 id) {
        address marginAsset = getMarketMarginAsset(params._market);
        uint256 executeOrderFee = getExecuteOrderFee();
        require(IERC20(marginAsset).balanceOf(msg.sender) >= params.margin, "Router: insufficient balance");
        require(IERC20(marginAsset).allowance(msg.sender, address(this)) >= params.margin, "Router: insufficient allowance");
        require(msg.value == executeOrderFee, "Router: inaccurate msg.value");

        TransferHelper.safeTransferFrom(marginAsset, msg.sender, params._market, params.margin);
        id = _takerOpen(params, false);
    }

    /// @notice place an open-position order margined by ETH
    /// @param params order params, detailed in the data structure declaration
    /// @return id order id
    function takerOpenETH(TakerOpenParams memory params) external payable ensure(params.deadline) validateMarket(params._market) returns (uint256 id) {
        address marginAsset = getMarketMarginAsset(params._market);
        /// @notice important can not remove
        require(marginAsset == WETH, "Router: margin asset of this market is not WETH");

        uint256 executeOrderFee = getExecuteOrderFee();
        require(msg.value == params.margin.add(executeOrderFee), "Router: inaccurate value");

        IWrappedCoin(WETH).deposit{value: params.margin}();
        TransferHelper.safeTransfer(WETH, params._market, params.margin);

        id = _takerOpen(params, true);
    }

    function _takerOpen(TakerOpenParams memory params, bool isETH) internal whenNotPaused returns (uint256 id) {
        require(params.minPrice <= params.maxPrice, "Router: slippage price error");

        setReferralCode(params.inviterCode);

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
            reduceOnly: 0,
            isLiquidate: false,
            isETH: isETH
        }));
        EnumerableSet.add(notExecuteOrderIds[msg.sender][params._market], id);
        emit TakerOpen(params._market, id);
    }

    /// @notice place a close-position order
    /// @param params order parameters, detailed in the data structure declaration
    /// @return id order id
    function takerClose(TakerCloseParams memory params) external payable ensure(params.deadline) validateMarket(params._market) whenNotPaused returns (uint256 id){
        require(params.minPrice <= params.maxPrice, "Router: slippage price error");
        uint256 executeOrderFee = getExecuteOrderFee();
        require(msg.value == executeOrderFee, "Router: insufficient execution fee");

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
            reduceOnly: 1,
            isLiquidate: false,
            isETH: false
        }));
        EnumerableSet.add(notExecuteOrderIds[msg.sender][params._market], id);
        emit TakerClose(params._market, id);
    }

    /// @notice batch execution of orders
    /// @param _market market contract address
    /// @param _ids trigger order ids
    /// @param _tokens index token name array
    /// @param _prices token prices array
    /// @param _timestamps token prices timestamps array
    function batchExecuteOrder(
        address _market,
        uint256[] memory _ids,
        string[] memory _tokens,
        uint128[] memory _prices,
        uint32[] memory _timestamps
    ) external onlyPriceProvider validateMarket(_market) {
        setPrices(_tokens, _prices, _timestamps);
        // execute trigger orders
        uint256 maxExecuteOrderNum;
        if (_ids.length > batchExecuteLimit) {
            maxExecuteOrderNum = batchExecuteLimit;
        } else {
            maxExecuteOrderNum = _ids.length;
        }
        for (uint256 i = 0; i < maxExecuteOrderNum; i++) {
            MarketDataStructure.Order memory order = IMarket(_market).getOrder(_ids[i]);
            if (order.orderType == MarketDataStructure.OrderType.TriggerOpen || order.orderType == MarketDataStructure.OrderType.TriggerClose) {
                _executeOrder(order, msg.sender);
            }
        }

        // execute market orders (non-trigger)
        (uint256 start,uint256 end) = getLastExecuteOrderId(_market);
        for (uint256 i = start; i < end; i++) {
            MarketDataStructure.Order memory order = IMarket(_market).getOrder(i);
            _executeOrder(order, msg.sender);
        }
    }

    /// @notice batch execution of orders by the community, only market orders supported
    /// @param _market market contract address
    function batchExecuteOrderByCommunity(address _market) external validateMarket(_market) {
        // execute market orders
        (uint256 start,uint256 end) = getLastExecuteOrderId(_market);
        for (uint256 i = start; i < end; i++) {
            MarketDataStructure.Order memory order = IMarket(_market).getOrder(i);
            if (
                order.orderType != MarketDataStructure.OrderType.TriggerOpen &&
                order.orderType != MarketDataStructure.OrderType.TriggerClose &&
                block.timestamp > order.createTs.add(IManager(manager).communityExecuteOrderDelay())
            ) {
                _executeOrder(order, msg.sender);
            }
        }
    }

    /// @notice execute an order
    /// @param order  order info
    /// @param to the address to receive the execution fee
    function _executeOrder(MarketDataStructure.Order memory order, address to) internal {
        if (order.status == MarketDataStructure.OrderStatus.Open) {
            (int256 resultCode,uint256 positionId) = IMarket(order.market).executeOrder(order.id);
            if (resultCode == 0) EnumerableSet.remove(notExecuteOrderIds[order.taker][order.market], order.id);
            if (resultCode == 0 || resultCode == 1) {
                TransferHelper.safeTransferETH(to, order.executeFee);
            }
            emit Open(order.market, positionId, order.id);
        }
    }

    /// @notice execute position liquidation, take profit and tpsl
    /// @param _market  market contract address
    /// @param id   position id
    /// @param action   reason and how to end the position
    /// @param _tokens  price tokens
    /// @param _prices  price
    /// @param _timestamps   price timestamp array
    function liquidate(address _market, uint256 id, MarketDataStructure.OrderType action, string[] memory _tokens, uint128[] memory _prices, uint32[] memory _timestamps) external validateMarket(_market) {
        require(IManager(manager).checkLiquidator(msg.sender), "Router: only liquidators");
        setPrices(_tokens, _prices, _timestamps);
        uint256 orderId = IMarket(_market).liquidate(id, action);
        if (MarketDataStructure.OrderType.Liquidate == action) {
            IRiskFunding(riskFunding).updateLiquidatorExecutedFee(msg.sender);
        }
        emit Liquidate(_market, id, orderId, msg.sender);
    }

    /// @notice execute position liquidation
    /// @param _market  market contract address
    /// @param id   position id
    function liquidateByCommunity(address _market, uint256 id) external validateMarket(_market) {
        uint256 orderId = IMarket(_market).liquidate(id, MarketDataStructure.OrderType.Liquidate);
        IRiskFunding(riskFunding).updateLiquidatorExecutedFee(msg.sender);
        emit Liquidate(_market, id, orderId, msg.sender);
    }

    /// @notice  increase margin to a position, margined by ETH
    /// @param _market  market contract address
    /// @param _id  position id
    function increaseMarginETH(address _market, uint256 _id) external payable validateMarket(_market) {
        address vault = IManager(manager).vault();
        address marginAsset = getMarketMarginAsset(_market);
        /// @notice important, can not remove, or 100 ETH can be used as 100 USDC
        require(marginAsset == WETH, "Router: margin is not WETH");
        IWrappedCoin(WETH).deposit{value: msg.value}();
        TransferHelper.safeTransfer(WETH, vault, msg.value);
        _updateMargin(_market, _id, msg.value, true);
    }

    /// @notice  add margin to a position, margined by ERC20 tokens
    /// @param _market  market contract address
    /// @param _id  position id
    /// @param _value  add margin value
    function increaseMargin(address _market, uint256 _id, uint256 _value) external validateMarket(_market) {
        address marginAsset = getMarketMarginAsset(_market);
        address vault = IManager(manager).vault();
        TransferHelper.safeTransferFrom(marginAsset, msg.sender, vault, _value);
        _updateMargin(_market, _id, _value, true);
    }

    /// @notice  remove margin from a position
    /// @param _market  market contract address
    /// @param _id  position id
    /// @param _value  remove margin value
    function decreaseMargin(address _market, uint256 _id, uint256 _value) external validateMarket(_market) {
        _updateMargin(_market, _id, _value, false);
    }

    function _updateMargin(address _market, uint256 _id, uint256 _deltaMargin, bool isIncrease) internal whenNotPaused {
        require(_deltaMargin != 0, "Router: wrong value for remove margin");
        MarketDataStructure.Position memory position = IMarket(_market).getPosition(_id);
        MarketDataStructure.MarketConfig memory marketConfig = IMarket(_market).getMarketConfig();
        require(position.taker == msg.sender, "Router: caller is not owner");
        require(position.amount > 0, "Router: position not exist");

        if (isIncrease) {
            position.takerMargin = position.takerMargin.add(_deltaMargin);
            require(position.takerMargin <= marketConfig.takerMarginMax && position.makerMargin >= position.takerMargin, 'Router: margin exceeded limit');
        } else {
            //get max decrease margin amount
            (uint256 maxDecreaseMargin) = IMarketLogic(marketLogic).getMaxTakerDecreaseMargin(position);
            if (maxDecreaseMargin < _deltaMargin) _deltaMargin = maxDecreaseMargin;
            position.takerMargin = position.takerMargin.sub(_deltaMargin);
        }

        IMarket(_market).updateMargin(_id, _deltaMargin, isIncrease);
    }

    /// @notice user or system cancel an order that open or failed
    /// @param _market market address
    /// @param id order id
    function orderCancel(address _market, uint256 id) external validateMarket(_market) {
        address marginAsset = getMarketMarginAsset(_market);
        MarketDataStructure.Order memory order = IMarket(_market).getOrder(id);
        if (!IManager(manager).checkSigner(msg.sender)) {
            require(order.taker == msg.sender, "Router: not owner");
            require(order.createTs.add(IManager(manager).cancelElapse()) <= block.timestamp, "Router: can not cancel until deadline");
        }

        IMarket(_market).cancel(id);
        if (order.freezeMargin > 0) {
            if (!order.isETH) {
                TransferHelper.safeTransfer(marginAsset, order.taker, order.freezeMargin);
            } else {
                IWrappedCoin(marginAsset).withdraw(order.freezeMargin);
                TransferHelper.safeTransferETH(order.taker, order.freezeMargin);
            }
        }

        if (order.status == MarketDataStructure.OrderStatus.Open)
            TransferHelper.safeTransferETH(order.taker, order.executeFee);
        EnumerableSet.remove(notExecuteOrderIds[order.taker][_market], id);
        emit Cancel(_market, id);
    }

    /// @notice user set prices for take-profit and stop-loss
    /// @param _market  market contract address
    /// @param _id  position id
    /// @param _profitPrice take-profit price
    /// @param _stopLossPrice stop-loss price
    function setTPSLPrice(address _market, uint256 _id, uint256 _profitPrice, uint256 _stopLossPrice) external validateMarket(_market) whenNotPaused {
        MarketDataStructure.Position memory position = IMarket(_market).getPosition(_id);
        require(position.taker == msg.sender, "Router: not taker");
        require(position.amount > 0, "Router: no position");
        IMarket(_market).setTPSLPrice(_id, _profitPrice, _stopLossPrice);
        emit SetStopProfitAndLossPrice(_id, _market, _profitPrice, _stopLossPrice);
    }

    /// @notice user modify position mode
    /// @param _market  market contract address
    /// @param _mode  position mode
    function switchPositionMode(address _market, MarketDataStructure.PositionMode _mode) external validateMarket(_market) {
        IMarketLogic(IMarket(_market).marketLogic()).checkSwitchMode(_market, msg.sender, _mode);
        IMarket(_market).switchPositionMode(msg.sender, _mode);
    }

    /// @notice update offChain price by price provider
    /// @param _tokens  index token name array
    /// @param _prices  price array
    /// @param _timestamps  timestamp array
    function setPrices(string[] memory _tokens, uint128[] memory _prices, uint32[] memory _timestamps) public onlyPriceProvider {
        IFastPriceFeed(fastPriceFeed).setPrices(_tokens, _prices, _timestamps);
    }

    /// @notice add liquidity to the pool by using ETH
    /// @param _pool  the pool to add liquidity
    /// @param _amount the amount to add liquidity
    /// @param _deadline the deadline time to add liquidity order
    function addLiquidityETH(address _pool, uint256 _amount, bool isStakeLp, uint256 _deadline) external payable ensure(_deadline) validatePool(_pool) returns (bool result, uint256 id){
        address baseAsset = IPool(_pool).getBaseAsset();
        require(baseAsset == WETH, "Router: baseAsset is not WETH");
        require(msg.value == _amount, "Router: inaccurate balance");
        IWrappedCoin(WETH).deposit{value: msg.value}();
        TransferHelper.safeTransfer(WETH, IManager(manager).vault(), msg.value);
        (uint256 _id) = IPool(_pool).addLiquidity(msg.sender, _amount);
        result = true;
        id = _id;
        emit AddLiquidity(_id, _pool, _amount);

        _executeLiquidityOrder(_pool, _id, true, isStakeLp);
    }


    /// @notice add liquidity to the pool by using ERC20 tokens
    /// @param _pool  the pool to add liquidity
    /// @param _amount the amount to add liquidity
    /// @param _deadline the deadline time to add liquidity order
    function addLiquidity(address _pool, uint256 _amount, bool isStakeLp, uint256 _deadline) external ensure(_deadline) validatePool(_pool) returns (bool result, uint256 id){
        address baseAsset = IPool(_pool).getBaseAsset();
        require(IERC20(baseAsset).balanceOf(msg.sender) >= _amount, "Router: insufficient balance");
        require(IERC20(baseAsset).allowance(msg.sender, address(this)) >= _amount, "Router: insufficient allowance");
        TransferHelper.safeTransferFrom(baseAsset, msg.sender, IManager(manager).vault(), _amount);
        (uint256 _id) = IPool(_pool).addLiquidity(msg.sender, _amount);
        result = true;
        id = _id;

        emit AddLiquidity(_id, _pool, _amount);

        _executeLiquidityOrder(_pool, _id, false, isStakeLp);
    }

    /// @notice execute liquidity orders
    /// @param _pool pool address
    /// @param _id liquidity order id
    function _executeLiquidityOrder(address _pool, uint256 _id, bool isETH, bool isStake) internal {
        //IPool(_pool).updateBorrowIG();
        PoolDataStructure.MakerOrder memory order = IPool(_pool).getOrder(_id);
        if (order.action == PoolDataStructure.PoolAction.Deposit) {
            (uint256 liquidity) = IPool(_pool).executeAddLiquidityOrder(_id);
            if (isStake && rewardRouter != address(0)) {
                IRewardRouter(rewardRouter).stakeLpForAccount(order.maker, _pool, liquidity);
            }
            emit ExecuteAddLiquidityOrder(_id, _pool);
        } else {
            IPool(_pool).executeRmLiquidityOrder(_id, isETH);
            emit ExecuteRmLiquidityOrder(_id, _pool);
        }
    }

    /// @notice remove liquidity from the pool, get ERC20 tokens
    /// @param _pool  which pool address to remove liquidity
    /// @param _liquidity liquidity amount to remove
    /// @param _deadline deadline time
    /// @return result result of cancel the order
    /// @return id order id for remove liquidity
    function removeLiquidity(address _pool, uint256 _liquidity, bool isUnStake, uint256 _deadline) external ensure(_deadline) validatePool(_pool) returns (bool result, uint256 id){
        if (isUnStake && rewardRouter != address(0)) {
            uint256 lpBalance = IERC20(_pool).balanceOf(msg.sender);
            if (lpBalance < _liquidity) {
                IRewardRouter(rewardRouter).unstakeLpForAccount(msg.sender, _pool, _liquidity.sub(lpBalance));
            }
        }

        (uint256 _id, uint256 _value) = IPool(_pool).removeLiquidity(msg.sender, _liquidity);
        result = true;
        id = _id;
        emit RemoveLiquidity(_id, _pool, _value);

        _executeLiquidityOrder(_pool, _id, false, false);
    }


    /// @notice execute remove liquidity orders, get ETH if and only if the base asset of the pool is WETH
    /// @param _pool  which pool address to remove liquidity
    /// @param _liquidity liquidity amount to remove
    /// @param _deadline deadline time
    /// @return result result of cancel the order
    /// @return id order id for remove liquidity
    function removeLiquidityETH(address _pool, uint256 _liquidity, bool isUnStake, uint256 _deadline) external ensure(_deadline) validatePool(_pool) returns (bool result, uint256 id){
        require(IPool(_pool).getBaseAsset() == WETH, "Router: baseAsset is not WETH");

        if (isUnStake && rewardRouter != address(0)) {
            uint256 lpBalance = IERC20(_pool).balanceOf(msg.sender);
            if (lpBalance < _liquidity) {
                IRewardRouter(rewardRouter).unstakeLpForAccount(msg.sender, _pool, _liquidity.sub(lpBalance));
            }
        }

        (uint256 _id, uint256 _value) = IPool(_pool).removeLiquidity(msg.sender, _liquidity);
        result = true;
        id = _id;
        emit RemoveLiquidity(_id, _pool, _value);

        _executeLiquidityOrder(_pool, _id, true, false);
    }

    /// @notice set the referral code for the trader
    /// @param inviterCode the inviter code
    function setReferralCode(bytes32 inviterCode) internal {
        IInviteManager(inviteManager).setTraderReferralCode(msg.sender, inviterCode);
    }

    /// @notice calculate the execution order ids
    /// @param _market market address
    /// @return start start order id
    /// @return end end order id
    function getLastExecuteOrderId(address _market) public view returns (uint256 start, uint256 end){
        uint256 lastOrderId = IMarket(_market).orderID();
        start = IMarket(_market).lastExecutedOrderId();
        uint256 deltaNum = lastOrderId.sub(start);
        if (deltaNum > batchExecuteLimit) deltaNum = batchExecuteLimit;
        start = start.add(1);
        end = start.add(deltaNum);
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

    fallback() external payable {
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
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

interface IFastPriceFeed {
    function setPrices(string[] memory _tokens, uint128[] memory _prices, uint32[] memory _timestamps) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "../libraries/MarketDataStructure.sol";

interface IFundingLogic {
    function getFunding(address market) external view returns (int256 fundingGrowthGlobalX96);

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

    function checkSigner(address _signer) external view returns (bool);

    function checkController(address _controller) view external returns (bool);

    function checkRouter(address _router) external view returns (bool);

    function checkMarket(address _market) external view returns (bool);

    function checkPool(address _pool) external view returns (bool);

    function cancelElapse() external view returns (uint256);

    function triggerOrderDuration() external view returns (uint256);

    function paused() external returns (bool);
    
    function getMakerByMarket(address maker) external view returns (address);

    function getMarketMarginAsset(address) external view returns (address);

    function isFundingPaused() external view returns (bool);

    function isInterestPaused() external view returns (bool);

    function executeOrderFee() external view returns (uint256);

    function inviteManager() external view returns (address);

    function getAllMarkets() external view returns (address[] memory);

    function getAllPools() external view returns (address[] memory);

    function orderNumLimit() external view returns (uint256);

    function checkTreasurer(address _treasurer) external view returns (bool);

    function checkLiquidator(address _liquidator) external view returns (bool);
    
    function communityExecuteOrderDelay() external view returns (uint256);
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

    function executeOrder(uint256 _id) external returns (int256, uint256);

    function updateMargin(uint256 _id, uint256 _updateMargin, bool isIncrease) external;

    function liquidate(uint256 _id, MarketDataStructure.OrderType action) external returns (uint256);

    function setTPSLPrice(uint256 _id, uint256 _profitPrice, uint256 _stopLossPrice) external;

    function takerOrderNum(address, MarketDataStructure.OrderType) external view returns (uint256);

    function getLogicAddress() external view returns (address);

    function initialize(string memory _indexToken, address _clearAnchor, address _pool, uint8 _marketType) external;

    function switchPositionMode(address _taker, MarketDataStructure.PositionMode _mode) external;

    function orderID() external view returns (uint256);

    function lastExecutedOrderId() external view returns (uint256);

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

    function trade(uint256 id, uint256 positionId, uint256, uint256) external view returns (MarketDataStructure.Order memory order, MarketDataStructure.Position memory position, MarketDataStructure.TradeResponse memory response, uint256 errCode);

    function createOrderInternal(MarketDataStructure.CreateInternalParams memory params) external view returns (MarketDataStructure.Order memory order);

    function getLiquidateInfo(LiquidityInfoParams memory params) external view returns (LiquidateInfoResponse memory response);

    function isLiquidateOrProfitMaximum(MarketDataStructure.Position memory position, uint256 mm, uint256 indexPrice, uint256 toPrecision) external view returns (bool);

    function getMaxTakerDecreaseMargin(MarketDataStructure.Position memory position) external view returns (uint256 maxDecreaseMargin);

    function checkOrder(uint256 id) external view;

    function checkSwitchMode(address _market, address _taker, MarketDataStructure.PositionMode _mode) external view;

    function checkoutConfig(address market, MarketDataStructure.MarketConfig memory _config) external view;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

import "../libraries/PoolDataStructure.sol";
import "../core/PoolStorage.sol";

interface IPool {
    struct InterestData {
        uint256 totalBorrowShare;
        uint256 lastInterestUpdateTs;
        uint256 borrowIG;
    }

    /// @notice the following tow structs are parameters used to update pool data when an order is executed.
    ///         We differ the affect of the executed order by result as open or close,
    ///         which represents increase or decrease the position.
    ///         Normally, there's one type of pool update operation during one order execution,
    ///         excepts in the one-way position model, when an order causing the position reversal, both opening and
    ///         closing process will be executed respectively.

    struct OpenUpdateInternalParams {
        uint256 orderId;
        uint256 _makerMargin;   // pool balance taken by this order
        uint256 _takerMargin;   // taker margin for this order
        uint256 _amount;        // order amount
        uint256 _total;         // order value
        uint256 makerFee;       // fees distributed to the pool, specially when an order causes the position reversal, the fee to maker will be updated in the closing process
        int8 _takerDirection;   // order direction
        uint256 marginToVault;  // margin should transferred to the vault
        address taker;          // taker address
        uint256 feeToInviter;   // fees distributed to the inviter, specially when an order causes the position reversal, the fee to maker will be updated in the closing process
        address inviter;        // inviter address
        uint256 deltaDebtShare; //add position debt share
        uint256 feeToExchange;  // fee distributed to the protocol, specially when an order causes the position reversal, the fee to maker will be updated in the closing process
    }

    struct CloseUpdateInternalParams {
        uint256 orderId;
        uint256 _makerMargin;//reduce maker margin，taker margin，amount，value
        uint256 _takerMargin;
        uint256 _amount;
        uint256 _total;
        int256 _makerProfit;
        uint256 makerFee;   //trade fee to maker
        int256 fundingPayment;//settled funding payment
        int8 _takerDirection;//old position direction
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

    function setMinAddLiquidityAmount(uint256 _minAmount) external returns (bool);

    function setMinRemoveLiquidity(uint256 _minLiquidity) external returns (bool);

    function setOpenRate(address _market, uint256 _openRate, uint256 _openLimit) external returns (bool);

    //function setRemoveLiquidityFeeRatio(uint256 _rate) external returns (bool);

    function canOpen(address _market, uint256 _makerMargin) external view returns (bool);

    function getMakerOrderIds(address _maker) external view returns (uint256[] memory);

    function getOrder(uint256 _no) external view returns (PoolDataStructure.MakerOrder memory);

    function openUpdate(OpenUpdateInternalParams memory params) external returns (bool);

    function closeUpdate(CloseUpdateInternalParams memory params) external returns (bool);

    function takerUpdateMargin(address _market, address, int256 _margin, bool isOutETH) external returns (bool);

    function addLiquidity(address sender, uint256 amount) external returns (uint256 _id);

    function executeAddLiquidityOrder(uint256 id) external returns (uint256 liquidity);

    function removeLiquidity(address sender, uint256 liquidity) external returns (uint256 _id, uint256 _liquidity);

    function executeRmLiquidityOrder(uint256 id, bool isETH) external returns (uint256 amount);

    function getLpBalanceOf(address _maker) external view returns (uint256 _balance, uint256 _totalSupply);

    function registerMarket(address _market) external returns (bool);

    function getSharePrice() external view returns (
        uint256 _price,
        uint256 _balance
    );

    function updateFundingPayment(address _market, int256 _fundingPayment) external;

    function getMarketAmount(address _market) external view returns (uint256, uint256, uint256);

    function getCurrentBorrowIG(int8 _direction) external view returns (uint256 _borrowRate, uint256 _borrowIG);

    function getCurrentAmount(int8 _direction, uint256 share) external view returns (uint256);

    function getCurrentShare(int8 _direction, uint256 amount) external view returns (uint256);

    function updateBorrowIG() external;

    function getAllMarketData() external view returns (PoolStorage.DataByMarket memory allMarketPos, uint256 allMakerFreeze);

    function getAssetAmount() external view returns (uint256 amount);

    function getBaseAsset() external view returns (address);

    function getAutoId() external view returns (uint256);

//    function updateLiquidatorFee(address _liquidator) external;

    function minRemoveLiquidityAmount() external view returns (uint256);

    function minAddLiquidityAmount() external view returns (uint256);

    function removeLiquidityFeeRate() external view returns (uint256);

    function reserveRate() external view returns (uint256);

    function addPaused() external view returns (bool);

    function removePaused() external view returns (bool);

    function makerProfitForLiquidity(bool isAdd) external view returns (int256 unPNL);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;

interface IRewardRouter {
    function stakeLpForAccount(address _account, address _lp, uint256 _amount) external returns (uint256);

    function unstakeLpForAccount(address _account, address _lp, uint256 _amount) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0 <0.8.0;
pragma abicoder v2;

interface IRiskFunding {
    function updateLiquidatorExecutedFee(address _liquidator) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
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
        UserStopLoss
    }

    /// @notice position mode, one-way or hedge
    enum PositionMode{
        OneWay,
        Hedge
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
        
        uint256 createTs;                         // create timestamp
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
library PoolDataStructure {
    enum PoolAction {
        Deposit,
        Withdraw
    }

    enum PoolActionStatus {
        Submit,
        Success,
        Fail,
        Cancel
    }

    /// @notice data structure of adding or removing liquidity order
    struct MakerOrder {
        uint256 id;                     // liquidity order id, generated by counter
        address maker;                  // user address
        uint256 submitBlockTimestamp;   // timestamp when order submitted
        uint256 amount;                 // base asset amount
        uint256 liquidity;              // liquidity
        uint256 feeToPool;              // fee charged when remove liquidity
        uint256 sharePrice;             // pool share price when order is executed
        int256 poolTotal;               // pool total valuation when order is executed
        int256 profit;                  // pool profit when order is executed, pnl + funding earns + interest earns
        PoolAction action;              // order action type
        PoolActionStatus status;        // order status
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
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