//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

enum OptionsState {
    Settled,
    Active,
    Unlocked
}

enum EpochState {
    InActive,
    BootStrapped,
    Expired,
    Paused
}

enum Contracts {
    QuoteToken,
    BaseToken,
    FeeDistributor,
    FeeStrategy,
    OptionPricing,
    PriceOracle,
    VolatilityOracle,
    Gov
}

enum VaultConfig {
    IvBoost,
    BlackoutWindow,
    FundingInterval,
    BaseFundingRate,
    UseDiscount
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {OptionsState, EpochState} from "./AtlanticPutsPoolEnums.sol";

struct EpochData {
    uint256 startTime;
    uint256 expiryTime;
    uint256 totalLiquidity;
    uint256 totalActiveCollateral;
    uint256 fundingRate;
    uint256 tickSize;
    MaxStrikesRange maxStrikesRange;
    EpochState state;
}

struct MaxStrikesRange {
    uint256 highest;
    uint256 lowest;
}

struct Checkpoint {
    uint256 startTime;
    uint256 unlockedCollateral;
    uint256 premiumAccrued;
    uint256 borrowFeesAccrued;
    uint256 underlyingAccrued;
    uint256 totalLiquidity;
    uint256 liquidityBalance;
    uint256 activeCollateral;
}

struct EpochRewards {
    address[] rewardTokens;
    uint256[] amounts;
}

struct OptionsPurchase {
    uint256 epoch;
    uint256 optionStrike;
    uint256 optionsAmount;
    uint256 unlockEntryTimestamp;
    uint256[] strikes;
    uint256[] checkpoints;
    uint256[] weights;
    OptionsState state;
    address user;
    address delegate;
}

struct DepositPosition {
    uint256 epoch;
    uint256 strike;
    uint256 liquidity;
    uint256 checkpoint;
    address depositor;
}

struct MaxStrike {
    uint256 maxStrike;
    uint256 activeCollateral;
    uint256[] rewardRates;
    mapping(uint256 => Checkpoint) checkpoints;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

// Structs
import {OptionsPurchase, DepositPosition, Checkpoint} from "./AtlanticPutsPoolStructs.sol";

// Interfaces
import {IAtlanticPutsPool} from "./interfaces/IAtlanticPutsPool.sol";

contract AtlanticsViewer {
    /**
     * @notice Get user options purchase positions
     * @param  _epoch             Epoch of the pool
     * @param  _pool              Address of the pool
     * @param  _user              Address of the user
     * @return _purchasePositions Options purchase positions of the user
     */
    function getUserOptionsPurchases(
        IAtlanticPutsPool _pool,
        uint256 _epoch,
        address _user
    ) external view returns (OptionsPurchase[] memory _purchasePositions) {
        _purchasePositions = new OptionsPurchase[](
            _pool.purchasePositionsCounter()
        );

        for (uint256 i; i < _purchasePositions.length; ) {
            OptionsPurchase memory purchasePosition = _pool
                .getOptionsPurchase(i);
            if (
                purchasePosition.user == _user &&
                purchasePosition.epoch == _epoch
            ) {
                _purchasePositions[i] = purchasePosition;
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Get user deposit positions
     * @param  _epoch            Epoch of the pool
     * @param  _pool             Address of the pool
     * @param  _user             Address of the user
     * @return _depositPositions Deposit positions of the user
     */
    function getUserDeposits(
        IAtlanticPutsPool _pool,
        uint256 _epoch,
        address _user
    ) external view returns (DepositPosition[] memory _depositPositions) {
        _depositPositions = new DepositPosition[](
            _pool.depositPositionsCounter()
        );

        for (uint256 i; i < _depositPositions.length; ) {
            DepositPosition memory depositPosition = _pool
                .getDepositPosition(i);
            if (
                depositPosition.depositor == _user &&
                depositPosition.epoch == _epoch
            ) {
                _depositPositions[i] = depositPosition;
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
   * @notice Fetch Checkpoint data(type) for a given strike in a pool
   * @param  _pool         Address of the pool
   * @param  _epoch        Epoch of the pool
   * @param  _strike       Strike to query for (max-strikes pool accepts strikes)
   * @return _checkpoints  Array of checkpoints

   */
    function getEpochCheckpoints(
        IAtlanticPutsPool _pool,
        uint256 _epoch,
        uint256 _strike
    ) external view returns (Checkpoint[] memory _checkpoints) {
        return _pool.getEpochCheckpoints(_epoch, _strike);
    }

    /**
     * @notice Fetch strikes of a atlantic pool
     * @param _pool     Address of the pool
     * @param _epoch    Epoch of the pool
     * @return _strikes Array of strikes
     */
    function getEpochStrikes(
        IAtlanticPutsPool _pool,
        uint256 _epoch
    ) external view returns (uint256[] memory) {
        return _pool.getEpochStrikes(_epoch);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Contracts, VaultConfig, OptionsState} from "../AtlanticPutsPoolEnums.sol";

import {DepositPosition, OptionsPurchase, Checkpoint} from "../AtlanticPutsPoolStructs.sol";

interface IAtlanticPutsPool {
    function purchasePositionsCounter() external view returns (uint256);

    function currentEpoch() external view returns (uint256);

    function getOptionsPurchase(
        uint256 positionId
    ) external view returns (OptionsPurchase memory);

    function getEpochTickSize(uint256 _epoch) external view returns (uint256);

    function addresses(Contracts _contractType) external view returns (address);

    function getOptionsState(
        uint256 _purchaseId
    ) external view returns (OptionsState);

    function purchase(
        uint256 _strike,
        uint256 _amount,
        address _delegate,
        address _account
    ) external returns (uint256 purchaseId);

    function calculateFundingFees(
        uint256 _collateralAccess,
        uint256 _entryTimestamp
    ) external view returns (uint256 fees);

    function relockCollateral(
        uint256 purchaseId,
        uint256 relockAmount
    ) external;

    function unwind(uint256 purchaseId, uint256 unwindAmount) external;

    function calculatePurchaseFees(
        address account,
        uint256 strike,
        uint256 amount
    ) external view returns (uint256 finalFee);

    function calculatePremium(
        uint256 _strike,
        uint256 _amount
    ) external view returns (uint256 premium);

    function unlockCollateral(
        uint256 purchaseId,
        address to
    ) external returns (uint256 unlockedCollateral);

    function getDepositPosition(
        uint256 positionId
    ) external view returns (DepositPosition memory);

    function strikeMulAmount(
        uint256 _strike,
        uint256 _amount
    ) external view returns (uint256 result);

    function getEpochStrikes(
        uint256 epoch
    ) external view returns (uint256[] memory maxStrikes);

    function getEpochCheckpoints(
        uint256 _epoch,
        uint256 _maxStrike
    ) external view returns (Checkpoint[] memory _checkpoints);

    function depositPositionsCounter() external view returns (uint256);

    function isWithinBlackoutWindow() external view returns (bool);
}