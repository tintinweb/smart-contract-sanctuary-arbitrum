// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "../interfaces/IRouterForKeeper.sol";
import "../interfaces/IOrderBook.sol";
import "../interfaces/IPairFactory.sol";
import "../interfaces/IMargin.sol";
import "../interfaces/IAmm.sol";
import "../interfaces/IWETH.sol";
import "../libraries/TransferHelper.sol";
import "../libraries/SignedMath.sol";
import "../libraries/FullMath.sol";
import "../utils/Ownable.sol";

contract RouterForKeeper is IRouterForKeeper, Ownable {
    using SignedMath for int256;
    using FullMath for uint256;

    address public immutable override pairFactory;
    address public immutable override WETH;
    address public orderBook;
    mapping(address => mapping(address => uint256)) public balanceOf;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "RouterForKeeper: EXPIRED");
        _;
    }

    modifier onlyOrderBook() {
        require(msg.sender == orderBook, "RouterForKeeper:only orderboook");
        _;
    }

    constructor(address pairFactory_, address _WETH) {
        owner = msg.sender;
        pairFactory = pairFactory_;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function setOrderBook(address newOrderBook) external override onlyOwner {
        require(newOrderBook != address(0), "RouterForKeeper.setOrderBook: ZERO_ADDRESS");
        orderBook = newOrderBook;
    }

    function openPositionWithWallet(IOrderBook.OpenPositionOrder memory order, uint256 slippageRatio)
        external
        override
        ensure(order.deadline)
        onlyOrderBook
        returns (uint256 baseAmount)
    {
        address margin = IPairFactory(pairFactory).getMargin(order.baseToken, order.quoteToken);
        require(margin != address(0), "RouterForKeeper.openPositionWithWallet: NOT_FOUND_MARGIN");
        require(order.side == 0 || order.side == 1, "RouterForKeeper.openPositionWithWallet: INVALID_SIDE");

        TransferHelper.safeTransferFrom(order.baseToken, order.trader, margin, order.baseAmount);

        IMargin(margin).addMargin(order.trader, order.baseAmount);
        baseAmount = IMargin(margin).openPosition(order.trader, order.side, order.quoteAmount);

        require(
            (order.side == 0)
                ? slippageRatio < ((order.quoteAmount * 1e18) / baseAmount)
                : slippageRatio > ((order.quoteAmount * 1e18) / baseAmount),
            "RouterForKeeper.openPositionWithWallet: INSUFFICIENT_QUOTE_AMOUNT"
        );
    }

    function openPositionWithMargin(IOrderBook.OpenPositionOrder memory order, uint256 slippageRatio)
        external
        override
        ensure(order.deadline)
        onlyOrderBook
        returns (uint256 baseAmount)
    {
        address margin = IPairFactory(pairFactory).getMargin(order.baseToken, order.quoteToken);
        require(margin != address(0), "RouterForKeeper.openPositionWithMargin: NOT_FOUND_MARGIN");
        require(order.side == 0 || order.side == 1, "RouterForKeeper.openPositionWithMargin: INVALID_SIDE");
        baseAmount = IMargin(margin).openPosition(order.trader, order.side, order.quoteAmount);

        require(
            (order.side == 0)
                ? slippageRatio < ((order.quoteAmount * 1e18) / baseAmount)
                : slippageRatio > ((order.quoteAmount * 1e18) / baseAmount),
            "RouterForKeeper.openPositionWithMargin: INSUFFICIENT_QUOTE_AMOUNT"
        );
    }

    function closePosition(IOrderBook.ClosePositionOrder memory order)
        external
        override
        ensure(order.deadline)
        onlyOrderBook
    returns (uint256 baseAmount, uint256 withdrawAmount)
    {
        address margin = IPairFactory(pairFactory).getMargin(order.baseToken, order.quoteToken);
        require(margin != address(0), "RouterForKeeper.closePosition: NOT_FOUND_MARGIN");
        (, int256 quoteSizeBefore, ) = IMargin(margin).getPosition(order.trader);
        require(
            quoteSizeBefore > 0 ? order.side == 1 : order.side == 0,
            "RouterForKeeper.closePosition: SIDE_NOT_MATCH"
        );
        if (!order.autoWithdraw) {
            baseAmount = IMargin(margin).closePosition(order.trader, order.quoteAmount);
        } else {
            {
                baseAmount = IMargin(margin).closePosition(order.trader, order.quoteAmount);
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

    function pairFactory() external view returns (address);

    function WETH() external view returns (address);

    function openPositionWithWallet(IOrderBook.OpenPositionOrder memory order, uint256 deadline)
        external
        returns (uint256 baseAmount);

    function openPositionWithMargin(IOrderBook.OpenPositionOrder memory order, uint256 deadline)
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

    function setBot(address newBot) external;
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