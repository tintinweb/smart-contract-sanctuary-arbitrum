// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { SignedSafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import { FullMath } from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import { ClearingHouseCallee } from "./base/ClearingHouseCallee.sol";
import { PerpSafeCast } from "./lib/PerpSafeCast.sol";
import { PerpMath } from "./lib/PerpMath.sol";
import { IVault } from "./interface/IVault.sol";
import { IVPool } from "./interface/IVPool.sol";
import { IBaseToken } from "./interface/IBaseToken.sol";
import { IIndexPrice } from "./interface/IIndexPrice.sol";
import { IClearingHouseConfig } from "./interface/IClearingHouseConfig.sol";
import { AccountBalanceStorageV1 } from "./storage/AccountBalanceStorage.sol";
import { BlockContext } from "./base/BlockContext.sol";
import { IAccountBalance } from "./interface/IAccountBalance.sol";
import { DataTypes } from "./types/DataTypes.sol";

// never inherit any new stateful contract. never change the orders of parent stateful contracts
contract AccountBalance is IAccountBalance, BlockContext, ClearingHouseCallee, AccountBalanceStorageV1 {
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;
    using PerpSafeCast for uint256;
    using PerpSafeCast for int256;
    using PerpMath for uint256;
    using PerpMath for int256;
    using PerpMath for uint160;

    //
    // CONSTANT
    //

    uint256 internal constant _DUST = 10 wei;
    uint256 internal constant _MIN_PARTIAL_LIQUIDATE_POSITION_VALUE = 100e18 wei; // 100 USD in decimal 18

    //
    // EXTERNAL NON-VIEW
    //

    function initialize(address clearingHouseConfigArg) external initializer {
        // IClearingHouseConfig address is not contract
        require(clearingHouseConfigArg.isContract(), "AB_CHCNC");

        __ClearingHouseCallee_init();

        _clearingHouseConfig = clearingHouseConfigArg;
    }

    function setVault(address vaultArg) external onlyOwner {
        // vault address is not contract
        require(vaultArg.isContract(), "AB_VNC");
        _vault = vaultArg;
        emit VaultChanged(vaultArg);
    }

    function modifyMarketMultiplier(address baseToken, uint256 longRate, uint256 shortRate) external override {
        _requireOnlyClearingHouse();
        if (_marketMap[baseToken].longMultiplierX10_18 == 0) {
            _marketMap[baseToken].longMultiplierX10_18 = 1e18;
        }
        if (_marketMap[baseToken].shortMultiplierX10_18 == 0) {
            _marketMap[baseToken].shortMultiplierX10_18 = 1e18;
        }
        if (longRate != 1e18) {
            _marketMap[baseToken].longMultiplierX10_18 = _marketMap[baseToken].longMultiplierX10_18.mulMultiplier(
                longRate
            );
        }
        if (shortRate != 1e18) {
            _marketMap[baseToken].shortMultiplierX10_18 = _marketMap[baseToken].shortMultiplierX10_18.mulMultiplier(
                shortRate
            );
        }

        emit MultiplierChanged(_marketMap[baseToken].longMultiplierX10_18, _marketMap[baseToken].shortMultiplierX10_18);
    }

    /// @inheritdoc IAccountBalance
    function modifyTakerBalance(
        address trader,
        address baseToken,
        int256 base,
        int256 quote
    ) external override returns (int256, int256) {
        _requireOnlyClearingHouse();
        return _modifyTakerBalance(trader, baseToken, base, quote);
    }

    /// @inheritdoc IAccountBalance
    function modifyOwedRealizedPnl(address trader, int256 amount) external override {
        _requireOnlyClearingHouse();
        _modifyOwedRealizedPnl(trader, amount);
    }

    /// @inheritdoc IAccountBalance
    function settleQuoteToOwedRealizedPnl(address trader, address baseToken, int256 amount) external override {
        _requireOnlyClearingHouse();
        _settleQuoteToOwedRealizedPnl(trader, baseToken, amount);
    }

    /// @inheritdoc IAccountBalance
    function settleOwedRealizedPnl(address trader) external override returns (int256) {
        // only vault
        require(_msgSender() == _vault, "AB_OV");
        int256 owedRealizedPnl = _owedRealizedPnlMap[trader];
        _owedRealizedPnlMap[trader] = 0;

        return owedRealizedPnl;
    }

    /// @inheritdoc IAccountBalance
    function settleBalanceAndDeregister(
        address trader,
        address baseToken,
        int256 takerBase,
        int256 takerQuote,
        int256 realizedPnl,
        int256 makerFee
    ) external override {
        _requireOnlyClearingHouse();
        _modifyTakerBalance(trader, baseToken, takerBase, takerQuote);
        _modifyOwedRealizedPnl(trader, makerFee);

        // @audit should merge _addOwedRealizedPnl and settleQuoteToOwedRealizedPnl in some way.
        // PnlRealized will be emitted three times when removing trader's liquidity
        _settleQuoteToOwedRealizedPnl(trader, baseToken, realizedPnl);
        _deregisterBaseToken(trader, baseToken);
    }

    /// @inheritdoc IAccountBalance
    function registerBaseToken(address trader, address baseToken) external override {
        _requireOnlyClearingHouse();
        address[] storage tokensStorage = _baseTokensMap[trader];
        if (_hasBaseToken(tokensStorage, baseToken)) {
            return;
        }

        tokensStorage.push(baseToken);
        // AB_MNE: markets number exceeds
        require(tokensStorage.length <= IClearingHouseConfig(_clearingHouseConfig).getMaxMarketsPerAccount(), "AB_MNE");
    }

    /// @inheritdoc IAccountBalance
    function deregisterBaseToken(address trader, address baseToken) external override {
        _requireOnlyClearingHouse();
        _deregisterBaseToken(trader, baseToken);
    }

    /// @inheritdoc IAccountBalance
    function updateTwPremiumGrowthGlobal(
        address trader,
        address baseToken,
        int256 lastLongTwPremiumGrowthGlobalX96,
        int256 lastShortTwPremiumGrowthGlobalX96
    ) external override {
        _requireOnlyClearingHouse();
        _accountMarketMap[trader][baseToken].lastLongTwPremiumGrowthGlobalX96 = lastLongTwPremiumGrowthGlobalX96;
        _accountMarketMap[trader][baseToken].lastShortTwPremiumGrowthGlobalX96 = lastShortTwPremiumGrowthGlobalX96;
    }

    /// @inheritdoc IAccountBalance
    /// @dev we don't do swap to get position notional here.
    ///      we define the position notional in a closed market is `closed price * position size`
    function settlePositionInClosedMarket(
        address trader,
        address baseToken
    )
        external
        override
        returns (int256 positionNotional, int256 openNotional, int256 realizedPnl, uint256 closedPrice)
    {
        _requireOnlyClearingHouse();

        int256 positionSize = getTakerPositionSize(trader, baseToken);

        closedPrice = IBaseToken(baseToken).getClosedPrice();
        positionNotional = positionSize.mulDiv(closedPrice.toInt256(), 1e18);
        openNotional = _accountMarketMap[trader][baseToken].takerOpenNotional;
        realizedPnl = positionNotional.add(openNotional);

        _deleteBaseToken(trader, baseToken);
        _modifyOwedRealizedPnl(trader, realizedPnl);

        return (positionNotional, openNotional, realizedPnl, closedPrice);
    }

    //
    // EXTERNAL VIEW
    //

    /// @inheritdoc IAccountBalance
    function getClearingHouseConfig() external view override returns (address) {
        return _clearingHouseConfig;
    }

    /// @inheritdoc IAccountBalance
    function getVault() external view override returns (address) {
        return _vault;
    }

    /// @inheritdoc IAccountBalance
    function getBaseTokens(address trader) external view override returns (address[] memory) {
        return _baseTokensMap[trader];
    }

    /// @inheritdoc IAccountBalance
    function getAccountInfo(
        address trader,
        address baseToken
    ) external view override returns (DataTypes.AccountMarketInfo memory) {
        return _accountMarketMap[trader][baseToken];
    }

    // @inheritdoc IAccountBalance
    function getTakerOpenNotional(address trader, address baseToken) external view override returns (int256) {
        return _accountMarketMap[trader][baseToken].takerOpenNotional;
    }

    // @inheritdoc IAccountBalance
    function getTotalOpenNotional(address trader, address baseToken) external view override returns (int256) {
        return getQuote(trader, baseToken);
    }

    /// @inheritdoc IAccountBalance
    // function getTotalDebtValue(address trader) external view override returns (uint256) {
    //     int256 totalQuoteBalance;
    //     int256 totalBaseDebtValue;
    //     uint256 tokenLen = _baseTokensMap[trader].length;
    //     for (uint256 i = 0; i < tokenLen; i++) {
    //         address baseToken = _baseTokensMap[trader][i];
    //         int256 baseBalance = getBase(trader, baseToken);
    //         int256 baseDebtValue;
    //         // baseDebt = baseBalance when it's negative
    //         if (baseBalance < 0) {
    //             // baseDebtValue = baseDebt * indexPrice
    //             baseDebtValue = baseBalance.mulDiv(_getReferencePrice(baseToken).toInt256(), 1e18);
    //         }
    //         totalBaseDebtValue = totalBaseDebtValue.add(baseDebtValue);

    //         // we can't calculate totalQuoteDebtValue until we have totalQuoteBalance
    //         totalQuoteBalance = totalQuoteBalance.add(getQuote(trader, baseToken));
    //     }
    //     int256 totalQuoteDebtValue = totalQuoteBalance >= 0 ? 0 : totalQuoteBalance;

    //     // both values are negative due to the above condition checks
    //     return totalQuoteDebtValue.add(totalBaseDebtValue).abs();
    // }

    /// @inheritdoc IAccountBalance
    function getPnlAndPendingFee(address trader) external view override returns (int256, int256, uint256) {
        int256 totalPositionValue;
        uint256 tokenLen = _baseTokensMap[trader].length;
        for (uint256 i = 0; i < tokenLen; i++) {
            address baseToken = _baseTokensMap[trader][i];
            totalPositionValue = totalPositionValue.add(getTotalPositionValue(trader, baseToken));
        }
        (int256 netQuoteBalance, uint256 pendingFee) = _getNetQuoteBalanceAndPendingFee(trader);
        int256 unrealizedPnl = totalPositionValue.add(netQuoteBalance);

        return (_owedRealizedPnlMap[trader], unrealizedPnl, pendingFee);
    }

    /// @inheritdoc IAccountBalance
    function getLiquidatablePositionSize(
        address trader,
        address baseToken,
        int256 accountValue
    ) external view override returns (int256) {
        int256 marginRequirement = getMarginRequirementForLiquidation(trader);
        int256 positionSize = getTotalPositionSize(trader, baseToken);

        // No liquidatable position
        if (accountValue >= marginRequirement || positionSize == 0) {
            return 0;
        }

        // Liquidate the entire position if its value is small enough
        // to prevent tiny positions left in the system
        uint256 positionValueAbs = _getPositionValue(baseToken, positionSize).abs();
        if (positionValueAbs <= _MIN_PARTIAL_LIQUIDATE_POSITION_VALUE) {
            return positionSize;
        }

        // https://www.notion.so/perp/Backstop-LP-Spec-614b42798d4943768c2837bfe659524d#968996cadaec4c00ac60bd1da02ea8bb
        // Liquidator can only take over partial position if margin ratio is ≥ 3.125% (aka the half of mmRatio).
        // If margin ratio < 3.125%, liquidator can take over the entire position.
        //
        // threshold = mmRatio / 2 = 3.125%
        // if marginRatio >= threshold, then
        //    maxLiquidateRatio = MIN(1, 0.5 * totalAbsPositionValue / absPositionValue)
        // if marginRatio < threshold, then
        //    maxLiquidateRatio = 1
        uint24 maxLiquidateRatio = 1e6; // 100%
        if (accountValue >= marginRequirement.div(2)) {
            // maxLiquidateRatio = getTotalAbsPositionValue / ( getTotalPositionValueInMarket.abs * 2 )
            maxLiquidateRatio = FullMath
                .mulDiv(getTotalAbsPositionValue(trader), 1e6, positionValueAbs.mul(2))
                .toUint24();
            if (maxLiquidateRatio > 1e6) {
                maxLiquidateRatio = 1e6;
            }
        }

        return positionSize.mulRatio(maxLiquidateRatio);
    }

    //
    // PUBLIC VIEW
    //

    function getOriginBase(address trader, address baseToken) public view override returns (int256) {
        return _accountMarketMap[trader][baseToken].takerPositionSize;
    }

    /// @inheritdoc IAccountBalance
    function getBase(address trader, address baseToken) public view override returns (int256) {
        int256 base = getOriginBase(trader, baseToken);
        (uint256 longMultiplier, uint256 shortMultiplier) = _getMarketMultiplier(baseToken);
        return base > 0 ? base.mulMultiplier(longMultiplier) : base.mulMultiplier(shortMultiplier);
    }

    /// @inheritdoc IAccountBalance
    function getQuote(address trader, address baseToken) public view override returns (int256) {
        return _accountMarketMap[trader][baseToken].takerOpenNotional;
    }

    function getOriginTakerPositionSize(address trader, address baseToken) public view returns (int256) {
        int256 positionSize = _accountMarketMap[trader][baseToken].takerPositionSize;
        return positionSize.abs() < _DUST ? 0 : positionSize;
    }

    /// @inheritdoc IAccountBalance
    function getTakerPositionSize(address trader, address baseToken) public view override returns (int256) {
        int256 positionSize = getOriginTakerPositionSize(trader, baseToken);
        (uint256 longMultiplier, uint256 shortMultiplier) = _getMarketMultiplier(baseToken);
        return
            positionSize > 0 ? positionSize.mulMultiplier(longMultiplier) : positionSize.mulMultiplier(shortMultiplier);
    }

    function getOriginTotalPositionSize(address trader, address baseToken) public view returns (int256) {
        // NOTE: when a token goes into UniswapV3 pool (addLiquidity or swap), there would be 1 wei rounding error
        // for instance, maker adds liquidity with 2 base (2000000000000000000),
        // the actual base amount in pool would be 1999999999999999999
        int256 takerPositionSize = _accountMarketMap[trader][baseToken].takerPositionSize;
        int256 totalPositionSize = takerPositionSize;
        return totalPositionSize.abs() < _DUST ? 0 : totalPositionSize;
    }

    /// @inheritdoc IAccountBalance
    function getTotalPositionSize(address trader, address baseToken) public view override returns (int256) {
        int256 totalPositionSize = getOriginTotalPositionSize(trader, baseToken);
        (uint256 longMultiplier, uint256 shortMultiplier) = _getMarketMultiplier(baseToken);
        return
            totalPositionSize > 0
                ? totalPositionSize.mulMultiplier(longMultiplier)
                : totalPositionSize.mulMultiplier(shortMultiplier);
    }

    /// @inheritdoc IAccountBalance
    function getTotalPositionValue(address trader, address baseToken) public view override returns (int256) {
        int256 positionSize = getTotalPositionSize(trader, baseToken);
        return _getPositionValue(baseToken, positionSize);
    }

    /// @inheritdoc IAccountBalance
    function getTotalAbsPositionValue(address trader) public view override returns (uint256) {
        address[] memory tokens = _baseTokensMap[trader];
        uint256 totalPositionValue;
        uint256 tokenLen = tokens.length;
        for (uint256 i = 0; i < tokenLen; i++) {
            address baseToken = tokens[i];
            // will not use negative value in this case
            uint256 positionValue = getTotalPositionValue(trader, baseToken).abs();
            totalPositionValue = totalPositionValue.add(positionValue);
        }
        return totalPositionValue;
    }

    /// @inheritdoc IAccountBalance
    function getMarginRequirementForLiquidation(address trader) public view override returns (int256) {
        return
            getTotalAbsPositionValue(trader)
                .mulRatio(IClearingHouseConfig(_clearingHouseConfig).getMmRatio())
                .toInt256();
    }

    function getOriginMarketPositionSize(address baseToken) public view returns (uint256, uint256) {
        return (_marketMap[baseToken].longPositionSize, _marketMap[baseToken].shortPositionSize);
    }

    /// @inheritdoc IAccountBalance
    function getMarketPositionSize(address baseToken) public view override returns (uint256, uint256) {
        (uint256 longMultiplier, uint256 shortMultiplier) = _getMarketMultiplier(baseToken);
        return (
            _marketMap[baseToken].longPositionSize.mulMultiplier(longMultiplier),
            _marketMap[baseToken].shortPositionSize.mulMultiplier(shortMultiplier)
        );
    }

    function getMarketMultiplier(
        address baseToken
    ) external view override returns (uint256 longMultiplier, uint256 shortMultiplier) {
        return _getMarketMultiplier(baseToken);
    }

    function _getMarketMultiplier(
        address baseToken
    ) internal view returns (uint256 longMultiplier, uint256 shortMultiplier) {
        longMultiplier = _marketMap[baseToken].longMultiplierX10_18;
        if (longMultiplier == 0) {
            longMultiplier = 1e18;
        }
        shortMultiplier = _marketMap[baseToken].shortMultiplierX10_18;
        if (shortMultiplier == 0) {
            shortMultiplier = 1e18;
        }
    }

    //
    // INTERNAL NON-VIEW
    //
    function getModifyBaseForMultiplier(
        address trader,
        address baseToken,
        int256 baseAfterMultiplier
    ) public view returns (int256 base) {
        DataTypes.AccountMarketInfo storage accountInfo = _accountMarketMap[trader][baseToken];
        // update for multiplier
        {
            (uint256 longMultiplier, uint256 shortMultiplier) = _getMarketMultiplier(baseToken);
            if (longMultiplier == 1e18 && shortMultiplier == 1e18) {
                return baseAfterMultiplier;
            }
            if (accountInfo.takerPositionSize > 0) {
                // in long
                if (baseAfterMultiplier > 0) {
                    base = baseAfterMultiplier.divMultiplier(longMultiplier);
                } else {
                    if (
                        accountInfo.takerPositionSize.abs() >= baseAfterMultiplier.divMultiplier(longMultiplier).abs()
                    ) {
                        base = baseAfterMultiplier.divMultiplier(longMultiplier);
                    } else {
                        int256 rangeBase = accountInfo.takerPositionSize.neg256();
                        base = rangeBase.add(
                            baseAfterMultiplier.sub(rangeBase.mulMultiplier(longMultiplier)).divMultiplier(
                                shortMultiplier
                            )
                        );
                    }
                }
            } else if (accountInfo.takerPositionSize == 0) {
                // in none
                if (baseAfterMultiplier > 0) {
                    base = baseAfterMultiplier.divMultiplier(longMultiplier);
                } else {
                    base = baseAfterMultiplier.divMultiplier(shortMultiplier);
                }
            } else {
                // in short
                if (baseAfterMultiplier < 0) {
                    base = baseAfterMultiplier.divMultiplier(shortMultiplier);
                } else {
                    if (
                        accountInfo.takerPositionSize.abs() >= baseAfterMultiplier.divMultiplier(shortMultiplier).abs()
                    ) {
                        base = baseAfterMultiplier.divMultiplier(shortMultiplier);
                    } else {
                        int256 rangeBase = accountInfo.takerPositionSize.neg256();
                        base = rangeBase.add(
                            baseAfterMultiplier.sub(rangeBase.mulMultiplier(shortMultiplier)).divMultiplier(
                                longMultiplier
                            )
                        );
                    }
                }
            }
        }
    }

    function _modifyTakerBalance(
        address trader,
        address baseToken,
        int256 baseAfterMultiplier,
        int256 quote
    ) internal returns (int256, int256) {
        // for multiplier
        int256 base = getModifyBaseForMultiplier(trader, baseToken, baseAfterMultiplier);
        //
        DataTypes.AccountMarketInfo storage accountInfo = _accountMarketMap[trader][baseToken];
        int256 oldPos = accountInfo.takerPositionSize;
        accountInfo.takerPositionSize = accountInfo.takerPositionSize.add(base);
        accountInfo.takerOpenNotional = accountInfo.takerOpenNotional.add(quote);
        if (oldPos >= 0 && base >= 0) {
            //long
            _marketMap[baseToken].longPositionSize += base.abs();
        } else if (oldPos <= 0 && base <= 0) {
            //short
            _marketMap[baseToken].shortPositionSize += base.abs();
        } else if (oldPos >= 0 && base <= 0) {
            //long => short
            if (accountInfo.takerPositionSize >= 0) {
                //new short <= old long
                _marketMap[baseToken].longPositionSize = _marketMap[baseToken].longPositionSize > base.abs()
                    ? _marketMap[baseToken].longPositionSize - base.abs()
                    : 0;
            } else {
                //new short > old long
                _marketMap[baseToken].longPositionSize = _marketMap[baseToken].longPositionSize > oldPos.abs()
                    ? _marketMap[baseToken].longPositionSize - oldPos.abs()
                    : 0;

                _marketMap[baseToken].shortPositionSize += accountInfo.takerPositionSize.abs();
            }
        } else {
            //short => long
            if (accountInfo.takerPositionSize <= 0) {
                //new long <= old short
                _marketMap[baseToken].shortPositionSize = _marketMap[baseToken].shortPositionSize > base.abs()
                    ? _marketMap[baseToken].shortPositionSize - base.abs()
                    : 0;
            } else {
                //new long > old short
                _marketMap[baseToken].shortPositionSize = _marketMap[baseToken].shortPositionSize > oldPos.abs()
                    ? _marketMap[baseToken].shortPositionSize - oldPos.abs()
                    : 0;
                _marketMap[baseToken].longPositionSize += accountInfo.takerPositionSize.abs();
            }
        }

        // _resetMultiplier(baseToken);

        return (accountInfo.takerPositionSize, accountInfo.takerOpenNotional);
    }

    // function _resetMultiplier(address baseToken) internal {
    //     if (_marketMap[baseToken].shortPositionSize == 0 && _marketMap[baseToken].longPositionSize == 0) {
    //         _marketMap[baseToken].longMultiplierX10_18 = 1e18;
    //         _marketMap[baseToken].shortMultiplierX10_18 = 1e18;
    //         emit MultiplierChanged(
    //             _marketMap[baseToken].longMultiplierX10_18,
    //             _marketMap[baseToken].shortMultiplierX10_18
    //         );
    //     }
    // }

    function _modifyOwedRealizedPnl(address trader, int256 amount) internal {
        if (amount != 0) {
            _owedRealizedPnlMap[trader] = _owedRealizedPnlMap[trader].add(amount);
            emit PnlRealized(trader, amount);
        }
    }

    function _settleQuoteToOwedRealizedPnl(address trader, address baseToken, int256 amount) internal {
        if (amount != 0) {
            DataTypes.AccountMarketInfo storage accountInfo = _accountMarketMap[trader][baseToken];
            accountInfo.takerOpenNotional = accountInfo.takerOpenNotional.sub(amount);
            _modifyOwedRealizedPnl(trader, amount);
        }
    }

    /// @dev this function is expensive
    function _deregisterBaseToken(address trader, address baseToken) internal {
        DataTypes.AccountMarketInfo memory info = _accountMarketMap[trader][baseToken];
        if (info.takerPositionSize.abs() >= _DUST || info.takerOpenNotional.abs() >= _DUST) {
            return;
        }
        _deleteBaseToken(trader, baseToken);
    }

    function _deleteBaseToken(address trader, address baseToken) internal {
        DataTypes.AccountMarketInfo memory info = _accountMarketMap[trader][baseToken];
        if (info.takerPositionSize.abs() > 0 && info.takerPositionSize.abs() < _DUST) {
            if (info.takerPositionSize < 0) {
                //update total short
                _marketMap[baseToken].shortPositionSize = _marketMap[baseToken].shortPositionSize >
                    info.takerPositionSize.abs()
                    ? _marketMap[baseToken].shortPositionSize - info.takerPositionSize.abs()
                    : 0;
            } else {
                //update total long
                _marketMap[baseToken].longPositionSize = _marketMap[baseToken].longPositionSize >
                    info.takerPositionSize.abs()
                    ? _marketMap[baseToken].longPositionSize - info.takerPositionSize.abs()
                    : 0;
            }
            // _resetMultiplier(baseToken);
        }
        delete _accountMarketMap[trader][baseToken];

        address[] storage tokensStorage = _baseTokensMap[trader];
        uint256 tokenLen = tokensStorage.length;
        for (uint256 i; i < tokenLen; i++) {
            if (tokensStorage[i] == baseToken) {
                // if the target to be removed is the last one, pop it directly;
                // else, replace it with the last one and pop the last one instead
                if (i != tokenLen - 1) {
                    tokensStorage[i] = tokensStorage[tokenLen - 1];
                }
                tokensStorage.pop();
                break;
            }
        }
    }

    //
    // INTERNAL VIEW
    //

    function _getPositionValue(address baseToken, int256 positionSize) internal view returns (int256) {
        if (positionSize == 0) return 0;

        uint256 markTwap = _getReferencePrice(baseToken); // pnft use mark price
        // uint256 indexTwap = _getReferencePrice(baseToken);
        // both positionSize & indexTwap are in 10^18 already
        // overflow inspection:
        // only overflow when position value in USD(18 decimals) > 2^255 / 10^18
        return positionSize.mulDiv(markTwap.toInt256(), 1e18);
    }

    // function _getReferencePrice(address baseToken) internal view returns (uint256) {
    //     return
    //         IBaseToken(baseToken).isClosed()
    //             ? IBaseToken(baseToken).getClosedPrice()
    //             : IIndexPrice(baseToken).getIndexPrice(IClearingHouseConfig(_clearingHouseConfig).getTwapInterval());
    // }

    function _getReferencePrice(address baseToken) internal view returns (uint256) {
        return
            IVPool(IVault(_vault).getVPool())
                .getSqrtMarkTwapX96(baseToken, IClearingHouseConfig(_clearingHouseConfig).getTwapInterval())
                .formatSqrtPriceX96ToPriceX96()
                .formatX96ToX10_18();
    }

    /// @return netQuoteBalance = quote.balance + totalQuoteInPools
    function _getNetQuoteBalanceAndPendingFee(
        address trader
    ) internal view returns (int256 netQuoteBalance, uint256 pendingFee) {
        int256 totalTakerQuoteBalance;
        uint256 tokenLen = _baseTokensMap[trader].length;
        for (uint256 i = 0; i < tokenLen; i++) {
            address baseToken = _baseTokensMap[trader][i];
            totalTakerQuoteBalance = totalTakerQuoteBalance.add(_accountMarketMap[trader][baseToken].takerOpenNotional);
        }
        // pendingFee is included
        int256 totalMakerQuoteBalance;
        netQuoteBalance = totalTakerQuoteBalance.add(totalMakerQuoteBalance);
        return (netQuoteBalance, pendingFee);
    }

    function _hasBaseToken(address[] memory baseTokens, address baseToken) internal pure returns (bool) {
        for (uint256 i = 0; i < baseTokens.length; i++) {
            if (baseTokens[i] == baseToken) {
                return true;
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMathUpgradeable {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { SafeOwnable } from "./SafeOwnable.sol";

abstract contract ClearingHouseCallee is SafeOwnable {
    //
    // STATE
    //
    address internal _clearingHouse;

    // __gap is reserved storage
    uint256[50] private __gap;

    //
    // EVENT
    //
    event ClearingHouseChanged(address indexed clearingHouse);

    //
    // CONSTRUCTOR
    //

    // solhint-disable-next-line func-order
    function __ClearingHouseCallee_init() internal initializer {
        __SafeOwnable_init();
    }

    function setClearingHouse(address clearingHouseArg) external onlyOwner {
        _clearingHouse = clearingHouseArg;
        emit ClearingHouseChanged(clearingHouseArg);
    }

    function getClearingHouse() external view returns (address) {
        return _clearingHouse;
    }

    function _requireOnlyClearingHouse() internal view {
        // only ClearingHouse
        require(_msgSender() == _clearingHouse, "CHD_OCH");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/**
 * @dev copy from "@openzeppelin/contracts-upgradeable/utils/SafeCastUpgradeable.sol"
 * and rename to avoid naming conflict with uniswap
 */
library PerpSafeCast {
    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128 returnValue) {
        require(((returnValue = uint128(value)) == value), "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64 returnValue) {
        require(((returnValue = uint64(value)) == value), "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32 returnValue) {
        require(((returnValue = uint32(value)) == value), "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toUint24(uint256 value) internal pure returns (uint24 returnValue) {
        require(((returnValue = uint24(value)) == value), "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16 returnValue) {
        require(((returnValue = uint16(value)) == value), "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8 returnValue) {
        require(((returnValue = uint8(value)) == value), "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 returnValue) {
        require(((returnValue = int128(value)) == value), "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 returnValue) {
        require(((returnValue = int64(value)) == value), "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 returnValue) {
        require(((returnValue = int32(value)) == value), "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 returnValue) {
        require(((returnValue = int16(value)) == value), "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 returnValue) {
        require(((returnValue = int8(value)) == value), "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }

    /**
     * @dev Returns the downcasted uint24 from int256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0 and into 24 bit.
     */
    function toUint24(int256 value) internal pure returns (uint24 returnValue) {
        require(
            ((returnValue = uint24(value)) == value),
            "SafeCast: value must be positive or value doesn't fit in an 24 bits"
        );
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     */
    function toInt24(int256 value) internal pure returns (int24 returnValue) {
        require(((returnValue = int24(value)) == value), "SafeCast: value doesn't fit in an 24 bits");
    }

    function toUint160(uint256 value) internal pure returns (uint160 returnValue) {
        require(((returnValue = uint160(value)) == value), "SafeCast: value doesn't fit in 160 bits");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { FullMath } from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import { PerpSafeCast } from "./PerpSafeCast.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { SignedSafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";

library PerpMath {
    // CONST
    int256 internal constant _IQ96 = 0x1000000000000000000000000;

    using PerpSafeCast for int256;
    using PerpSafeCast for uint256;
    using PerpMath for int256;
    using SignedSafeMathUpgradeable for int256;
    using SafeMathUpgradeable for uint256;

    function formatSqrtPriceX96ToPriceX96(uint160 sqrtPriceX96) internal pure returns (uint256) {
        return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }

    function formatX10_18ToX96(uint256 valueX10_18) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX10_18, FixedPoint96.Q96, 1 ether);
    }

    function formatX96ToX10_18(uint256 valueX96) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX96, 1 ether, FixedPoint96.Q96);
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function abs(int256 value) internal pure returns (uint256) {
        return value >= 0 ? value.toUint256() : neg256(value).toUint256();
    }

    function neg256(int256 a) internal pure returns (int256) {
        require(a > -2 ** 255, "PerpMath: inversion overflow");
        return -a;
    }

    function neg256(uint256 a) internal pure returns (int256) {
        return -PerpSafeCast.toInt256(a);
    }

    function neg128(int128 a) internal pure returns (int128) {
        require(a > -2 ** 127, "PerpMath: inversion overflow");
        return -a;
    }

    function neg128(uint128 a) internal pure returns (int128) {
        return -PerpSafeCast.toInt128(a);
    }

    function divBy10_18(int256 value) internal pure returns (int256) {
        // no overflow here
        return value / (1 ether);
    }

    function divBy10_18(uint256 value) internal pure returns (uint256) {
        // no overflow here
        return value / (1 ether);
    }

    function subRatio(uint24 a, uint24 b) internal pure returns (uint24) {
        require(b <= a, "PerpMath: subtraction overflow");
        return a - b;
    }

    function mulRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return FullMath.mulDiv(value, ratio, 1e6);
    }

    function mulRatio(int256 value, uint24 ratio) internal pure returns (int256) {
        return mulDiv(value, int256(ratio), 1e6);
    }

    function divRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return FullMath.mulDiv(value, 1e6, ratio);
    }

    /// @param denominator cannot be 0 and is checked in FullMath.mulDiv()
    function mulDiv(int256 a, int256 b, uint256 denominator) internal pure returns (int256 result) {
        uint256 unsignedA = a < 0 ? uint256(neg256(a)) : uint256(a);
        uint256 unsignedB = b < 0 ? uint256(neg256(b)) : uint256(b);
        bool negative = ((a < 0 && b > 0) || (a > 0 && b < 0)) ? true : false;

        uint256 unsignedResult = FullMath.mulDiv(unsignedA, unsignedB, denominator);

        result = negative ? neg256(unsignedResult) : PerpSafeCast.toInt256(unsignedResult);

        return result;
    }

    function mulMultiplier(int256 value, uint256 multiplier) internal pure returns (int256) {
        return mulDiv(value, int256(multiplier), 1e18);
    }

    function divMultiplier(int256 value, uint256 multiplier) internal pure returns (int256) {
        return mulDiv(value, 1e18, multiplier);
    }

    function mulMultiplier(uint256 value, uint256 multiplier) internal pure returns (uint256) {
        return FullMath.mulDiv(value, multiplier, 1e18);
    }

    function divMultiplier(uint256 value, uint256 multiplier) internal pure returns (uint256) {
        return FullMath.mulDiv(value, 1e18, multiplier);
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
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
        // else z = 0 (default value)
    }

    function formatPriceX10_18ToSqrtPriceX96(uint256 y) internal pure returns (uint160) {
        uint256 z;
        z = formatX10_18ToX96(y);
        z = z.mul(FixedPoint96.Q96);
        z = sqrt(z);
        return PerpSafeCast.toUint160(z);
    }

    uint256 internal constant _ONE_HUNDRED_PERCENT = 1e6; // 100%

    //
    // INTERNAL PURE
    //

    function calcAmountScaledByFeeRatio(
        uint256 amount,
        uint24 feeRatio,
        bool isScaledUp
    ) internal pure returns (uint256) {
        // when scaling up, round up to avoid imprecision; it's okay as long as we round down later
        return
            isScaledUp
                ? FullMath.mulDivRoundingUp(amount, _ONE_HUNDRED_PERCENT, uint256(_ONE_HUNDRED_PERCENT).sub(feeRatio))
                : FullMath.mulDiv(amount, uint256(_ONE_HUNDRED_PERCENT).sub(feeRatio), _ONE_HUNDRED_PERCENT);
    }

    /// @return scaledAmountForUniswapV3PoolSwap the unsigned scaled amount for UniswapV3Pool.swap()
    /// @return signedScaledAmountForReplaySwap the signed scaled amount for _replaySwap()
    /// @dev for UniswapV3Pool.swap(), scaling the amount is necessary to achieve the custom fee effect
    /// @dev for _replaySwap(), however, as we can input ExchangeFeeRatioRatio directly in SwapMath.computeSwapStep(),
    ///      there is no need to stick to the scaled amount
    /// @dev refer to CH._openPosition() docstring for explainer diagram
    function calcScaledAmountForSwaps(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        uint24 uniswapFeeRatio
    ) internal pure returns (uint256 scaledAmountForUniswapV3PoolSwap, int256 signedScaledAmountForReplaySwap) {
        if (isBaseToQuote) {
            scaledAmountForUniswapV3PoolSwap = isExactInput
                ? calcAmountScaledByFeeRatio(amount, uniswapFeeRatio, true)
                : calcAmountScaledByFeeRatio(amount, 0, true);
        } else {
            scaledAmountForUniswapV3PoolSwap = isExactInput
                ? calcAmountWithFeeRatioReplaced(amount, uniswapFeeRatio, 0, true)
                : amount;
        }

        // x : uniswapFeeRatio, y : exchangeFeeRatioRatio
        // since we can input ExchangeFeeRatioRatio directly in SwapMath.computeSwapStep() in _replaySwap(),
        // when !isBaseToQuote, we can use the original amount directly
        // ex: when x(uniswapFeeRatio) = 1%, y(exchangeFeeRatioRatio) = 3%, input == 1 quote
        // our target is to get fee == 0.03 quote
        // if scaling the input as 1 * 0.97 / 0.99, the fee calculated in `_replaySwap()` won't be 0.03
        signedScaledAmountForReplaySwap = isBaseToQuote
            ? scaledAmountForUniswapV3PoolSwap.toInt256()
            : amount.toInt256();
        signedScaledAmountForReplaySwap = isExactInput
            ? signedScaledAmountForReplaySwap
            : signedScaledAmountForReplaySwap.neg256();
    }

    /// @param isReplacingUniswapFeeRatio is to replace uniswapFeeRatio or clearingHouseFeeRatio
    ///        let x : uniswapFeeRatio, y : clearingHouseFeeRatio
    ///        true: replacing uniswapFeeRatio with clearingHouseFeeRatio: amount * (1 - y) / (1 - x)
    ///        false: replacing clearingHouseFeeRatio with uniswapFeeRatio: amount * (1 - x) / (1 - y)
    ///        multiplying a fee is applying it as the new standard and dividing a fee is removing its effect
    /// @dev calculate the amount when feeRatio is switched between uniswapFeeRatio and clearingHouseFeeRatio
    function calcAmountWithFeeRatioReplaced(
        uint256 amount,
        uint24 uniswapFeeRatio,
        uint24 clearingHouseFeeRatio,
        bool isReplacingUniswapFeeRatio
    ) internal pure returns (uint256) {
        (uint24 newFeeRatio, uint24 replacedFeeRatio) = isReplacingUniswapFeeRatio
            ? (clearingHouseFeeRatio, uniswapFeeRatio)
            : (uniswapFeeRatio, clearingHouseFeeRatio);

        return
            FullMath.mulDivRoundingUp(
                amount,
                uint256(_ONE_HUNDRED_PERCENT).sub(newFeeRatio),
                uint256(_ONE_HUNDRED_PERCENT).sub(replacedFeeRatio)
            );
    }

    function lte(
        uint256 settlementToken,
        // solhint-disable-next-line var-name-mixedcase
        uint256 amountX10_18,
        uint8 decimals
    ) internal pure returns (bool) {
        return parseSettlementToken(settlementToken, decimals) <= amountX10_18;
    }

    function lte(
        int256 settlementToken,
        // solhint-disable-next-line var-name-mixedcase
        int256 amountX10_18,
        uint8 decimals
    ) internal pure returns (bool) {
        return parseSettlementToken(settlementToken, decimals) <= amountX10_18;
    }

    function lt(
        uint256 settlementToken,
        // solhint-disable-next-line var-name-mixedcase
        uint256 amountX10_18,
        uint8 decimals
    ) internal pure returns (bool) {
        return parseSettlementToken(settlementToken, decimals) < amountX10_18;
    }

    function lt(
        int256 settlementToken,
        // solhint-disable-next-line var-name-mixedcase
        int256 amountX10_18,
        uint8 decimals
    ) internal pure returns (bool) {
        return parseSettlementToken(settlementToken, decimals) < amountX10_18;
    }

    function gt(
        uint256 settlementToken,
        // solhint-disable-next-line var-name-mixedcase
        uint256 amountX10_18,
        uint8 decimals
    ) internal pure returns (bool) {
        return parseSettlementToken(settlementToken, decimals) > amountX10_18;
    }

    function gt(
        int256 settlementToken,
        // solhint-disable-next-line var-name-mixedcase
        int256 amountX10_18,
        uint8 decimals
    ) internal pure returns (bool) {
        return parseSettlementToken(settlementToken, decimals) > amountX10_18;
    }

    function gte(
        uint256 settlementToken,
        // solhint-disable-next-line var-name-mixedcase
        uint256 amountX10_18,
        uint8 decimals
    ) internal pure returns (bool) {
        return parseSettlementToken(settlementToken, decimals) >= amountX10_18;
    }

    function gte(
        int256 settlementToken,
        // solhint-disable-next-line var-name-mixedcase
        int256 amountX10_18,
        uint8 decimals
    ) internal pure returns (bool) {
        return parseSettlementToken(settlementToken, decimals) >= amountX10_18;
    }

    // returns number with 18 decimals
    function parseSettlementToken(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        return amount.mul(10 ** (18 - decimals));
    }

    // returns number with 18 decimals
    function parseSettlementToken(int256 amount, uint8 decimals) internal pure returns (int256) {
        return amount.mul(int256(10 ** (18 - decimals)));
    }

    // returns number converted from 18 decimals to settlementToken's decimals
    function formatSettlementToken(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        return amount.div(10 ** (18 - decimals));
    }

    // returns number converted from 18 decimals to settlementToken's decimals
    // will always round down no matter positive value or negative value
    function formatSettlementToken(int256 amount, uint8 decimals) internal pure returns (int256) {
        uint256 denominator = 10 ** (18 - decimals);
        int256 rounding = 0;
        if (amount < 0 && uint256(-amount) % denominator != 0) {
            rounding = -1;
        }
        return amount.div(int256(denominator)).add(rounding);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

interface IVault {
    /// @notice Emitted when trader deposit collateral into vault
    /// @param collateralToken The address of token deposited
    /// @param trader The address of trader
    /// @param amount The amount of token deposited
    event Deposited(address indexed collateralToken, address indexed trader, uint256 amount);

    /// @notice Emitted when trader withdraw collateral from vault
    /// @param collateralToken The address of token withdrawn
    /// @param trader The address of trader
    /// @param amount The amount of token withdrawn
    event Withdrawn(address indexed collateralToken, address indexed trader, uint256 amount);

    /// @notice Emitted when a trader's collateral is liquidated
    /// @param trader The address of trader
    /// @param collateralToken The address of the token that is liquidated
    /// @param liquidator The address of liquidator
    /// @param collateral The amount of collateral token liquidated
    /// @param repaidSettlementWithoutInsuranceFundFeeX10_S The amount of settlement token repaid
    ///        for trader (in settlement token's decimals)
    /// @param insuranceFundFeeX10_S The amount of insurance fund fee paid(in settlement token's decimals)
    /// @param discountRatio The discount ratio of liquidation price
    event CollateralLiquidated(
        address indexed trader,
        address indexed collateralToken,
        address indexed liquidator,
        uint256 collateral,
        uint256 repaidSettlementWithoutInsuranceFundFeeX10_S,
        uint256 insuranceFundFeeX10_S,
        uint24 discountRatio
    );

    /// @notice Emitted when trustedForwarder is changed
    /// @dev trustedForwarder is only used for metaTx
    /// @param trustedForwarder The address of trustedForwarder
    event TrustedForwarderChanged(address indexed trustedForwarder);

    /// @notice Emitted when clearingHouse is changed
    /// @param clearingHouse The address of clearingHouse
    event ClearingHouseChanged(address indexed clearingHouse);

    /// @notice Emitted when collateralManager is changed
    /// @param collateralManager The address of collateralManager
    event CollateralManagerChanged(address indexed collateralManager);

    event MakerChanged(address indexed maker);

    /// @notice Emitted when WETH9 is changed
    /// @param WETH9 The address of WETH9
    event WETH9Changed(address indexed WETH9);

    /// @notice Emitted when bad debt realized and settled
    /// @param trader Address of the trader
    /// @param amount Absolute amount of bad debt
    event BadDebtSettled(address indexed trader, uint256 amount);

    /// @notice Deposit collateral into vault
    /// @param token The address of the token to deposit
    /// @param amount The amount of the token to deposit
    function deposit(address token, uint256 amount) external;

    /// @notice Deposit the collateral token for other account
    /// @param to The address of the account to deposit to
    /// @param token The address of collateral token
    /// @param amount The amount of the token to deposit
    function depositFor(
        address to,
        address token,
        uint256 amount
    ) external;

    /// @notice Deposit ETH as collateral into vault
    function depositEther() external payable;

    /// @notice Deposit ETH as collateral for specified account
    /// @param to The address of the account to deposit to
    function depositEtherFor(address to) external payable;

    /// @notice Withdraw collateral from vault
    /// @param token The address of the token to withdraw
    /// @param amount The amount of the token to withdraw
    function withdraw(address token, uint256 amount) external;

    /// @notice Withdraw ETH from vault
    /// @param amount The amount of the ETH to withdraw
    function withdrawEther(uint256 amount) external;

    /// @notice Withdraw all free collateral from vault
    /// @param token The address of the token to withdraw
    /// @return amount The amount of the token withdrawn
    function withdrawAll(address token) external returns (uint256 amount);

    /// @notice Withdraw all free collateral of ETH from vault
    /// @return amount The amount of ETH withdrawn
    function withdrawAllEther() external returns (uint256 amount);

    /// @notice Settle trader's bad debt
    /// @param trader The address of trader that will be settled
    function settleBadDebt(address trader) external;

    /// @notice Get the specified trader's settlement token balance, without pending fee, funding payment
    ///         and owed realized PnL
    /// @dev The function is equivalent to `getBalanceByToken(trader, settlementToken)`
    ///      We keep this function solely for backward-compatibility with the older single-collateral system.
    ///      In practical applications, the developer might want to use `getSettlementTokenValue()` instead
    ///      because the latter includes pending fee, funding payment etc.
    ///      and therefore more accurately reflects a trader's settlement (ex. USDC) balance
    /// @return balance The balance amount (in settlement token's decimals)
    function getBalance(address trader) external view returns (int256 balance);

    /// @notice Get the balance of Vault of the specified collateral token and trader
    /// @param trader The address of the trader
    /// @param token The address of the collateral token
    /// @return balance The balance amount (in its native decimals)
    function getBalanceByToken(address trader, address token) external view returns (int256 balance);

    /// @notice Get they array of collateral token addresses that a trader has
    /// @return collateralTokens array of collateral token addresses
    function getCollateralTokens(address trader) external view returns (address[] memory collateralTokens);

    /// @notice Get account value of the specified trader
    /// @param trader The address of the trader
    /// @return accountValueX10_S account value (in settlement token's decimals)
    function getAccountValue(address trader) external view returns (int256 accountValueX10_S);

    /// @notice Get the free collateral value denominated in the settlement token of the specified trader
    /// @param trader The address of the trader
    /// @return freeCollateral the value (in settlement token's decimals) of free collateral available
    ///         for withdraw or opening new positions or orders)
    function getFreeCollateral(address trader) external view returns (uint256 freeCollateral);

    /// @notice Get the free collateral amount of the specified trader and collateral ratio
    /// @dev There are three configurations for different insolvency risk tolerances:
    ///      **conservative, moderate &aggressive**. We will start with the **conservative** one
    ///      and gradually move to **aggressive** to increase capital efficiency
    /// @param trader The address of the trader
    /// @param ratio The margin requirement ratio, imRatio or mmRatio
    /// @return freeCollateralByRatio freeCollateral (in settlement token's decimals), by using the
    ///         input margin requirement ratio; can be negative
    function getFreeCollateralByRatio(address trader, uint24 ratio)
        external
        view
        returns (int256 freeCollateralByRatio);

    /// @notice Get the free collateral amount of the specified collateral token of specified trader
    /// @param trader The address of the trader
    /// @param token The address of the collateral token
    /// @return freeCollateral amount of that token (in the token's native decimals)
    function getFreeCollateralByToken(address trader, address token) external view returns (uint256 freeCollateral);

    /// @notice Get the specified trader's settlement value, including pending fee, funding payment,
    ///         owed realized PnL and unrealized PnL
    /// @dev Note the difference between `settlementTokenBalanceX10_S`, `getSettlementTokenValue()` and `getBalance()`:
    ///      They are all settlement token balances but with or without
    ///      pending fee, funding payment, owed realized PnL, unrealized PnL, respectively
    ///      In practical applications, we use `getSettlementTokenValue()` to get the trader's debt (if < 0)
    /// @param trader The address of the trader
    /// @return balance The balance amount (in settlement token's decimals)
    function getSettlementTokenValue(address trader) external view returns (int256 balance);

    /// @notice Get the settlement token address
    /// @dev We assume the settlement token should match the denominator of the price oracle.
    ///      i.e. if the settlement token is USDC, then the oracle should be priced in USD
    /// @return settlementToken The address of the settlement token
    function getSettlementToken() external view returns (address settlementToken);

    /// @notice Get settlement token decimals
    /// @dev cached the settlement token's decimal for gas optimization
    /// @return decimals The decimals of settlement token
    function decimals() external view returns (uint8 decimals);

    /// @notice (Deprecated) Get the borrowed settlement token amount from insurance fund
    /// @return debtAmount The debt amount (in settlement token's decimals)
    function getTotalDebt() external view returns (uint256 debtAmount);

    /// @notice Get `ClearingHouseConfig` contract address
    /// @return clearingHouseConfig The address of `ClearingHouseConfig` contract
    function getClearingHouseConfig() external view returns (address clearingHouseConfig);

    /// @notice Get `AccountBalance` contract address
    /// @return accountBalance The address of `AccountBalance` contract
    function getAccountBalance() external view returns (address accountBalance);

    /// @notice Get `InsuranceFund` contract address
    /// @return insuranceFund The address of `InsuranceFund` contract
    function getInsuranceFund() external view returns (address insuranceFund);

    /// @notice Get `Exchange` contract address
    /// @return exchange The address of `Exchange` contract
    function getVPool() external view returns (address exchange);

    /// @notice Get `ClearingHouse` contract address
    /// @return clearingHouse The address of `ClearingHouse` contract
    function getClearingHouse() external view returns (address clearingHouse);

    /// @notice Get `WETH9` contract address
    /// @return clearingHouse The address of `WETH9` contract
    function getWETH9() external view returns (address clearingHouse);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;
import { DataTypes } from "../types/DataTypes.sol";
import { UniswapV3Broker } from "../lib/UniswapV3Broker.sol";

interface IVPool {
    /// @param amount when closing position, amount(uint256) == takerPositionSize(int256),
    /// as amount is assigned as takerPositionSize in ClearingHouse.closePosition()
    struct SwapParams {
        address trader;
        address baseToken;
        bool isBaseToQuote;
        bool isExactInput;
        bool isClose;
        uint256 amount;
        uint160 sqrtPriceLimitX96;
    }

    struct SwapResponse {
        uint256 base;
        uint256 quote;
        int256 exchangedPositionSize;
        int256 exchangedPositionNotional;
        uint256 insuranceFundFee;
        uint256 platformFundFee;
        int256 pnlToBeRealized;
        uint256 sqrtPriceAfterX96;
        int24 tick;
        bool isPartialClose;
    }

    struct SwapCallbackData {
        address trader;
        address baseToken;
        address pool;
        uint24 uniswapFeeRatio;
        uint256 fee;
    }

    struct RealizePnlParams {
        address trader;
        address baseToken;
        int256 base;
        int256 quote;
    }

    /// @notice Emitted when the global funding growth is updated
    /// @param baseToken Address of the base token
    /// @param markTwap The market twap price when the funding growth is updated
    /// @param indexTwap The index twap price when the funding growth is updated
    event FundingUpdated(
        address indexed baseToken,
        uint256 markTwap,
        uint256 indexTwap,
        uint256 longPositionSize,
        uint256 shortPositionSize
    );

    /// @notice Emitted when maxTickCrossedWithinBlock is updated
    /// @param baseToken Address of the base token
    /// @param maxTickCrossedWithinBlock Max tick allowed to be crossed within block when reducing position
    event MaxTickCrossedWithinBlockChanged(address indexed baseToken, uint24 maxTickCrossedWithinBlock);

    /// @notice Emitted when accountBalance is updated
    /// @param accountBalance The address of accountBalance contract
    event AccountBalanceChanged(address accountBalance);

    /// @notice The actual swap function
    /// @dev can only be called from ClearingHouse
    /// @param params The parameters of the swap
    /// @return swapResponse The result of the swap
    function swap(SwapParams memory params) external returns (SwapResponse memory swapResponse);

    function settleFundingGlobal(address baseToken) external returns (DataTypes.Growth memory fundingGrowthGlobal);

    /// @notice Settle the funding payment for the time interval since the last settlement
    /// @dev This function should be called at the beginning of every high-level function, such as `openPosition()`
    ///      while it doesn't matter who calls this function
    ///      this function 1. settles personal funding payment 2. updates global funding growth
    ///      personal funding payment is settled whenever there is pending funding payment
    ///      the global funding growth update only happens once per unique timestamp (not blockNumber, due to Arbitrum)
    /// @return fundingPayment the funding payment of a trader in one market should be settled into owned realized Pnl
    /// @return fundingGrowthGlobal the up-to-date globalFundingGrowth, usually used for later calculations
    function settleFunding(
        address trader,
        address baseToken
    ) external returns (int256 fundingPayment, DataTypes.Growth memory fundingGrowthGlobal);

    /// @notice Get the max ticks allowed to be crossed within a block when reducing position
    /// @param baseToken Address of the base token
    /// @return maxTickCrossedWithinBlock The max ticks allowed to be crossed within a block when reducing position
    function getMaxTickCrossedWithinBlock(address baseToken) external view returns (uint24 maxTickCrossedWithinBlock);

    /// @notice Get all the pending funding payment for a trader
    /// @return pendingFundingPayment The pending funding payment of the trader.
    /// Positive value means the trader pays funding, negative value means the trader receives funding.
    function getAllPendingFundingPayment(address trader) external view returns (int256 pendingFundingPayment);

    /// @notice Check if current price spread between market price and index twap is over maximum price spread.
    /// @param baseToken Address of the base token
    /// @return true if over the maximum price spread
    function isOverPriceSpread(address baseToken) external view returns (bool);

    /// @notice Get the pending funding payment for a trader in a given market
    /// @dev this is the view version of _updateFundingGrowth()
    /// @return pendingFundingPayment The pending funding payment of a trader in one market,
    /// including liquidity & balance coefficients. Positive value means the trader pays funding,
    /// negative value means the trader receives funding.
    function getPendingFundingPayment(
        address trader,
        address baseToken
    ) external view returns (int256 pendingFundingPayment);

    /// @notice Get the square root of the market twap price with the given time interval
    /// @dev The return value is a X96 number
    /// @param baseToken Address of the base token
    /// @param twapInterval The time interval in seconds
    /// @return sqrtMarkTwapX96 The square root of the market twap price
    function getSqrtMarkTwapX96(address baseToken, uint32 twapInterval) external view returns (uint160 sqrtMarkTwapX96);

    /// @notice Get the pnl that can be realized if trader reduce position
    /// @dev This function normally won't be needed by traders, but it might be useful for 3rd party
    /// @param params The params needed to do the query, encoded as `RealizePnlParams` in calldata
    /// @return pnlToBeRealized The pnl that can be realized if trader reduce position
    function getPnlToBeRealized(RealizePnlParams memory params) external view returns (int256 pnlToBeRealized);

    /// @notice Get `AccountBalance` contract address
    /// @return accountBalance `AccountBalance` contract address
    function getAccountBalance() external view returns (address accountBalance);

    /// @notice Get `ClearingHouseConfig` contract address
    /// @return clearingHouse `ClearingHouseConfig` contract address
    function getClearingHouseConfig() external view returns (address clearingHouse);

    function getFundingGrowthGlobalAndTwaps(
        address baseToken
    ) external view returns (DataTypes.Growth memory fundingGrowthGlobal, uint256 markTwap, uint256 indexTwap);

    function updateOverPriceSpreadTimestamp(address baseToken) external;

    function isOverPriceSpreadTimestamp(address baseToken) external view returns (bool);

    function estimateSwap(
        DataTypes.OpenPositionParams memory params
    ) external view returns (UniswapV3Broker.ReplaySwapResponse memory response);

    function internalSwap(SwapParams memory params) external returns (SwapResponse memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

interface IBaseToken {
    // Do NOT change the order of enum values because it will break backwards compatibility
    enum Status { Open, Paused, Closed }

    event PriceFeedChanged(address indexed priceFeed);
    event StatusUpdated(Status indexed status);

    function close() external;

    /// @notice Update the cached index price of the token.
    /// @param interval The twap interval in seconds.
    function cacheTwap(uint256 interval) external;

    /// @notice Get the price feed address
    /// @return priceFeed the current price feed
    function getPriceFeed() external view returns (address priceFeed);

    function getPausedTimestamp() external view returns (uint256);

    function getPausedIndexPrice() external view returns (uint256);

    function getClosedPrice() external view returns (uint256);

    function isOpen() external view returns (bool);

    function isPaused() external view returns (bool);

    function isClosed() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

interface IIndexPrice {
    /// @notice Returns the index price of the token.
    /// @param interval The interval represents twap interval.
    /// @return indexPrice Twap price with interval
    function getIndexPrice(uint256 interval) external view returns (uint256 indexPrice);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

interface IClearingHouseConfig {
    /// @return maxMarketsPerAccount Max value of total markets per account
    function getMaxMarketsPerAccount() external view returns (uint8 maxMarketsPerAccount);

    /// @return imRatio Initial margin ratio
    function getImRatio() external view returns (uint24 imRatio);

    /// @return mmRatio Maintenance margin requirement ratio
    function getMmRatio() external view returns (uint24 mmRatio);

    /// @return liquidationPenaltyRatio Liquidation penalty ratio
    function getLiquidationPenaltyRatio() external view returns (uint24 liquidationPenaltyRatio);

    /// @return partialCloseRatio Partial close ratio
    function getPartialCloseRatio() external view returns (uint24 partialCloseRatio);

    /// @return twapInterval TwapInterval for funding and prices (mark & index) calculations
    function getTwapInterval() external view returns (uint32 twapInterval);

    /// @return settlementTokenBalanceCap Max value of settlement token balance
    function getSettlementTokenBalanceCap() external view returns (uint256 settlementTokenBalanceCap);

    /// @return maxFundingRate Max value of funding rate
    function getMaxFundingRate() external view returns (uint24 maxFundingRate);

    function getDurationRepegOverPriceSpread() external view returns (uint256 duration);

    /// @return isBackstopLiquidityProvider is backstop liquidity provider
    function isBackstopLiquidityProvider(address account) external view returns (bool isBackstopLiquidityProvider);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import { DataTypes } from "../types/DataTypes.sol";

/// @notice For future upgrades, do not change AccountBalanceStorageV1. Create a new
/// contract which implements AccountBalanceStorageV1 and following the naming convention
/// AccountBalanceStorageVX.
abstract contract AccountBalanceStorageV1 {
    address internal _clearingHouseConfig;
    address internal __orderBook;
    address internal _vault;

    address[10] private __gap1;
    uint256[10] private __gap2;

    // trader => owedRealizedPnl
    mapping(address => int256) internal _owedRealizedPnlMap;

    // trader => baseTokens
    // base token registry of each trader
    mapping(address => address[]) internal _baseTokensMap;

    mapping(address => DataTypes.MarketInfo) internal _marketMap;

    // first key: trader, second key: baseToken
    mapping(address => mapping(address => DataTypes.AccountMarketInfo)) internal _accountMarketMap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

abstract contract BlockContext {
    function _blockTimestamp() internal view virtual returns (uint256) {
        // Reply from Arbitrum
        // block.timestamp returns timestamp at the time at which the sequencer receives the tx.
        // It may not actually correspond to a particular L1 block
        return block.timestamp;
    }

    function _blockNumber() internal view virtual returns (uint256) {
        return block.number;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { DataTypes } from "../types/DataTypes.sol";

interface IAccountBalance {
    struct ModifyTotalPositionParams {
        address baseToken;
        uint256 positionSize;
        bool isLong;
        bool isDecrease;
    }

    /// @param vault The address of the vault contract
    event VaultChanged(address indexed vault);

    /// @dev Emit whenever a trader's `owedRealizedPnl` is updated
    /// @param trader The address of the trader
    /// @param amount The amount changed
    event PnlRealized(address indexed trader, int256 amount);

    event MultiplierChanged(uint256 longMultiplier, uint256 shortMultiplier);

    /// @notice Modify trader account balance
    /// @dev Only used by `ClearingHouse` contract
    /// @param trader The address of the trader
    /// @param baseToken The address of the baseToken
    /// @param base Modified amount of base
    /// @param quote Modified amount of quote
    /// @return takerPositionSize Taker position size after modified
    /// @return takerOpenNotional Taker open notional after modified
    function modifyTakerBalance(
        address trader,
        address baseToken,
        int256 base,
        int256 quote
    ) external returns (int256 takerPositionSize, int256 takerOpenNotional);

    /// @notice Modify trader owedRealizedPnl
    /// @dev Only used by `ClearingHouse` contract
    /// @param trader The address of the trader
    /// @param amount Modified amount of owedRealizedPnl
    function modifyOwedRealizedPnl(address trader, int256 amount) external;

    /// @notice Settle owedRealizedPnl
    /// @dev Only used by `Vault.withdraw()`
    /// @param trader The address of the trader
    /// @return pnl Settled owedRealizedPnl
    function settleOwedRealizedPnl(address trader) external returns (int256 pnl);

    /// @notice Modify trader owedRealizedPnl
    /// @dev Only used by `ClearingHouse` contract
    /// @param trader The address of the trader
    /// @param baseToken The address of the baseToken
    /// @param amount Settled quote amount
    function settleQuoteToOwedRealizedPnl(address trader, address baseToken, int256 amount) external;

    /// @notice Settle account balance and deregister base token
    /// @dev Only used by `ClearingHouse` contract
    /// @param trader The address of the trader
    /// @param baseToken The address of the baseToken
    /// @param takerBase Modified amount of taker base
    /// @param takerQuote Modified amount of taker quote
    /// @param realizedPnl Amount of pnl realized
    /// @param makerFee Amount of maker fee collected from pool
    function settleBalanceAndDeregister(
        address trader,
        address baseToken,
        int256 takerBase,
        int256 takerQuote,
        int256 realizedPnl,
        int256 makerFee
    ) external;

    /// @notice Every time a trader's position value is checked, the base token list of this trader will be traversed;
    /// thus, this list should be kept as short as possible
    /// @dev Only used by `ClearingHouse` contract
    /// @param trader The address of the trader
    /// @param baseToken The address of the trader's base token
    function registerBaseToken(address trader, address baseToken) external;

    /// @notice Deregister baseToken from trader accountInfo
    /// @dev Only used by `ClearingHouse` contract, this function is expensive, due to for loop
    /// @param trader The address of the trader
    /// @param baseToken The address of the trader's base token
    function deregisterBaseToken(address trader, address baseToken) external;

    /// @notice Update trader Twap premium info
    /// @dev Only used by `ClearingHouse` contract
    /// @param trader The address of trader
    /// @param baseToken The address of baseToken
    /// @param lastLongTwPremiumGrowthGlobalX96 The last Twap Premium
    /// @param lastShortTwPremiumGrowthGlobalX96 The last Twap Premium
    function updateTwPremiumGrowthGlobal(
        address trader,
        address baseToken,
        int256 lastLongTwPremiumGrowthGlobalX96,
        int256 lastShortTwPremiumGrowthGlobalX96
    ) external;

    /// @notice Settle trader's PnL in closed market
    /// @dev Only used by `ClearingHouse`
    /// @param trader The address of the trader
    /// @param baseToken The address of the trader's base token
    /// @return positionNotional Taker's position notional settled with closed price
    /// @return openNotional Taker's open notional
    /// @return realizedPnl Settled realized pnl
    /// @return closedPrice The closed price of the closed market
    function settlePositionInClosedMarket(
        address trader,
        address baseToken
    ) external returns (int256 positionNotional, int256 openNotional, int256 realizedPnl, uint256 closedPrice);

    /// @notice Get `ClearingHouseConfig` address
    /// @return clearingHouseConfig The address of ClearingHouseConfig
    function getClearingHouseConfig() external view returns (address clearingHouseConfig);

    /// @notice Get `Vault` address
    /// @return vault The address of Vault
    function getVault() external view returns (address vault);

    /// @notice Get trader registered baseTokens
    /// @param trader The address of trader
    /// @return baseTokens The array of baseToken address
    function getBaseTokens(address trader) external view returns (address[] memory baseTokens);

    /// @notice Get trader account info
    /// @param trader The address of trader
    /// @param baseToken The address of baseToken
    /// @return traderAccountInfo The baseToken account info of trader
    function getAccountInfo(
        address trader,
        address baseToken
    ) external view returns (DataTypes.AccountMarketInfo memory traderAccountInfo);

    /// @notice Get taker cost of trader's baseToken
    /// @param trader The address of trader
    /// @param baseToken The address of baseToken
    /// @return openNotional The taker cost of trader's baseToken
    function getTakerOpenNotional(address trader, address baseToken) external view returns (int256 openNotional);

    /// @notice Get total cost of trader's baseToken
    /// @param trader The address of trader
    /// @param baseToken The address of baseToken
    /// @return totalOpenNotional the amount of quote token paid for a position when opening
    function getTotalOpenNotional(address trader, address baseToken) external view returns (int256 totalOpenNotional);

    /// @notice Get total debt value of trader
    /// @param trader The address of trader
    /// @dev Total debt value will relate to `Vault.getFreeCollateral()`
    /// @return totalDebtValue The debt value of trader
    // function getTotalDebtValue(address trader) external view returns (uint256 totalDebtValue);

    /// @notice Get margin requirement to check whether trader will be able to liquidate
    /// @dev This is different from `Vault._getTotalMarginRequirement()`, which is for freeCollateral calculation
    /// @param trader The address of trader
    /// @return marginRequirementForLiquidation It is compared with `ClearingHouse.getAccountValue` which is also an int
    function getMarginRequirementForLiquidation(
        address trader
    ) external view returns (int256 marginRequirementForLiquidation);

    /// @notice Get owedRealizedPnl, unrealizedPnl and pending fee
    /// @param trader The address of trader
    /// @return owedRealizedPnl the pnl realized already but stored temporarily in AccountBalance
    /// @return unrealizedPnl the pnl not yet realized
    /// @return pendingFee the pending fee of maker earned
    function getPnlAndPendingFee(
        address trader
    ) external view returns (int256 owedRealizedPnl, int256 unrealizedPnl, uint256 pendingFee);

    function getOriginBase(address trader, address baseToken) external view returns (int256 baseAmount);

    /// @notice Get trader base amount
    /// @dev `base amount = takerPositionSize - orderBaseDebt`
    /// @param trader The address of trader
    /// @param baseToken The address of baseToken
    /// @return baseAmount The base amount of trader's baseToken market
    function getBase(address trader, address baseToken) external view returns (int256 baseAmount);

    /// @notice Get trader quote amount
    /// @dev `quote amount = takerOpenNotional - orderQuoteDebt`
    /// @param trader The address of trader
    /// @param baseToken The address of baseToken
    /// @return quoteAmount The quote amount of trader's baseToken market
    function getQuote(address trader, address baseToken) external view returns (int256 quoteAmount);

    /// @notice Get taker position size of trader's baseToken market
    /// @dev This will only has taker position, can get maker impermanent position through `getTotalPositionSize`
    /// @param trader The address of trader
    /// @param baseToken The address of baseToken
    /// @return takerPositionSize The taker position size of trader's baseToken market
    function getTakerPositionSize(address trader, address baseToken) external view returns (int256 takerPositionSize);

    /// @notice Get total position size of trader's baseToken market
    /// @dev `total position size = taker position size + maker impermanent position size`
    /// @param trader The address of trader
    /// @param baseToken The address of baseToken
    /// @return totalPositionSize The total position size of trader's baseToken market
    function getTotalPositionSize(address trader, address baseToken) external view returns (int256 totalPositionSize);

    /// @notice Get total position value of trader's baseToken market
    /// @dev A negative returned value is only be used when calculating pnl,
    /// @dev we use `15 mins` twap to calc position value
    /// @param trader The address of trader
    /// @param baseToken The address of baseToken
    /// @return totalPositionValue Total position value of trader's baseToken market
    function getTotalPositionValue(address trader, address baseToken) external view returns (int256 totalPositionValue);

    /// @notice Get all market position abs value of trader
    /// @param trader The address of trader
    /// @return totalAbsPositionValue Sum up positions value of every market
    function getTotalAbsPositionValue(address trader) external view returns (uint256 totalAbsPositionValue);

    /// @notice Get liquidatable position size of trader's baseToken market
    /// @param trader The address of trader
    /// @param baseToken The address of baseToken
    /// @param accountValue The account value of trader
    /// @return liquidatablePositionSize The liquidatable position size of trader's baseToken market
    function getLiquidatablePositionSize(
        address trader,
        address baseToken,
        int256 accountValue
    ) external view returns (int256);

    function getMarketPositionSize(address baseToken) external view returns (uint256, uint256);

    function getMarketMultiplier(address baseToken) external view returns (uint256, uint256);

    function modifyMarketMultiplier(address baseToken, uint256 longDeltaRate, uint256 shortDeltaRate) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.6;

library DataTypes {
    /// @dev tw: time-weighted
    /// @param twPremiumX96 overflow inspection (as twPremiumX96 > twPremiumDivBySqrtPriceX96):
    //         max = 2 ^ (255 - 96) = 2 ^ 159 = 7.307508187E47
    //         assume premium = 10000, time = 10 year = 60 * 60 * 24 * 365 * 10 -> twPremium = 3.1536E12
    struct Growth {
        int256 twLongPremiumX96;
        int256 twShortPremiumX96;
    }

    struct MarketInfo {
        uint256 longMultiplierX10_18; //X10_18
        uint256 shortMultiplierX10_18; //X10_18
        uint256 longPositionSize;
        uint256 shortPositionSize;
    }

    struct AccountMarketInfo {
        int256 takerPositionSize;
        int256 takerOpenNotional;
        int256 lastLongTwPremiumGrowthGlobalX96;
        int256 lastShortTwPremiumGrowthGlobalX96;
    }

    struct AddLiquidityParams {
        address baseToken;
        uint128 liquidity;
        uint256 deadline;
    }

    struct AddLiquidityResponse {
        uint256 base;
        uint256 quote;
        uint128 liquidity;
    }

    struct RemoveLiquidityParams {
        address baseToken;
        uint128 liquidity;
        uint256 deadline;
    }

    struct RemoveLiquidityResponse {
        uint256 base;
        uint256 quote;
    }

    struct OpenPositionParams {
        address baseToken;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint256 oppositeAmountBound;
        uint256 deadline;
        uint160 sqrtPriceLimitX96;
        bytes32 referralCode;
    }

    struct ClosePositionParams {
        address baseToken;
        uint160 sqrtPriceLimitX96;
        uint256 oppositeAmountBound;
        uint256 deadline;
        bytes32 referralCode;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

abstract contract SafeOwnable is ContextUpgradeable {
    address private _owner;
    address private _candidate;

    // __gap is reserved storage
    uint256[50] private __gap;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        // caller not owner
        require(owner() == _msgSender(), "SO_CNO");
        _;
    }

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __SafeOwnable_init() internal initializer {
        __Context_init();
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        // emitting event first to avoid caching values
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
        _candidate = address(0);
    }

    /**
     * @dev Set ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function setOwner(address newOwner) external onlyOwner {
        // newOwner is 0
        require(newOwner != address(0), "SO_NW0");
        // same as original
        require(newOwner != _owner, "SO_SAO");
        // same as candidate
        require(newOwner != _candidate, "SO_SAC");

        _candidate = newOwner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`_candidate`).
     * Can only be called by the new owner.
     */
    function updateOwner() external {
        // candidate is zero
        require(_candidate != address(0), "SO_C0");
        // caller is not candidate
        require(_candidate == _msgSender(), "SO_CNC");

        // emitting event first to avoid caching values
        emit OwnershipTransferred(_owner, _candidate);
        _owner = _candidate;
        _candidate = address(0);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the candidate that can become the owner.
     */
    function candidate() external view returns (address) {
        return _candidate;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import { IUniswapV3Factory } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import { TickMath } from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import { LiquidityAmounts } from "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";
import { PoolAddress } from "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import { BitMath } from "@uniswap/v3-core/contracts/libraries/BitMath.sol";
import { SwapMath } from "@uniswap/v3-core/contracts/libraries/SwapMath.sol";
import { FullMath } from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import { LiquidityMath } from "@uniswap/v3-core/contracts/libraries/LiquidityMath.sol";
import { PerpSafeCast } from "./PerpSafeCast.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { SignedSafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import { PerpMath } from "../lib/PerpMath.sol";

/**
 * Uniswap's v3 pool: token0 & token1
 * -> token0's price = token1 / token0; tick index = log(1.0001, token0's price)
 * Our system: base & quote
 * -> base's price = quote / base; tick index = log(1.0001, base price)
 * Thus, we require that (base, quote) = (token0, token1) is always true for convenience
 */
library UniswapV3Broker {
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;
    using PerpMath for int128;
    using PerpMath for uint160;
    using PerpMath for int256;
    using PerpMath for uint256;
    using PerpSafeCast for uint256;
    using PerpSafeCast for int256;

    //
    // STRUCT
    //

    struct AddLiquidityParams {
        address baseToken;
        uint128 liquidity;
    }

    struct InternalAddLiquidityParams {
        address pool;
        int24 lowerTick;
        int24 upperTick;
        uint128 liquidity;
        bytes data;
    }

    struct AddLiquidityResponse {
        uint256 base;
        uint256 quote;
        uint128 liquidity;
    }

    struct RemoveLiquidityParams {
        address baseToken;
        uint128 liquidity;
    }

    struct InternalRemoveLiquidityParams {
        address pool;
        address recipient;
        int24 lowerTick;
        int24 upperTick;
        uint128 liquidity;
    }

    /// @param base amount of base token received from burning the liquidity (excl. fee)
    /// @param quote amount of quote token received from burning the liquidity (excl. fee)
    struct RemoveLiquidityResponse {
        uint256 base;
        uint256 quote;
    }

    struct SwapState {
        int24 tick;
        uint160 sqrtPriceX96;
        int256 amountSpecifiedRemaining;
        uint128 liquidity;
    }

    struct SwapParams {
        address pool;
        address recipient;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint160 sqrtPriceLimitX96;
        bytes data;
    }

    struct SwapResponse {
        uint256 base;
        uint256 quote;
    }

    struct ReplaySwapParams {
        address baseToken;
        bool isBaseToQuote;
        bool shouldUpdateState;
        int256 amount;
        uint160 sqrtPriceLimitX96;
        uint24 uniswapFeeRatio;
    }

    struct ReplaySwapResponse {
        int24 tick;
        uint256 fee;
        uint256 amountIn;
        uint256 amountOut;
    }

    struct InternalSwapStep {
        uint160 initialSqrtPriceX96;
        int24 nextTick;
        bool isNextTickInitialized;
        uint160 nextSqrtPriceX96;
        uint256 amountIn;
        uint256 amountOut;
        uint256 fee;
    }

    //
    // CONSTANT
    //

    uint256 internal constant _DUST = 10;

    //
    // INTERNAL NON-VIEW
    //

    struct MintCallbackData {
        address pool;
    }

    function addLiquidity(
        address pool,
        AddLiquidityParams calldata params
    ) external returns (AddLiquidityResponse memory) {
        (int24 lowerTick, int24 upperTick) = getFullTickForLiquidity(pool);
        // add liquidity to pool
        return
            _addLiquidity(
                InternalAddLiquidityParams(
                    pool,
                    lowerTick,
                    upperTick,
                    params.liquidity,
                    abi.encode(MintCallbackData(pool))
                )
            );
    }

    function _addLiquidity(InternalAddLiquidityParams memory params) internal returns (AddLiquidityResponse memory) {
        (uint256 addedAmount0, uint256 addedAmount1) = IUniswapV3Pool(params.pool).mint(
            address(this),
            params.lowerTick,
            params.upperTick,
            params.liquidity,
            params.data
        );
        return AddLiquidityResponse({ base: addedAmount0, quote: addedAmount1, liquidity: params.liquidity });
    }

    function removeLiquidity(
        address pool,
        address recipient, // _clearingHouse
        RemoveLiquidityParams calldata params
    ) external returns (RemoveLiquidityResponse memory) {
        (int24 lowerTick, int24 upperTick) = getFullTickForLiquidity(pool);
        // adremoved liquidity from pool
        return _removeLiquidity(InternalRemoveLiquidityParams(pool, recipient, lowerTick, upperTick, params.liquidity));
    }

    function _removeLiquidity(
        InternalRemoveLiquidityParams memory params
    ) internal returns (RemoveLiquidityResponse memory) {
        // call burn(), which only updates tokensOwed instead of transferring the tokens
        (uint256 amount0Burned, uint256 amount1Burned) = IUniswapV3Pool(params.pool).burn(
            params.lowerTick,
            params.upperTick,
            params.liquidity
        );

        // call collect() to transfer tokens to CH
        // we don't care about the returned values here as they include:
        // 1. every maker's fee in the same range (ClearingHouse is the only maker in the pool's perspective)
        // 2. the amount of token equivalent to liquidity burned
        IUniswapV3Pool(params.pool).collect(
            params.recipient,
            params.lowerTick,
            params.upperTick,
            type(uint128).max,
            type(uint128).max
        );

        return RemoveLiquidityResponse({ base: amount0Burned, quote: amount1Burned });
    }

    function swap(SwapParams memory params) external returns (SwapResponse memory response) {
        // UniswapV3Pool uses the sign to determine isExactInput or not
        int256 specifiedAmount = params.isExactInput ? params.amount.toInt256() : params.amount.neg256();

        // signedAmount0 & signedAmount1 are delta amounts, in the perspective of the pool
        // > 0: pool gets; user pays
        // < 0: pool provides; user gets
        (int256 signedAmount0, int256 signedAmount1) = IUniswapV3Pool(params.pool).swap(
            params.recipient,
            params.isBaseToQuote,
            specifiedAmount,
            params.sqrtPriceLimitX96 == 0
                ? (params.isBaseToQuote ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
                : params.sqrtPriceLimitX96,
            params.data
        );

        (uint256 amount0, uint256 amount1) = (signedAmount0.abs(), signedAmount1.abs());

        // isExactInput = true, isZeroForOne = true => exact token0
        // isExactInput = false, isZeroForOne = false => exact token0
        // isExactInput = false, isZeroForOne = true => exact token1
        // isExactInput = true, isZeroForOne = false => exact token1
        uint256 exactAmount = params.isExactInput == params.isBaseToQuote ? amount0 : amount1;

        // if no price limit, require the full output amount as it's technically possible for amounts to not match
        // UB_UOA: unmatched output amount
        if (!params.isExactInput && params.sqrtPriceLimitX96 == 0) {
            require(
                (exactAmount > params.amount ? exactAmount.sub(params.amount) : params.amount.sub(exactAmount)) < _DUST,
                "UB_UOA"
            );
            return params.isBaseToQuote ? SwapResponse(amount0, params.amount) : SwapResponse(params.amount, amount1);
        }

        return SwapResponse(amount0, amount1);
    }

    //
    // INTERNAL VIEW
    //

    function getPool(
        address factory,
        address quoteToken,
        address baseToken,
        uint24 uniswapFeeRatio
    ) external view returns (address) {
        PoolAddress.PoolKey memory poolKeys = PoolAddress.getPoolKey(quoteToken, baseToken, uniswapFeeRatio);
        return IUniswapV3Factory(factory).getPool(poolKeys.token0, poolKeys.token1, uniswapFeeRatio);
    }

    function getTickSpacing(address pool) public view returns (int24 tickSpacing) {
        tickSpacing = IUniswapV3Pool(pool).tickSpacing();
    }

    function getSlot0(
        address pool
    )
        public
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        )
    {
        return IUniswapV3Pool(pool).slot0();
    }

    function getTick(address pool) external view returns (int24 tick) {
        (, tick, , , , , ) = IUniswapV3Pool(pool).slot0();
    }

    function getIsTickInitialized(address pool, int24 tick) external view returns (bool initialized) {
        (, , , , , , , initialized) = IUniswapV3Pool(pool).ticks(tick);
    }

    function getTickLiquidityNet(address pool, int24 tick) public view returns (int128 liquidityNet) {
        (, liquidityNet, , , , , , ) = IUniswapV3Pool(pool).ticks(tick);
    }

    function getSqrtMarkPriceX96(address pool) external view returns (uint160 sqrtMarkPrice) {
        (sqrtMarkPrice, , , , , , ) = IUniswapV3Pool(pool).slot0();
    }

    function getLiquidity(address pool) external view returns (uint128 liquidity) {
        return IUniswapV3Pool(pool).liquidity();
    }

    /// @dev if twapInterval < 10 (should be less than 1 block), return mark price without twap directly,
    ///      as twapInterval is too short and makes getting twap over such a short period meaningless
    function getSqrtMarkTwapX96(address pool, uint32 twapInterval) external view returns (uint160) {
        return getSqrtMarkTwapX96From(pool, 0, twapInterval);
    }

    function getSqrtMarkTwapX96From(
        address pool,
        uint32 secondsAgo,
        uint32 twapInterval
    ) public view returns (uint160) {
        // return the current price as twapInterval is too short/ meaningless
        if (twapInterval < 10) {
            (uint160 sqrtMarkPrice, , , , , , ) = getSlot0(pool);
            return sqrtMarkPrice;
        }
        uint32[] memory secondsAgos = new uint32[](2);

        // solhint-disable-next-line not-rely-on-time
        secondsAgos[0] = secondsAgo + twapInterval;
        secondsAgos[1] = secondsAgo;
        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondsAgos);

        // tick(imprecise as it's an integer) to price
        return TickMath.getSqrtRatioAtTick(int24((tickCumulatives[1] - tickCumulatives[0]) / twapInterval));
    }

    // copied from UniswapV3-core
    /// @param isBaseToQuote originally lte, meaning that the next tick < the current tick
    function getNextInitializedTickWithinOneWord(
        address pool,
        int24 tick,
        int24 tickSpacing,
        bool isBaseToQuote
    ) public view returns (int24 next, bool initialized) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

        if (isBaseToQuote) {
            (int16 wordPos, uint8 bitPos) = _getPositionOfInitializedTickWithinOneWord(compressed);
            // all the 1s at or to the right of the current bitPos
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = _getTickBitmap(pool, wordPos) & mask;

            // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed - int24(bitPos - BitMath.mostSignificantBit(masked))) * tickSpacing
                : (compressed - int24(bitPos)) * tickSpacing;
        } else {
            // start from the word of the next tick, since the current tick state doesn't matter
            (int16 wordPos, uint8 bitPos) = _getPositionOfInitializedTickWithinOneWord(compressed + 1);
            // all the 1s at or to the left of the bitPos
            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = _getTickBitmap(pool, wordPos) & mask;

            // if there are no initialized ticks to the left of the current tick, return leftmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed + 1 + int24(BitMath.leastSignificantBit(masked) - bitPos)) * tickSpacing
                : (compressed + 1 + int24(type(uint8).max - bitPos)) * tickSpacing;
        }
    }

    function getSwapState(
        address pool,
        int256 signedScaledAmountForReplaySwap
    ) public view returns (SwapState memory) {
        (uint160 sqrtMarkPrice, int24 tick, , , , , ) = getSlot0(pool);
        uint128 liquidity = IUniswapV3Pool(pool).liquidity();
        return
            SwapState({
                tick: tick,
                sqrtPriceX96: sqrtMarkPrice,
                amountSpecifiedRemaining: signedScaledAmountForReplaySwap,
                liquidity: liquidity
            });
    }

    //
    // PRIVATE VIEW
    //

    function _getTickBitmap(address pool, int16 wordPos) private view returns (uint256 tickBitmap) {
        return IUniswapV3Pool(pool).tickBitmap(wordPos);
    }

    /// @dev this function is Uniswap's TickBitmap.position()
    function _getPositionOfInitializedTickWithinOneWord(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(tick % 256);
    }

    function getFullTickForLiquidity(address pool) public view returns (int24 lowerTick, int24 upperTick) {
        int24 tickSpacing = IUniswapV3Pool(pool).tickSpacing();
        lowerTick = (TickMath.MIN_TICK / tickSpacing) * tickSpacing;
        upperTick = (TickMath.MAX_TICK / tickSpacing) * tickSpacing;
    }

    function replaySwap(
        address pool,
        ReplaySwapParams memory params
    ) external view returns (ReplaySwapResponse memory) {
        // address pool = IMarketRegistry(marketRegistry).getPool(params.baseToken);
        bool isExactInput = params.amount > 0;
        uint256 fee;

        SwapState memory swapState = getSwapState(pool, params.amount);

        params.sqrtPriceLimitX96 = params.sqrtPriceLimitX96 == 0
            ? (params.isBaseToQuote ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
            : params.sqrtPriceLimitX96;

        // if there is residue in amountSpecifiedRemaining, makers can get a tiny little bit less than expected,
        // which is safer for the system
        int24 tickSpacing = getTickSpacing(pool);

        while (swapState.amountSpecifiedRemaining != 0 && swapState.sqrtPriceX96 != params.sqrtPriceLimitX96) {
            InternalSwapStep memory step;
            step.initialSqrtPriceX96 = swapState.sqrtPriceX96;

            // find next tick
            // note the search is bounded in one word
            (step.nextTick, step.isNextTickInitialized) = getNextInitializedTickWithinOneWord(
                pool,
                swapState.tick,
                tickSpacing,
                params.isBaseToQuote
            );

            // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
            if (step.nextTick < TickMath.MIN_TICK) {
                step.nextTick = TickMath.MIN_TICK;
            } else if (step.nextTick > TickMath.MAX_TICK) {
                step.nextTick = TickMath.MAX_TICK;
            }

            // get the next price of this step (either next tick's price or the ending price)
            // use sqrtPrice instead of tick is more precise
            step.nextSqrtPriceX96 = TickMath.getSqrtRatioAtTick(step.nextTick);

            // find the next swap checkpoint
            // (either reached the next price of this step, or exhausted remaining amount specified)
            (swapState.sqrtPriceX96, step.amountIn, step.amountOut, step.fee) = SwapMath.computeSwapStep(
                swapState.sqrtPriceX96,
                (
                    params.isBaseToQuote
                        ? step.nextSqrtPriceX96 < params.sqrtPriceLimitX96
                        : step.nextSqrtPriceX96 > params.sqrtPriceLimitX96
                )
                    ? params.sqrtPriceLimitX96
                    : step.nextSqrtPriceX96,
                swapState.liquidity,
                swapState.amountSpecifiedRemaining,
                // isBaseToQuote: fee is charged in base token in uniswap pool; thus, use uniswapFeeRatio to replay
                // !isBaseToQuote: fee is charged in quote token in clearing house; thus, use exchangeFeeRatioRatio
                params.isBaseToQuote ? params.uniswapFeeRatio : 0
            );

            // user input 1 quote:
            // quote token to uniswap ===> 1*0.98/0.99 = 0.98989899
            // fee = 0.98989899 * 2% = 0.01979798
            if (isExactInput) {
                swapState.amountSpecifiedRemaining = swapState.amountSpecifiedRemaining.sub(
                    step.amountIn.add(step.fee).toInt256()
                );
            } else {
                swapState.amountSpecifiedRemaining = swapState.amountSpecifiedRemaining.add(step.amountOut.toInt256());
            }

            // update CH's global fee growth if there is liquidity in this range
            // note CH only collects quote fee when swapping base -> quote
            if (swapState.liquidity > 0) {
                if (params.isBaseToQuote) {
                    step.fee = FullMath.mulDivRoundingUp(step.amountOut, 0, 1e6);
                }
                fee += step.fee;
            }

            if (swapState.sqrtPriceX96 == step.nextSqrtPriceX96) {
                // we have reached the tick's boundary
                if (step.isNextTickInitialized) {
                    if (params.shouldUpdateState) {}
                    int128 liquidityNet = getTickLiquidityNet(pool, step.nextTick);
                    if (params.isBaseToQuote) liquidityNet = liquidityNet.neg128();
                    swapState.liquidity = LiquidityMath.addDelta(swapState.liquidity, liquidityNet);
                }

                swapState.tick = params.isBaseToQuote ? step.nextTick - 1 : step.nextTick;
            } else if (swapState.sqrtPriceX96 != step.initialSqrtPriceX96) {
                // update state.tick corresponding to the current price if the price has changed in this step
                swapState.tick = TickMath.getTickAtSqrtRatio(swapState.sqrtPriceX96);
            }
        }

        return ReplaySwapResponse({ tick: swapState.tick, fee: fee, amountIn: 0, amountOut: 0 });
    }

    function estimateSwap(
        address pool,
        ReplaySwapParams memory params
    ) public view returns (ReplaySwapResponse memory) {
        bool isExactInput = params.amount > 0;
        uint256 fee;

        uint256 amountIn;
        uint256 amountOut;

        SwapState memory swapState = getSwapState(pool, params.amount);

        params.sqrtPriceLimitX96 = params.sqrtPriceLimitX96 == 0
            ? (params.isBaseToQuote ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1)
            : params.sqrtPriceLimitX96;

        // if there is residue in amountSpecifiedRemaining, makers can get a tiny little bit less than expected,
        // which is safer for the system
        int24 tickSpacing = getTickSpacing(pool);

        while (swapState.amountSpecifiedRemaining != 0 && swapState.sqrtPriceX96 != params.sqrtPriceLimitX96) {
            InternalSwapStep memory step;
            step.initialSqrtPriceX96 = swapState.sqrtPriceX96;

            // find next tick
            // note the search is bounded in one word
            (step.nextTick, step.isNextTickInitialized) = getNextInitializedTickWithinOneWord(
                pool,
                swapState.tick,
                tickSpacing,
                params.isBaseToQuote
            );

            // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
            if (step.nextTick < TickMath.MIN_TICK) {
                step.nextTick = TickMath.MIN_TICK;
            } else if (step.nextTick > TickMath.MAX_TICK) {
                step.nextTick = TickMath.MAX_TICK;
            }

            // get the next price of this step (either next tick's price or the ending price)
            // use sqrtPrice instead of tick is more precise
            step.nextSqrtPriceX96 = TickMath.getSqrtRatioAtTick(step.nextTick);

            // find the next swap checkpoint
            // (either reached the next price of this step, or exhausted remaining amount specified)
            (swapState.sqrtPriceX96, step.amountIn, step.amountOut, step.fee) = SwapMath.computeSwapStep(
                swapState.sqrtPriceX96,
                (
                    params.isBaseToQuote
                        ? step.nextSqrtPriceX96 < params.sqrtPriceLimitX96
                        : step.nextSqrtPriceX96 > params.sqrtPriceLimitX96
                )
                    ? params.sqrtPriceLimitX96
                    : step.nextSqrtPriceX96,
                swapState.liquidity,
                swapState.amountSpecifiedRemaining,
                // isBaseToQuote: fee is charged in base token in uniswap pool; thus, use uniswapFeeRatio to replay
                // !isBaseToQuote: fee is charged in quote token in clearing house; thus, use exchangeFeeRatioRatio
                params.isBaseToQuote ? params.uniswapFeeRatio : 0
            );

            // user input 1 quote:
            // quote token to uniswap ===> 1*0.98/0.99 = 0.98989899
            // fee = 0.98989899 * 2% = 0.01979798
            if (isExactInput) {
                swapState.amountSpecifiedRemaining = swapState.amountSpecifiedRemaining.sub(
                    step.amountIn.add(step.fee).toInt256()
                );
            } else {
                swapState.amountSpecifiedRemaining = swapState.amountSpecifiedRemaining.add(step.amountOut.toInt256());
            }
            amountIn = amountIn.add(step.amountIn);
            amountOut = amountOut.add(step.amountOut);
            // update CH's global fee growth if there is liquidity in this range
            // note CH only collects quote fee when swapping base -> quote
            if (swapState.liquidity > 0) {
                if (params.isBaseToQuote) {
                    step.fee = FullMath.mulDivRoundingUp(step.amountOut, 0, 1e6);
                }
                fee += step.fee;
            }

            if (swapState.sqrtPriceX96 == step.nextSqrtPriceX96) {
                // we have reached the tick's boundary
                if (step.isNextTickInitialized) {
                    if (params.shouldUpdateState) {}
                    int128 liquidityNet = getTickLiquidityNet(pool, step.nextTick);
                    if (params.isBaseToQuote) liquidityNet = liquidityNet.neg128();
                    swapState.liquidity = LiquidityMath.addDelta(swapState.liquidity, liquidityNet);
                }

                swapState.tick = params.isBaseToQuote ? step.nextTick - 1 : step.nextTick;
            } else if (swapState.sqrtPriceX96 != step.initialSqrtPriceX96) {
                // update state.tick corresponding to the current price if the price has changed in this step
                swapState.tick = TickMath.getTickAtSqrtRatio(swapState.sqrtPriceX96);
            }
        }

        return ReplaySwapResponse({ tick: swapState.tick, fee: fee, amountIn: amountIn, amountOut: amountOut });
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './pool/IUniswapV3PoolImmutables.sol';
import './pool/IUniswapV3PoolState.sol';
import './pool/IUniswapV3PoolDerivedState.sol';
import './pool/IUniswapV3PoolActions.sol';
import './pool/IUniswapV3PoolOwnerActions.sol';
import './pool/IUniswapV3PoolEvents.sol';

/// @title The interface for a Uniswap V3 Pool
/// @notice A Uniswap pool facilitates swapping and automated market making between any two assets that strictly conform
/// to the ERC20 specification
/// @dev The pool interface is broken up into many smaller pieces
interface IUniswapV3Pool is
    IUniswapV3PoolImmutables,
    IUniswapV3PoolState,
    IUniswapV3PoolDerivedState,
    IUniswapV3PoolActions,
    IUniswapV3PoolOwnerActions,
    IUniswapV3PoolEvents
{

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -887272;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick) internal pure returns (uint160 sqrtPriceX96) {
        uint256 absTick = tick < 0 ? uint256(-int256(tick)) : uint256(int256(tick));
        require(absTick <= uint256(MAX_TICK), 'T');

        uint256 ratio = absTick & 0x1 != 0 ? 0xfffcb933bd6fad37aa2d162d1a594001 : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0) ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0) ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0) ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0) ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0) ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0) ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0) ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0) ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0) ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0) ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0) ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0) ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0) ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0) ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0) ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0) ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (absTick & 0x20000 != 0) ratio = (ratio * 0x5d6af8dedb81196699c329225ee604) >> 128;
        if (absTick & 0x40000 != 0) ratio = (ratio * 0x2216e584f5fa1ea926041bedfe98) >> 128;
        if (absTick & 0x80000 != 0) ratio = (ratio * 0x48a170391f7dc42444e8fa2) >> 128;

        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160((ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1));
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96) internal pure returns (int24 tick) {
        // second inequality must be < because the price can never reach the price at the max tick
        require(sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO, 'R');
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24((log_sqrt10001 - 3402992956809132418596140100660247210) >> 128);
        int24 tickHi = int24((log_sqrt10001 + 291339464771989622907027621153398088495) >> 128);

        tick = tickLow == tickHi ? tickLow : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96 ? tickHi : tickLow;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '@uniswap/v3-core/contracts/libraries/FullMath.sol';
import '@uniswap/v3-core/contracts/libraries/FixedPoint96.sol';

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {
    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of token0 and price range
    /// @dev Calculates amount0 * (sqrt(upper) * sqrt(lower)) / (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount0 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount0(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        uint256 intermediate = FullMath.mulDiv(sqrtRatioAX96, sqrtRatioBX96, FixedPoint96.Q96);
        return toUint128(FullMath.mulDiv(amount0, intermediate, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the amount of liquidity received for a given amount of token1 and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

    /// @notice Computes the maximum amount of liquidity received for a given amount of token0, token1, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount0 The amount of token0 being sent in
    /// @param amount1 The amount of token1 being sent in
    /// @return liquidity The maximum amount of liquidity received
    function getLiquidityForAmounts(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount0,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            liquidity = getLiquidityForAmount0(sqrtRatioAX96, sqrtRatioBX96, amount0);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            uint128 liquidity0 = getLiquidityForAmount0(sqrtRatioX96, sqrtRatioBX96, amount0);
            uint128 liquidity1 = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioX96, amount1);

            liquidity = liquidity0 < liquidity1 ? liquidity0 : liquidity1;
        } else {
            liquidity = getLiquidityForAmount1(sqrtRatioAX96, sqrtRatioBX96, amount1);
        }
    }

    /// @notice Computes the amount of token0 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    function getAmount0ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            FullMath.mulDiv(
                uint256(liquidity) << FixedPoint96.RESOLUTION,
                sqrtRatioBX96 - sqrtRatioAX96,
                sqrtRatioBX96
            ) / sqrtRatioAX96;
    }

    /// @notice Computes the amount of token1 for a given amount of liquidity and a price range
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount1 The amount of token1
    function getAmount1ForLiquidity(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Computes the token0 and token1 value for a given amount of liquidity, the current
    /// pool prices and the prices at the tick boundaries
    /// @param sqrtRatioX96 A sqrt price representing the current pool prices
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param liquidity The liquidity being valued
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function getAmountsForLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity
    ) internal pure returns (uint256 amount0, uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        if (sqrtRatioX96 <= sqrtRatioAX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        } else if (sqrtRatioX96 < sqrtRatioBX96) {
            amount0 = getAmount0ForLiquidity(sqrtRatioX96, sqrtRatioBX96, liquidity);
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioX96, liquidity);
        } else {
            amount1 = getAmount1ForLiquidity(sqrtRatioAX96, sqrtRatioBX96, liquidity);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title BitMath
/// @dev This library provides functionality for computing bit properties of an unsigned integer
library BitMath {
    /// @notice Returns the index of the most significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
    /// @param x the value for which to compute the most significant bit, must be greater than 0
    /// @return r the index of the most significant bit
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    /// @notice Returns the index of the least significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
    /// @param x the value for which to compute the least significant bit, must be greater than 0
    /// @return r the index of the least significant bit
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0);

        r = 255;
        if (x & type(uint128).max > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & type(uint64).max > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & type(uint32).max > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & type(uint16).max > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & type(uint8).max > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import './FullMath.sol';
import './SqrtPriceMath.sol';

/// @title Computes the result of a swap within ticks
/// @notice Contains methods for computing the result of a swap within a single tick price range, i.e., a single tick.
library SwapMath {
    /// @notice Computes the result of swapping some amount in, or amount out, given the parameters of the swap
    /// @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
    /// @param sqrtRatioCurrentX96 The current sqrt price of the pool
    /// @param sqrtRatioTargetX96 The price that cannot be exceeded, from which the direction of the swap is inferred
    /// @param liquidity The usable liquidity
    /// @param amountRemaining How much input or output amount is remaining to be swapped in/out
    /// @param feePips The fee taken from the input amount, expressed in hundredths of a bip
    /// @return sqrtRatioNextX96 The price after swapping the amount in/out, not to exceed the price target
    /// @return amountIn The amount to be swapped in, of either token0 or token1, based on the direction of the swap
    /// @return amountOut The amount to be received, of either token0 or token1, based on the direction of the swap
    /// @return feeAmount The amount of input that will be taken as a fee
    function computeSwapStep(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        int256 amountRemaining,
        uint24 feePips
    )
        internal
        pure
        returns (
            uint160 sqrtRatioNextX96,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        )
    {
        bool zeroForOne = sqrtRatioCurrentX96 >= sqrtRatioTargetX96;
        bool exactIn = amountRemaining >= 0;

        if (exactIn) {
            uint256 amountRemainingLessFee = FullMath.mulDiv(uint256(amountRemaining), 1e6 - feePips, 1e6);
            amountIn = zeroForOne
                ? SqrtPriceMath.getAmount0Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, true)
                : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, true);
            if (amountRemainingLessFee >= amountIn) sqrtRatioNextX96 = sqrtRatioTargetX96;
            else
                sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                    sqrtRatioCurrentX96,
                    liquidity,
                    amountRemainingLessFee,
                    zeroForOne
                );
        } else {
            amountOut = zeroForOne
                ? SqrtPriceMath.getAmount1Delta(sqrtRatioTargetX96, sqrtRatioCurrentX96, liquidity, false)
                : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioTargetX96, liquidity, false);
            if (uint256(-amountRemaining) >= amountOut) sqrtRatioNextX96 = sqrtRatioTargetX96;
            else
                sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
                    sqrtRatioCurrentX96,
                    liquidity,
                    uint256(-amountRemaining),
                    zeroForOne
                );
        }

        bool max = sqrtRatioTargetX96 == sqrtRatioNextX96;

        // get the input/output amounts
        if (zeroForOne) {
            amountIn = max && exactIn
                ? amountIn
                : SqrtPriceMath.getAmount0Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, true);
            amountOut = max && !exactIn
                ? amountOut
                : SqrtPriceMath.getAmount1Delta(sqrtRatioNextX96, sqrtRatioCurrentX96, liquidity, false);
        } else {
            amountIn = max && exactIn
                ? amountIn
                : SqrtPriceMath.getAmount1Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, true);
            amountOut = max && !exactIn
                ? amountOut
                : SqrtPriceMath.getAmount0Delta(sqrtRatioCurrentX96, sqrtRatioNextX96, liquidity, false);
        }

        // cap the output amount to not exceed the remaining output amount
        if (!exactIn && amountOut > uint256(-amountRemaining)) {
            amountOut = uint256(-amountRemaining);
        }

        if (exactIn && sqrtRatioNextX96 != sqrtRatioTargetX96) {
            // we didn't reach the target, so take the remainder of the maximum input as fee
            feeAmount = uint256(amountRemaining) - amountIn;
        } else {
            feeAmount = FullMath.mulDivRoundingUp(amountIn, feePips, 1e6 - feePips);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for liquidity
library LiquidityMath {
    /// @notice Add a signed liquidity delta to liquidity and revert if it overflows or underflows
    /// @param x The liquidity before change
    /// @param y The delta by which liquidity should be changed
    /// @return z The liquidity delta
    function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
        if (y < 0) {
            require((z = x - uint128(-y)) < x, 'LS');
        } else {
            require((z = x + uint128(y)) >= x, 'LA');
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that never changes
/// @notice These parameters are fixed for a pool forever, i.e., the methods will always return the same values
interface IUniswapV3PoolImmutables {
    /// @notice The contract that deployed the pool, which must adhere to the IUniswapV3Factory interface
    /// @return The contract address
    function factory() external view returns (address);

    /// @notice The first of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token0() external view returns (address);

    /// @notice The second of the two tokens of the pool, sorted by address
    /// @return The token contract address
    function token1() external view returns (address);

    /// @notice The pool's fee in hundredths of a bip, i.e. 1e-6
    /// @return The fee
    function fee() external view returns (uint24);

    /// @notice The pool tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter is enforced per tick to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to a pool
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that can change
/// @notice These methods compose the pool's state, and can change with any frequency including multiple times
/// per transaction
interface IUniswapV3PoolState {
    /// @notice The 0th storage slot in the pool stores many values, and is exposed as a single method to save gas
    /// when accessed externally.
    /// @return sqrtPriceX96 The current price of the pool as a sqrt(token1/token0) Q64.96 value
    /// tick The current tick of the pool, i.e. according to the last tick transition that was run.
    /// This value may not always be equal to SqrtTickMath.getTickAtSqrtRatio(sqrtPriceX96) if the price is on a tick
    /// boundary.
    /// observationIndex The index of the last oracle observation that was written,
    /// observationCardinality The current maximum number of observations stored in the pool,
    /// observationCardinalityNext The next maximum number of observations, to be updated when the observation.
    /// feeProtocol The protocol fee for both tokens of the pool.
    /// Encoded as two 4 bit values, where the protocol fee of token1 is shifted 4 bits and the protocol fee of token0
    /// is the lower 4 bits. Used as the denominator of a fraction of the swap fee, e.g. 4 means 1/4th of the swap fee.
    /// unlocked Whether the pool is currently locked to reentrancy
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        );

    /// @notice The fee growth as a Q128.128 fees of token0 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal0X128() external view returns (uint256);

    /// @notice The fee growth as a Q128.128 fees of token1 collected per unit of liquidity for the entire life of the pool
    /// @dev This value can overflow the uint256
    function feeGrowthGlobal1X128() external view returns (uint256);

    /// @notice The amounts of token0 and token1 that are owed to the protocol
    /// @dev Protocol fees will never exceed uint128 max in either token
    function protocolFees() external view returns (uint128 token0, uint128 token1);

    /// @notice The currently in range liquidity available to the pool
    /// @dev This value has no relationship to the total liquidity across all ticks
    function liquidity() external view returns (uint128);

    /// @notice Look up information about a specific tick in the pool
    /// @param tick The tick to look up
    /// @return liquidityGross the total amount of position liquidity that uses the pool either as tick lower or
    /// tick upper,
    /// liquidityNet how much liquidity changes when the pool price crosses the tick,
    /// feeGrowthOutside0X128 the fee growth on the other side of the tick from the current tick in token0,
    /// feeGrowthOutside1X128 the fee growth on the other side of the tick from the current tick in token1,
    /// tickCumulativeOutside the cumulative tick value on the other side of the tick from the current tick
    /// secondsPerLiquidityOutsideX128 the seconds spent per liquidity on the other side of the tick from the current tick,
    /// secondsOutside the seconds spent on the other side of the tick from the current tick,
    /// initialized Set to true if the tick is initialized, i.e. liquidityGross is greater than 0, otherwise equal to false.
    /// Outside values can only be used if the tick is initialized, i.e. if liquidityGross is greater than 0.
    /// In addition, these values are only relative and must be used only in comparison to previous snapshots for
    /// a specific position.
    function ticks(int24 tick)
        external
        view
        returns (
            uint128 liquidityGross,
            int128 liquidityNet,
            uint256 feeGrowthOutside0X128,
            uint256 feeGrowthOutside1X128,
            int56 tickCumulativeOutside,
            uint160 secondsPerLiquidityOutsideX128,
            uint32 secondsOutside,
            bool initialized
        );

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Returns the information about a position by the position's key
    /// @param key The position's key is a hash of a preimage composed by the owner, tickLower and tickUpper
    /// @return _liquidity The amount of liquidity in the position,
    /// Returns feeGrowthInside0LastX128 fee growth of token0 inside the tick range as of the last mint/burn/poke,
    /// Returns feeGrowthInside1LastX128 fee growth of token1 inside the tick range as of the last mint/burn/poke,
    /// Returns tokensOwed0 the computed amount of token0 owed to the position as of the last mint/burn/poke,
    /// Returns tokensOwed1 the computed amount of token1 owed to the position as of the last mint/burn/poke
    function positions(bytes32 key)
        external
        view
        returns (
            uint128 _liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    /// @notice Returns data about a specific observation index
    /// @param index The element of the observations array to fetch
    /// @dev You most likely want to use #observe() instead of this method to get an observation as of some amount of time
    /// ago, rather than at a specific index in the array.
    /// @return blockTimestamp The timestamp of the observation,
    /// Returns tickCumulative the tick multiplied by seconds elapsed for the life of the pool as of the observation timestamp,
    /// Returns secondsPerLiquidityCumulativeX128 the seconds per in range liquidity for the life of the pool as of the observation timestamp,
    /// Returns initialized whether the observation has been initialized and the values are safe to use
    function observations(uint256 index)
        external
        view
        returns (
            uint32 blockTimestamp,
            int56 tickCumulative,
            uint160 secondsPerLiquidityCumulativeX128,
            bool initialized
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Pool state that is not stored
/// @notice Contains view functions to provide information about the pool that is computed rather than stored on the
/// blockchain. The functions here may have variable gas costs.
interface IUniswapV3PoolDerivedState {
    /// @notice Returns the cumulative tick and liquidity as of each timestamp `secondsAgo` from the current block timestamp
    /// @dev To get a time weighted average tick or liquidity-in-range, you must call this with two values, one representing
    /// the beginning of the period and another for the end of the period. E.g., to get the last hour time-weighted average tick,
    /// you must call it with secondsAgos = [3600, 0].
    /// @dev The time weighted average tick represents the geometric time weighted average price of the pool, in
    /// log base sqrt(1.0001) of token1 / token0. The TickMath library can be used to go from a tick value to a ratio.
    /// @param secondsAgos From how long ago each cumulative tick and liquidity value should be returned
    /// @return tickCumulatives Cumulative tick values as of each `secondsAgos` from the current block timestamp
    /// @return secondsPerLiquidityCumulativeX128s Cumulative seconds per liquidity-in-range value as of each `secondsAgos` from the current block
    /// timestamp
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);

    /// @notice Returns a snapshot of the tick cumulative, seconds per liquidity and seconds inside a tick range
    /// @dev Snapshots must only be compared to other snapshots, taken over a period for which a position existed.
    /// I.e., snapshots cannot be compared if a position is not held for the entire period between when the first
    /// snapshot is taken and the second snapshot is taken.
    /// @param tickLower The lower tick of the range
    /// @param tickUpper The upper tick of the range
    /// @return tickCumulativeInside The snapshot of the tick accumulator for the range
    /// @return secondsPerLiquidityInsideX128 The snapshot of seconds per liquidity for the range
    /// @return secondsInside The snapshot of seconds per liquidity for the range
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissionless pool actions
/// @notice Contains pool methods that can be called by anyone
interface IUniswapV3PoolActions {
    /// @notice Sets the initial price for the pool
    /// @dev Price is represented as a sqrt(amountToken1/amountToken0) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the pool as a Q64.96
    function initialize(uint160 sqrtPriceX96) external;

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @dev The caller of this method receives a callback in the form of IUniswapV3MintCallback#uniswapV3MintCallback
    /// in which they must pay any token0 or token1 owed for the liquidity. The amount of token0/token1 due depends
    /// on tickLower, tickUpper, the amount of liquidity, and the current price.
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    /// @param data Any data that should be passed through to the callback
    /// @return amount0 The amount of token0 that was paid to mint the given amount of liquidity. Matches the value in the callback
    /// @return amount1 The amount of token1 that was paid to mint the given amount of liquidity. Matches the value in the callback
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Collects tokens owed to a position
    /// @dev Does not recompute fees earned, which must be done either via mint or burn of any amount of liquidity.
    /// Collect must be called by the position owner. To withdraw only token0 or only token1, amount0Requested or
    /// amount1Requested may be set to zero. To withdraw all tokens owed, caller may pass any value greater than the
    /// actual tokens owed, e.g. type(uint128).max. Tokens owed may be from accumulated swap fees or burned liquidity.
    /// @param recipient The address which should receive the fees collected
    /// @param tickLower The lower tick of the position for which to collect fees
    /// @param tickUpper The upper tick of the position for which to collect fees
    /// @param amount0Requested How much token0 should be withdrawn from the fees owed
    /// @param amount1Requested How much token1 should be withdrawn from the fees owed
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);

    /// @notice Burn liquidity from the sender and account tokens owed for the liquidity to the position
    /// @dev Can be used to trigger a recalculation of fees owed to a position by calling with an amount of 0
    /// @dev Fees must be collected separately via a call to #collect
    /// @param tickLower The lower tick of the position for which to burn liquidity
    /// @param tickUpper The upper tick of the position for which to burn liquidity
    /// @param amount How much liquidity to burn
    /// @return amount0 The amount of token0 sent to the recipient
    /// @return amount1 The amount of token1 sent to the recipient
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (uint256 amount0, uint256 amount1);

    /// @notice Swap token0 for token1, or token1 for token0
    /// @dev The caller of this method receives a callback in the form of IUniswapV3SwapCallback#uniswapV3SwapCallback
    /// @param recipient The address to receive the output of the swap
    /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
    /// @param amountSpecified The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @param sqrtPriceLimitX96 The Q64.96 sqrt price limit. If zero for one, the price cannot be less than this
    /// value after the swap. If one for zero, the price cannot be greater than this value after the swap
    /// @param data Any data to be passed through to the callback
    /// @return amount0 The delta of the balance of token0 of the pool, exact when negative, minimum when positive
    /// @return amount1 The delta of the balance of token1 of the pool, exact when negative, minimum when positive
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);

    /// @notice Receive token0 and/or token1 and pay it back, plus a fee, in the callback
    /// @dev The caller of this method receives a callback in the form of IUniswapV3FlashCallback#uniswapV3FlashCallback
    /// @dev Can be used to donate underlying tokens pro-rata to currently in-range liquidity providers by calling
    /// with 0 amount{0,1} and sending the donation amount(s) from the callback
    /// @param recipient The address which will receive the token0 and token1 amounts
    /// @param amount0 The amount of token0 to send
    /// @param amount1 The amount of token1 to send
    /// @param data Any data to be passed through to the callback
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;

    /// @notice Increase the maximum number of price and liquidity observations that this pool will store
    /// @dev This method is no-op if the pool already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param observationCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Permissioned pool actions
/// @notice Contains pool methods that may only be called by the factory owner
interface IUniswapV3PoolOwnerActions {
    /// @notice Set the denominator of the protocol's % share of the fees
    /// @param feeProtocol0 new protocol fee for token0 of the pool
    /// @param feeProtocol1 new protocol fee for token1 of the pool
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external;

    /// @notice Collect the protocol fee accrued to the pool
    /// @param recipient The address to which collected protocol fees should be sent
    /// @param amount0Requested The maximum amount of token0 to send, can be 0 to collect fees in only token1
    /// @param amount1Requested The maximum amount of token1 to send, can be 0 to collect fees in only token0
    /// @return amount0 The protocol fee collected in token0
    /// @return amount1 The protocol fee collected in token1
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external returns (uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Events emitted by a pool
/// @notice Contains all events emitted by the pool
interface IUniswapV3PoolEvents {
    /// @notice Emitted exactly once by a pool when #initialize is first called on the pool
    /// @dev Mint/Burn/Swap cannot be emitted by the pool before Initialize
    /// @param sqrtPriceX96 The initial sqrt price of the pool, as a Q64.96
    /// @param tick The initial tick of the pool, i.e. log base 1.0001 of the starting price of the pool
    event Initialize(uint160 sqrtPriceX96, int24 tick);

    /// @notice Emitted when liquidity is minted for a given position
    /// @param sender The address that minted the liquidity
    /// @param owner The owner of the position and recipient of any minted liquidity
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity minted to the position range
    /// @param amount0 How much token0 was required for the minted liquidity
    /// @param amount1 How much token1 was required for the minted liquidity
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted when fees are collected by the owner of a position
    /// @dev Collect events may be emitted with zero amount0 and amount1 when the caller chooses not to collect fees
    /// @param owner The owner of the position for which fees are collected
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount0 The amount of token0 fees collected
    /// @param amount1 The amount of token1 fees collected
    event Collect(
        address indexed owner,
        address recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount0,
        uint128 amount1
    );

    /// @notice Emitted when a position's liquidity is removed
    /// @dev Does not withdraw any fees earned by the liquidity position, which must be withdrawn via #collect
    /// @param owner The owner of the position for which liquidity is removed
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @param amount The amount of liquidity to remove
    /// @param amount0 The amount of token0 withdrawn
    /// @param amount1 The amount of token1 withdrawn
    event Burn(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount,
        uint256 amount0,
        uint256 amount1
    );

    /// @notice Emitted by the pool for any swaps between token0 and token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the output of the swap
    /// @param amount0 The delta of the token0 balance of the pool
    /// @param amount1 The delta of the token1 balance of the pool
    /// @param sqrtPriceX96 The sqrt(price) of the pool after the swap, as a Q64.96
    /// @param liquidity The liquidity of the pool after the swap
    /// @param tick The log base 1.0001 of price of the pool after the swap
    event Swap(
        address indexed sender,
        address indexed recipient,
        int256 amount0,
        int256 amount1,
        uint160 sqrtPriceX96,
        uint128 liquidity,
        int24 tick
    );

    /// @notice Emitted by the pool for any flashes of token0/token1
    /// @param sender The address that initiated the swap call, and that received the callback
    /// @param recipient The address that received the tokens from flash
    /// @param amount0 The amount of token0 that was flashed
    /// @param amount1 The amount of token1 that was flashed
    /// @param paid0 The amount of token0 paid for the flash, which can exceed the amount0 plus the fee
    /// @param paid1 The amount of token1 paid for the flash, which can exceed the amount1 plus the fee
    event Flash(
        address indexed sender,
        address indexed recipient,
        uint256 amount0,
        uint256 amount1,
        uint256 paid0,
        uint256 paid1
    );

    /// @notice Emitted by the pool for increases to the number of observations that can be stored
    /// @dev observationCardinalityNext is not the observation cardinality until an observation is written at the index
    /// just before a mint/swap/burn.
    /// @param observationCardinalityNextOld The previous value of the next observation cardinality
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event IncreaseObservationCardinalityNext(
        uint16 observationCardinalityNextOld,
        uint16 observationCardinalityNextNew
    );

    /// @notice Emitted when the protocol fee is changed by the pool
    /// @param feeProtocol0Old The previous value of the token0 protocol fee
    /// @param feeProtocol1Old The previous value of the token1 protocol fee
    /// @param feeProtocol0New The updated value of the token0 protocol fee
    /// @param feeProtocol1New The updated value of the token1 protocol fee
    event SetFeeProtocol(uint8 feeProtocol0Old, uint8 feeProtocol1Old, uint8 feeProtocol0New, uint8 feeProtocol1New);

    /// @notice Emitted when the collected protocol fees are withdrawn by the factory owner
    /// @param sender The address that collects the protocol fees
    /// @param recipient The address that receives the collected protocol fees
    /// @param amount0 The amount of token0 protocol fees that is withdrawn
    /// @param amount0 The amount of token1 protocol fees that is withdrawn
    event CollectProtocol(address indexed sender, address indexed recipient, uint128 amount0, uint128 amount1);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import './LowGasSafeMath.sol';
import './SafeCast.sol';

import './FullMath.sol';
import './UnsafeMath.sol';
import './FixedPoint96.sol';

/// @title Functions based on Q64.96 sqrt price and liquidity
/// @notice Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
library SqrtPriceMath {
    using LowGasSafeMath for uint256;
    using SafeCast for uint256;

    /// @notice Gets the next sqrt price given a delta of token0
    /// @dev Always rounds up, because in the exact output case (increasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (decreasing price) we need to move the
    /// price less in order to not send too much output.
    /// The most precise formula for this is liquidity * sqrtPX96 / (liquidity +- amount * sqrtPX96),
    /// if this is impossible because of overflow, we calculate liquidity / (liquidity / sqrtPX96 +- amount).
    /// @param sqrtPX96 The starting price, i.e. before accounting for the token0 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token0 to add or remove from virtual reserves
    /// @param add Whether to add or remove the amount of token0
    /// @return The price after adding or removing amount, depending on add
    function getNextSqrtPriceFromAmount0RoundingUp(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // we short circuit amount == 0 because the result is otherwise not guaranteed to equal the input price
        if (amount == 0) return sqrtPX96;
        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;

        if (add) {
            uint256 product;
            if ((product = amount * sqrtPX96) / amount == sqrtPX96) {
                uint256 denominator = numerator1 + product;
                if (denominator >= numerator1)
                    // always fits in 160 bits
                    return uint160(FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator));
            }

            return uint160(UnsafeMath.divRoundingUp(numerator1, (numerator1 / sqrtPX96).add(amount)));
        } else {
            uint256 product;
            // if the product overflows, we know the denominator underflows
            // in addition, we must check that the denominator does not underflow
            require((product = amount * sqrtPX96) / amount == sqrtPX96 && numerator1 > product);
            uint256 denominator = numerator1 - product;
            return FullMath.mulDivRoundingUp(numerator1, sqrtPX96, denominator).toUint160();
        }
    }

    /// @notice Gets the next sqrt price given a delta of token1
    /// @dev Always rounds down, because in the exact output case (decreasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (increasing price) we need to move the
    /// price less in order to not send too much output.
    /// The formula we compute is within <1 wei of the lossless version: sqrtPX96 +- amount / liquidity
    /// @param sqrtPX96 The starting price, i.e., before accounting for the token1 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token1 to add, or remove, from virtual reserves
    /// @param add Whether to add, or remove, the amount of token1
    /// @return The price after adding or removing `amount`
    function getNextSqrtPriceFromAmount1RoundingDown(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // if we're adding (subtracting), rounding down requires rounding the quotient down (up)
        // in both cases, avoid a mulDiv for most inputs
        if (add) {
            uint256 quotient =
                (
                    amount <= type(uint160).max
                        ? (amount << FixedPoint96.RESOLUTION) / liquidity
                        : FullMath.mulDiv(amount, FixedPoint96.Q96, liquidity)
                );

            return uint256(sqrtPX96).add(quotient).toUint160();
        } else {
            uint256 quotient =
                (
                    amount <= type(uint160).max
                        ? UnsafeMath.divRoundingUp(amount << FixedPoint96.RESOLUTION, liquidity)
                        : FullMath.mulDivRoundingUp(amount, FixedPoint96.Q96, liquidity)
                );

            require(sqrtPX96 > quotient);
            // always fits 160 bits
            return uint160(sqrtPX96 - quotient);
        }
    }

    /// @notice Gets the next sqrt price given an input amount of token0 or token1
    /// @dev Throws if price or liquidity are 0, or if the next price is out of bounds
    /// @param sqrtPX96 The starting price, i.e., before accounting for the input amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountIn How much of token0, or token1, is being swapped in
    /// @param zeroForOne Whether the amount in is token0 or token1
    /// @return sqrtQX96 The price after adding the input amount to token0 or token1
    function getNextSqrtPriceFromInput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountIn,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        // round to make sure that we don't pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountIn, true)
                : getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountIn, true);
    }

    /// @notice Gets the next sqrt price given an output amount of token0 or token1
    /// @dev Throws if price or liquidity are 0 or the next price is out of bounds
    /// @param sqrtPX96 The starting price before accounting for the output amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountOut How much of token0, or token1, is being swapped out
    /// @param zeroForOne Whether the amount out is token0 or token1
    /// @return sqrtQX96 The price after removing the output amount of token0 or token1
    function getNextSqrtPriceFromOutput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountOut,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0);
        require(liquidity > 0);

        // round to make sure that we pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount1RoundingDown(sqrtPX96, liquidity, amountOut, false)
                : getNextSqrtPriceFromAmount0RoundingUp(sqrtPX96, liquidity, amountOut, false);
    }

    /// @notice Gets the amount0 delta between two prices
    /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
    /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up or down
    /// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

        require(sqrtRatioAX96 > 0);

        return
            roundUp
                ? UnsafeMath.divRoundingUp(
                    FullMath.mulDivRoundingUp(numerator1, numerator2, sqrtRatioBX96),
                    sqrtRatioAX96
                )
                : FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) / sqrtRatioAX96;
    }

    /// @notice Gets the amount1 delta between two prices
    /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up, or down
    /// @return amount1 Amount of token1 required to cover a position of size liquidity between the two passed prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        return
            roundUp
                ? FullMath.mulDivRoundingUp(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96)
                : FullMath.mulDiv(liquidity, sqrtRatioBX96 - sqrtRatioAX96, FixedPoint96.Q96);
    }

    /// @notice Helper that gets signed token0 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount0 delta
    /// @return amount0 Amount of token0 corresponding to the passed liquidityDelta between the two prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount0) {
        return
            liquidity < 0
                ? -getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                : getAmount0Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
    }

    /// @notice Helper that gets signed token1 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount1 delta
    /// @return amount1 Amount of token1 corresponding to the passed liquidityDelta between the two prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount1) {
        return
            liquidity < 0
                ? -getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(-liquidity), false).toInt256()
                : getAmount1Delta(sqrtRatioAX96, sqrtRatioBX96, uint128(liquidity), true).toInt256();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCast {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y);
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y);
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255);
        z = int256(y);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import "../AccountBalance.sol";

contract TestAccountBalance is AccountBalance {
    using AddressUpgradeable for address;

    uint256 private _testBlockTimestamp;

    // copy paste from AccountBalance.initialize to avoid it to be public
    function __TestAccountBalance_init(address clearingHouseConfigArg) external initializer {
        // ClearingHouseConfig address is not contract
        require(clearingHouseConfigArg.isContract(), "AB_ENC");

        __ClearingHouseCallee_init();

        _clearingHouseConfig = clearingHouseConfigArg;
    }

    function setBlockTimestamp(uint256 blockTimestamp) external {
        _testBlockTimestamp = blockTimestamp;
    }

    function getBlockTimestamp() external view returns (uint256) {
        return _testBlockTimestamp;
    }

    function _blockTimestamp() internal view override returns (uint256) {
        return _testBlockTimestamp;
    }

    function getNetQuoteBalanceAndPendingFee(
        address trader
    ) external view returns (int256 netQuoteBalance, uint256 pendingFee) {
        return _getNetQuoteBalanceAndPendingFee(trader);
    }

    function testModifyOwedRealizedPnl(address trader, int256 owedRealizedPnlDelta) external {
        _modifyOwedRealizedPnl(trader, owedRealizedPnlDelta);
    }

    function testMarketMultiplier(
        address baseToken,
        uint256 longMultiplierX10_18,
        uint256 shortMultiplierX10_18
    ) external {
        if (_marketMap[baseToken].longMultiplierX10_18 == 0) {
            _marketMap[baseToken].longMultiplierX10_18 = 1e18;
        }
        if (_marketMap[baseToken].shortMultiplierX10_18 == 0) {
            _marketMap[baseToken].shortMultiplierX10_18 = 1e18;
        }
        _marketMap[baseToken].longMultiplierX10_18 = longMultiplierX10_18;
        _marketMap[baseToken].shortMultiplierX10_18 = shortMultiplierX10_18;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { PerpSafeCast } from "../lib/PerpSafeCast.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { SignedSafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import "../ClearingHouse.sol";
import "./TestAccountBalance.sol";
import "./TestVPool.sol";

contract TestClearingHouse is ClearingHouse {
    using PerpSafeCast for uint256;
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;

    uint256 private _testBlockTimestamp;

    function __TestClearingHouse_init(
        address configArg,
        address vaultArg,
        address quoteTokenArg,
        address uniV3FactoryArg,
        address exchangeArg,
        address accountBalanceArg,
        address marketRegistryArg,
        address insuranceFundArg,
        address platformFundArg,
        address makerArg
    ) external initializer {
        ClearingHouse.initialize(
            configArg,
            vaultArg,
            quoteTokenArg,
            uniV3FactoryArg,
            exchangeArg,
            accountBalanceArg,
            marketRegistryArg,
            insuranceFundArg,
            platformFundArg,
            makerArg
        );
        _testBlockTimestamp = block.timestamp;
    }

    function setBlockTimestamp(uint256 blockTimestamp) external {
        TestAccountBalance(_accountBalance).setBlockTimestamp(blockTimestamp);
        TestVPool(_vPool).setBlockTimestamp(blockTimestamp);
        _testBlockTimestamp = blockTimestamp;
    }

    function getBlockTimestamp() external view returns (uint256) {
        return _testBlockTimestamp;
    }

    function _blockTimestamp() internal view override returns (uint256) {
        return _testBlockTimestamp;
    }

    function setDelegateApprovalUnsafe(address delegateApprovalArg) external onlyOwner {
        _delegateApproval = delegateApprovalArg;
        emit DelegateApprovalChanged(delegateApprovalArg);
    }

    //
    // BELOW WERE LEGACY EXTERNAL FUNCTION, MOVE TO HERE FOR THE TESTING, CAN BE REMOVE LATER ONCE WE CLEAN THE TESTS
    //

    struct SwapParams {
        address baseToken;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint160 sqrtPriceLimitX96; // price slippage protection
    }

    function swap(SwapParams memory params) external nonReentrant() returns (IVPool.SwapResponse memory) {
        IAccountBalance(_accountBalance).registerBaseToken(_msgSender(), params.baseToken);

        IVPool.SwapResponse memory response =
            IVPool(_vPool).swap(
                IVPool.SwapParams({
                    trader: _msgSender(),
                    baseToken: params.baseToken,
                    isBaseToQuote: params.isBaseToQuote,
                    isExactInput: params.isExactInput,
                    isClose: false,
                    amount: params.amount,
                    sqrtPriceLimitX96: params.sqrtPriceLimitX96
                })
            );

        IAccountBalance(_accountBalance).modifyTakerBalance(
            _msgSender(),
            params.baseToken,
            response.exchangedPositionSize,
            response.exchangedPositionNotional.sub(response.insuranceFundFee.add(response.platformFundFee).toInt256())
        );

        if (response.pnlToBeRealized != 0) {
            IAccountBalance(_accountBalance).settleQuoteToOwedRealizedPnl(
                _msgSender(),
                params.baseToken,
                response.pnlToBeRealized
            );
        }
        return response;
    }

    function getTokenBalance(address trader, address baseToken) external view returns (int256, int256) {
        int256 base = IAccountBalance(_accountBalance).getBase(trader, baseToken);
        int256 quote = IAccountBalance(_accountBalance).getQuote(trader, baseToken);
        return (base, quote);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { SignedSafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import { IUniswapV3MintCallback } from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import { IUniswapV3SwapCallback } from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import { PerpMath } from "./lib/PerpMath.sol";
import { OwnerPausable } from "./base/OwnerPausable.sol";
import { IERC20Metadata } from "./interface/IERC20Metadata.sol";
import { IVault } from "./interface/IVault.sol";
import { IVPool } from "./interface/IVPool.sol";
import { IIndexPrice } from "./interface/IIndexPrice.sol";
import { IClearingHouseConfig } from "./interface/IClearingHouseConfig.sol";
import { IAccountBalance } from "./interface/IAccountBalance.sol";
import { IInsuranceFund } from "./interface/IInsuranceFund.sol";
import { IBaseToken } from "./interface/IBaseToken.sol";
import { IIndexPrice } from "./interface/IIndexPrice.sol";
import { IDelegateApproval } from "./interface/IDelegateApproval.sol";
import { BaseRelayRecipient } from "./gsn/BaseRelayRecipient.sol";
import { ClearingHouseStorage } from "./storage/ClearingHouseStorage.sol";
import { BlockContext } from "./base/BlockContext.sol";
import { IClearingHouse } from "./interface/IClearingHouse.sol";
import { ClearingHouseLogic } from "./lib/ClearingHouseLogic.sol";
import { GenericLogic } from "./lib/GenericLogic.sol";
import { IMarketRegistry } from "./interface/IMarketRegistry.sol";
import { DataTypes } from "./types/DataTypes.sol";
import { UniswapV3Broker } from "./lib/UniswapV3Broker.sol";

// never inherit any new stateful contract. never change the orders of parent stateful contracts
contract ClearingHouse is
    IUniswapV3MintCallback,
    IUniswapV3SwapCallback,
    IClearingHouse,
    BlockContext,
    ReentrancyGuardUpgradeable,
    OwnerPausable,
    BaseRelayRecipient,
    ClearingHouseStorage
{
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;
    using PerpMath for uint256;
    using PerpMath for uint160;
    using PerpMath for uint128;
    using PerpMath for int256;

    //
    // STRUCT
    //

    struct InternalRepegParams {
        uint160 oldSqrtMarkPrice;
        uint256 oldMarkPrice;
        uint160 newSqrtMarkPrice;
        uint256 newMarkPrice;
        uint256 spotPrice;
        uint160 sqrtSpotPrice;
        int256 oldDeltaBase;
        uint256 newDeltaBase;
        uint256 oldLongPositionSize;
        uint256 oldShortPositionSize;
        uint256 oldDeltaQuote;
    }

    //
    // MODIFIER
    //

    modifier checkDeadline(uint256 deadline) {
        // transaction expires
        require(_blockTimestamp() <= deadline, "CH_TE");
        _;
    }

    modifier onlyMaker() {
        // only maker
        require(_msgSender() == _maker, "CH_OM");
        _;
    }

    modifier checkSwapCallback() {
        // only exchange
        require(_msgSender() == _vPool, "CH_OE");
        _;
    }

    modifier checkMintCallback() {
        address pool = _msgSender();
        address baseToken = IUniswapV3Pool(pool).token0();
        // UCB_FCV: failed callback validation
        require(pool == IMarketRegistry(_marketRegistry).getPool(baseToken), "UCB_FCV");
        _;
    }

    //
    // EXTERNAL NON-VIEW
    //

    /// @dev this function is public for testing
    // solhint-disable-next-line func-order
    function initialize(
        address clearingHouseConfigArg,
        address vaultArg,
        address quoteTokenArg,
        address uniV3FactoryArg,
        address exchangeArg,
        address accountBalanceArg,
        address marketRegistryArg,
        address insuranceFundArg,
        address platformFundArg,
        address makerArg
    ) public initializer {
        // CH_VANC: Vault address is not contract
        _isContract(vaultArg, "CH_VANC");
        // CH_QANC: QuoteToken address is not contract
        _isContract(quoteTokenArg, "CH_QANC");
        // CH_QDN18: QuoteToken decimals is not 18
        require(IERC20Metadata(quoteTokenArg).decimals() == 18, "CH_QDN18");
        // CH_UANC: UniV3Factory address is not contract
        _isContract(uniV3FactoryArg, "CH_UANC");
        // ClearingHouseConfig address is not contract
        _isContract(clearingHouseConfigArg, "CH_CCNC");
        // AccountBalance is not contract
        _isContract(accountBalanceArg, "CH_ABNC");
        // CH_ENC: Exchange is not contract
        _isContract(exchangeArg, "CH_ENC");
        // CH_IFANC: InsuranceFund address is not contract
        _isContract(insuranceFundArg, "CH_IFANC");

        __ReentrancyGuard_init();
        __OwnerPausable_init();

        _clearingHouseConfig = clearingHouseConfigArg;
        _vault = vaultArg;
        _quoteToken = quoteTokenArg;
        _uniswapV3Factory = uniV3FactoryArg;
        _vPool = exchangeArg;
        _accountBalance = accountBalanceArg;
        _marketRegistry = marketRegistryArg;
        _insuranceFund = insuranceFundArg;
        _platformFund = platformFundArg;
        _maker = makerArg;

        _settlementTokenDecimals = IVault(_vault).decimals();
    }

    /// @dev remove to reduce bytecode size, might add back when we need it
    // // solhint-disable-next-line func-order
    // function setTrustedForwarder(address trustedForwarderArg) external onlyOwner {
    //     // CH_TFNC: TrustedForwarder is not contract
    //     require(trustedForwarderArg.isContract(), "CH_TFNC");
    //     // TrustedForwarderUpdated event is emitted in BaseRelayRecipient
    //     _setTrustedForwarder(trustedForwarderArg);
    // }

    function setDelegateApproval(address delegateApprovalArg) external onlyOwner {
        // CH_DANC: DelegateApproval is not contract
        require(delegateApprovalArg.isContract(), "CH_DANC");
        _delegateApproval = delegateApprovalArg;
        emit DelegateApprovalChanged(delegateApprovalArg);
    }

    function setPlatformFund(address platformFundArg) external onlyOwner {
        _platformFund = platformFundArg;
        emit PlatformFundChanged(platformFundArg);
    }

    function setRewardMiner(address rewardMinerArg) external onlyOwner {
        require(rewardMinerArg.isContract(), "CH_RMNC");
        _rewardMiner = rewardMinerArg;
        emit RewardMinerChanged(rewardMinerArg);
    }

    /// @inheritdoc IClearingHouse
    function addLiquidity(
        DataTypes.AddLiquidityParams memory params
    )
        public
        override
        whenNotPaused
        nonReentrant
        checkDeadline(params.deadline)
        onlyMaker
        returns (
            // check onlyLiquidityAdmin
            DataTypes.AddLiquidityResponse memory
        )
    {
        return GenericLogic.addLiquidity(address(this), params);
    }

    /// @inheritdoc IClearingHouse
    function removeLiquidity(
        DataTypes.RemoveLiquidityParams memory params
    )
        public
        override
        whenNotPaused
        nonReentrant
        checkDeadline(params.deadline)
        onlyMaker
        returns (DataTypes.RemoveLiquidityResponse memory)
    {
        return GenericLogic.removeLiquidity(address(this), params);
    }

    /// @inheritdoc IClearingHouse
    function settleAllFunding(address trader) external override {
        // only vault or trader
        // vault must check msg.sender == trader when calling settleAllFunding
        require(_msgSender() == _vault || _msgSender() == trader, "CH_OVOT");

        address[] memory baseTokens = IAccountBalance(_accountBalance).getBaseTokens(trader);
        uint256 baseTokenLength = baseTokens.length;
        int256 fundingPaymentTotal;
        for (uint256 i = 0; i < baseTokenLength; i++) {
            (, int256 fundingPayment) = GenericLogic.settleFunding(address(this), trader, baseTokens[i]);
            fundingPaymentTotal = fundingPaymentTotal.add(fundingPayment);
        }
        // reward miner
        ClearingHouseLogic.rewardMinerMint(address(this), trader, 0, fundingPaymentTotal.neg256());
    }

    /// @inheritdoc IClearingHouse
    function openPosition(
        DataTypes.OpenPositionParams memory params
    )
        external
        override
        whenNotPaused
        nonReentrant
        checkDeadline(params.deadline)
        returns (uint256 base, uint256 quote)
    {
        // openPosition() is already published, returned types remain the same (without fee)
        (base, quote, ) = _openPositionFor(_msgSender(), params);
        return (base, quote);
    }

    /// @inheritdoc IClearingHouse
    function openPositionFor(
        address trader,
        DataTypes.OpenPositionParams memory params
    )
        external
        override
        whenNotPaused
        nonReentrant
        checkDeadline(params.deadline)
        returns (uint256 base, uint256 quote, uint256 fee)
    {
        // CH_SHNAOPT: Sender Has No Approval to Open Position for Trader
        require(IDelegateApproval(_delegateApproval).canOpenPositionFor(trader, _msgSender()), "CH_SHNAOPT");

        return _openPositionFor(trader, params);
    }

    /// @inheritdoc IClearingHouse
    function closePosition(
        DataTypes.ClosePositionParams memory params
    )
        public
        override
        whenNotPaused
        nonReentrant
        checkDeadline(params.deadline)
        returns (uint256 base, uint256 quote, uint256 fee)
    {
        return ClearingHouseLogic.closePosition(address(this), _msgSender(), params);
    }

    /// @inheritdoc IClearingHouse
    function liquidate(
        address trader,
        address baseToken,
        int256 positionSize
    ) external override whenNotPaused nonReentrant returns (uint256 base, uint256 quote, uint256 fee) {
        // positionSizeToBeLiquidated = 0 means liquidating as much as possible
        return _liquidate(trader, baseToken, positionSize, false);
    }

    /// @inheritdoc IUniswapV3MintCallback
    /// @dev namings here follow Uniswap's convention
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external override checkMintCallback {
        // input requirement checks:
        //   amount0Owed: here
        //   amount1Owed: here
        //   data: X

        // For caller validation purposes it would be more efficient and more reliable to use
        // "msg.sender" instead of "_msgSender()" as contracts never call each other through GSN.
        // not orderbook
        // require(msg.sender == _orderBook, "CH_NOB");

        UniswapV3Broker.MintCallbackData memory callbackData = abi.decode(data, (UniswapV3Broker.MintCallbackData));

        if (amount0Owed > 0) {
            address token = IUniswapV3Pool(callbackData.pool).token0();
            _requireTransfer(token, callbackData.pool, amount0Owed);
        }
        if (amount1Owed > 0) {
            address token = IUniswapV3Pool(callbackData.pool).token1();
            _requireTransfer(token, callbackData.pool, amount1Owed);
        }
    }

    /// @inheritdoc IUniswapV3SwapCallback
    /// @dev namings here follow Uniswap's convention
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override checkSwapCallback {
        // input requirement checks:
        //   amount0Delta: here
        //   amount1Delta: here
        //   data: X
        // For caller validation purposes it would be more efficient and more reliable to use
        // "msg.sender" instead of "_msgSender()" as contracts never call each other through GSN.
        // require(msg.sender == _vPool, "CH_OE");

        // swaps entirely within 0-liquidity regions are not supported -> 0 swap is forbidden
        // CH_F0S: forbidden 0 swap
        require((amount0Delta > 0 && amount1Delta < 0) || (amount0Delta < 0 && amount1Delta > 0), "CH_F0S");

        IVPool.SwapCallbackData memory callbackData = abi.decode(data, (IVPool.SwapCallbackData));
        IUniswapV3Pool uniswapV3Pool = IUniswapV3Pool(callbackData.pool);

        // amount0Delta & amount1Delta are guaranteed to be positive when being the amount to be paid
        (address token, uint256 amountToPay) = amount0Delta > 0
            ? (uniswapV3Pool.token0(), uint256(amount0Delta))
            : (uniswapV3Pool.token1(), uint256(amount1Delta));

        // swap
        _requireTransfer(token, callbackData.pool, amountToPay);
    }

    //
    // EXTERNAL VIEW
    //

    /// @inheritdoc IClearingHouse
    function getQuoteToken() external view override returns (address) {
        return _quoteToken;
    }

    /// @inheritdoc IClearingHouse
    function getUniswapV3Factory() external view override returns (address) {
        return _uniswapV3Factory;
    }

    /// @inheritdoc IClearingHouse
    function getClearingHouseConfig() external view override returns (address) {
        return _clearingHouseConfig;
    }

    /// @inheritdoc IClearingHouse
    function getVault() external view override returns (address) {
        return _vault;
    }

    /// @inheritdoc IClearingHouse
    function getVPool() external view override returns (address) {
        return _vPool;
    }

    /// @inheritdoc IClearingHouse
    function getAccountBalance() external view override returns (address) {
        return _accountBalance;
    }

    /// @inheritdoc IClearingHouse
    function getRewardMiner() external view override returns (address) {
        return _rewardMiner;
    }

    /// @inheritdoc IClearingHouse
    function getInsuranceFund() external view override returns (address) {
        return _insuranceFund;
    }

    /// @inheritdoc IClearingHouse
    function getPlatformFund() external view override returns (address) {
        return _platformFund;
    }

    /// @inheritdoc IClearingHouse
    function getDelegateApproval() external view override returns (address) {
        return _delegateApproval;
    }

    function getMaker() external view override returns (address) {
        return _maker;
    }

    function getMarketRegistry() external view override returns (address) {
        return _marketRegistry;
    }

    // /// @inheritdoc IClearingHouse
    // function getAccountValue(address trader) public view override returns (int256) {
    //     return IVault(_vault).getAccountValue(trader).parseSettlementToken(_settlementTokenDecimals);
    // }

    function getLiquidity(address baseToken) external view returns (uint128) {
        address pool = IMarketRegistry(_marketRegistry).getPool(baseToken);
        return UniswapV3Broker.getLiquidity(pool);
    }

    //
    // INTERNAL NON-VIEW
    //

    function _requireTransfer(address token, address to, uint256 amount) internal {
        // CH_TF: Transfer failed
        require(IERC20Metadata(token).transfer(to, amount), "CH_TF");
    }

    function _liquidate(
        address trader,
        address baseToken,
        int256 positionSize,
        bool isForced
    ) internal returns (uint256 base, uint256 quote, uint256 fee) {
        return
            ClearingHouseLogic.liquidate(
                ClearingHouseLogic.InternalLiquidateParams({
                    chAddress: address(this),
                    marketRegistry: _marketRegistry,
                    liquidator: _msgSender(),
                    trader: trader,
                    baseToken: baseToken,
                    positionSizeToBeLiquidated: positionSize,
                    isForced: isForced
                })
            );
    }

    function _openPositionFor(
        address trader,
        DataTypes.OpenPositionParams memory params
    ) internal returns (uint256 base, uint256 quote, uint256 fee) {
        return ClearingHouseLogic.openPositionFor(address(this), trader, params);
    }

    //
    // INTERNAL VIEW
    //

    /// @inheritdoc BaseRelayRecipient
    function _msgSender() internal view override(BaseRelayRecipient, OwnerPausable) returns (address payable) {
        return super._msgSender();
    }

    /// @inheritdoc BaseRelayRecipient
    function _msgData() internal view override(BaseRelayRecipient, OwnerPausable) returns (bytes memory) {
        return super._msgData();
    }

    /// @dev liquidation condition:
    ///      accountValue < sum(abs(positionValue_by_market)) * mmRatio = totalMinimumMarginRequirement
    function isLiquidatable(address trader) external view returns (bool) {
        return GenericLogic.isLiquidatable(address(this), trader);
    }

    function _isContract(address contractArg, string memory errorMsg) internal view {
        require(contractArg.isContract(), errorMsg);
    }

    function isAbleRepeg(address baseToken) public view returns (bool) {
        (uint256 longPositionSize, uint256 shortPositionSize) = IAccountBalance(_accountBalance).getMarketPositionSize(
            baseToken
        );
        if (longPositionSize + shortPositionSize == 0) {
            return true;
        }
        if (!IVPool(_vPool).isOverPriceSpread(baseToken)) {
            return false;
        }
        if (!IVPool(_vPool).isOverPriceSpreadTimestamp(baseToken)) {
            return false;
        }
        return true;
    }

    ///REPEG
    function repeg(address baseToken) external {
        // check isAbleRepeg
        // CH_NRP: not repeg
        require(isAbleRepeg(baseToken), "CH_NRP");
        //settleFundingGlobal
        GenericLogic.settleFundingGlobal(address(this), baseToken);
        //variable
        InternalRepegParams memory repegParams;
        (repegParams.oldSqrtMarkPrice, , , , , , ) = UniswapV3Broker.getSlot0(
            IMarketRegistry(_marketRegistry).getPool(baseToken)
        );
        repegParams.oldMarkPrice = repegParams.oldSqrtMarkPrice.formatSqrtPriceX96ToPriceX96().formatX96ToX10_18();
        repegParams.spotPrice = IIndexPrice(baseToken).getIndexPrice(
            IClearingHouseConfig(_clearingHouseConfig).getTwapInterval()
        );
        repegParams.sqrtSpotPrice = repegParams.spotPrice.formatPriceX10_18ToSqrtPriceX96();

        if (repegParams.spotPrice != repegParams.oldMarkPrice) {
            // check mark price != index price over 10% and over 1 hour
            // calculate delta base (11) of long short -> delta quote (1)
            // for multiplier
            (
                repegParams.oldLongPositionSize,
                repegParams.oldShortPositionSize,
                repegParams.oldDeltaQuote
            ) = GenericLogic.getInfoMultiplier(address(this), baseToken);
            // for multiplier

            // calculate base amount for openPosition -> spot price
            // maker openPosition -> spot price
            bool isRepegUp = repegParams.spotPrice > repegParams.oldMarkPrice;
            //internal swap
            IVPool(_vPool).internalSwap(
                IVPool.SwapParams({
                    trader: msg.sender,
                    baseToken: baseToken,
                    isBaseToQuote: !isRepegUp,
                    isExactInput: true,
                    isClose: false,
                    amount: type(uint256).max.div(1e10),
                    sqrtPriceLimitX96: repegParams.sqrtSpotPrice
                })
            );
            // calculate delta quote (1) -> new delta base (22)
            // calculate scale -> new mark price => rate = (% delta price)
            // calculate scale for long short = (diff delta base on (11 - 22)) / (total_long + total_short)
            // if delta base < 0 -> decrase delta long short
            // -> if long > short -> decrease long and increase short
            // -> if long < short -> increase long and decrease short
            // if delta base > 0 -> increase delta long short
            // -> if long > short -> increase long and decrease short
            // -> if long < short -> decrease long and increase short
            // update scale for position size for long short
            (repegParams.newSqrtMarkPrice, , , , , , ) = UniswapV3Broker.getSlot0(
                IMarketRegistry(_marketRegistry).getPool(baseToken)
            );
            repegParams.newMarkPrice = repegParams.newSqrtMarkPrice.formatSqrtPriceX96ToPriceX96().formatX96ToX10_18();
            // for multiplier
            GenericLogic.updateInfoMultiplier(
                address(this),
                baseToken,
                repegParams.oldLongPositionSize,
                repegParams.oldShortPositionSize,
                repegParams.oldDeltaQuote,
                repegParams.oldMarkPrice,
                repegParams.newMarkPrice,
                false
            );
            // for multiplier
            IVPool(_vPool).updateOverPriceSpreadTimestamp(baseToken);
            // emit event
            emit Repeg(baseToken, repegParams.oldMarkPrice, repegParams.newMarkPrice);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import "../VPool.sol";

contract TestVPool is VPool {
    using AddressUpgradeable for address;

    uint256 private _testBlockTimestamp;

    // copy paste from AccountBalance.initialize to avoid it to be public

    function setBlockTimestamp(uint256 blockTimestamp) external {
        _testBlockTimestamp = blockTimestamp;
    }

    function getBlockTimestamp() external view returns (uint256) {
        return _testBlockTimestamp;
    }

    function _blockTimestamp() internal view override returns (uint256) {
        return _testBlockTimestamp;
    }

    // @dev max tick range = 887272 * 2
    // @dev ref : https://github.com/Uniswap/v3-core/blob/main/contracts/libraries/TickMath.sol#L25
    function _getMaxTickCrossedWithinBlockCap() internal pure override returns (uint24) {
        return 1774544;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#mint
/// @notice Any contract that calls IUniswapV3PoolActions#mint must implement this interface
interface IUniswapV3MintCallback {
    /// @notice Called to `msg.sender` after minting liquidity to a position from IUniswapV3Pool#mint.
    /// @dev In the implementation you must pay the pool tokens owed for the minted liquidity.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param amount0Owed The amount of token0 due to the pool for the minted liquidity
    /// @param amount1Owed The amount of token1 due to the pool for the minted liquidity
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#mint call
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { SafeOwnable } from "./SafeOwnable.sol";

abstract contract OwnerPausable is SafeOwnable, PausableUpgradeable {
    // __gap is reserved storage
    uint256[50] private __gap;

    // solhint-disable-next-line func-order
    function __OwnerPausable_init() internal initializer {
        __SafeOwnable_init();
        __Pausable_init();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _msgSender() internal view virtual override returns (address payable) {
        return super._msgSender();
    }

    function _msgData() internal view virtual override returns (bytes memory) {
        return super._msgData();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.6;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

interface IInsuranceFund {
    /// @param vault The address of the vault
    event VaultChanged(address vault);

    event ClearingHouseChanged(address clearingHouse);

    /// @notice Get settlement token address
    /// @return token The address of settlement token
    function getToken() external view returns (address token);

    /// @notice Get `Vault` address
    /// @return vault The address of `Vault`
    function getVault() external view returns (address vault);

        /// @notice Get `InsuranceFund` capacity
    /// @return capacityX10_S The capacity value (settlementTokenValue + walletBalance) in settlement token's decimals
    function getInsuranceFundCapacity() external view returns (int256 capacityX10_S);

    function getClearingHouse() external view returns (address);

    function getRepegAccumulatedFund() external view returns (int256);

    function getRepegDistributedFund() external view returns (int256);

    function addRepegFund(uint256 fund) external;

    function repegFund(int256 fund) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

interface IDelegateApproval {
    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @param actions The actions to be approved
    event DelegationApproved(address indexed trader, address delegate, uint8 actions);

    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @param actions The actions to be revoked
    event DelegationRevoked(address indexed trader, address delegate, uint8 actions);

    /// @param delegate The address of delegate
    /// @param actions The actions to be approved
    function approve(address delegate, uint8 actions) external;

    /// @param delegate The address of delegate
    /// @param actions The actions to be revoked
    function revoke(address delegate, uint8 actions) external;

    /// @return action The value of action `_CLEARINGHOUSE_OPENPOSITION`
    function getClearingHouseOpenPositionAction() external pure returns (uint8);

    /// @return action The value of action `_CLEARINGHOUSE_ADDLIQUIDITY`
    function getClearingHouseAddLiquidityAction() external pure returns (uint8);

    /// @return action The value of action `_CLEARINGHOUSE_REMOVELIQUIDITY`
    function getClearingHouseRemoveLiquidityAction() external pure returns (uint8);

    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @return actions The approved actions
    function getApprovedActions(address trader, address delegate) external view returns (uint8);

    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @param actions The actions to be checked
    /// @return true if delegate is allowed to perform **each** actions for trader, otherwise false
    function hasApprovalFor(
        address trader,
        address delegate,
        uint8 actions
    ) external view returns (bool);

    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @return true if delegate can open position for trader, otherwise false
    function canOpenPositionFor(address trader, address delegate) external view returns (bool);

    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @return true if delegate can add liquidity for trader, otherwise false
    function canAddLiquidityFor(address trader, address delegate) external view returns (bool);

    /// @param trader The address of trader
    /// @param delegate The address of delegate
    /// @return true if delegate can remove liquidity for trader, otherwise false
    function canRemoveLiquidityFor(address trader, address delegate) external view returns (bool);
}

// copied from @opengsn/provider-2.2.4,
// https://github.com/opengsn/gsn/blob/master/packages/contracts/src/BaseRelayRecipient.sol
// for adding `payable` property at the return value of _msgSender()
// SPDX-License-Identifier: MIT
// solhint-disable no-inline-assembly
pragma solidity 0.7.6;

import "./IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {
    /*
     * Forwarder singleton we accept calls from
     */
    address internal _trustedForwarder;

    // __gap is reserved storage
    uint256[50] private __gap;

    event TrustedForwarderUpdated(address trustedForwarder);

    function getTrustedForwarder() external view returns (address) {
        return _trustedForwarder;
    }

    /// @inheritdoc IRelayRecipient
    function versionRecipient() external pure override returns (string memory) {
        return "2.0.0";
    }

    /// @inheritdoc IRelayRecipient
    function isTrustedForwarder(address forwarder) public view virtual override returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _setTrustedForwarder(address trustedForwarderArg) internal {
        _trustedForwarder = trustedForwarderArg;
        emit TrustedForwarderUpdated(trustedForwarderArg);
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    /// @inheritdoc IRelayRecipient
    function _msgSender() internal view virtual override returns (address payable ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    /// @inheritdoc IRelayRecipient
    function _msgData() internal view virtual override returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

/// @notice For future upgrades, do not change ClearingHouseStorageV1. Create a new
/// contract which implements ClearingHouseStorageV1 and following the naming convention
/// ClearingHouseStorageVX.
abstract contract ClearingHouseStorage {
    // --------- IMMUTABLE ---------
    address internal _quoteToken;
    address internal _uniswapV3Factory;

    // cache the settlement token's decimals for gas optimization
    uint8 internal _settlementTokenDecimals;
    // --------- ^^^^^^^^^ ---------

    address internal _clearingHouseConfig;
    address internal _vault;
    address internal _vPool;
    address internal __orderBook;
    address internal _accountBalance;
    address internal _marketRegistry;
    address internal _insuranceFund;
    address internal _platformFund;
    address internal _maker;
    address internal _rewardMiner;

    address internal _delegateApproval;

    // sub 1 when use
    address[10] private __gap1;
    // sub 1 when use
    uint256[10] private __gap2;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;
import { DataTypes } from "../types/DataTypes.sol";

interface IClearingHouse {
    /// @param useTakerBalance only accept false now
    struct AddLiquidityParams {
        address baseToken;
        uint128 liquidity;
        int24 lowerTick;
        int24 upperTick;
        uint256 deadline;
    }

    /// @param liquidity collect fee when 0
    struct RemoveLiquidityParams {
        address baseToken;
        int24 lowerTick;
        int24 upperTick;
        uint128 liquidity;
        uint256 deadline;
    }

    struct AddLiquidityResponse {
        uint256 base;
        uint256 quote;
        uint256 fee;
        uint256 liquidity;
    }

    struct RemoveLiquidityResponse {
        uint256 base;
        uint256 quote;
        uint256 fee;
    }

    /// @param oppositeAmountBound
    // B2Q + exact input, want more output quote as possible, so we set a lower bound of output quote
    // B2Q + exact output, want less input base as possible, so we set a upper bound of input base
    // Q2B + exact input, want more output base as possible, so we set a lower bound of output base
    // Q2B + exact output, want less input quote as possible, so we set a upper bound of input quote
    // when it's set to 0, it will disable slippage protection entirely regardless of exact input or output
    // when it's over or under the bound, it will be reverted
    /// @param sqrtPriceLimitX96
    // B2Q: the price cannot be less than this value after the swap
    // Q2B: the price cannot be greater than this value after the swap
    // it will fill the trade until it reaches the price limit but WON'T REVERT
    // when it's set to 0, it will disable price limit;
    // when it's 0 and exact output, the output amount is required to be identical to the param amount
    struct OpenPositionParams {
        address baseToken;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint256 oppositeAmountBound;
        uint256 deadline;
        uint160 sqrtPriceLimitX96;
        bytes32 referralCode;
    }

    struct ClosePositionParams {
        address baseToken;
        uint160 sqrtPriceLimitX96;
        uint256 oppositeAmountBound;
        uint256 deadline;
        bytes32 referralCode;
    }

    struct CollectPendingFeeParams {
        address trader;
        address baseToken;
        int24 lowerTick;
        int24 upperTick;
    }

    event PlatformFundChanged(address indexed platformFundArg);

    event RewardMinerChanged(address indexed rewardMinerArg);

    /// @notice Emitted when open position with non-zero referral code
    /// @param referralCode The referral code by partners
    event ReferredPositionChanged(bytes32 indexed referralCode);

    /// @notice Emitted when maker's liquidity of a order changed
    /// @param maker The one who provide liquidity
    /// @param baseToken The address of virtual base token(ETH, BTC, etc...)
    /// @param quoteToken The address of virtual USD token
    /// @param lowerTick The lower tick of the position in which to add liquidity
    /// @param upperTick The upper tick of the position in which to add liquidity
    /// @param base The amount of base token added (> 0) / removed (< 0) as liquidity; fees not included
    /// @param quote The amount of quote token added ... (same as the above)
    /// @param liquidity The amount of liquidity unit added (> 0) / removed (< 0)
    /// @param quoteFee The amount of quote token the maker received as fees
    event LiquidityChanged(
        address indexed maker,
        address indexed baseToken,
        address indexed quoteToken,
        int24 lowerTick,
        int24 upperTick,
        int256 base,
        int256 quote,
        int128 liquidity,
        uint256 quoteFee
    );

    /// @notice Emitted when taker's position is being changed
    /// @param trader Trader address
    /// @param baseToken The address of virtual base token(ETH, BTC, etc...)
    /// @param exchangedPositionSize The actual amount swap to uniswapV3 pool
    /// @param exchangedPositionNotional The cost of position, include fee
    /// @param fee The fee of open/close position
    /// @param openNotional The cost of open/close position, < 0: long, > 0: short
    /// @param realizedPnl The realized Pnl after open/close position
    /// @param sqrtPriceAfterX96 The sqrt price after swap, in X96
    event PositionChanged(
        address indexed trader,
        address indexed baseToken,
        int256 exchangedPositionSize,
        int256 exchangedPositionNotional,
        uint256 fee,
        int256 openNotional,
        int256 realizedPnl,
        uint256 sqrtPriceAfterX96
    );

    //event
    event PositionLiquidated(
        address indexed trader,
        address indexed baseToken,
        uint256 positionSize,
        uint256 positionNotional,
        uint256 liquidationPenaltyFee,
        address liquidator,
        uint256 liquidatorFee
    );

    /// @notice Emitted when taker close her position in closed market
    /// @param trader Trader address
    /// @param baseToken The address of virtual base token(ETH, BTC, etc...)
    /// @param closedPositionSize Trader's position size in closed market
    /// @param closedPositionNotional Trader's position notional in closed market, based on closed price
    /// @param openNotional The cost of open/close position, < 0: long, > 0: short
    /// @param realizedPnl The realized Pnl after close position
    /// @param closedPrice The close price of position
    event PositionClosed(
        address indexed trader,
        address indexed baseToken,
        int256 closedPositionSize,
        int256 closedPositionNotional,
        int256 openNotional,
        int256 realizedPnl,
        uint256 closedPrice
    );

    /// @notice Emitted when settling a trader's funding payment
    /// @param trader The address of trader
    /// @param baseToken The address of virtual base token(ETH, BTC, etc...)
    /// @param fundingPayment The fundingPayment of trader on baseToken market, > 0: payment, < 0 : receipt
    event FundingPaymentSettled(address indexed trader, address indexed baseToken, int256 fundingPayment);

    /// @notice Emitted when trusted forwarder address changed
    /// @dev TrustedForward is only used for metaTx
    /// @param forwarder The trusted forwarder address
    event TrustedForwarderChanged(address indexed forwarder);

    /// @notice Emitted when DelegateApproval address changed
    /// @param delegateApproval The address of DelegateApproval
    event DelegateApprovalChanged(address indexed delegateApproval);

    event Repeg(address indexed baseToken, uint256 oldMarkPrice, uint256 newMarkPrice);

    /// @notice Maker can call `addLiquidity` to provide liquidity on Uniswap V3 pool
    /// @dev Tx will fail if adding `base == 0 && quote == 0` / `liquidity == 0`
    /// @dev - `AddLiquidityParams.useTakerBalance` is only accept `false` now
    /// @param params AddLiquidityParams struct
    /// @return response AddLiquidityResponse struct
    function addLiquidity(
        DataTypes.AddLiquidityParams calldata params
    ) external returns (DataTypes.AddLiquidityResponse memory response);

    /// @notice Maker can call `removeLiquidity` to remove liquidity
    /// @dev remove liquidity will transfer maker impermanent position to taker position,
    /// if `liquidity` of RemoveLiquidityParams struct is zero, the action will collect fee from
    /// pool to maker
    /// @param params RemoveLiquidityParams struct
    /// @return response RemoveLiquidityResponse struct
    function removeLiquidity(
        DataTypes.RemoveLiquidityParams calldata params
    ) external returns (DataTypes.RemoveLiquidityResponse memory response);

    /// @notice Settle all markets fundingPayment to owedRealized Pnl
    /// @param trader The address of trader
    function settleAllFunding(address trader) external;

    /// @notice Trader can call `openPosition` to long/short on baseToken market
    /// @dev - `OpenPositionParams.oppositeAmountBound`
    ///     - B2Q + exact input, want more output quote as possible, so we set a lower bound of output quote
    ///     - B2Q + exact output, want less input base as possible, so we set a upper bound of input base
    ///     - Q2B + exact input, want more output base as possible, so we set a lower bound of output base
    ///     - Q2B + exact output, want less input quote as possible, so we set a upper bound of input quote
    ///     > when it's set to 0, it will disable slippage protection entirely regardless of exact input or output
    ///     > when it's over or under the bound, it will be reverted
    /// @dev - `OpenPositionParams.sqrtPriceLimitX96`
    ///     - B2Q: the price cannot be less than this value after the swap
    ///     - Q2B: the price cannot be greater than this value after the swap
    ///     > it will fill the trade until it reaches the price limit but WON'T REVERT
    ///     > when it's set to 0, it will disable price limit;
    ///     > when it's 0 and exact output, the output amount is required to be identical to the param amount
    /// @param params OpenPositionParams struct
    /// @return base The amount of baseToken the taker got or spent
    /// @return quote The amount of quoteToken the taker got or spent
    function openPosition(DataTypes.OpenPositionParams memory params) external returns (uint256 base, uint256 quote);

    /// @param trader The address of trader
    /// @param params OpenPositionParams struct is the same as `openPosition()`
    /// @return base The amount of baseToken the taker got or spent
    /// @return quote The amount of quoteToken the taker got or spent
    /// @return fee The trading fee
    function openPositionFor(
        address trader,
        DataTypes.OpenPositionParams memory params
    ) external returns (uint256 base, uint256 quote, uint256 fee);

    /// @notice Close trader's position
    /// @param params ClosePositionParams struct
    /// @return base The amount of baseToken the taker got or spent
    /// @return quote The amount of quoteToken the taker got or spent
    function closePosition(
        DataTypes.ClosePositionParams calldata params
    ) external returns (uint256 base, uint256 quote, uint256 fee);

    /// @notice liquidate trader's position and will liquidate the max possible position size
    /// @dev If margin ratio >= 0.5 * mmRatio,
    ///         maxLiquidateRatio = MIN((1, 0.5 * totalAbsPositionValue / absPositionValue)
    /// @dev If margin ratio < 0.5 * mmRatio, maxLiquidateRatio = 1
    /// @dev maxLiquidatePositionSize = positionSize * maxLiquidateRatio
    /// @param trader The address of trader
    /// @param baseToken The address of baseToken
    function liquidate(
        address trader,
        address baseToken,
        int256 positionSize
    ) external returns (uint256 base, uint256 quote, uint256 fee);

    // /// @notice Cancel excess order of a maker
    // /// @dev Order id can get from `OrderBook.getOpenOrderIds`
    // /// @param baseToken The address of baseToken
    // function cancelExcessOrders(address baseToken) external;

    // /// @notice Cancel all excess orders of a maker if the maker is underwater
    // /// @dev This function won't fail if the maker has no order but fails when maker is not underwater
    // /// @param baseToken The address of baseToken
    // function cancelAllExcessOrders(address baseToken) external;

    /// @notice Close all positions and remove all liquidities of a trader in the closed market
    /// @param trader The address of trader
    /// @param baseToken The address of baseToken
    /// @return base The amount of base token that is closed
    /// @return quote The amount of quote token that is closed
    // function quitMarket(address trader, address baseToken) external returns (uint256 base, uint256 quote);

    // /// @notice Get account value of trader
    // /// @dev accountValue = totalCollateralValue + totalUnrealizedPnl, in 18 decimals
    // /// @param trader The address of trader
    // /// @return accountValue The account value of trader
    // function getAccountValue(address trader) external view returns (int256 accountValue);

    /// @notice Get QuoteToken address
    /// @return quoteToken The quote token address
    function getQuoteToken() external view returns (address quoteToken);

    /// @notice Get UniswapV3Factory address
    /// @return factory UniswapV3Factory address
    function getUniswapV3Factory() external view returns (address factory);

    /// @notice Get ClearingHouseConfig address
    /// @return clearingHouseConfig ClearingHouseConfig address
    function getClearingHouseConfig() external view returns (address clearingHouseConfig);

    /// @notice Get `Vault` address
    /// @return vault `Vault` address
    function getVault() external view returns (address vault);

    /// @notice Get `Exchange` address
    /// @return exchange `Exchange` address
    function getVPool() external view returns (address exchange);

    /// @notice Get AccountBalance address
    /// @return accountBalance `AccountBalance` address
    function getAccountBalance() external view returns (address accountBalance);

    function getRewardMiner() external view returns (address rewardMiner);

    /// @notice Get `InsuranceFund` address
    /// @return insuranceFund `InsuranceFund` address
    function getInsuranceFund() external view returns (address insuranceFund);

    /// @notice Get `DelegateApproval` address
    /// @return delegateApproval `DelegateApproval` address
    function getDelegateApproval() external view returns (address delegateApproval);

    function getMaker() external view returns (address maker);

    function getPlatformFund() external view returns (address platformFund);

    function getMarketRegistry() external view returns (address marketRegistry);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;
import { IAccountBalance } from "../interface/IAccountBalance.sol";
import { IInsuranceFund } from "../interface/IInsuranceFund.sol";
import { IBaseToken } from "../interface/IBaseToken.sol";
import { IClearingHouse } from "../interface/IClearingHouse.sol";
import { IClearingHouseConfig } from "../interface/IClearingHouseConfig.sol";
import { IVPool } from "../interface/IVPool.sol";
import { IVault } from "../interface/IVault.sol";
import { IMarketRegistry } from "../interface/IMarketRegistry.sol";
import { IRewardMiner } from "../interface/IRewardMiner.sol";
import { IIndexPrice } from "../interface/IIndexPrice.sol";
import { FullMath } from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import { PerpSafeCast } from "./PerpSafeCast.sol";
import { PerpMath } from "./PerpMath.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { SignedSafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import { DataTypes } from "../types/DataTypes.sol";
import { GenericLogic } from "../lib/GenericLogic.sol";
import { UniswapV3Broker } from "../lib/UniswapV3Broker.sol";
import "hardhat/console.sol";

library ClearingHouseLogic {
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;
    using PerpSafeCast for uint256;
    using PerpSafeCast for uint128;
    using PerpSafeCast for int256;
    using PerpMath for uint256;
    using PerpMath for uint160;
    using PerpMath for uint128;
    using PerpMath for int256;

    uint256 internal constant _BAD_AMOUNT = 1e10; // 15 sec

    //internal struct
    /// @param sqrtPriceLimitX96 tx will fill until it reaches this price but WON'T REVERT
    struct InternalOpenPositionParams {
        address trader;
        address baseToken;
        bool isBaseToQuote;
        bool isExactInput;
        bool isClose;
        uint256 amount;
        uint160 sqrtPriceLimitX96;
    }

    struct InternalSwapResponse {
        int256 base;
        int256 quote;
        int256 exchangedPositionSize;
        int256 exchangedPositionNotional;
        uint256 fee;
        int24 tick;
    }

    struct InternalLiquidateParams {
        address chAddress;
        address marketRegistry;
        address liquidator;
        address trader;
        address baseToken;
        int256 positionSizeToBeLiquidated;
        bool isForced;
    }

    struct InternalLiquidateVars {
        int256 positionSize;
        int256 openNotional;
        uint256 liquidationPenalty;
        int256 accountValue;
        int256 liquidatedPositionSize;
        int256 liquidatedPositionNotional;
        uint256 liquidationFeeToLiquidator;
        uint256 liquidationFeeToIF;
        int256 liquidatorExchangedPositionNotional;
        int256 accountValueAfterLiquidationX10_18;
        int256 insuranceFundCapacityX10_18;
        int256 liquidatorExchangedPositionSize;
        address insuranceFund;
        int256 traderRealizedPnl;
        int256 liquidatorRealizedPnl;
    }

    //
    function _openPosition(
        address chAddress,
        InternalOpenPositionParams memory params
    ) internal returns (IVPool.SwapResponse memory) {
        // must settle funding first
        (, int256 fundingPayment) = GenericLogic.settleFunding(chAddress, params.trader, params.baseToken);

        IVPool.SwapResponse memory response = IVPool(IClearingHouse(chAddress).getVPool()).swap(
            IVPool.SwapParams({
                trader: params.trader,
                baseToken: params.baseToken,
                isBaseToQuote: params.isBaseToQuote,
                isExactInput: params.isExactInput,
                isClose: params.isClose,
                amount: params.amount,
                sqrtPriceLimitX96: params.sqrtPriceLimitX96
            })
        );

        // EL_DA: DUST Amount
        require(
            response.exchangedPositionSize.abs() >= _BAD_AMOUNT ||
                response.exchangedPositionNotional.abs() >= _BAD_AMOUNT,
            "EL_DA"
        );

        address insuranceFund = IClearingHouse(chAddress).getInsuranceFund();
        // insuranceFundFee
        _modifyOwedRealizedPnl(chAddress, insuranceFund, response.insuranceFundFee.toInt256());
        // update repeg fund
        IInsuranceFund(insuranceFund).addRepegFund(response.insuranceFundFee.div(2));
        // platformFundFee
        _modifyOwedRealizedPnl(
            chAddress,
            IClearingHouse(chAddress).getPlatformFund(),
            response.platformFundFee.toInt256()
        );
        // sum fee, sub direct balance
        uint256 fee = response.insuranceFundFee.add(response.platformFundFee);
        _modifyOwedRealizedPnl(chAddress, params.trader, fee.toInt256().neg256());

        // examples:
        // https://www.figma.com/file/xuue5qGH4RalX7uAbbzgP3/swap-accounting-and-events?node-id=0%3A1
        IAccountBalance(IClearingHouse(chAddress).getAccountBalance()).settleBalanceAndDeregister(
            params.trader,
            params.baseToken,
            response.exchangedPositionSize,
            response.exchangedPositionNotional,
            response.pnlToBeRealized,
            0
        );

        if (response.pnlToBeRealized != 0) {
            // if realized pnl is not zero, that means trader is reducing or closing position
            // trader cannot reduce/close position if the remaining account value is less than
            // accountValue * LiquidationPenaltyRatio, which
            // enforces traders to keep LiquidationPenaltyRatio of accountValue to
            // shore the remaining positions and make sure traders having enough money to pay liquidation penalty.

            // CH_NEMRM : not enough minimum required margin after reducing/closing position
            require(
                GenericLogic.getAccountValue(chAddress, params.trader) >=
                    IAccountBalance(IClearingHouse(chAddress).getAccountBalance())
                        .getTotalAbsPositionValue(params.trader)
                        .mulRatio(
                            IClearingHouseConfig(IClearingHouse(chAddress).getClearingHouseConfig())
                                .getLiquidationPenaltyRatio()
                        )
                        .toInt256(),
                "CH_NEMRM"
            );
        }

        // if not closing a position, check margin ratio after swap
        if (params.isClose) {
            GenericLogic.requireEnoughFreeCollateralForClose(chAddress, params.trader);
        } else {
            GenericLogic.requireEnoughFreeCollateral(chAddress, params.trader);
        }

        // openNotional will be zero if baseToken is deregistered from trader's token list.
        int256 openNotional = GenericLogic.getTakerOpenNotional(chAddress, params.trader, params.baseToken);
        emit GenericLogic.PositionChanged(
            params.trader,
            params.baseToken,
            response.exchangedPositionSize,
            response.exchangedPositionNotional,
            fee,
            openNotional,
            response.pnlToBeRealized, // realizedPnl
            response.sqrtPriceAfterX96
        );

        // for miner amount
        rewardMinerMint(
            chAddress,
            params.trader,
            response.quote,
            fee.toInt256().neg256().add(response.pnlToBeRealized).add(fundingPayment.neg256())
        );

        return response;
    }

    function openPositionFor(
        address chAddress,
        address trader,
        DataTypes.OpenPositionParams memory params
    ) public returns (uint256 base, uint256 quote, uint256 fee) {
        // input requirement checks:
        //   baseToken: in Exchange.settleFunding()
        //   isBaseToQuote & isExactInput: X
        //   amount: in UniswapV3Pool.swap()
        //   oppositeAmountBound: in _checkSlippage()
        //   deadline: here
        //   sqrtPriceLimitX96: X (this is not for slippage protection)
        //   referralCode: X

        GenericLogic.checkMarketOpen(params.baseToken);

        GenericLogic.requireNotMaker(chAddress, trader);

        // register token if it's the first time
        GenericLogic.registerBaseToken(chAddress, trader, params.baseToken);

        IVPool.SwapResponse memory response = _openPosition(
            chAddress,
            InternalOpenPositionParams({
                trader: trader,
                baseToken: params.baseToken,
                isBaseToQuote: params.isBaseToQuote,
                isExactInput: params.isExactInput,
                amount: params.amount,
                isClose: false,
                sqrtPriceLimitX96: params.sqrtPriceLimitX96
            })
        );

        GenericLogic.checkSlippage(
            GenericLogic.InternalCheckSlippageParams({
                isBaseToQuote: params.isBaseToQuote,
                isExactInput: params.isExactInput,
                base: response.base,
                quote: response.quote,
                oppositeAmountBound: params.oppositeAmountBound
            })
        );

        _referredPositionChanged(params.referralCode);

        return (response.base, response.quote, response.insuranceFundFee.add(response.platformFundFee));
    }

    function _referredPositionChanged(bytes32 referralCode) internal {
        if (referralCode != 0) {
            emit GenericLogic.ReferredPositionChanged(referralCode);
        }
    }

    function closePosition(
        address chAddress,
        address trader,
        DataTypes.ClosePositionParams calldata params
    ) public returns (uint256 base, uint256 quote, uint256 fee) {
        // input requirement checks:
        //   baseToken: in Exchange.settleFunding()
        //   sqrtPriceLimitX96: X (this is not for slippage protection)
        //   oppositeAmountBound: in _checkSlippage()
        //   deadline: here
        //   referralCode: X

        GenericLogic.checkMarketOpen(params.baseToken);

        GenericLogic.requireNotMaker(chAddress, trader);

        int256 positionSize = GenericLogic.getTakerPositionSafe(chAddress, trader, params.baseToken);

        // old position is long. when closing, it's baseToQuote && exactInput (sell exact base)
        // old position is short. when closing, it's quoteToBase && exactOutput (buy exact base back)
        bool isBaseToQuote = positionSize > 0;

        IVPool.SwapResponse memory response = _openPosition(
            chAddress,
            InternalOpenPositionParams({
                trader: trader,
                baseToken: params.baseToken,
                isBaseToQuote: isBaseToQuote,
                isExactInput: isBaseToQuote,
                isClose: true,
                amount: positionSize.abs(),
                sqrtPriceLimitX96: params.sqrtPriceLimitX96
            })
        );

        GenericLogic.checkSlippage(
            GenericLogic.InternalCheckSlippageParams({
                isBaseToQuote: isBaseToQuote,
                isExactInput: isBaseToQuote,
                base: response.base,
                quote: response.quote,
                oppositeAmountBound: GenericLogic.getOppositeAmount(
                    chAddress,
                    params.oppositeAmountBound,
                    response.isPartialClose
                )
            })
        );

        _referredPositionChanged(params.referralCode);

        return (response.base, response.quote, response.insuranceFundFee.add(response.platformFundFee));
    }

    function rewardMinerMint(address chAddress, address trader, uint256 quote, int256 pnl) public {
        address rewardMiner = IClearingHouse(chAddress).getRewardMiner();
        if (rewardMiner != address(0)) {
            IRewardMiner(rewardMiner).mint(trader, quote, pnl);
        }
    }

    function _getLiquidatedPositionSizeAndNotional(
        address chAddress,
        address trader,
        address baseToken,
        int256 accountValue,
        int256 positionSizeToBeLiquidated
    ) internal view returns (int256, int256) {
        int256 maxLiquidatablePositionSize = IAccountBalance(IClearingHouse(chAddress).getAccountBalance())
            .getLiquidatablePositionSize(trader, baseToken, accountValue);

        if (positionSizeToBeLiquidated.abs() > maxLiquidatablePositionSize.abs() || positionSizeToBeLiquidated == 0) {
            positionSizeToBeLiquidated = maxLiquidatablePositionSize;
        }

        int256 markPrice = GenericLogic
            .getSqrtMarkX96(chAddress, baseToken)
            .formatSqrtPriceX96ToPriceX96()
            .formatX96ToX10_18()
            .toInt256();

        int256 liquidatedPositionSize = positionSizeToBeLiquidated.neg256();
        int256 liquidatedPositionNotional = positionSizeToBeLiquidated.mulDiv(markPrice, 1e18);

        return (liquidatedPositionSize, liquidatedPositionNotional);
    }

    function _modifyOwedRealizedPnl(address chAddress, address trader, int256 amount) internal {
        IAccountBalance(IClearingHouse(chAddress).getAccountBalance()).modifyOwedRealizedPnl(trader, amount);
    }

    /// @dev Calculate how much profit/loss we should realize,
    ///      The profit/loss is calculated by exchangedPositionSize/exchangedPositionNotional amount
    ///      and existing taker's base/quote amount.
    function _modifyPositionAndRealizePnl(
        address chAddress,
        address trader,
        address baseToken,
        int256 exchangedPositionSize,
        int256 exchangedPositionNotional,
        uint256 makerFee,
        uint256 takerFee
    ) internal returns (int256 realizedPnl) {
        if (exchangedPositionSize != 0) {
            realizedPnl = IVPool(IClearingHouse(chAddress).getVPool()).getPnlToBeRealized(
                IVPool.RealizePnlParams({
                    trader: trader,
                    baseToken: baseToken,
                    base: exchangedPositionSize,
                    quote: exchangedPositionNotional
                })
            );
        }

        // realizedPnl is realized here
        // will deregister baseToken if there is no position
        IAccountBalance(IClearingHouse(chAddress).getAccountBalance()).settleBalanceAndDeregister(
            trader,
            baseToken,
            exchangedPositionSize, // takerBase
            exchangedPositionNotional, // takerQuote
            realizedPnl,
            makerFee.toInt256()
        );
        int256 openNotional = GenericLogic.getTakerOpenNotional(chAddress, trader, baseToken);
        uint160 currentPrice = GenericLogic.getSqrtMarkX96(chAddress, baseToken);
        emit GenericLogic.PositionChanged(
            trader,
            baseToken,
            exchangedPositionSize,
            exchangedPositionNotional,
            takerFee, // fee
            openNotional, // openNotional
            realizedPnl,
            currentPrice // sqrtPriceAfterX96: no swap, so market price didn't change
        );
    }

    function liquidate(
        InternalLiquidateParams memory params
    ) public returns (uint256 base, uint256 quote, uint256 fee) {
        InternalLiquidateVars memory vars;

        GenericLogic.checkMarketOpen(params.baseToken);

        GenericLogic.requireNotMaker(params.chAddress, params.trader);

        if (!params.isForced) {
            // CH_EAV: enough account value
            require(GenericLogic.isLiquidatable(params.chAddress, params.trader), "CH_EAV");
        }

        vars.positionSize = GenericLogic.getTakerPositionSafe(params.chAddress, params.trader, params.baseToken);
        vars.openNotional = IAccountBalance(IClearingHouse(params.chAddress).getAccountBalance()).getTakerOpenNotional(
            params.trader,
            params.baseToken
        );

        // CH_WLD: wrong liquidation direction
        require(vars.positionSize.mul(params.positionSizeToBeLiquidated) >= 0, "CH_WLD");

        GenericLogic.registerBaseToken(params.chAddress, params.liquidator, params.baseToken);

        // must settle funding first
        GenericLogic.settleFunding(params.chAddress, params.trader, params.baseToken);
        GenericLogic.settleFunding(params.chAddress, params.liquidator, params.baseToken);

        vars.accountValue = GenericLogic.getAccountValue(params.chAddress, params.trader);

        // trader's position is closed at index price and pnl realized
        (vars.liquidatedPositionSize, vars.liquidatedPositionNotional) = _getLiquidatedPositionSizeAndNotional(
            params.chAddress,
            params.trader,
            params.baseToken,
            vars.accountValue,
            params.positionSizeToBeLiquidated
        );

        vars.traderRealizedPnl = _modifyPositionAndRealizePnl(
            params.chAddress,
            params.trader,
            params.baseToken,
            vars.liquidatedPositionSize,
            vars.liquidatedPositionNotional,
            0,
            0
        );

        // trader pays liquidation penalty
        vars.liquidationPenalty = vars.liquidatedPositionNotional.abs().mulRatio(
            GenericLogic.getLiquidationPenaltyRatio(params.chAddress)
        );
        IAccountBalance(IClearingHouse(params.chAddress).getAccountBalance()).modifyOwedRealizedPnl(
            params.trader,
            vars.liquidationPenalty.neg256()
        );

        vars.insuranceFund = IClearingHouse(params.chAddress).getInsuranceFund();

        // if there is bad debt, liquidation fees all go to liquidator; otherwise, split between liquidator & IF
        vars.liquidationFeeToLiquidator = vars.liquidationPenalty.div(2);
        vars.liquidationFeeToIF;
        if (vars.accountValue < 0) {
            vars.liquidationFeeToLiquidator = vars.liquidationPenalty;
        } else {
            vars.liquidationFeeToIF = vars.liquidationPenalty.sub(vars.liquidationFeeToLiquidator);
            IAccountBalance(IClearingHouse(params.chAddress).getAccountBalance()).modifyOwedRealizedPnl(
                vars.insuranceFund,
                vars.liquidationFeeToIF.toInt256()
            );
            // update repeg fund
            IInsuranceFund(vars.insuranceFund).addRepegFund(vars.liquidationFeeToIF.div(2));
        }

        // assume there is no longer any unsettled bad debt in the system
        // (so that true IF capacity = accountValue(IF) + USDC.balanceOf(IF))
        // if trader's account value becomes negative, the amount is the bad debt IF must have enough capacity to cover
        {
            vars.accountValueAfterLiquidationX10_18 = GenericLogic.getAccountValue(params.chAddress, params.trader);

            if (vars.accountValueAfterLiquidationX10_18 < 0) {
                vars.insuranceFundCapacityX10_18 = IInsuranceFund(vars.insuranceFund)
                    .getInsuranceFundCapacity()
                    .parseSettlementToken(IVault(IClearingHouse(params.chAddress).getVault()).decimals());

                // CH_IIC: insufficient insuranceFund capacity
                require(vars.insuranceFundCapacityX10_18 >= vars.accountValueAfterLiquidationX10_18.neg256(), "CH_IIC");
            }
        }

        // liquidator opens a position with liquidationFeeToLiquidator as a discount
        // liquidator's openNotional = -liquidatedPositionNotional + liquidationFeeToLiquidator
        vars.liquidatorExchangedPositionSize = vars.liquidatedPositionSize.neg256();
        vars.liquidatorExchangedPositionNotional = vars.liquidatedPositionNotional.neg256();
        // note that this function will realize pnl if it's reducing liquidator's existing position size
        vars.liquidatorRealizedPnl = _modifyPositionAndRealizePnl(
            params.chAddress,
            params.liquidator,
            params.baseToken,
            vars.liquidatorExchangedPositionSize, // exchangedPositionSize
            vars.liquidatorExchangedPositionNotional, // exchangedPositionNotional
            0, // makerFee
            0 // takerFee
        );
        // add fee to pnl
        IAccountBalance(IClearingHouse(params.chAddress).getAccountBalance()).modifyOwedRealizedPnl(
            params.liquidator,
            vars.liquidationFeeToLiquidator.toInt256()
        );

        GenericLogic.requireEnoughFreeCollateral(params.chAddress, params.liquidator);

        IVault(IClearingHouse(params.chAddress).getVault()).settleBadDebt(params.trader);

        emit GenericLogic.PositionLiquidated(
            params.trader,
            params.baseToken,
            vars.liquidatedPositionSize.abs(),
            vars.liquidatedPositionNotional.abs(),
            vars.liquidationPenalty,
            params.liquidator,
            vars.liquidationFeeToLiquidator
        );

        // for miner amount
        rewardMinerMint(
            params.chAddress,
            params.trader,
            vars.liquidatedPositionNotional.abs(),
            vars.traderRealizedPnl.add(vars.liquidationPenalty.toInt256().neg256())
        );

        rewardMinerMint(
            params.chAddress,
            params.liquidator,
            vars.liquidatorExchangedPositionNotional.abs(),
            vars.liquidatorRealizedPnl.add(vars.liquidationFeeToLiquidator.toInt256())
        );

        return (vars.liquidatedPositionSize.abs(), vars.liquidatedPositionNotional.abs(), vars.liquidationPenalty);
    }

    //
    function swap(address chAddress, IVPool.SwapParams memory params) public returns (InternalSwapResponse memory) {
        IMarketRegistry.MarketInfo memory marketInfo = IMarketRegistry(IClearingHouse(chAddress).getMarketRegistry())
            .getMarketInfo(params.baseToken);

        (uint256 scaledAmountForUniswapV3PoolSwap, int256 signedScaledAmountForReplaySwap) = PerpMath
            .calcScaledAmountForSwaps(
                params.isBaseToQuote,
                params.isExactInput,
                params.amount,
                marketInfo.uniswapFeeRatio
            );

        // simulate the swap to calculate the fees charged in exchange
        UniswapV3Broker.ReplaySwapResponse memory replayResponse = UniswapV3Broker.replaySwap(
            IMarketRegistry(IClearingHouse(chAddress).getMarketRegistry()).getPool(params.baseToken),
            UniswapV3Broker.ReplaySwapParams({
                baseToken: params.baseToken,
                isBaseToQuote: params.isBaseToQuote,
                shouldUpdateState: true,
                amount: signedScaledAmountForReplaySwap,
                sqrtPriceLimitX96: params.sqrtPriceLimitX96,
                uniswapFeeRatio: marketInfo.uniswapFeeRatio
            })
        );

        UniswapV3Broker.SwapResponse memory response = UniswapV3Broker.swap(
            UniswapV3Broker.SwapParams(
                marketInfo.pool,
                chAddress,
                params.isBaseToQuote,
                params.isExactInput,
                // mint extra base token before swap
                scaledAmountForUniswapV3PoolSwap,
                params.sqrtPriceLimitX96,
                abi.encode(
                    IVPool.SwapCallbackData({
                        trader: params.trader,
                        baseToken: params.baseToken,
                        pool: marketInfo.pool,
                        fee: replayResponse.fee,
                        uniswapFeeRatio: marketInfo.uniswapFeeRatio
                    })
                )
            )
        );

        // as we charge fees in ClearingHouse instead of in Uniswap pools,
        // we need to scale up base or quote amounts to get the exact exchanged position size and notional
        int256 exchangedPositionSize;
        int256 exchangedPositionNotional;
        if (params.isBaseToQuote) {
            // short: exchangedPositionSize <= 0 && exchangedPositionNotional >= 0
            exchangedPositionSize = PerpMath
                .calcAmountScaledByFeeRatio(response.base, marketInfo.uniswapFeeRatio, false)
                .neg256();
            // due to base to quote fee, exchangedPositionNotional contains the fee
            // s.t. we can take the fee away from exchangedPositionNotional
            exchangedPositionNotional = response.quote.toInt256();
        } else {
            // long: exchangedPositionSize >= 0 && exchangedPositionNotional <= 0
            exchangedPositionSize = response.base.toInt256();

            // scaledAmountForUniswapV3PoolSwap is the amount of quote token to swap (input),
            // response.quote is the actual amount of quote token swapped (output).
            // as long as liquidity is enough, they would be equal.
            // otherwise, response.quote < scaledAmountForUniswapV3PoolSwap
            // which also means response.quote < exact input amount.
            if (params.isExactInput && response.quote == scaledAmountForUniswapV3PoolSwap) {
                // NOTE: replayResponse.fee might have an extra charge of 1 wei, for instance:
                // Q2B exact input amount 1000000000000000000000 with fee ratio 1%,
                // replayResponse.fee is actually 10000000000000000001 (1000 * 1% + 1 wei),
                // and quote = exchangedPositionNotional - replayResponse.fee = -1000000000000000000001
                // which is not matched with exact input 1000000000000000000000
                // we modify exchangedPositionNotional here to make sure
                // quote = exchangedPositionNotional - replayResponse.fee = exact input
                exchangedPositionNotional = params.amount.sub(replayResponse.fee).toInt256().neg256();
            } else {
                exchangedPositionNotional = PerpMath
                    .calcAmountScaledByFeeRatio(response.quote, marketInfo.uniswapFeeRatio, false)
                    .neg256();
            }
        }

        // // update the timestamp of the first tx in this market
        // if (_firstTradedTimestampMap[params.baseToken] == 0) {
        //     _firstTradedTimestampMap[params.baseToken] = _blockTimestamp();
        // }

        return
            InternalSwapResponse({
                base: exchangedPositionSize,
                quote: exchangedPositionNotional.sub(replayResponse.fee.toInt256()),
                exchangedPositionSize: exchangedPositionSize,
                exchangedPositionNotional: exchangedPositionNotional,
                fee: replayResponse.fee,
                tick: replayResponse.tick
            });
    }

    function estimateSwap(
        address chAddress,
        DataTypes.OpenPositionParams memory params
    ) public view returns (UniswapV3Broker.ReplaySwapResponse memory response) {
        IMarketRegistry.MarketInfo memory marketInfo = IMarketRegistry(IClearingHouse(chAddress).getMarketRegistry())
            .getMarketInfo(params.baseToken);
        uint24 uniswapFeeRatio = marketInfo.uniswapFeeRatio;
        (, int256 signedScaledAmountForReplaySwap) = PerpMath.calcScaledAmountForSwaps(
            params.isBaseToQuote,
            params.isExactInput,
            params.amount,
            uniswapFeeRatio
        );
        response = UniswapV3Broker.estimateSwap(
            IMarketRegistry(IClearingHouse(chAddress).getMarketRegistry()).getPool(params.baseToken),
            UniswapV3Broker.ReplaySwapParams({
                baseToken: params.baseToken,
                isBaseToQuote: params.isBaseToQuote,
                amount: signedScaledAmountForReplaySwap,
                sqrtPriceLimitX96: params.sqrtPriceLimitX96,
                uniswapFeeRatio: uniswapFeeRatio,
                shouldUpdateState: false
            })
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;
import { IAccountBalance } from "../interface/IAccountBalance.sol";
import { IBaseToken } from "../interface/IBaseToken.sol";
import { IIndexPrice } from "../interface/IIndexPrice.sol";
import { IClearingHouse } from "../interface/IClearingHouse.sol";
import { IClearingHouseConfig } from "../interface/IClearingHouseConfig.sol";
import { IVPool } from "../interface/IVPool.sol";
import { IVault } from "../interface/IVault.sol";
import { IMarketRegistry } from "../interface/IMarketRegistry.sol";
import { IInsuranceFund } from "../interface/IInsuranceFund.sol";
import { FullMath } from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import { PerpSafeCast } from "./PerpSafeCast.sol";
import { PerpMath } from "./PerpMath.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { SignedSafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import { DataTypes } from "../types/DataTypes.sol";
import { UniswapV3Broker } from "./UniswapV3Broker.sol";

library GenericLogic {
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;
    using PerpSafeCast for uint256;
    using PerpSafeCast for uint128;
    using PerpSafeCast for int256;
    using PerpMath for uint256;
    using PerpMath for uint160;
    using PerpMath for uint128;
    using PerpMath for int256;

    uint256 internal constant _FULLY_CLOSED_RATIO = 1e18;

    //internal struct
    struct InternalCheckSlippageParams {
        bool isBaseToQuote;
        bool isExactInput;
        uint256 base;
        uint256 quote;
        uint256 oppositeAmountBound;
    }

    struct InternalUpdateInfoMultiplierVars {
        bool isBaseToQuote;
        int256 deltaBase;
        uint256 newDeltaBase;
        uint256 newDeltaQuote;
        uint256 newLongPositionSizeRate;
        uint256 newShortPositionSizeRate;
        int256 costDeltaQuote;
        bool isEnoughFund;
    }

    //event

    event FundingPaymentSettled(address indexed trader, address indexed baseToken, int256 fundingPayment);

    event MultiplierCostSpend(address indexed baseToken, int256 cost);

    /// @notice Emitted when taker's position is being changed
    /// @param trader Trader address
    /// @param baseToken The address of virtual base token(ETH, BTC, etc...)
    /// @param exchangedPositionSize The actual amount swap to uniswapV3 pool
    /// @param exchangedPositionNotional The cost of position, include fee
    /// @param fee The fee of open/close position
    /// @param openNotional The cost of open/close position, < 0: long, > 0: short
    /// @param realizedPnl The realized Pnl after open/close position
    /// @param sqrtPriceAfterX96 The sqrt price after swap, in X96
    event PositionChanged(
        address indexed trader,
        address indexed baseToken,
        int256 exchangedPositionSize,
        int256 exchangedPositionNotional,
        uint256 fee,
        int256 openNotional,
        int256 realizedPnl,
        uint256 sqrtPriceAfterX96
    );

    //event
    event PositionLiquidated(
        address indexed trader,
        address indexed baseToken,
        uint256 positionSize,
        uint256 positionNotional,
        uint256 liquidationPenaltyFee,
        address liquidator,
        uint256 liquidatorFee
    );

    /// @notice Emitted when maker's liquidity of a order changed
    /// @param baseToken The address of virtual base token(ETH, BTC, etc...)
    /// @param quoteToken The address of virtual USD token
    /// @param base The amount of base token added (> 0) / removed (< 0) as liquidity; fees not included
    /// @param quote The amount of quote token added ... (same as the above)
    /// @param liquidity The amount of liquidity unit added (> 0) / removed (< 0)
    event LiquidityChanged(
        address indexed baseToken,
        address indexed quoteToken,
        int256 base,
        int256 quote,
        int128 liquidity
    );

    /// @notice Emitted when open position with non-zero referral code
    /// @param referralCode The referral code by partners
    event ReferredPositionChanged(bytes32 indexed referralCode);

    //====================== END Event

    function requireNotMaker(address chAddress, address maker) internal view {
        // not Maker
        require(maker != IClearingHouse(chAddress).getMaker(), "CHD_NM");
    }

    function isLiquidatable(address chAddress, address trader) internal view returns (bool) {
        return
            getAccountValue(chAddress, trader) <
            IAccountBalance(IClearingHouse(chAddress).getAccountBalance()).getMarginRequirementForLiquidation(trader);
    }

    function checkMarketOpen(address baseToken) public view {
        // CH_MNO: Market not opened
        require(IBaseToken(baseToken).isOpen(), "CH_MNO");
    }

    function registerBaseToken(address chAddress, address trader, address baseToken) public {
        IAccountBalance(IClearingHouse(chAddress).getAccountBalance()).registerBaseToken(trader, baseToken);
    }

    function settleFundingGlobal(
        address chAddress,
        address baseToken
    ) public returns (DataTypes.Growth memory fundingGrowthGlobal) {
        (fundingGrowthGlobal) = IVPool(IClearingHouse(chAddress).getVPool()).settleFundingGlobal(baseToken);
        return fundingGrowthGlobal;
    }

    function settleFunding(
        address chAddress,
        address trader,
        address baseToken
    ) public returns (DataTypes.Growth memory fundingGrowthGlobal, int256 fundingPayment) {
        (fundingPayment, fundingGrowthGlobal) = IVPool(IClearingHouse(chAddress).getVPool()).settleFunding(
            trader,
            baseToken
        );
        if (fundingPayment != 0) {
            IAccountBalance(IClearingHouse(chAddress).getAccountBalance()).modifyOwedRealizedPnl(
                trader,
                fundingPayment.neg256()
            );
            emit FundingPaymentSettled(trader, baseToken, fundingPayment);
        }

        IAccountBalance(IClearingHouse(chAddress).getAccountBalance()).updateTwPremiumGrowthGlobal(
            trader,
            baseToken,
            fundingGrowthGlobal.twLongPremiumX96,
            fundingGrowthGlobal.twShortPremiumX96
        );
        return (fundingGrowthGlobal, fundingPayment);
    }

    function getFreeCollateralByRatio(address chAddress, address trader, uint24 ratio) public view returns (int256) {
        return IVault(IClearingHouse(chAddress).getVault()).getFreeCollateralByRatio(trader, ratio);
    }

    function checkSlippageAfterLiquidityChange(
        uint256 base,
        uint256 minBase,
        uint256 quote,
        uint256 minQuote
    ) public pure {
        // CH_PSCF: price slippage check fails
        require(base >= minBase && quote >= minQuote, "CH_PSCF");
    }

    function getSqrtMarkX96(address chAddress, address baseToken) public view returns (uint160) {
        return IVPool(IClearingHouse(chAddress).getVPool()).getSqrtMarkTwapX96(baseToken, 0);
    }

    function requireEnoughFreeCollateral(address chAddress, address trader) public view {
        if (trader == IClearingHouse(chAddress).getMaker()) return;
        // CH_NEFCI: not enough free collateral by imRatio
        require(
            getFreeCollateralByRatio(
                chAddress,
                trader,
                IClearingHouseConfig(IClearingHouse(chAddress).getClearingHouseConfig()).getImRatio()
            ) >= 0,
            "CH_NEFCI"
        );
    }

    function requireEnoughFreeCollateralForClose(address chAddress, address trader) public view {
        if (trader == IClearingHouse(chAddress).getMaker()) return;
        // CH_NEFCM: not enough free collateral by mmRatio
        require(
            getFreeCollateralByRatio(
                chAddress,
                trader,
                IClearingHouseConfig(IClearingHouse(chAddress).getClearingHouseConfig()).getMmRatio()
            ) >= 0,
            "CH_NEFCM"
        );
    }

    function getTakerOpenNotional(address chAddress, address trader, address baseToken) public view returns (int256) {
        return IAccountBalance(IClearingHouse(chAddress).getAccountBalance()).getTakerOpenNotional(trader, baseToken);
    }

    function getAccountValue(address chAddress, address trader) public view returns (int256) {
        return
            IVault(IClearingHouse(chAddress).getVault()).getAccountValue(trader).parseSettlementToken(
                IVault(IClearingHouse(chAddress).getVault()).decimals()
            );
    }

    function checkSlippage(InternalCheckSlippageParams memory params) public pure {
        // skip when params.oppositeAmountBound is zero
        if (params.oppositeAmountBound == 0) {
            return;
        }

        // B2Q + exact input, want more output quote as possible, so we set a lower bound of output quote
        // B2Q + exact output, want less input base as possible, so we set a upper bound of input base
        // Q2B + exact input, want more output base as possible, so we set a lower bound of output base
        // Q2B + exact output, want less input quote as possible, so we set a upper bound of input quote
        if (params.isBaseToQuote) {
            if (params.isExactInput) {
                // too little received when short
                require(params.quote >= params.oppositeAmountBound, "CH_TLRS");
            } else {
                // too much requested when short
                require(params.base <= params.oppositeAmountBound, "CH_TMRS");
            }
        } else {
            if (params.isExactInput) {
                // too little received when long
                require(params.base >= params.oppositeAmountBound, "CH_TLRL");
            } else {
                // too much requested when long
                require(params.quote <= params.oppositeAmountBound, "CH_TMRL");
            }
        }
    }

    function getTakerPositionSafe(address chAddress, address trader, address baseToken) public view returns (int256) {
        int256 takerPositionSize = IAccountBalance(IClearingHouse(chAddress).getAccountBalance()).getTakerPositionSize(
            trader,
            baseToken
        );
        // CH_PSZ: position size is zero
        require(takerPositionSize != 0, "CH_PSZ");
        return takerPositionSize;
    }

    function getOppositeAmount(
        address chAddress,
        uint256 oppositeAmountBound,
        bool isPartialClose
    ) internal view returns (uint256) {
        return
            isPartialClose
                ? oppositeAmountBound.mulRatio(
                    IClearingHouseConfig(IClearingHouse(chAddress).getClearingHouseConfig()).getPartialCloseRatio()
                )
                : oppositeAmountBound;
    }

    function getLiquidationPenaltyRatio(address chAddress) internal view returns (uint24) {
        return IClearingHouseConfig(IClearingHouse(chAddress).getClearingHouseConfig()).getLiquidationPenaltyRatio();
    }

    function getIndexPrice(address chAddress, address baseToken) internal view returns (uint256) {
        return
            IIndexPrice(baseToken).getIndexPrice(
                IClearingHouseConfig(IClearingHouse(chAddress).getClearingHouseConfig()).getTwapInterval()
            );
    }

    function getInsuranceFundFeeRatio(
        address exchange,
        address marketRegistry,
        address baseToken,
        bool isBaseToQuote
    ) public view returns (uint256) {
        (, uint256 markTwap, uint256 indexTwap) = IVPool(exchange).getFundingGrowthGlobalAndTwaps(baseToken);
        int256 deltaTwapRatio = (markTwap.toInt256().sub(indexTwap.toInt256())).mulDiv(1e6, indexTwap);
        IMarketRegistry.MarketInfo memory marketInfo = IMarketRegistry(marketRegistry).getMarketInfo(baseToken);
        // delta <= 2.5%
        if (deltaTwapRatio.abs() <= marketInfo.optimalDeltaTwapRatio) {
            return marketInfo.insuranceFundFeeRatio;
        }
        if ((isBaseToQuote && deltaTwapRatio > 0) || (!isBaseToQuote && deltaTwapRatio < 0)) {
            return 0;
        }
        // 2.5% < delta <= 5%
        if (
            marketInfo.optimalDeltaTwapRatio < deltaTwapRatio.abs() &&
            deltaTwapRatio.abs() <= marketInfo.unhealthyDeltaTwapRatio
        ) {
            return deltaTwapRatio.abs().mul(marketInfo.optimalFundingRatio).div(1e6);
        }
        // 5% < delta
        return
            PerpMath.min(
                deltaTwapRatio.abs(),
                uint256(IClearingHouseConfig(IVPool(exchange).getClearingHouseConfig()).getMaxFundingRate())
            );
    }

    function getNewPositionSizeForMultiplierRate(
        uint256 longPositionSize,
        uint256 shortPositionSize,
        uint256 oldMarkPrice,
        uint256 newMarkPrice,
        uint256 newDeltaPositionSize
    ) internal pure returns (uint256 newLongPositionSizeRate, uint256 newShortPositionSizeRate) {
        (uint256 newLongPositionSize, uint256 newShortPositionSize) = getNewPositionSizeForMultiplier(
            longPositionSize,
            shortPositionSize,
            oldMarkPrice,
            newMarkPrice,
            newDeltaPositionSize
        );
        newLongPositionSizeRate = longPositionSize != 0 ? newLongPositionSize.divMultiplier(longPositionSize) : 0;
        newShortPositionSizeRate = shortPositionSize != 0 ? newShortPositionSize.divMultiplier(shortPositionSize) : 0;
    }

    function getNewPositionSizeForMultiplier(
        uint256 longPositionSize,
        uint256 shortPositionSize,
        uint256 oldMarkPrice,
        uint256 newMarkPrice,
        uint256 newDeltaPositionSize
    ) internal pure returns (uint256 newLongPositionSize, uint256 newShortPositionSize) {
        newLongPositionSize = longPositionSize;
        newShortPositionSize = shortPositionSize;

        if ((longPositionSize + shortPositionSize) == 0) {
            return (newLongPositionSize, newShortPositionSize);
        }

        if (longPositionSize == shortPositionSize && oldMarkPrice == newMarkPrice) {
            return (newLongPositionSize, newShortPositionSize);
        }

        if (oldMarkPrice != newMarkPrice) {
            // GL_IP: Invalid Price
            require(oldMarkPrice > 0 && newMarkPrice > 0, "GL_IP");
            newLongPositionSize = FullMath.mulDiv(newLongPositionSize, oldMarkPrice, newMarkPrice);
            newShortPositionSize = FullMath.mulDiv(newShortPositionSize, oldMarkPrice, newMarkPrice);
        }

        // ajust to new delta base if newDeltaPositionSize > 0
        if (newDeltaPositionSize > 0) {
            uint256 oldDetalPositionSize = newLongPositionSize.toInt256().sub(newShortPositionSize.toInt256()).abs();
            int256 diffDetalPositionSize = newDeltaPositionSize.toInt256().sub(oldDetalPositionSize.toInt256());
            uint256 newTotalPositionSize = newLongPositionSize.add(newShortPositionSize);

            if (
                (diffDetalPositionSize > 0 && newLongPositionSize > newShortPositionSize) ||
                (diffDetalPositionSize < 0 && newLongPositionSize < newShortPositionSize)
            ) {
                newLongPositionSize = FullMath.mulDiv(
                    newLongPositionSize,
                    (1e18 + FullMath.mulDiv(diffDetalPositionSize.abs(), 1e18, newTotalPositionSize)),
                    1e18
                );
                newShortPositionSize = FullMath.mulDiv(
                    newShortPositionSize,
                    (1e18 - FullMath.mulDiv(diffDetalPositionSize.abs(), 1e18, newTotalPositionSize)),
                    1e18
                );
            } else if (
                (diffDetalPositionSize > 0 && newLongPositionSize < newShortPositionSize) ||
                (diffDetalPositionSize < 0 && newLongPositionSize > newShortPositionSize)
            ) {
                newLongPositionSize = FullMath.mulDiv(
                    newLongPositionSize,
                    (1e18 - FullMath.mulDiv(diffDetalPositionSize.abs(), 1e18, newTotalPositionSize)),
                    1e18
                );
                newShortPositionSize = FullMath.mulDiv(
                    newShortPositionSize,
                    (1e18 + FullMath.mulDiv(diffDetalPositionSize.abs(), 1e18, newTotalPositionSize)),
                    1e18
                );
            }
        }

        return (newLongPositionSize, newShortPositionSize);
    }

    function getInfoMultiplier(
        address chAddress,
        address baseToken
    ) internal view returns (uint256 oldLongPositionSize, uint256 oldShortPositionSize, uint256 deltaQuote) {
        (oldLongPositionSize, oldShortPositionSize) = IAccountBalance(IClearingHouse(chAddress).getAccountBalance())
            .getMarketPositionSize(baseToken);
        int256 oldDeltaBase = oldLongPositionSize.toInt256().sub(oldShortPositionSize.toInt256());
        if (oldDeltaBase != 0) {
            bool isBaseToQuote = oldDeltaBase > 0 ? true : false;
            UniswapV3Broker.ReplaySwapResponse memory estimate = IVPool(IClearingHouse(chAddress).getVPool())
                .estimateSwap(
                    DataTypes.OpenPositionParams({
                        baseToken: baseToken,
                        isBaseToQuote: isBaseToQuote,
                        isExactInput: isBaseToQuote,
                        oppositeAmountBound: 0,
                        amount: uint256(oldDeltaBase.abs()),
                        sqrtPriceLimitX96: 0,
                        deadline: block.timestamp + 60,
                        referralCode: ""
                    })
                );
            deltaQuote = isBaseToQuote ? estimate.amountOut : estimate.amountIn;
        }
    }

    function updateInfoMultiplier(
        address chAddress,
        address baseToken,
        uint256 longPositionSize,
        uint256 shortPositionSize,
        uint256 oldDeltaQuote,
        uint256 oldMarkPrice,
        uint256 newMarkPrice,
        bool isFixedPositionSize
    ) internal {
        InternalUpdateInfoMultiplierVars memory vars;

        vars.deltaBase = longPositionSize.toInt256().sub(shortPositionSize.toInt256());
        vars.isBaseToQuote = vars.deltaBase > 0 ? true : false;

        // update new size by price
        {
            (vars.newLongPositionSizeRate, vars.newShortPositionSizeRate) = GenericLogic
                .getNewPositionSizeForMultiplierRate(
                    longPositionSize,
                    shortPositionSize,
                    oldMarkPrice,
                    newMarkPrice,
                    0
                );
            IAccountBalance(IClearingHouse(chAddress).getAccountBalance()).modifyMarketMultiplier(
                baseToken,
                vars.newLongPositionSizeRate,
                vars.newShortPositionSizeRate
            );
        }

        (longPositionSize, shortPositionSize) = IAccountBalance(IClearingHouse(chAddress).getAccountBalance())
            .getMarketPositionSize(baseToken);

        vars.deltaBase = longPositionSize.toInt256().sub(shortPositionSize.toInt256());
        if (vars.deltaBase != 0) {
            UniswapV3Broker.ReplaySwapResponse memory estimate = IVPool(IClearingHouse(chAddress).getVPool())
                .estimateSwap(
                    DataTypes.OpenPositionParams({
                        baseToken: baseToken,
                        isBaseToQuote: vars.isBaseToQuote,
                        isExactInput: vars.isBaseToQuote,
                        oppositeAmountBound: 0,
                        amount: vars.deltaBase.abs(),
                        sqrtPriceLimitX96: 0,
                        deadline: block.timestamp + 60,
                        referralCode: ""
                    })
                );
            vars.newDeltaQuote = vars.isBaseToQuote ? estimate.amountOut : estimate.amountIn;
            vars.costDeltaQuote = (
                vars.isBaseToQuote
                    ? vars.newDeltaQuote.toInt256().sub(oldDeltaQuote.toInt256())
                    : oldDeltaQuote.toInt256().sub(vars.newDeltaQuote.toInt256())
            );
        }

        if (!isFixedPositionSize) {
            // for repeg price
            // estimate for check cost and fund
            vars.isEnoughFund = false;
            if (vars.costDeltaQuote > 0) {
                int256 remainDistributedFund = IInsuranceFund(IClearingHouse(chAddress).getInsuranceFund())
                    .getRepegAccumulatedFund()
                    .sub(IInsuranceFund(IClearingHouse(chAddress).getInsuranceFund()).getRepegDistributedFund());
                int256 freeCollateral = IVault(IClearingHouse(chAddress).getVault())
                    .getFreeCollateralByToken(
                        IClearingHouse(chAddress).getInsuranceFund(),
                        IInsuranceFund(IClearingHouse(chAddress).getInsuranceFund()).getToken()
                    )
                    .toInt256();
                if (remainDistributedFund >= vars.costDeltaQuote) {
                    if (freeCollateral >= vars.costDeltaQuote) {
                        vars.isEnoughFund = true;
                    }
                }
                if (!vars.isEnoughFund) {
                    // using cost with owedRealizedPnl from insuranceFund
                    vars.costDeltaQuote = PerpMath.min(
                        vars.costDeltaQuote,
                        PerpMath.min(
                            remainDistributedFund > 0 ? remainDistributedFund : 0,
                            freeCollateral > 0 ? freeCollateral : 0
                        )
                    );
                }
            } else {
                vars.isEnoughFund = true;
            }
            if (!vars.isEnoughFund) {
                // estimate cost to base
                UniswapV3Broker.ReplaySwapResponse memory estimate = IVPool(IClearingHouse(chAddress).getVPool())
                    .estimateSwap(
                        DataTypes.OpenPositionParams({
                            baseToken: baseToken,
                            isBaseToQuote: vars.isBaseToQuote,
                            isExactInput: !vars.isBaseToQuote,
                            oppositeAmountBound: 0,
                            amount: (
                                vars.isBaseToQuote
                                    ? oldDeltaQuote.add(vars.costDeltaQuote.abs())
                                    : oldDeltaQuote.sub(vars.costDeltaQuote.abs())
                            ),
                            sqrtPriceLimitX96: 0,
                            deadline: block.timestamp + 60,
                            referralCode: ""
                        })
                    );
                vars.newDeltaBase = vars.isBaseToQuote ? estimate.amountIn : estimate.amountOut;
                (vars.newLongPositionSizeRate, vars.newShortPositionSizeRate) = GenericLogic
                    .getNewPositionSizeForMultiplierRate(
                        longPositionSize,
                        shortPositionSize,
                        newMarkPrice,
                        newMarkPrice,
                        vars.newDeltaBase
                    );
                IAccountBalance(IClearingHouse(chAddress).getAccountBalance()).modifyMarketMultiplier(
                    baseToken,
                    vars.newLongPositionSizeRate,
                    vars.newShortPositionSizeRate
                );
            }
        }
        if (vars.costDeltaQuote != 0) {
            // update repeg fund
            IInsuranceFund(IClearingHouse(chAddress).getInsuranceFund()).repegFund(vars.costDeltaQuote);
            // update RealizedPnl for InsuranceFund
            IAccountBalance(IClearingHouse(chAddress).getAccountBalance()).modifyOwedRealizedPnl(
                IClearingHouse(chAddress).getInsuranceFund(),
                vars.costDeltaQuote.neg256()
            );
            // check RealizedPnl for InsuranceFund after repeg
            int256 freeCollateral = IVault(IClearingHouse(chAddress).getVault())
                .getFreeCollateralByToken(
                    IClearingHouse(chAddress).getInsuranceFund(),
                    IInsuranceFund(IClearingHouse(chAddress).getInsuranceFund()).getToken()
                )
                .toInt256();
            // GL_INE: InsuranceFund not fee fund
            require(freeCollateral >= 0, "GL_INFF");
            // emit event
            emit MultiplierCostSpend(baseToken, vars.costDeltaQuote);
        }
    }

    function addLiquidity(
        address chAddress,
        DataTypes.AddLiquidityParams calldata params
    )
        public
        returns (
            // check onlyLiquidityAdmin
            DataTypes.AddLiquidityResponse memory
        )
    {
        // input requirement checks:
        //   baseToken: in Exchange.settleFunding()
        //   base & quote: in LiquidityAmounts.getLiquidityForAmounts() -> FullMath.mulDiv()
        //   lowerTick & upperTick: in UniswapV3Pool._modifyPosition()
        //   minBase, minQuote & deadline: here

        checkMarketOpen(params.baseToken);

        // This condition is to prevent the intentional bad debt attack through price manipulation.
        // CH_OMPS: Over the maximum price spread
        // require(!IVPool(IClearingHouse(chAddress).getVPool()).isOverPriceSpread(params.baseToken), "CH_OMPS");

        settleFundingGlobal(chAddress, params.baseToken);

        // for multiplier
        (uint256 oldLongPositionSize, uint256 oldShortPositionSize, uint256 oldDeltaQuote) = GenericLogic
            .getInfoMultiplier(chAddress, params.baseToken);
        // for multiplier

        // note that we no longer check available tokens here because CH will always auto-mint in UniswapV3MintCallback
        UniswapV3Broker.AddLiquidityResponse memory response = UniswapV3Broker.addLiquidity(
            IMarketRegistry(IClearingHouse(chAddress).getMarketRegistry()).getPool(params.baseToken),
            UniswapV3Broker.AddLiquidityParams({ baseToken: params.baseToken, liquidity: params.liquidity })
        );

        // for multiplier
        updateInfoMultiplier(
            chAddress,
            params.baseToken,
            oldLongPositionSize,
            oldShortPositionSize,
            oldDeltaQuote,
            0,
            0,
            true
        );
        // for multiplier

        emit LiquidityChanged(
            params.baseToken,
            IClearingHouse(chAddress).getQuoteToken(),
            response.base.toInt256(),
            response.quote.toInt256(),
            response.liquidity.toInt128()
        );

        return
            DataTypes.AddLiquidityResponse({
                base: response.base,
                quote: response.quote,
                liquidity: response.liquidity
            });
    }

    function removeLiquidity(
        address chAddress,
        DataTypes.RemoveLiquidityParams memory params
    ) public returns (DataTypes.RemoveLiquidityResponse memory) {
        // input requirement checks:
        //   baseToken: in Exchange.settleFunding()
        //   lowerTick & upperTick: in UniswapV3Pool._modifyPosition()
        //   liquidity: in LiquidityMath.addDelta()
        //   minBase, minQuote & deadline: here

        // CH_MP: Market paused
        require(!IBaseToken(params.baseToken).isPaused(), "CH_MP");

        settleFundingGlobal(chAddress, params.baseToken);

        // for multiplier
        (uint256 oldLongPositionSize, uint256 oldShortPositionSize, uint256 oldDeltaQuote) = GenericLogic
            .getInfoMultiplier(chAddress, params.baseToken);
        // for multiplier

        // must settle funding first

        UniswapV3Broker.RemoveLiquidityResponse memory response = UniswapV3Broker.removeLiquidity(
            IMarketRegistry(IClearingHouse(chAddress).getMarketRegistry()).getPool(params.baseToken),
            chAddress,
            UniswapV3Broker.RemoveLiquidityParams({ baseToken: params.baseToken, liquidity: params.liquidity })
        );

        // for multiplier
        updateInfoMultiplier(
            chAddress,
            params.baseToken,
            oldLongPositionSize,
            oldShortPositionSize,
            oldDeltaQuote,
            0,
            0,
            true
        );
        // for multiplier

        emit LiquidityChanged(
            params.baseToken,
            IClearingHouse(chAddress).getQuoteToken(),
            response.base.neg256(),
            response.quote.neg256(),
            params.liquidity.neg128()
        );

        return DataTypes.RemoveLiquidityResponse({ quote: response.quote, base: response.base });
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

interface IMarketRegistry {
    struct MarketInfo {
        address pool;
        uint24 uniswapFeeRatio;
        uint24 insuranceFundFeeRatio;
        uint24 platformFundFeeRatio;
        uint24 optimalDeltaTwapRatio;
        uint24 unhealthyDeltaTwapRatio;
        uint24 optimalFundingRatio;
    }

    /// @notice Emitted when a new market is created.
    /// @param baseToken The address of the base token
    /// @param feeRatio Fee ratio of the market
    /// @param pool The address of the pool
    event PoolAdded(address indexed baseToken, uint24 indexed feeRatio, address indexed pool);

    /// @notice Emitted when the fee ratio of a market is updated.
    /// @param baseToken The address of the base token
    /// @param feeRatio Fee ratio of the market
    event PlatformFundFeeRatioChanged(address baseToken, uint24 feeRatio);

    /// @notice Emitted when the insurance fund fee ratio is updated.
    /// @param baseToken The address of the base token
    /// @param feeRatio Insurance fund fee ratio
    event InsuranceFundFeeRatioChanged(address baseToken, uint24 feeRatio);

    /// @notice Emitted when the max orders per market is updated.
    /// @param maxOrdersPerMarket Max orders per market
    event MaxOrdersPerMarketChanged(uint8 maxOrdersPerMarket);

    /// @dev Add a new pool to the registry.
    /// @param baseToken The token that the pool is for.
    /// @param feeRatio The fee ratio for the pool.
    /// @return pool The address of the pool.
    function addPool(address baseToken, uint24 feeRatio) external returns (address pool);

    /// @dev Set the fee ratio for a pool
    /// @param baseToken The token address of the pool.
    /// @param feeRatio The fee ratio for the pool.
    function setPlatformFundFeeRatio(address baseToken, uint24 feeRatio) external;

    /// @dev Set insurance fund fee ratio for a pool
    /// @param baseToken The token address of the pool.
    /// @param insuranceFundFeeRatioArg The fee ratio for the pool.
    function setInsuranceFundFeeRatio(address baseToken, uint24 insuranceFundFeeRatioArg) external;

    /// @dev Set max allowed orders per market
    /// @param maxOrdersPerMarketArg The max allowed orders per market
    function setMaxOrdersPerMarket(uint8 maxOrdersPerMarketArg) external;

    /// @notice Get the pool address (UNIv3 pool) by given base token address
    /// @param baseToken The address of the base token
    /// @return pool The address of the pool
    function getPool(address baseToken) external view returns (address pool);

    /// @notice Get the insurance fund fee ratio of a given market
    /// @dev The ratio is in `1e6` format, that means `1% = 1e4`
    /// @param baseToken The address of the base token
    /// @return feeRatio The fee ratio of the market, it is a decimal in `1e6`
    function getInsuranceFundFeeRatio(address baseToken) external view returns (uint24 feeRatio);

    /// @notice Get the insurance fund fee ratio of a given market
    /// @dev The ratio is in `1e6` format, that means `1% = 1e4`
    /// @param baseToken The address of the base token
    /// @return feeRatio The fee ratio of the market, it is a decimal in `1e6`
    function getPlatformFundFeeRatio(address baseToken) external view returns (uint24);

    /// @notice Get the insurance fund fee ratio of a given market
    /// @dev The ratio is in `1e6` format, that means `1% = 1e4`
    /// @param baseToken The address of the base token
    /// @return feeRatio The fee ratio of the market, it is a decimal in `1e6`
    function getOptimalDeltaTwapRatio(address baseToken) external view returns (uint24);

    /// @notice Get the insurance fund fee ratio of a given market
    /// @dev The ratio is in `1e6` format, that means `1% = 1e4`
    /// @param baseToken The address of the base token
    /// @return feeRatio The fee ratio of the market, it is a decimal in `1e6`
    function getOptimalFundingRatio(address baseToken) external view returns (uint24);

    /// @notice Get the market info by given base token address
    /// @param baseToken The address of the base token
    /// @return info The market info encoded as `MarketInfo`
    function getMarketInfo(address baseToken) external view returns (MarketInfo memory info);

    /// @notice Get the quote token address
    /// @return quoteToken The address of the quote token
    function getQuoteToken() external view returns (address quoteToken);

    /// @notice Get Uniswap factory address
    /// @return factory The address of the Uniswap factory
    function getUniswapV3Factory() external view returns (address factory);

    /// @notice Get max allowed orders per market
    /// @return maxOrdersPerMarket The max allowed orders per market
    function getMaxOrdersPerMarket() external view returns (uint8 maxOrdersPerMarket);

    /// @notice Check if a pool exist by given base token address
    /// @return hasPool True if the pool exist, false otherwise
    function hasPool(address baseToken) external view returns (bool hasPool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {
    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public view virtual returns (bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal view virtual returns (address payable);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal view virtual returns (bytes calldata);

    function versionRecipient() external view virtual returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

interface IRewardMiner {
    function mint(address trader, uint256 amount, int256 pnl) external;

}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { SignedSafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import { FullMath } from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import { TickMath } from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import { IUniswapV3SwapCallback } from "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import { BlockContext } from "./base/BlockContext.sol";
import { UniswapV3Broker } from "./lib/UniswapV3Broker.sol";
import { PerpSafeCast } from "./lib/PerpSafeCast.sol";
import { PerpMath } from "./lib/PerpMath.sol";
import { ClearingHouseCallee } from "./base/ClearingHouseCallee.sol";
import { UniswapV3CallbackBridge } from "./base/UniswapV3CallbackBridge.sol";
import { IMarketRegistry } from "./interface/IMarketRegistry.sol";
import { IAccountBalance } from "./interface/IAccountBalance.sol";
import { IClearingHouseConfig } from "./interface/IClearingHouseConfig.sol";
import { IClearingHouse } from "./interface/IClearingHouse.sol";
import { IIndexPrice } from "./interface/IIndexPrice.sol";
import { IBaseToken } from "./interface/IBaseToken.sol";
import { VPoolStorageV2 } from "./storage/VPoolStorage.sol";
import { IVPool } from "./interface/IVPool.sol";
import { DataTypes } from "./types/DataTypes.sol";
import { GenericLogic } from "./lib/GenericLogic.sol";
import { ClearingHouseLogic } from "./lib/ClearingHouseLogic.sol";

// never inherit any new stateful contract. never change the orders of parent stateful contracts
contract VPool is
    IUniswapV3SwapCallback,
    IVPool,
    BlockContext,
    ClearingHouseCallee,
    UniswapV3CallbackBridge,
    VPoolStorageV2
{
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;
    using SignedSafeMathUpgradeable for int24;
    using PerpMath for uint256;
    using PerpMath for uint160;
    using PerpMath for int256;
    using PerpSafeCast for uint256;
    using PerpSafeCast for int256;

    int256 internal constant _DEFAULT_FUNDING_PERIOD = 1 days;
    //
    // STRUCT
    //

    struct InternalReplaySwapParams {
        address baseToken;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint160 sqrtPriceLimitX96;
    }

    struct InternalRealizePnlParams {
        address trader;
        address baseToken;
        int256 takerPositionSize;
        int256 takerOpenNotional;
        int256 base;
        int256 quote;
    }

    struct InternalFundingGrowthGlobalAndTwapsVars {
        uint256 longPositionSize;
        uint256 shortPositionSize;
        uint256 longMultiplier;
        uint256 shortMultiplier;
        int256 deltaTwapX96;
        int256 deltaTwPremiumX96;
        int256 deltaShortTwPremiumX96;
        int256 deltaLongTwPremiumX96;
    }

    //
    // CONSTANT
    //

    uint256 internal constant _FULLY_CLOSED_RATIO = 1e18;
    // uint24 internal constant _MAX_TICK_CROSSED_WITHIN_BLOCK_CAP = 1000; // 10%
    uint24 internal constant _MAX_TICK_CROSSED_WITHIN_BLOCK_CAP = 1774544;
    uint24 internal constant _MAX_PRICE_SPREAD_RATIO = 0.05e6; // 5% in decimal 6
    uint256 internal constant _PRICE_LIMIT_INTERVAL = 15; // 15 sec

    //
    // EXTERNAL NON-VIEW
    //

    function initialize(address marketRegistryArg, address clearingHouseConfigArg) external initializer {
        __ClearingHouseCallee_init();
        __UniswapV3CallbackBridge_init(marketRegistryArg);

        // E_CHNC: CH is not contract
        require(clearingHouseConfigArg.isContract(), "E_CHNC");

        // update states
        _clearingHouseConfig = clearingHouseConfigArg;
    }

    /// @param accountBalanceArg: AccountBalance contract address
    function setAccountBalance(address accountBalanceArg) external onlyOwner {
        // accountBalance  0
        require(accountBalanceArg != address(0), "E_AB0");
        _accountBalance = accountBalanceArg;
        emit AccountBalanceChanged(accountBalanceArg);
    }

    /// @dev Restrict the price impact by setting the ticks can be crossed within a block when
    /// trader reducing liquidity. It is used to prevent the malicious behavior of the malicious traders.
    /// The restriction is applied in _isOverPriceLimitWithTick()
    /// @param baseToken The base token address
    /// @param maxTickCrossedWithinBlock The maximum ticks can be crossed within a block
    function setMaxTickCrossedWithinBlock(address baseToken, uint24 maxTickCrossedWithinBlock) external onlyOwner {
        // EX_BNC: baseToken is not contract
        require(baseToken.isContract(), "EX_BNC");
        // EX_BTNE: base token does not exists
        require(IMarketRegistry(_marketRegistry).hasPool(baseToken), "EX_BTNE");

        // tick range is [MIN_TICK, MAX_TICK], maxTickCrossedWithinBlock should be in [0, MAX_TICK - MIN_TICK]
        // EX_MTCLOOR: max tick crossed limit out of range
        require(maxTickCrossedWithinBlock <= _getMaxTickCrossedWithinBlockCap(), "EX_MTCLOOR");

        _maxTickCrossedWithinBlockMap[baseToken] = maxTickCrossedWithinBlock;
        emit MaxTickCrossedWithinBlockChanged(baseToken, maxTickCrossedWithinBlock);
    }

    /// @inheritdoc IUniswapV3SwapCallback
    /// @dev This callback is forwarded to ClearingHouse.uniswapV3SwapCallback() because all the tokens
    /// are stored in there.
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external override checkCallback {
        IUniswapV3SwapCallback(_clearingHouse).uniswapV3SwapCallback(amount0Delta, amount1Delta, data);
    }

    function internalSwap(SwapParams memory params) external override returns (SwapResponse memory) {
        _requireOnlyClearingHouse();
        ClearingHouseLogic.InternalSwapResponse memory response = _swap(params);
        return
            SwapResponse({
                base: response.base.abs(),
                quote: response.quote.abs(),
                exchangedPositionSize: response.exchangedPositionSize,
                exchangedPositionNotional: response.exchangedPositionNotional,
                insuranceFundFee: 0,
                platformFundFee: 0,
                pnlToBeRealized: 0,
                sqrtPriceAfterX96: 0,
                tick: response.tick,
                isPartialClose: false
            });
    }

    /// @param params The parameters of the swap
    /// @return The result of the swap
    /// @dev can only be called from ClearingHouse
    /// @inheritdoc IVPool
    function swap(SwapParams memory params) external override returns (SwapResponse memory) {
        _requireOnlyClearingHouse();

        // EX_MIP: market is paused
        require(_maxTickCrossedWithinBlockMap[params.baseToken] > 0, "EX_MIP");

        int256 takerPositionSize = IAccountBalance(_accountBalance).getTakerPositionSize(
            params.trader,
            params.baseToken
        );

        bool isPartialClose;
        bool isOverPriceLimit = _isOverPriceLimit(params.baseToken);
        // if over price limit when
        // 1. closing a position, then partially close the position
        // 2. else then revert
        if (params.isClose && takerPositionSize != 0) {
            // if trader is on long side, baseToQuote: true, exactInput: true
            // if trader is on short side, baseToQuote: false (quoteToBase), exactInput: false (exactOutput)
            // simulate the tx to see if it _isOverPriceLimit; if true, can partially close the position only once
            // if this is not the first tx in this timestamp and it's already over limit,
            // then use _isOverPriceLimit is enough
            if (
                isOverPriceLimit ||
                _isOverPriceLimitBySimulatingClosingPosition(
                    params.baseToken,
                    takerPositionSize < 0, // it's a short position
                    params.amount // it's the same as takerPositionSize but in uint256
                )
            ) {
                uint256 timestamp = _blockTimestamp();
                // EX_AOPLO: already over price limit once
                require(timestamp != _lastOverPriceLimitTimestampMap[params.trader][params.baseToken], "EX_AOPLO");

                _lastOverPriceLimitTimestampMap[params.trader][params.baseToken] = timestamp;

                uint24 partialCloseRatio = IClearingHouseConfig(_clearingHouseConfig).getPartialCloseRatio();
                params.amount = params.amount.mulRatio(partialCloseRatio);
                isPartialClose = true;
            }
        } else {
            // EX_OPLBS: over price limit before swap
            require(!isOverPriceLimit, "EX_OPLBS");
        }
        // check fee ratio before swap
        uint256 insuranceFundFeeRatio = getInsuranceFundFeeRatio(params.baseToken, params.isBaseToQuote);
        // get openNotional before swap
        int256 oldTakerOpenNotional = IAccountBalance(_accountBalance).getTakerOpenNotional(
            params.trader,
            params.baseToken
        );
        ClearingHouseLogic.InternalSwapResponse memory response = _swap(params);

        // if (!params.isClose) {
        // over price limit after swap
        require(!_isOverPriceLimitWithTick(params.baseToken, response.tick), "EX_OPLAS");
        // }

        // updateOverPriceSpreadTimestamp for repeg
        _updateOverPriceSpreadTimestamp(params.baseToken);

        // when takerPositionSize < 0, it's a short position
        bool isReducingPosition = takerPositionSize == 0 ? false : takerPositionSize < 0 != params.isBaseToQuote;
        // when reducing/not increasing the position size, it's necessary to realize pnl
        int256 pnlToBeRealized;
        if (isReducingPosition) {
            pnlToBeRealized = _getPnlToBeRealized(
                InternalRealizePnlParams({
                    trader: params.trader,
                    baseToken: params.baseToken,
                    takerPositionSize: takerPositionSize,
                    takerOpenNotional: oldTakerOpenNotional,
                    base: response.base,
                    quote: response.quote
                })
            );
        }

        (uint256 sqrtPriceX96, , , , , , ) = UniswapV3Broker.getSlot0(
            IMarketRegistry(_marketRegistry).getPool(params.baseToken)
        );

        // calculate fee
        IMarketRegistry.MarketInfo memory marketInfo = IMarketRegistry(_marketRegistry).getMarketInfo(params.baseToken);
        // platformFundFee
        uint256 platformFundFee = FullMath.mulDivRoundingUp(
            response.exchangedPositionNotional.abs(),
            marketInfo.platformFundFeeRatio,
            1e6
        );
        // insuranceFundFee
        uint256 insuranceFundFee = FullMath.mulDiv(
            response.exchangedPositionNotional.abs(),
            insuranceFundFeeRatio,
            1e6
        );

        return
            SwapResponse({
                base: response.base.abs(),
                quote: response.quote.abs(),
                exchangedPositionSize: response.exchangedPositionSize,
                exchangedPositionNotional: response.exchangedPositionNotional,
                insuranceFundFee: insuranceFundFee,
                platformFundFee: platformFundFee,
                pnlToBeRealized: pnlToBeRealized,
                sqrtPriceAfterX96: sqrtPriceX96,
                tick: response.tick,
                isPartialClose: isPartialClose
            });
    }

    /// @inheritdoc IVPool
    function settleFundingGlobal(
        address baseToken
    ) external override returns (DataTypes.Growth memory fundingGrowthGlobal) {
        _requireOnlyClearingHouse();
        // EX_BTNE: base token does not exists
        require(IMarketRegistry(_marketRegistry).hasPool(baseToken), "EX_BTNE");

        // if updating TWAP fails, this call will be reverted and thus using try-catch
        try IBaseToken(baseToken).cacheTwap(IClearingHouseConfig(_clearingHouseConfig).getTwapInterval()) {} catch {}
        uint256 markTwap;
        uint256 indexTwap;
        (fundingGrowthGlobal, markTwap, indexTwap) = _getFundingGrowthGlobalAndTwaps(baseToken);

        // funding will be stopped once the market is being paused
        uint256 timestamp = IBaseToken(baseToken).isOpen()
            ? _blockTimestamp()
            : IBaseToken(baseToken).getPausedTimestamp();

        // update states before further actions in this block; once per block
        if (timestamp != _lastSettledTimestampMap[baseToken]) {
            // update fundingGrowthGlobal and _lastSettledTimestamp
            DataTypes.Growth storage lastFundingGrowthGlobal = _globalFundingGrowthX96Map[baseToken];
            (
                _lastSettledTimestampMap[baseToken],
                lastFundingGrowthGlobal.twLongPremiumX96,
                lastFundingGrowthGlobal.twShortPremiumX96
            ) = (timestamp, fundingGrowthGlobal.twLongPremiumX96, fundingGrowthGlobal.twShortPremiumX96);

            (uint256 longPositionSize, uint256 shortPositionSize) = IAccountBalance(_accountBalance)
                .getMarketPositionSize(baseToken);

            emit FundingUpdated(baseToken, markTwap, indexTwap, longPositionSize, shortPositionSize);

            // update tick & timestamp for price limit check
            // if timestamp diff < _PRICE_LIMIT_INTERVAL, including when the market is paused, they won't get updated
            uint256 lastTickUpdatedTimestamp = _lastTickUpdatedTimestampMap[baseToken];
            if (timestamp >= lastTickUpdatedTimestamp.add(_PRICE_LIMIT_INTERVAL)) {
                _lastTickUpdatedTimestampMap[baseToken] = timestamp;
                _lastUpdatedTickMap[baseToken] = _getTick(baseToken);
            }
        }

        return (fundingGrowthGlobal);
    }

    function _calcPendingFundingPaymentWithLiquidityCoefficient(
        int256 baseBalance,
        int256 twLongPremiumGrowthGlobalX96,
        int256 twShortPremiumGrowthGlobalX96,
        DataTypes.Growth memory fundingGrowthGlobal
    ) internal pure returns (int256) {
        int256 balanceCoefficientInFundingPayment = 0;
        if (baseBalance > 0) {
            balanceCoefficientInFundingPayment = PerpMath.mulDiv(
                baseBalance,
                fundingGrowthGlobal.twLongPremiumX96.sub(twLongPremiumGrowthGlobalX96),
                uint256(PerpMath._IQ96)
            );
        }
        if (baseBalance < 0) {
            balanceCoefficientInFundingPayment = PerpMath.mulDiv(
                baseBalance,
                fundingGrowthGlobal.twShortPremiumX96.sub(twShortPremiumGrowthGlobalX96),
                uint256(PerpMath._IQ96)
            );
        }
        return balanceCoefficientInFundingPayment.div(_DEFAULT_FUNDING_PERIOD);
    }

    /// @inheritdoc IVPool
    function settleFunding(
        address trader,
        address baseToken
    ) external override returns (int256 fundingPayment, DataTypes.Growth memory fundingGrowthGlobal) {
        _requireOnlyClearingHouse();
        // EX_BTNE: base token does not exists
        require(IMarketRegistry(_marketRegistry).hasPool(baseToken), "EX_BTNE");

        // if updating TWAP fails, this call will be reverted and thus using try-catch
        try IBaseToken(baseToken).cacheTwap(IClearingHouseConfig(_clearingHouseConfig).getTwapInterval()) {} catch {}
        uint256 markTwap;
        uint256 indexTwap;
        (fundingGrowthGlobal, markTwap, indexTwap) = _getFundingGrowthGlobalAndTwaps(baseToken);

        fundingPayment = _calcPendingFundingPaymentWithLiquidityCoefficient(
            IAccountBalance(_accountBalance).getOriginBase(trader, baseToken),
            IAccountBalance(_accountBalance).getAccountInfo(trader, baseToken).lastLongTwPremiumGrowthGlobalX96,
            IAccountBalance(_accountBalance).getAccountInfo(trader, baseToken).lastShortTwPremiumGrowthGlobalX96,
            fundingGrowthGlobal
        );

        // funding will be stopped once the market is being paused
        uint256 timestamp = IBaseToken(baseToken).isOpen()
            ? _blockTimestamp()
            : IBaseToken(baseToken).getPausedTimestamp();

        // update states before further actions in this block; once per block
        if (timestamp != _lastSettledTimestampMap[baseToken]) {
            // update fundingGrowthGlobal and _lastSettledTimestamp
            DataTypes.Growth storage lastFundingGrowthGlobal = _globalFundingGrowthX96Map[baseToken];
            (
                _lastSettledTimestampMap[baseToken],
                lastFundingGrowthGlobal.twLongPremiumX96,
                lastFundingGrowthGlobal.twShortPremiumX96
            ) = (timestamp, fundingGrowthGlobal.twLongPremiumX96, fundingGrowthGlobal.twShortPremiumX96);

            (uint256 longPositionSize, uint256 shortPositionSize) = IAccountBalance(_accountBalance)
                .getMarketPositionSize(baseToken);

            emit FundingUpdated(baseToken, markTwap, indexTwap, longPositionSize, shortPositionSize);

            // update tick for price limit checks
            _lastUpdatedTickMap[baseToken] = _getTick(baseToken);
        }

        return (fundingPayment, fundingGrowthGlobal);
    }

    //
    // EXTERNAL VIEW
    //

    /// @inheritdoc IVPool
    function getAccountBalance() external view override returns (address) {
        return _accountBalance;
    }

    /// @inheritdoc IVPool
    function getClearingHouseConfig() external view override returns (address) {
        return _clearingHouseConfig;
    }

    /// @inheritdoc IVPool
    function getMaxTickCrossedWithinBlock(address baseToken) external view override returns (uint24) {
        return _maxTickCrossedWithinBlockMap[baseToken];
    }

    /// @inheritdoc IVPool
    function getPnlToBeRealized(RealizePnlParams memory params) external view override returns (int256) {
        DataTypes.AccountMarketInfo memory info = IAccountBalance(_accountBalance).getAccountInfo(
            params.trader,
            params.baseToken
        );

        int256 takerOpenNotional = info.takerOpenNotional;
        int256 takerPositionSize = info.takerPositionSize;
        // when takerPositionSize < 0, it's a short position; when base < 0, isBaseToQuote(shorting)
        bool isReducingPosition = takerPositionSize == 0 ? false : takerPositionSize < 0 != params.base < 0;

        return
            isReducingPosition
                ? _getPnlToBeRealized(
                    InternalRealizePnlParams({
                        trader: params.trader,
                        baseToken: params.baseToken,
                        takerPositionSize: takerPositionSize,
                        takerOpenNotional: takerOpenNotional,
                        base: params.base,
                        quote: params.quote
                    })
                )
                : 0;
    }

    /// @inheritdoc IVPool
    function getAllPendingFundingPayment(address trader) external view override returns (int256 pendingFundingPayment) {
        address[] memory baseTokens = IAccountBalance(_accountBalance).getBaseTokens(trader);
        uint256 baseTokenLength = baseTokens.length;

        for (uint256 i = 0; i < baseTokenLength; i++) {
            pendingFundingPayment = pendingFundingPayment.add(getPendingFundingPayment(trader, baseTokens[i]));
        }
        return pendingFundingPayment;
    }

    /// @inheritdoc IVPool
    function isOverPriceSpread(address baseToken) external view override returns (bool) {
        return _isOverPriceSpread(baseToken);
    }

    function _isOverPriceSpread(address baseToken) internal view returns (bool) {
        uint256 markPrice = getSqrtMarkTwapX96(baseToken, 0).formatSqrtPriceX96ToPriceX96().formatX96ToX10_18();
        uint256 indexTwap = IIndexPrice(baseToken).getIndexPrice(
            IClearingHouseConfig(_clearingHouseConfig).getTwapInterval()
        );
        uint256 spread = markPrice > indexTwap ? markPrice.sub(indexTwap) : indexTwap.sub(markPrice);
        // get market info
        IMarketRegistry.MarketInfo memory marketInfo = IMarketRegistry(_marketRegistry).getMarketInfo(baseToken);
        //
        return spread > PerpMath.mulRatio(indexTwap, marketInfo.unhealthyDeltaTwapRatio);
    }

    //
    // PUBLIC VIEW
    //

    /// @inheritdoc IVPool
    function getPendingFundingPayment(address trader, address baseToken) public view override returns (int256) {
        (DataTypes.Growth memory fundingGrowthGlobal, , ) = _getFundingGrowthGlobalAndTwaps(baseToken);
        return
            _calcPendingFundingPaymentWithLiquidityCoefficient(
                IAccountBalance(_accountBalance).getOriginBase(trader, baseToken),
                IAccountBalance(_accountBalance).getAccountInfo(trader, baseToken).lastLongTwPremiumGrowthGlobalX96,
                IAccountBalance(_accountBalance).getAccountInfo(trader, baseToken).lastShortTwPremiumGrowthGlobalX96,
                fundingGrowthGlobal
            );
    }

    /// @inheritdoc IVPool
    function getSqrtMarkTwapX96(address baseToken, uint32 twapInterval) public view override returns (uint160) {
        return UniswapV3Broker.getSqrtMarkTwapX96(IMarketRegistry(_marketRegistry).getPool(baseToken), twapInterval);
    }

    //
    // INTERNAL NON-VIEW
    //

    /// @dev this function is used only when closePosition()
    ///      inspect whether a tx will go over price limit by simulating closing position before swapping
    function _isOverPriceLimitBySimulatingClosingPosition(
        address baseToken,
        bool isOldPositionShort,
        uint256 positionSize
    ) internal view returns (bool) {
        // to simulate closing position, isOldPositionShort -> quote to exact base/long; else, exact base to quote/short
        return
            _isOverPriceLimitWithTick(
                baseToken,
                _replaySwap(
                    InternalReplaySwapParams({
                        baseToken: baseToken,
                        isBaseToQuote: !isOldPositionShort,
                        isExactInput: !isOldPositionShort,
                        amount: positionSize,
                        sqrtPriceLimitX96: _getSqrtPriceLimitForReplaySwap(baseToken, isOldPositionShort)
                    })
                )
            );
    }

    /// @return tick the resulting tick (derived from price) after replaying the swap
    function _replaySwap(InternalReplaySwapParams memory params) internal view returns (int24 tick) {
        IMarketRegistry.MarketInfo memory marketInfo = IMarketRegistry(_marketRegistry).getMarketInfo(params.baseToken);
        uint24 uniswapFeeRatio = marketInfo.uniswapFeeRatio;
        (, int256 signedScaledAmountForReplaySwap) = PerpMath.calcScaledAmountForSwaps(
            params.isBaseToQuote,
            params.isExactInput,
            params.amount,
            uniswapFeeRatio
        );

        // globalFundingGrowth can be empty if shouldUpdateState is false
        UniswapV3Broker.ReplaySwapResponse memory response = UniswapV3Broker.replaySwap(
            IMarketRegistry(_marketRegistry).getPool(params.baseToken),
            UniswapV3Broker.ReplaySwapParams({
                baseToken: params.baseToken,
                isBaseToQuote: params.isBaseToQuote,
                amount: signedScaledAmountForReplaySwap,
                sqrtPriceLimitX96: params.sqrtPriceLimitX96,
                uniswapFeeRatio: uniswapFeeRatio,
                shouldUpdateState: false
            })
        );
        return response.tick;
    }

    /// @dev customized fee: https://www.notion.so/perp/Customise-fee-tier-on-B2QFee-1b7244e1db63416c8651e8fa04128cdb
    function _swap(SwapParams memory params) internal returns (ClearingHouseLogic.InternalSwapResponse memory) {
        ClearingHouseLogic.InternalSwapResponse memory res = ClearingHouseLogic.swap(_clearingHouse, params);
        if (_firstTradedTimestampMap[params.baseToken] == 0) {
            _firstTradedTimestampMap[params.baseToken] = _blockTimestamp();
        }
        return res;
    }

    //
    // INTERNAL VIEW
    //

    function _isOverPriceLimit(address baseToken) internal view returns (bool) {
        int24 tick = _getTick(baseToken);
        return _isOverPriceLimitWithTick(baseToken, tick);
    }

    function _isOverPriceLimitWithTick(address baseToken, int24 tick) internal view returns (bool) {
        uint24 maxDeltaTick = _maxTickCrossedWithinBlockMap[baseToken];
        int24 lastUpdatedTick = _lastUpdatedTickMap[baseToken];
        // no overflow/underflow issue because there are range limits for tick and maxDeltaTick
        int24 upperTickBound = lastUpdatedTick.add(maxDeltaTick).toInt24();
        int24 lowerTickBound = lastUpdatedTick.sub(maxDeltaTick).toInt24();
        return (tick < lowerTickBound || tick > upperTickBound);
    }

    function _getTick(address baseToken) internal view returns (int24) {
        (, int24 tick, , , , , ) = UniswapV3Broker.getSlot0(IMarketRegistry(_marketRegistry).getPool(baseToken));
        return tick;
    }

    /// @dev this function calculates the up-to-date globalFundingGrowth and twaps and pass them out
    /// @return fundingGrowthGlobal the up-to-date globalFundingGrowth
    /// @return markTwap only for settleFunding()
    /// @return indexTwap only for settleFunding()

    function _getFundingGrowthGlobalAndTwaps(
        address baseToken
    ) internal view returns (DataTypes.Growth memory fundingGrowthGlobal, uint256 markTwap, uint256 indexTwap) {
        uint256 timestamp = IBaseToken(baseToken).isOpen()
            ? _blockTimestamp()
            : IBaseToken(baseToken).getPausedTimestamp();
        return
            _getFundingGrowthGlobalAndTwaps(
                baseToken,
                _firstTradedTimestampMap[baseToken],
                _lastSettledTimestampMap[baseToken],
                timestamp,
                _globalFundingGrowthX96Map[baseToken]
            );
    }

    function _getFundingGrowthGlobalAndTwaps(
        address baseToken,
        uint256 firstTrade,
        uint256 lastSettled,
        uint256 timestamp,
        DataTypes.Growth memory lastFundingGrowthGlobal
    ) internal view returns (DataTypes.Growth memory fundingGrowthGlobal, uint256 markTwap, uint256 indexTwap) {
        // shorten twapInterval if prior observations are not enough
        uint32 twapInterval;
        if (firstTrade != 0) {
            twapInterval = IClearingHouseConfig(_clearingHouseConfig).getTwapInterval();
            // overflow inspection:
            // 2 ^ 32 = 4,294,967,296 > 100 years = 60 * 60 * 24 * 365 * 100 = 3,153,600,000
            uint32 deltaTimestamp = timestamp.sub(firstTrade).toUint32();
            twapInterval = twapInterval > deltaTimestamp ? deltaTimestamp : twapInterval;
        }
        // uint256 markTwapX96;
        // if (marketOpen) {
        //     markTwapX96 = getSqrtMarkTwapX96(baseToken, twapInterval).formatSqrtPriceX96ToPriceX96();
        //     indexTwap = IIndexPrice(baseToken).getIndexPrice(twapInterval);
        // } else {
        //     // if a market is paused/closed, we use the last known index price which is getPausedIndexPrice
        //     //
        //     // -----+--- twap interval ---+--- secondsAgo ---+
        //     //                        pausedTime            now

        //     // timestamp is pausedTime when the market is not open
        //     uint32 secondsAgo = _blockTimestamp().sub(timestamp).toUint32();
        //     markTwapX96 = UniswapV3Broker
        //         .getSqrtMarkTwapX96From(IMarketRegistry(_marketRegistry).getPool(baseToken), secondsAgo, twapInterval)
        //         .formatSqrtPriceX96ToPriceX96();
        //     indexTwap = IBaseToken(baseToken).getPausedIndexPrice();
        // }

        uint256 markTwapX96 = getSqrtMarkTwapX96(baseToken, twapInterval).formatSqrtPriceX96ToPriceX96();

        markTwap = markTwapX96.formatX96ToX10_18();
        indexTwap = IIndexPrice(baseToken).getIndexPrice(twapInterval);

        if (timestamp == lastSettled || lastSettled == 0) {
            // if this is the latest updated timestamp, values in _globalFundingGrowthX96Map are up-to-date already
            fundingGrowthGlobal = lastFundingGrowthGlobal;
        } else {
            // deltaTwPremium = (markTwap - indexTwap) * (now - lastSettledTimestamp)
            // int256 deltaTwPremiumX96 = _getDeltaTwapX96(markTwapX96, indexTwap.formatX10_18ToX96()).mul(
            //     timestamp.sub(lastSettledTimestamp).toInt256()
            // );
            // fundingGrowthGlobal.twPremiumX96 = lastFundingGrowthGlobal.twPremiumX96.add(deltaTwPremiumX96);

            // // overflow inspection:
            // // assuming premium = 1 billion (1e9), time diff = 1 year (3600 * 24 * 365)
            // // log(1e9 * 2^96 * (3600 * 24 * 365) * 2^96) / log(2) = 246.8078491997 < 255
            // // twPremiumDivBySqrtPrice += deltaTwPremium / getSqrtMarkTwap(baseToken)
            // fundingGrowthGlobal.twPremiumDivBySqrtPriceX96 = lastFundingGrowthGlobal.twPremiumDivBySqrtPriceX96.add(
            //     PerpMath.mulDiv(deltaTwPremiumX96, PerpMath._IQ96, getSqrtMarkTwapX96(baseToken, 0))
            // );

            InternalFundingGrowthGlobalAndTwapsVars memory vars;

            (vars.longPositionSize, vars.shortPositionSize) = IAccountBalance(
                IClearingHouse(_clearingHouse).getAccountBalance()
            ).getMarketPositionSize(baseToken);
            if (vars.longPositionSize > 0 && vars.shortPositionSize > 0 && markTwap != indexTwap) {
                (vars.longMultiplier, vars.shortMultiplier) = IAccountBalance(
                    IClearingHouse(_clearingHouse).getAccountBalance()
                ).getMarketMultiplier(baseToken);
                vars.deltaTwapX96 = _getDeltaTwapX96(markTwapX96, indexTwap.formatX10_18ToX96());
                vars.deltaTwapX96 = _getDeltaTwapX96AfterOptimal(
                    baseToken,
                    vars.deltaTwapX96,
                    indexTwap.formatX10_18ToX96()
                );
                vars.deltaTwPremiumX96 = vars.deltaTwapX96.mul(timestamp.sub(lastSettled).toInt256());
                if (vars.deltaTwapX96 > 0) {
                    // LONG pay
                    fundingGrowthGlobal.twLongPremiumX96 = lastFundingGrowthGlobal.twLongPremiumX96.add(
                        vars.deltaTwPremiumX96.mulMultiplier(vars.longMultiplier)
                    );
                    // SHORT receive
                    vars.deltaShortTwPremiumX96 = vars.deltaTwPremiumX96.mul(vars.longPositionSize.toInt256()).div(
                        vars.shortPositionSize.toInt256()
                    );
                    fundingGrowthGlobal.twShortPremiumX96 = lastFundingGrowthGlobal.twShortPremiumX96.add(
                        vars.deltaShortTwPremiumX96.mulMultiplier(vars.shortMultiplier)
                    );
                } else if (vars.deltaTwapX96 < 0) {
                    // LONG receive
                    vars.deltaLongTwPremiumX96 = vars.deltaTwPremiumX96.mul(vars.shortPositionSize.toInt256()).div(
                        vars.longPositionSize.toInt256()
                    );
                    fundingGrowthGlobal.twLongPremiumX96 = lastFundingGrowthGlobal.twLongPremiumX96.add(
                        vars.deltaLongTwPremiumX96.mulMultiplier(vars.longMultiplier)
                    );
                    // SHORT pay
                    fundingGrowthGlobal.twShortPremiumX96 = lastFundingGrowthGlobal.twShortPremiumX96.add(
                        vars.deltaTwPremiumX96.mulMultiplier(vars.shortMultiplier)
                    );
                } else {
                    fundingGrowthGlobal = lastFundingGrowthGlobal;
                }
            } else {
                fundingGrowthGlobal = lastFundingGrowthGlobal;
            }
        }
        return (fundingGrowthGlobal, markTwap, indexTwap);
    }

    function _getDeltaTwapX96AfterOptimal(
        address baseToken,
        int256 deltaTwapX96,
        uint256 indexTwapX96
    ) public view returns (int256) {
        IMarketRegistry.MarketInfo memory marketInfo = IMarketRegistry(
            IClearingHouse(_clearingHouse).getMarketRegistry()
        ).getMarketInfo(baseToken);

        // optimalDeltaTwapRatio
        if ((deltaTwapX96.abs().mul(1e6)) <= (indexTwapX96.mul(marketInfo.optimalDeltaTwapRatio))) {
            return
                PerpMath.mulDiv(
                    deltaTwapX96,
                    PerpMath.mulDiv(marketInfo.optimalFundingRatio, marketInfo.optimalFundingRatio, 1e6),
                    1e6
                ); // 25% * 25%;
        }

        // unhealthyDeltaTwapRatio
        if ((deltaTwapX96.abs().mul(1e6)) <= (indexTwapX96.mul(marketInfo.unhealthyDeltaTwapRatio))) {
            return PerpMath.mulDiv(deltaTwapX96, marketInfo.optimalFundingRatio, 1e6); // 25%;
        }

        return deltaTwapX96;
    }

    function _getDeltaTwapX96(uint256 markTwapX96, uint256 indexTwapX96) public view returns (int256 deltaTwapX96) {
        uint24 maxFundingRate = IClearingHouseConfig(IClearingHouse(_clearingHouse).getClearingHouseConfig())
            .getMaxFundingRate();
        uint256 maxDeltaTwapX96 = indexTwapX96.mulRatio(maxFundingRate);
        uint256 absDeltaTwapX96;
        if (markTwapX96 > indexTwapX96) {
            absDeltaTwapX96 = markTwapX96.sub(indexTwapX96);
            deltaTwapX96 = absDeltaTwapX96 > maxDeltaTwapX96 ? maxDeltaTwapX96.toInt256() : absDeltaTwapX96.toInt256();
        } else {
            absDeltaTwapX96 = indexTwapX96.sub(markTwapX96);
            deltaTwapX96 = absDeltaTwapX96 > maxDeltaTwapX96 ? maxDeltaTwapX96.neg256() : absDeltaTwapX96.neg256();
        }
    }

    function _getPnlToBeRealized(InternalRealizePnlParams memory params) internal pure returns (int256) {
        // closedRatio is based on the position size
        uint256 closedRatio = FullMath.mulDiv(params.base.abs(), _FULLY_CLOSED_RATIO, params.takerPositionSize.abs());

        int256 pnlToBeRealized;
        // if closedRatio <= 1, it's reducing or closing a position; else, it's opening a larger reverse position
        if (closedRatio <= _FULLY_CLOSED_RATIO) {
            // https://docs.google.com/spreadsheets/d/1QwN_UZOiASv3dPBP7bNVdLR_GTaZGUrHW3-29ttMbLs/edit#gid=148137350
            // taker:
            // step 1: long 20 base
            // openNotionalFraction = 252.53
            // openNotional = -252.53
            // step 2: short 10 base (reduce half of the position)
            // quote = 137.5
            // closeRatio = 10/20 = 0.5
            // reducedOpenNotional = openNotional * closedRatio = -252.53 * 0.5 = -126.265
            // realizedPnl = quote + reducedOpenNotional = 137.5 + -126.265 = 11.235
            // openNotionalFraction = openNotionalFraction - quote + realizedPnl
            //                      = 252.53 - 137.5 + 11.235 = 126.265
            // openNotional = -openNotionalFraction = 126.265

            // overflow inspection:
            // max closedRatio = 1e18; range of oldOpenNotional = (-2 ^ 255, 2 ^ 255)
            // only overflow when oldOpenNotional < -2 ^ 255 / 1e18 or oldOpenNotional > 2 ^ 255 / 1e18
            int256 reducedOpenNotional = params.takerOpenNotional.mulDiv(closedRatio.toInt256(), _FULLY_CLOSED_RATIO);
            pnlToBeRealized = params.quote.add(reducedOpenNotional);
        } else {
            // https://docs.google.com/spreadsheets/d/1QwN_UZOiASv3dPBP7bNVdLR_GTaZGUrHW3-29ttMbLs/edit#gid=668982944
            // taker:
            // step 1: long 20 base
            // openNotionalFraction = 252.53
            // openNotional = -252.53
            // step 2: short 30 base (open a larger reverse position)
            // quote = 337.5
            // closeRatio = 30/20 = 1.5
            // closedPositionNotional = quote / closeRatio = 337.5 / 1.5 = 225
            // remainsPositionNotional = quote - closedPositionNotional = 337.5 - 225 = 112.5
            // realizedPnl = closedPositionNotional + openNotional = -252.53 + 225 = -27.53
            // openNotionalFraction = openNotionalFraction - quote + realizedPnl
            //                      = 252.53 - 337.5 + -27.53 = -112.5
            // openNotional = -openNotionalFraction = remainsPositionNotional = 112.5

            // overflow inspection:
            // max & min tick = 887272, -887272; max liquidity = 2 ^ 128
            // max quote = 2^128 * (sqrt(1.0001^887272) - sqrt(1.0001^-887272)) = 6.276865796e57 < 2^255 / 1e18
            int256 closedPositionNotional = params.quote.mulDiv(int256(_FULLY_CLOSED_RATIO), closedRatio);
            pnlToBeRealized = params.takerOpenNotional.add(closedPositionNotional);
        }

        return pnlToBeRealized;
    }

    /// @dev get a price limit for replaySwap s.t. it can stop when reaching the limit to save gas
    function _getSqrtPriceLimitForReplaySwap(address baseToken, bool isLong) internal view returns (uint160) {
        // price limit = max tick + 1 or min tick - 1, depending on which direction
        int24 tickBoundary = isLong
            ? _lastUpdatedTickMap[baseToken] + int24(_maxTickCrossedWithinBlockMap[baseToken]) + 1
            : _lastUpdatedTickMap[baseToken] - int24(_maxTickCrossedWithinBlockMap[baseToken]) - 1;

        // tickBoundary should be in [MIN_TICK, MAX_TICK]
        tickBoundary = tickBoundary > TickMath.MAX_TICK ? TickMath.MAX_TICK : tickBoundary;
        tickBoundary = tickBoundary < TickMath.MIN_TICK ? TickMath.MIN_TICK : tickBoundary;

        return TickMath.getSqrtRatioAtTick(tickBoundary);
    }

    // @dev use virtual for testing
    function _getMaxTickCrossedWithinBlockCap() internal pure virtual returns (uint24) {
        return _MAX_TICK_CROSSED_WITHIN_BLOCK_CAP;
    }

    function getInsuranceFundFeeRatio(address baseToken, bool isBaseToQuote) public view returns (uint256) {
        return GenericLogic.getInsuranceFundFeeRatio(address(this), _marketRegistry, baseToken, isBaseToQuote);
    }

    function getGlobalFundingGrowthInfo(
        address baseToken
    ) public view returns (uint256 lastSettledTimestamp, DataTypes.Growth memory fundingGrowthGlobal) {
        lastSettledTimestamp = _lastSettledTimestampMap[baseToken];
        fundingGrowthGlobal = _globalFundingGrowthX96Map[baseToken];
    }

    function getFundingGrowthGlobalAndTwaps(
        address baseToken
    )
        external
        view
        override
        returns (DataTypes.Growth memory fundingGrowthGlobal, uint256 markTwap, uint256 indexTwap)
    {
        (fundingGrowthGlobal, markTwap, indexTwap) = _getFundingGrowthGlobalAndTwaps(baseToken);
    }

    // OverPriceSpreadTimestamp
    function updateOverPriceSpreadTimestamp(address baseToken) external override {
        _updateOverPriceSpreadTimestamp(baseToken);
    }

    function _updateOverPriceSpreadTimestamp(address baseToken) internal {
        if (_isOverPriceSpread(baseToken)) {
            if (_lastOverPriceSpreadTimestampMap[baseToken] == 0) {
                _lastOverPriceSpreadTimestampMap[baseToken] = _blockTimestamp();
            }
        } else {
            _lastOverPriceSpreadTimestampMap[baseToken] = 0;
        }
    }

    function isOverPriceSpreadTimestamp(address baseToken) external view override returns (bool) {
        return
            _lastOverPriceSpreadTimestampMap[baseToken] > 0 &&
            _lastOverPriceSpreadTimestampMap[baseToken] <=
            (_blockTimestamp() - IClearingHouseConfig(_clearingHouseConfig).getDurationRepegOverPriceSpread());
    }

    function getOverPriceSpreadTimestamp(address baseToken) external view returns (uint256) {
        return _lastOverPriceSpreadTimestampMap[baseToken];
    }

    function getOverPriceSpreadInfo(
        address baseToken
    ) external view returns (uint256 spreadRatio, uint256 lastOverPriceSpreadTimestamp, uint256 repegTimestamp) {
        uint256 markPrice = getSqrtMarkTwapX96(baseToken, 0).formatSqrtPriceX96ToPriceX96().formatX96ToX10_18();
        uint256 indexTwap = IIndexPrice(baseToken).getIndexPrice(
            IClearingHouseConfig(_clearingHouseConfig).getTwapInterval()
        );
        spreadRatio = (markPrice > indexTwap ? markPrice.sub(indexTwap) : indexTwap.sub(markPrice)).mul(1e6).div(
            indexTwap
        );
        lastOverPriceSpreadTimestamp = _lastOverPriceSpreadTimestampMap[baseToken];
        repegTimestamp =
            lastOverPriceSpreadTimestamp +
            IClearingHouseConfig(_clearingHouseConfig).getDurationRepegOverPriceSpread();
    }

    function estimateSwap(
        DataTypes.OpenPositionParams memory params
    ) external view override returns (UniswapV3Broker.ReplaySwapResponse memory) {
        return ClearingHouseLogic.estimateSwap(_clearingHouse, params);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import { IMarketRegistry } from "../interface/IMarketRegistry.sol";

abstract contract UniswapV3CallbackBridge is ContextUpgradeable {
    //
    // STATE
    //
    address internal _marketRegistry;

    // __gap is reserved storage
    uint256[50] private __gap;

    //
    // MODIFIER
    //

    modifier checkCallback() {
        address pool = _msgSender();
        address baseToken = IUniswapV3Pool(pool).token0();
        // UCB_FCV: failed callback validation
        require(pool == IMarketRegistry(_marketRegistry).getPool(baseToken), "UCB_FCV");
        _;
    }

    //
    // CONSTRUCTOR
    //
    // solhint-disable-next-line func-order
    function __UniswapV3CallbackBridge_init(address marketRegistryArg) internal initializer {
        __Context_init();

        _marketRegistry = marketRegistryArg;
    }

    function getMarketRegistry() external view returns (address) {
        return _marketRegistry;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import { DataTypes } from "../types/DataTypes.sol";

/// @notice For future upgrades, do not change VPoolStorageV1. Create a new
/// contract which implements VPoolStorageV1 and following the naming convention
/// VPoolStorageVX.
abstract contract VPoolStorageV1 {
    address internal __orderBook;
    address internal _accountBalance;
    address internal _clearingHouseConfig;

    address[10] private __gap1;
    uint256[10] private __gap2;

    mapping(address => int24) internal _lastUpdatedTickMap;
    mapping(address => uint256) internal _firstTradedTimestampMap;
    mapping(address => uint256) internal _lastSettledTimestampMap;
    mapping(address => uint256) internal _lastOverPriceSpreadTimestampMap;
    mapping(address => DataTypes.Growth) internal _globalFundingGrowthX96Map;

    // key: base token
    // value: a threshold to limit the price impact per block when reducing or closing the position
    mapping(address => uint24) internal _maxTickCrossedWithinBlockMap;

    // first key: trader, second key: baseToken
    // value: the last timestamp when a trader exceeds price limit when closing a position/being liquidated
    mapping(address => mapping(address => uint256)) internal _lastOverPriceLimitTimestampMap;
}

abstract contract VPoolStorageV2 is VPoolStorageV1 {
    // the last timestamp when tick is updated; for price limit check
    // key: base token
    // value: the last timestamp to update the tick
    mapping(address => uint256) internal _lastTickUpdatedTimestampMap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";
import "@uniswap/v3-periphery/contracts/libraries/CallbackValidation.sol";
import "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/libraries/Path.sol";
import "../lib/UniswapV3Broker.sol";
import "../interface/IERC20Metadata.sol";
import "@uniswap/v3-periphery/contracts/libraries/PositionKey.sol";

contract TestUniswapV3Broker is IUniswapV3MintCallback, IUniswapV3SwapCallback, Initializable {
    using Path for bytes;

    address private _factory;

    function initialize(address factory) external initializer {
        _factory = factory;
    }

    /// @inheritdoc IUniswapV3MintCallback
    function uniswapV3MintCallback(
        uint256 amount0Owed,
        uint256 amount1Owed,
        bytes calldata
    ) external override {
        // address baseToken = abi.decode(data, (address));
        // address pool = _poolMap[baseToken];
        // no data structure here; thus comment out
        address pool = msg.sender;
        // CH_FMV: failed mintCallback verification
        require(msg.sender == pool, "CH_FMV");

        if (amount0Owed > 0) {
            IERC20Metadata(IUniswapV3Pool(pool).token0()).transfer(msg.sender, amount0Owed);
        }
        if (amount1Owed > 0) {
            IERC20Metadata(IUniswapV3Pool(pool).token1()).transfer(msg.sender, amount1Owed);
        }
    }

    struct SwapCallbackData {
        bytes path;
        address payer;
    }

    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata
    ) external override {
        // swaps entirely within 0-liquidity regions are not supported -> 0 swap is forbidden
        // CH_ZIs: forbidden 0 swap
        require(amount0Delta > 0 || amount1Delta > 0, "CH_F0S");

        // address baseToken = abi.decode(data, (address));
        // address pool = _poolMap[baseToken];
        // no data structure here; thus comment out
        IUniswapV3Pool pool = IUniswapV3Pool(msg.sender);
        // CH_FSV: failed swapCallback verification
        require(msg.sender == address(pool), "CH_FSV");

        // amount0Delta & amount1Delta are guaranteed to be positive when being the amount to be paid
        (address token, uint256 amountToPay) =
            amount0Delta > 0 ? (pool.token0(), uint256(amount0Delta)) : (pool.token1(), uint256(amount1Delta));
        IERC20Metadata(token).transfer(msg.sender, amountToPay);
    }

    function addLiquidity(UniswapV3Broker.InternalAddLiquidityParams calldata params)
        external
        returns (UniswapV3Broker.AddLiquidityResponse memory response)
    {
        return UniswapV3Broker._addLiquidity(params);
    }

    function removeLiquidity(UniswapV3Broker.InternalRemoveLiquidityParams calldata params)
        external
        returns (UniswapV3Broker.RemoveLiquidityResponse memory response)
    {
        return UniswapV3Broker._removeLiquidity(params);
    }

    function swap(UniswapV3Broker.SwapParams calldata params)
        public
        returns (UniswapV3Broker.SwapResponse memory response)
    {
        return UniswapV3Broker.swap(params);
    }

    function getPositionKey(int24 lowerTick, int24 upperTick) external view returns (bytes32) {
        return PositionKey.compute(address(this), lowerTick, upperTick);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import './PoolAddress.sol';

/// @notice Provides validation for callbacks from Uniswap V3 Pools
library CallbackValidation {
    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The V3 pool contract address
    function verifyCallback(
        address factory,
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal view returns (IUniswapV3Pool pool) {
        return verifyCallback(factory, PoolAddress.getPoolKey(tokenA, tokenB, fee));
    }

    /// @notice Returns the address of a valid Uniswap V3 Pool
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param poolKey The identifying key of the V3 pool
    /// @return pool The V3 pool contract address
    function verifyCallback(address factory, PoolAddress.PoolKey memory poolKey)
        internal
        view
        returns (IUniswapV3Pool pool)
    {
        pool = IUniswapV3Pool(PoolAddress.computeAddress(factory, poolKey));
        require(msg.sender == address(pool));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import './BytesLib.sol';

/// @title Functions for manipulating path data for multihop swaps
library Path {
    using BytesLib for bytes;

    /// @dev The length of the bytes encoded address
    uint256 private constant ADDR_SIZE = 20;
    /// @dev The length of the bytes encoded fee
    uint256 private constant FEE_SIZE = 3;

    /// @dev The offset of a single token address and pool fee
    uint256 private constant NEXT_OFFSET = ADDR_SIZE + FEE_SIZE;
    /// @dev The offset of an encoded pool key
    uint256 private constant POP_OFFSET = NEXT_OFFSET + ADDR_SIZE;
    /// @dev The minimum length of an encoding that contains 2 or more pools
    uint256 private constant MULTIPLE_POOLS_MIN_LENGTH = POP_OFFSET + NEXT_OFFSET;

    /// @notice Returns true iff the path contains two or more pools
    /// @param path The encoded swap path
    /// @return True if path contains two or more pools, otherwise false
    function hasMultiplePools(bytes memory path) internal pure returns (bool) {
        return path.length >= MULTIPLE_POOLS_MIN_LENGTH;
    }

    /// @notice Decodes the first pool in path
    /// @param path The bytes encoded swap path
    /// @return tokenA The first token of the given pool
    /// @return tokenB The second token of the given pool
    /// @return fee The fee level of the pool
    function decodeFirstPool(bytes memory path)
        internal
        pure
        returns (
            address tokenA,
            address tokenB,
            uint24 fee
        )
    {
        tokenA = path.toAddress(0);
        fee = path.toUint24(ADDR_SIZE);
        tokenB = path.toAddress(NEXT_OFFSET);
    }

    /// @notice Gets the segment corresponding to the first pool in the path
    /// @param path The bytes encoded swap path
    /// @return The segment containing all data necessary to target the first pool in the path
    function getFirstPool(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(0, POP_OFFSET);
    }

    /// @notice Skips a token + fee element from the buffer and returns the remainder
    /// @param path The swap path
    /// @return The remaining token + fee elements in the path
    function skipToken(bytes memory path) internal pure returns (bytes memory) {
        return path.slice(NEXT_OFFSET, path.length - NEXT_OFFSET);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

library PositionKey {
    /// @dev Returns the key of the position in the core library
    function compute(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.5.0 <0.8.0;

library BytesLib {
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, 'slice_overflow');
        require(_start + _length >= _start, 'slice_overflow');
        require(_bytes.length >= _start + _length, 'slice_outOfBounds');

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
                case 0 {
                    // Get a location of some free memory and store it in tempBytes as
                    // Solidity does for memory variables.
                    tempBytes := mload(0x40)

                    // The first word of the slice result is potentially a partial
                    // word read from the original array. To read it, we calculate
                    // the length of that partial word and start copying that many
                    // bytes into the array. The first word we copy will start with
                    // data we don't care about, but the last `lengthmod` bytes will
                    // land at the beginning of the contents of the new array. When
                    // we're done copying, we overwrite the full first word with
                    // the actual length of the slice.
                    let lengthmod := and(_length, 31)

                    // The multiplication in the next line is necessary
                    // because when slicing multiples of 32 bytes (lengthmod == 0)
                    // the following copy loop was copying the origin's length
                    // and then ending prematurely not copying everything it should.
                    let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                    let end := add(mc, _length)

                    for {
                        // The multiplication in the next line has the same exact purpose
                        // as the one above.
                        let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                    } lt(mc, end) {
                        mc := add(mc, 0x20)
                        cc := add(cc, 0x20)
                    } {
                        mstore(mc, mload(cc))
                    }

                    mstore(tempBytes, _length)

                    //update free-memory pointer
                    //allocating the array padded to 32 bytes like the compiler does now
                    mstore(0x40, and(add(mc, 31), not(31)))
                }
                //if we want a zero-length slice let's just return a zero-length array
                default {
                    tempBytes := mload(0x40)
                    //zero out the 32 bytes slice we are about to return
                    //we need to do it because Solidity does not garbage collect
                    mstore(tempBytes, 0)

                    mstore(0x40, add(tempBytes, 0x20))
                }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, 'toAddress_overflow');
        require(_bytes.length >= _start + 20, 'toAddress_outOfBounds');
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint24(bytes memory _bytes, uint256 _start) internal pure returns (uint24) {
        require(_start + 3 >= _start, 'toUint24_overflow');
        require(_bytes.length >= _start + 3, 'toUint24_outOfBounds');
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x3), _start))
        }

        return tempUint;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { SignedSafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";
import { SafeERC20Upgradeable, IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import { FullMath } from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import { TransferHelper } from "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import { PerpSafeCast } from "./lib/PerpSafeCast.sol";
import { PerpMath } from "./lib/PerpMath.sol";
import { IERC20Metadata } from "./interface/IERC20Metadata.sol";
import { IInsuranceFund } from "./interface/IInsuranceFund.sol";
import { IVPool } from "./interface/IVPool.sol";
import { IAccountBalance } from "./interface/IAccountBalance.sol";
import { IClearingHouseConfig } from "./interface/IClearingHouseConfig.sol";
import { IClearingHouse } from "./interface/IClearingHouse.sol";
import { BaseRelayRecipient } from "./gsn/BaseRelayRecipient.sol";
import { OwnerPausable } from "./base/OwnerPausable.sol";
import { VaultStorageV2 } from "./storage/VaultStorage.sol";
import { IVault } from "./interface/IVault.sol";
import { IWETH9 } from "./interface/external/IWETH9.sol";

// never inherit any new stateful contract. never change the orders of parent stateful contracts
contract Vault is IVault, ReentrancyGuardUpgradeable, OwnerPausable, BaseRelayRecipient, VaultStorageV2 {
    using SafeMathUpgradeable for uint256;
    using PerpSafeCast for uint256;
    using PerpSafeCast for int256;
    using SignedSafeMathUpgradeable for int256;
    using PerpMath for int256;
    using PerpMath for uint256;
    using PerpMath for uint24;
    using FullMath for uint256;
    using AddressUpgradeable for address;

    uint24 private constant _ONE_HUNDRED_PERCENT_RATIO = 1e6;

    //
    // MODIFIER
    //

    modifier onlySettlementOrCollateralToken(address token) {
        // V_OSCT: only settlement or collateral token
        require(token == _settlementToken || _isCollateral(token), "V_OSCT");
        _;
    }

    function _requireNotMaker(address maker) internal view {
        // only Maker
        require(maker != _maker, "V_NM");
    }

    function _requireOnlyMaker(address maker) internal view {
        // only Maker
        require(maker == _maker, "V_OM");
    }

    //
    // EXTERNAL NON-VIEW
    //

    /// @dev only used for unwrapping weth in withdrawETH
    receive() external payable {
        // V_SNW: sender is not WETH9
        require(_msgSender() == _WETH9, "V_SNW");
    }

    function initialize(
        address insuranceFundArg,
        address clearingHouseConfigArg,
        address accountBalanceArg,
        address exchangeArg,
        address makerArg
    ) external initializer {
        address settlementTokenArg = IInsuranceFund(insuranceFundArg).getToken();
        uint8 decimalsArg = IERC20Metadata(settlementTokenArg).decimals();

        // invalid settlementToken decimals
        require(decimalsArg <= 18, "V_ISTD");
        // ClearingHouseConfig address is not contract
        require(clearingHouseConfigArg.isContract(), "V_CHCNC");
        // accountBalance address is not contract
        require(accountBalanceArg.isContract(), "V_ABNC");
        // exchange address is not contract
        require(exchangeArg.isContract(), "V_ENC");

        __ReentrancyGuard_init();
        __OwnerPausable_init();

        // update states
        _decimals = decimalsArg;
        _settlementToken = settlementTokenArg;
        _insuranceFund = insuranceFundArg;
        _clearingHouseConfig = clearingHouseConfigArg;
        _accountBalance = accountBalanceArg;
        _vPool = exchangeArg;
        _maker = makerArg;
    }

    function setTrustedForwarder(address trustedForwarderArg) external onlyOwner {
        // V_TFNC: TrustedForwarder address is not contract
        require(trustedForwarderArg.isContract(), "V_TFNC");

        _setTrustedForwarder(trustedForwarderArg);
        emit TrustedForwarderChanged(trustedForwarderArg);
    }

    function setClearingHouse(address clearingHouseArg) external onlyOwner {
        // V_CHNC: ClearingHouse is not contract
        require(clearingHouseArg.isContract(), "V_CHNC");

        _clearingHouse = clearingHouseArg;
        emit ClearingHouseChanged(clearingHouseArg);
    }

    function setMaker(address makerArg) external onlyOwner {
        // V_CHNC: Maker is not contract
        // require(makerArg.isContract(), "V_CHNC");

        _maker = makerArg;
        emit MakerChanged(makerArg);
    }

    function setWETH9(address WETH9Arg) external onlyOwner {
        // V_WNC: WETH9 is not contract
        require(WETH9Arg.isContract(), "V_WNC");

        _WETH9 = WETH9Arg;
        emit WETH9Changed(WETH9Arg);
    }

    /// @inheritdoc IVault
    function deposit(
        address token,
        uint256 amount
    ) external override whenNotPaused nonReentrant onlySettlementOrCollateralToken(token) {
        // input requirement checks:
        //   token: here
        //   amount: _deposit

        address from = _msgSender();
        _deposit(from, from, token, amount);
    }

    /// @inheritdoc IVault
    function depositFor(
        address to,
        address token,
        uint256 amount
    ) external override whenNotPaused nonReentrant onlySettlementOrCollateralToken(token) {
        // input requirement checks:
        //   token: here
        //   amount: _deposit

        // V_DFZA: Deposit for zero address
        require(to != address(0), "V_DFZA");

        address from = _msgSender();
        _deposit(from, to, token, amount);
    }

    /// @inheritdoc IVault
    function depositEther() external payable override whenNotPaused nonReentrant {
        address to = _msgSender();
        _depositEther(to);
    }

    /// @inheritdoc IVault
    function depositEtherFor(address to) external payable override whenNotPaused nonReentrant {
        // input requirement checks:
        //   to: here

        // V_DFZA: Deposit for zero address
        require(to != address(0), "V_DFZA");
        _depositEther(to);
    }

    /// @inheritdoc IVault
    // the full process of withdrawal:
    // 1. settle funding payment to owedRealizedPnl
    // 2. collect fee to owedRealizedPnl
    // 3. call Vault.withdraw(token, amount)
    // 4. settle pnl to trader balance in Vault
    // 5. transfer the amount to trader
    function withdraw(
        address token,
        uint256 amount
    ) external override whenNotPaused nonReentrant onlySettlementOrCollateralToken(token) {
        // input requirement checks:
        //   token: here
        //   amount: in _settleAndDecreaseBalance()

        address to = _msgSender();
        _withdraw(to, token, amount);
    }

    /// @inheritdoc IVault
    function withdrawEther(uint256 amount) external override whenNotPaused nonReentrant {
        // input requirement checks:
        //   amount: in _settleAndDecreaseBalance()

        _requireWETH9IsCollateral();

        address to = _msgSender();

        _withdrawEther(to, amount);
    }

    /// @inheritdoc IVault
    function withdrawAll(
        address token
    ) external override whenNotPaused nonReentrant onlySettlementOrCollateralToken(token) returns (uint256 amount) {
        // input requirement checks:
        //   token: here

        address to = _msgSender();
        amount = getFreeCollateralByToken(to, token);

        _withdraw(to, token, amount);
        return amount;
    }

    /// @inheritdoc IVault
    function withdrawAllEther() external override whenNotPaused nonReentrant returns (uint256 amount) {
        _requireWETH9IsCollateral();

        address to = _msgSender();
        amount = getFreeCollateralByToken(to, _WETH9);

        _withdrawEther(to, amount);
        return amount;
    }

    //
    // EXTERNAL VIEW
    //

    /// @inheritdoc IVault
    function getSettlementToken() external view override returns (address) {
        return _settlementToken;
    }

    /// @inheritdoc IVault
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /// @inheritdoc IVault
    function getTotalDebt() external view override returns (uint256) {
        return _totalDebt;
    }

    /// @inheritdoc IVault
    function getClearingHouseConfig() external view override returns (address) {
        return _clearingHouseConfig;
    }

    /// @inheritdoc IVault
    function getAccountBalance() external view override returns (address) {
        return _accountBalance;
    }

    /// @inheritdoc IVault
    function getInsuranceFund() external view override returns (address) {
        return _insuranceFund;
    }

    /// @inheritdoc IVault
    function getVPool() external view override returns (address) {
        return _vPool;
    }

    /// @inheritdoc IVault
    function getClearingHouse() external view override returns (address) {
        return _clearingHouse;
    }

    /// @inheritdoc IVault
    function getWETH9() external view override returns (address) {
        return _WETH9;
    }

    /// @inheritdoc IVault
    function getFreeCollateral(address trader) external view override returns (uint256) {
        return _getFreeCollateral(trader).formatSettlementToken(_decimals);
    }

    /// @inheritdoc IVault
    function getFreeCollateralByRatio(address trader, uint24 ratio) external view override returns (int256) {
        return _getFreeCollateralByRatio(trader, ratio).formatSettlementToken(_decimals);
    }

    /// @inheritdoc IVault
    function getSettlementTokenValue(address trader) external view override returns (int256) {
        return _getSettlementTokenValue(trader).formatSettlementToken(_decimals);
    }

    /// @inheritdoc IVault
    function getAccountValue(address trader) external view override returns (int256) {
        (int256 accountValueX10_18, ) = _getAccountValueAndTotalCollateralValue(trader);
        return accountValueX10_18.formatSettlementToken(_decimals);
    }

    /// @inheritdoc IVault
    function getCollateralTokens(address trader) external view override returns (address[] memory) {
        return _collateralTokensMap[trader];
    }

    //
    // PUBLIC VIEW
    //

    /// @inheritdoc IVault
    function getBalance(address trader) public view override returns (int256) {
        return _balance[trader][_settlementToken];
    }

    /// @inheritdoc IVault
    function getBalanceByToken(address trader, address token) public view override returns (int256) {
        return _balance[trader][token];
    }

    /// @inheritdoc IVault
    /// @dev getFreeCollateralByToken(token) = (getSettlementTokenValue() >= 0)
    ///   ? min(getFreeCollateral() / indexPrice[token], getBalanceByToken(token))
    ///   : 0
    /// @dev if token is settlementToken, then indexPrice[token] = 1
    function getFreeCollateralByToken(address trader, address token) public view override returns (uint256) {
        // do not check settlementTokenValue == 0 because user's settlement token balance may be zero
        if (_getSettlementTokenValue(trader) < 0) {
            return 0;
        }

        uint256 freeCollateralX10_18 = _getFreeCollateral(trader);
        if (freeCollateralX10_18 == 0) {
            return 0;
        }

        if (token == _settlementToken) {
            (int256 settlementTokenBalanceX10_18, ) = _getSettlementTokenBalanceAndUnrealizedPnl(trader);
            return
                settlementTokenBalanceX10_18 <= 0
                    ? 0
                    : MathUpgradeable
                        .min(freeCollateralX10_18, settlementTokenBalanceX10_18.toUint256())
                        .formatSettlementToken(_decimals);
        }

        revert("V_NS");
    }

    /// @inheritdoc IVault
    /// @dev will only settle the bad debt when trader didn't have position and non-settlement collateral
    function settleBadDebt(address trader) public override {
        // V_CSI: can't settle insuranceFund
        require(trader != _insuranceFund, "V_CSI");

        // trader has position or trader has non-settlement collateral
        if (
            IAccountBalance(_accountBalance).getBaseTokens(trader).length != 0 ||
            _collateralTokensMap[trader].length != 0
        ) {
            return;
        }

        // assume trader has no position and no non-settlement collateral
        // so accountValue = settlement token balance
        (int256 accountValueX10_18, ) = _getSettlementTokenBalanceAndUnrealizedPnl(trader);
        int256 accountValueX10_S = accountValueX10_18.formatSettlementToken(_decimals);

        if (accountValueX10_S >= 0) {
            return;
        }

        // settle bad debt for trader
        int256 badDebt = accountValueX10_S.neg256();
        address settlementToken = _settlementToken; // SLOAD gas saving
        _modifyBalance(_insuranceFund, settlementToken, accountValueX10_S);
        _modifyBalance(trader, settlementToken, badDebt);

        uint256 absBadDebt = badDebt.toUint256();
        emit BadDebtSettled(trader, absBadDebt);
    }

    //
    // INTERNAL NON-VIEW
    //

    /// @param token the collateral token needs to be transferred into vault
    /// @param from the address of account who owns the collateral token
    /// @param amount the amount of collateral token needs to be transferred
    function _transferTokenIn(address token, address from, uint256 amount) internal {
        // check for deflationary tokens by assuring balances before and after transferring to be the same
        uint256 balanceBefore = IERC20Metadata(token).balanceOf(address(this));
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(token), from, address(this), amount);
        // V_IBA: inconsistent balance amount, to prevent from deflationary tokens
        require((IERC20Metadata(token).balanceOf(address(this)).sub(balanceBefore)) == amount, "V_IBA");
    }

    /// @param from deposit token from this address
    /// @param to deposit token to this address
    /// @param token the collateral token wish to deposit
    /// @param amount the amount of token to deposit
    function _deposit(address from, address to, address token, uint256 amount) internal {
        _requireNotMaker(from);
        _requireNotMaker(to);
        // V_ZA: Zero amount
        require(amount > 0, "V_ZA");
        _transferTokenIn(token, from, amount);
        _checkDepositCapAndRegister(token, to, amount);
    }

    /// @param to deposit ETH to this address
    function _depositEther(address to) internal {
        _requireNotMaker(to);
        uint256 amount = msg.value;
        // V_ZA: Zero amount
        require(amount > 0, "V_ZA");
        _requireWETH9IsCollateral();

        // SLOAD for gas saving
        address WETH9 = _WETH9;
        // wrap ETH into WETH
        IWETH9(WETH9).deposit{ value: amount }();
        _checkDepositCapAndRegister(WETH9, to, amount);
    }

    /// @param token the collateral token needs to be transferred out of vault
    /// @param to the address of account that the collateral token deposit to
    /// @param amount the amount of collateral token to be deposited
    function _checkDepositCapAndRegister(address token, address to, uint256 amount) internal {
        if (token == _settlementToken) {
            uint256 settlementTokenBalanceCap = IClearingHouseConfig(_clearingHouseConfig)
                .getSettlementTokenBalanceCap();
            // V_GTSTBC: greater than settlement token balance cap
            require(IERC20Metadata(token).balanceOf(address(this)) <= settlementTokenBalanceCap, "V_GTSTBC");
        } else {
            // V_NS: sot support
            revert("V_NS");
        }
        _modifyBalance(to, token, amount.toInt256());
        emit Deposited(token, to, amount);
    }

    function _settleAndDecreaseBalance(address to, address token, uint256 amount) internal {
        // settle all funding payments owedRealizedPnl
        // pending fee can be withdraw but won't be settled
        IClearingHouse(_clearingHouse).settleAllFunding(to);

        // incl. owedRealizedPnl
        uint256 freeCollateral = getFreeCollateralByToken(to, token);
        // V_NEFC: not enough freeCollateral
        require(freeCollateral >= amount, "V_NEFC");

        int256 deltaBalance = amount.toInt256().neg256();
        if (token == _settlementToken) {
            // settle both the withdrawn amount and owedRealizedPnl to collateral
            int256 owedRealizedPnlX10_18 = IAccountBalance(_accountBalance).settleOwedRealizedPnl(to);
            deltaBalance = deltaBalance.add(owedRealizedPnlX10_18.formatSettlementToken(_decimals));
        }

        _modifyBalance(to, token, deltaBalance);
    }

    function _withdraw(address to, address token, uint256 amount) internal {
        _requireNotMaker(to);

        _settleAndDecreaseBalance(to, token, amount);
        SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(token), to, amount);
        emit Withdrawn(token, to, amount);
    }

    function _withdrawEther(address to, uint256 amount) internal {
        _requireNotMaker(to);

        // SLOAD for gas saving
        address WETH9 = _WETH9;

        _settleAndDecreaseBalance(to, WETH9, amount);

        IWETH9(WETH9).withdraw(amount);
        TransferHelper.safeTransferETH(to, amount);
        emit Withdrawn(WETH9, to, amount);
    }

    /// @param amount can be 0; do not require this
    function _modifyBalance(address trader, address token, int256 amount) internal {
        if (amount == 0) {
            return;
        }

        int256 oldBalance = _balance[trader][token];
        int256 newBalance = oldBalance.add(amount);
        _balance[trader][token] = newBalance;

        if (token == _settlementToken) {
            return;
        }
        // V_NS: not yet supported
        revert("V_NS");
    }

    //
    // INTERNAL VIEW
    //

    function _getFreeCollateral(address trader) internal view returns (uint256 freeCollateralX10_18) {
        return
            PerpMath
                .max(_getFreeCollateralByRatio(trader, IClearingHouseConfig(_clearingHouseConfig).getImRatio()), 0)
                .toUint256();
    }

    function _getFreeCollateralByRatio(
        address trader,
        uint24 ratio
    ) internal view returns (int256 freeCollateralX10_18) {
        // conservative config: freeCollateral = min(totalCollateralValue, accountValue) - openOrderMarginReq
        (int256 accountValueX10_18, int256 totalCollateralValueX10_18) = _getAccountValueAndTotalCollateralValue(
            trader
        );
        uint256 totalMarginRequirementX10_18 = _getTotalMarginRequirement(trader, ratio);

        return
            PerpMath.min(totalCollateralValueX10_18, accountValueX10_18).sub(totalMarginRequirementX10_18.toInt256());

        // moderate config: freeCollateral = min(totalCollateralValue, accountValue - openOrderMarginReq)
        // return
        //     PerpMath.min(
        //         totalCollateralValueX10_18,
        //         accountValueX10_S.sub(totalMarginRequirementX10_18.toInt256())
        //     );

        // aggressive config: freeCollateral = accountValue - openOrderMarginReq
        // note that the aggressive model depends entirely on unrealizedPnl, which depends on the index price
        //      we should implement some sort of safety check before using this model; otherwise,
        //      a trader could drain the entire vault if the index price deviates significantly.
        // return accountValueX10_18.sub(totalMarginRequirementX10_18.toInt256());
    }

    function _getTotalCollateralValueAndUnrealizedPnl(
        address trader
    ) internal view returns (int256 totalCollateralValueX10_18, int256 unrealizedPnlX10_18) {
        int256 settlementTokenBalanceX10_18;
        (settlementTokenBalanceX10_18, unrealizedPnlX10_18) = _getSettlementTokenBalanceAndUnrealizedPnl(trader);
        return (settlementTokenBalanceX10_18, unrealizedPnlX10_18);
    }

    /// @notice Get the specified trader's settlement token balance, including pending fee, funding payment,
    ///         owed realized PnL, but without unrealized PnL)
    /// @dev Note the difference between the return argument`settlementTokenBalanceX10_18` and
    ///      the return value of `getSettlementTokenValue()`.
    ///      The first one is settlement token balance with pending fee, funding payment, owed realized PnL;
    ///      The second one is the first one plus unrealized PnL.
    /// @return settlementTokenBalanceX10_18 Settlement amount in 18 decimals
    /// @return unrealizedPnlX10_18 Unrealized PnL in 18 decimals
    function _getSettlementTokenBalanceAndUnrealizedPnl(
        address trader
    ) internal view returns (int256 settlementTokenBalanceX10_18, int256 unrealizedPnlX10_18) {
        int256 fundingPaymentX10_18 = IVPool(_vPool).getAllPendingFundingPayment(trader);

        int256 owedRealizedPnlX10_18;
        uint256 pendingFeeX10_18;
        (owedRealizedPnlX10_18, unrealizedPnlX10_18, pendingFeeX10_18) = IAccountBalance(_accountBalance)
            .getPnlAndPendingFee(trader);

        settlementTokenBalanceX10_18 = getBalance(trader).parseSettlementToken(_decimals).add(
            pendingFeeX10_18.toInt256().sub(fundingPaymentX10_18).add(owedRealizedPnlX10_18)
        );

        return (settlementTokenBalanceX10_18, unrealizedPnlX10_18);
    }

    /// @return settlementTokenValueX10_18 settlementTokenBalance + totalUnrealizedPnl, in 18 decimals
    function _getSettlementTokenValue(address trader) internal view returns (int256 settlementTokenValueX10_18) {
        (int256 settlementBalanceX10_18, int256 unrealizedPnlX10_18) = _getSettlementTokenBalanceAndUnrealizedPnl(
            trader
        );
        return settlementBalanceX10_18.add(unrealizedPnlX10_18);
    }

    function _getAccountValueAndTotalCollateralValue(
        address trader
    ) internal view returns (int256 accountValueX10_18, int256 totalCollateralValueX10_18) {
        int256 unrealizedPnlX10_18;

        (totalCollateralValueX10_18, unrealizedPnlX10_18) = _getTotalCollateralValueAndUnrealizedPnl(trader);

        // accountValue = totalCollateralValue + totalUnrealizedPnl, in 18 decimals
        accountValueX10_18 = totalCollateralValueX10_18.add(unrealizedPnlX10_18);

        return (accountValueX10_18, totalCollateralValueX10_18);
    }

    /// @return totalMarginRequirementX10_18 total margin requirement in 18 decimals
    function _getTotalMarginRequirement(
        address trader,
        uint24 ratio
    ) internal view returns (uint256 totalMarginRequirementX10_18) {
        // uint256 totalDebtValueX10_18 = IAccountBalance(_accountBalance).getTotalDebtValue(trader);
        uint256 totalDebtValueX10_18 = IAccountBalance(_accountBalance).getTotalAbsPositionValue(trader);
        return totalDebtValueX10_18.mulRatio(ratio);
    }

    function _isCollateral(address token) internal view returns (bool) {
        return token == _settlementToken;
    }

    function _requireWETH9IsCollateral() internal view {
        // V_WINAC: WETH9 is not a collateral
        require(_isCollateral(_WETH9), "V_WINAC");
    }

    /// @inheritdoc BaseRelayRecipient
    function _msgSender() internal view override(BaseRelayRecipient, OwnerPausable) returns (address payable) {
        return super._msgSender();
    }

    /// @inheritdoc BaseRelayRecipient
    function _msgData() internal view override(BaseRelayRecipient, OwnerPausable) returns (bytes memory) {
        return super._msgData();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

/// @notice For future upgrades, do not change VaultStorageV1. Create a new
/// contract which implements VaultStorageV1 and following the naming convention
/// VaultStorageVX.
abstract contract VaultStorageV1 {
    // --------- IMMUTABLE ---------

    uint8 internal _decimals;

    address internal _settlementToken;

    // --------- ^^^^^^^^^ ---------

    address internal _clearingHouseConfig;
    address internal _accountBalance;
    address internal _insuranceFund;
    address internal _vPool;
    address internal _clearingHouse;
    address internal _maker;
    // _totalDebt is deprecated
    uint256 internal _totalDebt;

    address[10] private __gap1;
    uint256[10] private __gap2;

    // key: trader, token address
    mapping(address => mapping(address => int256)) internal _balance;
}

abstract contract VaultStorageV2 is VaultStorageV1 {
    address internal _collateralManager;
    address internal _WETH9;

    // trader => collateral token
    // collateral token registry of each trader
    mapping(address => address[]) internal _collateralTokensMap;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for WETH9
interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;

    /// @notice Withdraw wrapped ether to get ether
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}

// contracts/PNFTToken.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./PNFTTokenStorage.sol";

/**
 * @title PNFTToken
 */
contract PNFTToken is
    Initializable,
    ERC20Upgradeable,
    ERC20BurnableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuard,
    PNFTTokenStorageV1
{
    using SafeMath for uint256;

    event Released(uint256 amount);
    event Revoked();

    /**
     * @dev Reverts if no vesting schedule matches the passed identifier.
     */
    modifier onlyIfVestingScheduleExists(bytes32 vestingScheduleId) {
        require(_vestingSchedules[vestingScheduleId].initialized == true);
        _;
    }

    /**
     * @dev Reverts if the vesting schedule does not exist or has been revoked.
     */
    modifier onlyIfVestingScheduleNotRevoked(bytes32 vestingScheduleId) {
        require(_vestingSchedules[vestingScheduleId].initialized == true);
        require(_vestingSchedules[vestingScheduleId].revoked == false);
        _;
    }

    //

    function initialize(string memory name, string memory symbol) public initializer {
        __ERC20_init(name, symbol);
        __ERC20Burnable_init();
        __Pausable_init();
        __Ownable_init();
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }

    receive() external payable {}

    fallback() external payable {}

    /**
     * @dev Returns the number of vesting schedules associated to a beneficiary.
     * @return the number of vesting schedules
     */
    function getVestingSchedulesCountByBeneficiary(address _beneficiary) external view returns (uint256) {
        return _holdersVestingCount[_beneficiary];
    }

    /**
     * @dev Returns the vesting schedule id at the given index.
     * @return the vesting id
     */
    function getVestingIdAtIndex(uint256 index) external view returns (bytes32) {
        require(index < getVestingSchedulesCount(), "PNFTToken: index out of bounds");
        return _vestingSchedulesIds[index];
    }

    /**
     * @notice Returns the vesting schedule information for a given holder and index.
     * @return the vesting schedule structure information
     */
    function getVestingScheduleByAddressAndIndex(
        address holder,
        uint256 index
    ) external view returns (VestingSchedule memory) {
        return getVestingSchedule(computeVestingScheduleIdForAddressAndIndex(holder, index));
    }

    /**
     * @notice Returns the total amount of vesting schedules.
     * @return the total amount of vesting schedules
     */
    function getVestingSchedulesTotalAmount() external view returns (uint256) {
        return _vestingSchedulesTotalAmount;
    }

    function createVestingScheduleBatch(VestingScheduleParams[] calldata params) public onlyOwner {
        for (uint256 i = 0; i < params.length; i++) {
            createVestingSchedule(params[i]);
        }
    }

    /**
     * @notice Creates a new vesting schedule for a beneficiary.
     */
    function createVestingSchedule(VestingScheduleParams calldata params) public onlyOwner {
        require(params.duration > 0, "PNFTToken: duration must be > 0");
        require(params.amount > 0, "PNFTToken: amount must be > 0");
        require(params.slicePeriodSeconds >= 1, "PNFTToken: slicePeriodSeconds must be >= 1");
        bytes32 vestingScheduleId = this.computeNextVestingScheduleIdForHolder(params.beneficiary);
        uint256 cliff = params.start.add(params.cliff);
        _vestingSchedules[vestingScheduleId] = VestingSchedule(
            true,
            params.beneficiary,
            cliff,
            params.start,
            params.duration,
            params.slicePeriodSeconds,
            params.revocable,
            params.amount,
            0,
            false
        );
        _vestingSchedulesTotalAmount = _vestingSchedulesTotalAmount.add(params.amount);
        _vestingSchedulesIds.push(vestingScheduleId);
        uint256 currentVestingCount = _holdersVestingCount[params.beneficiary];
        _holdersVestingCount[params.beneficiary] = currentVestingCount.add(1);
        if (params.unvestingAmount > 0) {
            address payable beneficiaryPayable = payable(params.beneficiary);
            _mint(beneficiaryPayable, params.unvestingAmount);
        }
    }

    /**
     * @notice Revokes the vesting schedule for given identifier.
     * @param vestingScheduleId the vesting schedule identifier
     */
    function revoke(bytes32 vestingScheduleId) public onlyOwner onlyIfVestingScheduleNotRevoked(vestingScheduleId) {
        VestingSchedule storage vestingSchedule = _vestingSchedules[vestingScheduleId];
        require(vestingSchedule.revocable == true, "PNFTToken: vesting is not revocable");
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        if (vestedAmount > 0) {
            release(vestingScheduleId);
        }
        uint256 unreleased = vestingSchedule.amountTotal.sub(vestingSchedule.released);
        _vestingSchedulesTotalAmount = _vestingSchedulesTotalAmount.sub(unreleased);
        vestingSchedule.revoked = true;
    }

    /**
     * @notice Release vested amount of tokens.
     * @param vestingScheduleId the vesting schedule identifier
     */
    function release(bytes32 vestingScheduleId) public nonReentrant onlyIfVestingScheduleNotRevoked(vestingScheduleId) {
        VestingSchedule storage vestingSchedule = _vestingSchedules[vestingScheduleId];
        bool isBeneficiary = msg.sender == vestingSchedule.beneficiary;
        bool isOwner = msg.sender == owner();
        require(isBeneficiary || isOwner, "PNFTToken: only beneficiary and owner can release vested tokens");
        uint256 vestedAmount = _computeReleasableAmount(vestingSchedule);
        vestingSchedule.released = vestingSchedule.released.add(vestedAmount);
        address payable beneficiaryPayable = payable(vestingSchedule.beneficiary);
        _vestingSchedulesTotalAmount = _vestingSchedulesTotalAmount.sub(vestedAmount);
        _mint(beneficiaryPayable, vestedAmount);
    }

    /**
     * @dev Returns the number of vesting schedules managed by this contract.
     * @return the number of vesting schedules
     */
    function getVestingSchedulesCount() public view returns (uint256) {
        return _vestingSchedulesIds.length;
    }

    /**
     * @notice Computes the vested amount of tokens for the given vesting schedule identifier.
     * @return the vested amount
     */
    function computeReleasableAmount(
        bytes32 vestingScheduleId
    ) public view onlyIfVestingScheduleNotRevoked(vestingScheduleId) returns (uint256) {
        VestingSchedule storage vestingSchedule = _vestingSchedules[vestingScheduleId];
        return _computeReleasableAmount(vestingSchedule);
    }

    /**
     * @notice Returns the vesting schedule information for a given identifier.
     * @return the vesting schedule structure information
     */
    function getVestingSchedule(bytes32 vestingScheduleId) public view returns (VestingSchedule memory) {
        return _vestingSchedules[vestingScheduleId];
    }

    /**
     * @dev Computes the next vesting schedule identifier for a given holder address.
     */
    function computeNextVestingScheduleIdForHolder(address holder) public view returns (bytes32) {
        return computeVestingScheduleIdForAddressAndIndex(holder, _holdersVestingCount[holder]);
    }

    /**
     * @dev Returns the last vesting schedule for a given holder address.
     */
    function getLastVestingScheduleForHolder(address holder) public view returns (VestingSchedule memory) {
        return _vestingSchedules[computeVestingScheduleIdForAddressAndIndex(holder, _holdersVestingCount[holder] - 1)];
    }

    /**
     * @dev Computes the vesting schedule identifier for an address and an index.
     */
    function computeVestingScheduleIdForAddressAndIndex(address holder, uint256 index) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(holder, index));
    }

    /**
     * @dev Computes the releasable amount of tokens for a vesting schedule.
     * @return the amount of releasable tokens
     */
    function _computeReleasableAmount(VestingSchedule memory vestingSchedule) internal view returns (uint256) {
        uint256 currentTime = getCurrentTime();
        if ((currentTime < vestingSchedule.cliff) || vestingSchedule.revoked == true) {
            return 0;
        } else if (currentTime >= vestingSchedule.start.add(vestingSchedule.duration)) {
            return vestingSchedule.amountTotal.sub(vestingSchedule.released);
        } else {
            uint256 timeFromStart = currentTime.sub(vestingSchedule.start);
            uint secondsPerSlice = vestingSchedule.slicePeriodSeconds;
            uint256 vestedSlicePeriods = timeFromStart.div(secondsPerSlice);
            uint256 vestedSeconds = vestedSlicePeriods.mul(secondsPerSlice);
            uint256 vestedAmount = vestingSchedule.amountTotal.mul(vestedSeconds).div(vestingSchedule.duration);
            vestedAmount = vestedAmount.sub(vestingSchedule.released);
            return vestedAmount;
        }
    }

    function getCurrentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable {
    using SafeMathUpgradeable for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/ContextUpgradeable.sol";
import "./ERC20Upgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal initializer {
        __Context_init_unchained();
        __ERC20Burnable_init_unchained();
    }

    function __ERC20Burnable_init_unchained() internal initializer {
    }
    using SafeMathUpgradeable for uint256;

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

/// @notice For future upgrades, do not change PNFTTokenStorageV1. Create a new
/// contract which implements PNFTTokenStorageV1 and following the naming convention
/// PNFTTokenStorageVX.
abstract contract PNFTTokenStorageV1 {
    // --------- IMMUTABLE ---------

    struct VestingScheduleParams {
        address beneficiary;
        uint256 start;
        uint256 cliff;
        uint256 duration;
        uint256 slicePeriodSeconds;
        bool revocable;
        uint256 unvestingAmount;
        uint256 amount;
    }

    struct VestingSchedule {
        bool initialized;
        // beneficiary of tokens after they are released
        address beneficiary;
        // cliff period in seconds
        uint256 cliff;
        // start time of the vesting period
        uint256 start;
        // duration of the vesting period in seconds
        uint256 duration;
        // duration of a slice period for the vesting in seconds
        uint256 slicePeriodSeconds;
        // whether or not the vesting is revocable
        bool revocable;
        // total amount of tokens to be released at the end of the vesting
        uint256 amountTotal;
        // amount of tokens released
        uint256 released;
        // whether or not the vesting has been revoked
        bool revoked;
    }

    // address of the ERC20 token
    bytes32[] internal _vestingSchedulesIds;
    mapping(bytes32 => VestingSchedule) internal _vestingSchedules;
    uint256 internal _vestingSchedulesTotalAmount;
    mapping(address => uint256) internal _holdersVestingCount;

    address[10] private __gap1;
    uint256[10] private __gap2;
}

// contracts/PNFTToken.sol
// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma abicoder v2;
import "./PNFTToken.sol";

/**
 * @title MockPNFTToken
 * WARNING: use only for testing and debugging purpose
 */
contract TestPNFTToken is PNFTToken {
    uint256 mockTime = 0;

    // constructor(string memory name, string memory symbol) PNFTToken(name, symbol) {}

    function setCurrentTime(uint256 _time) external {
        mockTime = _time;
    }

    function getCurrentTime() internal view virtual override returns (uint256) {
        return mockTime;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20Upgradeable.sol";
import "../../utils/PausableUpgradeable.sol";
import "../../proxy/Initializable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20PausableUpgradeable is Initializable, ERC20Upgradeable, PausableUpgradeable {
    function __ERC20Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
    }

    function __ERC20Pausable_init_unchained() internal initializer {
    }
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { OwnerPausable } from "../base/OwnerPausable.sol";
import { IVault } from "../interface/IVault.sol";

contract TestFaucet is OwnerPausable {
    //
    mapping(address => bool) internal _faucetMap;
    address internal _vault;
    address internal _token;
    uint256 internal _amount;

    function initialize(address vaultArg, address tokenArg, uint256 amountArg) external initializer {
        __OwnerPausable_init();
        _vault = vaultArg;
        _token = tokenArg;
        _amount = amountArg;
        // approve max
        IERC20Upgradeable(_token).approve(_vault, type(uint256).max);
    }

    function getVault() external view returns (address) {
        return _vault;
    }

    function getToken() external view returns (address) {
        return _token;
    }

    function getAmount() external view returns (uint256) {
        return _amount;
    }

    function isFaucet(address to) external view returns (bool) {
        return _faucetMap[to];
    }

    function depositFor(address to) external {
        // TF_EF: existed faucet
        require(!_faucetMap[to], "TF_EF");
        _faucetMap[to] = true;
        IVault(_vault).depositFor(to, _token, _amount);
    }

    function faucet(address to) external {
        // TF_EF: existed faucet
        require(!_faucetMap[to], "TF_EF");
        _faucetMap[to] = true;
        IERC20Upgradeable(_token).transfer(to, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { SignedSafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { PerpMath } from "./lib/PerpMath.sol";
import { PerpSafeCast } from "./lib/PerpSafeCast.sol";
import { InsuranceFundStorageV1 } from "./storage/InsuranceFundStorage.sol";
import { PerpSafeCast } from "./lib/PerpSafeCast.sol";
import { InsuranceFundStorageV2 } from "./storage/InsuranceFundStorage.sol";
import { OwnerPausable } from "./base/OwnerPausable.sol";
import { IInsuranceFund } from "./interface/IInsuranceFund.sol";
import { IVault } from "./interface/IVault.sol";

// never inherit any new stateful contract. never change the orders of parent stateful contracts
contract InsuranceFund is IInsuranceFund, ReentrancyGuardUpgradeable, OwnerPausable, InsuranceFundStorageV2 {
    using AddressUpgradeable for address;
    using SignedSafeMathUpgradeable for int256;
    using PerpMath for int256;
    using PerpSafeCast for int256;
    using PerpSafeCast for uint256;

    //
    // MODIFIER
    //

    function _requireOnlyClearingHouse() internal view {
        // only AccountBalance
        require(_msgSender() == _clearingHouse, "RF_OCH");
    }

    function initialize(address tokenArg) external initializer {
        // token address is not contract
        require(tokenArg.isContract(), "IF_TNC");

        __ReentrancyGuard_init();
        __OwnerPausable_init();

        _token = tokenArg;
    }

    function setVault(address vaultArg) external onlyOwner {
        // vault is not a contract
        require(vaultArg.isContract(), "IF_VNC");
        _vault = vaultArg;
        emit VaultChanged(vaultArg);
    }

    function setClearingHouse(address clearingHouseArg) external {
        _clearingHouse = clearingHouseArg;
        emit ClearingHouseChanged(clearingHouseArg);
    }

    //
    // EXTERNAL VIEW
    //

    /// @inheritdoc IInsuranceFund
    function getToken() external view override returns (address) {
        return _token;
    }

    /// @inheritdoc IInsuranceFund
    function getVault() external view override returns (address) {
        return _vault;
    }

    function getClearingHouse() external view override returns (address) {
        return _clearingHouse;
    }

    //
    // PUBLIC VIEW
    //

    /// @inheritdoc IInsuranceFund
    function getInsuranceFundCapacity() public view override returns (int256) {
        address vault = _vault;
        address token = _token;

        int256 insuranceFundSettlementTokenValueX10_S = IVault(vault).getSettlementTokenValue(address(this));
        int256 insuranceFundWalletBalanceX10_S = IERC20Upgradeable(token).balanceOf(address(this)).toInt256();
        return insuranceFundSettlementTokenValueX10_S.add(insuranceFundWalletBalanceX10_S);
    }

    //
    function getRepegAccumulatedFund() external view override returns (int256) {
        return _accumulatedRepegFund;
    }

    function getRepegDistributedFund() external view override returns (int256) {
        return _distributedRepegFund;
    }

    // internal function

    function _addRepegFund(uint256 fund) internal {
        _accumulatedRepegFund = _accumulatedRepegFund.add(fund.toInt256());
    }

    function _distributeRepegFund(int256 fund) internal {
        _distributedRepegFund = _distributedRepegFund.add(fund);
        // RF_LF: limit fund
        require(_distributedRepegFund <= _accumulatedRepegFund, "RF_LF");
    }

    // external function

    function addRepegFund(uint256 fund) external override {
        _requireOnlyClearingHouse();
        _addRepegFund(fund);
    }

    function repegFund(int256 fund) external override {
        _requireOnlyClearingHouse();
        _distributeRepegFund(fund);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

/// @notice For future upgrades, do not change InsuranceFundStorageV1. Create a new
/// contract which implements InsuranceFundStorageV1 and following the naming convention
/// InsuranceFundStorageVX.
abstract contract InsuranceFundStorageV1 {
    // --------- IMMUTABLE ---------

    address internal _token;

    // --------- ^^^^^^^^^ ---------

    address internal _vault;

    address internal _clearingHouse;
    address[9] private __gap1;

    int256 _accumulatedRepegFund;
    int256 _distributedRepegFund;
    uint256[8] private __gap2;
}

abstract contract InsuranceFundStorageV2 is InsuranceFundStorageV1 {
    address internal _surplusBeneficiary;

    // decimal is the same as the settlement token
    uint256 internal _distributionThreshold;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { IClearingHouse } from "../interface/IClearingHouse.sol";
import { DataTypes } from "../types/DataTypes.sol";

contract TestLimitOrderBook {
    address internal _clearingHouse;

    constructor(address clearingHouseArg) {
        _clearingHouse = clearingHouseArg;
    }

    function openPositionFor(address trader, IClearingHouse.OpenPositionParams memory params) external {
        // NOTE: here we only care about whether a contract can call `ClearingHouse.openPositionFor()` for a trader
        // for the actual `fillLimitOrder()` logic, see `perp-curie-limit-order-contract` repo
        IClearingHouse(_clearingHouse).openPositionFor(
            trader,
            DataTypes.OpenPositionParams({
                baseToken: params.baseToken,
                isBaseToQuote: params.isBaseToQuote,
                isExactInput: params.isExactInput,
                amount: params.amount,
                oppositeAmountBound: params.oppositeAmountBound,
                deadline: params.deadline,
                sqrtPriceLimitX96: params.sqrtPriceLimitX96,
                referralCode: params.referralCode
            })
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { IERC20Metadata } from "./interface/IERC20Metadata.sol";
import { ClearingHouseCallee } from "./base/ClearingHouseCallee.sol";
import { UniswapV3Broker } from "./lib/UniswapV3Broker.sol";
import { IVirtualToken } from "./interface/IVirtualToken.sol";
import { MarketRegistryStorageV1 } from "./storage/MarketRegistryStorage.sol";
import { IMarketRegistry } from "./interface/IMarketRegistry.sol";

// never inherit any new stateful contract. never change the orders of parent stateful contracts
contract MarketRegistry is IMarketRegistry, ClearingHouseCallee, MarketRegistryStorageV1 {
    using AddressUpgradeable for address;

    //
    // MODIFIER
    //

    modifier checkRatio(uint24 ratio) {
        // ratio overflow
        require(ratio <= 1e6, "MR_RO");
        _;
    }

    modifier checkPool(address baseToken) {
        // pool not exists
        require(_poolMap[baseToken] != address(0), "MR_PNE");
        _;
    }

    //
    // EXTERNAL NON-VIEW
    //

    function initialize(address uniswapV3FactoryArg, address quoteTokenArg) external initializer {
        __ClearingHouseCallee_init();

        // UnsiwapV3Factory is not contract
        require(uniswapV3FactoryArg.isContract(), "MR_UFNC");
        // QuoteToken is not contract
        require(quoteTokenArg.isContract(), "MR_QTNC");

        // update states
        _uniswapV3Factory = uniswapV3FactoryArg;
        _quoteToken = quoteTokenArg;
        _maxOrdersPerMarket = type(uint8).max;
    }

    /// @inheritdoc IMarketRegistry
    function addPool(address baseToken, uint24 feeRatio) external override onlyOwner returns (address) {
        // existent pool
        require(_poolMap[baseToken] == address(0), "MR_EP");
        // baseToken decimals is not 18
        require(IERC20Metadata(baseToken).decimals() == 18, "MR_BDN18");
        // clearingHouse base token balance not enough
        require(IERC20Metadata(baseToken).balanceOf(_clearingHouse) == type(uint256).max, "MR_CHBNE");

        // quote token total supply not enough
        require(IERC20Metadata(_quoteToken).totalSupply() == type(uint256).max, "MR_QTSNE");

        // to ensure the base is always token0 and quote is always token1
        // invalid baseToken
        require(baseToken < _quoteToken, "MR_IB");

        address pool = UniswapV3Broker.getPool(_uniswapV3Factory, _quoteToken, baseToken, feeRatio);
        // non-existent pool in uniswapV3 factory
        require(pool != address(0), "MR_NEP");

        (uint256 sqrtPriceX96, , , , , , ) = UniswapV3Broker.getSlot0(pool);
        // pool not (yet) initialized
        require(sqrtPriceX96 != 0, "MR_PNI");

        // clearingHouse not in baseToken whitelist
        require(IVirtualToken(baseToken).isInWhitelist(_clearingHouse), "MR_CNBWL");
        // pool not in baseToken whitelist
        require(IVirtualToken(baseToken).isInWhitelist(pool), "MR_PNBWL");

        // clearingHouse not in quoteToken whitelist
        require(IVirtualToken(_quoteToken).isInWhitelist(_clearingHouse), "MR_CHNQWL");
        // pool not in quoteToken whitelist
        require(IVirtualToken(_quoteToken).isInWhitelist(pool), "MR_PNQWL");

        _poolMap[baseToken] = pool;
        _uniswapFeeRatioMap[baseToken] = feeRatio;
        _insuranceFundFeeRatioMap[baseToken] = 500; // 0.05%
        _platformFundFeeRatioMap[baseToken] = 2000; // 0.2%
        _optimalDeltaTwapRatioMap[baseToken] = 30000; // 3%
        _unhealthyDeltaTwapRatioMap[baseToken] = 50000; // 5%
        _optimalFundingRatioMap[baseToken] = 250000; // 25%

        emit PoolAdded(baseToken, feeRatio, pool);
        return pool;
    }

    /// @inheritdoc IMarketRegistry
    function setPlatformFundFeeRatio(
        address baseToken,
        uint24 feeRatio
    ) external override checkPool(baseToken) checkRatio(feeRatio) onlyOwner {
        _platformFundFeeRatioMap[baseToken] = feeRatio;
        emit PlatformFundFeeRatioChanged(baseToken, feeRatio);
    }

    /// @inheritdoc IMarketRegistry
    function setInsuranceFundFeeRatio(
        address baseToken,
        uint24 feeRatio
    ) external override checkPool(baseToken) checkRatio(feeRatio) onlyOwner {
        _insuranceFundFeeRatioMap[baseToken] = feeRatio;
        emit InsuranceFundFeeRatioChanged(baseToken, feeRatio);
    }

    /// @inheritdoc IMarketRegistry
    function setMaxOrdersPerMarket(uint8 maxOrdersPerMarketArg) external override onlyOwner {
        _maxOrdersPerMarket = maxOrdersPerMarketArg;
        emit MaxOrdersPerMarketChanged(maxOrdersPerMarketArg);
    }

    //
    // EXTERNAL VIEW
    //

    /// @inheritdoc IMarketRegistry
    function getQuoteToken() external view override returns (address) {
        return _quoteToken;
    }

    /// @inheritdoc IMarketRegistry
    function getUniswapV3Factory() external view override returns (address) {
        return _uniswapV3Factory;
    }

    /// @inheritdoc IMarketRegistry
    function getMaxOrdersPerMarket() external view override returns (uint8) {
        return _maxOrdersPerMarket;
    }

    /// @inheritdoc IMarketRegistry
    function getPool(address baseToken) external view override checkPool(baseToken) returns (address) {
        return _poolMap[baseToken];
    }

    /// @inheritdoc IMarketRegistry
    function getInsuranceFundFeeRatio(address baseToken) external view override checkPool(baseToken) returns (uint24) {
        return _insuranceFundFeeRatioMap[baseToken];
    }

    function getPlatformFundFeeRatio(address baseToken) external view override checkPool(baseToken) returns (uint24) {
        return _platformFundFeeRatioMap[baseToken];
    }

    function getOptimalDeltaTwapRatio(address baseToken) external view override checkPool(baseToken) returns (uint24) {
        return _optimalDeltaTwapRatioMap[baseToken];
    }

    function getOptimalFundingRatio(address baseToken) external view override checkPool(baseToken) returns (uint24) {
        return _optimalFundingRatioMap[baseToken];
    }

    function setOptimalDeltaTwapRatio(address baseToken, uint24 optimalDeltaTwapRatio) external checkPool(baseToken) {
        _optimalDeltaTwapRatioMap[baseToken] = optimalDeltaTwapRatio;
    }

    /// @inheritdoc IMarketRegistry
    function getMarketInfo(address baseToken) external view override checkPool(baseToken) returns (MarketInfo memory) {
        return
            MarketInfo({
                pool: _poolMap[baseToken],
                uniswapFeeRatio: _uniswapFeeRatioMap[baseToken],
                insuranceFundFeeRatio: _insuranceFundFeeRatioMap[baseToken],
                platformFundFeeRatio: _platformFundFeeRatioMap[baseToken],
                optimalDeltaTwapRatio: _optimalDeltaTwapRatioMap[baseToken],
                unhealthyDeltaTwapRatio: _unhealthyDeltaTwapRatioMap[baseToken],
                optimalFundingRatio: _optimalFundingRatioMap[baseToken]
            });
    }

    /// @inheritdoc IMarketRegistry
    function hasPool(address baseToken) external view override returns (bool) {
        return _poolMap[baseToken] != address(0);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

interface IVirtualToken {
    function isInWhitelist(address account) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

/// @notice For future upgrades, do not change MarketRegistryStorageV1. Create a new
/// contract which implements MarketRegistryStorageV1 and following the naming convention
/// MarketRegistryStorageVX.
abstract contract MarketRegistryStorageV1 {
    address internal _uniswapV3Factory;
    address internal _quoteToken;

    uint8 internal _maxOrdersPerMarket;

    address[10] private __gap1;
    uint256[10] private __gap2;

    // key: baseToken, value: pool
    mapping(address => address) internal _poolMap;

    // key: baseToken, what insurance fund get = exchangeFee * insuranceFundFeeRatio
    mapping(address => uint24) internal _insuranceFundFeeRatioMap;

    // key: baseToken , uniswap fee will be ignored and use the exchangeFeeRatio instead
    mapping(address => uint24) internal _platformFundFeeRatioMap;

    // key: baseToken, _uniswapFeeRatioMap cache only
    mapping(address => uint24) internal _uniswapFeeRatioMap;

    mapping(address => uint24) internal _optimalDeltaTwapRatioMap;

    mapping(address => uint24) internal _optimalFundingRatioMap;

    mapping(address => uint24) internal _unhealthyDeltaTwapRatioMap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import { ERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { SafeOwnable } from "./base/SafeOwnable.sol";
import { IVirtualToken } from "./interface/IVirtualToken.sol";

contract VirtualToken is IVirtualToken, SafeOwnable, ERC20Upgradeable {
    mapping(address => bool) internal _whitelistMap;

    // __gap is reserved storage
    uint256[50] private __gap;

    event WhitelistAdded(address account);
    event WhitelistRemoved(address account);

    function __VirtualToken_init(string memory nameArg, string memory symbolArg) internal initializer {
        __SafeOwnable_init();
        __ERC20_init(nameArg, symbolArg);
    }

    function mintMaximumTo(address recipient) external onlyOwner {
        _mint(recipient, type(uint256).max);
    }

    function addWhitelist(address account) external onlyOwner {
        _whitelistMap[account] = true;
        emit WhitelistAdded(account);
    }

    function removeWhitelist(address account) external onlyOwner {
        // VT_BNZ: balance is not zero
        require(balanceOf(account) == 0, "VT_BNZ");
        delete _whitelistMap[account];
        emit WhitelistRemoved(account);
    }

    /// @inheritdoc IVirtualToken
    function isInWhitelist(address account) external view override returns (bool) {
        return _whitelistMap[account];
    }

    /// @inheritdoc ERC20Upgradeable
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        // `from` == address(0) when mint()
        if (from != address(0)) {
            // not whitelisted
            require(_whitelistMap[from], "VT_NW");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
import { VirtualToken } from "./VirtualToken.sol";

contract QuoteToken is VirtualToken {
    function initialize(string memory nameArg, string memory symbolArg) external initializer {
        __VirtualToken_init(nameArg, symbolArg);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import { SafeOwnable } from "../base/SafeOwnable.sol";
import "./TestERC20.sol";

contract TestWhitelistERC20 is TestERC20, SafeOwnable {
    mapping(address => bool) internal _whitelist;

    modifier whitelistCheck(address sender, address recipient) {
        if (!_whitelist[sender]) {
            require(_whitelist[recipient], "The address of recipient is not in whitelist.");
        }
        _;
    }

    function __TestWhitelistERC20_init(
        string memory name,
        string memory symbol,
        uint8 decimal
    ) external initializer {
        __TestERC20_init(name, symbol, decimal);
        __SafeOwnable_init();
    }

    function addWhitelist(address addr) external onlyOwner {
        _whitelist[addr] = true;
    }

    function removeWhitelist(address addr) external onlyOwner {
        _whitelist[addr] = false;
    }

    function isInWhitelist(address addr) external view returns (bool) {
        return _whitelist[addr];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        whitelistCheck(msg.sender, recipient)
        returns (bool)
    {
        return super.transfer(recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override whitelistCheck(msg.sender, recipient) returns (bool) {
        return super.transferFrom(sender, recipient, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/presets/ERC20PresetMinterPauserUpgradeable.sol";

contract TestERC20 is ERC20PresetMinterPauserUpgradeable {
    uint256 _transferFeeRatio;

    function __TestERC20_init(string memory name, string memory symbol, uint8 decimal) public initializer {
        __ERC20PresetMinterPauser_init(name, symbol);
        _setupDecimals(decimal);
        _transferFeeRatio = 0;
    }

    function setMinter(address minter) external {
        grantRole(MINTER_ROLE, minter);
    }

    function burnWithoutApproval(address user, uint256 amount) external {
        _burn(user, amount);
    }

    function setTransferFeeRatio(uint256 ratio) external {
        _transferFeeRatio = ratio;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool success) {
        if (_transferFeeRatio != 0) {
            uint256 fee = (amount * _transferFeeRatio) / 100;
            _burn(sender, fee);
            amount = amount - fee;
        }
        return super.transferFrom(sender, recipient, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../access/AccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../token/ERC20/ERC20Upgradeable.sol";
import "../token/ERC20/ERC20BurnableUpgradeable.sol";
import "../token/ERC20/ERC20PausableUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 */
contract ERC20PresetMinterPauserUpgradeable is Initializable, ContextUpgradeable, AccessControlUpgradeable, ERC20BurnableUpgradeable, ERC20PausableUpgradeable {
    function initialize(string memory name, string memory symbol) public virtual initializer {
        __ERC20PresetMinterPauser_init(name, symbol);
    }
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * See {ERC20-constructor}.
     */
    function __ERC20PresetMinterPauser_init(string memory name, string memory symbol) internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __ERC20Burnable_init_unchained();
        __Pausable_init_unchained();
        __ERC20Pausable_init_unchained();
        __ERC20PresetMinterPauser_init_unchained(name, symbol);
    }

    function __ERC20PresetMinterPauser_init_unchained(string memory name, string memory symbol) internal initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    /**
     * @dev Creates `amount` new tokens for `to`.
     *
     * See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 amount) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have minter role to mint");
        _mint(to, amount);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC20PresetMinterPauser: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override(ERC20Upgradeable, ERC20PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { PerpSafeCast } from "../lib/PerpSafeCast.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { SignedSafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import "../RewardMiner.sol";

contract TestRewardMiner is RewardMiner {
    uint256 private _testBlockTimestamp;

    function __TestRewardMiner_init(
        address clearingHouseArg,
        address pnftTokenArg,
        uint256 periodDurationArg,
        uint256[] memory starts,
        uint256[] memory ends,
        uint256[] memory totals,
        uint256 limitClaimPeriodArg
    ) external initializer {
        RewardMiner.initialize(
            clearingHouseArg,
            pnftTokenArg,
            periodDurationArg,
            starts,
            ends,
            totals,
            limitClaimPeriodArg
        );
        _testBlockTimestamp = block.timestamp;
    }

    function setBlockTimestamp(uint256 blockTimestamp) external {
        _testBlockTimestamp = blockTimestamp;
    }

    function getBlockTimestamp() external view returns (uint256) {
        return _testBlockTimestamp;
    }

    function _blockTimestamp() internal view override returns (uint256) {
        return _testBlockTimestamp;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { AddressUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { SignedSafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SignedSafeMathUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import { PerpSafeCast } from "./lib/PerpSafeCast.sol";
import { PerpMath } from "./lib/PerpMath.sol";
import { OwnerPausable } from "./base/OwnerPausable.sol";
import { IRewardMiner } from "./interface/IRewardMiner.sol";
import { BlockContext } from "./base/BlockContext.sol";
import { RewardMinerStorage } from "./storage/RewardMinerStorage.sol";

// never inherit any new stateful contract. never change the orders of parent stateful contracts
contract RewardMiner is IRewardMiner, BlockContext, OwnerPausable, RewardMinerStorage {
    using AddressUpgradeable for address;
    using SafeMathUpgradeable for uint256;
    using SignedSafeMathUpgradeable for int256;
    using PerpSafeCast for uint256;
    using PerpSafeCast for int256;
    using PerpMath for uint256;
    using PerpMath for int256;

    event Mint(uint256 indexed periodNumber, address indexed trader, uint256 amount);
    event MintWithPnl(uint256 indexed periodNumber, address indexed trader, uint256 amount, int256 pnl);
    event Spend(address indexed trader, uint256 amount);

    //
    // EXTERNAL NON-VIEW
    //

    function _requireOnlyClearingHouse() internal view {
        // only ClearingHouse
        require(_msgSender() == _clearingHouse, "RM_OCH");
    }

    /// @dev this function is public for testing
    // solhint-disable-next-line func-order
    function initialize(
        address clearingHouseArg,
        address pnftTokenArg,
        uint256 periodDurationArg,
        uint256[] memory starts,
        uint256[] memory ends,
        uint256[] memory totals,
        uint256 limitClaimPeriodArg
    ) public initializer {
        // ClearingHouse address is not contract
        // _isContract(clearingHouseArg, "RM_CHNC");
        _isContract(pnftTokenArg, "RM_PTNC");
        require(periodDurationArg > 0, "RM_PDZ");
        require(starts.length == ends.length && ends.length == totals.length, "RM_IL");

        __OwnerPausable_init();

        _clearingHouse = clearingHouseArg;
        _pnftToken = pnftTokenArg;
        _periodDuration = periodDurationArg;
        _limitClaimPeriod = limitClaimPeriodArg;

        for (uint256 i = 0; i < ends.length; i++) {
            // RM_ISE: invalid start end
            require(starts[i] <= ends[i], "RM_ISE");
            if (i > 0) {
                // RM_IS: invalid start
                require(starts[i] > starts[i - 1], "RM_IS");
            }
            // RM_IT: invalid total
            require(totals[i] > 0, "RM_IT");
            PeriodConfig memory cfg = PeriodConfig({ start: starts[i], end: ends[i], total: totals[i] });
            _periodConfigs.push(cfg);
        }
    }

    function _isContract(address contractArg, string memory errorMsg) internal view {
        require(contractArg.isContract(), errorMsg);
    }

    function setClearingHouse(address clearingHouseArg) external {
        _isContract(clearingHouseArg, "RM_CHNC");
        _clearingHouse = clearingHouseArg;
    }

    // function setPnftToken(address pnftTokenArg) external {
    //     _isContract(pnftTokenArg, "RM_PTNC");
    //     _pnftToken = pnftTokenArg;
    // }

    function setLimitClaimPeriod(uint256 limitClaimPeriodArg) external {
        _limitClaimPeriod = limitClaimPeriodArg;
    }

    function getLimitClaimPeriod() external view returns (uint256 limitClaimPeriod) {
        limitClaimPeriod = _limitClaimPeriod;
    }

    function getPeriodDuration() external view returns (uint256 periodDuration) {
        periodDuration = _periodDuration;
    }

    function getStart() external view returns (uint256 start) {
        start = _start;
    }

    function getStartPnlNumber() external view returns (uint256 startPnlNumber) {
        startPnlNumber = _startPnlNumber;
    }

    function getAllocation() external view returns (uint256 allocation) {
        allocation = _allocation;
    }

    function getSpend() external view returns (uint256 spend) {
        spend = _spend;
    }

    function getCurrentPeriodInfo()
        external
        view
        returns (uint256 periodNumber, uint256 start, uint256 end, uint256 total, uint256 amount, int256 pnlAmount)
    {
        periodNumber = _getPeriodNumber();
        (start, end, total, amount, pnlAmount) = _getCurrentPeriodInfoByNumner(periodNumber);
    }

    function getCurrentPeriodInfoByNumner(
        uint256 periodNumber
    ) external view returns (uint256 start, uint256 end, uint256 total, uint256 amount, int256 pnlAmount) {
        (start, end, total, amount, pnlAmount) = _getCurrentPeriodInfoByNumner(periodNumber);
    }

    function _getCurrentPeriodInfoByNumner(
        uint256 periodNumber
    ) internal view returns (uint256 start, uint256 end, uint256 total, uint256 amount, int256 pnlAmount) {
        (start, end, total, amount, pnlAmount) = _getPeriodInfo(periodNumber);
    }

    function getCurrentPeriodInfoTrader(
        address trader
    )
        external
        view
        returns (
            uint256 periodNumber,
            uint256 start,
            uint256 end,
            uint256 total,
            uint256 amount,
            int256 pnlAmount,
            uint256 traderAmount,
            int256 traderPnl
        )
    {
        periodNumber = _getPeriodNumber();
        (start, end, total, amount, pnlAmount, traderAmount, traderPnl) = _getCurrentPeriodInfoTrader(
            trader,
            periodNumber
        );
    }

    function _getCurrentPeriodInfoTrader(
        address trader,
        uint256 periodNumber
    )
        internal
        view
        returns (
            uint256 start,
            uint256 end,
            uint256 total,
            uint256 amount,
            int256 pnlAmount,
            uint256 traderAmount,
            int256 traderPnl
        )
    {
        (start, end, total, amount, pnlAmount) = _getPeriodInfo(periodNumber);
        traderAmount = _periodDataMap[periodNumber].users[trader];
        traderPnl = _periodDataMap[periodNumber].pnlUsers[trader];
    }

    function _getPeriodInfo(
        uint256 periodNumber
    ) internal view returns (uint256 start, uint256 end, uint256 total, uint256 amount, int256 pnlAmount) {
        require(_blockTimestamp() >= _start, "RM_IT");
        PeriodData storage periodData = _periodDataMap[periodNumber];
        if (periodData.periodNumber != 0) {
            total = periodData.total;
            amount = periodData.amount;
            pnlAmount = periodData.pnlAmount;
        } else {
            for (uint256 i = 0; i < _periodConfigs.length; i++) {
                PeriodConfig memory cfg = _periodConfigs[i];
                if (cfg.start <= periodNumber && periodNumber <= cfg.end) {
                    total = cfg.total;
                }
            }
        }
        start = _start + (periodNumber - 1) * _periodDuration;
        end = start + _periodDuration;
    }

    function getPeriodNumber() external view returns (uint256 periodNumber) {
        return _getPeriodNumber();
    }

    function _getPeriodNumber() internal view returns (uint256 periodNumber) {
        uint256 timestamp = _blockTimestamp();
        require(timestamp >= _start, "RM_IT");
        periodNumber = timestamp.sub(_start).div(_periodDuration).add(1);
    }

    function _createPeriodData() internal returns (PeriodData storage periodData) {
        uint256 periodNumber = _getPeriodNumber();
        periodData = _periodDataMap[periodNumber];
        if (periodData.periodNumber == 0) {
            (, , uint256 total, , ) = _getPeriodInfo(periodNumber);
            if (total > 0) {
                // periodData
                periodData.periodNumber = periodNumber;
                periodData.total = total;
                _periodNumbers.push(periodData.periodNumber);
                // _allocation
                _allocation = _allocation.add(total);
            }
        }
    }

    function getClaimable(address trader) external view returns (uint256 amount) {
        return _getClaimable(trader);
    }

    struct InternalSetClaimableVars {
        uint256 periodNumber;
        uint256 lastPeriodNumber;
        int256 endPeriod;
        uint256 userAmount;
        int256 pnlUserAmount;
    }

    function _getClaimable(address trader) internal view returns (uint256 amount) {
        InternalSetClaimableVars memory vars;
        vars.periodNumber = _getPeriodNumber();
        vars.lastPeriodNumber = _lastClaimPeriodNumberMap[trader];
        if (_periodNumbers.length > 0) {
            vars.endPeriod = 0;
            if (_limitClaimPeriod > 0 && (_periodNumbers.length - 1).toInt256() >= _limitClaimPeriod.toInt256()) {
                vars.endPeriod = (_periodNumbers.length - 1).toInt256().sub(_limitClaimPeriod.toInt256());
            }
            for (int256 i = (_periodNumbers.length - 1).toInt256(); i >= vars.endPeriod; i--) {
                PeriodData storage periodData = _periodDataMap[_periodNumbers[uint256(i)]];

                vars.userAmount = periodData.users[trader];
                vars.pnlUserAmount = periodData.pnlUsers[trader];

                if (
                    (vars.userAmount > 0 || vars.pnlUserAmount > 0) &&
                    periodData.periodNumber < vars.periodNumber &&
                    periodData.periodNumber > vars.lastPeriodNumber
                ) {
                    if (_startPnlNumber == 0 || periodData.periodNumber < _startPnlNumber) {
                        amount = amount.add(vars.userAmount.mul(periodData.total).div(periodData.amount));
                    } else {
                        if (vars.userAmount > 0) {
                            amount = amount.add(
                                vars
                                    .userAmount
                                    .mul(periodData.total)
                                    .div(periodData.amount)
                                    .mul(uint256(1e6).sub(_pnlRatio))
                                    .div(1e6)
                            );
                        }
                        if (vars.pnlUserAmount > 0) {
                            amount = amount.add(
                                vars
                                    .pnlUserAmount
                                    .mul(periodData.total.toInt256())
                                    .div(periodData.pnlAmount)
                                    .mul(_pnlRatio.toInt256())
                                    .div(1e6)
                                    .abs()
                            );
                        }
                    }
                }
                if (periodData.periodNumber <= vars.lastPeriodNumber) {
                    break;
                }
            }
        }
    }

    function startMiner(uint256 startArg) external onlyOwner {
        // RM_SZ: start zero
        require(_start == 0, "RM_SZ");
        // RM_IT: invalid time
        require(startArg >= _blockTimestamp(), "RM_IT");
        _start = startArg;
    }

    function startPnlMiner(uint256 startPnlNumberArg, uint256 pnlRatioArg) external onlyOwner {
        // RM_SZ: start zero
        require(_startPnlNumber == 0, "RM_SZ");
        // RM_IT: invalid number
        require(startPnlNumberArg >= _getPeriodNumber(), "RM_IN");
        _startPnlNumber = startPnlNumberArg;
        _pnlRatio = pnlRatioArg;
    }

    function mint(address trader, uint256 amount, int256 pnl) external override {
        _requireOnlyClearingHouse();
        if (_start > 0 && _blockTimestamp() >= _start) {
            PeriodData storage periodData = _createPeriodData();
            if (periodData.total > 0) {
                // for volume
                {
                    periodData.users[trader] = periodData.users[trader].add(amount);
                    periodData.amount = periodData.amount.add(amount);

                    _userAmountMap[trader] = _userAmountMap[trader].add(amount);
                }
                // for pnl
                if (_startPnlNumber > 0) {
                    if (periodData.periodNumber >= _startPnlNumber) {
                        if (periodData.pnlUsers[trader] >= 0) {
                            if (pnl >= 0) {
                                periodData.pnlAmount = periodData.pnlAmount.add(pnl);
                            } else {
                                int256 newUserAmount = periodData.pnlUsers[trader].add(pnl);
                                if (newUserAmount < 0) {
                                    periodData.pnlAmount = periodData.pnlAmount.sub(periodData.pnlUsers[trader]);
                                } else {
                                    periodData.pnlAmount = periodData.pnlAmount.add(pnl);
                                }
                            }
                        } else {
                            if (pnl >= 0) {
                                int256 newUserAmount = periodData.pnlUsers[trader].add(pnl);
                                if (newUserAmount >= 0) {
                                    periodData.pnlAmount = periodData.pnlAmount.add(newUserAmount);
                                }
                            }
                        }
                        periodData.pnlUsers[trader] = periodData.pnlUsers[trader].add(pnl);
                    }
                }
                emit MintWithPnl(periodData.periodNumber, trader, amount, pnl);
            }
        }
    }

    function _claim(address trader) internal returns (uint256 amount) {
        amount = _getClaimable(trader);
        //
        _spend = _spend.add(amount);
        // transfer reward
        IERC20Upgradeable(_pnftToken).transfer(trader, amount);
        // update last claim period
        _lastClaimPeriodNumberMap[trader] = (_getPeriodNumber() - 1);

        _userSpendMap[trader] = _userSpendMap[trader].add(amount);

        emit Spend(trader, amount);
    }

    function claim() external returns (uint256 amount) {
        return _claim(_msgSender());
    }

    function emergencyWithdraw(uint256 amount) external onlyOwner {
        IERC20Upgradeable(_pnftToken).transfer(_msgSender(), amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

/// @notice For future upgrades, do not change InsuranceFundStorageV1. Create a new
/// contract which implements InsuranceFundStorageV1 and following the naming convention
/// InsuranceFundStorageVX.
abstract contract RewardMinerStorage {
    // --------- IMMUTABLE ---------

    struct PeriodConfig {
        uint256 start;
        uint256 end;
        uint256 total;
    }

    struct PeriodData {
        uint256 periodNumber;
        mapping(address => uint256) users;
        uint256 amount;
        uint256 total;
        mapping(address => int256) pnlUsers;
        int256 pnlAmount;
    }
    //
    address internal _clearingHouse;
    address internal _pnftToken;
    uint256 internal _start;
    uint256 internal _periodDuration;
    uint256 internal _limitClaimPeriod;
    PeriodConfig[] public _periodConfigs;
    //
    mapping(uint256 => PeriodData) public _periodDataMap;
    uint256[] public _periodNumbers;
    uint256 internal _allocation;
    uint256 internal _spend;
    mapping(address => uint256) public _lastClaimPeriodNumberMap;
    mapping(address => uint256) public _userAmountMap;
    mapping(address => uint256) public _userSpendMap;

    address[10] private __gap1;

    uint256 internal _startPnlNumber;
    uint256 internal _pnlRatio;

    uint256[8] private __gap2;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import { BlockContext } from "../../../base/BlockContext.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

contract CumulativeTwap is BlockContext {
    using SafeMath for uint256;

    //
    // STRUCT
    //
    struct Observation {
        uint256 price;
        uint256 priceCumulative;
        uint256 timestamp;
    }

    //
    // EVENT
    //
    event PriceUpdated(uint256 price, uint256 timestamp, uint8 indexAt);

    //
    // STATE
    //
    // let's use 15 mins and 1 hr twap as example
    // if the price is being updated 15 secs, then needs 60 and 240 historical data for 15mins and 1hr twap.
    Observation[256] public observations;

    uint8 public currentObservationIndex;

    function _update(uint256 price, uint256 lastUpdatedTimestamp) internal {
        // for the first time update
        if (currentObservationIndex == 0 && observations[0].timestamp == 0) {
            observations[0] = Observation({ price: price, priceCumulative: 0, timestamp: lastUpdatedTimestamp });
            emit PriceUpdated(price, lastUpdatedTimestamp, 0);
            return;
        }

        // CT_IT: invalid timestamp
        Observation memory lastObservation = observations[currentObservationIndex];
        require(lastUpdatedTimestamp > lastObservation.timestamp, "CT_IT");

        // overflow of currentObservationIndex is desired since currentObservationIndex is uint8 (0 - 255),
        // so 255 + 1 will be 0
        currentObservationIndex++;

        uint256 elapsedTime = lastUpdatedTimestamp - lastObservation.timestamp;
        observations[currentObservationIndex] = Observation({
            priceCumulative: lastObservation.priceCumulative + (lastObservation.price * elapsedTime),
            timestamp: lastUpdatedTimestamp,
            price: price
        });

        emit PriceUpdated(price, lastUpdatedTimestamp, currentObservationIndex);
    }

    function _calculateTwapPrice(
        uint256 interval,
        uint256 latestPrice,
        uint256 latestUpdatedTimestamp
    ) internal view returns (uint256) {
        Observation memory latestObservation = observations[currentObservationIndex];
        if (latestObservation.price == 0) {
            // CT_ND: no data
            revert("CT_ND");
        }

        uint256 currentTimestamp = _blockTimestamp();
        uint256 targetTimestamp = currentTimestamp.sub(interval);
        (Observation memory beforeOrAt, Observation memory atOrAfter) = _getSurroundingObservations(targetTimestamp);
        uint256 currentCumulativePrice =
            latestObservation.priceCumulative.add(
                (latestObservation.price.mul(latestUpdatedTimestamp.sub(latestObservation.timestamp))).add(
                    latestPrice.mul(currentTimestamp.sub(latestUpdatedTimestamp))
                )
            );

        //
        //                   beforeOrAt                    atOrAfter
        //      ------------------+-------------+---------------+------------------
        //                <-------|             |               |
        // case 1       targetTimestamp         |               |------->
        // case 2                               |              targetTimestamp
        // case 3                          targetTimestamp
        //
        uint256 targetCumulativePrice;
        // case1. not enough historical data or just enough (`==` case)
        if (targetTimestamp <= beforeOrAt.timestamp) {
            targetTimestamp = beforeOrAt.timestamp;
            targetCumulativePrice = beforeOrAt.priceCumulative;
        }
        // case2. the latest data is older than or equal the request
        else if (atOrAfter.timestamp <= targetTimestamp) {
            targetTimestamp = atOrAfter.timestamp;
            targetCumulativePrice = atOrAfter.priceCumulative;
        }
        // case3. in the middle
        else {
            uint256 observationTimeDelta = atOrAfter.timestamp - beforeOrAt.timestamp;
            uint256 targetTimeDelta = targetTimestamp - beforeOrAt.timestamp;
            targetCumulativePrice = beforeOrAt.priceCumulative.add(
                ((atOrAfter.priceCumulative.sub(beforeOrAt.priceCumulative)).mul(targetTimeDelta)).div(
                    observationTimeDelta
                )
            );
        }

        return currentCumulativePrice.sub(targetCumulativePrice).div(currentTimestamp - targetTimestamp);
    }

    function _getSurroundingObservations(uint256 targetTimestamp)
        internal
        view
        returns (Observation memory beforeOrAt, Observation memory atOrAfter)
    {
        uint8 index = currentObservationIndex;
        uint8 beforeOrAtIndex;
        uint8 atOrAfterIndex;

        // run at most 256 times
        uint256 observationLen = observations.length;
        uint256 i;
        for (i = 0; i < observationLen; i++) {
            if (observations[index].timestamp <= targetTimestamp) {
                // if the next observation is empty, using the last one
                // it implies the historical data is not enough
                if (observations[index].timestamp == 0) {
                    atOrAfterIndex = beforeOrAtIndex = index + 1;
                    break;
                }
                beforeOrAtIndex = index;
                atOrAfterIndex = beforeOrAtIndex + 1;
                break;
            }
            index--;
        }

        // not enough historical data to query
        if (i == observationLen) {
            // CT_NEH: no enough historical data
            revert("CT_NEH");
        }

        beforeOrAt = observations[beforeOrAtIndex];
        atOrAfter = observations[atOrAfterIndex];

        // if timestamp of the right bound is earlier than timestamp of the left bound,
        // it means the left bound is the lastest observation.
        // It implies the latest observation is older than requested
        // Then we set the right bound to the left bound.
        if (atOrAfter.timestamp < beforeOrAt.timestamp) {
            atOrAfter = beforeOrAt;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import { CumulativeTwap } from "./CumulativeTwap.sol";

abstract contract CachedTwap is CumulativeTwap {
    uint256 internal _cachedTwap;
    uint160 internal _lastUpdatedAt;
    uint80 internal _interval;

    constructor(uint80 interval) {
        _interval = interval;
    }

    function _cacheTwap(
        uint256 interval,
        uint256 latestPrice,
        uint256 latestUpdatedTimestamp
    ) internal virtual returns (uint256) {
        // if requested interval is not the same as the one we have cached, then call _getPrice() directly
        if (_interval != interval) {
            return _calculateTwapPrice(interval, latestPrice, latestUpdatedTimestamp);
        }

        // if twap has been calculated in this block, then return cached value directly
        if (_blockTimestamp() == _lastUpdatedAt) {
            return _cachedTwap;
        }

        _update(latestPrice, latestUpdatedTimestamp);
        _lastUpdatedAt = uint160(_blockTimestamp());
        _cachedTwap = _calculateTwapPrice(interval, latestPrice, latestUpdatedTimestamp);

        return _cachedTwap;
    }

    function _getCachedTwap(
        uint256 interval,
        uint256 latestPrice,
        uint256 latestUpdatedTimestamp
    ) internal view returns (uint256) {
        if (_blockTimestamp() == _lastUpdatedAt && interval == _interval) {
            return _cachedTwap;
        }
        return _calculateTwapPrice(interval, latestPrice, latestUpdatedTimestamp);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import { IChainlinkPriceFeed } from "./interface/IChainlinkPriceFeed.sol";
import { IPriceFeedV2 } from "../../oracle/interface/IPriceFeedV2.sol";
import { BlockContext } from "../../base/BlockContext.sol";
import { CachedTwap } from "./twap/CachedTwap.sol";

contract ChainlinkPriceFeedV2 is IChainlinkPriceFeed, IPriceFeedV2, BlockContext, CachedTwap {
    using Address for address;

    AggregatorV3Interface private immutable _aggregator;

    constructor(AggregatorV3Interface aggregator, uint80 cacheTwapInterval) CachedTwap(cacheTwapInterval) {
        // CPF_ANC: Aggregator address is not contract
        require(address(aggregator).isContract(), "CPF_ANC");

        _aggregator = aggregator;
    }

    /// @dev anyone can help update it.
    function update() external {
        (, uint256 latestPrice, uint256 latestTimestamp) = _getLatestRoundData();
        _update(latestPrice, latestTimestamp);
    }

    function cacheTwap(uint256 interval) external override returns (uint256) {
        (uint80 round, uint256 latestPrice, uint256 latestTimestamp) = _getLatestRoundData();

        if (interval == 0 || round == 0) {
            return latestPrice;
        }
        return _cacheTwap(interval, latestPrice, latestTimestamp);
    }

    function decimals() external view override returns (uint8) {
        return _aggregator.decimals();
    }

    function getAggregator() external view override returns (address) {
        return address(_aggregator);
    }

    function getRoundData(uint80 roundId) external view override returns (uint256, uint256) {
        // NOTE: aggregator will revert if roundId is invalid (but there might not be a revert message sometimes)
        // will return (roundId, 0, 0, 0, roundId) if round is not complete (not existed yet)
        // https://docs.chain.link/docs/historical-price-data/
        (, int256 price, , uint256 updatedAt, ) = _aggregator.getRoundData(roundId);

        // CPF_IP: Invalid Price
        require(price > 0, "CPF_IP");

        // CPF_RINC: Round Is Not Complete
        require(updatedAt > 0, "CPF_RINC");

        return (uint256(price), updatedAt);
    }

    function getPrice(uint256 interval) external view override returns (uint256) {
        (uint80 round, uint256 latestPrice, uint256 latestTimestamp) = _getLatestRoundData();

        if (interval == 0 || round == 0) {
            return latestPrice;
        }

        return _getCachedTwap(interval, latestPrice, latestTimestamp);
    }

    function _getLatestRoundData()
        private
        view
        returns (
            uint80,
            uint256 finalPrice,
            uint256
        )
    {
        (uint80 round, int256 latestPrice, , uint256 latestTimestamp, ) = _aggregator.latestRoundData();
        finalPrice = uint256(latestPrice);
        if (latestPrice < 0) {
            _requireEnoughHistory(round);
            (round, finalPrice, latestTimestamp) = _getRoundData(round - 1);
        }
        return (round, finalPrice, latestTimestamp);
    }

    function _getRoundData(uint80 _round)
        private
        view
        returns (
            uint80,
            uint256,
            uint256
        )
    {
        (uint80 round, int256 latestPrice, , uint256 latestTimestamp, ) = _aggregator.getRoundData(_round);
        while (latestPrice < 0) {
            _requireEnoughHistory(round);
            round = round - 1;
            (, latestPrice, , latestTimestamp, ) = _aggregator.getRoundData(round);
        }
        return (round, uint256(latestPrice), latestTimestamp);
    }

    function _requireEnoughHistory(uint80 _round) private pure {
        // CPF_NEH: no enough history
        require(_round > 0, "CPF_NEH");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

interface IChainlinkPriceFeed {
    function getAggregator() external view returns (address);

    /// @param roundId The roundId that fed into Chainlink aggregator.
    function getRoundData(uint80 roundId) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import "./IPriceFeed.sol";

interface IPriceFeedV2 is IPriceFeed {
    /// @dev Returns the cached index price of the token.
    /// @param interval The interval represents twap interval.
    function cacheTwap(uint256 interval) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

interface IPriceFeed {
    function decimals() external view returns (uint8);

    /// @dev Returns the index price of the token.
    /// @param interval The interval represents twap interval.
    function getPrice(uint256 interval) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IPriceFeedV2 } from "./interface/IPriceFeedV2.sol";
import { BlockContext } from "../base/BlockContext.sol";

contract NftPriceFeed is IPriceFeedV2, Ownable, BlockContext {
    using Address for address;

    address public priceFeedAdmin;
    string public symbol = "";
    uint256 public latestPrice = 0;

    event FeedAdminUpdated(address indexed admin);
    event PriceUpdated(uint256 price);

    constructor(string memory symbolArg) {
        symbol = symbolArg;
        priceFeedAdmin = msg.sender;
    }

    modifier onlyAdmin() {
        // NPF_NA: Not admin
        require(msg.sender == priceFeedAdmin, "NPF_NA");
        _;
    }

    function setPriceFeedAdmin(address _admin) external onlyOwner {
        priceFeedAdmin = _admin;
        emit FeedAdminUpdated(_admin);
    }

    function cacheTwap(uint256 interval) external override returns (uint256) {
        return 0;
    }

    function decimals() external view override returns (uint8) {
        return 18;
    }

    function setPrice(uint256 priceArg) external onlyAdmin {
        require(priceArg > 0, "NPF_IP");
        latestPrice = priceArg;
        emit PriceUpdated(priceArg);
    }

    function getPrice(uint256 interval) external view override returns (uint256) {
        // NPF_IP: invalid price
        require(latestPrice > 0, "NPF_IP");
        return latestPrice;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../access/Ownable.sol";
import "./TransparentUpgradeableProxy.sol";

/**
 * @dev This is an auxiliary contract meant to be assigned as the admin of a {TransparentUpgradeableProxy}. For an
 * explanation of why you would want to use this see the documentation for {TransparentUpgradeableProxy}.
 */
contract ProxyAdmin is Ownable {

    /**
     * @dev Returns the current implementation of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyImplementation(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("implementation()")) == 0x5c60da1b
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"5c60da1b");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Returns the current admin of `proxy`.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function getProxyAdmin(TransparentUpgradeableProxy proxy) public view virtual returns (address) {
        // We need to manually run the static call since the getter cannot be flagged as view
        // bytes4(keccak256("admin()")) == 0xf851a440
        (bool success, bytes memory returndata) = address(proxy).staticcall(hex"f851a440");
        require(success);
        return abi.decode(returndata, (address));
    }

    /**
     * @dev Changes the admin of `proxy` to `newAdmin`.
     *
     * Requirements:
     *
     * - This contract must be the current admin of `proxy`.
     */
    function changeProxyAdmin(TransparentUpgradeableProxy proxy, address newAdmin) public virtual onlyOwner {
        proxy.changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrades `proxy` to `implementation`. See {TransparentUpgradeableProxy-upgradeTo}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgrade(TransparentUpgradeableProxy proxy, address implementation) public virtual onlyOwner {
        proxy.upgradeTo(implementation);
    }

    /**
     * @dev Upgrades `proxy` to `implementation` and calls a function on the new implementation. See
     * {TransparentUpgradeableProxy-upgradeToAndCall}.
     *
     * Requirements:
     *
     * - This contract must be the admin of `proxy`.
     */
    function upgradeAndCall(TransparentUpgradeableProxy proxy, address implementation, bytes memory data) public payable virtual onlyOwner {
        proxy.upgradeToAndCall{value: msg.value}(implementation, data);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external virtual ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual ifAdmin {
        _upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol';

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@openzeppelin/contracts/proxy/ProxyAdmin.sol';

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import { SafeMathUpgradeable } from "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import { IPriceFeedV2 } from "./oracle/interface/IPriceFeedV2.sol";
import { IIndexPrice } from "./interface/IIndexPrice.sol";
import { VirtualToken } from "./VirtualToken.sol";
import { BaseTokenStorageV2 } from "./storage/BaseTokenStorage.sol";
import { IBaseToken } from "./interface/IBaseToken.sol";
import { BlockContext } from "./base/BlockContext.sol";

// never inherit any new stateful contract. never change the orders of parent stateful contracts
contract BaseToken is IBaseToken, IIndexPrice, VirtualToken, BlockContext, BaseTokenStorageV2 {
    using SafeMathUpgradeable for uint256;
    using SafeMathUpgradeable for uint8;

    //
    // CONSTANT
    //

    uint256 internal constant _TWAP_INTERVAL_FOR_PAUSE = 15 * 60; // 15 minutes
    uint256 internal constant _MAX_WAITING_PERIOD = 5 days;

    //
    // EXTERNAL NON-VIEW
    //

    function initialize(
        string memory nameArg,
        string memory symbolArg,
        address priceFeedArg
    ) external initializer {
        __VirtualToken_init(nameArg, symbolArg);

        uint8 priceFeedDecimals = IPriceFeedV2(priceFeedArg).decimals();

        // invalid price feed decimals
        require(priceFeedDecimals <= decimals(), "BT_IPFD");

        _priceFeed = priceFeedArg;
        _priceFeedDecimals = priceFeedDecimals;
    }

    function pause() external onlyOwner {
        // BT_NO: Not open
        require(_status == IBaseToken.Status.Open, "BT_NO");
        _pausedIndexPrice = getIndexPrice(_TWAP_INTERVAL_FOR_PAUSE);
        _status = IBaseToken.Status.Paused;
        _pausedTimestamp = _blockTimestamp();
        emit StatusUpdated(_status);
    }

    function close(uint256 closedPrice) external onlyOwner {
        // BT_NP: Not paused
        require(_status == IBaseToken.Status.Paused, "BT_NP");
        _close(closedPrice);
    }

    function close() external override {
        // BT_NP: Not paused
        require(_status == IBaseToken.Status.Paused, "BT_NP");
        // BT_WPNE: Waiting period not expired
        require(_blockTimestamp() > _pausedTimestamp + _MAX_WAITING_PERIOD, "BT_WPNE");
        _close(_pausedIndexPrice);
    }

    function setPriceFeed(address priceFeedArg) external onlyOwner {
        // ChainlinkPriceFeed uses 8 decimals
        // BandPriceFeed uses 18 decimals
        uint8 priceFeedDecimals = IPriceFeedV2(priceFeedArg).decimals();
        // BT_IPFD: Invalid price feed decimals
        require(priceFeedDecimals <= decimals(), "BT_IPFD");

        _priceFeed = priceFeedArg;
        _priceFeedDecimals = priceFeedDecimals;

        emit PriceFeedChanged(_priceFeed);
    }

    function cacheTwap(uint256 interval) external override {
        IPriceFeedV2(_priceFeed).cacheTwap(interval);
    }

    //
    // INTERNAL NON-VIEW
    //

    function _close(uint256 closedPrice) internal {
        _status = IBaseToken.Status.Closed;
        _closedPrice = closedPrice;
        emit StatusUpdated(_status);
    }

    //
    // EXTERNAL VIEW
    //

    /// @inheritdoc IBaseToken
    function getPriceFeed() external view override returns (address) {
        return _priceFeed;
    }

    function isOpen() external view override returns (bool) {
        return _status == IBaseToken.Status.Open;
    }

    function isPaused() external view override returns (bool) {
        return _status == IBaseToken.Status.Paused;
    }

    function isClosed() external view override returns (bool) {
        return _status == IBaseToken.Status.Closed;
    }

    function getPausedTimestamp() external view override returns (uint256) {
        return _pausedTimestamp;
    }

    function getPausedIndexPrice() external view override returns (uint256) {
        return _pausedIndexPrice;
    }

    /// @inheritdoc IBaseToken
    function getClosedPrice() external view override returns (uint256) {
        // not closed
        require(_status == IBaseToken.Status.Closed, "BT_NC");
        return _closedPrice;
    }

    //
    // PUBLIC VIEW
    //

    /// @inheritdoc IIndexPrice
    /// @dev we overwrite the index price in BaseToken depending on the status
    ///      1. Open: the price is from the price feed
    ///      2. Paused or Closed: the price is twap when the token was paused
    function getIndexPrice(uint256 interval) public view override returns (uint256) {
        if (_status == IBaseToken.Status.Open) {
            return _formatDecimals(IPriceFeedV2(_priceFeed).getPrice(interval));
        }

        return _pausedIndexPrice;
    }

    //
    // INTERNAL VIEW
    //

    function _formatDecimals(uint256 _price) internal view returns (uint256) {
        return _price.mul(10**(decimals().sub(_priceFeedDecimals)));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import { IBaseToken } from "../interface/IBaseToken.sol";

/// @notice For future upgrades, do not change BaseTokenStorageV1. Create a new
/// contract which implements BaseTokenStorageV1 and following the naming convention
/// BaseTokenStorageVX.
abstract contract BaseTokenStorageV1 {
    // --------- IMMUTABLE ---------

    uint8 internal _priceFeedDecimals;

    // --------- ^^^^^^^^^ ---------

    address internal _priceFeed;

    address[10] private __gap1;
    uint256[10] private __gap2;
}

abstract contract BaseTokenStorageV2 is BaseTokenStorageV1 {
    IBaseToken.Status internal _status;

    uint256 internal _pausedIndexPrice;

    uint256 internal _pausedTimestamp;

    uint256 internal _closedPrice;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract TestAggregatorV3 is AggregatorV3Interface {
    function decimals() external view override returns (uint8) {
        return 8;
    }

    function description() external view override returns (string memory) {
        revert();
    }

    function version() external view override returns (uint256) {
        revert();
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        revert();
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        revert();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import { PerpMath } from "../lib/PerpMath.sol";

contract TestPerpMath {
    using PerpMath for uint160;
    using PerpMath for uint256;
    using PerpMath for int256;

    function testFormatSqrtPriceX96ToPriceX96(uint160 value) external pure returns (uint256) {
        return value.formatSqrtPriceX96ToPriceX96();
    }

    function testFormatX10_18ToX96(uint256 value) external pure returns (uint256) {
        return value.formatX10_18ToX96();
    }

    function testFormatX96ToX10_18(uint256 value) external pure returns (uint256) {
        return value.formatX96ToX10_18();
    }

    function testMax(int256 a, int256 b) external pure returns (int256) {
        return PerpMath.max(a, b);
    }

    function testMin(int256 a, int256 b) external pure returns (int256) {
        return PerpMath.min(a, b);
    }

    function testAbs(int256 value) external pure returns (uint256) {
        return value.abs();
    }

    function testDivBy10_18(int256 value) external pure returns (int256) {
        return value.divBy10_18();
    }

    function testDivBy10_18(uint256 value) external pure returns (uint256) {
        return value.divBy10_18();
    }

    function testMulRatio(uint256 value, uint24 ratio) external pure returns (uint256) {
        return value.mulRatio(ratio);
    }

    function testMulRatio(int256 value, uint24 ratio) external pure returns (int256) {
        return value.mulRatio(ratio);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { PerpSafeCast } from "../lib/PerpSafeCast.sol";

contract TestPerpSafeCast {
    using PerpSafeCast for uint256;
    using PerpSafeCast for int256;

    // uint test

    // int256 to uin256
    function testToUint256(int256 value) external pure returns (uint256) {
        return value.toUint256();
    }

    function testToUint128(uint256 value) external pure returns (uint128) {
        return value.toUint128();
    }

    function testToUint64(uint256 value) external pure returns (uint64) {
        return value.toUint64();
    }

    function testToUint32(uint256 value) external pure returns (uint32) {
        return value.toUint32();
    }

    // int24 to uint24
    function testToUint24(int256 value) external pure returns (uint24) {
        return value.toUint24();
    }

    function testToUint16(uint256 value) external pure returns (uint16) {
        return value.toUint16();
    }

    function testToUint8(uint256 value) external pure returns (uint8) {
        return value.toUint8();
    }

    // int test

    // uint256 to int256
    function testToInt256(uint256 value) external pure returns (int256) {
        return value.toInt256();
    }

    function testToInt128(int256 value) external pure returns (int128) {
        return value.toInt128();
    }

    function testToInt64(int256 value) external pure returns (int64) {
        return value.toInt64();
    }

    function testToInt32(int256 value) external pure returns (int32) {
        return value.toInt32();
    }

    function testToInt24(int256 value) external pure returns (int24) {
        return value.toInt24();
    }

    function testToInt16(int256 value) external pure returns (int16) {
        return value.toInt16();
    }

    function testToInt8(int256 value) external pure returns (int8) {
        return value.toInt8();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import './FullMath.sol';
import './FixedPoint128.sol';
import './LiquidityMath.sol';

/// @title Position
/// @notice Positions represent an owner address' liquidity between a lower and upper tick boundary
/// @dev Positions store additional state for tracking fees owed to the position
library Position {
    // info stored for each user's position
    struct Info {
        // the amount of liquidity owned by this position
        uint128 liquidity;
        // fee growth per unit of liquidity as of the last update to liquidity or fees owed
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
        // the fees owed to the position owner in token0/token1
        uint128 tokensOwed0;
        uint128 tokensOwed1;
    }

    /// @notice Returns the Info struct of a position, given an owner and position boundaries
    /// @param self The mapping containing all user positions
    /// @param owner The address of the position owner
    /// @param tickLower The lower tick boundary of the position
    /// @param tickUpper The upper tick boundary of the position
    /// @return position The position info struct of the given owners' position
    function get(
        mapping(bytes32 => Info) storage self,
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (Position.Info storage position) {
        position = self[keccak256(abi.encodePacked(owner, tickLower, tickUpper))];
    }

    /// @notice Credits accumulated fees to a user's position
    /// @param self The individual position to update
    /// @param liquidityDelta The change in pool liquidity as a result of the position update
    /// @param feeGrowthInside0X128 The all-time fee growth in token0, per unit of liquidity, inside the position's tick boundaries
    /// @param feeGrowthInside1X128 The all-time fee growth in token1, per unit of liquidity, inside the position's tick boundaries
    function update(
        Info storage self,
        int128 liquidityDelta,
        uint256 feeGrowthInside0X128,
        uint256 feeGrowthInside1X128
    ) internal {
        Info memory _self = self;

        uint128 liquidityNext;
        if (liquidityDelta == 0) {
            require(_self.liquidity > 0, 'NP'); // disallow pokes for 0 liquidity positions
            liquidityNext = _self.liquidity;
        } else {
            liquidityNext = LiquidityMath.addDelta(_self.liquidity, liquidityDelta);
        }

        // calculate accumulated fees
        uint128 tokensOwed0 =
            uint128(
                FullMath.mulDiv(
                    feeGrowthInside0X128 - _self.feeGrowthInside0LastX128,
                    _self.liquidity,
                    FixedPoint128.Q128
                )
            );
        uint128 tokensOwed1 =
            uint128(
                FullMath.mulDiv(
                    feeGrowthInside1X128 - _self.feeGrowthInside1LastX128,
                    _self.liquidity,
                    FixedPoint128.Q128
                )
            );

        // update the position
        if (liquidityDelta != 0) self.liquidity = liquidityNext;
        self.feeGrowthInside0LastX128 = feeGrowthInside0X128;
        self.feeGrowthInside1LastX128 = feeGrowthInside1X128;
        if (tokensOwed0 > 0 || tokensOwed1 > 0) {
            // overflow is acceptable, have to withdraw before you hit type(uint128).max fees
            self.tokensOwed0 += tokensOwed0;
            self.tokensOwed1 += tokensOwed1;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import './LowGasSafeMath.sol';
import './SafeCast.sol';

import './TickMath.sol';
import './LiquidityMath.sol';

/// @title Tick
/// @notice Contains functions for managing tick processes and relevant calculations
library Tick {
    using LowGasSafeMath for int256;
    using SafeCast for int256;

    // info stored for each initialized individual tick
    struct Info {
        // the total position liquidity that references this tick
        uint128 liquidityGross;
        // amount of net liquidity added (subtracted) when tick is crossed from left to right (right to left),
        int128 liquidityNet;
        // fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;
        // the cumulative tick value on the other side of the tick
        int56 tickCumulativeOutside;
        // the seconds per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint160 secondsPerLiquidityOutsideX128;
        // the seconds spent on the other side of the tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint32 secondsOutside;
        // true iff the tick is initialized, i.e. the value is exactly equivalent to the expression liquidityGross != 0
        // these 8 bits are set to prevent fresh sstores when crossing newly initialized ticks
        bool initialized;
    }

    /// @notice Derives max liquidity per tick from given tick spacing
    /// @dev Executed within the pool constructor
    /// @param tickSpacing The amount of required tick separation, realized in multiples of `tickSpacing`
    ///     e.g., a tickSpacing of 3 requires ticks to be initialized every 3rd tick i.e., ..., -6, -3, 0, 3, 6, ...
    /// @return The max liquidity per tick
    function tickSpacingToMaxLiquidityPerTick(int24 tickSpacing) internal pure returns (uint128) {
        int24 minTick = (TickMath.MIN_TICK / tickSpacing) * tickSpacing;
        int24 maxTick = (TickMath.MAX_TICK / tickSpacing) * tickSpacing;
        uint24 numTicks = uint24((maxTick - minTick) / tickSpacing) + 1;
        return type(uint128).max / numTicks;
    }

    /// @notice Retrieves fee growth data
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tickLower The lower tick boundary of the position
    /// @param tickUpper The upper tick boundary of the position
    /// @param tickCurrent The current tick
    /// @param feeGrowthGlobal0X128 The all-time global fee growth, per unit of liquidity, in token0
    /// @param feeGrowthGlobal1X128 The all-time global fee growth, per unit of liquidity, in token1
    /// @return feeGrowthInside0X128 The all-time fee growth in token0, per unit of liquidity, inside the position's tick boundaries
    /// @return feeGrowthInside1X128 The all-time fee growth in token1, per unit of liquidity, inside the position's tick boundaries
    function getFeeGrowthInside(
        mapping(int24 => Tick.Info) storage self,
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128
    ) internal view returns (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) {
        Info storage lower = self[tickLower];
        Info storage upper = self[tickUpper];

        // calculate fee growth below
        uint256 feeGrowthBelow0X128;
        uint256 feeGrowthBelow1X128;
        if (tickCurrent >= tickLower) {
            feeGrowthBelow0X128 = lower.feeGrowthOutside0X128;
            feeGrowthBelow1X128 = lower.feeGrowthOutside1X128;
        } else {
            feeGrowthBelow0X128 = feeGrowthGlobal0X128 - lower.feeGrowthOutside0X128;
            feeGrowthBelow1X128 = feeGrowthGlobal1X128 - lower.feeGrowthOutside1X128;
        }

        // calculate fee growth above
        uint256 feeGrowthAbove0X128;
        uint256 feeGrowthAbove1X128;
        if (tickCurrent < tickUpper) {
            feeGrowthAbove0X128 = upper.feeGrowthOutside0X128;
            feeGrowthAbove1X128 = upper.feeGrowthOutside1X128;
        } else {
            feeGrowthAbove0X128 = feeGrowthGlobal0X128 - upper.feeGrowthOutside0X128;
            feeGrowthAbove1X128 = feeGrowthGlobal1X128 - upper.feeGrowthOutside1X128;
        }

        feeGrowthInside0X128 = feeGrowthGlobal0X128 - feeGrowthBelow0X128 - feeGrowthAbove0X128;
        feeGrowthInside1X128 = feeGrowthGlobal1X128 - feeGrowthBelow1X128 - feeGrowthAbove1X128;
    }

    /// @notice Updates a tick and returns true if the tick was flipped from initialized to uninitialized, or vice versa
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The tick that will be updated
    /// @param tickCurrent The current tick
    /// @param liquidityDelta A new amount of liquidity to be added (subtracted) when tick is crossed from left to right (right to left)
    /// @param feeGrowthGlobal0X128 The all-time global fee growth, per unit of liquidity, in token0
    /// @param feeGrowthGlobal1X128 The all-time global fee growth, per unit of liquidity, in token1
    /// @param secondsPerLiquidityCumulativeX128 The all-time seconds per max(1, liquidity) of the pool
    /// @param time The current block timestamp cast to a uint32
    /// @param upper true for updating a position's upper tick, or false for updating a position's lower tick
    /// @param maxLiquidity The maximum liquidity allocation for a single tick
    /// @return flipped Whether the tick was flipped from initialized to uninitialized, or vice versa
    function update(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        int24 tickCurrent,
        int128 liquidityDelta,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128,
        uint160 secondsPerLiquidityCumulativeX128,
        int56 tickCumulative,
        uint32 time,
        bool upper,
        uint128 maxLiquidity
    ) internal returns (bool flipped) {
        Tick.Info storage info = self[tick];

        uint128 liquidityGrossBefore = info.liquidityGross;
        uint128 liquidityGrossAfter = LiquidityMath.addDelta(liquidityGrossBefore, liquidityDelta);

        require(liquidityGrossAfter <= maxLiquidity, 'LO');

        flipped = (liquidityGrossAfter == 0) != (liquidityGrossBefore == 0);

        if (liquidityGrossBefore == 0) {
            // by convention, we assume that all growth before a tick was initialized happened _below_ the tick
            if (tick <= tickCurrent) {
                info.feeGrowthOutside0X128 = feeGrowthGlobal0X128;
                info.feeGrowthOutside1X128 = feeGrowthGlobal1X128;
                info.secondsPerLiquidityOutsideX128 = secondsPerLiquidityCumulativeX128;
                info.tickCumulativeOutside = tickCumulative;
                info.secondsOutside = time;
            }
            info.initialized = true;
        }

        info.liquidityGross = liquidityGrossAfter;

        // when the lower (upper) tick is crossed left to right (right to left), liquidity must be added (removed)
        info.liquidityNet = upper
            ? int256(info.liquidityNet).sub(liquidityDelta).toInt128()
            : int256(info.liquidityNet).add(liquidityDelta).toInt128();
    }

    /// @notice Clears tick data
    /// @param self The mapping containing all initialized tick information for initialized ticks
    /// @param tick The tick that will be cleared
    function clear(mapping(int24 => Tick.Info) storage self, int24 tick) internal {
        delete self[tick];
    }

    /// @notice Transitions to next tick as needed by price movement
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The destination tick of the transition
    /// @param feeGrowthGlobal0X128 The all-time global fee growth, per unit of liquidity, in token0
    /// @param feeGrowthGlobal1X128 The all-time global fee growth, per unit of liquidity, in token1
    /// @param secondsPerLiquidityCumulativeX128 The current seconds per liquidity
    /// @param time The current block.timestamp
    /// @return liquidityNet The amount of liquidity added (subtracted) when tick is crossed from left to right (right to left)
    function cross(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128,
        uint160 secondsPerLiquidityCumulativeX128,
        int56 tickCumulative,
        uint32 time
    ) internal returns (int128 liquidityNet) {
        Tick.Info storage info = self[tick];
        info.feeGrowthOutside0X128 = feeGrowthGlobal0X128 - info.feeGrowthOutside0X128;
        info.feeGrowthOutside1X128 = feeGrowthGlobal1X128 - info.feeGrowthOutside1X128;
        info.secondsPerLiquidityOutsideX128 = secondsPerLiquidityCumulativeX128 - info.secondsPerLiquidityOutsideX128;
        info.tickCumulativeOutside = tickCumulative - info.tickCumulativeOutside;
        info.secondsOutside = time - info.secondsOutside;
        liquidityNet = info.liquidityNet;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './interfaces/IUniswapV3Pool.sol';

import './NoDelegateCall.sol';

import './libraries/LowGasSafeMath.sol';
import './libraries/SafeCast.sol';
import './libraries/Tick.sol';
import './libraries/TickBitmap.sol';
import './libraries/Position.sol';
import './libraries/Oracle.sol';

import './libraries/FullMath.sol';
import './libraries/FixedPoint128.sol';
import './libraries/TransferHelper.sol';
import './libraries/TickMath.sol';
import './libraries/LiquidityMath.sol';
import './libraries/SqrtPriceMath.sol';
import './libraries/SwapMath.sol';

import './interfaces/IUniswapV3PoolDeployer.sol';
import './interfaces/IUniswapV3Factory.sol';
import './interfaces/IERC20Minimal.sol';
import './interfaces/callback/IUniswapV3MintCallback.sol';
import './interfaces/callback/IUniswapV3SwapCallback.sol';
import './interfaces/callback/IUniswapV3FlashCallback.sol';

contract UniswapV3Pool is IUniswapV3Pool, NoDelegateCall {
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;
    using SafeCast for uint256;
    using SafeCast for int256;
    using Tick for mapping(int24 => Tick.Info);
    using TickBitmap for mapping(int16 => uint256);
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;
    using Oracle for Oracle.Observation[65535];

    /// @inheritdoc IUniswapV3PoolImmutables
    address public immutable override factory;
    /// @inheritdoc IUniswapV3PoolImmutables
    address public immutable override token0;
    /// @inheritdoc IUniswapV3PoolImmutables
    address public immutable override token1;
    /// @inheritdoc IUniswapV3PoolImmutables
    uint24 public immutable override fee;

    /// @inheritdoc IUniswapV3PoolImmutables
    int24 public immutable override tickSpacing;

    /// @inheritdoc IUniswapV3PoolImmutables
    uint128 public immutable override maxLiquidityPerTick;

    struct Slot0 {
        // the current price
        uint160 sqrtPriceX96;
        // the current tick
        int24 tick;
        // the most-recently updated index of the observations array
        uint16 observationIndex;
        // the current maximum number of observations that are being stored
        uint16 observationCardinality;
        // the next maximum number of observations to store, triggered in observations.write
        uint16 observationCardinalityNext;
        // the current protocol fee as a percentage of the swap fee taken on withdrawal
        // represented as an integer denominator (1/x)%
        uint8 feeProtocol;
        // whether the pool is locked
        bool unlocked;
    }
    /// @inheritdoc IUniswapV3PoolState
    Slot0 public override slot0;

    /// @inheritdoc IUniswapV3PoolState
    uint256 public override feeGrowthGlobal0X128;
    /// @inheritdoc IUniswapV3PoolState
    uint256 public override feeGrowthGlobal1X128;

    // accumulated protocol fees in token0/token1 units
    struct ProtocolFees {
        uint128 token0;
        uint128 token1;
    }
    /// @inheritdoc IUniswapV3PoolState
    ProtocolFees public override protocolFees;

    /// @inheritdoc IUniswapV3PoolState
    uint128 public override liquidity;

    /// @inheritdoc IUniswapV3PoolState
    mapping(int24 => Tick.Info) public override ticks;
    /// @inheritdoc IUniswapV3PoolState
    mapping(int16 => uint256) public override tickBitmap;
    /// @inheritdoc IUniswapV3PoolState
    mapping(bytes32 => Position.Info) public override positions;
    /// @inheritdoc IUniswapV3PoolState
    Oracle.Observation[65535] public override observations;

    /// @dev Mutually exclusive reentrancy protection into the pool to/from a method. This method also prevents entrance
    /// to a function before the pool is initialized. The reentrancy guard is required throughout the contract because
    /// we use balance checks to determine the payment status of interactions such as mint, swap and flash.
    modifier lock() {
        require(slot0.unlocked, 'LOK');
        slot0.unlocked = false;
        _;
        slot0.unlocked = true;
    }

    /// @dev Prevents calling a function from anyone except the address returned by IUniswapV3Factory#owner()
    modifier onlyFactoryOwner() {
        require(msg.sender == IUniswapV3Factory(factory).owner());
        _;
    }

    constructor() {
        int24 _tickSpacing;
        (factory, token0, token1, fee, _tickSpacing) = IUniswapV3PoolDeployer(msg.sender).parameters();
        tickSpacing = _tickSpacing;

        maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(_tickSpacing);
    }

    /// @dev Common checks for valid tick inputs.
    function checkTicks(int24 tickLower, int24 tickUpper) private pure {
        require(tickLower < tickUpper, 'TLU');
        require(tickLower >= TickMath.MIN_TICK, 'TLM');
        require(tickUpper <= TickMath.MAX_TICK, 'TUM');
    }

    /// @dev Returns the block timestamp truncated to 32 bits, i.e. mod 2**32. This method is overridden in tests.
    function _blockTimestamp() internal view virtual returns (uint32) {
        return uint32(block.timestamp); // truncation is desired
    }

    /// @dev Get the pool's balance of token0
    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    /// check
    function balance0() private view returns (uint256) {
        (bool success, bytes memory data) =
            token0.staticcall(abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this)));
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    /// @dev Get the pool's balance of token1
    /// @dev This function is gas optimized to avoid a redundant extcodesize check in addition to the returndatasize
    /// check
    function balance1() private view returns (uint256) {
        (bool success, bytes memory data) =
            token1.staticcall(abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this)));
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    /// @inheritdoc IUniswapV3PoolDerivedState
    function snapshotCumulativesInside(int24 tickLower, int24 tickUpper)
        external
        view
        override
        noDelegateCall
        returns (
            int56 tickCumulativeInside,
            uint160 secondsPerLiquidityInsideX128,
            uint32 secondsInside
        )
    {
        checkTicks(tickLower, tickUpper);

        int56 tickCumulativeLower;
        int56 tickCumulativeUpper;
        uint160 secondsPerLiquidityOutsideLowerX128;
        uint160 secondsPerLiquidityOutsideUpperX128;
        uint32 secondsOutsideLower;
        uint32 secondsOutsideUpper;

        {
            Tick.Info storage lower = ticks[tickLower];
            Tick.Info storage upper = ticks[tickUpper];
            bool initializedLower;
            (tickCumulativeLower, secondsPerLiquidityOutsideLowerX128, secondsOutsideLower, initializedLower) = (
                lower.tickCumulativeOutside,
                lower.secondsPerLiquidityOutsideX128,
                lower.secondsOutside,
                lower.initialized
            );
            require(initializedLower);

            bool initializedUpper;
            (tickCumulativeUpper, secondsPerLiquidityOutsideUpperX128, secondsOutsideUpper, initializedUpper) = (
                upper.tickCumulativeOutside,
                upper.secondsPerLiquidityOutsideX128,
                upper.secondsOutside,
                upper.initialized
            );
            require(initializedUpper);
        }

        Slot0 memory _slot0 = slot0;

        if (_slot0.tick < tickLower) {
            return (
                tickCumulativeLower - tickCumulativeUpper,
                secondsPerLiquidityOutsideLowerX128 - secondsPerLiquidityOutsideUpperX128,
                secondsOutsideLower - secondsOutsideUpper
            );
        } else if (_slot0.tick < tickUpper) {
            uint32 time = _blockTimestamp();
            (int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128) =
                observations.observeSingle(
                    time,
                    0,
                    _slot0.tick,
                    _slot0.observationIndex,
                    liquidity,
                    _slot0.observationCardinality
                );
            return (
                tickCumulative - tickCumulativeLower - tickCumulativeUpper,
                secondsPerLiquidityCumulativeX128 -
                    secondsPerLiquidityOutsideLowerX128 -
                    secondsPerLiquidityOutsideUpperX128,
                time - secondsOutsideLower - secondsOutsideUpper
            );
        } else {
            return (
                tickCumulativeUpper - tickCumulativeLower,
                secondsPerLiquidityOutsideUpperX128 - secondsPerLiquidityOutsideLowerX128,
                secondsOutsideUpper - secondsOutsideLower
            );
        }
    }

    /// @inheritdoc IUniswapV3PoolDerivedState
    function observe(uint32[] calldata secondsAgos)
        external
        view
        override
        noDelegateCall
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s)
    {
        return
            observations.observe(
                _blockTimestamp(),
                secondsAgos,
                slot0.tick,
                slot0.observationIndex,
                liquidity,
                slot0.observationCardinality
            );
    }

    /// @inheritdoc IUniswapV3PoolActions
    function increaseObservationCardinalityNext(uint16 observationCardinalityNext)
        external
        override
        lock
        noDelegateCall
    {
        uint16 observationCardinalityNextOld = slot0.observationCardinalityNext; // for the event
        uint16 observationCardinalityNextNew =
            observations.grow(observationCardinalityNextOld, observationCardinalityNext);
        slot0.observationCardinalityNext = observationCardinalityNextNew;
        if (observationCardinalityNextOld != observationCardinalityNextNew)
            emit IncreaseObservationCardinalityNext(observationCardinalityNextOld, observationCardinalityNextNew);
    }

    /// @inheritdoc IUniswapV3PoolActions
    /// @dev not locked because it initializes unlocked
    function initialize(uint160 sqrtPriceX96) external override {
        require(slot0.sqrtPriceX96 == 0, 'AI');

        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

        (uint16 cardinality, uint16 cardinalityNext) = observations.initialize(_blockTimestamp());

        slot0 = Slot0({
            sqrtPriceX96: sqrtPriceX96,
            tick: tick,
            observationIndex: 0,
            observationCardinality: cardinality,
            observationCardinalityNext: cardinalityNext,
            feeProtocol: 0,
            unlocked: true
        });

        emit Initialize(sqrtPriceX96, tick);
    }

    struct ModifyPositionParams {
        // the address that owns the position
        address owner;
        // the lower and upper tick of the position
        int24 tickLower;
        int24 tickUpper;
        // any change in liquidity
        int128 liquidityDelta;
    }

    /// @dev Effect some changes to a position
    /// @param params the position details and the change to the position's liquidity to effect
    /// @return position a storage pointer referencing the position with the given owner and tick range
    /// @return amount0 the amount of token0 owed to the pool, negative if the pool should pay the recipient
    /// @return amount1 the amount of token1 owed to the pool, negative if the pool should pay the recipient
    function _modifyPosition(ModifyPositionParams memory params)
        private
        noDelegateCall
        returns (
            Position.Info storage position,
            int256 amount0,
            int256 amount1
        )
    {
        checkTicks(params.tickLower, params.tickUpper);

        Slot0 memory _slot0 = slot0; // SLOAD for gas optimization

        position = _updatePosition(
            params.owner,
            params.tickLower,
            params.tickUpper,
            params.liquidityDelta,
            _slot0.tick
        );

        if (params.liquidityDelta != 0) {
            if (_slot0.tick < params.tickLower) {
                // current tick is below the passed range; liquidity can only become in range by crossing from left to
                // right, when we'll need _more_ token0 (it's becoming more valuable) so user must provide it
                amount0 = SqrtPriceMath.getAmount0Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    params.liquidityDelta
                );
            } else if (_slot0.tick < params.tickUpper) {
                // current tick is inside the passed range
                uint128 liquidityBefore = liquidity; // SLOAD for gas optimization

                // write an oracle entry
                (slot0.observationIndex, slot0.observationCardinality) = observations.write(
                    _slot0.observationIndex,
                    _blockTimestamp(),
                    _slot0.tick,
                    liquidityBefore,
                    _slot0.observationCardinality,
                    _slot0.observationCardinalityNext
                );

                amount0 = SqrtPriceMath.getAmount0Delta(
                    _slot0.sqrtPriceX96,
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    params.liquidityDelta
                );
                amount1 = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    _slot0.sqrtPriceX96,
                    params.liquidityDelta
                );

                liquidity = LiquidityMath.addDelta(liquidityBefore, params.liquidityDelta);
            } else {
                // current tick is above the passed range; liquidity can only become in range by crossing from right to
                // left, when we'll need _more_ token1 (it's becoming more valuable) so user must provide it
                amount1 = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    params.liquidityDelta
                );
            }
        }
    }

    /// @dev Gets and updates a position with the given liquidity delta
    /// @param owner the owner of the position
    /// @param tickLower the lower tick of the position's tick range
    /// @param tickUpper the upper tick of the position's tick range
    /// @param tick the current tick, passed to avoid sloads
    function _updatePosition(
        address owner,
        int24 tickLower,
        int24 tickUpper,
        int128 liquidityDelta,
        int24 tick
    ) private returns (Position.Info storage position) {
        position = positions.get(owner, tickLower, tickUpper);

        uint256 _feeGrowthGlobal0X128 = feeGrowthGlobal0X128; // SLOAD for gas optimization
        uint256 _feeGrowthGlobal1X128 = feeGrowthGlobal1X128; // SLOAD for gas optimization

        // if we need to update the ticks, do it
        bool flippedLower;
        bool flippedUpper;
        if (liquidityDelta != 0) {
            uint32 time = _blockTimestamp();
            (int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128) =
                observations.observeSingle(
                    time,
                    0,
                    slot0.tick,
                    slot0.observationIndex,
                    liquidity,
                    slot0.observationCardinality
                );

            flippedLower = ticks.update(
                tickLower,
                tick,
                liquidityDelta,
                _feeGrowthGlobal0X128,
                _feeGrowthGlobal1X128,
                secondsPerLiquidityCumulativeX128,
                tickCumulative,
                time,
                false,
                maxLiquidityPerTick
            );
            flippedUpper = ticks.update(
                tickUpper,
                tick,
                liquidityDelta,
                _feeGrowthGlobal0X128,
                _feeGrowthGlobal1X128,
                secondsPerLiquidityCumulativeX128,
                tickCumulative,
                time,
                true,
                maxLiquidityPerTick
            );

            if (flippedLower) {
                tickBitmap.flipTick(tickLower, tickSpacing);
            }
            if (flippedUpper) {
                tickBitmap.flipTick(tickUpper, tickSpacing);
            }
        }

        (uint256 feeGrowthInside0X128, uint256 feeGrowthInside1X128) =
            ticks.getFeeGrowthInside(tickLower, tickUpper, tick, _feeGrowthGlobal0X128, _feeGrowthGlobal1X128);

        position.update(liquidityDelta, feeGrowthInside0X128, feeGrowthInside1X128);

        // clear any tick data that is no longer needed
        if (liquidityDelta < 0) {
            if (flippedLower) {
                ticks.clear(tickLower);
            }
            if (flippedUpper) {
                ticks.clear(tickUpper);
            }
        }
    }

    /// @inheritdoc IUniswapV3PoolActions
    /// @dev noDelegateCall is applied indirectly via _modifyPosition
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount,
        bytes calldata data
    ) external override lock returns (uint256 amount0, uint256 amount1) {
        require(amount > 0);
        (, int256 amount0Int, int256 amount1Int) =
            _modifyPosition(
                ModifyPositionParams({
                    owner: recipient,
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    liquidityDelta: int256(amount).toInt128()
                })
            );

        amount0 = uint256(amount0Int);
        amount1 = uint256(amount1Int);

        uint256 balance0Before;
        uint256 balance1Before;
        if (amount0 > 0) balance0Before = balance0();
        if (amount1 > 0) balance1Before = balance1();
        IUniswapV3MintCallback(msg.sender).uniswapV3MintCallback(amount0, amount1, data);
        if (amount0 > 0) require(balance0Before.add(amount0) <= balance0(), 'M0');
        if (amount1 > 0) require(balance1Before.add(amount1) <= balance1(), 'M1');

        emit Mint(msg.sender, recipient, tickLower, tickUpper, amount, amount0, amount1);
    }

    /// @inheritdoc IUniswapV3PoolActions
    function collect(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external override lock returns (uint128 amount0, uint128 amount1) {
        // we don't need to checkTicks here, because invalid positions will never have non-zero tokensOwed{0,1}
        Position.Info storage position = positions.get(msg.sender, tickLower, tickUpper);

        amount0 = amount0Requested > position.tokensOwed0 ? position.tokensOwed0 : amount0Requested;
        amount1 = amount1Requested > position.tokensOwed1 ? position.tokensOwed1 : amount1Requested;

        if (amount0 > 0) {
            position.tokensOwed0 -= amount0;
            TransferHelper.safeTransfer(token0, recipient, amount0);
        }
        if (amount1 > 0) {
            position.tokensOwed1 -= amount1;
            TransferHelper.safeTransfer(token1, recipient, amount1);
        }

        emit Collect(msg.sender, recipient, tickLower, tickUpper, amount0, amount1);
    }

    /// @inheritdoc IUniswapV3PoolActions
    /// @dev noDelegateCall is applied indirectly via _modifyPosition
    function burn(
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external override lock returns (uint256 amount0, uint256 amount1) {
        (Position.Info storage position, int256 amount0Int, int256 amount1Int) =
            _modifyPosition(
                ModifyPositionParams({
                    owner: msg.sender,
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    liquidityDelta: -int256(amount).toInt128()
                })
            );

        amount0 = uint256(-amount0Int);
        amount1 = uint256(-amount1Int);

        if (amount0 > 0 || amount1 > 0) {
            (position.tokensOwed0, position.tokensOwed1) = (
                position.tokensOwed0 + uint128(amount0),
                position.tokensOwed1 + uint128(amount1)
            );
        }

        emit Burn(msg.sender, tickLower, tickUpper, amount, amount0, amount1);
    }

    struct SwapCache {
        // the protocol fee for the input token
        uint8 feeProtocol;
        // liquidity at the beginning of the swap
        uint128 liquidityStart;
        // the timestamp of the current block
        uint32 blockTimestamp;
        // the current value of the tick accumulator, computed only if we cross an initialized tick
        int56 tickCumulative;
        // the current value of seconds per liquidity accumulator, computed only if we cross an initialized tick
        uint160 secondsPerLiquidityCumulativeX128;
        // whether we've computed and cached the above two accumulators
        bool computedLatestObservation;
    }

    // the top level state of the swap, the results of which are recorded in storage at the end
    struct SwapState {
        // the amount remaining to be swapped in/out of the input/output asset
        int256 amountSpecifiedRemaining;
        // the amount already swapped out/in of the output/input asset
        int256 amountCalculated;
        // current sqrt(price)
        uint160 sqrtPriceX96;
        // the tick associated with the current price
        int24 tick;
        // the global fee growth of the input token
        uint256 feeGrowthGlobalX128;
        // amount of input token paid as protocol fee
        uint128 protocolFee;
        // the current liquidity in range
        uint128 liquidity;
    }

    struct StepComputations {
        // the price at the beginning of the step
        uint160 sqrtPriceStartX96;
        // the next tick to swap to from the current tick in the swap direction
        int24 tickNext;
        // whether tickNext is initialized or not
        bool initialized;
        // sqrt(price) for the next tick (1/0)
        uint160 sqrtPriceNextX96;
        // how much is being swapped in in this step
        uint256 amountIn;
        // how much is being swapped out
        uint256 amountOut;
        // how much fee is being paid in
        uint256 feeAmount;
    }

    /// @inheritdoc IUniswapV3PoolActions
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external override noDelegateCall returns (int256 amount0, int256 amount1) {
        require(amountSpecified != 0, 'AS');

        Slot0 memory slot0Start = slot0;

        require(slot0Start.unlocked, 'LOK');
        require(
            zeroForOne
                ? sqrtPriceLimitX96 < slot0Start.sqrtPriceX96 && sqrtPriceLimitX96 > TickMath.MIN_SQRT_RATIO
                : sqrtPriceLimitX96 > slot0Start.sqrtPriceX96 && sqrtPriceLimitX96 < TickMath.MAX_SQRT_RATIO,
            'SPL'
        );

        slot0.unlocked = false;

        SwapCache memory cache =
            SwapCache({
                liquidityStart: liquidity,
                blockTimestamp: _blockTimestamp(),
                feeProtocol: zeroForOne ? (slot0Start.feeProtocol % 16) : (slot0Start.feeProtocol >> 4),
                secondsPerLiquidityCumulativeX128: 0,
                tickCumulative: 0,
                computedLatestObservation: false
            });

        bool exactInput = amountSpecified > 0;

        SwapState memory state =
            SwapState({
                amountSpecifiedRemaining: amountSpecified,
                amountCalculated: 0,
                sqrtPriceX96: slot0Start.sqrtPriceX96,
                tick: slot0Start.tick,
                feeGrowthGlobalX128: zeroForOne ? feeGrowthGlobal0X128 : feeGrowthGlobal1X128,
                protocolFee: 0,
                liquidity: cache.liquidityStart
            });

        // continue swapping as long as we haven't used the entire input/output and haven't reached the price limit
        while (state.amountSpecifiedRemaining != 0 && state.sqrtPriceX96 != sqrtPriceLimitX96) {
            StepComputations memory step;

            step.sqrtPriceStartX96 = state.sqrtPriceX96;

            (step.tickNext, step.initialized) = tickBitmap.nextInitializedTickWithinOneWord(
                state.tick,
                tickSpacing,
                zeroForOne
            );

            // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
            if (step.tickNext < TickMath.MIN_TICK) {
                step.tickNext = TickMath.MIN_TICK;
            } else if (step.tickNext > TickMath.MAX_TICK) {
                step.tickNext = TickMath.MAX_TICK;
            }

            // get the price for the next tick
            step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

            // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
            (state.sqrtPriceX96, step.amountIn, step.amountOut, step.feeAmount) = SwapMath.computeSwapStep(
                state.sqrtPriceX96,
                (zeroForOne ? step.sqrtPriceNextX96 < sqrtPriceLimitX96 : step.sqrtPriceNextX96 > sqrtPriceLimitX96)
                    ? sqrtPriceLimitX96
                    : step.sqrtPriceNextX96,
                state.liquidity,
                state.amountSpecifiedRemaining,
                fee
            );

            if (exactInput) {
                state.amountSpecifiedRemaining -= (step.amountIn + step.feeAmount).toInt256();
                state.amountCalculated = state.amountCalculated.sub(step.amountOut.toInt256());
            } else {
                state.amountSpecifiedRemaining += step.amountOut.toInt256();
                state.amountCalculated = state.amountCalculated.add((step.amountIn + step.feeAmount).toInt256());
            }

            // if the protocol fee is on, calculate how much is owed, decrement feeAmount, and increment protocolFee
            if (cache.feeProtocol > 0) {
                uint256 delta = step.feeAmount / cache.feeProtocol;
                step.feeAmount -= delta;
                state.protocolFee += uint128(delta);
            }

            // update global fee tracker
            if (state.liquidity > 0)
                state.feeGrowthGlobalX128 += FullMath.mulDiv(step.feeAmount, FixedPoint128.Q128, state.liquidity);

            // shift tick if we reached the next price
            if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
                // if the tick is initialized, run the tick transition
                if (step.initialized) {
                    // check for the placeholder value, which we replace with the actual value the first time the swap
                    // crosses an initialized tick
                    if (!cache.computedLatestObservation) {
                        (cache.tickCumulative, cache.secondsPerLiquidityCumulativeX128) = observations.observeSingle(
                            cache.blockTimestamp,
                            0,
                            slot0Start.tick,
                            slot0Start.observationIndex,
                            cache.liquidityStart,
                            slot0Start.observationCardinality
                        );
                        cache.computedLatestObservation = true;
                    }
                    int128 liquidityNet =
                        ticks.cross(
                            step.tickNext,
                            (zeroForOne ? state.feeGrowthGlobalX128 : feeGrowthGlobal0X128),
                            (zeroForOne ? feeGrowthGlobal1X128 : state.feeGrowthGlobalX128),
                            cache.secondsPerLiquidityCumulativeX128,
                            cache.tickCumulative,
                            cache.blockTimestamp
                        );
                    // if we're moving leftward, we interpret liquidityNet as the opposite sign
                    // safe because liquidityNet cannot be type(int128).min
                    if (zeroForOne) liquidityNet = -liquidityNet;

                    state.liquidity = LiquidityMath.addDelta(state.liquidity, liquidityNet);
                }

                state.tick = zeroForOne ? step.tickNext - 1 : step.tickNext;
            } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
                // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
                state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
            }
        }

        // update tick and write an oracle entry if the tick change
        if (state.tick != slot0Start.tick) {
            (uint16 observationIndex, uint16 observationCardinality) =
                observations.write(
                    slot0Start.observationIndex,
                    cache.blockTimestamp,
                    slot0Start.tick,
                    cache.liquidityStart,
                    slot0Start.observationCardinality,
                    slot0Start.observationCardinalityNext
                );
            (slot0.sqrtPriceX96, slot0.tick, slot0.observationIndex, slot0.observationCardinality) = (
                state.sqrtPriceX96,
                state.tick,
                observationIndex,
                observationCardinality
            );
        } else {
            // otherwise just update the price
            slot0.sqrtPriceX96 = state.sqrtPriceX96;
        }

        // update liquidity if it changed
        if (cache.liquidityStart != state.liquidity) liquidity = state.liquidity;

        // update fee growth global and, if necessary, protocol fees
        // overflow is acceptable, protocol has to withdraw before it hits type(uint128).max fees
        if (zeroForOne) {
            feeGrowthGlobal0X128 = state.feeGrowthGlobalX128;
            if (state.protocolFee > 0) protocolFees.token0 += state.protocolFee;
        } else {
            feeGrowthGlobal1X128 = state.feeGrowthGlobalX128;
            if (state.protocolFee > 0) protocolFees.token1 += state.protocolFee;
        }

        (amount0, amount1) = zeroForOne == exactInput
            ? (amountSpecified - state.amountSpecifiedRemaining, state.amountCalculated)
            : (state.amountCalculated, amountSpecified - state.amountSpecifiedRemaining);

        // do the transfers and collect payment
        if (zeroForOne) {
            if (amount1 < 0) TransferHelper.safeTransfer(token1, recipient, uint256(-amount1));

            uint256 balance0Before = balance0();
            IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(amount0, amount1, data);
            require(balance0Before.add(uint256(amount0)) <= balance0(), 'IIA');
        } else {
            if (amount0 < 0) TransferHelper.safeTransfer(token0, recipient, uint256(-amount0));

            uint256 balance1Before = balance1();
            IUniswapV3SwapCallback(msg.sender).uniswapV3SwapCallback(amount0, amount1, data);
            require(balance1Before.add(uint256(amount1)) <= balance1(), 'IIA');
        }

        emit Swap(msg.sender, recipient, amount0, amount1, state.sqrtPriceX96, state.liquidity, state.tick);
        slot0.unlocked = true;
    }

    /// @inheritdoc IUniswapV3PoolActions
    function flash(
        address recipient,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external override lock noDelegateCall {
        uint128 _liquidity = liquidity;
        require(_liquidity > 0, 'L');

        uint256 fee0 = FullMath.mulDivRoundingUp(amount0, fee, 1e6);
        uint256 fee1 = FullMath.mulDivRoundingUp(amount1, fee, 1e6);
        uint256 balance0Before = balance0();
        uint256 balance1Before = balance1();

        if (amount0 > 0) TransferHelper.safeTransfer(token0, recipient, amount0);
        if (amount1 > 0) TransferHelper.safeTransfer(token1, recipient, amount1);

        IUniswapV3FlashCallback(msg.sender).uniswapV3FlashCallback(fee0, fee1, data);

        uint256 balance0After = balance0();
        uint256 balance1After = balance1();

        require(balance0Before.add(fee0) <= balance0After, 'F0');
        require(balance1Before.add(fee1) <= balance1After, 'F1');

        // sub is safe because we know balanceAfter is gt balanceBefore by at least fee
        uint256 paid0 = balance0After - balance0Before;
        uint256 paid1 = balance1After - balance1Before;

        if (paid0 > 0) {
            uint8 feeProtocol0 = slot0.feeProtocol % 16;
            uint256 fees0 = feeProtocol0 == 0 ? 0 : paid0 / feeProtocol0;
            if (uint128(fees0) > 0) protocolFees.token0 += uint128(fees0);
            feeGrowthGlobal0X128 += FullMath.mulDiv(paid0 - fees0, FixedPoint128.Q128, _liquidity);
        }
        if (paid1 > 0) {
            uint8 feeProtocol1 = slot0.feeProtocol >> 4;
            uint256 fees1 = feeProtocol1 == 0 ? 0 : paid1 / feeProtocol1;
            if (uint128(fees1) > 0) protocolFees.token1 += uint128(fees1);
            feeGrowthGlobal1X128 += FullMath.mulDiv(paid1 - fees1, FixedPoint128.Q128, _liquidity);
        }

        emit Flash(msg.sender, recipient, amount0, amount1, paid0, paid1);
    }

    /// @inheritdoc IUniswapV3PoolOwnerActions
    function setFeeProtocol(uint8 feeProtocol0, uint8 feeProtocol1) external override lock onlyFactoryOwner {
        require(
            (feeProtocol0 == 0 || (feeProtocol0 >= 4 && feeProtocol0 <= 10)) &&
                (feeProtocol1 == 0 || (feeProtocol1 >= 4 && feeProtocol1 <= 10))
        );
        uint8 feeProtocolOld = slot0.feeProtocol;
        slot0.feeProtocol = feeProtocol0 + (feeProtocol1 << 4);
        emit SetFeeProtocol(feeProtocolOld % 16, feeProtocolOld >> 4, feeProtocol0, feeProtocol1);
    }

    /// @inheritdoc IUniswapV3PoolOwnerActions
    function collectProtocol(
        address recipient,
        uint128 amount0Requested,
        uint128 amount1Requested
    ) external override lock onlyFactoryOwner returns (uint128 amount0, uint128 amount1) {
        amount0 = amount0Requested > protocolFees.token0 ? protocolFees.token0 : amount0Requested;
        amount1 = amount1Requested > protocolFees.token1 ? protocolFees.token1 : amount1Requested;

        if (amount0 > 0) {
            if (amount0 == protocolFees.token0) amount0--; // ensure that the slot is not cleared, for gas savings
            protocolFees.token0 -= amount0;
            TransferHelper.safeTransfer(token0, recipient, amount0);
        }
        if (amount1 > 0) {
            if (amount1 == protocolFees.token1) amount1--; // ensure that the slot is not cleared, for gas savings
            protocolFees.token1 -= amount1;
            TransferHelper.safeTransfer(token1, recipient, amount1);
        }

        emit CollectProtocol(msg.sender, recipient, amount0, amount1);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

/// @title Prevents delegatecall to a contract
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCall {
    /// @dev The original address of this contract
    address private immutable original;

    constructor() {
        // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
        // In other words, this variable won't change when it's checked at runtime.
        original = address(this);
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function checkNotDelegateCall() private view {
        require(address(this) == original);
    }

    /// @notice Prevents delegatecall into the modified method
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

import './BitMath.sol';

/// @title Packed tick initialized state library
/// @notice Stores a packed mapping of tick index to its initialized state
/// @dev The mapping uses int16 for keys since ticks are represented as int24 and there are 256 (2^8) values per word.
library TickBitmap {
    /// @notice Computes the position in the mapping where the initialized bit for a tick lives
    /// @param tick The tick for which to compute the position
    /// @return wordPos The key in the mapping containing the word in which the bit is stored
    /// @return bitPos The bit position in the word where the flag is stored
    function position(int24 tick) private pure returns (int16 wordPos, uint8 bitPos) {
        wordPos = int16(tick >> 8);
        bitPos = uint8(tick % 256);
    }

    /// @notice Flips the initialized state for a given tick from false to true, or vice versa
    /// @param self The mapping in which to flip the tick
    /// @param tick The tick to flip
    /// @param tickSpacing The spacing between usable ticks
    function flipTick(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing
    ) internal {
        require(tick % tickSpacing == 0); // ensure that the tick is spaced
        (int16 wordPos, uint8 bitPos) = position(tick / tickSpacing);
        uint256 mask = 1 << bitPos;
        self[wordPos] ^= mask;
    }

    /// @notice Returns the next initialized tick contained in the same word (or adjacent word) as the tick that is either
    /// to the left (less than or equal to) or right (greater than) of the given tick
    /// @param self The mapping in which to compute the next initialized tick
    /// @param tick The starting tick
    /// @param tickSpacing The spacing between usable ticks
    /// @param lte Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
    /// @return next The next initialized or uninitialized tick up to 256 ticks away from the current tick
    /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) internal view returns (int24 next, bool initialized) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

        if (lte) {
            (int16 wordPos, uint8 bitPos) = position(compressed);
            // all the 1s at or to the right of the current bitPos
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = self[wordPos] & mask;

            // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed - int24(bitPos - BitMath.mostSignificantBit(masked))) * tickSpacing
                : (compressed - int24(bitPos)) * tickSpacing;
        } else {
            // start from the word of the next tick, since the current tick state doesn't matter
            (int16 wordPos, uint8 bitPos) = position(compressed + 1);
            // all the 1s at or to the left of the bitPos
            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = self[wordPos] & mask;

            // if there are no initialized ticks to the left of the current tick, return leftmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed + 1 + int24(BitMath.leastSignificantBit(masked) - bitPos)) * tickSpacing
                : (compressed + 1 + int24(type(uint8).max - bitPos)) * tickSpacing;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.5.0;

/// @title Oracle
/// @notice Provides price and liquidity data useful for a wide variety of system designs
/// @dev Instances of stored oracle data, "observations", are collected in the oracle array
/// Every pool is initialized with an oracle array length of 1. Anyone can pay the SSTOREs to increase the
/// maximum length of the oracle array. New slots will be added when the array is fully populated.
/// Observations are overwritten when the full length of the oracle array is populated.
/// The most recent observation is available, independent of the length of the oracle array, by passing 0 to observe()
library Oracle {
    struct Observation {
        // the block timestamp of the observation
        uint32 blockTimestamp;
        // the tick accumulator, i.e. tick * time elapsed since the pool was first initialized
        int56 tickCumulative;
        // the seconds per liquidity, i.e. seconds elapsed / max(1, liquidity) since the pool was first initialized
        uint160 secondsPerLiquidityCumulativeX128;
        // whether or not the observation is initialized
        bool initialized;
    }

    /// @notice Transforms a previous observation into a new observation, given the passage of time and the current tick and liquidity values
    /// @dev blockTimestamp _must_ be chronologically equal to or greater than last.blockTimestamp, safe for 0 or 1 overflows
    /// @param last The specified observation to be transformed
    /// @param blockTimestamp The timestamp of the new observation
    /// @param tick The active tick at the time of the new observation
    /// @param liquidity The total in-range liquidity at the time of the new observation
    /// @return Observation The newly populated observation
    function transform(
        Observation memory last,
        uint32 blockTimestamp,
        int24 tick,
        uint128 liquidity
    ) private pure returns (Observation memory) {
        uint32 delta = blockTimestamp - last.blockTimestamp;
        return
            Observation({
                blockTimestamp: blockTimestamp,
                tickCumulative: last.tickCumulative + int56(tick) * delta,
                secondsPerLiquidityCumulativeX128: last.secondsPerLiquidityCumulativeX128 +
                    ((uint160(delta) << 128) / (liquidity > 0 ? liquidity : 1)),
                initialized: true
            });
    }

    /// @notice Initialize the oracle array by writing the first slot. Called once for the lifecycle of the observations array
    /// @param self The stored oracle array
    /// @param time The time of the oracle initialization, via block.timestamp truncated to uint32
    /// @return cardinality The number of populated elements in the oracle array
    /// @return cardinalityNext The new length of the oracle array, independent of population
    function initialize(Observation[65535] storage self, uint32 time)
        internal
        returns (uint16 cardinality, uint16 cardinalityNext)
    {
        self[0] = Observation({
            blockTimestamp: time,
            tickCumulative: 0,
            secondsPerLiquidityCumulativeX128: 0,
            initialized: true
        });
        return (1, 1);
    }

    /// @notice Writes an oracle observation to the array
    /// @dev Writable at most once per block. Index represents the most recently written element. cardinality and index must be tracked externally.
    /// If the index is at the end of the allowable array length (according to cardinality), and the next cardinality
    /// is greater than the current one, cardinality may be increased. This restriction is created to preserve ordering.
    /// @param self The stored oracle array
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param blockTimestamp The timestamp of the new observation
    /// @param tick The active tick at the time of the new observation
    /// @param liquidity The total in-range liquidity at the time of the new observation
    /// @param cardinality The number of populated elements in the oracle array
    /// @param cardinalityNext The new length of the oracle array, independent of population
    /// @return indexUpdated The new index of the most recently written element in the oracle array
    /// @return cardinalityUpdated The new cardinality of the oracle array
    function write(
        Observation[65535] storage self,
        uint16 index,
        uint32 blockTimestamp,
        int24 tick,
        uint128 liquidity,
        uint16 cardinality,
        uint16 cardinalityNext
    ) internal returns (uint16 indexUpdated, uint16 cardinalityUpdated) {
        Observation memory last = self[index];

        // early return if we've already written an observation this block
        if (last.blockTimestamp == blockTimestamp) return (index, cardinality);

        // if the conditions are right, we can bump the cardinality
        if (cardinalityNext > cardinality && index == (cardinality - 1)) {
            cardinalityUpdated = cardinalityNext;
        } else {
            cardinalityUpdated = cardinality;
        }

        indexUpdated = (index + 1) % cardinalityUpdated;
        self[indexUpdated] = transform(last, blockTimestamp, tick, liquidity);
    }

    /// @notice Prepares the oracle array to store up to `next` observations
    /// @param self The stored oracle array
    /// @param current The current next cardinality of the oracle array
    /// @param next The proposed next cardinality which will be populated in the oracle array
    /// @return next The next cardinality which will be populated in the oracle array
    function grow(
        Observation[65535] storage self,
        uint16 current,
        uint16 next
    ) internal returns (uint16) {
        require(current > 0, 'I');
        // no-op if the passed next value isn't greater than the current next value
        if (next <= current) return current;
        // store in each slot to prevent fresh SSTOREs in swaps
        // this data will not be used because the initialized boolean is still false
        for (uint16 i = current; i < next; i++) self[i].blockTimestamp = 1;
        return next;
    }

    /// @notice comparator for 32-bit timestamps
    /// @dev safe for 0 or 1 overflows, a and b _must_ be chronologically before or equal to time
    /// @param time A timestamp truncated to 32 bits
    /// @param a A comparison timestamp from which to determine the relative position of `time`
    /// @param b From which to determine the relative position of `time`
    /// @return bool Whether `a` is chronologically <= `b`
    function lte(
        uint32 time,
        uint32 a,
        uint32 b
    ) private pure returns (bool) {
        // if there hasn't been overflow, no need to adjust
        if (a <= time && b <= time) return a <= b;

        uint256 aAdjusted = a > time ? a : a + 2**32;
        uint256 bAdjusted = b > time ? b : b + 2**32;

        return aAdjusted <= bAdjusted;
    }

    /// @notice Fetches the observations beforeOrAt and atOrAfter a target, i.e. where [beforeOrAt, atOrAfter] is satisfied.
    /// The result may be the same observation, or adjacent observations.
    /// @dev The answer must be contained in the array, used when the target is located within the stored observation
    /// boundaries: older than the most recent observation and younger, or the same age as, the oldest observation
    /// @param self The stored oracle array
    /// @param time The current block.timestamp
    /// @param target The timestamp at which the reserved observation should be for
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param cardinality The number of populated elements in the oracle array
    /// @return beforeOrAt The observation recorded before, or at, the target
    /// @return atOrAfter The observation recorded at, or after, the target
    function binarySearch(
        Observation[65535] storage self,
        uint32 time,
        uint32 target,
        uint16 index,
        uint16 cardinality
    ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        uint256 l = (index + 1) % cardinality; // oldest observation
        uint256 r = l + cardinality - 1; // newest observation
        uint256 i;
        while (true) {
            i = (l + r) / 2;

            beforeOrAt = self[i % cardinality];

            // we've landed on an uninitialized tick, keep searching higher (more recently)
            if (!beforeOrAt.initialized) {
                l = i + 1;
                continue;
            }

            atOrAfter = self[(i + 1) % cardinality];

            bool targetAtOrAfter = lte(time, beforeOrAt.blockTimestamp, target);

            // check if we've found the answer!
            if (targetAtOrAfter && lte(time, target, atOrAfter.blockTimestamp)) break;

            if (!targetAtOrAfter) r = i - 1;
            else l = i + 1;
        }
    }

    /// @notice Fetches the observations beforeOrAt and atOrAfter a given target, i.e. where [beforeOrAt, atOrAfter] is satisfied
    /// @dev Assumes there is at least 1 initialized observation.
    /// Used by observeSingle() to compute the counterfactual accumulator values as of a given block timestamp.
    /// @param self The stored oracle array
    /// @param time The current block.timestamp
    /// @param target The timestamp at which the reserved observation should be for
    /// @param tick The active tick at the time of the returned or simulated observation
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param liquidity The total pool liquidity at the time of the call
    /// @param cardinality The number of populated elements in the oracle array
    /// @return beforeOrAt The observation which occurred at, or before, the given timestamp
    /// @return atOrAfter The observation which occurred at, or after, the given timestamp
    function getSurroundingObservations(
        Observation[65535] storage self,
        uint32 time,
        uint32 target,
        int24 tick,
        uint16 index,
        uint128 liquidity,
        uint16 cardinality
    ) private view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        // optimistically set before to the newest observation
        beforeOrAt = self[index];

        // if the target is chronologically at or after the newest observation, we can early return
        if (lte(time, beforeOrAt.blockTimestamp, target)) {
            if (beforeOrAt.blockTimestamp == target) {
                // if newest observation equals target, we're in the same block, so we can ignore atOrAfter
                return (beforeOrAt, atOrAfter);
            } else {
                // otherwise, we need to transform
                return (beforeOrAt, transform(beforeOrAt, target, tick, liquidity));
            }
        }

        // now, set before to the oldest observation
        beforeOrAt = self[(index + 1) % cardinality];
        if (!beforeOrAt.initialized) beforeOrAt = self[0];

        // ensure that the target is chronologically at or after the oldest observation
        require(lte(time, beforeOrAt.blockTimestamp, target), 'OLD');

        // if we've reached this point, we have to binary search
        return binarySearch(self, time, target, index, cardinality);
    }

    /// @dev Reverts if an observation at or before the desired observation timestamp does not exist.
    /// 0 may be passed as `secondsAgo' to return the current cumulative values.
    /// If called with a timestamp falling between two observations, returns the counterfactual accumulator values
    /// at exactly the timestamp between the two observations.
    /// @param self The stored oracle array
    /// @param time The current block timestamp
    /// @param secondsAgo The amount of time to look back, in seconds, at which point to return an observation
    /// @param tick The current tick
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param liquidity The current in-range pool liquidity
    /// @param cardinality The number of populated elements in the oracle array
    /// @return tickCumulative The tick * time elapsed since the pool was first initialized, as of `secondsAgo`
    /// @return secondsPerLiquidityCumulativeX128 The time elapsed / max(1, liquidity) since the pool was first initialized, as of `secondsAgo`
    function observeSingle(
        Observation[65535] storage self,
        uint32 time,
        uint32 secondsAgo,
        int24 tick,
        uint16 index,
        uint128 liquidity,
        uint16 cardinality
    ) internal view returns (int56 tickCumulative, uint160 secondsPerLiquidityCumulativeX128) {
        if (secondsAgo == 0) {
            Observation memory last = self[index];
            if (last.blockTimestamp != time) last = transform(last, time, tick, liquidity);
            return (last.tickCumulative, last.secondsPerLiquidityCumulativeX128);
        }

        uint32 target = time - secondsAgo;

        (Observation memory beforeOrAt, Observation memory atOrAfter) =
            getSurroundingObservations(self, time, target, tick, index, liquidity, cardinality);

        if (target == beforeOrAt.blockTimestamp) {
            // we're at the left boundary
            return (beforeOrAt.tickCumulative, beforeOrAt.secondsPerLiquidityCumulativeX128);
        } else if (target == atOrAfter.blockTimestamp) {
            // we're at the right boundary
            return (atOrAfter.tickCumulative, atOrAfter.secondsPerLiquidityCumulativeX128);
        } else {
            // we're in the middle
            uint32 observationTimeDelta = atOrAfter.blockTimestamp - beforeOrAt.blockTimestamp;
            uint32 targetDelta = target - beforeOrAt.blockTimestamp;
            return (
                beforeOrAt.tickCumulative +
                    ((atOrAfter.tickCumulative - beforeOrAt.tickCumulative) / observationTimeDelta) *
                    targetDelta,
                beforeOrAt.secondsPerLiquidityCumulativeX128 +
                    uint160(
                        (uint256(
                            atOrAfter.secondsPerLiquidityCumulativeX128 - beforeOrAt.secondsPerLiquidityCumulativeX128
                        ) * targetDelta) / observationTimeDelta
                    )
            );
        }
    }

    /// @notice Returns the accumulator values as of each time seconds ago from the given time in the array of `secondsAgos`
    /// @dev Reverts if `secondsAgos` > oldest observation
    /// @param self The stored oracle array
    /// @param time The current block.timestamp
    /// @param secondsAgos Each amount of time to look back, in seconds, at which point to return an observation
    /// @param tick The current tick
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param liquidity The current in-range pool liquidity
    /// @param cardinality The number of populated elements in the oracle array
    /// @return tickCumulatives The tick * time elapsed since the pool was first initialized, as of each `secondsAgo`
    /// @return secondsPerLiquidityCumulativeX128s The cumulative seconds / max(1, liquidity) since the pool was first initialized, as of each `secondsAgo`
    function observe(
        Observation[65535] storage self,
        uint32 time,
        uint32[] memory secondsAgos,
        int24 tick,
        uint16 index,
        uint128 liquidity,
        uint16 cardinality
    ) internal view returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s) {
        require(cardinality > 0, 'I');

        tickCumulatives = new int56[](secondsAgos.length);
        secondsPerLiquidityCumulativeX128s = new uint160[](secondsAgos.length);
        for (uint256 i = 0; i < secondsAgos.length; i++) {
            (tickCumulatives[i], secondsPerLiquidityCumulativeX128s[i]) = observeSingle(
                self,
                time,
                secondsAgos[i],
                tick,
                index,
                liquidity,
                cardinality
            );
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '../interfaces/IERC20Minimal.sol';

/// @title TransferHelper
/// @notice Contains helper methods for interacting with ERC20 tokens that do not consistently return true/false
library TransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Calls transfer on token contract, errors with TF if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20Minimal.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TF');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title An interface for a contract that is capable of deploying Uniswap V3 Pools
/// @notice A contract that constructs a pool must implement this to pass arguments to the pool
/// @dev This is used to avoid having constructor arguments in the pool contract, which results in the init code hash
/// of the pool being constant allowing the CREATE2 address of the pool to be cheaply computed on-chain
interface IUniswapV3PoolDeployer {
    /// @notice Get the parameters to be used in constructing the pool, set transiently during pool creation.
    /// @dev Called by the pool constructor to fetch the parameters of the pool
    /// Returns factory The factory address
    /// Returns token0 The first token of the pool by address sort order
    /// Returns token1 The second token of the pool by address sort order
    /// Returns fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// Returns tickSpacing The minimum number of ticks between initialized ticks
    function parameters()
        external
        view
        returns (
            address factory,
            address token0,
            address token1,
            uint24 fee,
            int24 tickSpacing
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Minimal ERC20 interface for Uniswap
/// @notice Contains a subset of the full ERC20 interface that is used in Uniswap V3
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#flash
/// @notice Any contract that calls IUniswapV3PoolActions#flash must implement this interface
interface IUniswapV3FlashCallback {
    /// @notice Called to `msg.sender` after transferring to the recipient from IUniswapV3Pool#flash.
    /// @dev In the implementation you must repay the pool the tokens sent by flash plus the computed fee amounts.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// @param fee0 The fee amount in token0 due to the pool by the end of the flash
    /// @param fee1 The fee amount in token1 due to the pool by the end of the flash
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#flash call
    function uniswapV3FlashCallback(
        uint256 fee0,
        uint256 fee1,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@uniswap/v3-core/contracts/UniswapV3Pool.sol';

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './interfaces/IUniswapV3Factory.sol';

import './UniswapV3PoolDeployer.sol';
import './NoDelegateCall.sol';

import './UniswapV3Pool.sol';

/// @title Canonical Uniswap V3 factory
/// @notice Deploys Uniswap V3 pools and manages ownership and control over pool protocol fees
contract UniswapV3Factory is IUniswapV3Factory, UniswapV3PoolDeployer, NoDelegateCall {
    /// @inheritdoc IUniswapV3Factory
    address public override owner;

    /// @inheritdoc IUniswapV3Factory
    mapping(uint24 => int24) public override feeAmountTickSpacing;
    /// @inheritdoc IUniswapV3Factory
    mapping(address => mapping(address => mapping(uint24 => address))) public override getPool;

    constructor() {
        owner = msg.sender;
        emit OwnerChanged(address(0), msg.sender);

        feeAmountTickSpacing[500] = 10;
        emit FeeAmountEnabled(500, 10);
        feeAmountTickSpacing[3000] = 60;
        emit FeeAmountEnabled(3000, 60);
        feeAmountTickSpacing[10000] = 200;
        emit FeeAmountEnabled(10000, 200);
    }

    /// @inheritdoc IUniswapV3Factory
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external override noDelegateCall returns (address pool) {
        require(tokenA != tokenB);
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0));
        int24 tickSpacing = feeAmountTickSpacing[fee];
        require(tickSpacing != 0);
        require(getPool[token0][token1][fee] == address(0));
        pool = deploy(address(this), token0, token1, fee, tickSpacing);
        getPool[token0][token1][fee] = pool;
        // populate mapping in the reverse direction, deliberate choice to avoid the cost of comparing addresses
        getPool[token1][token0][fee] = pool;
        emit PoolCreated(token0, token1, fee, tickSpacing, pool);
    }

    /// @inheritdoc IUniswapV3Factory
    function setOwner(address _owner) external override {
        require(msg.sender == owner);
        emit OwnerChanged(owner, _owner);
        owner = _owner;
    }

    /// @inheritdoc IUniswapV3Factory
    function enableFeeAmount(uint24 fee, int24 tickSpacing) public override {
        require(msg.sender == owner);
        require(fee < 1000000);
        // tick spacing is capped at 16384 to prevent the situation where tickSpacing is so large that
        // TickBitmap#nextInitializedTickWithinOneWord overflows int24 container from a valid tick
        // 16384 ticks represents a >5x price change with ticks of 1 bips
        require(tickSpacing > 0 && tickSpacing < 16384);
        require(feeAmountTickSpacing[fee] == 0);

        feeAmountTickSpacing[fee] = tickSpacing;
        emit FeeAmountEnabled(fee, tickSpacing);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

import './interfaces/IUniswapV3PoolDeployer.sol';

import './UniswapV3Pool.sol';

contract UniswapV3PoolDeployer is IUniswapV3PoolDeployer {
    struct Parameters {
        address factory;
        address token0;
        address token1;
        uint24 fee;
        int24 tickSpacing;
    }

    /// @inheritdoc IUniswapV3PoolDeployer
    Parameters public override parameters;

    /// @dev Deploys a pool with the given parameters by transiently setting the parameters storage slot and then
    /// clearing it after deploying the pool.
    /// @param factory The contract address of the Uniswap V3 factory
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The spacing between usable ticks
    function deploy(
        address factory,
        address token0,
        address token1,
        uint24 fee,
        int24 tickSpacing
    ) internal returns (address pool) {
        parameters = Parameters({factory: factory, token0: token0, token1: token1, fee: fee, tickSpacing: tickSpacing});
        pool = address(new UniswapV3Pool{salt: keccak256(abi.encode(token0, token1, fee))}());
        delete parameters;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@uniswap/v3-core/contracts/UniswapV3Factory.sol';

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/presets/ERC20PresetMinterPauserUpgradeable.sol";

contract MockPNFTToken is ERC20PresetMinterPauserUpgradeable {
    function __MockPNFTToken_init(string memory name, string memory symbol, uint8 decimal) public initializer {
        __ERC20PresetMinterPauser_init(name, symbol);
        _setupDecimals(decimal);
    }

    function setMinter(address minter) external {
        grantRole(MINTER_ROLE, minter);
    }

    function adminTransfer(address sender, address recipient, uint256 amount) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "MockPNFTToken: must have minter role to transfer");
        _transfer(sender, recipient, amount);
    }

    function adminBurn(address recipient, uint256 amount) external {
        require(hasRole(MINTER_ROLE, _msgSender()), "MockPNFTToken: must have minter role to transfer");
        _burn(recipient, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import { SafeOwnable } from "./base/SafeOwnable.sol";
import { ClearingHouseConfigStorageV2 } from "./storage/ClearingHouseConfigStorage.sol";
import { IClearingHouseConfig } from "./interface/IClearingHouseConfig.sol";

// never inherit any new stateful contract. never change the orders of parent stateful contracts
contract ClearingHouseConfig is IClearingHouseConfig, SafeOwnable, ClearingHouseConfigStorageV2 {
    //
    // EVENT
    //
    event ImRatioChanged(uint24 imRatio);
    event TwapIntervalChanged(uint256 twapInterval);
    event LiquidationPenaltyRatioChanged(uint24 liquidationPenaltyRatio);
    event PartialCloseRatioChanged(uint24 partialCloseRatio);
    event MaxMarketsPerAccountChanged(uint8 maxMarketsPerAccount);
    event SettlementTokenBalanceCapChanged(uint256 cap);
    event MaxFundingRateChanged(uint24 rate);
    event BackstopLiquidityProviderChanged(address indexed account, bool indexed isProvider);
    event DurationRepegOverPriceSpreadChanged(uint256 duration);

    //
    // MODIFIER
    //

    modifier checkRatio(uint24 ratio) {
        // CHC_RO: ratio overflow
        require(ratio <= 1e6, "CHC_RO");
        _;
    }

    //
    // EXTERNAL NON-VIEW
    //

    function initialize() external initializer {
        __SafeOwnable_init();

        _maxMarketsPerAccount = type(uint8).max;
        _imRatio = 0.2e6; // initial-margin ratio, 20% in decimal 6
        _mmRatio = 0.0625e6; // minimum-margin ratio, 6.25% in decimal 6
        _liquidationPenaltyRatio = 0.025e6; // initial penalty ratio, 2.5% in decimal 6
        _partialCloseRatio = 0.25e6; // partial close ratio, 25% in decimal 6
        _maxFundingRate = 0.1e6; // max funding rate, 10% in decimal 6
        // _twapInterval = 15 minutes;
        _twapInterval = 0;
        _settlementTokenBalanceCap = type(uint256).max;
        _durationRepegOverPriceSpread = 8 hours;
    }

    function setImRatio(uint24 imRatioArg) external checkRatio(imRatioArg) onlyOwner {
        _imRatio = imRatioArg;
        emit ImRatioChanged(imRatioArg);
    }

    function setLiquidationPenaltyRatio(
        uint24 liquidationPenaltyRatioArg
    ) external checkRatio(liquidationPenaltyRatioArg) onlyOwner {
        _liquidationPenaltyRatio = liquidationPenaltyRatioArg;
        emit LiquidationPenaltyRatioChanged(liquidationPenaltyRatioArg);
    }

    function setPartialCloseRatio(uint24 partialCloseRatioArg) external checkRatio(partialCloseRatioArg) onlyOwner {
        // CHC_IPCR: invalid partialCloseRatio
        require(partialCloseRatioArg > 0, "CHC_IPCR");

        _partialCloseRatio = partialCloseRatioArg;
        emit PartialCloseRatioChanged(partialCloseRatioArg);
    }

    function setTwapInterval(uint32 twapIntervalArg) external onlyOwner {
        // CHC_ITI: invalid twapInterval
        require(twapIntervalArg != 0, "CHC_ITI");

        _twapInterval = twapIntervalArg;
        emit TwapIntervalChanged(twapIntervalArg);
    }

    function setMaxMarketsPerAccount(uint8 maxMarketsPerAccountArg) external onlyOwner {
        _maxMarketsPerAccount = maxMarketsPerAccountArg;
        emit MaxMarketsPerAccountChanged(maxMarketsPerAccountArg);
    }

    function setSettlementTokenBalanceCap(uint256 cap) external onlyOwner {
        _settlementTokenBalanceCap = cap;
        emit SettlementTokenBalanceCapChanged(cap);
    }

    function setMaxFundingRate(uint24 rate) external onlyOwner {
        _maxFundingRate = rate;
        emit MaxFundingRateChanged(rate);
    }

    function setBackstopLiquidityProvider(address account, bool isProvider) external onlyOwner {
        _backstopLiquidityProviderMap[account] = isProvider;
        emit BackstopLiquidityProviderChanged(account, isProvider);
    }

    function setDurationRepegOverPriceSpread(uint24 durationRepegOverPriceSpreadArg) external onlyOwner {
        _durationRepegOverPriceSpread = durationRepegOverPriceSpreadArg;
        emit DurationRepegOverPriceSpreadChanged(_durationRepegOverPriceSpread);
    }

    //
    // EXTERNAL VIEW
    //

    /// @inheritdoc IClearingHouseConfig
    function getMaxMarketsPerAccount() external view override returns (uint8) {
        return _maxMarketsPerAccount;
    }

    /// @inheritdoc IClearingHouseConfig
    function getImRatio() external view override returns (uint24) {
        return _imRatio;
    }

    /// @inheritdoc IClearingHouseConfig
    function getMmRatio() external view override returns (uint24) {
        return _mmRatio;
    }

    /// @inheritdoc IClearingHouseConfig
    function getLiquidationPenaltyRatio() external view override returns (uint24) {
        return _liquidationPenaltyRatio;
    }

    /// @inheritdoc IClearingHouseConfig
    function getPartialCloseRatio() external view override returns (uint24) {
        return _partialCloseRatio;
    }

    /// @inheritdoc IClearingHouseConfig
    function getTwapInterval() external view override returns (uint32) {
        return _twapInterval;
    }

    /// @inheritdoc IClearingHouseConfig
    function getSettlementTokenBalanceCap() external view override returns (uint256) {
        return _settlementTokenBalanceCap;
    }

    /// @inheritdoc IClearingHouseConfig
    function getMaxFundingRate() external view override returns (uint24) {
        return _maxFundingRate;
    }

    /// @inheritdoc IClearingHouseConfig
    function isBackstopLiquidityProvider(address account) external view override returns (bool) {
        return _backstopLiquidityProviderMap[account];
    }

    function getDurationRepegOverPriceSpread() external view override returns (uint256 duration) {
        return _durationRepegOverPriceSpread;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

/// @notice For future upgrades, do not change ClearingHouseConfigStorageV1. Create a new
/// contract which implements ClearingHouseConfigStorageV1 and following the naming convention
/// ClearingHouseConfigStorageVX.
abstract contract ClearingHouseConfigStorageV1 {
    uint8 internal _maxMarketsPerAccount;
    uint24 internal _imRatio;
    uint24 internal _mmRatio;
    uint24 internal _liquidationPenaltyRatio;
    uint24 internal _partialCloseRatio;
    uint24 internal _maxFundingRate;
    uint32 internal _twapInterval;
    uint256 internal _settlementTokenBalanceCap;
    uint256 internal _durationRepegOverPriceSpread;

    address[10] private __gap1;
    uint256[10] private __gap2;
}

abstract contract ClearingHouseConfigStorageV2 is ClearingHouseConfigStorageV1 {
    mapping(address => bool) internal _backstopLiquidityProviderMap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import { BaseRelayRecipient } from "../gsn/BaseRelayRecipient.sol";

contract TestMetaTxRecipient is BaseRelayRecipient, Initializable {
    address public pokedBy;

    function __TestMetaTxRecipient_init(address trustedForwarderArg) external initializer {
        _setTrustedForwarder(trustedForwarderArg);
    }

    function poke() external {
        pokedBy = _msgSender();
    }

    // solhint-disable
    function error() external pure {
        revert("MetaTxRecipientMock: Error");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import "../Vault.sol";

contract TestVault is Vault {
}