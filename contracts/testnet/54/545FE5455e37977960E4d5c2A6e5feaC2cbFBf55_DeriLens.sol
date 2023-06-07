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

interface INameVersion {

    function nameId() external view returns (bytes32);

    function versionId() external view returns (bytes32);

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

interface IAdmin {

    event NewAdmin(address indexed newAdmin);

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/NameVersion.sol';
import '../library/SafeMath.sol';
import './SymbolsLens.sol';
import '../token/IERC20.sol';
import '../vault/IVault.sol';

contract DeriLens is NameVersion {

    using SafeMath for uint256;
    using SafeMath for int256;

    int256 constant ONE = 1e18;

    ISymbolsLens immutable symbolsLens;

    constructor (address symbolsLens_) NameVersion('DeriLens', '3.0.2') {
        symbolsLens = ISymbolsLens(symbolsLens_);
    }

    struct PoolInfo {
        address pool;
        address implementation;
        address protocolFeeCollector;

        address tokenB0;
        address tokenWETH;
        address vTokenB0;
        address vTokenETH;
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
        uint256 totalSupply;
    }

    struct MarketInfo {
        address underlying;
        address vToken;
        string underlyingSymbol;
        string vTokenSymbol;
        uint256 underlyingPrice;
        uint256 exchangeRate;
        uint256 vTokenBalance;
    }

    struct TokenInfo {
        address token;
        uint256 price;
        uint256 balance;
        string symbol;
    }

    struct LpInfo {
        address account;
        uint256 lTokenId;
        address vault;
        int256 amountB0;
        int256 liquidity;
        int256 cumulativePnlPerLiquidity;
        uint256 vaultLiquidity;
        // MarketInfo[] markets;
    }

    struct PositionInfo {
        address symbolAddress;
        string symbol;
        int256 volume;
        int256 cost;
        int256 cumulativeFundingPerVolume;
        int256 margin;
        int256 marginUsed;
        uint256 vaultLiquidity;
        address vault;
        int256 leverage;
        int256 liquidationPrice;
    }

    struct TdInfo {
        address account;
        uint256 pTokenId;
        int256 amountB0;
        // MarketInfo[] markets;
        PositionInfo[] positions;
    }

    struct TradeData {
        int256 tradeVolume;
        int256 K;
        int256 tradeCost;
        int256 tradeFee;
        int256 cumulativeFundingPerVolume;
        int256 diff;
        int256 traderFunding;
        int256 tradeRealizedCost;
        int256 cost;
        int256 traderPnl;
        int256 amountB0;
        int256 traderMargin;
        int256 marginA;
        int256 volumeA;
    }

    struct TradeInfo {
        int256 vaultLiquidity;
        int256 amountB0;
        int256 funding;
        int256 cost;
        int256 volume;
        int256 feeRatio;
        int256 maxLeverage;
        int256 cumulativeFundingPerVolume;
        int256 diff;
        int256 marginUsed;
        int256 availableMargin;
        int256 maxVolume;
        int256 curIndexPrice;
        int256 marginRequiredRatio;
    }

    function getInfo(address pool_, address account_, ISymbolsLens.PriceAndVolatility[] memory pvs) external view returns (
        PoolInfo memory poolInfo,
        // MarketInfo[] memory marketsInfo,
        ISymbolsLens.SymbolInfo[] memory symbolsInfo,
        TdInfo memory tdInfo,
        TokenInfo[] memory tokenInfo
    ) {
        poolInfo = getPoolInfo(pool_);
        // marketsInfo = getMarketsInfo(pool_);
        symbolsInfo = getSymbolsInfo(pool_, pvs);
        // lpInfo = getLpInfo(pool_, account_);
        tdInfo = getTdInfo(pool_, account_);
        tokenInfo = getTokenInfo(pool_, account_);
    }

    function getPoolInfo(address pool_) public view returns (PoolInfo memory info) {
        ILensPool p = ILensPool(pool_);
        info.pool = pool_;
        info.implementation = p.implementation();
        info.protocolFeeCollector = p.protocolFeeCollector();
        info.tokenB0 = p.tokenB0();
        info.tokenWETH = p.tokenWETH();
        // info.vTokenB0 = p.vTokenB0();
        // info.vTokenETH = p.vTokenETH();
        // info.lToken = p.lToken();
        // info.pToken = p.pToken();

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
        info.liquidity =  p.getLiquidity().utoi();

        address lpAddress = p.lpTokenAddress();
        info.totalSupply = IERC20(lpAddress).totalSupply();

        info.lpsPnl = p.lpsPnl();
        info.cumulativePnlPerLiquidity = p.cumulativePnlPerLiquidity();
        info.protocolFeeAccrued = p.protocolFeeAccrued();

        info.symbolManagerImplementation = ILensSymbolManager(info.symbolManager).implementation();
        info.initialMarginRequired = ILensSymbolManager(info.symbolManager).initialMarginRequired();
    }

    // function getMarketsInfo(address pool_) public view returns (MarketInfo[] memory infos) {
    //     ILensPool pool = ILensPool(pool_);
    //     ILensComptroller comptroller = ILensComptroller(ILensVault(pool.vaultImplementation()).comptroller());
    //     ILensOracle oracle = ILensOracle(comptroller.oracle());

    //     address tokenB0 = pool.tokenB0();
    //     address tokenWETH = pool.tokenWETH();
    //     address vTokenB0 = pool.vTokenB0();
    //     address vTokenETH = pool.vTokenETH();

    //     address[] memory allMarkets = comptroller.getAllMarkets();
    //     address[] memory underlyings = new address[](allMarkets.length);
    //     uint256 count;
    //     for (uint256 i = 0; i < allMarkets.length; i++) {
    //         address vToken = allMarkets[i];
    //         if (vToken == vTokenB0) {
    //             underlyings[i] = tokenB0;
    //             count++;
    //         } else if (vToken == vTokenETH) {
    //             underlyings[i] = tokenWETH;
    //             count++;
    //         } else {
    //             address underlying = ILensVToken(vToken).underlying();
    //             if (pool.markets(underlying) == vToken) {
    //                 underlyings[i] = underlying;
    //                 count++;
    //             }
    //         }
    //     }

    //     infos = new MarketInfo[](count);
    //     count = 0;
    //     for (uint256 i = 0; i < underlyings.length; i++) {
    //         if (underlyings[i] != address(0)) {
    //             infos[count].underlying = underlyings[i];
    //             infos[count].vToken = allMarkets[i];
    //             infos[count].underlyingSymbol = ILensERC20(underlyings[i]).symbol();
    //             infos[count].vTokenSymbol = ILensVToken(allMarkets[i]).symbol();
    //             infos[count].underlyingPrice = oracle.getUnderlyingPrice(allMarkets[i]);
    //             infos[count].exchangeRate = ILensVToken(allMarkets[i]).exchangeRateStored();
    //             count++;
    //         }
    //     }
    // }

    function getTokenInfo(address pool_, address account_) public view returns (TokenInfo [] memory infos) {
        ILensPool pool = ILensPool(pool_);
        uint256 length = pool.allWhitelistedTokensLength();

        infos = new TokenInfo[](length);

        for(uint256 i=0 ; i< length ; i++) {
            address token = pool.allWhitelistedTokens(i);
            infos[i].token = token;
            infos[i].price = pool.getTokenPrice(token);
            infos[i].balance = IERC20(token).balanceOf(account_);
            infos[i].symbol = IERC20(token).symbol();
        }   
    }

    function getSymbolInfo(address pool_, string calldata symbolName, ISymbolsLens.PriceAndVolatility[] memory pvs)
    public view returns (ISymbolsLens.SymbolInfo memory info) {
        info = symbolsLens.getSymbolInfo(pool_, symbolName, pvs);
        return info;
    }

    function getSymbolsInfo(address pool_, ISymbolsLens.PriceAndVolatility[] memory pvs)
    public view returns (ISymbolsLens.SymbolInfo[] memory infos) {
        return symbolsLens.getSymbolsInfo(pool_, pvs);
    }

    function getLpInfo(address pool_, address account_) public view returns (LpInfo memory info) {
        ILensPool pool = ILensPool(pool_);
        info.account = account_;
        // info.lTokenId = ILensDToken(pool.lToken()).getTokenIdOf(account_);
        // if (info.lTokenId != 0) {
        //     ILensPool.PoolLpInfo memory tmp = pool.lpInfos(info.lTokenId);
        //     info.vault = tmp.vault;
        //     info.amountB0 = tmp.amountB0;
        //     info.liquidity = tmp.liquidity;
        //     info.cumulativePnlPerLiquidity = tmp.cumulativePnlPerLiquidity;
        //     info.vaultLiquidity = ILensVault(info.vault).getVaultLiquidity();

            // address[] memory markets = ILensVault(info.vault).getMarketsIn();
            // info.markets = new MarketInfo[](markets.length);
            // for (uint256 i = 0; i < markets.length; i++) {
            //     address vToken = markets[i];
            //     info.markets[i].vToken = vToken;
            //     info.markets[i].vTokenSymbol = ILensVToken(vToken).symbol();
            //     info.markets[i].underlying = vToken != pool.vTokenETH() ? ILensVToken(vToken).underlying() : pool.tokenWETH();
            //     info.markets[i].underlyingSymbol = ILensERC20(info.markets[i].underlying).symbol();
            //     info.markets[i].underlyingPrice = ILensOracle(ILensComptroller(ILensVault(pool.vaultImplementation()).comptroller()).oracle()).getUnderlyingPrice(vToken);
            //     info.markets[i].exchangeRate = ILensVToken(vToken).exchangeRateStored();
            //     info.markets[i].vTokenBalance = ILensVToken(vToken).balanceOf(info.vault);
            // }
        // }
        // ILensPool.PoolLpInfo memory tmp = pool.lpInfos(info.lTokenId);
        info.vault = address(0);
        info.amountB0 = 0;
        info.liquidity =  pool.getLiquidity().utoi();
        info.cumulativePnlPerLiquidity = 0;

        address lpAddress = pool.lpTokenAddress();
        uint256 totalSupply = IERC20(lpAddress).totalSupply();
        uint256 balance = IERC20(lpAddress).balanceOf(account_);
        

        info.vaultLiquidity = info.liquidity.itou() * balance / totalSupply;
    }

    function estimateLiquidationPrice(address pool_, address account_, string memory symbolName, int256 tradeVolume) public view returns (int256 liquidationPrice) {
        // return 0;
        bytes32 vaultId = keccak256(abi.encodePacked(account_, symbolName));
        ILensSymbolManager manager = ILensSymbolManager(ILensPool(pool_).symbolManager());
        bytes32 symbolId = keccak256(abi.encodePacked(symbolName));
        address symbolAddress = manager.symbols(symbolId);
        ILensSymbol symbol = ILensSymbol(symbolAddress);
        ILensPool pool = ILensPool(pool_);
        ILensSymbol.Position memory p = symbol.positions(account_);
        int256 curIndexPrice;
        if(symbol.nameId() != keccak256(abi.encodePacked("SymbolImplementationFutures"))){
            return 0;
        }
        curIndexPrice = ILensOracleManager(symbol.oracleManager()).value(symbol.symbolId()).utoi();
        // if(symbol.nameId() == keccak256(abi.encodePacked("SymbolImplementationFutures"))){
        //     curIndexPrice = ILensOracleManager(symbol.oracleManager()).value(symbol.symbolId()).utoi();
        // }
        // else {
        //     curIndexPrice = ILensOracleManager(symbol.oracleManager()).value(symbol.priceId()).utoi();
        // }
        TradeData memory tradeData;
        tradeData.tradeVolume = tradeVolume;
        tradeData.K = curIndexPrice * symbol.alpha() / pool.getLiquidity().utoi();
        tradeData.tradeCost = DpmmLinearPricing.calculateCost(curIndexPrice, tradeData.K, symbol.netVolume(), tradeData.tradeVolume);
        tradeData.tradeFee = tradeData.tradeCost.abs() * symbol.feeRatio() / ONE;
        tradeData.cumulativeFundingPerVolume = symbol.cumulativeFundingPerVolume();
        tradeData.diff = tradeData.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume;
        tradeData.traderFunding = p.volume * tradeData.diff / ONE;
        if (!(p.volume >= 0 && tradeVolume >= 0) && !(p.volume <= 0 && tradeVolume <= 0)) {
            int256 absVolume = p.volume.abs();
            int256 absTradeVolume = tradeVolume.abs();
            if (absVolume <= absTradeVolume) {
                tradeData.tradeRealizedCost = tradeData.tradeCost * absVolume / absTradeVolume + p.cost;
            } else {
                tradeData.tradeRealizedCost = p.cost * absTradeVolume / absVolume + tradeData.tradeCost;
            }
        }
        p.volume = p.volume + tradeData.tradeVolume;
        tradeData.cost = p.cost + tradeData.tradeCost - tradeData.tradeRealizedCost;
        tradeData.traderPnl = p.volume * curIndexPrice / ONE - tradeData.cost;
        tradeData.amountB0 = pool.userAmountB0(vaultId) - tradeData.traderFunding - tradeData.tradeFee - tradeData.tradeRealizedCost;
        tradeData.traderMargin = tradeData.traderPnl + ILensVault(pool.userVault(vaultId)).getVaultLiquidity().utoi() + tradeData.amountB0;
        for (uint256 i = 0; i < pool.allWhitelistedTokensLength(); i++) {
            if (!pool.whitelistedTokens(pool.allWhitelistedTokens(i))) {
                continue;
            }
            bytes32 priceId = pool.getTokenPriceId(pool.allWhitelistedTokens(i));
            if (priceId==symbolId){
                tradeData.volumeA = ILensVault(pool.userVault(vaultId)).getVaultLiquidityTokenVolume(pool.allWhitelistedTokens(i)).utoi();
                tradeData.marginA = ILensVault(pool.userVault(vaultId)).getVaultLiquidityToken(pool.allWhitelistedTokens(i)).utoi();
            }
        }
        if (p.volume!=0){
            liquidationPrice = (p.cost-tradeData.traderMargin+tradeData.marginA)/(p.volume+tradeData.volumeA)*ONE;
            if (liquidationPrice<0){
                liquidationPrice = 0;
            }
        }
        // return (p.cost-tradeData.traderMargin+tradeData.marginA)/(p.volume+tradeData.volumeA)*ONE;
    }

    function getTdInfo(address pool_, address account_) public view returns (TdInfo memory info) {
        ILensPool pool = ILensPool(pool_);
        info.account = account_;
        // info.pTokenId = ILensDToken(pool.pToken()).getTokenIdOf(account_);
            // address[] memory markets = ILensVault(info.vault).getMarketsIn();
            // info.markets = new MarketInfo[](markets.length);
            // for (uint256 i = 0; i < markets.length; i++) {
            //     address vToken = markets[i];
            //     info.markets[i].vToken = vToken;
            //     info.markets[i].vTokenSymbol = ILensVToken(vToken).symbol();
            //     info.markets[i].underlying = vToken != pool.vTokenETH() ? ILensVToken(vToken).underlying() : pool.tokenWETH();
            //     info.markets[i].underlyingSymbol = ILensERC20(info.markets[i].underlying).symbol();
            //     info.markets[i].underlyingPrice = ILensOracle(ILensComptroller(ILensVault(pool.vaultImplementation()).comptroller()).oracle()).getUnderlyingPrice(vToken);
            //     info.markets[i].exchangeRate = ILensVToken(vToken).exchangeRateStored();
            //     info.markets[i].vTokenBalance = ILensVToken(vToken).balanceOf(info.vault);
            // }


        uint256 length = ILensSymbolManager(pool.symbolManager()).getSymbolsLength();
        info.positions = new PositionInfo[](length);
        for (uint256 i = 0; i < length; i++) {
            address symbolAddr = ILensSymbolManager(pool.symbolManager()).indexedSymbols(i);
            ILensSymbol symbol = ILensSymbol(symbolAddr);
            info.positions[i].symbolAddress = symbolAddr;
            info.positions[i].symbol = symbol.symbol();

            bytes32 vaultId = keccak256(abi.encodePacked(account_, info.positions[i].symbol));
            info.positions[i].vault = pool.userVault(vaultId);
            info.positions[i].vaultLiquidity = info.positions[i].vault == address(0) ? 0 : ILensVault(info.positions[i].vault).getVaultLiquidity();
            
            ILensSymbol.Position memory p = symbol.positions(account_);
            info.positions[i].volume = p.volume;
            info.positions[i].cost = p.cost;
            info.positions[i].cumulativeFundingPerVolume = p.cumulativeFundingPerVolume;

            // ILensPool.PoolTdInfo memory tmp = pool.tdInfos(info.pTokenId);

            // int256 K;
            // int256 curVolatility = ILensOracleManager(symbol.oracleManager()).value(symbol.volatilityId()).utoi();
            // int256 liquidity = pool.getLiquidity().utoi() + pool.lpsPnl() + 1;
            // if (symbol.nameId() == keccak256(abi.encodePacked("SymbolImplementationFutures"))){
            //     K = ILensOracleManager(curIndexPrice * symbol.alpha() / liquidity;
            // } else if (symbol.nameId() == keccak256(abi.encodePacked("SymbolImplementationOption"))) {
            //     int256 timeValue;
            //     int256 delta;
            //     (timeValue, delta, ) = symbolsLens.everlastingOptionPricingLens.getEverlastingTimeValueAndDelta(
            //         curIndexPrice, symbol.strikePrice(), curVolatility, symbol.fundingPeriod() * ONE / 31536000
            //     );
            //     int256 intrinsicValue = symbol.isCall() ?
            //                             (curIndexPrice - symbol.strikePrice()).max(0) :
            //                             (symbol.strikePrice() - curIndexPrice).max(0);
            //     K = curIndexPrice ** 2 / (intrinsicValue + timeValue) * delta.abs() * symbol.alpha() / liquidity / ONE;
            // } else if (symbol.nameId() == keccak256(abi.encodePacked("SymbolImplementationPower"))) {
            //     int256 hT = curVolatility ** 2 / ONE * symbol.power().utoi() * (symbol.power().utoi() - 1) / 2 * symbol.fundingPeriod() / 31536000;
            //     int256 powerPrice = _exp(curIndexPrice, symbol.power());
            //     int256 theoreticalPrice = powerPrice * ONE / (ONE - hT);
            //     K = symbol.power().utoi() * theoreticalPrice * symbol.alpha() / liquidity;
            // }

            // int256 tradeCost = DpmmLinearPricing.calculateCost(symbol.indexPrice(), K, symbol.netVolume(), tradeVolume);
            // int256 tradeFee = tradeCost.abs() * symbol.feeRatio() / ONE;
            // int tradeRealizedCost;
            // if (!(p.volume >= 0 && tradeVolume >= 0) && !(p.volume <= 0 && tradeVolume <= 0)) {
            //     int256 absVolume = p.volume.abs();
            //     int256 absTradeVolume = tradeVolume.abs();
            //     if (absVolume <= absTradeVolume) {
            //         tradeRealizedCost = tradeCost * absVolume / absTradeVolume + p.cost;
            //     } else {
            //         tradeRealizedCost = p.cost * absTradeVolume / absVolume + tradeCost;
            //     }
            // }

            int256 diff;
            unchecked { diff = symbol.cumulativeFundingPerVolume() - p.cumulativeFundingPerVolume; }

            int256 curIndexPrice;
            if(symbol.nameId() == keccak256(abi.encodePacked("SymbolImplementationFutures"))){
                curIndexPrice = ILensOracleManager(symbol.oracleManager()).value(symbol.symbolId()).utoi();
            } else {
                // curIndexPrice = ILensOracleManager(symbol.oracleManager()).value(symbol.priceId()).utoi();
                ISymbolsLens.PriceAndVolatility[] memory pvs;
                ISymbolsLens.SymbolInfo memory symbolInfo = symbolsLens.getSymbolInfo(pool_,symbol.symbol(),pvs);
                curIndexPrice = symbolInfo.theoreticalPrice;
            }
            int256 notional = p.volume * curIndexPrice / ONE;

            info.amountB0 = pool.userAmountB0(vaultId);
            int256 traderpnl = notional - p.cost;

            info.positions[i].margin = info.positions[i].vaultLiquidity.utoi() + info.amountB0 + traderpnl;
            info.positions[i].marginUsed = traderpnl < 0 ? traderpnl.abs() : int256(0);
            if (info.positions[i].volume != 0){
                info.positions[i].liquidationPrice = estimateLiquidationPrice(pool_,account_,symbol.symbol(),0);
            }
        }
    }


    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    // function estimateMaxVolume(address pool_, address account_, string memory symbolName, bool isLong) public view returns (int256 maxVolume) {
    //     int256 negative;
    //      if (isLong){
    //         negative = 1;
    //      }else{
    //         negative = -1;
    //      }
    //     bytes32 vaultId = keccak256(abi.encodePacked(account_, symbolName));
    //     ILensSymbolManager manager = ILensSymbolManager(ILensPool(pool_).symbolManager());
    //     ILensSymbol symbol = ILensSymbol(manager.symbols(keccak256(abi.encodePacked(symbolName))));
    //     ILensPool pool = ILensPool(pool_);
    //     ILensSymbol.Position memory p = symbol.positions(account_);
    //     TradeInfo memory tradeInfo;
    //     if(symbol.nameId() == keccak256(abi.encodePacked("SymbolImplementationFutures"))){
    //         tradeInfo.curIndexPrice = ILensOracleManager(symbol.oracleManager()).value(symbol.symbolId()).utoi();
    //     }
    //     else {
    //         tradeInfo.curIndexPrice = ILensOracleManager(symbol.oracleManager()).value(symbol.priceId()).utoi();
    //     }
        
    //     tradeInfo.vaultLiquidity = ILensVault(pool.userVault(vaultId)).getVaultLiquidity().utoi();
    //     if (tradeInfo.vaultLiquidity==0){
    //         return 0;
    //     }
    //     tradeInfo.amountB0 = pool.userAmountB0(vaultId);
    //     tradeInfo.K = tradeInfo.curIndexPrice * symbol.alpha() / (pool.getLiquidity().utoi() + pool.lpsPnl());
    //     tradeInfo.cumulativeFundingPerVolume = symbol.cumulativeFundingPerVolume();
    //     tradeInfo.diff = tradeInfo.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume;
    //     tradeInfo.funding = p.volume * tradeInfo.diff / ONE;
    //     tradeInfo.cost = p.cost;
    //     tradeInfo.volume = p.volume;
    //     tradeInfo.feeRatio = symbol.feeRatio();
    //     tradeInfo.maxLeverage = symbol.maxLeverage();
    //     tradeInfo.netVolume = symbol.netVolume();
    //     tradeInfo.marginUsed = tradeInfo.curIndexPrice*p.volume/ONE-tradeInfo.cost;
    //     if (tradeInfo.marginUsed>0){
    //         tradeInfo.marginUsed = 0;
    //     }
    //     int256 n=1;
    //     if (!isLong){
    //         n = -1;
    //     }
    //     tradeInfo.a = - tradeInfo.maxLeverage*tradeInfo.curIndexPrice/ONE*tradeInfo.K/ONE*(tradeInfo.feeRatio+ONE)/2/ONE;
    //     tradeInfo.b = (-tradeInfo.maxLeverage*tradeInfo.feeRatio/ONE*tradeInfo.curIndexPrice/ONE*(tradeInfo.K*tradeInfo.netVolume*n/ONE+ONE)/ONE-tradeInfo.curIndexPrice*(tradeInfo.maxLeverage*tradeInfo.netVolume*n/ONE*tradeInfo.K/ONE+ONE)/ONE)*negative;
    //     tradeInfo.c = tradeInfo.maxLeverage*(tradeInfo.vaultLiquidity+tradeInfo.amountB0-tradeInfo.funding+tradeInfo.curIndexPrice/ONE*p.volume-p.cost)/ONE - p.volume.abs()*tradeInfo.curIndexPrice/ONE;

    //     int256 b24ac = tradeInfo.b**2-4*tradeInfo.a*tradeInfo.c;
    //     tradeInfo.maxVolume = (-tradeInfo.b-negative*sqrt(b24ac.itou()).utoi())*ONE/(2*tradeInfo.a);
    //     return tradeInfo.maxVolume;
    // }
    function estimateMaxVolume(address pool_, address account_, string memory symbolName, bool isLong) public view returns (int256 maxVolume) {
        bytes32 vaultId = keccak256(abi.encodePacked(account_, symbolName));
        ILensSymbolManager manager = ILensSymbolManager(ILensPool(pool_).symbolManager());
        ILensSymbol symbol = ILensSymbol(manager.symbols(keccak256(abi.encodePacked(symbolName))));
        ILensPool pool = ILensPool(pool_);
        ILensSymbol.Position memory p = symbol.positions(account_);
        TradeInfo memory tradeInfo;
        if(symbol.nameId() == keccak256(abi.encodePacked("SymbolImplementationFutures"))){
            tradeInfo.curIndexPrice = ILensOracleManager(symbol.oracleManager()).value(symbol.symbolId()).utoi();
        }
        else {
            tradeInfo.curIndexPrice = ILensOracleManager(symbol.oracleManager()).value(symbol.priceId()).utoi();
        }
        
        tradeInfo.vaultLiquidity = ILensVault(pool.userVault(vaultId)).getVaultLiquidity().utoi();
        if (tradeInfo.vaultLiquidity==0){
            return 0;
        }
        tradeInfo.amountB0 = pool.userAmountB0(vaultId);
        tradeInfo.cumulativeFundingPerVolume = symbol.cumulativeFundingPerVolume();
        tradeInfo.diff = tradeInfo.cumulativeFundingPerVolume - p.cumulativeFundingPerVolume;
        tradeInfo.funding = p.volume * tradeInfo.diff / ONE;
        tradeInfo.cost = p.cost;
        tradeInfo.volume = p.volume;
        tradeInfo.maxLeverage = symbol.maxLeverage();
        tradeInfo.marginRequiredRatio = symbol.marginRequiredRatio();
        tradeInfo.marginUsed = tradeInfo.curIndexPrice*p.volume/ONE-tradeInfo.cost;
        if (tradeInfo.marginUsed>0){
            tradeInfo.marginUsed = 0;
        }
        tradeInfo.availableMargin = tradeInfo.vaultLiquidity+tradeInfo.amountB0-tradeInfo.funding+tradeInfo.marginUsed;
        tradeInfo.maxVolume = (tradeInfo.availableMargin*tradeInfo.maxLeverage/ONE*tradeInfo.marginRequiredRatio/ONE-tradeInfo.cost)*ONE/tradeInfo.curIndexPrice;
        return tradeInfo.maxVolume;
    }

}