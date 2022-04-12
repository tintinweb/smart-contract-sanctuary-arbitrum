// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IBondPoolFactory.sol";
import "./interfaces/IBondPool.sol";
import "./interfaces/IPCVTreasury.sol";
import "./interfaces/IBondPriceOracle.sol";
import "../core/interfaces/IRouter.sol";
import "../core/interfaces/IAmm.sol";
import "../core/interfaces/IERC20.sol";
import "../core/interfaces/IWETH.sol";
import "../libraries/TransferHelper.sol";
import "../libraries/FullMath.sol";
import "../utils/Ownable.sol";

contract BondPool is IBondPool, Ownable {
    IBondPoolFactory public override factory;
    address public override WETH;
    address public override apeXToken;
    address public override amm;
    uint256 public override maxPayout;
    uint256 public override discount; // [0, 10000]
    uint256 public override vestingTerm; // in seconds
    bool public override bondPaused;

    mapping(address => Bond) private bondInfo; // stores bond information for depositor

    function initialize(
        address owner_,
        address WETH_,
        address apeXToken_,
        address amm_,
        uint256 maxPayout_,
        uint256 discount_,
        uint256 vestingTerm_
    ) external override {
        require(WETH == address(0), "BondPool.initialize: ALREADY_INIT");
        factory = IBondPoolFactory(msg.sender);
        owner = owner_;
        WETH = WETH_;
        apeXToken = apeXToken_;
        amm = amm_;
        maxPayout = maxPayout_;
        discount = discount_;
        vestingTerm = vestingTerm_;
    }

    function setBondPaused(bool state) external override onlyOwner {
        bondPaused = state;
        emit BondPaused(state);
    }

    function setMaxPayout(uint256 maxPayout_) external override onlyOwner {
        emit MaxPayoutChanged(maxPayout, maxPayout_);
        maxPayout = maxPayout_;
    }

    function setDiscount(uint256 discount_) external override onlyOwner {
        require(discount_ <= 10000, "BondPool.setDiscount: OVER_100%");
        emit DiscountChanged(discount, discount_);
        discount = discount_;
    }

    function setVestingTerm(uint256 vestingTerm_) external override onlyOwner {
        require(vestingTerm_ >= 129600, "BondPool.setVestingTerm: MUST_BE_LONGER_THAN_36_HOURS");
        emit VestingTermChanged(vestingTerm, vestingTerm_);
        vestingTerm = vestingTerm_;
    }

    function deposit(
        address depositor,
        uint256 depositAmount,
        uint256 minPayout
    ) external override returns (uint256 payout) {
        return _depositInternal(msg.sender, depositor, depositAmount, minPayout);
    }

    function depositETH(address depositor, uint256 minPayout) external payable override returns (uint256 ethAmount, uint256 payout) {
        require(IAmm(amm).baseToken() == WETH, "BondPool.depositETH: ETH_NOT_SUPPORTED");
        ethAmount = msg.value;
        IWETH(WETH).deposit{value: ethAmount}();
        payout = _depositInternal(address(this), depositor, ethAmount, minPayout);
    }

    function redeem(address depositor) external override returns (uint256 payout) {
        Bond memory info = bondInfo[depositor];
        uint256 percentVested = percentVestedFor(depositor); // (blocks since last interaction / vesting term remaining)

        if (percentVested >= 10000) {
            // if fully vested
            delete bondInfo[depositor]; // delete user info
            payout = info.payout;
            emit BondRedeemed(depositor, payout, 0); // emit bond data
            TransferHelper.safeTransfer(apeXToken, depositor, payout);
        } else {
            // if unfinished
            // calculate payout vested
            payout = (info.payout * percentVested) / 10000;

            // store updated deposit info
            bondInfo[depositor] = Bond({
                payout: info.payout - payout,
                vesting: info.vesting - (block.timestamp - info.lastBlockTime),
                lastBlockTime: block.timestamp,
                paidAmount: info.paidAmount
            });

            emit BondRedeemed(depositor, payout, bondInfo[depositor].payout);
            TransferHelper.safeTransfer(apeXToken, depositor, payout);
        }
    }

    function bondInfoFor(address depositor) external view override returns (Bond memory) {
        return bondInfo[depositor];
    }

    // calculate how many APEX out for input amount of base token
    // marketPrice = amount / marketApeXAmount
    // bondPrice = marketPrice * (1 - discount) = amount * (1 - discount) / marketApeXAmount
    // payout = amount / bondPrice = marketApeXAmount / (1 - discount))
    function payoutFor(uint256 amount) public view override returns (uint256 payout) {
        address baseToken = IAmm(amm).baseToken();
        uint256 marketApeXAmount = IBondPriceOracle(factory.priceOracle()).quote(baseToken, amount);
        payout = marketApeXAmount * 10000 / (10000 - discount);
    }

    function percentVestedFor(address depositor) public view override returns (uint256 percentVested) {
        Bond memory bond = bondInfo[depositor];
        uint256 deltaSinceLast = block.timestamp - bond.lastBlockTime;
        uint256 vesting = bond.vesting;
        if (vesting > 0) {
            percentVested = (deltaSinceLast * 10000) / vesting;
        } else {
            percentVested = 0;
        }
    }

    function _depositInternal(
        address from,
        address depositor,
        uint256 depositAmount,
        uint256 minPayout
    ) internal returns (uint256 payout) {
        require(!bondPaused, "BondPool._depositInternal: BOND_PAUSED");
        require(depositor != address(0), "BondPool._depositInternal: ZERO_ADDRESS");
        require(depositAmount > 0, "BondPool._depositInternal: ZERO_AMOUNT");

        address baseToken = IAmm(amm).baseToken();
        address quoteToken = IAmm(amm).quoteToken();
        TransferHelper.safeTransferFrom(baseToken, from, address(this), depositAmount);

        address router = factory.router();
        uint256 allowance = IERC20(baseToken).allowance(address(this), router);
        if (allowance < depositAmount) {
            IERC20(baseToken).approve(router, type(uint256).max);
        }
        (, uint256 liquidity) = IRouter(router).addLiquidity(baseToken, quoteToken, depositAmount, 1, block.timestamp, false);
        require(liquidity > 0, "BondPool._depositInternal: AMOUNT_TOO_SMALL");

        payout = payoutFor(depositAmount);
        require(payout >= minPayout, "BondPool._depositInternal: UNDER_MIN_LAYOUT");
        require(payout <= maxPayout, "BondPool._depositInternal: OVER_MAX_PAYOUT");
        maxPayout -= payout;

        address treasury = factory.treasury();
        TransferHelper.safeApprove(amm, treasury, liquidity);
        IPCVTreasury(treasury).deposit(amm, liquidity, payout);

        bondInfo[depositor] = Bond({
            payout: bondInfo[depositor].payout + payout,
            vesting: vestingTerm,
            lastBlockTime: block.timestamp,
            paidAmount: bondInfo[depositor].paidAmount + depositAmount
        });
        emit BondCreated(depositor, depositAmount, payout, block.timestamp + vestingTerm);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title The interface for a bond pool factory
/// @notice For create bond pool
interface IBondPoolFactory {
    event BondPoolCreated(address indexed amm, address indexed pool);
    event RouterUpdated(address indexed oldRouter, address indexed newRouter);
    event PriceOracleUpdated(address indexed oldOracle, address indexed newOracle);
    event PoolTemplateUpdated(address indexed oldTemplate, address indexed newTemplate);

    function setRouter(address newRouter) external;

    function setPriceOracle(address newOracle) external;

    function setPoolTemplate(address poolTemplate) external;

    function updateParams(
        uint256 maxPayout_,
        uint256 discount_,
        uint256 vestingTerm_
    ) external;

    function createPool(address amm) external returns (address);

    function WETH() external view returns (address);

    function apeXToken() external view returns (address);

    function treasury() external view returns (address);

    function router() external view returns (address);

    function priceOracle() external view returns (address);

    function poolTemplate() external view returns (address);

    function maxPayout() external view returns (uint256);

    function discount() external view returns (uint256);

    function vestingTerm() external view returns (uint256);

    function getPool(address amm) external view returns (address);

    function allPools(uint256) external view returns (address);

    function allPoolsLength() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IBondPoolFactory.sol";

/// @title The interface for a bond pool
/// @notice A bond pool always be created by bond pool factory
interface IBondPool {
    /// @notice Emitted when a user finish deposit for a bond
    /// @param depositor User's address
    /// @param deposit The base token amount paid by sender
    /// @param payout The amount of apeX token for this bond
    /// @param expires The bonding's expire timestamp
    event BondCreated(address depositor, uint256 deposit, uint256 payout, uint256 expires);

    /// @notice Emitted when a redeem finish
    /// @param depositor Bonder's address
    /// @param payout The amount of apeX redeemed
    /// @param remaining The amount of apeX remaining in the bond
    event BondRedeemed(address depositor, uint256 payout, uint256 remaining);

    event BondPaused(bool state);
    event MaxPayoutChanged(uint256 oldMaxPayout, uint256 newMaxPayout);
    event DiscountChanged(uint256 oldDiscount, uint256 newDiscount);
    event VestingTermChanged(uint256 oldVestingTerm, uint256 newVestingTerm);

    // Info for bond depositor
    struct Bond {
        uint256 payout; // apeX token amount
        uint256 vesting; // bonding term, in seconds
        uint256 lastBlockTime; // last action time
        uint256 paidAmount; // base token paid
    }

    function initialize(
        address owner_,
        address WETH_,
        address apeXToken_,
        address amm_,
        uint256 maxPayout_,
        uint256 discount_,
        uint256 vestingTerm_
    ) external;

    /// @notice Set bond open or pause
    function setBondPaused(bool state) external;

    /// @notice Only owner can set this
    function setMaxPayout(uint256 maxPayout_) external;

    /// @notice Only owner can set this
    function setDiscount(uint256 discount_) external;

    /// @notice Only owner can set this
    function setVestingTerm(uint256 vestingTerm_) external;

    /// @notice User deposit the base token to make a bond for the apeX token
    function deposit(
        address depositor,
        uint256 depositAmount,
        uint256 minPayout
    ) external returns (uint256 payout);

    /// @notice User deposit ETH to make a bond for the apeX token
    function depositETH(address depositor, uint256 minPayout) external payable returns (uint256 ethAmount, uint256 payout);

    /// @notice For user to redeem the apeX
    function redeem(address depositor) external returns (uint256 payout);

    /// @notice BondPoolFactory address
    function factory() external view returns (IBondPoolFactory);

    /// @notice WETH address
    function WETH() external view returns (address);

    /// @notice ApeXToken address
    function apeXToken() external view returns (address);

    /// @notice Amm pool address
    function amm() external view returns (address);

    /// @notice Left total amount of apeX token for bonding in this bond pool
    function maxPayout() external view returns (uint256);

    /// @notice Discount percent for bonding
    function discount() external view returns (uint256);

    /// @notice Bonding term in seconds, at least 129600 = 36 hours
    function vestingTerm() external view returns (uint256);

    /// @notice If is true, the bond is paused
    function bondPaused() external view returns (bool);

    /// @notice Get depositor's bond info
    function bondInfoFor(address depositor) external view returns (Bond memory);

    /// @notice Calculate how many apeX payout for input base token amount
    function payoutFor(uint256 amount) external view returns (uint256 payout);

    /// @notice Get the percent of apeX redeemable
    function percentVestedFor(address depositor) external view returns (uint256 percentVested);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IPCVTreasury {
    event NewLiquidityToken(address indexed lpToken);
    event NewBondPool(address indexed pool);
    event Deposit(address indexed pool, address indexed lpToken, uint256 amountIn, uint256 payout);
    event Withdraw(address indexed lpToken, address indexed policy, uint256 amount);
    event ApeXGranted(address indexed to, uint256 amount);

    function apeXToken() external view returns (address);

    function isLiquidityToken(address) external view returns (bool);

    function isBondPool(address) external view returns (bool);

    function addLiquidityToken(address lpToken) external;

    function addBondPool(address pool) external;

    function deposit(
        address lpToken,
        uint256 amountIn,
        uint256 payout
    ) external;

    function withdraw(
        address lpToken,
        address policy,
        uint256 amount,
        bytes calldata data
    ) external;

    function grantApeX(address to, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IBondPriceOracle {
    function setupTwap(address baseToken) external;

    function quote(address baseToken, uint256 baseAmount) external view returns (uint256 apeXAmount);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IRouter {
    function config() external view returns (address);
    
    function pairFactory() external view returns (address);

    function pcvTreasury() external view returns (address);

    function WETH() external view returns (address);

    function addLiquidity(
        address baseToken,
        address quoteToken,
        uint256 baseAmount,
        uint256 quoteAmountMin,
        uint256 deadline,
        bool pcv
    ) external returns (uint256 quoteAmount, uint256 liquidity);

    function addLiquidityETH(
        address quoteToken,
        uint256 quoteAmountMin,
        uint256 deadline,
        bool pcv
    )
        external
        payable
        returns (
            uint256 ethAmount,
            uint256 quoteAmount,
            uint256 liquidity
        );

    function removeLiquidity(
        address baseToken,
        address quoteToken,
        uint256 liquidity,
        uint256 baseAmountMin,
        uint256 deadline
    ) external returns (uint256 baseAmount, uint256 quoteAmount);

    function removeLiquidityETH(
        address quoteToken,
        uint256 liquidity,
        uint256 ethAmountMin,
        uint256 deadline
    ) external returns (uint256 ethAmount, uint256 quoteAmount);

    function deposit(
        address baseToken,
        address quoteToken,
        address holder,
        uint256 amount
    ) external;

    function depositETH(address quoteToken, address holder) external payable;

    function withdraw(
        address baseToken,
        address quoteToken,
        uint256 amount
    ) external;

    function withdrawETH(address quoteToken, uint256 amount) external;

    function openPositionWithWallet(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 marginAmount,
        uint256 quoteAmount,
        uint256 baseAmountLimit,
        uint256 deadline
    ) external returns (uint256 baseAmount);

    function openPositionETHWithWallet(
        address quoteToken,
        uint8 side,
        uint256 quoteAmount,
        uint256 baseAmountLimit,
        uint256 deadline
    ) external payable returns (uint256 baseAmount);

    function openPositionWithMargin(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 quoteAmount,
        uint256 baseAmountLimit,
        uint256 deadline
    ) external returns (uint256 baseAmount);

    function closePosition(
        address baseToken,
        address quoteToken,
        uint256 quoteAmount,
        uint256 deadline,
        bool autoWithdraw
    ) external returns (uint256 baseAmount, uint256 withdrawAmount);

    function closePositionETH(
        address quoteToken,
        uint256 quoteAmount,
        uint256 deadline
    ) external returns (uint256 baseAmount, uint256 withdrawAmount);

    function liquidate(
        address baseToken,
        address quoteToken,
        address trader,
        address to
    ) external returns (uint256 quoteAmount, uint256 baseAmount, uint256 bonus);

    function getReserves(address baseToken, address quoteToken)
        external
        view
        returns (uint256 reserveBase, uint256 reserveQuote);

    function getQuoteAmount(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 baseAmount
    ) external view returns (uint256 quoteAmount);

    function getWithdrawable(
        address baseToken,
        address quoteToken,
        address holder
    ) external view returns (uint256 amount);

    function getPosition(
        address baseToken,
        address quoteToken,
        address holder
    )
        external
        view
        returns (
            int256 baseSize,
            int256 quoteSize,
            uint256 tradeSize
        );
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./BondPool.sol";
import "./interfaces/IBondPoolFactory.sol";
import "./interfaces/IBondPool.sol";
import "./interfaces/IPCVTreasury.sol";
import "./interfaces/IBondPriceOracle.sol";
import "../utils/Ownable.sol";
import "../core/interfaces/IAmm.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract BondPoolFactory is IBondPoolFactory, Ownable {
    address public immutable override WETH;
    address public immutable override apeXToken;
    address public immutable override treasury;
    address public override router;
    address public override priceOracle;
    address public override poolTemplate;
    uint256 public override maxPayout;
    uint256 public override discount; // [0, 10000]
    uint256 public override vestingTerm;

    address[] public override allPools;
    // amm => pool
    mapping(address => address) public override getPool;

    constructor(
        address WETH_,
        address apeXToken_,
        address treasury_,
        address router_,
        address priceOracle_,
        address poolTemplate_,
        uint256 maxPayout_,
        uint256 discount_,
        uint256 vestingTerm_
    ) {
        owner = msg.sender;
        WETH = WETH_;
        apeXToken = apeXToken_;
        treasury = treasury_;
        router = router_;
        priceOracle = priceOracle_;
        poolTemplate = poolTemplate_;
        maxPayout = maxPayout_;
        discount = discount_;
        vestingTerm = vestingTerm_;
    }

    function setRouter(address newRouter) external override onlyOwner {
        require(newRouter != address(0), "BondPoolFactory.setRouter: ZERO_ADDRESS");
        emit RouterUpdated(router, newRouter);
        router = newRouter;
    }

    function setPriceOracle(address newOracle) external override onlyOwner {
        require(newOracle != address(0), "BondPoolFactory.setPriceOracle: ZERO_ADDRESS");
        emit PriceOracleUpdated(priceOracle, newOracle);
        priceOracle = newOracle;
    }

    function setPoolTemplate(address newTemplate) external override onlyOwner {
        require(newTemplate != address(0), "BondPoolFactory.setPoolTemplate: ZERO_ADDRESS");
        emit PoolTemplateUpdated(poolTemplate, newTemplate);
        poolTemplate = newTemplate;
    }

    function updateParams(
        uint256 maxPayout_,
        uint256 discount_,
        uint256 vestingTerm_
    ) external override onlyOwner {
        maxPayout = maxPayout_;
        require(discount_ <= 10000, "BondPoolFactory.updateParams: DISCOUNT_OVER_100%");
        discount = discount_;
        require(vestingTerm_ >= 129600, "BondPoolFactory.updateParams: MUST_BE_LONGER_THAN_36_HOURS");
        vestingTerm = vestingTerm_;
    }

    function createPool(address amm) external override onlyOwner returns (address) {
        require(amm != address(0), "BondPoolFactory.createPool: ZERO_ADDRESS");
        require(getPool[amm] == address(0), "BondPoolFactory.createPool: POOL_EXIST");
        address pool = Clones.clone(poolTemplate);
        IBondPool(pool).initialize(owner, WETH, apeXToken, amm, maxPayout, discount, vestingTerm);
        getPool[amm] = pool;
        allPools.push(pool);
        address baseToken = IAmm(amm).baseToken();
        IBondPriceOracle(priceOracle).setupTwap(baseToken);
        emit BondPoolCreated(amm, pool);
        return pool;
    }

    function allPoolsLength() external view override returns (uint256) {
        return allPools.length;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IStakingPool.sol";
import "./interfaces/IApeXPool.sol";
import "./interfaces/IStakingPoolFactory.sol";
import "../utils/Initializable.sol";
import "../utils/Ownable.sol";
import "./StakingPool.sol";
import "./interfaces/IERC20Extend.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

//this is a stakingPool factory to create and register stakingPool, distribute esApeX token according to pools' weight
contract StakingPoolFactory is IStakingPoolFactory, Ownable, Initializable {
    uint256 constant tenK = 10000;
    address public override apeX;
    address public override esApeX;
    address public override veApeX;
    address public override treasury;
    uint256 public override lastUpdateTimestamp;
    uint256 public override secSpanPerUpdate;
    uint256 public override apeXPerSec;
    uint256 public override totalWeight;
    uint256 public override endTimestamp;
    uint256 public override lockTime;
    uint256 public override minRemainRatioAfterBurn; //10k-based
    uint256 public override remainForOtherVest; //100-based, 50 means half of remain to other vest, half to treasury
    uint256 public priceOfWeight; //multiplied by 10k
    uint256 public lastTimeUpdatePriceOfWeight;
    address public override stakingPoolTemplate;

    mapping(address => address) public tokenPoolMap; //token->pool, only for relationships in use
    mapping(address => PoolWeight) public poolWeightMap; //pool->weight, historical pools are also stored

    function initialize(
        address _apeX,
        address _treasury,
        uint256 _apeXPerSec,
        uint256 _secSpanPerUpdate,
        uint256 _initTimestamp,
        uint256 _endTimestamp,
        uint256 _lockTime
    ) public initializer {
        require(_apeX != address(0), "spf.initialize: INVALID_APEX");
        require(_treasury != address(0), "spf.initialize: INVALID_TREASURY");
        require(_apeXPerSec > 0, "spf.initialize: INVALID_PER_SEC");
        require(_secSpanPerUpdate > 0, "spf.initialize: INVALID_UPDATE_SPAN");
        require(_initTimestamp > 0, "spf.initialize: INVALID_INIT_TIMESTAMP");
        require(_endTimestamp > _initTimestamp, "spf.initialize: INVALID_END_TIMESTAMP");
        require(_lockTime > 0, "spf.initialize: INVALID_LOCK_TIME");

        owner = msg.sender;
        apeX = _apeX;
        treasury = _treasury;
        apeXPerSec = _apeXPerSec;
        secSpanPerUpdate = _secSpanPerUpdate;
        lastUpdateTimestamp = _initTimestamp;
        endTimestamp = _endTimestamp;
        lockTime = _lockTime;
        lastTimeUpdatePriceOfWeight = _initTimestamp;
    }

    function setStakingPoolTemplate(address _template) external override onlyOwner {
        require(_template != address(0), "spf.setStakingPoolTemplate: ZERO_ADDRESS");

        emit SetStakingPoolTemplate(stakingPoolTemplate, _template);
        stakingPoolTemplate = _template;
    }

    function createPool(address _poolToken, uint256 _weight) external override onlyOwner {
        require(_poolToken != address(0), "spf.createPool: ZERO_ADDRESS");
        require(_poolToken != apeX, "spf.createPool: CANT_APEX");
        require(stakingPoolTemplate != address(0), "spf.createPool: ZERO_TEMPLATE");

        address pool = Clones.clone(stakingPoolTemplate);
        IStakingPool(pool).initialize(address(this), _poolToken);

        _registerPool(pool, _poolToken, _weight);
    }

    function registerApeXPool(address _pool, uint256 _weight) external override onlyOwner {
        address poolToken = IApeXPool(_pool).poolToken();
        require(poolToken == apeX, "spf.registerApeXPool: MUST_APEX");

        _registerPool(_pool, poolToken, _weight);
    }

    function unregisterPool(address _pool) external override onlyOwner {
        require(poolWeightMap[_pool].weight != 0, "spf.unregisterPool: POOL_NOT_REGISTERED");
        require(poolWeightMap[_pool].exitYieldPriceOfWeight == 0, "spf.unregisterPool: POOL_HAS_UNREGISTERED");

        priceOfWeight += ((_calPendingFactoryReward() * tenK) / totalWeight);
        lastTimeUpdatePriceOfWeight = block.timestamp;

        totalWeight -= poolWeightMap[_pool].weight;
        poolWeightMap[_pool].exitYieldPriceOfWeight = priceOfWeight;
        delete tokenPoolMap[IStakingPool(_pool).poolToken()];

        emit PoolUnRegistered(msg.sender, _pool);
    }

    function changePoolWeight(address _pool, uint256 _weight) external override onlyOwner {
        require(poolWeightMap[_pool].weight > 0, "spf.changePoolWeight: POOL_NOT_EXIST");
        require(poolWeightMap[_pool].exitYieldPriceOfWeight == 0, "spf.changePoolWeight: POOL_INVALID");
        require(_weight != 0, "spf.changePoolWeight: CANT_CHANGE_TO_ZERO_WEIGHT");

        if (totalWeight != 0) {
            priceOfWeight += ((_calPendingFactoryReward() * tenK) / totalWeight);
            lastTimeUpdatePriceOfWeight = block.timestamp;
        }

        totalWeight = totalWeight + _weight - poolWeightMap[_pool].weight;
        poolWeightMap[_pool].weight = _weight;
        poolWeightMap[_pool].lastYieldPriceOfWeight = priceOfWeight;

        emit WeightUpdated(msg.sender, _pool, _weight);
    }

    function updateApeXPerSec() external override {
        uint256 currentTimestamp = block.timestamp;
        require(currentTimestamp >= lastUpdateTimestamp + secSpanPerUpdate, "spf.updateApeXPerSec: TOO_FREQUENT");
        require(currentTimestamp <= endTimestamp, "spf.updateApeXPerSec: END");

        apeXPerSec = (apeXPerSec * 97) / 100;
        lastUpdateTimestamp = currentTimestamp;

        emit UpdateApeXPerSec(apeXPerSec);
    }

    function syncYieldPriceOfWeight() external override returns (uint256) {
        (uint256 reward, uint256 newPriceOfWeight) = _calStakingPoolApeXReward(msg.sender);
        emit SyncYieldPriceOfWeight(poolWeightMap[msg.sender].lastYieldPriceOfWeight, newPriceOfWeight);

        poolWeightMap[msg.sender].lastYieldPriceOfWeight = newPriceOfWeight;
        return reward;
    }

    function transferYieldTo(address _to, uint256 _amount) external override {
        require(poolWeightMap[msg.sender].weight > 0, "spf.transferYieldTo: ACCESS_DENIED");

        emit TransferYieldTo(msg.sender, _to, _amount);
        IERC20(apeX).transfer(_to, _amount);
    }

    function transferYieldToTreasury(uint256 _amount) external override {
        require(poolWeightMap[msg.sender].weight > 0, "spf.transferYieldToTreasury: ACCESS_DENIED");

        address _treasury = treasury;
        emit TransferYieldToTreasury(msg.sender, _treasury, _amount);
        IERC20(apeX).transfer(_treasury, _amount);
    }

    function withdrawApeX(address to, uint256 amount) external override onlyOwner {
        require(amount <= IERC20(apeX).balanceOf(address(this)), "spf.withdrawApeX: NO_ENOUGH_APEX");
        IERC20(apeX).transfer(to, amount);
        emit WithdrawApeX(to, amount);
    }

    function transferEsApeXTo(address _to, uint256 _amount) external override {
        require(poolWeightMap[msg.sender].weight > 0, "spf.transferEsApeXTo: ACCESS_DENIED");

        emit TransferEsApeXTo(msg.sender, _to, _amount);
        IERC20(esApeX).transfer(_to, _amount);
    }

    function transferEsApeXFrom(
        address _from,
        address _to,
        uint256 _amount
    ) external override {
        require(poolWeightMap[msg.sender].weight > 0, "spf.transferEsApeXFrom: ACCESS_DENIED");

        emit TransferEsApeXFrom(_from, _to, _amount);
        IERC20(esApeX).transferFrom(_from, _to, _amount);
    }

    function burnEsApeX(address from, uint256 amount) external override {
        require(poolWeightMap[msg.sender].weight > 0, "spf.burnEsApeX: ACCESS_DENIED");
        IERC20Extend(esApeX).burn(from, amount);
    }

    function mintEsApeX(address to, uint256 amount) external override {
        require(poolWeightMap[msg.sender].weight > 0, "spf.mintEsApeX: ACCESS_DENIED");
        IERC20Extend(esApeX).mint(to, amount);
    }

    function burnVeApeX(address from, uint256 amount) external override {
        require(poolWeightMap[msg.sender].weight > 0, "spf.burnVeApeX: ACCESS_DENIED");
        IERC20Extend(veApeX).burn(from, amount);
    }

    function mintVeApeX(address to, uint256 amount) external override {
        require(poolWeightMap[msg.sender].weight > 0, "spf.mintVeApeX: ACCESS_DENIED");
        IERC20Extend(veApeX).mint(to, amount);
    }

    function calPendingFactoryReward() external view override returns (uint256 reward) {
        return _calPendingFactoryReward();
    }

    function calLatestPriceOfWeight() external view override returns (uint256) {
        return priceOfWeight + ((_calPendingFactoryReward() * tenK) / totalWeight);
    }

    function calStakingPoolApeXReward(address token)
        external
        view
        override
        returns (uint256 reward, uint256 newPriceOfWeight)
    {
        address pool = tokenPoolMap[token];
        return _calStakingPoolApeXReward(pool);
    }

    function shouldUpdateRatio() external view override returns (bool) {
        uint256 currentTimestamp = block.timestamp;
        return currentTimestamp > endTimestamp ? false : currentTimestamp >= lastUpdateTimestamp + secSpanPerUpdate;
    }

    function _registerPool(
        address _pool,
        address _poolToken,
        uint256 _weight
    ) internal {
        require(poolWeightMap[_pool].weight == 0, "spf.registerPool: POOL_REGISTERED");
        require(tokenPoolMap[_poolToken] == address(0), "spf.registerPool: POOL_TOKEN_REGISTERED");

        if (totalWeight != 0) {
            priceOfWeight += ((_calPendingFactoryReward() * tenK) / totalWeight);
            lastTimeUpdatePriceOfWeight = block.timestamp;
        }

        tokenPoolMap[_poolToken] = _pool;
        poolWeightMap[_pool] = PoolWeight({
            weight: _weight,
            lastYieldPriceOfWeight: priceOfWeight,
            exitYieldPriceOfWeight: 0
        });
        totalWeight += _weight;

        emit PoolRegistered(msg.sender, _poolToken, _pool, _weight);
    }

    function _calPendingFactoryReward() internal view returns (uint256 reward) {
        uint256 currentTimestamp = block.timestamp;
        uint256 secPassed = currentTimestamp > endTimestamp
            ? endTimestamp - lastTimeUpdatePriceOfWeight
            : currentTimestamp - lastTimeUpdatePriceOfWeight;
        reward = secPassed * apeXPerSec;
    }

    function _calStakingPoolApeXReward(address pool) internal view returns (uint256 reward, uint256 newPriceOfWeight) {
        require(pool != address(0), "spf._calStakingPoolApeXReward: INVALID_TOKEN");
        PoolWeight memory pw = poolWeightMap[pool];
        if (pw.exitYieldPriceOfWeight > 0) {
            newPriceOfWeight = pw.exitYieldPriceOfWeight;
            reward = (pw.weight * (pw.exitYieldPriceOfWeight - pw.lastYieldPriceOfWeight)) / tenK;
            return (reward, newPriceOfWeight);
        }
        newPriceOfWeight = priceOfWeight;
        if (totalWeight > 0) {
            newPriceOfWeight += ((_calPendingFactoryReward() * tenK) / totalWeight);
        }

        reward = (pw.weight * (newPriceOfWeight - pw.lastYieldPriceOfWeight)) / tenK;
    }

    function setLockTime(uint256 _lockTime) external onlyOwner {
        lockTime = _lockTime;

        emit SetYieldLockTime(_lockTime);
    }

    function setMinRemainRatioAfterBurn(uint256 _minRemainRatioAfterBurn) external override onlyOwner {
        require(_minRemainRatioAfterBurn <= tenK, "spf.setMinRemainRatioAfterBurn: INVALID_VALUE");
        minRemainRatioAfterBurn = _minRemainRatioAfterBurn;

        emit SetMinRemainRatioAfterBurn(_minRemainRatioAfterBurn);
    }

    function setRemainForOtherVest(uint256 _remainForOtherVest) external override onlyOwner {
        require(_remainForOtherVest <= 100, "spf.setRemainForOtherVest: INVALID_VALUE");
        remainForOtherVest = _remainForOtherVest;

        emit SetRemainForOtherVest(_remainForOtherVest);
    }

    function setEsApeX(address _esApeX) external override onlyOwner {
        require(esApeX == address(0), "spf.setEsApeX: HAS_SET");
        esApeX = _esApeX;

        emit SetEsApeX(_esApeX);
    }

    function setVeApeX(address _veApeX) external override onlyOwner {
        require(veApeX == address(0), "spf.setVeApeX: HAS_SET");
        veApeX = _veApeX;

        emit SetVeApeX(_veApeX);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IStakingPool {
    struct Deposit {
        uint256 amount;
        uint256 weight;
        uint256 lockFrom;
        uint256 lockUntil;
    }

    struct User {
        uint256 tokenAmount; //vest + stake
        uint256 totalWeight; //stake
        uint256 subYieldRewards;
        Deposit[] deposits; //stake slp/alp
    }

    event BatchWithdraw(address indexed by, uint256[] _depositIds, uint256[] _depositAmounts);

    event Staked(address indexed to, uint256 depositId, uint256 amount, uint256 lockFrom, uint256 lockUntil);

    event Synchronized(address indexed by, uint256 yieldRewardsPerWeight);

    event UpdateStakeLock(address indexed by, uint256 depositId, uint256 lockFrom, uint256 lockUntil);

    event MintEsApeX(address to, uint256 amount);

    /// @notice Get pool token of this core pool
    function poolToken() external view returns (address);

    function getStakeInfo(address _user)
        external
        view
        returns (
            uint256 tokenAmount,
            uint256 totalWeight,
            uint256 subYieldRewards
        );

    function getDeposit(address _user, uint256 _depositId) external view returns (Deposit memory);

    function getDepositsLength(address _user) external view returns (uint256);

    function initialize(address _factory, address _poolToken) external;

    /// @notice Process yield reward (esApeX) of msg.sender
    function processRewards() external;

    /// @notice Stake poolToken
    /// @param amount poolToken's amount to stake.
    /// @param lockUntil time to lock.
    function stake(uint256 amount, uint256 lockUntil) external;

    /// @notice BatchWithdraw poolToken
    /// @param depositIds the deposit index.
    /// @param depositAmounts poolToken's amount to unstake.
    function batchWithdraw(uint256[] memory depositIds, uint256[] memory depositAmounts) external;

    /// @notice enlarge lock time of this deposit `depositId` to `lockUntil`
    /// @param depositId the deposit index.
    /// @param lockUntil new lock time.
    function updateStakeLock(uint256 depositId, uint256 lockUntil) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IApeXPool {
    struct Deposit {
        uint256 amount;
        uint256 weight;
        uint256 lockFrom;
        uint256 lockUntil;
    }

    struct Yield {
        uint256 amount;
        uint256 lockFrom;
        uint256 lockUntil;
    }

    struct User {
        uint256 tokenAmount; //vest + stake
        uint256 totalWeight; //stake
        uint256 subYieldRewards;
        Deposit[] deposits; //stake ApeX
        Yield[] yields; //vest esApeX
        Deposit[] esDeposits; //stake esApeX
    }

    event BatchWithdraw(
        address indexed by,
        uint256[] _depositIds,
        uint256[] _depositAmounts,
        uint256[] _yieldIds,
        uint256[] _yieldAmounts,
        uint256[] _esDepositIds,
        uint256[] _esDepositAmounts
    );

    event ForceWithdraw(address indexed by, uint256[] yieldIds);

    event Staked(
        address indexed to,
        uint256 depositId,
        bool isEsApeX,
        uint256 amount,
        uint256 lockFrom,
        uint256 lockUntil
    );

    event YieldClaimed(address indexed by, uint256 depositId, uint256 amount, uint256 lockFrom, uint256 lockUntil);

    event Synchronized(address indexed by, uint256 yieldRewardsPerWeight);

    event UpdateStakeLock(address indexed by, uint256 depositId, bool isEsApeX, uint256 lockFrom, uint256 lockUntil);

    event MintEsApeX(address to, uint256 amount);

    /// @notice Get pool token of this core pool
    function poolToken() external view returns (address);

    function getStakeInfo(address _user)
        external
        view
        returns (
            uint256 tokenAmount,
            uint256 totalWeight,
            uint256 subYieldRewards
        );

    function getDeposit(address _user, uint256 _depositId) external view returns (Deposit memory);

    function getDepositsLength(address _user) external view returns (uint256);

    function getYield(address _user, uint256 _yieldId) external view returns (Yield memory);

    function getYieldsLength(address _user) external view returns (uint256);

    function getEsDeposit(address _user, uint256 _esDepositId) external view returns (Deposit memory);

    function getEsDepositsLength(address _user) external view returns (uint256);

    /// @notice Process yield reward (esApeX) of msg.sender
    function processRewards() external;

    /// @notice Stake apeX
    /// @param amount apeX's amount to stake.
    /// @param lockUntil time to lock.
    function stake(uint256 amount, uint256 lockUntil) external;

    function stakeEsApeX(uint256 amount, uint256 lockUntil) external;

    function vest(uint256 amount) external;

    /// @notice BatchWithdraw poolToken
    /// @param depositIds the deposit index.
    /// @param depositAmounts poolToken's amount to unstake.
    function batchWithdraw(
        uint256[] memory depositIds,
        uint256[] memory depositAmounts,
        uint256[] memory yieldIds,
        uint256[] memory yieldAmounts,
        uint256[] memory esDepositIds,
        uint256[] memory esDepositAmounts
    ) external;

    /// @notice force withdraw locked reward
    /// @param depositIds the deposit index of locked reward.
    function forceWithdraw(uint256[] memory depositIds) external;

    /// @notice enlarge lock time of this deposit `depositId` to `lockUntil`
    /// @param depositId the deposit index.
    /// @param lockUntil new lock time.
    /// @param isEsApeX update esApeX or apeX stake.
    function updateStakeLock(
        uint256 depositId,
        uint256 lockUntil,
        bool isEsApeX
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IStakingPoolFactory {
    struct PoolWeight {
        uint256 weight;
        uint256 lastYieldPriceOfWeight; //multiplied by 10000
        uint256 exitYieldPriceOfWeight;
    }

    event WeightUpdated(address indexed by, address indexed pool, uint256 weight);

    event PoolRegistered(address indexed by, address indexed poolToken, address indexed pool, uint256 weight);

    event PoolUnRegistered(address indexed by, address indexed pool);

    event SetYieldLockTime(uint256 yieldLockTime);

    event UpdateApeXPerSec(uint256 apeXPerSec);

    event TransferYieldTo(address by, address to, uint256 amount);

    event TransferYieldToTreasury(address by, address to, uint256 amount);

    event TransferEsApeXTo(address by, address to, uint256 amount);

    event TransferEsApeXFrom(address from, address to, uint256 amount);

    event SetEsApeX(address esApeX);

    event SetVeApeX(address veApeX);

    event SetStakingPoolTemplate(address oldTemplate, address newTemplate);

    event SyncYieldPriceOfWeight(uint256 oldYieldPriceOfWeight, uint256 newYieldPriceOfWeight);

    event WithdrawApeX(address to, uint256 amount);

    event SetRemainForOtherVest(uint256);

    event SetMinRemainRatioAfterBurn(uint256);

    function apeX() external view returns (address);

    function esApeX() external view returns (address);

    function veApeX() external view returns (address);

    function treasury() external view returns (address);

    function lastUpdateTimestamp() external view returns (uint256);

    function secSpanPerUpdate() external view returns (uint256);

    function apeXPerSec() external view returns (uint256);

    function totalWeight() external view returns (uint256);

    function stakingPoolTemplate() external view returns (address);

    /// @notice get the end timestamp to yield, after this, no yield reward
    function endTimestamp() external view returns (uint256);

    function lockTime() external view returns (uint256);

    /// @notice get minimum remain ratio after force withdraw
    function minRemainRatioAfterBurn() external view returns (uint256);

    function remainForOtherVest() external view returns (uint256);

    /// @notice check if can update reward ratio
    function shouldUpdateRatio() external view returns (bool);

    /// @notice calculate yield reward of poolToken since lastYieldPriceOfWeight
    function calStakingPoolApeXReward(address token) external view returns (uint256 reward, uint256 newPriceOfWeight);

    function calPendingFactoryReward() external view returns (uint256 reward);

    function calLatestPriceOfWeight() external view returns (uint256);

    function syncYieldPriceOfWeight() external returns (uint256 reward);

    /// @notice update yield reward rate
    function updateApeXPerSec() external;

    function setStakingPoolTemplate(address _template) external;

    /// @notice create a new stakingPool
    /// @param poolToken stakingPool staked token.
    /// @param weight new pool's weight between all other stakingPools.
    function createPool(address poolToken, uint256 weight) external;

    /// @notice register apeX pool to factory
    /// @param pool the exist pool.
    /// @param weight pool's weight between all other stakingPools.
    function registerApeXPool(address pool, uint256 weight) external;

    /// @notice unregister an exist pool
    function unregisterPool(address pool) external;

    /// @notice mint apex to staker
    /// @param to the staker.
    /// @param amount apex amount.
    function transferYieldTo(address to, uint256 amount) external;

    function transferYieldToTreasury(uint256 amount) external;

    function withdrawApeX(address to, uint256 amount) external;

    /// @notice change a pool's weight
    /// @param poolAddr the pool.
    /// @param weight new weight.
    function changePoolWeight(address poolAddr, uint256 weight) external;

    /// @notice set minimum reward ratio when force withdraw locked rewards
    function setMinRemainRatioAfterBurn(uint256 _minRemainRatioAfterBurn) external;

    function setRemainForOtherVest(uint256 _remainForOtherVest) external;

    function mintEsApeX(address to, uint256 amount) external;

    function burnEsApeX(address from, uint256 amount) external;

    function transferEsApeXTo(address to, uint256 amount) external;

    function transferEsApeXFrom(
        address from,
        address to,
        uint256 amount
    ) external;

    function mintVeApeX(address to, uint256 amount) external;

    function burnVeApeX(address from, uint256 amount) external;

    function setEsApeX(address _esApeX) external;

    function setVeApeX(address _veApeX) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Initializable {
    bool private _initialized;

    bool private _initializing;

    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IStakingPool.sol";
import "./interfaces/IStakingPoolFactory.sol";
import "../core/interfaces/IERC20.sol";
import "../utils/Reentrant.sol";
import "../utils/Initializable.sol";

contract StakingPool is IStakingPool, Reentrant, Initializable {
    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;
    uint256 internal constant MAX_TIME_STAKE_WEIGHT_MULTIPLIER = 2 * WEIGHT_MULTIPLIER;
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e12;

    address public override poolToken;
    IStakingPoolFactory public factory;
    uint256 public yieldRewardsPerWeight;
    uint256 public usersLockingWeight;
    mapping(address => User) public users;

    function initialize(address _factory, address _poolToken) external override initializer {
        factory = IStakingPoolFactory(_factory);
        poolToken = _poolToken;
    }

    function stake(uint256 _amount, uint256 _lockUntil) external override nonReentrant {
        require(_amount > 0, "sp.stake: INVALID_AMOUNT");
        uint256 now256 = block.timestamp;
        uint256 lockTime = factory.lockTime();
        require(
            _lockUntil == 0 || (_lockUntil > now256 && _lockUntil <= now256 + lockTime),
            "sp._stake: INVALID_LOCK_INTERVAL"
        );

        address _staker = msg.sender;
        User storage user = users[_staker];
        _processRewards(_staker, user);

        //if 0, not lock
        uint256 lockFrom = _lockUntil > 0 ? now256 : 0;
        uint256 stakeWeight = (((_lockUntil - lockFrom) * WEIGHT_MULTIPLIER) / lockTime + WEIGHT_MULTIPLIER) * _amount;
        uint256 depositId = user.deposits.length;
        Deposit memory deposit = Deposit({
            amount: _amount,
            weight: stakeWeight,
            lockFrom: lockFrom,
            lockUntil: _lockUntil
        });

        user.deposits.push(deposit);
        user.tokenAmount += _amount;
        user.totalWeight += stakeWeight;
        user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
        usersLockingWeight += stakeWeight;

        emit Staked(_staker, depositId, _amount, lockFrom, _lockUntil);
        IERC20(poolToken).transferFrom(msg.sender, address(this), _amount);
    }

    function batchWithdraw(uint256[] memory depositIds, uint256[] memory depositAmounts) external override {
        require(depositIds.length == depositAmounts.length, "sp.batchWithdraw: INVALID_DEPOSITS_AMOUNTS");

        User storage user = users[msg.sender];
        _processRewards(msg.sender, user);
        emit BatchWithdraw(msg.sender, depositIds, depositAmounts);
        uint256 lockTime = factory.lockTime();

        uint256 _amount;
        uint256 _id;
        uint256 stakeAmount;
        uint256 newWeight;
        uint256 deltaUsersLockingWeight;
        Deposit memory stakeDeposit;
        for (uint256 i = 0; i < depositIds.length; i++) {
            _amount = depositAmounts[i];
            _id = depositIds[i];
            require(_amount != 0, "sp.batchWithdraw: INVALID_DEPOSIT_AMOUNT");
            stakeDeposit = user.deposits[_id];
            require(
                stakeDeposit.lockFrom == 0 || block.timestamp > stakeDeposit.lockUntil,
                "sp.batchWithdraw: DEPOSIT_LOCKED"
            );
            require(stakeDeposit.amount >= _amount, "sp.batchWithdraw: EXCEED_DEPOSIT_STAKED");

            newWeight =
                (((stakeDeposit.lockUntil - stakeDeposit.lockFrom) * WEIGHT_MULTIPLIER) /
                    lockTime +
                    WEIGHT_MULTIPLIER) *
                (stakeDeposit.amount - _amount);

            stakeAmount += _amount;
            deltaUsersLockingWeight += (stakeDeposit.weight - newWeight);

            if (stakeDeposit.amount == _amount) {
                delete user.deposits[_id];
            } else {
                stakeDeposit.amount -= _amount;
                stakeDeposit.weight = newWeight;
                user.deposits[_id] = stakeDeposit;
            }
        }

        user.totalWeight -= deltaUsersLockingWeight;
        usersLockingWeight -= deltaUsersLockingWeight;
        user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;

        if (stakeAmount > 0) {
            user.tokenAmount -= stakeAmount;
            IERC20(poolToken).transfer(msg.sender, stakeAmount);
        }
    }

    function updateStakeLock(uint256 _id, uint256 _lockUntil) external override {
        uint256 now256 = block.timestamp;
        require(_lockUntil > now256, "sp.updateStakeLock: INVALID_LOCK_UNTIL");

        uint256 lockTime = factory.lockTime();
        address _staker = msg.sender;
        User storage user = users[_staker];
        _processRewards(_staker, user);

        Deposit storage stakeDeposit;

        stakeDeposit = user.deposits[_id];

        require(_lockUntil > stakeDeposit.lockUntil, "sp.updateStakeLock: INVALID_NEW_LOCK");

        if (stakeDeposit.lockFrom == 0) {
            require(_lockUntil <= now256 + lockTime, "sp.updateStakeLock: EXCEED_MAX_LOCK_PERIOD");
            stakeDeposit.lockFrom = now256;
        } else {
            require(_lockUntil <= stakeDeposit.lockFrom + lockTime, "sp.updateStakeLock: EXCEED_MAX_LOCK");
        }

        uint256 oldWeight = stakeDeposit.weight;
        uint256 newWeight = (((_lockUntil - stakeDeposit.lockFrom) * WEIGHT_MULTIPLIER) /
            lockTime +
            WEIGHT_MULTIPLIER) * stakeDeposit.amount;

        stakeDeposit.lockUntil = _lockUntil;
        stakeDeposit.weight = newWeight;
        user.totalWeight = user.totalWeight - oldWeight + newWeight;
        user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
        usersLockingWeight = usersLockingWeight - oldWeight + newWeight;

        emit UpdateStakeLock(_staker, _id, stakeDeposit.lockFrom, _lockUntil);
    }

    function processRewards() external override {
        address staker = msg.sender;
        User storage user = users[staker];

        _processRewards(staker, user);
        user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
    }

    function syncWeightPrice() public {
        if (factory.shouldUpdateRatio()) {
            factory.updateApeXPerSec();
        }

        uint256 apeXReward = factory.syncYieldPriceOfWeight();

        if (usersLockingWeight == 0) {
            return;
        }

        yieldRewardsPerWeight += (apeXReward * REWARD_PER_WEIGHT_MULTIPLIER) / usersLockingWeight;
        emit Synchronized(msg.sender, yieldRewardsPerWeight);
    }

    function _processRewards(address _staker, User storage user) internal {
        syncWeightPrice();

        //if no yield
        if (user.totalWeight == 0) return;
        uint256 yieldAmount = (user.totalWeight * yieldRewardsPerWeight) /
            REWARD_PER_WEIGHT_MULTIPLIER -
            user.subYieldRewards;
        if (yieldAmount == 0) return;

        factory.mintEsApeX(_staker, yieldAmount);
        emit MintEsApeX(_staker, yieldAmount);
    }

    function pendingYieldRewards(address _staker) external view returns (uint256 pending) {
        uint256 newYieldRewardsPerWeight = yieldRewardsPerWeight;

        if (usersLockingWeight != 0) {
            (uint256 apeXReward, ) = factory.calStakingPoolApeXReward(poolToken);
            newYieldRewardsPerWeight += (apeXReward * REWARD_PER_WEIGHT_MULTIPLIER) / usersLockingWeight;
        }

        User memory user = users[_staker];
        pending = (user.totalWeight * newYieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER - user.subYieldRewards;
    }

    function getStakeInfo(address _user)
        external
        view
        override
        returns (
            uint256 tokenAmount,
            uint256 totalWeight,
            uint256 subYieldRewards
        )
    {
        User memory user = users[_user];
        return (user.tokenAmount, user.totalWeight, user.subYieldRewards);
    }

    function getDeposit(address _user, uint256 _id) external view override returns (Deposit memory) {
        return users[_user].deposits[_id];
    }

    function getDepositsLength(address _user) external view override returns (uint256) {
        return users[_user].deposits.length;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../../core/interfaces/IERC20.sol";

interface IERC20Extend is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Reentrant {
    bool private entered;

    modifier nonReentrant() {
        require(entered == false, "Reentrant: reentrant call");
        entered = true;
        _;
        entered = false;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../utils/Initializable.sol";

contract NewPoolTemplate is Initializable {
    address public poolToken;
    address public factory;

    function initialize(address _factory, address _poolToken) external initializer {
        factory = _factory;
        poolToken = _poolToken;
    }

    function getDepositsLength(address _user) external view returns (uint256) {
        return 10000;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IRouter.sol";
import "./interfaces/IPairFactory.sol";
import "./interfaces/IAmm.sol";
import "./interfaces/IMargin.sol";
import "./interfaces/ILiquidityERC20.sol";
import "./interfaces/IConfig.sol";
import "./interfaces/IWETH.sol";
import "../libraries/TransferHelper.sol";
import "../libraries/SignedMath.sol";
import "../libraries/ChainAdapter.sol";
import "../utils/Initializable.sol";

contract Router is IRouter, Initializable {
    using SignedMath for int256;

    address public override config;
    address public override pairFactory;
    address public override pcvTreasury;
    address public override WETH;

    // user => amm => block
    mapping(address => mapping(address => uint256)) public userLastOperation;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Router: EXPIRED");
        _;
    }

    modifier notEmergency() {
        bool inEmergency = IConfig(config).inEmergency(address(this));
        require(inEmergency == false, "Router: IN_EMERGENCY");
        _;
    }

    function initialize(
        address config_,
        address pairFactory_,
        address pcvTreasury_,
        address _WETH
    ) external initializer {
        config = config_;
        pairFactory = pairFactory_;
        pcvTreasury = pcvTreasury_;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function addLiquidity(
        address baseToken,
        address quoteToken,
        uint256 baseAmount,
        uint256 quoteAmountMin,
        uint256 deadline,
        bool pcv
    ) external override ensure(deadline) notEmergency returns (uint256 quoteAmount, uint256 liquidity) {
        address amm = IPairFactory(pairFactory).getAmm(baseToken, quoteToken);
        if (amm == address(0)) {
            (amm, ) = IPairFactory(pairFactory).createPair(baseToken, quoteToken);
        }
        _recordLastOperation(msg.sender, amm);
        TransferHelper.safeTransferFrom(baseToken, msg.sender, amm, baseAmount);
        if (pcv) {
            (, quoteAmount, liquidity) = IAmm(amm).mint(address(this));
            TransferHelper.safeTransfer(amm, pcvTreasury, liquidity);
        } else {
            (, quoteAmount, liquidity) = IAmm(amm).mint(msg.sender);
        }
        require(quoteAmount >= quoteAmountMin, "Router.addLiquidity: INSUFFICIENT_QUOTE_AMOUNT");
    }

    function addLiquidityETH(
        address quoteToken,
        uint256 quoteAmountMin,
        uint256 deadline,
        bool pcv
    )
        external
        payable
        override
        ensure(deadline)
        notEmergency
        returns (
            uint256 ethAmount,
            uint256 quoteAmount,
            uint256 liquidity
        )
    {
        address amm = IPairFactory(pairFactory).getAmm(WETH, quoteToken);
        if (amm == address(0)) {
            (amm, ) = IPairFactory(pairFactory).createPair(WETH, quoteToken);
        }
        _recordLastOperation(msg.sender, amm);
        ethAmount = msg.value;
        IWETH(WETH).deposit{value: ethAmount}();
        assert(IWETH(WETH).transfer(amm, ethAmount));
        if (pcv) {
            (, quoteAmount, liquidity) = IAmm(amm).mint(address(this));
            TransferHelper.safeTransfer(amm, pcvTreasury, liquidity);
        } else {
            (, quoteAmount, liquidity) = IAmm(amm).mint(msg.sender);
        }
        require(quoteAmount >= quoteAmountMin, "Router.addLiquidityETH: INSUFFICIENT_QUOTE_AMOUNT");
    }

    function removeLiquidity(
        address baseToken,
        address quoteToken,
        uint256 liquidity,
        uint256 baseAmountMin,
        uint256 deadline
    ) external override ensure(deadline) notEmergency returns (uint256 baseAmount, uint256 quoteAmount) {
        address amm = IPairFactory(pairFactory).getAmm(baseToken, quoteToken);
        _recordLastOperation(msg.sender, amm);
        TransferHelper.safeTransferFrom(amm, msg.sender, amm, liquidity);
        (baseAmount, quoteAmount, ) = IAmm(amm).burn(msg.sender);
        require(baseAmount >= baseAmountMin, "Router.removeLiquidity: INSUFFICIENT_BASE_AMOUNT");
    }

    function removeLiquidityETH(
        address quoteToken,
        uint256 liquidity,
        uint256 ethAmountMin,
        uint256 deadline
    ) external override ensure(deadline) notEmergency returns (uint256 ethAmount, uint256 quoteAmount) {
        address amm = IPairFactory(pairFactory).getAmm(WETH, quoteToken);
        _recordLastOperation(msg.sender, amm);
        TransferHelper.safeTransferFrom(amm, msg.sender, amm, liquidity);
        (ethAmount, quoteAmount, ) = IAmm(amm).burn(address(this));
        require(ethAmount >= ethAmountMin, "Router.removeLiquidityETH: INSUFFICIENT_ETH_AMOUNT");
        IWETH(WETH).withdraw(ethAmount);
        TransferHelper.safeTransferETH(msg.sender, ethAmount);
    }

    function deposit(
        address baseToken,
        address quoteToken,
        address holder,
        uint256 amount
    ) external override notEmergency {
        address margin = IPairFactory(pairFactory).getMargin(baseToken, quoteToken);
        require(margin != address(0), "Router.deposit: NOT_FOUND_MARGIN");
        TransferHelper.safeTransferFrom(baseToken, msg.sender, margin, amount);
        IMargin(margin).addMargin(holder, amount);
    }

    function depositETH(address quoteToken, address holder) external payable override notEmergency {
        address margin = IPairFactory(pairFactory).getMargin(WETH, quoteToken);
        require(margin != address(0), "Router.depositETH: NOT_FOUND_MARGIN");
        uint256 amount = msg.value;
        IWETH(WETH).deposit{value: amount}();
        assert(IWETH(WETH).transfer(margin, amount));
        IMargin(margin).addMargin(holder, amount);
    }

    function withdraw(
        address baseToken,
        address quoteToken,
        uint256 amount
    ) external override {
        address margin = IPairFactory(pairFactory).getMargin(baseToken, quoteToken);
        require(margin != address(0), "Router.withdraw: NOT_FOUND_MARGIN");
        IMargin(margin).removeMargin(msg.sender, msg.sender, amount);
    }

    function withdrawETH(address quoteToken, uint256 amount) external override {
        address margin = IPairFactory(pairFactory).getMargin(WETH, quoteToken);
        require(margin != address(0), "Router.withdraw: NOT_FOUND_MARGIN");
        IMargin(margin).removeMargin(msg.sender, address(this), amount);
        IWETH(WETH).withdraw(amount);
        TransferHelper.safeTransferETH(msg.sender, amount);
    }

    function openPositionWithWallet(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 marginAmount,
        uint256 quoteAmount,
        uint256 baseAmountLimit,
        uint256 deadline
    ) external override ensure(deadline) notEmergency returns (uint256 baseAmount) {
        address amm = IPairFactory(pairFactory).getAmm(baseToken, quoteToken);
        _recordLastOperation(msg.sender, amm);
        address margin = IPairFactory(pairFactory).getMargin(baseToken, quoteToken);
        require(margin != address(0), "Router.openPositionWithWallet: NOT_FOUND_MARGIN");
        require(side == 0 || side == 1, "Router.openPositionWithWallet: INSUFFICIENT_SIDE");
        TransferHelper.safeTransferFrom(baseToken, msg.sender, margin, marginAmount);
        IMargin(margin).addMargin(msg.sender, marginAmount);
        baseAmount = IMargin(margin).openPosition(msg.sender, side, quoteAmount);
        if (side == 0) {
            require(baseAmount >= baseAmountLimit, "Router.openPositionWithWallet: INSUFFICIENT_QUOTE_AMOUNT");
        } else {
            require(baseAmount <= baseAmountLimit, "Router.openPositionWithWallet: INSUFFICIENT_QUOTE_AMOUNT");
        }
    }

    function openPositionETHWithWallet(
        address quoteToken,
        uint8 side,
        uint256 quoteAmount,
        uint256 baseAmountLimit,
        uint256 deadline
    ) external payable override ensure(deadline) notEmergency returns (uint256 baseAmount) {
        address amm = IPairFactory(pairFactory).getAmm(WETH, quoteToken);
        _recordLastOperation(msg.sender, amm);
        address margin = IPairFactory(pairFactory).getMargin(WETH, quoteToken);
        require(margin != address(0), "Router.openPositionETHWithWallet: NOT_FOUND_MARGIN");
        require(side == 0 || side == 1, "Router.openPositionETHWithWallet: INSUFFICIENT_SIDE");
        uint256 marginAmount = msg.value;
        IWETH(WETH).deposit{value: marginAmount}();
        assert(IWETH(WETH).transfer(margin, marginAmount));
        IMargin(margin).addMargin(msg.sender, marginAmount);
        baseAmount = IMargin(margin).openPosition(msg.sender, side, quoteAmount);
        if (side == 0) {
            require(baseAmount >= baseAmountLimit, "Router.openPositionETHWithWallet: INSUFFICIENT_QUOTE_AMOUNT");
        } else {
            require(baseAmount <= baseAmountLimit, "Router.openPositionETHWithWallet: INSUFFICIENT_QUOTE_AMOUNT");
        }
    }

    function openPositionWithMargin(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 quoteAmount,
        uint256 baseAmountLimit,
        uint256 deadline
    ) external override ensure(deadline) notEmergency returns (uint256 baseAmount) {
        address amm = IPairFactory(pairFactory).getAmm(baseToken, quoteToken);
        _recordLastOperation(msg.sender, amm);
        address margin = IPairFactory(pairFactory).getMargin(baseToken, quoteToken);
        require(margin != address(0), "Router.openPositionWithMargin: NOT_FOUND_MARGIN");
        require(side == 0 || side == 1, "Router.openPositionWithMargin: INSUFFICIENT_SIDE");
        baseAmount = IMargin(margin).openPosition(msg.sender, side, quoteAmount);
        if (side == 0) {
            require(baseAmount >= baseAmountLimit, "Router.openPositionWithMargin: INSUFFICIENT_QUOTE_AMOUNT");
        } else {
            require(baseAmount <= baseAmountLimit, "Router.openPositionWithMargin: INSUFFICIENT_QUOTE_AMOUNT");
        }
    }

    function closePosition(
        address baseToken,
        address quoteToken,
        uint256 quoteAmount,
        uint256 deadline,
        bool autoWithdraw
    ) external override ensure(deadline) returns (uint256 baseAmount, uint256 withdrawAmount) {
        address amm = IPairFactory(pairFactory).getAmm(baseToken, quoteToken);
        _recordLastOperation(msg.sender, amm);
        address margin = IPairFactory(pairFactory).getMargin(baseToken, quoteToken);
        require(margin != address(0), "Router.closePosition: NOT_FOUND_MARGIN");
        if (!autoWithdraw) {
            baseAmount = IMargin(margin).closePosition(msg.sender, quoteAmount);
        } else {
            (, int256 quoteSizeBefore, ) = IMargin(margin).getPosition(msg.sender);
            baseAmount = IMargin(margin).closePosition(msg.sender, quoteAmount);
            (int256 baseSize, int256 quoteSizeAfter, uint256 tradeSize) = IMargin(margin).getPosition(msg.sender);
            int256 unrealizedPnl = IMargin(margin).calUnrealizedPnl(msg.sender);
            int256 traderMargin;
            if (quoteSizeAfter < 0) { // long, traderMargin = baseSize - tradeSize + unrealizedPnl
                traderMargin = baseSize.subU(tradeSize) + unrealizedPnl;
            } else { // short, traderMargin = baseSize + tradeSize + unrealizedPnl
                traderMargin = baseSize.addU(tradeSize) + unrealizedPnl;
            }
            withdrawAmount = traderMargin.abs() - traderMargin.abs() * quoteSizeAfter.abs() / quoteSizeBefore.abs();
            uint256 withdrawable = IMargin(margin).getWithdrawable(msg.sender);
            if (withdrawable < withdrawAmount) {
                withdrawAmount = withdrawable;
            }
            if (withdrawAmount > 0) {
                IMargin(margin).removeMargin(msg.sender, msg.sender, withdrawAmount);
            }
        }
    }

    function closePositionETH(
        address quoteToken,
        uint256 quoteAmount,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256 baseAmount, uint256 withdrawAmount) {
        address amm = IPairFactory(pairFactory).getAmm(WETH, quoteToken);
        _recordLastOperation(msg.sender, amm);
        address margin = IPairFactory(pairFactory).getMargin(WETH, quoteToken);
        require(margin != address(0), "Router.closePosition: NOT_FOUND_MARGIN");
        
        (, int256 quoteSizeBefore, ) = IMargin(margin).getPosition(msg.sender);
        baseAmount = IMargin(margin).closePosition(msg.sender, quoteAmount);
        (int256 baseSize, int256 quoteSizeAfter, uint256 tradeSize) = IMargin(margin).getPosition(msg.sender);
        int256 unrealizedPnl = IMargin(margin).calUnrealizedPnl(msg.sender);
        int256 traderMargin;
        if (quoteSizeAfter < 0) { // long, traderMargin = baseSize - tradeSize + unrealizedPnl
            traderMargin = baseSize.subU(tradeSize) + unrealizedPnl;
        } else { // short, traderMargin = baseSize + tradeSize + unrealizedPnl
            traderMargin = baseSize.addU(tradeSize) + unrealizedPnl;
        }
        withdrawAmount = traderMargin.abs() - traderMargin.abs() * quoteSizeAfter.abs() / quoteSizeBefore.abs();
        uint256 withdrawable = IMargin(margin).getWithdrawable(msg.sender);
        if (withdrawable < withdrawAmount) {
            withdrawAmount = withdrawable;
        }
        if (withdrawAmount > 0) {
            IMargin(margin).removeMargin(msg.sender, address(this), withdrawAmount);
            IWETH(WETH).withdraw(withdrawAmount);
            TransferHelper.safeTransferETH(msg.sender, withdrawAmount);
        }
    }

    function liquidate(
        address baseToken,
        address quoteToken,
        address trader,
        address to
    ) external override returns (uint256 quoteAmount, uint256 baseAmount, uint256 bonus) {
        address amm = IPairFactory(pairFactory).getAmm(baseToken, quoteToken);
        uint256 blockNumber = ChainAdapter.blockNumber();
        require(userLastOperation[msg.sender][amm] != blockNumber, "Router.liquidate: FORBIDDEN");

        address margin = IPairFactory(pairFactory).getMargin(baseToken, quoteToken);
        require(margin != address(0), "Router.closePosition: NOT_FOUND_MARGIN");
        (quoteAmount, baseAmount, bonus) = IMargin(margin).liquidate(trader, to);
    }

    function getReserves(address baseToken, address quoteToken)
        external
        view
        override
        returns (uint256 reserveBase, uint256 reserveQuote)
    {
        address amm = IPairFactory(pairFactory).getAmm(baseToken, quoteToken);
        (reserveBase, reserveQuote, ) = IAmm(amm).getReserves();
    }

    function getQuoteAmount(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 baseAmount
    ) external view override returns (uint256 quoteAmount) {
        address amm = IPairFactory(pairFactory).getAmm(baseToken, quoteToken);
        (uint256 reserveBase, uint256 reserveQuote, ) = IAmm(amm).getReserves();
        if (side == 0) {
            quoteAmount = _getAmountIn(baseAmount, reserveQuote, reserveBase);
        } else {
            quoteAmount = _getAmountOut(baseAmount, reserveBase, reserveQuote);
        }
    }

    function getWithdrawable(
        address baseToken,
        address quoteToken,
        address holder
    ) external view override returns (uint256 amount) {
        address margin = IPairFactory(pairFactory).getMargin(baseToken, quoteToken);
        amount = IMargin(margin).getWithdrawable(holder);
    }

    function getPosition(
        address baseToken,
        address quoteToken,
        address holder
    )
        external
        view
        override
        returns (
            int256 baseSize,
            int256 quoteSize,
            uint256 tradeSize
        )
    {
        address margin = IPairFactory(pairFactory).getMargin(baseToken, quoteToken);
        (baseSize, quoteSize, tradeSize) = IMargin(margin).getPosition(holder);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "Router.getAmountOut: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "Router.getAmountOut: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 999;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "Router.getAmountIn: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "Router.getAmountIn: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 999;
        amountIn = numerator / denominator + 1;
    }

    function _recordLastOperation(address user, address amm) internal {
        require(tx.origin == msg.sender, "Router._recordLastOperation: ONLY_EOA");
        uint256 blockNumber = ChainAdapter.blockNumber();
        require(userLastOperation[user][amm] != blockNumber, "Router._recordLastOperation: FORBIDDEN");
        userLastOperation[user][amm] = blockNumber;
    }
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

import "./IERC20.sol";

interface ILiquidityERC20 is IERC20 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IArbSys {
    function arbBlockNumber() external view returns (uint256);
}

library ChainAdapter {
    address constant arbSys = address(100);

    function blockNumber() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        if (chainId == 421611 || chainId == 42161) { // Arbitrum Testnet || Arbitrum Mainnet
            return IArbSys(arbSys).arbBlockNumber();
        } else {
            return block.number;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
import "../libraries/ChainAdapter.sol";

/// @title Multicall - Aggregate results from multiple read-only function calls
contract Multicall2 {
    struct Call {
        address target;
        bytes callData;
    }
    struct Result {
        bool success;
        bytes returnData;
    }

    function aggregate(Call[] memory calls) public returns (uint256 blockNumber, bytes[] memory returnData) {
        blockNumber = ChainAdapter.blockNumber();
        returnData = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);
            require(success, "Multicall aggregate: call failed");
            returnData[i] = ret;
        }
    }

    function blockAndAggregate(Call[] memory calls)
        public
        returns (
            uint256 blockNumber,
            bytes32 blockHash,
            Result[] memory returnData
        )
    {
        (blockNumber, blockHash, returnData) = tryBlockAndAggregate(true, calls);
    }

    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {
        blockHash = blockhash(blockNumber);
    }

    function getBlockNumber() public view returns (uint256 blockNumber) {
        blockNumber = ChainAdapter.blockNumber();
    }

    function getCurrentBlockCoinbase() public view returns (address coinbase) {
        coinbase = block.coinbase;
    }

    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {
        difficulty = block.difficulty;
    }

    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {
        gaslimit = block.gaslimit;
    }

    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {
        timestamp = block.timestamp;
    }

    function getEthBalance(address addr) public view returns (uint256 balance) {
        balance = addr.balance;
    }

    function getLastBlockHash() public view returns (bytes32 blockHash) {
        blockHash = blockhash(ChainAdapter.blockNumber() - 1);
    }

    function tryAggregate(bool requireSuccess, Call[] memory calls) public returns (Result[] memory returnData) {
        returnData = new Result[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);

            if (requireSuccess) {
                require(success, "Multicall2 aggregate: call failed");
            }

            returnData[i] = Result(success, ret);
        }
    }

    function tryBlockAndAggregate(bool requireSuccess, Call[] memory calls)
        public
        returns (
            uint256 blockNumber,
            bytes32 blockHash,
            Result[] memory returnData
        )
    {
        blockNumber =  ChainAdapter.blockNumber();
        blockHash = blockhash(blockNumber);
        returnData = tryAggregate(requireSuccess, calls);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IMarginFactory.sol";
import "./interfaces/IAmmFactory.sol";
import "./interfaces/IAmm.sol";
import "./interfaces/IConfig.sol";
import "./interfaces/IMargin.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IWETH.sol";
import "../utils/Reentrant.sol";
import "../libraries/SignedMath.sol";
import "../libraries/ChainAdapter.sol";

contract Margin is IMargin, IVault, Reentrant {
    using SignedMath for int256;

    address public immutable override factory;
    address public override config;
    address public override amm;
    address public override baseToken;
    address public override quoteToken;
    mapping(address => Position) public traderPositionMap;
    mapping(address => int256) public traderCPF; //trader's latestCPF checkpoint, to calculate funding fee
    uint256 public override reserve;
    uint256 public lastUpdateCPF; //last timestamp update cpf
    uint256 public totalQuoteLong;
    uint256 public totalQuoteShort;
    int256 internal latestCPF; //latestCPF with 1e18 multiplied

    constructor() {
        factory = msg.sender;
    }

    function initialize(
        address baseToken_,
        address quoteToken_,
        address amm_
    ) external override {
        require(factory == msg.sender, "Margin.initialize: FORBIDDEN");
        baseToken = baseToken_;
        quoteToken = quoteToken_;
        amm = amm_;
        config = IMarginFactory(factory).config();
    }

    //@notice before add margin, ensure contract's baseToken balance larger than depositAmount
    function addMargin(address trader, uint256 depositAmount) external override nonReentrant {
        uint256 balance = IERC20(baseToken).balanceOf(address(this));
        uint256 _reserve = reserve;
        require(depositAmount <= balance - _reserve, "Margin.addMargin: WRONG_DEPOSIT_AMOUNT");
        Position memory traderPosition = traderPositionMap[trader];

        traderPosition.baseSize = traderPosition.baseSize.addU(depositAmount);
        traderPositionMap[trader] = traderPosition;
        reserve = _reserve + depositAmount;

        emit AddMargin(trader, depositAmount, traderPosition);
    }

    //remove baseToken from trader's fundingFee+unrealizedPnl+margin, remain position need to meet the requirement of initMarginRatio
    function removeMargin(
        address trader,
        address to,
        uint256 withdrawAmount
    ) external override nonReentrant {
        require(withdrawAmount > 0, "Margin.removeMargin: ZERO_WITHDRAW_AMOUNT");
        require(IConfig(config).routerMap(msg.sender), "Margin.removeMargin: FORBIDDEN");
        int256 _latestCPF = updateCPF();
        Position memory traderPosition = traderPositionMap[trader];

        //after last time operating trader's position, new fundingFee to earn.
        int256 fundingFee = _calFundingFee(trader, _latestCPF);
        //if close all position, trader can withdraw how much and earn how much pnl
        (uint256 withdrawableAmount, int256 unrealizedPnl) = _getWithdrawable(
            traderPosition.quoteSize,
            traderPosition.baseSize + fundingFee,
            traderPosition.tradeSize
        );
        require(withdrawAmount <= withdrawableAmount, "Margin.removeMargin: NOT_ENOUGH_WITHDRAWABLE");

        uint256 withdrawAmountFromMargin;
        //withdraw from fundingFee firstly, then unrealizedPnl, finally margin
        int256 uncoverAfterFundingFee = int256(1).mulU(withdrawAmount) - fundingFee;
        if (uncoverAfterFundingFee > 0) {
            //fundingFee cant cover withdrawAmount, use unrealizedPnl and margin.
            //update tradeSize only, no quoteSize, so can sub uncoverAfterFundingFee directly
            if (uncoverAfterFundingFee <= unrealizedPnl) {
                traderPosition.tradeSize -= uncoverAfterFundingFee.abs();
            } else {
                //fundingFee and unrealizedPnl cant cover withdrawAmount, use margin
                withdrawAmountFromMargin = (uncoverAfterFundingFee - unrealizedPnl).abs();
                //update tradeSize to current price to make unrealizedPnl zero
                traderPosition.tradeSize = traderPosition.quoteSize < 0
                    ? (int256(1).mulU(traderPosition.tradeSize) - unrealizedPnl).abs()
                    : (int256(1).mulU(traderPosition.tradeSize) + unrealizedPnl).abs();
            }
        }

        traderPosition.baseSize = traderPosition.baseSize - uncoverAfterFundingFee;

        traderPositionMap[trader] = traderPosition;
        traderCPF[trader] = _latestCPF;
        _withdraw(trader, to, withdrawAmount);

        emit RemoveMargin(trader, to, withdrawAmount, fundingFee, withdrawAmountFromMargin, traderPosition);
    }

    function openPosition(
        address trader,
        uint8 side,
        uint256 quoteAmount
    ) external override nonReentrant returns (uint256 baseAmount) {
        require(side == 0 || side == 1, "Margin.openPosition: INVALID_SIDE");
        require(quoteAmount > 0, "Margin.openPosition: ZERO_QUOTE_AMOUNT");
        require(IConfig(config).routerMap(msg.sender), "Margin.openPosition: FORBIDDEN");
        int256 _latestCPF = updateCPF();

        Position memory traderPosition = traderPositionMap[trader];

        uint256 quoteSizeAbs = traderPosition.quoteSize.abs();
        int256 fundingFee = _calFundingFee(trader, _latestCPF);

        uint256 quoteAmountMax;
        {
            int256 marginAcc;
            if (traderPosition.quoteSize == 0) {
                marginAcc = traderPosition.baseSize + fundingFee;
            } else if (traderPosition.quoteSize > 0) {
                //simulate to close short
                uint256[2] memory result = IAmm(amm).estimateSwap(
                    address(quoteToken),
                    address(baseToken),
                    traderPosition.quoteSize.abs(),
                    0
                );
                marginAcc = traderPosition.baseSize.addU(result[1]) + fundingFee;
            } else {
                //simulate to close long
                uint256[2] memory result = IAmm(amm).estimateSwap(
                    address(baseToken),
                    address(quoteToken),
                    0,
                    traderPosition.quoteSize.abs()
                );
                marginAcc = traderPosition.baseSize.subU(result[0]) + fundingFee;
            }
            require(marginAcc > 0, "Margin.openPosition: INVALID_MARGIN_ACC");
            (, uint112 quoteReserve, ) = IAmm(amm).getReserves();
            (, uint256 _quoteAmountT, bool isIndexPrice) = IPriceOracle(IConfig(config).priceOracle())
                .getMarkPriceInRatio(amm, 0, marginAcc.abs());

            uint256 _quoteAmount = isIndexPrice
                ? _quoteAmountT
                : IAmm(amm).estimateSwap(baseToken, quoteToken, marginAcc.abs(), 0)[1];

            quoteAmountMax =
                (quoteReserve * 10000 * _quoteAmount) /
                ((IConfig(config).initMarginRatio() * quoteReserve) + (200 * _quoteAmount * IConfig(config).beta()));
        }

        bool isLong = side == 0;
        baseAmount = _addPositionWithAmm(trader, isLong, quoteAmount);
        require(baseAmount > 0, "Margin.openPosition: TINY_QUOTE_AMOUNT");

        if (
            traderPosition.quoteSize == 0 ||
            (traderPosition.quoteSize < 0 == isLong) ||
            (traderPosition.quoteSize > 0 == !isLong)
        ) {
            //baseAmount is real base cost
            traderPosition.tradeSize = traderPosition.tradeSize + baseAmount;
        } else {
            if (quoteAmount < quoteSizeAbs) {
                //entry price not change
                traderPosition.tradeSize =
                    traderPosition.tradeSize -
                    (quoteAmount * traderPosition.tradeSize) /
                    quoteSizeAbs;
            } else {
                //after close all opposite position, create new position with new entry price
                traderPosition.tradeSize = ((quoteAmount - quoteSizeAbs) * baseAmount) / quoteAmount;
            }
        }

        if (isLong) {
            traderPosition.quoteSize = traderPosition.quoteSize.subU(quoteAmount);
            traderPosition.baseSize = traderPosition.baseSize.addU(baseAmount) + fundingFee;
            totalQuoteLong = totalQuoteLong + quoteAmount;
        } else {
            traderPosition.quoteSize = traderPosition.quoteSize.addU(quoteAmount);
            traderPosition.baseSize = traderPosition.baseSize.subU(baseAmount) + fundingFee;
            totalQuoteShort = totalQuoteShort + quoteAmount;
        }
        require(traderPosition.quoteSize.abs() <= quoteAmountMax, "Margin.openPosition: INIT_MARGIN_RATIO");
        require(
            _calDebtRatio(traderPosition.quoteSize, traderPosition.baseSize) < IConfig(config).liquidateThreshold(),
            "Margin.openPosition: WILL_BE_LIQUIDATED"
        );

        traderCPF[trader] = _latestCPF;
        traderPositionMap[trader] = traderPosition;
        emit OpenPosition(trader, side, baseAmount, quoteAmount, fundingFee, traderPosition);
    }

    function closePosition(address trader, uint256 quoteAmount)
        external
        override
        nonReentrant
        returns (uint256 baseAmount)
    {
        require(IConfig(config).routerMap(msg.sender), "Margin.openPosition: FORBIDDEN");
        int256 _latestCPF = updateCPF();

        Position memory traderPosition = traderPositionMap[trader];
        require(quoteAmount != 0, "Margin.closePosition: ZERO_POSITION");
        uint256 quoteSizeAbs = traderPosition.quoteSize.abs();
        require(quoteAmount <= quoteSizeAbs, "Margin.closePosition: ABOVE_POSITION");

        bool isLong = traderPosition.quoteSize < 0;
        int256 fundingFee = _calFundingFee(trader, _latestCPF);
        require(
            _calDebtRatio(traderPosition.quoteSize, traderPosition.baseSize + fundingFee) <
                IConfig(config).liquidateThreshold(),
            "Margin.closePosition: DEBT_RATIO_OVER"
        );

        baseAmount = _minusPositionWithAmm(trader, isLong, quoteAmount);
        traderPosition.tradeSize -= (quoteAmount * traderPosition.tradeSize) / quoteSizeAbs;

        if (isLong) {
            totalQuoteLong = totalQuoteLong - quoteAmount;
            traderPosition.quoteSize = traderPosition.quoteSize.addU(quoteAmount);
            traderPosition.baseSize = traderPosition.baseSize.subU(baseAmount) + fundingFee;
        } else {
            totalQuoteShort = totalQuoteShort - quoteAmount;
            traderPosition.quoteSize = traderPosition.quoteSize.subU(quoteAmount);
            traderPosition.baseSize = traderPosition.baseSize.addU(baseAmount) + fundingFee;
        }
        if (traderPosition.quoteSize == 0 && traderPosition.baseSize < 0) {
            IAmm(amm).forceSwap(trader, quoteToken, baseToken, 0, traderPosition.baseSize.abs());
            traderPosition.baseSize = 0;
        }

        traderCPF[trader] = _latestCPF;
        traderPositionMap[trader] = traderPosition;

        emit ClosePosition(trader, quoteAmount, baseAmount, fundingFee, traderPosition);
    }

    function liquidate(address trader, address to)
        external
        override
        nonReentrant
        returns (
            uint256 quoteAmount,
            uint256 baseAmount,
            uint256 bonus
        )
    {
        require(IConfig(config).routerMap(msg.sender), "Margin.openPosition: FORBIDDEN");
        int256 _latestCPF = updateCPF();
        Position memory traderPosition = traderPositionMap[trader];
        int256 baseSize = traderPosition.baseSize;
        int256 quoteSize = traderPosition.quoteSize;
        require(quoteSize != 0, "Margin.liquidate: ZERO_POSITION");

        quoteAmount = quoteSize.abs();
        bool isLong = quoteSize < 0;
        int256 fundingFee = _calFundingFee(trader, _latestCPF);
        require(
            _calDebtRatio(quoteSize, baseSize + fundingFee) >= IConfig(config).liquidateThreshold(),
            "Margin.liquidate: NOT_LIQUIDATABLE"
        );

        {
            (uint256 _baseAmountT, , bool isIndexPrice) = IPriceOracle(IConfig(config).priceOracle())
                .getMarkPriceInRatio(amm, quoteAmount, 0);

            baseAmount = isIndexPrice ? _baseAmountT : _querySwapBaseWithAmm(isLong, quoteAmount);
            (uint256 _baseAmount, uint256 _quoteAmount) = (baseAmount, quoteAmount);
            bonus = _executeSettle(trader, isIndexPrice, isLong, fundingFee, baseSize, _baseAmount, _quoteAmount);
            if (isLong) {
                totalQuoteLong = totalQuoteLong - quoteSize.abs();
            } else {
                totalQuoteShort = totalQuoteShort - quoteSize.abs();
            }
        }

        traderCPF[trader] = _latestCPF;
        if (bonus > 0) {
            _withdraw(trader, to, bonus);
        }

        delete traderPositionMap[trader];

        emit Liquidate(msg.sender, trader, to, quoteAmount, baseAmount, bonus, fundingFee, traderPosition);
    }

    function _executeSettle(
        address _trader,
        bool isIndexPrice,
        bool isLong,
        int256 fundingFee,
        int256 baseSize,
        uint256 baseAmount,
        uint256 quoteAmount
    ) internal returns (uint256 bonus) {
        int256 remainBaseAmountAfterLiquidate = isLong
            ? baseSize.subU(baseAmount) + fundingFee
            : baseSize.addU(baseAmount) + fundingFee;

        if (remainBaseAmountAfterLiquidate >= 0) {
            bonus = (remainBaseAmountAfterLiquidate.abs() * IConfig(config).liquidateFeeRatio()) / 10000;
            if (!isIndexPrice) {
                if (isLong) {
                    IAmm(amm).forceSwap(_trader, baseToken, quoteToken, baseAmount, quoteAmount);
                } else {
                    IAmm(amm).forceSwap(_trader, quoteToken, baseToken, quoteAmount, baseAmount);
                }
            }

            if (remainBaseAmountAfterLiquidate.abs() > bonus) {
                address treasury = IAmmFactory(IAmm(amm).factory()).feeTo();
                if (treasury != address(0)) {
                    IERC20(baseToken).transfer(treasury, remainBaseAmountAfterLiquidate.abs() - bonus);
                } else {
                    IAmm(amm).forceSwap(
                        _trader,
                        baseToken,
                        quoteToken,
                        remainBaseAmountAfterLiquidate.abs() - bonus,
                        0
                    );
                }
            }
        } else {
            if (!isIndexPrice) {
                if (isLong) {
                    IAmm(amm).forceSwap(
                        _trader,
                        baseToken,
                        quoteToken,
                        ((baseSize.subU(bonus) + fundingFee).abs()),
                        quoteAmount
                    );
                } else {
                    IAmm(amm).forceSwap(
                        _trader,
                        quoteToken,
                        baseToken,
                        quoteAmount,
                        ((baseSize.subU(bonus) + fundingFee).abs())
                    );
                }
            } else {
                IAmm(amm).forceSwap(_trader, quoteToken, baseToken, 0, remainBaseAmountAfterLiquidate.abs());
            }
        }
    }

    function deposit(address user, uint256 amount) external override nonReentrant {
        require(msg.sender == amm, "Margin.deposit: REQUIRE_AMM");
        require(amount > 0, "Margin.deposit: AMOUNT_IS_ZERO");
        uint256 balance = IERC20(baseToken).balanceOf(address(this));
        require(amount <= balance - reserve, "Margin.deposit: INSUFFICIENT_AMOUNT");

        reserve = reserve + amount;

        emit Deposit(user, amount);
    }

    function withdraw(
        address user,
        address receiver,
        uint256 amount
    ) external override nonReentrant {
        require(msg.sender == amm, "Margin.withdraw: REQUIRE_AMM");

        _withdraw(user, receiver, amount);
    }

    function _withdraw(
        address user,
        address receiver,
        uint256 amount
    ) internal {
        require(amount > 0, "Margin._withdraw: AMOUNT_IS_ZERO");
        require(amount <= reserve, "Margin._withdraw: NOT_ENOUGH_RESERVE");
        reserve = reserve - amount;
        IERC20(baseToken).transfer(receiver, amount);

        emit Withdraw(user, receiver, amount);
    }

    //swap exact quote to base
    function _addPositionWithAmm(
        address trader,
        bool isLong,
        uint256 quoteAmount
    ) internal returns (uint256 baseAmount) {
        (address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount) = _getSwapParam(
            !isLong,
            quoteAmount
        );

        uint256[2] memory result = IAmm(amm).swap(trader, inputToken, outputToken, inputAmount, outputAmount);
        return isLong ? result[1] : result[0];
    }

    //close position, swap base to get exact quoteAmount, the base has contained pnl
    function _minusPositionWithAmm(
        address trader,
        bool isLong,
        uint256 quoteAmount
    ) internal returns (uint256 baseAmount) {
        (address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount) = _getSwapParam(
            isLong,
            quoteAmount
        );

        uint256[2] memory result = IAmm(amm).swap(trader, inputToken, outputToken, inputAmount, outputAmount);
        return isLong ? result[0] : result[1];
    }

    //update global funding fee
    function updateCPF() public override returns (int256 newLatestCPF) {
        uint256 currentTimeStamp = block.timestamp;
        newLatestCPF = _getNewLatestCPF();

        latestCPF = newLatestCPF;
        lastUpdateCPF = currentTimeStamp;

        emit UpdateCPF(currentTimeStamp, newLatestCPF);
    }

    function querySwapBaseWithAmm(bool isLong, uint256 quoteAmount) external view override returns (uint256) {
        return _querySwapBaseWithAmm(isLong, quoteAmount);
    }

    function getPosition(address trader)
        external
        view
        override
        returns (
            int256,
            int256,
            uint256
        )
    {
        Position memory position = traderPositionMap[trader];
        return (position.baseSize, position.quoteSize, position.tradeSize);
    }

    function getWithdrawable(address trader) external view override returns (uint256 withdrawable) {
        Position memory position = traderPositionMap[trader];
        int256 fundingFee = _calFundingFee(trader, _getNewLatestCPF());

        (withdrawable, ) = _getWithdrawable(position.quoteSize, position.baseSize + fundingFee, position.tradeSize);
    }

    function getNewLatestCPF() external view override returns (int256) {
        return _getNewLatestCPF();
    }

    function canLiquidate(address trader) external view override returns (bool) {
        Position memory position = traderPositionMap[trader];
        int256 fundingFee = _calFundingFee(trader, _getNewLatestCPF());

        return
            _calDebtRatio(position.quoteSize, position.baseSize + fundingFee) >= IConfig(config).liquidateThreshold();
    }

    function calFundingFee(address trader) public view override returns (int256) {
        return _calFundingFee(trader, _getNewLatestCPF());
    }

    function calDebtRatio(address trader) external view override returns (uint256 debtRatio) {
        Position memory position = traderPositionMap[trader];
        int256 fundingFee = _calFundingFee(trader, _getNewLatestCPF());

        return _calDebtRatio(position.quoteSize, position.baseSize + fundingFee);
    }

    function calUnrealizedPnl(address trader) external view override returns (int256 unrealizedPnl) {
        Position memory position = traderPositionMap[trader];
        if (position.quoteSize.abs() == 0) return 0;
        (uint256 _baseAmountT, , bool isIndexPrice) = IPriceOracle(IConfig(config).priceOracle()).getMarkPriceInRatio(
            amm,
            position.quoteSize.abs(),
            0
        );
        uint256 repayBaseAmount = isIndexPrice
            ? _baseAmountT
            : _querySwapBaseWithAmm(position.quoteSize < 0, position.quoteSize.abs());
        if (position.quoteSize < 0) {
            //borrowed - repay, earn when borrow more and repay less
            unrealizedPnl = int256(1).mulU(position.tradeSize).subU(repayBaseAmount);
        } else if (position.quoteSize > 0) {
            //repay - lent, earn when lent less and repay more
            unrealizedPnl = int256(1).mulU(repayBaseAmount).subU(position.tradeSize);
        }
    }

    function netPosition() external view override returns (int256) {
        require(totalQuoteShort < type(uint128).max, "Margin.netPosition: OVERFLOW");
        return int256(totalQuoteShort).subU(totalQuoteLong);
    }

    function totalPosition() external view override returns (uint256 totalQuotePosition) {
        totalQuotePosition = totalQuoteLong + totalQuoteShort;
    }

    //query swap exact quote to base
    function _querySwapBaseWithAmm(bool isLong, uint256 quoteAmount) internal view returns (uint256) {
        (address inputToken, address outputToken, uint256 inputAmount, uint256 outputAmount) = _getSwapParam(
            isLong,
            quoteAmount
        );

        uint256[2] memory result = IAmm(amm).estimateSwap(inputToken, outputToken, inputAmount, outputAmount);
        return isLong ? result[0] : result[1];
    }

    //@notice returns newLatestCPF with 1e18 multiplied
    function _getNewLatestCPF() internal view returns (int256 newLatestCPF) {
        int256 premiumFraction = IPriceOracle(IConfig(config).priceOracle()).getPremiumFraction(amm);
        uint256 maxCPFBoost = IConfig(config).maxCPFBoost();
        int256 delta;
        if (
            totalQuoteLong <= maxCPFBoost * totalQuoteShort &&
            totalQuoteShort <= maxCPFBoost * totalQuoteLong &&
            !(totalQuoteShort == 0 && totalQuoteLong == 0)
        ) {
            delta = premiumFraction >= 0
                ? premiumFraction.mulU(totalQuoteLong).divU(totalQuoteShort)
                : premiumFraction.mulU(totalQuoteShort).divU(totalQuoteLong);
        } else if (totalQuoteLong > maxCPFBoost * totalQuoteShort) {
            delta = premiumFraction >= 0 ? premiumFraction.mulU(maxCPFBoost) : premiumFraction.divU(maxCPFBoost);
        } else if (totalQuoteShort > maxCPFBoost * totalQuoteLong) {
            delta = premiumFraction >= 0 ? premiumFraction.divU(maxCPFBoost) : premiumFraction.mulU(maxCPFBoost);
        } else {
            delta = premiumFraction;
        }

        newLatestCPF = delta.mulU(block.timestamp - lastUpdateCPF) + latestCPF;
    }

    //@notice withdrawable from fundingFee, unrealizedPnl and margin
    function _getWithdrawable(
        int256 quoteSize,
        int256 baseSize,
        uint256 tradeSize
    ) internal view returns (uint256 amount, int256 unrealizedPnl) {
        if (quoteSize == 0) {
            amount = baseSize <= 0 ? 0 : baseSize.abs();
        } else if (quoteSize < 0) {
            uint256[2] memory result = IAmm(amm).estimateSwap(
                address(baseToken),
                address(quoteToken),
                0,
                quoteSize.abs()
            );

            uint256 a = result[0] * 10000;
            uint256 b = (10000 - IConfig(config).initMarginRatio());
            //calculate how many base needed to maintain current position
            uint256 baseNeeded = a / b;
            if (a % b != 0) {
                baseNeeded += 1;
            }
            //borrowed - repay, earn when borrow more and repay less
            unrealizedPnl = int256(1).mulU(tradeSize).subU(result[0]);
            amount = baseSize.abs() <= baseNeeded ? 0 : baseSize.abs() - baseNeeded;
        } else {
            uint256[2] memory result = IAmm(amm).estimateSwap(
                address(quoteToken),
                address(baseToken),
                quoteSize.abs(),
                0
            );

            uint256 baseNeeded = (result[1] * (10000 - IConfig(config).initMarginRatio())) / 10000;
            //repay - lent, earn when lent less and repay more
            unrealizedPnl = int256(1).mulU(result[1]).subU(tradeSize);
            int256 remainBase = baseSize.addU(baseNeeded);
            amount = remainBase <= 0 ? 0 : remainBase.abs();
        }
    }

    function _calFundingFee(address trader, int256 _latestCPF) internal view returns (int256) {
        Position memory position = traderPositionMap[trader];

        int256 baseAmountFunding;
        if (position.quoteSize == 0) {
            baseAmountFunding = 0;
        } else {
            baseAmountFunding = position.quoteSize < 0
                ? int256(0).subU(_querySwapBaseWithAmm(true, position.quoteSize.abs()))
                : int256(0).addU(_querySwapBaseWithAmm(false, position.quoteSize.abs()));
        }

        return (baseAmountFunding * (_latestCPF - traderCPF[trader])).divU(1e18);
    }

    function _calDebtRatio(int256 quoteSize, int256 baseSize) internal view returns (uint256 debtRatio) {
        if (quoteSize == 0 || (quoteSize > 0 && baseSize >= 0)) {
            debtRatio = 0;
        } else if (quoteSize < 0 && baseSize <= 0) {
            debtRatio = 10000;
        } else if (quoteSize > 0) {
            uint256 quoteAmount = quoteSize.abs();
            //simulate to close short, markPriceAcc bigger, asset undervalue
            uint256 baseAmount = IPriceOracle(IConfig(config).priceOracle()).getMarkPriceAcc(
                amm,
                IConfig(config).beta(),
                quoteAmount,
                false
            );

            debtRatio = baseAmount == 0 ? 10000 : (baseSize.abs() * 10000) / baseAmount;
        } else {
            uint256 quoteAmount = quoteSize.abs();
            //simulate to close long, markPriceAcc smaller, debt overvalue
            uint256 baseAmount = IPriceOracle(IConfig(config).priceOracle()).getMarkPriceAcc(
                amm,
                IConfig(config).beta(),
                quoteAmount,
                true
            );

            debtRatio = (baseAmount * 10000) / baseSize.abs();
        }
    }

    function _getSwapParam(bool isCloseLongOrOpenShort, uint256 amount)
        internal
        view
        returns (
            address inputToken,
            address outputToken,
            uint256 inputAmount,
            uint256 outputAmount
        )
    {
        if (isCloseLongOrOpenShort) {
            outputToken = quoteToken;
            outputAmount = amount;
            inputToken = baseToken;
        } else {
            inputToken = quoteToken;
            inputAmount = amount;
            outputToken = baseToken;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IMarginFactory {
    event MarginCreated(address indexed baseToken, address indexed quoteToken, address margin);

    function createMargin(address baseToken, address quoteToken) external returns (address margin);

    function initMargin(
        address baseToken,
        address quoteToken,
        address amm
    ) external;

    function upperFactory() external view returns (address);

    function config() external view returns (address);

    function getMargin(address baseToken, address quoteToken) external view returns (address margin);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IVault {
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, address indexed receiver, uint256 amount);

    /// @notice deposit baseToken to user
    function deposit(address user, uint256 amount) external;

    /// @notice withdraw user's baseToken from margin contract to receiver
    function withdraw(
        address user,
        address receiver,
        uint256 amount
    ) external;

    /// @notice get baseToken amount in margin
    function reserve() external view returns (uint256);
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

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "../core/Margin.sol";

contract MockFactory {
    address public config;
    Margin public margin;

    constructor(address _config) {
        config = _config;
    }

    function createPair() public {
        margin = new Margin();
    }

    function initialize(
        address baseToken_,
        address quoteToken_,
        address amm_
    ) public {
        margin.initialize(baseToken_, quoteToken_, amm_);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./Margin.sol";
import "./interfaces/IMarginFactory.sol";

//factory of margin, called by pairFactory
contract MarginFactory is IMarginFactory {
    address public immutable override upperFactory; // PairFactory
    address public immutable override config;

    // baseToken => quoteToken => margin
    mapping(address => mapping(address => address)) public override getMargin;

    modifier onlyUpper() {
        require(msg.sender == upperFactory, "AmmFactory: FORBIDDEN");
        _;
    }

    constructor(address upperFactory_, address config_) {
        require(upperFactory_ != address(0), "MarginFactory: ZERO_UPPER");
        require(config_ != address(0), "MarginFactory: ZERO_CONFIG");
        upperFactory = upperFactory_;
        config = config_;
    }

    function createMargin(address baseToken, address quoteToken) external override onlyUpper returns (address margin) {
        require(baseToken != quoteToken, "MarginFactory.createMargin: IDENTICAL_ADDRESSES");
        require(baseToken != address(0) && quoteToken != address(0), "MarginFactory.createMargin: ZERO_ADDRESS");
        require(getMargin[baseToken][quoteToken] == address(0), "MarginFactory.createMargin: MARGIN_EXIST");
        bytes32 salt = keccak256(abi.encodePacked(baseToken, quoteToken));
        bytes memory marginBytecode = type(Margin).creationCode;
        assembly {
            margin := create2(0, add(marginBytecode, 32), mload(marginBytecode), salt)
        }
        getMargin[baseToken][quoteToken] = margin;
        emit MarginCreated(baseToken, quoteToken, margin);
    }

    function initMargin(
        address baseToken,
        address quoteToken,
        address amm
    ) external override onlyUpper {
        require(amm != address(0), "MarginFactory.initMargin: ZERO_AMM");
        address margin = getMargin[baseToken][quoteToken];
        require(margin != address(0), "MarginFactory.initMargin: ZERO_MARGIN");
        IMargin(margin).initialize(baseToken, quoteToken, amm);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IPairFactory.sol";
import "./interfaces/IAmmFactory.sol";
import "./interfaces/IMarginFactory.sol";
import "./interfaces/IAmm.sol";
import "./interfaces/IMargin.sol";
import "../utils/Ownable.sol";

contract PairFactory is IPairFactory, Ownable {
    address public override ammFactory;
    address public override marginFactory;

    constructor() {
        owner = msg.sender;
    }

    function init(address ammFactory_, address marginFactory_) external onlyOwner {
        require(ammFactory == address(0) && marginFactory == address(0), "PairFactory: ALREADY_INITED");
        require(ammFactory_ != address(0) && marginFactory_ != address(0), "PairFactory: ZERO_ADDRESS");
        ammFactory = ammFactory_;
        marginFactory = marginFactory_;
    }

    function createPair(address baseToken, address quoteToken) external override returns (address amm, address margin) {
        amm = IAmmFactory(ammFactory).createAmm(baseToken, quoteToken);
        margin = IMarginFactory(marginFactory).createMargin(baseToken, quoteToken);
        IAmmFactory(ammFactory).initAmm(baseToken, quoteToken, margin);
        IMarginFactory(marginFactory).initMargin(baseToken, quoteToken, amm);
        emit NewPair(baseToken, quoteToken, amm, margin);
    }

    function getAmm(address baseToken, address quoteToken) external view override returns (address) {
        return IAmmFactory(ammFactory).getAmm(baseToken, quoteToken);
    }

    function getMargin(address baseToken, address quoteToken) external view override returns (address) {
        return IMarginFactory(marginFactory).getMargin(baseToken, quoteToken);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../core/interfaces/IERC20.sol";
import "../utils/Reentrant.sol";
import "../utils/Ownable.sol";
import "../libraries/TransferHelper.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract RewardForStaking is Reentrant, Ownable {
    using ECDSA for bytes32;

    event SetEmergency(bool emergency);
    event SetSigner(address signer, bool state);
    event Claim(address indexed user, address[] tokens, uint256[] amounts, bytes nonce);

    address public WETH;
    bool public emergency;
    mapping(address => bool) public signers;
    mapping(bytes => bool) public usedNonce;

    constructor(address WETH_) {
        owner = msg.sender;
        WETH = WETH_;
    }

    receive() external payable {}

    function setSigner(address signer, bool state) external onlyOwner {
        require(signer != address(0), "RewardForStaking: ZERO_ADDRESS");
        signers[signer] = state;
        emit SetSigner(signer, state);
    }

    function setEmergency(bool emergency_) external onlyOwner {
        emergency = emergency_;
        emit SetEmergency(emergency_);
    }

    function emergencyWithdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(emergency, "NOT_EMERGENCY");
        TransferHelper.safeTransfer(token, to, amount);
    }

    function claim(
        address user,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata nonce,
        uint256 expireAt,
        bytes memory signature
    ) external nonReentrant {
        require(!emergency, "EMERGENCY");
        verify(user, tokens, amounts, nonce, expireAt, signature);
        usedNonce[nonce] = true;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == WETH) {
                TransferHelper.safeTransferETH(user, amounts[i]);
            } else {
                TransferHelper.safeTransfer(tokens[i], user, amounts[i]);
            }
        }
        emit Claim(user, tokens, amounts, nonce);
    }

    function verify(
        address user,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata nonce,
        uint256 expireAt,
        bytes memory signature
    ) public view returns (bool) {
        address recover = keccak256(abi.encode(user, tokens, amounts, nonce, expireAt, address(this)))
            .toEthSignedMessageHash()
            .recover(signature);
        require(signers[recover], "NOT_SIGNER");
        require(!usedNonce[nonce], "NONCE_USED");
        require(expireAt > block.timestamp, "EXPIRED");
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../core/interfaces/IERC20.sol";
import "../utils/Reentrant.sol";
import "../utils/Ownable.sol";
import "../libraries/TransferHelper.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract RewardForCashback is Reentrant, Ownable {
    using ECDSA for bytes32;

    event SetEmergency(bool emergency);
    event SetSigner(address signer, bool state);
    event Claim(address indexed user, address[] tokens, uint256[] amounts, bytes nonce, uint8 useFor);

    address public WETH;
    bool public emergency;
    mapping(address => bool) public signers;
    mapping(bytes => bool) public usedNonce;

    constructor(address WETH_) {
        owner = msg.sender;
        WETH = WETH_;
    }
    receive() external payable { }

    function setSigner(address signer, bool state) external onlyOwner {
        require(signer != address(0), "ZERO_ADDRESS");
        signers[signer] = state;
        emit SetSigner(signer, state);
    }

    function setEmergency(bool emergency_) external onlyOwner {
        emergency = emergency_;
        emit SetEmergency(emergency_);
    }

    function emergencyWithdraw(
        address token,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(emergency, "NOT_EMERGENCY");
        TransferHelper.safeTransfer(token, to, amount);
    }

    function claim(
        address user,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata nonce,
        uint256 expireAt,
        uint8 useFor,
        bytes memory signature
    ) external nonReentrant {
        require(!emergency, "EMERGENCY");
        verify(user, tokens, amounts, nonce, expireAt, useFor, signature);
        usedNonce[nonce] = true;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == WETH) {
                TransferHelper.safeTransferETH(user, amounts[i]);
            } else {
                TransferHelper.safeTransfer(tokens[i], user, amounts[i]);
            }
        }
        emit Claim(user, tokens, amounts, nonce, useFor);
    }

    function verify(
        address user,
        address[] calldata tokens,
        uint256[] calldata amounts,
        bytes calldata nonce,
        uint256 expireAt,
        uint8 useFor,
        bytes memory signature
    ) public view returns (bool) {
        address recover = keccak256(abi.encode(user, tokens, amounts, nonce, expireAt, useFor, address(this)))
            .toEthSignedMessageHash()
            .recover(signature);
        require(signers[recover], "NOT_SIGNER");
        require(!usedNonce[nonce], "NONCE_USED");
        require(expireAt > block.timestamp, "EXPIRED");
        return true;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../core/interfaces/IERC20.sol";
import "../utils/Reentrant.sol";
import "../utils/Ownable.sol";
import "../libraries/TransferHelper.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract NFTRebate is Reentrant, Ownable {
    using ECDSA for bytes32;

    event SetEmergency(bool emergency);
    event SetSigner(address signer, bool state);
    event Claim(address indexed user, bytes nonce, uint256 amount);

    uint256 public eachNFT;
    uint16 public maxCount;
    uint16 public claimedCount;
    
    mapping(address => bool) public signers;
    mapping(bytes => bool) public usedNonce;

    bool public emergency;

    constructor(uint256 eachNFT_, uint16 maxCount_) {
        owner = msg.sender;
        eachNFT = eachNFT_;
        maxCount = maxCount_;
    }
    
    receive() external payable { }

    function setSigner(address signer, bool state) external onlyOwner {
        require(signer != address(0), "ZERO_ADDRESS");
        signers[signer] = state;
        emit SetSigner(signer, state);
    }

    function setEmergency(bool emergency_) external onlyOwner {
        emergency = emergency_;
        emit SetEmergency(emergency_);
    }

    function emergencyWithdraw(
        address to,
        uint256 amount
    ) external onlyOwner {
        require(emergency, "NOT_EMERGENCY");
        TransferHelper.safeTransferETH(to, amount);
    }

    function claim(
        address user,
        uint16 count,
        bytes calldata nonce,
        bytes memory signature
    ) external nonReentrant {
        require(!emergency, "EMERGENCY");
        verify(user, count, nonce, signature);
        usedNonce[nonce] = true;
        uint256 amount = eachNFT * count;
        claimedCount += count;
        TransferHelper.safeTransferETH(user, amount);
        emit Claim(user, nonce, amount);
    }

    function verify(
        address user,
        uint16 count,
        bytes calldata nonce,
        bytes memory signature
    ) public view returns (bool) {
        address recover = keccak256(abi.encode(user, count, nonce, address(this)))
            .toEthSignedMessageHash()
            .recover(signature);
        require(signers[recover], "NOT_SIGNER");
        require(!usedNonce[nonce], "NONCE_USED");
        require(count <= maxCount - claimedCount, "OVER_COUNT");
        return true;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IApeXPool.sol";
import "./interfaces/IStakingPoolFactory.sol";
import "../core/interfaces/IERC20.sol";
import "../utils/Reentrant.sol";

contract ApeXPool is IApeXPool, Reentrant {
    uint256 internal constant WEIGHT_MULTIPLIER = 1e6;
    uint256 internal constant MAX_TIME_STAKE_WEIGHT_MULTIPLIER = 2 * WEIGHT_MULTIPLIER;
    uint256 internal constant REWARD_PER_WEIGHT_MULTIPLIER = 1e12;

    address public immutable override poolToken;
    IStakingPoolFactory public immutable factory;
    uint256 public yieldRewardsPerWeight;
    uint256 public usersLockingWeight;
    mapping(address => User) public users;

    constructor(address _factory, address _poolToken) {
        require(_factory != address(0), "cp: INVALID_FACTORY");
        require(_poolToken != address(0), "cp: INVALID_POOL_TOKEN");

        factory = IStakingPoolFactory(_factory);
        poolToken = _poolToken;
    }

    function stake(uint256 _amount, uint256 _lockUntil) external override nonReentrant {
        _stake(_amount, _lockUntil, false);
        IERC20(poolToken).transferFrom(msg.sender, address(this), _amount);
    }

    function stakeEsApeX(uint256 _amount, uint256 _lockUntil) external override {
        _stake(_amount, _lockUntil, true);
        factory.transferEsApeXFrom(msg.sender, address(factory), _amount);
    }

    function _stake(
        uint256 _amount,
        uint256 _lockUntil,
        bool _isEsApeX
    ) internal {
        require(_amount > 0, "sp.stake: INVALID_AMOUNT");
        uint256 now256 = block.timestamp;
        uint256 lockTime = factory.lockTime();
        require(
            _lockUntil == 0 || (_lockUntil > now256 && _lockUntil <= now256 + lockTime),
            "sp._stake: INVALID_LOCK_INTERVAL"
        );

        address _staker = msg.sender;
        User storage user = users[_staker];
        _processRewards(_staker, user);

        //if 0, not lock
        uint256 lockFrom = _lockUntil > 0 ? now256 : 0;
        uint256 stakeWeight = (((_lockUntil - lockFrom) * WEIGHT_MULTIPLIER) / lockTime + WEIGHT_MULTIPLIER) * _amount;
        uint256 depositId = user.deposits.length;
        Deposit memory deposit = Deposit({
            amount: _amount,
            weight: stakeWeight,
            lockFrom: lockFrom,
            lockUntil: _lockUntil
        });

        if (_isEsApeX) {
            user.esDeposits.push(deposit);
        } else {
            user.deposits.push(deposit);
        }

        factory.mintVeApeX(_staker, stakeWeight / WEIGHT_MULTIPLIER);
        user.tokenAmount += _amount;
        user.totalWeight += stakeWeight;
        user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
        usersLockingWeight += stakeWeight;

        emit Staked(_staker, depositId, _isEsApeX, _amount, lockFrom, _lockUntil);
    }

    function batchWithdraw(
        uint256[] memory depositIds,
        uint256[] memory depositAmounts,
        uint256[] memory yieldIds,
        uint256[] memory yieldAmounts,
        uint256[] memory esDepositIds,
        uint256[] memory esDepositAmounts
    ) external override {
        require(depositIds.length == depositAmounts.length, "sp.batchWithdraw: INVALID_DEPOSITS_AMOUNTS");
        require(yieldIds.length == yieldAmounts.length, "sp.batchWithdraw: INVALID_YIELDS_AMOUNTS");
        require(esDepositIds.length == esDepositAmounts.length, "sp.batchWithdraw: INVALID_ESDEPOSITS_AMOUNTS");

        User storage user = users[msg.sender];
        _processRewards(msg.sender, user);
        emit BatchWithdraw(
            msg.sender,
            depositIds,
            depositAmounts,
            yieldIds,
            yieldAmounts,
            esDepositIds,
            esDepositAmounts
        );
        uint256 lockTime = factory.lockTime();

        uint256 _amount;
        uint256 _id;
        uint256 stakeAmount;
        uint256 newWeight;
        uint256 deltaUsersLockingWeight;
        Deposit memory stakeDeposit;
        for (uint256 i = 0; i < depositIds.length; i++) {
            _amount = depositAmounts[i];
            _id = depositIds[i];
            require(_amount != 0, "sp.batchWithdraw: INVALID_DEPOSIT_AMOUNT");
            stakeDeposit = user.deposits[_id];
            require(
                stakeDeposit.lockFrom == 0 || block.timestamp > stakeDeposit.lockUntil,
                "sp.batchWithdraw: DEPOSIT_LOCKED"
            );
            require(stakeDeposit.amount >= _amount, "sp.batchWithdraw: EXCEED_DEPOSIT_STAKED");

            newWeight =
                (((stakeDeposit.lockUntil - stakeDeposit.lockFrom) * WEIGHT_MULTIPLIER) /
                    lockTime +
                    WEIGHT_MULTIPLIER) *
                (stakeDeposit.amount - _amount);

            stakeAmount += _amount;
            deltaUsersLockingWeight += (stakeDeposit.weight - newWeight);

            if (stakeDeposit.amount == _amount) {
                delete user.deposits[_id];
            } else {
                stakeDeposit.amount -= _amount;
                stakeDeposit.weight = newWeight;
                user.deposits[_id] = stakeDeposit;
            }
        }
        {
            uint256 esStakeAmount;
            for (uint256 i = 0; i < esDepositIds.length; i++) {
                _amount = esDepositAmounts[i];
                _id = esDepositIds[i];
                require(_amount != 0, "sp.batchWithdraw: INVALID_ESDEPOSIT_AMOUNT");
                stakeDeposit = user.esDeposits[_id];
                require(
                    stakeDeposit.lockFrom == 0 || block.timestamp > stakeDeposit.lockUntil,
                    "sp.batchWithdraw: ESDEPOSIT_LOCKED"
                );
                require(stakeDeposit.amount >= _amount, "sp.batchWithdraw: EXCEED_ESDEPOSIT_STAKED");

                newWeight =
                    (((stakeDeposit.lockUntil - stakeDeposit.lockFrom) * WEIGHT_MULTIPLIER) /
                        lockTime +
                        WEIGHT_MULTIPLIER) *
                    (stakeDeposit.amount - _amount);

                esStakeAmount += _amount;
                deltaUsersLockingWeight += (stakeDeposit.weight - newWeight);

                if (stakeDeposit.amount == _amount) {
                    delete user.esDeposits[_id];
                } else {
                    stakeDeposit.amount -= _amount;
                    stakeDeposit.weight = newWeight;
                    user.esDeposits[_id] = stakeDeposit;
                }
            }
            if (esStakeAmount > 0) {
                user.tokenAmount -= esStakeAmount;
                factory.transferEsApeXTo(msg.sender, esStakeAmount);
            }
        }

        factory.burnVeApeX(msg.sender, deltaUsersLockingWeight / WEIGHT_MULTIPLIER);
        user.totalWeight -= deltaUsersLockingWeight;
        usersLockingWeight -= deltaUsersLockingWeight;
        user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;

        {
            uint256 yieldAmount;
            Yield memory stakeYield;
            for (uint256 i = 0; i < yieldIds.length; i++) {
                _amount = yieldAmounts[i];
                _id = yieldIds[i];
                require(_amount != 0, "sp.batchWithdraw: INVALID_YIELD_AMOUNT");
                stakeYield = user.yields[_id];
                require(block.timestamp > stakeYield.lockUntil, "sp.batchWithdraw: YIELD_LOCKED");
                require(stakeYield.amount >= _amount, "sp.batchWithdraw: EXCEED_YIELD_STAKED");

                yieldAmount += _amount;

                if (stakeYield.amount == _amount) {
                    delete user.yields[_id];
                } else {
                    stakeYield.amount -= _amount;
                    user.yields[_id] = stakeYield;
                }
            }

            if (yieldAmount > 0) {
                user.tokenAmount -= yieldAmount;
                factory.transferYieldTo(msg.sender, yieldAmount);
            }
        }

        if (stakeAmount > 0) {
            user.tokenAmount -= stakeAmount;
            IERC20(poolToken).transfer(msg.sender, stakeAmount);
        }
    }

    function forceWithdraw(uint256[] memory _yieldIds) external override {
        uint256 minRemainRatio = factory.minRemainRatioAfterBurn();
        address _staker = msg.sender;
        uint256 now256 = block.timestamp;

        User storage user = users[_staker];

        uint256 deltaTotalAmount;
        uint256 yieldAmount;

        //force withdraw vesting or vested rewards
        Yield memory yield;
        for (uint256 i = 0; i < _yieldIds.length; i++) {
            yield = user.yields[_yieldIds[i]];
            deltaTotalAmount += yield.amount;

            if (now256 >= yield.lockUntil) {
                yieldAmount += yield.amount;
            } else {
                yieldAmount +=
                    (yield.amount *
                        (minRemainRatio +
                            ((10000 - minRemainRatio) * (now256 - yield.lockFrom)) /
                            factory.lockTime())) /
                    10000;
            }
            delete user.yields[_yieldIds[i]];
        }

        uint256 remainApeX = deltaTotalAmount - yieldAmount;

        //half of remaining esApeX to boost remain vester
        uint256 remainForOtherVest = factory.remainForOtherVest();
        uint256 newYieldRewardsPerWeight = yieldRewardsPerWeight +
            ((remainApeX * REWARD_PER_WEIGHT_MULTIPLIER) * remainForOtherVest) /
            100 /
            usersLockingWeight;
        yieldRewardsPerWeight = newYieldRewardsPerWeight;

        //half of remaining esApeX to transfer to treasury in apeX
        factory.transferYieldToTreasury(remainApeX - (remainApeX * remainForOtherVest) / 100);

        user.tokenAmount -= deltaTotalAmount;
        factory.burnEsApeX(address(this), deltaTotalAmount);
        if (yieldAmount > 0) {
            factory.transferYieldTo(_staker, yieldAmount);
        }

        emit ForceWithdraw(_staker, _yieldIds);
    }

    //only can extend lock time
    function updateStakeLock(
        uint256 _id,
        uint256 _lockUntil,
        bool _isEsApeX
    ) external override {
        uint256 now256 = block.timestamp;
        require(_lockUntil > now256, "sp.updateStakeLock: INVALID_LOCK_UNTIL");

        uint256 lockTime = factory.lockTime();
        address _staker = msg.sender;
        User storage user = users[_staker];
        _processRewards(_staker, user);

        Deposit storage stakeDeposit;
        if (_isEsApeX) {
            stakeDeposit = user.esDeposits[_id];
        } else {
            stakeDeposit = user.deposits[_id];
        }
        require(_lockUntil > stakeDeposit.lockUntil, "sp.updateStakeLock: INVALID_NEW_LOCK");

        if (stakeDeposit.lockFrom == 0) {
            require(_lockUntil <= now256 + lockTime, "sp.updateStakeLock: EXCEED_MAX_LOCK_PERIOD");
            stakeDeposit.lockFrom = now256;
        } else {
            require(_lockUntil <= stakeDeposit.lockFrom + lockTime, "sp.updateStakeLock: EXCEED_MAX_LOCK");
        }

        uint256 oldWeight = stakeDeposit.weight;
        uint256 newWeight = (((_lockUntil - stakeDeposit.lockFrom) * WEIGHT_MULTIPLIER) /
            lockTime +
            WEIGHT_MULTIPLIER) * stakeDeposit.amount;

        factory.mintVeApeX(_staker, (newWeight - oldWeight) / WEIGHT_MULTIPLIER);
        stakeDeposit.lockUntil = _lockUntil;
        stakeDeposit.weight = newWeight;
        user.totalWeight = user.totalWeight - oldWeight + newWeight;
        user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
        usersLockingWeight = usersLockingWeight - oldWeight + newWeight;

        emit UpdateStakeLock(_staker, _id, _isEsApeX, stakeDeposit.lockFrom, _lockUntil);
    }

    function processRewards() external override {
        address staker = msg.sender;
        User storage user = users[staker];

        _processRewards(staker, user);
        user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;
    }

    function syncWeightPrice() public {
        if (factory.shouldUpdateRatio()) {
            factory.updateApeXPerSec();
        }

        uint256 apeXReward = factory.syncYieldPriceOfWeight();
        if (usersLockingWeight == 0) {
            return;
        }
        yieldRewardsPerWeight += (apeXReward * REWARD_PER_WEIGHT_MULTIPLIER) / usersLockingWeight;
        emit Synchronized(msg.sender, yieldRewardsPerWeight);
    }

    //update weight price, then if apeX, add deposits; if not, stake as pool.
    function _processRewards(address _staker, User storage user) internal {
        syncWeightPrice();

        //if no yield
        if (user.totalWeight == 0) return;
        uint256 yieldAmount = (user.totalWeight * yieldRewardsPerWeight) /
            REWARD_PER_WEIGHT_MULTIPLIER -
            user.subYieldRewards;
        if (yieldAmount == 0) return;

        //mint esApeX to _staker
        factory.mintEsApeX(_staker, yieldAmount);
        emit MintEsApeX(_staker, yieldAmount);
    }

    function vest(uint256 vestAmount) external override {
        User storage user = users[msg.sender];
        _processRewards(msg.sender, user);

        uint256 now256 = block.timestamp;
        uint256 lockUntil = now256 + factory.lockTime();
        emit YieldClaimed(msg.sender, user.yields.length, vestAmount, now256, lockUntil);

        user.yields.push(Yield({amount: vestAmount, lockFrom: now256, lockUntil: lockUntil}));
        user.tokenAmount += vestAmount;
        user.subYieldRewards = (user.totalWeight * yieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER;

        factory.transferEsApeXFrom(msg.sender, address(this), vestAmount);
    }

    function pendingYieldRewards(address _staker) external view returns (uint256 pending) {
        uint256 newYieldRewardsPerWeight = yieldRewardsPerWeight;

        if (usersLockingWeight != 0) {
            (uint256 apeXReward, ) = factory.calStakingPoolApeXReward(poolToken);
            newYieldRewardsPerWeight += (apeXReward * REWARD_PER_WEIGHT_MULTIPLIER) / usersLockingWeight;
        }

        User memory user = users[_staker];
        pending = (user.totalWeight * newYieldRewardsPerWeight) / REWARD_PER_WEIGHT_MULTIPLIER - user.subYieldRewards;
    }

    function getStakeInfo(address _user)
        external
        view
        override
        returns (
            uint256 tokenAmount,
            uint256 totalWeight,
            uint256 subYieldRewards
        )
    {
        User memory user = users[_user];
        return (user.tokenAmount, user.totalWeight, user.subYieldRewards);
    }

    function getDeposit(address _user, uint256 _id) external view override returns (Deposit memory) {
        return users[_user].deposits[_id];
    }

    function getDepositsLength(address _user) external view override returns (uint256) {
        return users[_user].deposits.length;
    }

    function getYield(address _user, uint256 _yieldId) external view override returns (Yield memory) {
        return users[_user].yields[_yieldId];
    }

    function getYieldsLength(address _user) external view override returns (uint256) {
        return users[_user].yields.length;
    }

    function getEsDeposit(address _user, uint256 _id) external view override returns (Deposit memory) {
        return users[_user].esDeposits[_id];
    }

    function getEsDepositsLength(address _user) external view override returns (uint256) {
        return users[_user].esDeposits.length;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IAmm.sol";
import "./interfaces/IRouter.sol";
import "./interfaces/IPairFactory.sol";
import "../libraries/TransferHelper.sol";
import "../utils/Reentrant.sol";

contract Migrator is Reentrant {
    event Migrate(address indexed user, uint256 oldLiquidity, uint256 newLiquidity, uint256 baseAmount);

    IRouter public oldRouter;
    IRouter public newRouter;
    IPairFactory public oldFactory;
    IPairFactory public newFactory;

    constructor(IRouter oldRouter_, IRouter newRouter_) {
        oldRouter = oldRouter_;
        newRouter = newRouter_;
        oldFactory = IPairFactory(oldRouter.pairFactory());
        newFactory = IPairFactory(newRouter.pairFactory());
    }

    function migrate(address baseToken, address quoteToken) external nonReentrant {
        address oldAmm = oldFactory.getAmm(baseToken, quoteToken);
        uint256 oldLiquidity = IERC20(oldAmm).balanceOf(msg.sender);
        require(oldLiquidity > 0, "ZERO_LIQUIDITY");
        TransferHelper.safeTransferFrom(oldAmm, msg.sender, oldAmm, oldLiquidity);
        (uint256 baseAmount, , ) = IAmm(oldAmm).burn(address(this));
        require(baseAmount > 0, "ZERO_BASE_AMOUNT");

        address newAmm = newFactory.getAmm(baseToken, quoteToken);
        TransferHelper.safeTransfer(baseToken, newAmm, baseAmount);
        ( , , uint256 newLiquidity) = IAmm(newAmm).mint(msg.sender);
        emit Migrate(msg.sender, oldLiquidity, newLiquidity, baseAmount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./LiquidityERC20.sol";
import "./interfaces/IAmmFactory.sol";
import "./interfaces/IConfig.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/IMarginFactory.sol";
import "./interfaces/IAmm.sol";
import "./interfaces/IVault.sol";
import "./interfaces/IMargin.sol";
import "./interfaces/IPairFactory.sol";
import "../utils/Reentrant.sol";
import "../libraries/UQ112x112.sol";
import "../libraries/Math.sol";
import "../libraries/FullMath.sol";
import "../libraries/ChainAdapter.sol";
import "../libraries/SignedMath.sol";

contract Amm is IAmm, LiquidityERC20, Reentrant {
    using UQ112x112 for uint224;
    using SignedMath for int256;

    uint256 public constant override MINIMUM_LIQUIDITY = 10**3;

    address public immutable override factory;
    address public override config;
    address public override baseToken;
    address public override quoteToken;
    address public override margin;

    uint256 public override price0CumulativeLast;
    uint256 public override price1CumulativeLast;

    uint256 public kLast;
    uint256 public override lastPrice;

    bytes4 private constant SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    uint112 private baseReserve; // uses single storage slot, accessible via getReserves
    uint112 private quoteReserve; // uses single storage slot, accessible via getReserves
    uint32 private blockTimestampLast;
    uint256 private lastBlockNumber;
    uint256 private rebaseTimestampLast;

    modifier onlyMargin() {
        require(margin == msg.sender, "Amm: ONLY_MARGIN");
        _;
    }

    constructor() {
        factory = msg.sender;
    }

    function initialize(
        address baseToken_,
        address quoteToken_,
        address margin_
    ) external override {
        require(msg.sender == factory, "Amm.initialize: FORBIDDEN"); // sufficient check
        baseToken = baseToken_;
        quoteToken = quoteToken_;
        margin = margin_;
        config = IAmmFactory(factory).config();
    }

    /// @notice add liquidity
    /// @dev  calculate the liquidity according to the real baseReserve.
    function mint(address to)
        external
        override
        nonReentrant
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        )
    {
        // only router can add liquidity
        require(IConfig(config).routerMap(msg.sender), "Amm.mint: FORBIDDEN");

        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves(); // gas savings

        // get real baseReserve
        uint256 realBaseReserve = getRealBaseReserve();

        baseAmount = IERC20(baseToken).balanceOf(address(this));
        require(baseAmount > 0, "Amm.mint: ZERO_BASE_AMOUNT");

        bool feeOn = _mintFee(_baseReserve, _quoteReserve);
        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee

        if (_totalSupply == 0) {
            (quoteAmount, ) = IPriceOracle(IConfig(config).priceOracle()).quote(baseToken, quoteToken, baseAmount);

            require(quoteAmount > 0, "Amm.mint: INSUFFICIENT_QUOTE_AMOUNT");
            liquidity = Math.sqrt(baseAmount * quoteAmount) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
        } else {
            quoteAmount = (baseAmount * _quoteReserve) / _baseReserve;

            // realBaseReserve
            liquidity = (baseAmount * _totalSupply) / realBaseReserve;
        }
        require(liquidity > 0, "Amm.mint: INSUFFICIENT_LIQUIDITY_MINTED");
        _mint(to, liquidity);

        //price check  0.1%
        require(
            (_baseReserve + baseAmount) * _quoteReserve * 999 <= (_quoteReserve + quoteAmount) * _baseReserve * 1000,
            "Amm.mint: PRICE_BEFORE_AND_AFTER_MUST_BE_THE_SAME"
        );
        require(
            (_quoteReserve + quoteAmount) * _baseReserve * 1000 <= (_baseReserve + baseAmount) * _quoteReserve * 1001,
            "Amm.mint: PRICE_BEFORE_AND_AFTER_MUST_BE_THE_SAME"
        );

        _update(_baseReserve + baseAmount, _quoteReserve + quoteAmount, _baseReserve, _quoteReserve, false);

        if (feeOn) kLast = uint256(baseReserve) * quoteReserve;

        _safeTransfer(baseToken, margin, baseAmount);
        IVault(margin).deposit(msg.sender, baseAmount);

        emit Mint(msg.sender, to, baseAmount, quoteAmount, liquidity);
    }

    /// @notice add liquidity
    /// @dev  calculate the liquidity according to the real baseReserve.
    function burn(address to)
        external
        override
        nonReentrant
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        )
    {
        // only router can burn liquidity
        require(IConfig(config).routerMap(msg.sender), "Amm.mint: FORBIDDEN");
        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves(); // gas savings
        liquidity = balanceOf[address(this)];

        // get real baseReserve
        uint256 realBaseReserve = getRealBaseReserve();

        // calculate the fee
        bool feeOn = _mintFee(_baseReserve, _quoteReserve);

        uint256 _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        baseAmount = (liquidity * realBaseReserve) / _totalSupply;
        // quoteAmount = (liquidity * _quoteReserve) / _totalSupply; // using balances ensures pro-rata distribution
        quoteAmount = (baseAmount * _quoteReserve) / _baseReserve;
        require(baseAmount > 0 && quoteAmount > 0, "Amm.burn: INSUFFICIENT_LIQUIDITY_BURNED");

        // gurantee the net postion close and total position(quote) in a tolerant sliappage after remove liquidity
        maxWithdrawCheck(uint256(_quoteReserve), quoteAmount);

        require(
            (_baseReserve - baseAmount) * _quoteReserve * 999 <= (_quoteReserve - quoteAmount) * _baseReserve * 1000,
            "Amm.burn: PRICE_BEFORE_AND_AFTER_MUST_BE_THE_SAME"
        );
        require(
            (_quoteReserve - quoteAmount) * _baseReserve * 1000 <= (_baseReserve - baseAmount) * _quoteReserve * 1001,
            "Amm.burn: PRICE_BEFORE_AND_AFTER_MUST_BE_THE_SAME"
        );

        _burn(address(this), liquidity);
        _update(_baseReserve - baseAmount, _quoteReserve - quoteAmount, _baseReserve, _quoteReserve, false);
        if (feeOn) kLast = uint256(baseReserve) * quoteReserve;

        IVault(margin).withdraw(msg.sender, to, baseAmount);
        emit Burn(msg.sender, to, baseAmount, quoteAmount, liquidity);
    }

    function maxWithdrawCheck(uint256 quoteReserve_, uint256 quoteAmount) public view {
        int256 quoteTokenOfNetPosition = IMargin(margin).netPosition();
        uint256 quoteTokenOfTotalPosition = IMargin(margin).totalPosition();
        uint256 lpWithdrawThresholdForNet = IConfig(config).lpWithdrawThresholdForNet();
        uint256 lpWithdrawThresholdForTotal = IConfig(config).lpWithdrawThresholdForTotal();

        require(
            quoteTokenOfNetPosition.abs() * 100 <= (quoteReserve_ - quoteAmount) * lpWithdrawThresholdForNet,
            "Amm.burn: TOO_LARGE_LIQUIDITY_WITHDRAW_FOR_NET_POSITION"
        );
        require(
            quoteTokenOfTotalPosition * 100 <= (quoteReserve_ - quoteAmount) * lpWithdrawThresholdForTotal,
            "Amm.burn: TOO_LARGE_LIQUIDITY_WITHDRAW_FOR_TOTAL_POSITION"
        );
    }

    function getRealBaseReserve() public view returns (uint256 realBaseReserve) {
        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves();

        int256 quoteTokenOfNetPosition = IMargin(margin).netPosition();

        require(int256(uint256(_quoteReserve)) + quoteTokenOfNetPosition <= 2**112, "Amm.mint:NetPosition_VALUE_WRONT");

        uint256 baseTokenOfNetPosition;

        if (quoteTokenOfNetPosition == 0) {
            return uint256(_baseReserve);
        }

        uint256[2] memory result;
        if (quoteTokenOfNetPosition < 0) {
            // long  （+， -）
            result = estimateSwap(baseToken, quoteToken, 0, quoteTokenOfNetPosition.abs());
            baseTokenOfNetPosition = result[0];

            realBaseReserve = uint256(_baseReserve) + baseTokenOfNetPosition;
        } else {
            //short  （-， +）
            result = estimateSwap(quoteToken, baseToken, quoteTokenOfNetPosition.abs(), 0);
            baseTokenOfNetPosition = result[1];

            realBaseReserve = uint256(_baseReserve) - baseTokenOfNetPosition;
        }
    }

    /// @notice
    function swap(
        address trader,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external override nonReentrant onlyMargin returns (uint256[2] memory amounts) {
        uint256[2] memory reserves;
        (reserves, amounts) = _estimateSwap(inputToken, outputToken, inputAmount, outputAmount);
        //check trade slippage
        _checkTradeSlippage(reserves[0], reserves[1], baseReserve, quoteReserve);
        _update(reserves[0], reserves[1], baseReserve, quoteReserve, false);

        emit Swap(trader, inputToken, outputToken, amounts[0], amounts[1]);
    }

    /// @notice  use in the situation  of forcing closing position
    function forceSwap(
        address trader,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external override nonReentrant onlyMargin {
        require(inputToken == baseToken || inputToken == quoteToken, "Amm.forceSwap: WRONG_INPUT_TOKEN");
        require(outputToken == baseToken || outputToken == quoteToken, "Amm.forceSwap: WRONG_OUTPUT_TOKEN");
        require(inputToken != outputToken, "Amm.forceSwap: SAME_TOKENS");
        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves();
        bool feeOn = _mintFee(_baseReserve, _quoteReserve);

        uint256 reserve0;
        uint256 reserve1;
        if (inputToken == baseToken) {
            reserve0 = _baseReserve + inputAmount;
            reserve1 = _quoteReserve - outputAmount;
        } else {
            reserve0 = _baseReserve - outputAmount;
            reserve1 = _quoteReserve + inputAmount;
        }

        _update(reserve0, reserve1, _baseReserve, _quoteReserve, true);
        if (feeOn) kLast = uint256(baseReserve) * quoteReserve;

        emit ForceSwap(trader, inputToken, outputToken, inputAmount, outputAmount);
    }

    /// @notice invoke when price gap is larger than "gap" percent;
    /// @notice gap is in config contract
    function rebase() external override nonReentrant returns (uint256 quoteReserveAfter) {
        require(msg.sender == tx.origin, "Amm.rebase: ONLY_EOA");
        uint256 interval = IConfig(config).rebaseInterval();
        require(block.timestamp - rebaseTimestampLast >= interval, "Amm.rebase: NOT_REACH_NEXT_REBASE_TIME");

        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves();
        bool feeOn = _mintFee(_baseReserve, _quoteReserve);

        uint256 quoteReserveFromInternal;
        (uint256 quoteReserveFromExternal, uint8 priceSource) = IPriceOracle(IConfig(config).priceOracle()).quote(
            baseToken,
            quoteToken,
            _baseReserve
        );
        if (priceSource == 0) {
            // external price use UniswapV3Twap, internal price use ammTwap
            quoteReserveFromInternal = IPriceOracle(IConfig(config).priceOracle()).quoteFromAmmTwap(
                address(this),
                _baseReserve
            );
        } else {
            // otherwise, use lastPrice as internal price
            quoteReserveFromInternal = (lastPrice * _baseReserve) / 2**112;
        }

        uint256 gap = IConfig(config).rebasePriceGap();
        require(
            quoteReserveFromExternal * 100 >= quoteReserveFromInternal * (100 + gap) ||
                quoteReserveFromExternal * 100 <= quoteReserveFromInternal * (100 - gap),
            "Amm.rebase: NOT_BEYOND_PRICE_GAP"
        );

        quoteReserveAfter = quoteReserveFromExternal;

        rebaseTimestampLast = uint32(block.timestamp % 2**32);
        _update(_baseReserve, quoteReserveAfter, _baseReserve, _quoteReserve, true);
        if (feeOn) kLast = uint256(baseReserve) * quoteReserve;

        emit Rebase(_quoteReserve, quoteReserveAfter, _baseReserve, quoteReserveFromInternal, quoteReserveFromExternal);
    }

    function collectFee() external override returns (bool feeOn) {
        require(IConfig(config).routerMap(msg.sender), "Amm.collectFee: FORBIDDEN");

        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves();
        feeOn = _mintFee(_baseReserve, _quoteReserve);
        if (feeOn) kLast = uint256(_baseReserve) * _quoteReserve;
    }

    /// notice view method for estimating swap
    function estimateSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) public view override returns (uint256[2] memory amounts) {
        (, amounts) = _estimateSwap(inputToken, outputToken, inputAmount, outputAmount);
    }

    //query max withdraw liquidity
    function getTheMaxBurnLiquidity() public view override returns (uint256 maxLiquidity) {
        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves(); // gas savings
        // get real baseReserve
        uint256 realBaseReserve = getRealBaseReserve();
        int256 quoteTokenOfNetPosition = IMargin(margin).netPosition();
        uint256 quoteTokenOfTotalPosition = IMargin(margin).totalPosition();
        uint256 _totalSupply = totalSupply + getFeeLiquidity();

        uint256 lpWithdrawThresholdForNet = IConfig(config).lpWithdrawThresholdForNet();
        uint256 lpWithdrawThresholdForTotal = IConfig(config).lpWithdrawThresholdForTotal();

        //  for net position  case
        uint256 maxQuoteLeftForNet = (quoteTokenOfNetPosition.abs() * 100) / lpWithdrawThresholdForNet;
        uint256 maxWithdrawQuoteAmountForNet;
        if (_quoteReserve > maxQuoteLeftForNet) {
            maxWithdrawQuoteAmountForNet = _quoteReserve - maxQuoteLeftForNet;
        }

        //  for total position  case
        uint256 maxQuoteLeftForTotal = (quoteTokenOfTotalPosition * 100) / lpWithdrawThresholdForTotal;
        uint256 maxWithdrawQuoteAmountForTotal;
        if (_quoteReserve > maxQuoteLeftForTotal) {
            maxWithdrawQuoteAmountForTotal = _quoteReserve - maxQuoteLeftForTotal;
        }

        uint256 maxWithdrawBaseAmount;
        // use the min quote amount;
        if (maxWithdrawQuoteAmountForNet > maxWithdrawQuoteAmountForTotal) {
            maxWithdrawBaseAmount = (maxWithdrawQuoteAmountForTotal * _baseReserve) / _quoteReserve;
        } else {
            maxWithdrawBaseAmount = (maxWithdrawQuoteAmountForNet * _baseReserve) / _quoteReserve;
        }

        maxLiquidity = (maxWithdrawBaseAmount * _totalSupply) / realBaseReserve;
    }

    function getFeeLiquidity() public view override returns (uint256) {
        address feeTo = IAmmFactory(factory).feeTo();
        bool feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        uint256 liquidity;
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(baseReserve) * quoteReserve);
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply * (rootK - rootKLast);

                    uint256 feeParameter = IConfig(config).feeParameter();
                    uint256 denominator = (rootK * feeParameter) / 100 + rootKLast;
                    liquidity = numerator / denominator;
                }
            }
        }
        return liquidity;
    }

    function getReserves()
        public
        view
        override
        returns (
            uint112 reserveBase,
            uint112 reserveQuote,
            uint32 blockTimestamp
        )
    {
        reserveBase = baseReserve;
        reserveQuote = quoteReserve;
        blockTimestamp = blockTimestampLast;
    }

    function _checkTradeSlippage(
        uint256 baseReserveNew,
        uint256 quoteReserveNew,
        uint112 baseReserveOld,
        uint112 quoteReserveOld
    ) internal view {
        // check trade slippage for every transaction
        uint256 numerator = quoteReserveNew * baseReserveOld * 100;
        uint256 demominator = baseReserveNew * quoteReserveOld;
        uint256 tradingSlippage = IConfig(config).tradingSlippage();
        require(
            (numerator < (100 + tradingSlippage) * demominator) && (numerator > (100 - tradingSlippage) * demominator),
            "AMM._update: TRADINGSLIPPAGE_TOO_LARGE_THAN_LAST_TRANSACTION"
        );
        require(
            (quoteReserveNew * 100 < ((100 + tradingSlippage) * baseReserveNew * lastPrice) / 2**112) &&
                (quoteReserveNew * 100 > ((100 - tradingSlippage) * baseReserveNew * lastPrice) / 2**112),
            "AMM._update: TRADINGSLIPPAGE_TOO_LARGE_THAN_LAST_BLOCK"
        );
    }

    function _estimateSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) internal view returns (uint256[2] memory reserves, uint256[2] memory amounts) {
        require(inputToken == baseToken || inputToken == quoteToken, "Amm._estimateSwap: WRONG_INPUT_TOKEN");
        require(outputToken == baseToken || outputToken == quoteToken, "Amm._estimateSwap: WRONG_OUTPUT_TOKEN");
        require(inputToken != outputToken, "Amm._estimateSwap: SAME_TOKENS");
        require(inputAmount > 0 || outputAmount > 0, "Amm._estimateSwap: INSUFFICIENT_AMOUNT");

        (uint112 _baseReserve, uint112 _quoteReserve, ) = getReserves();
        uint256 reserve0;
        uint256 reserve1;
        if (inputAmount > 0 && inputToken != address(0)) {
            // swapInput
            if (inputToken == baseToken) {
                outputAmount = _getAmountOut(inputAmount, _baseReserve, _quoteReserve);
                reserve0 = _baseReserve + inputAmount;
                reserve1 = _quoteReserve - outputAmount;
            } else {
                outputAmount = _getAmountOut(inputAmount, _quoteReserve, _baseReserve);
                reserve0 = _baseReserve - outputAmount;
                reserve1 = _quoteReserve + inputAmount;
            }
        } else {
            // swapOutput
            if (outputToken == baseToken) {
                require(outputAmount < _baseReserve, "AMM._estimateSwap: INSUFFICIENT_LIQUIDITY");
                inputAmount = _getAmountIn(outputAmount, _quoteReserve, _baseReserve);
                reserve0 = _baseReserve - outputAmount;
                reserve1 = _quoteReserve + inputAmount;
            } else {
                require(outputAmount < _quoteReserve, "AMM._estimateSwap: INSUFFICIENT_LIQUIDITY");
                inputAmount = _getAmountIn(outputAmount, _baseReserve, _quoteReserve);
                reserve0 = _baseReserve + inputAmount;
                reserve1 = _quoteReserve - outputAmount;
            }
        }
        reserves = [reserve0, reserve1];
        amounts = [inputAmount, outputAmount];
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "Amm._getAmountOut: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "Amm._getAmountOut: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 999;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function _getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "Amm._getAmountIn: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "Amm._getAmountIn: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 999;
        amountIn = (numerator / denominator) + 1;
    }

    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)
    function _mintFee(uint112 reserve0, uint112 reserve1) private returns (bool feeOn) {
        address feeTo = IAmmFactory(factory).feeTo();
        feeOn = feeTo != address(0);
        uint256 _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint256 rootK = Math.sqrt(uint256(reserve0) * reserve1);
                uint256 rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint256 numerator = totalSupply * (rootK - rootKLast);

                    uint256 feeParameter = IConfig(config).feeParameter();
                    uint256 denominator = (rootK * feeParameter) / 100 + rootKLast;
                    uint256 liquidity = numerator / denominator;
                    if (liquidity > 0) _mint(feeTo, liquidity);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    function _update(
        uint256 baseReserveNew,
        uint256 quoteReserveNew,
        uint112 baseReserveOld,
        uint112 quoteReserveOld,
        bool isRebaseOrForceSwap
    ) private {
        require(baseReserveNew <= type(uint112).max && quoteReserveNew <= type(uint112).max, "AMM._update: OVERFLOW");

        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        // last price means last block price.
        if (timeElapsed > 0 && baseReserveOld != 0 && quoteReserveOld != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint256(UQ112x112.encode(quoteReserveOld).uqdiv(baseReserveOld)) * timeElapsed;
            price1CumulativeLast += uint256(UQ112x112.encode(baseReserveOld).uqdiv(quoteReserveOld)) * timeElapsed;
            // update twap
            IPriceOracle(IConfig(config).priceOracle()).updateAmmTwap(address(this));
        }

        uint256 blockNumberDelta = ChainAdapter.blockNumber() - lastBlockNumber;
        //every arbi block number calculate
        if (blockNumberDelta > 0 && baseReserveOld != 0) {
            lastPrice = uint256(UQ112x112.encode(quoteReserveOld).uqdiv(baseReserveOld));
        }

        //set the last price to current price for rebase may cause price gap oversize the tradeslippage.
        if ((lastPrice == 0 && baseReserveNew != 0) || isRebaseOrForceSwap) {
            lastPrice = uint256(UQ112x112.encode(uint112(quoteReserveNew)).uqdiv(uint112(baseReserveNew)));
        }

        baseReserve = uint112(baseReserveNew);
        quoteReserve = uint112(quoteReserveNew);

        lastBlockNumber = ChainAdapter.blockNumber();
        blockTimestampLast = blockTimestamp;

        emit Sync(baseReserve, quoteReserve);
    }

    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "AMM._safeTransfer: TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/ILiquidityERC20.sol";

contract LiquidityERC20 is ILiquidityERC20 {
    string public constant override name = "APEX LP";
    string public constant override symbol = "APEX-LP";
    uint8 public constant override decimals = 18;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant override PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 public immutable override DOMAIN_SEPARATOR;

    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    mapping(address => uint256) public override nonces;

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] = allowance[from][msg.sender] - value;
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(deadline >= block.timestamp, "LiquidityERC20: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "LiquidityERC20: INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address owner,
        address spender,
        uint256 value
    ) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        balanceOf[from] = balanceOf[from] - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x > y) {
            return y;
        }
        return x;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./Amm.sol";
import "./interfaces/IAmmFactory.sol";
import "./interfaces/IPriceOracle.sol";

contract AmmFactory is IAmmFactory {
    address public immutable override upperFactory; // PairFactory
    address public immutable override config;
    address public override feeTo;
    address public override feeToSetter;

    // baseToken => quoteToken => amm
    mapping(address => mapping(address => address)) public override getAmm;

    modifier onlyUpper() {
        require(msg.sender == upperFactory, "AmmFactory: FORBIDDEN");
        _;
    }

    constructor(
        address upperFactory_,
        address config_,
        address feeToSetter_
    ) {
        require(config_ != address(0) && feeToSetter_ != address(0), "AmmFactory: ZERO_ADDRESS");
        upperFactory = upperFactory_;
        config = config_;
        feeToSetter = feeToSetter_;
    }

    function createAmm(address baseToken, address quoteToken) external override onlyUpper returns (address amm) {
        require(baseToken != quoteToken, "AmmFactory.createAmm: IDENTICAL_ADDRESSES");
        require(baseToken != address(0) && quoteToken != address(0), "AmmFactory.createAmm: ZERO_ADDRESS");
        require(getAmm[baseToken][quoteToken] == address(0), "AmmFactory.createAmm: AMM_EXIST");
        bytes32 salt = keccak256(abi.encodePacked(baseToken, quoteToken));
        bytes memory ammBytecode = type(Amm).creationCode;
        assembly {
            amm := create2(0, add(ammBytecode, 32), mload(ammBytecode), salt)
        }
        getAmm[baseToken][quoteToken] = amm;
        emit AmmCreated(baseToken, quoteToken, amm);
    }

    function initAmm(
        address baseToken,
        address quoteToken,
        address margin
    ) external override onlyUpper {
        address amm = getAmm[baseToken][quoteToken];
        Amm(amm).initialize(baseToken, quoteToken, margin);
        IPriceOracle(IConfig(config).priceOracle()).setupTwap(amm);
    }

    function setFeeTo(address feeTo_) external override {
        require(msg.sender == feeToSetter, "AmmFactory.setFeeTo: FORBIDDEN");
        feeTo = feeTo_;
    }

    function setFeeToSetter(address feeToSetter_) external override {
        require(msg.sender == feeToSetter, "AmmFactory.setFeeToSetter: FORBIDDEN");
        feeToSetter = feeToSetter_;
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "../core/interfaces/IERC20.sol";
import "../core/interfaces/IAmm.sol";
import "../core/interfaces/IConfig.sol";
import "../core/interfaces/IPriceOracle.sol";
import "../libraries/FullMath.sol";

contract PriceOracleForTest is IPriceOracle {
    struct Reserves {
        uint256 base;
        uint256 quote;
    }
    mapping(address => mapping(address => Reserves)) public getReserves;

    function setReserve(
        address baseToken,
        address quoteToken,
        uint256 reserveBase,
        uint256 reserveQuote
    ) external {
        getReserves[baseToken][quoteToken] = Reserves(reserveBase, reserveQuote);
    }

    function setupTwap(address amm) external override {
        return;
    }

    function updateAmmTwap(address pair) external override {}

    function quote(
        address baseToken,
        address quoteToken,
        uint256 baseAmount
    ) public view override returns (uint256 quoteAmount, uint8 source) {
        Reserves memory reserves = getReserves[baseToken][quoteToken];
        require(baseAmount > 0, "INSUFFICIENT_AMOUNT");
        require(reserves.base > 0 && reserves.quote > 0, "INSUFFICIENT_LIQUIDITY");
        quoteAmount = (baseAmount * reserves.quote) / reserves.base;
    }

    function quoteFromAmmTwap(address amm, uint256 baseAmount) public view override returns (uint256 quoteAmount) {
        quoteAmount = 0;
    }

    function getIndexPrice(address amm) public view override returns (uint256) {
        address baseToken = IAmm(amm).baseToken();
        address quoteToken = IAmm(amm).quoteToken();
        uint256 baseDecimals = IERC20(baseToken).decimals();
        uint256 quoteDecimals = IERC20(quoteToken).decimals();
        (uint256 quoteAmount, ) = quote(baseToken, quoteToken, 10**baseDecimals);
        return quoteAmount * (10**(18 - quoteDecimals));
    }

    function getMarketPrice(address amm) public view override returns (uint256) {
        
    }

    function getMarkPrice(address amm) public view override returns (uint256 price, bool isIndexPrice) {
        (uint256 baseReserve, uint256 quoteReserve, ) = IAmm(amm).getReserves();
        uint8 baseDecimals = IERC20(IAmm(amm).baseToken()).decimals();
        uint8 quoteDecimals = IERC20(IAmm(amm).quoteToken()).decimals();
        uint256 exponent = uint256(10**(18 + baseDecimals - quoteDecimals));
        price = FullMath.mulDiv(exponent, quoteReserve, baseReserve);
    }

    function getMarkPriceInRatio(
        address amm,
        uint256 quoteAmount,
        uint256 baseAmount
    )
        public
        view
        override
        returns (
            uint256,
            uint256,
            bool
        )
    {
        return (0, 0, false);
    }

    function getMarkPriceAfterSwap(
        address amm,
        uint256 quoteAmount,
        uint256 baseAmount
    ) external view override returns (uint256 price, bool isIndexPrice) {
        return (0, false);
    }

    function getMarkPriceAcc(
        address amm,
        uint8 beta,
        uint256 quoteAmount,
        bool negative
    ) public view override returns (uint256 price) {
        (, uint256 quoteReserve, ) = IAmm(amm).getReserves();
        (uint256 markPrice, ) = getMarkPrice(amm);
        uint256 rvalue = FullMath.mulDiv(markPrice, (2 * quoteAmount * beta) / 100, quoteReserve);
        if (negative) {
            price = markPrice - rvalue;
        } else {
            price = markPrice + rvalue;
        }
    }

    //premiumFraction is (markPrice - indexPrice) / 24h / indexPrice
    function getPremiumFraction(address amm) public view override returns (int256) {
        (uint256 markPriceUint, ) = getMarkPrice(amm);
        int256 markPrice = int256(markPriceUint);
        int256 indexPrice = int256(getIndexPrice(amm));
        require(markPrice > 0 && indexPrice > 0, "PriceOracle.getPremiumFraction: INVALID_PRICE");
        return ((markPrice - indexPrice) * 1e18) / (24 * 3600) / indexPrice;
    }


}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../libraries/Math.sol";
import "../libraries/FullMath.sol";
import "../core/interfaces/uniswapV3/IUniswapV3Pool.sol";
import "../libraries/TickMath.sol";
import "../libraries/V3Oracle.sol";
import "../core/interfaces/IERC20.sol";

contract MockUniswapV3Pool is IUniswapV3Pool {
    using Math for uint256;
    using FullMath for uint256;

    struct Observation {
        // the block timestamp of the observation
        uint32 blockTimestamp;
        // the tick accumulator, i.e. tick * time elapsed since the pool was first initialized
        int56 tickCumulative;
        // the seconds per liquidity, i.e. seconds elapsed / max(1, liquidity) since the pool was first initialized
        uint160 secondsPerLiquidityCumulativeX128;
        // whether or not the observation is initialized
        bool initialized;
    }

    address public immutable override token0;
    address public immutable override token1;
    uint24 public immutable override fee;
    uint128 public override liquidity;
    Observation[65535] public override observations;

    struct Slot0 {
        // the current price
        uint160 sqrtPriceX96;
        // the current tick
        int24 tick;
        // the most-recently updated index of the observations array
        uint16 observationIndex;
        // the current maximum number of observations that are being stored
        uint16 observationCardinality;
        // the next maximum number of observations to store, triggered in observations.write
        uint16 observationCardinalityNext;
        // the current protocol fee as a percentage of the swap fee taken on withdrawal
        // represented as an integer denominator (1/x)%
        uint8 feeProtocol;
        // whether the pool is locked
        bool unlocked;
    }
    Slot0 public override slot0;

    constructor(
        address token0_,
        address token1_,
        uint24 fee_
    ) {
        token0 = token0_;
        token1 = token1_;
        fee = fee_;
    }

    function initialize(uint112 baseReserve, uint112 quoteReserve) external {
        uint160 sqrtPriceX96 = _getSqrtPriceX96(baseReserve, quoteReserve);
        require(slot0.sqrtPriceX96 == 0, 'AI');

        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
        observations[0] = Observation({
            blockTimestamp: _blockTimestamp(),
            tickCumulative: 0,
            secondsPerLiquidityCumulativeX128: 0,
            initialized: true
        });
        slot0 = Slot0({
            sqrtPriceX96: sqrtPriceX96,
            tick: tick,
            observationIndex: 0,
            observationCardinality: 1,
            observationCardinalityNext: 1,
            feeProtocol: 0,
            unlocked: true
        });
    }

    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external override returns (int256 amount0, int256 amount1) {
        if (zeroForOne) {
            IERC20(token1).transfer(recipient, 100);
        } else {
            IERC20(token0).transfer(recipient, 100);
        }
    }

    function setLiquidity(uint128 liquidity_) external {
        liquidity = liquidity_;
    }

    function setSqrtPriceX96(uint112 baseReserve, uint112 quoteReserve) external {
        slot0.sqrtPriceX96 = _getSqrtPriceX96(baseReserve, quoteReserve);
    }

    function writeObservation() external {
        Observation memory last = observations[slot0.observationIndex];

        // early return if we've already written an observation this block
        if (last.blockTimestamp == _blockTimestamp()) return;

        uint16 indexUpdated; 
        uint16 cardinalityUpdated;
        // if the conditions are right, we can bump the cardinality
        if (slot0.observationCardinalityNext > slot0.observationCardinality && slot0.observationIndex == (slot0.observationCardinality - 1)) {
            cardinalityUpdated = slot0.observationCardinalityNext;
        } else {
            cardinalityUpdated = slot0.observationCardinality;
        }

        indexUpdated = (slot0.observationIndex + 1) % cardinalityUpdated;
        observations[indexUpdated] = transform(last, _blockTimestamp(), slot0.tick, liquidity);
        slot0.observationIndex = indexUpdated;
        slot0.observationCardinality = cardinalityUpdated;
    }

    function observe(uint32[] calldata secondsAgos)
        external
        view
        override
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s) {

        tickCumulatives = new int56[](secondsAgos.length);
        secondsPerLiquidityCumulativeX128s = new uint160[](secondsAgos.length);
        for (uint256 i = 0; i < secondsAgos.length; i++) {
            (tickCumulatives[i], secondsPerLiquidityCumulativeX128s[i]) = observeSingle(
                observations,
                _blockTimestamp(),
                secondsAgos[i],
                slot0.tick,
                slot0.observationIndex,
                liquidity,
                slot0.observationCardinality
            );
        }
    }

    function observeSingle(
        Observation[65535] storage self,
        uint32 time,
        uint32 secondsAgo,
        int24 tick,
        uint16 index,
        uint128 liquidity_,
        uint16 cardinality
    ) internal view returns (int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128) {
        if (secondsAgo == 0) {
            Observation memory last = self[index];
            if (last.blockTimestamp != time) last = transform(last, time, tick, liquidity_);
            return (last.tickCumulative, last.secondsPerLiquidityCumulativeX128);
        }

        uint32 target = time - secondsAgo;

        (Observation memory beforeOrAt, Observation memory atOrAfter) =
            getSurroundingObservations(self, time, target, tick, index, liquidity_, cardinality);

        if (target == beforeOrAt.blockTimestamp) {
            // we're at the left boundary
            return (beforeOrAt.tickCumulative, beforeOrAt.secondsPerLiquidityCumulativeX128);
        } else if (target == atOrAfter.blockTimestamp) {
            // we're at the right boundary
            return (atOrAfter.tickCumulative, atOrAfter.secondsPerLiquidityCumulativeX128);
        } else {
            // we're in the middle
            uint32 observationTimeDelta = atOrAfter.blockTimestamp - beforeOrAt.blockTimestamp;
            uint32 targetDelta = target - beforeOrAt.blockTimestamp;
            return (
                beforeOrAt.tickCumulative +
                    ((atOrAfter.tickCumulative - beforeOrAt.tickCumulative) / int56(uint56(observationTimeDelta))) *
                    int56(uint56(targetDelta)),
                beforeOrAt.secondsPerLiquidityCumulativeX128 +
                    uint160(
                        (uint256(
                            atOrAfter.secondsPerLiquidityCumulativeX128 - beforeOrAt.secondsPerLiquidityCumulativeX128
                        ) * targetDelta) / observationTimeDelta
                    )
            );
        }
    }

    function getSurroundingObservations(
        Observation[65535] storage self,
        uint32 time,
        uint32 target,
        int24 tick,
        uint16 index,
        uint128 liquidity_,
        uint16 cardinality
    ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        // optimistically set before to the newest observation
        beforeOrAt = self[index];

        // if the target is chronologically at or after the newest observation, we can early return
        if (lte(time, beforeOrAt.blockTimestamp, target)) {
            if (beforeOrAt.blockTimestamp == target) {
                // if newest observation equals target, we're in the same block, so we can ignore atOrAfter
                return (beforeOrAt, atOrAfter);
            } else {
                // otherwise, we need to transform
                return (beforeOrAt, transform(beforeOrAt, target, tick, liquidity_));
            }
        }

        // now, set before to the oldest observation
        beforeOrAt = self[(index + 1) % cardinality];
        if (!beforeOrAt.initialized) beforeOrAt = self[0];

        // ensure that the target is chronologically at or after the oldest observation
        require(lte(time, beforeOrAt.blockTimestamp, target), 'OLD');

        // if we've reached this point, we have to binary search
        return binarySearch(self, time, target, index, cardinality);
    }

    function binarySearch(
        Observation[65535] storage self,
        uint32 time,
        uint32 target,
        uint16 index,
        uint16 cardinality
    ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        uint256 l = (index + 1) % cardinality; // oldest observation
        uint256 r = l + cardinality - 1; // newest observation
        uint256 i;
        while (true) {
            i = (l + r) / 2;

            beforeOrAt = self[i % cardinality];

            // we've landed on an uninitialized tick, keep searching higher (more recently)
            if (!beforeOrAt.initialized) {
                l = i + 1;
                continue;
            }

            atOrAfter = self[(i + 1) % cardinality];

            bool targetAtOrAfter = lte(time, beforeOrAt.blockTimestamp, target);

            // check if we've found the answer!
            if (targetAtOrAfter && lte(time, target, atOrAfter.blockTimestamp)) break;

            if (!targetAtOrAfter) r = i - 1;
            else l = i + 1;
        }
    }

    function transform(
        Observation memory last,
        uint32 blockTimestamp,
        int24 tick,
        uint128 liquidity_
    ) private pure returns (Observation memory) {
        uint32 delta = blockTimestamp - last.blockTimestamp;
        return
            Observation({
                blockTimestamp: blockTimestamp,
                tickCumulative: last.tickCumulative + int56(tick) * int56(uint56(delta)),
                secondsPerLiquidityCumulativeX128: last.secondsPerLiquidityCumulativeX128 +
                    ((uint160(delta) << 128) / (liquidity_ > 0 ? liquidity_ : 1)),
                initialized: true
            });
    }

    function lte(
        uint32 time,
        uint32 a,
        uint32 b
    ) private pure returns (bool) {
        // if there hasn't been overflow, no need to adjust
        if (a <= time && b <= time) return a <= b;

        uint256 aAdjusted = a > time ? a : a + 2**32;
        uint256 bAdjusted = b > time ? b : b + 2**32;

        return aAdjusted <= bAdjusted;
    }

    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external override {
        uint16 observationCardinalityNextOld = slot0.observationCardinalityNext; // for the event
        for (uint16 i = observationCardinalityNextOld; i < observationCardinalityNext; i++) observations[i].blockTimestamp = 1;
        slot0.observationCardinalityNext = observationCardinalityNext;
    }

    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp); // truncation is desired
    }

    function _getSqrtPriceX96(uint112 baseReserve, uint112 quoteReserve) internal pure returns (uint160) {
        uint256 priceX192 = uint256(quoteReserve).mulDiv(2**192, baseReserve);
        return uint160(priceX192.sqrt());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV3Pool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;

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

    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );

    function liquidity() external view returns (uint128);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function fee() external view returns (uint24);

    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

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
        require(absTick <= uint256(int256(MAX_TICK)), "T");

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
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R");
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Oracle
/// @notice Provides price and liquidity data useful for a wide variety of system designs
/// @dev Instances of stored oracle data, "observations", are collected in the oracle array
/// Every pool is initialized with an oracle array length of 1. Anyone can pay the SSTOREs to increase the
/// maximum length of the oracle array. New slots will be added when the array is fully populated.
/// Observations are overwritten when the full length of the oracle array is populated.
/// The most recent observation is available, independent of the length of the oracle array, by passing 0 to observe()
library V3Oracle {
    struct Observation {
        // the block timestamp of the observation
        uint32 blockTimestamp;
        // the tick accumulator, i.e. tick * time elapsed since the pool was first initialized
        int56 tickCumulative;
        // whether or not the observation is initialized
        bool initialized;
    }

    /// @notice Transforms a previous observation into a new observation, given the passage of time and the current tick and liquidity values
    /// @dev blockTimestamp _must_ be chronologically equal to or greater than last.blockTimestamp, safe for 0 or 1 overflows
    /// @param last The specified observation to be transformed
    /// @param blockTimestamp The timestamp of the new observation
    /// @param tick The active tick at the time of the new observation
    /// @return Observation The newly populated observation
    function transform(
        Observation memory last,
        uint32 blockTimestamp,
        int24 tick
    ) private pure returns (Observation memory) {
        uint32 delta = blockTimestamp - last.blockTimestamp;
        return
            Observation({
                blockTimestamp: blockTimestamp,
                tickCumulative: last.tickCumulative + int56(tick) * int32(delta),
                initialized: true
            });
    }

    function initialize(Observation[65535] storage self, uint32 time)
        internal
        returns (uint16 cardinality, uint16 cardinalityNext)
    {
        self[0] = Observation({
            blockTimestamp: time,
            tickCumulative: 0,
            initialized: true
        });
        return (1, 1);
    }

    function write(
        Observation[65535] storage self,
        uint16 index,
        uint32 blockTimestamp,
        int24 tick,
        uint16 cardinality,
        uint16 cardinalityNext
    ) internal returns (uint16 indexUpdated, uint16 cardinalityUpdated) {
        Observation memory last = self[index];

        // early return if we've already written an observation this block
        if (last.blockTimestamp == blockTimestamp) return (index, cardinality);

        // if the conditions are right, we can bump the cardinality
        if (cardinalityNext > cardinality && index == (cardinality - 1)) {
            cardinalityUpdated = cardinalityNext;
        } else {
            cardinalityUpdated = cardinality;
        }

        indexUpdated = (index + 1) % cardinalityUpdated;
        self[indexUpdated] = transform(last, blockTimestamp, tick);
    }

    function grow(
        Observation[65535] storage self,
        uint16 current,
        uint16 next
    ) internal returns (uint16) {
        require(current > 0, 'I');
        // no-op if the passed next value isn't greater than the current next value
        if (next <= current) return current;
        // store in each slot to prevent fresh SSTOREs in swaps
        // this data will not be used because the initialized boolean is still false
        for (uint16 i = current; i < next; i++) self[i].blockTimestamp = 1;
        return next;
    }

    function lte(
        uint32 time,
        uint32 a,
        uint32 b
    ) private pure returns (bool) {
        // if there hasn't been overflow, no need to adjust
        if (a <= time && b <= time) return a <= b;

        uint256 aAdjusted = a > time ? a : a + 2**32;
        uint256 bAdjusted = b > time ? b : b + 2**32;

        return aAdjusted <= bAdjusted;
    }

    function binarySearch(
        Observation[65535] storage self,
        uint32 time,
        uint32 target,
        uint16 index,
        uint16 cardinality
    ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        uint256 l = (index + 1) % cardinality; // oldest observation
        uint256 r = l + cardinality - 1; // newest observation
        uint256 i;
        while (true) {
            i = (l + r) / 2;

            beforeOrAt = self[i % cardinality];

            // we've landed on an uninitialized tick, keep searching higher (more recently)
            if (!beforeOrAt.initialized) {
                l = i + 1;
                continue;
            }

            atOrAfter = self[(i + 1) % cardinality];

            bool targetAtOrAfter = lte(time, beforeOrAt.blockTimestamp, target);

            // check if we've found the answer!
            if (targetAtOrAfter && lte(time, target, atOrAfter.blockTimestamp)) break;

            if (!targetAtOrAfter) r = i - 1;
            else l = i + 1;
        }
    }

    function getSurroundingObservations(
        Observation[65535] storage self,
        uint32 time,
        uint32 target,
        int24 tick,
        uint16 index,
        uint16 cardinality
    ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        // optimistically set before to the newest observation
        beforeOrAt = self[index];

        // if the target is chronologically at or after the newest observation, we can early return
        if (lte(time, beforeOrAt.blockTimestamp, target)) {
            if (beforeOrAt.blockTimestamp == target) {
                // if newest observation equals target, we're in the same block, so we can ignore atOrAfter
                return (beforeOrAt, atOrAfter);
            } else {
                // otherwise, we need to transform
                return (beforeOrAt, transform(beforeOrAt, target, tick));
            }
        }

        // now, set before to the oldest observation
        beforeOrAt = self[(index + 1) % cardinality];
        if (!beforeOrAt.initialized) beforeOrAt = self[0];

        // ensure that the target is chronologically at or after the oldest observation
        require(lte(time, beforeOrAt.blockTimestamp, target), 'OLD');

        // if we've reached this point, we have to binary search
        return binarySearch(self, time, target, index, cardinality);
    }

    function observeSingle(
        Observation[65535] storage self,
        uint32 time,
        uint32 secondsAgo,
        int24 tick,
        uint16 index,
        uint16 cardinality
    ) internal view returns (int56 tickCumulative) {
        if (secondsAgo == 0) {
            Observation memory last = self[index];
            if (last.blockTimestamp != time) last = transform(last, time, tick);
            return last.tickCumulative;
        }

        uint32 target = time - secondsAgo;

        (Observation memory beforeOrAt, Observation memory atOrAfter) =
            getSurroundingObservations(self, time, target, tick, index, cardinality);

        if (target == beforeOrAt.blockTimestamp) {
            // we're at the left boundary
            return beforeOrAt.tickCumulative;
        } else if (target == atOrAfter.blockTimestamp) {
            // we're at the right boundary
            return atOrAfter.tickCumulative;
        } else {
            // we're in the middle
            uint32 observationTimeDelta = atOrAfter.blockTimestamp - beforeOrAt.blockTimestamp;
            uint32 targetDelta = target - beforeOrAt.blockTimestamp;
            return 
                beforeOrAt.tickCumulative +
                    ((atOrAfter.tickCumulative - beforeOrAt.tickCumulative) / int32(observationTimeDelta)) *
                    int32(targetDelta);
        }
    }
    
    function observe(
        Observation[65535] storage self,
        uint32 time,
        uint32[] memory secondsAgos,
        int24 tick,
        uint16 index,
        uint16 cardinality
    ) internal view returns (int56[] memory tickCumulatives) {
        require(cardinality > 0, 'I');

        tickCumulatives = new int56[](secondsAgos.length);
        for (uint256 i = 0; i < secondsAgos.length; i++) {
            tickCumulatives[i] = observeSingle(
                self,
                time,
                secondsAgos[i],
                tick,
                index,
                cardinality
            );
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IAmm.sol";
import "./interfaces/IPriceOracle.sol";
import "./interfaces/uniswapV3/IUniswapV3Factory.sol";
import "./interfaces/uniswapV3/IUniswapV3Pool.sol";
import "../libraries/FullMath.sol";
import "../libraries/Math.sol";
import "../libraries/TickMath.sol";
import "../libraries/UniswapV3TwapGetter.sol";
import "../libraries/FixedPoint96.sol";
import "../libraries/V3Oracle.sol";
import "../utils/Initializable.sol";

contract PriceOracle is IPriceOracle, Initializable {
    using Math for uint256;
    using FullMath for uint256;
    using V3Oracle for V3Oracle.Observation[65535];

    uint8 public constant priceGap = 10;
    uint16 public constant cardinality = 60;
    uint32 public constant twapInterval = 900; // 15 min

    address public WETH;
    address public v3Factory;
    uint24[3] public v3Fees;

    // baseToken => quoteToken => v3Pool
    mapping(address => mapping(address => address)) public v3Pools;
    mapping(address => V3Oracle.Observation[65535]) public ammObservations;
    mapping(address => uint16) public ammObservationIndex;

    function initialize(address WETH_, address v3Factory_) public initializer {
        WETH = WETH_;
        v3Factory = v3Factory_;
        v3Fees[0] = 500;
        v3Fees[1] = 3000;
        v3Fees[2] = 10000;
    }

    function setupTwap(address amm) external override {
        require(!ammObservations[amm][0].initialized, "PriceOracle.setupTwap: ALREADY_SETUP");
        address baseToken = IAmm(amm).baseToken();
        address quoteToken = IAmm(amm).quoteToken();

        address pool = getTargetPool(baseToken, quoteToken);
        if (pool != address(0)) {
            _setupV3Pool(baseToken, quoteToken, pool);
        } else {
            pool = getTargetPool(baseToken, WETH);
            require(pool != address(0), "PriceOracle.setupTwap: POOL_NOT_FOUND");
            _setupV3Pool(baseToken, WETH, pool);

            pool = getTargetPool(WETH, quoteToken);
            require(pool != address(0), "PriceOracle.setupTwap: POOL_NOT_FOUND");
            _setupV3Pool(WETH, quoteToken, pool);
        }

        ammObservationIndex[amm] = 0;
        ammObservations[amm].initialize(_blockTimestamp());
        ammObservations[amm].grow(1, cardinality);
    }

    function updateAmmTwap(address amm) external override {
        uint160 sqrtPriceX96 = _getSqrtPriceX96(amm);
        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
        uint16 index = ammObservationIndex[amm];
        (uint16 indexUpdated, ) = ammObservations[amm].write(index, _blockTimestamp(), tick, cardinality, cardinality);
        ammObservationIndex[amm] = indexUpdated;
    }

    function quoteFromAmmTwap(address amm, uint256 baseAmount) external view override returns (uint256 quoteAmount) {
        uint160 sqrtPriceX96 = _getSqrtPriceX96(amm);
        uint16 index = ammObservationIndex[amm];
        V3Oracle.Observation memory observation = ammObservations[amm][(index + 1) % cardinality];
        if (!observation.initialized) {
            observation = ammObservations[amm][0];
        }
        uint32 currentTime = _blockTimestamp();
        uint32 delta = currentTime - observation.blockTimestamp;
        if (delta > 0) {
            address _amm = amm;
            uint32 _twapInterval = twapInterval;
            if (delta < _twapInterval) _twapInterval = delta;
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = twapInterval; // from (before)
            secondsAgos[1] = 0; // to (now)
            int56[] memory tickCumulatives = ammObservations[_amm].observe(
                currentTime,
                secondsAgos,
                TickMath.getTickAtSqrtRatio(sqrtPriceX96),
                index,
                cardinality
            );
            // tick(imprecise as it's an integer) to price
            sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                int24((tickCumulatives[1] - tickCumulatives[0]) / int56(uint56(_twapInterval)))
            );
        }
        // priceX96 = token1/token0, this price is scaled by 2^96
        uint256 priceX96 = UniswapV3TwapGetter.getPriceX96FromSqrtPriceX96(sqrtPriceX96);
        quoteAmount = baseAmount.mulDiv(priceX96, FixedPoint96.Q96);
        require(quoteAmount > 0, "PriceOracle.quoteFromAmmTwap: ZERO_AMOUNT");
    }

    function quote(
        address baseToken,
        address quoteToken,
        uint256 baseAmount
    ) public view override returns (uint256 quoteAmount, uint8 source) {
        quoteAmount = quoteSingle(baseToken, quoteToken, baseAmount);
        if (quoteAmount == 0) {
            uint256 wethAmount = quoteSingle(baseToken, WETH, baseAmount);
            quoteAmount = quoteSingle(WETH, quoteToken, wethAmount);
        }
        require(quoteAmount > 0, "PriceOracle.quote: ZERO_AMOUNT");
    }

    // the price is scaled by 1e18. example: 1eth = 2000usdt, price = 2000*1e18
    function getIndexPrice(address amm) public view override returns (uint256) {
        address baseToken = IAmm(amm).baseToken();
        address quoteToken = IAmm(amm).quoteToken();
        uint256 baseDecimals = IERC20(baseToken).decimals();
        uint256 quoteDecimals = IERC20(quoteToken).decimals();
        (uint256 quoteAmount, ) = quote(baseToken, quoteToken, 10**baseDecimals);
        return quoteAmount * (10**(18 - quoteDecimals));
    }

    function getMarketPrice(address amm) public view override returns (uint256) {
        (uint112 baseReserve, uint112 quoteReserve, ) = IAmm(amm).getReserves();
        uint8 baseDecimals = IERC20(IAmm(amm).baseToken()).decimals();
        uint8 quoteDecimals = IERC20(IAmm(amm).quoteToken()).decimals();
        uint256 exponent = uint256(10**(18 + baseDecimals - quoteDecimals));
        return exponent.mulDiv(quoteReserve, baseReserve);
    }

    // the price is scaled by 1e18. example: 1eth = 2000usdt, price = 2000*1e18
    function getMarkPrice(address amm) public view override returns (uint256 price, bool isIndexPrice) {
        price = getMarketPrice(amm);
        uint256 indexPrice = getIndexPrice(amm);
        if (price * 100 >= indexPrice * (100 + priceGap) || price * 100 <= indexPrice * (100 - priceGap)) {
            price = indexPrice;
            isIndexPrice = true;
        }
    }

    function getMarkPriceAfterSwap(
        address amm,
        uint256 quoteAmount,
        uint256 baseAmount
    ) public view override returns (uint256 price, bool isIndexPrice) {
        (uint112 baseReserveBefore, uint112 quoteReserveBefore, ) = IAmm(amm).getReserves();
        address baseToken = IAmm(amm).baseToken();
        address quoteToken = IAmm(amm).quoteToken();
        uint256 baseReserveAfter;
        uint256 quoteReserveAfter;
        if (quoteAmount > 0) {
            uint256[2] memory amounts = IAmm(amm).estimateSwap(quoteToken, baseToken, quoteAmount, 0);
            baseReserveAfter = uint256(baseReserveBefore) - amounts[1];
            quoteReserveAfter = uint256(quoteReserveBefore) + quoteAmount;
        } else {
            uint256[2] memory amounts = IAmm(amm).estimateSwap(baseToken, quoteToken, baseAmount, 0);
            baseReserveAfter = uint256(baseReserveBefore) + baseAmount;
            quoteReserveAfter = uint256(quoteReserveBefore) - amounts[1];
        }

        uint8 baseDecimals = IERC20(baseToken).decimals();
        uint8 quoteDecimals = IERC20(quoteToken).decimals();
        uint256 exponent = uint256(10**(18 + baseDecimals - quoteDecimals));
        price = exponent.mulDiv(quoteReserveAfter, baseReserveAfter);

        address amm_ = amm; // avoid stack too deep
        uint256 indexPrice = getIndexPrice(amm_);
        if (price * 100 >= indexPrice * (100 + priceGap) || price * 100 <= indexPrice * (100 - priceGap)) {
            price = indexPrice;
            isIndexPrice = true;
        }
    }

    // example: 1eth = 2000usdt, 1eth = 1e18, 1usdt = 1e6, price = (1e6/1e18)*1e18
    function getMarkPriceInRatio(
        address amm,
        uint256 quoteAmount,
        uint256 baseAmount
    )
        public
        view
        override
        returns (
            uint256 resultBaseAmount,
            uint256 resultQuoteAmount,
            bool isIndexPrice
        )
    {
        require(quoteAmount == 0 || baseAmount == 0, "PriceOracle.getMarkPriceInRatio: AT_LEAST_ONE_ZERO");
        uint256 markPrice;
        (markPrice, isIndexPrice) = getMarkPrice(amm);
        if (!isIndexPrice) {
            (markPrice, isIndexPrice) = getMarkPriceAfterSwap(amm, quoteAmount, baseAmount);
        }

        uint8 baseDecimals = IERC20(IAmm(amm).baseToken()).decimals();
        uint8 quoteDecimals = IERC20(IAmm(amm).quoteToken()).decimals();
        uint256 ratio;
        if (quoteDecimals > baseDecimals) {
            ratio = markPrice * 10**(quoteDecimals - baseDecimals);
        } else {
            ratio = markPrice / 10**(baseDecimals - quoteDecimals);
        }
        if (quoteAmount > 0) {
            resultBaseAmount = (quoteAmount * 1e18) / ratio;
        } else {
            resultQuoteAmount = (baseAmount * ratio) / 1e18;
        }
    }

    // get user's mark price, return base amount, it's for checking if user's position can be liquidated.
    // price = ( sqrt(markPrice) +/- beta * quoteAmount / sqrt(x*y) )**2
    function getMarkPriceAcc(
        address amm,
        uint8 beta,
        uint256 quoteAmount,
        bool negative
    ) external view override returns (uint256 baseAmount) {
        (uint112 baseReserve, uint112 quoteReserve, ) = IAmm(amm).getReserves();
        require((2 * beta * quoteAmount) / 100 < quoteReserve, "PriceOracle.getMarkPriceAcc: SLIPPAGE_TOO_LARGE");

        (uint256 baseAmount_, , bool isIndexPrice) = getMarkPriceInRatio(amm, quoteAmount, 0);
        if (!isIndexPrice) {
            // markPrice = y/x
            // price = ( sqrt(y/x) +/- beta * quoteAmount / sqrt(x*y) )**2 = (y +/- beta * quoteAmount)**2 / x*y
            // baseAmount = quoteAmount / price = quoteAmount * x * y / (y +/- beta * quoteAmount)**2
            uint256 rvalue = (quoteAmount * beta) / 100;
            uint256 denominator;
            if (negative) {
                denominator = quoteReserve - rvalue;
            } else {
                denominator = quoteReserve + rvalue;
            }
            denominator = denominator * denominator;
            baseAmount = quoteAmount.mulDiv(uint256(baseReserve) * quoteReserve, denominator);
        } else {
            // price = markPrice(1 +/- 2 * beta * quoteAmount / quoteReserve)
            uint256 markPrice = (quoteAmount * 1e18) / baseAmount_;
            uint256 rvalue = markPrice.mulDiv((2 * beta * quoteAmount) / 100, quoteReserve);
            uint256 price;
            if (negative) {
                price = markPrice - rvalue;
            } else {
                price = markPrice + rvalue;
            }
            baseAmount = quoteAmount.mulDiv(1e18, price);
        }
    }

    //premiumFraction is (marketPrice - indexPrice) / 24h / indexPrice, scale by 1e18
    function getPremiumFraction(address amm) external view override returns (int256) {
        uint256 marketPrice = getMarketPrice(amm);
        uint256 indexPrice = getIndexPrice(amm);
        require(marketPrice > 0 && indexPrice > 0, "PriceOracle.getPremiumFraction: INVALID_PRICE");
        return ((int256(marketPrice) - int256(indexPrice)) * 1e18) / (24 * 3600) / int256(indexPrice);
    }

    function quoteSingle(
        address baseToken,
        address quoteToken,
        uint256 baseAmount
    ) public view returns (uint256 quoteAmount) {
        address pool = v3Pools[baseToken][quoteToken];
        if (pool == address(0)) {
            pool = getTargetPool(baseToken, quoteToken);
        }
        if (pool == address(0)) return 0;
        uint160 sqrtPriceX96 = UniswapV3TwapGetter.getSqrtTwapX96(pool, twapInterval);
        // priceX96 = token1/token0, this price is scaled by 2^96
        uint256 priceX96 = UniswapV3TwapGetter.getPriceX96FromSqrtPriceX96(sqrtPriceX96);
        if (baseToken == IUniswapV3Pool(pool).token0()) {
            quoteAmount = baseAmount.mulDiv(priceX96, FixedPoint96.Q96);
        } else {
            quoteAmount = baseAmount.mulDiv(FixedPoint96.Q96, priceX96);
        }
    }

    function getTargetPool(address baseToken, address quoteToken) public view returns (address) {
        // find out the pool with best liquidity as target pool
        address pool;
        address tempPool;
        uint256 poolLiquidity;
        uint256 tempLiquidity;
        for (uint256 i = 0; i < v3Fees.length; i++) {
            tempPool = IUniswapV3Factory(v3Factory).getPool(baseToken, quoteToken, v3Fees[i]);
            if (tempPool == address(0)) continue;
            tempLiquidity = uint256(IUniswapV3Pool(tempPool).liquidity());
            // use the max liquidity pool as index price source
            if (tempLiquidity > poolLiquidity) {
                poolLiquidity = tempLiquidity;
                pool = tempPool;
            }
        }
        return pool;
    }

    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp); // truncation is desired
    }

    function _getSqrtPriceX96(address amm) internal view returns (uint160) {
        (uint112 baseReserve, uint112 quoteReserve, ) = IAmm(amm).getReserves();
        uint256 priceX192 = uint256(quoteReserve).mulDiv(2**192, baseReserve);
        return uint160(priceX192.sqrt());
    }

    function _setupV3Pool(
        address baseToken,
        address quoteToken,
        address pool
    ) internal {
        require(v3Pools[baseToken][quoteToken] != address(0), "PriceOracle._setupV3Pool: POOL_ALREADY_SETUP");
        v3Pools[baseToken][quoteToken] = pool;
        IUniswapV3Pool v3Pool = IUniswapV3Pool(pool);
        (, , , , uint16 cardinalityNext, , ) = v3Pool.slot0();
        if (cardinalityNext < cardinality) {
            IUniswapV3Pool(pool).increaseObservationCardinalityNext(cardinality);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV3Factory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../core/interfaces/uniswapV3/IUniswapV3Pool.sol";
import "./FixedPoint96.sol";
import "./TickMath.sol";
import "./FullMath.sol";

library UniswapV3TwapGetter {
    function getSqrtTwapX96(address uniswapV3Pool, uint32 twapInterval) internal view returns (uint160 sqrtPriceX96) {
        IUniswapV3Pool pool = IUniswapV3Pool(uniswapV3Pool);
        if (twapInterval == 0) {
            // return the current price if twapInterval == 0
            (sqrtPriceX96, , , , , , ) = pool.slot0();
        } else {
            (, , uint16 index, uint16 cardinality, , , ) = pool.slot0();
            (uint32 targetElementTime, , , bool initialized) = pool.observations((index + 1) % cardinality);
            if (!initialized) {
                (targetElementTime, , , ) = pool.observations(0);
            }
            uint32 delta = uint32(block.timestamp) - targetElementTime;
            if (delta == 0) {
                (sqrtPriceX96, , , , , , ) = pool.slot0();
            } else {
                if (delta < twapInterval) twapInterval = delta;
                uint32[] memory secondsAgos = new uint32[](2);
                secondsAgos[0] = twapInterval; // from (before)
                secondsAgos[1] = 0; // to (now)
                (int56[] memory tickCumulatives, ) = pool.observe(secondsAgos);
                // tick(imprecise as it's an integer) to price
                sqrtPriceX96 = TickMath.getSqrtRatioAtTick(
                    int24((tickCumulatives[1] - tickCumulatives[0]) / int56(uint56(twapInterval)))
                );
            }
        }
    }

    function getPriceX96FromSqrtPriceX96(uint160 sqrtPriceX96) internal pure returns (uint256 priceX96) {
        return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IAmm.sol";
import "../utils/Ownable.sol";
import "../libraries/TransferHelper.sol";
import "../libraries/TickMath.sol";
import "../core/interfaces/uniswapV3/IUniswapV3Factory.sol";
import "../core/interfaces/uniswapV3/IUniswapV3Pool.sol";
import "../core/interfaces/uniswapV3/ISwapRouter.sol";
import "../core/interfaces/IWETH.sol";

contract FeeTreasury is Ownable {
    event RatioForStakingChanged(uint8 oldRatio, uint8 newRatio);
    event RewardForStakingChanged(address indexed oldReward, address indexed newReward);
    event RewardForCashbackChanged(address indexed oldReward, address indexed newReward);
    event OperatorChanged(address indexed oldOperator, address indexed newOperator);
    event SettlementIntervalChanged(uint256 oldInterval, uint256 newInterval);
    event DistributeToStaking(
        address indexed rewardForStaking,
        uint256 ethAmount, 
        uint256 usdcAmount,
        uint256 timestamp
    );
    event DistributeToCashback(
        address indexed rewardForCashback, 
        uint256 ethAmount, 
        uint256 usdcAmount,
        uint256 timestamp
    );

    ISwapRouter public v3Router;
    address public v3Factory;
    address public WETH;
    address public USDC;
    address public operator;
    uint24[3] public v3Fees;

    uint8 public ratioForStaking = 33;
    // the Reward contract address for staking
    address public rewardForStaking;
    // the Reward contract address for cashback
    address public rewardForCashback;

    uint256 public settlementInterval = 7*24*3600; // one week
    uint256 public nextSettleTime;

    modifier check() {
        require(msg.sender == operator, "FORBIDDEN");
        require(block.timestamp >= nextSettleTime, "NOT_REACH_TIME");
        _;
    }

    constructor(
        ISwapRouter v3Router_, 
        address USDC_,  
        address operator_, 
        uint256 nextSettleTime_
    ) {
        owner = msg.sender;
        v3Router = v3Router_;
        v3Factory = v3Router.factory();
        WETH = v3Router.WETH9();
        USDC = USDC_;
        operator = operator_;
        nextSettleTime = nextSettleTime_;
        v3Fees[0] = 500;
        v3Fees[1] = 3000;
        v3Fees[2] = 10000;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function setRatioForStaking(uint8 newrRatio) external onlyOwner {
        require(newrRatio <= 100, "OVER_100%");
        emit RatioForStakingChanged(ratioForStaking, newrRatio);
        ratioForStaking = newrRatio;
    }

    function setRewardForStaking(address newReward) external onlyOwner {
        require(newReward != address(0), "ZERO_ADDRESS");
        emit RewardForStakingChanged(rewardForStaking, newReward);
        rewardForStaking = newReward;
    }

    function setRewardForCashback(address newReward) external onlyOwner {
        require(newReward != address(0), "ZERO_ADDRESS");
        emit RewardForCashbackChanged(rewardForCashback, newReward);
        rewardForCashback = newReward;
    }

    function setOperator(address newOperator) external onlyOwner {
        require(newOperator != address(0), "ZERO_ADDRESS");
        emit OperatorChanged(operator, newOperator);
        operator = newOperator;
    }

    function setSettlementInterval(uint256 newInterval) external onlyOwner {
        require(newInterval > 0, "ZERO");
        emit SettlementIntervalChanged(settlementInterval, newInterval);
        settlementInterval = newInterval;
    }

    function batchRemoveLiquidity(address[] memory amms) external check {
        for (uint256 i = 0; i < amms.length; i++) {
            address amm = amms[i];
            IAmm(amm).collectFee();

            uint256 liquidity = IERC20(amm).balanceOf(address(this));
            if (liquidity == 0) continue;
            
            TransferHelper.safeTransfer(amm, amm, liquidity);
            IAmm(amm).burn(address(this));
        }
    }

    function batchSwapToETH(address[] memory tokens) external check {
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0 && token != WETH && token != USDC) {
                // query target pool
                address pool;
                uint256 poolLiquidity;
                for (uint256 j = 0; j < v3Fees.length; j++) {
                    address tempPool = IUniswapV3Factory(v3Factory).getPool(token, WETH, v3Fees[j]);
                    if (tempPool == address(0)) continue;
                    uint256 tempLiquidity = uint256(IUniswapV3Pool(tempPool).liquidity());
                    // use the max liquidity pool as target pool
                    if (tempLiquidity > poolLiquidity) {
                        poolLiquidity = tempLiquidity;
                        pool = tempPool;
                    }
                }

                // swap token to WETH
                uint256 allowance = IERC20(token).allowance(address(this), address(v3Router));
                if (allowance < balance) {
                    IERC20(token).approve(address(v3Router), type(uint256).max);
                }
                ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                    tokenIn: token,
                    tokenOut: WETH,
                    fee: IUniswapV3Pool(pool).fee(),
                    recipient: address(this),
                    amountIn: balance,
                    amountOutMinimum: 1,
                    sqrtPriceLimitX96: token < WETH ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1
                });
                v3Router.exactInputSingle(params);
            }
        }
        uint256 wethBalance = IERC20(WETH).balanceOf(address(this));
        if (wethBalance > 0) IWETH(WETH).withdraw(wethBalance);
    }

    function distribute() external check {
        require(rewardForCashback != address(0), "NOT_FOUND_REWARD_FOR_CASHBACK");
        uint256 ethBalance = address(this).balance;
        uint256 usdcBalance = IERC20(USDC).balanceOf(address(this));

        if (rewardForStaking == address(0)) {
            if (ethBalance > 0) TransferHelper.safeTransferETH(rewardForCashback, ethBalance);
            if (usdcBalance > 0) TransferHelper.safeTransfer(USDC, rewardForCashback, usdcBalance);
            emit DistributeToCashback(rewardForCashback, ethBalance, usdcBalance, block.timestamp);
        } else {
            uint256 ethForStaking = ethBalance * ratioForStaking / 100;
            uint256 ethForCashback = ethBalance - ethForStaking;
            
            uint256 usdcForStaking = usdcBalance * ratioForStaking / 100;
            uint256 usdcForCashback = usdcBalance - usdcForStaking;

            if (ethForStaking > 0) TransferHelper.safeTransferETH(rewardForStaking, ethForStaking);
            if (ethForCashback > 0) TransferHelper.safeTransferETH(rewardForCashback, ethForCashback);
            if (usdcForStaking > 0) TransferHelper.safeTransfer(USDC, rewardForStaking, usdcForStaking);
            if (usdcForCashback > 0) TransferHelper.safeTransfer(USDC, rewardForCashback, usdcForCashback);
            
            emit DistributeToStaking(rewardForStaking, ethForStaking, usdcForStaking, block.timestamp);
            emit DistributeToCashback(rewardForCashback, ethForCashback, usdcForCashback, block.timestamp);
        }
        
        nextSettleTime = nextSettleTime + settlementInterval;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    function factory() external view returns (address);

    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../core/interfaces/IMargin.sol";
import "../core/interfaces/IWETH.sol";

contract MockRouter {
    IMargin public margin;
    IERC20 public baseToken;
    IWETH public WETH;

    constructor(address _baseToken, address _weth) {
        baseToken = IERC20(_baseToken);
        WETH = IWETH(_weth);
    }

    receive() external payable {
        assert(msg.sender == address(WETH)); // only accept ETH via fallback from the WETH contract
    }

    function setMarginContract(address _marginContract) external {
        margin = IMargin(_marginContract);
    }

    function addMargin(address _receiver, uint256 _amount) external {
        baseToken.transferFrom(msg.sender, address(margin), _amount);
        margin.addMargin(_receiver, _amount);
    }

    function removeMargin(uint256 _amount) external {
        margin.removeMargin(msg.sender, msg.sender, _amount);
    }

    function withdrawETH(address quoteToken, uint256 amount) external {
        margin.removeMargin(msg.sender, msg.sender, amount);
        IWETH(WETH).withdraw(amount);
    }

    function closePositionETH(
        address quoteToken,
        uint256 quoteAmount,
        uint256 deadline,
        bool autoWithdraw
    ) external returns (uint256 baseAmount, uint256 withdrawAmount) {
        baseAmount = margin.closePosition(msg.sender, quoteAmount);
        if (autoWithdraw) {
            withdrawAmount = margin.getWithdrawable(msg.sender);
            if (withdrawAmount > 0) {
                margin.removeMargin(msg.sender, msg.sender, withdrawAmount);
                IWETH(WETH).withdraw(withdrawAmount);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";
import "../core/interfaces/IMargin.sol";

interface IERC20Mint {
    function mint(address spender, uint256 amount) external;
}

contract MockFlashAttacker is IERC3156FlashBorrower {
    ERC20FlashMint public baseToken;
    IMargin public margin;
    address public quoteToken;

    enum Action {
        action1,
        action2
    }

    struct FlashData {
        uint256 baseAmount;
        Action action;
    }

    constructor(
        address _token,
        address _margin,
        address _quoteToken
    ) {
        baseToken = ERC20FlashMint(_token);
        margin = IMargin(_margin);
        quoteToken = _quoteToken;
    }

    function onFlashLoan(
        address _initiator,
        address _token,
        uint256 _amount,
        uint256 _fee,
        bytes calldata data
    ) external override returns (bytes32) {
        require(_initiator == address(this), "");
        uint8 long = 0;
        FlashData memory flashData = abi.decode(data, (FlashData));
        if (flashData.action == Action.action1) {
            IERC20(_token).transfer(address(margin), flashData.baseAmount);
            margin.addMargin(address(this), flashData.baseAmount);
            margin.openPosition(address(this), long, flashData.baseAmount * 2);
            margin.closePosition(address(this), flashData.baseAmount * 2);
        } else {
            IERC20(_token).transfer(address(margin), flashData.baseAmount);
            margin.addMargin(address(this), flashData.baseAmount);
            margin.openPosition(address(this), long, flashData.baseAmount * 2);
            margin.removeMargin(address(this), address(this), 1);
        }

        IERC20(_token).approve(address(_token), _amount + _fee);
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    function attack1(uint256 borrow, uint256 baseAmount) public {
        baseToken.flashLoan(
            IERC3156FlashBorrower(this),
            address(baseToken),
            borrow,
            abi.encode(FlashData(baseAmount, Action.action1))
        );
    }

    function attack2(uint256 borrow, uint256 baseAmount) public {
        IERC20Mint(address(baseToken)).mint(address(this), 1000);
        baseToken.flashLoan(
            IERC3156FlashBorrower(this),
            address(baseToken),
            borrow,
            abi.encode(FlashData(baseAmount, Action.action2))
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC3156 FlashBorrower, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../../interfaces/IERC3156.sol";
import "../ERC20.sol";

/**
 * @dev Implementation of the ERC3156 Flash loans extension, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * Adds the {flashLoan} method, which provides flash loan support at the token
 * level. By default there is no fee, but this can be changed by overriding {flashFee}.
 *
 * _Available since v4.1._
 */
abstract contract ERC20FlashMint is ERC20, IERC3156FlashLender {
    bytes32 private constant _RETURN_VALUE = keccak256("ERC3156FlashBorrower.onFlashLoan");

    /**
     * @dev Returns the maximum amount of tokens available for loan.
     * @param token The address of the token that is requested.
     * @return The amont of token that can be loaned.
     */
    function maxFlashLoan(address token) public view override returns (uint256) {
        return token == address(this) ? type(uint256).max - ERC20.totalSupply() : 0;
    }

    /**
     * @dev Returns the fee applied when doing flash loans. By default this
     * implementation has 0 fees. This function can be overloaded to make
     * the flash loan mechanism deflationary.
     * @param token The token to be flash loaned.
     * @param amount The amount of tokens to be loaned.
     * @return The fees applied to the corresponding flash loan.
     */
    function flashFee(address token, uint256 amount) public view virtual override returns (uint256) {
        require(token == address(this), "ERC20FlashMint: wrong token");
        // silence warning about unused variable without the addition of bytecode.
        amount;
        return 0;
    }

    /**
     * @dev Performs a flash loan. New tokens are minted and sent to the
     * `receiver`, who is required to implement the {IERC3156FlashBorrower}
     * interface. By the end of the flash loan, the receiver is expected to own
     * amount + fee tokens and have them approved back to the token contract itself so
     * they can be burned.
     * @param receiver The receiver of the flash loan. Should implement the
     * {IERC3156FlashBorrower.onFlashLoan} interface.
     * @param token The token to be flash loaned. Only `address(this)` is
     * supported.
     * @param amount The amount of tokens to be loaned.
     * @param data An arbitrary datafield that is passed to the receiver.
     * @return `true` is the flash loan was successful.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) public virtual override returns (bool) {
        uint256 fee = flashFee(token, amount);
        _mint(address(receiver), amount);
        require(
            receiver.onFlashLoan(msg.sender, token, amount, fee, data) == _RETURN_VALUE,
            "ERC20FlashMint: invalid return value"
        );
        uint256 currentAllowance = allowance(address(receiver), address(this));
        require(currentAllowance >= amount + fee, "ERC20FlashMint: allowance does not allow refund");
        _approve(address(receiver), address(this), currentAllowance - amount - fee);
        _burn(address(receiver), amount + fee);
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";
import "./IERC3156FlashLender.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";

/**
 * @dev Interface of the ERC3156 FlashLender, as defined in
 * https://eips.ethereum.org/EIPS/eip-3156[ERC-3156].
 *
 * _Available since v4.1._
 */
interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20FlashMint.sol";

contract MockToken is ERC20, ERC20FlashMint {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function flashFee(address token, uint256 amount) public view override returns (uint256) {
        require(token == address(this), "ERC20FlashMint: wrong token");
        return amount / 10;
    }

    receive() external payable {}

    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external payable {
        _burn(msg.sender, msg.value);
        payable(msg.sender).transfer(amount);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function ethBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockQuoteToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockBaseToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    receive() external payable {}

    function deposit() external payable {
        _mint(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external payable {
        _burn(msg.sender, msg.value);
        payable(msg.sender).transfer(amount);
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function ethBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../core/interfaces/IVault.sol";

contract MockAmmOfMargin is ERC20 {
    address public baseToken;
    address public quoteToken;
    address public margin;
    uint112 private baseReserve;
    uint112 private quoteReserve;
    uint32 private blockTimestampLast;
    uint256 public price = 2e9;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function initialize(address baseToken_, address quoteToken_) external {
        baseToken = baseToken_;
        quoteToken = quoteToken_;
    }

    function setMargin(address margin_) external {
        margin = margin_;
    }

    //2000usdc/eth -> 2000*(1e6/1e18)*1e18
    function setPrice(uint256 _price) external {
        price = _price;
    }

    function setReserves(uint112 reserveBase, uint112 reserveQuote) external {
        baseReserve = reserveBase;
        quoteReserve = reserveQuote;
    }

    function getReserves()
        public
        view
        returns (
            uint112 reserveBase,
            uint112 reserveQuote,
            uint32 blockTimestamp
        )
    {
        reserveBase = baseReserve;
        reserveQuote = quoteReserve;
        blockTimestamp = blockTimestampLast;
    }

    function mint(address to)
        external
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        )
    {
        baseAmount = 1000;
        quoteAmount = 1000;
        liquidity = 1000;
        _mint(to, liquidity);
    }

    function deposit(address to, uint256 amount) external {
        IVault(margin).deposit(to, amount);
    }

    function withdraw(
        address user,
        address receiver,
        uint256 amount
    ) external {
        IVault(margin).withdraw(user, receiver, amount);
    }

    function estimateSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external view returns (uint256[2] memory amounts) {
        inputToken = inputToken;
        outputToken = outputToken;
        if (inputToken == baseToken) {
            if (inputAmount != 0) {
                amounts = [0, (inputAmount * price) / 1e18];
            } else {
                amounts = [(outputAmount * 1e18) / price, 0];
            }
        } else {
            if (inputAmount != 0) {
                amounts = [0, (inputAmount * 1e18) / price];
            } else {
                amounts = [(outputAmount * price) / 1e18, 0];
            }
        }
    }

    function swap(
        address trader,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external view returns (uint256[2] memory amounts) {
        inputToken = inputToken;
        outputToken = outputToken;

        if (inputToken == baseToken) {
            if (inputAmount != 0) {
                amounts = [0, (inputAmount * price) / 1e18];
            } else {
                amounts = [(outputAmount * 1e18) / price, 0];
            }
        } else {
            if (inputAmount != 0) {
                amounts = [0, (inputAmount * 1e18) / price];
            } else {
                amounts = [(outputAmount * price) / 1e18, 0];
            }
        }
    }

    function forceSwap(
        address trader,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external {
        if (inputToken == baseToken) {
            baseReserve += uint112(inputAmount);
            quoteReserve -= uint112(outputAmount);
        } else {
            baseReserve -= uint112(outputAmount);
            quoteReserve += uint112(inputAmount);
        }
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockAmm is ERC20 {
    address public baseToken;
    address public quoteToken;
    uint112 private baseReserve;
    uint112 private quoteReserve;
    uint32 private blockTimestampLast;
    uint256 public price = 1;

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function initialize(address baseToken_, address quoteToken_) external {
        baseToken = baseToken_;
        quoteToken = quoteToken_;
    }

    function setPrice(uint256 _price) external {
        price = _price;
    }

    function setReserves(uint112 reserveBase, uint112 reserveQuote) external {
        baseReserve = reserveBase;
        quoteReserve = reserveQuote;
    }

    function getReserves()
        public
        view
        returns (
            uint112 reserveBase,
            uint112 reserveQuote,
            uint32 blockTimestamp
        )
    {
        reserveBase = baseReserve;
        reserveQuote = quoteReserve;
        blockTimestamp = blockTimestampLast;
    }

    function mint(address to)
        external
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        )
    {
        baseAmount = 1000;
        quoteAmount = 1000;
        liquidity = 1000;
        _mint(to, liquidity);
    }

    function estimateSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external view returns (uint256[2] memory amounts) {
        inputToken = inputToken;
        outputToken = outputToken;
        if (inputToken == baseToken) {
            if (inputAmount != 0) {
                amounts = [0, inputAmount * price];
            } else {
                amounts = [outputAmount / price, 0];
            }
        } else {
            if (inputAmount != 0) {
                amounts = [0, inputAmount / price];
            } else {
                amounts = [outputAmount * price, 0];
            }
        }
    }

    function swap(
        address trader,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external view returns (uint256[2] memory amounts) {
        inputToken = inputToken;
        outputToken = outputToken;

        if (inputToken == baseToken) {
            if (inputAmount != 0) {
                amounts = [0, inputAmount * price];
            } else {
                amounts = [outputAmount / price, 0];
            }
        } else {
            if (inputAmount != 0) {
                amounts = [0, inputAmount / price];
            } else {
                amounts = [outputAmount * price, 0];
            }
        }
    }

    function forceSwap(
        address trader,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        assembly {
            size := extcodesize(account)
        }
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../extensions/ERC721Enumerable.sol";
import "../extensions/ERC721Burnable.sol";
import "../extensions/ERC721Pausable.sol";
import "../../../access/AccessControlEnumerable.sol";
import "../../../utils/Context.sol";
import "../../../utils/Counters.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC721PresetMinterPauserAutoId is
    Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable
{
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * Token URIs will be autogenerated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../core/interfaces/IERC20.sol";

contract NftSquid is ERC721PresetMinterPauserAutoId, Ownable {
    uint256 private constant HALF_YEAR = 180 days;
    uint256 private constant MULTIPLIER = 1e18;
    uint256 internal constant BURN_DISCOUNT = 40;
    uint256 internal constant BONUS_PERPAX = 1500 * 10**18;
    uint256 internal constant BASE_AMOUNT = 3000 * 10**18;
    // uint256 public constant price = 0.45 ether;
    uint256 public constant price = 0.001 ether; // for test

    uint256 public vaultAmount;
    uint256 public squidStartTime;
    uint256 public nftStartTime;
    uint256 public nftEndTime;

    uint256 public remainOwners;
    uint256 public constant MAX_PLAYERS = 4560;

    uint256 public id;
    address public token;
    uint256 public totalEth;

    // reserved for whitelist address
    mapping(address => bool) public reserved;
    // left reserved that not claim yet
    uint16 public reservedCount;
    // if turn to false, then all reserved will become invalid
    bool public reservedOn = true;
    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;

    event Mint(address indexed owner, uint256 tokenId);
    event Burn(uint256 tokenId, uint256 withdrawAmount, address indexed sender);

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        address _token,
        uint256 _nftStartTime,
        uint256 _nftEndTime
    ) ERC721PresetMinterPauserAutoId(_name, _symbol, _baseTokenURI) {
        token = _token;
        nftStartTime = _nftStartTime;
        nftEndTime = _nftEndTime;
        _mint(msg.sender, MAX_PLAYERS);
    }

    function setReservedOff() external onlyOwner {
        reservedOn = false;
    }

    function addToReserved(address[] memory list) external onlyOwner {
        require(block.timestamp < nftEndTime, "NFT_SALE_TIME_END");
        for (uint16 i = 0; i < list.length; i++) {
            if (!reserved[list[i]]) {
                reserved[list[i]] = true;
                reservedCount++;
            }
        }
    }

    function removeFromReserved(address[] memory list) external onlyOwner {
        require(block.timestamp < nftEndTime, "NFT_SALE_TIME_END");
        for (uint16 i = 0; i < list.length; i++) {
            if (reserved[list[i]]) {
                delete reserved[list[i]];
                reservedCount--;
            }
        }
    }

    // The time players are able to burn
    function setSquidStartTime(uint256 _squidStartTime) external onlyOwner {
        require(_squidStartTime > nftEndTime, "SQUID_START_TIME_MUST_BIGGER_THAN_NFT_END_TIME");
        squidStartTime = _squidStartTime; //unix time
    }  
     function setNFTStartTime(uint256 _nftStartTime) external onlyOwner {
        require(_nftStartTime > block.timestamp, "NFT_START_TIME_MUST_BIGGER_THAN_NOW");
        nftStartTime = _nftStartTime; //unix time
    }  
     function setNFTEndTime(uint256 _nftEndTime) external onlyOwner {
        require(_nftEndTime > nftStartTime, "NFT_END_TIME_MUST_AFTER_START_TIME");
        nftEndTime = _nftEndTime; //unix time
    }

    // player can buy before startTime
    function claimApeXNFT(uint256 userSeed) external payable {
        require(msg.value == price, "value not match");
        totalEth = totalEth + price;
        uint256 randRaw = random(userSeed);
        uint256 rand = getUnusedRandom(randRaw);
        _mint(msg.sender, rand);
        _setClaimed(rand);
        emit Mint(msg.sender, rand);
        require(block.timestamp <= nftEndTime  , "GAME_IS_ALREADY_END");
        require(block.timestamp >= nftStartTime  , "GAME_IS_NOT_BEGIN");
        id++;
        remainOwners++;
        require(remainOwners <= MAX_PLAYERS, "SOLD_OUT");
        if (reservedOn) {
            require(remainOwners <= MAX_PLAYERS - reservedCount, "SOLD_OUT_NORMAL");
            if (reserved[msg.sender]) {
                delete reserved[msg.sender];
                reservedCount--;
            }
        }
    }

    // player burn their nft
    function burnAndEarn(uint256 tokenId) external {
        uint256 _remainOwners = remainOwners;
        require(_remainOwners > 0, "ALL_BURNED");
        require(ownerOf(tokenId) == msg.sender, "NO_AUTHORITY");
        require(squidStartTime != 0 && block.timestamp >= squidStartTime, "GAME_IS_NOT_BEGIN");
        _burn(tokenId);
        (uint256 withdrawAmount, uint256 bonus) = _calWithdrawAmountAndBonus();

        if (_remainOwners > 1) {
            vaultAmount = vaultAmount + BONUS_PERPAX - bonus;
        }

        remainOwners = _remainOwners - 1;
        emit Burn(tokenId, withdrawAmount, msg.sender);
        require(IERC20(token).transfer(msg.sender, withdrawAmount));
    }

    function random(uint256 userSeed) public view returns (uint256) {
        return
            uint256(keccak256(abi.encodePacked(block.timestamp, block.number, userSeed, blockhash(block.number)))) %
            MAX_PLAYERS;
    }

    function getUnusedRandom(uint256 randomNumber) internal view returns (uint256) {
        while (isClaimed(randomNumber)) {
            randomNumber++;
            if (randomNumber == MAX_PLAYERS) {
                randomNumber = randomNumber % MAX_PLAYERS;
            }
        }

        return randomNumber;
    }

    function isClaimed(uint256 index) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    function withdrawETH(address to) external onlyOwner {
        payable(to).transfer(address(this).balance);
    }

    function withdrawERC20Token(address token_, address to, uint256 amount) external onlyOwner returns (bool) {
        uint256 balance = IERC20(token_).balanceOf(address(this));
        require(balance >= amount, "NOT_ENOUGH_BALANCE");
        require(IERC20(token_).transfer(to, amount));
        return true;
    }

    function calWithdrawAmountAndBonus() external view returns (uint256 withdrawAmount, uint256 bonus) {
        return _calWithdrawAmountAndBonus();
    }

    function _calWithdrawAmountAndBonus() internal view returns (uint256 withdrawAmount, uint256 bonus) {
        uint256 endTime = squidStartTime + HALF_YEAR;
        uint256 nowTime = block.timestamp;
        uint256 diffTime = nowTime < endTime ? nowTime - squidStartTime : endTime - squidStartTime;

        // the last one is special
        if (remainOwners == 1) {
            withdrawAmount = BASE_AMOUNT + BONUS_PERPAX + vaultAmount;
            return (withdrawAmount, BONUS_PERPAX + vaultAmount);
        }

        // (t/6*5000+ vaultAmount/N)60%
        bonus =
            ((diffTime * BONUS_PERPAX * (100 - BURN_DISCOUNT)) /
                HALF_YEAR +
                (vaultAmount * (100 - BURN_DISCOUNT)) /
                remainOwners) /
            100;

        // drain the pool
        if (bonus > vaultAmount + BONUS_PERPAX) {
            bonus = vaultAmount + BONUS_PERPAX;
        }

        withdrawAmount = BASE_AMOUNT + bonus;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../core/interfaces/IERC20.sol";

contract GenesisNFT is ERC721PresetMinterPauserAutoId, Ownable {
  
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI
    ) ERC721PresetMinterPauserAutoId(_name, _symbol, _baseTokenURI) {
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../core/interfaces/IERC20.sol";

contract ApeXVIPNFT is ERC721PresetMinterPauserAutoId, Ownable {
    event Claimed(address indexed user, uint256 amount);
    event StartTimeChanged(uint256 startTime, uint256 cliffTime, uint256 endTime);

    uint256 public totalEth;
    uint256 public remainOwners = 20;
    uint256 public id;

    mapping(address => bool) public whitelist;
    mapping(address => bool) public buyer;

    uint256 public startTime;
    uint256 public cliffTime;
    uint256 public endTime;
    // every buyer get
    uint256 public totalAmount = 1041666 * 10**18;
    // nft per price 
    // uint256 public price = 50 ether;
    uint256 public price = 0.01 ether; // for test
    mapping(address => uint256) public claimed;
    address public token;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseTokenURI,
        address _token,
        uint256 _startTime,
        uint256 _cliff,
        uint256 _duration
    ) ERC721PresetMinterPauserAutoId(_name, _symbol, _baseTokenURI) {
        token = _token;
        startTime = _startTime;
        endTime = _startTime + _duration;
        cliffTime = _startTime + _cliff;
        _mint(msg.sender, id);
        id++;
    }

    function setStartTime(uint256 _startTime, uint256 cliff, uint256 duration) external onlyOwner {
        require(duration > cliff, "CLIFF < DURATION");
        startTime = _startTime;
        cliffTime = _startTime + cliff;
        endTime = _startTime + duration;
        emit StartTimeChanged(startTime, cliffTime, endTime);
    }

    function setTotalAmount(uint256 _totalAmount) external onlyOwner {
        totalAmount = _totalAmount;
    }

    function addManyToWhitelist(address[] calldata _beneficiaries) external onlyOwner {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

    function removeFromWhitelist(address _beneficiary) public onlyOwner {
        _removeFromWhitelist(_beneficiary);
    }

    function claimApeXVIPNFT() external payable isWhitelisted(msg.sender) {
        require(msg.value == price, "VALUE_NOT_MATCH");
        totalEth = totalEth + price;
        require(remainOwners > 0, "SOLD_OUT");
        _mint(msg.sender, id);
        require(block.timestamp <= startTime, "PLEASE_CLAIM_NFT_BEFORE_RELEASE_BEGIN");
        id++;
        remainOwners--;
        _removeFromWhitelist(msg.sender);
        buyer[msg.sender] = true;
    }

    function claimAPEX() external {
        address user = msg.sender;
        require(buyer[user], "ONLY_VIP_NFT_BUYER_CAN_CLAIM");

        uint256 unClaimed = claimableAmount(user);
        require(unClaimed > 0, "unClaimed_AMOUNT_MUST_BIGGER_THAN_ZERO");

        claimed[user] = claimed[user] + unClaimed;

        IERC20(token).transfer(user, unClaimed);

        emit Claimed(user, unClaimed);
    }

    function withdrawETH(address to) external onlyOwner {
        payable(to).transfer(address(this).balance);
    }

    function withdrawERC20Token(address token_, address to, uint256 amount) external onlyOwner returns (bool) {
        uint256 balance = IERC20(token_).balanceOf(address(this));
        require(balance >= amount, "NOT_ENOUGH_BALANCE");
        require(IERC20(token_).transfer(to, amount));
        return true;
    }

    function claimableAmount(address user) public view returns (uint256) {
        return vestedAmount() - (claimed[user]);
    }

    function vestedAmount() public view returns (uint256) {
        if (block.timestamp < cliffTime) {
            return 0;
        } else if (block.timestamp >= endTime) {
            return totalAmount;
        } else {
            return (totalAmount * (block.timestamp - cliffTime)) / (endTime - cliffTime);
        }
    }

    function _removeFromWhitelist(address _beneficiary) internal {
        whitelist[_beneficiary] = false;
    }

    modifier isWhitelisted(address _beneficiary) {
        require(whitelist[_beneficiary]);
        _;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract ApeXToken is ERC20Votes, Ownable {
    event AddMinter(address minter);
    event RemoveMinter(address minter);

    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet private minters;
    uint256 public constant initTotalSupply = 1_000_000_000e18; // 1 billion

    // modifier for mint function
    modifier onlyMinter() {
        require(isMinter(msg.sender), "ApeXToken: CALLER_IS_NOT_THE_MINTER");
        _;
    }

    constructor() ERC20Permit("") ERC20("ApeX Token", "APEX") {
        _mint(msg.sender, initTotalSupply);
    }

    function mint(address to, uint256 amount) external onlyMinter returns (bool) {
        _mint(to, amount);
        return true;
    }

    function addMinter(address minter) external onlyOwner returns (bool) {
        require(minter != address(0), "ApeXToken.addMinter: ZERO_ADDRESS");
        emit AddMinter(minter);
        return EnumerableSet.add(minters, minter);
    }

    function removeMinter(address minter) external onlyOwner returns (bool) {
        require(minter != address(0), "ApeXToken.delMinter: ZERO_ADDRESS");
        emit RemoveMinter(minter);
        return EnumerableSet.remove(minters, minter);
    }

    function isMinter(address account) public view returns (bool) {
        return EnumerableSet.contains(minters, account);
    }

    function getMinterLength() external view returns (uint256) {
        return EnumerableSet.length(minters);
    }

    function getMinter(uint256 index) external view onlyOwner returns (address) {
        require(index <= EnumerableSet.length(minters) - 1, "ApeXToken.getMinter: OUT_OF_BOUNDS");
        return EnumerableSet.at(minters, index);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./draft-ERC20Permit.sol";
import "../../../utils/math/Math.sol";
import "../../../utils/math/SafeCast.sol";
import "../../../utils/cryptography/ECDSA.sol";

/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^224^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * NOTE: If exact COMP compatibility is required, use the {ERC20VotesComp} variant of this module.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 * Enabling self-delegation can easily be done by overriding the {delegates} function. Keep in mind however that this
 * will significantly increase the base gas cost of transfers.
 *
 * _Available since v4.2._
 */
abstract contract ERC20Votes is ERC20Permit {
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to an account's voting power.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view virtual returns (address) {
        return _delegates[account];
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual {
        return _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
        return _delegate(signer, delegatee);
    }

    /**
     * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= _maxSupply(), "ERC20Votes: total supply risks overflowing votes");

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        _moveVotingPower(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCast.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCast.toUint32(block.number), votes: SafeCast.toUint224(newWeight)}));
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

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
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
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
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
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
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
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
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
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
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
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
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
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
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
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
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
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
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
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
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
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
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

contract VeAPEX is ERC20Votes {
    address public stakingPoolFactory;
    event Mint(address, uint256);
    event Burn(address, uint256);

    constructor(address _stakingPoolFactory) ERC20("veApeX token", "veApeX") ERC20Permit("veApeX token") {
        stakingPoolFactory = _stakingPoolFactory;
    }

    function mint(address account, uint256 amount) external {
        require(msg.sender == stakingPoolFactory, "veApeX.mint: NO_AUTHORITY");
        _mint(account, amount);

        emit Mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        require(msg.sender == stakingPoolFactory, "veApeX.burn: NO_AUTHORITY");
        _burn(account, amount);

        emit Burn(account, amount);
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert("veApeX.approve: veToken is non-transferable");
    }

    function transfer(address, uint256) public pure override returns (bool) {
        revert("veApeX.transfer: veToken is non-transferable");
    }

    function transferFrom(
        address,
        address,
        uint256
    ) public pure override returns (bool) {
        revert("veApeX.transferFrom: veToken is non-transferable");
    }

    function decreaseAllowance(address, uint256) public pure override returns (bool) {
        revert("veApeX.decreaseAllowance: veToken is non-transferable");
    }

    function increaseAllowance(address, uint256) public pure override returns (bool) {
        revert("veApeX.increaseAllowance: veToken is non-transferable");
    }

    function getChainId() external view returns (uint256) {
        return block.chainid;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../core/interfaces/IAmm.sol";
import "../libraries/SignedMath.sol";

contract MockMargin  {

     using SignedMath for int256;
    address public config;
    address public amm;
    address public baseToken;
    address public quoteToken;
    uint256 public reserve;
    int256 public netpostion ;
    uint256 public totalpostion ;
    constructor() {
    }

    function initialize(
        address baseToken_,
        address quoteToken_,
        address amm_,
        address config_
    ) external  {
        baseToken = baseToken_;
        quoteToken = quoteToken_;
        amm = amm_;
        config = config_ ;
    }


    function totalPosition() external view returns (uint256 ){
        return netpostion.abs()*7;
    }
    function netPosition() external view returns (int256 ){
        return netpostion;
    }
    function setNetPosition(int256 newNetpositon ) external  returns (int256 ){
      
       netpostion = newNetpositon;
       return netpostion; 
    }


    function deposit(address user, uint256 amount) external  {
        require(msg.sender == amm, "Margin.deposit: REQUIRE_AMM");
        require(amount > 0, "Margin.deposit: AMOUNT_IS_ZERO");
        uint256 balance = IERC20(baseToken).balanceOf(address(this));
        require(amount <= balance - reserve, "Margin.deposit: INSUFFICIENT_AMOUNT");

        reserve = reserve + amount;
    }

    // need for testing
    function swapProxy(
        address trader,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external returns (uint256[2] memory amounts) {
      IAmm(amm).swap(trader, inputToken, outputToken, inputAmount, outputAmount);
    }

       function withdraw(
        address user,
        address receiver,
        uint256 amount
    ) external   {
        require(msg.sender == amm, "Margin.withdraw: REQUIRE_AMM");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import "../core/interfaces/IAmm.sol";
import "../core/LiquidityERC20.sol";
import "../core/interfaces/IERC20.sol";

contract MyAmm is IAmm, LiquidityERC20  {
    uint256 public constant override MINIMUM_LIQUIDITY = 10**3;

    address public override factory;
    address public override config;
    address public override baseToken;
    address public override quoteToken;
    address public override margin;

    uint256 public override price0CumulativeLast;
    uint256 public override price1CumulativeLast;

    uint256 public override lastPrice;

    uint112 private baseReserve;
    uint112 private quoteReserve;
    uint32 private blockTimestampLast;

    constructor() {
        factory = msg.sender;
    }

    // only factory can call this function
    function initialize(
        address baseToken_,
        address quoteToken_,
        address margin_
    ) external override {
        baseToken = baseToken_;
        quoteToken = quoteToken_;
        margin = margin_;
    }

    function setReserves(uint112 reserveBase, uint112 reserveQuote) external {
        baseReserve = reserveBase;
        quoteReserve = reserveQuote;
    }

    function mint(address to)
        external override
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        ) {
            _mint(to, 10000);
        }

    function burn(address to)
        external override
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        ) {
            IERC20(baseToken).transfer(to, 100);
        }

    // only binding margin can call this function
    function swap(
        address trader,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external override returns (uint256[2] memory amounts) {

    }

    // only binding margin can call this function
    function forceSwap(
        address trader,
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external override {

    }

    function rebase() external override returns (uint256 quoteReserveAfter) {

    }

    function collectFee() external override returns (bool) {
        
    }

    function getReserves()
        external
        view override
        returns (
            uint112 reserveBase,
            uint112 reserveQuote,
            uint32 blockTimestamp
        ) 
    {
        reserveBase = baseReserve;
        reserveQuote = quoteReserve;
        blockTimestamp = blockTimestampLast;
    }

    function estimateSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external view override returns (uint256[2] memory amounts) {

    }

    function getFeeLiquidity() external override view returns (uint256) {

    }

    function getTheMaxBurnLiquidity() external override view returns (uint256 maxLiquidity) {

    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../core/interfaces/uniswapV3/ISwapRouter.sol";

contract MockSwapRouter is ISwapRouter {
    address public override WETH9;
    address public override factory;

    constructor(address WETH9_, address factory_) {
        WETH9 = WETH9_;
        factory = factory_;
    }
    
    function exactInputSingle(ExactInputSingleParams calldata params) external payable override returns (uint256 amountOut) {
        
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IBondPriceOracle.sol";
import "./interfaces/IBondPool.sol";
import "../core/interfaces/uniswapV3/IUniswapV3Factory.sol";
import "../core/interfaces/uniswapV3/IUniswapV3Pool.sol";
import "../libraries/FullMath.sol";
import "../libraries/UniswapV3TwapGetter.sol";
import "../libraries/FixedPoint96.sol";
import "../utils/Initializable.sol";

contract BondPriceOracle is IBondPriceOracle, Initializable {
    using FullMath for uint256;

    address public apeX;
    address public WETH;
    address public v3Factory;
    uint24[3] public v3Fees;

    uint16 public constant cardinality = 24;
    uint32 public constant twapInterval = 86400; // 24 hour
    
    // baseToken => v3Pool
    mapping(address => address) public v3Pools; // baseToken-WETH Pool in UniswapV3

    function initialize(address apeX_, address WETH_, address v3Factory_) public initializer {
        apeX = apeX_;
        WETH = WETH_;
        v3Factory = v3Factory_;
        v3Fees[0] = 500;
        v3Fees[1] = 3000;
        v3Fees[2] = 10000;
        setupTwap(apeX);
    }

    function setupTwap(address baseToken) public override {
        require(baseToken != address(0), "BondPriceOracle.setupTwap: ZERO_ADDRESS");
        if (baseToken == WETH) return;
        if (v3Pools[baseToken] != address(0)) return;
        // find out the pool with best liquidity as target pool
        address pool;
        address tempPool;
        uint256 poolLiquidity;
        uint256 tempLiquidity;
        for (uint256 i = 0; i < v3Fees.length; i++) {
            tempPool = IUniswapV3Factory(v3Factory).getPool(baseToken, WETH, v3Fees[i]);
            if (tempPool == address(0)) continue;
            tempLiquidity = uint256(IUniswapV3Pool(tempPool).liquidity());
            // use the max liquidity pool as index price source
            if (tempLiquidity > poolLiquidity) {
                poolLiquidity = tempLiquidity;
                pool = tempPool;
            }
        }
        require(pool != address(0), "PriceOracle.setupTwap: POOL_NOT_FOUND");
        v3Pools[baseToken] = pool;

        IUniswapV3Pool v3Pool = IUniswapV3Pool(pool);
        (, , , , uint16 cardinalityNext, , ) = v3Pool.slot0();
        if (cardinalityNext < cardinality) {
            IUniswapV3Pool(pool).increaseObservationCardinalityNext(cardinality);
        }
    }

    function quote(
        address baseToken,
        uint256 baseAmount
    ) public view override returns (uint256 apeXAmount) {
        if (baseToken == WETH) {
            address pool = v3Pools[apeX];
            uint160 sqrtPriceX96 = UniswapV3TwapGetter.getSqrtTwapX96(pool, twapInterval);
            // priceX96 = token1/token0, this price is scaled by 2^96
            uint256 priceX96 = UniswapV3TwapGetter.getPriceX96FromSqrtPriceX96(sqrtPriceX96);
            if (baseToken == IUniswapV3Pool(pool).token0()) {
                apeXAmount = baseAmount.mulDiv(priceX96, FixedPoint96.Q96);
            } else {
                apeXAmount = baseAmount.mulDiv(FixedPoint96.Q96, priceX96);
            }
        } else {
            address pool = v3Pools[baseToken];
            require(pool != address(0), "PriceOracle.quote: POOL_NOT_FOUND");
            uint160 sqrtPriceX96 = UniswapV3TwapGetter.getSqrtTwapX96(pool, twapInterval);
            // priceX96 = token1/token0, this price is scaled by 2^96
            uint256 priceX96 = UniswapV3TwapGetter.getPriceX96FromSqrtPriceX96(sqrtPriceX96);
            uint256 wethAmount;
            if (baseToken == IUniswapV3Pool(pool).token0()) {
                wethAmount = baseAmount.mulDiv(priceX96, FixedPoint96.Q96);
            } else {
                wethAmount = baseAmount.mulDiv(FixedPoint96.Q96, priceX96);
            }

            pool = v3Pools[apeX];
            sqrtPriceX96 = UniswapV3TwapGetter.getSqrtTwapX96(pool, twapInterval);
            // priceX96 = token1/token0, this price is scaled by 2^96
            priceX96 = UniswapV3TwapGetter.getPriceX96FromSqrtPriceX96(sqrtPriceX96);
            if (WETH == IUniswapV3Pool(pool).token0()) {
                apeXAmount = wethAmount.mulDiv(priceX96, FixedPoint96.Q96);
            } else {
                apeXAmount = wethAmount.mulDiv(FixedPoint96.Q96, priceX96);
            }
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../core/interfaces/uniswapV3/IUniswapV3Factory.sol";

contract MockUniswapV3Factory is IUniswapV3Factory {
    mapping(address => mapping(address => mapping(uint24 => address))) public override getPool;

    function setPool(
        address tokenA,
        address tokenB,
        uint24 fee,
        address pool
    ) external {
        getPool[tokenA][tokenB][fee] = pool;
        getPool[tokenB][tokenA][fee] = pool;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
import "../bonding/interfaces/IBondPriceOracle.sol";

contract MockBondPriceOracle is IBondPriceOracle {
    function setupTwap(address baseToken) external override {

    }

    function quote(address baseToken, uint256 baseAmount) external view override returns (uint256 apeXAmount) {
        return baseAmount * 100;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./FullMath.sol";

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint::mul: overflow');
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(uq112x112 memory self, int256 y) internal pure returns (int256) {
        uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
        require(z < 2**255, 'FixedPoint::muli: overflow');
        return y < 0 ? -int256(z) : int256(z);
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(upper <= type(uint112).max, 'FixedPoint::muluq: upper overflow');

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) + uppers_lowero + uppero_lowers + (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= type(uint224).max, 'FixedPoint::muluq: sum overflow');

        return uq112x112(uint224(sum));
    }

    // divide a UQ112x112 by a UQ112x112, returning a UQ112x112
    function divuq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        require(other._x > 0, 'FixedPoint::divuq: division by zero');
        if (self._x == other._x) {
            return uq112x112(uint224(Q112));
        }
        if (self._x <= type(uint144).max) {
            uint256 value = (uint256(self._x) << RESOLUTION) / other._x;
            require(value <= type(uint224).max, 'FixedPoint::divuq: overflow');
            return uq112x112(uint224(value));
        }

        uint256 result = FullMath.mulDiv(Q112, self._x, other._x);
        require(result <= type(uint224).max, 'FixedPoint::divuq: overflow');
        return uq112x112(uint224(result));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // can be lossy
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= type(uint144).max) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= type(uint224).max, 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= type(uint224).max, 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint::reciprocal: reciprocal of zero');
        require(self._x != 1, 'FixedPoint::reciprocal: overflow');
        return uq112x112(uint224(Q224 / self._x));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../core/interfaces/uniswapV2/IUniswapV2Pair.sol";
import "./FixedPoint.sol";

library V2Oracle {
    struct Observation {
        uint256 timestamp;
        uint256 price0Cumulative;
        uint256 price1Cumulative;
    }

    // returns the index of the observation corresponding to the given timestamp
    function observationIndexOf(uint256 timestamp, uint256 periodSize, uint16 granularity) internal pure returns (uint16 index) {
        uint256 epochPeriod = timestamp / periodSize;
        return uint16(epochPeriod % granularity);
    }

    // returns the observation from the oldest epoch (at the beginning of the window) relative to the current time
    function getFirstObservationInWindow(Observation[] storage self, uint256 periodSize, uint16 granularity) internal view returns (Observation storage firstObservation) {
        uint16 observationIndex = observationIndexOf(block.timestamp, periodSize, granularity);
        // no overflow issue. if observationIndex + 1 overflows, result is still zero.
        uint16 firstObservationIndex = (observationIndex + 1) % granularity;
        firstObservation = self[firstObservationIndex];
    }


    // update the cumulative price for the observation at the current timestamp. each observation is updated at most
    // once per epoch period.
    function update(Observation[] storage self, address pair, uint256 periodSize, uint16 granularity) internal {
        // populate the array with empty observations (first call only)
        for (uint256 i = self.length; i < granularity; i++) {
            self.push();
        }

        // get the observation for the current period
        uint16 observationIndex = observationIndexOf(block.timestamp, periodSize, granularity);
        Observation memory observation = self[observationIndex];

        // we only want to commit updates once per period (i.e. windowSize / granularity)
        uint timeElapsed = block.timestamp - observation.timestamp;
        if (timeElapsed > periodSize) {
            (uint256 price0Cumulative, uint256 price1Cumulative,) = currentCumulativePrices(pair);
            observation.timestamp = block.timestamp;
            observation.price0Cumulative = price0Cumulative;
            observation.price1Cumulative = price1Cumulative;
            self[observationIndex] = observation;
        }
    }

    // given the cumulative prices of the start and end of a period, and the length of the period, compute the average
    // price in terms of how much amount out is received for the amount in
    function computeAmountOut(
        uint256 priceCumulativeStart, uint256 priceCumulativeEnd,
        uint256 timeElapsed, uint256 amountIn
    ) private pure returns (uint256 amountOut) {
        // overflow is desired.
        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
            uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
        );
        FixedPoint.uq144x112 memory amountOut144x112 = FixedPoint.mul(priceAverage, amountIn);
        amountOut = FixedPoint.decode144(amountOut144x112);
    }

    // returns the amount out corresponding to the amount in for a given token using the moving average over the time
    // range [now - [windowSize, windowSize - periodSize * 2], now]
    // update must have been called for the bucket corresponding to timestamp `now - windowSize`
    function consult(
        Observation[] storage self, 
        address pair, 
        address tokenIn, 
        address tokenOut, 
        uint256 amountIn, 
        uint256 windowSize, 
        uint256 periodSize, 
        uint16 granularity
    ) internal view returns (uint256 amountOut) {
        Observation memory firstObservation = getFirstObservationInWindow(self, periodSize, granularity);

        uint timeElapsed = block.timestamp - firstObservation.timestamp;
        require(timeElapsed <= windowSize, 'V2Oracle: MISSING_HISTORICAL_OBSERVATION');
        // should never happen.
        require(timeElapsed >= windowSize - periodSize * 2, 'V2Oracle: UNEXPECTED_TIME_ELAPSED');

        (uint256 price0Cumulative, uint256 price1Cumulative,) = currentCumulativePrices(pair);
        (address token0,) = sortTokens(tokenIn, tokenOut);

        if (token0 == tokenIn) {
            return computeAmountOut(firstObservation.price0Cumulative, price0Cumulative, timeElapsed, amountIn);
        } else {
            return computeAmountOut(firstObservation.price1Cumulative, price1Cumulative, timeElapsed, amountIn);
        }
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = uint32(block.timestamp % 2 ** 32);
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'V2Oracle: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'V2Oracle: ZERO_ADDRESS');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function totalSupply() external view returns (uint256);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint256);
    function price1CumulativeLast() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IConfig.sol";
import "../utils/Ownable.sol";

contract Config is IConfig, Ownable {
    address public override priceOracle;

    uint8 public override beta = 120; // 50-200，50 means 0.5
    uint256 public override maxCPFBoost = 10; // default 10
    uint256 public override rebasePriceGap = 3; //0-100 , if 5 means 5%
    uint256 public override rebaseInterval = 900; // in seconds
    uint256 public override tradingSlippage = 5; //0-100, if 5 means 5%
    uint256 public override initMarginRatio = 800; //if 1000, means margin ratio >= 10%
    uint256 public override liquidateThreshold = 10000; //if 10000, means debt ratio < 100%
    uint256 public override liquidateFeeRatio = 100; //if 100, means liquidator bot get 1% as fee
    uint256 public override feeParameter = 11; // 100 * (1/fee-1)
    uint256 public override lpWithdrawThresholdForNet = 10; // 1-100
    uint256 public override lpWithdrawThresholdForTotal = 50; // 

    mapping(address => bool) public override routerMap;
    mapping(address => bool) public override inEmergency;

    constructor() {
        owner = msg.sender;
    }

    function setMaxCPFBoost(uint256 newMaxCPFBoost) external override onlyOwner {
        emit SetMaxCPFBoost(maxCPFBoost, newMaxCPFBoost);
        maxCPFBoost = newMaxCPFBoost;
    }

    function setPriceOracle(address newOracle) external override onlyOwner {
        require(newOracle != address(0), "Config: ZERO_ADDRESS");
        emit PriceOracleChanged(priceOracle, newOracle);
        priceOracle = newOracle;
    }

    function setRebasePriceGap(uint256 newGap) external override onlyOwner {
        require(newGap > 0 && newGap < 100, "Config: ZERO_GAP");
        emit RebasePriceGapChanged(rebasePriceGap, newGap);
        rebasePriceGap = newGap;
    }

    function setRebaseInterval(uint256 interval) external override onlyOwner {
        emit RebaseIntervalChanged(rebaseInterval, interval);
        rebaseInterval = interval;
    }

    function setTradingSlippage(uint256 newTradingSlippage) external override onlyOwner {
        require(newTradingSlippage > 0 && newTradingSlippage < 100, "Config: TRADING_SLIPPAGE_RANGE_ERROR");
        emit TradingSlippageChanged(tradingSlippage, newTradingSlippage);
        tradingSlippage = newTradingSlippage;
    }

    function setInitMarginRatio(uint256 marginRatio) external override onlyOwner {
        require(marginRatio >= 100, "Config: INVALID_MARGIN_RATIO");
        emit SetInitMarginRatio(initMarginRatio, marginRatio);
        initMarginRatio = marginRatio;
    }

    function setLiquidateThreshold(uint256 threshold) external override onlyOwner {
        require(threshold > 9000 && threshold <= 10000, "Config: INVALID_LIQUIDATE_THRESHOLD");
        emit SetLiquidateThreshold(liquidateThreshold, threshold);
        liquidateThreshold = threshold;
    } 

    function setLiquidateFeeRatio(uint256 feeRatio) external override onlyOwner {
        require(feeRatio > 0 && feeRatio <= 2000, "Config: INVALID_LIQUIDATE_FEE_RATIO");
        emit SetLiquidateFeeRatio(liquidateFeeRatio, feeRatio);
        liquidateFeeRatio = feeRatio;
    }

    function setFeeParameter(uint256 newFeeParameter) external override onlyOwner {
        emit SetFeeParameter(feeParameter, newFeeParameter);
        feeParameter = newFeeParameter;
    }
   
    function setLpWithdrawThresholdForNet(uint256 newLpWithdrawThresholdForNet) external override onlyOwner {
        require(lpWithdrawThresholdForNet >= 1 && lpWithdrawThresholdForNet <= 100, "Config: INVALID_LIQUIDATE_THRESHOLD_FOR_NET");
        emit SetLpWithdrawThresholdForNet(lpWithdrawThresholdForNet, newLpWithdrawThresholdForNet);
        lpWithdrawThresholdForNet = newLpWithdrawThresholdForNet;
    }
    
      function setLpWithdrawThresholdForTotal(uint256 newLpWithdrawThresholdForTotal) external override onlyOwner {
       // require(lpWithdrawThresholdForTotal >= 1 && lpWithdrawThresholdForTotal <= 100, "Config: INVALID_LIQUIDATE_THRESHOLD_FOR_TOTAL");
        emit SetLpWithdrawThresholdForTotal(lpWithdrawThresholdForTotal, newLpWithdrawThresholdForTotal);
        lpWithdrawThresholdForTotal = newLpWithdrawThresholdForTotal;
    }
    
    function setBeta(uint8 newBeta) external override onlyOwner {
        require(newBeta >= 50 && newBeta <= 200, "Config: INVALID_BETA");
        emit SetBeta(beta, newBeta);
        beta = newBeta;
    }

    function registerRouter(address router) external override onlyOwner {
        require(router != address(0), "Config: ZERO_ADDRESS");
        require(!routerMap[router], "Config: REGISTERED");
        routerMap[router] = true;

        emit RouterRegistered(router);
    }

    function unregisterRouter(address router) external override onlyOwner {
        require(router != address(0), "Config: ZERO_ADDRESS");
        require(routerMap[router], "Config: UNREGISTERED");
        delete routerMap[router];

        emit RouterUnregistered(router);
    }

    function setEmergency(address router) external override onlyOwner {
        require(routerMap[router], "Config: UNREGISTERED");
        inEmergency[router] = true;
        emit SetEmergency(router);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IPCVTreasury.sol";
import "./interfaces/IPCVPolicy.sol";
import "../core/interfaces/IERC20.sol";
import "../libraries/TransferHelper.sol";
import "../utils/Ownable.sol";

///@notice PCVTreasury contract manager all PCV(Protocol Controlled Value) assets
///@dev apeXToken for bonding is need to be transferred into this contract before bonding really setup
contract PCVTreasury is IPCVTreasury, Ownable {
    address public immutable override apeXToken;
    mapping(address => bool) public override isLiquidityToken;
    mapping(address => bool) public override isBondPool;

    constructor(address apeXToken_) {
        owner = msg.sender;
        apeXToken = apeXToken_;
    }

    function addLiquidityToken(address lpToken) external override onlyOwner {
        require(lpToken != address(0), "PCVTreasury.addLiquidityToken: ZERO_ADDRESS");
        require(!isLiquidityToken[lpToken], "PCVTreasury.addLiquidityToken: ALREADY_ADDED");
        isLiquidityToken[lpToken] = true;
        emit NewLiquidityToken(lpToken);
    }

    function addBondPool(address pool) external override onlyOwner {
        require(pool != address(0), "PCVTreasury.addBondPool: ZERO_ADDRESS");
        require(!isBondPool[pool], "PCVTreasury.addBondPool: ALREADY_ADDED");
        isBondPool[pool] = true;
        emit NewBondPool(pool);
    }

    function deposit(
        address lpToken,
        uint256 amountIn,
        uint256 payout
    ) external override {
        require(isBondPool[msg.sender], "PCVTreasury.deposit: FORBIDDEN");
        require(isLiquidityToken[lpToken], "PCVTreasury.deposit: NOT_LIQUIDITY_TOKEN");
        require(amountIn > 0, "PCVTreasury.deposit: ZERO_AMOUNT_IN");
        require(payout > 0, "PCVTreasury.deposit: ZERO_PAYOUT");
        uint256 apeXBalance = IERC20(apeXToken).balanceOf(address(this));
        require(payout <= apeXBalance, "PCVTreasury.deposit: NOT_ENOUGH_APEX");
        TransferHelper.safeTransferFrom(lpToken, msg.sender, address(this), amountIn);
        TransferHelper.safeTransfer(apeXToken, msg.sender, payout);
        emit Deposit(msg.sender, lpToken, amountIn, payout);
    }

    /// @notice Call this function can withdraw specified lp token to a policy contract
    /// @param lpToken The lp token address want to be withdraw
    /// @param policy The policy contract address to receive the lp token
    /// @param amount Withdraw amount of lp token
    /// @param data Other data want to send to the policy
    function withdraw(
        address lpToken,
        address policy,
        uint256 amount,
        bytes calldata data
    ) external override onlyOwner {
        require(isLiquidityToken[lpToken], "PCVTreasury.deposit: NOT_LIQUIDITY_TOKEN");
        require(policy != address(0), "PCVTreasury.deposit: ZERO_ADDRESS");
        require(amount > 0, "PCVTreasury.deposit: ZERO_AMOUNT");
        uint256 balance = IERC20(lpToken).balanceOf(address(this));
        require(amount <= balance, "PCVTreasury.deposit: NOT_ENOUGH_BALANCE");
        TransferHelper.safeTransfer(lpToken, policy, amount);
        IPCVPolicy(policy).execute(lpToken, amount, data);
        emit Withdraw(lpToken, policy, amount);
    }

    /// @notice left apeXToken in this contract can be granted out by owner
    /// @param to the address receive the apeXToken
    /// @param amount the amount want to be granted
    function grantApeX(address to, uint256 amount) external override onlyOwner {
        require(to != address(0), "PCVTreasury.grantApeX: ZERO_ADDRESS");
        require(amount > 0, "PCVTreasury.grantApeX: ZERO_AMOUNT");
        uint256 balance = IERC20(apeXToken).balanceOf(address(this));
        require(amount <= balance, "PCVTreasury.grantApeX: NOT_ENOUGH_BALANCE");
        TransferHelper.safeTransfer(apeXToken, to, amount);
        emit ApeXGranted(to, amount);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IPCVPolicy {
    function execute(address lpToken, uint256 amount, bytes calldata data) external;
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "../bonding/interfaces/IPCVPolicy.sol";

contract MockPCVPolicy is IPCVPolicy {
    function execute(
        address lpToken_,
        uint256 amount,
        bytes calldata data
    ) external override {}
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./Ownable.sol";

abstract contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;
    mapping(address => bool) public operator; //have access to mint/burn

    function addManyWhitelist(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = true;
        }
    }

    function removeManyWhitelist(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = false;
        }
    }

    function addOperator(address account) external onlyOwner {
        _addOperator(account);
    }

    function removeOperator(address account) external onlyOwner {
        require(operator[account], "whitelist.removeOperator: NOT_OPERATOR");
        operator[account] = false;
    }

    function _addOperator(address account) internal {
        require(!operator[account], "whitelist.addOperator: ALREADY_OPERATOR");
        operator[account] = true;
    }

    modifier onlyOperator() {
        require(operator[msg.sender], "whitelist: NOT_IN_OPERATOR");
        _;
    }

    modifier operatorOrWhitelist() {
        require(operator[msg.sender] || whitelist[msg.sender], "whitelist: NOT_IN_OPERATOR_OR_WHITELIST");
        _;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../core/interfaces/IERC20.sol";
import "../utils/Whitelist.sol";

contract EsAPEX is IERC20, Whitelist {
    string public constant override name = "esApeX Token";
    string public constant override symbol = "esApeX";
    uint8 public constant override decimals = 18;

    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    constructor(address _stakingPoolFactory) {
        owner = msg.sender;
        _addOperator(_stakingPoolFactory);
    }

    function mint(address to, uint256 value) external onlyOperator returns (bool) {
        _mint(to, value);
        return true;
    }

    function burn(address from, uint256 value) external onlyOperator returns (bool) {
        _burn(from, value);
        return true;
    }

    function transfer(address to, uint256 value) external override operatorOrWhitelist returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override operatorOrWhitelist returns (bool) {
        uint256 currentAllowance = allowance[from][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= value, "ERC20: transfer amount exceeds allowance");
            allowance[from][msg.sender] = currentAllowance - value;
        }
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function _mint(address to, uint256 value) internal {
        totalSupply = totalSupply + value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from] - value;
        totalSupply = totalSupply - value;
        emit Transfer(from, address(0), value);
    }

    function _approve(
        address _owner,
        address spender,
        uint256 value
    ) private {
        allowance[_owner][spender] = value;
        emit Approval(_owner, spender, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) private {
        uint256 fromBalance = balanceOf[from];
        require(fromBalance >= value, "ERC20: transfer amount exceeds balance");
        balanceOf[from] = fromBalance - value;
        balanceOf[to] = balanceOf[to] + value;
        emit Transfer(from, to, value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../staking/EsAPEX.sol";

contract MockEsApeX is EsAPEX {
    constructor(address _stakingPoolFactory) EsAPEX(_stakingPoolFactory) {}

    function setFactory(address f) external {
        _addOperator(f);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../core/interfaces/IERC20.sol";
import "./MerkleProof.sol";
import "./interfaces/IMerkleDistributor.sol";

/// @notice use for claim reward
contract MerkleDistributor is IMerkleDistributor {
    address public immutable override token;
    bytes32 public immutable override merkleRoot;

    // This is a packed array of booleans.
    mapping(uint256 => uint256) private claimedBitMap;
    address public owner;

    /// @param token_  the token will be distributed to users;
    /// @param merkleRoot_ the merkle root generated by all user reward info
    constructor(address token_, bytes32 merkleRoot_)  {
        token = token_;
        merkleRoot = merkleRoot_;
        owner = msg.sender;
    }

    /// @notice check user whether claimed
    /// @param index check user index  in reward list or not
    function isClaimed(uint256 index) public view override returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function _setClaimed(uint256 index) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[claimedWordIndex] = claimedBitMap[claimedWordIndex] | (1 << claimedBitIndex);
    }

    /// @notice  user  claimed  reward with proof 
    /// @param index user index in reward list
    /// @param account user address
    /// @param amount  user reward amount
    /// @param merkleProof  user merkelProof ,generate by merkel.js
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata merkleProof
    ) external override {
        require(!isClaimed(index), "MerkleDistributor: Drop already claimed.");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "MerkleDistributor: Invalid proof.");

        // Mark it claimed and send the token.
        _setClaimed(index);
        require(IERC20(token).transfer(account, amount), "MerkleDistributor: Transfer failed.");

        emit Claimed(index, account, amount);
    }

    /// @notice  owner withdraw the rest token
    function claimRestTokens(address to ) public returns (bool) {
        // only owner
        require(msg.sender == owner);
        require(IERC20(token).balanceOf(address(this)) >= 0);
        require(IERC20(token).transfer(to, IERC20(token).balanceOf(address(this))));
        return true;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

// Allows anyone to claim a token if they exist in a merkle root.
interface IMerkleDistributor {
    // Returns the address of the token distributed by this contract.
    function token() external view returns (address);
    // Returns the merkle root of the merkle tree containing account balances available to claim.
    function merkleRoot() external view returns (bytes32);
    // Returns true if the index has been marked claimed.
    function isClaimed(uint256 index) external view returns (bool);
    // Claim the given amount of the token to the given address. Reverts if the inputs are invalid.
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) external;

    // This event is triggered whenever a call to #claim succeeds.
    event Claimed(uint256 index, address account, uint256 amount);
}