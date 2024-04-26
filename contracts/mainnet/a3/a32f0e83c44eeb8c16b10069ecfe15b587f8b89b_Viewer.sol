// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IPool} from "./IPool.sol";
import {IOracle} from "./IOracle.sol";
import {IDataProvider} from "./IDataProvider.sol";
import {IERC20} from "./IERC20.sol";

contract Viewer {
    
    IPool public pool;
    IOracle public oracle;
    IDataProvider public dataProvider;

    constructor(
        address _pool,
        address _oracle,
        address _dataProvider
    ) {
        pool = IPool(_pool);
        oracle = IOracle(_oracle);
        dataProvider = IDataProvider(_dataProvider);
    }

    function getAvailableLiquidityAndDebt() external view returns (uint256 liquidity, uint256 debt) {
        return _getCombinedValue(address(0));
    }

    function getUserDepositsAndBorrows(address user) external view returns (uint256 liquidity, uint256 debt) {
        return _getCombinedValue(user);
    }

    // passing address(0) as user will fetch total values.
    function _getCombinedValue(address user) internal view returns (uint256 liquidity, uint256 debt) {
        (address[] memory reserves) = _getActiveReserves();
        uint256[] memory prices = oracle.getAssetsPrices(reserves);
        uint256[] memory decimals = _getDecimals(reserves);
        uint256 ethUsdPrice = oracle.getAssetPrice(0x10F7Fc1F91Ba351f9C629c5947AD69bD03C05b96);
        for (uint256 i = 0; i < reserves.length; i++) {
            (uint256 _liquidity, uint256 _debt) = user == address(0) ? _getTotalAmounts(reserves[i]) : _getUserAmounts(reserves[i], user);
            liquidity += _liquidity * prices[i] / (10 ** decimals[i]);
            debt += _debt * prices[i] / (10 ** decimals[i]);
        }
        // Leave two units of percision (for $ decimals).
        liquidity = liquidity * ethUsdPrice / (1e18 * 1e6);
        debt = debt * ethUsdPrice / (1e18 * 1e6);
    }

    function _getActiveReserves() internal view returns (address[] memory activeReserves) {
        address[] memory allReserves = pool.getReservesList();
        address[] memory _activeReserves = new address[](allReserves.length);
        uint256 n;
        for (uint256 i = 0; i < allReserves.length; i++) {
            (,,,,,,,,bool isActive, bool isFrozen) = dataProvider.getReserveConfigurationData(allReserves[i]);
            if (isActive && !isFrozen) {
                _activeReserves[n] = allReserves[i];
                n++;
            }
        }
        activeReserves = new address[](n);
        for (uint256 j = 0; j < n; j++) {
            activeReserves[j] = _activeReserves[j];
        }
    }

    function _getTotalAmounts(address reserve) internal view returns (uint256 liquidity, uint256 debt) {
        (liquidity,,debt,,,,,,,) = dataProvider.getReserveData(reserve);
    }

    function _getUserAmounts(address reserve, address user) internal view returns (uint256 liquidity, uint256 debt) {
        (liquidity,,debt,,,,,,) = dataProvider.getUserReserveData(reserve, user);
    }

    function _getDecimals(address[] memory tokens) internal view returns (uint256[] memory decimals) {
        decimals = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            decimals[i] = IERC20(tokens[i]).decimals();
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8;

interface IPool {
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint16 indexed referral
    );
    event Deposit(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referral
    );
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium,
        uint16 referralCode
    );
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );
    event Paused();
    event RebalanceStableBorrowRate(
        address indexed reserve,
        address indexed user
    );
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount
    );
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );
    event ReserveUsedAsCollateralDisabled(
        address indexed reserve,
        address indexed user
    );
    event ReserveUsedAsCollateralEnabled(
        address indexed reserve,
        address indexed user
    );
    event Swap(address indexed reserve, address indexed user, uint256 rateMode);
    event Unpaused();
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    function FLASHLOAN_PREMIUM_TOTAL() external view returns (uint256);

    function LENDINGPOOL_REVISION() external view returns (uint256);

    function MAX_NUMBER_RESERVES() external view returns (uint256);

    function MAX_STABLE_RATE_BORROW_SIZE_PERCENT()
        external
        view
        returns (uint256);

    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromBefore,
        uint256 balanceToBefore
    ) external;

    function flashLoan(
        address receiverAddress,
        address[] memory assets,
        uint256[] memory amounts,
        uint256[] memory modes,
        address onBehalfOf,
        bytes memory params,
        uint16 referralCode
    ) external;

    function getAddressesProvider() external view returns (address);

    function getConfiguration(address asset)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory);

    function getReserveNormalizedIncome(address asset)
        external
        view
        returns (uint256);

    function getReserveNormalizedVariableDebt(address asset)
        external
        view
        returns (uint256);

    function getReservesList() external view returns (address[] memory);

    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function getUserConfiguration(address user)
        external
        view
        returns (DataTypes.UserConfigurationMap memory);

    function initReserve(
        address asset,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function initialize(address provider) external;

    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    function paused() external view returns (bool);

    function rebalanceStableBorrowRate(address asset, address user) external;

    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    function setConfiguration(address asset, uint256 configuration) external;

    function setPause(bool val) external;

    function setReserveInterestRateStrategyAddress(
        address asset,
        address rateStrategyAddress
    ) external;

    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral)
        external;

    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

interface DataTypes {
    struct ReserveConfigurationMap {
        uint256 data;
    }

    struct ReserveData {
        ReserveConfigurationMap configuration;
        uint128 liquidityIndex;
        uint128 variableBorrowIndex;
        uint128 currentLiquidityRate;
        uint128 currentVariableBorrowRate;
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        address interestRateStrategyAddress;
        uint8 id;
    }

    struct UserConfigurationMap {
        uint256 data;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8;

interface IOracle {
    event AssetSourceUpdated(address indexed asset, address indexed source);
    event BaseCurrencySet(
        address indexed baseCurrency,
        uint256 baseCurrencyUnit
    );
    event FallbackOracleUpdated(address indexed fallbackOracle);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function BASE_CURRENCY() external view returns (address);

    function BASE_CURRENCY_UNIT() external view returns (uint256);

    function getAssetPrice(address asset) external view returns (uint256);

    function getAssetsPrices(address[] memory assets)
        external
        view
        returns (uint256[] memory);

    function getFallbackOracle() external view returns (address);

    function getSourceOfAsset(address asset) external view returns (address);

    function owner() external view returns (address);

    function renounceOwnership() external;

    function setAssetSources(address[] memory assets, address[] memory sources)
        external;

    function setFallbackOracle(address fallbackOracle) external;

    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8;

interface IDataProvider {
    function ADDRESSES_PROVIDER() external view returns (address);

    function getAllATokens()
        external
        view
        returns (AaveProtocolDataProvider.TokenData[] memory);

    function getAllReservesTokens()
        external
        view
        returns (AaveProtocolDataProvider.TokenData[] memory);

    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        );

    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );

    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );

    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        );
}

interface AaveProtocolDataProvider {
    struct TokenData {
        string symbol;
        address tokenAddress;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8;

interface IERC20 {
    function decimals() external view returns (uint8);
}