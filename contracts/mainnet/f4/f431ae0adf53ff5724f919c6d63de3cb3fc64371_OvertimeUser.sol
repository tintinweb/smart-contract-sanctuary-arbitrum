// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.20;

import { ISportPositionalMarket } from "thales-markets/interfaces/ISportPositionalMarket.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";
import { IFeeManager } from "../interfaces/IFeeManager.sol";
import { IOvertimeUser } from "../interfaces/IOvertimeUser.sol";
import { IParlayMarket } from "../interfaces/IParlayMarket.sol";
import { IParlayMarketsAMM } from "../interfaces/IParlayMarketsAMM.sol";
import { ISportsAMM } from "../interfaces/ISportsAMM.sol";
import { IWETH } from "../interfaces/IWETH.sol";

contract OvertimeUser is IOvertimeUser {
    address public factory;
    address public user;
    address public overtimeReferrer;

    ISportsAMM public sportsAMM;
    IParlayMarketsAMM public parlayMarketsAMM;
    IFeeManager public feeManager;
    IERC20 public susd;
    IWETH public weth;

    bool public initializedReferrer;

    modifier onlyFactory() {
        if (msg.sender != factory) revert Unauthorized();
        _;
    }

    constructor() { }

    function buySingle(
        address market,
        uint8 position,
        uint256 payout,
        uint256 desiredAmount
    )
        external
        payable
        onlyFactory
    {
        susd.approve(address(sportsAMM), desiredAmount);

        if (initializedReferrer) {
            sportsAMM.buyFromAMM(market, ISportsAMM.Position(position), payout, desiredAmount, 0);
        } else {
            sportsAMM.buyFromAMMWithReferrer(
                market, ISportsAMM.Position(position), payout, desiredAmount, 0, overtimeReferrer
            );
        }

        emit BuySingleBet(market, position, payout, address(susd), desiredAmount);
    }

    function buySingleWithDifferentCollateral(
        address market,
        uint8 position,
        uint256 payout,
        uint256 desiredAmount,
        address collateral
    )
        external
        payable
        onlyFactory
    {
        IERC20(collateral).approve(address(sportsAMM), desiredAmount);

        if (initializedReferrer) {
            sportsAMM.buyFromAMMWithDifferentCollateral(
                market, ISportsAMM.Position(position), payout, desiredAmount, 0, collateral
            );
        } else {
            sportsAMM.buyFromAMMWithDifferentCollateralAndReferrer(
                market, ISportsAMM.Position(position), payout, desiredAmount, 0, collateral, overtimeReferrer
            );
        }

        emit BuySingleBet(market, position, payout, collateral, desiredAmount);
    }

    /**
     * @dev Buys a parlay with native collateral.
     * @param sportMarkets The addresses of the sport markets.
     * @param positions The positions of the outcomes, can be 0 (home), 1 (draw), or 2 (away).
     * @param desiredAmount The desired amount of sUSD (or native token collateral) to pay for the parlay.
     * @param expectedPayout The expected payout amount.
     */
    function buyParlay(
        address[] calldata sportMarkets,
        uint[] calldata positions,
        uint256 expectedPayout,
        uint256 desiredAmount
    )
        external
        payable
        onlyFactory
    {
        susd.approve(address(parlayMarketsAMM), desiredAmount);

        if (!initializedReferrer) {
            parlayMarketsAMM.buyFromParlayWithReferrer(
                sportMarkets, positions, desiredAmount, 0, expectedPayout, address(0), overtimeReferrer
            );
        } else {
            parlayMarketsAMM.buyFromParlay(sportMarkets, positions, desiredAmount, 0, expectedPayout, address(0));
        }

        emit BuyParlayBet(sportMarkets, positions, expectedPayout, address(susd), desiredAmount);
    }

    /**
     * @dev Buys a parlay with different collateral.
     * @param sportMarkets The addresses of the sport markets.
     * @param positions The positions of the outcomes, can be 0 (home), 1 (draw), or 2 (away).
     * @param desiredAmount The desired amount of sUSD (or native token collateral) to pay for the parlay.
     * @param expectedPayout The expected payout amount.
     * @param collateral The address of the collateral token.
     */
    function buyParlayWithDifferentCollateral(
        address[] calldata sportMarkets,
        uint[] calldata positions,
        uint256 expectedPayout,
        uint256 desiredAmount,
        uint256 collateralAmount,
        address collateral
    )
        external
        payable
        onlyFactory
    {
        IERC20(collateral).approve(address(parlayMarketsAMM), collateralAmount);

        parlayMarketsAMM.buyFromParlayWithDifferentCollateralAndReferrer(
            sportMarkets, positions, desiredAmount, 0, expectedPayout, collateral, overtimeReferrer
        );

        emit BuyParlayBet(sportMarkets, positions, expectedPayout, collateral, desiredAmount);
    }

    function exerciseSingle(address market) external onlyFactory returns (uint256 fee, address referrer) {
        (fee, referrer) = _exerciseSingle(market);
        uint256 payout = susd.balanceOf(address(this));
        SafeTransferLib.safeTransfer(address(susd), user, payout);

        emit ExerciseSingleBet(market, address(susd), payout);
    }

    function exerciseSingleWithDifferentCollateral(
        address market,
        address collateral,
        bool toEth
    )
        external
        onlyFactory
        returns (uint256 fee, address referrer)
    {
        uint256 payout;

        (fee, referrer) = _exerciseSingleWithDifferentCollateral(market, collateral);

        if (collateral == address(weth) && toEth) {
            payout = weth.balanceOf(address(this));
            weth.withdraw(payout);
            SafeTransferLib.safeTransferETH(user, address(this).balance);
        } else {
            payout = IERC20(collateral).balanceOf(address(this));
            SafeTransferLib.safeTransfer(collateral, user, payout);
        }

        emit ExerciseSingleBet(market, collateral, payout);
    }

    function exerciseParlay(address market) external onlyFactory returns (uint256 fee, address referrer) {
        (fee, referrer) = _exerciseParlay(market);

        uint256 payout = susd.balanceOf(address(this));

        SafeTransferLib.safeTransfer(address(susd), user, payout);

        emit ExerciseParlayBet(market, address(susd), payout);
    }

    function exerciseParlayWithDifferentCollateral(
        address market,
        address collateral,
        bool toEth
    )
        external
        onlyFactory
        returns (uint256 fee, address referrer)
    {
        (fee, referrer) = _exerciseParlayWithDifferentCollateral(market, collateral);

        uint256 payout;

        if (collateral == address(weth) && toEth) {
            payout = weth.balanceOf(address(this));
            weth.withdraw(payout);
            SafeTransferLib.safeTransferETH(user, address(this).balance);
        } else {
            payout = IERC20(collateral).balanceOf(address(this));
            SafeTransferLib.safeTransfer(collateral, user, payout);
        }

        emit ExerciseParlayBet(market, collateral, payout);
    }

    function setVariables(
        address _sportsAMM,
        address _parlayMarketsAMM,
        address _feeManager,
        address _susd,
        address _weth,
        address _overtimeReferrer
    )
        external
        onlyFactory
    {
        sportsAMM = ISportsAMM(payable(_sportsAMM));
        parlayMarketsAMM = IParlayMarketsAMM(payable(_parlayMarketsAMM));
        feeManager = IFeeManager(_feeManager);
        susd = IERC20(_susd);
        weth = IWETH(_weth);
        overtimeReferrer = _overtimeReferrer;
        initializedReferrer = false;
    }

    function initialize(address _user) external {
        if (_user == address(0)) revert ZeroAddress();
        if (user != address(0)) revert Initialized();
        factory = msg.sender;
        user = _user;
    }

    /*.•°•.•°•.•°•.•°°•.•°•.•°•.•°•.*/
    /*      Internal functions      */
    /*°•.•°•.•°•.•°•..•°•.•°•.•°•.•°*/

    function _exerciseSingle(address _market) internal returns (uint256 fee, address referrer) {
        uint8 result = uint8(ISportPositionalMarket(_market).result());
        uint256 amountBefore = susd.balanceOf(address(this));
        ISportPositionalMarket(_market).exerciseOptions();
        uint256 amountAfter = susd.balanceOf(address(this));
        uint256 payout = amountAfter - amountBefore;
        if (payout == 0 || result == 0) return (0, address(0));

        IFeeManager.BetInfo memory info = IFeeManager(feeManager).getBetInfo(user, _market, result - 1);
        uint256 profit = payout - info.amount;

        fee = _collectFee(profit, address(susd));
        referrer = info.referrer;
    }

    function _exerciseSingleWithDifferentCollateral(
        address _market,
        address _collateral
    )
        internal
        returns (uint256 fee, address referrer)
    {
        uint256 collateralBefore = IERC20(_collateral).balanceOf(address(this));

        uint8 result = uint8(ISportPositionalMarket(_market).result());
        (uint256 home, uint256 away, uint256 draw) = ISportPositionalMarket(_market).balancesOf(address(this));
        uint256 payout;
        if (result == 1) {
            payout = home;
        } else if (result == 2) {
            payout = away;
        } else {
            payout = draw;
        }

        sportsAMM.exerciseWithOfframp(_market, _collateral, false);
        uint256 collateralAfter = IERC20(_collateral).balanceOf(address(this));
        uint256 collateralPayout = collateralAfter - collateralBefore;
        if (collateralPayout == 0 || result == 0) return (0, address(0));

        IFeeManager.BetInfo memory info = IFeeManager(feeManager).getBetInfo(user, _market, result - 1);
        uint256 profit = payout - info.amount;

        uint256 collateralProfit = profit * collateralPayout / payout;
        fee = _collectFee(collateralProfit, _collateral);
        referrer = info.referrer;
    }

    function _exerciseParlay(address _market) internal returns (uint256 fee, address referrer) {
        uint256 amountBefore = susd.balanceOf(address(this));
        uint256 sUSDAfterFees = IParlayMarket(_market).sUSDPaid();
        uint256 safeBoxImpact = IParlayMarketsAMM(parlayMarketsAMM).safeBoxImpact();
        uint256 parlayAmmFee = IParlayMarketsAMM(parlayMarketsAMM).parlayAmmFee();
        uint256 paid = (sUSDAfterFees * 1 ether) / (1 ether - (safeBoxImpact + parlayAmmFee));
        parlayMarketsAMM.exerciseParlay(_market);
        uint256 amountAfter = susd.balanceOf(address(this));
        uint256 payout = amountAfter - amountBefore;

        if (payout == 0) return (0, address(0));

        uint256 profit = payout - paid;

        fee = _collectFee(profit, address(susd));

        uint256 expiry = IParlayMarket(_market).expiry();
        uint256 amount = IParlayMarket(_market).amount();
        uint256 sUSDPaid = IParlayMarket(_market).sUSDPaid();

        bytes32 refHash = IFeeManager(feeManager).getParlayHash(expiry, amount, sUSDPaid);
        referrer = IFeeManager(feeManager).getParlayInfo(user, refHash).referrer;
    }

    function _exerciseParlayWithDifferentCollateral(
        address _market,
        address collateral
    )
        internal
        returns (uint256 fee, address referrer)
    {
        IERC20 collateral_ = IERC20(collateral);
        uint256 collateralBefore = collateral_.balanceOf(address(this));

        uint256 payout = susd.balanceOf(_market);
        uint256 length = IParlayMarket(_market).numOfSportMarkets();
        for (uint i = 0; i < length; i++) {
            (address _sportMarket,, uint256 odd,,,,,) = IParlayMarket(_market).sportMarket(i);
            ISportPositionalMarket currentSportMarket = ISportPositionalMarket(_sportMarket);
            uint result = uint(currentSportMarket.result());
            if (result == 0) {
                payout = (payout * odd) / 1 ether;
            }
        }

        susd.approve(address(parlayMarketsAMM), payout);

        parlayMarketsAMM.exerciseParlayWithOfframp(_market, collateral, false);
        uint256 collateralAfter = collateral_.balanceOf(address(this));
        uint256 sUSDAfterFees = IParlayMarket(_market).sUSDPaid();
        uint256 safeBoxImpact = IParlayMarketsAMM(parlayMarketsAMM).safeBoxImpact();
        uint256 parlayAmmFee = IParlayMarketsAMM(parlayMarketsAMM).parlayAmmFee();
        uint256 paid = (sUSDAfterFees * 1 ether) / (1 ether - (safeBoxImpact + parlayAmmFee));

        uint256 profit = payout - paid;
        uint256 collateralPayout = collateralAfter - collateralBefore;

        uint256 collateralProfit = profit * collateralPayout / payout;

        fee = _collectFee(collateralProfit, collateral);

        uint256 expiry = IParlayMarket(_market).expiry();
        uint256 amount = IParlayMarket(_market).amount();

        bytes32 refHash = IFeeManager(feeManager).getParlayHash(expiry, amount, sUSDAfterFees);
        IFeeManager.BetInfo memory info = IFeeManager(feeManager).getParlayInfo(user, refHash);
        referrer = info.referrer;
    }

    function _collectFee(uint256 profit, address collateral) internal returns (uint256 fee) {
        fee = feeManager.fee(profit);

        SafeTransferLib.safeTransfer(collateral, address(feeManager), fee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarketManager.sol";
import "../interfaces/IPosition.sol";
import "../interfaces/IPriceFeed.sol";

interface ISportPositionalMarket {
    /* ========== TYPES ========== */

    enum Phase {
        Trading,
        Maturity,
        Expiry
    }
    enum Side {
        Cancelled,
        Home,
        Away,
        Draw
    }

    /* ========== VIEWS / VARIABLES ========== */

    function getOptions()
        external
        view
        returns (
            IPosition home,
            IPosition away,
            IPosition draw
        );

    function times() external view returns (uint maturity, uint destruction);

    function getGameDetails() external view returns (bytes32 gameId, string memory gameLabel);

    function getGameId() external view returns (bytes32);

    function deposited() external view returns (uint);

    function optionsCount() external view returns (uint);

    function creator() external view returns (address);

    function resolved() external view returns (bool);

    function cancelled() external view returns (bool);

    function paused() external view returns (bool);

    function phase() external view returns (Phase);

    function canResolve() external view returns (bool);

    function result() external view returns (Side);

    function isChild() external view returns (bool);

    function optionsInitialized() external view returns (bool);

    function tags(uint idx) external view returns (uint);

    function getTags() external view returns (uint tag1, uint tag2);

    function getTagsLength() external view returns (uint tagsLength);

    function getParentMarketPositions() external view returns (IPosition position1, IPosition position2);

    function getParentMarketPositionsUint() external view returns (uint position1, uint position2);

    function getStampedOdds()
        external
        view
        returns (
            uint,
            uint,
            uint
        );

    function balancesOf(address account)
        external
        view
        returns (
            uint home,
            uint away,
            uint draw
        );

    function totalSupplies()
        external
        view
        returns (
            uint home,
            uint away,
            uint draw
        );

    function isDoubleChance() external view returns (bool);

    function parentMarket() external view returns (ISportPositionalMarket);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function setPaused(bool _paused) external;

    function updateDates(uint256 _maturity, uint256 _expiry) external;

    function mint(uint value) external;

    function exerciseOptions() external;

    function restoreInvalidOdds(
        uint _homeOdds,
        uint _awayOdds,
        uint _drawOdds
    ) external;

    function initializeOptions() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.20;

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
     * @dev Returns the value of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the value of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves a `value` amount of tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets a `value` amount of tokens as the allowance of `spender` over the
     * caller's tokens.
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
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * @dev Moves a `value` amount of tokens from `from` to `to` using the
     * allowance mechanism. `value` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
///
/// @dev Note:
/// - For ETH transfers, please use `forceSafeTransferETH` for DoS protection.
/// - For ERC20s, this implementation won't check that a token has code,
///   responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH that disallows any storage writes.
    uint256 internal constant GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    uint256 internal constant GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // If the ETH transfer MUST succeed with a reasonable gas budget, use the force variants.
    //
    // The regular variants:
    // - Forwards all remaining gas to the target.
    // - Reverts if the target reverts.
    // - Reverts if the current contract has insufficient balance.
    //
    // The force variants:
    // - Forwards with an optional gas stipend
    //   (defaults to `GAS_STIPEND_NO_GRIEF`, which is sufficient for most cases).
    // - If the target reverts, or if the gas stipend is exhausted,
    //   creates a temporary contract to force send the ETH via `SELFDESTRUCT`.
    //   Future compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758.
    // - Reverts if the current contract has insufficient balance.
    //
    // The try variants:
    // - Forwards with a mandatory gas stipend.
    // - Instead of reverting, returns whether the transfer succeeded.

    /// @dev Sends `amount` (in wei) ETH to `to`.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gas(), to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Sends all the ETH in the current contract to `to`.
    function safeTransferAllETH(address to) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer all the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if lt(selfbalance(), amount) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
            if iszero(call(gasStipend, to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(amount, 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends all the ETH in the current contract to `to`, with a `gasStipend`.
    function forceSafeTransferAllETH(address to, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(call(gasStipend, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(selfbalance(), 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with `GAS_STIPEND_NO_GRIEF`.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            if lt(selfbalance(), amount) {
                mstore(0x00, 0xb12d13eb) // `ETHTransferFailed()`.
                revert(0x1c, 0x04)
            }
            if iszero(call(GAS_STIPEND_NO_GRIEF, to, amount, codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(amount, 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Force sends all the ETH in the current contract to `to`, with `GAS_STIPEND_NO_GRIEF`.
    function forceSafeTransferAllETH(address to) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            if iszero(call(GAS_STIPEND_NO_GRIEF, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                if iszero(create(selfbalance(), 0x0b, 0x16)) { revert(codesize(), codesize()) } // For gas estimation.
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            success := call(gasStipend, to, amount, codesize(), 0x00, codesize(), 0x00)
        }
    }

    /// @dev Sends all the ETH in the current contract to `to`, with a `gasStipend`.
    function trySafeTransferAllETH(address to, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            success := call(gasStipend, to, selfbalance(), codesize(), 0x00, codesize(), 0x00)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x60, amount) // Store the `amount` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x23b872dd000000000000000000000000) // `transferFrom(address,address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have their entire balance approved for
    /// the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to)
        internal
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x2c, shl(96, from)) // Store the `from` argument.
            mstore(0x0c, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            // Read the balance, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x00, 0x23b872dd) // `transferFrom(address,address,uint256)`.
            amount := mload(0x60) // The `amount` is already at 0x60. We'll need to return it.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x7939f424) // `TransferFromFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            // Read the balance, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x34, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x14, to) // Store the `to` argument.
            amount := mload(0x34) // The `amount` is already at 0x34. We'll need to return it.
            mstore(0x00, 0xa9059cbb000000000000000000000000) // `transfer(address,uint256)`.
            // Perform the transfer, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x90b8ec18) // `TransferFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
            // Perform the approval, reverting upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x00, 0x3e3f8f73) // `ApproveFailed()`.
                revert(0x1c, 0x04)
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// If the initial attempt to approve fails, attempts to reset the approved amount to zero,
    /// then retries the approval again (some tokens, e.g. USDT, requires this).
    /// Reverts upon failure.
    function safeApproveWithRetry(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, to) // Store the `to` argument.
            mstore(0x34, amount) // Store the `amount` argument.
            mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
            // Perform the approval, retrying upon failure.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                    call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                )
            ) {
                mstore(0x34, 0) // Store 0 for the `amount`.
                mstore(0x00, 0x095ea7b3000000000000000000000000) // `approve(address,uint256)`.
                pop(call(gas(), token, 0, 0x10, 0x44, codesize(), 0x00)) // Reset the approval.
                mstore(0x34, amount) // Store back the original `amount`.
                // Retry the approval, reverting upon failure.
                if iszero(
                    and(
                        or(eq(mload(0x00), 1), iszero(returndatasize())), // Returned 1 or nothing.
                        call(gas(), token, 0, 0x10, 0x44, 0x00, 0x20)
                    )
                ) {
                    mstore(0x00, 0x3e3f8f73) // `ApproveFailed()`.
                    revert(0x1c, 0x04)
                }
            }
            mstore(0x34, 0) // Restore the part of the free memory pointer that was overwritten.
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x14, account) // Store the `account` argument.
            mstore(0x00, 0x70a08231000000000000000000000000) // `balanceOf(address)`.
            amount :=
                mul(
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), token, 0x10, 0x24, 0x20, 0x20)
                    )
                )
        }
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.20;

interface IFeeManager {
    event FeeCollected(
        address betReferrer, address userReferrer, uint256 amount, uint256 betReferrerAmount, uint256 referrerAmount
    );
    event BetReferrerSet(address indexed user, address indexed referrer, address market, uint8 position);
    event ParlayReferrerSet(address indexed user, address indexed referrer, bytes32 _hash);

    struct BetInfo {
        uint256 amount;
        address referrer;
    }

    function setReferrer(address referrer, address referred) external;

    function setBetInfo(
        address referred,
        address referrer,
        address market,
        uint256 susdAmount,
        uint8 position
    )
        external;

    function setParlayInfo(address referred, address referrer, bytes32 _hash, uint256 susdAmount) external;

    function getBetInfo(address user, address market, uint8 position) external view returns (BetInfo memory);

    function getParlayInfo(address user, bytes32 hash) external view returns (BetInfo memory);

    function getParlayHash(uint256 expiry, uint256 amount, uint256 sUSDPaid) external pure returns (bytes32 refHash);

    function fee(uint256 total) external returns (uint256);
    function collectFee(uint256 amount, address user, address betReferrer, address collateral) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IOvertimeUser {
    error Initialized();
    error Unauthorized();
    error ZeroAddress();
    error NullPayout();

    event SingleReferrerSet(address market, uint8 position, address referrer);
    event ParlayReferrerSet(address[] sportMarkets, uint[] positions, address referrer);
    event BuySingleBet(address market, uint8 position, uint256 payout, address collateral, uint256 collateralAmount);
    event BuyParlayBet(
        address[] sportMarkets, uint[] positions, uint256 expectedPayout, address collateral, uint256 collateralAmount
    );
    event ExerciseSingleBet(address market, address collateral, uint256 payout);
    event ExerciseParlayBet(address market, address collateral, uint256 payout);

    function buySingle(address market, uint8 position, uint256 payout, uint256 desiredAmount) external payable;

    function buySingleWithDifferentCollateral(
        address market,
        uint8 position,
        uint256 payout,
        uint256 desiredAmount,
        address collateral
    )
        external
        payable;

    function buyParlay(
        address[] memory sportMarkets,
        uint256[] memory positions,
        uint256 expectedPayout,
        uint256 desiredAmount
    )
        external
        payable;

    function buyParlayWithDifferentCollateral(
        address[] memory sportMarkets,
        uint256[] memory positions,
        uint256 expectedPayout,
        uint256 desiredAmount,
        uint256 collateralAmount,
        address collateral
    )
        external
        payable;

    function exerciseParlay(address market) external returns (uint256 fee, address referrer);

    function exerciseParlayWithDifferentCollateral(
        address market,
        address collateral,
        bool toEth
    )
        external
        returns (uint256 fee, address referrer);

    function exerciseSingle(address market) external returns (uint256 fee, address referrer);

    function exerciseSingleWithDifferentCollateral(
        address market,
        address collateral,
        bool toEth
    )
        external
        returns (uint256 fee, address referrer);

    function initialize(address _user) external;

    function setVariables(
        address _sportsAMM,
        address _parlayMarketsAMM,
        address _feeManager,
        address _susd,
        address _weth,
        address _overtimeReferrer
    )
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IParlayMarket {
    type Phase is uint8;

    event Expired(address beneficiary);
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerNominated(address newOwner);
    event PauseUpdated(bool _paused);
    event Resolved(bool isUserTheWinner);

    function acceptOwnership() external;
    function amount() external view returns (uint256);
    function areAllPositionsResolved() external view returns (bool);
    function exerciseWiningSportMarkets() external;
    function expire(address payable beneficiary) external;
    function expiry() external view returns (uint256);
    function initialize(
        address[] memory _sportMarkets,
        uint256[] memory _positionPerMarket,
        uint256 _amount,
        uint256 _sUSDPaid,
        uint256 _expiryDuration,
        address _parlayMarketsAMM,
        address _parlayOwner,
        uint256 _totalQuote,
        uint256[] memory _marketQuotes
    )
        external;
    function initialized() external view returns (bool);
    function isParlayExercisable()
        external
        view
        returns (bool isExercisable, bool[] memory exercisedOrExercisableMarkets);
    function isParlayLost() external view returns (bool);
    function isUserTheWinner() external view returns (bool hasUserWon);
    function nominateNewOwner(address _owner) external;
    function nominatedOwner() external view returns (address);
    function numOfSportMarkets() external view returns (uint256);
    function owner() external view returns (address);
    function parlayAlreadyLost() external view returns (bool);
    function parlayMarketsAMM() external view returns (address);
    function parlayOwner() external view returns (address);
    function paused() external view returns (bool);
    function phase() external view returns (Phase);
    function resolved() external view returns (bool);
    function sUSDPaid() external view returns (uint256);
    function setPaused(bool _paused) external;
    function sportMarket(uint256)
        external
        view
        returns (
            address sportAddress,
            uint256 position,
            uint256 odd,
            uint256 result,
            bool resolved,
            bool exercised,
            bool hasWon,
            bool isCancelled
        );
    function totalResultQuote() external view returns (uint256);
    function withdrawCollateral(address recipient) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IParlayMarketsAMM {
    event AddressesSet(address _thalesAMM, address _safeBox, address _referrals, address _parlayMarketData);
    event ExtraAmountTransferredDueToCancellation(address receiver, uint256 amount);
    event NewParametersSet(uint256 parlaySize);
    event NewParlayMarket(address market, address[] markets, uint256[] positions, uint256 amount, uint256 sUSDpaid);
    event NewParlayMastercopy(address parlayMarketMastercopy);
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerNominated(address newOwner);
    event ParlayAmmFeePerAddressChanged(address _address, uint256 newFee);
    event ParlayLPSet(address parlayLP);
    event ParlayMarketCreated(
        address market,
        address account,
        uint256 amount,
        uint256 sUSDPaid,
        uint256 sUSDAfterFees,
        uint256 totalQuote,
        uint256 skewImpact,
        uint256[] marketQuotes
    );
    event ParlayResolved(address _parlayMarket, address _parlayOwner, bool _userWon);
    event PauseChanged(bool isPaused);
    event ReferrerPaid(address refferer, address trader, uint256 amount, uint256 volume);
    event SafeBoxFeePerAddressChanged(address _address, uint256 newFee);
    event SetAmounts(
        uint256 minUSDamount,
        uint256 max_amount,
        uint256 max_odds,
        uint256 _parlayAMMFee,
        uint256 _safeBoxImpact,
        uint256 _referrerFee,
        uint256 _maxAllowedRiskPerCombination
    );
    event SetMultiCollateralOnOffRamp(address _onramper, bool enabled);
    event SetSGPFeePerPosition(uint256 tag1, uint256 tag2_1, uint256 tag2_2, uint256 fee);
    event SetSUSD(address sUSDToken);
    event VerifierAndPolicySet(address _parlayVerifier, address _parlayPolicy);

    receive() external payable;

    function SGPFeePerCombination(uint256, uint256, uint256) external view returns (uint256);
    function acceptOwnership() external;
    function activeParlayMarkets(uint256 index, uint256 pageSize) external view returns (address[] memory);
    function buyFromParlay(
        address[] memory _sportMarkets,
        uint256[] memory _positions,
        uint256 _sUSDPaid,
        uint256 _additionalSlippage,
        uint256 _expectedPayout,
        address _differentRecipient
    )
        external;
    function buyFromParlayWithDifferentCollateralAndReferrer(
        address[] memory _sportMarkets,
        uint256[] memory _positions,
        uint256 _sUSDPaid,
        uint256 _additionalSlippage,
        uint256 _expectedPayout,
        address collateral,
        address _referrer
    )
        external;
    function buyFromParlayWithEth(
        address[] memory _sportMarkets,
        uint256[] memory _positions,
        uint256 _sUSDPaid,
        uint256 _additionalSlippage,
        uint256 _expectedPayout,
        address collateral,
        address _referrer
    )
        external
        payable;
    function buyFromParlayWithReferrer(
        address[] memory _sportMarkets,
        uint256[] memory _positions,
        uint256 _sUSDPaid,
        uint256 _additionalSlippage,
        uint256 _expectedPayout,
        address _differentRecipient,
        address _referrer
    )
        external;
    function buyQuoteFromParlay(
        address[] memory _sportMarkets,
        uint256[] memory _positions,
        uint256 _sUSDPaid
    )
        external
        view
        returns (
            uint256 sUSDAfterFees,
            uint256 totalBuyAmount,
            uint256 totalQuote,
            uint256 initialQuote,
            uint256 skewImpact,
            uint256[] memory finalQuotes,
            uint256[] memory amountsToBuy
        );
    function buyQuoteFromParlayWithDifferentCollateral(
        address[] memory _sportMarkets,
        uint256[] memory _positions,
        uint256 _sUSDPaid,
        address _collateral
    )
        external
        view
        returns (
            uint256 collateralQuote,
            uint256 sUSDAfterFees,
            uint256 totalBuyAmount,
            uint256 totalQuote,
            uint256 skewImpact,
            uint256[] memory finalQuotes,
            uint256[] memory amountsToBuy
        );
    function canCreateParlayMarket(
        address[] memory _sportMarkets,
        uint256[] memory _positions,
        uint256 _sUSDToPay
    )
        external
        view
        returns (bool canBeCreated);
    function curveSUSD() external view returns (address);
    function exerciseParlay(address _parlayMarket) external;
    function exerciseParlayWithOfframp(address _parlayMarket, address collateral, bool toEth) external;
    function expireMarkets(address[] memory _parlayMarkets) external;
    function getSgpFeePerCombination(
        uint256 tag1,
        uint256 tag2_1,
        uint256 tag2_2,
        uint256 position1,
        uint256 position2
    )
        external
        view
        returns (uint256 sgpFee);
    function initNonReentrant() external;
    function initialize(
        address _owner,
        address _sportsAmm,
        address _sportManager,
        uint256 _parlayAmmFee,
        uint256 _maxSupportedAmount,
        uint256 _maxSupportedOdds,
        address _sUSD,
        address _safeBox,
        uint256 _safeBoxImpact
    )
        external;
    function isActiveParlay(address _parlayMarket) external view returns (bool isActiveParlayMarket);
    function isParlayOwnerTheWinner(address _parlayMarket) external view returns (bool isUserTheWinner);
    function lastPauseTime() external view returns (uint256);
    function maxAllowedRiskPerCombination() external view returns (uint256);
    function maxSupportedAmount() external view returns (uint256);
    function maxSupportedOdds() external view returns (uint256);
    function minUSDAmount() external view returns (uint256);
    function multiCollateralOnOffRamp() external view returns (address);
    function multicollateralEnabled() external view returns (bool);
    function nominateNewOwner(address _owner) external;
    function nominatedOwner() external view returns (address);
    function numActiveParlayMarkets() external view returns (uint256);
    function owner() external view returns (address);
    function parlayAmmFee() external view returns (uint256);
    function parlayAmmFeePerAddress(address) external view returns (uint256);
    function parlayLP() external view returns (address);
    function parlayMarketData() external view returns (address);
    function parlayMarketMastercopy() external view returns (address);
    function parlayPolicy() external view returns (address);
    function parlaySize() external view returns (uint256);
    function parlayVerifier() external view returns (address);
    function parlaysWithNewFormat(address) external view returns (bool);
    function paused() external view returns (bool);
    function referrals() external view returns (address);
    function resolveParlay() external;
    function resolvedParlay(address) external view returns (bool);
    function riskPerCombination(
        address,
        uint256,
        address,
        uint256,
        address,
        uint256,
        address,
        uint256
    )
        external
        view
        returns (uint256);
    function riskPerGameCombination(
        address,
        address,
        address,
        address,
        address,
        address,
        address,
        address
    )
        external
        view
        returns (uint256);
    function riskPerMarketAndPosition(address, uint256) external view returns (uint256);
    function riskPerPackedGamesCombination(bytes32) external view returns (uint256);
    function sUSD() external view returns (address);
    function safeBox() external view returns (address);
    function safeBoxFeePerAddress(address) external view returns (uint256);
    function safeBoxImpact() external view returns (uint256);
    function setAddresses(
        address _sportsAMM,
        address _safeBox,
        address _referrals,
        address _parlayMarketData
    )
        external;
    function setAmounts(
        uint256 _minUSDAmount,
        uint256 _maxSupportedAmount,
        uint256 _maxSupportedOdds,
        uint256 _parlayAMMFee,
        uint256 _safeBoxImpact,
        uint256 _referrerFee,
        uint256 _maxAllowedRiskPerCombination
    )
        external;
    function setMultiCollateralOnOffRamp(address _onramper, bool enabled) external;
    function setOwner(address _owner) external;
    function setParameters(uint256 _parlaySize) external;
    function setParlayAmmFeePerAddress(address _address, uint256 newFee) external;
    function setParlayLP(address _parlayLP) external;
    function setParlayMarketMastercopies(address _parlayMarketMastercopy) external;
    function setPaused(bool _paused) external;
    function setPausedMarkets(address[] memory _parlayMarkets, bool _paused) external;
    function setSGPFeePerPosition(
        uint256[] memory tag1,
        uint256 tag2_1,
        uint256 tag2_2,
        uint256 position_1,
        uint256 position_2,
        uint256 fee
    )
        external;
    function setSafeBoxFeePerAddress(address _address, uint256 newFee) external;
    function setSgpFeePerCombination(uint256 tag1, uint256 tag2_1, uint256 tag2_2, uint256 fee) external;
    function setVerifierAndPolicyAddresses(address _parlayVerifier, address _parlayPolicy) external;
    function sportManager() external view returns (address);
    function sportsAmm() external view returns (address);
    function stakingThales() external view returns (address);
    function transferOwnershipAtInit(address proxyAddress) external;
    function triggerResolvedEvent(address _account, bool _userWon) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ISportsAMM {
    enum Position {
        Home,
        Away,
        Draw
    }

    event AddressesUpdated(
        address _safeBox,
        address _sUSD,
        address _theRundownConsumer,
        address _stakingThales,
        address _referrals,
        address _parlayAMM,
        address _wrapper,
        address _lp,
        address _riskManager
    );
    event BoughtFromAmm(
        address buyer, address market, Position position, uint256 amount, uint256 sUSDPaid, address susd, address asset
    );
    event ExercisedWithOfframp(
        address user, address market, address collateral, bool toEth, uint256 payout, uint256 payoutInCollateral
    );
    event OwnerChanged(address oldOwner, address newOwner);
    event OwnerNominated(address newOwner);
    event ParametersUpdated(
        uint256 _minimalTimeLeftToMaturity,
        uint256 _minSpread,
        uint256 _maxSpread,
        uint256 _minSupportedOdds,
        uint256 _maxSupportedOdds,
        uint256 _safeBoxImpact,
        uint256 _referrerFee,
        uint256 threshold
    );
    event Paused(address account);
    event ReferrerPaid(address refferer, address trader, uint256 amount, uint256 volume);
    event SetMultiCollateralOnOffRamp(address _onramper, bool enabled);
    event SetSportsPositionalMarketManager(address _manager);
    event Unpaused(address account);

    receive() external payable;

    function TAG_NUMBER_PLAYERS() external view returns (uint256);
    function acceptOwnership() external;
    function availableToBuyFromAMM(address market, Position position) external view returns (uint256 _available);
    function availableToBuyFromAMMWithBaseOdds(
        address market,
        Position position,
        uint256 baseOdds,
        uint256 balance,
        bool useBalance
    )
        external
        view
        returns (uint256 availableAmount);
    function buyFromAMM(
        address market,
        Position position,
        uint256 amount,
        uint256 expectedPayout,
        uint256 additionalSlippage
    )
        external;
    function buyFromAMMWithDifferentCollateral(
        address market,
        Position position,
        uint256 amount,
        uint256 expectedPayout,
        uint256 additionalSlippage,
        address collateral
    )
        external;
    function buyFromAMMWithDifferentCollateralAndReferrer(
        address market,
        Position position,
        uint256 amount,
        uint256 expectedPayout,
        uint256 additionalSlippage,
        address collateral,
        address _referrer
    )
        external;
    function buyFromAMMWithEthAndReferrer(
        address market,
        Position position,
        uint256 amount,
        uint256 expectedPayout,
        uint256 additionalSlippage,
        address collateral,
        address _referrer
    )
        external
        payable;
    function buyFromAMMWithReferrer(
        address market,
        Position position,
        uint256 amount,
        uint256 expectedPayout,
        uint256 additionalSlippage,
        address _referrer
    )
        external;
    function buyFromAmmQuote(
        address market,
        Position position,
        uint256 amount
    )
        external
        view
        returns (uint256 _quote);
    function buyFromAmmQuoteForParlayAMM(
        address market,
        Position position,
        uint256 amount
    )
        external
        view
        returns (uint256 _quote);
    function buyFromAmmQuoteWithDifferentCollateral(
        address market,
        Position position,
        uint256 amount,
        address collateral
    )
        external
        view
        returns (uint256 collateralQuote, uint256 sUSDToPay);
    function buyPriceImpact(address market, Position position, uint256 amount) external view returns (int256 impact);
    function exerciseWithOfframp(address market, address collateral, bool toEth) external;
    function floorBaseOdds(uint256 baseOdds, address market) external view returns (uint256);
    function getMarketDefaultOdds(address _market, bool isSell) external view returns (uint256[] memory odds);
    function initNonReentrant() external;
    function initialize(
        address _owner,
        address _sUSD,
        uint256 _min_spread,
        uint256 _max_spread,
        uint256 _minimalTimeLeftToMaturity
    )
        external;
    function isMarketInAMMTrading(address market) external view returns (bool isTrading);
    function liquidityPool() external view returns (address);
    function manager() external view returns (address);
    function maxSupportedOdds() external view returns (uint256);
    function max_spread() external view returns (uint256);
    function minSupportedOdds() external view returns (uint256);
    function min_spread() external view returns (uint256);
    function min_spreadPerAddress(address) external view returns (uint256);
    function minimalTimeLeftToMaturity() external view returns (uint256);
    function multiCollateralOnOffRamp() external view returns (address);
    function multicollateralEnabled() external view returns (bool);
    function nominateNewOwner(address _owner) external;
    function nominatedOwner() external view returns (address);
    function obtainOdds(address _market, Position _position) external view returns (uint256 oddsToReturn);
    function owner() external view returns (address);
    function parlayAMM() external view returns (address);
    function paused() external view returns (bool);
    function referrals() external view returns (address);
    function riskManager() external view returns (address);
    function sUSD() external view returns (address);
    function safeBox() external view returns (address);
    function safeBoxFeePerAddress(address) external view returns (uint256);
    function safeBoxImpact() external view returns (uint256);
    function setAddresses(
        address _safeBox,
        address _sUSD,
        address _theRundownConsumer,
        address _stakingThales,
        address _referrals,
        address _parlayAMM,
        address _wrapper,
        address _lp,
        address _riskManager
    )
        external;
    function setAmmUtils(address _ammUtils) external;
    function setMultiCollateralOnOffRamp(address _onramper, bool enabled) external;
    function setOwner(address _owner) external;
    function setParameters(
        uint256 _minimalTimeLeftToMaturity,
        uint256 _minSpread,
        uint256 _maxSpread,
        uint256 _minSupportedOdds,
        uint256 _maxSupportedOdds,
        uint256 _safeBoxImpact,
        uint256 _referrerFee,
        uint256 _threshold
    )
        external;
    function setPaused(bool _setPausing) external;
    function setSafeBoxFeeAndMinSpreadPerAddress(address _address, uint256 newSBFee, uint256 newMSFee) external;
    function setSportsPositionalMarketManager(address _manager) external;
    function spentOnGame(address) external view returns (uint256);
    function sportAmmUtils() external view returns (address);
    function stakingThales() external view returns (address);
    function theRundownConsumer() external view returns (address);
    function thresholdForOddsUpdate() external view returns (uint256);
    function transferOwnershipAtInit(address proxyAddress) external;
    function updateParlayVolume(address _account, uint256 _amount) external;
    function wrapper() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarket.sol";

interface IPositionalMarketManager {
    /* ========== VIEWS / VARIABLES ========== */

    function durations() external view returns (uint expiryDuration, uint maxTimeToMaturity);

    function capitalRequirement() external view returns (uint);

    function marketCreationEnabled() external view returns (bool);

    function onlyAMMMintingAndBurning() external view returns (bool);

    function transformCollateral(uint value) external view returns (uint);

    function reverseTransformCollateral(uint value) external view returns (uint);

    function totalDeposited() external view returns (uint);

    function numActiveMarkets() external view returns (uint);

    function activeMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function numMaturedMarkets() external view returns (uint);

    function maturedMarkets(uint index, uint pageSize) external view returns (address[] memory);

    function isActiveMarket(address candidate) external view returns (bool);

    function isKnownMarket(address candidate) external view returns (bool);

    function getThalesAMM() external view returns (address);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function createMarket(
        bytes32 oracleKey,
        uint strikePrice,
        uint maturity,
        uint initialMint // initial sUSD to mint options for,
    ) external returns (IPositionalMarket);

    function resolveMarket(address market) external;

    function expireMarkets(address[] calldata market) external;

    function transferSusdTo(
        address sender,
        address receiver,
        uint amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "./IPositionalMarket.sol";

interface IPosition {
    /* ========== VIEWS / VARIABLES ========== */

    function getBalanceOf(address account) external view returns (uint);

    function getTotalSupply() external view returns (uint);

    function exerciseWithAmount(address claimant, uint amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

interface IPriceFeed {
    // Structs
    struct RateAndUpdatedTime {
        uint216 rate;
        uint40 time;
    }

    // Mutative functions
    function addAggregator(bytes32 currencyKey, address aggregatorAddress) external;

    function removeAggregator(bytes32 currencyKey) external;

    // Views

    function rateForCurrency(bytes32 currencyKey) external view returns (uint);

    function rateAndUpdatedTime(bytes32 currencyKey) external view returns (uint rate, uint time);

    function getRates() external view returns (uint[] memory);

    function getCurrencies() external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.16;

import "../interfaces/IPositionalMarketManager.sol";
import "../interfaces/IPosition.sol";
import "../interfaces/IPriceFeed.sol";

interface IPositionalMarket {
    /* ========== TYPES ========== */

    enum Phase {
        Trading,
        Maturity,
        Expiry
    }
    enum Side {
        Up,
        Down
    }

    /* ========== VIEWS / VARIABLES ========== */

    function getOptions() external view returns (IPosition up, IPosition down);

    function times() external view returns (uint maturity, uint destructino);

    function getOracleDetails()
        external
        view
        returns (
            bytes32 key,
            uint strikePrice,
            uint finalPrice
        );

    function fees() external view returns (uint poolFee, uint creatorFee);

    function deposited() external view returns (uint);

    function creator() external view returns (address);

    function resolved() external view returns (bool);

    function phase() external view returns (Phase);

    function oraclePrice() external view returns (uint);

    function oraclePriceAndTimestamp() external view returns (uint price, uint updatedAt);

    function canResolve() external view returns (bool);

    function result() external view returns (Side);

    function balancesOf(address account) external view returns (uint up, uint down);

    function totalSupplies() external view returns (uint up, uint down);

    function getMaximumBurnable(address account) external view returns (uint amount);

    /* ========== MUTATIVE FUNCTIONS ========== */

    function mint(uint value) external;

    function exerciseOptions() external returns (uint);

    function burnOptions(uint amount) external;

    function burnOptionsMaximum() external;
}