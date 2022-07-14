// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IAmmFactory.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/IRouterForKeeper.sol";
import "../interfaces/IConfig.sol";
import "../interfaces/IOrderBook.sol";
import "../interfaces/IPairFactory.sol";
import "../interfaces/IMargin.sol";
import "../interfaces/IAmm.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IPriceOracle.sol";
import "../libraries/TransferHelper.sol";
import "../libraries/SignedMath.sol";
import "../libraries/FullMath.sol";
import "../utils/Ownable.sol";

contract RouterForKeeper is IRouterForKeeper, Ownable {
    using SignedMath for int256;
    using FullMath for uint256;

    address public immutable override config;
    address public immutable override pairFactory;
    address public immutable override WETH;
    address public immutable override USDC;
    address public override orderBook;
    address public override keeper;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "RFK: EXPIRED");
        _;
    }

    modifier onlyOrderBook() {
        require(msg.sender == orderBook, "RFK:only orderboook");
        _;
    }

    constructor(address config_, address pairFactory_, address WETH_, address USDC_) {
        owner = msg.sender;
        config = config_;
        pairFactory = pairFactory_;
        WETH = WETH_;
        USDC = USDC_;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function setOrderBook(address newOrderBook) external override onlyOwner {
        require(newOrderBook != address(0), "RFK.SOB: ZERO_ADDRESS");
        orderBook = newOrderBook;
    }

    function setKeeper(address keeper_) external override onlyOwner {
        require(keeper_ != address(0), "RFK.SK: ZERO_ADDRESS");
        keeper = keeper_;
    }

    function openPositionWithWallet(IOrderBook.OpenPositionOrder memory order)
        external
        override
        ensure(order.deadline)
        onlyOrderBook
        returns (uint256 baseAmount)
    {
        address margin = IPairFactory(pairFactory).getMargin(order.baseToken, order.quoteToken);
        require(margin != address(0), "RFK.OPWW: NOT_FOUND_MARGIN");
        require(order.side == 0 || order.side == 1, "RFK.OPWW: INVALID_SIDE");

        TransferHelper.safeTransferFrom(order.baseToken, order.trader, margin, order.baseAmount);

        IMargin(margin).addMargin(order.trader, order.baseAmount);
        baseAmount = IMargin(margin).openPosition(order.trader, order.side, order.quoteAmount);
        if (order.side == 0) {
            _collectFee(baseAmount, margin, order.trader);
        }
        _rewardForKeeper(margin, order.trader, order.baseToken);
    }

    function openPositionWithMargin(IOrderBook.OpenPositionOrder memory order)
        external
        override
        ensure(order.deadline)
        onlyOrderBook
        returns (uint256 baseAmount)
    {
        address margin = IPairFactory(pairFactory).getMargin(order.baseToken, order.quoteToken);
        require(margin != address(0), "RFK.OPWM: NOT_FOUND_MARGIN");
        require(order.side == 0 || order.side == 1, "RFK.OPWM: INVALID_SIDE");
        baseAmount = IMargin(margin).openPosition(order.trader, order.side, order.quoteAmount);
        if (order.side == 0) {
            _collectFee(baseAmount, margin, order.trader);
        }
        _rewardForKeeper(margin, order.trader, order.baseToken);
    }

    function closePosition(IOrderBook.ClosePositionOrder memory order)
        external
        override
        ensure(order.deadline)
        onlyOrderBook
    returns (uint256 baseAmount, uint256 withdrawAmount)
    {
        address margin = IPairFactory(pairFactory).getMargin(order.baseToken, order.quoteToken);
        require(margin != address(0), "RFK.CP: NOT_FOUND_MARGIN");
        (, int256 quoteSizeBefore, ) = IMargin(margin).getPosition(order.trader);
        require(
            quoteSizeBefore > 0 ? order.side == 1 : order.side == 0,
            "RFK.CP: SIDE_NOT_MATCH"
        );
        _rewardForKeeper(margin, order.trader, order.baseToken);
        if (!order.autoWithdraw) {
            baseAmount = IMargin(margin).closePosition(order.trader, order.quoteAmount);
            if (quoteSizeBefore > 0) {
                _collectFee(baseAmount, margin, order.trader);
            }
        } else {
            {
                baseAmount = IMargin(margin).closePosition(order.trader, order.quoteAmount);
                if (quoteSizeBefore > 0) {
                    _collectFee(baseAmount, margin, order.trader);
                }
                (int256 baseSize, int256 quoteSizeAfter, uint256 tradeSize) = IMargin(margin).getPosition(order.trader);
                int256 unrealizedPnl = IMargin(margin).calUnrealizedPnl(order.trader);
                int256 traderMargin;
                if (quoteSizeAfter < 0) {
                    // long, traderMargin = baseSize - tradeSize + unrealizedPnl
                    traderMargin = baseSize.subU(tradeSize) + unrealizedPnl;
                } else {
                    // short, traderMargin = baseSize + tradeSize + unrealizedPnl
                    traderMargin = baseSize.addU(tradeSize) + unrealizedPnl;
                }
                withdrawAmount =
                    traderMargin.abs() -
                    (traderMargin.abs() * quoteSizeAfter.abs()) /
                    quoteSizeBefore.abs();
            }

            uint256 withdrawable = IMargin(margin).getWithdrawable(order.trader);
            if (withdrawable < withdrawAmount) {
                withdrawAmount = withdrawable;
            }
            if (withdrawAmount > 0) {
                IMargin(margin).removeMargin(order.trader, order.trader, withdrawAmount);
            }
        }
    }

    //if eth is 2000usdc, then here return 2000*1e18, 18, 6
    function getSpotPriceWithMultiplier(address baseToken, address quoteToken)
        external
        view
        override
        returns (
            uint256 spotPriceWithMultiplier,
            uint256 baseDecimal,
            uint256 quoteDecimal
        )
    {
        address amm = IPairFactory(pairFactory).getAmm(baseToken, quoteToken);
        (uint256 reserveBase, uint256 reserveQuote, ) = IAmm(amm).getReserves();

        uint256 baseDecimals = IERC20(baseToken).decimals();
        uint256 quoteDecimals = IERC20(quoteToken).decimals();
        uint256 exponent = uint256(10**(18 + baseDecimals - quoteDecimals));

        return (exponent.mulDiv(reserveQuote, reserveBase), baseDecimals, quoteDecimals);
    }

    function _collectFee(uint256 baseAmount, address margin, address trader) internal {
        uint256 fee = baseAmount / 1000;
        address feeTreasury = IAmmFactory(IPairFactory(pairFactory).ammFactory()).feeTo();
        IMargin(margin).removeMargin(trader, feeTreasury, fee);
        emit CollectFee(trader, margin, fee);
    }

    function _rewardForKeeper(address margin, address trader, address baseToken) internal {
        IPriceOracle oracle = IPriceOracle(IConfig(config).priceOracle());
        uint8 baseDecimals = IERC20(baseToken).decimals();
        uint8 usdcDecimals = IERC20(USDC).decimals();
        (uint256 usdcAmount, ) = oracle.quote(baseToken, USDC, 10**(baseDecimals));
        uint256 reward = 10**(baseDecimals + usdcDecimals) / usdcAmount;
        IMargin(margin).removeMargin(trader, keeper, reward);
        emit RewardForKeeper(trader, margin, reward);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IAmmFactory {
    event AmmCreated(address indexed baseToken, address indexed quoteToken, address amm);

    function createAmm(address baseToken, address quoteToken) external returns (address amm);

    function initAmm(
        address baseToken,
        address quoteToken,
        address margin
    ) external;

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function upperFactory() external view returns (address);

    function config() external view returns (address);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getAmm(address baseToken, address quoteToken) external view returns (address amm);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
import "./IOrderBook.sol";

interface IRouterForKeeper {
    event CollectFee(address indexed trader, address indexed margin, uint256 fee);
    event RewardForKeeper(address indexed trader, address indexed margin, uint256 reward);

    function config() external view returns (address);

    function pairFactory() external view returns (address);

    function WETH() external view returns (address);

    function USDC() external view returns (address);

    function orderBook() external view returns (address);

    function keeper() external view returns (address);

    function openPositionWithWallet(IOrderBook.OpenPositionOrder memory order)
        external
        returns (uint256 baseAmount);

    function openPositionWithMargin(IOrderBook.OpenPositionOrder memory order)
        external
        returns (uint256 baseAmount);

    function closePosition(IOrderBook.ClosePositionOrder memory order)
        external
        returns (uint256 baseAmount, uint256 withdrawAmount);

    function getSpotPriceWithMultiplier(address baseToken, address quoteToken)
        external
        view
        returns (
            uint256 spotPriceWithMultiplier,
            uint256 baseDecimal,
            uint256 quoteDecimal
        );

    function setOrderBook(address newOrderBook) external;

    function setKeeper(address keeper_) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IConfig {
    event PriceOracleChanged(address indexed oldOracle, address indexed newOracle);
    event RebasePriceGapChanged(uint256 oldGap, uint256 newGap);
    event RebaseIntervalChanged(uint256 oldInterval, uint256 newInterval);
    event TradingSlippageChanged(uint256 oldTradingSlippage, uint256 newTradingSlippage);
    event RouterRegistered(address indexed router);
    event RouterUnregistered(address indexed router);
    event SetLiquidateFeeRatio(uint256 oldLiquidateFeeRatio, uint256 liquidateFeeRatio);
    event SetLiquidateThreshold(uint256 oldLiquidateThreshold, uint256 liquidateThreshold);
    event SetLpWithdrawThresholdForNet(uint256 oldLpWithdrawThresholdForNet, uint256 lpWithdrawThresholdForNet);
    event SetLpWithdrawThresholdForTotal(uint256 oldLpWithdrawThresholdForTotal, uint256 lpWithdrawThresholdForTotal);
    event SetInitMarginRatio(uint256 oldInitMarginRatio, uint256 initMarginRatio);
    event SetBeta(uint256 oldBeta, uint256 beta);
    event SetFeeParameter(uint256 oldFeeParameter, uint256 feeParameter);
    event SetMaxCPFBoost(uint256 oldMaxCPFBoost, uint256 maxCPFBoost);
    event SetEmergency(address indexed router);

    /// @notice get price oracle address.
    function priceOracle() external view returns (address);

    /// @notice get beta of amm.
    function beta() external view returns (uint8);

    /// @notice get feeParameter of amm.
    function feeParameter() external view returns (uint256);

    /// @notice get init margin ratio of margin.
    function initMarginRatio() external view returns (uint256);

    /// @notice get liquidate threshold of margin.
    function liquidateThreshold() external view returns (uint256);

    /// @notice get liquidate fee ratio of margin.
    function liquidateFeeRatio() external view returns (uint256);

    /// @notice get trading slippage  of amm.
    function tradingSlippage() external view returns (uint256);

    /// @notice get rebase gap of amm.
    function rebasePriceGap() external view returns (uint256);

    /// @notice get lp withdraw threshold of amm.
    function lpWithdrawThresholdForNet() external view returns (uint256);
  
    /// @notice get lp withdraw threshold of amm.
    function lpWithdrawThresholdForTotal() external view returns (uint256);

    function rebaseInterval() external view returns (uint256);

    function routerMap(address) external view returns (bool);

    function maxCPFBoost() external view returns (uint256);

    function inEmergency(address router) external view returns (bool);

    function registerRouter(address router) external;

    function unregisterRouter(address router) external;

    /// @notice Set a new oracle
    /// @param newOracle new oracle address.
    function setPriceOracle(address newOracle) external;

    /// @notice Set a new beta of amm
    /// @param newBeta new beta.
    function setBeta(uint8 newBeta) external;

    /// @notice Set a new rebase gap of amm
    /// @param newGap new gap.
    function setRebasePriceGap(uint256 newGap) external;

    function setRebaseInterval(uint256 interval) external;

    /// @notice Set a new trading slippage of amm
    /// @param newTradingSlippage .
    function setTradingSlippage(uint256 newTradingSlippage) external;

    /// @notice Set a new init margin ratio of margin
    /// @param marginRatio new init margin ratio.
    function setInitMarginRatio(uint256 marginRatio) external;

    /// @notice Set a new liquidate threshold of margin
    /// @param threshold new liquidate threshold of margin.
    function setLiquidateThreshold(uint256 threshold) external;
  
     /// @notice Set a new lp withdraw threshold of amm net position
    /// @param newLpWithdrawThresholdForNet new lp withdraw threshold of amm.
    function setLpWithdrawThresholdForNet(uint256 newLpWithdrawThresholdForNet) external;
    
    /// @notice Set a new lp withdraw threshold of amm total position
    /// @param newLpWithdrawThresholdForTotal new lp withdraw threshold of amm.
    function setLpWithdrawThresholdForTotal(uint256 newLpWithdrawThresholdForTotal) external;

    /// @notice Set a new liquidate fee of margin
    /// @param feeRatio new liquidate fee of margin.
    function setLiquidateFeeRatio(uint256 feeRatio) external;

    /// @notice Set a new feeParameter.
    /// @param newFeeParameter New feeParameter get from AMM swap fee.
    /// @dev feeParameter = (1/fee -1 ) *100 where fee set by owner.
    function setFeeParameter(uint256 newFeeParameter) external;

    function setMaxCPFBoost(uint256 newMaxCPFBoost) external;

    function setEmergency(address router) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IOrderBook {
    struct RespData {
        bool success;
        bytes result;
    }

    struct OpenPositionOrder {
        address routerToExecute;
        address trader;
        address baseToken;
        address quoteToken;
        uint8 side;
        uint256 baseAmount;
        uint256 quoteAmount;
        uint256 slippage;
        uint256 limitPrice;
        uint256 deadline;
        bool withWallet;
        bytes nonce;
    }

    struct ClosePositionOrder {
        address routerToExecute;
        address trader;
        address baseToken;
        address quoteToken;
        uint8 side;
        uint256 quoteAmount;
        uint256 limitPrice;
        uint256 deadline;
        bool autoWithdraw;
        bytes nonce;
    }

    event BatchExecuteOpen(OpenPositionOrder[] orders, bytes[] signatures, bool requireSuccess);

    event BatchExecuteClose(ClosePositionOrder[] orders, bytes[] signatures, bool requireSuccess);

    event SetRouterForKeeper(address newRouterForKeeper);

    event ExecuteOpen(OpenPositionOrder order, bytes signature);

    event ExecuteClose(ClosePositionOrder order, bytes signature);

    event ExecuteLog(bytes orderId, bool success);

    function batchExecuteOpen(
        OpenPositionOrder[] memory orders,
        bytes[] memory signatures,
        bool requireSuccess
    ) external returns (RespData[] memory respData);

    function batchExecuteClose(
        ClosePositionOrder[] memory orders,
        bytes[] memory signatures,
        bool requireSuccess
    ) external returns (RespData[] memory respData);

    function executeOpen(OpenPositionOrder memory order, bytes memory signature) external;

    function executeClose(ClosePositionOrder memory order, bytes memory signature) external;

    function verifyOpen(OpenPositionOrder memory order, bytes memory signature) external view returns (bool);

    function verifyClose(ClosePositionOrder memory order, bytes memory signature) external view returns (bool);

    function setRouterForKeeper(address routerForKeeper) external;

    function addBot(address newBot) external;

    function reverseBotState(address bot) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IPairFactory {
    event NewPair(address indexed baseToken, address indexed quoteToken, address amm, address margin);

    function createPair(address baseToken, address quotoToken) external returns (address amm, address margin);

    function ammFactory() external view returns (address);

    function marginFactory() external view returns (address);

    function getAmm(address baseToken, address quoteToken) external view returns (address);

    function getMargin(address baseToken, address quoteToken) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IMargin {
    struct Position {
        int256 quoteSize; //quote amount of position
        int256 baseSize; //margin + fundingFee + unrealizedPnl + deltaBaseWhenClosePosition
        uint256 tradeSize; //if quoteSize>0 unrealizedPnl = baseValueOfQuoteSize - tradeSize; if quoteSize<0 unrealizedPnl = tradeSize - baseValueOfQuoteSize;
    }

    event AddMargin(address indexed trader, uint256 depositAmount, Position position);
    event RemoveMargin(
        address indexed trader,
        address indexed to,
        uint256 withdrawAmount,
        int256 fundingFee,
        uint256 withdrawAmountFromMargin,
        Position position
    );
    event OpenPosition(
        address indexed trader,
        uint8 side,
        uint256 baseAmount,
        uint256 quoteAmount,
        int256 fundingFee,
        Position position
    );
    event ClosePosition(
        address indexed trader,
        uint256 quoteAmount,
        uint256 baseAmount,
        int256 fundingFee,
        Position position
    );
    event Liquidate(
        address indexed liquidator,
        address indexed trader,
        address indexed to,
        uint256 quoteAmount,
        uint256 baseAmount,
        uint256 bonus,
        int256 fundingFee,
        Position position
    );
    event UpdateCPF(uint256 timeStamp, int256 cpf);

    /// @notice only factory can call this function
    /// @param baseToken_ margin's baseToken.
    /// @param quoteToken_ margin's quoteToken.
    /// @param amm_ amm address.
    function initialize(
        address baseToken_,
        address quoteToken_,
        address amm_
    ) external;

    /// @notice add margin to trader
    /// @param trader .
    /// @param depositAmount base amount to add.
    function addMargin(address trader, uint256 depositAmount) external;

    /// @notice remove margin to msg.sender
    /// @param withdrawAmount base amount to withdraw.
    function removeMargin(
        address trader,
        address to,
        uint256 withdrawAmount
    ) external;

    /// @notice open position with side and quoteAmount by msg.sender
    /// @param side long or short.
    /// @param quoteAmount quote amount.
    function openPosition(
        address trader,
        uint8 side,
        uint256 quoteAmount
    ) external returns (uint256 baseAmount);

    /// @notice close msg.sender's position with quoteAmount
    /// @param quoteAmount quote amount to close.
    function closePosition(address trader, uint256 quoteAmount) external returns (uint256 baseAmount);

    /// @notice liquidate trader
    function liquidate(address trader, address to)
        external
        returns (
            uint256 quoteAmount,
            uint256 baseAmount,
            uint256 bonus
        );

    function updateCPF() external returns (int256);

    /// @notice get factory address
    function factory() external view returns (address);

    /// @notice get config address
    function config() external view returns (address);

    /// @notice get base token address
    function baseToken() external view returns (address);

    /// @notice get quote token address
    function quoteToken() external view returns (address);

    /// @notice get amm address of this margin
    function amm() external view returns (address);

    /// @notice get all users' net position of quote
    function netPosition() external view returns (int256 netQuotePosition);

    /// @notice get all users' net position of quote
    function totalPosition() external view returns (uint256 totalQuotePosition);

    /// @notice get trader's position
    function getPosition(address trader)
        external
        view
        returns (
            int256 baseSize,
            int256 quoteSize,
            uint256 tradeSize
        );

    /// @notice get withdrawable margin of trader
    function getWithdrawable(address trader) external view returns (uint256 amount);

    /// @notice check if can liquidate this trader's position
    function canLiquidate(address trader) external view returns (bool);

    /// @notice calculate the latest funding fee with current position
    function calFundingFee(address trader) external view returns (int256 fundingFee);

    /// @notice calculate the latest debt ratio with Pnl and funding fee
    function calDebtRatio(address trader) external view returns (uint256 debtRatio);

    function calUnrealizedPnl(address trader) external view returns (int256);

    function getNewLatestCPF() external view returns (int256);

    function querySwapBaseWithAmm(bool isLong, uint256 quoteAmount) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IAmm {
    event Mint(address indexed sender, address indexed to, uint256 baseAmount, uint256 quoteAmount, uint256 liquidity);
    event Burn(address indexed sender, address indexed to, uint256 baseAmount, uint256 quoteAmount, uint256 liquidity);
    event Swap(address indexed trader, address indexed inputToken, address indexed outputToken, uint256 inputAmount, uint256 outputAmount);
    event ForceSwap(address indexed trader, address indexed inputToken, address indexed outputToken, uint256 inputAmount, uint256 outputAmount);
    event Rebase(uint256 quoteReserveBefore, uint256 quoteReserveAfter, uint256 _baseReserve , uint256 quoteReserveFromInternal,  uint256 quoteReserveFromExternal );
    event Sync(uint112 reserveBase, uint112 reserveQuote);

    // only factory can call this function
    function initialize(
        address baseToken_,
        address quoteToken_,
        address margin_
    ) external;

    function mint(address to)
        external
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        );

    function burn(address to)
        external
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        );

    // only binding margin can call this function
    function swap(
        address trader,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external returns (uint256[2] memory amounts);

    // only binding margin can call this function
    function forceSwap(
        address trader,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external;

    function rebase() external returns (uint256 quoteReserveAfter);

    function collectFee() external returns (bool feeOn);

    function factory() external view returns (address);

    function config() external view returns (address);

    function baseToken() external view returns (address);

    function quoteToken() external view returns (address);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function margin() external view returns (address);

    function lastPrice() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserveBase,
            uint112 reserveQuote,
            uint32 blockTimestamp
        );

    function estimateSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external view returns (uint256[2] memory amounts);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function getFeeLiquidity() external view returns (uint256);

    function getTheMaxBurnLiquidity() external view returns (uint256 maxLiquidity);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IPriceOracle {
    function setupTwap(address amm) external;

    function quoteFromAmmTwap(address amm, uint256 baseAmount) external view returns (uint256 quoteAmount);

    function updateAmmTwap(address pair) external;

    // index price maybe get from different oracle, like UniswapV3 TWAP,Chainklink, or others
    // source represents which oracle used. 0 = UniswapV3 TWAP
    function quote(
        address baseToken,
        address quoteToken,
        uint256 baseAmount
    ) external view returns (uint256 quoteAmount, uint8 source);

    function getIndexPrice(address amm) external view returns (uint256);

    function getMarketPrice(address amm) external view returns (uint256);

    function getMarkPrice(address amm) external view returns (uint256 price, bool isIndexPrice);

    function getMarkPriceAfterSwap(
        address amm,
        uint256 quoteAmount,
        uint256 baseAmount
    ) external view returns (uint256 price, bool isIndexPrice);

    function getMarkPriceInRatio(
        address amm,
        uint256 quoteAmount,
        uint256 baseAmount
    )
        external
        view
        returns (
            uint256 resultBaseAmount,
            uint256 resultQuoteAmount,
            bool isIndexPrice
        );

    function getMarkPriceAcc(
        address amm,
        uint8 beta,
        uint256 quoteAmount,
        bool negative
    ) external view returns (uint256 baseAmount);

    function getPremiumFraction(address amm) external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SignedMath {
    function abs(int256 x) internal pure returns (uint256) {
        if (x < 0) {
            return uint256(0 - x);
        }
        return uint256(x);
    }

    function addU(int256 x, uint256 y) internal pure returns (int256) {
        require(y <= uint256(type(int256).max), "overflow");
        return x + int256(y);
    }

    function subU(int256 x, uint256 y) internal pure returns (int256) {
        require(y <= uint256(type(int256).max), "overflow");
        return x - int256(y);
    }

    function mulU(int256 x, uint256 y) internal pure returns (int256) {
        require(y <= uint256(type(int256).max), "overflow");
        return x * int256(y);
    }

    function divU(int256 x, uint256 y) internal pure returns (int256) {
        require(y <= uint256(type(int256).max), "overflow");
        return x / int256(y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

        // todo unchecked
        unchecked {
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
            uint256 twos = (~denominator + 1) & denominator;
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
pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;
    address public pendingOwner;

    event NewOwner(address indexed oldOwner, address indexed newOwner);
    event NewPendingOwner(address indexed oldPendingOwner, address indexed newPendingOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: REQUIRE_OWNER");
        _;
    }

    function setPendingOwner(address newPendingOwner) external onlyOwner {
        require(pendingOwner != newPendingOwner, "Ownable: ALREADY_SET");
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "Ownable: REQUIRE_PENDING_OWNER");
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }
}