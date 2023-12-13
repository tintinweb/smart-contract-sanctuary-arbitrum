pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



interface IReserves {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1);

    function getFees() external view returns (uint256 fee0, uint256 fee1);
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



import './IERC20.sol';

interface ITwapERC20 is IERC20 {
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



interface ITwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    event OwnerSet(address owner);

    function owner() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB,
        address oracle,
        address trader
    ) external returns (address pair);

    function setOwner(address) external;

    function setMintFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external;

    function setBurnFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external;

    function setSwapFee(
        address tokenA,
        address tokenB,
        uint256 fee
    ) external;

    function setOracle(
        address tokenA,
        address tokenB,
        address oracle
    ) external;

    function setTrader(
        address tokenA,
        address tokenB,
        address trader
    ) external;

    function collect(
        address tokenA,
        address tokenB,
        address to
    ) external;

    function withdraw(
        address tokenA,
        address tokenB,
        uint256 amount,
        address to
    ) external;
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



interface ITwapOracle {
    event OwnerSet(address owner);
    event UniswapPairSet(address uniswapPair);

    function decimalsConverter() external view returns (int256);

    function xDecimals() external view returns (uint8);

    function yDecimals() external view returns (uint8);

    function owner() external view returns (address);

    function uniswapPair() external view returns (address);

    function getPriceInfo() external view returns (uint256 priceAccumulator, uint256 priceTimestamp);

    function getSpotPrice() external view returns (uint256);

    function getAveragePrice(uint256 priceAccumulator, uint256 priceTimestamp) external view returns (uint256);

    function setOwner(address _owner) external;

    function setUniswapPair(address _uniswapPair) external;

    function tradeX(
        uint256 xAfter,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view returns (uint256 yAfter);

    function tradeY(
        uint256 yAfter,
        uint256 yBefore,
        uint256 xBefore,
        bytes calldata data
    ) external view returns (uint256 xAfter);

    function depositTradeXIn(
        uint256 xLeft,
        uint256 xBefore,
        uint256 yBefore,
        bytes calldata data
    ) external view returns (uint256 xIn);

    function depositTradeYIn(
        uint256 yLeft,
        uint256 yBefore,
        uint256 xBefore,
        bytes calldata data
    ) external view returns (uint256 yIn);

    function getSwapAmount0Out(
        uint256 swapFee,
        uint256 amount1In,
        bytes calldata data
    ) external view returns (uint256 amount0Out);

    function getSwapAmount1Out(
        uint256 swapFee,
        uint256 amount0In,
        bytes calldata data
    ) external view returns (uint256 amount1Out);

    function getSwapAmountInMaxOut(
        bool inverse,
        uint256 swapFee,
        uint256 _amountOut,
        bytes calldata data
    ) external view returns (uint256 amountIn, uint256 amountOut);

    function getSwapAmountInMinOut(
        bool inverse,
        uint256 swapFee,
        uint256 _amountOut,
        bytes calldata data
    ) external view returns (uint256 amountIn, uint256 amountOut);
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



import './ITwapERC20.sol';
import './IReserves.sol';

interface ITwapPair is ITwapERC20, IReserves {
    event Mint(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 liquidityOut, address indexed to);
    event Burn(address indexed sender, uint256 amount0Out, uint256 amount1Out, uint256 liquidityIn, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event SetMintFee(uint256 fee);
    event SetBurnFee(uint256 fee);
    event SetSwapFee(uint256 fee);
    event SetOracle(address account);
    event SetTrader(address trader);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function oracle() external view returns (address);

    function trader() external view returns (address);

    function mintFee() external view returns (uint256);

    function setMintFee(uint256 fee) external;

    function mint(address to) external returns (uint256 liquidity);

    function burnFee() external view returns (uint256);

    function setBurnFee(uint256 fee) external;

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swapFee() external view returns (uint256);

    function setSwapFee(uint256 fee) external;

    function setOracle(address account) external;

    function setTrader(address account) external;

    function collect(address to) external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function sync() external;

    function initialize(
        address _token0,
        address _token1,
        address _oracle,
        address _trader
    ) external;

    function getSwapAmount0In(uint256 amount1Out, bytes calldata data) external view returns (uint256 swapAmount0In);

    function getSwapAmount1In(uint256 amount0Out, bytes calldata data) external view returns (uint256 swapAmount1In);

    function getSwapAmount0Out(uint256 amount1In, bytes calldata data) external view returns (uint256 swapAmount0Out);

    function getSwapAmount1Out(uint256 amount0In, bytes calldata data) external view returns (uint256 swapAmount1Out);

    function getDepositAmount0In(uint256 amount0, bytes calldata data) external view returns (uint256 depositAmount0In);

    function getDepositAmount1In(uint256 amount1, bytes calldata data) external view returns (uint256 depositAmount1In);
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity 0.7.6;
pragma abicoder v2;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9




import './SafeMath.sol';
import '../libraries/Math.sol';
import '../interfaces/ITwapFactory.sol';
import '../interfaces/ITwapPair.sol';
import '../interfaces/ITwapOracle.sol';
import '../libraries/TokenShares.sol';


library Orders {
    using SafeMath for uint256;
    using TokenShares for TokenShares.Data;
    using TransferHelper for address;

    enum OrderType {
        Empty,
        Deposit,
        Withdraw,
        Sell,
        Buy
    }
    enum OrderStatus {
        NonExistent,
        EnqueuedWaiting,
        EnqueuedReady,
        ExecutedSucceeded,
        ExecutedFailed,
        Canceled
    }

    event DepositEnqueued(uint256 indexed orderId, Order order);
    event WithdrawEnqueued(uint256 indexed orderId, Order order);
    event SellEnqueued(uint256 indexed orderId, Order order);
    event BuyEnqueued(uint256 indexed orderId, Order order);

    event OrderTypesDisabled(address pair, Orders.OrderType[] orderTypes, bool disabled);

    event RefundFailed(address indexed to, address indexed token, uint256 amount, bytes data);

    // Note on gas estimation for the full order execution in the UI:
    // Add (ORDER_BASE_COST + token transfer costs) to the actual gas usage
    // of the TwapDelay._execute* functions when updating gas cost in the UI.
    // Remember that ETH unwrap is part of those functions. It is optional,
    // but also needs to be included in the estimate.

    uint256 public constant ETHER_TRANSFER_COST = ETHER_TRANSFER_CALL_COST + 2600 + 1504; // Std cost + EIP-2929 acct access cost + Gnosis Safe receive ETH cost
    uint256 private constant BOT_ETHER_TRANSFER_COST = 10_000;
    uint256 private constant BUFFER_COST = 10_000;
    uint256 private constant ORDER_EXECUTED_EVENT_COST = 3700;
    uint256 private constant EXECUTE_PREPARATION_COST = 30_000; // dequeue + gas calculation before calls to _execute* functions

    uint256 public constant ETHER_TRANSFER_CALL_COST = 10_000;
    uint256 public constant PAIR_TRANSFER_COST = 55_000;
    uint256 public constant REFUND_BASE_COST =
        BOT_ETHER_TRANSFER_COST + ETHER_TRANSFER_COST + BUFFER_COST + ORDER_EXECUTED_EVENT_COST;
    uint256 public constant ORDER_BASE_COST = EXECUTE_PREPARATION_COST + REFUND_BASE_COST;

    // Masks used for setting order disabled
    // Different bits represent different order types
    uint8 private constant DEPOSIT_MASK = uint8(1 << uint8(OrderType.Deposit)); //   00000010
    uint8 private constant WITHDRAW_MASK = uint8(1 << uint8(OrderType.Withdraw)); // 00000100
    uint8 private constant SELL_MASK = uint8(1 << uint8(OrderType.Sell)); //         00001000
    uint8 private constant BUY_MASK = uint8(1 << uint8(OrderType.Buy)); //           00010000

    address public constant FACTORY_ADDRESS = 0x717EF162cf831db83c51134734A15D1EBe9E516a; 
    uint256 public constant MAX_GAS_LIMIT = 5000000; 
    uint256 public constant GAS_PRICE_INERTIA = 20000000; 
    uint256 public constant MAX_GAS_PRICE_IMPACT = 1000000; 
    uint256 public constant DELAY = 1800; 

    address public constant NATIVE_CURRENCY_SENTINEL = address(0); // A sentinel value for the native currency to distinguish it from ERC20 tokens

    struct Data {
        uint256 newestOrderId;
        uint256 lastProcessedOrderId;
        mapping(uint256 => bytes32) orderQueue;
        uint256 gasPrice;
        mapping(uint256 => bool) canceled;
        // Bit on specific positions indicates whether order type is disabled (1) or enabled (0) on specific pair
        mapping(address => uint8) orderTypesDisabled;
        mapping(uint256 => bool) refundFailed;
    }

    struct Order {
        uint256 orderId;
        OrderType orderType;
        bool inverted;
        uint256 validAfterTimestamp;
        bool unwrap;
        uint256 timestamp;
        uint256 gasLimit;
        uint256 gasPrice;
        uint256 liquidity;
        uint256 value0; // Deposit: share0, Withdraw: amount0Min, Sell: shareIn, Buy: shareInMax
        uint256 value1; // Deposit: share1, Withdraw: amount1Min, Sell: amountOutMin, Buy: amountOut
        address token0; // Sell: tokenIn, Buy: tokenIn
        address token1; // Sell: tokenOut, Buy: tokenOut
        address to;
        uint256 minSwapPrice;
        uint256 maxSwapPrice;
        bool swap;
        uint256 priceAccumulator;
        uint256 amountLimit0;
        uint256 amountLimit1;
    }

    function getOrderStatus(
        Data storage data,
        uint256 orderId,
        uint256 validAfterTimestamp
    ) internal view returns (OrderStatus) {
        if (orderId > data.newestOrderId) {
            return OrderStatus.NonExistent;
        }
        if (data.canceled[orderId]) {
            return OrderStatus.Canceled;
        }
        if (data.refundFailed[orderId]) {
            return OrderStatus.ExecutedFailed;
        }
        if (data.orderQueue[orderId] == bytes32(0)) {
            return OrderStatus.ExecutedSucceeded;
        }
        if (validAfterTimestamp >= block.timestamp) {
            return OrderStatus.EnqueuedWaiting;
        }
        return OrderStatus.EnqueuedReady;
    }

    function getPair(address tokenA, address tokenB) internal view returns (address pair, bool inverted) {
        pair = ITwapFactory(FACTORY_ADDRESS).getPair(tokenA, tokenB);
        require(pair != address(0), 'OS17');
        inverted = tokenA > tokenB;
    }

    function getDepositDisabled(Data storage data, address pair) internal view returns (bool) {
        return data.orderTypesDisabled[pair] & DEPOSIT_MASK != 0;
    }

    function getWithdrawDisabled(Data storage data, address pair) internal view returns (bool) {
        return data.orderTypesDisabled[pair] & WITHDRAW_MASK != 0;
    }

    function getSellDisabled(Data storage data, address pair) internal view returns (bool) {
        return data.orderTypesDisabled[pair] & SELL_MASK != 0;
    }

    function getBuyDisabled(Data storage data, address pair) internal view returns (bool) {
        return data.orderTypesDisabled[pair] & BUY_MASK != 0;
    }

    function setOrderTypesDisabled(
        Data storage data,
        address pair,
        Orders.OrderType[] calldata orderTypes,
        bool disabled
    ) external {
        uint256 orderTypesLength = orderTypes.length;
        uint8 currentSettings = data.orderTypesDisabled[pair];

        uint8 combinedMask;
        for (uint256 i; i < orderTypesLength; ++i) {
            Orders.OrderType orderType = orderTypes[i];
            require(orderType != Orders.OrderType.Empty, 'OS32');
            // zeros with 1 bit set at position specified by orderType
            // e.g. for SELL order type
            // mask for SELL    = 00001000
            // combinedMask     = 00000110 (DEPOSIT and WITHDRAW masks set in previous iterations)
            // the result of OR = 00001110 (DEPOSIT, WITHDRAW and SELL combined mask)
            combinedMask = combinedMask | uint8(1 << uint8(orderType));
        }

        // set/unset a bit accordingly to 'disabled' value
        if (disabled) {
            // OR operation to disable order
            // e.g. for disable DEPOSIT
            // currentSettings   = 00010100 (BUY and WITHDRAW disabled)
            // mask for DEPOSIT  = 00000010
            // the result of OR  = 00010110
            currentSettings = currentSettings | combinedMask;
        } else {
            // AND operation with a mask negation to enable order
            // e.g. for enable DEPOSIT
            // currentSettings   = 00010100 (BUY and WITHDRAW disabled)
            // 0xff              = 11111111
            // mask for Deposit  = 00000010
            // mask negation     = 11111101
            // the result of AND = 00010100
            currentSettings = currentSettings & (combinedMask ^ 0xff);
        }
        require(currentSettings != data.orderTypesDisabled[pair], 'OS01');
        data.orderTypesDisabled[pair] = currentSettings;

        emit OrderTypesDisabled(pair, orderTypes, disabled);
    }

    function markRefundFailed(Data storage data) internal {
        data.refundFailed[data.lastProcessedOrderId] = true;
    }

    /// @dev The passed in order.oderId is ignored and overwritten with the correct value, i.e. an updated data.newestOrderId.
    /// This is done to ensure atomicity of these two actions while optimizing gas usage - adding an order to the queue and incrementing
    /// data.newestOrderId (which should not be done anywhere else in the contract).
    /// Must only be called on verified orders.
    function enqueueOrder(Data storage data, Order memory order) internal {
        order.orderId = ++data.newestOrderId;
        data.orderQueue[order.orderId] = getOrderDigest(order);
    }

    struct DepositParams {
        address token0;
        address token1;
        uint256 amount0;
        uint256 amount1;
        uint256 minSwapPrice;
        uint256 maxSwapPrice;
        bool wrap;
        bool swap;
        address to;
        uint256 gasLimit;
        uint32 submitDeadline;
    }

    function deposit(
        Data storage data,
        DepositParams calldata depositParams,
        TokenShares.Data storage tokenShares
    ) external {
        {
            // scope for checks, avoids stack too deep errors
            uint256 token0TransferCost = getTransferGasCost(depositParams.token0);
            uint256 token1TransferCost = getTransferGasCost(depositParams.token1);
            checkOrderParams(
                depositParams.to,
                depositParams.gasLimit,
                depositParams.submitDeadline,
                ORDER_BASE_COST.add(token0TransferCost).add(token1TransferCost)
            );
        }
        require(depositParams.amount0 != 0 || depositParams.amount1 != 0, 'OS25');
        (address pairAddress, bool inverted) = getPair(depositParams.token0, depositParams.token1);
        require(!getDepositDisabled(data, pairAddress), 'OS46');
        {
            // scope for value, avoids stack too deep errors
            uint256 value = msg.value;

            // allocate gas refund
            if (depositParams.wrap) {
                if (depositParams.token0 == TokenShares.WETH_ADDRESS) {
                    value = msg.value.sub(depositParams.amount0, 'OS1E');
                } else if (depositParams.token1 == TokenShares.WETH_ADDRESS) {
                    value = msg.value.sub(depositParams.amount1, 'OS1E');
                }
            }
            allocateGasRefund(data, value, depositParams.gasLimit);
        }

        uint256 shares0 = tokenShares.amountToShares(
            inverted ? depositParams.token1 : depositParams.token0,
            inverted ? depositParams.amount1 : depositParams.amount0,
            depositParams.wrap
        );
        uint256 shares1 = tokenShares.amountToShares(
            inverted ? depositParams.token0 : depositParams.token1,
            inverted ? depositParams.amount0 : depositParams.amount1,
            depositParams.wrap
        );

        (uint256 priceAccumulator, uint256 timestamp) = ITwapOracle(ITwapPair(pairAddress).oracle()).getPriceInfo();

        Order memory order = Order(
            0,
            OrderType.Deposit,
            inverted,
            timestamp + DELAY, // validAfterTimestamp
            depositParams.wrap,
            timestamp,
            depositParams.gasLimit,
            data.gasPrice,
            0, // liquidity
            shares0,
            shares1,
            inverted ? depositParams.token1 : depositParams.token0,
            inverted ? depositParams.token0 : depositParams.token1,
            depositParams.to,
            depositParams.minSwapPrice,
            depositParams.maxSwapPrice,
            depositParams.swap,
            priceAccumulator,
            inverted ? depositParams.amount1 : depositParams.amount0,
            inverted ? depositParams.amount0 : depositParams.amount1
        );
        enqueueOrder(data, order);

        emit DepositEnqueued(order.orderId, order);
    }

    struct WithdrawParams {
        address token0;
        address token1;
        uint256 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        bool unwrap;
        address to;
        uint256 gasLimit;
        uint32 submitDeadline;
    }

    function withdraw(Data storage data, WithdrawParams calldata withdrawParams) external {
        (address pair, bool inverted) = getPair(withdrawParams.token0, withdrawParams.token1);
        require(!getWithdrawDisabled(data, pair), 'OS0A');
        checkOrderParams(
            withdrawParams.to,
            withdrawParams.gasLimit,
            withdrawParams.submitDeadline,
            ORDER_BASE_COST.add(PAIR_TRANSFER_COST)
        );
        require(withdrawParams.liquidity != 0, 'OS22');

        allocateGasRefund(data, msg.value, withdrawParams.gasLimit);
        pair.safeTransferFrom(msg.sender, address(this), withdrawParams.liquidity);

        Order memory order = Order(
            0,
            OrderType.Withdraw,
            inverted,
            block.timestamp + DELAY, // validAfterTimestamp
            withdrawParams.unwrap,
            0, // timestamp
            withdrawParams.gasLimit,
            data.gasPrice,
            withdrawParams.liquidity,
            inverted ? withdrawParams.amount1Min : withdrawParams.amount0Min,
            inverted ? withdrawParams.amount0Min : withdrawParams.amount1Min,
            inverted ? withdrawParams.token1 : withdrawParams.token0,
            inverted ? withdrawParams.token0 : withdrawParams.token1,
            withdrawParams.to,
            0, // minSwapPrice
            0, // maxSwapPrice
            false, // swap
            0, // priceAccumulator
            0, // amountLimit0
            0 // amountLimit1
        );
        enqueueOrder(data, order);

        emit WithdrawEnqueued(order.orderId, order);
    }

    struct SellParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        bool wrapUnwrap;
        address to;
        uint256 gasLimit;
        uint32 submitDeadline;
    }

    function sell(
        Data storage data,
        SellParams calldata sellParams,
        TokenShares.Data storage tokenShares
    ) external {
        uint256 tokenTransferCost = getTransferGasCost(sellParams.tokenIn);
        checkOrderParams(
            sellParams.to,
            sellParams.gasLimit,
            sellParams.submitDeadline,
            ORDER_BASE_COST.add(tokenTransferCost)
        );

        (address pairAddress, bool inverted) = sellHelper(data, sellParams);

        (uint256 priceAccumulator, uint256 timestamp) = ITwapOracle(ITwapPair(pairAddress).oracle()).getPriceInfo();

        uint256 shares = tokenShares.amountToShares(sellParams.tokenIn, sellParams.amountIn, sellParams.wrapUnwrap);

        Order memory order = Order(
            0,
            OrderType.Sell,
            inverted,
            timestamp + DELAY, // validAfterTimestamp
            sellParams.wrapUnwrap,
            timestamp,
            sellParams.gasLimit,
            data.gasPrice,
            0, // liquidity
            shares,
            sellParams.amountOutMin,
            sellParams.tokenIn,
            sellParams.tokenOut,
            sellParams.to,
            0, // minSwapPrice
            0, // maxSwapPrice
            false, // swap
            priceAccumulator,
            sellParams.amountIn,
            0 // amountLimit1
        );
        enqueueOrder(data, order);

        emit SellEnqueued(order.orderId, order);
    }

    function relayerSell(
        Data storage data,
        SellParams calldata sellParams,
        TokenShares.Data storage tokenShares
    ) external {
        checkOrderParams(sellParams.to, sellParams.gasLimit, sellParams.submitDeadline, ORDER_BASE_COST);

        (, bool inverted) = sellHelper(data, sellParams);

        uint256 shares = tokenShares.amountToSharesWithoutTransfer(
            sellParams.tokenIn,
            sellParams.amountIn,
            sellParams.wrapUnwrap
        );

        Order memory order = Order(
            0,
            OrderType.Sell,
            inverted,
            block.timestamp + DELAY, // validAfterTimestamp
            false, // Never wrap/unwrap
            block.timestamp,
            sellParams.gasLimit,
            data.gasPrice,
            0, // liquidity
            shares,
            sellParams.amountOutMin,
            sellParams.tokenIn,
            sellParams.tokenOut,
            sellParams.to,
            0, // minSwapPrice
            0, // maxSwapPrice
            false, // swap
            0, // priceAccumulator - oracleV3 pairs don't need priceAccumulator
            sellParams.amountIn,
            0 // amountLimit1
        );
        enqueueOrder(data, order);

        emit SellEnqueued(order.orderId, order);
    }

    function sellHelper(Data storage data, SellParams calldata sellParams)
        internal
        returns (address pairAddress, bool inverted)
    {
        require(sellParams.amountIn != 0, 'OS24');
        (pairAddress, inverted) = getPair(sellParams.tokenIn, sellParams.tokenOut);
        require(!getSellDisabled(data, pairAddress), 'OS13');

        // allocate gas refund
        uint256 value = msg.value;
        if (sellParams.wrapUnwrap && sellParams.tokenIn == TokenShares.WETH_ADDRESS) {
            value = msg.value.sub(sellParams.amountIn, 'OS1E');
        }
        allocateGasRefund(data, value, sellParams.gasLimit);
    }

    struct BuyParams {
        address tokenIn;
        address tokenOut;
        uint256 amountInMax;
        uint256 amountOut;
        bool wrapUnwrap;
        address to;
        uint256 gasLimit;
        uint32 submitDeadline;
    }

    function buy(
        Data storage data,
        BuyParams calldata buyParams,
        TokenShares.Data storage tokenShares
    ) external {
        uint256 tokenTransferCost = getTransferGasCost(buyParams.tokenIn);
        checkOrderParams(
            buyParams.to,
            buyParams.gasLimit,
            buyParams.submitDeadline,
            ORDER_BASE_COST.add(tokenTransferCost)
        );
        require(buyParams.amountOut != 0, 'OS23');
        (address pairAddress, bool inverted) = getPair(buyParams.tokenIn, buyParams.tokenOut);
        require(!getBuyDisabled(data, pairAddress), 'OS49');
        uint256 value = msg.value;

        // allocate gas refund
        if (buyParams.tokenIn == TokenShares.WETH_ADDRESS && buyParams.wrapUnwrap) {
            value = msg.value.sub(buyParams.amountInMax, 'OS1E');
        }

        allocateGasRefund(data, value, buyParams.gasLimit);

        uint256 shares = tokenShares.amountToShares(buyParams.tokenIn, buyParams.amountInMax, buyParams.wrapUnwrap);

        (uint256 priceAccumulator, uint256 timestamp) = ITwapOracle(ITwapPair(pairAddress).oracle()).getPriceInfo();

        Order memory order = Order(
            0,
            OrderType.Buy,
            inverted,
            timestamp + DELAY, // validAfterTimestamp
            buyParams.wrapUnwrap,
            timestamp,
            buyParams.gasLimit,
            data.gasPrice,
            0, // liquidity
            shares,
            buyParams.amountOut,
            buyParams.tokenIn,
            buyParams.tokenOut,
            buyParams.to,
            0, // minSwapPrice
            0, // maxSwapPrice
            false, // swap
            priceAccumulator,
            buyParams.amountInMax,
            0 // amountLimit1
        );
        enqueueOrder(data, order);

        emit BuyEnqueued(order.orderId, order);
    }

    function checkOrderParams(
        address to,
        uint256 gasLimit,
        uint32 submitDeadline,
        uint256 minGasLimit
    ) private view {
        require(submitDeadline >= block.timestamp, 'OS04');
        require(gasLimit <= MAX_GAS_LIMIT, 'OS3E');
        require(gasLimit >= minGasLimit, 'OS3D');
        require(to != address(0), 'OS26');
    }

    function allocateGasRefund(
        Data storage data,
        uint256 value,
        uint256 gasLimit
    ) private returns (uint256 futureFee) {
        futureFee = data.gasPrice.mul(gasLimit);
        require(value >= futureFee, 'OS1E');
        if (value > futureFee) {
            TransferHelper.safeTransferETH(
                msg.sender,
                value.sub(futureFee),
                getTransferGasCost(NATIVE_CURRENCY_SENTINEL)
            );
        }
    }

    function updateGasPrice(Data storage data, uint256 gasUsed) external {
        uint256 scale = Math.min(gasUsed, MAX_GAS_PRICE_IMPACT);
        data.gasPrice = data.gasPrice.mul(GAS_PRICE_INERTIA.sub(scale)).add(tx.gasprice.mul(scale)).div(
            GAS_PRICE_INERTIA
        );
    }

    function refundLiquidity(
        address pair,
        address to,
        uint256 liquidity,
        bytes4 selector
    ) internal returns (bool) {
        if (liquidity == 0) {
            return true;
        }
        (bool success, bytes memory data) = address(this).call{ gas: PAIR_TRANSFER_COST }(
            abi.encodeWithSelector(selector, pair, to, liquidity, false)
        );
        if (!success) {
            emit RefundFailed(to, pair, liquidity, data);
        }
        return success;
    }

    function dequeueOrder(Data storage data, uint256 orderId) internal {
        ++data.lastProcessedOrderId;
        require(orderId == data.lastProcessedOrderId, 'OS72');
    }

    function forgetOrder(Data storage data, uint256 orderId) internal {
        delete data.orderQueue[orderId];
    }

    function forgetLastProcessedOrder(Data storage data) internal {
        delete data.orderQueue[data.lastProcessedOrderId];
    }

    function getOrderDigest(Order memory order) internal pure returns (bytes32) {
        // Used to avoid the 'stack too deep' error.
        bytes memory partialOrderData = abi.encodePacked(
            order.orderId,
            order.orderType,
            order.inverted,
            order.validAfterTimestamp,
            order.unwrap,
            order.timestamp,
            order.gasLimit,
            order.gasPrice,
            order.liquidity,
            order.value0,
            order.value1,
            order.token0,
            order.token1,
            order.to
        );

        return
            keccak256(
                abi.encodePacked(
                    partialOrderData,
                    order.minSwapPrice,
                    order.maxSwapPrice,
                    order.swap,
                    order.priceAccumulator,
                    order.amountLimit0,
                    order.amountLimit1
                )
            );
    }

    function verifyOrder(Data storage data, Order memory order) external view {
        require(getOrderDigest(order) == data.orderQueue[order.orderId], 'OS71');
    }

    
    // constant mapping for transferGasCost
    /**
     * @dev This function should either return a default value != 0 or revert.
     */
    function getTransferGasCost(address token) internal pure returns (uint256) {
        if (token == NATIVE_CURRENCY_SENTINEL) return ETHER_TRANSFER_CALL_COST;
        if (token == 0xaf88d065e77c8cC2239327C5EDb3A432268e5831) return 70000;
        if (token == 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8) return 70000;
        return 60000;
    }
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    int256 private constant _INT256_MIN = -2**255;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'SM4E');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = sub(x, y, 'SM12');
    }

    function sub(
        uint256 x,
        uint256 y,
        string memory message
    ) internal pure returns (uint256 z) {
        require((z = x - y) <= x, message);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'SM2A');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SM43');
        return a / b;
    }

    function ceil_div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = div(a, b);
        if (a != mul(b, c)) {
            return add(c, 1);
        }
    }

    function toUint32(uint256 n) internal pure returns (uint32) {
        require(n <= type(uint32).max, 'SM50');
        return uint32(n);
    }

    function toUint64(uint256 n) internal pure returns (uint64) {
        require(n <= type(uint64).max, 'SM54');
        return uint64(n);
    }

    function toUint112(uint256 n) internal pure returns (uint112) {
        require(n <= type(uint112).max, 'SM51');
        return uint112(n);
    }

    function toInt256(uint256 unsigned) internal pure returns (int256 signed) {
        require(unsigned <= uint256(type(int256).max), 'SM34');
        signed = int256(unsigned);
    }

    // int256

    function add(int256 a, int256 b) internal pure returns (int256 c) {
        c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), 'SM4D');
    }

    function sub(int256 a, int256 b) internal pure returns (int256 c) {
        c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), 'SM11');
    }

    function mul(int256 a, int256 b) internal pure returns (int256 c) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), 'SM29');

        c = a * b;
        require(c / a == b, 'SM29');
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, 'SM43');
        require(!(b == -1 && a == _INT256_MIN), 'SM42');

        return a / b;
    }

    function neg_floor_div(int256 a, int256 b) internal pure returns (int256 c) {
        c = div(a, b);
        if ((a < 0 && b > 0) || (a >= 0 && b < 0)) {
            if (a != mul(b, c)) {
                c = sub(c, 1);
            }
        }
    }
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



import '../interfaces/IERC20.sol';
import '../interfaces/IWETH.sol';
import './SafeMath.sol';
import './TransferHelper.sol';


library TokenShares {
    using SafeMath for uint256;
    using TransferHelper for address;

    uint256 private constant PRECISION = 10**18;
    uint256 private constant TOLERANCE = 10**18 + 10**16;
    uint256 private constant TOTAL_SHARES_PRECISION = 10**18;

    event UnwrapFailed(address to, uint256 amount);

    // represents wrapped native currency (WETH or WMATIC)
    address public constant WETH_ADDRESS = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1; 

    struct Data {
        mapping(address => uint256) totalShares;
    }

    function sharesToAmount(
        Data storage data,
        address token,
        uint256 share,
        uint256 amountLimit,
        address refundTo
    ) external returns (uint256) {
        if (share == 0) {
            return 0;
        }
        if (token == WETH_ADDRESS || isNonRebasing(token)) {
            return share;
        }

        uint256 totalTokenShares = data.totalShares[token];
        require(totalTokenShares >= share, 'TS3A');
        uint256 balance = IERC20(token).balanceOf(address(this));
        uint256 value = balance.mul(share).div(totalTokenShares);
        data.totalShares[token] = totalTokenShares.sub(share);

        if (amountLimit > 0) {
            uint256 amountLimitWithTolerance = amountLimit.mul(TOLERANCE).div(PRECISION);
            if (value > amountLimitWithTolerance) {
                TransferHelper.safeTransfer(token, refundTo, value.sub(amountLimitWithTolerance));
                return amountLimitWithTolerance;
            }
        }

        return value;
    }

    function amountToShares(
        Data storage data,
        address token,
        uint256 amount,
        bool wrap
    ) external returns (uint256) {
        if (amount == 0) {
            return 0;
        }
        if (token == WETH_ADDRESS) {
            if (wrap) {
                require(msg.value >= amount, 'TS03');
                IWETH(token).deposit{ value: amount }();
            } else {
                token.safeTransferFrom(msg.sender, address(this), amount);
            }
            return amount;
        } else if (isNonRebasing(token)) {
            token.safeTransferFrom(msg.sender, address(this), amount);
            return amount;
        } else {
            uint256 balanceBefore = IERC20(token).balanceOf(address(this));
            token.safeTransferFrom(msg.sender, address(this), amount);
            uint256 balanceAfter = IERC20(token).balanceOf(address(this));

            return amountToSharesHelper(data, token, balanceBefore, balanceAfter);
        }
    }

    function amountToSharesWithoutTransfer(
        Data storage data,
        address token,
        uint256 amount,
        bool wrap
    ) external returns (uint256) {
        if (token == WETH_ADDRESS) {
            if (wrap) {
                // require(msg.value >= amount, 'TS03'); // Duplicate check in TwapRelayer.sell
                IWETH(token).deposit{ value: amount }();
            }
            return amount;
        } else if (isNonRebasing(token)) {
            return amount;
        } else {
            uint256 balanceAfter = IERC20(token).balanceOf(address(this));
            uint256 balanceBefore = balanceAfter.sub(amount);
            return amountToSharesHelper(data, token, balanceBefore, balanceAfter);
        }
    }

    function amountToSharesHelper(
        Data storage data,
        address token,
        uint256 balanceBefore,
        uint256 balanceAfter
    ) internal returns (uint256) {
        uint256 totalTokenShares = data.totalShares[token];
        require(balanceBefore > 0 || totalTokenShares == 0, 'TS30');
        require(balanceAfter > balanceBefore, 'TS2C');

        if (balanceBefore > 0) {
            if (totalTokenShares == 0) {
                totalTokenShares = balanceBefore.mul(TOTAL_SHARES_PRECISION);
            }
            uint256 newShares = totalTokenShares.mul(balanceAfter).div(balanceBefore);
            require(balanceAfter < type(uint256).max.div(newShares), 'TS73'); // to prevent overflow at execution
            data.totalShares[token] = newShares;
            return newShares - totalTokenShares;
        } else {
            totalTokenShares = balanceAfter.mul(TOTAL_SHARES_PRECISION);
            require(totalTokenShares < type(uint256).max.div(totalTokenShares), 'TS73'); // to prevent overflow at execution
            data.totalShares[token] = totalTokenShares;
            return totalTokenShares;
        }
    }

    function onUnwrapFailed(address to, uint256 amount) external {
        emit UnwrapFailed(to, amount);
        IWETH(WETH_ADDRESS).deposit{ value: amount }();
        TransferHelper.safeTransfer(WETH_ADDRESS, to, amount);
    }

    
    // constant mapping for nonRebasingToken
    function isNonRebasing(address token) internal pure returns (bool) {
        if (token == 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1) return true;
        if (token == 0xaf88d065e77c8cC2239327C5EDb3A432268e5831) return true;
        if (token == 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8) return true;
        if (token == 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9) return true;
        if (token == 0x5979D7b546E38E414F7E9822514be443A4800529) return true;
        return false;
    }
}

pragma solidity 0.7.6;

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9



// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH4B');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH05');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH0E');
    }

    function safeTransferETH(
        address to,
        uint256 value,
        uint256 gasLimit
    ) internal {
        (bool success, ) = to.call{ value: value, gas: gasLimit }('');
        require(success, 'TH3F');
    }

    function transferETH(
        address to,
        uint256 value,
        uint256 gasLimit
    ) internal returns (bool success) {
        (success, ) = to.call{ value: value, gas: gasLimit }('');
    }
}