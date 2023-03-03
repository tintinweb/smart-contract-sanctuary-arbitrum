// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/NameVersion.sol';
import '../library/SafeMath.sol';
import './LensStorage.sol';
import './SymbolsLens.sol';

contract LensImplementationAave is LensStorage, NameVersion {

    using SafeMath for uint256;
    using SafeMath for int256;

    int256 constant ONE = 1e18;
    uint256 constant UONE = 1e18;

    ISymbolsLens immutable symbolsLens;

    constructor (address symbolsLens_) NameVersion('Lens', '3.1.Aave') {
        symbolsLens = ISymbolsLens(symbolsLens_);
    }

    struct PoolInfo {
        address pool;
        address implementation;
        address protocolFeeCollector;

        address tokenB0;
        address tokenWETH;
        address marketB0;
        address marketWETH;
        address lToken;
        address pToken;
        address oracleManager;
        address swapper;
        address symbolManager;
        uint256 reserveRatioB0;
        int256 minRatioB0;
        int256 poolInitialMarginMultiplier;
        int256 protocolFeeCollectRatio;
        int256 minLiquidationReward;
        int256 maxLiquidationReward;
        int256 liquidationRewardCutRatio;

        int256 liquidity;
        int256 lpsPnl;
        int256 cumulativePnlPerLiquidity;
        int256 protocolFeeAccrued;

        address symbolManagerImplementation;
        int256 initialMarginRequired;
    }

    struct MarketInfo {
        address asset;
        address market;
        string assetSymbol;
        string marketSymbol;
        uint256 assetPrice;
        uint256 collateralFactor;
        uint256 assetBalance;
    }

    struct LpInfo {
        address account;
        uint256 lTokenId;
        address vault;
        int256 amountB0;
        int256 liquidity;
        int256 cumulativePnlPerLiquidity;
        uint256 vaultLiquidity;
        MarketInfo[] markets;
    }

    struct PositionInfo {
        address symbolAddress;
        string symbol;
        int256 volume;
        int256 cost;
        int256 cumulativeFundingPerVolume;
        // Gamma
        int256 powerVolume;
        int256 realFuturesVolume;
        int256 cumulaitveFundingPerPowerVolume;
        int256 cumulativeFundingPerRealFuturesVolume;
    }

    struct TdInfo {
        address account;
        uint256 pTokenId;
        address vault;
        int256 amountB0;
        uint256 vaultLiquidity;
        MarketInfo[] markets;
        PositionInfo[] positions;
    }

    function getInfo(address pool_, address account_, ISymbolsLens.PriceAndVolatility[] memory pvs) external view returns (
        PoolInfo memory poolInfo,
        MarketInfo[] memory marketsInfo,
        ISymbolsLens.SymbolInfo[] memory symbolsInfo,
        LpInfo memory lpInfo,
        TdInfo memory tdInfo
    ) {
        poolInfo = getPoolInfo(pool_);
        marketsInfo = getMarketsInfo(pool_);
        symbolsInfo = getSymbolsInfo(pool_, pvs);
        lpInfo = getLpInfo(pool_, account_);
        tdInfo = getTdInfo(pool_, account_);
    }

    function getPoolInfo(address pool_) public view returns (PoolInfo memory info) {
        ILensPool p = ILensPool(pool_);
        info.pool = pool_;
        info.implementation = p.implementation();
        info.protocolFeeCollector = p.protocolFeeCollector();
        info.tokenB0 = p.tokenB0();
        info.tokenWETH = p.tokenWETH();
        info.marketB0 = p.marketB0();
        info.marketWETH = p.marketWETH();
        info.lToken = p.lToken();
        info.pToken = p.pToken();
        info.oracleManager = p.oracleManager();
        info.swapper = p.swapper();
        info.symbolManager = p.symbolManager();
        info.reserveRatioB0 = p.reserveRatioB0();
        info.minRatioB0 = p.minRatioB0();
        info.poolInitialMarginMultiplier = p.poolInitialMarginMultiplier();
        info.protocolFeeCollectRatio = p.protocolFeeCollectRatio();
        info.minLiquidationReward = p.minLiquidationReward();
        info.maxLiquidationReward = p.maxLiquidationReward();
        info.liquidationRewardCutRatio = p.liquidationRewardCutRatio();
        info.liquidity = p.liquidity();
        info.lpsPnl = p.lpsPnl();
        info.cumulativePnlPerLiquidity = p.cumulativePnlPerLiquidity();
        info.protocolFeeAccrued = p.protocolFeeAccrued();

        info.symbolManagerImplementation = ILensSymbolManager(info.symbolManager).implementation();
        info.initialMarginRequired = ILensSymbolManager(info.symbolManager).initialMarginRequired();
    }

    function getMarketsInfo(address pool_) public view returns (MarketInfo[] memory infos) {
        ILensPool pool = ILensPool(pool_);
        ILensAavePool aavePool = ILensAavePool(ILensVault(pool.vaultImplementation()).aavePool());
        ILensAaveOracle aaveOracle = ILensAaveOracle(ILensVault(pool.vaultImplementation()).aaveOracle());

        address tokenB0 = pool.tokenB0();
        address tokenWETH = pool.tokenWETH();
        address marketB0 = pool.marketB0();
        address marketWETH = pool.marketWETH();

        address[] memory allAssets = aavePool.getReservesList();
        infos = new MarketInfo[](allAssets.length);
        uint256 index = 0;
        for (uint256 i = 0; i < allAssets.length; i++) {
            address asset = allAssets[i];
            address market = asset == tokenB0 ? marketB0 : (asset == tokenWETH ? marketWETH : pool.markets(asset));
            if (market == address(0)) continue;
            infos[index].asset = asset;
            infos[index].market = market;
            infos[index].assetSymbol = ILensERC20(asset).symbol();
            infos[index].marketSymbol = ILensERC20(market).symbol();
            ILensAavePool.ReserveConfigurationMap memory config = aavePool.getConfiguration(asset);
            infos[index].collateralFactor = uint256(config.data & 0xFFFF) * UONE / 10000;
            infos[index].assetPrice = aaveOracle.getAssetPrice(asset) * UONE / aaveOracle.BASE_CURRENCY_UNIT();
            index++;
        }
        assembly {
            mstore(infos, index)
        }
    }

    function getSymbolsInfo(address pool_, ISymbolsLens.PriceAndVolatility[] memory pvs)
    public view returns (ISymbolsLens.SymbolInfo[] memory infos) {
        return symbolsLens.getSymbolsInfo(pool_, pvs);
    }

    function getLpInfo(address pool_, address account_) public view returns (LpInfo memory info) {
        ILensPool pool = ILensPool(pool_);
        info.account = account_;
        info.lTokenId = ILensDToken(pool.lToken()).getTokenIdOf(account_);
        if (info.lTokenId != 0) {
            ILensPool.PoolLpInfo memory tmp = pool.lpInfos(info.lTokenId);
            info.vault = tmp.vault;
            info.amountB0 = tmp.amountB0;
            info.liquidity = tmp.liquidity;
            info.cumulativePnlPerLiquidity = tmp.cumulativePnlPerLiquidity;
            info.vaultLiquidity = ILensVault(info.vault).getVaultLiquidity();

            address[] memory assetsIn = ILensVault(info.vault).getAssetsIn();
            info.markets = new MarketInfo[](assetsIn.length);
            for (uint256 i = 0; i < assetsIn.length; i++) {
                address asset = assetsIn[i];
                address market = assetsIn[i] == pool.tokenB0() ?
                                 pool.marketB0() : (
                                     assetsIn[i] == pool.tokenWETH() ?
                                     pool.marketWETH() :
                                     pool.markets(assetsIn[i])
                                 );
                info.markets[i].asset = asset;
                info.markets[i].assetSymbol = ILensERC20(asset).symbol();
                info.markets[i].assetBalance = ILensVault(info.vault).getAssetBalance(market) * UONE / 10 ** ILensERC20(assetsIn[i]).decimals();
            }
        }
    }

    function getTdInfo(address pool_, address account_) public view returns (TdInfo memory info) {
        ILensPool pool = ILensPool(pool_);
        info.account = account_;
        info.pTokenId = ILensDToken(pool.pToken()).getTokenIdOf(account_);
        if (info.pTokenId != 0) {
            ILensPool.PoolTdInfo memory tmp = pool.tdInfos(info.pTokenId);
            info.vault = tmp.vault;
            info.amountB0 = tmp.amountB0;
            info.vaultLiquidity = ILensVault(info.vault).getVaultLiquidity();

            address[] memory assetsIn = ILensVault(info.vault).getAssetsIn();
            info.markets = new MarketInfo[](assetsIn.length);
            for (uint256 i = 0; i < assetsIn.length; i++) {
                address asset = assetsIn[i];
                address market = assetsIn[i] == pool.tokenB0() ?
                                 pool.marketB0() : (
                                     assetsIn[i] == pool.tokenWETH() ?
                                     pool.marketWETH() :
                                     pool.markets(assetsIn[i])
                                 );
                info.markets[i].asset = asset;
                info.markets[i].assetSymbol = ILensERC20(asset).symbol();
                info.markets[i].assetBalance = ILensVault(info.vault).getAssetBalance(market) * UONE / 10 ** ILensERC20(assetsIn[i]).decimals();
            }

            address[] memory symbols = ILensSymbolManager(pool.symbolManager()).getActiveSymbols(info.pTokenId);
            info.positions = new PositionInfo[](symbols.length);
            for (uint256 i = 0; i < symbols.length; i++) {
                ILensSymbol symbol = ILensSymbol(symbols[i]);
                info.positions[i].symbolAddress = symbols[i];
                info.positions[i].symbol = symbol.symbol();

                if (symbol.nameId() != keccak256(abi.encodePacked('SymbolImplementationGamma'))) {
                    ILensSymbol.Position memory p = symbol.positions(info.pTokenId);
                    info.positions[i].volume = p.volume;
                    info.positions[i].cost = p.cost;
                    info.positions[i].cumulativeFundingPerVolume = p.cumulativeFundingPerVolume;
                } else {
                    ILensSymbolGamma.Position memory p = ILensSymbolGamma(address(symbol)).positions(info.pTokenId);
                    info.positions[i].powerVolume = p.powerVolume;
                    info.positions[i].realFuturesVolume = p.realFuturesVolume;
                    info.positions[i].cost = p.cost;
                    info.positions[i].cumulaitveFundingPerPowerVolume = p.cumulaitveFundingPerPowerVolume;
                    info.positions[i].cumulativeFundingPerRealFuturesVolume = p.cumulativeFundingPerRealFuturesVolume;
                }
            }
        }
    }

}


interface ILensAavePool {
    struct ReserveConfigurationMap {
        uint256 data;
    }
    function getReservesList() external view returns (address[] memory);
    function getConfiguration(address asset) external view returns (ReserveConfigurationMap memory);
}

interface ILensVault {
    function aavePool() external view returns (address);
    function aaveOracle() external view returns (address);
    function getVaultLiquidity() external view returns (uint256);
    function getAssetsIn() external view returns (address[] memory);
    function getAssetBalance(address asset) external view returns (uint256);
}

interface ILensAaveOracle {
    function BASE_CURRENCY_UNIT() external view returns (uint256);
    function getAssetPrice(address asset) external view returns (uint256);
}

interface ILensERC20 {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface ILensDToken {
    function getTokenIdOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/Admin.sol';

abstract contract LensStorage is Admin {

    address public implementation;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/NameVersion.sol';
import '../library/SafeMath.sol';
import '../library/DpmmLinearPricing.sol';

interface ISymbolsLens {

    struct SymbolInfo {
        string category;
        string symbol;
        address symbolAddress;
        address implementation;
        address manager;
        address oracleManager;
        bytes32 symbolId;
        int256 feeRatio;
        int256 alpha;
        int256 fundingPeriod;
        int256 minTradeVolume;
        int256 minInitialMarginRatio;
        int256 initialMarginRatio;
        int256 maintenanceMarginRatio;
        int256 pricePercentThreshold;
        uint256 timeThreshold;
        bool isCloseOnly;
        bytes32 priceId;
        bytes32 volatilityId;
        int256 feeRatioNotional;
        int256 feeRatioMark;
        int256 strikePrice;
        bool isCall;

        int256 netVolume;
        int256 netCost;
        int256 indexPrice;
        uint256 fundingTimestamp;
        int256 cumulativeFundingPerVolume;
        int256 tradersPnl;
        int256 initialMarginRequired;
        uint256 nPositionHolders;

        int256 curIndexPrice;
        int256 curVolatility;
        int256 curCumulativeFundingPerVolume;
        int256 K;
        int256 markPrice;
        int256 funding;
        int256 timeValue;
        int256 delta;
        int256 u;

        int256 power;
        int256 hT;
        int256 powerPrice;
        int256 theoreticalPrice;

        // Gamma
        int256 powerAlpha;
        int256 futuresAlpha;
        int256 netPowerVolume;
        int256 netRealFuturesVolume;
        int256 cumulaitveFundingPerPowerVolume;
        int256 cumulativeFundingPerRealFuturesVolume;
    }

    struct PriceAndVolatility {
        string symbol;
        int256 indexPrice;
        int256 volatility;
    }

    function getSymbolsInfo(address pool_, PriceAndVolatility[] memory pvs) external view returns (SymbolInfo[] memory infos);

}

contract SymbolsLens is ISymbolsLens, NameVersion {

    using SafeMath for uint256;
    using SafeMath for int256;

    int256 constant ONE = 1e18;

    IEverlastingOptionPricing public immutable everlastingOptionPricing;

    constructor (address everlastingOptionPricing_) NameVersion('SymbolsLens', '3.1') {
        everlastingOptionPricing = IEverlastingOptionPricing(everlastingOptionPricing_);
    }

    function getSymbolsInfo(address pool_, PriceAndVolatility[] memory pvs) public view returns (SymbolInfo[] memory infos) {
        ILensSymbolManager manager = ILensSymbolManager(ILensPool(pool_).symbolManager());
        uint256 length = manager.getSymbolsLength();
        infos = new SymbolInfo[](length);
        for (uint256 i = 0; i < length; i++) {
            SymbolInfo memory info = infos[i];
            ILensSymbol s = ILensSymbol(manager.indexedSymbols(i));
            info.symbol = s.symbol();
            info.symbolAddress = address(s);
            info.implementation = s.implementation();
            info.manager = s.manager();
            info.oracleManager = s.oracleManager();
            info.symbolId = s.symbolId();

            bool isGamma = s.nameId() == keccak256(abi.encodePacked('SymbolImplementationGamma'));
            if (!isGamma) {
                info.alpha = s.alpha();
            } else {
                info.powerAlpha = s.powerAlpha();
                info.futuresAlpha = s.futuresAlpha();
            }

            info.fundingPeriod = s.fundingPeriod();
            info.minTradeVolume = s.minTradeVolume();
            info.initialMarginRatio = s.initialMarginRatio();
            info.maintenanceMarginRatio = s.maintenanceMarginRatio();
            if (!isGamma) {
                info.pricePercentThreshold = s.pricePercentThreshold();
                info.timeThreshold = s.timeThreshold();
            }
            info.isCloseOnly = s.isCloseOnly();

            if (!isGamma) {
                info.netVolume = s.netVolume();
            } else {
                info.netPowerVolume = s.netPowerVolume();
                info.netRealFuturesVolume = s.netRealFuturesVolume();
            }
            info.netCost = s.netCost();
            info.indexPrice = s.indexPrice();
            info.fundingTimestamp = s.fundingTimestamp();
            if (!isGamma) {
                info.cumulativeFundingPerVolume = s.cumulativeFundingPerVolume();
            } else {
                info.cumulaitveFundingPerPowerVolume = s.cumulaitveFundingPerPowerVolume();
                info.cumulativeFundingPerRealFuturesVolume = s.cumulativeFundingPerRealFuturesVolume();
            }
            info.tradersPnl = s.tradersPnl();
            info.initialMarginRequired = s.initialMarginRequired();
            info.nPositionHolders = s.nPositionHolders();

            int256 liquidity = ILensPool(pool_).liquidity() + ILensPool(pool_).lpsPnl();
            bool success;
            bytes memory res;
            if (isGamma) {
                info.category = 'gamma';
                info.feeRatio = s.feeRatio();
                info.priceId = s.priceId();
                info.volatilityId = s.volatilityId();
                info.curIndexPrice = ILensOracleManager(info.oracleManager).value(info.priceId).utoi();
                info.curVolatility = ILensOracleManager(info.oracleManager).value(info.volatilityId).utoi();
                for (uint256 j = 0; j < pvs.length; j++) {
                    if (info.priceId == keccak256(abi.encodePacked(pvs[j].symbol))) {
                        if (pvs[j].indexPrice != 0) info.curIndexPrice = pvs[j].indexPrice;
                        if (pvs[j].volatility != 0) info.curVolatility = pvs[j].volatility;
                        break;
                    }
                }
            } else if (s.nameId() == keccak256(abi.encodePacked('SymbolImplementationFutures'))) {
                info.category = 'futures';
                info.feeRatio = s.feeRatio();
                info.curIndexPrice = ILensOracleManager(info.oracleManager).value(info.symbolId).utoi();
                for (uint256 j = 0; j < pvs.length; j++) {
                    if (info.symbolId == keccak256(abi.encodePacked(pvs[j].symbol))) {
                        if (pvs[j].indexPrice != 0) info.curIndexPrice = pvs[j].indexPrice;
                        break;
                    }
                }
                info.K = info.curIndexPrice * info.alpha / liquidity;
                info.markPrice = DpmmLinearPricing.calculateMarkPrice(info.curIndexPrice, info.K, info.netVolume);
                int256 diff = (info.markPrice - info.curIndexPrice) * (block.timestamp - info.fundingTimestamp).utoi() / info.fundingPeriod;
                info.funding = info.netVolume * diff / ONE;
                unchecked { info.curCumulativeFundingPerVolume = info.cumulativeFundingPerVolume + diff; }

            } else if (s.nameId() == keccak256(abi.encodePacked('SymbolImplementationOption'))) {
                info.category = 'option';
                info.priceId = s.priceId();
                info.volatilityId = s.volatilityId();

                (success, res) = address(s).staticcall(abi.encodeWithSelector(s.feeRatioNotional.selector));
                if (success) {
                    info.feeRatioNotional = abi.decode(res, (int256));
                }
                (success, res) = address(s).staticcall(abi.encodeWithSelector(s.feeRatioMark.selector));
                if (success) {
                    info.feeRatioMark = abi.decode(res, (int256));
                }

                info.strikePrice = s.strikePrice();
                info.isCall = s.isCall();
                info.curIndexPrice = ILensOracleManager(info.oracleManager).value(info.priceId).utoi();
                info.curVolatility = ILensOracleManager(info.oracleManager).value(info.volatilityId).utoi();
                for (uint256 j = 0; j < pvs.length; j++) {
                    if (info.priceId == keccak256(abi.encodePacked(pvs[j].symbol))) {
                        if (pvs[j].indexPrice != 0) info.curIndexPrice = pvs[j].indexPrice;
                        if (pvs[j].volatility != 0) info.curVolatility = pvs[j].volatility;
                        break;
                    }
                }
                int256 intrinsicValue = info.isCall ?
                                        (info.curIndexPrice - info.strikePrice).max(0) :
                                        (info.strikePrice - info.curIndexPrice).max(0);
                (info.timeValue, info.delta, info.u) = everlastingOptionPricing.getEverlastingTimeValueAndDelta(
                    info.curIndexPrice, info.strikePrice, info.curVolatility, info.fundingPeriod * ONE / 31536000
                );
                if (intrinsicValue > 0) {
                    if (info.isCall) info.delta += ONE;
                    else info.delta -= ONE;
                } else if (info.curIndexPrice == info.strikePrice) {
                    if (info.isCall) info.delta = ONE / 2;
                    else info.delta = -ONE / 2;
                }
                info.K = info.curIndexPrice ** 2 / (intrinsicValue + info.timeValue) * info.delta.abs() * info.alpha / liquidity / ONE;
                info.markPrice = DpmmLinearPricing.calculateMarkPrice(
                    intrinsicValue + info.timeValue, info.K, info.netVolume
                );
                int256 diff = (info.markPrice - intrinsicValue) * (block.timestamp - info.fundingTimestamp).utoi() / info.fundingPeriod;
                info.funding = info.netVolume * diff / ONE;
                unchecked { info.curCumulativeFundingPerVolume = info.cumulativeFundingPerVolume + diff; }

            } else if (s.nameId() == keccak256(abi.encodePacked('SymbolImplementationPower'))) {
                info.category = 'power';
                info.power = s.power().utoi();
                info.feeRatio = s.feeRatio();
                info.priceId = s.priceId();
                info.volatilityId = s.volatilityId();
                info.curIndexPrice = ILensOracleManager(info.oracleManager).value(info.priceId).utoi();
                info.curVolatility = ILensOracleManager(info.oracleManager).value(info.volatilityId).utoi();
                for (uint256 j = 0; j < pvs.length; j++) {
                    if (info.priceId == keccak256(abi.encodePacked(pvs[j].symbol))) {
                        if (pvs[j].indexPrice != 0) info.curIndexPrice = pvs[j].indexPrice;
                        if (pvs[j].volatility != 0) info.curVolatility = pvs[j].volatility;
                        break;
                    }
                }
                info.hT = info.curVolatility ** 2 / ONE * info.power * (info.power - 1) / 2 * info.fundingPeriod / 31536000;
                info.powerPrice = _exp(info.curIndexPrice, s.power());
                info.theoreticalPrice = info.powerPrice * ONE / (ONE - info.hT);
                info.K = info.power * info.theoreticalPrice * info.alpha / liquidity;
                info.markPrice = DpmmLinearPricing.calculateMarkPrice(
                    info.theoreticalPrice, info.K, info.netVolume
                );
                int256 diff = (info.markPrice - info.powerPrice) * (block.timestamp - info.fundingTimestamp).utoi() / info.fundingPeriod;
                info.funding = info.netVolume * diff / ONE;
                unchecked { info.curCumulativeFundingPerVolume = info.cumulativeFundingPerVolume + diff; }
            }

        }
    }

    function _exp(int256 base, uint256 exp) internal pure returns (int256) {
        int256 res = ONE;
        for (uint256 i = 0; i < exp; i++) {
            res = res * base / ONE;
        }
        return res;
    }

}

interface ILensPool {
    struct PoolLpInfo {
        address vault;
        int256 amountB0;
        int256 liquidity;
        int256 cumulativePnlPerLiquidity;
    }
    struct PoolTdInfo {
        address vault;
        int256 amountB0;
    }
    function implementation() external view returns (address);
    function protocolFeeCollector() external view returns (address);
    function vaultImplementation() external view returns (address);
    function tokenB0() external view returns (address);
    function tokenWETH() external view returns (address);
    function vTokenB0() external view returns (address);  // Venus
    function vTokenETH() external view returns (address); // Venus
    function marketB0() external view returns (address);   // Aave
    function marketWETH() external view returns (address); // Aave
    function lToken() external view returns (address);
    function pToken() external view returns (address);
    function oracleManager() external view returns (address);
    function swapper() external view returns (address);
    function symbolManager() external view returns (address);
    function reserveRatioB0() external view returns (uint256);
    function minRatioB0() external view returns (int256);
    function poolInitialMarginMultiplier() external view returns (int256);
    function protocolFeeCollectRatio() external view returns (int256);
    function minLiquidationReward() external view returns (int256);
    function maxLiquidationReward() external view returns (int256);
    function liquidationRewardCutRatio() external view returns (int256);
    function liquidity() external view returns (int256);
    function lpsPnl() external view returns (int256);
    function cumulativePnlPerLiquidity() external view returns (int256);
    function protocolFeeAccrued() external view returns (int256);
    function markets(address underlying_) external view returns (address);
    function lpInfos(uint256 lTokenId) external view returns (PoolLpInfo memory);
    function tdInfos(uint256 pTokenId) external view returns (PoolTdInfo memory);
}

interface ILensSymbolManager {
    function implementation() external view returns (address);
    function initialMarginRequired() external view returns (int256);
    function getSymbolsLength() external view returns (uint256);
    function indexedSymbols(uint256 index) external view returns (address);
    function getActiveSymbols(uint256 pTokenId) external view returns (address[] memory);
}

interface ILensSymbol {
    function nameId() external view returns (bytes32);
    function symbol() external view returns (string memory);
    function implementation() external view returns (address);
    function manager() external view returns (address);
    function oracleManager() external view returns (address);
    function symbolId() external view returns (bytes32);
    function feeRatio() external view returns (int256);
    function alpha() external view returns (int256);
    function fundingPeriod() external view returns (int256);
    function minTradeVolume() external view returns (int256);
    function minInitialMarginRatio() external view returns (int256);
    function initialMarginRatio() external view returns (int256);
    function maintenanceMarginRatio() external view returns (int256);
    function pricePercentThreshold() external view returns (int256);
    function timeThreshold() external view returns (uint256);
    function isCloseOnly() external view returns (bool);
    function priceId() external view returns (bytes32);
    function volatilityId() external view returns (bytes32);
    function feeRatioITM() external view returns (int256);
    function feeRatioOTM() external view returns (int256);
    function feeRatioNotional() external view returns (int256);
    function feeRatioMark() external view returns (int256);
    function strikePrice() external view returns (int256);
    function isCall() external view returns (bool);
    function netVolume() external view returns (int256);
    function netCost() external view returns (int256);
    function indexPrice() external view returns (int256);
    function fundingTimestamp() external view returns (uint256);
    function cumulativeFundingPerVolume() external view returns (int256);
    function tradersPnl() external view returns (int256);
    function initialMarginRequired() external view returns (int256);
    function nPositionHolders() external view returns (uint256);
    struct Position {
        int256 volume;
        int256 cost;
        int256 cumulativeFundingPerVolume;
    }
    function positions(uint256 pTokenId) external view returns (Position memory);
    function power() external view returns (uint256);

    function powerAlpha() external view returns (int256);
    function futuresAlpha() external view returns (int256);
    function netPowerVolume() external view returns (int256);
    function netRealFuturesVolume() external view returns (int256);
    function cumulaitveFundingPerPowerVolume() external view returns (int256);
    function cumulativeFundingPerRealFuturesVolume() external view returns (int256);
}

interface ILensSymbolGamma {
    struct Position {
        int256 powerVolume;
        int256 realFuturesVolume;
        int256 cost;
        int256 cumulaitveFundingPerPowerVolume;
        int256 cumulativeFundingPerRealFuturesVolume;
    }
    function positions(uint256 pTokenId) external view returns (Position memory);
}

interface ILensOracleManager {
    function value(bytes32 symbolId) external view returns (uint256);
}

interface IEverlastingOptionPricing {
    function getEverlastingTimeValueAndDelta(int256 S, int256 K, int256 V, int256 T)
    external pure returns (int256 timeValue, int256 delta, int256 u);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library DpmmLinearPricing {

    int256 constant ONE = 1e18;

    function calculateMarkPrice(
        int256 indexPrice,
        int256 K,
        int256 tradersNetVolume
    ) internal pure returns (int256)
    {
        return indexPrice * (ONE + K * tradersNetVolume / ONE) / ONE;
    }

    function calculateCost(
        int256 indexPrice,
        int256 K,
        int256 tradersNetVolume,
        int256 tradeVolume
    ) internal pure returns (int256)
    {
        int256 r = ((tradersNetVolume + tradeVolume) ** 2 - tradersNetVolume ** 2) / ONE * K / ONE / 2 + tradeVolume;
        return indexPrice * r / ONE;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

library SafeMath {

    uint256 constant UMAX = 2 ** 255 - 1;
    int256  constant IMIN = -2 ** 255;

    function utoi(uint256 a) internal pure returns (int256) {
        require(a <= UMAX, 'SafeMath.utoi: overflow');
        return int256(a);
    }

    function itou(int256 a) internal pure returns (uint256) {
        require(a >= 0, 'SafeMath.itou: underflow');
        return uint256(a);
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != IMIN, 'SafeMath.abs: overflow');
        return a >= 0 ? a : -a;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a <= b ? a : b;
    }

    // rescale a uint256 from base 10**decimals1 to 10**decimals2
    function rescale(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256) {
        return decimals1 == decimals2 ? a : a * 10**decimals2 / 10**decimals1;
    }

    // rescale towards zero
    // b: rescaled value in decimals2
    // c: the remainder
    function rescaleDown(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256 b, uint256 c) {
        b = rescale(a, decimals1, decimals2);
        c = a - rescale(b, decimals2, decimals1);
    }

    // rescale towards infinity
    // b: rescaled value in decimals2
    // c: the excessive
    function rescaleUp(uint256 a, uint256 decimals1, uint256 decimals2) internal pure returns (uint256 b, uint256 c) {
        b = rescale(a, decimals1, decimals2);
        uint256 d = rescale(b, decimals2, decimals1);
        if (d != a) {
            b += 1;
            c = rescale(b, decimals2, decimals1) - a;
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IAdmin.sol';

abstract contract Admin is IAdmin {

    address public admin;

    modifier _onlyAdmin_() {
        require(msg.sender == admin, 'Admin: only admin');
        _;
    }

    constructor () {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    function setAdmin(address newAdmin) external _onlyAdmin_ {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IAdmin {

    event NewAdmin(address indexed newAdmin);

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface INameVersion {

    function nameId() external view returns (bytes32);

    function versionId() external view returns (bytes32);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './INameVersion.sol';

/**
 * @dev Convenience contract for name and version information
 */
abstract contract NameVersion is INameVersion {

    bytes32 public immutable nameId;
    bytes32 public immutable versionId;

    constructor (string memory name, string memory version) {
        nameId = keccak256(abi.encodePacked(name));
        versionId = keccak256(abi.encodePacked(version));
    }

}