// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/NameVersion.sol';
import '../library/SafeMath.sol';
import '../library/DpmmLinearPricing.sol';
import '../vault/IVault.sol';

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
        int256 feeRatioITM;
        int256 feeRatioOTM;
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
    }

    struct PriceAndVolatility {
        string symbol;
        int256 indexPrice;
        int256 volatility;
    }

    function getSymbolInfo(address pool_, string calldata symbolName_, PriceAndVolatility[] memory pvs) external view returns (SymbolInfo memory info);

    function getSymbolsInfo(address pool_, PriceAndVolatility[] memory pvs) external view returns (SymbolInfo[] memory infos);

}

contract SymbolsLens is ISymbolsLens, NameVersion {

    using SafeMath for uint256;
    using SafeMath for int256;

    int256 constant ONE = 1e18;

    IEverlastingOptionPricingLens public immutable everlastingOptionPricingLens;

    constructor (address everlastingOptionPricingLens_) NameVersion('SymbolsLens', '3.0.2') {
        everlastingOptionPricingLens = IEverlastingOptionPricingLens(everlastingOptionPricingLens_);
    }

    function getSymbolInfoByAddress(address pool_, address symbolAddress_, PriceAndVolatility[] memory pvs) internal view returns (SymbolInfo memory info) {
        ILensSymbol s = ILensSymbol(symbolAddress_);

        info.symbol = s.symbol();
        info.symbolAddress = address(s);
        info.implementation = s.implementation();
        info.manager = s.manager();
        info.oracleManager = s.oracleManager();
        info.symbolId = s.symbolId();
        info.alpha = s.alpha();
        info.fundingPeriod = s.fundingPeriod();
        info.minTradeVolume = s.minTradeVolume();
        info.initialMarginRatio = s.initialMarginRatio();
        info.maintenanceMarginRatio = s.maintenanceMarginRatio();
        info.pricePercentThreshold = s.pricePercentThreshold();
        info.timeThreshold = s.timeThreshold();
        info.isCloseOnly = s.isCloseOnly();

        info.netVolume = s.netVolume();
        info.netCost = s.netCost();
        info.indexPrice = s.indexPrice();
        info.fundingTimestamp = s.fundingTimestamp();
        info.cumulativeFundingPerVolume = s.cumulativeFundingPerVolume();
        info.tradersPnl = s.tradersPnl();
        info.initialMarginRequired = s.initialMarginRequired();
        info.nPositionHolders = s.nPositionHolders();

        int256 liquidity = ILensPool(pool_).getLiquidity().utoi() + ILensPool(pool_).lpsPnl() + 1;
        if (s.nameId() == keccak256(abi.encodePacked('SymbolImplementationFutures'))) {
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
            info.minInitialMarginRatio = s.minInitialMarginRatio();
            info.priceId = s.priceId();
            info.volatilityId = s.volatilityId();
            info.feeRatioITM = s.feeRatioITM();
            info.feeRatioOTM = s.feeRatioOTM();
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
            (info.timeValue, info.delta, info.u) = everlastingOptionPricingLens.getEverlastingTimeValueAndDelta(
                info.curIndexPrice, info.strikePrice, info.curVolatility, info.fundingPeriod * ONE / 31536000
            );
            if (intrinsicValue > 0) {
                if (info.isCall) info.delta += ONE;
                else info.delta -= ONE;
            } else if (info.curIndexPrice == info.strikePrice) {
                if (info.isCall) info.delta = ONE / 2;
                else info.delta = -ONE / 2;
            }
            info.theoreticalPrice = intrinsicValue + info.timeValue;
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

    function getSymbolInfo(address pool_, string calldata symbolName, PriceAndVolatility[] memory pvs) public view returns (SymbolInfo memory info) {
        ILensSymbolManager manager = ILensSymbolManager(ILensPool(pool_).symbolManager());
        bytes32 symbolId = keccak256(abi.encodePacked(symbolName));
        address symbolAddress = manager.symbols(symbolId);
        if (symbolAddress == address(0))
            return info;
        info = getSymbolInfoByAddress(pool_, symbolAddress, pvs);
    }

    function getSymbolsInfo(address pool_, PriceAndVolatility[] memory pvs) public view returns (SymbolInfo[] memory infos) {
        ILensSymbolManager manager = ILensSymbolManager(ILensPool(pool_).symbolManager());
        uint256 length = manager.getSymbolsLength();
        infos = new SymbolInfo[](length);
        for (uint256 i = 0; i < length; i++) {
            address symbolAddress = manager.indexedSymbols(i);
            infos[i] = getSymbolInfoByAddress(pool_, symbolAddress, pvs);
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
    function vTokenB0() external view returns (address);
    function vTokenETH() external view returns (address);
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
    function userVault(bytes32 vaultId) external view returns (address);
    function userAmountB0(bytes32 vaultId) external view returns (int256);
    function getLiquidity() external view returns (uint256);
    function lpTokenAddress() external view returns (address);
    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint256 index) external view returns (address);
    function whitelistedTokens(address token) external view returns (bool);
    function getTokenPrice(address token) external view returns (uint256);
    function getTokenPriceId(address token) external view returns (bytes32);
    function mintFeeBasisPoints() external view returns (uint256);
    function burnFeeBasisPoints() external view returns (uint256);
    function BASIS_POINTS_DIVISOR() external view returns (uint256);
}

interface ILensSymbolManager {
    function implementation() external view returns (address);
    function initialMarginRequired() external view returns (int256);
    function getSymbolsLength() external view returns (uint256);
    function indexedSymbols(uint256 index) external view returns (address);
    function getActiveSymbols(uint256 pTokenId) external view returns (address[] memory);
    function symbols(bytes32 symbolId) external view returns (address);
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
    function positions(address pTokenId) external view returns (Position memory);
    function power() external view returns (uint256);
    function maxLeverage() external view returns (int256);
    function marginRequiredRatio() external view returns (int256);
}

interface ILensVault {
    function comptroller() external view returns (address);
    function getVaultLiquidity() external view returns (uint256);
    function getVaultLiquidityToken(address token) external view returns (uint256);
    function getVaultLiquidityTokenVolume(address token) external view returns (uint256);
    function getVaultTokenVolume() external view returns (TokenVolumeInfo[] memory);
    function getMarketsIn() external view returns (address[] memory);
}

interface ILensVToken {
    function symbol() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function underlying() external view returns (address);
    function exchangeRateStored() external view returns (uint256);
}

interface ILensComptroller {
    function getAllMarkets() external view returns (address[] memory);
    function oracle() external view returns (address);
}

interface ILensOracle {
    function getUnderlyingPrice(address vToken) external view returns (uint256);
}

interface ILensERC20 {
    function symbol() external view returns (string memory);
}

interface ILensOracleManager {
    function value(bytes32 symbolId) external view returns (uint256);
}

interface ILensDToken {
    function getTokenIdOf(address account) external view returns (uint256);
}

interface IEverlastingOptionPricingLens {
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

interface INameVersion {

    function nameId() external view returns (bytes32);

    function versionId() external view returns (bytes32);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./INameVersion.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/INameVersion.sol';

interface IVault is INameVersion {

    function pool() external view returns (address);

    // function comptroller() external view returns (address);

    // function vTokenETH() external view returns (address);

    // function tokenXVS() external view returns (address);

    function vaultLiquidityMultiplier() external view returns (uint256);

    function getVaultLiquidity() external view  returns (uint256);

    function getVaultLiquidityToken(address token) external view returns (uint256);

    function getVaultLiquidityTokenVolume(address token) external view returns (uint256);

    function getVaultTokenVolume() external view returns (TokenVolumeInfo[] memory);

    // function getHypotheticalVaultLiquidity(address vTokenModify, uint256 redeemVTokens) external view returns (uint256);

    // function isInMarket(address vToken) external view returns (bool);

    // function getMarketsIn() external view returns (address[] memory);

    // function getBalances(address vToken) external view returns (uint256 vTokenBalance, uint256 underlyingBalance);

    // function enterMarket(address vToken) external;

    // function exitMarket(address vToken) external;

    // function mint() external payable;

    // function mint(address vToken, uint256 amount) external;

    // function redeem(address vToken, uint256 amount) external;

    // function redeemAll(address vToken) external;

    // function redeemUnderlying(address vToken, uint256 amount) external;

    function transfer(address underlying, address to, uint256 amount) external;

    function transferAll(address underlying, address to) external returns (uint256);

    // function claimVenus(address account) external;

    // function supply(address token, uint256 amount) external;
    // function withdraw(address token, uint256 amount) external;

}

struct TokenVolumeInfo {
        address token;
        string symbol;
        uint256 volume;
}