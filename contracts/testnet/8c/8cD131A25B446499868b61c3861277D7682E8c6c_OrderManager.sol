//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./uniswap/IUniswapV3Pool.sol";
import "./uniswap/FullMath.sol";
import "./uniswap/TickMath.sol";
import "./uniswap/SwapMath.sol";
import "./uniswap/LiquidityMath.sol";
import "./uniswap/FixedPoint128.sol";
import "./uniswap/IUniswapV3MintCallback.sol";
import "./uniswap/LiquidityAmounts.sol";
import "./interfaces/IOrderManager.sol";
import "./interfaces/IOddzMarket.sol";
import "./maths/OddzSafeCast.sol";
import "./utils/oddzOwnable.sol";
import "./utils/uniswapInteractor.sol";
import "./utils/tick.sol";

contract OrderManager is IUniswapV3MintCallback, IOrderManager, OddzOwnable {
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint128;
    using SignedSafeMathUpgradeable for int256;
    using OddzSafeCast for uint256;
    using AddressUpgradeable for address;
    using OddzMath for int128;

    /* /// @param liquidity          Liquidity amount
    /// @param lowerTick          Lower tick of liquidity range
    /// @param upperTick          Upper tick of liquidity range
    /// @param baseAmountInPool   number of base token added
    /// @param quoteAmountInPool  number of quote token added
    struct OrderInfo {
        uint128 liquidity;
        int24 lowerTick;
        int24 upperTick;
        uint256 baseAmountInPool;
        uint256 quoteAmountInPool;
        uint256 collateralForOrder;
    } */

    //VARIABLES

    address public oddzExchange;
    address public oddzClearingHouse;
    address public oddzMarket;
    address public swapManager;

    // key: currentOrderId => Order Info
    mapping(bytes32 => OrderInfo) internal currentOrderMap;

    mapping(address => uint256) internal totalCollateralForOrders;

    // first key: trader, second key: base token
    //This gives all the orders of that trader for that market
    //Mapping of Trader => Base Token => orderID
    mapping(address => mapping(address => bytes32[]))
        internal _currentOrderIdsMap;

    //MODIFIERS
    //

    modifier onlyClearingHouse() {
        require(
            _msgSender() == oddzClearingHouse,
            "OddzOrderManager: Only clearhouse allowed"
        );
        _;
    }

    modifier onlySwapManager() {
        require(
            _msgSender() == swapManager,
            "OddzOrderManager: Only swap manager allowed"
        );
        _;
    }

    modifier checkUniswapCallback() {
        address pool = _msgSender();
        address baseToken = IUniswapV3Pool(pool).token0();
        require(
            pool == IOddzMarket(oddzMarket).fetchPool(baseToken),
            "OddzOrderManager : Uniswap CallBack check failed"
        );
        _;
    }

    //INITIALIZER

    function initialize(address _oddzMarket) external initializer {
        require(
            _oddzMarket.isContract(),
            "OddzOrderManager: market should be a contract"
        );
        __OddzOwnable_init();
        oddzMarket = _oddzMarket;
    }

    /**
     * @notice Used to update clearing house contract address
     * @param _clearingHouse Address of the clearing house contract
     */

    function updateClearingHouse(address _clearingHouse) external onlyOwner {
        require(
            _clearingHouse.isContract(),
            "OddzOrderManager: clearing house should be a contract"
        );
        oddzClearingHouse = _clearingHouse;
    }

    /**
     * @notice Used to update market contract address
     * @param _market Address of the market contract
     */

    function updateMarket(address _market) external onlyOwner {
        require(
            _market.isContract(),
            "OddzOrderManager: market should be a contract"
        );
        oddzMarket = _market;
    }

    /**
     * @notice Used to update swap manager contract address.
     * @param _swapManager Address of the clearing house contract.
     */

    function updateSwapManager(address _swapManager) external onlyOwner {
        require(
            _swapManager.isContract(),
            "OddzOrderManager: swap manager should be a contract"
        );
        swapManager = _swapManager;
    }

    /**
     * @notice User calls this function to add liquidity in the uniswap pool
     * @dev Called by the clearing house contract
     * Also update the order details for the trader
     * returns base, quote, liquidity
     */
    function addLiquidity(AddLiquidityParams calldata params)
        external
        override
        onlyClearingHouse
        returns (
          AddLiquidityResponse memory _response
        )
    {
        address pool = IOddzMarket(oddzMarket).fetchPool(params.baseToken);

        // add liquidity to pool
        UniswapInteractor.AddLiquidityResponse
            memory response = UniswapInteractor.addLiquidity(
                UniswapInteractor.AddLiquidityParams(
                    pool,
                    params.lowerTickOfOrder,
                    params.upperTickOfOrder,
                    params.baseAmount,
                    params.quoteAmount,
                    abi.encode(MintCallbackData(params.trader, pool))
                )
            );

        //caluclate order ID
        bytes32 orderId = calcOrderID(
            params.trader,
            params.baseToken,
            params.lowerTickOfOrder,
            params.upperTickOfOrder
        );
        OrderInfo storage openOrder = currentOrderMap[orderId];

        if (openOrder.liquidity == 0) {
            bytes32[] storage orderIds = _currentOrderIdsMap[params.trader][
                params.baseToken
            ];

            // state changes
            orderIds.push(orderId);
            openOrder.lowerTick = params.lowerTickOfOrder;
            openOrder.upperTick = params.upperTickOfOrder;
        }

        openOrder.collateralForOrder = openOrder.collateralForOrder.add(
            params.collateralForOrder
        );
        totalCollateralForOrders[params.trader] = totalCollateralForOrders[
            params.trader
        ].add(params.collateralForOrder);

        // after this liquidity  can be updated
        openOrder.liquidity = openOrder
            .liquidity
            .add(response.liquidity)
            .toUint128();
        openOrder.baseAmountInPool = openOrder.baseAmountInPool.add(
            response.base
        );
        openOrder.quoteAmountInPool = openOrder.quoteAmountInPool.add(
            response.quote
        );

        return AddLiquidityResponse({
            baseAmount:response.base,
            quoteAmount:response.quote,
            liquidityAmount:response.liquidity,
            orderId:orderId
        });
    }

    /**
     * @notice User calls this function to remove liquidity in the uniswap pool
     * @dev Called by the clearing house contract
     * Also update the order details for the trader
     * returns base, quote, liquidity
     */
    function removeLiquidity(RemoveLiquidityParams calldata params)
        external
        override
        onlyClearingHouse
        returns (RemoveLiquidityResponse memory _response)
    {
        bytes32 orderId = calcOrderID(
            params.trader,
            params.baseToken,
            params.lowerTickOfOrder,
            params.upperTickOfOrder
        );

        //Remove liquidity from the uniswap pool
        UniswapInteractor.RemoveLiquidityResponse memory response = UniswapInteractor
            .removeLiquidity(
                UniswapInteractor.RemoveLiquidityParams(
                    IOddzMarket(oddzMarket).fetchPool(params.baseToken),
                    address(this), // where  fees will go
                    params.lowerTickOfOrder,
                    params.upperTickOfOrder,
                    params.liquidityAmount
                )
            );

        // update token info based on existing open order
        OrderInfo storage openOrder = currentOrderMap[orderId];
        uint256 tempBaseAmountInPool;
        uint256 tempQuoteAmountInPool;

        //If the whole liqiuidty is not removed then update the quote token and base token accordingly
        if (params.liquidityAmount != 0) {
            if (openOrder.baseAmountInPool != 0) {
                tempBaseAmountInPool = FullMath.mulDiv(
                    openOrder.baseAmountInPool,
                    params.liquidityAmount,
                    openOrder.liquidity
                );
                openOrder.baseAmountInPool = openOrder.baseAmountInPool.sub(
                    tempBaseAmountInPool
                );
            }
            if (openOrder.quoteAmountInPool != 0) {
                tempQuoteAmountInPool = FullMath.mulDiv(
                    openOrder.quoteAmountInPool,
                    params.liquidityAmount,
                    openOrder.liquidity
                );
                openOrder.quoteAmountInPool = openOrder.quoteAmountInPool.sub(
                    tempQuoteAmountInPool
                );
            }
            openOrder.liquidity = openOrder
                .liquidity
                .sub(params.liquidityAmount)
                .toUint128();
        }

        //Difference in what user added , and what user recieved when user removed the liquidity
        int256 takerBase = response.base.toInt256().sub(
            tempBaseAmountInPool.toInt256()
        );
        int256 takerQuote = response.quote.toInt256().sub(
            tempQuoteAmountInPool.toInt256()
        );

        //update Order Information if the liquidity is zero
        if (openOrder.liquidity == 0) {
            totalCollateralForOrders[params.trader] = totalCollateralForOrders[
                params.trader
            ].sub(openOrder.collateralForOrder);
            bytes32[] storage orderIds = _currentOrderIdsMap[params.trader][
                params.baseToken
            ];
            uint256 length = orderIds.length;
            for (uint256 i = 0; i < length; i++) {
                if (orderIds[i] == orderId) {
                    // found the existing order ID
                    // delete it from the array efficiently by re-ordering and deleting the last element
                    if (i != length - 1) {
                        orderIds[i] = orderIds[length - 1];
                    }
                    orderIds.pop();
                    delete currentOrderMap[orderId];
                    break;
                }
            }
        }
        return
            RemoveLiquidityResponse({
                baseAmount: response.base,
                quoteAmount: response.quote,
                takerBaseAmount: takerBase,
                takerQuoteAmount: takerQuote,
                orderId:orderId
            });
    }

    /// @inheritdoc IUniswapV3MintCallback
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external override checkUniswapCallback {
        IUniswapV3MintCallback(oddzClearingHouse).uniswapV3MintCallback(
            amount0Owed,
            amount1Owed,
            data
        );
    }

    /**
     * @notice Calculates unique order ID
     * @param _trader Address of the trader
     * @param _baseToken Base token Address
     * @param _lowerTick  Lower tick of liquidity range
     * @param _upperTick  Upper tick of liquidity range
     * @return bytes32 unique hash/ID of that order
     */
    function calcOrderID(
        address _trader,
        address _baseToken,
        int24 _lowerTick,
        int24 _upperTick
    ) public override pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_trader, _baseToken, _lowerTick, _upperTick)
            );
    }

    /// @notice Used to get all the order ids of the trader for that market
    /// @param _trader User address
    /// @param _baseToken base token address
    /// @return _orderIds all the order id of the user
    function getCurrentOrderIdsMap(address _trader, address _baseToken)
        external
        view
        override
        returns (bytes32[] memory _orderIds)
    {
        return _currentOrderIdsMap[_trader][_baseToken];
    }


    /**
     * @notice Calculates token amount inside the pool for a trader
     * @param _trader Address of the trader
     * @param _baseToken Base token Address
     * @param _base  true means calculate base token amount and false means quote token amount
     * @return _totalOrdersAmount returns all orders amount for a particular token
     */
    function getTotalOrdersAmountInPool(
        address _trader,
        address _baseToken,
        bool _base
    ) public view override returns (uint256 _totalOrdersAmount) {
        bytes32[] memory orderIds = _currentOrderIdsMap[_trader][_baseToken];
        uint256 orderIdLength = orderIds.length;
        for (uint256 i = 0; i < orderIdLength; i++) {
            OrderInfo memory orderInfo = currentOrderMap[orderIds[i]];
            if (_base) {
                _totalOrdersAmount = _totalOrdersAmount.add(
                    orderInfo.baseAmountInPool
                );
            } else {
                _totalOrdersAmount = _totalOrdersAmount.add(
                    orderInfo.quoteAmountInPool
                );
            }
        }
    }

     /**
     * @notice Calculates token amount inside the pool for a trader
     * @param _orderId order id
     * @param _base  true means calculate base token amount and false means quote token amount
     * @return _orderAmount returns order amount for a particular token
     */
    function getAmountInPoolByOrderId(
        bytes32 _orderId,
        bool _base
    ) public view override returns (uint256 _orderAmount) {
        OrderInfo memory orderInfo = currentOrderMap[_orderId];
        if (_base) {
            _orderAmount = _orderAmount.add(
                orderInfo.baseAmountInPool
            );
        } else {
            _orderAmount = _orderAmount.add(
                orderInfo.quoteAmountInPool
            );
        }  
    }

     /**
     * @notice Calculates current token amount inside the specific pool of uniswapV3Pool for a trader
     * @param _baseToken base token address
     * @param _orderId order id
     * @param _base  true: get base amount, false: get quote amount
     * @return _tokenAmountInPool returns all token inside pool amount for a particular token
     */
    function getCurrentTotalTokenAmountInPoolByOrderId(
        address _baseToken,
        bytes32 _orderId,
        bool _base
    ) external override view returns (uint256 _tokenAmountInPool) {
      (_tokenAmountInPool) = _getCurrentTotalTokenAmountInPoolByOrderId(_baseToken,_orderId,_base);
    }

    /**
     * @notice Calculates current token amount inside the specific pool of uniswapV3Pool for a trader
     * @param _baseToken base token address
     * @param _orderId order id
     * @param _base  true: get base amount, false: get quote amount
     * @return _tokenAmountInPool returns all token inside pool amount for a particular token
     */
    function _getCurrentTotalTokenAmountInPoolByOrderId(
        address _baseToken,
        bytes32 _orderId,
        bool _base
    ) internal view returns (uint256 _tokenAmountInPool) {
         OrderInfo memory orderInfo = currentOrderMap[_orderId];
        address pool = IOddzMarket(oddzMarket).fetchPool(_baseToken);
        (uint160 sqrtMarkPriceX96, , , , , , ) = UniswapInteractor.fetchSlot0(pool);
           
            uint160 sqrtPriceAtLowerTickCheck = TickMath.getSqrtRatioAtTick(orderInfo.lowerTick);
            uint160 sqrtPriceAtUpperTickCheck = TickMath.getSqrtRatioAtTick(orderInfo.upperTick);

            if (_base && 
                 (sqrtMarkPriceX96 < sqrtPriceAtUpperTickCheck))
            {
                // Computes the amount of token0 for a given amount of liquidity
                // if current price < upper tick, trader has base
                // case 1 : current price < lower tick
                //  --> trader only has base token
                uint256 token0AmountInPool = LiquidityAmounts.getAmount0ForLiquidity(
                        sqrtMarkPriceX96 > sqrtPriceAtLowerTickCheck ? sqrtMarkPriceX96 : sqrtPriceAtLowerTickCheck,
                        sqrtPriceAtUpperTickCheck,
                        orderInfo.liquidity
                );
                _tokenAmountInPool = _tokenAmountInPool.add(token0AmountInPool);
            } else if (!_base && 
                 (sqrtMarkPriceX96 > sqrtPriceAtLowerTickCheck))
            {
                // Computes the amount of token1 for a given amount of liquidity
                // if current price > lower tick, trader has quote
                // case 2 : current price > upper tick
                //  --> trader only has quote token
                uint256 token1AmountInPool = LiquidityAmounts.getAmount1ForLiquidity(
                        sqrtPriceAtLowerTickCheck,
                        sqrtMarkPriceX96 < sqrtPriceAtUpperTickCheck ? sqrtMarkPriceX96 : sqrtPriceAtUpperTickCheck,
                        orderInfo.liquidity
                );
                _tokenAmountInPool = _tokenAmountInPool.add(token1AmountInPool);
            }
    }

    function getTotalCollateralForOrders(address trader)
        external
        view
        override
        returns (uint256)
    {
        return totalCollateralForOrders[trader];
    }

    function getCurrentOrderMap(bytes32 orderId)
        external
        view
        override
        returns (OrderInfo memory)
    {
        return currentOrderMap[orderId];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMathUpgradeable {
    int256 constant private _INT256_MIN = -2**255;

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

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

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
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

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

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './IUniswapV3PoolImmutables.sol';
import './IUniswapV3PoolState.sol';
import './IUniswapV3PoolDerivedState.sol';
import './IUniswapV3PoolActions.sol';
import './IUniswapV3PoolOwnerActions.sol';
import './IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0 <0.8.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import './FullMath.sol';
import './SqrtPriceMath.sol';

/// @title Computes the result of a swap within ticks
/// @notice Contains methods for computing the result of a swap within a single tick price range, i.e., a single tick.
library SwapMath {
    /// @notice Computes the result of swapping some amount in, or amount out, given the parameters of the swap
    /// @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
    /// @param sqrtRatioCurrentX96 The current sqrt price of the pool
    /// @param sqrtRatioTargetX96 The price that cannot be exceeded, from which the direction of the swap is inferred
    /// @param liquidity The usable liquidity
    /// @param amountRemaining How much input or output amount is remaining to be swapped in/out
    /// @param feePips The fee taken from the input amount, expressed in hundredths of a bip
    /// @return sqrtRatioNextX96 The price after swapping the amount in/out, not to exceed the price target
    /// @return amountIn The amount to be swapped in, of either token0 or token1, based on the direction of the swap
    /// @return amountOut The amount to be received, of either token0 or token1, based on the direction of the swap
    /// @return feeAmount The amount of input that will be taken as a fee
    function computeSwapStep(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    )
        internal
        pure
        returns (
            uint160 sqrtRatioNextX96,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        )
    {
        bool zeroForOne = sqrtRatioCurrentX96 >= sqrtRatioTargetX96;
        bool exactIn = amountRemaining >= 0;

        if (exactIn) {
            uint256 amountRemainingLessFee = FullMath.mulDiv(uint256(amountRemaining), 1e6 - feePips, 1e6);
            amountIn = zeroForOne
                ? SqrtPriceMath.getAmount0Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, true)
                : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, true);
            if (amountRemainingLessFee >= amountIn) sqrtRatioNextX96 = sqrtRatioTargetX96;
            else
                sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                    sqrtRatioCurrentX96,
                    liquidity,
                    amountRemainingLessFee,
                    zeroForOne
                );
        } else {
            amountOut = zeroForOne
                ? SqrtPriceMath.getAmount1Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, false)
                : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, false);
            if (uint256(-amountRemaining) >= amountOut) sqrtRatioNextX96 = sqrtRatioTargetX96;
            else
                sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
                    sqrtRatioCurrentX96,
                    liquidity,
                    uint256(-amountRemaining),
                    zeroForOne
                );
        }

        bool max = sqrtRatioTargetX96 == sqrtRatioNextX96;

        // get the input/output amounts
        if (zeroForOne) {
            amountIn = max && exactIn
                ? amountIn
                : SqrtPriceMath.getAmount0Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, true);
            amountOut = max && !exactIn
                ? amountOut
                : SqrtPriceMath.getAmount1Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, false);
        } else {
            amountIn = max && exactIn
                ? amountIn
                : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, true);
            amountOut = max && !exactIn
                ? amountOut
                : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, false);
        }

        // cap the output amount to not exceed the remaining output amount
        if (!exactIn && amountOut > uint256(-amountRemaining)) {
            amountOut = uint256(-amountRemaining);
        }

        if (exactIn && sqrtRatioNextX96 != sqrtRatioTargetX96) {
            // we didn't reach the target, so take the remainder of the maximum input as fee
            feeAmount = uint256(amountRemaining) - amountIn;
        } else {
            feeAmount = FullMath.mulDivRoundingUp(amountIn, feePips, 1e6 - feePips);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for liquidity
library LiquidityMath {
    /// @notice Add a signed liquidity delta to liquidity and revert if it overflows or underflows
    /// @param x The liquidity before change
    /// @param y The delta by which liquidity should be changed
    /// @return z The liquidity delta
    function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
        if (y < 0) {
            require((z = x - uint128(-y)) < x, 'LS');
        } else {
            require((z = x + uint128(y)) >= x, 'LA');
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#mint
/// @notice Any contract that calls IUniswapV3PoolActions#mint must implement this interface
interface IUniswapV3MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './FullMath.sol';
import './FixedPoint96.sol';

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IOrderManager {
    /// @param liquidity          Liquidity amount
    /// @param lowerTick          Lower tick of liquidity range
    /// @param upperTick          Upper tick of liquidity range
    /// @param baseAmountInPool   number of base token added
    /// @param quoteAmountInPool  number of quote token added
    struct OrderInfo {
        uint128 liquidity;
        int24 lowerTick;
        int24 upperTick;
        uint256 baseAmountInPool;
        uint256 quoteAmountInPool;
        uint256 collateralForOrder;
    }
    /// @param trader                   Trader address
    /// @param baseToken                Base token address
    /// @param baseAmount               Base token amount
    /// @param quoteAmount              Quote token amount
    /// @param lowerTickOfOrder         Lower tick of liquidity range
    /// @param upperTickOfOrder         Upper tick of liquidity range
    struct AddLiquidityParams {
        address trader;
        address baseToken;
        uint256 baseAmount;
        uint256 quoteAmount;
        int24 lowerTickOfOrder;
        int24 upperTickOfOrder;
        uint256 collateralForOrder;
    }

    /// @param baseAmount         The amount of base token added to the pool
    /// @param quoteAmount        The amount of quote token added to the pool
    /// @param liquidityAmount    The amount of liquidity recieved from the pool
    /// @param orderId             order id for this liquidity position
    struct AddLiquidityResponse {
        uint256 baseAmount;
        uint256 quoteAmount;
        uint128 liquidityAmount;
        bytes32 orderId;
    }

    /// @param trader                  Trader Address
    /// @param baseToken               Base token address
    /// @param lowerTickOfOrder        Lower tick of liquidity range
    /// @param upperTickOfOrder        Upper tick of liquidity range
    /// @param liquidityAmount         Amount of liquidity you want to remove
    struct RemoveLiquidityParams {
        address trader;
        address baseToken;
        int24 lowerTickOfOrder;
        int24 upperTickOfOrder;
        uint128 liquidityAmount;
    }

    /// @param baseAmount       The amount of base token removed from the pool
    /// @param quoteAmount      The amount of quote token removed from the pool
    /// @param takerBaseAmount  The base amount which is different from what had been added
    /// @param takerQuoteAmount The quote amount which is different from what had been added
    /// @param orderId             order id for this liquidity position
    struct RemoveLiquidityResponse {
        uint256 baseAmount;
        uint256 quoteAmount;
        int256 takerBaseAmount;
        int256 takerQuoteAmount;
        bytes32 orderId;
    }

    struct MintCallbackData {
        address trader;
        address pool;
    }

    struct ReplaySwapParams {
        address baseToken;
        bool isShort;
        bool shouldUpdateState;
        int256 amount;
        uint160 sqrtPriceLimitX96;
        uint24 exchangeFee;
        uint24 uniswapFee;
    }

    struct ReplaySwapResponse {
        int24 tick;
        uint256 fee;
    }

    /// @notice Add liquidity logic
    /// @dev Only used by `Oddz Clearing House` contract
    /// @param params Add liquidity params, detail on `IOrderManager.AddLiquidityParams`
    /// @return response Response of add liquidity
    function addLiquidity(AddLiquidityParams calldata params)
        external
        returns (AddLiquidityResponse memory response);

    /// @notice Remove liquidity logic, only used by `Oddz Clearing House` contract
    /// @param params Remove liquidity params, detail on `IOrderManager.RemoveLiquidityParams`
    /// @return response Response of remove liquidity
    function removeLiquidity(RemoveLiquidityParams calldata params)
        external
        returns (RemoveLiquidityResponse memory response);

    /// @notice Used to get all the order ids of the trader for that market
    /// @param trader User address
    /// @param baseToken base token address
    /// @return orderIds all the order id of the user
    function getCurrentOrderIdsMap(address trader, address baseToken)
        external
        view
        returns (bytes32[] memory orderIds);

    /// @notice Used to get all the order amounts in the pool
    /// @param trader User address
    /// @param baseToken base token address
    /// @param base if true only include base token amount in pool otherwise only include quote token amount in pool
    /// @return amountInPool Gives the total amount of a particular token in the pool for the user
    function getTotalOrdersAmountInPool(
        address trader,
        address baseToken,
        bool base
    ) external view returns (uint256 amountInPool);

    function getAmountInPoolByOrderId(bytes32 orderId, bool base)
        external
        view
        returns (uint256 orderAmount);

    /**
     * @notice Calculates current token amount inside the specific pool of uniswapV3Pool for a trader
     * @param baseToken base token address
     * @param orderId order id
     * @param base  true: get base amount, false: get quote amount
     * @return tokenAmountInPool returns all token inside pool amount for a particular token
     */
    function getCurrentTotalTokenAmountInPoolByOrderId(
        address baseToken,
        bytes32 orderId,
        bool base
    ) external view returns (uint256 tokenAmountInPool);

    /**
     *@notice  to get the total collateral used in orders
     *@param trader address of the trader
     *@return collateral total collateral
     */
    function getTotalCollateralForOrders(address trader)
        external
        view
        returns (uint256 collateral);

    /**
     *@notice  to get the info of the order
     *@param orderId order is of the liquidity position
     *@return info order info
     */
    function getCurrentOrderMap(bytes32 orderId)
        external
        view
        returns (OrderInfo memory info);

    /**
     * @notice Calculates unique order ID
     * @param trader Address of the trader
     * @param baseToken Base token Address
     * @param lowerTick  Lower tick of liquidity range
     * @param upperTick  Upper tick of liquidity range
     * @return bytes32 unique hash/ID of that order
     */
    function calcOrderID(
        address trader,
        address baseToken,
        int24 lowerTick,
        int24 upperTick
    ) external pure returns (bytes32);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;
pragma abicoder v2;

interface IOddzMarket {

    struct MarketData {
        address pool;
        uint24 exchangeFee;
        uint24 uniswapFee;
    }

     /// @notice Get the pool address (UNIv3 pool) by given base token address
    /// @param baseToken The address of the base token
    /// @return pool The address of the pool
    function fetchPool(address baseToken) external view returns (address pool);

    /// @notice Get max allowed orders per market
    /// @return maxOrdersPerMarket The max allowed orders per market
    function getMaxOrdersPerMarket() external view returns (uint8 maxOrdersPerMarket);

    /**
    * @notice This is the view function which returns the market data.
    * @param _bToken tokenA One of the two tokens in the desired pool
    * @return _data market data of pool and various fees.
    */
    function fetchMarketData(address _bToken) external view returns (MarketData memory _data) ;

    
    /**
    * @notice get total market added.
    */
    function addedMarket() external view returns (address[] memory);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.6;

/**
 * @dev copy from "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol"
 * and rename to avoid naming conflict with uniswap
 */
library OddzSafeCast {
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
    function toUint128(uint256 value) internal pure returns (uint128 returnValue) {
        require(((returnValue = uint128(value)) == value), "SafeCast: value doesn't fit in 128 bits");
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
    function toUint64(uint256 value) internal pure returns (uint64 returnValue) {
        require(((returnValue = uint64(value)) == value), "SafeCast: value doesn't fit in 64 bits");
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
    function toUint32(uint256 value) internal pure returns (uint32 returnValue) {
        require(((returnValue = uint32(value)) == value), "SafeCast: value doesn't fit in 32 bits");
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
    function toUint16(uint256 value) internal pure returns (uint16 returnValue) {
        require(((returnValue = uint16(value)) == value), "SafeCast: value doesn't fit in 16 bits");
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
    function toUint8(uint256 value) internal pure returns (uint8 returnValue) {
        require(((returnValue = uint8(value)) == value), "SafeCast: value doesn't fit in 8 bits");
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
    function toInt128(int256 value) internal pure returns (int128 returnValue) {
        require(((returnValue = int128(value)) == value), "SafeCast: value doesn't fit in 128 bits");
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
    function toInt64(int256 value) internal pure returns (int64 returnValue) {
        require(((returnValue = int64(value)) == value), "SafeCast: value doesn't fit in 64 bits");
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
    function toInt32(int256 value) internal pure returns (int32 returnValue) {
        require(((returnValue = int32(value)) == value), "SafeCast: value doesn't fit in 32 bits");
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
    function toInt16(int256 value) internal pure returns (int16 returnValue) {
        require(((returnValue = int16(value)) == value), "SafeCast: value doesn't fit in 16 bits");
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
    function toInt8(int256 value) internal pure returns (int8 returnValue) {
        require(((returnValue = int8(value)) == value), "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }


    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 returnValue) {
        require(((returnValue = int24(value)) == value), "SafeCast: value doesn't fit in an 24 bits");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract OddzOwnable is ContextUpgradeable {

    address public owner;
    address public nominatedOwner;

    // __gap is reserved storage for adding more variables
    uint256[50] private __gap;

    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner);

    /**
     * @dev Checks the current caller is owner or not.If not throws error
     */
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable:Caller is not the owner");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __OddzOwnable_init() internal initializer {
        __Context_init();
        address deployer = _msgSender();
        owner = deployer;
        emit OwnershipTransferred(address(0), deployer);
    }

    /**
     * @dev For renouncing the ownership , After calling this ,ownership will be 
     *  transfered to zero address 
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
        nominatedOwner = address(0);
    }

    /**
     * @dev for nominating a new owner.Can only be called by existing owner
     * @param _newOwner New owner address
     */
    function nominateNewOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Ownable: newOwner can not be zero addresss");
    
        require(_newOwner != owner, "Ownable: newOwner can not be same as current owner");
        // same as candidate
        require(_newOwner != nominatedOwner, "Ownable : already nominated");

        nominatedOwner = _newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_candidate`).
     * Can only be called by the new owner.
     */
    function AcceptOwnership() external {
    
        require(nominatedOwner != address(0), "Ownable: No one is nominated");
        require(nominatedOwner == _msgSender(), "Ownable: You are not nominated");

        // emitting event first to avoid caching values
        emit OwnershipTransferred(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "../uniswap/IUniswapV3Pool.sol";
import "../uniswap/IUniswapV3Factory.sol";
import "../uniswap/TickMath.sol";
import "../uniswap/LiquidityAmounts.sol";
import "../uniswap/PoolAddress.sol";
import "../uniswap/BitMath.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "../maths/OddzSafeCast.sol";
import "../maths/OddzMath.sol";

library UniswapInteractor {
    using SafeMathUpgradeable for uint256;
    using OddzMath for int256;
    using OddzMath for uint256;
    using OddzSafeCast for uint256;
    using OddzSafeCast for int256;

    //
    // STRUCT
    //

    struct AddLiquidityParams {
        address pool;
        int24 lowerTick;
        int24 upperTick;
        uint256 base;
        uint256 quote;
        bytes data;
    }

    struct AddLiquidityResponse {
        uint256 base;
        uint256 quote;
        uint128 liquidity;
    }

    struct RemoveLiquidityParams {
        address pool;
        address recipient;
        int24 lowerTick;
        int24 upperTick;
        uint128 liquidity;
    }

    /// @param base amount of base token received from burning the liquidity (excl. fee)
    /// @param quote amount of quote token received from burning the liquidity (excl. fee)
    struct RemoveLiquidityResponse {
        uint256 base;
        uint256 quote;
    }

    struct SwapState {
        int24 tick;
        uint160 sqrtPriceX96;
        int256 amountSpecifiedRemaining;
        uint256 feeGrowthGlobalX128;
        uint128 liquidity;
    }

    struct SwapParams {
        address pool;
        address recipient;
        bool isShort;
        bool isExactInput;
        uint256 specifiedAmount;
        uint160 sqrtPriceLimitX96;
        bytes data;
    }



    //
    // CONSTANT
    //

    uint256 internal constant _DUST = 10;

    //
    // INTERNAL NON-VIEW
    //

    function addLiquidity(AddLiquidityParams memory params)
        internal
        returns (AddLiquidityResponse memory)
    {
        (uint160 sqrtMarkPrice, , , , , , ) = fetchSlot0(params.pool);

        // get the equivalent amount of liquidity from amount0 & amount1 with current price
        uint128 liquidity = LiquidityAmounts.getLiquidityForAmounts(
            sqrtMarkPrice,
            TickMath.getSqrtRatioAtTick(params.lowerTick),
            TickMath.getSqrtRatioAtTick(params.upperTick),
            params.base,
            params.quote
        );

        (uint256 addedAmount0, uint256 addedAmount1) = IUniswapV3Pool(
            params.pool
        ).mint(
                address(this),
                params.lowerTick,
                params.upperTick,
                liquidity,
                params.data
            );

        return
            AddLiquidityResponse({
                base: addedAmount0,
                quote: addedAmount1,
                liquidity: liquidity
            });
    }

    function removeLiquidity(RemoveLiquidityParams memory params)
        internal
        returns (RemoveLiquidityResponse memory)
    {
        // call burn(), which only updates tokensOwed instead of transferring the tokens
        (uint256 amount0Burned, uint256 amount1Burned) = IUniswapV3Pool(
            params.pool
        ).burn(params.lowerTick, params.upperTick, params.liquidity);

        // call collect() to transfer tokens to CH
        // we don't care about the returned values here as they include:
        // 1. every maker's fee in the same range (ClearingHouse is the only maker in the pool's perspective)
        // 2. the amount of token equivalent to liquidity burned
        IUniswapV3Pool(params.pool).collect(
            params.recipient,
            params.lowerTick,
            params.upperTick,
            type(uint128).max,
            type(uint128).max
        );

        return
            RemoveLiquidityResponse({
                base: amount0Burned,
                quote: amount1Burned
            });
    }

    function swap(SwapParams memory params) internal returns (uint256 base,uint256 quote) {
        // UniswapV3Pool uses the sign to determine isExactInput or not
        int256 specifiedAmount = params.isExactInput ? params.specifiedAmount.toInt256() : params.specifiedAmount.neg256();

        // signedAmount0 & signedAmount1 are delta amounts, in the perspective of the pool
        // > 0: pool gets; user pays
        // < 0: pool provides; user gets
        (int256 signedAmount0, int256 signedAmount1) =
            IUniswapV3Pool(params.pool).swap(
                params.recipient,
                params.isShort,
                specifiedAmount,
                params.sqrtPriceLimitX96 == 0
                    ? (params.isShort ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                    : params.sqrtPriceLimitX96,
                params.data
            );

        (uint256 amount0, uint256 amount1) = (signedAmount0.abs(), signedAmount1.abs());

        // isExactInput = true, isZeroForOne = true => exact token0
        // isExactInput = false, isZeroForOne = false => exact token0
        // isExactInput = false, isZeroForOne = true => exact token1
        // isExactInput = true, isZeroForOne = false => exact token1
        uint256 exactAmount = params.isExactInput == params.isShort ? amount0 : amount1;

        // if no price limit, require the full output amount as it's technically possible for amounts to not match
        // UB_UOA: unmatched output amount
        if (!params.isExactInput && params.sqrtPriceLimitX96 == 0) {
            require(
                (exactAmount > params.specifiedAmount ? exactAmount.sub(params.specifiedAmount) : params.specifiedAmount.sub(exactAmount)) < _DUST,
                "UB_UOA"
            );
            return params.isShort ? (amount0, params.specifiedAmount) : (params.specifiedAmount, amount1);
        }

        return (amount0, amount1);
    }

    function getTickLiquidityNet(address pool, int24 tick) internal view returns (int128 liquidityNet) {
        (, liquidityNet, , , , , , ) = IUniswapV3Pool(pool).ticks(tick);
    }

    function fetchSlot0(address pool)
        internal
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        )
    {
        return IUniswapV3Pool(pool).slot0();
    }

     /**
    * @notice This function provide address of the pool created on uniswapV3.
    * @return The pool address for a given pair of tokens
    */  
    function fetchPoolFromUniV3(
        address factory,
        address QToken,
        address BToken,
        uint24 feeAccured
    ) internal view returns (address) {
        PoolAddress.PoolKey memory VariablePool = PoolAddress.getPoolKey(QToken, BToken, feeAccured);
        return IUniswapV3Factory(factory).getPool(VariablePool.token0, VariablePool.token1, feeAccured);
    }

    function getSwapState(
        address pool,
        int256 signedScaledAmountForReplaySwap,
        uint256 feeGrowthGlobalX128
    ) internal view returns (SwapState memory) {
        (uint160 sqrtMarkPrice, int24 tick, , , , , ) = fetchSlot0(pool);
        uint128 liquidity = IUniswapV3Pool(pool).liquidity();
        return
            SwapState({
                tick: tick,
                sqrtPriceX96: sqrtMarkPrice,
                amountSpecifiedRemaining: signedScaledAmountForReplaySwap,
                feeGrowthGlobalX128: feeGrowthGlobalX128,
                liquidity: liquidity
            });
    }

    function getTickSpacing(address pool) internal view returns (int24 tickSpacing) {
        tickSpacing = IUniswapV3Pool(pool).tickSpacing();
    }

     // copied from UniswapV3-core
    /// @param isBaseToQuote originally lte, meaning that the next tick < the current tick
    function getNextInitializedTickWithinOneWord(
        address pool,
        int24 tick,
        int24 tickSpacing,
        bool isBaseToQuote
    ) internal view returns (int24 next, bool initialized) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

        if (isBaseToQuote) {
            (int16 wordPos, uint8 bitPos) = _getPositionOfInitializedTickWithinOneWord(compressed);
            // all the 1s at or to the right of the current bitPos
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = _getTickBitmap(pool, wordPos) & mask;

            // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed - int24(bitPos - BitMath.mostSignificantBit(masked))) * tickSpacing
                : (compressed - int24(bitPos)) * tickSpacing;
        } else {
            // start from the word of the next tick, since the current tick state doesn't matter
            (int16 wordPos, uint8 bitPos) = _getPositionOfInitializedTickWithinOneWord(compressed + 1);
            // all the 1s at or to the left of the bitPos
            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = _getTickBitmap(pool, wordPos) & mask;

            // if there are no initialized ticks to the left of the current tick, return leftmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed + 1 + int24(BitMath.leastSignificantBit(masked) - bitPos)) * tickSpacing
                : (compressed + 1 + int24(type(uint8).max - bitPos)) * tickSpacing;
        }
    }

     function _getTickBitmap(address pool, int16 wordPos) private view returns (uint256 tickBitmap) {
        return IUniswapV3Pool(pool).tickBitmap(wordPos);
    }

    /// @dev this function is Uniswap's TickBitmap.position()
    function _getPositionOfInitializedTickWithinOneWord(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(tick % 256);
    }

    
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

library Tick {
    struct GrowthInfo {
        uint256 feeX128;
        int256 twPremiumX96;
        int256 twPremiumDivBySqrtPriceX96;
    }

    struct FundingGrowthRangeInfo {
        int256 twPremiumGrowthInsideX96;
        int256 twPremiumGrowthBelowX96;
        int256 twPremiumDivBySqrtPriceGrowthInsideX96;
    }

    /// @dev call this function only if (liquidityGrossBefore == 0 && liquidityDelta != 0)
    /// @dev per Uniswap: we assume that all growths before a tick is initialized happen "below" the tick
    function initialize(
        mapping(int24 => GrowthInfo) storage self,
        int24 tick,
        int24 currentTick,
        GrowthInfo memory globalGrowthInfo
    ) internal {
        if (tick <= currentTick) {
            GrowthInfo storage growthInfo = self[tick];
            growthInfo.feeX128 = globalGrowthInfo.feeX128;
            growthInfo.twPremiumX96 = globalGrowthInfo.twPremiumX96;
            growthInfo.twPremiumDivBySqrtPriceX96 = globalGrowthInfo.twPremiumDivBySqrtPriceX96;
        }
    }

    function cross(
        mapping(int24 => GrowthInfo) storage self,
        int24 tick,
        GrowthInfo memory globalGrowthInfo
    ) internal {
        GrowthInfo storage growthInfo = self[tick];
        growthInfo.feeX128 = globalGrowthInfo.feeX128 - growthInfo.feeX128;
        growthInfo.twPremiumX96 = globalGrowthInfo.twPremiumX96 - growthInfo.twPremiumX96;
        growthInfo.twPremiumDivBySqrtPriceX96 =
            globalGrowthInfo.twPremiumDivBySqrtPriceX96 -
            growthInfo.twPremiumDivBySqrtPriceX96;
    }

    function clear(mapping(int24 => GrowthInfo) storage self, int24 tick) internal {
        delete self[tick];
    }

    /// @dev all values in this function are scaled by 2^128 (X128), thus adding the suffix to external params
    /// @return feeGrowthInsideX128 this value can underflow per Tick.feeGrowthOutside specs
    function getFeeGrowthInsideX128(
        mapping(int24 => GrowthInfo) storage self,
        int24 lowerTick,
        int24 upperTick,
        int24 currentTick,
        uint256 feeGrowthGlobalX128
    ) internal view returns (uint256 feeGrowthInsideX128) {
        uint256 lowerFeeGrowthOutside = self[lowerTick].feeX128;
        uint256 upperFeeGrowthOutside = self[upperTick].feeX128;

        uint256 feeGrowthBelow =
            currentTick >= lowerTick ? lowerFeeGrowthOutside : feeGrowthGlobalX128 - lowerFeeGrowthOutside;
        uint256 feeGrowthAbove =
            currentTick < upperTick ? upperFeeGrowthOutside : feeGrowthGlobalX128 - upperFeeGrowthOutside;

        return feeGrowthGlobalX128 - feeGrowthBelow - feeGrowthAbove;
    }

    /// @return all values returned can underflow per feeGrowthOutside specs;
    ///         see https://www.notion.so/32990980ba8b43859f6d2541722a739b
    function getAllFundingGrowth(
        mapping(int24 => GrowthInfo) storage self,
        int24 lowerTick,
        int24 upperTick,
        int24 currentTick,
        int256 twPremiumGrowthGlobalX96,
        int256 twPremiumDivBySqrtPriceGrowthGlobalX96
    ) internal view returns (FundingGrowthRangeInfo memory) {
        GrowthInfo storage lowerTickGrowthInfo = self[lowerTick];
        GrowthInfo storage upperTickGrowthInfo = self[upperTick];

        int256 lowerTwPremiumGrowthOutsideX96 = lowerTickGrowthInfo.twPremiumX96;
        int256 upperTwPremiumGrowthOutsideX96 = upperTickGrowthInfo.twPremiumX96;

        FundingGrowthRangeInfo memory fundingGrowthRangeInfo;
        fundingGrowthRangeInfo.twPremiumGrowthBelowX96 = currentTick >= lowerTick
            ? lowerTwPremiumGrowthOutsideX96
            : twPremiumGrowthGlobalX96 - lowerTwPremiumGrowthOutsideX96;
        int256 twPremiumGrowthAboveX96 =
            currentTick < upperTick
                ? upperTwPremiumGrowthOutsideX96
                : twPremiumGrowthGlobalX96 - upperTwPremiumGrowthOutsideX96;

        int256 lowerTwPremiumDivBySqrtPriceGrowthOutsideX96 = lowerTickGrowthInfo.twPremiumDivBySqrtPriceX96;
        int256 upperTwPremiumDivBySqrtPriceGrowthOutsideX96 = upperTickGrowthInfo.twPremiumDivBySqrtPriceX96;

        int256 twPremiumDivBySqrtPriceGrowthBelowX96 =
            currentTick >= lowerTick
                ? lowerTwPremiumDivBySqrtPriceGrowthOutsideX96
                : twPremiumDivBySqrtPriceGrowthGlobalX96 - lowerTwPremiumDivBySqrtPriceGrowthOutsideX96;
        int256 twPremiumDivBySqrtPriceGrowthAboveX96 =
            currentTick < upperTick
                ? upperTwPremiumDivBySqrtPriceGrowthOutsideX96
                : twPremiumDivBySqrtPriceGrowthGlobalX96 - upperTwPremiumDivBySqrtPriceGrowthOutsideX96;

        fundingGrowthRangeInfo.twPremiumGrowthInsideX96 =
            twPremiumGrowthGlobalX96 -
            fundingGrowthRangeInfo.twPremiumGrowthBelowX96 -
            twPremiumGrowthAboveX96;
        fundingGrowthRangeInfo.twPremiumDivBySqrtPriceGrowthInsideX96 =
            twPremiumDivBySqrtPriceGrowthGlobalX96 -
            twPremiumDivBySqrtPriceGrowthBelowX96 -
            twPremiumDivBySqrtPriceGrowthAboveX96;

        return fundingGrowthRangeInfo;
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

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import './LowGasSafeMath.sol';
import './SafeCast.sol';

import './FullMath.sol';
import './UnsafeMath.sol';
import './FixedPoint96.sol';

/// @title Functions based on Q64.96 sqrt price and liquidity
/// @notice Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
library SqrtPriceMath {
    using LowGasSafeMath for uint256;
    using SafeCast for uint256;

    /// @notice Gets the next sqrt price given a delta of token0
    /// @dev Always rounds up, because in the exact output case (increasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (decreasing price) we need to move the
    /// price less in order to not send too much output.
    /// The most precise formula for this is liquidity * sqrtPX96 / (liquidity +- amount * sqrtPX96),
    /// if this is impossible because of overflow, we calculate liquidity / (liquidity / sqrtPX96 +- amount).
    /// @param sqrtPX96 The starting price, i.e. before accounting for the token0 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token0 to add or remove from virtual reserves
    /// @param add Whether to add or remove the amount of token0
    /// @return The price after adding or removing amount, depending on add
    function getNextSqrtPriceFromAmount0RoundingUp(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // we short circuit amount == 0 because the result is otherwise not guaranteed to equal the input price
        if (amount == 0) return sqrtPX96;
        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;

        if (add) {
            uint256 product;
            if ((product = amount * sqrtPX96) / amount == sqrtPX96) {
                uint256 denominator = numerator1 + product;
                if (denominator >= numerator1)
                    // always fits in 160 bits
                    return uint160(FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator));
            }

            return uint160(UnsafeMath.divRoundingUp(numerator1, (numerator1 / sqrtPX96).add(amount)));
        } else {
            uint256 product;
            // if the product overflows, we know the denominator underflows
            // in addition, we must check that the denominator does not underflow
            require((product = amount * sqrtPX96) / amount == sqrtPX96 && numerator1 > product);
            uint256 denominator = numerator1 - product;
            return FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator).toUint160();
        }
    }

    /// @notice Gets the next sqrt price given a delta of token1
    /// @dev Always rounds down, because in the exact output case (decreasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (increasing price) we need to move the
    /// price less in order to not send too much output.
    /// The formula we compute is within <1 wei of the lossless version: sqrtPX96 +- amount / liquidity
    /// @param sqrtPX96 The starting price, i.e., before accounting for the token1 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token1 to add, or remove, from virtual reserves
    /// @param add Whether to add, or remove, the amount of token1
    /// @return The price after adding or removing `amount`
    function getNextSqrtPriceFromAmount1RoundingDown(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // if we're adding (subtracting), rounding down requires rounding the quotient down (up)
        // in both cases, avoid a mulDiv for most inputs
        if (add) {
            uint256 quotient =
                (
                    amount <= type(uint160).max
                        ? (amount << FixedPoint96.RESOLUTION) / liquidity
                        : FullMath.mulDiv(amount, FixedPoint96.Q96, liquidity)
                );

            return uint256(sqrtPX96).add(quotient).toUint160();
        } else {
            uint256 quotient =
                (
                    amount <= type(uint160).max
                        ? UnsafeMath.divRoundingUp(amount << FixedPoint96.RESOLUTION, liquidity)
                        : FullMath.mulDivRoundingUp(amount, FixedPoint96.Q96, liquidity)
                );

            require(sqrtPX96 > quotient);
            // always fits 160 bits
            return uint160(sqrtPX96 - quotient);
        }
    }

    /// @notice Gets the next sqrt price given an input amount of token0 or token1
    /// @dev Throws if price or liquidity are 0, or if the next price is out of bounds
    /// @param sqrtPX96 The starting price, i.e., before accounting for the input amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountIn How much of token0, or token1, is being swapped in
    /// @param zeroForOne Whether the amount in is token0 or token1
    /// @return sqrtQX96 The price after adding the input amount to token0 or token1
    function getNextSqrtPriceFromInput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountIn,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        // round to make sure that we don't pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountIn, true)
                : getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountIn, true);
    }

    /// @notice Gets the next sqrt price given an output amount of token0 or token1
    /// @dev Throws if price or liquidity are 0 or the next price is out of bounds
    /// @param sqrtPX96 The starting price before accounting for the output amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountOut How much of token0, or token1, is being swapped out
    /// @param zeroForOne Whether the amount out is token0 or token1
    /// @return sqrtQX96 The price after removing the output amount of token0 or token1
    function getNextSqrtPriceFromOutput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountOut,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        // round to make sure that we pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountOut, false)
                : getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountOut, false);
    }

    /// @notice Gets the amount0 delta between two prices
    /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
    /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up or down
    /// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

        require(sqrtRatioAX96 > 0);

        return
            roundUp
                ? UnsafeMath.divRoundingUp(
                    FullMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96),
                    sqrtRatioAX96
                )
                : FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
    }

    /// @notice Gets the amount1 delta between two prices
    /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up, or down
    /// @return amount1 Amount of token1 required to cover a position of size liquidity between the two passed prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            roundUp
                ? FullMath.mulDivRoundingUp(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96)
                : FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Helper that gets signed token0 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount0 delta
    /// @return amount0 Amount of token0 corresponding to the passed liquidityDelta between the two prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount0) {
        return
            liquidity < 0
                ? -getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                : getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
    }

    /// @notice Helper that gets signed token1 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount1 delta
    /// @return amount1 Amount of token1 corresponding to the passed liquidityDelta between the two prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount1) {
        return
            liquidity < 0
                ? -getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                : getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(uint160(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title BitMath
/// @dev This library provides functionality for computing bit properties of an unsigned integer
library BitMath {
    /// @notice Returns the index of the most significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
    /// @param x the value for which to compute the most significant bit, must be greater than 0
    /// @return r the index of the most significant bit
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    /// @notice Returns the index of the least significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
    /// @param x the value for which to compute the least significant bit, must be greater than 0
    /// @return r the index of the least significant bit
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        r = 255;
        if (x & type(uint128).max > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & type(uint64).max > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & type(uint32).max > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & type(uint16).max > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & type(uint8).max > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.6;

import "../uniswap/FixedPoint96.sol";
import "../uniswap/FullMath.sol";
import "./OddzSafeCast.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";

library OddzMath {
    using OddzSafeCast for int256;
    using SignedSafeMathUpgradeable for int256;
    using SafeMathUpgradeable for uint256;

    function formatSqrtPriceX96ToPriceX96(uint160 sqrtPriceX96) internal pure returns (uint256) {
        return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }

    function formatX10_18ToX96(uint256 valueX10_18) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX10_18, FixedPoint96.Q96, 1 ether);
    }

    function formatX96ToX10_18(uint256 valueX96) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX96, 1 ether, FixedPoint96.Q96);
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function abs(int256 value) internal pure returns (uint256) {
        return value >= 0 ? value.toUint256() : neg256(value).toUint256();
    }

    function neg256(int256 a) internal pure returns (int256) {
        require(a > -2**255, "PerpMath: inversion overflow");
        return -a;
    }

    function neg256(uint256 a) internal pure returns (int256) {
        return -OddzSafeCast.toInt256(a);
    }

    function neg128(int128 a) internal pure returns (int128) {
        require(a > -2**127, "PerpMath: inversion overflow");
        return -a;
    }

    function neg128(uint128 a) internal pure returns (int128) {
        return -OddzSafeCast.toInt128(a);
    }

    function divBy10_18(int256 value) internal pure returns (int256) {
        // no overflow here
        return value / (1 ether);
    }

    function divBy10_18(uint256 value) internal pure returns (uint256) {
        // no overflow here
        return value / (1 ether);
    }

    function mulRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return FullMath.mulDiv(value, ratio, 1e6);
    }

    /// @param denominator cannot be 0 and is checked in FullMath.mulDiv()
    function mulDiv(
        int256 a,
        int256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        uint256 unsignedA = a < 0 ? uint256(neg256(a)) : uint256(a);
        uint256 unsignedB = b < 0 ? uint256(neg256(b)) : uint256(b);
        bool negative = ((a < 0 && b > 0) || (a > 0 && b < 0)) ? true : false;

        uint256 unsignedResult = FullMath.mulDiv(unsignedA, unsignedB, denominator);

        result = negative ? neg256(unsignedResult) : OddzSafeCast.toInt256(unsignedResult);

        return result;
    }
}