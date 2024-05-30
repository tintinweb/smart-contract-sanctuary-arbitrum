// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import { IAccessControlManager } from "interfaces/IAccessControlManager.sol";
import { IGetters } from "interfaces/IGetters.sol";

import { LibOracle } from "../libraries/LibOracle.sol";
import { LibGetters } from "../libraries/LibGetters.sol";
import { LibStorage as s } from "../libraries/LibStorage.sol";
import { LibWhitelist } from "../libraries/LibWhitelist.sol";

import "../../utils/Constants.sol";
import "../../utils/Errors.sol";
import "../Storage.sol";

/// @title Getters
/// @author Angle Labs, Inc.
/// @dev There may be duplicates in the info provided by the getters defined here
contract Getters is IGetters {
    /// @inheritdoc IGetters
    function isValidSelector(bytes4 selector) external view returns (bool) {
        return s.diamondStorage().selectorInfo[selector].facetAddress != address(0);
    }

    /// @inheritdoc IGetters
    function accessControlManager() external view returns (IAccessControlManager) {
        return s.diamondStorage().accessControlManager;
    }

    /// @inheritdoc IGetters
    function agToken() external view returns (IAgToken) {
        return s.transmuterStorage().agToken;
    }

    /// @inheritdoc IGetters
    function getCollateralList() external view returns (address[] memory) {
        return s.transmuterStorage().collateralList;
    }

    /// @inheritdoc IGetters
    function getCollateralInfo(address collateral) external view returns (Collateral memory) {
        return s.transmuterStorage().collaterals[collateral];
    }

    /// @inheritdoc IGetters
    function getCollateralDecimals(address collateral) external view returns (uint8) {
        return s.transmuterStorage().collaterals[collateral].decimals;
    }

    /// @inheritdoc IGetters
    function getCollateralMintFees(
        address collateral
    ) external view returns (uint64[] memory xFeeMint, int64[] memory yFeeMint) {
        Collateral storage collatInfo = s.transmuterStorage().collaterals[collateral];
        return (collatInfo.xFeeMint, collatInfo.yFeeMint);
    }

    /// @inheritdoc IGetters
    function getCollateralBurnFees(
        address collateral
    ) external view returns (uint64[] memory xFeeBurn, int64[] memory yFeeBurn) {
        Collateral storage collatInfo = s.transmuterStorage().collaterals[collateral];
        return (collatInfo.xFeeBurn, collatInfo.yFeeBurn);
    }

    /// @inheritdoc IGetters
    function getRedemptionFees()
        external
        view
        returns (uint64[] memory xRedemptionCurve, int64[] memory yRedemptionCurve)
    {
        TransmuterStorage storage ts = s.transmuterStorage();
        return (ts.xRedemptionCurve, ts.yRedemptionCurve);
    }

    /// @inheritdoc IGetters
    /// @dev This function may revert and overflow if the collateral ratio is too big due to a too small
    /// amount of `stablecoinsIssued`. Due to this, it is recommended to initialize the system with a non
    /// negligible amount of `stablecoinsIssued` so DoS attacks on redemptions which use this function
    /// become economically impossible
    function getCollateralRatio() external view returns (uint64 collatRatio, uint256 stablecoinsIssued) {
        TransmuterStorage storage ts = s.transmuterStorage();
        // Reentrant protection
        if (ts.statusReentrant == ENTERED) revert ReentrantCall();

        (collatRatio, stablecoinsIssued, , , ) = LibGetters.getCollateralRatio();
    }

    /// @inheritdoc IGetters
    function getIssuedByCollateral(
        address collateral
    ) external view returns (uint256 stablecoinsFromCollateral, uint256 stablecoinsIssued) {
        TransmuterStorage storage ts = s.transmuterStorage();
        uint256 _normalizer = ts.normalizer;
        return (
            (uint256(ts.collaterals[collateral].normalizedStables) * _normalizer) / BASE_27,
            (uint256(ts.normalizedStables) * _normalizer) / BASE_27
        );
    }

    /// @inheritdoc IGetters
    function getTotalIssued() external view returns (uint256) {
        TransmuterStorage storage ts = s.transmuterStorage();
        return (uint256(ts.normalizedStables) * uint256(ts.normalizer)) / BASE_27;
    }

    /// @inheritdoc IGetters
    function getManagerData(address collateral) external view returns (bool, IERC20[] memory, bytes memory) {
        Collateral storage collatInfo = s.transmuterStorage().collaterals[collateral];
        if (collatInfo.isManaged > 0) {
            return (true, collatInfo.managerData.subCollaterals, collatInfo.managerData.config);
        }
        return (false, new IERC20[](0), "");
    }

    /// @inheritdoc IGetters
    /// @dev This function is not optimized for gas consumption as for instance the `burn` value for collateral
    /// is computed twice: once in `readBurn` and once in `getBurnOracle`
    function getOracleValues(
        address collateral
    ) external view returns (uint256 mint, uint256 burn, uint256 ratio, uint256 minRatio, uint256 redemption) {
        bytes memory oracleConfig = s.transmuterStorage().collaterals[collateral].oracleConfig;
        (burn, ratio) = LibOracle.readBurn(oracleConfig);
        (minRatio, ) = LibOracle.getBurnOracle(collateral, oracleConfig);
        return (LibOracle.readMint(oracleConfig), burn, ratio, minRatio, LibOracle.readRedemption(oracleConfig));
    }

    /// @inheritdoc IGetters
    function getOracle(
        address collateral
    )
        external
        view
        returns (
            OracleReadType oracleType,
            OracleReadType targetType,
            bytes memory oracleData,
            bytes memory targetData,
            bytes memory hyperparameters
        )
    {
        return LibOracle.getOracle(collateral);
    }

    /// @inheritdoc IGetters
    function isPaused(address collateral, ActionType action) external view returns (bool) {
        if (action == ActionType.Mint || action == ActionType.Burn) {
            Collateral storage collatInfo = s.transmuterStorage().collaterals[collateral];
            if (collatInfo.decimals == 0) revert NotCollateral();
            if (action == ActionType.Mint) {
                return collatInfo.isMintLive == 0;
            } else {
                return collatInfo.isBurnLive == 0;
            }
        } else {
            return s.transmuterStorage().isRedemptionLive == 0;
        }
    }

    /// @inheritdoc IGetters
    function isTrusted(address sender) external view returns (bool) {
        return s.transmuterStorage().isTrusted[sender] == 1;
    }

    /// @inheritdoc IGetters
    function isTrustedSeller(address sender) external view returns (bool) {
        return s.transmuterStorage().isSellerTrusted[sender] == 1;
    }

    /// @inheritdoc IGetters
    function isWhitelistedForType(WhitelistType whitelistType, address sender) external view returns (bool) {
        return s.transmuterStorage().isWhitelistedForType[whitelistType][sender] > 0;
    }

    /// @inheritdoc IGetters
    /// @dev This function is non view as it may consult external non view functions from whitelist providers
    function isWhitelistedForCollateral(address collateral, address sender) external returns (bool) {
        Collateral storage collatInfo = s.transmuterStorage().collaterals[collateral];
        return (collatInfo.onlyWhitelisted == 0 || LibWhitelist.checkWhitelist(collatInfo.whitelistData, sender));
    }

    /// @inheritdoc IGetters
    function isWhitelistedCollateral(address collateral) external view returns (bool) {
        return s.transmuterStorage().collaterals[collateral].onlyWhitelisted == 1;
    }

    /// @inheritdoc IGetters
    function getCollateralWhitelistData(address collateral) external view returns (bytes memory) {
        return s.transmuterStorage().collaterals[collateral].whitelistData;
    }

    /// @inheritdoc IGetters
    function getStablecoinCap(address collateral) external view returns (uint256) {
        return s.transmuterStorage().collaterals[collateral].stablecoinCap;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

/// @title IAccessControlManager
/// @author Angle Labs, Inc.
interface IAccessControlManager {
    /// @notice Checks whether an address is governor of the Angle Protocol or not
    /// @param admin Address to check
    /// @return Whether the address has the `GOVERNOR_ROLE` or not
    function isGovernor(address admin) external view returns (bool);

    /// @notice Checks whether an address is governor or a guardian of the Angle Protocol or not
    /// @param admin Address to check
    /// @return Whether the address has the `GUARDIAN_ROLE` or not
    /// @dev Governance should make sure when adding a governor to also give this governor the guardian
    /// role by calling the `addGovernor` function
    function isGovernorOrGuardian(address admin) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import { IAccessControlManager } from "interfaces/IAccessControlManager.sol";
import { IAgToken } from "interfaces/IAgToken.sol";

import "../transmuter/Storage.sol";

/// @title IGetters
/// @author Angle Labs, Inc.
interface IGetters {
    /// @notice Checks whether a given `selector` is actually a valid selector corresponding to a function in one of the
    /// facets of the proxy
    function isValidSelector(bytes4 selector) external view returns (bool);

    /// @notice Reference to the `accessControlManager` contract of the system
    function accessControlManager() external view returns (IAccessControlManager);

    /// @notice Stablecoin minted by transmuter
    function agToken() external view returns (IAgToken);

    /// @notice Returns the list of collateral assets supported by the system
    function getCollateralList() external view returns (address[] memory);

    /// @notice Returns all the info in storage associated to a `collateral`
    function getCollateralInfo(address collateral) external view returns (Collateral memory);

    /// @notice Returns the decimals of a given `collateral`
    function getCollateralDecimals(address collateral) external view returns (uint8);

    /// @notice Returns the `xFee` and `yFee` arrays from which fees are computed when coming to mint
    /// with `collateral`
    function getCollateralMintFees(address collateral) external view returns (uint64[] memory, int64[] memory);

    /// @notice Returns the `xFee` and `yFee` arrays from which fees are computed when coming to burn
    /// for `collateral`
    function getCollateralBurnFees(address collateral) external view returns (uint64[] memory, int64[] memory);

    /// @notice Returns the `xFee` and `yFee` arrays used to compute the penalty factor depending on the collateral
    /// ratio when users come to redeem
    function getRedemptionFees() external view returns (uint64[] memory, int64[] memory);

    /// @notice Returns the collateral ratio of Transmuter in base `10**9` and a rounded version of the total amount
    /// of stablecoins issued
    function getCollateralRatio() external view returns (uint64 collatRatio, uint256 stablecoinsIssued);

    /// @notice Returns the total amount of stablecoins issued through Transmuter
    function getTotalIssued() external view returns (uint256 stablecoinsIssued);

    /// @notice Returns the amount of stablecoins issued from `collateral` and the total amount of stablecoins issued
    /// through Transmuter
    function getIssuedByCollateral(
        address collateral
    ) external view returns (uint256 stablecoinsFromCollateral, uint256 stablecoinsIssued);

    /// @notice Returns if a collateral is "managed" and the associated manager configuration
    function getManagerData(
        address collateral
    ) external view returns (bool isManaged, IERC20[] memory subCollaterals, bytes memory config);

    /// @notice Returns the oracle values associated to `collateral`
    /// @return mint Oracle value to be used for a mint transaction with `collateral`
    /// @return burn Oracle value that will be used for `collateral` for a burn transaction. This value
    /// is then used along with oracle values for all other collateral assets to get a global burn value for the oracle
    /// @return ratio Ratio, in base `10**18` between the oracle value of the `collateral` and its target price.
    /// This value is 10**18 if the oracle is greater than the collateral price
    /// @return minRatio Minimum ratio across all collateral assets between a collateral burn price and its target
    /// price. This value is independent of `collateral` and is used to normalize the burn oracle value for burn
    /// transactions.
    /// @return redemption Oracle value that would be used to price `collateral` when computing the collateral ratio
    /// during a redemption
    function getOracleValues(
        address collateral
    ) external view returns (uint256 mint, uint256 burn, uint256 ratio, uint256 minRatio, uint256 redemption);

    /// @notice Returns the data used to compute oracle values for `collateral`
    /// @return oracleType Type of oracle (Chainlink, external smart contract, ...)
    /// @return targetType Type passed to read the value of the target price
    /// @return oracleData Extra data needed to read the oracle. For Chainlink oracles, this data is supposed to give
    /// the addresses of the Chainlink feeds to read, the stale periods for each feed, ...
    /// @return targetData Extra data needed to read the target price of the asset
    function getOracle(
        address collateral
    )
        external
        view
        returns (
            OracleReadType oracleType,
            OracleReadType targetType,
            bytes memory oracleData,
            bytes memory targetData,
            bytes memory hyperparameters
        );

    /// @notice Returns if the associated functionality is paused or not
    function isPaused(address collateral, ActionType action) external view returns (bool);

    /// @notice Returns if `sender` is trusted to update normalizers
    function isTrusted(address sender) external view returns (bool);

    /// @notice Returns if `sender` is trusted to update sell rewards
    function isTrustedSeller(address sender) external view returns (bool);

    /// @notice Checks whether `sender` has a non null entry in the `isWhitelistedForType` storage mapping
    /// @dev Note that ultimately whitelisting may depend as well on external providers
    function isWhitelistedForType(WhitelistType whitelistType, address sender) external view returns (bool);

    /// @notice Checks whether `sender` can deal with `collateral` during burns and redemptions
    function isWhitelistedForCollateral(address collateral, address sender) external returns (bool);

    /// @notice Checks whether only whitelisted address can deal with `collateral` during burns and redemptions
    function isWhitelistedCollateral(address collateral) external view returns (bool);

    /// @notice Gets the data needed to deal with whitelists for `collateral`
    function getCollateralWhitelistData(address collateral) external view returns (bytes memory);

    /// @notice Returns the stablecoin cap for `collateral`
    function getStablecoinCap(address collateral) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import { ITransmuterOracle } from "interfaces/ITransmuterOracle.sol";
import { AggregatorV3Interface } from "interfaces/external/chainlink/AggregatorV3Interface.sol";
import { IMorphoOracle } from "interfaces/external/morpho/IMorphoOracle.sol";
import { IPyth, PythStructs } from "interfaces/external/pyth/IPyth.sol";

import { LibStorage as s } from "./LibStorage.sol";

import "../../utils/Constants.sol";
import "../../utils/Errors.sol";
import "../Storage.sol";

/// @title LibOracle
/// @author Angle Labs, Inc.
library LibOracle {
    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                               ACTIONS SPECIFIC ORACLES                                             
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Reads the oracle value used during a redemption to compute collateral ratio for `oracleConfig`
    /// @dev This value is only sensitive to compute the collateral ratio and deduce a penalty factor
    function readRedemption(bytes memory oracleConfig) internal view returns (uint256 oracleValue) {
        (
            OracleReadType oracleType,
            OracleReadType targetType,
            bytes memory oracleData,
            bytes memory targetData,

        ) = _parseOracleConfig(oracleConfig);
        if (oracleType == OracleReadType.EXTERNAL) {
            ITransmuterOracle externalOracle = abi.decode(oracleData, (ITransmuterOracle));
            return externalOracle.readRedemption();
        } else {
            (oracleValue, ) = readSpotAndTarget(oracleType, targetType, oracleData, targetData, 0);
            return oracleValue;
        }
    }

    /// @notice Reads the oracle value used during mint operations for an asset with `oracleConfig`
    /// @dev For assets which do not rely on external oracles, this value is the minimum between the processed oracle
    /// value for the asset and its target price
    function readMint(bytes memory oracleConfig) internal view returns (uint256 oracleValue) {
        (
            OracleReadType oracleType,
            OracleReadType targetType,
            bytes memory oracleData,
            bytes memory targetData,
            bytes memory hyperparameters
        ) = _parseOracleConfig(oracleConfig);
        if (oracleType == OracleReadType.EXTERNAL) {
            ITransmuterOracle externalOracle = abi.decode(oracleData, (ITransmuterOracle));
            return externalOracle.readMint();
        }

        (uint128 userDeviation, ) = abi.decode(hyperparameters, (uint128, uint128));
        uint256 targetPrice;
        (oracleValue, targetPrice) = readSpotAndTarget(oracleType, targetType, oracleData, targetData, userDeviation);
        if (targetPrice < oracleValue) oracleValue = targetPrice;
    }

    /// @notice Reads the oracle value used for a burn operation for an asset with `oracleConfig`
    /// @return oracleValue The actual oracle value obtained
    /// @return ratio If `oracle value < target price`, the ratio between the oracle value and the target
    /// price, otherwise `BASE_18`
    function readBurn(bytes memory oracleConfig) internal view returns (uint256 oracleValue, uint256 ratio) {
        (
            OracleReadType oracleType,
            OracleReadType targetType,
            bytes memory oracleData,
            bytes memory targetData,
            bytes memory hyperparameters
        ) = _parseOracleConfig(oracleConfig);
        if (oracleType == OracleReadType.EXTERNAL) {
            ITransmuterOracle externalOracle = abi.decode(oracleData, (ITransmuterOracle));
            return externalOracle.readBurn();
        }
        (uint128 userDeviation, uint128 burnRatioDeviation) = abi.decode(hyperparameters, (uint128, uint128));
        uint256 targetPrice;
        (oracleValue, targetPrice) = readSpotAndTarget(oracleType, targetType, oracleData, targetData, userDeviation);
        // Firewall in case the oracle value reported is low compared to the target
        // If the oracle value is slightly below its target, then no deviation is reported for the oracle and
        // the price of burning the stablecoin for other assets is not impacted. Also, the oracle value of this asset
        // is set to the target price, to not be open to direct arbitrage
        ratio = BASE_18;
        if (oracleValue * BASE_18 < targetPrice * (BASE_18 - burnRatioDeviation))
            ratio = (oracleValue * BASE_18) / targetPrice;
        else if (oracleValue < targetPrice) oracleValue = targetPrice;
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                    VIEW FUNCTIONS                                                  
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Internal version of the `getOracle` function
    function getOracle(
        address collateral
    ) internal view returns (OracleReadType, OracleReadType, bytes memory, bytes memory, bytes memory) {
        return _parseOracleConfig(s.transmuterStorage().collaterals[collateral].oracleConfig);
    }

    /// @notice Gets the oracle value and the ratio with respect to the target price when it comes to
    /// burning for `collateral`
    function getBurnOracle(
        address collateral,
        bytes memory oracleConfig
    ) internal view returns (uint256 minRatio, uint256 oracleValue) {
        TransmuterStorage storage ts = s.transmuterStorage();
        minRatio = BASE_18;
        address[] memory collateralList = ts.collateralList;
        uint256 length = collateralList.length;
        for (uint256 i; i < length; ++i) {
            uint256 ratioObserved = BASE_18;
            if (collateralList[i] != collateral) {
                (, ratioObserved) = readBurn(ts.collaterals[collateralList[i]].oracleConfig);
            } else {
                (oracleValue, ratioObserved) = readBurn(oracleConfig);
            }
            if (ratioObserved < minRatio) minRatio = ratioObserved;
        }
    }

    /// @notice Computes the `quoteAmount` (for Chainlink oracles) depending on a `quoteType` and a base value
    /// (e.g the target price of the asset)
    /// @dev For cases where the Chainlink feed directly looks into the value of the asset, `quoteAmount` is `BASE_18`.
    /// For others, like wstETH for which Chainlink only has an oracle for stETH, `quoteAmount` is the target price
    function quoteAmount(OracleQuoteType quoteType, uint256 baseValue) internal pure returns (uint256) {
        if (quoteType == OracleQuoteType.UNIT) return BASE_18;
        else return baseValue;
    }

    function readSpotAndTarget(
        OracleReadType oracleType,
        OracleReadType targetType,
        bytes memory oracleData,
        bytes memory targetData,
        uint256 deviation
    ) internal view returns (uint256 oracleValue, uint256 targetPrice) {
        targetPrice = read(targetType, BASE_18, targetData);
        oracleValue = read(oracleType, targetPrice, oracleData);
        // System may tolerate small deviations from target
        // If the oracle value reported is reasonably close to the target
        // --> disregard the oracle value and return the target price
        if (
            targetPrice * (BASE_18 - deviation) < oracleValue * BASE_18 &&
            oracleValue * BASE_18 < targetPrice * (BASE_18 + deviation)
        ) oracleValue = targetPrice;
    }

    /// @notice Reads an oracle value (or a target oracle value) for an asset based on its data parsed `oracleConfig`
    function read(OracleReadType readType, uint256 baseValue, bytes memory data) internal view returns (uint256) {
        if (readType == OracleReadType.CHAINLINK_FEEDS) {
            (
                AggregatorV3Interface[] memory circuitChainlink,
                uint32[] memory stalePeriods,
                uint8[] memory circuitChainIsMultiplied,
                uint8[] memory chainlinkDecimals,
                OracleQuoteType quoteType
            ) = abi.decode(data, (AggregatorV3Interface[], uint32[], uint8[], uint8[], OracleQuoteType));
            uint256 quotePrice = quoteAmount(quoteType, baseValue);
            uint256 listLength = circuitChainlink.length;
            for (uint256 i; i < listLength; ++i) {
                quotePrice = readChainlinkFeed(
                    quotePrice,
                    circuitChainlink[i],
                    circuitChainIsMultiplied[i],
                    chainlinkDecimals[i],
                    stalePeriods[i]
                );
            }
            return quotePrice;
        } else if (readType == OracleReadType.STABLE) {
            return BASE_18;
        } else if (readType == OracleReadType.NO_ORACLE) {
            return baseValue;
        } else if (readType == OracleReadType.WSTETH) {
            return STETH.getPooledEthByShares(1 ether);
        } else if (readType == OracleReadType.CBETH) {
            return CBETH.exchangeRate();
        } else if (readType == OracleReadType.RETH) {
            return RETH.getExchangeRate();
        } else if (readType == OracleReadType.SFRXETH) {
            return SFRXETH.pricePerShare();
        } else if (readType == OracleReadType.PYTH) {
            (
                address pyth,
                bytes32[] memory feedIds,
                uint32[] memory stalePeriods,
                uint8[] memory isMultiplied,
                OracleQuoteType quoteType
            ) = abi.decode(data, (address, bytes32[], uint32[], uint8[], OracleQuoteType));
            uint256 quotePrice = quoteAmount(quoteType, baseValue);
            uint256 listLength = feedIds.length;
            for (uint256 i; i < listLength; ++i) {
                quotePrice = readPythFeed(quotePrice, feedIds[i], pyth, isMultiplied[i], stalePeriods[i]);
            }
            return quotePrice;
        } else if (readType == OracleReadType.MAX) {
            uint256 maxValue = abi.decode(data, (uint256));
            return maxValue;
        } else if (readType == OracleReadType.MORPHO_ORACLE) {
            (address contractAddress, uint256 normalizationFactor) = abi.decode(data, (address, uint256));
            return IMorphoOracle(contractAddress).price() / normalizationFactor;
        }
        // If the `OracleReadType` is `EXTERNAL`, it means that this function is called to compute a
        // `targetPrice` in which case the `baseValue` is returned here
        else {
            return baseValue;
        }
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                   SPECIFIC HELPERS                                                 
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Reads a Chainlink feed using a quote amount and converts the quote amount to the out-currency
    /// @param _quoteAmount The amount for which to compute the price expressed in `BASE_18`
    /// @param feed Chainlink feed to query
    /// @param multiplied Whether the ratio outputted by Chainlink should be multiplied or divided to the `quoteAmount`
    /// @param decimals Number of decimals of the corresponding Chainlink pair
    /// @return The `quoteAmount` converted in out-currency
    function readChainlinkFeed(
        uint256 _quoteAmount,
        AggregatorV3Interface feed,
        uint8 multiplied,
        uint256 decimals,
        uint32 stalePeriod
    ) internal view returns (uint256) {
        (, int256 ratio, , uint256 updatedAt, ) = feed.latestRoundData();
        if (ratio <= 0 || block.timestamp - updatedAt > stalePeriod) revert InvalidChainlinkRate();
        // Checking whether we should multiply or divide by the ratio computed
        if (multiplied == 1) return (_quoteAmount * uint256(ratio)) / (10 ** decimals);
        else return (_quoteAmount * (10 ** decimals)) / uint256(ratio);
    }

    /// @notice Reads a Pyth fee using a quote amount and converts the quote amount to the `out-currency`
    function readPythFeed(
        uint256 _quoteAmount,
        bytes32 feedId,
        address pyth,
        uint8 multiplied,
        uint32 stalePeriod
    ) internal view returns (uint256) {
        PythStructs.Price memory pythData = IPyth(pyth).getPriceNoOlderThan(feedId, stalePeriod);
        if (pythData.price <= 0) revert InvalidRate();
        uint256 normalizedPrice = uint64(pythData.price);
        bool isNormalizerExpoNeg = pythData.expo < 0;
        uint256 normalizer = isNormalizerExpoNeg ? 10 ** uint32(-pythData.expo) : 10 ** uint32(pythData.expo);
        if (multiplied == 1 && isNormalizerExpoNeg) return (_quoteAmount * normalizedPrice) / normalizer;
        else if (multiplied == 1 && !isNormalizerExpoNeg) return _quoteAmount * normalizedPrice * normalizer;
        else if (multiplied == 0 && isNormalizerExpoNeg) return (_quoteAmount * normalizer) / normalizedPrice;
        else return _quoteAmount / (normalizer * normalizedPrice);
    }

    /// @notice Parses an `oracleConfig` into several sub fields
    function _parseOracleConfig(
        bytes memory oracleConfig
    ) private pure returns (OracleReadType, OracleReadType, bytes memory, bytes memory, bytes memory) {
        return abi.decode(oracleConfig, (OracleReadType, OracleReadType, bytes, bytes, bytes));
    }

    function updateOracle(address collateral) internal {
        TransmuterStorage storage ts = s.transmuterStorage();
        if (ts.collaterals[collateral].decimals == 0) revert NotCollateral();

        (
            OracleReadType oracleType,
            OracleReadType targetType,
            bytes memory oracleData,
            bytes memory targetData,
            bytes memory hyperparameters
        ) = _parseOracleConfig(ts.collaterals[collateral].oracleConfig);

        if (targetType != OracleReadType.MAX) revert OracleUpdateFailed();
        uint256 oracleValue = read(oracleType, BASE_18, oracleData);

        uint256 maxValue = abi.decode(targetData, (uint256));
        if (oracleValue > maxValue)
            ts.collaterals[collateral].oracleConfig = abi.encode(
                oracleType,
                targetType,
                oracleData,
                // There are no checks whether the value increased or not
                abi.encode(oracleValue),
                hyperparameters
            );
        else revert OracleUpdateFailed();
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import { IERC20 } from "oz/token/ERC20/IERC20.sol";
import { Math } from "oz/utils/math/Math.sol";
import { SafeCast } from "oz/utils/math/SafeCast.sol";

import { LibHelpers } from "./LibHelpers.sol";
import { LibManager } from "./LibManager.sol";
import { LibOracle } from "./LibOracle.sol";
import { LibStorage as s } from "./LibStorage.sol";

import "../../utils/Constants.sol";
import "../Storage.sol";

/// @title LibGetters
/// @author Angle Labs, Inc.
library LibGetters {
    using Math for uint256;
    using SafeCast for uint256;

    /// @notice Internal version of the `getCollateralRatio` function with additional return values like `tokens` that
    /// is the list of tokens supported by the system, or `balances` which is the amount of each token in `tokens`
    /// controlled by the protocol
    /// @dev In case some collaterals support external strategies (`isManaged>0`), this list may be bigger
    /// than the `collateralList`
    /// @dev `subCollateralsTracker` is an array which gives for each collateral asset in the collateral list an
    /// accumulator helping to recompute the amount of sub-collateral for each collateral. If the array is:
    /// [1,4,5], this means that the collateral with index 1 in the `collateralsList` has 4-1=3 sub-collaterals.
    function getCollateralRatio()
        internal
        view
        returns (
            uint64 collatRatio,
            uint256 stablecoinsIssued,
            address[] memory tokens,
            uint256[] memory balances,
            uint256[] memory subCollateralsTracker
        )
    {
        TransmuterStorage storage ts = s.transmuterStorage();
        uint256 totalCollateralization;
        address[] memory collateralList = ts.collateralList;
        uint256 collateralListLength = collateralList.length;
        uint256 subCollateralsAmount;
        // Building the `subCollateralsTracker` array which is useful when later sending the tokens as part of the
        // redemption
        subCollateralsTracker = new uint256[](collateralListLength);
        for (uint256 i; i < collateralListLength; ++i) {
            if (ts.collaterals[collateralList[i]].isManaged == 0) ++subCollateralsAmount;
            else subCollateralsAmount += ts.collaterals[collateralList[i]].managerData.subCollaterals.length;
            subCollateralsTracker[i] = subCollateralsAmount;
        }
        balances = new uint256[](subCollateralsAmount);
        tokens = new address[](subCollateralsAmount);

        {
            uint256 countCollat;
            for (uint256 i; i < collateralListLength; ++i) {
                Collateral storage collateral = ts.collaterals[collateralList[i]];
                uint256 collateralBalance; // Will be either the balance or the value of assets managed
                if (collateral.isManaged > 0) {
                    // If a collateral is managed, the balances of the sub-collaterals cannot be directly obtained by
                    // calling `balanceOf` of the sub-collaterals
                    uint256[] memory subCollateralsBalances;
                    (subCollateralsBalances, collateralBalance) = LibManager.totalAssets(collateral.managerData.config);
                    uint256 numSubCollats = subCollateralsBalances.length;
                    for (uint256 k; k < numSubCollats; ++k) {
                        tokens[countCollat + k] = address(collateral.managerData.subCollaterals[k]);
                        balances[countCollat + k] = subCollateralsBalances[k];
                    }
                    countCollat += numSubCollats;
                } else {
                    collateralBalance = IERC20(collateralList[i]).balanceOf(address(this));
                    tokens[countCollat] = collateralList[i];
                    balances[countCollat++] = collateralBalance;
                }
                uint256 oracleValue = LibOracle.readRedemption(collateral.oracleConfig);
                totalCollateralization +=
                    (oracleValue * LibHelpers.convertDecimalTo(collateralBalance, collateral.decimals, 18)) /
                    BASE_18;
            }
        }
        // The `stablecoinsIssued` value need to be rounded up because it is then used as a divizer when computing
        // the `collatRatio`
        stablecoinsIssued = uint256(ts.normalizedStables).mulDiv(ts.normalizer, BASE_27, Math.Rounding.Up);
        if (stablecoinsIssued > 0) {
            collatRatio = (totalCollateralization.mulDiv(BASE_9, stablecoinsIssued, Math.Rounding.Up)).toUint64();
        } else collatRatio = type(uint64).max;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import "../../utils/Constants.sol";
import { DiamondStorage, ImplementationStorage, TransmuterStorage } from "../Storage.sol";

/// @title LibStorage
/// @author Angle Labs, Inc.
library LibStorage {
    /// @notice Returns the storage struct stored at the `DIAMOND_STORAGE_POSITION` slot
    /// @dev This struct handles the logic of the different facets used in the diamond proxy
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice Returns the storage struct stored at the `TRANSMUTER_STORAGE_POSITION` slot
    /// @dev This struct handles the particular logic of the Transmuter system
    function transmuterStorage() internal pure returns (TransmuterStorage storage ts) {
        bytes32 position = TRANSMUTER_STORAGE_POSITION;
        assembly {
            ts.slot := position
        }
    }

    /// @notice Returns the storage struct stored at the `IMPLEMENTATION_STORAGE_POSITION` slot
    /// @dev This struct handles the logic for making the contract easily usable on Etherscan
    function implementationStorage() internal pure returns (ImplementationStorage storage ims) {
        bytes32 position = IMPLEMENTATION_STORAGE_POSITION;
        assembly {
            ims.slot := position
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import { IKeyringGuard } from "interfaces/external/keyring/IKeyringGuard.sol";

import { LibStorage as s } from "./LibStorage.sol";

import "../../utils/Errors.sol";
import "../Storage.sol";

/// @title LibWhitelist
/// @author Angle Labs, Inc.
library LibWhitelist {
    /// @notice Checks whether `sender` is whitelisted for a collateral with `whitelistData`
    function checkWhitelist(bytes memory whitelistData, address sender) internal returns (bool) {
        (WhitelistType whitelistType, bytes memory data) = abi.decode(whitelistData, (WhitelistType, bytes));
        if (s.transmuterStorage().isWhitelistedForType[whitelistType][sender] > 0) return true;
        if (data.length != 0) {
            if (whitelistType == WhitelistType.BACKED) {
                address keyringGuard = abi.decode(data, (address));
                if (keyringGuard != address(0)) return IKeyringGuard(keyringGuard).isAuthorized(address(this), sender);
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

import { ICbETH } from "interfaces/external/coinbase/ICbETH.sol";
import { ISfrxETH } from "interfaces/external/frax/ISfrxETH.sol";
import { IStETH } from "interfaces/external/lido/IStETH.sol";
import { IRETH } from "interfaces/external/rocketPool/IRETH.sol";

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                 STORAGE SLOTS                                                  
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

/// @dev Storage position of `DiamondStorage` structure
/// @dev Equals `keccak256("diamond.standard.diamond.storage") - 1`
bytes32 constant DIAMOND_STORAGE_POSITION = 0xc8fcad8db84d3cc18b4c41d551ea0ee66dd599cde068d998e57d5e09332c131b;

/// @dev Storage position of `TransmuterStorage` structure
/// @dev Equals `keccak256("diamond.standard.transmuter.storage") - 1`
bytes32 constant TRANSMUTER_STORAGE_POSITION = 0xc1f2f38dde3351ac0a64934139e816326caa800303a1235dc53707d0de05d8bd;

/// @dev Storage position of `ImplementationStorage` structure
/// @dev Equals `keccak256("eip1967.proxy.implementation") - 1`
bytes32 constant IMPLEMENTATION_STORAGE_POSITION = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                     MATHS                                                      
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

uint256 constant BASE_6 = 1e6;
uint256 constant BASE_8 = 1e8;
uint256 constant BASE_9 = 1e9;
uint256 constant BASE_12 = 1e12;
uint256 constant BPS = 1e14;
uint256 constant BASE_18 = 1e18;
uint256 constant HALF_BASE_27 = 1e27 / 2;
uint256 constant BASE_27 = 1e27;
uint256 constant BASE_36 = 1e36;
uint256 constant MAX_BURN_FEE = 999_000_000;
uint256 constant MAX_MINT_FEE = BASE_12 - 1;

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                     REENTRANT                                                      
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

// The values being non-zero value makes deployment a bit more expensive,
// but in exchange the refund on every call to nonReentrant will be lower in
// amount. Since refunds are capped to a percentage of the total
// transaction's gas, it is best to keep them low in cases like this one, to
// increase the likelihood of the full refund coming into effect.
uint8 constant NOT_ENTERED = 1;
uint8 constant ENTERED = 2;

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                               COMMON ADDRESSES                                                 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

address constant PERMIT_2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
address constant ONE_INCH_ROUTER = 0x1111111254EEB25477B68fb85Ed929f73A960582;
address constant AGEUR = 0x1a7e4e63778B4f12a199C062f3eFdD288afCBce8;
ICbETH constant CBETH = ICbETH(0xBe9895146f7AF43049ca1c1AE358B0541Ea49704);
IRETH constant RETH = IRETH(0xae78736Cd615f374D3085123A210448E74Fc6393);
IStETH constant STETH = IStETH(0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84);
ISfrxETH constant SFRXETH = ISfrxETH(0xac3E018457B222d93114458476f3E3416Abbe38F);

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

error AlreadyAdded();
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
error CannotRemoveImmutableFunction(bytes4 _selector);
error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] _selectors);
error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(bytes4 _selector);
error CannotReplaceImmutableFunction(bytes4 _selector);
error ContractHasNoCode();
error FunctionNotFound(bytes4 _functionSelector);
error IncorrectFacetCutAction(uint8 _action);
error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);
error InvalidChainlinkRate();
error InvalidLengths();
error InvalidNegativeFees();
error InvalidOracleType();
error InvalidParam();
error InvalidParams();
error InvalidRate();
error InvalidSwap();
error InvalidTokens();
error ManagerHasAssets();
error NoSelectorsProvidedForFacetForCut(address _facetAddress);
error NotAllowed();
error NotCollateral();
error NotGovernor();
error NotGovernorOrGuardian();
error NotTrusted();
error NotWhitelisted();
error OneInchSwapFailed();
error OracleUpdateFailed();
error Paused();
error ReentrantCall();
error RemoveFacetAddressMustBeZeroAddress(address _facetAddress);
error TooBigAmountIn();
error TooLate();
error TooSmallAmountOut();
error ZeroAddress();
error ZeroAmount();

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import { IERC20 } from "oz/token/ERC20/IERC20.sol";
import { IAccessControlManager } from "interfaces/IAccessControlManager.sol";
import { IAgToken } from "interfaces/IAgToken.sol";

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                        ENUMS                                                      
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

enum FacetCutAction {
    Add,
    Replace,
    Remove
}

enum ManagerType {
    EXTERNAL
}

enum ActionType {
    Mint,
    Burn,
    Redeem
}

enum TrustedType {
    Updater,
    Seller
}

enum QuoteType {
    MintExactInput,
    MintExactOutput,
    BurnExactInput,
    BurnExactOutput
}

enum OracleReadType {
    CHAINLINK_FEEDS,
    EXTERNAL,
    NO_ORACLE,
    STABLE,
    WSTETH,
    CBETH,
    RETH,
    SFRXETH,
    PYTH,
    MAX,
    MORPHO_ORACLE
}

enum OracleQuoteType {
    UNIT,
    TARGET
}

enum WhitelistType {
    BACKED
}

/*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                    STRUCTS                                                     
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

struct Permit2Details {
    address to; // Address that will receive the funds
    uint256 nonce; // Nonce of the transaction
    bytes signature; // Permit signature of the user
}

struct FacetCut {
    address facetAddress; // Facet contract address
    FacetCutAction action; // Can be add, remove or replace
    bytes4[] functionSelectors; // Ex. bytes4(keccak256("transfer(address,uint256)"))
}

struct Facet {
    address facetAddress; // Facet contract address
    bytes4[] functionSelectors; // Ex. bytes4(keccak256("transfer(address,uint256)"))
}

struct FacetInfo {
    address facetAddress; // Facet contract address
    uint16 selectorPosition; // Position in the list of all selectors
}

struct DiamondStorage {
    bytes4[] selectors; // List of all available selectors
    mapping(bytes4 => FacetInfo) selectorInfo; // Selector to (address, position in list)
    IAccessControlManager accessControlManager; // Contract handling access control
}

struct ImplementationStorage {
    address implementation; // Dummy implementation address for Etherscan usability
}

struct ManagerStorage {
    IERC20[] subCollaterals; // Subtokens handled by the manager or strategies
    bytes config; // Additional configuration data
}

struct Collateral {
    uint8 isManaged; // If the collateral is managed through external strategies
    uint8 isMintLive; // If minting from this asset is unpaused
    uint8 isBurnLive; // If burning to this asset is unpaused
    uint8 decimals; // IERC20Metadata(collateral).decimals()
    uint8 onlyWhitelisted; // If only whitelisted addresses can burn or redeem for this token
    uint216 normalizedStables; // Normalized amount of stablecoins issued from this collateral
    uint64[] xFeeMint; // Increasing exposures in [0,BASE_9[
    int64[] yFeeMint; // Mint fees at the exposures specified in `xFeeMint`
    uint64[] xFeeBurn; // Decreasing exposures in ]0,BASE_9]
    int64[] yFeeBurn; // Burn fees at the exposures specified in `xFeeBurn`
    bytes oracleConfig; // Data about the oracle used for the collateral
    bytes whitelistData; // For whitelisted collateral, data used to verify whitelists
    ManagerStorage managerData; // For managed collateral, data used to handle the strategies
    uint256 stablecoinCap; // Cap on the amount of stablecoins that can be issued from this collateral
}

struct TransmuterStorage {
    IAgToken agToken; // agToken handled by the system
    uint8 isRedemptionLive; // If redemption is unpaused
    uint8 statusReentrant; // If call is reentrant or not
    uint128 normalizedStables; // Normalized amount of stablecoins issued by the system
    uint128 normalizer; // To reconcile `normalizedStables` values with the actual amount
    address[] collateralList; // List of collateral assets supported by the system
    uint64[] xRedemptionCurve; // Increasing collateral ratios > 0
    int64[] yRedemptionCurve; // Value of the redemption fees at `xRedemptionCurve`
    mapping(address => Collateral) collaterals; // Maps a collateral asset to its parameters
    mapping(address => uint256) isTrusted; // If an address is trusted to update the normalizer value
    mapping(address => uint256) isSellerTrusted; // If an address is trusted to sell accruing reward tokens or to run keeper jobs on oracles
    mapping(WhitelistType => mapping(address => uint256)) isWhitelistedForType;
    // Whether an address is whitelisted for a specific whitelist type
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import { IERC20 } from "oz/token/ERC20/IERC20.sol";

/// @title IAgToken
/// @author Angle Labs, Inc.
/// @notice Interface for the stablecoins `AgToken` contracts
interface IAgToken is IERC20 {
    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                              MINTER ROLE ONLY FUNCTIONS                                            
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Lets a whitelisted contract mint agTokens
    /// @param account Address to mint to
    /// @param amount Amount to mint
    function mint(address account, uint256 amount) external;

    /// @notice Burns `amount` tokens from a `burner` address after being asked to by `sender`
    /// @param amount Amount of tokens to burn
    /// @param burner Address to burn from
    /// @param sender Address which requested the burn from `burner`
    /// @dev This method is to be called by a contract with the minter right after being requested
    /// to do so by a `sender` address willing to burn tokens from another `burner` address
    /// @dev The method checks the allowance between the `sender` and the `burner`
    function burnFrom(uint256 amount, address burner, address sender) external;

    /// @notice Burns `amount` tokens from a `burner` address
    /// @param amount Amount of tokens to burn
    /// @param burner Address to burn from
    /// @dev This method is to be called by a contract with a minter right on the AgToken after being
    /// requested to do so by an address willing to burn tokens from its address
    function burnSelf(uint256 amount, address burner) external;

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                TREASURY ONLY FUNCTIONS                                             
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Adds a minter in the contract
    /// @param minter Minter address to add
    /// @dev Zero address checks are performed directly in the `Treasury` contract
    function addMinter(address minter) external;

    /// @notice Removes a minter from the contract
    /// @param minter Minter address to remove
    /// @dev This function can also be called by a minter wishing to revoke itself
    function removeMinter(address minter) external;

    /// @notice Sets a new treasury contract
    /// @param _treasury New treasury address
    function setTreasury(address _treasury) external;

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                  EXTERNAL FUNCTIONS                                                
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks whether an address has the right to mint agTokens
    /// @param minter Address for which the minting right should be checked
    /// @return Whether the address has the right to mint agTokens or not
    function isMinter(address minter) external view returns (bool);

    /// @notice Amount of decimals of the stablecoin
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

/// @title ITransmuterOracle
/// @author Angle Labs, Inc.
interface ITransmuterOracle {
    /// @notice Reads the oracle value for asset to use in a redemption to compute the collateral ratio
    function readRedemption() external view returns (uint256);

    /// @notice Reads the oracle value for asset to use in a mint. It should be comprehensive of the
    /// deviation from the target price
    function readMint() external view returns (uint256);

    /// @notice Reads the oracle value for asset to use in a burn transaction as well as the ratio
    /// between the current price and the target price for the asset
    function readBurn() external view returns (uint256 oracleValue, uint256 ratio);

    /// @notice Reads the oracle value for asset
    function read() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

/// @title IMorphoOracle
/// @notice Interface for the oracle contracts used within Morpho
interface IMorphoOracle {
    function price() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

contract PythStructs {
    // A price with a degree of uncertainty, represented as a price +- a confidence interval.
    //
    // The confidence interval roughly corresponds to the standard error of a normal distribution.
    // Both the price and confidence are stored in a fixed-point numeric representation,
    // `x * (10^expo)`, where `expo` is the exponent.
    //
    // Please refer to the documentation at https://docs.pyth.network/consumers/best-practices for how
    // to how this price safely.
    struct Price {
        // Price
        int64 price;
        // Confidence interval around the price
        uint64 conf;
        // Price exponent
        int32 expo;
        // Unix timestamp describing when the price was published
        uint publishTime;
    }

    // PriceFeed represents a current aggregate price from pyth publisher feeds.
    struct PriceFeed {
        // The price ID.
        bytes32 id;
        // Latest available price
        Price price;
        // Latest available exponentially-weighted moving average price
        Price emaPrice;
    }
}

// @title IPythEvents contains the events that Pyth contract emits.
/// @dev This interface can be used for listening to the updates for off-chain and testing purposes.
interface IPythEvents {
    /// @dev Emitted when the price feed with `id` has received a fresh update.
    /// @param id The Pyth Price Feed ID.
    /// @param publishTime Publish time of the given price update.
    /// @param price Price of the given price update.
    /// @param conf Confidence interval of the given price update.
    event PriceFeedUpdate(bytes32 indexed id, uint64 publishTime, int64 price, uint64 conf);

    /// @dev Emitted when a batch price update is processed successfully.
    /// @param chainId ID of the source chain that the batch price update comes from.
    /// @param sequenceNumber Sequence number of the batch price update.
    event BatchPriceFeedUpdate(uint16 chainId, uint64 sequenceNumber);
}

/// @title Consume prices from the Pyth Network (https://pyth.network/).
/// @author Pyth Data Association
interface IPyth is IPythEvents {
    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() external view returns (uint validTimePeriod);

    /// @notice Returns the price and confidence interval.
    /// @dev Reverts if the price has not been updated within the last `getValidTimePeriod()` seconds.
    /// @param id The Pyth Price Feed ID of which to fetch the price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPrice(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price and confidence interval.
    /// @dev Reverts if the EMA price is not available.
    /// @param id The Pyth Price Feed ID of which to fetch the EMA price and confidence interval.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPrice(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price of a price feed without any sanity checks.
    /// @dev This function returns the most recent price update in this contract without any recency checks.
    /// This function is unsafe as the returned price update may be arbitrarily far in the past.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getPrice` or `getPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the price that is no older than `age` seconds of the current time.
    /// @dev This function is a sanity-checked version of `getPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getPriceNoOlderThan(bytes32 id, uint age) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price of a price feed without any sanity checks.
    /// @dev This function returns the same price as `getEmaPrice` in the case where the price is available.
    /// However, if the price is not recent this function returns the latest available price.
    ///
    /// The returned price can be from arbitrarily far in the past; this function makes no guarantees that
    /// the returned price is recent or useful for any particular application.
    ///
    /// Users of this function should check the `publishTime` in the price to ensure that the returned price is
    /// sufficiently recent for their application. If you are considering using this function, it may be
    /// safer / easier to use either `getEmaPrice` or `getEmaPriceNoOlderThan`.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceUnsafe(bytes32 id) external view returns (PythStructs.Price memory price);

    /// @notice Returns the exponentially-weighted moving average price that is no older than `age` seconds
    /// of the current time.
    /// @dev This function is a sanity-checked version of `getEmaPriceUnsafe` which is useful in
    /// applications that require a sufficiently-recent price. Reverts if the price wasn't updated sufficiently
    /// recently.
    /// @return price - please read the documentation of PythStructs.Price to understand how to use this safely.
    function getEmaPriceNoOlderThan(bytes32 id, uint age) external view returns (PythStructs.Price memory price);

    /// @notice Update price feeds with given update messages.
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    /// Prices will be updated if they are more recent than the current stored prices.
    /// The call will succeed even if the update is not the most recent.
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    function updatePriceFeeds(bytes[] calldata updateData) external payable;

    /// @notice Wrapper around updatePriceFeeds that rejects fast if a price update is not necessary. A price update is
    /// necessary if the current on-chain publishTime is older than the given publishTime. It relies solely on the
    /// given `publishTimes` for the price feeds and does not read the actual price update publish time within
    /// `updateData`.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    /// `priceIds` and `publishTimes` are two arrays with the same size that correspond to senders known publishTime
    /// of each priceId when calling this method. If all of price feeds within `priceIds` have updated and have
    /// a newer or equal publish time than the given publish time, it will reject the transaction to save gas.
    /// Otherwise, it calls updatePriceFeeds method to update the prices.
    ///
    /// @dev Reverts if update is not needed or the transferred fee is not sufficient or the updateData is invalid.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param publishTimes Array of publishTimes. `publishTimes[i]` corresponds to known `publishTime` of `priceIds[i]`
    function updatePriceFeedsIfNecessary(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64[] calldata publishTimes
    ) external payable;

    /// @notice Returns the required fee to update an array of price updates.
    /// @param updateData Array of price update data.
    /// @return feeAmount The required fee in Wei.
    function getUpdateFee(bytes[] calldata updateData) external view returns (uint feeAmount);

    /// @notice Parse `updateData` and return price feeds of the given `priceIds` if they are all published
    /// within `minPublishTime` and `maxPublishTime`.
    ///
    /// You can use this method if you want to use a Pyth price at a fixed time and not the most recent price;
    /// otherwise, please consider using `updatePriceFeeds`. This method does not store the price updates on-chain.
    ///
    /// This method requires the caller to pay a fee in wei; the required fee can be computed by calling
    /// `getUpdateFee` with the length of the `updateData` array.
    ///
    ///
    /// @dev Reverts if the transferred fee is not sufficient or the updateData is invalid or there is
    /// no update for any of the given `priceIds` within the given time range.
    /// @param updateData Array of price update data.
    /// @param priceIds Array of price ids.
    /// @param minPublishTime minimum acceptable publishTime for the given `priceIds`.
    /// @param maxPublishTime maximum acceptable publishTime for the given `priceIds`.
    /// @return priceFeeds Array of the price feeds corresponding to the given `priceIds` (with the same order).
    function parsePriceFeedUpdates(
        bytes[] calldata updateData,
        bytes32[] calldata priceIds,
        uint64 minPublishTime,
        uint64 maxPublishTime
    ) external payable returns (PythStructs.PriceFeed[] memory priceFeeds);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
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
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
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
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
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
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
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
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
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
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
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
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;

import { Math } from "oz/utils/math/Math.sol";

import "../Storage.sol";

/// @title LibHelpers
/// @author Angle Labs, Inc.
library LibHelpers {
    /// @notice Rebases the units of `amount` from `fromDecimals` to `toDecimals`
    function convertDecimalTo(uint256 amount, uint8 fromDecimals, uint8 toDecimals) internal pure returns (uint256) {
        if (fromDecimals > toDecimals) return amount / 10 ** (fromDecimals - toDecimals);
        else if (fromDecimals < toDecimals) return amount * 10 ** (toDecimals - fromDecimals);
        else return amount;
    }

    /// @notice Checks whether a `token` is in a list `tokens` and returns the index of the token in the list
    /// or -1 in the other case
    function checkList(address token, address[] memory tokens) internal pure returns (int256) {
        uint256 tokensLength = tokens.length;
        for (uint256 i; i < tokensLength; ++i) {
            if (token == tokens[i]) return int256(i);
        }
        return -1;
    }

    /// @notice Searches a sorted `array` and returns the first index that contains a value strictly greater
    /// (or lower if increasingArray is false) to `element` minus 1
    /// @dev If no such index exists (i.e. all values in the array are strictly lesser/greater than `element`),
    /// either array length minus 1, or 0 are returned
    /// @dev The time complexity of the search is O(log n).
    /// @dev Inspired from OpenZeppelin Contracts v4.4.1:
    /// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Arrays.sol
    /// @dev Modified by Angle Labs to support `uint64`, monotonous arrays and exclusive upper bounds
    function findLowerBound(
        bool increasingArray,
        uint64[] memory array,
        uint64 normalizerArray,
        uint64 element
    ) internal pure returns (uint256) {
        if (array.length == 0) {
            return 0;
        }
        uint256 low = 1;
        uint256 high = array.length;

        if (
            (increasingArray && array[high - 1] * normalizerArray <= element) ||
            (!increasingArray && array[high - 1] * normalizerArray >= element)
        ) return high - 1;

        while (low < high) {
            uint256 mid = Math.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (increasingArray ? array[mid] * normalizerArray > element : array[mid] * normalizerArray < element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        // At this point `low` is the exclusive upper bound.
        // `low - 1` is the inclusive lower bound.
        return low - 1;
    }

    /// @notice Evaluates for `x` a piecewise linear function defined with the breaking points in the arrays
    /// `xArray` and `yArray`
    /// @dev The values in the `xArray` must be increasing
    function piecewiseLinear(uint64 x, uint64[] memory xArray, int64[] memory yArray) internal pure returns (int64) {
        uint256 indexLowerBound = findLowerBound(true, xArray, 1, x);
        if (indexLowerBound == 0 && x < xArray[0]) return yArray[0];
        else if (indexLowerBound == xArray.length - 1) return yArray[xArray.length - 1];
        return
            yArray[indexLowerBound] +
            ((yArray[indexLowerBound + 1] - yArray[indexLowerBound]) * int64(x - xArray[indexLowerBound])) /
            int64(xArray[indexLowerBound + 1] - xArray[indexLowerBound]);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import { IManager } from "interfaces/IManager.sol";

import "../Storage.sol";

/// @title LibManager
/// @author Angle Labs, Inc.
/// @dev Managed collateral assets may be handled through external smart contracts or directly through this library
/// @dev There is no implementation at this point for a managed collateral handled through this library, and
/// a new specific `ManagerType` would need to be added in this case
library LibManager {
    /// @notice Checks to which address managed funds must be transferred
    function transferRecipient(bytes memory config) internal view returns (address recipient) {
        (ManagerType managerType, bytes memory data) = parseManagerConfig(config);
        recipient = address(this);
        if (managerType == ManagerType.EXTERNAL) return abi.decode(data, (address));
    }

    /// @notice Performs a transfer of `token` for a collateral that is managed to a `to` address
    /// @dev `token` may not be the actual collateral itself, as some collaterals have subcollaterals associated
    /// with it
    /// @dev Eventually pulls funds from strategies
    function release(address token, address to, uint256 amount, bytes memory config) internal {
        (ManagerType managerType, bytes memory data) = parseManagerConfig(config);
        if (managerType == ManagerType.EXTERNAL) abi.decode(data, (IManager)).release(token, to, amount);
    }

    /// @notice Gets the balances of all the tokens controlled through `managerData`
    /// @return balances An array of size `subCollaterals` with current balances of all subCollaterals
    /// including the one corresponding to the `managerData` given
    /// @return totalValue The value of all the `subCollaterals` in `collateral`
    /// @dev `subCollaterals` must always have as first token (index 0) the collateral itself
    function totalAssets(bytes memory config) internal view returns (uint256[] memory balances, uint256 totalValue) {
        (ManagerType managerType, bytes memory data) = parseManagerConfig(config);
        if (managerType == ManagerType.EXTERNAL) return abi.decode(data, (IManager)).totalAssets();
    }

    /// @notice Calls a hook if needed after new funds have been transfered to a manager
    function invest(uint256 amount, bytes memory config) internal {
        (ManagerType managerType, bytes memory data) = parseManagerConfig(config);
        if (managerType == ManagerType.EXTERNAL) abi.decode(data, (IManager)).invest(amount);
    }

    /// @notice Returns available underlying tokens, for instance if liquidity is fully used and
    /// not withdrawable the function will return 0
    function maxAvailable(bytes memory config) internal view returns (uint256 available) {
        (ManagerType managerType, bytes memory data) = parseManagerConfig(config);
        if (managerType == ManagerType.EXTERNAL) return abi.decode(data, (IManager)).maxAvailable();
    }

    /// @notice Decodes the `managerData` associated to a collateral
    function parseManagerConfig(
        bytes memory config
    ) internal pure returns (ManagerType managerType, bytes memory data) {
        (managerType, data) = abi.decode(config, (ManagerType, bytes));
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

/// @title IKeyringGuard
/// @notice Interface for the `KeyringGuard` contract
interface IKeyringGuard {
    function isAuthorized(address from, address to) external returns (bool passed);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

/// @title ICbETH
/// @notice Interface for the `cbETH` contract
interface ICbETH {
    function exchangeRate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

/// @title ISfrxETH
/// @notice Interface for the `sfrxETH` contract
interface ISfrxETH {
    function pricePerShare() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

/// @title IStETH
/// @notice Interface for the `StETH` contract
interface IStETH {
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);

    function submit(address) external payable returns (uint256);

    function getSharesByPooledEth(uint256 _ethAmount) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

/// @title IRETH
/// @notice Interface for the `rETH` contract
interface IRETH {
    function getExchangeRate() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

/// @title IManager
/// @author Angle Labs, Inc.
interface IManager {
    /// @notice Returns the amount of collateral managed by the Manager
    /// @return balances Balances of all the subCollaterals handled by the manager
    /// @dev MUST NOT revert
    function totalAssets() external view returns (uint256[] memory balances, uint256 totalValue);

    /// @notice Hook to invest `amount` of `collateral`
    /// @dev MUST revert if the manager cannot accept these funds
    /// @dev MUST have received the funds beforehand
    function invest(uint256 amount) external;

    /// @notice Sends `amount` of `collateral` to the `to` address
    /// @dev Called when `agToken` are burnt and during redemptions
    //  @dev MUST revert if there are not funds enough available
    /// @dev MUST be callable only by the transmuter
    function release(address asset, address to, uint256 amount) external;

    /// @notice Gives the maximum amount of collateral immediately available for a transfer
    /// @dev Useful for integrators using `quoteIn` and `quoteOut`
    function maxAvailable() external view returns (uint256);
}