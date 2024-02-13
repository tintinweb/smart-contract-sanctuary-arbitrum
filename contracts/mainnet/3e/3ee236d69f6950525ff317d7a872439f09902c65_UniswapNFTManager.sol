// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {ERC20, SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {Borrower, IManager} from "aloe-ii-core/Borrower.sol";
import {Factory} from "aloe-ii-core/Factory.sol";

import {IUniswapPositionNFT} from "../interfaces/IUniswapPositionNFT.sol";

contract UniswapNFTManager is IManager {
    using SafeTransferLib for ERC20;

    Factory public immutable FACTORY;

    address public immutable BORROWER_NFT;

    IUniswapPositionNFT public immutable UNISWAP_NFT;

    constructor(Factory factory, address borrowerNft, IUniswapPositionNFT uniswapNft) {
        FACTORY = factory;
        BORROWER_NFT = borrowerNft;
        UNISWAP_NFT = uniswapNft;
    }

    function callback(bytes calldata data, address owner, uint208) external override returns (uint208 positions) {
        // We cast `msg.sender` as a `Borrower`, but it could really be anything. DO NOT TRUST!
        Borrower borrower = Borrower(payable(msg.sender));

        // Need to check that `msg.sender` is really a borrower and that its owner is `BORROWER_NFT`
        // in order to be sure that incoming `data` is in the expected format
        require(FACTORY.isBorrower(msg.sender) && owner == BORROWER_NFT, "Aloe: bad caller");

        // Now `owner` is the true owner of the borrower
        owner = address(bytes20(data[:20]));

        // The ID of the NFT to which liquidity will be added/removed
        uint256 tokenId;
        // The position's lower tick
        int24 lower;
        // The position's upper tick
        int24 upper;
        // The change in the NFT's liquidity. Negative values move NFT-->Borrower, positives do the opposite
        int128 liquidity;
        (tokenId, lower, upper, liquidity, positions) = abi.decode(data[20:], (uint256, int24, int24, int128, uint208));

        // move position from NonfungiblePositionManager to Borrower
        if (liquidity < 0) {
            // safety checks since this contract will be approved to manager users' positions
            require(owner == UNISWAP_NFT.ownerOf(tokenId));

            _withdrawFromNFT(tokenId, uint128(-liquidity), msg.sender);
            borrower.uniswapDeposit(lower, upper, uint128(uint256(uint128(-liquidity)) * 999 / 1000));
        }
        // move position from Borrower to NonfungiblePositionManager (position must exist already)
        else {
            ERC20 token0 = borrower.TOKEN0();
            ERC20 token1 = borrower.TOKEN1();

            (uint256 burned0, uint256 burned1, , ) = borrower.uniswapWithdraw(
                lower,
                upper,
                uint128(liquidity),
                address(this)
            );

            token0.safeApprove(address(UNISWAP_NFT), burned0);
            token1.safeApprove(address(UNISWAP_NFT), burned1);
            UNISWAP_NFT.increaseLiquidity(
                IUniswapPositionNFT.IncreaseLiquidityParams({
                    tokenId: tokenId,
                    amount0Desired: burned0,
                    amount1Desired: burned1,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                })
            );

            token0.safeTransfer(owner, token0.balanceOf(address(this)));
            token1.safeTransfer(owner, token1.balanceOf(address(this)));
        }
    }

    function _withdrawFromNFT(uint256 tokenId, uint128 liquidity, address recipient) private {
        UNISWAP_NFT.decreaseLiquidity(
            IUniswapPositionNFT.DecreaseLiquidityParams({
                tokenId: tokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            })
        );

        UNISWAP_NFT.collect(
            IUniswapPositionNFT.CollectParams({
                tokenId: tokenId,
                recipient: recipient,
                amount0Max: type(uint128).max,
                amount1Max: type(uint128).max
            })
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {ImmutableArgs} from "clones-with-immutable-args/ImmutableArgs.sol";
import {FixedPointMathLib as SoladyMath} from "solady/utils/FixedPointMathLib.sol";
import {ERC20, SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IUniswapV3MintCallback} from "v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import {IUniswapV3Pool} from "v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {TERMINATING_CLOSE_FACTOR} from "./libraries/constants/Constants.sol";
import {BalanceSheet, AuctionAmounts, Assets, Prices} from "./libraries/BalanceSheet.sol";
import {LiquidityAmounts} from "./libraries/LiquidityAmounts.sol";
import {extract} from "./libraries/Positions.sol";
import {TickMath} from "./libraries/TickMath.sol";

import {Factory} from "./Factory.sol";
import {Lender} from "./Lender.sol";
import {VolatilityOracle} from "./VolatilityOracle.sol";

interface ILiquidator {
    receive() external payable;

    /**
     * @notice Transfers `amounts.out0` and `amounts.out1` to the liquidator with the expectation that they'll
     * transfer `amounts.repay0` and `amounts.repay1` to the appropriate `Lender`s, executing swaps if necessary.
     * The liquidator can keep leftover funds as a reward.
     * @param data Encoded parameters that were passed to `Borrower.liquidate`
     * @param caller The address that called `Borrower.liquidate`
     * @param amounts The key amounts involved in the liquidation
     */
    function callback(bytes calldata data, address caller, AuctionAmounts memory amounts) external;
}

interface IManager {
    /**
     * @notice Gives the `IManager` full control of the `Borrower`. Called within `Borrower.modify`.
     * @dev In most cases, you'll want to verify that `msg.sender` is, in fact, a `Borrower` using
     * `factory.isBorrower(msg.sender)`.
     * @param data Encoded parameters that were passed to `Borrower.modify`
     * @param owner The owner of the `Borrower`
     * @param positions The `Borrower`'s current Uniswap positions. You can convert them to an array using
     * `Positions.extract`
     * @return Updated positions, encoded using `Positions.zip`. Return 0 if you don't wish to make any changes.
     */
    function callback(bytes calldata data, address owner, uint208 positions) external returns (uint208);
}

/// @title Borrower
/// @author Aloe Labs, Inc.
/// @dev "Test everything; hold fast what is good." - 1 Thessalonians 5:21
contract Borrower is IUniswapV3MintCallback {
    using SoladyMath for uint256;
    using SafeTransferLib for ERC20;

    /**
     * @notice Emitted when the account gets `warn`ed. The liquidation incentive will be 0 for 5 minutes,
     * giving the account owner time to regain health on their own. After this `LIQUIDATION_GRACE_PERIOD`,
     * the incentive starts increasing (following the Dutch Auction curve in `BalanceSheet`).
     * @dev Simply regaining health is not enough. To clear the warning, you must replenish the `ante` and
     * call `modify`.
     */
    event Warn();

    /// @notice Emitted when the account gets `liquidate`d
    event Liquidate();

    enum State {
        Ready,
        Locked,
        InModifyCallback
    }

    uint256 private constant SLOT0_MASK_POSITIONS = 0x000000000000ffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 private constant SLOT0_MASK_USERSPACE = 0x000000000000ffffffffffffffff000000000000000000000000000000000000; // prettier-ignore
    uint256 private constant SLOT0_MASK_AUCTION   = 0x00ffffffffff0000000000000000000000000000000000000000000000000000; // prettier-ignore
    uint256 private constant SLOT0_MASK_STATE     = 0x7f00000000000000000000000000000000000000000000000000000000000000; // prettier-ignore
    uint256 private constant SLOT0_DIRT           = 0x8000000000000000000000000000000000000000000000000000000000000000; // prettier-ignore

    /// @notice The factory that created this contract
    Factory public immutable FACTORY;

    /// @notice The oracle to use for prices and implied volatility
    VolatilityOracle public immutable ORACLE;

    /// @notice The Uniswap pair in which this `Borrower` can manage positions
    IUniswapV3Pool public immutable UNISWAP_POOL;

    /// @notice The first token of the Uniswap pair
    ERC20 public immutable TOKEN0;

    /// @notice The second token of the Uniswap pair
    ERC20 public immutable TOKEN1;

    /// @notice The lender of `TOKEN0`
    Lender public immutable LENDER0;

    /// @notice The lender of `TOKEN1`
    Lender public immutable LENDER1;

    /**
     * @notice The `Borrower`'s only mutable storage. Lowest 144 bits store the lower/upper bounds of up to 3 Uniswap
     * positions, encoded by `Positions.zip`. Next 64 bits are unused within the `Borrower` and available to users as
     * "free" storage － no additional sstore's. These 208 bits (144 + 64) are passed to `IManager.callback`, and get
     * updated when the callback returns a non-zero value. The next 40 bits are either 0 or the warning time. The
     * highest 8 bits represent the current `State` enum, plus 128. We add 128 (i.e. set the highest bit to 1) so that
     * the slot is always non-zero, even in the absence of Uniswap positions － this saves gas.
     */
    uint256 public slot0;

    modifier onlyInModifyCallback() {
        require(slot0 & SLOT0_MASK_STATE == uint256(State.InModifyCallback) << 248);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(VolatilityOracle oracle, IUniswapV3Pool pool, Lender lender0, Lender lender1) {
        FACTORY = Factory(msg.sender);
        ORACLE = oracle;
        UNISWAP_POOL = pool;
        LENDER0 = lender0;
        LENDER1 = lender1;

        TOKEN0 = lender0.asset();
        TOKEN1 = lender1.asset();
    }

    receive() external payable {}

    function owner() public pure returns (address) {
        return ImmutableArgs.addr();
    }

    /*//////////////////////////////////////////////////////////////
                           MAIN ENTRY POINTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Warns the borrower that they're about to be liquidated
     * @param oracleSeed The indices of `UNISWAP_POOL.observations` where we start our search for
     * the 30-minute-old (lowest 16 bits) and 60-minute-old (next 16 bits) observations when getting
     * TWAPs. If any of the highest 8 bits are set, we fallback to onchain binary search.
     */
    function warn(uint40 oracleSeed) external {
        uint256 slot0_ = slot0;
        // Essentially `slot0.state == State.Ready && slot0.warnTime == 0`
        require(slot0_ & (SLOT0_MASK_STATE | SLOT0_MASK_AUCTION) == 0);

        // Fetch prices from oracle
        (Prices memory prices, , , uint208 ante) = getPrices(oracleSeed);
        // Tally assets
        Assets memory assets = _getAssets(slot0_, prices);
        // Fetch liabilities from lenders
        (uint256 liabilities0, uint256 liabilities1) = getLiabilities();
        // Ensure only unhealthy accounts get warned and liquidated
        require(!BalanceSheet.isHealthy(prices, assets, liabilities0, liabilities1), "Aloe: healthy");

        // Start auction
        slot0 = slot0_ | (block.timestamp << 208);
        emit Warn();

        SafeTransferLib.safeTransferETH(msg.sender, address(this).balance.min(ante / 4));
    }

    /**
     * @notice Clears the warning state if the account is healthy and has a full ante
     * @dev If you bring the account back to health via a `modify` call, the warning state is cleared
     * automatically. However, if borrowing is paused and `modify` is restricted, you may want to repay
     * the `Lender`(s) directly and use this to clear the warning.
     * @param oracleSeed The indices of `UNISWAP_POOL.observations` where we start our search for
     * the 30-minute-old (lowest 16 bits) and 60-minute-old (next 16 bits) observations when getting
     * TWAPs. If any of the highest 8 bits are set, we fallback to onchain binary search.
     */
    function clear(uint40 oracleSeed) external payable {
        uint256 slot0_ = slot0;
        // Essentially `slot0.state == State.Ready && slot0.warnTime > 0`
        require(slot0_ & SLOT0_MASK_STATE == 0 && slot0_ & SLOT0_MASK_AUCTION > 0);

        // Fetch prices from oracle
        (Prices memory prices, , , uint208 ante) = getPrices(oracleSeed);
        // Tally assets
        Assets memory assets = _getAssets(slot0_, prices);
        // Fetch liabilities from lenders
        (uint256 liabilities0, uint256 liabilities1) = getLiabilities();
        // Ensure the warning can only be cleared for healthy accounts with replenished ante
        require(address(this).balance >= ante, "Aloe: conditions");
        require(BalanceSheet.isHealthy(prices, assets, liabilities0, liabilities1), "Aloe: unhealthy");

        // End auction
        slot0 = slot0_ & ~SLOT0_MASK_AUCTION;
    }

    /* solhint-disable code-complexity */
    /**
     * @notice Liquidates the borrower, using all available assets to pay down liabilities. `callee` must
     * transfer at least `amounts.repay0` and `amounts.repay1` to `LENDER0` and `LENDER1`, respectively.
     * `amounts.out0` and `amounts.out1` start at 0 and increase over time. Once their value exceeds what
     * must be repaid, the excess acts as a liquidation incentive.
     * @dev The amounts out are 0 for the entirety of the `LIQUIDATION_GRACE_PERIOD`. They start rising
     * afterwards, reaching 105% of the repay value after 5 minutes and 112% after 55 minutes.
     * @param callee The smart contract responsible for swapping and repaying
     * @param data Encoded parameters that get forwarded to `callee`
     * @param closeFactor The fraction of liabilities to repay, expressed in basis points
     * @param oracleSeed The indices of `UNISWAP_POOL.observations` where we start our search for
     * the 30-minute-old (lowest 16 bits) and 60-minute-old (next 16 bits) observations when getting
     * TWAPs. If any of the highest 8 bits are set, we fallback to onchain binary search.
     */
    function liquidate(ILiquidator callee, bytes calldata data, uint256 closeFactor, uint40 oracleSeed) external {
        require(0 < closeFactor && closeFactor <= 10000, "Aloe: close");

        uint256 slot0_ = slot0;
        // Essentially `slot0.state == State.Ready && slot0.warnTime > 0`
        require(slot0_ & SLOT0_MASK_STATE == 0 && slot0_ & SLOT0_MASK_AUCTION > 0);
        slot0 = slot0_ | (uint256(State.Locked) << 248);

        // Withdraw all Uniswap positions
        _uniswapWithdraw(slot0_);

        // Fetch prices from oracle
        (Prices memory prices, , , ) = getPrices(oracleSeed);
        // Tally assets
        (uint256 assets0, uint256 assets1) = (TOKEN0.balanceOf(address(this)), TOKEN1.balanceOf(address(this)));
        // Fetch liabilities from lenders
        (uint256 liabilities0, uint256 liabilities1) = getLiabilities();
        // Sanity check
        {
            (uint160 sqrtPriceX96, , , , , , ) = UNISWAP_POOL.slot0();
            require(prices.a < sqrtPriceX96 && sqrtPriceX96 < prices.b);
        }

        AuctionAmounts memory amounts = BalanceSheet.computeAuctionAmounts(
            prices.c,
            assets0,
            assets1,
            liabilities0,
            liabilities1,
            BalanceSheet.auctionTime((slot0_ & SLOT0_MASK_AUCTION) >> 208),
            closeFactor
        );

        if (amounts.out0 > 0) TOKEN0.safeTransfer(address(callee), amounts.out0);
        if (amounts.out1 > 0) TOKEN1.safeTransfer(address(callee), amounts.out1);

        callee.callback(data, msg.sender, amounts);

        if (amounts.repay0 > 0) LENDER0.repay(amounts.repay0, address(this));
        if (amounts.repay1 > 0) LENDER1.repay(amounts.repay1, address(this));

        if (closeFactor == 10000) {
            // Everything was repaid → no need to `warn` again → can pay out remaining ETH as incentive
            SafeTransferLib.safeTransferETH(payable(callee), address(this).balance);
            // End auction since account is definitely healthy
            slot0_ &= ~SLOT0_MASK_AUCTION;
        } else if (closeFactor > TERMINATING_CLOSE_FACTOR) {
            // End auction if account is healthy
            if (
                BalanceSheet.isHealthy(
                    prices,
                    assets0 - amounts.out0,
                    assets1 - amounts.out1,
                    liabilities0 - amounts.repay0,
                    liabilities1 - amounts.repay1
                )
            ) slot0_ &= ~SLOT0_MASK_AUCTION;
        }

        slot0 = (slot0_ & (SLOT0_MASK_USERSPACE | SLOT0_MASK_AUCTION)) | SLOT0_DIRT;
        emit Liquidate();
    }

    /* solhint-enable code-complexity */

    /**
     * @notice Allows the owner to manage their account by handing control to some `callee`. Inside the
     * callback `callee` has access to all sub-commands (`uniswapDeposit`, `uniswapWithdraw`, `transfer`,
     * `borrow`, `repay`, and `withdrawAnte`). Whatever `callee` does, the account MUST be healthy
     * after the callback.
     * @param callee The smart contract that will get temporary control of this account
     * @param data Encoded parameters that get forwarded to `callee`
     * @param oracleSeed The indices of `UNISWAP_POOL.observations` where we start our search for
     * the 30-minute-old (lowest 16 bits) and 60-minute-old (next 16 bits) observations when getting
     * TWAPs. If any of the highest 8 bits are set, we fallback to onchain binary search.
     */
    function modify(IManager callee, bytes calldata data, uint40 oracleSeed) external payable {
        uint256 slot0_ = slot0;
        // Essentially `slot0.state == State.Ready && msg.sender == owner()`
        require(slot0_ & SLOT0_MASK_STATE == 0 && msg.sender == owner(), "Aloe: only owner");

        slot0 = slot0_ | (uint256(State.InModifyCallback) << 248);
        {
            uint208 positions = callee.callback(data, msg.sender, uint208(slot0_));
            assembly ("memory-safe") {
                // Equivalent to `if (positions > 0) slot0_ = positions`
                slot0_ := or(positions, mul(slot0_, iszero(positions)))
            }
        }
        slot0 = (slot0_ & SLOT0_MASK_POSITIONS) | SLOT0_DIRT;

        (uint256 liabilities0, uint256 liabilities1) = getLiabilities();
        if (liabilities0 > 0 || liabilities1 > 0) {
            // Fetch prices from oracle
            (Prices memory prices, bool seemsLegit, bool isPaused, uint208 ante) = getPrices(oracleSeed);
            // Tally assets
            Assets memory assets = _getAssets(slot0_, prices);
            // Ensure account is healthy and meets the conditions for borrowing
            require(seemsLegit && !isPaused && address(this).balance >= ante, "Aloe: conditions");
            require(BalanceSheet.isHealthy(prices, assets, liabilities0, liabilities1), "Aloe: unhealthy");
        }
    }

    /*//////////////////////////////////////////////////////////////
                              SUB-COMMANDS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Callback for Uniswap V3 pool; necessary for `uniswapDeposit` to work
     * @param amount0 The amount of `TOKEN0` owed to the `UNISWAP_POOL`
     * @param amount1 The amount of `TOKEN1` owed to the `UNISWAP_POOL`
     */
    function uniswapV3MintCallback(uint256 amount0, uint256 amount1, bytes calldata) external {
        require(msg.sender == address(UNISWAP_POOL));

        if (amount0 > 0) TOKEN0.safeTransfer(msg.sender, amount0);
        if (amount1 > 0) TOKEN1.safeTransfer(msg.sender, amount1);
    }

    /**
     * @notice Allows the `owner()` to add liquidity to a Uniswap position (or create a new one). Only works
     * within the `modify` callback.
     * @dev The `LiquidityAmounts` library can help convert underlying amounts to units of `liquidity`.
     * NOTE: Depending on your use-case, it may be more gas-efficient to call `UNISWAP_POOL.mint` in your
     * own contract, instead of doing `uniswapDeposit` inside of `modify`'s callback. As long as you set
     * this `Borrower` as the recipient in `UNISWAP_POOL.mint`, the result is the same.
     * @param lower The tick at the position's lower bound
     * @param upper The tick at the position's upper bound
     * @param liquidity The amount of liquidity to add, in Uniswap's internal units
     * @return amount0 The precise amount of `TOKEN0` that went into the Uniswap position
     * @return amount1 The precise amount of `TOKEN1` that went into the Uniswap position
     */
    function uniswapDeposit(
        int24 lower,
        int24 upper,
        uint128 liquidity
    ) external onlyInModifyCallback returns (uint256 amount0, uint256 amount1) {
        (amount0, amount1) = UNISWAP_POOL.mint(address(this), lower, upper, liquidity, "");
    }

    /**
     * @notice Allows the `owner()` to withdraw liquidity from one of their Uniswap positions. Only works within
     * the `modify` callback.
     * @dev The `LiquidityAmounts` library can help convert underlying amounts to units of `liquidity`
     * @param lower The tick at the position's lower bound
     * @param upper The tick at the position's upper bound
     * @param liquidity The amount of liquidity to remove, in Uniswap's internal units. Pass 0 to collect
     * fees without burning any liquidity.
     * @param recipient Receives the tokens from Uniswap. Usually the address of this `Borrower` account.
     * @return burned0 The amount of `TOKEN0` that was removed from the Uniswap position
     * @return burned1 The amount of `TOKEN1` that was removed from the Uniswap position
     * @return collected0 Equal to `burned0` plus any earned `TOKEN0` fees that hadn't yet been claimed
     * @return collected1 Equal to `burned1` plus any earned `TOKEN1` fees that hadn't yet been claimed
     */
    function uniswapWithdraw(
        int24 lower,
        int24 upper,
        uint128 liquidity,
        address recipient
    ) external onlyInModifyCallback returns (uint256 burned0, uint256 burned1, uint256 collected0, uint256 collected1) {
        (burned0, burned1, collected0, collected1) = _uniswapWithdraw(lower, upper, liquidity, recipient);
    }

    /**
     * @notice The most flexible sub-command. Allows the `owner()` to transfer amounts of `TOKEN0` and `TOKEN1`
     * to any `recipient` they want. Only works within the `modify` callback.
     * @param amount0 The amount of `TOKEN0` to transfer
     * @param amount1 The amount of `TOKEN1` to transfer
     * @param recipient Receives the transferred tokens
     */
    function transfer(uint256 amount0, uint256 amount1, address recipient) external onlyInModifyCallback {
        if (amount0 > 0) TOKEN0.safeTransfer(recipient, amount0);
        if (amount1 > 0) TOKEN1.safeTransfer(recipient, amount1);
    }

    /**
     * @notice Allows the `owner()` to transfer an `amount` of ETH to any `recipient` they want. Only works within
     * the `modify` callback.
     * @param amount The amount of ETH to transfer
     * @param recipient Receives the ETH
     */
    function transferEth(uint256 amount, address payable recipient) external onlyInModifyCallback {
        // WARNING: External call to user-specified address
        SafeTransferLib.safeTransferETH(recipient, amount);
    }

    /**
     * @notice Allows the `owner()` to borrow funds from `LENDER0` and `LENDER1`. Only works within the `modify`
     * callback.
     * @dev If `amount0 > 0` and interest hasn't yet accrued in this block for `LENDER0`, it will accrue
     * prior to processing your new borrow. Same goes for `amount1 > 0` and `LENDER1`.
     * @param amount0 The amount of `TOKEN0` to borrow
     * @param amount1 The amount of `TOKEN1` to borrow
     * @param recipient Receives the borrowed tokens. Usually the address of this `Borrower` account.
     */
    function borrow(uint256 amount0, uint256 amount1, address recipient) external onlyInModifyCallback {
        if (amount0 > 0) LENDER0.borrow(amount0, recipient);
        if (amount1 > 0) LENDER1.borrow(amount1, recipient);
    }

    /**
     * @notice Allows the `owner()` to repay debts to `LENDER0` and `LENDER1`. Only works within the `modify`
     * callback.
     * @dev This is technically unnecessary since you could call `Lender.repay` directly, specifying this
     * contract as the `beneficiary` and using the `transfer` sub-command to make payments. We include it
     * because it's convenient and gas-efficient for common use-cases.
     * @param amount0 The amount of `TOKEN0` to repay
     * @param amount1 The amount of `TOKEN1` to repay
     */
    function repay(uint256 amount0, uint256 amount1) external onlyInModifyCallback {
        if (amount0 > 0) {
            TOKEN0.safeTransfer(address(LENDER0), amount0);
            LENDER0.repay(amount0, address(this));
        }
        if (amount1 > 0) {
            TOKEN1.safeTransfer(address(LENDER1), amount1);
            LENDER1.repay(amount1, address(this));
        }
    }

    /**
     * @notice Allows the `owner()` to perform arbitrary transfers. Useful for rescuing misplaced funds. Only
     * works within the `modify` callback.
     * @param token The ERC20 token to transfer
     * @param amount The amount to transfer
     * @param recipient Receives the transferred tokens
     */
    function rescue(ERC20 token, uint256 amount, address recipient) external onlyInModifyCallback {
        // WARNING: External call to user-specified address
        token.safeTransfer(recipient, amount);
    }

    /*//////////////////////////////////////////////////////////////
                             BALANCE SHEET
    //////////////////////////////////////////////////////////////*/

    function getUniswapPositions() external view returns (int24[] memory) {
        return extract(slot0);
    }

    function getAssets() external view returns (Assets memory) {
        (Prices memory prices, , , ) = getPrices(1 << 32);
        return _getAssets(slot0, prices);
    }

    function getLiabilities() public view returns (uint256 amount0, uint256 amount1) {
        amount0 = LENDER0.borrowBalance(address(this));
        amount1 = LENDER1.borrowBalance(address(this));
    }

    /**
     * @notice Summarizes all oracle data pertinent to account health
     * @dev If `seemsLegit == false`, you can call `Factory.pause` to temporarily disable borrows
     * @param oracleSeed The indices of `UNISWAP_POOL.observations` where we start our search for
     * the 30-minute-old (lowest 16 bits) and 60-minute-old (next 16 bits) observations when getting
     * TWAPs. If any of the highest 8 bits are set, we fallback to onchain binary search.
     * @return The probe prices currently being used to evaluate account health
     * @return Whether the Uniswap TWAP seems to have been manipulated or not
     * @return Whether the factory has paused this market
     * @return The current ante that must be posted before borrowing
     */
    function getPrices(uint40 oracleSeed) public view returns (Prices memory, bool, bool, uint208) {
        Prices memory prices;
        uint56 metric;
        uint256 iv;
        bool seemsLegit;

        // compute current price and volatility
        (metric, prices.c, iv) = ORACLE.consult(UNISWAP_POOL, oracleSeed);
        // get parameters from factory
        (uint208 ante, uint8 nSigma, uint8 mtd, uint32 pausedUntilTime) = FACTORY.getParameters(UNISWAP_POOL);
        // compute prices at which solvency will be checked
        (prices.a, prices.b, seemsLegit) = BalanceSheet.computeProbePrices(metric, prices.c, iv, nSigma, mtd);

        return (prices, seemsLegit, block.timestamp < pausedUntilTime, ante);
    }

    function _getAssets(uint256 slot0_, Prices memory prices) private view returns (Assets memory assets) {
        assets.amount0AtA = assets.amount0AtB = TOKEN0.balanceOf(address(this));
        assets.amount1AtA = assets.amount1AtB = TOKEN1.balanceOf(address(this));

        int24[] memory positions = extract(slot0_);
        uint256 count = positions.length;
        unchecked {
            for (uint256 i; i < count; i += 2) {
                // Load lower and upper ticks from the `positions` array
                int24 l = positions[i];
                int24 u = positions[i + 1];
                // Fetch amount of `liquidity` in the position
                (uint128 liquidity, , , , ) = UNISWAP_POOL.positions(keccak256(abi.encodePacked(address(this), l, u)));

                if (liquidity == 0) continue;

                // Compute lower and upper sqrt ratios
                uint160 L = TickMath.getSqrtRatioAtTick(l);
                uint160 U = TickMath.getSqrtRatioAtTick(u);

                uint256 amount0;
                uint256 amount1;
                // Compute what amounts underlie `liquidity` at both probe prices
                (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(prices.a, L, U, liquidity);
                assets.amount0AtA += amount0;
                assets.amount1AtA += amount1;
                (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(prices.b, L, U, liquidity);
                assets.amount0AtB += amount0;
                assets.amount1AtB += amount1;
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 HELPERS
    //////////////////////////////////////////////////////////////*/

    function _uniswapWithdraw(uint256 slot0_) private {
        int24[] memory positions = extract(slot0_);
        uint256 count = positions.length;
        unchecked {
            for (uint256 i; i < count; i += 2) {
                // Load lower and upper ticks from the `positions` array
                int24 l = positions[i];
                int24 u = positions[i + 1];
                // Fetch amount of `liquidity` in the position
                (uint128 liquidity, , , , ) = UNISWAP_POOL.positions(keccak256(abi.encodePacked(address(this), l, u)));

                if (liquidity == 0) continue;

                // Withdraw all `liquidity` from the position
                _uniswapWithdraw(l, u, liquidity, address(this));
            }
        }
    }

    function _uniswapWithdraw(
        int24 lower,
        int24 upper,
        uint128 liquidity,
        address recipient
    ) private returns (uint256 burned0, uint256 burned1, uint256 collected0, uint256 collected1) {
        (burned0, burned1) = UNISWAP_POOL.burn(lower, upper, liquidity);
        (collected0, collected1) = UNISWAP_POOL.collect(recipient, lower, upper, type(uint128).max, type(uint128).max);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {ClonesWithImmutableArgs} from "clones-with-immutable-args/ClonesWithImmutableArgs.sol";
import {ERC20, SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IUniswapV3Pool} from "v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {
    DEFAULT_ANTE,
    DEFAULT_N_SIGMA,
    DEFAULT_MANIPULATION_THRESHOLD_DIVISOR,
    DEFAULT_RESERVE_FACTOR,
    CONSTRAINT_N_SIGMA_MIN,
    CONSTRAINT_N_SIGMA_MAX,
    CONSTRAINT_MANIPULATION_THRESHOLD_DIVISOR_MIN,
    CONSTRAINT_MANIPULATION_THRESHOLD_DIVISOR_MAX,
    CONSTRAINT_RESERVE_FACTOR_MIN,
    CONSTRAINT_RESERVE_FACTOR_MAX,
    CONSTRAINT_ANTE_MAX,
    UNISWAP_AVG_WINDOW
} from "./libraries/constants/Constants.sol";

import {Borrower} from "./Borrower.sol";
import {Lender} from "./Lender.sol";
import {IRateModel} from "./RateModel.sol";
import {VolatilityOracle} from "./VolatilityOracle.sol";

/// @title Factory
/// @author Aloe Labs, Inc.
/// @dev "Test everything; hold fast what is good." - 1 Thessalonians 5:21
contract Factory {
    using ClonesWithImmutableArgs for address;
    using SafeTransferLib for ERC20;

    event CreateMarket(IUniswapV3Pool indexed pool, Lender lender0, Lender lender1);

    event CreateBorrower(IUniswapV3Pool indexed pool, address indexed owner, Borrower account);

    event EnrollCourier(uint32 indexed id, address indexed wallet, uint16 cut);

    event SetMarketConfig(IUniswapV3Pool indexed pool, MarketConfig config);

    // This `Factory` can create a `Market` for any Uniswap V3 pool
    struct Market {
        // The `Lender` of `token0` in the Uniswap pool
        Lender lender0;
        // The `Lender` of `token1` in the Uniswap pool
        Lender lender1;
        // The implementation to which all `Borrower` clones will point
        Borrower borrowerImplementation;
    }

    // Each `Market` has a set of borrowing `Parameters` to help manage risk
    struct Parameters {
        // The amount of Ether a `Borrower` must hold in order to borrow assets
        uint208 ante;
        // To avoid liquidation, a `Borrower` must be solvent at TWAP * e^{± nSigma * IV}
        uint8 nSigma;
        // Borrowing is paused when the manipulation metric > threshold; this scales the threshold up/down
        uint8 manipulationThresholdDivisor;
        // The time at which borrowing can resume
        uint32 pausedUntilTime;
    }

    // The set of all governable `Market` properties
    struct MarketConfig {
        // Described above
        uint208 ante;
        // Described above
        uint8 nSigma;
        // Described above
        uint8 manipulationThresholdDivisor;
        // The reserve factor for `market.lender0`, expressed as a reciprocal
        uint8 reserveFactor0;
        // The reserve factor for `market.lender1`, expressed as a reciprocal
        uint8 reserveFactor1;
        // The rate model for `market.lender0`
        IRateModel rateModel0;
        // The rate model for `market.lender1`
        IRateModel rateModel1;
    }

    // By enrolling as a `Courier`, frontends can earn a portion of their users' interest
    struct Courier {
        // The address that receives earnings whenever users withdraw
        address wallet;
        // The portion of users' interest to take, expressed in basis points
        uint16 cut;
    }

    /// @notice The only address that can propose new `MarketConfig`s and rewards programs
    address public immutable GOVERNOR;

    /// @notice The oracle to use for prices and implied volatility
    VolatilityOracle public immutable ORACLE;

    /// @notice The implementation to which all `Lender` clones will point
    address public immutable LENDER_IMPLEMENTATION;

    /// @notice A simple contract that deploys `Borrower`s to keep `Factory` bytecode size down
    BorrowerDeployer private immutable _BORROWER_DEPLOYER;

    /// @notice The rate model that `Lender`s will use when first created
    IRateModel public immutable DEFAULT_RATE_MODEL;

    /*//////////////////////////////////////////////////////////////
                             WORLD STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the `Market` addresses associated with a Uniswap V3 pool
    mapping(IUniswapV3Pool => Market) public getMarket;

    /// @notice Returns the borrowing `Parameters` associated with a Uniswap V3 pool
    mapping(IUniswapV3Pool => Parameters) public getParameters;

    /// @notice Returns the other `Lender` in the `Market` iff input is itself a `Lender`, otherwise 0
    mapping(address => address) public peer;

    /// @notice Returns whether the given address is a `Borrower` deployed by this `Factory`
    mapping(address => bool) public isBorrower;

    /*//////////////////////////////////////////////////////////////
                           INCENTIVE STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The token in which rewards are paid out
    ERC20 public rewardsToken;

    /// @notice Returns the `Courier` for any given ID
    mapping(uint32 => Courier) public couriers;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        address governor,
        address reserve,
        VolatilityOracle oracle,
        BorrowerDeployer borrowerDeployer,
        IRateModel defaultRateModel
    ) {
        GOVERNOR = governor;
        ORACLE = oracle;
        LENDER_IMPLEMENTATION = address(new Lender(reserve));
        _BORROWER_DEPLOYER = borrowerDeployer;
        DEFAULT_RATE_MODEL = defaultRateModel;
    }

    /*//////////////////////////////////////////////////////////////
                               EMERGENCY
    //////////////////////////////////////////////////////////////*/

    function pause(IUniswapV3Pool pool, uint40 oracleSeed) external {
        (, bool seemsLegit, , ) = getMarket[pool].borrowerImplementation.getPrices(oracleSeed);
        if (seemsLegit) return;

        unchecked {
            getParameters[pool].pausedUntilTime = uint32(block.timestamp) + UNISWAP_AVG_WINDOW;
        }
    }

    /*//////////////////////////////////////////////////////////////
                             WORLD CREATION
    //////////////////////////////////////////////////////////////*/

    function createMarket(IUniswapV3Pool pool) external {
        ORACLE.prepare(pool);

        address asset0 = pool.token0();
        address asset1 = pool.token1();

        // Deploy market-specific components
        bytes32 salt = keccak256(abi.encodePacked(pool));
        Lender lender0 = Lender(LENDER_IMPLEMENTATION.cloneDeterministic({salt: salt, data: abi.encodePacked(asset0)}));
        Lender lender1 = Lender(LENDER_IMPLEMENTATION.cloneDeterministic({salt: salt, data: abi.encodePacked(asset1)}));
        Borrower borrowerImplementation = _newBorrower(pool, lender0, lender1);

        // Store deployment addresses
        getMarket[pool] = Market(lender0, lender1, borrowerImplementation);
        peer[address(lender0)] = address(lender1);
        peer[address(lender1)] = address(lender0);

        // Initialize lenders and set default market config
        lender0.initialize();
        lender1.initialize();
        _setMarketConfig(
            pool,
            MarketConfig(
                DEFAULT_ANTE,
                DEFAULT_N_SIGMA,
                DEFAULT_MANIPULATION_THRESHOLD_DIVISOR,
                DEFAULT_RESERVE_FACTOR,
                DEFAULT_RESERVE_FACTOR,
                DEFAULT_RATE_MODEL,
                DEFAULT_RATE_MODEL
            ),
            0
        );

        emit CreateMarket(pool, lender0, lender1);
    }

    function createBorrower(IUniswapV3Pool pool, address owner, bytes12 salt) external returns (Borrower borrower) {
        Market memory market = getMarket[pool];

        borrower = Borrower(
            address(market.borrowerImplementation).cloneDeterministic({
                salt: bytes32(bytes.concat(bytes20(msg.sender), salt)),
                data: abi.encodePacked(owner)
            })
        );
        isBorrower[address(borrower)] = true;

        market.lender0.whitelist(address(borrower));
        market.lender1.whitelist(address(borrower));

        emit CreateBorrower(pool, owner, borrower);
    }

    /*//////////////////////////////////////////////////////////////
                               INCENTIVES
    //////////////////////////////////////////////////////////////*/

    function claimRewards(Lender[] calldata lenders, address beneficiary) external returns (uint256 earned) {
        unchecked {
            uint256 count = lenders.length;
            for (uint256 i = 0; i < count; i++) {
                // Make sure it is, in fact, a `Lender`
                require(peer[address(lenders[i])] != address(0));
                earned += lenders[i].claimRewards(msg.sender);
            }
        }

        require(address(rewardsToken).code.length > 0);
        rewardsToken.safeTransfer(beneficiary, earned);
    }

    /**
     * @notice Enrolls `msg.sender` in the referral program. This allows frontends/wallets/apps to
     * credit themselves for a given user's deposit, and receive a portion of their interest. Note
     * that after enrolling, `msg.sender` will not be eligible for `REWARDS_TOKEN` rewards.
     * @dev See `Lender.creditCourier`
     * @param id A unique identifier for the courier
     * @param cut The portion of interest the courier will receive. Should be in the range [0, 10000),
     * with 10000 being 100%.
     */
    function enrollCourier(uint32 id, uint16 cut) external {
        // Requirements:
        // - `id != 0` because 0 is reserved as the no-courier case
        // - `cut != 0 && cut < 10_000` just means between 0 and 100%
        require(id != 0 && cut != 0 && cut < 10_000);
        // Once an `id` has been enrolled, its info can't be changed
        require(couriers[id].cut == 0);

        couriers[id] = Courier(msg.sender, cut);
        emit EnrollCourier(id, msg.sender, cut);
    }

    /*//////////////////////////////////////////////////////////////
                               GOVERNANCE
    //////////////////////////////////////////////////////////////*/

    function governRewardsToken(ERC20 rewardsToken_) external {
        require(msg.sender == GOVERNOR && address(rewardsToken) == address(0));
        rewardsToken = rewardsToken_;
    }

    function governRewardsRate(Lender lender, uint64 rate) external {
        require(msg.sender == GOVERNOR);
        lender.setRewardsRate(rate);
    }

    function governMarketConfig(IUniswapV3Pool pool, MarketConfig memory config) external {
        require(msg.sender == GOVERNOR);

        require(
            // ante: max
            (config.ante <= CONSTRAINT_ANTE_MAX) &&
                // nSigma: min, max
                (CONSTRAINT_N_SIGMA_MIN <= config.nSigma && config.nSigma <= CONSTRAINT_N_SIGMA_MAX) &&
                // manipulationThresholdDivisor: min, max
                (CONSTRAINT_MANIPULATION_THRESHOLD_DIVISOR_MIN <= config.manipulationThresholdDivisor &&
                    config.manipulationThresholdDivisor <= CONSTRAINT_MANIPULATION_THRESHOLD_DIVISOR_MAX) &&
                // reserveFactor0: min, max
                (CONSTRAINT_RESERVE_FACTOR_MIN <= config.reserveFactor0 &&
                    config.reserveFactor0 <= CONSTRAINT_RESERVE_FACTOR_MAX) &&
                // reserveFactor1: min, max
                (CONSTRAINT_RESERVE_FACTOR_MIN <= config.reserveFactor1 &&
                    config.reserveFactor1 <= CONSTRAINT_RESERVE_FACTOR_MAX),
            "Aloe: constraints"
        );

        _setMarketConfig(pool, config, getParameters[pool].pausedUntilTime);
    }

    function _setMarketConfig(IUniswapV3Pool pool, MarketConfig memory config, uint32 pausedUntilTime) private {
        getParameters[pool] = Parameters({
            ante: config.ante,
            nSigma: config.nSigma,
            manipulationThresholdDivisor: config.manipulationThresholdDivisor,
            pausedUntilTime: pausedUntilTime
        });

        Market memory market = getMarket[pool];
        market.lender0.setRateModelAndReserveFactor(config.rateModel0, config.reserveFactor0);
        market.lender1.setRateModelAndReserveFactor(config.rateModel1, config.reserveFactor1);

        emit SetMarketConfig(pool, config);
    }

    function _newBorrower(IUniswapV3Pool pool, Lender lender0, Lender lender1) private returns (Borrower) {
        (bool success, bytes memory data) = address(_BORROWER_DEPLOYER).delegatecall(
            abi.encodeCall(BorrowerDeployer.deploy, (ORACLE, pool, lender0, lender1))
        );
        require(success);
        return abi.decode(data, (Borrower));
    }
}

contract BorrowerDeployer {
    function deploy(
        VolatilityOracle oracle,
        IUniswapV3Pool pool,
        Lender lender0,
        Lender lender1
    ) external returns (Borrower) {
        return new Borrower(oracle, pool, lender0, lender1);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

/// @dev Docs @ https://github.com/Uniswap/v3-periphery/blob/main/contracts/interfaces/INonfungiblePositionManager.sol
interface IUniswapPositionNFT is IERC721 {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(
        MintParams calldata params
    ) external payable returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(
        IncreaseLiquidityParams calldata params
    ) external payable returns (uint128 liquidity, uint256 amount0, uint256 amount1);

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(
        DecreaseLiquidityParams calldata params
    ) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(
        uint256 tokenId
    )
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.15;

/// @title ImmutableArgs
/// @author zefram.eth, Saw-mon & Natalie
/// @notice Provides helper functions for reading immutable args from calldata
library ImmutableArgs {
    function addr() internal pure returns (address arg) {
        assembly {
            arg := shr(0x60, calldataload(sub(calldatasize(), 22)))
        }
    }

    /// @notice Reads an immutable arg with type address
    /// @param offset The offset of the arg in the packed data
    /// @return arg The arg value
    function addressAt(uint256 offset) internal pure returns (address arg) {
        uint256 start = _startOfImmutableArgs();
        assembly {
            arg := shr(0x60, calldataload(add(start, offset)))
        }
    }

    /// @notice Reads an immutable arg with type uint256
    /// @param offset The offset of the arg in the packed data
    /// @return arg The arg value
    function uint256At(uint256 offset) internal pure returns (uint256 arg) {
        uint256 start = _startOfImmutableArgs();
        assembly {
            arg := calldataload(add(start, offset))
        }
    }

    function all() internal pure returns (bytes memory args) {
        uint256 start = _startOfImmutableArgs();
        unchecked {
            args = msg.data[start:msg.data.length - 2];
        }
    }

    /// @return offset The offset of the packed immutable args in calldata
    function _startOfImmutableArgs() private pure returns (uint256 offset) {
        assembly {
            //                                      read final 2 bytes of calldata, i.e. `extraLength`
            offset := sub(calldatasize(), shr(0xf0, calldataload(sub(calldatasize(), 2))))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error ExpOverflow();

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error FactorialOverflow();

    /// @dev The operation failed, due to an multiplication overflow.
    error MulWadFailed();

    /// @dev The operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error DivWadFailed();

    /// @dev The multiply-divide operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error MulDivFailed();

    /// @dev The division failed, as the denominator is zero.
    error DivFailed();

    /// @dev The full precision multiply-divide operation failed, either due
    /// to the result being larger than 256 bits, or a division by a zero.
    error FullMulDivFailed();

    /// @dev The output is undefined, as the input is less-than-or-equal to zero.
    error LnWadUndefined();

    /// @dev The output is undefined, as the input is zero.
    error Log2Undefined();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The scalar of ETH and most ERC20s.
    uint256 internal constant WAD = 1e18;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              SIMPLIFIED FIXED POINT OPERATIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to `(x * y) / WAD` rounded down.
    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), WAD)
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded up.
    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), WAD))), div(mul(x, y), WAD))
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded down.
    function divWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, WAD), y)
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded up.
    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, WAD), y))), div(mul(x, WAD), y))
        }
    }

    /// @dev Equivalent to `x` to the power of `y`.
    /// because `x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)`.
    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Using `ln(x)` means `x` must be greater than 0.
        return expWad((lnWad(x) * y) / int256(WAD));
    }

    /// @dev Returns `exp(x)`, denominated in `WAD`.
    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return r;

            /// @solidity memory-safe-assembly
            assembly {
                // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
                // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
                if iszero(slt(x, 135305999368893231589)) {
                    // Store the function selector of `ExpOverflow()`.
                    mstore(0x00, 0xa37bfec9)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5 ** 18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256(
                (uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k)
            );
        }
    }

    /// @dev Returns `ln(x)`, denominated in `WAD`.
    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            /// @solidity memory-safe-assembly
            assembly {
                if iszero(sgt(x, 0)) {
                    // Store the function selector of `LnWadUndefined()`.
                    mstore(0x00, 0x1615e638)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Compute k = log2(x) - 96.
            int256 k;
            /// @solidity memory-safe-assembly
            assembly {
                let v := x
                k := shl(7, lt(0xffffffffffffffffffffffffffffffff, v))
                k := or(k, shl(6, lt(0xffffffffffffffff, shr(k, v))))
                k := or(k, shl(5, lt(0xffffffff, shr(k, v))))

                // For the remaining 32 bits, use a De Bruijn lookup.
                // See: https://graphics.stanford.edu/~seander/bithacks.html
                v := shr(k, v)
                v := or(v, shr(1, v))
                v := or(v, shr(2, v))
                v := or(v, shr(4, v))
                v := or(v, shr(8, v))
                v := or(v, shr(16, v))

                // forgefmt: disable-next-item
                k := sub(or(k, byte(shr(251, mul(v, shl(224, 0x07c4acdd))),
                    0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f)), 96)
            }

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  GENERAL NUMBER UTILITIES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Calculates `floor(a * b / d)` with full precision.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Remco Bloemen under MIT license: https://2π.com/21/muldiv
    function fullMulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for {} 1 {} {
                // 512-bit multiply `[prod1 prod0] = x * y`.
                // Compute the product mod `2**256` and mod `2**256 - 1`
                // then use the Chinese Remainder Theorem to reconstruct
                // the 512 bit result. The result is stored in two 256
                // variables such that `product = prod1 * 2**256 + prod0`.

                // Least significant 256 bits of the product.
                let prod0 := mul(x, y)
                let mm := mulmod(x, y, not(0))
                // Most significant 256 bits of the product.
                let prod1 := sub(mm, add(prod0, lt(mm, prod0)))

                // Handle non-overflow cases, 256 by 256 division.
                if iszero(prod1) {
                    if iszero(d) {
                        // Store the function selector of `FullMulDivFailed()`.
                        mstore(0x00, 0xae47f702)
                        // Revert with (offset, size).
                        revert(0x1c, 0x04)
                    }
                    result := div(prod0, d)
                    break       
                }

                // Make sure the result is less than `2**256`.
                // Also prevents `d == 0`.
                if iszero(gt(d, prod1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }

                ///////////////////////////////////////////////
                // 512 by 256 division.
                ///////////////////////////////////////////////

                // Make division exact by subtracting the remainder from `[prod1 prod0]`.
                // Compute remainder using mulmod.
                let remainder := mulmod(x, y, d)
                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
                // Factor powers of two out of `d`.
                // Compute largest power of two divisor of `d`.
                // Always greater or equal to 1.
                let twos := and(d, sub(0, d))
                // Divide d by power of two.
                d := div(d, twos)
                // Divide [prod1 prod0] by the factors of two.
                prod0 := div(prod0, twos)
                // Shift in bits from `prod1` into `prod0`. For this we need
                // to flip `twos` such that it is `2**256 / twos`.
                // If `twos` is zero, then it becomes one.
                prod0 := or(prod0, mul(prod1, add(div(sub(0, twos), twos), 1)))
                // Invert `d mod 2**256`
                // Now that `d` is an odd number, it has an inverse
                // modulo `2**256` such that `d * inv = 1 mod 2**256`.
                // Compute the inverse by starting with a seed that is correct
                // correct for four bits. That is, `d * inv = 1 mod 2**4`.
                let inv := xor(mul(3, d), 2)
                // Now use Newton-Raphson iteration to improve the precision.
                // Thanks to Hensel's lifting lemma, this also works in modular
                // arithmetic, doubling the correct bits in each step.
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**8
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**16
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**32
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**64
                inv := mul(inv, sub(2, mul(d, inv))) // inverse mod 2**128
                result := mul(prod0, mul(inv, sub(2, mul(d, inv)))) // inverse mod 2**256
                break
            }
        }
    }

    /// @dev Calculates `floor(x * y / d)` with full precision, rounded up.
    /// Throws if result overflows a uint256 or when `d` is zero.
    /// Credit to Uniswap-v3-core under MIT license:
    /// https://github.com/Uniswap/v3-core/blob/contracts/libraries/FullMath.sol
    function fullMulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 result) {
        result = fullMulDiv(x, y, d);
        /// @solidity memory-safe-assembly
        assembly {
            if mulmod(x, y, d) {
                if iszero(add(result, 1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
                result := add(result, 1)
            }
        }
    }

    /// @dev Returns `floor(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDiv(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), d)
        }
    }

    /// @dev Returns `ceil(x * y / d)`.
    /// Reverts if `x * y` overflows, or `d` is zero.
    function mulDivUp(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(d != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(d, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), d))), div(mul(x, y), d))
        }
    }

    /// @dev Returns `ceil(x / d)`.
    /// Reverts if `d` is zero.
    function divUp(uint256 x, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(d) {
                // Store the function selector of `DivFailed()`.
                mstore(0x00, 0x65244e4e)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(x, d))), div(x, d))
        }
    }

    /// @dev Returns `max(0, x - y)`.
    function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Returns the square root of `x`.
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // `floor(sqrt(2**15)) = 181`. `sqrt(2**15) - 181 = 2.84`.
            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // Let `y = x / 2**r`.
            // We check `y >= 2**(k + 8)` but shift right by `k` bits
            // each branch to ensure that if `x >= 256`, then `y >= 256`.
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffffff, shr(r, x))))
            z := shl(shr(1, r), z)

            // Goal was to get `z*z*y` within a small factor of `x`. More iterations could
            // get y in a tighter range. Currently, we will have y in `[256, 256*(2**16))`.
            // We ensured `y >= 256` so that the relative difference between `y` and `y+1` is small.
            // That's not possible if `x < 256` but we can just verify those cases exhaustively.

            // Now, `z*z*y <= x < z*z*(y+1)`, and `y <= 2**(16+8)`, and either `y >= 256`, or `x < 256`.
            // Correctness can be checked exhaustively for `x < 256`, so we assume `y >= 256`.
            // Then `z*sqrt(y)` is within `sqrt(257)/sqrt(256)` of `sqrt(x)`, or about 20bps.

            // For `s` in the range `[1/256, 256]`, the estimate `f(s) = (181/1024) * (s+1)`
            // is in the range `(1/2.84 * sqrt(s), 2.84 * sqrt(s))`,
            // with largest error when `s = 1` and when `s = 256` or `1/256`.

            // Since `y` is in `[256, 256*(2**16))`, let `a = y/65536`, so that `a` is in `[1/256, 256)`.
            // Then we can estimate `sqrt(y)` using
            // `sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2**18`.

            // There is no overflow risk here since `y < 2**136` after the first branch above.
            z := shr(18, mul(z, add(shr(r, x), 65536))) // A `mul()` is saved from starting `z` at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If `x+1` is a perfect square, the Babylonian method cycles between
            // `floor(sqrt(x))` and `ceil(sqrt(x))`. This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    /// @dev Returns the cube root of `x`.
    /// Credit to bout3fiddy and pcaversaccio under AGPLv3 license:
    /// https://github.com/pcaversaccio/snekmate/blob/main/src/utils/Math.vy
    function cbrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))

            z := shl(add(div(r, 3), lt(0xf, shr(r, x))), 0xff)
            z := div(z, byte(mod(r, 3), shl(232, 0x7f624b)))

            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)
            z := div(add(add(div(x, mul(z, z)), z), z), 3)

            z := sub(z, lt(div(x, mul(z, z)), z))
        }
    }

    /// @dev Returns the factorial of `x`.
    function factorial(uint256 x) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(lt(x, 58)) {
                // Store the function selector of `FactorialOverflow()`.
                mstore(0x00, 0xaba0f2a2)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            for { result := 1 } x {} {
                result := mul(result, x)
                x := sub(x, 1)
            }
        }
    }

    /// @dev Returns the log2 of `x`.
    /// Equivalent to computing the index of the most significant bit (MSB) of `x`.
    function log2(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(x) {
                // Store the function selector of `Log2Undefined()`.
                mstore(0x00, 0x5be3aa5c)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))

            // For the remaining 32 bits, use a De Bruijn lookup.
            // See: https://graphics.stanford.edu/~seander/bithacks.html
            x := shr(r, x)
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))

            // forgefmt: disable-next-item
            r := or(r, byte(shr(251, mul(x, shl(224, 0x07c4acdd))),
                0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f))
        }
    }

    /// @dev Returns the log2 of `x`, rounded up.
    function log2Up(uint256 x) internal pure returns (uint256 r) {
        unchecked {
            uint256 isNotPo2;
            assembly {
                isNotPo2 := iszero(iszero(and(x, sub(x, 1))))
            }
            return log2(x) + isNotPo2;
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = (x & y) + ((x ^ y) >> 1);
        }
    }

    /// @dev Returns the average of `x` and `y`.
    function avg(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = (x >> 1) + (y >> 1) + (((x & 1) + (y & 1)) >> 1);
        }
    }

    /// @dev Returns the absolute value of `x`.
    function abs(int256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let mask := sub(0, shr(255, x))
            z := xor(mask, add(mask, x))
        }
    }

    /// @dev Returns the absolute distance between `x` and `y`.
    function dist(int256 x, int256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let a := sub(y, x)
            z := xor(a, mul(xor(a, sub(x, y)), sgt(x, y)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), slt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), sgt(y, x)))
        }
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(uint256 x, uint256 minValue, uint256 maxValue)
        internal
        pure
        returns (uint256 z)
    {
        z = min(max(x, minValue), maxValue);
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(int256 x, int256 minValue, int256 maxValue) internal pure returns (int256 z) {
        z = min(max(x, minValue), maxValue);
    }

    /// @dev Returns greatest common divisor of `x` and `y`.
    function gcd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for { z := x } y {} {
                let t := y
                y := mod(z, y)
                z := t
            }
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   RAW NUMBER OPERATIONS                    */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x + y`, without checking for overflow.
    function rawAdd(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x + y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x - y`, without checking for underflow.
    function rawSub(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x - y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x * y`, without checking for overflow.
    function rawMul(int256 x, int256 y) internal pure returns (int256 z) {
        unchecked {
            z = x * y;
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := div(x, y)
        }
    }

    /// @dev Returns `x / y`, returning 0 if `y` is zero.
    function rawSDiv(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := sdiv(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mod(x, y)
        }
    }

    /// @dev Returns `x % y`, returning 0 if `y` is zero.
    function rawSMod(int256 x, int256 y) internal pure returns (int256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := smod(x, y)
        }
    }

    /// @dev Returns `(x + y) % d`, return 0 if `d` if zero.
    function rawAddMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := addmod(x, y, d)
        }
    }

    /// @dev Returns `(x * y) % d`, return 0 if `d` if zero.
    function rawMulMod(uint256 x, uint256 y, uint256 d) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mulmod(x, y, d)
        }
    }
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

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

/// @dev The initial value of `Lender`'s `borrowIndex`
uint256 constant ONE = 1e12;

/// @dev An additional scaling factor applied to borrowed amounts before dividing by `borrowIndex` and storing.
/// 72 matches the type of `borrowIndex` in `Ledger` to guarantee that the stored borrow units fit in uint256.
uint256 constant BORROWS_SCALER = ONE << 72;

/// @dev The maximum percentage yield per second, scaled up by 1e12. The current value is equivalent to
/// `((1 + 706354 / 1e12) ** (24 * 60 * 60)) - 1` ⇒ +6.3% per day or +53% per week. If the rate is consistently at
/// this maximum value, the `Lender` will function for 1 year before `borrowIndex` overflows.
/// @custom:math
/// > 📘 Useful Math
/// >
/// > - T: number of years before overflow, assuming maximum rate
/// > - borrowIndexInit: `ONE`
/// > - borrowIndexMax: 2^72 - 1
/// >
/// > - maxAPR: ln(borrowIndexMax / borrowIndexInit) / T
/// > - maxAPY: exp(maxAPR) - 1
/// > - MAX_RATE: (exp(maxAPR / secondsPerYear) - 1) * 1e12
uint256 constant MAX_RATE = 706354;

/*//////////////////////////////////////////////////////////////
                        FACTORY DEFAULTS
//////////////////////////////////////////////////////////////*/

/// @dev The default amount of Ether required to take on debt in a `Borrower`. The `Factory` can override this value
/// on a per-market basis. Incentivizes calls to `Borrower.warn`.
uint208 constant DEFAULT_ANTE = 0.01 ether;

/// @dev The default number of standard deviations of price movement used to determine probe prices for `Borrower`
/// solvency. The `Factory` can override this value on a per-market basis. Expressed x10, e.g. 50 → 5σ
uint8 constant DEFAULT_N_SIGMA = 50;

/// @dev Assume someone is manipulating the Uniswap TWAP oracle. To steal money from the protocol and create bad debt,
/// they would need to change the TWAP by a factor of (1 / LTV), where the LTV is a function of volatility. We have a
/// manipulation metric that increases as an attacker tries to change the TWAP. If this metric rises above a certain
/// threshold, certain functionality will be paused, e.g. no new debt can be created. The threshold is calculated as
/// follows:
///
/// \\( \text{manipulationThreshold} =
/// \frac{log_{1.0001}\left( \frac{1}{\text{LTV}} \right)}{\text{MANIPULATION_THRESHOLD_DIVISOR}} \\)
uint8 constant DEFAULT_MANIPULATION_THRESHOLD_DIVISOR = 12;

/// @dev The default portion of interest that will accrue to a `Lender`'s `RESERVE` address.
/// Expressed as a reciprocal, e.g. 16 → 6.25%
uint8 constant DEFAULT_RESERVE_FACTOR = 16;

/*//////////////////////////////////////////////////////////////
                        GOVERNANCE CONSTRAINTS
//////////////////////////////////////////////////////////////*/

/// @dev The lowest number of standard deviations of price movement allowed for determining `Borrower` probe prices.
/// Expressed x10, e.g. 40 → 4σ
uint8 constant CONSTRAINT_N_SIGMA_MIN = 40;

/// @dev The highest number of standard deviations of price movement allowed for determining `Borrower` probe prices.
/// Expressed x10, e.g. 80 → 8σ
uint8 constant CONSTRAINT_N_SIGMA_MAX = 80;

/// @dev The minimum value of the `manipulationThresholdDivisor`, described above
uint8 constant CONSTRAINT_MANIPULATION_THRESHOLD_DIVISOR_MIN = 10;

/// @dev The maximum value of the `manipulationThresholdDivisor`, described above
uint8 constant CONSTRAINT_MANIPULATION_THRESHOLD_DIVISOR_MAX = 16;

/// @dev The lower bound on what any `Lender`'s reserve factor can be. Expressed as reciprocal, e.g. 4 → 25%
uint8 constant CONSTRAINT_RESERVE_FACTOR_MIN = 4;

/// @dev The upper bound on what any `Lender`'s reserve factor can be. Expressed as reciprocal, e.g. 20 → 5%
uint8 constant CONSTRAINT_RESERVE_FACTOR_MAX = 20;

/// @dev The maximum amount of Ether that `Borrower`s can be required to post before taking on debt
uint216 constant CONSTRAINT_ANTE_MAX = 0.5 ether;

/*//////////////////////////////////////////////////////////////
                            LIQUIDATION
//////////////////////////////////////////////////////////////*/

/// @dev \\( 1 + \frac{1}{\text{MAX_LEVERAGE}} \\) should be greater than the maximum feasible single-block
/// `accrualFactor` so that liquidators have time to respond to interest updates
uint256 constant MAX_LEVERAGE = 200;

/// @dev The minimum discount that a healthy `Borrower` should be able to offer a liquidator when swapping
/// assets. Expressed as reciprocal, e.g. 20 → 5%
uint256 constant LIQUIDATION_INCENTIVE = 20;

/// @dev The minimum time that must pass between calls to `Borrower.warn` and `Borrower.liquidate`.
uint256 constant LIQUIDATION_GRACE_PERIOD = 5 minutes;

/// @dev The minimum `closeFactor` necessary to conclude a liquidation auction. To actually conclude the auction,
/// `Borrower.liquidate` must result in a healthy balance sheet (in addition to this `closeFactor` requirement).
/// Expressed in basis points.
/// NOTE: The ante is depleted after just 4 `Borrower.warn`ings. By requiring that each auction repay at least
/// 68%, we ensure that after 4 auctions, no more than 1% of debt remains ((1 - 0.6838)^4). Increasing the threshold
/// would reduce that further, but we don't want to prolong individual auctions unnecessarily since the incentive
/// (and loss to `Borrower`s) increases with time.
uint256 constant TERMINATING_CLOSE_FACTOR = 6837;

/// @dev The minimum scaling factor by which `sqrtMeanPriceX96` is multiplied or divided to get probe prices
uint256 constant PROBE_SQRT_SCALER_MIN = 1.026248453011e12;

/// @dev The maximum scaling factor by which `sqrtMeanPriceX96` is multiplied or divided to get probe prices
uint256 constant PROBE_SQRT_SCALER_MAX = 3.078745359035e12;

/// @dev Equivalent to \\( \frac{10^{36}}{1 + \frac{1}{liquidationIncentive} + \frac{1}{maxLeverage}} \\)
uint256 constant LTV_NUMERATOR = uint256(LIQUIDATION_INCENTIVE * MAX_LEVERAGE * 1e36) /
    (LIQUIDATION_INCENTIVE * MAX_LEVERAGE + LIQUIDATION_INCENTIVE + MAX_LEVERAGE);

/// @dev The minimum loan-to-value ratio. Actual ratio is based on implied volatility; this is just a lower bound.
/// Expressed as a 1e12 percentage, e.g. 0.10e12 → 10%. Must be greater than `TickMath.MIN_SQRT_RATIO` because
/// we reuse a base 1.0001 logarithm in `BalanceSheet`
uint256 constant LTV_MIN = LTV_NUMERATOR / (PROBE_SQRT_SCALER_MAX * PROBE_SQRT_SCALER_MAX);

/// @dev The maximum loan-to-value ratio. Actual ratio is based on implied volatility; this is just a upper bound.
/// Expressed as a 1e12 percentage, e.g. 0.90e12 → 90%
uint256 constant LTV_MAX = LTV_NUMERATOR / (PROBE_SQRT_SCALER_MIN * PROBE_SQRT_SCALER_MIN);

/*//////////////////////////////////////////////////////////////
                            IV AND TWAP
//////////////////////////////////////////////////////////////*/

/// @dev The timescale of implied volatility, applied to measurements and calculations. When `BalanceSheet` detects
/// that an `nSigma` event would cause insolvency in this time period, it enables liquidations. So if you squint your
/// eyes and wave your hands enough, this is (in expectation) the time liquidators have to act before the protocol
/// accrues bad debt.
uint32 constant IV_SCALE = 24 hours;

/// @dev The initial value of implied volatility, used when `VolatilityOracle.prepare` is called for a new pool.
/// Expressed as a 1e12 percentage at `IV_SCALE`, e.g. {0.12e12, 24 hours} → 12% daily → 229% annual. Error on the
/// side of making this too large (resulting in low LTV).
uint104 constant IV_COLD_START = 0.127921282726e12;

/// @dev The maximum rate at which (reported) implied volatility can change. Raw samples in `VolatilityOracle.update`
/// are clamped (before being stored) so as not to exceed this rate.
/// Expressed in 1e12 percentage points at `IV_SCALE` **per second**, e.g. {115740, 24 hours} means daily IV can
/// change by 0.0000116 percentage points per second → 1 percentage point per day.
uint256 constant IV_CHANGE_PER_SECOND = 115740;

/// @dev The maximum amount by which (reported) implied volatility can change with a single `VolatilityOracle.update`
/// call. If updates happen as frequently as possible (every `FEE_GROWTH_SAMPLE_PERIOD`), this cap is no different
/// from `IV_CHANGE_PER_SECOND` alone.
uint104 constant IV_CHANGE_PER_UPDATE = uint104(IV_CHANGE_PER_SECOND * FEE_GROWTH_SAMPLE_PERIOD);

/// @dev The gain on the EMA update when IV is increasing. Expressed as reciprocal, e.g. 20 → 0.05
int256 constant IV_EMA_GAIN_POS = 20;

/// @dev The gain on the EMA update when IV is decreasing. Expressed as reciprocal, e.g. 100 → 0.01
int256 constant IV_EMA_GAIN_NEG = 100;

/// @dev To estimate volume, we need 2 samples. One is always at the current block, the other is from
/// `FEE_GROWTH_AVG_WINDOW` seconds ago, +/- `FEE_GROWTH_SAMPLE_PERIOD / 2`. Larger values make the resulting volume
/// estimate more robust, but may cause the oracle to miss brief spikes in activity.
uint256 constant FEE_GROWTH_AVG_WINDOW = 72 hours;

/// @dev The length of the circular buffer that stores feeGrowthGlobals samples.
/// Must be in interval
/// \\( \left[ \frac{\text{FEE_GROWTH_AVG_WINDOW}}{\text{FEE_GROWTH_SAMPLE_PERIOD}}, 256 \right) \\)
uint256 constant FEE_GROWTH_ARRAY_LENGTH = 32;

/// @dev The minimum number of seconds that must elapse before a new feeGrowthGlobals sample will be stored. This
/// controls how often the oracle can update IV.
uint256 constant FEE_GROWTH_SAMPLE_PERIOD = 4 hours;

/// @dev To compute Uniswap mean price & liquidity, we need 2 samples. One is always at the current block, the other is
/// from `UNISWAP_AVG_WINDOW` seconds ago. Larger values make the resulting price/liquidity values harder to
/// manipulate, but also make the oracle slower to respond to changes.
uint32 constant UNISWAP_AVG_WINDOW = 30 minutes;

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {FixedPointMathLib as SoladyMath} from "solady/utils/FixedPointMathLib.sol";

import {
    MAX_LEVERAGE,
    LIQUIDATION_INCENTIVE,
    LIQUIDATION_GRACE_PERIOD,
    PROBE_SQRT_SCALER_MIN,
    PROBE_SQRT_SCALER_MAX,
    LTV_NUMERATOR
} from "./constants/Constants.sol";
import {exp1e12} from "./Exp.sol";
import {square, mulDiv128, mulDiv128Up} from "./MulDiv.sol";
import {TickMath} from "./TickMath.sol";

struct AuctionAmounts {
    // The amount of `TOKEN0` sent to the liquidator in exchange for repaying `repay0` and `repay1`
    uint256 out0;
    // The amount of `TOKEN1` sent to the liquidator in exchange for repaying `repay0` and `repay1`
    uint256 out1;
    // The amount of `TOKEN0` the liquidator must send to `LENDER0` in order to complete the liquidation
    uint256 repay0;
    // The amount of `TOKEN1` the liquidator must send to `LENDER1` in order to complete the liquidation
    uint256 repay1;
}

struct Assets {
    // `TOKEN0.balanceOf(borrower)`, plus the amount of `TOKEN0` underlying its Uniswap liquidity at `Prices.a`
    uint256 amount0AtA;
    // `TOKEN1.balanceOf(borrower)`, plus the amount of `TOKEN1` underlying its Uniswap liquidity at `Prices.a`
    uint256 amount1AtA;
    // `TOKEN0.balanceOf(borrower)`, plus the amount of `TOKEN0` underlying its Uniswap liquidity at `Prices.b`
    uint256 amount0AtB;
    // `TOKEN1.balanceOf(borrower)`, plus the amount of `TOKEN1` underlying its Uniswap liquidity at `Prices.b`
    uint256 amount1AtB;
}

struct Prices {
    // Some sqrtPriceX96 *less* than the current TWAP
    uint160 a;
    // Some sqrtPriceX96 *greater* than the current TWAP
    uint160 b;
    // The current TWAP, expressed as a sqrtPriceX96
    uint160 c;
}

/// @title BalanceSheet
/// @notice Provides functions for computing a `Borrower`'s health
/// @author Aloe Labs, Inc.
library BalanceSheet {
    using SoladyMath for uint256;

    // During liquidation auctions, the usable fraction is given by S + (R / (N - t)) - (Q / (M + 1000000t)),
    // where `t` is the time elapsed since the end of the `LIQUIDATION_GRACE_PERIOD`.
    //
    // | time since warning |      t | usable fraction |
    // | ------------------ | ------ | --------------- |
    // | 0 minutes          |      0 |              0% |
    // | 1 minute           |      0 |              0% |
    // | 4 minutes          |      0 |              0% |
    // | 5 minutes          |      0 |              0% |
    // | 5 minutes + 12 sec |     12 |             42% |
    // | 5 minutes + 24 sec |     24 |             61% |
    // | 6 minutes          |     60 |             84% |
    // | 7 minutes          |    132 |             96% |
    // | 10 minutes         |    300 |            105% |
    // | 60 minutes         |   3300 |            112% |
    // | ~1 days            |  86100 |            115% |
    // | ~3 days            | 258900 |            125% |
    // | ~7 days            | 604500 |               ∞ |
    //
    uint256 private constant _Q = 22.8811827075e18;
    uint256 private constant _R = 103567.889099532e12;
    uint256 private constant _S = 0.95e12;
    uint256 private constant _M = 20.405429e6;
    uint256 private constant _N = 7 days - LIQUIDATION_GRACE_PERIOD;

    function auctionTime(uint256 warnTime) internal view returns (uint256) {
        unchecked {
            require(warnTime > 0 && block.timestamp >= warnTime + LIQUIDATION_GRACE_PERIOD, "Aloe: grace");
            return block.timestamp - (warnTime + LIQUIDATION_GRACE_PERIOD);
        }
    }

    function auctionCurve(uint256 t) internal pure returns (uint256) {
        unchecked {
            return _S + _R.rawDiv(_N - t) - _Q.rawDiv(_M + 1e6 * t);
        }
    }

    function computeAuctionAmounts(
        uint160 sqrtPriceX96,
        uint256 assets0,
        uint256 assets1,
        uint256 liabilities0,
        uint256 liabilities1,
        uint256 t,
        uint256 closeFactor
    ) internal pure returns (AuctionAmounts memory amounts) {
        uint256 priceX128 = square(sqrtPriceX96);
        uint256 liabilities = liabilities1 + mulDiv128Up(liabilities0, priceX128);
        uint256 assets = assets1 + mulDiv128Up(assets0, priceX128);

        unchecked {
            if (t < _N) {
                liabilities *= auctionCurve(t);
                assets *= 1e12;

                if (liabilities < assets) {
                    assets0 = assets0.fullMulDiv(liabilities, assets);
                    assets1 = assets1.fullMulDiv(liabilities, assets);
                }
            }

            // All amounts scale with `closeFactor`
            amounts.out0 = (assets0 * closeFactor) / 10000;
            amounts.out1 = (assets1 * closeFactor) / 10000;
            amounts.repay0 = (liabilities0 * closeFactor).divUp(10000);
            amounts.repay1 = (liabilities1 * closeFactor).divUp(10000);
        }
    }

    /**
     * @dev Checks whether a `Borrower` is healthy given the probe prices and its current assets and liabilities.
     * Should be used when `assets` at `prices.a` differ from those at `prices.b` (due to Uniswap positions).
     */
    function isHealthy(
        Prices memory prices,
        Assets memory assets,
        uint256 liabilities0,
        uint256 liabilities1
    ) internal pure returns (bool) {
        unchecked {
            uint256 augmented0;
            uint256 augmented1;

            // The optimizer eliminates the conditional in `divUp`; don't worry about gas golfing that
            augmented0 =
                liabilities0 +
                liabilities0.divUp(MAX_LEVERAGE) +
                liabilities0.zeroFloorSub(assets.amount0AtA).divUp(LIQUIDATION_INCENTIVE);
            augmented1 =
                liabilities1 +
                liabilities1.divUp(MAX_LEVERAGE) +
                liabilities1.zeroFloorSub(assets.amount1AtA).divUp(LIQUIDATION_INCENTIVE);

            if (!isSolvent(prices.a, assets.amount0AtA, assets.amount1AtA, augmented0, augmented1)) return false;

            augmented0 =
                liabilities0 +
                liabilities0.divUp(MAX_LEVERAGE) +
                liabilities0.zeroFloorSub(assets.amount0AtB).divUp(LIQUIDATION_INCENTIVE);
            augmented1 =
                liabilities1 +
                liabilities1.divUp(MAX_LEVERAGE) +
                liabilities1.zeroFloorSub(assets.amount1AtB).divUp(LIQUIDATION_INCENTIVE);

            if (!isSolvent(prices.b, assets.amount0AtB, assets.amount1AtB, augmented0, augmented1)) return false;

            return true;
        }
    }

    /**
     * @dev Checks whether a `Borrower` is healthy given the probe prices and its current assets and liabilities.
     * Can be used when `assets` at `prices.a` are the same as those at `prices.b` (no Uniswap positions).
     */
    function isHealthy(
        Prices memory prices,
        uint256 assets0,
        uint256 assets1,
        uint256 liabilities0,
        uint256 liabilities1
    ) internal pure returns (bool) {
        unchecked {
            // The optimizer eliminates the conditional in `divUp`; don't worry about gas golfing that
            liabilities0 +=
                liabilities0.divUp(MAX_LEVERAGE) +
                liabilities0.zeroFloorSub(assets0).divUp(LIQUIDATION_INCENTIVE);
            liabilities1 +=
                liabilities1.divUp(MAX_LEVERAGE) +
                liabilities1.zeroFloorSub(assets1).divUp(LIQUIDATION_INCENTIVE);

            if (!isSolvent(prices.a, assets0, assets1, liabilities0, liabilities1)) return false;
            if (!isSolvent(prices.b, assets0, assets1, liabilities0, liabilities1)) return false;
            return true;
        }
    }

    function isSolvent(
        uint160 sqrtPriceX96,
        uint256 assets0,
        uint256 assets1,
        uint256 liabilities0,
        uint256 liabilities1
    ) internal pure returns (bool) {
        uint256 priceX128 = square(sqrtPriceX96);
        uint256 liabilities = liabilities1 + mulDiv128Up(liabilities0, priceX128);
        uint256 assets = assets1 + mulDiv128(assets0, priceX128);
        return assets >= liabilities;
    }

    /**
     * Given data from the `ORACLE` (first 3 args) and parameters from the `FACTORY` (last 2 args), computes
     * the probe prices at which to check the account's health
     * @param metric The manipulation metric (from oracle)
     * @param sqrtMeanPriceX96 The current TWAP, expressed as a sqrtPriceX96 (from oracle)
     * @param iv The estimated implied volatility, expressed as a 1e12 percentage (from oracle)
     * @param nSigma The number of standard deviations of price movement to account for (from factory)
     * @param manipulationThresholdDivisor Helps compute the manipulation threshold (from factory). See `Constants.sol`
     * @return a \\( \text{TWAP} \cdot e^{-n \cdot \sigma} \\) expressed as a sqrtPriceX96
     * @return b \\( \text{TWAP} \cdot e^{+n \cdot \sigma} \\) expressed as a sqrtPriceX96
     * @return seemsLegit Whether the Uniswap TWAP has been manipulated enough to create bad debt at the effective LTV
     */
    function computeProbePrices(
        uint56 metric,
        uint256 sqrtMeanPriceX96,
        uint256 iv,
        uint8 nSigma,
        uint8 manipulationThresholdDivisor
    ) internal pure returns (uint160 a, uint160 b, bool seemsLegit) {
        unchecked {
            // Essentially sqrt(e^{nSigma*iv}). Note the `Factory` defines `nSigma` with an extra factor of 10
            uint256 sqrtScaler = uint256(exp1e12(int256((nSigma * iv) / 20))).clamp(
                PROBE_SQRT_SCALER_MIN,
                PROBE_SQRT_SCALER_MAX
            );

            seemsLegit = metric < _manipulationThreshold(_ltv(sqrtScaler), manipulationThresholdDivisor);

            a = uint160((sqrtMeanPriceX96 * 1e12).rawDiv(sqrtScaler).max(TickMath.MIN_SQRT_RATIO));
            b = uint160((sqrtMeanPriceX96 * sqrtScaler).rawDiv(1e12).min(TickMath.MAX_SQRT_RATIO));
        }
    }

    /// @dev Equivalent to \\( \frac{log_{1.0001} \left( \frac{10^{12}}{ltv} \right)}{\text{MANIPULATION_THRESHOLD_DIVISOR}} \\)
    function _manipulationThreshold(uint160 ltv, uint8 manipulationThresholdDivisor) private pure returns (uint24) {
        unchecked {
            return uint24(-TickMath.getTickAtSqrtRatio(ltv) - 778261) / (2 * manipulationThresholdDivisor);
        }
    }

    /**
     * @notice The effective LTV implied by `sqrtScaler`. This LTV is accurate for fixed assets and out-of-range
     * Uniswap positions, but not for in-range Uniswap positions (impermanent losses make their effective LTV
     * slightly smaller).
     */
    function _ltv(uint256 sqrtScaler) private pure returns (uint160 ltv) {
        unchecked {
            ltv = uint160(LTV_NUMERATOR.rawDiv(sqrtScaler * sqrtScaler));
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";

import {square, mulDiv96, mulDiv224} from "./MulDiv.sol";

/// @title LiquidityAmounts
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
/// @author Aloe Labs, Inc.
/// @author Modified from [Uniswap](https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/LiquidityAmounts.sol)
library LiquidityAmounts {
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
        assert(sqrtRatioAX96 <= sqrtRatioBX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = _getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = _getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = _getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = _getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }

    /// @notice Computes the value of each portion of the liquidity in terms of token1
    /// @dev Each return value can fit in a uint192 if necessary
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the lower tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the upper tick boundary
    /// @param liquidity The liquidity being valued
    /// @return value0 The value of amount0 underlying `liquidity`, in terms of token1
    /// @return value1 The amount of token1
    function getValuesOfLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 value0, uint256 value1) {
        assert(sqrtRatioAX96 <= sqrtRatioBX96);

        unchecked {
            if (sqrtRatioX96 <= sqrtRatioAX96) {
                uint256 priceX128 = square(sqrtRatioX96);
                uint256 amount0XSqrtRatioAX64 = Math.mulDiv(
                    uint256(liquidity) << 64,
                    sqrtRatioBX96 - sqrtRatioAX96,
                    sqrtRatioBX96
                );

                value0 = Math.mulDiv(amount0XSqrtRatioAX64, priceX128, uint256(sqrtRatioAX96) << 96);
            } else if (sqrtRatioX96 < sqrtRatioBX96) {
                uint256 numerator = Math.mulDiv(uint256(liquidity) << 128, sqrtRatioX96, sqrtRatioBX96);

                value0 = mulDiv224(numerator, sqrtRatioBX96 - sqrtRatioX96);
                value1 = mulDiv96(liquidity, sqrtRatioX96 - sqrtRatioAX96);
            } else {
                value1 = mulDiv96(liquidity, sqrtRatioBX96 - sqrtRatioAX96);
            }
        }
    }

    /// @notice Computes the value of the liquidity in terms of token1
    /// @dev The return value can fit in a uint192 if necessary
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the lower tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the upper tick boundary
    /// @param liquidity The liquidity being valued
    /// @return The value of the underlying `liquidity`, in terms of token1
    function getValueOfLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256) {
        (uint256 value0, uint256 value1) = getValuesOfLiquidity(sqrtRatioX96, sqrtRatioAX96, sqrtRatioBX96, liquidity);
        unchecked {
            return value0 + value1;
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0. Will fit in a uint224 if you need it to
    function _getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) private pure returns (uint256 amount0) {
        amount0 = Math.mulDiv(uint256(liquidity) << 96, sqrtRatioBX96 - sqrtRatioAX96, sqrtRatioBX96) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1. Will fit in a uint192 if you need it to
    function _getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) private pure returns (uint256 amount1) {
        amount1 = mulDiv96(liquidity, sqrtRatioBX96 - sqrtRatioAX96);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {Q24, Q48} from "./constants/Q.sol"; // solhint-disable-line no-unused-import

/**
 * @notice Compresses `positions` into `zipped`. Useful for creating the return value of `IManager.callback`
 * @param positions A flattened array of ticks, each consecutive pair of indices representing one Uniswap position
 * @param zipped Encoded Uniswap positions
 */
function zip(int24[6] memory positions) pure returns (uint144 zipped) {
    assembly ("memory-safe") {
        zipped := mod(mload(positions), Q24)
        zipped := add(zipped, shl(24, mod(mload(add(positions, 32)), Q24)))
        zipped := add(zipped, shl(48, mod(mload(add(positions, 64)), Q24)))
        zipped := add(zipped, shl(72, mod(mload(add(positions, 96)), Q24)))
        zipped := add(zipped, shl(96, mod(mload(add(positions, 128)), Q24)))
        zipped := add(zipped, shl(120, mod(mload(add(positions, 160)), Q24)))
    }
}

/**
 * @notice Extracts up to three Uniswap positions from `zipped`. Each position consists of an `int24 lower` and
 * `int24 upper`, and will be included in the output array *iff* `lower != upper`. The output array is flattened
 * such that lower and upper ticks are next to each other, e.g. one position may be at indices 0 & 1, and another
 * at indices 2 & 3.
 * @dev The output array's length will be one of {0, 2, 4, 6}. We do *not* validate that `lower < upper`, nor do
 * we check whether positions actually hold liquidity. Also note that this function will revert if `zipped`
 * contains duplicate positions like [-100, 100, -100, 100].
 * @param zipped Encoded Uniswap positions. Equivalent to the layout of `int24[6] storage yourPositions`
 * @return positionsOfNonZeroWidth Flattened array of Uniswap positions that may or may not hold liquidity
 */
function extract(uint256 zipped) pure returns (int24[] memory positionsOfNonZeroWidth) {
    assembly ("memory-safe") {
        // zipped:
        // -->  xl + (xu << 24) + (yl << 48) + (yu << 72) + (zl << 96) + (zu << 120)
        // -->  |-------|-----|----|----|----|----|----|
        //      | shift | 120 | 96 | 72 | 48 | 24 |  0 |
        //      | value |  zu | zl | yu | yl | xu | xl |
        //      |-------|-----|----|----|----|----|----|

        positionsOfNonZeroWidth := mload(0x40)
        let offset := 32

        // if xl != xu
        let l := mod(zipped, Q24)
        let u := mod(shr(24, zipped), Q24)
        if iszero(eq(l, u)) {
            mstore(add(positionsOfNonZeroWidth, 32), l)
            mstore(add(positionsOfNonZeroWidth, 64), u)
            offset := 96
        }

        // if yl != yu
        l := mod(shr(48, zipped), Q24)
        u := mod(shr(72, zipped), Q24)
        if iszero(eq(l, u)) {
            let isSameAsX := eq(mod(shr(48, zipped), Q48), mod(zipped, Q48))
            if isSameAsX {
                // revert with `DuplicatePosition()`
                mstore(0x00, 0xe13355df)
                revert(0x1c, 0x04)
            }

            mstore(add(positionsOfNonZeroWidth, offset), l)
            mstore(add(positionsOfNonZeroWidth, add(offset, 32)), u)
            offset := add(offset, 64)
        }

        // if zl != zu
        l := mod(shr(96, zipped), Q24)
        u := mod(shr(120, zipped), Q24)
        if iszero(eq(l, u)) {
            let isSameAsX := eq(mod(shr(96, zipped), Q48), mod(zipped, Q48))
            let isSameAsY := eq(mod(shr(96, zipped), Q48), mod(shr(48, zipped), Q48))
            if or(isSameAsX, isSameAsY) {
                // revert with `DuplicatePosition()`
                mstore(0x00, 0xe13355df)
                revert(0x1c, 0x04)
            }

            mstore(add(positionsOfNonZeroWidth, offset), l)
            mstore(add(positionsOfNonZeroWidth, add(offset, 32)), u)
            offset := add(offset, 64)
        }

        mstore(positionsOfNonZeroWidth, shr(5, sub(offset, 32)))
        mstore(0x40, add(positionsOfNonZeroWidth, offset))
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {FixedPointMathLib as SoladyMath} from "solady/utils/FixedPointMathLib.sol";

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. \\(\sqrt{1.0001^{tick}}\\) as fixed point Q64.96 numbers. Supports
/// prices between \\(2^{-128}\\) and \\(2^{128}\\)
/// @author Aloe Labs, Inc.
/// @author Modified from [Uniswap](https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/TickMath.sol) and
/// [Aperture Finance](https://github.com/Aperture-Finance/uni-v3-lib/blob/main/src/TickMath.sol)
library TickMath {
    /// @dev The minimum tick that may be passed to `getSqrtRatioAtTick` computed from \\( log_{1.0001}2^{-128} \\)
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to `getSqrtRatioAtTick` computed from \\( log_{1.0001}2^{128} \\)
    int24 internal constant MAX_TICK = 887272;

    /// @dev The minimum value that can be returned from `getSqrtRatioAtTick`. Equivalent to `getSqrtRatioAtTick(MIN_TICK)`
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from `getSqrtRatioAtTick`. Equivalent to `getSqrtRatioAtTick(MAX_TICK)`
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
    /// @dev A threshold used for optimized bounds check, equals `MAX_SQRT_RATIO - MIN_SQRT_RATIO - 1`
    uint160 private constant MAX_SQRT_RATIO_MINUS_MIN_SQRT_RATIO_MINUS_ONE =
        1461446703485210103287273052203988822378723970342 - 4295128739 - 1;

    /* solhint-disable code-complexity */

    /// @notice Calculates \\( \sqrt{1.0001^{tick}} * 2^{96} \\)
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        unchecked {
            int256 tick256;
            uint256 absTick;

            assembly ("memory-safe") {
                // sign extend to make tick an int256 in twos complement
                tick256 := signextend(2, tick)

                // compute absolute value (in-lined method from solady)
                // --> mask = 0 if x >= 0 else -1
                let mask := sub(0, slt(tick256, 0))
                // --> If x >= 0, |x| = x = 0 ^ x
                // --> If x < 0, |x| = ~~|x| = ~(-|x| - 1) = ~(x - 1) = -1 ^ (x - 1)
                // --> Either case, |x| = mask ^ (x + mask)
                absTick := xor(mask, add(mask, tick256))

                // Equivalent: if (absTick > MAX_TICK) revert("T")
                if gt(absTick, MAX_TICK) {
                    // selector "Error(string)", [0x1c, 0x20)
                    mstore(0, 0x08c379a0)
                    // abi encoding offset
                    mstore(0x20, 0x20)
                    // reason string length 1 and 'T', [0x5f, 0x61)
                    mstore(0x41, 0x0154)
                    // 4 byte selector + 32 byte offset + 32 byte length + 1 byte reason
                    revert(0x1c, 0x45)
                }
            }

            // Equivalent: ratio = 2**128 / sqrt(1.0001) if absTick & 0x1 else 1 << 128
            uint256 ratio;
            assembly ("memory-safe") {
                ratio := and(
                    shr(
                        // 128 if absTick & 0x1 else 0
                        shl(7, and(absTick, 0x1)),
                        // upper 128 bits of 2**256 / sqrt(1.0001) where the 128th bit is 1
                        0xfffcb933bd6fad37aa2d162d1a59400100000000000000000000000000000000
                    ),
                    0x1ffffffffffffffffffffffffffffffff // mask lower 129 bits
                )
            }
            // Iterate through 1st to 19th bit of absTick because MAX_TICK < 2**20
            // Equivalent to:
            //      for i in range(1, 20):
            //          if absTick & 2 ** i:
            //              ratio = ratio * (2 ** 128 / 1.0001 ** (2 ** (i - 1))) / 2 ** 128
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

            // Equivalent: if (tick > 0) ratio = type(uint256).max / ratio
            assembly ("memory-safe") {
                if sgt(tick256, 0) {
                    ratio := div(not(0), ratio)
                }
            }

            // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
            // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
            // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
            assembly ("memory-safe") {
                sqrtPriceX96 := shr(32, add(ratio, 0xffffffff))
            }
        }
    }

    /* solhint-enable code-complexity */

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // Equivalent: require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, "R")
        assembly ("memory-safe") {
            // if sqrtPriceX96 < MIN_SQRT_RATIO, the `sub` underflows and `gt` is true
            // if sqrtPriceX96 >= MAX_SQRT_RATIO, sqrtPriceX96 - MIN_SQRT_RATIO > MAX_SQRT_RATIO - MAX_SQRT_RATIO - 1
            if gt(sub(sqrtPriceX96, MIN_SQRT_RATIO), MAX_SQRT_RATIO_MINUS_MIN_SQRT_RATIO_MINUS_ONE) {
                // selector "Error(string)", [0x1c, 0x20)
                mstore(0, 0x08c379a0)
                // abi encoding offset
                mstore(0x20, 0x20)
                // reason string length 1 and 'R', [0x5f, 0x61)
                mstore(0x41, 0x0152)
                // 4 byte selector + 32 byte offset + 32 byte length + 1 byte reason
                revert(0x1c, 0x45)
            }
        }

        // Compute the integer part of the logarithm
        // n ∈ [32, 160) so it could fit in uint8 if we wanted
        uint256 n = SoladyMath.log2(sqrtPriceX96);

        int256 log_2;
        assembly ("memory-safe") {
            log_2 := shl(64, sub(n, 96))
            let r := shr(sub(n, 31), shl(96, sqrtPriceX96))

            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)

            r := shr(127, mul(r, r))
            f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)

            r := shr(127, mul(r, r))
            f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)

            r := shr(127, mul(r, r))
            f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)

            r := shr(127, mul(r, r))
            f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)

            r := shr(127, mul(r, r))
            f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)

            r := shr(127, mul(r, r))
            f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)

            r := shr(127, mul(r, r))
            f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)

            r := shr(127, mul(r, r))
            f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)

            r := shr(127, mul(r, r))
            f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)

            r := shr(127, mul(r, r))
            f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)

            r := shr(127, mul(r, r))
            f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)

            r := shr(127, mul(r, r))
            f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)

            r := shr(127, mul(r, r))
            f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        unchecked {
            int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

            int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
            tick = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

            // Equivalent: tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow
            if (tickLow != tick) {
                uint160 sqrtRatioAtTickHi = getSqrtRatioAtTick(tick);
                assembly ("memory-safe") {
                    tick := sub(tick, gt(sqrtRatioAtTickHi, sqrtPriceX96))
                }
            }
        }
    }

    /// @notice Rounds down to the nearest tick where tick % tickSpacing == 0
    /// @param tick The tick to round
    /// @param tickSpacing The tick spacing to round to
    /// @return the floored tick
    /// @dev Ensure tick +/- tickSpacing does not overflow or underflow int24
    function floor(int24 tick, int24 tickSpacing) internal pure returns (int24) {
        int24 mod = tick % tickSpacing;

        unchecked {
            if (mod >= 0) return tick - mod;
            return tick - mod - tickSpacing;
        }
    }

    /// @notice Rounds up to the nearest tick where tick % tickSpacing == 0
    /// @param tick The tick to round
    /// @param tickSpacing The tick spacing to round to
    /// @return the ceiled tick
    /// @dev Ensure tick +/- tickSpacing does not overflow or underflow int24
    function ceil(int24 tick, int24 tickSpacing) internal pure returns (int24) {
        int24 mod = tick % tickSpacing;

        unchecked {
            if (mod > 0) return tick - mod + tickSpacing;
            return tick - mod;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC20, SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {SafeCastLib} from "solmate/utils/SafeCastLib.sol";

import {BORROWS_SCALER, ONE} from "./libraries/constants/Constants.sol";
import {Q112} from "./libraries/constants/Q.sol";
import {Rewards} from "./libraries/Rewards.sol";

import {Ledger} from "./Ledger.sol";
import {IRateModel} from "./RateModel.sol";

/// @title Lender
/// @author Aloe Labs, Inc.
/// @dev "Test everything; hold fast what is good." - 1 Thessalonians 5:21
contract Lender is Ledger {
    using FixedPointMathLib for uint256;
    using SafeCastLib for uint256;
    using SafeTransferLib for ERC20;

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    event Borrow(address indexed caller, address indexed recipient, uint256 amount, uint256 units);

    event Repay(address indexed caller, address indexed beneficiary, uint256 amount, uint256 units);

    event CreditCourier(uint32 indexed id, address indexed account);

    /*//////////////////////////////////////////////////////////////
                       CONSTRUCTOR & INITIALIZER
    //////////////////////////////////////////////////////////////*/

    constructor(address reserve) Ledger(reserve) {}

    function initialize() external {
        require(borrowIndex == 0);
        borrowIndex = uint72(ONE);
        lastAccrualTime = uint32(block.timestamp);
    }

    /// @notice Sets the `rateModel` and `reserveFactor`. Only the `FACTORY` can call this.
    function setRateModelAndReserveFactor(IRateModel rateModel_, uint8 reserveFactor_) external {
        require(msg.sender == address(FACTORY) && reserveFactor_ > 0);

        accrueInterest();
        rateModel = rateModel_;
        reserveFactor = reserveFactor_;
    }

    /**
     * @notice Sets the rewards rate. May be 0. Only the `FACTORY` can call this.
     * @param rate The rewards rate, specified in [token units per second]. If non-zero, keep between 10^17 and
     * 10^28 token units per year for smooth operation. Assuming `FACTORY.rewardsToken()` has 18 decimals, this is
     * between 0.1 and 10 billion tokens per year.
     */
    function setRewardsRate(uint64 rate) external {
        require(msg.sender == address(FACTORY));

        (Rewards.Storage storage s, uint160 a) = Rewards.load(totalSupply);
        Rewards.setRate(s, a, rate);
    }

    /// @notice Allows `borrower` to call `borrow`. One the `FACTORY` can call this.
    function whitelist(address borrower) external {
        // Requirements:
        // - `msg.sender == FACTORY` so that only the factory can whitelist borrowers
        // - `borrows[borrower] == 0` ensures we don't accidentally erase debt
        require(msg.sender == address(FACTORY) && borrows[borrower] == 0);

        // `borrow` and `repay` have to read the `borrows` mapping anyway, so setting this to 1
        // allows them to efficiently check whether a given borrower is whitelisted. This extra
        // unit of debt won't accrue interest or impact solvency calculations.
        borrows[borrower] = 1;
    }

    /*//////////////////////////////////////////////////////////////
                                REWARDS
    //////////////////////////////////////////////////////////////*/

    function claimRewards(address owner) external returns (uint96 earned) {
        // All claims are made through the `FACTORY`
        require(msg.sender == address(FACTORY));

        (Rewards.Storage storage s, uint160 a) = Rewards.load(totalSupply);
        earned = Rewards.claim(s, a, owner, balanceOf(owner));
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Mints `shares` to `beneficiary` by depositing exactly `amount` of underlying tokens
     * @dev `deposit` is more efficient than `mint` and is the recommended way of depositing. Also
     * supports the additional flow where you prepay `amount` instead of relying on approve/transferFrom.
     * @param amount The amount of underlying tokens to deposit
     * @param beneficiary The receiver of `shares`
     * @param courierId The ID of the courier (or 0, to indicate lack thereof) that will receive a cut of
     * `beneficiary`'s future interest. Only takes effect when `balanceOf(beneficiary) == 0`. In
     * all other cases, pass 0 to avoid wasting gas on courier-related checks.
     * @return shares The number of shares (banknotes) minted to `beneficiary`
     */
    function deposit(uint256 amount, address beneficiary, uint32 courierId) public returns (uint256 shares) {
        if (courierId != 0) {
            // Callers are free to set their own courier, but they need permission to mess with others'
            if (msg.sender != beneficiary) {
                require(allowance[beneficiary][msg.sender] > 0, "Aloe: courier");
                allowance[beneficiary][msg.sender] = 0;
            }

            (address courier, uint16 cut) = FACTORY.couriers(courierId);

            require(
                // Prevent `RESERVE` from having a courier, since its principle wouldn't be tracked properly
                (beneficiary != RESERVE) &&
                    // Payout logic can't handle self-reference, so don't let accounts credit themselves
                    (beneficiary != courier) &&
                    // Make sure `cut` has been set
                    (cut != 0),
                "Aloe: courier"
            );
        }

        // Accrue interest and update reserves
        (Cache memory cache, uint256 inventory) = _load();

        // Convert `amount` to `shares`
        shares = _convertToShares(amount, inventory, cache.totalSupply, /* roundUp: */ false);
        require(shares != 0, "Aloe: zero impact");

        // Mint shares, track rewards, and (if applicable) handle courier accounting
        cache.totalSupply = _mint(beneficiary, shares, amount, cache.totalSupply, courierId);
        // Assume tokens are transferred
        cache.lastBalance += amount;

        // Save state to storage (thus far, only mappings have been updated, so we must address everything else)
        _save(cache, /* didChangeBorrowBase: */ false);

        // Ensure tokens are transferred
        ERC20 asset_ = asset();
        bool didPrepay = cache.lastBalance <= asset_.balanceOf(address(this));
        if (!didPrepay) {
            asset_.safeTransferFrom(msg.sender, address(this), amount);
        }

        emit Deposit(msg.sender, beneficiary, amount, shares);
    }

    function deposit(uint256 amount, address beneficiary) external returns (uint256 shares) {
        shares = deposit(amount, beneficiary, 0);
    }

    function mint(uint256 shares, address beneficiary) external returns (uint256 amount) {
        amount = previewMint(shares);
        deposit(amount, beneficiary, 0);
    }

    /**
     * @notice Burns `shares` from `owner` and sends `amount` of underlying tokens to `receiver`. If
     * `owner` has a courier, additional shares will be transferred from `owner` to the courier as a fee.
     * @dev `redeem` is more efficient than `withdraw` and is the recommended way of withdrawing
     * @param shares The number of shares to burn in exchange for underlying tokens. To burn all your shares,
     * you can pass `maxRedeem(owner)`. If `maxRedeem(owner)` is changing over time (due to a courier or
     * high utilization) you can pass `type(uint256).max` and it will be computed in-place.
     * @param recipient The receiver of `amount` of underlying tokens
     * @param owner The user from whom shares are taken (for both the burn and possible fee transfer)
     * @return amount The number of underlying tokens transferred to `recipient`
     */
    function redeem(uint256 shares, address recipient, address owner) public returns (uint256 amount) {
        if (shares == type(uint256).max) shares = maxRedeem(owner);

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender];
            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Accrue interest and update reserves
        (Cache memory cache, uint256 inventory) = _load();

        // Convert `shares` to `amount`
        amount = _convertToAssets(shares, inventory, cache.totalSupply, /* roundUp: */ false);
        require(amount != 0, "Aloe: zero impact");

        // Burn shares, track rewards, and (if applicable) handle courier accounting
        cache.totalSupply = _burn(owner, shares, inventory, cache.totalSupply);
        // Assume tokens are transferred
        cache.lastBalance -= amount;

        // Save state to storage (thus far, only mappings have been updated, so we must address everything else)
        _save(cache, /* didChangeBorrowBase: */ false);

        // Transfer tokens
        asset().safeTransfer(recipient, amount);

        emit Withdraw(msg.sender, recipient, owner, amount, shares);
    }

    function withdraw(uint256 amount, address recipient, address owner) external returns (uint256 shares) {
        shares = previewWithdraw(amount);
        redeem(shares, recipient, owner);
    }

    /*//////////////////////////////////////////////////////////////
                           BORROW/REPAY LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Sends `amount` of `asset` to `recipient` and increases `msg.sender`'s debt by `units`
    function borrow(uint256 amount, address recipient) external returns (uint256 units) {
        // Accrue interest and update reserves
        (Cache memory cache, ) = _load();

        unchecked {
            uint256 b = borrows[msg.sender];
            require(b != 0, "Aloe: not a borrower");

            // Convert `amount` to `units`
            units = (amount * BORROWS_SCALER) / cache.borrowIndex;

            // Track borrows
            borrows[msg.sender] = b + units;
        }
        cache.borrowBase += units;
        // Assume tokens are transferred
        cache.lastBalance -= amount;

        // Save state to storage (thus far, only mappings have been updated, so we must address everything else)
        _save(cache, /* didChangeBorrowBase: */ true);

        // Transfer tokens
        asset().safeTransfer(recipient, amount);

        emit Borrow(msg.sender, recipient, amount, units);
    }

    /**
     * @notice Reduces `beneficiary`'s debt by `units`, assuming someone has pre-paid `amount` of `asset`. To repay
     * all debt for some account, call `repay(borrowBalance(account), account)`.
     * @dev To avoid frontrunning, `amount` should be pre-paid in the same transaction as the `repay` call.
     * @custom:example ```solidity
     *   PERMIT2.permitTransferFrom(
     *     permitMsg,
     *     IPermit2.SignatureTransferDetails({to: address(lender), requestedAmount: amount}),
     *     msg.sender,
     *     signature
     *   );
     *   lender.repay(amount, beneficiary)
     * ```
     */
    function repay(uint256 amount, address beneficiary) external returns (uint256 units) {
        // Accrue interest and update reserves
        (Cache memory cache, ) = _load();

        unchecked {
            uint256 b = borrows[beneficiary];

            // Convert `amount` to `units`
            units = (amount * BORROWS_SCALER) / cache.borrowIndex;
            if (!(units < b)) {
                units = b - 1;

                uint256 maxRepay = (units * cache.borrowIndex).unsafeDivUp(BORROWS_SCALER);
                require(b > 1 && amount <= maxRepay, "Aloe: repay too much");
            }

            // Track borrows
            borrows[beneficiary] = b - units;
            cache.borrowBase -= units;
        }
        // Assume tokens are transferred
        cache.lastBalance += amount;

        // Save state to storage (thus far, only mappings have been updated, so we must address everything else)
        _save(cache, /* didChangeBorrowBase: */ true);

        // Ensure tokens are transferred
        require(cache.lastBalance <= asset().balanceOf(address(this)), "Aloe: insufficient pre-pay");

        emit Repay(msg.sender, beneficiary, amount, units);
    }

    function accrueInterest() public returns (uint72) {
        (Cache memory cache, ) = _load();
        _save(cache, /* didChangeBorrowBase: */ false);
        return uint72(cache.borrowIndex);
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 shares) external returns (bool) {
        allowance[msg.sender][spender] = shares;

        emit Approval(msg.sender, spender, shares);

        return true;
    }

    function transfer(address to, uint256 shares) external returns (bool) {
        accrueInterest();
        _transfer(msg.sender, to, shares);

        return true;
    }

    function transferFrom(address from, address to, uint256 shares) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - shares;

        accrueInterest();
        _transfer(from, to, shares);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             ERC2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "Aloe: permit expired");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "Aloe: permit invalid");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    /// @dev Transfers `shares` from `from` to `to`, iff neither of them have a courier
    function _transfer(address from, address to, uint256 shares) private {
        (Rewards.Storage storage s, uint160 a) = Rewards.load(totalSupply);

        unchecked {
            // From most to least significant...
            // -------------------------------
            // | courier id       | 32 bits  |
            // | user's principle | 112 bits |
            // | user's balance   | 112 bits |
            // -------------------------------
            uint256 data;

            data = balances[from];
            require(data >> 224 == 0 && shares <= data % Q112);
            balances[from] = data - shares;

            Rewards.updateUserState(s, a, from, data % Q112);

            data = balances[to];
            require(data >> 224 == 0);
            balances[to] = data + shares;

            Rewards.updateUserState(s, a, to, data % Q112);
        }

        emit Transfer(from, to, shares);
    }

    /// @dev Make sure to do something with the return value, `newTotalSupply`!
    function _mint(
        address to,
        uint256 shares,
        uint256 amount,
        uint256 totalSupply_,
        uint32 courierId
    ) private returns (uint256 newTotalSupply) {
        // Need to compute `newTotalSupply` with checked math to avoid overflow
        newTotalSupply = totalSupply_ + shares;

        unchecked {
            // From most to least significant...
            // -------------------------------
            // | courier id       | 32 bits  |
            // | user's principle | 112 bits |
            // | user's balance   | 112 bits |
            // -------------------------------
            uint256 data = balances[to];

            // Get rewards accounting out of the way
            (Rewards.Storage storage s, uint160 a) = Rewards.load(totalSupply_);
            Rewards.updatePoolState(s, a);
            Rewards.updateUserState(s, a, to, data % Q112);

            // Only set courier if balance is 0. Otherwise previous courier may be cheated out of fees.
            if (data % Q112 == 0) {
                data = uint256(courierId) << 224;
                emit CreditCourier(courierId, to);
            }

            // Keep track of principle iff `to` has a courier
            if (data >> 224 != 0) {
                require(amount + ((data >> 112) % Q112) < Q112);
                data += amount << 112;
            }

            // Keep track of balance regardless of courier.
            // Since `totalSupply` fits in uint112, the user's balance will too. No need to check here.
            balances[to] = data + shares;
        }

        emit Transfer(address(0), to, shares);
    }

    /// @dev Make sure to do something with the return value, `newTotalSupply`!
    function _burn(
        address from,
        uint256 shares,
        uint256 inventory,
        uint256 totalSupply_
    ) private returns (uint256 newTotalSupply) {
        unchecked {
            // Can compute `newTotalSupply` with unchecked math since other checks cover underflow
            newTotalSupply = totalSupply_ - shares;

            // From most to least significant...
            // -------------------------------
            // | courier id       | 32 bits  |
            // | user's principle | 112 bits |
            // | user's balance   | 112 bits |
            // -------------------------------
            uint256 data = balances[from];
            uint256 balance = data % Q112;

            // Get rewards accounting out of the way
            (Rewards.Storage storage s, uint160 a) = Rewards.load(totalSupply_);
            Rewards.updatePoolState(s, a);
            Rewards.updateUserState(s, a, from, balance);

            uint32 id = uint32(data >> 224);
            if (id != 0) {
                uint256 principleAssets = (data >> 112) % Q112;
                uint256 principleShares = principleAssets.mulDivUp(totalSupply_, inventory);

                if (balance > principleShares) {
                    (address courier, uint16 cut) = FACTORY.couriers(id);

                    // Compute total fee owed to courier. Take it out of balance so that
                    // comparison is correct later on (`shares <= balance`)
                    uint256 fee = ((balance - principleShares) * cut) / 10_000;
                    balance -= fee;

                    // Compute portion of fee to pay out during this burn.
                    fee = (fee * shares) / balance;

                    // Send `fee` from `from` to `courier`.
                    // NOTE: We skip principle update on courier, so if couriers credit
                    // each other, 100% of `fee` is treated as profit and will pass through
                    // to the next courier.
                    data -= fee;
                    Rewards.updateUserState(s, a, courier, ((balances[courier] += fee) - fee) % Q112);
                    emit Transfer(from, courier, fee);
                }

                // Update principle
                data -= ((principleAssets * shares) / balance) << 112;
            }

            require(shares <= balance);
            balances[from] = data - shares;
        }

        emit Transfer(from, address(0), shares);
    }

    function _load() private returns (Cache memory cache, uint256 inventory) {
        // Accrue interest (only in memory)
        uint256 newTotalSupply;
        (cache, inventory, newTotalSupply) = _previewInterest(_getCache());

        // Update reserves (new `totalSupply` is only in memory, but `balances[RESERVE]` is updated in storage)
        if (newTotalSupply > cache.totalSupply) {
            cache.totalSupply = _mint(RESERVE, newTotalSupply - cache.totalSupply, 0, cache.totalSupply, 0);
        }
    }

    function _save(Cache memory cache, bool didChangeBorrowBase) private {
        // `cache.lastAccrualTime == 0` implies that `cache.borrowIndex` was updated
        if (cache.lastAccrualTime == 0 || didChangeBorrowBase) {
            borrowBase = cache.borrowBase.safeCastTo184();
            borrowIndex = cache.borrowIndex.safeCastTo72();
        }

        totalSupply = cache.totalSupply.safeCastTo112();
        lastBalance = cache.lastBalance.safeCastTo112();
        lastAccrualTime = uint32(block.timestamp);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {IUniswapV3Pool} from "v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {
    IV_SCALE,
    IV_COLD_START,
    IV_CHANGE_PER_UPDATE,
    IV_EMA_GAIN_POS,
    IV_EMA_GAIN_NEG,
    UNISWAP_AVG_WINDOW,
    FEE_GROWTH_AVG_WINDOW,
    FEE_GROWTH_ARRAY_LENGTH,
    FEE_GROWTH_SAMPLE_PERIOD
} from "./libraries/constants/Constants.sol";
import {Oracle} from "./libraries/Oracle.sol";
import {Volatility} from "./libraries/Volatility.sol";

/// @title VolatilityOracle
/// @author Aloe Labs, Inc.
/// @dev "Test everything; hold fast what is good." - 1 Thessalonians 5:21
contract VolatilityOracle {
    event Update(IUniswapV3Pool indexed pool, uint160 sqrtMeanPriceX96, uint104 iv);

    struct LastWrite {
        uint8 index;
        uint40 time;
        uint104 oldIV;
        uint104 newIV;
    }

    mapping(IUniswapV3Pool => Volatility.PoolMetadata) public cachedMetadata;

    mapping(IUniswapV3Pool => Volatility.FeeGrowthGlobals[FEE_GROWTH_ARRAY_LENGTH]) public feeGrowthGlobals;

    mapping(IUniswapV3Pool => LastWrite) public lastWrites;

    function prepare(IUniswapV3Pool pool) external {
        cachedMetadata[pool] = _getPoolMetadata(pool);

        if (lastWrites[pool].time == 0) {
            feeGrowthGlobals[pool][0] = _getFeeGrowthGlobalsNow(pool);
            lastWrites[pool] = LastWrite(0, uint40(block.timestamp), IV_COLD_START, IV_COLD_START);
        }
    }

    function update(IUniswapV3Pool pool, uint40 seed) external returns (uint56, uint160, uint256) {
        unchecked {
            // Read `lastWrite` info from storage
            LastWrite memory lastWrite = lastWrites[pool];
            require(lastWrite.time > 0);

            // We need to call `Oracle.consult` even if we're going to return early, so go ahead and do it
            (uint56 metric, uint160 sqrtMeanPriceX96) = Oracle.consult(pool, seed);

            // If fewer than `FEE_GROWTH_SAMPLE_PERIOD` seconds have elapsed, return early.
            // We still fetch the latest TWAP, but we do not sample feeGrowthGlobals or update IV.
            if (block.timestamp - lastWrite.time < FEE_GROWTH_SAMPLE_PERIOD) {
                return (metric, sqrtMeanPriceX96, _interpolateIV(lastWrite));
            }

            // Populate `FeeGrowthGlobals`
            Volatility.FeeGrowthGlobals[FEE_GROWTH_ARRAY_LENGTH] storage arr = feeGrowthGlobals[pool];
            Volatility.FeeGrowthGlobals memory a = _getFeeGrowthGlobalsOld(arr, lastWrite.index);
            Volatility.FeeGrowthGlobals memory b = _getFeeGrowthGlobalsNow(pool);

            // Bring `lastWrite` forward so it's essentially "currentWrite"
            lastWrite.index = uint8((lastWrite.index + 1) % FEE_GROWTH_ARRAY_LENGTH);
            lastWrite.time = uint40(block.timestamp);
            lastWrite.oldIV = lastWrite.newIV;
            // lastWrite.newIV is updated below, iff feeGrowthGlobals samples are ≈`FEE_GROWTH_AVG_WINDOW` hours apart

            if (
                _isInInterval({
                    min: FEE_GROWTH_AVG_WINDOW - FEE_GROWTH_SAMPLE_PERIOD / 2,
                    x: b.timestamp - a.timestamp,
                    max: FEE_GROWTH_AVG_WINDOW + FEE_GROWTH_SAMPLE_PERIOD / 2
                })
            ) {
                // Update exponential moving average with a new IV estimate
                lastWrite.newIV = _ema(
                    int256(uint256(lastWrite.oldIV)),
                    int256(Volatility.estimate(cachedMetadata[pool], sqrtMeanPriceX96, a, b, IV_SCALE))
                );

                // Clamp `newIV` so it lies within [previous - maxChange, previous + maxChange]
                if (lastWrite.newIV > lastWrite.oldIV + IV_CHANGE_PER_UPDATE) {
                    lastWrite.newIV = lastWrite.oldIV + IV_CHANGE_PER_UPDATE;
                } else if (lastWrite.newIV + IV_CHANGE_PER_UPDATE < lastWrite.oldIV) {
                    lastWrite.newIV = lastWrite.oldIV - IV_CHANGE_PER_UPDATE;
                }
            }

            // Store the new feeGrowthGlobals sample and update `lastWrites`
            arr[lastWrite.index] = b;
            lastWrites[pool] = lastWrite;

            emit Update(pool, sqrtMeanPriceX96, lastWrite.newIV);
            return (metric, sqrtMeanPriceX96, lastWrite.oldIV); // `lastWrite.oldIV == _interpolateIV(lastWrite)` here
        }
    }

    function consult(IUniswapV3Pool pool, uint40 seed) external view returns (uint56, uint160, uint256) {
        (uint56 metric, uint160 sqrtMeanPriceX96) = Oracle.consult(pool, seed);
        return (metric, sqrtMeanPriceX96, _interpolateIV(lastWrites[pool]));
    }

    function _ema(int256 oldIV, int256 estimate) private pure returns (uint104) {
        unchecked {
            int256 gain = estimate > oldIV ? IV_EMA_GAIN_POS : IV_EMA_GAIN_NEG;
            uint256 newIV = uint256(oldIV + (estimate - oldIV) / gain);
            return newIV > type(uint104).max ? type(uint104).max : uint104(newIV);
        }
    }

    function _interpolateIV(LastWrite memory lastWrite) private view returns (uint256) {
        unchecked {
            int256 deltaT = int256(block.timestamp - lastWrite.time);
            if (deltaT >= int256(FEE_GROWTH_SAMPLE_PERIOD)) return lastWrite.newIV;

            int256 oldIV = int256(uint256(lastWrite.oldIV));
            int256 newIV = int256(uint256(lastWrite.newIV));
            return uint256(oldIV + ((newIV - oldIV) * deltaT) / int256(FEE_GROWTH_SAMPLE_PERIOD));
        }
    }

    function _getPoolMetadata(IUniswapV3Pool pool) private view returns (Volatility.PoolMetadata memory metadata) {
        (, , uint16 observationIndex, uint16 observationCardinality, , uint8 feeProtocol, ) = pool.slot0();
        // We want observations from `UNISWAP_AVG_WINDOW` and `UNISWAP_AVG_WINDOW * 2` seconds ago. Since observation
        // frequency varies with `pool` usage, we apply an extra 3x safety factor. If `pool` usage increases,
        // oracle cardinality may need to be increased as well. This should be monitored off-chain.
        require(
            Oracle.getMaxSecondsAgo(pool, observationIndex, observationCardinality) > UNISWAP_AVG_WINDOW * 6,
            "Aloe: cardinality"
        );

        uint24 fee = pool.fee();
        metadata.gamma0 = fee;
        metadata.gamma1 = fee;
        unchecked {
            if (feeProtocol % 16 != 0) metadata.gamma0 -= fee / (feeProtocol % 16);
            if (feeProtocol >> 4 != 0) metadata.gamma1 -= fee / (feeProtocol >> 4);
        }

        metadata.tickSpacing = pool.tickSpacing();
    }

    function _getFeeGrowthGlobalsNow(IUniswapV3Pool pool) private view returns (Volatility.FeeGrowthGlobals memory) {
        return
            Volatility.FeeGrowthGlobals(
                pool.feeGrowthGlobal0X128(),
                pool.feeGrowthGlobal1X128(),
                uint32(block.timestamp)
            );
    }

    function _getFeeGrowthGlobalsOld(
        Volatility.FeeGrowthGlobals[FEE_GROWTH_ARRAY_LENGTH] storage arr,
        uint256 index
    ) private view returns (Volatility.FeeGrowthGlobals memory) {
        uint256 target = block.timestamp - FEE_GROWTH_AVG_WINDOW;

        // See if the newest sample is nearest to `target`
        Volatility.FeeGrowthGlobals memory sample = arr[index];
        if (sample.timestamp <= target) return sample;

        // See if the oldest sample is nearest to `target`
        uint256 next = (index + 1) % FEE_GROWTH_ARRAY_LENGTH;
        sample = arr[next];
        if (sample.timestamp >= target) return sample;

        // Now that we've checked the edges, we know the best sample lies somewhere within the array.
        return _binarySearch(arr, next, target);
    }

    function _binarySearch(
        Volatility.FeeGrowthGlobals[FEE_GROWTH_ARRAY_LENGTH] storage arr,
        uint256 l,
        uint256 target
    ) private view returns (Volatility.FeeGrowthGlobals memory) {
        Volatility.FeeGrowthGlobals memory beforeOrAt;
        Volatility.FeeGrowthGlobals memory atOrAfter;

        unchecked {
            uint256 r = l + (FEE_GROWTH_ARRAY_LENGTH - 1);
            uint256 i;
            while (true) {
                i = (l + r) / 2;

                beforeOrAt = arr[i % FEE_GROWTH_ARRAY_LENGTH];
                atOrAfter = arr[(i + 1) % FEE_GROWTH_ARRAY_LENGTH];

                if (_isInInterval(beforeOrAt.timestamp, target, atOrAfter.timestamp)) break;

                if (target < beforeOrAt.timestamp) r = i - 1;
                else l = i + 1;
            }

            uint256 errorA = target - beforeOrAt.timestamp;
            uint256 errorB = atOrAfter.timestamp - target;

            return errorB < errorA ? atOrAfter : beforeOrAt;
        }
    }

    function _isInInterval(uint256 min, uint256 x, uint256 max) private pure returns (bool) {
        return min <= x && x <= max;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.15;

import {Create2} from "./Create2.sol";

/// @title ClonesWithImmutableArgs
/// @author wighawag, zefram.eth, Saw-mon & Natalie, wminshew
/// @notice Enables creating clone contracts with immutable args
library ClonesWithImmutableArgs {
    // abi.encodeWithSignature("CreateFail()")
    uint256 private constant _CREATE_FAIL_ERROR_SIG =
        0xebfef18800000000000000000000000000000000000000000000000000000000;

    // abi.encodeWithSignature("IdentityPrecompileFailure()")
    uint256 private constant _IDENTITY_PRECOMPILE_ERROR_SIG =
        0x3a008ffa00000000000000000000000000000000000000000000000000000000;

    uint256 private constant _CUSTOM_ERROR_SIG_PTR = 0x0;

    uint256 private constant _CUSTOM_ERROR_LENGTH = 0x4;

    uint256 private constant _BOOTSTRAP_LENGTH = 0x3f; // 63 (43 instructions + 20 for implementation address)

    /// @notice Creates a clone proxy of the implementation contract with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function clone(address implementation, bytes memory data) internal returns (address instance) {
        (uint256 creationPtr, uint256 creationSize) = _getCreationCode(implementation, data);

        assembly ("memory-safe") {
            instance := create(0, creationPtr, creationSize)

            // if the create failed, the instance address won't be set
            if iszero(instance) {
                mstore(_CUSTOM_ERROR_SIG_PTR, _CREATE_FAIL_ERROR_SIG)
                revert(_CUSTOM_ERROR_SIG_PTR, _CUSTOM_ERROR_LENGTH)
            }
        }
    }

    /// @notice Creates a clone proxy of the implementation contract with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param salt The salt for create2
    /// @param data Encoded immutable args
    /// @return instance The address of the created clone
    function cloneDeterministic(
        address implementation,
        bytes32 salt,
        bytes memory data
    ) internal returns (address payable instance) {
        (uint256 creationPtr, uint256 creationSize) = _getCreationCode(implementation, data);

        assembly ("memory-safe") {
            instance := create2(0, creationPtr, creationSize, salt)

            // if the create failed, the instance address won't be set
            if iszero(instance) {
                mstore(_CUSTOM_ERROR_SIG_PTR, _CREATE_FAIL_ERROR_SIG)
                revert(_CUSTOM_ERROR_SIG_PTR, _CUSTOM_ERROR_LENGTH)
            }
        }
    }

    /// @notice Predicts the address where a deterministic clone of implementation will be deployed
    /// @param implementation The implementation contract to clone
    /// @param salt The salt for create2
    /// @param data Encoded immutable args
    /// @return predicted The predicted address of the created clone exists
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer,
        bytes memory data
    ) internal view returns (address predicted) {
        (uint256 creationPtr, uint256 creationSize) = _getCreationCode(implementation, data);

        bytes32 bytecodeHash;
        assembly ("memory-safe") {
            bytecodeHash := keccak256(creationPtr, creationSize)
        }

        predicted = Create2.computeAddress(salt, bytecodeHash, deployer);
    }

    /// @notice Predicts the address where a deterministic clone of implementation will be deployed
    /// @param implementation The implementation contract to clone
    /// @param salt The salt for create2
    /// @param data Encoded immutable args
    /// @return predicted The predicted address of the created clone exists
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        bytes memory data
    ) internal view returns (address predicted) {
        predicted = predictDeterministicAddress(implementation, salt, address(this), data);
    }

    /// @notice Computes the creation code for a clone with immutable args
    /// @dev data cannot exceed 65535 bytes, since 2 bytes are used to store the data length
    /// @param implementation The implementation contract to clone
    /// @param data Encoded immutable args
    /// @return ptr The ptr to the clone's bytecode
    /// @return creationSize The size of the clone to be created
    function _getCreationCode(
        address implementation,
        bytes memory data
    ) private view returns (uint256 ptr, uint256 creationSize) {
        // unrealistic for memory ptr or data length to exceed 256 bits
        assembly ("memory-safe") {
            let extraLength := add(mload(data), 2) // +2 bytes for telling how much data there is appended to the call
            creationSize := add(extraLength, _BOOTSTRAP_LENGTH)
            let runSize := sub(creationSize, 0x0a)

            // free memory pointer
            ptr := mload(0x40)

            // -------------------------------------------------------------------------------------------------------------
            // CREATION (10 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // 61 runtime  | PUSH2 runtime (r)     | r                       | –
            // 3d          | RETURNDATASIZE        | 0 r                     | –
            // 81          | DUP2                  | r 0 r                   | –
            // 60 offset   | PUSH1 offset (o)      | o r 0 r                 | –
            // 3d          | RETURNDATASIZE        | 0 o r 0 r               | –
            // 39          | CODECOPY              | 0 r                     | [0 - runSize): runtime code
            // f3          | RETURN                |                         | [0 - runSize): runtime code

            // -------------------------------------------------------------------------------------------------------------
            // RUNTIME (53 bytes + extraLength)
            // -------------------------------------------------------------------------------------------------------------

            // --- copy calldata to memmory ---
            // 36          | CALLDATASIZE          | cds                     | –
            // 3d          | RETURNDATASIZE        | 0 cds                   | –
            // 3d          | RETURNDATASIZE        | 0 0 cds                 | –
            // 37          | CALLDATACOPY          |                         | [0 - cds): calldata

            // --- keep some values in stack ---
            // 3d          | RETURNDATASIZE        | 0                       | [0 - cds): calldata
            // 3d          | RETURNDATASIZE        | 0 0                     | [0 - cds): calldata
            // 3d          | RETURNDATASIZE        | 0 0 0                   | [0 - cds): calldata
            // 3d          | RETURNDATASIZE        | 0 0 0 0                 | [0 - cds): calldata
            // 61 extra    | PUSH2 extra (e)       | e 0 0 0 0               | [0 - cds): calldata

            // --- copy extra data to memory ---
            // 80          | DUP1                  | e e 0 0 0 0             | [0 - cds): calldata
            // 60 0x35     | PUSH1 0x35            | 0x35 e e 0 0 0 0        | [0 - cds): calldata
            // 36          | CALLDATASIZE          | cds 0x35 e e 0 0 0 0    | [0 - cds): calldata
            // 39          | CODECOPY              | e 0 0 0 0               | [0 - cds): calldata, [cds - cds + e): extraData

            // --- delegate call to the implementation contract ---
            // 36          | CALLDATASIZE          | cds e 0 0 0 0           | [0 - cds): calldata, [cds - cds + e): extraData
            // 01          | ADD                   | cds+e 0 0 0 0           | [0 - cds): calldata, [cds - cds + e): extraData
            // 3d          | RETURNDATASIZE        | 0 cds+e 0 0 0 0         | [0 - cds): calldata, [cds - cds + e): extraData
            // 73 addr     | PUSH20 addr           | addr 0 cds+e 0 0 0 0    | [0 - cds): calldata, [cds - cds + e): extraData
            // 5a          | GAS                   | gas addr 0 cds+e 0 0 0 0| [0 - cds): calldata, [cds - cds + e): extraData
            // f4          | DELEGATECALL          | success 0 0             | [0 - cds): calldata, [cds - cds + e): extraData

            // --- copy return data to memory ---
            // 3d          | RETURNDATASIZE        | rds success 0 0         | [0 - cds): calldata, [cds - cds + e): extraData
            // 3d          | RETURNDATASIZE        | rds rds success 0 0     | [0 - cds): calldata, [cds - cds + e): extraData
            // 93          | SWAP4                 | 0 rds success 0 rds     | [0 - cds): calldata, [cds - cds + e): extraData
            // 80          | DUP1                  | 0 0 rds success 0 rds   | [0 - cds): calldata, [cds - cds + e): extraData
            // 3e          | RETURNDATACOPY        | success 0 rds           | [0 - rds): returndata, ... the rest might be dirty

            // 60 0x33     | PUSH1 0x33            | 0x33 success 0 rds      | [0 - rds): returndata, ... the rest might be dirty
            // 57          | JUMPI                 | 0 rds                   | [0 - rds): returndata, ... the rest might be dirty

            // --- revert ---
            // fd          | REVERT                |                         | [0 - rds): returndata, ... the rest might be dirty

            // --- return ---
            // 5b          | JUMPDEST              | 0 rds                   | [0 - rds): returndata, ... the rest might be dirty
            // f3          | RETURN                |                         | [0 - rds): returndata, ... the rest might be dirty

            mstore(
                ptr,
                or(
                    // ⎬  ♠︎♠︎♠︎♠︎         ♣︎♣︎         ⎨           -              ♥︎♥︎♥︎♥︎-     ♦︎♦︎      -           >
                    hex"610000_3d_81_600a_3d_39_f3_36_3d_3d_37_3d_3d_3d_3d_610000_80_6035_36_39_36_01_3d_73", // 30 bytes
                    or(shl(0xe8, runSize), shl(0x58, extraLength)) // ♠︎=runSize, ♥︎=extraLength
                )
            )

            mstore(add(ptr, 0x1e), shl(0x60, implementation)) // 20 bytes

            //                        >     -                 ☼☼   -        |
            mstore(add(ptr, 0x32), hex"5a_f4_3d_3d_93_80_3e_6033_57_fd_5b_f3") // 13 bytes

            // -------------------------------------------------------------------------------------------------------------
            // APPENDED DATA (Accessible from extcodecopy)
            // (but also send as appended data to the delegatecall)
            // -------------------------------------------------------------------------------------------------------------

            extraLength := sub(extraLength, 2)

            if iszero(
                staticcall(
                    gas(),
                    0x04, // identity precompile
                    add(data, 0x20), // copy source
                    extraLength,
                    add(ptr, _BOOTSTRAP_LENGTH), // copy destination
                    extraLength
                )
            ) {
                mstore(_CUSTOM_ERROR_SIG_PTR, _IDENTITY_PRECOMPILE_ERROR_SIG)
                revert(_CUSTOM_ERROR_SIG_PTR, _CUSTOM_ERROR_LENGTH)
            }

            mstore(add(add(ptr, _BOOTSTRAP_LENGTH), extraLength), shl(0xf0, add(extraLength, 2)))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

import {MAX_RATE, ONE} from "./libraries/constants/Constants.sol";

interface IRateModel {
    /**
     * @notice Specifies the percentage yield per second for a `lender`. Need not be a pure function
     * of `utilization`. To convert to APY: `(1 + returnValue / 1e12) ** secondsPerYear - 1`
     * @param utilization The `lender`'s total borrows divided by total assets, scaled up by 1e18
     * @param lender The `Lender` to examine
     * @return The percentage yield per second, scaled up by 1e12
     */
    function getYieldPerSecond(uint256 utilization, address lender) external view returns (uint256);
}

/// @title RateModel
/// @author Aloe Labs, Inc.
/// @dev "Test everything; hold fast what is good." - 1 Thessalonians 5:21
contract RateModel is IRateModel {
    uint256 private constant _A = 6.1010463348e20;

    uint256 private constant _B = _A / 1e18;

    /// @inheritdoc IRateModel
    function getYieldPerSecond(uint256 utilization, address) external pure returns (uint256) {
        unchecked {
            return (utilization < 0.99e18) ? _A / (1e18 - utilization) - _B : 60400;
        }
    }
}

library SafeRateLib {
    using FixedPointMathLib for uint256;

    function getAccrualFactor(IRateModel rateModel, uint256 utilization, uint256 dt) internal view returns (uint256) {
        uint256 rate;

        // Essentially `rate = rateModel.getYieldPerSecond(utilization, address(this)) ?? 0`, i.e. if the call
        // fails, we set `rate = 0` instead of reverting. Solidity's try/catch could accomplish the same thing,
        // but this is slightly more gas efficient.
        bytes memory encodedCall = abi.encodeCall(IRateModel.getYieldPerSecond, (utilization, address(this)));
        assembly ("memory-safe") {
            let success := staticcall(100000, rateModel, add(encodedCall, 32), mload(encodedCall), 0, 32)
            rate := mul(success, mload(0))
        }

        return _computeAccrualFactor(rate, dt);
    }

    function _computeAccrualFactor(uint256 rate, uint256 dt) private pure returns (uint256) {
        if (rate > MAX_RATE) rate = MAX_RATE;
        if (dt > 1 weeks) dt = 1 weeks;

        unchecked {
            return (ONE + rate).rpow(dt, ONE);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// @dev Returns \\( 10^{12} \cdot e^{\frac{x}{10^{12}}} \\) or `type(int256).max`, whichever is smaller
/// @custom:author Modified from [Solady](https://github.com/Vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol#L113)
function exp1e12(int256 x) pure returns (int256 r) {
    unchecked {
        // When the result is < 0.5 we return zero. This happens when
        // x <= floor(ln(0.5 / 1e12) * 1e12) ~ -28e12
        if (x <= -28324168296488) return r;
        // When the result is > (2**255 - 1) we cannot represent it as an int.
        // This happens when x >= floor(ln((2**255 - 1) / 1e12) * 1e12) ~ 149e12.
        if (x >= 149121509926857) return type(int256).max;

        // x is now in the range (-29, 150) * 1e12. Convert to (-29, 150) * 2**96
        // for more intermediate precision and a binary basis. This base conversion
        // is a multiplication by 2**96 / 1e12 = 2**84 / 5**12.
        x = (x << 84) / 5 ** 12;

        // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
        // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
        // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
        int256 k = ((x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
        x = x - k * 54916777467707473351141471128;

        // k is in the range [-41, 215].

        // Evaluate using a (6, 7)-term rational approximation.
        // p is made monic, we'll multiply by a scale factor later.
        int256 y = x + 1346386616545796478920950773328;
        y = ((y * x) >> 96) + 57155421227552351082224309758442;
        int256 p = y + x - 94201549194550492254356042504812;
        p = ((p * y) >> 96) + 28719021644029726153956944680412240;
        p = p * x + (4385272521454847904659076985693276 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        int256 q = x - 2855989394907223263936484059900;
        q = ((q * x) >> 96) + 50020603652535783019961831881945;
        q = ((q * x) >> 96) - 533845033583426703283633433725380;
        q = ((q * x) >> 96) + 3604857256930695427073651918091429;
        q = ((q * x) >> 96) - 14423608567350463180887372962807573;
        q = ((q * x) >> 96) + 26449188498355588339934803723976023;

        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial won't have zeros in the domain as all its roots are complex.
            // No scaling is necessary because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r should be in the range (0.09, 0.25) * 2**96.

        // We now need to multiply r by:
        // * the scale factor s = ~6.031367120.
        // * the 2**k factor from the range reduction.
        // * the 1e12 / 2**96 factor for base conversion.
        r = int256((uint256(r) * 4008531014412650626985742312566589230316694133190) >> uint256(215 - k));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

/// @dev Equivalent to `fullMulDiv(x, x, 1 << 64)`
function square(uint160 x) pure returns (uint256 result) {
    assembly ("memory-safe") {
        // 512-bit multiply [prod1 prod0] = x * x. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.

        // Least significant 256 bits of the product.
        let prod0 := mul(x, x)
        let mm := mulmod(x, x, not(0))
        // Most significant 256 bits of the product.
        let prod1 := sub(mm, add(prod0, lt(mm, prod0)))

        // Divide [prod1 prod0] by 2^64.
        result := or(shr(64, prod0), shl(192, prod1))
    }
}

/// @dev Equivalent to `fullMulDiv(x, y, 1 << 96)`.
/// NOTE: Does not check for overflow, so choose `x` and `y` carefully.
function mulDiv96(uint256 x, uint256 y) pure returns (uint256 result) {
    assembly ("memory-safe") {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.

        // Least significant 256 bits of the product.
        let prod0 := mul(x, y)
        let mm := mulmod(x, y, not(0))
        // Most significant 256 bits of the product.
        let prod1 := sub(mm, add(prod0, lt(mm, prod0)))

        // Divide [prod1 prod0] by 2^96.
        result := or(shr(96, prod0), shl(160, prod1))
    }
}

/// @dev Equivalent to `fullMulDiv(x, x, 1 << 128)`
function mulDiv128(uint256 x, uint256 y) pure returns (uint256 result) {
    assembly ("memory-safe") {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.

        // Least significant 256 bits of the product.
        let prod0 := mul(x, y)
        let mm := mulmod(x, y, not(0))
        // Most significant 256 bits of the product.
        let prod1 := sub(mm, add(prod0, lt(mm, prod0)))

        // Make sure the result is less than `2**256`.
        if iszero(gt(0x100000000000000000000000000000000, prod1)) {
            // Store the function selector of `FullMulDivFailed()`.
            mstore(0x00, 0xae47f702)
            // Revert with (offset, size).
            revert(0x1c, 0x04)
        }

        // Divide [prod1 prod0] by 2^128.
        result := or(shr(128, prod0), shl(128, prod1))
    }
}

/// @dev Equivalent to `fullMulDivUp(x, x, 1 << 128)`
function mulDiv128Up(uint256 x, uint256 y) pure returns (uint256 result) {
    result = mulDiv128(x, y);
    assembly ("memory-safe") {
        if mulmod(x, y, 0x100000000000000000000000000000000) {
            if iszero(add(result, 1)) {
                // Store the function selector of `FullMulDivFailed()`.
                mstore(0x00, 0xae47f702)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            result := add(result, 1)
        }
    }
}

/// @dev Equivalent to `fullMulDiv(x, y, 1 << 224)`.
/// NOTE: Does not check for overflow, so choose `x` and `y` carefully.
function mulDiv224(uint256 x, uint256 y) pure returns (uint256 result) {
    assembly ("memory-safe") {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.

        // Least significant 256 bits of the product.
        let prod0 := mul(x, y)
        let mm := mulmod(x, y, not(0))
        // Most significant 256 bits of the product.
        let prod1 := sub(mm, add(prod0, lt(mm, prod0)))

        // Divide [prod1 prod0] by 2^224.
        result := or(shr(224, prod0), shl(32, prod1))
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
        return a > b ? a : b;
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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

uint256 constant Q8 = 1 << 8;

uint256 constant Q16 = 1 << 16;

uint256 constant Q24 = 1 << 24;

uint256 constant Q32 = 1 << 32;

uint256 constant Q40 = 1 << 40;

uint256 constant Q48 = 1 << 48;

uint256 constant Q56 = 1 << 56;

uint256 constant Q64 = 1 << 64;

uint256 constant Q72 = 1 << 72;

uint256 constant Q80 = 1 << 80;

uint256 constant Q88 = 1 << 88;

uint256 constant Q96 = 1 << 96;

uint256 constant Q104 = 1 << 104;

uint256 constant Q112 = 1 << 112;

uint256 constant Q120 = 1 << 120;

uint256 constant Q128 = 1 << 128;

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x < 1 << 248);

        y = uint248(x);
    }

    function safeCastTo240(uint256 x) internal pure returns (uint240 y) {
        require(x < 1 << 240);

        y = uint240(x);
    }

    function safeCastTo232(uint256 x) internal pure returns (uint232 y) {
        require(x < 1 << 232);

        y = uint232(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x < 1 << 224);

        y = uint224(x);
    }

    function safeCastTo216(uint256 x) internal pure returns (uint216 y) {
        require(x < 1 << 216);

        y = uint216(x);
    }

    function safeCastTo208(uint256 x) internal pure returns (uint208 y) {
        require(x < 1 << 208);

        y = uint208(x);
    }

    function safeCastTo200(uint256 x) internal pure returns (uint200 y) {
        require(x < 1 << 200);

        y = uint200(x);
    }

    function safeCastTo192(uint256 x) internal pure returns (uint192 y) {
        require(x < 1 << 192);

        y = uint192(x);
    }
    
    function safeCastTo184(uint256 x) internal pure returns (uint184 y) {
        require(x < 1 << 184);

        y = uint184(x);
    }

    function safeCastTo176(uint256 x) internal pure returns (uint176 y) {
        require(x < 1 << 176);

        y = uint176(x);
    }

    function safeCastTo168(uint256 x) internal pure returns (uint168 y) {
        require(x < 1 << 168);

        y = uint168(x);
    }

    function safeCastTo160(uint256 x) internal pure returns (uint160 y) {
        require(x < 1 << 160);

        y = uint160(x);
    }

    function safeCastTo152(uint256 x) internal pure returns (uint152 y) {
        require(x < 1 << 152);

        y = uint152(x);
    }

    function safeCastTo144(uint256 x) internal pure returns (uint144 y) {
        require(x < 1 << 144);

        y = uint144(x);
    }

    function safeCastTo136(uint256 x) internal pure returns (uint136 y) {
        require(x < 1 << 136);

        y = uint136(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x < 1 << 128);

        y = uint128(x);
    }

    function safeCastTo120(uint256 x) internal pure returns (uint120 y) {
        require(x < 1 << 120);

        y = uint120(x);
    }

    function safeCastTo112(uint256 x) internal pure returns (uint112 y) {
        require(x < 1 << 112);

        y = uint112(x);
    }

    function safeCastTo104(uint256 x) internal pure returns (uint104 y) {
        require(x < 1 << 104);

        y = uint104(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x < 1 << 96);

        y = uint96(x);
    }

    function safeCastTo88(uint256 x) internal pure returns (uint88 y) {
        require(x < 1 << 88);

        y = uint88(x);
    }

    function safeCastTo80(uint256 x) internal pure returns (uint80 y) {
        require(x < 1 << 80);

        y = uint80(x);
    }

    function safeCastTo72(uint256 x) internal pure returns (uint72 y) {
        require(x < 1 << 72);

        y = uint72(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x < 1 << 64);

        y = uint64(x);
    }

    function safeCastTo56(uint256 x) internal pure returns (uint56 y) {
        require(x < 1 << 56);

        y = uint56(x);
    }

    function safeCastTo48(uint256 x) internal pure returns (uint48 y) {
        require(x < 1 << 48);

        y = uint48(x);
    }

    function safeCastTo40(uint256 x) internal pure returns (uint40 y) {
        require(x < 1 << 40);

        y = uint40(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x < 1 << 32);

        y = uint32(x);
    }

    function safeCastTo24(uint256 x) internal pure returns (uint24 y) {
        require(x < 1 << 24);

        y = uint24(x);
    }

    function safeCastTo16(uint256 x) internal pure returns (uint16 y) {
        require(x < 1 << 16);

        y = uint16(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x < 1 << 8);

        y = uint8(x);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {FixedPointMathLib as SoladyMath} from "solady/utils/FixedPointMathLib.sol";

/// @title Rewards
/// @notice Implements logic for staking rewards
/// @author Aloe Labs, Inc.
/// @author Inspired by [Yield Protocol](https://github.com/yieldprotocol/yield-utils-v2/blob/main/src/token/ERC20Rewards.sol)
library Rewards {
    event RewardsRateSet(uint64 rate);

    event RewardsClaimed(address indexed user, uint96 amount);

    struct PoolState {
        // Accumulated rewards per token, scaled up by 1e18
        uint160 accumulated;
        // Last time `accumulated` was updated
        uint32 lastUpdated;
        // The rewards rate, specified as [token units per second]
        uint64 rate;
    }

    struct UserState {
        // Rewards earned by the user up until the checkpoint
        uint96 earned;
        // `poolState.accumulated` the last time `userState` was updated
        uint160 checkpoint;
    }

    struct Storage {
        PoolState poolState;
        mapping(address => UserState) userStates;
    }

    bytes32 private constant _REWARDS_SLOT = keccak256("aloe.ii.rewards");

    /**
     * @notice Sets the pool's rewards rate. May be 0.
     * @param store The rewards storage pointer
     * @param accumulated Up-to-date `poolState.accumulated`, i.e. the output of `_accumulate`
     * @param rate The rewards rate, specified as [token units per second]. Keep between 10^17 and 10^28
     * token units per year for smooth operation -- between 0.1 and 10 billion tokens, assuming 18 decimals.
     */
    function setRate(Storage storage store, uint160 accumulated, uint64 rate) internal {
        store.poolState = PoolState(accumulated, uint32(block.timestamp), rate);
        emit RewardsRateSet(rate);
    }

    function claim(
        Storage storage store,
        uint160 accumulated,
        address user,
        uint256 balance
    ) internal returns (uint96 earned) {
        UserState memory userState = previewUserState(store, accumulated, user, balance);

        earned = userState.earned;
        userState.earned = 0;

        store.userStates[user] = userState;
        emit RewardsClaimed(user, earned);
    }

    /**
     * @notice Ensures that changes in the pool's `totalSupply` don't mess up rewards accounting. Should
     * be called anytime `totalSupply` changes.
     * @dev Use `Rewards.load()` to easily obtain the first two arguments
     * @param store The rewards storage pointer
     * @param accumulated Up-to-date `poolState.accumulated`, i.e. the output of `_accumulate`
     */
    function updatePoolState(Storage storage store, uint160 accumulated) internal {
        PoolState memory poolState = store.poolState;

        poolState.accumulated = accumulated;
        poolState.lastUpdated = uint32(block.timestamp);
        // poolState.rate is unchanged

        store.poolState = poolState;
    }

    /**
     * @notice Tracks how much reward a `user` earned while holding a particular `balance`. Should be
     * called anytime their balance changes.
     * @dev Use `Rewards.load()` to easily obtain the first two arguments
     * @param store The rewards storage pointer
     * @param accumulated Up-to-date `poolState.accumulated`, i.e. the output of `_accumulate`
     * @param user The user whose balance (# of shares) is about to change
     * @param balance The user's balance (# of shares) -- before it changes
     */
    function updateUserState(Storage storage store, uint160 accumulated, address user, uint256 balance) internal {
        store.userStates[user] = previewUserState(store, accumulated, user, balance);
    }

    function previewUserState(
        Storage storage store,
        uint160 accumulated,
        address user,
        uint256 balance
    ) internal view returns (UserState memory userState) {
        unchecked {
            userState = store.userStates[user];

            userState.earned += uint96((balance * (accumulated - userState.checkpoint)) / 1e18);
            userState.checkpoint = accumulated;
        }
    }

    function getRate() internal view returns (uint64) {
        return _storage().poolState.rate;
    }

    /// @dev Returns arguments to be used in `updatePoolState` and `updateUserState`. No good semantic
    /// meaning here, just a coincidence that both functions need this information.
    function load(uint256 totalSupply) internal view returns (Storage storage store, uint160 accumulator) {
        store = _storage();
        accumulator = _accumulate(store.poolState, totalSupply);
    }

    /// @dev Accumulates rewards based on the current `rate` and time elapsed since last update
    function _accumulate(PoolState memory poolState, uint256 totalSupply) private view returns (uint160) {
        unchecked {
            uint256 deltaT = block.timestamp - poolState.lastUpdated;
            return poolState.accumulated + uint160(SoladyMath.rawDiv(1e18 * deltaT * poolState.rate, totalSupply));
        }
    }

    /// @dev Diamond-pattern-style storage getter
    function _storage() private pure returns (Storage storage store) {
        bytes32 position = _REWARDS_SLOT;
        assembly ("memory-safe") {
            store.slot := position
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {ImmutableArgs} from "clones-with-immutable-args/ImmutableArgs.sol";
import {IERC165} from "openzeppelin-contracts/contracts/interfaces/IERC165.sol";
import {IERC2612} from "openzeppelin-contracts/contracts/interfaces/IERC2612.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {FixedPointMathLib as SoladyMath} from "solady/utils/FixedPointMathLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

import {BORROWS_SCALER, ONE} from "./libraries/constants/Constants.sol";
import {Q112} from "./libraries/constants/Q.sol";
import {Rewards} from "./libraries/Rewards.sol";

import {Factory} from "./Factory.sol";
import {IRateModel, SafeRateLib} from "./RateModel.sol";

contract Ledger {
    using FixedPointMathLib for uint256;
    using SafeRateLib for IRateModel;

    struct Cache {
        uint256 totalSupply;
        uint256 lastBalance;
        uint256 lastAccrualTime;
        uint256 borrowBase;
        uint256 borrowIndex;
    }

    Factory public immutable FACTORY;

    address public immutable RESERVE;

    /*//////////////////////////////////////////////////////////////
                             LENDER STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Doesn't include reserve inflation. If you want that, use `stats()`
    uint112 public totalSupply;

    /// @dev Used in lieu of `asset.balanceOf` to prevent inflation attacks
    uint112 public lastBalance;

    /// @dev The last `block.timestamp` at which interest accrued
    uint32 public lastAccrualTime;

    /// @dev The principle of all outstanding loans as if they were taken out at `borrowIndex = ONE`
    uint184 public borrowBase;

    /// @dev Tracks all-time growth of borrow interest. Starts at `ONE` and increases monotonically over time
    uint72 public borrowIndex;

    /// @dev The principle of a given user's loan as if it was taken out at `borrowIndex = ONE`
    mapping(address => uint256) public borrows;

    /*//////////////////////////////////////////////////////////////
                             ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @dev Highest 32 bits are the referral code, next 112 are the principle, lowest 112 are the shares.
    mapping(address => uint256) public balances;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            ERC2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                         GOVERNABLE PARAMETERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev `rateModel.getYieldPerSecond` is given 100000 gas, and the output is clamped to `MAX_RATE`. If
     * the call reverts, it's treated the same as if it returned 0.
     */
    IRateModel public rateModel;

    /// @dev The portion of interest that accrues to the `RESERVE`. Expressed as a reciprocal, e.g. 16 → 6.25%
    uint8 public reserveFactor;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address reserve) {
        FACTORY = Factory(msg.sender);
        RESERVE = reserve;
    }

    /// @notice Returns true if this contract implements the interface defined by `interfaceId`
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC2612).interfaceId ||
            interfaceId == type(IERC4626).interfaceId;
    }

    /// @notice The name of the banknote.
    function name() external view returns (string memory) {
        return string.concat("Aloe ", asset().name(), unicode" ⚭ [", Ledger(peer()).asset().symbol(), "]");
    }

    /// @notice The symbol of the banknote.
    function symbol() external view returns (string memory) {
        return string.concat(asset().symbol(), "+");
    }

    /// @notice The number of decimals the banknote uses. Matches the underlying token.
    function decimals() external view returns (uint8) {
        return asset().decimals();
    }

    /// @notice The address of the underlying token.
    function asset() public pure returns (ERC20) {
        return ERC20(ImmutableArgs.addr());
    }

    /// @notice The address of the other `Lender` in the market
    function peer() public view returns (address) {
        return FACTORY.peer(address(this));
    }

    /// @notice The domain separator for EIP-2612
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string version,uint256 chainId,address verifyingContract)"),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /**
     * @notice Gets basic lending statistics as if `accrueInterest` were just called.
     * @return The updated `borrowIndex`
     * @return The sum of all banknote balances, in underlying units (i.e. `totalAssets`)
     * @return The sum of all outstanding debts, in underlying units
     * @return The sum of all banknote balances. Will differ from `totalSupply` due to reserves inflation
     */
    function stats() external view returns (uint72, uint256, uint256, uint256) {
        (Cache memory cache, uint256 inventory, uint256 newTotalSupply) = _previewInterest(_getCache());

        unchecked {
            return (uint72(cache.borrowIndex), inventory, inventory - cache.lastBalance, newTotalSupply);
        }
    }

    /// @notice The rewards rate, specified as [token units per second]
    function rewardsRate() external view returns (uint64 rate) {
        rate = Rewards.getRate();
    }

    /// @notice All rewards earned by `account` that have not yet been paid out
    function rewardsOf(address account) external view returns (uint96) {
        (Rewards.Storage storage s, uint160 a) = Rewards.load(totalSupply);
        return Rewards.previewUserState(s, a, account, balanceOf(account)).earned;
    }

    /// @notice The ID of the referrer associated with `account`'s deposit. If 0, they have no courier.
    function courierOf(address account) external view returns (uint32) {
        return uint32(balances[account] >> 224);
    }

    /// @notice The lending principle of `account`. Only tracked if they have a courier.
    function principleOf(address account) external view returns (uint256) {
        return (balances[account] >> 112) % Q112;
    }

    /// @notice The number of shares held by `account`
    function balanceOf(address account) public view returns (uint256) {
        return balances[account] % Q112;
    }

    /**
     * @notice The amount of `asset` owed to `account` after accruing the latest interest, i.e.
     * the value that `maxWithdraw` would return if outstanding borrows weren't a constraint.
     * Fees owed to couriers are automatically subtracted from this value in real-time, but couriers
     * themselves won't receive earnings until users `redeem` or `withdraw`.
     * @dev Because of the fees, ∑underlyingBalances != totalAssets
     */
    function underlyingBalance(address account) external view returns (uint256) {
        (, uint256 inventory, uint256 newTotalSupply) = _previewInterest(_getCache());
        return _convertToAssets(_nominalShares(account, inventory, newTotalSupply), inventory, newTotalSupply, false);
    }

    /**
     * @notice The amount of `asset` owed to `account` before accruing the latest interest.
     * See `underlyingBalance` for details.
     * @dev An underestimate; more gas efficient than `underlyingBalance`
     */
    function underlyingBalanceStored(address account) external view returns (uint256) {
        unchecked {
            uint256 inventory = lastBalance + (uint256(borrowBase) * borrowIndex) / BORROWS_SCALER;
            uint256 totalSupply_ = totalSupply;

            return _convertToAssets(_nominalShares(account, inventory, totalSupply_), inventory, totalSupply_, false);
        }
    }

    /**
     * @notice The amount of `asset` owed by `account` after accruing the latest interest. If one calls
     * `repay(borrowBalance(account), account)`, the `account` will be left with a borrow balance of 0.
     */
    function borrowBalance(address account) external view returns (uint256) {
        uint256 b = borrows[account];

        (Cache memory cache, , ) = _previewInterest(_getCache());
        unchecked {
            return b > 1 ? ((b - 1) * cache.borrowIndex).unsafeDivUp(BORROWS_SCALER) : 0;
        }
    }

    /// @notice The amount of `asset` owed by `account` before accruing the latest interest.
    function borrowBalanceStored(address account) external view returns (uint256) {
        uint256 b = borrows[account];

        unchecked {
            return b > 1 ? ((b - 1) * borrowIndex).unsafeDivUp(BORROWS_SCALER) : 0;
        }
    }

    /*//////////////////////////////////////////////////////////////
                           ERC4626 ACCOUNTING
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice The total amount of `asset` under management
     * @dev `convertToShares(totalAssets()) != totalSupply()` due to reserves inflation. If you need
     * the up-to-date supply, use `stats()`
     */
    function totalAssets() external view returns (uint256) {
        (, uint256 inventory, ) = _previewInterest(_getCache());
        return inventory;
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        (, uint256 inventory, uint256 newTotalSupply) = _previewInterest(_getCache());
        return _convertToShares(assets, inventory, newTotalSupply, /* roundUp: */ false);
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        (, uint256 inventory, uint256 newTotalSupply) = _previewInterest(_getCache());
        return _convertToAssets(shares, inventory, newTotalSupply, /* roundUp: */ false);
    }

    function previewDeposit(uint256 assets) public view returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view returns (uint256) {
        (, uint256 inventory, uint256 newTotalSupply) = _previewInterest(_getCache());
        return _convertToAssets(shares, inventory, newTotalSupply, /* roundUp: */ true);
    }

    function previewRedeem(uint256 shares) public view returns (uint256) {
        return convertToAssets(shares);
    }

    function previewWithdraw(uint256 assets) public view returns (uint256) {
        (, uint256 inventory, uint256 newTotalSupply) = _previewInterest(_getCache());
        return _convertToShares(assets, inventory, newTotalSupply, /* roundUp: */ true);
    }

    /*//////////////////////////////////////////////////////////////
                    ERC4626 DEPOSIT/WITHDRAWAL LIMITS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns a conservative estimate of the maximum amount of `asset()` that can be deposited into the
     * Vault for `receiver`, through a deposit call.
     * @dev Should return the *precise* maximum. In this case that'd be on the order of 2^112 with constraints
     * coming from both `lastBalance` and `totalSupply`, which changes during interest accrual. Instead of doing
     * complicated math, we provide a constant conservative estimate of 2^96.
     * @return The maximum amount of `asset()` that can be deposited
     */
    function maxDeposit(address) external pure returns (uint256) {
        return 1 << 96;
    }

    /**
     * @notice Returns a conservative estimate of the maximum number of Vault shares that can be minted for `receiver`,
     * through a mint call.
     * @dev Should return the *precise* maximum. In this case that'd be on the order of 2^112 with constraints
     * coming from both `lastBalance` and `totalSupply`, which changes during interest accrual. Instead of doing
     * complicated math, we provide a constant conservative estimate of 2^96.
     * @return The maximum number of Vault shares that can be minted
     */
    function maxMint(address) external pure returns (uint256) {
        return 1 << 96;
    }

    /**
     * @notice Returns the maximum number of Vault shares that can be redeemed in the Vault by `owner`, through a
     * redeem call.
     * @param owner The address that would burn Vault shares when redeeming
     * @return The maximum number of Vault shares that can be redeemed
     */
    function maxRedeem(address owner) public view returns (uint256) {
        (Cache memory cache, uint256 inventory, uint256 newTotalSupply) = _previewInterest(_getCache());

        uint256 a = _nominalShares(owner, inventory, newTotalSupply);
        uint256 b = _convertToShares(cache.lastBalance, inventory, newTotalSupply, false);

        return a < b ? a : b;
    }

    /**
     * @notice Returns the maximum amount of `asset()` that can be withdrawn from the Vault by `owner`, through a
     * withdraw call.
     * @param owner The address that would burn Vault shares when withdrawing
     * @return The maximum amount of `asset()` that can be withdrawn
     */
    function maxWithdraw(address owner) external view returns (uint256) {
        return convertToAssets(maxRedeem(owner));
    }

    /*//////////////////////////////////////////////////////////////
                                 HELPERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Accrues interest up to the current `block.timestamp`. Updates and returns `cache`, but doesn't write
     * anything to storage.
     */
    function _previewInterest(Cache memory cache) internal view returns (Cache memory, uint256, uint256) {
        unchecked {
            uint256 oldBorrows = (cache.borrowBase * cache.borrowIndex) / BORROWS_SCALER;
            uint256 oldInventory = cache.lastBalance + oldBorrows;

            if (cache.lastAccrualTime == block.timestamp || oldBorrows == 0) {
                return (cache, oldInventory, cache.totalSupply);
            }

            // sload `reserveFactor` and `rateModel` at the same time since they're in the same slot
            uint8 rf = reserveFactor;
            uint256 accrualFactor = rateModel.getAccrualFactor({
                utilization: (1e18 * oldBorrows) / oldInventory,
                dt: block.timestamp - cache.lastAccrualTime
            });

            cache.borrowIndex = SoladyMath.min((cache.borrowIndex * accrualFactor) / ONE, type(uint72).max);
            cache.lastAccrualTime = 0; // 0 indicates `borrowIndex` was updated

            uint256 newInventory = cache.lastBalance + (cache.borrowBase * cache.borrowIndex) / BORROWS_SCALER;
            uint256 newTotalSupply = SoladyMath.min(
                SoladyMath.fullMulDiv(
                    cache.totalSupply,
                    newInventory,
                    newInventory - (newInventory - oldInventory) / rf
                ),
                type(uint112).max
            );
            return (cache, newInventory, newTotalSupply);
        }
    }

    function _convertToShares(
        uint256 assets,
        uint256 inventory,
        uint256 totalSupply_,
        bool roundUp
    ) internal pure returns (uint256) {
        if (totalSupply_ == 0) return assets;
        return roundUp ? assets.mulDivUp(totalSupply_, inventory) : assets.mulDivDown(totalSupply_, inventory);
    }

    function _convertToAssets(
        uint256 shares,
        uint256 inventory,
        uint256 totalSupply_,
        bool roundUp
    ) internal pure returns (uint256) {
        if (totalSupply_ == 0) return shares;
        return roundUp ? shares.mulDivUp(inventory, totalSupply_) : shares.mulDivDown(inventory, totalSupply_);
    }

    /// @dev The `account`'s balance, minus any shares earned by their courier
    function _nominalShares(
        address account,
        uint256 inventory,
        uint256 totalSupply_
    ) private view returns (uint256 balance) {
        unchecked {
            uint256 data = balances[account];
            balance = data % Q112;

            uint32 id = uint32(data >> 224);
            if (id != 0) {
                uint256 principleAssets = (data >> 112) % Q112;
                uint256 principleShares = _convertToShares(principleAssets, inventory, totalSupply_, true);

                if (balance > principleShares) {
                    (, uint16 cut) = FACTORY.couriers(id);

                    uint256 fee = ((balance - principleShares) * cut) / 10_000;
                    balance -= fee;
                }
            }
        }
    }

    function _getCache() internal view returns (Cache memory) {
        return Cache(totalSupply, lastBalance, lastAccrualTime, borrowBase, borrowIndex);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {FixedPointMathLib as SoladyMath} from "solady/utils/FixedPointMathLib.sol";
import {IUniswapV3Pool} from "v3-core/contracts/interfaces/IUniswapV3Pool.sol";

import {UNISWAP_AVG_WINDOW} from "./constants/Constants.sol";
import {Q16} from "./constants/Q.sol";
import {TickMath} from "./TickMath.sol";

/// @title Oracle
/// @notice Provides functions to integrate with V3 pool oracle
/// @author Aloe Labs, Inc.
/// @author Modified from [Uniswap](https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/OracleLibrary.sol)
library Oracle {
    /**
     * @notice Calculates time-weighted means of tick and liquidity for a given Uniswap V3 pool
     * @param pool Address of the pool that we want to observe
     * @param seed The indices of `pool.observations` where we start our search for the 30-minute-old (lowest 16 bits)
     * and 60-minute-old (next 16 bits) observations. Determine these off-chain to make this method more efficient
     * than Uniswap's binary search. If any of the highest 8 bits are set, we fallback to onchain binary search.
     * @return metric If the price was manipulated at any point in the past `UNISWAP_AVG_WINDOW` seconds, then at
     * some point in that period, this value will spike. It may still be high now, or (if the attacker is smart and
     * well-financed) it may have returned to nominal.
     * @return sqrtMeanPriceX96 sqrt(TWAP) over the past `UNISWAP_AVG_WINDOW` seconds
     */
    function consult(IUniswapV3Pool pool, uint40 seed) internal view returns (uint56 metric, uint160 sqrtMeanPriceX96) {
        unchecked {
            int56[] memory tickCumulatives = new int56[](3);

            if ((seed >> 32) > 0) {
                uint32[] memory secondsAgos = new uint32[](3);
                secondsAgos[0] = UNISWAP_AVG_WINDOW * 2;
                secondsAgos[1] = UNISWAP_AVG_WINDOW;
                secondsAgos[2] = 0;
                (tickCumulatives, ) = pool.observe(secondsAgos);
            } else {
                (, int24 currentTick, uint16 observationIndex, uint16 observationCardinality, , , ) = pool.slot0();
                {
                    (, , , bool initialized) = pool.observations((observationIndex + 1) % observationCardinality);
                    if (!initialized) observationCardinality = observationIndex + 1;
                }

                (tickCumulatives[0], ) = observe(
                    pool,
                    uint32(block.timestamp - UNISWAP_AVG_WINDOW * 2),
                    seed >> 16,
                    currentTick,
                    observationIndex,
                    observationCardinality
                );
                (tickCumulatives[1], ) = observe(
                    pool,
                    uint32(block.timestamp - UNISWAP_AVG_WINDOW),
                    seed % Q16,
                    currentTick,
                    observationIndex,
                    observationCardinality
                );
                (tickCumulatives[2], ) = observe(
                    pool,
                    uint32(block.timestamp),
                    observationIndex,
                    currentTick,
                    observationIndex,
                    observationCardinality
                );
            }

            // Compute arithmetic mean tick over `UNISWAP_AVG_WINDOW`, always rounding down to -inf
            int256 delta = tickCumulatives[2] - tickCumulatives[1];
            int256 meanTick0ToW = delta / int32(UNISWAP_AVG_WINDOW);
            assembly ("memory-safe") {
                // Equivalent: if (delta < 0 && (delta % UNISWAP_AVG_WINDOW != 0)) meanTick0ToW--;
                meanTick0ToW := sub(meanTick0ToW, and(slt(delta, 0), iszero(iszero(smod(delta, UNISWAP_AVG_WINDOW)))))
            }
            sqrtMeanPriceX96 = TickMath.getSqrtRatioAtTick(int24(meanTick0ToW));

            // Compute arithmetic mean tick over the interval [-2w, 0)
            int256 meanTick0To2W = (tickCumulatives[2] - tickCumulatives[0]) / int32(UNISWAP_AVG_WINDOW * 2);
            // Compute arithmetic mean tick over the interval [-2w, -w]
            int256 meanTickWTo2W = (tickCumulatives[1] - tickCumulatives[0]) / int32(UNISWAP_AVG_WINDOW);
            //                                         i                 i-2w                       i-w               i-2w
            //        meanTick0To2W - meanTickWTo2W = (∑ tick_n * dt_n - ∑ tick_n * dt_n) / (2T) - (∑ tick_n * dt_n - ∑ tick_n * dt_n) / T
            //                                         n=0               n=0                        n=0               n=0
            //
            //                                        i                   i-w
            // 2T * (meanTick0To2W - meanTickWTo2W) = ∑ tick_n * dt_n  - 2∑ tick_n * dt_n
            //                                        n=i-2w              n=i-2w
            //
            //                                        i                   i-w
            //                                      = ∑ tick_n * dt_n  -  ∑ tick_n * dt_n
            //                                        n=i-w               n=i-2w
            //
            // Thus far all values have been "true". We now assume that some manipulated value `manip_n` is added to each `tick_n`
            //
            //                                        i                               i-w
            //                                      = ∑ (tick_n + manip_n) * dt_n  -  ∑ (tick_n + manip_n) * dt_n
            //                                        n=i-w                           n=i-2w
            //
            //                                        i                   i-w                 i                    i-w
            //                                      = ∑ tick_n * dt_n  -  ∑ tick_n * dt_n  +  ∑ manip_n * dt_n  -  ∑ manip_n * dt_n
            //                                        n=i-w               n=i-2w              n=i-w                n=i-2w
            //
            //        meanTick0To2W - meanTickWTo2W = (meanTick0ToW_true - meanTickWTo2W_true) / 2  +  (sumManip0ToW - sumManipWTo2W) / (2T)
            //
            // For short time periods and reasonable market conditions, (meanTick0ToW_true - meanTickWTo2W_true) ≈ 0
            //
            //                                      ≈ (sumManip0ToW - sumManipWTo2W) / (2T)
            //
            // The TWAP we care about (see a few lines down) is measured over the interval [-w, 0). The result we've
            // just derived contains `sumManip0ToW`, which is the sum of all manipulation in that same interval. As
            // such, we use it as a metric for detecting manipulation. NOTE: If an attacker manipulates things to
            // the same extent in the prior interval [-2w, -w), the metric will be 0. To guard against this, we must
            // to watch the metric over the entire window. Even though it may be 0 *now*, it will have risen past a
            // threshold at *some point* in the past `UNISWAP_AVG_WINDOW` seconds.
            metric = uint56(SoladyMath.dist(meanTick0To2W, meanTickWTo2W));
        }
    }

    /**
     * @notice Searches for oracle observations nearest to the `target` time. If `target` lies between two existing
     * observations, linearly interpolate between them. If `target` is newer than the most recent observation,
     * we interpolate between the most recent one and a hypothetical one taken at the current block.
     * @dev As long as `target <= block.timestamp`, return values should match what you'd get from Uniswap.
     * @custom:example ```solidity
     *   uint32[] memory secondsAgos = new uint32[](1);
     *   secondsAgos[0] = block.timestamp - target;
     *   (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s) = pool.observe(
     *     secondsAgos
     *   );
     * ```
     * @param pool The Uniswap pool to examine
     * @param target The timestamp of the desired observation
     * @param seed The index of `pool.observations` where we start our search. Can be determined off-chain to make
     * this method more efficient than Uniswap's binary search.
     * @param tick The current tick (from `pool.slot0()`)
     * @param observationIndex The current observation index (from `pool.slot0()`)
     * @param observationCardinality The current observation cardinality. Should be determined as follows:
     * ```solidity
     *   (, , uint16 observationIndex, uint16 observationCardinality, , , ) = pool.slot0();
     *   (, , , bool initialized) = pool.observations((observationIndex + 1) % observationCardinality);
     *   if (!initialized) observationCardinality = observationIndex + 1;
     * ```
     * NOTE: If you fail to account for the `!initialized` case, and `target` comes before the oldest observation,
     * this may return incorrect data instead of reverting with "OLD".
     * @return The tick * time elapsed since `pool` was first initialized
     * @return The time elapsed / max(1, liquidity) since `pool` was first initialized
     */
    function observe(
        IUniswapV3Pool pool,
        uint32 target,
        uint256 seed,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality
    ) internal view returns (int56, uint160) {
        unchecked {
            seed %= observationCardinality;
            (uint32 timeL, int56 tickCumL, uint160 liqCumL, ) = pool.observations(seed);

            for (uint256 i = 0; i < observationCardinality; i++) {
                if (timeL == target) {
                    return (tickCumL, liqCumL);
                }

                if (timeL < target && seed == observationIndex) {
                    uint56 delta = target - timeL;
                    uint128 liquidity = pool.liquidity();
                    return (
                        tickCumL + tick * int56(delta),
                        liqCumL + (uint160(delta) << 128) / (liquidity > 0 ? liquidity : 1)
                    );
                }

                seed = (seed + 1) % observationCardinality;
                (uint32 timeR, int56 tickCumR, uint160 liqCumR, ) = pool.observations(seed);

                if (timeL < target && target < timeR) {
                    uint56 delta = target - timeL;
                    uint56 denom = timeR - timeL;
                    // Uniswap divides before multiplying, so we do too
                    return (
                        tickCumL + ((tickCumR - tickCumL) / int56(denom)) * int56(delta),
                        liqCumL + uint160((uint256(liqCumR - liqCumL) * delta) / denom)
                    );
                }

                (timeL, tickCumL, liqCumL) = (timeR, tickCumR, liqCumR);
            }

            revert("OLD");
        }
    }

    /**
     * @notice Given a pool, returns the number of seconds ago of the oldest stored observation
     * @param pool Address of Uniswap V3 pool that we want to observe
     * @param observationIndex The observation index from pool.slot0()
     * @param observationCardinality The observationCardinality from pool.slot0()
     * @dev `(, , uint16 observationIndex, uint16 observationCardinality, , , ) = pool.slot0();`
     * @return secondsAgo The number of seconds ago that the oldest observation was stored
     */
    function getMaxSecondsAgo(
        IUniswapV3Pool pool,
        uint16 observationIndex,
        uint16 observationCardinality
    ) internal view returns (uint32 secondsAgo) {
        require(observationCardinality != 0, "NI");

        unchecked {
            (uint32 observationTimestamp, , , bool initialized) = pool.observations(
                (observationIndex + 1) % observationCardinality
            );

            // The next index might not be initialized if the cardinality is in the process of increasing
            // In this case the oldest observation is always in index 0
            if (!initialized) {
                (observationTimestamp, , , ) = pool.observations(0);
            }

            secondsAgo = uint32(block.timestamp) - observationTimestamp;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.23;

import {FixedPointMathLib as SoladyMath} from "solady/utils/FixedPointMathLib.sol";

/// @title Volatility
/// @notice Provides functions that use Uniswap v3 to compute price volatility
/// @author Aloe Labs, Inc.
library Volatility {
    using SoladyMath for uint256;

    struct PoolMetadata {
        // the overall fee minus the protocol fee for token0, times 1e6
        uint24 gamma0;
        // the overall fee minus the protocol fee for token1, times 1e6
        uint24 gamma1;
        // the pool tick spacing
        int24 tickSpacing;
    }

    struct FeeGrowthGlobals {
        // the fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
        uint256 feeGrowthGlobal0X128;
        // the fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
        uint256 feeGrowthGlobal1X128;
        // the block timestamp at which feeGrowthGlobal0X128 and feeGrowthGlobal1X128 were last updated
        uint32 timestamp;
    }

    uint256 private constant _Q224Div1e18 = (uint256(1 << 224) * 1e6) / 1e24; // solhint-disable const-name-snakecase
    uint256 private constant _Q128Div1e18 = (uint256(1 << 128) * 1e6) / 1e24; // solhint-disable const-name-snakecase

    /**
     * @notice Estimates implied volatility using
     * [this math](https://lambert-guillaume.medium.com/on-chain-volatility-and-uniswap-v3-d031b98143d1).
     * @dev The return value can fit in uint128 if necessary
     * @param metadata The pool's metadata (may be cached)
     * @param sqrtMeanPriceX96 sqrt(TWAP) over some period. Likely from `Oracle.consult`
     * @param a The pool's cumulative feeGrowthGlobals some time in the past
     * @param b The pool's cumulative feeGrowthGlobals as of the current block
     * @param scale The timescale (in seconds) in which IV should be reported, e.g. hourly, daily, annualized
     * @return An estimate of the implied volatility scaled by 1e12
     */
    function estimate(
        PoolMetadata memory metadata,
        uint160 sqrtMeanPriceX96,
        FeeGrowthGlobals memory a,
        FeeGrowthGlobals memory b,
        uint32 scale
    ) internal pure returns (uint256) {
        unchecked {
            // Return early to avoid division by 0
            if (b.timestamp - a.timestamp == 0) return 0;

            // Goal:  IV = 2γ √(volume / valueOfLiquidity)
            //
            //  γ = √(γ₀γ₁)
            //  volume ≈ ((P · fgg0 / γ₀) + (fgg1 / γ₁)) · liquidity
            //  valueOfLiquidity = (tickSpacing · liquidity · √P) / 20000
            //
            //        IV = 2 √( 20000 · γ₀γ₁ · ((P · fgg0 / γ₀) + (fgg1 / γ₁)) / √P / tickSpacing )
            //           = 2 √( 20000 ·        ((P · fgg0 · γ₁) + (fgg1 · γ₀)) / √P / tickSpacing )
            //           = 2 √( 20000 ·        (fgg0 · γ₁ · √P  +  fgg1 · γ₀ / √P)  / tickSpacing )

            // Calculate average [fees per unit of liquidity] for this time period
            uint256 fgg0X128 = b.feeGrowthGlobal0X128 - a.feeGrowthGlobal0X128;
            uint256 fgg1X128 = b.feeGrowthGlobal1X128 - a.feeGrowthGlobal1X128;

            // Start math.
            // Also remove Q128 and instead scale by 1e24 (gammas have 1e6, and we pull 1e18 out of the denominator).
            uint256 fgg0Gamma1MulP = fgg0X128.fullMulDiv(uint256(metadata.gamma1) * sqrtMeanPriceX96, _Q224Div1e18);
            uint256 fgg1Gamma0DivP = fgg1X128.fullMulDiv(
                uint256(metadata.gamma0) << 96,
                sqrtMeanPriceX96 * _Q128Div1e18
            );

            // Make sure numerator won't overflow in the next step
            uint256 inner = (fgg0Gamma1MulP + fgg1Gamma0DivP).min(uint256(1 << 224) / 20_000);

            // Finish math and adjust to specified timescale
            return
                2 *
                SoladyMath.sqrt(
                    (20_000 * inner * scale) / (b.timestamp - a.timestamp) / uint256(int256(metadata.tickSpacing))
                );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/**
 * @author OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.0/contracts/utils/Create2.sol)
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address addr) {
        assembly ("memory-safe") {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC2612.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Permit.sol";

interface IERC2612 is IERC20Permit {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC4626.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";
import "../token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @dev Interface of the ERC4626 "Tokenized Vault Standard", as defined in
 * https://eips.ethereum.org/EIPS/eip-4626[ERC-4626].
 *
 * _Available since v4.7._
 */
interface IERC4626 is IERC20, IERC20Metadata {
    event Deposit(address indexed sender, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /**
     * @dev Returns the address of the underlying token used for the Vault for accounting, depositing, and withdrawing.
     *
     * - MUST be an ERC-20 token contract.
     * - MUST NOT revert.
     */
    function asset() external view returns (address assetTokenAddress);

    /**
     * @dev Returns the total amount of the underlying asset that is “managed” by Vault.
     *
     * - SHOULD include any compounding that occurs from yield.
     * - MUST be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT revert.
     */
    function totalAssets() external view returns (uint256 totalManagedAssets);

    /**
     * @dev Returns the amount of shares that the Vault would exchange for the amount of assets provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToShares(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Returns the amount of assets that the Vault would exchange for the amount of shares provided, in an ideal
     * scenario where all the conditions are met.
     *
     * - MUST NOT be inclusive of any fees that are charged against assets in the Vault.
     * - MUST NOT show any variations depending on the caller.
     * - MUST NOT reflect slippage or other on-chain conditions, when performing the actual exchange.
     * - MUST NOT revert.
     *
     * NOTE: This calculation MAY NOT reflect the “per-user” price-per-share, and instead should reflect the
     * “average-user’s” price-per-share, meaning what the average user should expect to see when exchanging to and
     * from.
     */
    function convertToAssets(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be deposited into the Vault for the receiver,
     * through a deposit call.
     *
     * - MUST return a limited value if receiver is subject to some deposit limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of assets that may be deposited.
     * - MUST NOT revert.
     */
    function maxDeposit(address receiver) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their deposit at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of Vault shares that would be minted in a deposit
     *   call in the same transaction. I.e. deposit should return the same or more shares as previewDeposit if called
     *   in the same transaction.
     * - MUST NOT account for deposit limits like those returned from maxDeposit and should always act as though the
     *   deposit would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewDeposit SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewDeposit(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Mints shares Vault shares to receiver by depositing exactly amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   deposit execution, and are accounted for during deposit.
     * - MUST revert if all of assets cannot be deposited (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of the Vault shares that can be minted for the receiver, through a mint call.
     * - MUST return a limited value if receiver is subject to some mint limit.
     * - MUST return 2 ** 256 - 1 if there is no limit on the maximum amount of shares that may be minted.
     * - MUST NOT revert.
     */
    function maxMint(address receiver) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their mint at the current block, given
     * current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of assets that would be deposited in a mint call
     *   in the same transaction. I.e. mint should return the same or fewer assets as previewMint if called in the
     *   same transaction.
     * - MUST NOT account for mint limits like those returned from maxMint and should always act as though the mint
     *   would be accepted, regardless if the user has enough tokens approved, etc.
     * - MUST be inclusive of deposit fees. Integrators should be aware of the existence of deposit fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewMint SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by minting.
     */
    function previewMint(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Mints exactly shares Vault shares to receiver by depositing amount of underlying tokens.
     *
     * - MUST emit the Deposit event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the mint
     *   execution, and are accounted for during mint.
     * - MUST revert if all of shares cannot be minted (due to deposit limit being reached, slippage, the user not
     *   approving enough underlying tokens to the Vault contract, etc).
     *
     * NOTE: most implementations will require pre-approval of the Vault with the Vault’s underlying asset token.
     */
    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    /**
     * @dev Returns the maximum amount of the underlying asset that can be withdrawn from the owner balance in the
     * Vault, through a withdraw call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxWithdraw(address owner) external view returns (uint256 maxAssets);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their withdrawal at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no fewer than the exact amount of Vault shares that would be burned in a withdraw
     *   call in the same transaction. I.e. withdraw should return the same or fewer shares as previewWithdraw if
     *   called
     *   in the same transaction.
     * - MUST NOT account for withdrawal limits like those returned from maxWithdraw and should always act as though
     *   the withdrawal would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToShares and previewWithdraw SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by depositing.
     */
    function previewWithdraw(uint256 assets) external view returns (uint256 shares);

    /**
     * @dev Burns shares from owner and sends exactly assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   withdraw execution, and are accounted for during withdraw.
     * - MUST revert if all of assets cannot be withdrawn (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * Note that some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256 shares);

    /**
     * @dev Returns the maximum amount of Vault shares that can be redeemed from the owner balance in the Vault,
     * through a redeem call.
     *
     * - MUST return a limited value if owner is subject to some withdrawal limit or timelock.
     * - MUST return balanceOf(owner) if owner is not subject to any withdrawal limit or timelock.
     * - MUST NOT revert.
     */
    function maxRedeem(address owner) external view returns (uint256 maxShares);

    /**
     * @dev Allows an on-chain or off-chain user to simulate the effects of their redeemption at the current block,
     * given current on-chain conditions.
     *
     * - MUST return as close to and no more than the exact amount of assets that would be withdrawn in a redeem call
     *   in the same transaction. I.e. redeem should return the same or more assets as previewRedeem if called in the
     *   same transaction.
     * - MUST NOT account for redemption limits like those returned from maxRedeem and should always act as though the
     *   redemption would be accepted, regardless if the user has enough shares, etc.
     * - MUST be inclusive of withdrawal fees. Integrators should be aware of the existence of withdrawal fees.
     * - MUST NOT revert.
     *
     * NOTE: any unfavorable discrepancy between convertToAssets and previewRedeem SHOULD be considered slippage in
     * share price or some other type of condition, meaning the depositor will lose assets by redeeming.
     */
    function previewRedeem(uint256 shares) external view returns (uint256 assets);

    /**
     * @dev Burns exactly shares from owner and sends assets of underlying tokens to receiver.
     *
     * - MUST emit the Withdraw event.
     * - MAY support an additional flow in which the underlying tokens are owned by the Vault contract before the
     *   redeem execution, and are accounted for during redeem.
     * - MUST revert if all of shares cannot be redeemed (due to withdrawal limit being reached, slippage, the owner
     *   not having enough shares, etc).
     *
     * NOTE: some implementations will require pre-requesting to the Vault before a withdrawal may be performed.
     * Those methods should be performed separately.
     */
    function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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