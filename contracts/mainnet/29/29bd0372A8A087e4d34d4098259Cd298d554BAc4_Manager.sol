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

import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "../interfaces/IMarket.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IMarketLogic.sol";

contract Manager {
    using EnumerableSet for EnumerableSet.AddressSet;

    address public controller;      //controller, can change all config params
    address public router;          //router address
    address public vault;           //vault address
    address public riskFunding;     //riskFunding address
    address public inviteManager;   //inviteManager address

    uint256 public executeOrderFee = 0.0001 ether;  // execution fee of one order

    mapping(address => bool) signers;       // signers are qualified addresses to execute orders and update off-chain price
    mapping(address => bool) treasurers;    // vault administrators
    mapping(address => bool) liquidators;   // liquidators are qualified addresses to liquidate positions

    uint256 public communityExecuteOrderDelay;   // time elapse after that every one can execute orders
    uint256 public cancelElapse;            // time elapse after that user can cancel not executed orders
    uint256 public triggerOrderDuration;    // validity period of trigger orders

    bool public paused = true;              // protocol pause flag
    bool public isFundingPaused = true;     // funding mechanism pause flag
    bool public isInterestPaused = false;   // interests mechanism pause flag

    mapping(address => address) public getMakerByMarket;        // mapping of market to pool, market => pool
    mapping(address => address) public getMarketMarginAsset;    // mapping of market to base asset, market => base asset
    mapping(address => address) public getPoolBaseAsset;        // mapping of base asset and pool
    EnumerableSet.AddressSet internal markets;                  // enumerate of all markets
    EnumerableSet.AddressSet internal pools;                    // enumerate of all pools

    uint256 public orderNumLimit;                               //taker open order number limit

    event MarketCreated(address market, address pool, string indexToken, address marginAsset, uint8 marketType);
    event SignerAdded(address signer);
    event SignerRemoved(address signer);
    event Pause(bool paused);
    event Unpause(bool paused);
    event OrderNumLimitModified(uint256 _limit);
    event RouterModified(address _router);
    event ControllerModified(address _controller);
    event VaultModified(address _vault);
    event RiskFundingModified(address _riskFunding);
    event ExecuteOrderFeeModified(uint256 _feeToPriceProvider);
    event ExecuteOrderFeeOwnerModified(address _feeOwner);
    event InviteManagerModified(address _referralManager);
    event CancelElapseModified(uint256 _cancelElapse);
    event CommunityExecuteOrderDelayModified(uint256 _communityExecuteOrderDelay);
    event TriggerOrderDurationModified(uint256 triggerOrderDuration);
    event InterestStatusModified(bool _interestPaused);
    event FundingStatusModified(bool _fundingPaused);
    event TreasurerModified(address _treasurer, bool _isOpen);
    event LiquidatorModified(address _liquidator, bool _isOpen);

    modifier onlyController{
        require(msg.sender == controller, "Manager:only controller");
        _;
    }

    constructor(address _controller) {
        require(_controller != address(0), "Manager:address zero");
        controller = _controller;
    }

    /// @notice  pause the protocol
    function pause() external onlyController {
        require(!paused, "Manager:already paused");
        paused = true;
        emit Pause(paused);
    }

    /// @notice unpause the protocol
    function unpause() external onlyController {
        require(paused, "Manager:not paused");
        paused = false;
        emit Unpause(paused);
    }


    /// @notice modify liquidator
    /// @param _liquidator liquidator address
    /// @param _isOpen true open ;false close
    function modifyLiquidator(address _liquidator, bool _isOpen) external onlyController {
        require(_liquidator != address(0), "Manager:address error");
        liquidators[_liquidator] = _isOpen;
        emit LiquidatorModified(_liquidator, _isOpen);
    }

    /// @notice modify treasurer address
    /// @param _treasurer treasurer address
    /// @param _isOpen true open ;false close
    function modifyTreasurer(address _treasurer, bool _isOpen) external onlyController {
        require(_treasurer != address(0), "Manager:address error");
        treasurers[_treasurer] = _isOpen;
        emit TreasurerModified(_treasurer, _isOpen);
    }

    /// @notice modify order num limit of market
    /// @param _limit order num limit
    function modifyOrderNumLimit(uint256 _limit) external onlyController {
        require(_limit > 0, "Manager:limit error");
        orderNumLimit = _limit;
        emit OrderNumLimitModified(_limit);
    }

    /// @notice modify router address
    /// @param _router router address
    function modifyRouter(address _router) external onlyController {
        //        require(router == address(0), "router already notify");
        require(_router != address(0), "Manager:address zero");
        router = _router;
        emit RouterModified(_router);
    }

    /// @notice add a signer address
    /// @param _signer signer address
    function addSigner(address _signer) external onlyController {
        require(_signer != address(0), "Manager:address zero");
        signers[_signer] = true;
        emit SignerAdded(_signer);
    }

    /// @notice remove a signer address
    /// @param _signer signer address
    function removeSigner(address _signer) external onlyController {
        require(_signer != address(0), "Manager:address zero");
        signers[_signer] = false;
        emit SignerRemoved(_signer);
    }

    /// @notice modify controller address
    /// @param _controller controller address
    function modifyController(address _controller) external onlyController{
        require(_controller != address(0), "Manager:address zero");
        controller = _controller;
        emit ControllerModified(_controller);
    }

    /// @notice modify price provider fee owner address
    /// @param _riskFunding risk funding address
    function modifyRiskFunding(address _riskFunding) external onlyController {
        require(_riskFunding != address(0), "Manager:address zero");
        riskFunding = _riskFunding;
        emit RiskFundingModified(_riskFunding);
    }

    /// @notice activate or deactivate the interests module
    /// @param _interestPaused true:interest paused;false:interest not paused
    function modifyInterestStatus(bool _interestPaused) external onlyController {
        require(isInterestPaused != _interestPaused, "Manager:_interestPaused not change");

        for (uint256 i = 0; i < EnumerableSet.length(pools); i++) {
            IPool(EnumerableSet.at(pools, i)).updateBorrowIG();
        }

        isInterestPaused = _interestPaused;

        emit InterestStatusModified(_interestPaused);
    }

    /// @notice activate or deactivate
    /// @param _fundingPaused true:funding paused;false:funding not paused
    function modifyFundingStatus(bool _fundingPaused) external onlyController {
        require(isFundingPaused != _fundingPaused, "Manager:_fundingPaused not change");

        //update funding growth global
        for (uint256 i = 0; i < EnumerableSet.length(markets); i++) {
            IMarket(EnumerableSet.at(markets, i)).updateFundingGrowthGlobal();
        }

        isFundingPaused = _fundingPaused;

        emit FundingStatusModified(_fundingPaused);
    }

    /// @notice modify vault address
    /// @param _vault vault address
    function modifyVault(address _vault) external onlyController{
        require(_vault != address(0), "Manager:address zero");
        vault = _vault;
        emit VaultModified(_vault);
    }

    /// @notice modify price provider fee
    /// @param _fee price provider fee
    function modifyExecuteOrderFee(uint256 _fee) external onlyController{
        executeOrderFee = _fee;
        emit ExecuteOrderFeeModified(_fee);
    }

    /// @notice modify invite manager address
    /// @param _inviteManager invite manager address
    function modifyInviteManager(address _inviteManager) external onlyController{
        inviteManager = _inviteManager;
        emit InviteManagerModified(_inviteManager);
    }

    /// @notice modify cancel time elapse
    /// @param _cancelElapse cancel time elapse
    function modifyCancelElapse(uint256 _cancelElapse) external onlyController {
        require(_cancelElapse > 0, "Manager:_cancelElapse zero");
        cancelElapse = _cancelElapse;
        emit CancelElapseModified(_cancelElapse);
    }


    /// @notice modify community execute order delay time
    /// @param _communityExecuteOrderDelay execute time elapse
    function modifyCommunityExecuteOrderDelay(uint256 _communityExecuteOrderDelay) external onlyController {
        require(_communityExecuteOrderDelay > 0, "Manager:_communityExecuteOrderDelay zero");
        communityExecuteOrderDelay = _communityExecuteOrderDelay;
        emit CommunityExecuteOrderDelayModified(_communityExecuteOrderDelay);
    }

    /// @notice modify the trigger order validity period
    /// @param _triggerOrderDuration trigger order time dead line
    function modifyTriggerOrderDuration(uint256 _triggerOrderDuration) external onlyController {
        require(_triggerOrderDuration > 0, "Manager: time duration should > 0");
        triggerOrderDuration = _triggerOrderDuration;
        emit TriggerOrderDurationModified(_triggerOrderDuration);
    }

    /// @notice validate whether an address is a signer
    /// @param _signer signer address
    function checkSigner(address _signer) external view returns (bool) {
        return signers[_signer];
    }

    /// @notice validate whether an address is a treasurer
    /// @param _treasurer treasurer address
    function checkTreasurer(address _treasurer) external view returns (bool) {
        return treasurers[_treasurer];
    }

    /// @notice validate whether an address is a liquidator
    /// @param _liquidator liquidator address
    function checkLiquidator(address _liquidator) external view returns (bool) {
        return liquidators[_liquidator];
    }

    /// @notice validate whether an address is a controller
    function checkController(address _controller) view external returns (bool) {
        return _controller == controller;
    }

    /// @notice validate whether an address is the router
    function checkRouter(address _router) external view returns (bool) {
        return _router == router;
    }

    /// @notice validate whether an address is a legal market address
    function checkMarket(address _market) external view returns (bool) {
        return getMarketMarginAsset[_market] != address(0);
    }

    /// @notice validate whether an address is a legal pool address
    function checkPool(address _pool) external view returns (bool) {
        return getPoolBaseAsset[_pool] != address(0);
    }

    /// @notice create pair ,only controller can call
    /// @param pool pool address
    /// @param market market address
    /// @param token save price key
    /// @param marketType market type
    function createPair(
        address pool,
        address market,
        string memory token,
        uint8 marketType,
        MarketDataStructure.MarketConfig memory _config
    ) external onlyController {
        require(bytes(token).length != 0, 'Manager:indexToken is address(0)');
        require(marketType == 0 || marketType == 1 || marketType == 2, 'Manager:marketType error');
        require(pool != address(0) && market != address(0), 'Manager:market and maker is not address(0)');
        require(getMakerByMarket[market] == address(0), 'Manager:maker already exist');

        getMakerByMarket[market] = pool;
        address asset = IPool(pool).getBaseAsset();
        if(getPoolBaseAsset[pool] == address(0)){
            getPoolBaseAsset[pool] = asset;
        }
        require(getPoolBaseAsset[pool] == asset, 'Manager:pool base asset error');
        getMarketMarginAsset[market] = asset;
        
        EnumerableSet.add(markets, market);
        if (!EnumerableSet.contains(pools, pool)) {
            EnumerableSet.add(pools, pool);
        }
        IMarket(market).initialize(token, asset, pool, marketType);
        IPool(pool).registerMarket(market);
        
        _setMarketConfigInternal(market, _config);

        emit MarketCreated(market, pool, token, asset, marketType);
    }

    /// @notice set general market configurations, only controller can call
    /// @param _config configuration parameters
    function setMarketConfig(address market, MarketDataStructure.MarketConfig memory _config) public onlyController {
        _setMarketConfigInternal(market, _config);
    }

    function _setMarketConfigInternal(address market, MarketDataStructure.MarketConfig memory _config) internal {
        IMarketLogic(IMarket(market).marketLogic()).checkoutConfig(market, _config);
        IMarket(market).setMarketConfig(_config);
    }

    /// @notice modify the pause status for creating an order of a market
    /// @param market market address
    /// @param paused paused or not
    function modifyMarketCreateOrderPaused(address market, bool paused) public onlyController{
        MarketDataStructure.MarketConfig memory _config = IMarket(market).getMarketConfig();
        _config.createOrderPaused = paused;
        _setMarketConfigInternal(market, _config);
    }

    /// @notice modify the status for setting tpsl for an position
    /// @param market market address
    /// @param paused paused or not
    function modifyMarketTPSLPricePaused(address market, bool paused) public onlyController{
        MarketDataStructure.MarketConfig memory _config = IMarket(market).getMarketConfig();
        _config.setTPSLPricePaused = paused;
        _setMarketConfigInternal(market, _config);
    }

    /// @notice modify the pause status for creating a trigger order
    /// @param market market address
    /// @param paused paused or not
    function modifyMarketCreateTriggerOrderPaused(address market, bool paused) public onlyController {
        MarketDataStructure.MarketConfig memory _config = IMarket(market).getMarketConfig();
        _config.createTriggerOrderPaused = paused;
        _setMarketConfigInternal(market, _config);
    }

    /// @notice modify the pause status for updating the position margin
    /// @param market market address
    /// @param paused paused or not
    function modifyMarketUpdateMarginPaused(address market, bool paused) public onlyController {
        MarketDataStructure.MarketConfig memory _config = IMarket(market).getMarketConfig();
        _config.updateMarginPaused = paused;
        _setMarketConfigInternal(market, _config);
    }
    
    /// @notice get all markets
    function getAllMarkets() external view returns (address[] memory) {
        address[] memory _markets = new address[](EnumerableSet.length(markets));
        for (uint256 i = 0; i < EnumerableSet.length(markets); i++) {
            _markets[i] = EnumerableSet.at(markets, i);
        }
        return _markets;
    }

    /// @notice get all poolss
    function getAllPools() external view returns (address[] memory) {
        address[] memory _pools = new address[](EnumerableSet.length(pools));
        for (uint256 i = 0; i < EnumerableSet.length(pools); i++) {
            _pools[i] = EnumerableSet.at(pools, i);
        }
        return _pools;
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