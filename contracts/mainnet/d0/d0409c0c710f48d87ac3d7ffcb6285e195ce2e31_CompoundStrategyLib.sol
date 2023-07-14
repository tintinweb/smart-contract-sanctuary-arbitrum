// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {ICompoundStrategy} from "src/interfaces/ICompoundStrategy.sol";
import {IRouter} from "src/interfaces/IRouter.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

library CompoundStrategyLib {
    using FixedPointMathLib for uint256;

    /**
     * @notice Get current epoch and end time.
     */
    function epochEndTime(ICompoundStrategy self) external view returns (uint256, uint64) {
        uint256 _epoch = self.currentEpoch();
        return (_epoch, self.epochData(_epoch).endTime);
    }

    /**
     * @notice Get current epoch, end time and both option risks.
     */
    function epochEndTimeAndOptionRisk(ICompoundStrategy self)
        external
        view
        returns (uint256, uint64, uint256, uint256)
    {
        uint256 _epoch = self.currentEpoch();
        ICompoundStrategy.Epoch memory epochData = self.epochData(_epoch);
        return (_epoch, epochData.endTime, epochData.optionBullRisk, epochData.optionBearRisk);
    }

    /**
     * @notice Get current epoch, end time and withdraw rate.
     */
    function epochEndTimeAndWithdrawRates(ICompoundStrategy self, uint256 _epoch, IRouter.OptionStrategy _strategy)
        external
        view
        returns (uint256, uint256, uint256)
    {
        uint256 epoch_ = self.currentEpoch();
        ICompoundStrategy.Epoch memory epochData = self.epochData(_epoch);

        uint256 exchangeRate = _strategy == IRouter.OptionStrategy.BULL
            ? uint256(epochData.withdrawBullExchangeRate)
            : uint256(epochData.withdrawBearExchangeRate);

        return (epoch_, epochData.endTime, exchangeRate);
    }

    /**
     * @notice Get current epoch, end time and depsoit rate.
     */
    function epochEndTimeAndDepositRate(ICompoundStrategy self, uint256 _epoch, IRouter.OptionStrategy _strategy)
        external
        view
        returns (uint256, uint256, uint256)
    {
        uint256 epoch_ = self.currentEpoch();
        ICompoundStrategy.Epoch memory epochData = self.epochData(_epoch);
        uint256 rate;

        if (_strategy == IRouter.OptionStrategy.BULL) {
            rate = epochData.depositBullRatio;
        } else {
            rate = epochData.depositBearRatio;
        }

        return (epoch_, epochData.endTime, rate);
    }

    /**
     * @notice Get custom epoch, end time and flip rate.
     */
    function epochEndTimeAndFlipRate(
        ICompoundStrategy self,
        uint256 _targetEpoch,
        IRouter.OptionStrategy _oldStrategy,
        IRouter.OptionStrategy _newStrategy
    ) external view returns (uint256, uint256, uint256) {
        uint256 _epoch = self.currentEpoch();
        ICompoundStrategy.Epoch memory epochData;

        if (_targetEpoch == 0) {
            epochData = self.epochData(_epoch);
        } else {
            epochData = self.epochData(_targetEpoch - 1);
        }

        uint256 flipRate;

        if (_oldStrategy == IRouter.OptionStrategy.BULL && _newStrategy == IRouter.OptionStrategy.BEAR) {
            flipRate = uint256(epochData.flipBullToBearExchangeRate);
        }
        if (_oldStrategy == IRouter.OptionStrategy.BULL && _newStrategy == IRouter.OptionStrategy.CRAB) {
            flipRate = uint256(epochData.flipBullToCrabExchangeRate);
        }
        if (_oldStrategy == IRouter.OptionStrategy.BEAR && _newStrategy == IRouter.OptionStrategy.BULL) {
            flipRate = uint256(epochData.flipBearToBullExchangeRate);
        }
        if (_oldStrategy == IRouter.OptionStrategy.BEAR && _newStrategy == IRouter.OptionStrategy.CRAB) {
            flipRate = uint256(epochData.flipBearToCrabExchangeRate);
        }
        if (_oldStrategy == IRouter.OptionStrategy.CRAB && _newStrategy == IRouter.OptionStrategy.BULL) {
            flipRate = uint256(epochData.flipCrabToBullExchangeRate);
        }
        if (_oldStrategy == IRouter.OptionStrategy.CRAB && _newStrategy == IRouter.OptionStrategy.BEAR) {
            flipRate = uint256(epochData.flipCrabToBearExchangeRate);
        }

        return (_epoch, epochData.endTime, flipRate);
    }

    /**
     * @notice Get current epoch, shares with penalty, retention incentive and incentive receiver.
     */
    function retentionAndPenalty(ICompoundStrategy self, uint256 _shares, IRouter.OptionStrategy _strategy)
        external
        view
        returns (uint256, uint256, uint256, address)
    {
        uint256 _epoch = self.currentEpoch();
        ICompoundStrategy.Epoch memory epochData = self.epochData(_epoch);

        uint256 sharesWithPenalty;

        if (_strategy == IRouter.OptionStrategy.BULL) {
            sharesWithPenalty = _shares - _shares.mulDivDown(epochData.optionBullRisk, 1e12);
        } else if (_strategy == IRouter.OptionStrategy.BEAR) {
            sharesWithPenalty = _shares - _shares.mulDivDown(epochData.optionBearRisk, 1e12);
        } else {
            sharesWithPenalty = _shares;
        }

        return (_epoch, sharesWithPenalty, self.retentionIncentive(), self.incentiveReceiver());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IOption} from "src/interfaces/IOption.sol";
import {IRouter} from "src/interfaces/IRouter.sol";
import {ISwap} from "src/interfaces/ISwap.sol";
import {ILPVault} from "src/interfaces/ILPVault.sol";
import {IOptionStrategy} from "src/interfaces/IOptionStrategy.sol";

interface ICompoundStrategy {
    /**
     * @notice Usefull Epoch Data
     */
    struct Epoch {
        // Start time of the epoch
        uint64 startTime;
        // When the Epoch expiries
        uint64 virtualEndTime;
        // When we finish the Epoch
        uint64 endTime;
        // % of Bull vault used to buy call options
        uint64 optionBullRisk;
        // % of Bear vault used to buy put options
        uint64 optionBearRisk;
        // Initial LP amount in the begin of the Epoch
        uint128 initialBullRatio;
        uint128 initialBearRatio;
        uint128 initialCrabRatio;
        // Withdraw Rates jLP -> LP
        uint128 withdrawBullExchangeRate;
        uint128 withdrawBearExchangeRate;
        // Flip Rates bullLP -> bearLP
        uint128 flipBullToBearExchangeRate;
        uint128 flipBullToCrabExchangeRate;
        uint128 flipBearToBullExchangeRate;
        uint128 flipBearToCrabExchangeRate;
        uint128 flipCrabToBullExchangeRate;
        uint128 flipCrabToBearExchangeRate;
        // Deposit Rates
        uint128 depositBullRatio;
        uint128 depositBearRatio;
        // Final amount of LP in the end of the Epoch
        uint128 finalBullRatio;
        uint128 finalBearRatio;
        uint128 finalCrabRatio;
    }

    /**
     * @notice Start epoch information, help on startEpoch (stack too deep)
     */
    struct StartEpochInfo {
        uint256 epoch;
        address thisAddress;
        uint256 currentLPBalance;
        uint256 farmBalance;
        uint256 initialBalanceSnapshot;
        uint256 bullAssets;
        uint256 bearAssets;
        uint256 crabAssets;
        uint256 totalBalance;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 toOptions;
        uint256 bullRatio;
        uint256 bearRatio;
        uint256 crabRatio;
    }

    /**
     * @notice General epoch information, help on endEpoch (stack too deep)
     */
    struct GeneralInfo {
        Epoch epochData;
        uint256 currentEpoch;
        uint256 endTime;
        address thisAddress;
        IRouter router;
        address routerAddress;
        ILPVault bullVault;
        ILPVault bearVault;
        ILPVault crabVault;
        IRouter.OptionStrategy bullStrat;
        IRouter.OptionStrategy bearStrat;
        IRouter.OptionStrategy crabStrat;
        IERC20 lpToken;
    }

    /**
     * @notice Flip signals information.
     */
    struct FlipInfo {
        uint256 bullToBear;
        uint256 bullToCrab;
        uint256 bearToBull;
        uint256 bearToCrab;
        uint256 crabToBull;
        uint256 crabToBear;
        uint256 redeemBullToBearAssets;
        uint256 redeemBullToCrabAssets;
        uint256 redeemBearToBullAssets;
        uint256 redeemBearToCrabAssets;
        uint256 redeemCrabToBullAssets;
        uint256 redeemCrabToBearAssets;
        uint256 bullToBearShares;
        uint256 bullToCrabShares;
        uint256 bearToBullShares;
        uint256 bearToCrabShares;
        uint256 crabToBearShares;
        uint256 crabToBullShares;
        uint256 bullToBearRate;
        uint256 bullToCrabRate;
        uint256 bearToBullRate;
        uint256 bearToCrabRate;
        uint256 crabToBullRate;
        uint256 crabToBearRate;
    }

    /**
     * @notice Withdraw signals information.
     */
    struct WithdrawInfo {
        uint256 bullShares;
        uint256 bearShares;
        uint256 bullAssets;
        uint256 bearAssets;
        uint256 totalSignals;
        uint256 bullRetention;
        uint256 bearRetention;
        uint256 retention;
        uint256 toTreasury;
        uint256 toPayBack;
        uint256 currentBalance;
        uint256 withdrawBullRate;
        uint256 withdrawBearRate;
    }

    /**
     * @notice Next epoch deposit information.
     */
    struct DepositInfo {
        uint256 depositBullAssets;
        uint256 depositBearAssets;
        uint256 depositBullShares;
        uint256 depositBearShares;
        uint256 depositBullRate;
        uint256 depositBearRate;
    }

    /**
     * @notice Auto compounds all the farming rewards.
     */
    function autoCompound() external;

    /**
     * @notice Handles LPs deposits accountability and staking
     * @param _amount Amount of LP tokens being deposited
     * @param _type Strategy which balance will be updated
     * @param _nextEpoch signal to not increase the balance of the vault immidiatly.
     */
    function deposit(uint256 _amount, IRouter.OptionStrategy _type, bool _nextEpoch) external;

    /**
     * @notice Withdraw LP assets.
     * @param _amountWithPenalty Amount to unstake
     * @param _receiver Who will receive the LP token
     */
    function instantWithdraw(uint256 _amountWithPenalty, IRouter.OptionStrategy _type, address _receiver) external;

    /**
     * @notice Get Strategy Assets; farm + here
     */
    function totalAssets() external view returns (uint256);

    /**
     * @notice Get LP Vault Assets, overall LP for a Vault.
     */
    function vaultAssets(IRouter.OptionStrategy _type) external view returns (uint256);

    /**
     * @notice Get Current epoch.
     */
    function currentEpoch() external view returns (uint256);

    /**
     * @notice Get epoch Data.
     */
    function epochData(uint256 number) external view returns (Epoch memory);

    /**
     * @notice Get the LP Token.
     */
    function lpToken() external view returns (IERC20);

    /**
     * @notice Get retention incentive percentage.
     */
    function retentionIncentive() external view returns (uint256);

    /**
     * @notice Get the incentive receiver address.
     */
    function incentiveReceiver() external view returns (address);

    /**
     * @notice Get the three strategy Vaults; 0 => BULL, 1 => BEAR, 2 => CRAB
     */
    function getVaults() external view returns (ILPVault[] memory);

    /**
     * @notice Start new epoch.
     */
    function startEpoch(uint64 epochExpiry, uint64 optionBullRisk, uint64 optionBearRisk) external;

    /**
     * @notice Finish current epoch.
     */
    function endEpoch() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IOptionStrategy} from "src/interfaces/IOptionStrategy.sol";
import {ICompoundStrategy} from "src/interfaces/ICompoundStrategy.sol";
import {ILPVault} from "src/interfaces/ILPVault.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IRouter {
    /**
     * @notice Different types of vaults.
     */
    enum OptionStrategy {
        BULL,
        BEAR,
        CRAB
    }

    /**
     * @notice Deposit info struct, helps on deposit process (stack too deep).
     */
    struct DepositInfo {
        address receiver;
        OptionStrategy strategy;
        address thisAddress;
        uint256 epoch;
        uint64 endTime;
        uint256 optionBullRisk;
        uint256 optionBearRisk;
        address strategyAddress;
        address optionsAddress;
        ICompoundStrategy compoundStrategy;
        IOptionStrategy optionStrategy;
        IERC20 lpToken;
        ILPVault vault;
        uint256 assets;
        uint256 toFarm;
        uint256 toBuyOptions;
        uint256 shares;
    }

    /**
     * @notice Withdraw info struct, helps on withdraw process (stack too deep).
     */
    struct WithdrawInfo {
        uint256 currentEpoch;
        uint256 endTime;
        uint256 withdrawExchangeRate;
        uint256 currentBalance;
        uint256 lpAssets;
        uint256 retention;
        uint256 toTreasury;
        uint256 redemeed;
    }

    /**
     * @notice Cancel flip info struct, helps on cancelFlip (stack too deep).
     */
    struct CancelFlipInfo {
        uint256 commitEpoch;
        uint256 currentEpoch;
        uint256 endTime;
        uint256 finalShares;
        uint256 flipRate;
    }

    /**
     * @notice User withdraw signal struct.
     */
    struct WithdrawalSignal {
        uint256 targetEpoch;
        uint256 commitedShares;
        OptionStrategy strategy;
        uint256 redeemed;
    }

    /**
     * @notice User flip signal struct.
     */
    struct FlipSignal {
        uint256 targetEpoch;
        uint256 commitedShares;
        OptionStrategy oldStrategy;
        OptionStrategy newStrategy;
        uint256 redeemed;
    }

    /**
     * @notice Enable LP deposits to a Strategy Metavault.
     * @param _assets Amount of assets to be deposit
     * @param _strategy Type of Metavault, it can be BULL, BEAR or CRAB.
     * @param _instant True if is instant deposit, false if is for the next epoch.
     * @param _receiver Who will receive the shares.
     * @return Amount of shares minted.
     */
    function deposit(uint256 _assets, OptionStrategy _strategy, bool _instant, address _receiver)
        external
        returns (uint256);

    /**
     * @notice Get shares for previues epoch deposit.
     * @param _commitEpoch Amount of assets to be deposit
     * @param _strategy Type of Metavault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the shares.
     * @return Amount of shares.
     */
    function claim(uint256 _commitEpoch, OptionStrategy _strategy, address _receiver) external returns (uint256);

    /**
     * @notice Signal withdraw to the next epoch.
     * @param _receiver Who will receive the assets redeemed.
     * @param _strategy Type of Metavault, it can be BULL, BEAR or CRAB.
     * @param _shares Amount of Metavault shares to redeem.
     * @return Target epoch.
     */
    function signalWithdraw(address _receiver, OptionStrategy _strategy, uint256 _shares) external returns (uint256);

    /**
     * @notice Cancel signal withdraw.
     * @param _targetEpoch Signal target epoch.
     * @param _strategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the shares.
     * @return LP shares.
     */
    function cancelSignal(uint256 _targetEpoch, OptionStrategy _strategy, address _receiver)
        external
        returns (uint256);

    /**
     * @notice Withdraw.
     * @param _targetEpoch Signal target epoch.
     * @param _strategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the assets.
     * @return LP assets.
     */
    function withdraw(uint256 _targetEpoch, OptionStrategy _strategy, address _receiver) external returns (uint256);

    /**
     * @notice Instant withdraw.
     * @param _shares Shares to redeem.
     * @param _strategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the assets.
     * @return LP assets.
     */
    function instantWithdraw(uint256 _shares, OptionStrategy _strategy, address _receiver) external returns (uint256);

    /**
     * @notice Signal flip.
     * @param _shares Shares to flip.
     * @param _oldtrategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _newStrategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the shares.
     */
    function signalFlip(uint256 _shares, OptionStrategy _oldtrategy, OptionStrategy _newStrategy, address _receiver)
        external
        returns (uint256);

    /**
     * @notice Cancel Flip Signal.
     * @param _targetEpoch Signal target epoch.
     * @param _oldStrategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _newStrategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the shares.
     * @return LP shares.
     */
    function cancelFlip(
        uint256 _targetEpoch,
        OptionStrategy _oldStrategy,
        OptionStrategy _newStrategy,
        address _receiver
    ) external returns (uint256);

    /**
     * @notice Withdraw flipped shares.
     * @param _targetEpoch Shares to flip.
     * @param _oldStrategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _newStrategy Type of Vault, it can be BULL, BEAR or CRAB.
     * @param _receiver Who will receive the shares.
     * @return LP shares.
     */
    function flipWithdraw(
        uint256 _targetEpoch,
        OptionStrategy _oldStrategy,
        OptionStrategy _newStrategy,
        address _receiver
    ) external returns (uint256);

    /**
     * @notice Update accounting when epoch finish.
     */
    function executeFinishEpoch() external;

    /**
     * @notice Total strategy next epoch deposit.
     */
    function nextEpochDeposits(OptionStrategy _strategy) external view returns (uint256);

    /**
     * @notice User next epoch deposit for a strategy.
     */
    function userNextEpochDeposits(address _user, uint256 _epoch, IRouter.OptionStrategy _strategy)
        external
        view
        returns (uint256);

    /**
     * @notice Get total withdraw signals.
     */
    function withdrawSignals(OptionStrategy _strategy) external view returns (uint256);

    /**
     * @notice Get user withdraw signals per epoch per strategy.
     */
    function getWithdrawSignal(address _user, uint256 _targetEpoch, OptionStrategy _strategy)
        external
        view
        returns (WithdrawalSignal memory);

    /**
     * @notice Total Flip Signals.
     */
    function flipSignals(OptionStrategy _oldStrategy, OptionStrategy _newStrategy) external view returns (uint256);

    /**
     * @notice Get user flip signals.
     */
    function getFlipSignal(
        address _user,
        uint256 _targetEpoch,
        OptionStrategy _oldStrategy,
        OptionStrategy _newStrategy
    ) external view returns (FlipSignal memory);

    /**
     * @notice Get premium.
     */
    function premium() external view returns (uint256);

    /**
     * @notice Get slippage.
     */
    function slippage() external view returns (uint256);
}

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IRouter} from "src/interfaces/IRouter.sol";
import {ISSOV, IERC20} from "src/interfaces/option/dopex/ISSOV.sol";

interface IOption {
    enum OPTION_TYPE {
        CALLS,
        PUTS
    }

    struct ExecuteParams {
        uint256 currentEpoch;
        // strike price
        uint256[] _strikes;
        // % used in each strike;
        uint256[] _collateralEachStrike;
        uint256 _expiry;
        bytes _externalData;
    }

    // Data needed to settle the ITM options
    struct SettleParams {
        uint256 currentEpoch;
        uint256 optionEpoch;
        // The ITM strikes we will settle
        uint256[] strikesToSettle;
        bytes _externalData;
    }

    // Data needed to execute a single option pruchase (stack too deep)
    struct SingleOptionInfo {
        ISSOV ssov;
        IERC20 collateralToken;
        address here;
        address collateralAddress;
        uint256 collateral;
        uint256 ssovEpoch;
        uint256 optionsAmount;
    }

    // Buys options.
    // Return avg option price in WETH
    function purchase(ExecuteParams calldata params) external;

    // Execute option pruchase in mid epoch
    function executeSingleOptionPurchase(uint256 _epoch, uint256 _strike, uint256 _collateral)
        external
        returns (uint256);

    // Settle ITM options
    function settle(SettleParams calldata params) external returns (uint256);

    // Get option price from given type and strike. On DopEx its returned in collateral token.
    function getOptionPrice(uint256 _strike) external view returns (uint256);

    // system epoch => option epoch
    function epochs(uint256 _epoch) external view returns (uint256);

    function strategy() external view returns (IRouter.OptionStrategy _strategy);

    // avg option price getting ExecuteParams buy the same options
    function optionType() external view returns (OPTION_TYPE);

    function getCurrentStrikes() external view returns (uint256[] memory);

    // Token used to buy options
    function getCollateralToken() external view returns (address);

    function geAllStrikestPrices() external view returns (uint256[] memory);

    function getAvailableOptions(uint256 _strike) external view returns (uint256);
    function position(address _compoundStrategy) external view returns (uint256);

    function lpToCollateral(address _lp, uint256 _amount) external view returns (uint256);
    function getExpiry() external view returns (uint256);

    function amountOfOptions(address _optionStrategy, uint256 _epoch, uint256 _strikeIndex)
        external
        view
        returns (uint256);
    function pnl(address _optionStrategy, address _compoundStrategy) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface ISwap {
    struct SwapData {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        bytes externalData;
    }

    function swap(SwapData memory) external returns (uint256);
    function batchSwap(SwapData[] memory) external returns (uint256[] memory);
    function swapTokensToEth(address _token, uint256 _amount) external;

    error NotImplemented();
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// Interfaces
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface ILPVault is IERC20 {
    /**
     * @notice get underlying token
     */
    function underlying() external returns (IERC20);
    /**
     * @notice See {IERC4626-deposit}.
     */
    function mint(uint256 _shares, address _receiver) external returns (uint256);
    /**
     * @notice See {IERC4626-deposit}.
     */
    function burn(address _account, uint256 _shares) external;
    /**
     * @notice See {IERC4626-deposit}.
     */
    function previewDeposit(uint256 _assets) external view returns (uint256);
    /**
     * @notice See {IERC4626-deposit}.
     */
    function previewRedeem(uint256 _shares) external view returns (uint256);
    /**
     * @notice get Vault total assets
     */
    function totalAssets() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import {IRouter} from "src/interfaces/IRouter.sol";
import {IOption} from "src/interfaces/IOption.sol";
import {ISwap} from "src/interfaces/ISwap.sol";

interface IOptionStrategy {
    // One deposit can buy from different providers
    struct OptionParams {
        // Swap Data (WETH -> token needed to buy options)
        // Worst case we make 4 swaps
        bytes swapData;
        // Swappper to buy options (default: OneInch)
        ISwap swapper;
        // Amount of lp to BULL
        uint256 percentageLpBull;
    }

    struct Strike {
        // Strike price, eg: $1800
        uint256 price;
        // How much it cost to buy one option for the given strike
        uint256 costIndividual;
        // How much it was spent in total for this strike
        uint256 costTotal;
        // From the amount set to be spent on options, how much this strike represents of the total portion
        uint256 percentageOverTotalCollateral;
        // Current amount of options
        uint256 currentOptions;
    }

    // Index 0 is most profitable option
    struct ExecuteStrategy {
        uint256 currentEpoch;
        // Array of providers
        IOption[] providers;
        // amount of the broken lp that will go to the provider to purchase options
        uint256[] providerPercentage;
        // Each provider can have different strikes
        // Strikes according to the same order as percentageEachStrike. Using 8 decimals
        uint256[][] strikes;
        uint256[][] collateralEachStrike;
        // Used for Dopex's leave blank (0) for other providers.
        uint256[] expiry;
        // Extra data for options providers
        bytes[] externalData;
    }

    // Struct used to collect profits from options purchase
    struct CollectRewards {
        // System epoch
        uint256 currentEpoch;
        // Array of providers
        IOption[] providers;
        // Each provider can have different strikes
        // Strikes according to the same order as percentageEachStrike. DopEx default: 8 decimals
        uint256[][] strikes;
        // Extra data for options providers
        bytes[] externalData;
    }

    // Deposits into OptionStrategy to execute options logic
    struct Budget {
        // Deposits to buy options
        uint128 totalDeposits;
        uint128 bullDeposits;
        uint128 bearDeposits;
        // Profits from options
        uint128 bullEarned;
        uint128 bearEarned;
        uint128 totalEarned;
    }

    struct DifferenceAndOverpaying {
        // Strike (eg: 1800e8)
        uint256 strikePrice;
        // How much it costs to buy strike
        uint256 strikeCost;
        // Amount of collateral going to given strike
        uint256 collateral;
        // ToFarm -> only in case options prices are now cheaper
        uint256 toFarm;
        // true -> means options prices are now higher than when strategy was executed
        // If its false, we are purchasing same amount of options with less collateral and sending extra to farm
        bool isOverpaying;
    }

    function deposit(uint256 _epoch, uint256 _amount, uint256 _bullDeposits, uint256 _bearDeposits) external;
    function middleEpochOptionsBuy(
        uint256 _epoch,
        IRouter.OptionStrategy _type,
        IOption _provider,
        uint256 _collateralAmount,
        uint256 _strike
    ) external returns (uint256);
    function optionPosition(uint256 _epoch, IRouter.OptionStrategy _type) external view returns (uint256);
    function deltaPrice(uint256 _epoch, uint256 usersAmountOfLp, IOption _provider)
        external
        view
        returns (DifferenceAndOverpaying[] memory);
    function dopexAdapter(IOption.OPTION_TYPE) external view returns (IOption);
    function startCrabStrategy(IRouter.OptionStrategy _strategyType, uint256 _epoch) external;
    function getBullProviders(uint256 epoch) external view returns (IOption[] memory);
    function getBearProviders(uint256 epoch) external view returns (IOption[] memory);
    function executeBullStrategy(uint256 _epoch, uint128 _toSpend, ExecuteStrategy calldata _execute) external;
    function executeBearStrategy(uint256 _epoch, uint128 _toSpend, ExecuteStrategy calldata _execute) external;
    function collectRewards(IOption.OPTION_TYPE _type, CollectRewards calldata _collect, bytes memory _externalData)
        external
        returns (uint256);
    function getBoughtStrikes(uint256 _epoch, IOption _provider) external view returns (Strike[] memory);
    function addBoughtStrikes(uint256 _epoch, IOption _provider, Strike memory _data) external;
    function updateOptionStrike(uint256 _epoch, IOption _provider, uint256 _strike, Strike memory _data) external;
    function settleOptionStrike(uint256 _epoch, IOption _provider, uint256 _strike) external;
    function borrowedLP(IRouter.OptionStrategy _type) external view returns (uint256);
    function executedStrategy(uint256 _epoch, IRouter.OptionStrategy _type) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

interface ISSOV {
    struct Addresses {
        address feeStrategy;
        address stakingStrategy;
        address optionPricing;
        address priceOracle;
        address volatilityOracle;
        address feeDistributor;
        address optionsTokenImplementation;
    }

    struct EpochData {
        bool expired;
        uint256 startTime;
        uint256 expiry;
        uint256 settlementPrice;
        uint256 totalCollateralBalance; // Premium + Deposits from all strikes
        uint256 collateralExchangeRate; // Exchange rate for collateral to underlying (Only applicable to CALL options)
        uint256 settlementCollateralExchangeRate; // Exchange rate for collateral to underlying on settlement (Only applicable to CALL options)
        uint256[] strikes;
        uint256[] totalRewardsCollected;
        uint256[] rewardDistributionRatios;
        address[] rewardTokensToDistribute;
    }

    struct EpochStrikeData {
        address strikeToken;
        uint256 totalCollateral;
        uint256 activeCollateral;
        uint256 totalPremiums;
        uint256 checkpointPointer;
        uint256[] rewardStoredForPremiums;
        uint256[] rewardDistributionRatiosForPremiums;
    }

    struct VaultCheckpoint {
        uint256 activeCollateral;
        uint256 totalCollateral;
        uint256 accruedPremium;
    }

    struct WritePosition {
        uint256 epoch;
        uint256 strike;
        uint256 collateralAmount;
        uint256 checkpointIndex;
        uint256[] rewardDistributionRatios;
    }

    function expire() external;

    function deposit(uint256 strikeIndex, uint256 amount, address user) external returns (uint256 tokenId);

    function purchase(uint256 strikeIndex, uint256 amount, address user)
        external
        returns (uint256 premium, uint256 totalFee);

    function settle(uint256 strikeIndex, uint256 amount, uint256 epoch, address to) external returns (uint256 pnl);

    function withdraw(uint256 tokenId, address to)
        external
        returns (uint256 collateralTokenWithdrawAmount, uint256[] memory rewardTokenWithdrawAmounts);

    function getUnderlyingPrice() external view returns (uint256);

    function getCollateralPrice() external returns (uint256);

    function getVolatility(uint256 _strike) external view returns (uint256);

    function calculatePremium(uint256 _strike, uint256 _amount, uint256 _expiry)
        external
        view
        returns (uint256 premium);

    function calculatePnl(uint256 price, uint256 strike, uint256 amount, uint256 collateralExchangeRate)
        external
        pure
        returns (uint256);

    function calculatePurchaseFees(uint256 strike, uint256 amount) external view returns (uint256);

    function calculateSettlementFees(uint256) external view returns (uint256);

    function getEpochTimes(uint256 epoch) external view returns (uint256 start, uint256 end);

    function writePosition(uint256 tokenId)
        external
        view
        returns (
            uint256 epoch,
            uint256 strike,
            uint256 collateralAmount,
            uint256 checkpointIndex,
            uint256[] memory rewardDistributionRatios
        );

    function getEpochStrikeTokens(uint256 epoch) external view returns (address[] memory);

    function getEpochStrikeData(uint256 epoch, uint256 strike) external view returns (EpochStrikeData memory);

    function getLastVaultCheckpoint(uint256 epoch, uint256 strike) external view returns (VaultCheckpoint memory);

    function underlyingSymbol() external returns (string memory);

    function isPut() external view returns (bool);

    function addresses() external view returns (Addresses memory);

    function collateralToken() external view returns (IERC20);

    function currentEpoch() external view returns (uint256);

    function expireDelayTolerance() external returns (uint256);

    function collateralPrecision() external returns (uint256);

    function getEpochData(uint256 epoch) external view returns (EpochData memory);

    function epochStrikeData(uint256 epoch, uint256 strike) external view returns (EpochStrikeData memory);

    function balanceOf(address owner) external view returns (uint256);

    // Dopex management only
    function expire(uint256 _settlementPrice, uint256 _settlementCollateralExchangeRate) external;

    function bootstrap(uint256[] memory strikes, uint256 expiry, string memory expirySymbol) external;

    function addToContractWhitelist(address _contract) external;
}