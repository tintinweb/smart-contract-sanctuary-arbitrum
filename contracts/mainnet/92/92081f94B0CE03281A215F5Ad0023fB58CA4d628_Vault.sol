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

import "../libraries/SafeMath.sol";
import "../libraries/SignedSafeMath.sol";
import "../libraries/ReentrancyGuard.sol";
import "../libraries/SafeCast.sol";
import "../interfaces/IManager.sol";
import "../interfaces/IPool.sol";
import "../libraries/TransferHelper.sol";
import "../interfaces/IWrappedCoin.sol";

contract Vault is ReentrancyGuard {
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SignedSafeMath for int8;
    using SafeCast for int256;
    using SafeCast for uint256;

    address public manager;
    address public WETH;

    // balance of pool, position fee and remove lp fee
    // pool => token => balance;
    // usdt of vault = usdt of poolBalances + usdt of exchangeFees + usdt of poolRmLpFeeBalances
    // pool array is in manager
    mapping(address => mapping(address => uint256)) public poolBalances;
    mapping(address => uint256) public poolRmLpFeeBalances;
    mapping(address => uint256) public exchangeFees; //pool => exchange fee

    event AddPoolBalance(address _pool, address _token, uint256 _amount);
    event DecreasePoolBalance(address _pool, address _token, uint256 _amount);
    event ReceiveRmLpFee(address _pool, uint256 _feeAmount);
    event ReceiveExchangeFee(address _pool, uint256 _feeAmount);
    event Transfer(address _pool, address _token, address _to, uint256 _amount);
    event CollectPoolRmFee(address _pool, address _token, address _to, uint256 _amount);
    event CollectExchangeFee(address _token, address _to, uint256 _amount);

    constructor(address _manager, address _WETH) {
        require(_manager != address(0) && _WETH != address(0), "Vault: invalid input address");
        manager = _manager;
        WETH = _WETH;
    }

    modifier onlyController() {
        require(IManager(manager).checkController(msg.sender), "Vault: Must be controller");
        _;
    }

    modifier onlyTreasurer() {
        require(IManager(manager).checkTreasurer(msg.sender), "Vault: Must be treasurer");
        _;
    }

    modifier onlyPool() {
        require(IManager(manager).checkPool(msg.sender), "Vault: Must be pool");
        _;
    }

    /// @notice transfer token to vault by pool , only pool can call
    /// @param _balance amount
    function addPoolBalance(uint256 _balance) external nonReentrant onlyPool {
        address _pool = msg.sender;
        address _token = IPool(_pool).getBaseAsset();
        poolBalances[_pool][_token] = poolBalances[_pool][_token].add(_balance);
        emit AddPoolBalance(_pool, _token, _balance);
    }

    /// @notice decrease pool balance by pool
    /// @param _pool pool address
    /// @param _token token address
    /// @param _balance amount
    function decreasePoolBalance(address _pool, address _token, uint256 _balance) internal {
        require(poolBalances[_pool][_token] >= _balance, "Vault: Insufficient balance");
        poolBalances[_pool][_token] = poolBalances[_pool][_token].sub(_balance);
        emit DecreasePoolBalance(_pool, _token, _balance);
    }


    /// @notice transfer fee to vault by pool , only pool can call
    /// @param _feeAmount fee amount
    function addPoolRmLpFeeBalance(uint256 _feeAmount) external nonReentrant onlyPool {
        address _pool = msg.sender;
        address _token = IPool(_pool).getBaseAsset();
        decreasePoolBalance(_pool, _token, _feeAmount);
        poolRmLpFeeBalances[_pool] = poolRmLpFeeBalances[_pool].add(_feeAmount);
        emit ReceiveRmLpFee(_pool, _feeAmount);
    }

    /// @notice transfer fee to vault by pool , only pool can call
    /// @param _feeAmount fee amount
    function addExchangeFeeBalance(uint256 _feeAmount) external nonReentrant onlyPool {
        address _pool = msg.sender;
        address _token = IPool(_pool).getBaseAsset();
        decreasePoolBalance(_pool, _token, _feeAmount);
        exchangeFees[_pool] = exchangeFees[_pool].add(_feeAmount);
        emit ReceiveExchangeFee(_pool, _feeAmount);
    }

    /// @notice transfer token out from vault by pool , only pool can call
    /// @param _to to address
    /// @param _amount amount
    /// @param isOutETH is out eth
    function transfer(address _to, uint256 _amount, bool isOutETH) external nonReentrant onlyPool {
        require(_to != address(this) && _to != address(0), "Vault: to address error");
        address _pool = msg.sender;
        address _token = IPool(_pool).getBaseAsset();
        decreasePoolBalance(_pool, _token, _amount);
        if (isOutETH) {
            require(_token == WETH, "Vault: token is not WETH");
            IWrappedCoin(_token).withdraw(_amount);
            TransferHelper.safeTransferETH(_to, _amount);
        } else {
            TransferHelper.safeTransfer(_token, _to, _amount);
        }
        emit Transfer(_pool, _token, _to, _amount);
    }

    /// @notice transfer remove liquidity fee out
    /// @param _pool pool address
    /// @param to address
    function collectPoolRmFee(address _pool, address to) external nonReentrant onlyTreasurer {
        require(poolRmLpFeeBalances[_pool] > 0, "Vault:remove liquidity fee balance is 0");
        require(to != address(this) && to != address(0), "Vault: to address is invalid");
        address _token = IPool(_pool).getBaseAsset();
        uint256 _fee = poolRmLpFeeBalances[_pool];
        poolRmLpFeeBalances[_pool] = 0;
        if (_token == WETH) {
            IWrappedCoin(_token).withdraw(_fee);
            TransferHelper.safeTransferETH(to, _fee);
        } else {
            TransferHelper.safeTransfer(_token, to, _fee);
        }
        emit CollectPoolRmFee(_pool, _token, to, _fee);
    }

    /// @notice transfer remove liquidity fee out
    /// @param _pool pool address
    /// @param to address
    function collectExchangeFee(address _pool, address to) external nonReentrant onlyTreasurer {
        require(exchangeFees[_pool] > 0, "Vault:exchange fee balance is 0");
        require(to != address(this) && to != address(0), "Vault: to address is invalid");
        address _token = IPool(_pool).getBaseAsset();
        uint256 _fee = exchangeFees[_pool];
        exchangeFees[_pool] = 0;
        if (_token == WETH) {
            IWrappedCoin(_token).withdraw(_fee);
            TransferHelper.safeTransferETH(to, _fee);
        } else {
            TransferHelper.safeTransfer(_token, to, _fee);
        }
        emit CollectExchangeFee(_token, to, _fee);
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

interface IWrappedCoin {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
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

// SPDX-License-Identifier: GPL-2.0-or-later
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