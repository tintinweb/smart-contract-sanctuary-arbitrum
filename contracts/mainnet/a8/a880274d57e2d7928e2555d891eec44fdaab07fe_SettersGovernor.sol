// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.19;

import { IERC20 } from "oz/interfaces/IERC20.sol";
import { SafeERC20 } from "oz/token/ERC20/utils/SafeERC20.sol";

import { IAccessControlManager } from "interfaces/IAccessControlManager.sol";
import { ISettersGovernor } from "interfaces/ISetters.sol";

import { LibManager } from "../libraries/LibManager.sol";
import { LibOracle } from "../libraries/LibOracle.sol";
import { LibSetters } from "../libraries/LibSetters.sol";
import { LibStorage as s } from "../libraries/LibStorage.sol";
import { AccessControlModifiers } from "./AccessControlModifiers.sol";

import "../../utils/Constants.sol";
import "../../utils/Errors.sol";
import "../Storage.sol";

/// @title SettersGovernor
/// @author Angle Labs, Inc.
contract SettersGovernor is AccessControlModifiers, ISettersGovernor {
    using SafeERC20 for IERC20;

    event Recovered(address indexed token, address indexed to, uint256 amount);

    /// @inheritdoc ISettersGovernor
    /// @dev No check is made on the collateral that is redeemed: this function could typically be used by a
    /// governance during a manual rebalance of the reserves of the system
    /// @dev `collateral` is different from `token` only in the case of a managed collateral
    function recoverERC20(address collateral, IERC20 token, address to, uint256 amount) external onlyGovernor {
        Collateral storage collatInfo = s.transmuterStorage().collaterals[collateral];
        if (collatInfo.isManaged > 0) LibManager.release(address(token), to, amount, collatInfo.managerData.config);
        else token.safeTransfer(to, amount);
        emit Recovered(address(token), to, amount);
    }

    /// @inheritdoc ISettersGovernor
    function setAccessControlManager(address _newAccessControlManager) external onlyGovernor {
        LibSetters.setAccessControlManager(IAccessControlManager(_newAccessControlManager));
    }

    /// @inheritdoc ISettersGovernor
    /// @dev Funds need to have been withdrawn from the eventual previous manager prior to this call
    function setCollateralManager(address collateral, ManagerStorage memory managerData) external onlyGovernor {
        LibSetters.setCollateralManager(collateral, managerData);
    }

    /// @inheritdoc ISettersGovernor
    /// @dev This function can typically be used to grant allowance to a newly added manager for it to pull the
    /// funds associated to the collateral it corresponds to
    function changeAllowance(IERC20 token, address spender, uint256 amount) external onlyGovernor {
        uint256 currentAllowance = token.allowance(address(this), spender);
        if (currentAllowance < amount) {
            token.safeIncreaseAllowance(spender, amount - currentAllowance);
        } else if (currentAllowance > amount) {
            token.safeDecreaseAllowance(spender, currentAllowance - amount);
        }
    }

    /// @inheritdoc ISettersGovernor
    function toggleTrusted(address sender, TrustedType t) external onlyGovernor {
        LibSetters.toggleTrusted(sender, t);
    }

    /// @inheritdoc ISettersGovernor
    /// @dev Collateral assets with a fee on transfer are not supported by the system
    function addCollateral(address collateral) external onlyGovernor {
        LibSetters.addCollateral(collateral);
    }

    /// @inheritdoc ISettersGovernor
    /// @dev The amount passed here must be an absolute amount
    function adjustStablecoins(address collateral, uint128 amount, bool increase) external onlyGovernor {
        LibSetters.adjustStablecoins(collateral, amount, increase);
    }

    /// @inheritdoc ISettersGovernor
    /// @dev Require `collatInfo.normalizedStables == 0`, that is to say that the collateral
    /// is not used to back stables
    /// @dev The system may still have a non null balance of the collateral that is revoked: this should later
    /// be handled through a recoverERC20 call
    /// @dev Funds needs to have been withdrew from the manager prior to this call
    function revokeCollateral(address collateral) external onlyGovernor {
        LibSetters.revokeCollateral(collateral);
    }

    /// @inheritdoc ISettersGovernor
    function setOracle(address collateral, bytes memory oracleConfig) external onlyGovernor {
        LibSetters.setOracle(collateral, oracleConfig);
    }

    function updateOracle(address collateral) external {
        if (s.transmuterStorage().isSellerTrusted[msg.sender] == 0) revert NotTrusted();
        LibOracle.updateOracle(collateral);
    }

    /// @inheritdoc ISettersGovernor
    function setWhitelistStatus(
        address collateral,
        uint8 whitelistStatus,
        bytes memory whitelistData
    ) external onlyGovernor {
        LibSetters.setWhitelistStatus(collateral, whitelistStatus, whitelistData);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

import { IERC20 } from "oz/interfaces/IERC20.sol";

import "../transmuter/Storage.sol";

/// @title ISettersGovernor
/// @author Angle Labs, Inc.
interface ISettersGovernor {
    /// @notice Recovers `amount` of `token` from the Transmuter contract
    function recoverERC20(address collateral, IERC20 token, address to, uint256 amount) external;

    /// @notice Sets a new access control manager address
    function setAccessControlManager(address _newAccessControlManager) external;

    /// @notice Sets (or unsets) a collateral manager  `collateral`
    function setCollateralManager(address collateral, ManagerStorage memory managerData) external;

    /// @notice Sets the allowance of the contract on `token` for `spender` to `amount`
    function changeAllowance(IERC20 token, address spender, uint256 amount) external;

    /// @notice Changes the trusted status for `sender` when for selling rewards or updating the normalizer
    function toggleTrusted(address sender, TrustedType t) external;

    /// @notice Changes whether a `collateral` can only be handled during burns and redemptions by whitelisted addresses
    /// and sets the data used to read into the whitelist
    function setWhitelistStatus(address collateral, uint8 whitelistStatus, bytes memory whitelistData) external;

    /// @notice Add `collateral` as a supported collateral in the system
    function addCollateral(address collateral) external;

    /// @notice Adjusts the amount of stablecoins issued from `collateral` by `amount`
    function adjustStablecoins(address collateral, uint128 amount, bool increase) external;

    /// @notice Revokes `collateral` from the system
    function revokeCollateral(address collateral) external;

    /// @notice Sets the `oracleConfig` used to read the value of `collateral` for the mint, burn and redemption
    /// operations
    function setOracle(address collateral, bytes memory oracleConfig) external;

    /// @notice Update oracle data for a given `collateral`
    function updateOracle(address collateral) external;
}

/// @title ISettersGovernor
/// @author Angle Labs, Inc.
interface ISettersGuardian {
    /// @notice Changes the pause status for mint or burn transactions for `collateral`
    function togglePause(address collateral, ActionType action) external;

    /// @notice Sets the mint or burn fees for `collateral`
    function setFees(address collateral, uint64[] memory xFee, int64[] memory yFee, bool mint) external;

    /// @notice Sets the parameters for the redemption curve
    function setRedemptionCurveParams(uint64[] memory xFee, int64[] memory yFee) external;

    /// @notice Changes the whitelist status for a collateral with `whitelistType` for an address `who`
    function toggleWhitelist(WhitelistType whitelistType, address who) external;

    /// @notice Sets the stablecoin cap that can be issued from a `collateral`
    function setStablecoinCap(address collateral, uint256 stablecoinCap) external;
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

import { SafeCast } from "oz/utils/math/SafeCast.sol";
import { IERC20Metadata } from "oz/token/ERC20/extensions/IERC20Metadata.sol";

import { LibManager } from "../libraries/LibManager.sol";
import { LibOracle } from "./LibOracle.sol";
import { LibStorage as s } from "./LibStorage.sol";
import { LibDiamond } from "./LibDiamond.sol";
import { LibWhitelist } from "./LibWhitelist.sol";

import "../../utils/Constants.sol";
import "../../utils/Errors.sol";
import "../Storage.sol";

/// @title LibSetters
/// @author Angle Labs, Inc.
library LibSetters {
    using SafeCast for uint256;

    event CollateralAdded(address indexed collateral);
    event CollateralManagerSet(address indexed collateral, ManagerStorage managerData);
    event CollateralRevoked(address indexed collateral);
    event CollateralWhitelistStatusUpdated(address indexed collateral, bytes whitelistData, uint8 whitelistStatus);
    event FeesSet(address indexed collateral, uint64[] xFee, int64[] yFee, bool mint);
    event OracleSet(address indexed collateral, bytes oracleConfig);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event PauseToggled(address indexed collateral, uint256 pausedType, bool isPaused);
    event RedemptionCurveParamsSet(uint64[] xFee, int64[] yFee);
    event ReservesAdjusted(address indexed collateral, uint256 amount, bool increase);
    event StablecoinCapSet(address indexed collateral, uint256 stablecoinCap);
    event TrustedToggled(address indexed sender, bool isTrusted, TrustedType trustedType);
    event WhitelistStatusToggled(WhitelistType whitelistType, address indexed who, uint256 whitelistStatus);

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                 ONLY GOVERNOR ACTIONS                                              
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Internal version of `setAccessControlManager`
    function setAccessControlManager(IAccessControlManager _newAccessControlManager) internal {
        DiamondStorage storage ds = s.diamondStorage();
        IAccessControlManager previousAccessControlManager = ds.accessControlManager;
        ds.accessControlManager = _newAccessControlManager;
        emit OwnershipTransferred(address(previousAccessControlManager), address(_newAccessControlManager));
    }

    /// @notice Internal version of `setCollateralManager`
    function setCollateralManager(address collateral, ManagerStorage memory managerData) internal {
        Collateral storage collatInfo = s.transmuterStorage().collaterals[collateral];
        if (collatInfo.decimals == 0) revert NotCollateral();
        uint8 isManaged = collatInfo.isManaged;
        if (isManaged > 0) {
            (, uint256 totalValue) = LibManager.totalAssets(collatInfo.managerData.config);
            if (totalValue > 0) revert ManagerHasAssets();
        }
        if (managerData.config.length != 0) {
            // The first subCollateral given should be the actual collateral asset
            if (address(managerData.subCollaterals[0]) != collateral) revert InvalidParams();
            // Sanity check on the manager data that is passed
            LibManager.parseManagerConfig(managerData.config);
            collatInfo.isManaged = 1;
        } else collatInfo.isManaged = 0;
        collatInfo.managerData = managerData;
        emit CollateralManagerSet(collateral, managerData);
    }

    /// @notice Internal version of `toggleTrusted`
    function toggleTrusted(address sender, TrustedType t) internal {
        TransmuterStorage storage ts = s.transmuterStorage();
        uint256 trustedStatus;
        if (t == TrustedType.Updater) {
            trustedStatus = 1 - ts.isTrusted[sender];
            ts.isTrusted[sender] = trustedStatus;
        } else {
            trustedStatus = 1 - ts.isSellerTrusted[sender];
            ts.isSellerTrusted[sender] = trustedStatus;
        }
        emit TrustedToggled(sender, trustedStatus == 1, t);
    }

    /// @notice Internal version of `addCollateral`
    function addCollateral(address collateral) internal {
        TransmuterStorage storage ts = s.transmuterStorage();
        Collateral storage collatInfo = ts.collaterals[collateral];
        if (collatInfo.decimals != 0) revert AlreadyAdded();
        collatInfo.decimals = uint8(IERC20Metadata(collateral).decimals());
        ts.collateralList.push(collateral);
        emit CollateralAdded(collateral);
    }

    /// @notice Internal version of `adjustStablecoins`
    function adjustStablecoins(address collateral, uint128 amount, bool increase) internal {
        TransmuterStorage storage ts = s.transmuterStorage();
        Collateral storage collatInfo = ts.collaterals[collateral];
        if (collatInfo.decimals == 0) revert NotCollateral();
        uint128 normalizedAmount = ((amount * BASE_27) / ts.normalizer).toUint128();
        if (increase) {
            collatInfo.normalizedStables = collatInfo.normalizedStables + uint216(normalizedAmount);
            ts.normalizedStables = ts.normalizedStables + normalizedAmount;
        } else {
            collatInfo.normalizedStables = collatInfo.normalizedStables - uint216(normalizedAmount);
            ts.normalizedStables = ts.normalizedStables - normalizedAmount;
        }
        emit ReservesAdjusted(collateral, amount, increase);
    }

    /// @notice Internal version of `revokeCollateral`
    function revokeCollateral(address collateral) internal {
        TransmuterStorage storage ts = s.transmuterStorage();
        Collateral storage collatInfo = ts.collaterals[collateral];
        if (collatInfo.decimals == 0 || collatInfo.normalizedStables > 0) revert NotCollateral();
        uint8 isManaged = collatInfo.isManaged;
        if (isManaged > 0) {
            (, uint256 totalValue) = LibManager.totalAssets(collatInfo.managerData.config);
            if (totalValue > 0) revert ManagerHasAssets();
        }
        delete ts.collaterals[collateral];
        address[] memory collateralListMem = ts.collateralList;
        uint256 length = collateralListMem.length;
        for (uint256 i; i < length - 1; ++i) {
            if (collateralListMem[i] == collateral) {
                ts.collateralList[i] = collateralListMem[length - 1];
                break;
            }
        }
        ts.collateralList.pop();
        emit CollateralRevoked(collateral);
    }

    /// @notice Internal version of `setOracle`
    function setOracle(address collateral, bytes memory oracleConfig) internal {
        Collateral storage collatInfo = s.transmuterStorage().collaterals[collateral];
        if (collatInfo.decimals == 0) revert NotCollateral();
        // Checks oracle validity
        LibOracle.readMint(oracleConfig);
        collatInfo.oracleConfig = oracleConfig;
        emit OracleSet(collateral, oracleConfig);
    }

    /// @notice Internal version of `setWhitelistStatus`
    function setWhitelistStatus(address collateral, uint8 whitelistStatus, bytes memory whitelistData) internal {
        Collateral storage collatInfo = s.transmuterStorage().collaterals[collateral];
        if (collatInfo.decimals == 0) revert NotCollateral();
        if (whitelistStatus == 1) {
            // Sanity check
            LibWhitelist.checkWhitelist(whitelistData, address(this));
            collatInfo.whitelistData = whitelistData;
        }
        collatInfo.onlyWhitelisted = whitelistStatus;
        emit CollateralWhitelistStatusUpdated(collateral, whitelistData, whitelistStatus);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                 ONLY GUARDIAN ACTIONS                                              
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Internal version of `togglePause`
    function togglePause(address collateral, ActionType action) internal {
        uint8 isLive;
        if (action == ActionType.Mint || action == ActionType.Burn) {
            Collateral storage collatInfo = s.transmuterStorage().collaterals[collateral];
            if (collatInfo.decimals == 0) revert NotCollateral();
            if (action == ActionType.Mint) {
                isLive = 1 - collatInfo.isMintLive;
                collatInfo.isMintLive = isLive;
            } else {
                isLive = 1 - collatInfo.isBurnLive;
                collatInfo.isBurnLive = isLive;
            }
        } else {
            TransmuterStorage storage ts = s.transmuterStorage();
            isLive = 1 - ts.isRedemptionLive;
            ts.isRedemptionLive = isLive;
        }
        emit PauseToggled(collateral, uint256(action), isLive == 0);
    }

    /// @notice Internal version of `setFees`
    function setFees(address collateral, uint64[] memory xFee, int64[] memory yFee, bool mint) internal {
        TransmuterStorage storage ts = s.transmuterStorage();
        Collateral storage collatInfo = ts.collaterals[collateral];
        if (collatInfo.decimals == 0) revert NotCollateral();
        checkFees(xFee, yFee, mint ? ActionType.Mint : ActionType.Burn);
        if (mint) {
            collatInfo.xFeeMint = xFee;
            collatInfo.yFeeMint = yFee;
        } else {
            collatInfo.xFeeBurn = xFee;
            collatInfo.yFeeBurn = yFee;
        }
        emit FeesSet(collateral, xFee, yFee, mint);
    }

    /// @notice Internal version of `setRedemptionCurveParams`
    function setRedemptionCurveParams(uint64[] memory xFee, int64[] memory yFee) internal {
        TransmuterStorage storage ts = s.transmuterStorage();
        LibSetters.checkFees(xFee, yFee, ActionType.Redeem);
        ts.xRedemptionCurve = xFee;
        ts.yRedemptionCurve = yFee;
        emit RedemptionCurveParamsSet(xFee, yFee);
    }

    /// @notice Internal version of `toggleWhitelist`
    function toggleWhitelist(WhitelistType whitelistType, address who) internal {
        TransmuterStorage storage ts = s.transmuterStorage();
        uint256 whitelistStatus = 1 - ts.isWhitelistedForType[whitelistType][who];
        ts.isWhitelistedForType[whitelistType][who] = whitelistStatus;
        emit WhitelistStatusToggled(whitelistType, who, whitelistStatus);
    }

    /// @notice Sets the stablecoin cap that can be issued from a collateral
    function setStablecoinCap(address collateral, uint256 stablecoinCap) internal {
        Collateral storage collatInfo = s.transmuterStorage().collaterals[collateral];
        if (collatInfo.decimals == 0) revert NotCollateral();
        collatInfo.stablecoinCap = stablecoinCap;
        emit StablecoinCapSet(collateral, stablecoinCap);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                        HELPERS                                                     
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks the fee values given for the `mint`, `burn`, and `redeem` functions
    function checkFees(uint64[] memory xFee, int64[] memory yFee, ActionType action) internal view {
        uint256 n = xFee.length;
        if (n != yFee.length || n == 0) revert InvalidParams();
        if (
            // Mint inflexion points should be in [0,BASE_9[
            // We have: amountPostFee * (BASE_9 + yFeeMint) = amountPreFee * BASE_9
            // Hence we consider BASE_12 as the max value (100% fees) for yFeeMint
            (action == ActionType.Mint && (xFee[n - 1] >= BASE_9 || xFee[0] != 0 || yFee[n - 1] > int256(BASE_12))) ||
            // Burn inflexion points should be in [0,BASE_9] but fees should be constant in
            // the first segment [BASE_9, x_{n-1}[
            (action == ActionType.Burn &&
                (xFee[0] != BASE_9 || yFee[n - 1] > int256(BASE_9) || (n > 1 && (yFee[0] != yFee[1])))) ||
            // Redemption inflexion points should be in [0,BASE_9]
            (action == ActionType.Redeem && (xFee[n - 1] > BASE_9 || yFee[n - 1] < 0 || yFee[n - 1] > int256(BASE_9)))
        ) revert InvalidParams();

        for (uint256 i; i < n - 1; ++i) {
            if (
                // xFee strictly increasing and yFee increasing for mints
                (action == ActionType.Mint && (xFee[i] >= xFee[i + 1] || (yFee[i + 1] < yFee[i]))) ||
                // xFee strictly decreasing and yFee increasing for burns
                (action == ActionType.Burn && (xFee[i] <= xFee[i + 1] || (yFee[i + 1] < yFee[i]))) ||
                // xFee strictly increasing and yFee should be in [0,BASE_9] for redemptions
                (action == ActionType.Redeem && (xFee[i] >= xFee[i + 1] || yFee[i] < 0 || yFee[i] > int256(BASE_9)))
            ) revert InvalidParams();
        }

        // If a mint or burn fee is negative, we need to check that accounts atomically minting
        // (from any collateral) and then burning cannot get more than their initial value
        if (yFee[0] < 0) {
            if (!LibDiamond.isGovernor(msg.sender)) revert NotGovernor(); // Only governor can set negative fees
            TransmuterStorage storage ts = s.transmuterStorage();
            address[] memory collateralListMem = ts.collateralList;
            uint256 length = collateralListMem.length;
            if (action == ActionType.Mint) {
                // This can be mathematically expressed by `(1-min_c(burnFee_c))<=(1+mintFee[0])`
                for (uint256 i; i < length; ++i) {
                    int64[] memory burnFees = ts.collaterals[collateralListMem[i]].yFeeBurn;
                    if (burnFees[0] + yFee[0] < 0) revert InvalidNegativeFees();
                }
            }
            if (action == ActionType.Burn) {
                // This can be mathematically expressed by `(1-burnFee[0])<=(1+min_c(mintFee_c))`
                for (uint256 i; i < length; ++i) {
                    int64[] memory mintFees = ts.collaterals[collateralListMem[i]].yFeeMint;
                    if (yFee[0] + mintFees[0] < 0) revert InvalidNegativeFees();
                }
            }
        }
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

import { LibDiamond } from "../libraries/LibDiamond.sol";
import { LibStorage as s, TransmuterStorage } from "../libraries/LibStorage.sol";
import "../../utils/Errors.sol";
import "../../utils/Constants.sol";

/// @title AccessControlModifiers
/// @author Angle Labs, Inc.
contract AccessControlModifiers {
    /// @notice Checks whether the `msg.sender` has the governor role
    modifier onlyGovernor() {
        if (!LibDiamond.isGovernor(msg.sender)) revert NotGovernor();
        _;
    }

    /// @notice Checks whether the `msg.sender` has the guardian role
    modifier onlyGuardian() {
        if (!LibDiamond.isGovernorOrGuardian(msg.sender)) revert NotGovernorOrGuardian();
        _;
    }

    /// @notice Prevents a contract from calling itself, directly or indirectly
    /// @dev This implementation is an adaptation of the OpenZepellin `ReentrancyGuard` for the purpose of this
    /// Diamond Proxy system. The base implementation can be found here
    /// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol
    modifier nonReentrant() {
        TransmuterStorage storage ts = s.transmuterStorage();
        // Reentrant protection
        // On the first call, `ts.statusReentrant` will be `NOT_ENTERED`
        if (ts.statusReentrant == ENTERED) revert ReentrantCall();
        // Any calls to the `nonReentrant` modifier after this point will fail
        ts.statusReentrant = ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200)
        ts.statusReentrant = NOT_ENTERED;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { LibStorage as s } from "./LibStorage.sol";

import "../../utils/Errors.sol";
import "../Storage.sol";

/// @title LibDiamond
/// @author Angle Labs, Inc.
/// @notice Helper library to deal with diamond proxies.
/// @dev Reference: EIP-2535 Diamonds
/// @dev Forked from https://github.com/mudgen/diamond-3/blob/master/contracts/libraries/LibDiamond.sol by mudgen
library LibDiamond {
    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                  INTERNAL FUNCTIONS                                                
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Checks whether `admin` has the governor role
    function isGovernor(address admin) internal view returns (bool) {
        return s.diamondStorage().accessControlManager.isGovernor(admin);
    }

    /// @notice Checks whether `admin` has the guardian role
    function isGovernorOrGuardian(address admin) internal view returns (bool) {
        return s.diamondStorage().accessControlManager.isGovernorOrGuardian(admin);
    }

    /// @notice Internal function version of `diamondCut`
    function diamondCut(FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        uint256 diamondCutLength = _diamondCut.length;
        for (uint256 facetIndex; facetIndex < diamondCutLength; facetIndex++) {
            bytes4[] memory functionSelectors = _diamondCut[facetIndex].functionSelectors;
            address facetAddress = _diamondCut[facetIndex].facetAddress;

            if (functionSelectors.length == 0) {
                revert NoSelectorsProvidedForFacetForCut(facetAddress);
            }

            FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == FacetCutAction.Add) {
                _addFunctions(facetAddress, functionSelectors);
            } else if (action == FacetCutAction.Replace) {
                _replaceFunctions(facetAddress, functionSelectors);
            } else if (action == FacetCutAction.Remove) {
                _removeFunctions(facetAddress, functionSelectors);
            }
        }

        emit DiamondCut(_diamondCut, _init, _calldata);
        _initializeDiamondCut(_init, _calldata);
    }

    /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                   PRIVATE FUNCTIONS                                                
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////*/

    /// @notice Does a delegate call on `_init` with `_calldata`
    function _initializeDiamondCut(address _init, bytes memory _calldata) private {
        if (_init == address(0)) {
            return;
        }
        _enforceHasContractCode(_init);
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    /// @notice Adds a new function to the diamond proxy
    /// @dev Reverts if selectors are already existing
    function _addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) private {
        if (_facetAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        DiamondStorage storage ds = s.diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        _enforceHasContractCode(_facetAddress);
        uint256 functionSelectorsLength = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorInfo[selector].facetAddress;
            if (oldFacetAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }
            ds.selectorInfo[selector] = FacetInfo(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    /// @notice Upgrades a function in the diamond proxy
    /// @dev Reverts if selectors do not already exist
    function _replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) private {
        DiamondStorage storage ds = s.diamondStorage();
        if (_facetAddress == address(0)) {
            revert CannotReplaceFunctionsFromFacetWithZeroAddress(_functionSelectors);
        }
        _enforceHasContractCode(_facetAddress);
        uint256 functionSelectorsLength = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorInfo[selector].facetAddress;
            // Can't replace immutable functions -- functions defined directly in the diamond in this case
            if (oldFacetAddress == address(this)) {
                revert CannotReplaceImmutableFunction(selector);
            }
            if (oldFacetAddress == _facetAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(selector);
            }
            if (oldFacetAddress == address(0)) {
                revert CannotReplaceFunctionThatDoesNotExists(selector);
            }
            // Replace old facet address
            ds.selectorInfo[selector].facetAddress = _facetAddress;
        }
    }

    /// @notice Removes a function in the diamond proxy
    /// @dev Reverts if selectors do not already exist
    function _removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) private {
        DiamondStorage storage ds = s.diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if (_facetAddress != address(0)) {
            revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        }
        uint256 functionSelectorsLength = _functionSelectors.length;
        for (uint256 selectorIndex; selectorIndex < functionSelectorsLength; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetInfo memory oldFacetAddressAndSelectorPosition = ds.selectorInfo[selector];
            if (oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {
                revert CannotRemoveFunctionThatDoesNotExist(selector);
            }

            // Can't remove immutable functions -- functions defined directly in the diamond
            if (oldFacetAddressAndSelectorPosition.facetAddress == address(this)) {
                revert CannotRemoveImmutableFunction(selector);
            }
            // Replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.selectorInfo[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // Delete last selector
            ds.selectors.pop();
            delete ds.selectorInfo[selector];
        }
    }

    /// @notice Checks that an address has a non void bytecode
    function _enforceHasContractCode(address _contract) private view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert ContractHasNoCode();
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

/// @title IKeyringGuard
/// @notice Interface for the `KeyringGuard` contract
interface IKeyringGuard {
    function isAuthorized(address from, address to) external returns (bool passed);
}