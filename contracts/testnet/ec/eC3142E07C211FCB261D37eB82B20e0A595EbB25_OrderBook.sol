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

import "../token/IERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {

    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ISymbol {

    struct SettlementOnAddLiquidity {
        bool settled;
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
    }

    struct SettlementOnRemoveLiquidity {
        bool settled;
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
        int256 removeLiquidityPenalty;
    }

    struct SettlementOnTraderWithPosition {
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderInitialMarginRequired;
    }

    struct SettlementOnTrade {
        int256 funding;
        int256 deltaTradersPnl;
        // int256 deltaInitialMarginRequired;
        int256 indexPrice;
        int256 traderFunding;
        int256 traderPnl;
        // int256 traderInitialMarginRequired;
        int256 tradeCost;
        int256 tradeFee;
        int256 tradeRealizedCost;
        int256 positionChangeStatus; // 1: new open (enter), -1: total close (exit), 0: others (not change)
        int256 marginRequired;
    }

    struct SettlementOnLiquidate {
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
        int256 indexPrice;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderMaintenanceMarginRequired;
        int256 tradeVolume;
        int256 tradeCost;
        int256 tradeRealizedCost;
        int256 marginRequired;
    }

    struct Position {
        int256 volume;
        int256 cost;
        int256 cumulativeFundingPerVolume;
    }

    function implementation() external view returns (address);

    function symbol() external view returns (string memory);

    function netVolume() external view returns (int256);

    function netCost() external view returns (int256);

    function indexPrice() external view returns (int256);

    function fundingTimestamp() external view returns (uint256);

    function cumulativeFundingPerVolume() external view returns (int256);

    function tradersPnl() external view returns (int256);

    function initialMarginRequired() external view returns (int256);

    function nPositionHolders() external view returns (uint256);

    function positions(uint256 pTokenId) external view returns (Position memory);

    function setImplementation(address newImplementation) external;

    function manager() external view returns (address);

    function oracleManager() external view returns (address);

    function symbolId() external view returns (bytes32);

    function feeRatio() external view returns (int256);             // futures only

    function alpha() external view returns (int256);

    function fundingPeriod() external view returns (int256);

    function minTradeVolume() external view returns (int256);

    function initialMarginRatio() external view returns (int256);

    function maintenanceMarginRatio() external view returns (int256);

    function pricePercentThreshold() external view returns (int256);

    function timeThreshold() external view returns (uint256);

    function isCloseOnly() external view returns (bool);

    function priceId() external view returns (bytes32);              // option only

    function volatilityId() external view returns (bytes32);         // option only

    function feeRatioITM() external view returns (int256);           // option only

    function feeRatioOTM() external view returns (int256);           // option only

    function strikePrice() external view returns (int256);           // option only

    function minInitialMarginRatio() external view returns (int256); // option only

    function isCall() external view returns (bool);                  // option only

    function hasPosition(address pTokenId) external view returns (bool);

    function settleOnAddLiquidity(int256 liquidity)
    external returns (ISymbol.SettlementOnAddLiquidity memory s);

    function settleOnRemoveLiquidity(int256 liquidity, int256 removedLiquidity)
    external returns (ISymbol.SettlementOnRemoveLiquidity memory s);

    function settleOnTraderWithPosition(address pTokenId, int256 liquidity)
    external returns (ISymbol.SettlementOnTraderWithPosition memory s);

    function settleOnTrade(address pTokenId, int256 tradeVolume, int256 liquidity, int256 priceLimit)
    external returns (ISymbol.SettlementOnTrade memory s);

    function settleOnLiquidate(address pTokenId, int256 liquidity)
    external returns (ISymbol.SettlementOnLiquidate memory s);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ISymbolManager {

    struct SettlementOnAddLiquidity {
        int256 funding;
        int256 deltaTradersPnl;
    }

    struct SettlementOnRemoveLiquidity {
        int256 funding;
        int256 deltaTradersPnl;
        int256 initialMarginRequired;
        int256 removeLiquidityPenalty;
    }

    struct SettlementOnRemoveMargin {
        int256 funding;
        int256 deltaTradersPnl;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderInitialMarginRequired;
    }

    struct SettlementOnTrade {
        int256 funding;
        int256 deltaTradersPnl;
        // int256 initialMarginRequired;
        int256 traderFunding;
        int256 traderPnl;
        // int256 traderInitialMarginRequired;
        int256 tradeFee;
        int256 tradeRealizedCost;
        int256 marginRequired;
    }

    struct SettlementOnLiquidate {
        int256 funding;
        int256 deltaTradersPnl;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderMaintenanceMarginRequired;
        int256 traderRealizedCost;
        int256 marginRequired;
    }

    function implementation() external view returns (address);

    function initialMarginRequired() external view returns (int256);

    function pool() external view returns (address);

    function getActiveSymbols(address pTokenId) external view returns (address[] memory);

    function getSymbolsLength() external view returns (uint256);

    function addSymbol(address symbol) external;

    function removeSymbol(bytes32 symbolId) external;

    function symbols(bytes32 symbolId) external view returns (address);

    function settleSymbolsOnAddLiquidity(int256 liquidity)
    external returns (SettlementOnAddLiquidity memory ss);

    function settleSymbolsOnRemoveLiquidity(int256 liquidity, int256 removedLiquidity)
    external returns (SettlementOnRemoveLiquidity memory ss);

    function settleSymbolsOnRemoveMargin(address pTokenId, bytes32 symbolId, int256 liquidity)
    external returns (SettlementOnRemoveMargin memory ss);

    function settleSymbolsOnTrade(address pTokenId, bytes32 symbolId, int256 tradeVolume, int256 liquidity, int256 priceLimit)
    external returns (SettlementOnTrade memory ss);

    function settleSymbolsOnLiquidate(address pTokenId, bytes32 symbolId, int256 liquidity)
    external returns (SettlementOnLiquidate memory ss);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/INameVersion.sol';
import '../utils/IAdmin.sol';

interface IPool is INameVersion, IAdmin {

    function implementation() external view returns (address);

    function protocolFeeCollector() external view returns (address);

    function liquidity() external view returns (int256);

    function lpsPnl() external view returns (int256);

    function cumulativePnlPerLiquidity() external view returns (int256);

    function protocolFeeAccrued() external view returns (int256);

    function setImplementation(address newImplementation) external;

    function addMarket(address token, address market) external;

    function getMarket(address token) external view returns (address);

    function changeSwapper(address swapper) external;

    function approveSwapper(address underlying) external;

    function collectProtocolFee() external;

    function claimVenusLp(address account) external;

    function claimVenusTrader(address account) external;

    struct OracleSignature {
        bytes32 oracleSymbolId;
        uint256 timestamp;
        uint256 value;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function addLiquidity(address underlying, uint256 amount, OracleSignature[] memory oracleSignatures) external returns (uint256);

    function removeLiquidity(address underlying, uint256 amount, OracleSignature[] memory oracleSignatures) external returns (uint256);

    function addMargin(address account, address underlying, string memory symbolName, uint256 amount, OracleSignature[] memory oracleSignatures) external;

    function removeMargin(address account, address underlying, string memory symbolName, uint256 amount, OracleSignature[] memory oracleSignatures) external;

    function trade(address account, string memory symbolName, int256 tradeVolume, int256 priceLimit, OracleSignature[] memory oracleSignatures) external;

    function liquidate(uint256 pTokenId, OracleSignature[] memory oracleSignatures) external;

    function transfer(address account, address underlying, string memory fromSymbolName, string memory toSymbolName, uint256 amount, OracleSignature[] memory oracleSignatures) external;

    function addWhitelistedTokens(address _token) external;
    function removeWhitelistedTokens(address _token) external;
    function allWhitelistedTokens(uint256 index) external view returns (address);
    function allWhitelistedTokensLength() external view returns (uint256);
    function whitelistedTokens(address) external view returns (bool);
    function tokenPriceId(address) external view returns (bytes32);

    function getLiquidity() external view returns (uint256);

    function getTokenPrice(address token) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "../library/SafeMath.sol";
import "../token/IERC20.sol";
import "../library/SafeERC20.sol";
import "../symbol/ISymbolManager.sol";
import "../symbol/ISymbol.sol";
import "../pool/IPool.sol";
import "../lens/SymbolsLens.sol";

// import "../libraries/utils/ReentrancyGuard.sol";

// import "./interfaces/IRouter.sol";
// import "./interfaces/IVault.sol";
// import "./interfaces/IOrderBook.sol";

contract OrderBook {
    using SafeMath for uint256;
    using SafeMath for int256;
    using SafeERC20 for IERC20;
    // using Address for address payable;

    bool internal _mutex;

    modifier _reentryLock_() {
        require(!_mutex, 'Pool: reentry');
        _mutex = true;
        _;
        _mutex = false;
    }

    uint256 public constant PRICE_PRECISION = 1e18;
    uint256 public constant USDA_PRECISION = 1e18;

    //string memory symbolName,
    // int256 tradeVolume,
    // uint256 _triggerPrice,
    // bool _triggerAboveThreshold
    struct TradeOrder {
        address account;
        string symbolName;
        int256 tradeVolume;
        uint256 triggerPrice;
        bool triggerAboveThreshold;
        uint256 executionFee;
        int256 priceLimit;
    }

    event CreateTradeOrder(
        address indexed account,
        uint256 orderIndex,
        string symbolName,
        int256 tradeVolume,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        int256 priceLimit
    );

    event UpdateTradeOrder(
        address indexed account,
        uint256 orderIndex,
        string symbolName,
        int256 tradeVolume,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        int256 priceLimit
    );

    event CancelTradeOrder(
        address indexed account,
        uint256 orderIndex,
        string symbolName,
        int256 tradeVolume,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        int256 priceLimit
    );

    event ExecuteTradeOrder(
        address indexed account,
        uint256 orderIndex,
        string symbolName,
        int256 tradeVolume,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        uint256 curentPrice
    );




    mapping (address => mapping(uint256 => TradeOrder)) public tradeOrders;
    mapping (address => uint256) public tradeOrdersIndex;

    address public gov;
    address public pool;
    address public symbolManager;
    uint256 public minExecutionFee;

    ISymbolsLens immutable symbolsLens;

    event UpdateMinExecutionFee(uint256 minExecutionFee);
    event UpdateGov(address gov);

    modifier onlyGov() {
        require(msg.sender == gov, "OrderBook: forbidden");
        _;
    }

    constructor(
        address _pool,
        address _symbolManager,
        uint256 _minExecutionFee,
        address _symbolLens
    ) {
        gov = msg.sender;
        minExecutionFee = _minExecutionFee;
        symbolManager = _symbolManager;
        pool = _pool;
        // symbolLens = _symbolLens;
        symbolsLens = ISymbolsLens(_symbolLens);
    }

    // receive() external payable {
    //     require(msg.sender == weth, "OrderBook: invalid sender");
    // }
    

    function setMinExecutionFee(uint256 _minExecutionFee) external onlyGov {
        minExecutionFee = _minExecutionFee;

        emit UpdateMinExecutionFee(_minExecutionFee);
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;

        emit UpdateGov(_gov);
    }

    function cancelMultiple(
        uint256[] memory _tradeOrderIndexes
    ) external {
        for (uint256 i = 0; i < _tradeOrderIndexes.length; i++) {
            cancelTradeOrder(_tradeOrderIndexes[i]);
        }
    }
    
    function validatePositionOrderPrice(
        string memory symbol,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        bool _raise
    ) public view returns (uint256, bool) {
        // uint256 UMAX = 2 ** 255 - 1;
        uint256 currentPrice;
        // if(_triggerAboveThreshold) {
        //     return (0, true);
        // }
        // return (UMAX, true);
        ISymbolsLens.PriceAndVolatility[] memory pvs;
        ISymbolsLens.SymbolInfo memory info = symbolsLens.getSymbolInfo(pool, symbol, pvs);
        string memory futures = "futures";
        if (keccak256(abi.encodePacked(info.category)) == keccak256(abi.encodePacked(futures))) {
            currentPrice = info.curIndexPrice.itou();
        } else {
            currentPrice = info.theoreticalPrice.itou();
        }
        // uint256 currentPrice = IVault(vault).getMarketPrice(_indexToken, _sizeDelta, _maximizePrice);
        bool isPriceValid = _triggerAboveThreshold ? currentPrice > _triggerPrice : currentPrice < _triggerPrice;
        if (_raise) {
            require(isPriceValid, "OrderBook: invalid price for execution");
        }
        return (currentPrice, isPriceValid);
    }

    function createTradeOrder(
        string memory _symbolName,
        int256 _tradeVolume,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        int256 _priceLimit
    ) external payable _reentryLock_ {
        // always need this call because of mandatory executionFee user has to transfer in ETH
        // msg.value is execution fee
        require(msg.value >= minExecutionFee, "OrderBook: insufficient execution fee");
        bytes32 symbolId = keccak256(abi.encodePacked(_symbolName));
        address symbol = ISymbolManager(symbolManager).symbols(symbolId);
        require(symbol != address(0), 'OrderBook.createTradeOrder: invalid trade symbol');
        int256 minTradeVolume = ISymbol(symbol).minTradeVolume();
        require(
            _tradeVolume != 0 && _tradeVolume % minTradeVolume == 0,
            'OrderBook.createTradeOrder: invalid tradeVolume'
        );

        _createTradeOrder(
            msg.sender,
            _symbolName,
            _tradeVolume,
            _triggerPrice,
            _triggerAboveThreshold,
            _priceLimit,
            msg.value
        );
    }

    function _createTradeOrder(
        address _account,
        string memory _symbolName,
        int256 _tradeVolume,
        uint256 _triggerPrice,
        bool _triggerAboveThreshold,
        int256 _priceLimit,
        uint256 _executionFee
    ) private {
        uint256 _orderIndex = tradeOrdersIndex[_account];
        TradeOrder memory order = TradeOrder(
            _account,
            _symbolName,
            _tradeVolume,
            _triggerPrice,
            _triggerAboveThreshold,
            _executionFee,
            _priceLimit
        );
        tradeOrdersIndex[_account] = _orderIndex + 1;
        tradeOrders[_account][_orderIndex] = order;

        emit CreateTradeOrder(
            _account,
            _orderIndex,
            _symbolName,
            _tradeVolume,
            _triggerPrice,
            _triggerAboveThreshold,
            _executionFee,
            _priceLimit
        );
    }

    function getTradeOrder(address _account, uint256 _orderIndex) public view returns (
        string memory symbolName,
        int256 tradeVolume,
        uint256 triggerPrice,
        bool triggerAboveThreshold,
        uint256 executionFee,
        int256 priceLimit
    ) {
        TradeOrder memory order = tradeOrders[_account][_orderIndex];
        return (
            order.symbolName,
            order.tradeVolume,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee,
            order.priceLimit
        );
    }

    function updateTradeOrder(uint256 _orderIndex, int256 _tradeVolume, uint256 _triggerPrice, bool _triggerAboveThreshold, int256 _priceLimit) external  {
        TradeOrder storage order = tradeOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        order.triggerPrice = _triggerPrice;
        order.triggerAboveThreshold = _triggerAboveThreshold;
        order.tradeVolume = _tradeVolume;
        order.priceLimit = _priceLimit;

        emit UpdateTradeOrder(
            msg.sender,
            _orderIndex,
            order.symbolName,
            _tradeVolume,
            _triggerPrice,
            _triggerAboveThreshold,
            _priceLimit
        );
    }


    function cancelTradeOrder(uint256 _orderIndex) public _reentryLock_ {
        TradeOrder memory order = tradeOrders[msg.sender][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        delete tradeOrders[msg.sender][_orderIndex];

        // if (order.purchaseToken == weth) {
        //     _transferOutETH(order.executionFee.add(order.purchaseTokenAmount), msg.sender);
        // } else {
            // IERC20(order.purchaseToken).safeTransfer(msg.sender, order.purchaseTokenAmount);
            // _transferOutETH(order.executionFee, msg.sender);
        // }

        _transferOutETH(order.executionFee, payable(msg.sender));

        emit CancelTradeOrder(
            order.account,
            _orderIndex,
            order.symbolName,
            order.tradeVolume,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee,
            order.priceLimit
        );
    }


    function executeTradeOrder(address _address, uint256 _orderIndex, address payable _feeReceiver) external _reentryLock_ {
        TradeOrder memory order = tradeOrders[_address][_orderIndex];
        require(order.account != address(0), "OrderBook: non-existent order");

        // increase long should use max price
        // increase short should use min price
        (uint256 currentPrice, ) = validatePositionOrderPrice(
            order.symbolName,
            order.triggerPrice,
            order.triggerAboveThreshold,
            true
        );

        delete tradeOrders[_address][_orderIndex];
        IPool.OracleSignature[] memory oracleSignatures;
        IPool(pool).trade(order.account, order.symbolName, order.tradeVolume, order.priceLimit, oracleSignatures);

        // IERC20(order.purchaseToken).safeTransfer(vault, order.purchaseTokenAmount);

        // if (order.purchaseToken != order.collateralToken) {
        //     address[] memory path = new address[](2);
        //     path[0] = order.purchaseToken;
        //     path[1] = order.collateralToken;

        //     uint256 amountOut = _swap(path, 0, address(this));
        //     IERC20(order.collateralToken).safeTransfer(vault, amountOut);
        // }

        // IRouter(router).pluginIncreasePosition(order.account, order.collateralToken, order.indexToken, order.sizeDelta, order.isLong);

        // pay executor
        _transferOutETH(order.executionFee, _feeReceiver);

        emit ExecuteTradeOrder(
            order.account,
            _orderIndex,
            order.symbolName,
            order.tradeVolume,
            order.triggerPrice,
            order.triggerAboveThreshold,
            order.executionFee,
            currentPrice
        );
    }

    // function _transferInETH() private {
    //     if (msg.value != 0) {
    //         IWETH(weth).deposit{value: msg.value}();
    //     }
    // }

    function _transferOutETH(uint256 _amountOut, address payable _receiver) private {
        // IWETH(weth).withdraw(_amountOut);

        (bool success, ) = _receiver.call{value: _amountOut}('');
        require(success, 'OrderBook.transfer: send ETH fail');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}