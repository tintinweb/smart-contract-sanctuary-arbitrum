// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { BlockContext } from "./utils/BlockContext.sol";
import { IPriceFeed } from "./interfaces/IPriceFeed.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { OwnableUpgradeableSafe } from "./OwnableUpgradeableSafe.sol";
import { IAmm } from "./interfaces/IAmm.sol";
import { IntMath } from "./utils/IntMath.sol";
import { UIntMath } from "./utils/UIntMath.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { AmmMath } from "./utils/AmmMath.sol";

contract Amm is IAmm, OwnableUpgradeableSafe, BlockContext {
    using UIntMath for uint256;
    using IntMath for int256;

    //
    // enum and struct
    //

    // internal usage
    enum QuoteAssetDir {
        QUOTE_IN,
        QUOTE_OUT
    }

    struct ReserveSnapshot {
        uint256 quoteAssetReserve;
        uint256 baseAssetReserve;
        uint256 cumulativeTWPBefore; // cumulative time weighted price of market before the current block, used for TWAP calculation
        uint256 timestamp;
        uint256 blockNumber;
    }

    // To record current base/quote asset to calculate TWAP

    struct TwapInputAsset {
        Dir dir;
        uint256 assetAmount;
        QuoteAssetDir inOrOut;
    }

    struct TwapPriceCalcParams {
        uint16 snapshotIndex;
        TwapInputAsset asset;
    }

    //
    // CONSTANT
    //
    // because position decimal rounding error,
    // if the position size is less than IGNORABLE_DIGIT_FOR_SHUTDOWN, it's equal size is 0
    uint256 private constant IGNORABLE_DIGIT_FOR_SHUTDOWN = 1e9;

    uint256 public constant MAX_ORACLE_SPREAD_RATIO = 0.05 ether; // 5%

    uint8 public constant MIN_NUM_REPEG_FLAG = 3;

    //**********************************************************//
    //    The below state variables can not change the order    //
    //**********************************************************//

    // only admin
    uint256 public override initMarginRatio;

    // only admin
    uint256 public override maintenanceMarginRatio;

    // only admin
    uint256 public override liquidationFeeRatio;

    // only admin
    uint256 public override partialLiquidationRatio;

    uint256 public longPositionSize;
    uint256 public shortPositionSize;

    int256 private cumulativeNotional;

    uint256 private settlementPrice;
    uint256 public tradeLimitRatio;
    uint256 public quoteAssetReserve;
    uint256 public baseAssetReserve;
    uint256 public fluctuationLimitRatio;

    // owner can update
    uint256 public tollRatio;
    uint256 public spreadRatio;

    uint256 public spotPriceTwapInterval;
    uint256 public fundingPeriod;
    uint256 public fundingBufferPeriod;
    uint256 public nextFundingTime;
    bytes32 public priceFeedKey;
    // this storage variable is used for TWAP calcualtion
    // let's use 15 mins and 3 hr twap as example
    // if the price is being updated 1 secs, then needs 900 and 10800 historical data for 15mins and 3hr twap.
    ReserveSnapshot[65536] public reserveSnapshots; // 2**16=65536
    uint16 public latestReserveSnapshotIndex;

    address private counterParty;
    address public globalShutdown;
    IERC20 public override quoteAsset;
    IPriceFeed public priceFeed;
    bool public override open;
    bool public override adjustable;
    bool public override canLowerK;
    uint8 public repegFlag;
    uint256 public repegPriceGapRatio;

    uint256 public fundingCostCoverRate; // system covers pct of normal funding payment when cost, 1 means normal funding rate
    uint256 public fundingRevenueTakeRate; // system takes ptc of normal funding payment when revenue, 1 means normal funding rate

    uint256 public override ptcKIncreaseMax;
    uint256 public override ptcKDecreaseMax;

    uint256[50] private __gap;

    //**********************************************************//
    //    The above state variables can not change the order    //
    //**********************************************************//

    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//

    //
    // EVENTS
    //
    event SwapInput(Dir dirOfQuote, uint256 quoteAssetAmount, uint256 baseAssetAmount);
    event SwapOutput(Dir dirOfQuote, uint256 quoteAssetAmount, uint256 baseAssetAmount);
    event FundingRateUpdated(int256 rateLong, int256 rateShort, uint256 underlyingPrice, int256 fundingPayment);
    event ReserveSnapshotted(uint256 quoteAssetReserve, uint256 baseAssetReserve, uint256 timestamp);
    event CapChanged(uint256 maxHoldingBaseAsset, uint256 openInterestNotionalCap);
    event Shutdown(uint256 settlementPrice);
    event PriceFeedUpdated(address priceFeed);
    event ReservesAdjusted(uint256 quoteAssetReserve, uint256 baseAssetReserve, int256 totalPositionSize, int256 cumulativeNotional);

    //
    // MODIFIERS
    //
    modifier onlyOpen() {
        require(open, "AMM_C"); //amm was closed
        _;
    }

    modifier onlyCounterParty() {
        require(counterParty == _msgSender(), "AMM_NCP"); //not counterParty
        _;
    }

    //
    // FUNCTIONS
    //
    function initialize(
        uint256 _quoteAssetReserve,
        uint256 _baseAssetReserve,
        uint256 _tradeLimitRatio,
        uint256 _fundingPeriod,
        IPriceFeed _priceFeed,
        bytes32 _priceFeedKey,
        address _quoteAsset,
        uint256 _fluctuationLimitRatio,
        uint256 _tollRatio,
        uint256 _spreadRatio
    ) public initializer {
        require(
            _quoteAssetReserve != 0 &&
                _tradeLimitRatio != 0 &&
                _baseAssetReserve != 0 &&
                _fundingPeriod != 0 &&
                address(_priceFeed) != address(0) &&
                _quoteAsset != address(0),
            "AMM_III"
        ); //initial with invalid input
        _requireRatio(_fluctuationLimitRatio);
        _requireRatio(_tollRatio);
        _requireRatio(_spreadRatio);
        _requireRatio(_tradeLimitRatio);
        (bool success, bytes memory data) = _quoteAsset.call(abi.encodeWithSelector(bytes4(keccak256("decimals()"))));
        require(success && abi.decode(data, (uint8)) == 18, "AMM_NMD"); // not match decimal
        require(_priceFeed.decimals(_priceFeedKey) == 18, "AMM_NMD"); // not match decimal

        __Ownable_init();

        initMarginRatio = 0.2 ether; // 5x leverage
        maintenanceMarginRatio = 0.1 ether; // 10x leverage
        partialLiquidationRatio = 0.125 ether; // 1/8 of position size
        liquidationFeeRatio = 0.05 ether; // 5% - 1/2 of maintenance margin

        repegPriceGapRatio = 0; // 0%
        fundingCostCoverRate = 0.5 ether; // system covers 50% of normal funding payment when cost
        fundingRevenueTakeRate = 1 ether; // system take 100% of normal funding payment when revenue

        ptcKIncreaseMax = 1.005 ether; // 100.5% (0.5%) increase
        ptcKDecreaseMax = 0.99 ether; // 99% (1%) decrease

        quoteAssetReserve = _quoteAssetReserve;
        baseAssetReserve = _baseAssetReserve;
        tradeLimitRatio = _tradeLimitRatio;
        tollRatio = _tollRatio;
        spreadRatio = _spreadRatio;
        fluctuationLimitRatio = _fluctuationLimitRatio;
        fundingPeriod = _fundingPeriod;
        fundingBufferPeriod = _fundingPeriod / 2;
        spotPriceTwapInterval = 3 hours;
        priceFeedKey = _priceFeedKey;
        quoteAsset = IERC20(_quoteAsset);
        priceFeed = _priceFeed;
        reserveSnapshots[0] = ReserveSnapshot(quoteAssetReserve, baseAssetReserve, 0, _blockTimestamp(), _blockNumber());
        emit ReserveSnapshotted(quoteAssetReserve, baseAssetReserve, _blockTimestamp());
    }

    /**
     * @notice this function is called only when opening position
     * @dev Only clearingHouse can call this function
     * @param _dir ADD_TO_AMM, REMOVE_FROM_AMM
     * @param _amount quote asset amount
     * @param _isQuote whether or not amount is quote
     * @param _canOverFluctuationLimit if true, the impact of the price MUST be less than `fluctuationLimitRatio`
     */
    function swapInput(
        Dir _dir,
        uint256 _amount,
        bool _isQuote,
        bool _canOverFluctuationLimit
    )
        external
        override
        onlyOpen
        onlyCounterParty
        returns (
            uint256 quoteAssetAmount,
            int256 baseAssetAmount,
            uint256 spreadFee,
            uint256 tollFee
        )
    {
        uint256 uBaseAssetAmount;
        if (_isQuote) {
            quoteAssetAmount = _amount;
            uBaseAssetAmount = getQuotePrice(_dir, _amount);
        } else {
            quoteAssetAmount = getBasePrice(_dir, _amount);
            uBaseAssetAmount = _amount;
        }

        Dir dirOfQuote;
        if (_isQuote == (_dir == Dir.ADD_TO_AMM)) {
            // open long
            longPositionSize += uBaseAssetAmount;
            dirOfQuote = Dir.ADD_TO_AMM;
            baseAssetAmount = int256(uBaseAssetAmount);
        } else {
            // open short
            shortPositionSize += uBaseAssetAmount;
            dirOfQuote = Dir.REMOVE_FROM_AMM;
            baseAssetAmount = -1 * int256(uBaseAssetAmount);
        }
        spreadFee = quoteAssetAmount.mulD(spreadRatio);
        tollFee = quoteAssetAmount.mulD(tollRatio);

        _updateReserve(dirOfQuote, quoteAssetAmount, uBaseAssetAmount, _canOverFluctuationLimit);
        emit SwapInput(dirOfQuote, quoteAssetAmount, uBaseAssetAmount);
    }

    /**
     * @notice this function is called only when closing/reversing position
     * @dev only clearingHouse can call this function
     * @param _dir ADD_TO_AMM, REMOVE_FROM_AMM
     * @param _amount base asset amount
     * @param _isQuote whether or not amount is quote
     * @param _canOverFluctuationLimit if true, the impact of the price MUST be less than `fluctuationLimitRatio`
     */
    function swapOutput(
        Dir _dir,
        uint256 _amount,
        bool _isQuote,
        bool _canOverFluctuationLimit
    )
        external
        override
        onlyOpen
        onlyCounterParty
        returns (
            uint256 quoteAssetAmount,
            int256 baseAssetAmount,
            uint256 spreadFee,
            uint256 tollFee
        )
    {
        uint256 uBaseAssetAmount;
        if (_isQuote) {
            quoteAssetAmount = _amount;
            uBaseAssetAmount = getQuotePrice(_dir, _amount);
        } else {
            quoteAssetAmount = getBasePrice(_dir, _amount);
            uBaseAssetAmount = _amount;
        }

        Dir dirOfQuote;
        if (_isQuote == (_dir == Dir.ADD_TO_AMM)) {
            // close/reverse short
            uint256 _shortPositionSize = shortPositionSize;
            _shortPositionSize >= uBaseAssetAmount ? shortPositionSize = _shortPositionSize - uBaseAssetAmount : shortPositionSize = 0;
            dirOfQuote = Dir.ADD_TO_AMM;
            baseAssetAmount = int256(uBaseAssetAmount);
        } else {
            // close/reverse long
            uint256 _longPositionSize = longPositionSize;
            _longPositionSize >= uBaseAssetAmount ? longPositionSize = _longPositionSize - uBaseAssetAmount : longPositionSize = 0;
            dirOfQuote = Dir.REMOVE_FROM_AMM;
            baseAssetAmount = -1 * int256(uBaseAssetAmount);
        }
        spreadFee = quoteAssetAmount.mulD(spreadRatio);
        tollFee = quoteAssetAmount.mulD(tollRatio);

        _updateReserve(dirOfQuote, quoteAssetAmount, uBaseAssetAmount, _canOverFluctuationLimit);
        emit SwapOutput(dirOfQuote, quoteAssetAmount, uBaseAssetAmount);
    }

    /**
     * @notice update funding rate
     * @dev only allow to update while reaching `nextFundingTime`
     * @param _cap the limit of expense of funding payment
     * @return premiumFractionLong premium fraction for long of this period in 18 digits
     * @return premiumFractionShort premium fraction for short of this period in 18 digits
     * @return fundingPayment profit of insurance fund in funding payment
     */
    function settleFunding(uint256 _cap)
        external
        override
        onlyOpen
        onlyCounterParty
        returns (
            int256 premiumFractionLong,
            int256 premiumFractionShort,
            int256 fundingPayment
        )
    {
        require(_blockTimestamp() >= nextFundingTime, "AMM_SFTE"); //settle funding too early
        uint256 underlyingPrice;
        bool notPayable;
        (notPayable, premiumFractionLong, premiumFractionShort, fundingPayment, underlyingPrice) = getFundingPaymentEstimation(_cap);
        if (notPayable) {
            _implShutdown();
        }
        // positive fundingPayment is revenue to system, otherwise cost to system
        emit FundingRateUpdated(
            premiumFractionLong.divD(underlyingPrice.toInt()),
            premiumFractionShort.divD(underlyingPrice.toInt()),
            underlyingPrice,
            fundingPayment
        );

        // in order to prevent multiple funding settlement during very short time after network congestion
        uint256 minNextValidFundingTime = _blockTimestamp() + fundingBufferPeriod;

        // floor((nextFundingTime + fundingPeriod) / 3600) * 3600
        uint256 nextFundingTimeOnHourStart = ((nextFundingTime + fundingPeriod) / (1 hours)) * (1 hours);

        // max(nextFundingTimeOnHourStart, minNextValidFundingTime)
        nextFundingTime = nextFundingTimeOnHourStart > minNextValidFundingTime ? nextFundingTimeOnHourStart : minNextValidFundingTime;
    }

    /**
     * @notice check if repeg can be done and get the cost and reserves of formulaic repeg
     * @param _budget the budget available for repeg
     * @return isAdjustable if true, curve can be adjustable by repeg
     * @return cost the amount of cost of repeg, negative means profit of system
     * @return newQuoteAssetReserve the new quote asset reserve by repeg
     * @return newBaseAssetReserve the new base asset reserve by repeg
     */
    function repegCheck(uint256 _budget)
        external
        override
        onlyCounterParty
        returns (
            bool isAdjustable,
            int256 cost,
            uint256 newQuoteAssetReserve,
            uint256 newBaseAssetReserve
        )
    {
        if (open && adjustable) {
            uint256 _repegFlag = repegFlag;
            (bool result, uint256 marketPrice, uint256 oraclePrice) = isOverSpreadLimit();
            if (result) {
                _repegFlag += 1;
            } else {
                _repegFlag = 0;
            }
            int256 _positionSize = getBaseAssetDelta();
            uint256 targetPrice;
            if (_positionSize == 0) {
                targetPrice = oraclePrice;
            } else if (_repegFlag >= MIN_NUM_REPEG_FLAG) {
                targetPrice = oraclePrice > marketPrice
                    ? oraclePrice.mulD(1 ether - repegPriceGapRatio)
                    : oraclePrice.mulD(1 ether + repegPriceGapRatio);
            }
            if (targetPrice != 0) {
                uint256 _quoteAssetReserve = quoteAssetReserve; //to optimize gas cost
                uint256 _baseAssetReserve = baseAssetReserve; //to optimize gas cost
                (newQuoteAssetReserve, newBaseAssetReserve) = AmmMath.calcReservesAfterRepeg(
                    _quoteAssetReserve,
                    _baseAssetReserve,
                    targetPrice,
                    _positionSize
                );
                cost = AmmMath.calcCostForAdjustReserves(
                    _quoteAssetReserve,
                    _baseAssetReserve,
                    _positionSize,
                    newQuoteAssetReserve,
                    newBaseAssetReserve
                );
                if (cost > 0 && uint256(cost) > _budget) {
                    isAdjustable = false;
                } else {
                    isAdjustable = true;
                }
            }
            repegFlag = uint8(_repegFlag);
        }
    }

    /**
     * Repeg both reserves in case of repegging and k-adjustment
     */
    function adjust(uint256 _quoteAssetReserve, uint256 _baseAssetReserve) external onlyCounterParty {
        require(_quoteAssetReserve != 0, "AMM_ZQ"); //quote asset reserve cannot be 0
        require(_baseAssetReserve != 0, "AMM_ZB"); //base asset reserve cannot be 0
        quoteAssetReserve = _quoteAssetReserve;
        baseAssetReserve = _baseAssetReserve;
        _addReserveSnapshot();
        emit ReservesAdjusted(quoteAssetReserve, baseAssetReserve, getBaseAssetDelta(), cumulativeNotional);
    }

    /**
     * @notice shutdown amm,
     * @dev only `globalShutdown` or owner can call this function
     * The price calculation is in `globalShutdown`.
     */
    function shutdown() external override {
        require(_msgSender() == owner() || _msgSender() == globalShutdown, "AMM_NONG"); //not owner nor globalShutdown
        _implShutdown();
    }

    /**
     * @notice set init margin ratio, should be bigger than mm ratio
     * @dev only owner can call
     * @param _initMarginRatio new maintenance margin ratio in 18 digits
     */
    function setInitMarginRatio(uint256 _initMarginRatio) external onlyOwner {
        _requireNonZeroInput(_initMarginRatio);
        _requireRatio(_initMarginRatio);
        require(maintenanceMarginRatio < _initMarginRatio, "AMM_WIMR"); // wrong init margin ratio
        initMarginRatio = _initMarginRatio;
    }

    /**
     * @notice set maintenance margin ratio, should be smaller than initMarginRatio
     * @dev only owner can call
     * @param _maintenanceMarginRatio new maintenance margin ratio in 18 digits
     */
    function setMaintenanceMarginRatio(uint256 _maintenanceMarginRatio) external onlyOwner {
        _requireNonZeroInput(_maintenanceMarginRatio);
        _requireRatio(_maintenanceMarginRatio);
        require(_maintenanceMarginRatio < initMarginRatio, "AMM_WMMR"); // wrong maintenance margin ratio
        maintenanceMarginRatio = _maintenanceMarginRatio;
    }

    /**
     * @notice set liquidation fee ratio, shouldn't be bigger than mm ratio
     * @dev only owner can call
     * @param _liquidationFeeRatio new liquidation fee ratio in 18 digits
     */
    function setLiquidationFeeRatio(uint256 _liquidationFeeRatio) external onlyOwner {
        _requireNonZeroInput(_liquidationFeeRatio);
        _requireRatio(_liquidationFeeRatio);
        require(_liquidationFeeRatio <= maintenanceMarginRatio, "AMM_WLFR"); // wrong liquidation fee ratio
        liquidationFeeRatio = _liquidationFeeRatio;
    }

    /**
     * @notice set the margin ratio after deleveraging
     * @dev only owner can call
     */
    function setPartialLiquidationRatio(uint256 _ratio) external onlyOwner {
        _requireRatio(_ratio);
        partialLiquidationRatio = _ratio;
    }

    /**
     * @notice set counter party
     * @dev only owner can call this function
     * @param _counterParty address of counter party
     */
    function setCounterParty(address _counterParty) external onlyOwner {
        _requireNonZeroAddress(_counterParty);
        counterParty = _counterParty;
    }

    /**
     * @notice set `globalShutdown`
     * @dev only owner can call this function
     * @param _globalShutdown address of `globalShutdown`
     */
    function setGlobalShutdown(address _globalShutdown) external onlyOwner {
        _requireNonZeroAddress(_globalShutdown);
        globalShutdown = _globalShutdown;
    }

    /**
     * @notice set fluctuation limit rate. Default value is `1 / max leverage`
     * @dev only owner can call this function
     * @param _fluctuationLimitRatio fluctuation limit rate in 18 digits, 0 means skip the checking
     */
    function setFluctuationLimitRatio(uint256 _fluctuationLimitRatio) external onlyOwner {
        _requireRatio(_fluctuationLimitRatio);
        fluctuationLimitRatio = _fluctuationLimitRatio;
    }

    /**
     * @notice set time interval for twap calculation, default is 1 hour
     * @dev only owner can call this function
     * @param _interval time interval in seconds
     */
    function setSpotPriceTwapInterval(uint256 _interval) external onlyOwner {
        require(_interval != 0, "AMM_ZI"); // zero interval
        require(_interval <= 24 * 3600, "AMM_GTO"); // greater than 1 day
        spotPriceTwapInterval = _interval;
    }

    /**
     * @notice set `open` flag. Amm is open to trade if `open` is true. Default is false.
     * @dev only owner can call this function
     * @param _open open to trade is true, otherwise is false.
     */
    function setOpen(bool _open) external onlyOwner {
        if (open == _open) return;

        open = _open;
        if (_open) {
            nextFundingTime = ((_blockTimestamp() + fundingPeriod) / (1 hours)) * (1 hours);
        }
    }

    /**
     * @notice set `adjustable` flag. Amm is open to formulaic repeg and K adjustment if `adjustable` is true. Default is false.
     * @dev only owner can call this function
     * @param _adjustable open to formulaic repeg and K adjustment is true, otherwise is false.
     */
    function setAdjustable(bool _adjustable) external onlyOwner {
        if (adjustable == _adjustable) return;
        adjustable = _adjustable;
    }

    /**
     * @notice set `canLowerK` flag. Amm is open to decrease K adjustment if `canLowerK` is true. Default is false.
     * @dev only owner can call this function
     * @param _canLowerK open to decrease K adjustment is true, otherwise is false.
     */
    function setCanLowerK(bool _canLowerK) external onlyOwner {
        if (canLowerK == _canLowerK) return;
        canLowerK = _canLowerK;
    }

    /**
     * @notice set new toll ratio
     * @dev only owner can call
     * @param _tollRatio new toll ratio in 18 digits
     */
    function setTollRatio(uint256 _tollRatio) external onlyOwner {
        _requireRatio(_tollRatio);
        tollRatio = _tollRatio;
    }

    /**
     * @notice set new spread ratio
     * @dev only owner can call
     * @param _spreadRatio new toll spread in 18 digits
     */
    function setSpreadRatio(uint256 _spreadRatio) external onlyOwner {
        _requireRatio(_spreadRatio);
        spreadRatio = _spreadRatio;
    }

    /**
     * @notice set priceFee address
     * @dev only owner can call
     * @param _priceFeed new price feed for this AMM
     */
    function setPriceFeed(IPriceFeed _priceFeed) external onlyOwner {
        _requireNonZeroAddress(address(_priceFeed));
        priceFeed = _priceFeed;
        emit PriceFeedUpdated(address(priceFeed));
    }

    function setRepegPriceGapRatio(uint256 _ratio) external onlyOwner {
        _requireRatio(_ratio);
        repegPriceGapRatio = _ratio;
    }

    function setFundingCostCoverRate(uint256 _rate) external onlyOwner {
        _requireRatio(_rate);
        fundingCostCoverRate = _rate;
    }

    function setFundingRevenueTakeRate(uint256 _rate) external onlyOwner {
        _requireRatio(_rate);
        fundingRevenueTakeRate = _rate;
    }

    function setKIncreaseMax(uint256 _rate) external onlyOwner {
        require(_rate > 1 ether, "AMM_IIR"); // invalid increase ratio
        ptcKIncreaseMax = _rate;
    }

    function setKDecreaseMax(uint256 _rate) external onlyOwner {
        require(_rate < 1 ether && _rate > 0, "AMM_IDR"); // invalid decrease ratio
        ptcKDecreaseMax = _rate;
    }

    //
    // VIEW FUNCTIONS
    //

    /**
     * @notice get the cost and reserves when adjust k
     * @param _budget the budget available for adjust
     * @return isAdjustable if true, curve can be adjustable by adjust k
     * @return cost the amount of cost of adjust k
     * @return newQuoteAssetReserve the new quote asset reserve by adjust k
     * @return newBaseAssetReserve the new base asset reserve by adjust k
     */

    function getFormulaicUpdateKResult(int256 _budget)
        external
        view
        returns (
            bool isAdjustable,
            int256 cost,
            uint256 newQuoteAssetReserve,
            uint256 newBaseAssetReserve
        )
    {
        if (open && adjustable && (_budget > 0 || (_budget < 0 && canLowerK))) {
            uint256 _quoteAssetReserve = quoteAssetReserve; //to optimize gas cost
            uint256 _baseAssetReserve = baseAssetReserve; //to optimize gas cost
            int256 _positionSize = getBaseAssetDelta(); //to optimize gas cost
            (uint256 scaleNum, uint256 scaleDenom) = AmmMath.calculateBudgetedKScale(
                AmmMath.BudgetedKScaleCalcParams({
                    quoteAssetReserve: _quoteAssetReserve,
                    baseAssetReserve: _baseAssetReserve,
                    budget: _budget,
                    positionSize: _positionSize,
                    ptcKIncreaseMax: ptcKIncreaseMax,
                    ptcKDecreaseMax: ptcKDecreaseMax
                })
            );
            if (scaleNum == scaleDenom || scaleDenom == 0 || scaleNum == 0) {
                isAdjustable = false;
            } else {
                newQuoteAssetReserve = Math.mulDiv(_quoteAssetReserve, scaleNum, scaleDenom);
                newBaseAssetReserve = Math.mulDiv(_baseAssetReserve, scaleNum, scaleDenom);
                isAdjustable = _positionSize >= 0 || newBaseAssetReserve > _positionSize.abs();
                if (isAdjustable) {
                    cost = AmmMath.calcCostForAdjustReserves(
                        _quoteAssetReserve,
                        _baseAssetReserve,
                        _positionSize,
                        newQuoteAssetReserve,
                        newBaseAssetReserve
                    );
                }
            }
        }
    }

    function getMaxKDecreaseRevenue(uint256 _quoteAssetReserve, uint256 _baseAssetReserve) external view override returns (int256 revenue) {
        if (open && adjustable && canLowerK) {
            uint256 _ptcKDecreaseMax = ptcKDecreaseMax;
            int256 _positionSize = getBaseAssetDelta();
            if (_positionSize >= 0 || _baseAssetReserve.mulD(_ptcKDecreaseMax) > _positionSize.abs()) {
                // decreasing cost is always negative (profit)
                revenue =
                    (-1) *
                    AmmMath.calcCostForAdjustReserves(
                        _quoteAssetReserve,
                        _baseAssetReserve,
                        _positionSize,
                        _quoteAssetReserve.mulD(_ptcKDecreaseMax),
                        _baseAssetReserve.mulD(_ptcKDecreaseMax)
                    );
            }
        }
    }

    function isOverFluctuationLimit(Dir _dirOfBase, uint256 _baseAssetAmount) external view override returns (bool) {
        // Skip the check if the limit is 0
        if (fluctuationLimitRatio == 0) {
            return false;
        }

        (uint256 upperLimit, uint256 lowerLimit) = _getPriceBoundariesOfLastBlock();

        uint256 quoteAssetExchanged = getBasePrice(_dirOfBase, _baseAssetAmount);
        uint256 price = (_dirOfBase == Dir.REMOVE_FROM_AMM)
            ? (quoteAssetReserve + quoteAssetExchanged).divD(baseAssetReserve - _baseAssetAmount)
            : (quoteAssetReserve - quoteAssetExchanged).divD(baseAssetReserve + _baseAssetAmount);

        if (price <= upperLimit && price >= lowerLimit) {
            return false;
        }
        return true;
    }

    /**
     * @notice get input twap amount.
     * returns how many base asset you will get with the input quote amount based on twap price.
     * @param _dirOfQuote ADD_TO_AMM for long, REMOVE_FROM_AMM for short.
     * @param _quoteAssetAmount quote asset amount
     * @return base asset amount
     */
    function getQuoteTwap(Dir _dirOfQuote, uint256 _quoteAssetAmount) public view override returns (uint256) {
        return _implGetInputAssetTwapPrice(_dirOfQuote, _quoteAssetAmount, QuoteAssetDir.QUOTE_IN, 15 minutes);
    }

    /**
     * @notice get output twap amount.
     * return how many quote asset you will get with the input base amount on twap price.
     * @param _dirOfBase ADD_TO_AMM for short, REMOVE_FROM_AMM for long, opposite direction from `getQuoteTwap`.
     * @param _baseAssetAmount base asset amount
     * @return quote asset amount
     */
    function getBaseTwap(Dir _dirOfBase, uint256 _baseAssetAmount) public view override returns (uint256) {
        return _implGetInputAssetTwapPrice(_dirOfBase, _baseAssetAmount, QuoteAssetDir.QUOTE_OUT, 15 minutes);
    }

    /**
     * @notice get input amount. returns how many base asset you will get with the input quote amount.
     * @param _dirOfQuote ADD_TO_AMM for long, REMOVE_FROM_AMM for short.
     * @param _quoteAssetAmount quote asset amount
     * @return base asset amount
     */
    function getQuotePrice(Dir _dirOfQuote, uint256 _quoteAssetAmount) public view override returns (uint256) {
        return getQuotePriceWithReserves(_dirOfQuote, _quoteAssetAmount, quoteAssetReserve, baseAssetReserve);
    }

    /**
     * @notice get output price. return how many quote asset you will get with the input base amount
     * @param _dirOfBase ADD_TO_AMM for short, REMOVE_FROM_AMM for long, opposite direction from `getInput`.
     * @param _baseAssetAmount base asset amount
     * @return quote asset amount
     */
    function getBasePrice(Dir _dirOfBase, uint256 _baseAssetAmount) public view override returns (uint256) {
        return getBasePriceWithReserves(_dirOfBase, _baseAssetAmount, quoteAssetReserve, baseAssetReserve);
    }

    /**
     * @notice get underlying price provided by oracle
     * @return underlying price
     */
    function getUnderlyingPrice() public view override returns (uint256) {
        return uint256(priceFeed.getPrice(priceFeedKey));
    }

    /**
     * @notice get underlying twap price provided by oracle
     * @return underlying price
     */
    function getUnderlyingTwapPrice(uint256 _intervalInSeconds) public view returns (uint256) {
        return uint256(priceFeed.getTwapPrice(priceFeedKey, _intervalInSeconds));
    }

    /**
     * @notice get spot price based on current quote/base asset reserve.
     * @return spot price
     */
    function getSpotPrice() public view override returns (uint256) {
        return quoteAssetReserve.divD(baseAssetReserve);
    }

    /**
     * @notice get twap price
     */
    function getTwapPrice(uint256 _intervalInSeconds) public view returns (uint256) {
        return _calcTwap(_intervalInSeconds);
    }

    /**
     * @notice get current quote/base asset reserve.
     * @return (quote asset reserve, base asset reserve)
     */
    function getReserve() public view returns (uint256, uint256) {
        return (quoteAssetReserve, baseAssetReserve);
    }

    function getCumulativeNotional() public view override returns (int256) {
        return cumulativeNotional;
    }

    function getSettlementPrice() public view override returns (uint256) {
        return settlementPrice;
    }

    function getBaseAssetDelta() public view override returns (int256) {
        return longPositionSize.toInt() - shortPositionSize.toInt();
    }

    function isOverSpreadLimit()
        public
        view
        override
        returns (
            bool result,
            uint256 marketPrice,
            uint256 oraclePrice
        )
    {
        (result, marketPrice, oraclePrice) = isOverSpread(MAX_ORACLE_SPREAD_RATIO);
    }

    function isOverSpread(uint256 _limit)
        public
        view
        virtual
        override
        returns (
            bool result,
            uint256 marketPrice,
            uint256 oraclePrice
        )
    {
        oraclePrice = getUnderlyingPrice();
        require(oraclePrice > 0, "AMM_ZOP"); //zero oracle price
        marketPrice = getSpotPrice();
        uint256 oracleSpreadRatioAbs = (marketPrice.toInt() - oraclePrice.toInt()).divD(oraclePrice.toInt()).abs();

        result = oracleSpreadRatioAbs >= _limit ? true : false;
    }

    /**
     * @notice calculate total fee (including toll and spread) by input quoteAssetAmount
     * @param _quoteAssetAmount quoteAssetAmount
     * @return total tx fee
     */
    function calcFee(uint256 _quoteAssetAmount) public view override returns (uint256, uint256) {
        return (_quoteAssetAmount.mulD(tollRatio), _quoteAssetAmount.mulD(spreadRatio));
    }

    /*       plus/minus 1 while the amount is not dividable
     *
     *        getQuotePrice                         getBasePrice
     *
     *     ＡＤＤ      (amount - 1)              (amount + 1)   ＲＥＭＯＶＥ
     *      ◥◤            ▲                         |             ◢◣
     *      ◥◤  ------->  |                         ▼  <--------  ◢◣
     *    -------      -------                   -------        -------
     *    |  Q  |      |  B  |                   |  Q  |        |  B  |
     *    -------      -------                   -------        -------
     *      ◥◤  ------->  ▲                         |  <--------  ◢◣
     *      ◥◤            |                         ▼             ◢◣
     *   ＲＥＭＯＶＥ  (amount + 1)              (amount - 1)      ＡＤＤ
     **/

    function getQuotePriceWithReserves(
        Dir _dirOfQuote,
        uint256 _quoteAssetAmount,
        uint256 _quoteAssetPoolAmount,
        uint256 _baseAssetPoolAmount
    ) public pure override returns (uint256) {
        if (_quoteAssetAmount == 0) {
            return 0;
        }

        bool isAddToAmm = _dirOfQuote == Dir.ADD_TO_AMM;
        uint256 baseAssetAfter;
        uint256 quoteAssetAfter;
        uint256 baseAssetBought;
        if (isAddToAmm) {
            quoteAssetAfter = _quoteAssetPoolAmount + _quoteAssetAmount;
        } else {
            quoteAssetAfter = _quoteAssetPoolAmount - _quoteAssetAmount;
        }
        require(quoteAssetAfter != 0, "AMM_ZQAA"); //zero quote asset after

        baseAssetAfter = Math.mulDiv(_quoteAssetPoolAmount, _baseAssetPoolAmount, quoteAssetAfter, Math.Rounding.Up);
        baseAssetBought = (baseAssetAfter.toInt() - _baseAssetPoolAmount.toInt()).abs();

        return baseAssetBought;
    }

    function getBasePriceWithReserves(
        Dir _dirOfBase,
        uint256 _baseAssetAmount,
        uint256 _quoteAssetPoolAmount,
        uint256 _baseAssetPoolAmount
    ) public pure override returns (uint256) {
        if (_baseAssetAmount == 0) {
            return 0;
        }

        bool isAddToAmm = _dirOfBase == Dir.ADD_TO_AMM;
        uint256 quoteAssetAfter;
        uint256 baseAssetAfter;
        uint256 quoteAssetSold;

        if (isAddToAmm) {
            baseAssetAfter = _baseAssetPoolAmount + _baseAssetAmount;
        } else {
            baseAssetAfter = _baseAssetPoolAmount - _baseAssetAmount;
        }
        require(baseAssetAfter != 0, "AMM_ZBAA"); //zero base asset after

        quoteAssetAfter = Math.mulDiv(_quoteAssetPoolAmount, _baseAssetPoolAmount, baseAssetAfter, Math.Rounding.Up);
        quoteAssetSold = (quoteAssetAfter.toInt() - _quoteAssetPoolAmount.toInt()).abs();

        return quoteAssetSold;
    }

    function getFundingPaymentEstimation(uint256 _cap)
        public
        view
        override
        returns (
            bool notPayable,
            int256 premiumFractionLong,
            int256 premiumFractionShort,
            int256 fundingPayment,
            uint256 underlyingPrice
        )
    {
        // premium = twapMarketPrice - twapIndexPrice
        // timeFraction = fundingPeriod(3 hour) / 1 day
        // premiumFraction = premium * timeFraction
        underlyingPrice = getUnderlyingTwapPrice(spotPriceTwapInterval);
        int256 premiumFraction = ((getTwapPrice(spotPriceTwapInterval).toInt() - underlyingPrice.toInt()) * fundingPeriod.toInt()) /
            int256(1 days);
        int256 positionSize = getBaseAssetDelta();
        // funding payment = premium fraction * position
        // eg. if alice takes 10 long position, totalPositionSize = 10
        // if premiumFraction is positive: long pay short, amm get positive funding payment
        // if premiumFraction is negative: short pay long, amm get negative funding payment
        // if totalPositionSize.side * premiumFraction > 0, funding payment is positive which means profit
        int256 normalFundingPayment = premiumFraction.mulD(positionSize);

        // dynamic funding rate formula
        // premiumFractionLong  = premiumFraction * (2*shortSize + a*positionSize) / (longSize + shortSize)
        // premiumFractionShort = premiumFraction * (2*longSize  - a*positionSize) / (longSize + shortSize)
        int256 _longPositionSize = int256(longPositionSize);
        int256 _shortPositionSize = int256(shortPositionSize);
        int256 _fundingRevenueTakeRate = int256(fundingRevenueTakeRate);
        int256 _fundingCostCoverRate = int256(fundingCostCoverRate);

        if (normalFundingPayment > 0 && _fundingRevenueTakeRate < 1 ether && _longPositionSize + _shortPositionSize != 0) {
            // when the normal funding payment is revenue and daynamic rate is available, system takes profit partially
            fundingPayment = normalFundingPayment.mulD(_fundingRevenueTakeRate);
            int256 sign = premiumFraction >= 0 ? int256(1) : int256(-1);
            premiumFractionLong =
                int256(
                    Math.mulDiv(
                        premiumFraction.abs(),
                        uint256(_shortPositionSize * 2 + positionSize.mulD(_fundingRevenueTakeRate)),
                        uint256(_longPositionSize + _shortPositionSize)
                    )
                ) *
                sign;
            premiumFractionShort =
                int256(
                    Math.mulDiv(
                        premiumFraction.abs(),
                        uint256(_longPositionSize * 2 - positionSize.mulD(_fundingRevenueTakeRate)),
                        uint256(_longPositionSize + _shortPositionSize)
                    )
                ) *
                sign;
        } else if (normalFundingPayment < 0 && _fundingCostCoverRate < 1 ether && _longPositionSize + _shortPositionSize != 0) {
            // when the normal funding payment is cost and daynamic rate is available, system covers partially
            fundingPayment = normalFundingPayment.mulD(_fundingCostCoverRate);
            int256 sign = premiumFraction >= 0 ? int256(1) : int256(-1);
            if (uint256(-fundingPayment) > _cap) {
                // when the funding payment that system covers is greater than the cap, then not pay funding and shutdown amm
                fundingPayment = 0;
                notPayable = true;
            } else {
                premiumFractionLong =
                    int256(
                        Math.mulDiv(
                            premiumFraction.abs(),
                            uint256(_shortPositionSize * 2 + positionSize.mulD(_fundingCostCoverRate)),
                            uint256(_longPositionSize + _shortPositionSize)
                        )
                    ) *
                    sign;
                premiumFractionShort =
                    int256(
                        Math.mulDiv(
                            premiumFraction.abs(),
                            uint256(_longPositionSize * 2 - positionSize.mulD(_fundingCostCoverRate)),
                            uint256(_longPositionSize + _shortPositionSize)
                        )
                    ) *
                    sign;
            }
        } else {
            fundingPayment = normalFundingPayment;
            // if expense of funding payment is greater than cap amount, then not pay funding and shutdown amm
            if (fundingPayment < 0 && uint256(-fundingPayment) > _cap) {
                fundingPayment = 0;
                notPayable = true;
            } else {
                premiumFractionLong = premiumFraction;
                premiumFractionShort = premiumFraction;
            }
        }
    }

    function _addReserveSnapshot() internal {
        uint256 currentBlock = _blockNumber();
        uint16 _latestReserveSnapshotIndex = latestReserveSnapshotIndex;
        ReserveSnapshot storage latestSnapshot = reserveSnapshots[_latestReserveSnapshotIndex];
        // update values in snapshot if in the same block
        if (currentBlock == latestSnapshot.blockNumber) {
            latestSnapshot.quoteAssetReserve = quoteAssetReserve;
            latestSnapshot.baseAssetReserve = baseAssetReserve;
        } else {
            // _latestReserveSnapshotIndex is uint16, so overflow means 65535+1=0
            unchecked {
                _latestReserveSnapshotIndex++;
            }
            latestReserveSnapshotIndex = _latestReserveSnapshotIndex;
            reserveSnapshots[_latestReserveSnapshotIndex] = ReserveSnapshot(
                quoteAssetReserve,
                baseAssetReserve,
                latestSnapshot.cumulativeTWPBefore +
                    latestSnapshot.quoteAssetReserve.divD(latestSnapshot.baseAssetReserve) *
                    (_blockTimestamp() - latestSnapshot.timestamp),
                _blockTimestamp(),
                currentBlock
            );
        }
        emit ReserveSnapshotted(quoteAssetReserve, baseAssetReserve, _blockTimestamp());
    }

    // the direction is in quote asset
    function _updateReserve(
        Dir _dirOfQuote,
        uint256 _quoteAssetAmount,
        uint256 _baseAssetAmount,
        bool _canOverFluctuationLimit
    ) internal {
        uint256 _quoteAssetReserve = quoteAssetReserve;
        uint256 _baseAssetReserve = baseAssetReserve;
        // check if it's over fluctuationLimitRatio
        // this check should be before reserves being updated
        _checkIsOverBlockFluctuationLimit(
            _dirOfQuote,
            _quoteAssetAmount,
            _baseAssetAmount,
            _quoteAssetReserve,
            _baseAssetReserve,
            _canOverFluctuationLimit
        );

        if (_dirOfQuote == Dir.ADD_TO_AMM) {
            require(_baseAssetReserve.mulD(tradeLimitRatio) >= _baseAssetAmount, "AMM_OTL"); //over trading limit
            quoteAssetReserve = _quoteAssetReserve + _quoteAssetAmount;
            baseAssetReserve = _baseAssetReserve - _baseAssetAmount;
            cumulativeNotional = cumulativeNotional + _quoteAssetAmount.toInt();
        } else {
            require(_quoteAssetReserve.mulD(tradeLimitRatio) >= _quoteAssetAmount, "AMM_OTL"); //over trading limit
            quoteAssetReserve = _quoteAssetReserve - _quoteAssetAmount;
            baseAssetReserve = _baseAssetReserve + _baseAssetAmount;
            cumulativeNotional = cumulativeNotional - _quoteAssetAmount.toInt();
        }

        // _addReserveSnapshot must be after checking price fluctuation
        _addReserveSnapshot();
    }

    function _implGetInputAssetTwapPrice(
        Dir _dirOfQuote,
        uint256 _assetAmount,
        QuoteAssetDir _inOut,
        uint256 _interval
    ) internal view returns (uint256) {
        TwapPriceCalcParams memory params;
        params.snapshotIndex = latestReserveSnapshotIndex;
        params.asset.dir = _dirOfQuote;
        params.asset.assetAmount = _assetAmount;
        params.asset.inOrOut = _inOut;
        return _calcAssetTwap(params, _interval);
    }

    function _calcAssetTwap(TwapPriceCalcParams memory _params, uint256 _interval) internal view returns (uint256) {
        uint256 baseTimestamp = _blockTimestamp() - _interval;
        uint256 previousTimestamp = _blockTimestamp();
        uint256 i;
        ReserveSnapshot memory currentSnapshot;
        uint256 currentPrice;
        uint256 period;
        uint256 weightedPrice;
        uint256 timeFraction;
        // runs at most 900, due to have 15mins interval
        for (i; i < 65536; ) {
            currentSnapshot = reserveSnapshots[_params.snapshotIndex];
            // not enough history
            if (currentSnapshot.timestamp == 0) {
                return period == 0 ? currentPrice : weightedPrice / period;
            }
            currentPrice = _getAssetPriceWithSpecificSnapshot(currentSnapshot, _params);

            // check if current round timestamp is earlier than target timestamp
            if (currentSnapshot.timestamp <= baseTimestamp) {
                // weighted time period will be (target timestamp - previous timestamp). For example,
                // now is 1000, _interval is 100, then target timestamp is 900. If timestamp of current round is 970,
                // and timestamp of NEXT round is 880, then the weighted time period will be (970 - 900) = 70,
                // instead of (970 - 880)
                weightedPrice = weightedPrice + (currentPrice * (previousTimestamp - baseTimestamp));
                break;
            }
            timeFraction = previousTimestamp - currentSnapshot.timestamp;
            weightedPrice = weightedPrice + (currentPrice * timeFraction);
            period = period + timeFraction;
            previousTimestamp = currentSnapshot.timestamp;
            unchecked {
                _params.snapshotIndex = _params.snapshotIndex - 1;
                i++;
            }
        }
        // if snapshot history is too short
        if (i == 256) {
            return weightedPrice / period;
        } else {
            return weightedPrice / _interval;
        }
    }

    function _getAssetPriceWithSpecificSnapshot(ReserveSnapshot memory snapshot, TwapPriceCalcParams memory params)
        internal
        pure
        virtual
        returns (uint256)
    {
        if (params.asset.assetAmount == 0) {
            return 0;
        }
        if (params.asset.inOrOut == QuoteAssetDir.QUOTE_IN) {
            return
                getQuotePriceWithReserves(
                    params.asset.dir,
                    params.asset.assetAmount,
                    snapshot.quoteAssetReserve,
                    snapshot.baseAssetReserve
                );
        } else if (params.asset.inOrOut == QuoteAssetDir.QUOTE_OUT) {
            return
                getBasePriceWithReserves(params.asset.dir, params.asset.assetAmount, snapshot.quoteAssetReserve, snapshot.baseAssetReserve);
        }
        revert("AMM_NOMP"); //not supported option for market price for a specific snapshot
    }

    function _calcTwap(uint256 interval) internal view returns (uint256) {
        ReserveSnapshot memory latestSnapshot = reserveSnapshots[latestReserveSnapshotIndex];
        uint256 currentTimestamp = _blockTimestamp();
        uint256 targetTimestamp = currentTimestamp - interval;
        ReserveSnapshot memory beforeOrAt = _getBeforeOrAtReserveSnapshots(targetTimestamp);
        uint256 currentCumulativePrice = latestSnapshot.cumulativeTWPBefore +
            latestSnapshot.quoteAssetReserve.divD(latestSnapshot.baseAssetReserve) *
            (currentTimestamp - latestSnapshot.timestamp);

        //
        //                   beforeOrAt
        //      ------------------+-------------+---------------
        //                <-------|             |
        // case 1       targetTimestamp         |
        // case 2                          targetTimestamp
        //
        uint256 targetCumulativePrice;
        // case1. not enough historical data or just enough (`==` case)
        if (targetTimestamp <= beforeOrAt.timestamp) {
            targetTimestamp = beforeOrAt.timestamp;
            targetCumulativePrice = beforeOrAt.cumulativeTWPBefore;
        }
        // case2. enough historical data
        else {
            uint256 targetTimeDelta = targetTimestamp - beforeOrAt.timestamp;
            targetCumulativePrice =
                beforeOrAt.cumulativeTWPBefore +
                beforeOrAt.quoteAssetReserve.divD(beforeOrAt.baseAssetReserve) *
                targetTimeDelta;
        }
        if (currentTimestamp == targetTimestamp) {
            return beforeOrAt.quoteAssetReserve.divD(beforeOrAt.baseAssetReserve);
        } else {
            return (currentCumulativePrice - targetCumulativePrice) / (currentTimestamp - targetTimestamp);
        }
    }

    /**
     * @dev searches the reserve snapshot array and returns the snapshot of which timestamp is just before or equals to the target timestamp
     * if no such one exists, returns the oldest snapshot
     * time complexity O(log n) due to binary search algorithm, max len of array is 2**16, so max loops is 16
     */
    function _getBeforeOrAtReserveSnapshots(uint256 targetTimestamp) internal view returns (ReserveSnapshot memory beforeOrAt) {
        uint256 _latestReserveSnapshotIndex = uint256(latestReserveSnapshotIndex);
        uint256 low = _latestReserveSnapshotIndex + 1;
        uint256 high = _latestReserveSnapshotIndex | (uint256(1) << 16);
        uint256 mid;
        if (reserveSnapshots[uint16(low)].timestamp == 0) {
            low = 0;
            high = high ^ (uint256(1) << 16);
        }

        while (low < high) {
            unchecked {
                mid = (low + high) / 2;
            }

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because it is derived from integer division.
            if (reserveSnapshots[uint16(mid)].timestamp > targetTimestamp) {
                high = mid;
            } else {
                unchecked {
                    low = mid + 1;
                }
            }
        }

        if (low > 0 && low != _latestReserveSnapshotIndex + 1 && reserveSnapshots[uint16(low)].timestamp > targetTimestamp) {
            beforeOrAt = reserveSnapshots[uint16(low - 1)];
        } else {
            beforeOrAt = reserveSnapshots[uint16(low)];
        }
    }

    function _getPriceBoundariesOfLastBlock() internal view returns (uint256, uint256) {
        uint16 _latestReserveSnapshotIndex = latestReserveSnapshotIndex;
        ReserveSnapshot memory latestSnapshot = reserveSnapshots[_latestReserveSnapshotIndex];
        // if the latest snapshot is the same as current block and it is not the initial snapshot, get the previous one
        if (latestSnapshot.blockNumber == _blockNumber()) {
            // underflow means 0-1=65535
            unchecked {
                _latestReserveSnapshotIndex--;
            }
            if (reserveSnapshots[_latestReserveSnapshotIndex].timestamp != 0)
                latestSnapshot = reserveSnapshots[_latestReserveSnapshotIndex];
        }

        uint256 lastPrice = latestSnapshot.quoteAssetReserve.divD(latestSnapshot.baseAssetReserve);
        uint256 upperLimit = lastPrice.mulD(1 ether + fluctuationLimitRatio);
        uint256 lowerLimit = lastPrice.mulD(1 ether - fluctuationLimitRatio);
        return (upperLimit, lowerLimit);
    }

    /**
     * @notice there can only be one tx in a block can skip the fluctuation check
     *         otherwise, some positions can never be closed or liquidated
     * @param _canOverFluctuationLimit if true, can skip fluctuation check for once; else, can never skip
     */
    function _checkIsOverBlockFluctuationLimit(
        Dir _dirOfQuote,
        uint256 _quoteAssetAmount,
        uint256 _baseAssetAmount,
        uint256 _quoteAssetReserve,
        uint256 _baseAssetReserve,
        bool _canOverFluctuationLimit
    ) internal view {
        // Skip the check if the limit is 0
        if (fluctuationLimitRatio == 0) {
            return;
        }

        //
        // assume the price of the last block is 10, fluctuation limit ratio is 5%, then
        //
        //          current price
        //  --+---------+-----------+---
        //   9.5        10         10.5
        // lower limit           upper limit
        //
        // when `openPosition`, the price can only be between 9.5 - 10.5
        // when `liquidate` and `closePosition`, the price can exceed the boundary once
        // (either lower than 9.5 or higher than 10.5)
        // once it exceeds the boundary, all the rest txs in this block fail
        //

        (uint256 upperLimit, uint256 lowerLimit) = _getPriceBoundariesOfLastBlock();

        uint256 price = _quoteAssetReserve.divD(_baseAssetReserve);
        require(price <= upperLimit && price >= lowerLimit, "AMM_POFL"); //price is already over fluctuation limit

        if (!_canOverFluctuationLimit) {
            price = (_dirOfQuote == Dir.ADD_TO_AMM)
                ? (_quoteAssetReserve + _quoteAssetAmount).divD(_baseAssetReserve - _baseAssetAmount)
                : (_quoteAssetReserve - _quoteAssetAmount).divD(_baseAssetReserve + _baseAssetAmount);
            require(price <= upperLimit && price >= lowerLimit, "AMM_POFL"); //price is over fluctuation limit
        }
    }

    function _implShutdown() internal {
        uint256 _quoteAssetReserve = quoteAssetReserve;
        uint256 _baseAssetReserve = baseAssetReserve;
        int256 _totalPositionSize = getBaseAssetDelta();
        uint256 initBaseReserve = (_totalPositionSize + _baseAssetReserve.toInt()).abs();
        if (initBaseReserve > IGNORABLE_DIGIT_FOR_SHUTDOWN) {
            uint256 initQuoteReserve = Math.mulDiv(_quoteAssetReserve, _baseAssetReserve, initBaseReserve);
            int256 positionNotionalValue = initQuoteReserve.toInt() - _quoteAssetReserve.toInt();
            // if total position size less than IGNORABLE_DIGIT_FOR_SHUTDOWN, treat it as 0 positions due to rounding error
            if (_totalPositionSize.toUint() > IGNORABLE_DIGIT_FOR_SHUTDOWN) {
                settlementPrice = positionNotionalValue.abs().divD(_totalPositionSize.abs());
            }
        }
        open = false;
        emit Shutdown(settlementPrice);
    }

    function _requireRatio(uint256 _ratio) private pure {
        require(_ratio <= 1 ether, "AMM_IR"); //invalid ratio
    }

    function _requireNonZeroAddress(address _input) private pure {
        require(_input != address(0), "AMM_ZA");
    }

    function _requireNonZeroInput(uint256 _input) private pure {
        require(_input != 0, "AMM_ZI"); //zero input
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract OwnableUpgradeableSafe is OwnableUpgradeable {
    function renounceOwnership() public view override onlyOwner {
        revert("OS_NR"); // not able to renounce
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

interface IPriceFeed {
    // get latest price
    function getPrice(bytes32 _priceFeedKey) external view returns (uint256);

    // get latest timestamp
    function getLatestTimestamp(bytes32 _priceFeedKey) external view returns (uint256);

    // get previous price with _back rounds
    function getPreviousPrice(bytes32 _priceFeedKey, uint256 _numOfRoundBack) external view returns (uint256);

    // get previous timestamp with _back rounds
    function getPreviousTimestamp(bytes32 _priceFeedKey, uint256 _numOfRoundBack) external view returns (uint256);

    // get twap price depending on _period
    function getTwapPrice(bytes32 _priceFeedKey, uint256 _interval) external view returns (uint256);

    function setLatestData(
        bytes32 _priceFeedKey,
        uint256 _price,
        uint256 _timestamp,
        uint256 _roundId
    ) external;

    function decimals(bytes32 _priceFeedKey) external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

// wrap block.xxx functions for testing
// only support timestamp and number so far
abstract contract BlockContext {
    //◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤ add state variables below ◥◤◥◤◥◤◥◤◥◤◥◤◥◤◥◤//

    //◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣ add state variables above ◢◣◢◣◢◣◢◣◢◣◢◣◢◣◢◣//
    uint256[50] private __gap;

    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function _blockNumber() internal view virtual returns (uint256) {
        return block.number;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/// @dev Implements simple signed fixed point math add, sub, mul and div operations.
library IntMath {
    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (int256) {
        return int256(10**uint256(decimals));
    }

    function toUint(int256 x) internal pure returns (uint256) {
        return uint256(abs(x));
    }

    function abs(int256 x) internal pure returns (uint256) {
        uint256 t = 0;
        if (x < 0) {
            t = uint256(0 - x);
        } else {
            t = uint256(x);
        }
        return t;
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function mulD(int256 x, int256 y) internal pure returns (int256) {
        return mulD(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function mulD(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        if (x == 0 || y == 0) {
            return 0;
        }
        if (x * y < 0) {
            return int256(Math.mulDiv(abs(x), abs(y), 10**uint256(decimals))) * (-1);
        } else {
            return int256(Math.mulDiv(abs(x), abs(y), 10**uint256(decimals)));
        }
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divD(int256 x, int256 y) internal pure returns (int256) {
        return divD(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divD(
        int256 x,
        int256 y,
        uint8 decimals
    ) internal pure returns (int256) {
        if (x == 0 || y == 0) {
            return 0;
        }
        if (x * y < 0) {
            return int256(Math.mulDiv(abs(x), 10**uint256(decimals), abs(y))) * (-1);
        } else {
            return int256(Math.mulDiv(abs(x), 10**uint256(decimals), abs(y)));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

/// @dev Implements simple fixed point math add, sub, mul and div operations.
library UIntMath {
    string private constant ERROR_NON_CONVERTIBLE = "Math: uint value is bigger than _INT256_MAX";

    /// @dev Returns 1 in the fixed point representation, with `decimals` decimals.
    function unit(uint8 decimals) internal pure returns (uint256) {
        return 10**uint256(decimals);
    }

    function toInt(uint256 x) internal pure returns (int256) {
        require(uint256(type(int256).max) >= x, ERROR_NON_CONVERTIBLE);
        return int256(x);
    }

    // function modD(uint256 x, uint256 y) internal pure returns (uint256) {
    //     return (x * unit(18)) % y;
    // }

    /// @dev Multiplies x and y, assuming they are both fixed point with 18 digits.
    function mulD(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulD(x, y, 18);
    }

    /// @dev Multiplies x and y, assuming they are both fixed point with `decimals` digits.
    function mulD(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return Math.mulDiv(x, y, unit(decimals));
    }

    /// @dev Divides x between y, assuming they are both fixed point with 18 digits.
    function divD(uint256 x, uint256 y) internal pure returns (uint256) {
        return divD(x, y, 18);
    }

    /// @dev Divides x between y, assuming they are both fixed point with `decimals` digits.
    function divD(
        uint256 x,
        uint256 y,
        uint8 decimals
    ) internal pure returns (uint256) {
        return Math.mulDiv(x, unit(decimals), y);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IPriceFeed } from "./IPriceFeed.sol";

interface IAmm {
    /**
     * @notice asset direction, used in getQuotePrice, getBasePrice, swapInput and swapOutput
     * @param ADD_TO_AMM add asset to Amm
     * @param REMOVE_FROM_AMM remove asset from Amm
     */
    enum Dir {
        ADD_TO_AMM,
        REMOVE_FROM_AMM
    }

    function swapInput(
        Dir _dir,
        uint256 _amount,
        bool _isQuote,
        bool _canOverFluctuationLimit
    )
        external
        returns (
            uint256 quoteAssetAmount,
            int256 baseAssetAmount,
            uint256 spreadFee,
            uint256 tollFee
        );

    function swapOutput(
        Dir _dir,
        uint256 _amount,
        bool _isQuote,
        bool _canOverFluctuationLimit
    )
        external
        returns (
            uint256 quoteAssetAmount,
            int256 baseAssetAmount,
            uint256 spreadFee,
            uint256 tollFee
        );

    function repegCheck(uint256 budget)
        external
        returns (
            bool,
            int256,
            uint256,
            uint256
        );

    function adjust(uint256 _quoteAssetReserve, uint256 _baseAssetReserve) external;

    function shutdown() external;

    function settleFunding(uint256 _cap)
        external
        returns (
            int256 premiumFractionLong,
            int256 premiumFractionShort,
            int256 fundingPayment
        );

    function calcFee(uint256 _quoteAssetAmount) external view returns (uint256, uint256);

    //
    // VIEW
    //

    function getFormulaicUpdateKResult(int256 budget)
        external
        view
        returns (
            bool isAdjustable,
            int256 cost,
            uint256 newQuoteAssetReserve,
            uint256 newBaseAssetReserve
        );

    function getMaxKDecreaseRevenue(uint256 _quoteAssetReserve, uint256 _baseAssetReserve) external view returns (int256 revenue);

    function isOverFluctuationLimit(Dir _dirOfBase, uint256 _baseAssetAmount) external view returns (bool);

    function getQuoteTwap(Dir _dir, uint256 _quoteAssetAmount) external view returns (uint256);

    function getBaseTwap(Dir _dir, uint256 _baseAssetAmount) external view returns (uint256);

    function getQuotePrice(Dir _dir, uint256 _quoteAssetAmount) external view returns (uint256);

    function getBasePrice(Dir _dir, uint256 _baseAssetAmount) external view returns (uint256);

    function getQuotePriceWithReserves(
        Dir _dir,
        uint256 _quoteAssetAmount,
        uint256 _quoteAssetPoolAmount,
        uint256 _baseAssetPoolAmount
    ) external pure returns (uint256);

    function getBasePriceWithReserves(
        Dir _dir,
        uint256 _baseAssetAmount,
        uint256 _quoteAssetPoolAmount,
        uint256 _baseAssetPoolAmount
    ) external pure returns (uint256);

    function getSpotPrice() external view returns (uint256);

    // overridden by state variable

    function initMarginRatio() external view returns (uint256);

    function maintenanceMarginRatio() external view returns (uint256);

    function liquidationFeeRatio() external view returns (uint256);

    function partialLiquidationRatio() external view returns (uint256);

    function quoteAsset() external view returns (IERC20);

    function priceFeedKey() external view returns (bytes32);

    function tradeLimitRatio() external view returns (uint256);

    function fundingPeriod() external view returns (uint256);

    function priceFeed() external view returns (IPriceFeed);

    function getReserve() external view returns (uint256, uint256);

    function open() external view returns (bool);

    function adjustable() external view returns (bool);

    function canLowerK() external view returns (bool);

    function ptcKIncreaseMax() external view returns (uint256);

    function ptcKDecreaseMax() external view returns (uint256);

    function getSettlementPrice() external view returns (uint256);

    function getCumulativeNotional() external view returns (int256);

    function getBaseAssetDelta() external view returns (int256);

    function getUnderlyingPrice() external view returns (uint256);

    function isOverSpreadLimit()
        external
        view
        returns (
            bool result,
            uint256 marketPrice,
            uint256 oraclePrice
        );

    function isOverSpread(uint256 _limit)
        external
        view
        returns (
            bool result,
            uint256 marketPrice,
            uint256 oraclePrice
        );

    function getFundingPaymentEstimation(uint256 _cap)
        external
        view
        returns (
            bool notPayable,
            int256 premiumFractionLong,
            int256 premiumFractionShort,
            int256 fundingPayment,
            uint256 underlyingPrice
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.9;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IntMath } from "./IntMath.sol";
import { UIntMath } from "./UIntMath.sol";

library AmmMath {
    using UIntMath for uint256;
    using IntMath for int256;

    struct BudgetedKScaleCalcParams {
        uint256 quoteAssetReserve;
        uint256 baseAssetReserve;
        int256 budget;
        int256 positionSize;
        uint256 ptcKIncreaseMax;
        uint256 ptcKDecreaseMax;
    }

    /**
     * @notice calculate reserves after repegging with preserving K
     * @dev https://docs.google.com/document/d/1JcKFCFY7vDxys0eWl0K1B3kQEEz-mrr7VU3-JPLPkkE/edit?usp=sharing
     */
    function calcReservesAfterRepeg(
        uint256 _quoteAssetReserve,
        uint256 _baseAssetReserve,
        uint256 _targetPrice,
        int256 _positionSize
    ) internal pure returns (uint256 newQuoteAssetReserve, uint256 newBaseAssetReserve) {
        uint256 spotPrice = _quoteAssetReserve.divD(_baseAssetReserve);
        newQuoteAssetReserve = Math.mulDiv(_baseAssetReserve, Math.sqrt(spotPrice.mulD(_targetPrice)), 1e9);
        newBaseAssetReserve = Math.mulDiv(_baseAssetReserve, Math.sqrt(spotPrice.divD(_targetPrice)), 1e9);
        // in case net user position size is short and its absolute value is bigger than the expected base asset reserve
        if (_positionSize < 0 && newBaseAssetReserve <= _positionSize.abs()) {
            newQuoteAssetReserve = _baseAssetReserve.mulD(_targetPrice);
            newBaseAssetReserve = _baseAssetReserve;
        }
    }

    // function calcBudgetedQuoteReserve(
    //     uint256 _quoteAssetReserve,
    //     uint256 _baseAssetReserve,
    //     int256 _positionSize,
    //     uint256 _budget
    // ) internal pure returns (uint256 newQuoteAssetReserve) {
    //     newQuoteAssetReserve = _positionSize > 0
    //         ? _budget + _quoteAssetReserve + Math.mulDiv(_budget, _baseAssetReserve, _positionSize.abs())
    //         : _budget + _quoteAssetReserve - Math.mulDiv(_budget, _baseAssetReserve, _positionSize.abs());
    // }

    /**
     *@notice calculate the cost for adjusting the reserves
     *@dev
     *For #long>#short (d>0): cost = (y'-x'y'/(x'+d)) - (y-xy/(x+d)) = y'd/(x'+d) - yd/(x+d)
     *For #long<#short (d<0): cost = (xy/(x-|d|)-y) - (x'y'/(x'-|d|)-y') = y|d|/(x-|d|) - y'|d|/(x'-|d|)
     *@param _quoteAssetReserve y
     *@param _baseAssetReserve x
     *@param _positionSize d
     *@param _newQuoteAssetReserve y'
     *@param _newBaseAssetReserve x'
     */

    function calcCostForAdjustReserves(
        uint256 _quoteAssetReserve,
        uint256 _baseAssetReserve,
        int256 _positionSize,
        uint256 _newQuoteAssetReserve,
        uint256 _newBaseAssetReserve
    ) internal pure returns (int256 cost) {
        if (_positionSize > 0) {
            cost =
                (Math.mulDiv(_newQuoteAssetReserve, uint256(_positionSize), (_newBaseAssetReserve + uint256(_positionSize)))).toInt() -
                (Math.mulDiv(_quoteAssetReserve, uint256(_positionSize), (_baseAssetReserve + uint256(_positionSize)))).toInt();
        } else {
            cost =
                (Math.mulDiv(_quoteAssetReserve, uint256(-_positionSize), (_baseAssetReserve - uint256(-_positionSize)), Math.Rounding.Up))
                    .toInt() -
                (
                    Math.mulDiv(
                        _newQuoteAssetReserve,
                        uint256(-_positionSize),
                        (_newBaseAssetReserve - uint256(-_positionSize)),
                        Math.Rounding.Up
                    )
                ).toInt();
        }
    }

    function calculateBudgetedKScale(BudgetedKScaleCalcParams memory params) internal pure returns (uint256, uint256) {
        if (params.positionSize == 0 && params.budget > 0) {
            return (params.ptcKIncreaseMax, 1 ether);
        } else if (params.positionSize == 0 && params.budget < 0) {
            return (params.ptcKDecreaseMax, 1 ether);
        }
        int256 numerator;
        int256 denominator;
        {
            int256 x = params.baseAssetReserve.toInt();
            int256 y = params.quoteAssetReserve.toInt();
            int256 x_d = x + params.positionSize;
            int256 num1 = y.mulD(params.positionSize).mulD(params.positionSize);
            int256 num2 = params.positionSize.mulD(x_d).mulD(params.budget);
            int256 denom2 = x.mulD(x_d).mulD(params.budget);
            int256 denom1 = num1;
            numerator = num1 + num2;
            denominator = denom1 - denom2;
        }
        if (params.budget > 0 && denominator < 0) {
            return (params.ptcKIncreaseMax, 1 ether);
        } else if (params.budget < 0 && numerator < 0) {
            return (params.ptcKDecreaseMax, 1 ether);
        }
        // if (numerator > 0 != denominator > 0 || denominator == 0 || numerator == 0) {
        //     return (_budget > 0 ? params.ptcKIncreaseMax : params.ptcKDecreaseMax, 1 ether);
        // }
        uint256 absNum = numerator.abs();
        uint256 absDen = denominator.abs();
        if (absNum > absDen) {
            uint256 curChange = absNum.divD(absDen);
            uint256 maxChange = params.ptcKIncreaseMax.divD(1 ether);
            if (curChange > maxChange) {
                return (params.ptcKIncreaseMax, 1 ether);
            } else {
                return (absNum, absDen);
            }
        } else {
            uint256 curChange = absNum.divD(absDen);
            uint256 maxChange = params.ptcKDecreaseMax.divD(1 ether);
            if (curChange < maxChange) {
                return (params.ptcKDecreaseMax, 1 ether);
            } else {
                return (absNum, absDen);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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