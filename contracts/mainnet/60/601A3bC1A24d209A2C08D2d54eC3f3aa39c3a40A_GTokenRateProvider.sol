// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/**
 * @dev Interface for GToken contract
 */
interface IGToken {
    struct GnsPriceProvider {
        address addr;
        bytes signature;
    }

    struct LockedDeposit {
        address owner;
        uint256 shares; // collateralConfig.precision
        uint256 assetsDeposited; // collateralConfig.precision
        uint256 assetsDiscount; // collateralConfig.precision
        uint256 atTimestamp; // timestamp
        uint256 lockDuration; // timestamp
    }

    struct ContractAddresses {
        address asset;
        address owner; // 2-week timelock contract
        address manager; // 3-day timelock contract
        address admin; // bypasses timelock, access to emergency functions
        address gnsToken;
        address lockedDepositNft;
        address pnlHandler;
        address openTradesPnlFeed;
        GnsPriceProvider gnsPriceProvider;
    }

    struct Meta {
        string name;
        string symbol;
    }

    function manager() external view returns (address);

    function admin() external view returns (address);

    function currentEpoch() external view returns (uint256);

    function currentEpochStart() external view returns (uint256);

    function currentEpochPositiveOpenPnl() external view returns (uint256);

    function updateAccPnlPerTokenUsed(
        uint256 prevPositiveOpenPnl,
        uint256 newPositiveOpenPnl
    ) external returns (uint256);

    function getLockedDeposit(uint256 depositId) external view returns (LockedDeposit memory);

    function sendAssets(uint256 assets, address receiver) external;

    function receiveAssets(uint256 assets, address user) external;

    function distributeReward(uint256 assets) external;

    function tvl() external view returns (uint256);

    function marketCap() external view returns (uint256);

    function shareToAssetsPrice() external view returns (uint256);

    function collateralConfig() external view returns (uint128, uint128);

    event ManagerUpdated(address newValue);
    event AdminUpdated(address newValue);
    event PnlHandlerUpdated(address newValue);
    event OpenTradesPnlFeedUpdated(address newValue);
    event GnsPriceProviderUpdated(GnsPriceProvider newValue);
    event WithdrawLockThresholdsPUpdated(uint256[2] newValue);
    event MaxAccOpenPnlDeltaUpdated(uint256 newValue);
    event MaxDailyAccPnlDeltaUpdated(uint256 newValue);
    event MaxSupplyIncreaseDailyPUpdated(uint256 newValue);
    event LossesBurnPUpdated(uint256 newValue);
    event MaxGnsSupplyMintDailyPUpdated(uint256 newValue);
    event MaxDiscountPUpdated(uint256 newValue);
    event MaxDiscountThresholdPUpdated(uint256 newValue);

    event CurrentMaxSupplyUpdated(uint256 newValue);
    event DailyAccPnlDeltaReset();
    event ShareToAssetsPriceUpdated(uint256 newValue);
    event OpenTradesPnlFeedCallFailed();

    event WithdrawRequested(
        address indexed sender,
        address indexed owner,
        uint256 shares,
        uint256 currEpoch,
        uint256 indexed unlockEpoch
    );
    event WithdrawCanceled(
        address indexed sender,
        address indexed owner,
        uint256 shares,
        uint256 currEpoch,
        uint256 indexed unlockEpoch
    );

    event DepositLocked(address indexed sender, address indexed owner, uint256 depositId, LockedDeposit d);
    event DepositUnlocked(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 depositId,
        LockedDeposit d
    );

    event RewardDistributed(address indexed sender, uint256 assets);

    event AssetsSent(address indexed sender, address indexed receiver, uint256 assets);
    event AssetsReceived(address indexed sender, address indexed user, uint256 assets, uint256 assetsLessDeplete);

    event Depleted(address indexed sender, uint256 assets, uint256 amountGns);
    event Refilled(address indexed sender, uint256 assets, uint256 amountGns);

    event AccPnlPerTokenUsedUpdated(
        address indexed sender,
        uint256 indexed newEpoch,
        uint256 prevPositiveOpenPnl,
        uint256 newPositiveOpenPnl,
        uint256 newEpochPositiveOpenPnl,
        int256 newAccPnlPerTokenUsed
    );

    error OnlyManager();
    error OnlyTradingPnlHandler();
    error OnlyPnlFeed();
    error AddressZero();
    error PriceZero();
    error ValueZero();
    error BytesZero();
    error NoActiveDiscount();
    error BelowMin();
    error AboveMax();
    error WrongValue();
    error WrongValues();
    error GnsPriceCallFailed();
    error GnsTokenPriceZero();
    error PendingWithdrawal();
    error EndOfEpoch();
    error NotAllowed();
    error NoDiscount();
    error NotUnlocked();
    error NotEnoughAssets();
    error MaxDailyPnl();
    error NotUnderCollateralized();
    error AboveInflationLimit();

    // Ownable
    error OwnableInvalidOwner(address owner);

    // ERC4626
    error ERC4626ExceededMaxDeposit();
    error ERC4626ExceededMaxMint();
    error ERC4626ExceededMaxWithdraw();
    error ERC4626ExceededMaxRedeem();
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

interface IRateProvider {
    function getRate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import "../interfaces/IRateProvider.sol";
import "../interfaces/IGToken.sol";

/**
 * @title GToken Rate Provider
 * @dev Balancer rate provider to return the value of a gToken in terms of its collaterals token
 */
contract GTokenRateProvider is IRateProvider {
    IGToken public immutable gToken;

    constructor(IGToken _gToken) {
        gToken = _gToken;
    }

    /**
     * @dev Fetches the price rate of a gToken
     * @return the value of gToken in collateral token, in 1e18 precision
     */
    function getRate() external view override returns (uint256) {
        return gToken.shareToAssetsPrice();
    }
}