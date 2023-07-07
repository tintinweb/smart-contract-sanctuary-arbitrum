// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

import {IRouter} from "src/interfaces/IRouter.sol";
import {ILPVault} from "src/interfaces/ILPVault.sol";
import {ICompoundStrategy} from "src/interfaces/ICompoundStrategy.sol";
import {IOptionStrategy} from "src/interfaces/IOptionStrategy.sol";

import {LibDiamond} from "src/libraries/diamond/LibDiamond.sol";
import {RouterLib} from "src/libraries/diamond/RouterLib.sol";
import {FlipLib} from "src/libraries/diamond/FlipLib.sol";
import {WithdrawLib} from "src/libraries/diamond/WithdrawLib.sol";
import {DepositLib} from "src/libraries/diamond/DepositLib.sol";

contract RouterFacet {
    /* -------------------------------------------------------------------------- */
    /*                                    INIT                                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Initialize the router.
     */
    function initializeRouter(
        address _compoundStrategy,
        address _optionStrategy,
        address[] calldata _strategyVaults,
        uint256 _premium
    ) external {
        LibDiamond.enforceIsContractOwner();
        RouterLib.RouterStorage storage rs = RouterLib.routerStorage();

        if (rs.initialized) {
            revert AlreadyInitialized();
        }

        rs.vaults[IRouter.OptionStrategy.BULL] = ILPVault(_strategyVaults[0]);
        rs.vaults[IRouter.OptionStrategy.BEAR] = ILPVault(_strategyVaults[1]);
        rs.vaults[IRouter.OptionStrategy.CRAB] = ILPVault(_strategyVaults[2]);

        rs.compoundStrategy = ICompoundStrategy(_compoundStrategy);
        rs.optionStrategy = IOptionStrategy(_optionStrategy);

        rs.lpToken = ICompoundStrategy(_compoundStrategy).lpToken();
        rs.premium = _premium;

        rs.basis = 1e12;
        rs.slippage = (999 * 1e12) / 1000;

        rs.initialized = true;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    VIEW                                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Get LP Token.
     */
    function lpToken() external view returns (IERC20) {
        return RouterLib.lpToken();
    }

    /**
     * @notice Get premium.
     */
    function premium() external view returns (uint256) {
        return RouterLib.premium();
    }

    /**
     * @notice Get slippage.
     */
    function slippage() external view returns (uint256) {
        return RouterLib.slippage();
    }

    /**
     * @notice Get strategy vault.
     */
    function vaults(IRouter.OptionStrategy _strategy) external view returns (ILPVault) {
        return RouterLib.vaults(_strategy);
    }

    /**
     * @notice Update Compound Strategy.
     */
    function updateCompoundStrategy(address _compoundStrategy) external {
        LibDiamond.enforceIsContractOwner();
        RouterLib.RouterStorage storage rs = RouterLib.routerStorage();
        rs.compoundStrategy = ICompoundStrategy(_compoundStrategy);
        rs.lpToken = ICompoundStrategy(_compoundStrategy).lpToken();
    }

    /**
     * @notice Update Option Strategy.
     */
    function updateOptionStrategy(address _optionStrategy) external {
        LibDiamond.enforceIsContractOwner();
        RouterLib.RouterStorage storage rs = RouterLib.routerStorage();
        rs.optionStrategy = IOptionStrategy(_optionStrategy);
    }

    /**
     * @notice Update Premium.
     */
    function updatePremium(uint256 _premium) external {
        LibDiamond.enforceIsContractOwner();
        RouterLib.RouterStorage storage rs = RouterLib.routerStorage();
        rs.premium = _premium;
    }

    /**
     * @notice Updates slippage.
     */
    function updateSlippage(uint256 _slippage) external {
        LibDiamond.enforceIsContractOwner();
        RouterLib.RouterStorage storage rs = RouterLib.routerStorage();
        rs.slippage = _slippage;
    }

    /**
     * @notice Moves assets from the strategy to `_to`
     * @param _assets An array of IERC20 compatible tokens to move out from the strategy
     * @param _withdrawNative `true` if we want to move the native asset from the strategy
     */
    function emergencyWithdraw(address _to, address[] memory _assets, bool _withdrawNative) external {
        LibDiamond.enforceIsContractOwner();
        uint256 assetsLength = _assets.length;
        for (uint256 i = 0; i < assetsLength; i++) {
            IERC20 asset = IERC20(_assets[i]);
            uint256 assetBalance = asset.balanceOf(address(this));

            if (assetBalance > 0) {
                // Transfer the ERC20 tokens
                asset.transfer(_to, assetBalance);
            }

            unchecked {
                ++i;
            }
        }

        uint256 nativeBalance = address(this).balance;

        // Nothing else to do
        if (_withdrawNative && nativeBalance > 0) {
            // Transfer the native currency
            (bool sent,) = payable(_to).call{value: nativeBalance}("");
            if (!sent) {
                revert FailSendETH();
            }
        }

        emit EmergencyWithdrawal(msg.sender, _to, _assets, _withdrawNative ? nativeBalance : 0);
    }

    /* -------------------------------------------------------------------------- */
    /*                                 ONLY STRATEGY                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Update accounting when epoch finish.
     */
    function executeFinishEpoch() external {
        if (msg.sender != address(RouterLib.compoundStrategy())) revert InvalidStrategy();

        IRouter.OptionStrategy bullStrategy = IRouter.OptionStrategy.BULL;
        IRouter.OptionStrategy bearStrategy = IRouter.OptionStrategy.BEAR;
        IRouter.OptionStrategy crabStrategy = IRouter.OptionStrategy.CRAB;

        FlipLib.FlipStorage storage fs = FlipLib.flipStorage();

        fs.flipSignals[bullStrategy][bearStrategy] = 0;
        fs.flipSignals[bullStrategy][crabStrategy] = 0;
        fs.flipSignals[bearStrategy][bullStrategy] = 0;
        fs.flipSignals[bearStrategy][crabStrategy] = 0;
        fs.flipSignals[crabStrategy][bullStrategy] = 0;
        fs.flipSignals[crabStrategy][bearStrategy] = 0;

        WithdrawLib.WithdrawStorage storage ws = WithdrawLib.withdrawStorage();

        ws.withdrawSignals[bullStrategy] = 0;
        ws.withdrawSignals[bearStrategy] = 0;
        ws.withdrawSignals[crabStrategy] = 0;

        DepositLib.DepositStorage storage ds = DepositLib.depositStorage();

        ds.nextEpochDeposits[bullStrategy] = 0;
        ds.nextEpochDeposits[bearStrategy] = 0;
        ds.nextEpochDeposits[crabStrategy] = 0;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event EmergencyWithdrawal(address indexed caller, address indexed receiver, address[] tokens, uint256 nativeBalanc);

    /* -------------------------------------------------------------------------- */
    /*                                    ERRORS                                  */
    /* -------------------------------------------------------------------------- */

    error AlreadyInitialized();
    error FailSendETH();
    error InvalidStrategy();
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
    function borrowedLP(IRouter.OptionStrategy _type) external view returns (uint256);
    function executedStrategy(uint256 _epoch, IRouter.OptionStrategy _type) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IDiamond} from "src/interfaces/diamond/IDiamond.sol";
import {IBeacon} from "openzeppelin-contracts/proxy/beacon/IBeacon.sol";
import {IDiamondCut} from "src/interfaces/diamond/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeBeacon to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error NoSelectorsGivenToAdd();
error NotContractOwner(address _user, address _contractOwner);
error NoSelectorsProvidedForBeaconForCut(address _beaconAddress);
error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
error NoBytecodeAtAddress(address _contractAddress, string _message);
error IncorrectBeaconCutAction(uint8 _action);
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
error CannotReplaceFunctionsFromBeaconWithZeroAddress(bytes4[] _selectors);
error CannotReplaceImmutableFunction(bytes4 _selector);
error CannotReplaceFunctionWithTheSameFunctionFromTheSameBeacon(bytes4 _selector);
error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
error RemoveBeaconAddressMustBeZeroAddress(address _beaconAddress);
error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
error CannotRemoveImmutableFunction(bytes4 _selector);
error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    /**
     * @notice Diamond storage position.
     */
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    /**
     * @notice Beacon and Selector position struct.
     */
    struct BeaconAddressAndSelectorPosition {
        address beaconAddress;
        uint16 selectorPosition;
    }

    /**
     * @notice Diamond storage.
     */
    struct DiamondStorage {
        // function selector => beacon address and selector position in selectors array
        mapping(bytes4 => BeaconAddressAndSelectorPosition) beaconAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    /**
     * @notice Get diamond storage.
     */
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event SetBeacon(address indexed oldBeacon, address indexed newBeacon);

    /**
     * @notice Set owner.
     */
    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    /**
     * @notice Get owner.
     */
    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    /**
     * @notice If msg.sender not owner revert.
     */
    function enforceIsContractOwner() internal view {
        if (msg.sender != diamondStorage().contractOwner) {
            revert NotContractOwner(msg.sender, diamondStorage().contractOwner);
        }
    }

    event DiamondCut(IDiamondCut.BeaconCut[] _diamondCut, address _init, bytes _calldata);

    /**
     * @notice Procces to Add, replace or Remove Facets.
     */
    function diamondCut(IDiamondCut.BeaconCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        uint256 length = _diamondCut.length;
        for (uint256 beaconIndex; beaconIndex < length;) {
            bytes4[] memory functionSelectors = _diamondCut[beaconIndex].functionSelectors;
            address beaconAddress = _diamondCut[beaconIndex].beaconAddress;
            if (functionSelectors.length == 0) {
                revert NoSelectorsProvidedForBeaconForCut(beaconAddress);
            }
            IDiamondCut.BeaconCutAction action = _diamondCut[beaconIndex].action;
            if (action == IDiamond.BeaconCutAction.Add) {
                addFunctions(beaconAddress, functionSelectors);
            } else if (action == IDiamond.BeaconCutAction.Replace) {
                replaceFunctions(beaconAddress, functionSelectors);
            } else if (action == IDiamond.BeaconCutAction.Remove) {
                removeFunctions(beaconAddress, functionSelectors);
            } else {
                revert IncorrectBeaconCutAction(uint8(action));
            }
            unchecked {
                ++beaconIndex;
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    /**
     * @notice Procces to Add Facets.
     */
    function addFunctions(address _beaconAddress, bytes4[] memory _functionSelectors) internal {
        if (_beaconAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        enforceHasContractCode(_beaconAddress, "LibDiamondCut: Add beacon has no code");
        uint256 length = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < length;) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldBeaconAddress = ds.beaconAddressAndSelectorPosition[selector].beaconAddress;
            if (oldBeaconAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }
            ds.beaconAddressAndSelectorPosition[selector] =
                BeaconAddressAndSelectorPosition(_beaconAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
            unchecked {
                ++selectorIndex;
            }
        }
    }

    /**
     * @notice Procces to Replace Facets.
     */
    function replaceFunctions(address _beaconAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        if (_beaconAddress == address(0)) {
            revert CannotReplaceFunctionsFromBeaconWithZeroAddress(_functionSelectors);
        }
        enforceHasContractCode(_beaconAddress, "LibDiamondCut: Replace beacont has no code");
        uint256 length = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < length;) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldBeaconAddress = ds.beaconAddressAndSelectorPosition[selector].beaconAddress;
            // can't replace immutable functions -- functions defined directly in the diamond in this case
            if (oldBeaconAddress == address(this)) {
                revert CannotReplaceImmutableFunction(selector);
            }
            if (oldBeaconAddress == _beaconAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameBeacon(selector);
            }
            if (oldBeaconAddress == address(0)) {
                revert CannotReplaceFunctionThatDoesNotExists(selector);
            }
            // replace old beacon address
            ds.beaconAddressAndSelectorPosition[selector].beaconAddress = _beaconAddress;
            unchecked {
                ++selectorIndex;
            }
        }
    }

    /**
     * @notice Procces to Remove Facets.
     */
    function removeFunctions(address _beaconAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if (_beaconAddress != address(0)) {
            revert RemoveBeaconAddressMustBeZeroAddress(_beaconAddress);
        }
        uint256 length = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < length;) {
            bytes4 selector = _functionSelectors[selectorIndex];
            BeaconAddressAndSelectorPosition memory oldBeaconAddressAndSelectorPosition =
                ds.beaconAddressAndSelectorPosition[selector];
            if (oldBeaconAddressAndSelectorPosition.beaconAddress == address(0)) {
                revert CannotRemoveFunctionThatDoesNotExist(selector);
            }

            // can't remove immutable functions -- functions defined directly in the diamond
            if (oldBeaconAddressAndSelectorPosition.beaconAddress == address(this)) {
                revert CannotRemoveImmutableFunction(selector);
            }
            // replace selector with last selector
            selectorCount--;
            if (oldBeaconAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldBeaconAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.beaconAddressAndSelectorPosition[lastSelector].selectorPosition =
                    oldBeaconAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.beaconAddressAndSelectorPosition[selector];

            unchecked {
                ++selectorIndex;
            }
        }
    }

    /**
     * @notice Procces to initialize Diamond contract.
     */
    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    /**
     * @notice Enforce contract.
     */
    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert NoBytecodeAtAddress(_contract, _errorMessage);
        }
    }

    /**
     * @notice get beacon implementation.
     */
    function _implementation() internal view returns (address) {
        return IBeacon(diamondStorage().beaconAddressAndSelectorPosition[msg.sig].beaconAddress).implementation();
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {IRouter} from "src/interfaces/IRouter.sol";
import {ILPVault} from "src/interfaces/ILPVault.sol";
import {ICompoundStrategy} from "src/interfaces/ICompoundStrategy.sol";
import {IOptionStrategy} from "src/interfaces/IOptionStrategy.sol";
import {LibDiamond} from "src/libraries/diamond/LibDiamond.sol";

error ReentrantCall();
error PauseError();

library RouterLib {
    /**
     * @notice Router storage position.
     */
    bytes32 constant ROUTER_STORAGE_POSITION = keccak256("diamond.standard.router.storage");

    /**
     * @notice Reentrancy constant.
     */
    uint256 constant _NOT_ENTERED = 1;
    /**
     * @notice Reentrancy constant.
     */
    uint256 constant _ENTERED = 2;

    /**
     * @notice Router storage.
     */
    struct RouterStorage {
        IERC20 lpToken;
        uint256 basis;
        uint256 premium;
        uint256 slippage;
        bool initialized;
        uint256 status;
        bool paused;
        mapping(IRouter.OptionStrategy => ILPVault) vaults;
        ICompoundStrategy compoundStrategy;
        IOptionStrategy optionStrategy;
    }

    /**
     * @notice Get router storage.
     */
    function routerStorage() internal pure returns (RouterStorage storage rs) {
        bytes32 position = ROUTER_STORAGE_POSITION;
        assembly {
            rs.slot := position
        }
    }

    /**
     * @notice To avoid reentrancy.
     */
    function nonReentrantBefore() internal {
        RouterStorage storage rs = routerStorage();
        // On the first call to nonReentrant, _status will be 1 _NOT_ENTERED
        if (rs.status == _ENTERED) {
            revert ReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        rs.status = _ENTERED;
    }

    /**
     * @notice To avoid reentrancy.
     */
    function nonReentrantAfter() internal {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        RouterStorage storage rs = routerStorage();
        rs.status = _NOT_ENTERED;
    }

    event PauseChanged(address _caller, bool _paused);

    /**
     * @notice Switch between paused and unpaused.
     */
    function togglePause() internal {
        LibDiamond.enforceIsContractOwner();
        RouterStorage storage rs = routerStorage();
        rs.paused = !rs.paused;
        emit PauseChanged(msg.sender, rs.paused);
    }

    /**
     * @notice If it is paused revert.
     */
    function requireNotPaused() internal view {
        if (routerStorage().paused) {
            revert PauseError();
        }
    }

    /**
     * @notice Get LP Token.
     */
    function lpToken() internal view returns (IERC20) {
        return routerStorage().lpToken;
    }

    /**
     * @notice Get basis point.
     */
    function basis() internal view returns (uint256) {
        return routerStorage().basis;
    }

    /**
     * @notice Get premium.
     */
    function premium() internal view returns (uint256) {
        return routerStorage().premium;
    }

    /**
     * @notice Get slippage.
     */
    function slippage() internal view returns (uint256) {
        return routerStorage().slippage;
    }

    /**
     * @notice Get initialized.
     */
    function initialized() internal view returns (bool) {
        return routerStorage().initialized;
    }

    /**
     * @notice Get strategy vault.
     */
    function vaults(IRouter.OptionStrategy _strategy) internal view returns (ILPVault) {
        return routerStorage().vaults[_strategy];
    }

    /**
     * @notice Get compound strategy.
     */
    function compoundStrategy() internal view returns (ICompoundStrategy) {
        return routerStorage().compoundStrategy;
    }

    /**
     * @notice Get option strategy.
     */
    function optionStrategy() internal view returns (IOptionStrategy) {
        return routerStorage().optionStrategy;
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {IRouter} from "src/interfaces/IRouter.sol";

library FlipLib {
    /**
     * @notice Flip storage position.
     */
    bytes32 constant FLIP_STORAGE_POSITION = keccak256("diamond.standard.flip.storage");

    /**
     * @notice Flip storage.
     */
    struct FlipStorage {
        mapping(
            address
                => mapping(
                    uint256 => mapping(IRouter.OptionStrategy => mapping(IRouter.OptionStrategy => IRouter.FlipSignal))
                )
            ) userFlip;
        mapping(IRouter.OptionStrategy => mapping(IRouter.OptionStrategy => uint256)) flipSignals;
    }

    /**
     * @notice Flip deposit storage.
     */
    function flipStorage() internal pure returns (FlipStorage storage fs) {
        bytes32 position = FLIP_STORAGE_POSITION;
        assembly {
            fs.slot := position
        }
    }

    /**
     * @notice Total Flip Signals.
     */
    function flipSignals(IRouter.OptionStrategy _oldStrategy, IRouter.OptionStrategy _newStrategy)
        internal
        view
        returns (uint256)
    {
        return flipStorage().flipSignals[_oldStrategy][_newStrategy];
    }

    /**
     * @notice User flip signals.
     */
    function userFlip(
        address _user,
        uint256 _epoch,
        IRouter.OptionStrategy _oldStrategy,
        IRouter.OptionStrategy _newStrategy
    ) internal view returns (IRouter.FlipSignal memory) {
        return flipStorage().userFlip[_user][_epoch][_oldStrategy][_newStrategy];
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {IRouter} from "src/interfaces/IRouter.sol";

library WithdrawLib {
    /**
     * @notice Withdraw storage position.
     */
    bytes32 constant WITHDRAW_STORAGE_POSITION = keccak256("diamond.standard.withdraw.storage");

    /**
     * @notice Withdraw storage.
     */
    struct WithdrawStorage {
        mapping(IRouter.OptionStrategy => uint256) withdrawSignals;
        mapping(address => mapping(uint256 => mapping(IRouter.OptionStrategy => IRouter.WithdrawalSignal))) userSignal;
    }

    /**
     * @notice Get withdraw storage.
     */
    function withdrawStorage() internal pure returns (WithdrawStorage storage ws) {
        bytes32 position = WITHDRAW_STORAGE_POSITION;
        assembly {
            ws.slot := position
        }
    }

    /**
     * @notice Get total withdraw signals.
     */
    function withdrawSignals(IRouter.OptionStrategy _strategy) internal view returns (uint256) {
        return withdrawStorage().withdrawSignals[_strategy];
    }

    /**
     * @notice Get user withdraw signals per epoch per strategy.
     */
    function userSignal(address _user, uint256 _epoch, IRouter.OptionStrategy _strategy)
        internal
        view
        returns (IRouter.WithdrawalSignal memory)
    {
        return withdrawStorage().userSignal[_user][_epoch][_strategy];
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2023 JonesDAO - All rights reserved
// Jones DAO: https://www.jonesdao.io/

// Check https://docs.jonesdao.io/jones-dao/other/bounty for details on our bounty program.

pragma solidity ^0.8.10;

import {IRouter} from "src/interfaces/IRouter.sol";

library DepositLib {
    /**
     * @notice Deposit storage position.
     */
    bytes32 constant DEPOSIT_STORAGE_POSITION = keccak256("diamond.standard.deposit.storage");

    /**
     * @notice Deposit storage.
     */
    struct DepositStorage {
        mapping(IRouter.OptionStrategy => uint256) nextEpochDeposits;
        mapping(address => mapping(uint256 => mapping(IRouter.OptionStrategy => uint256))) userNextEpochDeposits;
    }

    /**
     * @notice Get deposit storage.
     */
    function depositStorage() internal pure returns (DepositStorage storage ds) {
        bytes32 position = DEPOSIT_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /**
     * @notice Total strategy next epoch deposit.
     */
    function nextEpochDeposits(IRouter.OptionStrategy _strategy) internal view returns (uint256) {
        return depositStorage().nextEpochDeposits[_strategy];
    }

    /**
     * @notice User next epoch deposit for a strategy.
     */
    function userNextEpochDeposits(address _user, uint256 _epoch, IRouter.OptionStrategy _strategy)
        internal
        view
        returns (uint256)
    {
        return depositStorage().userNextEpochDeposits[_user][_epoch][_strategy];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {IRouter} from "src/interfaces/IRouter.sol";

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

    // Buys options.
    // Return avg option price in WETH
    function purchase(ExecuteParams calldata params) external;

    function executeSingleOptionPurchase(uint256 _strike, uint256 _collateral) external returns (uint256);

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
    function position() external view returns (uint256);

    function lpToCollateral(address _lp, uint256 _amount) external view returns (uint256);
    function getExpiry() external view returns (uint256);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
// EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535

interface IDiamond {
    enum BeaconCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct BeaconCut {
        address beaconAddress;
        BeaconCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(BeaconCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
// EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535

import {IDiamond} from "src/interfaces/diamond/IDiamond.sol";

interface IDiamondCut is IDiamond {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(IDiamond.BeaconCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}